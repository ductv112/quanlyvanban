// ============================================================
// LGSP Auth -- Phase 37.3 (2026-05-22) shared module cho workers
//
// LGSP truc Lang Son yeu cau Authorization: Bearer <token> trong moi API call per-DN
// (ngoai X-SystemId + X-SecretKey). Token lay tu /v1/auth/login admin endpoint, cached
// in-memory per environment + baseUrl combo.
//
// Per-env admin credentials read tu env vars:
//   sandbox: LGSP_SANDBOX_USERNAME / LGSP_SANDBOX_PASSWORD / LGSP_SANDBOX_APPLICATION_CODE
//   prod:    LGSP_PROD_USERNAME    / LGSP_PROD_PASSWORD    / LGSP_PROD_APPLICATION_CODE
//   legacy:  LGSP_USERNAME / LGSP_PASSWORD / LGSP_APPLICATION_CODE (fallback)
// ============================================================
import pino from 'pino';

const logger = pino({ name: 'lgsp-auth' });

const TOKEN_TTL_MS = 29 * 60 * 1000; // 29 phut (LGSP token expire 30')

interface CacheEntry {
  token: string;
  expiresAt: number;
}

// Cache keyed by `${baseUrl}::${environment}` so sandbox + prod hold separate tokens.
const tokenCache = new Map<string, CacheEntry>();

// In-flight login promise dedup (Phase 37.4 fix): khi nhieu worker concurrent
// can token cung cacheKey, chi 1 login HTTP duoc fire, cac call khac await chung Promise.
// Tranh LGSP IdP rate-limit khi 5 worker fire login dong thoi luc token expire.
const inflightLogins = new Map<string, Promise<string>>();

interface LoginResponse {
  code?: number | string;
  success?: boolean;
  message?: string;
  token?: string;
  data?: { token?: string };
}

/**
 * Lay Bearer token cho admin user theo environment. Cached 29 phut, auto-refresh khi het han.
 *
 * @param baseUrl LGSP endpoint base URL (vd: https://apiltvb.langson.gov.vn)
 * @param environment 'sandbox' | 'prod' - de chon dung env vars LGSP_SANDBOX_* / LGSP_PROD_*
 * @returns JWT token (PASS vao Authorization: Bearer header)
 * @throws Error neu env vars missing hoac login fail
 */
export async function getLgspAdminBearerToken(
  baseUrl: string,
  environment: 'sandbox' | 'prod',
): Promise<string> {
  const normalizedBaseUrl = baseUrl.replace(/\/$/, '');
  const cacheKey = `${normalizedBaseUrl}::${environment}`;

  // Hit cache neu chua het han
  const cached = tokenCache.get(cacheKey);
  if (cached && Date.now() < cached.expiresAt) {
    return cached.token;
  }

  // Dedup in-flight login: neu da co request login same cacheKey dang chay -> await chung Promise
  // Tranh thrashing LGSP IdP khi multiple worker concurrent expire cung luc
  const existing = inflightLogins.get(cacheKey);
  if (existing) {
    return existing;
  }

  const loginPromise = doLogin(cacheKey, normalizedBaseUrl, environment);
  inflightLogins.set(cacheKey, loginPromise);
  try {
    return await loginPromise;
  } finally {
    inflightLogins.delete(cacheKey);
  }
}

/**
 * Internal: thuc su goi LGSP /v1/auth/login + cache token. Tach ra de dedup wrapper goi.
 */
async function doLogin(
  cacheKey: string,
  normalizedBaseUrl: string,
  environment: 'sandbox' | 'prod',
): Promise<string> {
  // Read per-env admin credentials (fallback legacy)
  const envPrefix = environment === 'prod' ? 'LGSP_PROD' : 'LGSP_SANDBOX';
  const username = process.env[`${envPrefix}_USERNAME`] || process.env.LGSP_USERNAME;
  const password = process.env[`${envPrefix}_PASSWORD`] || process.env.LGSP_PASSWORD;
  const applicationCode =
    process.env[`${envPrefix}_APPLICATION_CODE`] || process.env.LGSP_APPLICATION_CODE;

  if (!username || !password || !applicationCode) {
    throw new Error(
      `LGSP admin credentials missing for env=${environment} ` +
        `(can set ${envPrefix}_USERNAME/PASSWORD/APPLICATION_CODE trong backend/.env)`,
    );
  }

  // Login -- /v1/auth/login?allow_anonymous=true (Phase 37.3 authoritative endpoint)
  const loginUrl = `${normalizedBaseUrl}/v1/auth/login?allow_anonymous=true`;
  const body = JSON.stringify({
    username,
    password,
    applicationCode,
    otp: null,
    twoFactorProvider: null,
    typeObjs: [0, 1],
  });

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 30_000);
  try {
    const res = await fetch(loginUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
      body,
      signal: controller.signal,
    });
    const text = await res.text();
    if (!res.ok) {
      throw new Error(`LGSP login HTTP ${res.status}: ${text.slice(0, 300)}`);
    }
    let json: LoginResponse;
    try {
      json = JSON.parse(text);
    } catch {
      throw new Error(`LGSP login non-JSON response: ${text.slice(0, 200)}`);
    }
    // Phase 37.3: token nested in res.data.token (authoritative). Fallback res.token (legacy).
    const token = json.data?.token || json.token;
    if (!token) {
      throw new Error(
        `LGSP login failed: ${json.message || 'no token in response'} (code=${json.code ?? 'n/a'})`,
      );
    }

    tokenCache.set(cacheKey, {
      token,
      expiresAt: Date.now() + TOKEN_TTL_MS,
    });
    logger.info({ env: environment, baseUrl: normalizedBaseUrl, tokenLen: token.length }, 'LGSP login OK');
    return token;
  } finally {
    clearTimeout(timer);
  }
}

/** Clear cache (test only, or khi admin reset credential trong env). */
export function clearLgspTokenCache(): void {
  tokenCache.clear();
}

/**
 * Phase 37.4 fix: clear cache cho 1 cacheKey cu the (khi HTTP 401 detected).
 * Service goi function nay roi retry 1 lan voi token moi truoc khi throw lon hon.
 */
export function clearLgspTokenForKey(
  baseUrl: string,
  environment: 'sandbox' | 'prod',
): void {
  const normalizedBaseUrl = baseUrl.replace(/\/$/, '');
  const cacheKey = `${normalizedBaseUrl}::${environment}`;
  tokenCache.delete(cacheKey);
  inflightLogins.delete(cacheKey);
}
