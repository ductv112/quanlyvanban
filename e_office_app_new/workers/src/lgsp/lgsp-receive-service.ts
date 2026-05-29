// ============================================================
// LGSP Receive Service — worker-context HTTP client - Phase 35 Plan 35-02
// REQ: LGSP-RECV-02, LGSP-RECV-03
// Mirror: workers/src/lgsp/lgsp-send-service.ts (Phase 34 Approach B)
// - Inline pg pgp_sym_decrypt for credential load (no backend imports)
// - Native fetch + AbortController + X-SystemId/X-SecretKey headers
// - Per-attempt fresh credential load (CONTEXT D-14)
// ============================================================
import type { Pool } from 'pg';
import pino from 'pino';
import { getLgspAdminBearerToken, clearLgspTokenForKey } from './lgsp-auth.js';

const logger = pino({ name: 'lgsp-receive-service' });

export interface WorkerLgspCredentials {
  baseUrl: string;
  systemId: string;
  secretKey: string;
  environment: 'sandbox' | 'prod';  // Phase 37.3: pick admin Bearer token per env
  lastSyncedAt: string | null;
}

export interface LgspReceivedSummary {
  lgsp_doc_id: string;
  from_org_code: string;
  to_org_code: string;
  status: string;
  status_desc: string;
  created_time: string;
  updated_time: string;
}

export interface LgspReceivedFullAttachment {
  file_name: string;
  file_content_base64: string;
}

export interface LgspReceivedFull {
  lgsp_doc_id: string;
  sender_org_code: string;
  sender_org_name: string;
  edoc_code: string;
  edoc_abstract: string;
  edxml: string;
  attachments: LgspReceivedFullAttachment[];
}

/**
 * Load LGSP credential for a single (unit_id, environment) row. Always reads fresh from DB
 * (per CONTEXT D-14 — credential rotation pickup without restart).
 *
 * Throws if row not found or is_active=false (caller's job to surface as no-op).
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
    last_synced_at: string | null;
  }>(
    `SELECT system_id,
            base_url,
            pgp_sym_decrypt(secret_key_encrypted, $3)::text AS secret_key,
            last_synced_at
       FROM edoc.lgsp_agency_config
      WHERE unit_id = $1
        AND environment = $2
        AND is_active = TRUE
      LIMIT 1`,
    [unitId, environment, signingSecretKey],
  );
  if (rs.rowCount === 0) {
    throw new Error(`LGSP credential not found or inactive: unit_id=${unitId}, env=${environment}`);
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
    lastSyncedAt: row.last_synced_at,
  };
}

/** Format Date to YYYY/MM/DD (LGSP-required per CONTEXT D-10). */
export function formatLgspDate(d: Date): string {
  const y = d.getUTCFullYear();
  const m = String(d.getUTCMonth() + 1).padStart(2, '0');
  const day = String(d.getUTCDate()).padStart(2, '0');
  return `${y}/${m}/${day}`;
}

/**
 * GET /v1/syncReceivedEdocList — returns summaries of received docs for the calling DN
 * in the given date window. fromDate / toDate are 'YYYY/MM/DD' strings.
 *
 * Caller (DN worker) computes fromDate = COALESCE(lastSyncedAt, NOW-7d), toDate = NOW.
 */
export async function syncReceivedList(
  credentials: WorkerLgspCredentials,
  fromDateYmd: string,
  toDateYmd: string,
  timeoutMs = 30_000,
): Promise<LgspReceivedSummary[]> {
  const url =
    `${credentials.baseUrl}/v1/syncReceivedEdocList` +
    `?messageType=edoc&fromDate=${encodeURIComponent(fromDateYmd)}` +
    `&toDate=${encodeURIComponent(toDateYmd)}`;
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
        method: 'GET',
        headers: {
          Authorization: `Bearer ${bearerToken}`,
          'X-SystemId': credentials.systemId,
          'X-SecretKey': credentials.secretKey,
          Accept: 'application/json',
        },
        signal: controller.signal,
      });
      if (res.status === 401 && attempt < maxAttempts) {
        clearLgspTokenForKey(credentials.baseUrl, credentials.environment);
        logger.warn(
          { url, env: credentials.environment, attempt },
          'LGSP /v1/syncReceivedEdocList HTTP 401 - clear cache + retry',
        );
        continue;
      }
      const text = await res.text();
      if (!res.ok) {
        throw new Error(
          `LGSP /v1/syncReceivedEdocList HTTP ${res.status}: ${text.slice(0, 300)}`,
        );
      }
      let json: {
        code?: number;
        message?: string;
        count?: number;
        data?: any[];
        success?: boolean;
        errorDetail?: Array<{ exception?: string }>;
      };
      try {
        json = JSON.parse(text);
      } catch {
        throw new Error(
          `LGSP /v1/syncReceivedEdocList non-JSON response: ${text.slice(0, 200)}`,
        );
      }
      // Phase 37.7: parse real LGSP response shape (KHONG dung json.success)
      const hasErrorDetail = Array.isArray(json.errorDetail) && json.errorDetail.length > 0;
      const isSuccess =
        res.status === 200 &&
        (json.code === 200 || json.code === 0) &&
        !hasErrorDetail;
      if (!isSuccess || !Array.isArray(json.data)) {
        logger.warn(
          { from: fromDateYmd, to: toDateYmd, jsonCode: json.code, message: json.message, rawBody: text.slice(0, 300) },
          'LGSP syncReceivedEdocList: not success or empty data',
        );
        return [];
      }
      return json.data.map((d: any) => ({
        lgsp_doc_id: String(d.docId ?? ''),
        from_org_code: String(d.from ?? ''),
        to_org_code: String(d.to ?? ''),
        status: String(d.status ?? ''),
        status_desc: String(d.statusDesc ?? ''),
        created_time: String(d.createdTime ?? ''),
        updated_time: String(d.updatedTime ?? ''),
      }));
    } finally {
      clearTimeout(timer);
    }
  }
}

/**
 * GET /v1/getEdoc?docId=<uuid> — returns full edXML + base64 attachments for one doc.
 * Returns null when LGSP reports success=false or data missing (doc may have been recalled).
 */
export async function getEdocFull(
  credentials: WorkerLgspCredentials,
  lgspDocId: string,
  timeoutMs = 60_000,
): Promise<LgspReceivedFull | null> {
  const url = `${credentials.baseUrl}/v1/getEdoc?docId=${encodeURIComponent(lgspDocId)}`;
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
        method: 'GET',
        headers: {
          Authorization: `Bearer ${bearerToken}`,
          'X-SystemId': credentials.systemId,
          'X-SecretKey': credentials.secretKey,
          Accept: 'application/json',
        },
        signal: controller.signal,
      });
      if (res.status === 401 && attempt < maxAttempts) {
        clearLgspTokenForKey(credentials.baseUrl, credentials.environment);
        logger.warn(
          { lgspDocId, env: credentials.environment, attempt },
          'LGSP /v1/getEdoc HTTP 401 - clear cache + retry',
        );
        continue;
      }
      const text = await res.text();
      if (!res.ok) {
        throw new Error(
          `LGSP /v1/getEdoc HTTP ${res.status} for docId=${lgspDocId}: ${text.slice(0, 300)}`,
        );
      }
      let json: {
        code?: number;
        message?: string;
        data?: any;
        success?: boolean;
        errorDetail?: Array<{ exception?: string }>;
      };
      try {
        json = JSON.parse(text);
      } catch {
        throw new Error(
          `LGSP /v1/getEdoc non-JSON response for docId=${lgspDocId}: ${text.slice(0, 200)}`,
        );
      }
      // Phase 37.7: parse real LGSP response shape (KHONG dung json.success)
      const hasErrorDetail = Array.isArray(json.errorDetail) && json.errorDetail.length > 0;
      const isSuccess =
        res.status === 200 &&
        (json.code === 200 || json.code === 0) &&
        !hasErrorDetail;
      if (!isSuccess || !json.data) {
        logger.warn(
          { lgspDocId, jsonCode: json.code, message: json.message, rawBody: text.slice(0, 300) },
          'LGSP /v1/getEdoc: not success or missing data',
        );
        return null;
      }
      const d = json.data;
      // Phase 37.10: real LGSP response shape — KHONG co d.edxml/d.attachments rieng.
      // Server tra ve d.data = base64 cua TOAN BO edXML envelope (gom <AttachmentEncoded>).
      // Worker phai decode base64 -> raw XML string. parseEdxml downstream se extract
      // attachments tu <AttachmentEncoded> section trong cung XML.
      const dataBase64 = String(d.data ?? d.edxml ?? '');
      let edxmlString = '';
      if (dataBase64) {
        try {
          edxmlString = Buffer.from(dataBase64, 'base64').toString('utf8');
        } catch (decodeErr) {
          logger.warn(
            { lgspDocId, err: (decodeErr as Error).message },
            'LGSP /v1/getEdoc: failed to decode base64 data.data',
          );
        }
      }
      return {
        lgsp_doc_id: String(d.docId ?? lgspDocId),
        sender_org_code: String(d.from ?? ''),
        sender_org_name: String(d.fromName ?? ''),
        edoc_code: String(d.edocCode ?? ''),
        edoc_abstract: String(d.edocAbstract ?? ''),
        edxml: edxmlString,
        // Attachments duoc extract trong parseEdxml downstream tu <AttachmentEncoded> section.
        attachments: [],
      };
    } finally {
      clearTimeout(timer);
    }
  }
}
