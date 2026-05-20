// ============================================================
// LGSP Service Interface + Factory
//
// Phase 18 v3.0: MOCK_EXTERNAL=true env flag controls mock vs real (backward compat)
// Phase 33: thêm `getLgspService(unit_id, environment)` lookup credential per-unit
//           + LRU-style cache (Map + TTL) + invalidate(unit_id) cho admin update
// ============================================================

import { lgspAgencyConfigRepository } from '../repositories/lgsp-agency-config.repository.js';
import { decryptSecret } from './signing/crypto.js';

export interface LgspReceivedDoc {
  lgsp_doc_id: string;
  doc_code: string;
  doc_abstract: string;
  sender_org_code: string;
  sender_org_name: string;
  edxml_content: string;
  attachments: { file_name: string; file_content: string }[];
}

export interface LgspSendResult {
  success: boolean;
  lgsp_doc_id: string;
  message: string;
  /**
   * Phase 34: ma errorCode tu LGSP response.data.errorCode (9 ma: 0/10/15/18/19/20/21/22/23).
   * Worker (Plan 34-02) dung de classify retry vs no-retry per CONTEXT D-11
   * (qua isLgspNonRetryableError trong ./lgsp/error-codes.js).
   * `'0'` = success; undefined = chua co code (luc network/timeout truoc khi nhan response).
   */
  errorCode?: string;
}

export interface LgspOrganization {
  org_code: string;
  org_name: string;
  parent_code: string | null;
  address: string | null;
  email: string | null;
  phone: string | null;
}

export interface ILgspService {
  getToken(): Promise<string>;
  receiveDocuments(): Promise<LgspReceivedDoc[]>;
  /**
   * Phase 34: signature doi tu (string, string) -> (Buffer, string, string).
   *
   * @param edxmlBuffer Buffer chua edXML envelope (built tu services/lgsp/edxml-builder.ts)
   * @param destOrgCode Code don vi nhan (cho log only - LGSP parse tu edXML MessageHeader.To)
   * @param docCode Notation/document_code (lam filename trong multipart .edxml)
   */
  sendDocument(
    edxmlBuffer: Buffer,
    destOrgCode: string,
    docCode: string,
  ): Promise<LgspSendResult>;
  syncOrganizations(): Promise<LgspOrganization[]>;
}

// ============================================================================
// Phase 33: Per-unit cache + invalidate (D-02 invalidate-on-write strategy)
// ============================================================================

const CACHE_TTL_MS = 5 * 60 * 1000; // 5 phút (D-02 safety net)

interface CacheEntry {
  service: ILgspService;
  cachedAt: number;
}

/**
 * Cache key = `${unit_id}:${environment}`. Map giữ instance LGSPRealService per (unit, env).
 *
 * Phase 33 dùng inline Map (CONTEXT D-02 — chọn Map giảm dependency, chưa cần lru-cache).
 * Khi scale ra cluster sẽ chuyển sang Redis pub/sub (defer v3.3+).
 */
const cache = new Map<string, CacheEntry>();

function cacheKey(unitId: number, environment: 'sandbox' | 'prod'): string {
  return `${unitId}:${environment}`;
}

/**
 * Invalidate cache entry cho 1 unit. Admin UI Phase 37 gọi sau khi update credential.
 *
 * @param unitId Root unit id
 * @param environment Optional — undefined = invalidate cả prod + sandbox
 */
export function invalidateLgspServiceCache(
  unitId: number,
  environment?: 'sandbox' | 'prod',
): void {
  if (environment) {
    cache.delete(cacheKey(unitId, environment));
    return;
  }
  // Invalidate cả 2 env cho unit này
  cache.delete(cacheKey(unitId, 'prod'));
  cache.delete(cacheKey(unitId, 'sandbox'));
}

/**
 * Clear toàn bộ cache (dùng cho test reset hoặc admin "Clear all cache" button).
 */
export function clearLgspServiceCache(): void {
  cache.clear();
}

/**
 * Phase 33: Lookup LGSP service cho 1 unit cụ thể.
 *
 * Flow:
 *   1. Check cache → hit + chưa expire → return cached instance
 *   2. Lookup `lgsp_agency_config` qua repo
 *   3. Validate is_active=TRUE (throw nếu false)
 *   4. Decrypt secret_key_encrypted
 *   5. Reject placeholder secret (seed default)
 *   6. Instantiate LGSPRealService với credentials
 *   7. Cache instance + return
 *
 * @throws Error nếu unit không có config, hoặc is_active=FALSE, hoặc decrypt fail, hoặc placeholder
 */
async function getLgspServiceForUnit(
  unitId: number,
  environment: 'sandbox' | 'prod',
): Promise<ILgspService> {
  // 1. Check cache
  const key = cacheKey(unitId, environment);
  const entry = cache.get(key);
  if (entry && Date.now() - entry.cachedAt < CACHE_TTL_MS) {
    return entry.service;
  }
  // Expired → xóa luôn (defensive)
  if (entry) cache.delete(key);

  // 2. Lookup config
  const config = await lgspAgencyConfigRepository.getByUnitId(unitId, environment);
  if (!config) {
    throw new Error(
      `LGSP not configured for unit_id=${unitId} environment=${environment}. ` +
        `Admin can vao chuc nang /quan-tri/lgsp-config de cau hinh.`,
    );
  }

  // 3. Validate active
  if (!config.is_active) {
    throw new Error(
      `LGSP configured but disabled for unit_id=${unitId} environment=${environment}. ` +
        `Admin can bat is_active qua /quan-tri/lgsp-config sau khi nhap credential that.`,
    );
  }

  // 4. Decrypt secret
  let plaintextSecret: string;
  try {
    plaintextSecret = await decryptSecret(config.secret_key_encrypted);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    throw new Error(
      `Khong the decrypt LGSP secret cho unit_id=${unitId}: ${msg}. ` +
        `Kiem tra SIGNING_SECRET_KEY trong backend/.env co match khi seed/admin nhap credential khong.`,
    );
  }

  // 5. Reject placeholder secret (seed Plan 33-02 default)
  if (plaintextSecret === 'placeholder_not_configured' || plaintextSecret === '') {
    throw new Error(
      `LGSP secret la placeholder cho unit_id=${unitId}. ` +
        `Admin can nhap credential that qua /quan-tri/lgsp-config truoc khi gui/nhan VB.`,
    );
  }

  // 6. Instantiate per-unit instance (lazy import tránh circular dep)
  const { createLgspRealService } = await import('./lgsp-real.service.js');
  const service = createLgspRealService({
    baseUrl: config.base_url,
    systemId: config.system_id,
    secretKey: plaintextSecret,
  });

  // 7. Cache + return
  cache.set(key, { service, cachedAt: Date.now() });
  return service;
}

/**
 * Factory chính.
 *
 * 3 modes:
 *   - `getLgspService(unitId, environment)` → per-unit lookup + cache (Phase 33+)
 *   - `getLgspService(unitId)` → defaults environment='prod' (Phase 33+)
 *   - `getLgspService()` → backward compat Phase 18 (MOCK_EXTERNAL flag → mock vs real env)
 *
 * @param unitId Optional — nếu undefined fallback Phase 18 behavior
 * @param environment Default 'prod'
 */
export async function getLgspService(
  unitId?: number,
  environment: 'sandbox' | 'prod' = 'prod',
): Promise<ILgspService> {
  // Phase 33: per-unit mode
  if (typeof unitId === 'number') {
    return getLgspServiceForUnit(unitId, environment);
  }

  // Phase 18 backward compat
  if (process.env.MOCK_EXTERNAL === 'true' || !process.env.LGSP_ENDPOINT) {
    const mod = await import('./lgsp-mock.service.js');
    return mod.lgspMockService;
  }
  const mod = await import('./lgsp-real.service.js');
  return mod.lgspRealService;
}
