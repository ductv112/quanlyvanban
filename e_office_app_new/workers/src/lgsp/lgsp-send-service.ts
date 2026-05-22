// ============================================================
// LGSP Send Service for Worker (Phase 34 — APPROACH B self-contained)
//
// Combine: credential lookup (per-unit, per-environment) + sendDocument via /v1/sendEdoc.
//
// Duplicated logic from:
//   - backend/src/services/lgsp.service.ts (getLgspServiceForUnit factory)
//   - backend/src/services/lgsp-real.service.ts (sendDocument multipart)
//   - backend/src/repositories/lgsp-agency-config.repository.ts (getByUnitId)
//   - backend/src/services/signing/crypto.ts (decryptSecret)
//
// SIMPLIFIED for worker context:
//   - Decrypt qua pgcrypto pgp_sym_decrypt INLINE SQL (KHONG dung Node crypto layer)
//     because workers KHONG import 'jose' / 'pgcrypto' Node lib — chi rely vao DB pgp_sym_decrypt
//   - app.signing_secret_key SET per query (worker doc env SIGNING_SECRET_KEY)
//   - Per-attempt cache MISS (no in-memory cache) — CONTEXT D-14 says fresh per attempt
//     anyway, so worker khong can cache. Backend layer co cache cho route HTTP.
//
// KEEP IN SYNC voi backend services khi sua. Plan 34-05 audit checksum.
// ============================================================

import type { Pool } from 'pg';
import pino from 'pino';
import FormData from 'form-data';
import {
  LgspSendError,
  mapLgspError,
} from './error-codes.js';
import { getLgspAdminBearerToken, clearLgspTokenForKey } from './lgsp-auth.js';

const logger = pino({ name: 'lgsp-send-service-worker' });

export interface LgspSendResult {
  success: boolean;
  lgsp_doc_id: string;
  message: string;
  /** Ma 9 ErrorCode LGSP (0/10/15/18/19/20/21/22/23). undefined neu network/timeout. */
  errorCode?: string;
}

interface SendEdocResponse {
  success: boolean;
  message: string;
  docId?: string;
  data?: {
    docId?: string | null;
    status?: string;
    errorCode?: string;
    errorDesc?: string;
  };
}

interface LgspCredentialsRow {
  base_url: string;
  system_id: string;
  /** Plaintext sau khi pgp_sym_decrypt — KHONG log. */
  secret_key_plain: string;
  is_active: boolean;
}

/**
 * Lookup LGSP credential cho unit + environment, decrypt secret_key qua pgp_sym_decrypt.
 *
 * @param pool pg Pool (worker module-level singleton)
 * @param unitId Root unit_id (departments.id)
 * @param environment 'sandbox' | 'prod'
 * @param signingSecretKey process.env.SIGNING_SECRET_KEY (decrypt key)
 * @throws Error neu khong tim thay config, is_active=false, decrypt fail, hoac placeholder secret
 */
export async function loadLgspCredentials(
  pool: Pool,
  unitId: number,
  environment: 'sandbox' | 'prod',
  signingSecretKey: string,
): Promise<{ baseUrl: string; systemId: string; secretKey: string; environment: 'sandbox' | 'prod' }> {
  if (!signingSecretKey) {
    throw new Error(
      `SIGNING_SECRET_KEY env var missing — khong the decrypt LGSP credential cho unit_id=${unitId}`,
    );
  }

  // SET app.signing_secret_key for this query then SELECT with pgp_sym_decrypt INLINE.
  // KHONG dung 2 query rieng (pool tra ve connection khac nhau -> SET LOCAL co the lost).
  // pgcrypto pgp_sym_decrypt(bytea, text) tra ve bytea -> cast ::text.
  const res = await pool.query<LgspCredentialsRow>(
    `SELECT base_url,
            system_id,
            pgp_sym_decrypt(secret_key_encrypted, $3)::text AS secret_key_plain,
            is_active
       FROM edoc.lgsp_agency_config
      WHERE unit_id = $1 AND environment = $2`,
    [unitId, environment, signingSecretKey],
  );

  const row = res.rows[0];
  if (!row) {
    throw new Error(
      `LGSP not configured for unit_id=${unitId} environment=${environment}. ` +
        `Admin can cau hinh qua /quan-tri/lgsp-config.`,
    );
  }
  if (!row.is_active) {
    throw new Error(
      `LGSP configured but disabled for unit_id=${unitId} environment=${environment}. ` +
        `Admin can bat is_active qua /quan-tri/lgsp-config sau khi nhap credential that.`,
    );
  }
  if (
    row.secret_key_plain === 'placeholder_not_configured' ||
    row.secret_key_plain === ''
  ) {
    throw new Error(
      `LGSP secret la placeholder cho unit_id=${unitId}. ` +
        `Admin can nhap credential that qua /quan-tri/lgsp-config truoc khi gui VB.`,
    );
  }

  return {
    baseUrl: row.base_url,
    systemId: row.system_id,
    secretKey: row.secret_key_plain,
    environment,
  };
}

/**
 * Send edXML doc qua LGSP /v1/sendEdoc multipart/form-data.
 *
 * Headers: X-SystemId, X-SecretKey.
 * Body: multipart with `edocFile` (Buffer) + `messageType=edoc`.
 *
 * Response shape:
 *   Success: { success: true, message: 'OK', docId: '<uuid>' }
 *   Error:   { success: false, message: '...', data: { docId, status, errorCode, errorDesc } }
 *
 * @returns LgspSendResult — caller (worker) classify errorCode for retry/no-retry per D-11
 * @throws LgspSendError neu network/timeout/non-JSON (worker rethrow -> BullMQ retry)
 */
export async function sendDocument(
  credentials: { baseUrl: string; systemId: string; secretKey: string; environment: 'sandbox' | 'prod' },
  edxmlBuffer: Buffer,
  destOrgCode: string,
  docCode: string,
): Promise<LgspSendResult> {
  const endpoint = credentials.baseUrl.replace(/\/$/, '');

  if (!credentials.systemId || !credentials.secretKey) {
    throw new LgspSendError(
      `LGSP credential missing: systemId=${credentials.systemId ? 'OK' : 'EMPTY'}, secretKey=${credentials.secretKey ? 'OK' : 'EMPTY'}`,
    );
  }

  const safeFilename =
    (docCode || 'edoc').replace(/[\\/:*?"<>|]/g, '_').slice(0, 100) + '.edxml';

  // Phase 37.4 fix: wrap fetch trong retry-on-401 (LGSP token co the rotate som
  // ngoai TTL 29 phut — clear cache + retry 1 lan voi token moi truoc khi throw)
  let attempt = 0;
  const maxAttempts = 2;
  while (true) {
    attempt++;
    const form = new FormData();
    form.append('edocFile', edxmlBuffer, {
      filename: safeFilename,
      contentType: 'application/xml',
      knownLength: edxmlBuffer.length,
    });
    form.append('messageType', 'edoc');
    const formBuffer = form.getBuffer();
    const formHeaders = form.getHeaders();

    const bearerToken = await getLgspAdminBearerToken(endpoint, credentials.environment);

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 60_000);
    try {
      const res = await fetch(`${endpoint}/v1/sendEdoc`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${bearerToken}`,
          'X-SystemId': credentials.systemId,
          'X-SecretKey': credentials.secretKey,
          ...formHeaders,
          'Content-Length': String(formBuffer.length),
        },
        body: formBuffer as unknown as BodyInit,
        signal: controller.signal,
      });

      // Phase 37.4: HTTP 401 -> clear token cache + retry 1 lan voi token moi
      if (res.status === 401 && attempt < maxAttempts) {
        clearLgspTokenForKey(endpoint, credentials.environment);
        logger.warn(
          { endpoint, env: credentials.environment, attempt },
          'LGSP /v1/sendEdoc HTTP 401 - clear cache + retry voi token moi',
        );
        continue;
      }

      const text = await res.text();
      let json: SendEdocResponse;
      try {
        json = JSON.parse(text) as SendEdocResponse;
      } catch {
        throw new LgspSendError(
          `LGSP /v1/sendEdoc HTTP ${res.status} non-JSON response: ${text.slice(0, 200)}`,
        );
      }

      const docId = json.docId || json.data?.docId || '';
      const errorCode = json.data?.errorCode;
      const rawMessage = json.message || json.data?.errorDesc || 'unknown';

      if (!json.success) {
        return {
          success: false,
          lgsp_doc_id: docId || '',
          message: mapLgspError(errorCode, rawMessage),
          errorCode: errorCode || undefined,
        };
      }

      logger.info(
        { docCode, destOrgCode, lgspDocId: docId, bytes: edxmlBuffer.length },
        'LGSP /v1/sendEdoc success',
      );
      return {
        success: true,
        lgsp_doc_id: docId || '',
        message: rawMessage,
        errorCode: errorCode || '0',
      };
    } catch (err: unknown) {
      if (err instanceof LgspSendError) throw err;
      const msg = err instanceof Error ? err.message : String(err);
      throw new LgspSendError(`LGSP /v1/sendEdoc network/timeout: ${msg}`);
    } finally {
      clearTimeout(timer);
    }
  }
}
