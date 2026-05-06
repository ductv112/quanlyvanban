/**
 * tests/fixtures/auth.ts — Auth helpers cho Playwright E2E tests
 *
 * Usage 1: storage state path (chinh — skip login moi test):
 *   import { storageStateFor } from '../fixtures/auth';
 *   test.use({ storageState: storageStateFor('vanthu') });
 *   test('TC-VBD-001 ...', async ({ page }) => {
 *     // page da co session vanthu — KHONG can login
 *   });
 *
 * Usage 2: programmatic login (ch test logout / change password / fresh session):
 *   import { loginAs } from '../fixtures/auth';
 *   test('TC-AUTH-005 logout', async ({ page, request }) => {
 *     const { accessToken, user } = await loginAs(request, 'vanthu');
 *     // ... test logout flow ...
 *   });
 *
 * Co-located cred map matches:
 *   - tests/globalSetup.ts (TEST_USERS_FOR_AUTH)
 *   - e_office_app_new/backend/tests/fixtures/users.ts (TEST_USERS)
 *   - database/seed/003_test_fixtures.sql (test_admin / test_vanthu / ...)
 */

import path from 'path';

/**
 * Resolve tests/.auth dir relative to this fixtures file.
 * __dirname (CJS) hoat dong khi Playwright load qua require().
 * Dung path.resolve voi __dirname truc tiep — Playwright config compile CJS.
 */
export const STORAGE_STATE_DIR = path.resolve(__dirname, '..', '.auth');

/**
 * 5 role keys (skip 'locked' — login 401, khong co storage state).
 */
export type RoleKey = 'admin' | 'vanthu' | 'lanhdao' | 'canbo' | 'canboX';

/**
 * Path tuyet doi den storage state file cua role.
 *   storageStateFor('vanthu') -> '/abs/path/to/tests/.auth/vanthu.json'
 */
export function storageStateFor(role: RoleKey): string {
  return path.join(STORAGE_STATE_DIR, `${role}.json`);
}

/**
 * Credentials for 5 role (mirror seed/003_test_fixtures.sql).
 */
const CREDENTIALS: Record<RoleKey, { username: string; password: string }> = {
  admin: { username: 'test_admin', password: 'Test@123' },
  vanthu: { username: 'test_vanthu', password: 'Test@123' },
  lanhdao: { username: 'test_lanhdao', password: 'Test@123' },
  canbo: { username: 'test_canbo', password: 'Test@123' },
  canboX: { username: 'test_canbo_x', password: 'Test@123' },
};

/**
 * Minimal HTTP request interface khop voi Playwright APIRequestContext
 * + Node fetch wrapper (cho integration test). Khong import @playwright/test
 * de file nay dung cho ca 2 tier (E2E + integration).
 */
export interface HttpRequest {
  post(
    url: string,
    options: { data: unknown; headers?: Record<string, string> }
  ): Promise<{ ok(): boolean; status(): number; text(): Promise<string>; json(): Promise<unknown> }>;
}

export interface LoginResult {
  accessToken: string;
  user: {
    id: number;
    username: string;
    full_name: string;
    roles?: string[];
    department_id?: number;
    unit_id?: number;
  };
}

/**
 * Programmatic login (cho test can fresh login khong reuse storage state).
 *
 * @param request - Playwright APIRequestContext (test fixture) hoac compatible wrapper
 * @param role - 1 trong 5 RoleKey
 * @param baseUrl - optional override (default PLAYWRIGHT_API_URL hoac http://localhost:4000)
 */
export async function loginAs(
  request: HttpRequest,
  role: RoleKey,
  baseUrl?: string
): Promise<LoginResult> {
  const apiUrl = baseUrl || process.env.PLAYWRIGHT_API_URL || 'http://localhost:4000';
  const cred = CREDENTIALS[role];
  if (!cred) throw new Error(`[loginAs] Unknown role: ${role}`);

  const response = await request.post(`${apiUrl}/api/auth/login`, {
    data: cred,
    headers: { 'Content-Type': 'application/json' },
  });

  if (!response.ok()) {
    const body = await response.text();
    throw new Error(`[loginAs] Login fail cho ${role} (${cred.username}): ${response.status()} ${body}`);
  }

  const json = (await response.json()) as {
    success: boolean;
    data?: LoginResult;
    message?: string;
  };

  if (!json.success || !json.data) {
    throw new Error(`[loginAs] Login response invalid cho ${role}: ${JSON.stringify(json)}`);
  }

  return json.data;
}

/**
 * Bearer header helper (cho integration tier — supertest / fetch).
 *   const headers = getAuthHeader(token);
 *   const res = await fetch(url, { headers });
 */
export function getAuthHeader(accessToken: string): Record<string, string> {
  return { Authorization: `Bearer ${accessToken}` };
}
