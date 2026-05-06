/**
 * start.ci.ts — Boot 3 mocks cho CI environment (CI-friendly mode).
 *
 * Khác start.ts ở 3 điểm:
 *  - Output redirect ra /tmp/qlvb-mocks.log (CI captures plain text, không màu)
 *  - Tail process detached (parent EXIT 0 sau khi 3 mock UP, mock vẫn chạy background)
 *  - PID file lưu /tmp/qlvb-mocks.pid để CI cleanup step kill được mocks
 *
 * Usage trong CI workflow yaml:
 *   - name: Boot mocks
 *     run: |
 *       cd tools/mocks
 *       npx tsx start.ci.ts
 *       # ↑ Lệnh này EXIT 0 sau khi 3 mock UP (~3-5s), KHÔNG block step.
 *       # Mocks tiếp tục chạy background nhờ child.unref()
 *
 *   - name: Cleanup mocks
 *     if: always()
 *     run: |
 *       [ -f /tmp/qlvb-mocks.pid ] && kill $(cat /tmp/qlvb-mocks.pid) 2>/dev/null || true
 *
 * Acceptance:
 *  - Exit code 0 khi cả 3 mock /health trả 200 trong < 15s
 *  - Exit code 1 nếu bất kỳ mock nào không UP — CI step fail
 *
 * Created: 2026-05-06 — Phase 21 Plan 06 (REQ CI-01)
 */

import { spawn } from 'child_process';
import path from 'path';
import { fileURLToPath } from 'url';
import http from 'http';
import fs from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

interface MockSpec {
  name: string;
  file: string;
  port: number;
}

const MOCKS: MockSpec[] = [
  { name: 'smartca', file: 'smartca-mock.ts', port: 8181 },
  { name: 'mysign',  file: 'mysign-mock.ts',  port: 8182 },
  { name: 'lgsp',    file: 'lgsp-mock.ts',    port: 8183 },
];

// CI thường dùng /tmp; fallback sang process.cwd() nếu /tmp không tồn tại (local Windows test)
const TMP_DIR = fs.existsSync('/tmp') ? '/tmp' : process.cwd();
const PID_FILE = path.join(TMP_DIR, 'qlvb-mocks.pid');
const LOG_FILE = path.join(TMP_DIR, 'qlvb-mocks.log');

const HEALTH_TIMEOUT_MS = 15_000;
const POLL_INTERVAL_MS = 200;

async function waitForHealth(port: number, timeoutMs = HEALTH_TIMEOUT_MS): Promise<boolean> {
  const url = `http://localhost:${port}/health`;
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    const ok = await new Promise<boolean>((resolve) => {
      const req = http.get(url, (res) => {
        resolve(res.statusCode === 200);
        res.resume();
      });
      req.on('error', () => resolve(false));
      req.setTimeout(2000, () => {
        req.destroy();
        resolve(false);
      });
    });
    if (ok) return true;
    await new Promise(r => setTimeout(r, POLL_INTERVAL_MS));
  }
  return false;
}

async function main(): Promise<void> {
  console.log(`[start.ci] Booting 3 mocks (SmartCA + MySign + LGSP) — log: ${LOG_FILE}`);

  // Truncate log file ở đầu run (mỗi CI run sạch)
  fs.writeFileSync(LOG_FILE, `[start.ci] === ${new Date().toISOString()} ===\n`);
  const logStream = fs.createWriteStream(LOG_FILE, { flags: 'a' });

  const pids: number[] = [];
  const isWin = process.platform === 'win32';

  for (const spec of MOCKS) {
    const file = path.join(__dirname, spec.file);
    const cmd = isWin ? 'npx.cmd' : 'npx';
    // detached: true cho phép parent exit mà child vẫn chạy
    // unref() ngắt parent khỏi child reference → parent process exit không kéo child theo
    const child = spawn(cmd, ['tsx', file], {
      stdio: ['ignore', 'pipe', 'pipe'],
      env: { ...process.env },
      detached: !isWin, // Windows không hỗ trợ detached chuẩn — dùng default
      cwd: __dirname,
      shell: isWin,
    });

    child.stdout?.pipe(logStream);
    child.stderr?.pipe(logStream);
    child.unref();

    if (child.pid) {
      pids.push(child.pid);
      console.log(`[start.ci] Spawned ${spec.name} pid=${child.pid} port=${spec.port}`);
    } else {
      console.error(`[start.ci] FAIL: ${spec.name} không spawn được (pid undefined)`);
      process.exit(1);
    }
  }

  // Wait all 3 health
  const t0 = Date.now();
  const results = await Promise.all(MOCKS.map(s => waitForHealth(s.port)));
  const elapsed = Date.now() - t0;

  if (!results.every(r => r)) {
    console.error(`[start.ci] FAIL: không phải 3 mock đều UP sau ${elapsed}ms`);
    results.forEach((up, i) => {
      console.error(`  ${MOCKS[i].name} (port ${MOCKS[i].port}): ${up ? 'UP' : 'DOWN'}`);
    });
    console.error(`[start.ci] Check log: ${LOG_FILE}`);
    // Cleanup các PID đã spawn (tránh để zombie chiếm port trong CI step kế)
    for (const pid of pids) {
      try { process.kill(pid, 'SIGKILL'); } catch { /* ignore */ }
    }
    process.exit(1);
  }

  // Save PIDs cho cleanup step
  fs.writeFileSync(PID_FILE, pids.join('\n') + '\n');

  console.log(`[start.ci] All 3 mocks UP in ${elapsed}ms`);
  console.log(`[start.ci]   - SmartCA: http://localhost:8181/health (pid ${pids[0]})`);
  console.log(`[start.ci]   - MySign:  http://localhost:8182/health (pid ${pids[1]})`);
  console.log(`[start.ci]   - LGSP:    http://localhost:8183/health (pid ${pids[2]})`);
  console.log(`[start.ci] PID file: ${PID_FILE}`);
  console.log(`[start.ci] Log file: ${LOG_FILE}`);
  console.log(`[start.ci] Exit 0 — mocks tiếp tục chạy background.`);

  // Exit ngay — child.unref() đảm bảo mocks không bị kill theo
  process.exit(0);
}

main().catch((err) => {
  console.error('[start.ci] FATAL:', err);
  process.exit(1);
});
