/**
 * stop.ts — Kill 3 mock server còn chạy (cleanup)
 *
 * Usage:
 *   npm run stop
 *   tsx stop.ts
 *
 * Cross-platform: dùng netstat/taskkill (Windows) hoặc lsof/kill (Linux/macOS).
 * Tear down clean port 8181/8182/8183 — không để leak nếu start.ts crash.
 */

import { execSync } from 'child_process';

const PORTS = [8181, 8182, 8183];

function killByPortWindows(port: number): void {
  try {
    const out = execSync(`netstat -ano | findstr :${port}`, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] });
    const pids = new Set<string>();
    out.split('\n').forEach(line => {
      // Chỉ lấy process LISTENING trên port (không phải TIME_WAIT từ client)
      if (!line.includes('LISTENING')) return;
      const parts = line.trim().split(/\s+/);
      const pid = parts[parts.length - 1];
      if (pid && /^\d+$/.test(pid)) pids.add(pid);
    });
    if (pids.size === 0) {
      console.log(`[stop] no LISTENING process on port ${port}`);
      return;
    }
    pids.forEach(pid => {
      try {
        execSync(`taskkill /PID ${pid} /T /F`, { stdio: 'ignore' });
        console.log(`[stop] killed pid ${pid} on port ${port}`);
      } catch {
        // Process có thể đã chết
      }
    });
  } catch {
    console.log(`[stop] no process on port ${port}`);
  }
}

function killByPortUnix(port: number): void {
  try {
    const out = execSync(`lsof -ti :${port}`, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
    if (out) {
      const pids = out.split('\n').filter(Boolean);
      pids.forEach(pid => {
        try {
          execSync(`kill -TERM ${pid}`, { stdio: 'ignore' });
          console.log(`[stop] killed pid ${pid} on port ${port}`);
        } catch {
          // ignore
        }
      });
    } else {
      console.log(`[stop] no process on port ${port}`);
    }
  } catch {
    console.log(`[stop] no process on port ${port}`);
  }
}

function killByPort(port: number): void {
  if (process.platform === 'win32') {
    killByPortWindows(port);
  } else {
    killByPortUnix(port);
  }
}

PORTS.forEach(killByPort);
console.log('[stop] DONE');
