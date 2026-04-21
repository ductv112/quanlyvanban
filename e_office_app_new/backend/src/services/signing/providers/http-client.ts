/**
 * Minimal HTTP client abstraction cho signing adapters.
 *
 * Tại sao KHÔNG dùng axios?
 *   Backend package.json không có `axios` (chỉ frontend). Tránh thêm dependency
 *   mới chỉ để 2 adapter dùng. Node 18+ có `fetch` native đủ cho JSON POST/GET.
 *
 * Tại sao KHÔNG dùng `fetch` trực tiếp?
 *   Test cần inject mock → interface `HttpClient` cho phép pass fake implementation
 *   trong test, production dùng `createDefaultHttpClient()` wrap `fetch`.
 *
 * Thiết kế tối giản:
 *   - `post(url, body, headers?)` → JSON POST, parse response JSON
 *   - Mặc định: timeout 15s (threat T-09-05 DoS mitigation)
 *   - Validate https-only trong validateHttpsBaseUrl() — ngăn MITM (T-09-04)
 */

const DEFAULT_TIMEOUT_MS = 15_000; // 15s — ngăn provider hang làm kẹt worker Phase 11

/**
 * Interface HTTP client — 2 adapter dùng chung.
 * Test inject mock qua `createSmartCaVnptProvider(mockClient)`.
 */
export interface HttpClient {
  post<T = unknown>(
    url: string,
    body: Record<string, unknown>,
    headers?: Record<string, string>,
  ): Promise<T>;
}

/**
 * Validate baseUrl phải là HTTPS (trừ localhost cho dev) — ngăn MITM.
 * Threat T-09-04 Spoofing.
 */
export function validateHttpsBaseUrl(baseUrl: string): void {
  if (typeof baseUrl !== 'string' || baseUrl.trim() === '') {
    throw new Error('baseUrl rỗng — cần URL provider hợp lệ');
  }
  try {
    const url = new URL(baseUrl);
    const host = url.hostname.toLowerCase();
    // Allow localhost for dev; reject other http://
    const isLocalhost = host === 'localhost' || host === '127.0.0.1' || host === '::1';
    if (url.protocol !== 'https:' && !(url.protocol === 'http:' && isLocalhost)) {
      throw new Error(`baseUrl phải là HTTPS (got ${url.protocol}//${host})`);
    }
  } catch (err: unknown) {
    if (err instanceof Error && err.message.startsWith('baseUrl')) throw err;
    throw new Error(`baseUrl không hợp lệ: ${baseUrl}`);
  }
}

/**
 * Tạo HttpClient mặc định wrap Node `fetch` + timeout 15s.
 */
export function createDefaultHttpClient(timeoutMs: number = DEFAULT_TIMEOUT_MS): HttpClient {
  return {
    async post<T = unknown>(
      url: string,
      body: Record<string, unknown>,
      headers: Record<string, string> = {},
    ): Promise<T> {
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), timeoutMs);

      try {
        const res = await fetch(url, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Accept: 'application/json',
            ...headers,
          },
          body: JSON.stringify(body),
          signal: controller.signal,
        });

        // Parse response body trước khi check status — provider thường trả JSON error body
        const text = await res.text();
        let parsed: unknown = null;
        try {
          parsed = text ? JSON.parse(text) : {};
        } catch {
          // Non-JSON response — wrap thành error
          throw new Error(
            `HTTP ${res.status}: phản hồi không phải JSON (${text.slice(0, 100)})`,
          );
        }

        if (!res.ok) {
          // Với 401/403/500 → throw có status để caller phân loại
          const errMsg =
            (parsed as { message?: string } | null)?.message ??
            `HTTP ${res.status} ${res.statusText}`;
          throw new Error(errMsg);
        }

        return parsed as T;
      } finally {
        clearTimeout(timer);
      }
    },
  };
}
