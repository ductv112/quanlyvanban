/**
 * tests/fixtures/api-client.ts — HTTP client wrapper cho integration + E2E tests
 *
 * Vitest integration test KHONG dung supertest(app) truc tiep vi backend
 * server.ts co app.listen() top-level (khong export factory function).
 * Workaround: goi qua HTTP localhost:4000 (backend da chay bg trong CI).
 *
 * Usage trong Vitest test:
 *   import { createApiClient, loginAndGetToken } from '../fixtures/api-client';
 *
 *   describe('VB den', () => {
 *     let api: ApiClient;
 *     beforeAll(async () => {
 *       const { accessToken } = await loginAndGetToken('vanthu');
 *       api = createApiClient(accessToken);
 *     });
 *     it('TC-VBD-001 GET list', async () => {
 *       const res = await api.get('/api/van-ban-den');
 *       expect(res.status).toBe(200);
 *     });
 *   });
 *
 * Future refactor (deferred Phase 22+): split createApp() factory tu server.ts
 *  -> co the dung supertest(app) thay vi HTTP -> nhanh hon va isolation tot hon.
 */

const BACKEND_URL =
  process.env.PLAYWRIGHT_API_URL || process.env.BACKEND_URL || 'http://localhost:4000';

export interface ApiResponse<T = unknown> {
  status: number;
  ok: boolean;
  data: T;
  headers: Record<string, string>;
}

export interface ApiClient {
  get<T = unknown>(path: string): Promise<ApiResponse<T>>;
  post<T = unknown>(path: string, body?: unknown): Promise<ApiResponse<T>>;
  put<T = unknown>(path: string, body?: unknown): Promise<ApiResponse<T>>;
  patch<T = unknown>(path: string, body?: unknown): Promise<ApiResponse<T>>;
  delete<T = unknown>(path: string): Promise<ApiResponse<T>>;
  upload<T = unknown>(path: string, formData: FormData): Promise<ApiResponse<T>>;
}

/**
 * Tao API client wrap fetch native voi:
 *   - Auto attach Bearer token (neu accessToken truyen vao)
 *   - Auto JSON encode request body (tru khi multipart)
 *   - Auto parse response body theo content-type
 *   - Return shape uniform { status, ok, data, headers }
 */
export function createApiClient(accessToken?: string, baseUrl?: string): ApiClient {
  const base = baseUrl || BACKEND_URL;
  const baseHeaders: Record<string, string> = {};
  if (accessToken) baseHeaders['Authorization'] = `Bearer ${accessToken}`;

  async function request<T>(
    method: string,
    pathOrUrl: string,
    body?: unknown,
    isMultipart = false
  ): Promise<ApiResponse<T>> {
    const url = pathOrUrl.startsWith('http') ? pathOrUrl : `${base}${pathOrUrl}`;
    const headers: Record<string, string> = { ...baseHeaders };
    let bodyToSend: BodyInit | undefined = undefined;

    if (body !== undefined) {
      if (isMultipart) {
        bodyToSend = body as FormData;
        // KHONG set Content-Type cho multipart — fetch tu set kem boundary
      } else {
        headers['Content-Type'] = 'application/json';
        bodyToSend = JSON.stringify(body);
      }
    }

    const res = await fetch(url, { method, headers, body: bodyToSend });

    const respHeaders: Record<string, string> = {};
    res.headers.forEach((v, k) => {
      respHeaders[k] = v;
    });

    let data: unknown;
    const contentType = res.headers.get('content-type') || '';
    if (contentType.includes('application/json')) {
      data = await res.json();
    } else {
      data = await res.text();
    }

    return {
      status: res.status,
      ok: res.ok,
      data: data as T,
      headers: respHeaders,
    };
  }

  return {
    get: <T = unknown>(p: string) => request<T>('GET', p),
    post: <T = unknown>(p: string, b?: unknown) => request<T>('POST', p, b),
    put: <T = unknown>(p: string, b?: unknown) => request<T>('PUT', p, b),
    patch: <T = unknown>(p: string, b?: unknown) => request<T>('PATCH', p, b),
    delete: <T = unknown>(p: string) => request<T>('DELETE', p),
    upload: <T = unknown>(p: string, fd: FormData) => request<T>('POST', p, fd, true),
  };
}

/**
 * 5 role key (mirror seed 003 + tests/fixtures/auth.ts RoleKey).
 */
export type ApiRoleKey = 'admin' | 'vanthu' | 'lanhdao' | 'canbo' | 'canboX';

const CREDENTIALS_API: Record<ApiRoleKey, { username: string; password: string }> = {
  admin: { username: 'test_admin', password: 'Test@123' },
  vanthu: { username: 'test_vanthu', password: 'Test@123' },
  lanhdao: { username: 'test_lanhdao', password: 'Test@123' },
  canbo: { username: 'test_canbo', password: 'Test@123' },
  canboX: { username: 'test_canbo_x', password: 'Test@123' },
};

interface LoginResponseShape {
  success: boolean;
  data: {
    accessToken: string;
    user: {
      id: number;
      username: string;
      full_name: string;
      roles?: string[];
      department_id?: number;
      unit_id?: number;
    };
  };
  message?: string;
}

/**
 * Login programmatically + return accessToken + user.
 * Dung trong Vitest beforeAll de setup auth:
 *   const { accessToken } = await loginAndGetToken('vanthu');
 *   const api = createApiClient(accessToken);
 */
export async function loginAndGetToken(role: ApiRoleKey, baseUrl?: string) {
  const cred = CREDENTIALS_API[role];
  if (!cred) throw new Error(`[loginAndGetToken] Unknown role: ${role}`);

  const apiClient = createApiClient(undefined, baseUrl);
  const res = await apiClient.post<LoginResponseShape>('/api/auth/login', cred);

  if (!res.ok || !res.data?.success || !res.data?.data) {
    throw new Error(
      `[loginAndGetToken] Login fail cho ${role} (${cred.username}): HTTP ${res.status} ${JSON.stringify(res.data)}`
    );
  }

  return res.data.data;
}
