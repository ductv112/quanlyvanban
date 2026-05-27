// ============================================================
// LGSP Status Service — worker-context HTTP client - Phase 36 Plan 36-02
// REQ: LGSP-STATUS-09
// Mirror: workers/src/lgsp/lgsp-receive-service.ts (Phase 35-02 Approach B)
// - Inline pg pgp_sym_decrypt for credential load (no backend imports)
// - Inline SQL resolve doc owner unit + active environment
// - Native fetch + AbortController + X-SystemId/X-SecretKey headers
// - Per-attempt fresh credential load (CONTEXT D-14)
// ============================================================
import type { Pool } from 'pg';
import pino from 'pino';
import { LgspSendError, mapLgspError } from './error-codes.js';
import { getLgspAdminBearerToken, clearLgspTokenForKey } from './lgsp-auth.js';

const logger = pino({ name: 'lgsp-status-service' });

export interface WorkerLgspCredentials {
  baseUrl: string;
  systemId: string;
  secretKey: string;
  environment: 'sandbox' | 'prod';  // Phase 37.3: pick admin Bearer token per env
}

export interface ResolvedDocOwner {
  unit_id: number;
  environment: 'sandbox' | 'prod';
}

export interface LgspUpdateStatusResult {
  success: boolean;
  message: string;
  errorCode?: string;
}

/**
 * Resolve which DN owns `incoming_doc_id` + which active LGSP env to use.
 *
 * Prefer 'prod' env over 'sandbox' if both rows is_active=true (mirror Phase 34/35 prefer-prod).
 * Returns null if doc not found OR doc's unit has no active LGSP config (caller -> mark error).
 */
export async function resolveDocOwner(
  pool: Pool,
  incomingDocId: number,
): Promise<ResolvedDocOwner | null> {
  const rs = await pool.query<{ unit_id: string; environment: 'sandbox' | 'prod' }>(
    `SELECT d.unit_id, ac.environment
       FROM edoc.incoming_docs d
       JOIN edoc.lgsp_agency_config ac
         ON ac.unit_id = d.unit_id AND ac.is_active = TRUE
      WHERE d.id = $1
      ORDER BY CASE WHEN ac.environment = 'prod' THEN 0 ELSE 1 END
      LIMIT 1`,
    [incomingDocId],
  );
  if (rs.rowCount === 0) return null;
  return {
    unit_id: Number(rs.rows[0].unit_id),
    environment: rs.rows[0].environment,
  };
}

/**
 * Load LGSP credential for (unitId, environment). Always reads fresh from DB
 * (CONTEXT D-14 -- credential rotation pickup without restart).
 *
 * Throws if not found / inactive / placeholder.
 */
export async function loadLgspCredentials(
  pool: Pool,
  unitId: number,
  environment: 'sandbox' | 'prod',
  signingSecretKey: string,
): Promise<WorkerLgspCredentials> {
  if (!signingSecretKey) {
    throw new Error(
      `SIGNING_SECRET_KEY env var missing — khong the decrypt LGSP credential cho unit_id=${unitId}`,
    );
  }
  const rs = await pool.query<{
    system_id: string;
    base_url: string;
    secret_key: string;
  }>(
    `SELECT system_id,
            base_url,
            pgp_sym_decrypt(secret_key_encrypted, $3)::text AS secret_key
       FROM edoc.lgsp_agency_config
      WHERE unit_id = $1
        AND environment = $2
        AND is_active = TRUE
      LIMIT 1`,
    [unitId, environment, signingSecretKey],
  );
  if (rs.rowCount === 0) {
    throw new Error(
      `LGSP credential not found or inactive: unit_id=${unitId}, env=${environment}`,
    );
  }
  const row = rs.rows[0];
  if (!row.secret_key || row.secret_key === 'placeholder_not_configured') {
    throw new Error(
      `LGSP secret la placeholder cho unit_id=${unitId}. Admin can nhap credential that.`,
    );
  }
  return {
    baseUrl: row.base_url.replace(/\/$/, ''),
    systemId: row.system_id,
    secretKey: row.secret_key,
    environment,
  };
}

/**
 * POST /v1/updateStatus -- send 1 status callback to LGSP truc.
 *
 * AUTHORITATIVE shape (Postman 06.updateStatus):
 *   Body: { docId: string, status: string }
 *   Headers: Content-Type: application/json, X-SystemId, X-SecretKey
 *
 * Returns LgspUpdateStatusResult with errorCode populated when LGSP responds success=false.
 * Caller (event worker) classifies retry vs no-retry via isLgspNonRetryableError().
 *
 * Throws LgspSendError for network/timeout/non-JSON (retryable via BullMQ).
 */
export async function updateStatus(
  credentials: WorkerLgspCredentials,
  docId: string,
  status: string,
  timeoutMs = 30_000,
): Promise<LgspUpdateStatusResult> {
  const url = `${credentials.baseUrl}/v1/updateStatus`;
  const bodyJson = JSON.stringify({ docId, status });

  // Phase 37.4 fix: retry-on-401 (token rotation reactive)
  let attempt = 0;
  const maxAttempts = 2;
  while (true) {
    attempt++;
    const bearerToken = await getLgspAdminBearerToken(credentials.baseUrl, credentials.environment);
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    try {
      const res = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${bearerToken}`,
          'X-SystemId': credentials.systemId,
          'X-SecretKey': credentials.secretKey,
          Accept: 'application/json',
        },
        body: bodyJson,
        signal: controller.signal,
      });
      if (res.status === 401 && attempt < maxAttempts) {
        clearLgspTokenForKey(credentials.baseUrl, credentials.environment);
        logger.warn(
          { docId, status, env: credentials.environment, attempt },
          'LGSP /v1/updateStatus HTTP 401 - clear cache + retry',
        );
        continue;
      }
      const text = await res.text();
      let json: {
        code?: number;
        message?: string;
        data?: { status?: string; errorCode?: string; errorDesc?: string };
        success?: boolean;
        errorDetail?: Array<{ exception?: string }>;
      };
      try {
        json = JSON.parse(text);
      } catch {
        throw new LgspSendError(
          `LGSP /v1/updateStatus HTTP ${res.status} non-JSON: ${text.slice(0, 200)}`,
        );
      }

      const errorCode = json.data?.errorCode;
      const rawMessage = json.message || json.data?.errorDesc || 'unknown';

      // Phase 37.7: parse real LGSP response shape (KHONG dung json.success)
      const dataStatus = (json.data?.status || '').toUpperCase();
      const hasErrorDetail = Array.isArray(json.errorDetail) && json.errorDetail.length > 0;
      const isSuccess =
        res.status === 200 &&
        (json.code === 200 || json.code === 0) &&
        (dataStatus === '' || dataStatus === 'OK' || dataStatus === 'SUCCESS') &&
        !hasErrorDetail;

      if (!isSuccess) {
        return {
          success: false,
          message: mapLgspError(errorCode, rawMessage),
          errorCode: errorCode || undefined,
        };
      }
      return { success: true, message: rawMessage, errorCode: '0' };
    } catch (err: unknown) {
      if (err instanceof LgspSendError) throw err;
      const msg = err instanceof Error ? err.message : String(err);
      throw new LgspSendError(`LGSP /v1/updateStatus network/timeout: ${msg}`);
    } finally {
      clearTimeout(timer);
    }
  }
}
