/**
 * start.ts — Boot 3 mock server concurrent (SmartCA, MySign, LGSP)
 *
 * Usage:
 *   npm start                                    # foreground (Ctrl+C để stop)
 *   tsx start.ts                                 # alternative
 *   tsx start.ts &                               # background (test scripts)
 *
 * Sau khi start, /health của 3 server phải trả 200 trong < 3 giây.
 *
 * Cross-platform: dùng process.platform === 'win32' để pick npx.cmd vs npx.
 */

import { spawn, ChildProcess } from 'child_process';
import path from 'path';
import { fileURLToPath } from 'url';
import http from 'http';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

interface MockSpec {
  name: string;
  file: string;
  port: number;
  healthPath: string;
}

const MOCKS: MockSpec[] = [
  { name: 'smartca', file: 'smartca-mock.ts', port: 8181, healthPath: '/health' },
  { name: 'mysign',  file: 'mysign-mock.ts',  port: 8182, healthPath: '/health' },
  { name: 'lgsp',    file: 'lgsp-mock.ts',    port: 8183, healthPath: '/health' },
];

const children: ChildProcess[] = [];

function spawnMock(spec: MockSpec): ChildProcess {
  const file = path.join(__dirname, spec.file);
  // Cross-platform: dùng tsx CLI (đã cài trong tools/mocks/devDependencies)
  // Windows: shell: true cần thiết để Node 22+ có thể spawn .cmd file (EINVAL nếu shell: false)
  const isWin = process.platform === 'win32';
  const cmd = isWin ? 'npx.cmd' : 'npx';
  const child = spawn(cmd, ['tsx', file], {
    stdio: ['ignore', 'inherit', 'inherit'],
    env: { ...process.env },
    detached: false,
    cwd: __dirname,
    shell: isWin,
  });
  child.on('exit', (code) => {
    if (code !== null && code !== 0) {
      console.error(`[start] ${spec.name} exited with code ${code}`);
    }
  });
  child.on('error', (err) => {
    console.error(`[start] ${spec.name} error:`, err.message);
  });
  return child;
}

async function waitForHealth(port: number, healthPath: string, timeoutMs = 10000): Promise<boolean> {
  const url = `http://localhost:${port}${healthPath}`;
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
    await new Promise(r => setTimeout(r, 200));
  }
  return false;
}

async function main(): Promise<void> {
  console.log('[start] Booting 3 mock servers (SmartCA + MySign + LGSP)...');

  for (const spec of MOCKS) {
    children.push(spawnMock(spec));
  }

  // Wait for all 3 health endpoints
  const t0 = Date.now();
  const results = await Promise.all(MOCKS.map(spec => waitForHealth(spec.port, spec.healthPath)));
  const allUp = results.every(r => r);

  if (!allUp) {
    console.error('[start] One or more mocks failed to boot:');
    results.forEach((up, i) => console.error(`  ${MOCKS[i].name} (${MOCKS[i].port}): ${up ? 'UP' : 'DOWN'}`));
    shutdown('FAIL');
    return;
  }

  const elapsed = Date.now() - t0;
  console.log(`[start] All 3 mocks UP in ${elapsed}ms`);
  console.log(`  - SmartCA: http://localhost:8181/health`);
  console.log(`  - MySign:  http://localhost:8182/health`);
  console.log(`  - LGSP:    http://localhost:8183/health`);
  console.log('[start] Press Ctrl+C to stop');
}

// Graceful shutdown — kill children
function shutdown(signal: string): void {
  console.log(`[start] ${signal} — terminating ${children.length} mock processes`);
  for (const child of children) {
    if (child.pid && !child.killed) {
      try {
        if (process.platform === 'win32') {
          // Windows: taskkill /T kill child tree (npx → tsx → node)
          spawn('taskkill', ['/pid', String(child.pid), '/T', '/F'], { stdio: 'ignore', shell: true });
        } else {
          child.kill('SIGTERM');
        }
      } catch (e) {
        console.error(`[start] error killing pid ${child.pid}:`, (e as Error).message);
      }
    }
  }
  setTimeout(() => process.exit(signal === 'FAIL' ? 1 : 0), 1000);
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

main().catch((err: Error) => {
  console.error('[start] FATAL:', err);
  shutdown('FATAL');
});
