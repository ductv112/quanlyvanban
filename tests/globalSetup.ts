/**
 * tests/globalSetup.ts — Playwright global setup
 *
 * Chay 1 LAN truoc toan bo E2E suite:
 *   1. Verify backend health (GET http://localhost:4000/api/health)
 *   2. Login 5 user fixture (admin, vanthu, lanhdao, canbo, canboX) qua POST /api/auth/login
 *   3. Save 5 storage state file vao tests/.auth/<role>.json
 *
 * Storage state shape (Playwright):
 *   {
 *     cookies: [{name, value, domain, path, expires, httpOnly, secure, sameSite}],
 *     origins: [{origin: 'http://localhost:3000', localStorage: [{name: 'accessToken', value: '...'}]}]
 *   }
 *
 * Tests dung:
 *   import { storageStateFor } from './fixtures/auth';
 *   test.use({ storageState: storageStateFor('vanthu') });
 *   // -> tu dong co cookie refreshToken (path=/api/auth) + localStorage accessToken
 *
 * Backend POST /api/auth/login response shape (verify backend/src/routes/auth.ts):
 *   - 200 { success: true, data: { accessToken: string, user: {...} } }
 *   - Set-Cookie: refreshToken=<JWT> httpOnly path=/api/auth maxAge=7d
 *
 * Frontend localStorage key: 'accessToken' (verify frontend/src/stores/auth.store.ts:47)
 *
 * Pre-req: backend dev running on :4000 + test DB seeded (npm run test:db:reset)
 *   cd e_office_app_new/backend && PG_DATABASE=qlvb_test npm run dev
 */

import { chromium, type FullConfig } from '@playwright/test';
import path from 'path';
import fs from 'fs';
import http from 'http';

// Inline credential map (do NOT import @ ts boundary path issue).
// Source of truth: e_office_app_new/backend/tests/fixtures/users.ts (TEST_USERS).
// Skip 'locked' user (login se 401 vi is_locked=true) - chi 5 storage state.
const TEST_USERS_FOR_AUTH = [
  { key: 'admin', username: 'test_admin', password: 'Test@123' },
  { key: 'vanthu', username: 'test_vanthu', password: 'Test@123' },
  { key: 'lanhdao', username: 'test_lanhdao', password: 'Test@123' },
  { key: 'canbo', username: 'test_canbo', password: 'Test@123' },
  { key: 'canboX', username: 'test_canbo_x', password: 'Test@123' },
] as const;

const BACKEND_URL = process.env.PLAYWRIGHT_API_URL || 'http://localhost:4000';
const FRONTEND_URL = process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:3000';
const STORAGE_STATE_DIR = path.resolve(__dirname, '.auth');

/**
 * Poll GET /api/health until 200 (or timeout). Khong hang.
 */
async function waitForBackend(timeoutMs = 30000): Promise<void> {
  const url = `${BACKEND_URL}/api/health`;
  const start = Date.now();

  while (Date.now() - start < timeoutMs) {
    const ok = await new Promise<boolean>((resolve) => {
      const req = http.get(url, (res) => {
        const status = res.statusCode || 0;
        res.resume();
        resolve(status >= 200 && status < 300);
      });
      req.on('error', () => resolve(false));
      req.setTimeout(2000, () => {
        req.destroy();
        resolve(false);
      });
    });

    if (ok) return;
    await new Promise((r) => setTimeout(r, 500));
  }

  throw new Error(
    `[globalSetup] Backend khong phan hoi tai ${url} sau ${timeoutMs}ms. ` +
      `Dam bao backend dang chay: cd e_office_app_new/backend && PG_DATABASE=qlvb_test npm run dev`
  );
}

/**
 * Login 1 user qua POST /api/auth/login + save storage state.
 *  - cookie refreshToken (httpOnly, path=/api/auth) duoc browser context capture
 *  - localStorage accessToken duoc set thu cong (axios interceptor frontend doc key nay)
 */
async function loginAndSaveState(user: {
  key: string;
  username: string;
  password: string;
}): Promise<void> {
  const browser = await chromium.launch();
  const context = await browser.newContext();
  const page = await context.newPage();

  try {
    // 1. Goi POST /api/auth/login truc tiep (page.request.post -> share cookie jar voi context)
    const loginResponse = await page.request.post(`${BACKEND_URL}/api/auth/login`, {
      data: { username: user.username, password: user.password },
      headers: { 'Content-Type': 'application/json' },
    });

    if (!loginResponse.ok()) {
      const body = await loginResponse.text();
      throw new Error(
        `[globalSetup] Login fail cho ${user.username}: HTTP ${loginResponse.status()} ${body}`
      );
    }

    const json = (await loginResponse.json()) as {
      success: boolean;
      data?: { accessToken: string; user: unknown };
      message?: string;
    };

    if (!json.success || !json.data?.accessToken) {
      throw new Error(
        `[globalSetup] Login response invalid cho ${user.username}: ${JSON.stringify(json)}`
      );
    }

    const accessToken = json.data.accessToken;

    // 2. Navigate frontend roi set localStorage (origin = http://localhost:3000)
    //    Khong can frontend render UI - chi can origin de browser ghi localStorage.
    //    Dung 'commit' wait state de tranh phai cho full network idle.
    await page.goto(FRONTEND_URL, { waitUntil: 'commit' });
    await page.evaluate((token) => {
      window.localStorage.setItem('accessToken', token);
    }, accessToken);

    // 3. Save storage state (cookies + localStorage) -> tests/.auth/<key>.json
    const statePath = path.join(STORAGE_STATE_DIR, `${user.key}.json`);
    await context.storageState({ path: statePath });

    // eslint-disable-next-line no-console
    console.log(`[globalSetup]   ${user.key.padEnd(10)} -> ${statePath}`);
  } finally {
    await context.close();
    await browser.close();
  }
}

/**
 * Playwright entry point. Chay 1 lan truoc toan bo suite.
 */
export default async function globalSetup(_config: FullConfig): Promise<void> {
  // eslint-disable-next-line no-console
  console.log('[globalSetup] Starting...');

  // 1. Ensure auth dir exists
  if (!fs.existsSync(STORAGE_STATE_DIR)) {
    fs.mkdirSync(STORAGE_STATE_DIR, { recursive: true });
  }

  // 2. Wait for backend healthy
  // eslint-disable-next-line no-console
  console.log(`[globalSetup] Waiting for backend at ${BACKEND_URL}/api/health...`);
  await waitForBackend();
  // eslint-disable-next-line no-console
  console.log('[globalSetup] Backend healthy');

  // 3. Login 5 user PARALLEL (Promise.all -> ~200ms x 5 ~= 1s tong)
  const t0 = Date.now();
  await Promise.all(TEST_USERS_FOR_AUTH.map(loginAndSaveState));
  const elapsed = Date.now() - t0;
  // eslint-disable-next-line no-console
  console.log(`[globalSetup] Logged in ${TEST_USERS_FOR_AUTH.length} users in ${elapsed}ms`);

  // 4. Verify 5 file generated + non-empty
  for (const user of TEST_USERS_FOR_AUTH) {
    const f = path.join(STORAGE_STATE_DIR, `${user.key}.json`);
    if (!fs.existsSync(f)) {
      throw new Error(`[globalSetup] Storage state file missing: ${f}`);
    }
    const stat = fs.statSync(f);
    if (stat.size < 50) {
      throw new Error(`[globalSetup] Storage state file empty: ${f} (${stat.size} bytes)`);
    }
  }

  // eslint-disable-next-line no-console
  console.log('[globalSetup] DONE');
}
