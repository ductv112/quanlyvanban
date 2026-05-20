// ============================================================
// LGSP Receive DN Worker - Phase 35 Plan 35-02
// REQ: LGSP-RECV-02..07
// CONTEXT D-06 (field mapping), D-07 (MinIO 'lgsp/<docId>/<fileName>' + 50MB skip),
//         D-08 (auto-register sender), D-09 (dedup catch SQLSTATE 23505),
//         D-10 (last_synced_at resume), D-11 (per-attempt error handling),
//         D-12 (outbox status='01' INSERT — Phase 36 consumes)
//
// Handler: 1 DN end-to-end sync.
//   1. loadLgspCredentials (fresh per attempt — D-14)
//   2. Compute fromDate = COALESCE(last_synced_at, NOW-7d) -> YYYY/MM/DD
//   3. GET /v1/syncReceivedEdocList
//   4. For each docId NOT yet in DB:
//        a. GET /v1/getEdoc (full payload)
//        b. parseEdxml(payload.edxml)
//        c. autoRegisterSender(From.OrganId, From.OrganName)
//        d. INSERT incoming_docs via fn_incoming_doc_create (source_type='external_lgsp')
//           — on SQLSTATE 23505 (duplicate) skip + log INFO (do NOT throw)
//        e. For each attachment: decode base64 -> MinIO put -> INSERT attachments row
//           — skip if >50MB + log WARN
//        f. INSERT lgsp_status_outbox row target_status='01' sent_status='pending'
//   5. SUCCESS -> UPDATE lgsp_agency_config.last_synced_at=NOW(), last_sync_error=NULL
//   6. FAIL -> UPDATE lgsp_agency_config.last_sync_error=<truncated message>;
//            DO NOT update last_synced_at; THROW for BullMQ retry (3 attempts exp 30s).
// ============================================================
import { Worker, Job } from 'bullmq';
import IORedis from 'ioredis';
import pg from 'pg';
import { Client as MinioClient } from 'minio';
import pino from 'pino';
import {
  LGSP_RECEIVE_QUEUE_NAME,
  LGSP_RECEIVE_DN_JOB_NAME,
  LGSP_RECEIVE_DN_CONCURRENCY,
  LGSP_RECEIVE_DN_MAX_ATTEMPTS,
  type LgspReceiveDnJobData,
} from '../queues/lgsp-receive-queue.js';
import {
  loadLgspCredentials,
  syncReceivedList,
  getEdocFull,
  formatLgspDate,
  type LgspReceivedFull,
} from '../lgsp/lgsp-receive-service.js';
import { parseEdxml, type ParsedEdxml } from '../lgsp/edxml-parser.js';

const { Pool } = pg;
const logger = pino({ name: 'lgsp-receive-dn-worker' });

const MAX_ATTACHMENT_BYTES = 50 * 1024 * 1024; // 50MB cap (CONTEXT D-07 + LGSP spec)
const MINIO_BUCKET = process.env.MINIO_BUCKET || 'documents';
const SYSTEM_STAFF_ID = 1; // TODO Phase 37: dedicated lgsp-system staff user

let connection: IORedis | null = null;
let pool: pg.Pool | null = null;
let minioClient: MinioClient | null = null;

function getConnection(): IORedis {
  if (!connection) {
    connection = new IORedis({
      host: process.env.REDIS_HOST || 'localhost',
      port: Number(process.env.REDIS_PORT) || 6379,
      password: process.env.REDIS_PASSWORD,
      maxRetriesPerRequest: null,
    });
  }
  return connection;
}

function getPool(): pg.Pool {
  if (!pool) {
    pool = new Pool({
      host: process.env.PG_HOST || 'localhost',
      port: Number(process.env.PG_PORT) || 5432,
      database: process.env.PG_DATABASE || 'qlvb_dev',
      user: process.env.PG_USER || 'qlvb_admin',
      password: process.env.PG_PASSWORD,
      max: 5,
      idleTimeoutMillis: 30000,
    });
  }
  return pool;
}

function getMinio(): MinioClient {
  if (!minioClient) {
    minioClient = new MinioClient({
      endPoint: process.env.MINIO_ENDPOINT || 'localhost',
      port: Number(process.env.MINIO_PORT) || 9000,
      useSSL: process.env.MINIO_USE_SSL === 'true',
      accessKey: process.env.MINIO_ACCESS_KEY || 'minioadmin',
      secretKey: process.env.MINIO_SECRET_KEY || 'minioadmin',
    });
  }
  return minioClient;
}

// ============================================================
// SQL helpers
// ============================================================

async function findExistingByLgspDocId(p: pg.Pool, lgspDocId: string): Promise<number | null> {
  const rs = await p.query<{ id: string }>(
    `SELECT id FROM edoc.incoming_docs
      WHERE external_doc_id = $1 AND source_type = 'external_lgsp'
      LIMIT 1`,
    [lgspDocId.slice(0, 200)],
  );
  return rs.rowCount ? Number(rs.rows[0].id) : null;
}

async function autoRegisterSender(p: pg.Pool, code: string, name: string): Promise<number> {
  const trimmedCode = code.slice(0, 100);
  const trimmedName = (name || code).slice(0, 500);
  const inserted = await p.query<{ id: string }>(
    `INSERT INTO edoc.inter_organizations (code, name, lgsp_organ_id, is_active, created_at, updated_at)
     VALUES ($1, $2, $1, FALSE, NOW(), NOW())
     ON CONFLICT (code) DO NOTHING RETURNING id`,
    [trimmedCode, trimmedName],
  );
  if (inserted.rowCount) {
    logger.info({ code: trimmedCode, name: trimmedName }, 'Auto-registered new external org from LGSP');
    return Number(inserted.rows[0].id);
  }
  const existing = await p.query<{ id: string }>(
    `SELECT id FROM edoc.inter_organizations WHERE code = $1 LIMIT 1`,
    [trimmedCode],
  );
  return Number(existing.rows[0].id);
}

interface IncomingDocInsertInput {
  unit_id: number;
  external_doc_id: string;
  lgsp_sender_org_code: string;
  publish_unit: string;
  notation: string;
  document_code: string;
  abstract: string;
  signer: string;
  sign_date: string | null;
  publish_date: string | null;
  number_paper: number;
  recipients_text: string;
}

interface IncomingDocInsertResult {
  inserted: boolean;
  skipped: boolean;
  id: number | null;
  message: string;
}

async function insertIncomingDoc(p: pg.Pool, x: IncomingDocInsertInput): Promise<IncomingDocInsertResult> {
  try {
    const rs = await p.query<{ success: boolean; message: string; id: string | null }>(
      `SELECT * FROM edoc.fn_incoming_doc_create(
         $1, $2::timestamptz, NULL::integer, $3, $4, $5, $6, $7::timestamptz, $8, $9::timestamptz,
         NULL::integer, NULL::integer, NULL::integer,
         1::smallint, 1::smallint, $10::integer, 1::integer,
         NULL::timestamptz, $11, NULL::text,
         FALSE::boolean, $12::integer, $1::integer,
         'external_lgsp'::edoc.doc_source_type, FALSE::boolean, $6,
         NULL::bigint, $13
       )`,
      [
        x.unit_id,                              // $1 p_unit_id + p_department_id
        new Date().toISOString(),               // $2 p_received_date NOW
        x.notation.slice(0, 50),                // $3
        x.document_code.slice(0, 100),          // $4
        x.abstract,                             // $5
        x.publish_unit.slice(0, 500),           // $6 publish_unit + p_unit_send (reuse)
        x.publish_date,                         // $7
        x.signer.slice(0, 200),                 // $8
        x.sign_date,                            // $9
        x.number_paper,                         // $10
        x.recipients_text.slice(0, 1000),       // $11
        SYSTEM_STAFF_ID,                        // $12 created_by
        x.external_doc_id.slice(0, 200),        // $13
      ],
    );
    const row = rs.rows[0];
    if (!row) return { inserted: false, skipped: false, id: null, message: 'SP returned no row' };
    if (row.success && row.id) {
      await p.query(
        `UPDATE edoc.incoming_docs SET lgsp_sender_org_code = $1 WHERE id = $2`,
        [x.lgsp_sender_org_code.slice(0, 13), row.id],
      );
      return { inserted: true, skipped: false, id: Number(row.id), message: row.message };
    }
    // Dedup detection (CONTEXT D-09)
    const m = (row.message || '').toLowerCase();
    if (
      m.includes('idx_incoming_docs_external_dedupe') ||
      m.includes('duplicate key') ||
      m.includes('unique constraint')
    ) {
      return { inserted: false, skipped: true, id: null, message: `dedup skipped: ${x.external_doc_id}` };
    }
    return { inserted: false, skipped: false, id: null, message: row.message };
  } catch (err: unknown) {
    // Direct pg error (rare — SP wraps most). 23505 = unique_violation.
    const e = err as { code?: string; message?: string };
    if (e?.code === '23505') {
      return { inserted: false, skipped: true, id: null, message: `dedup skipped (pg 23505): ${x.external_doc_id}` };
    }
    throw err;
  }
}

async function insertAttachmentRow(
  p: pg.Pool,
  params: { incoming_doc_id: number; file_name: string; file_path: string; file_size: number; content_type: string },
): Promise<number> {
  const rs = await p.query<{ id: string }>(
    `INSERT INTO edoc.attachments
       (incoming_doc_id, file_name, file_path, file_size, content_type, uploaded_by, created_at)
     VALUES ($1, $2, $3, $4, $5, $6, NOW())
     RETURNING id`,
    [
      params.incoming_doc_id,
      params.file_name.slice(0, 500),
      params.file_path.slice(0, 1000),
      params.file_size,
      (params.content_type || 'application/octet-stream').slice(0, 200),
      SYSTEM_STAFF_ID,
    ],
  );
  return Number(rs.rows[0].id);
}

async function insertOutboxStatus01(
  p: pg.Pool,
  incomingDocId: number,
  payload: Record<string, unknown>,
): Promise<void> {
  await p.query(
    `SELECT * FROM edoc.fn_lgsp_status_outbox_insert($1::bigint, $2::varchar, $3::jsonb)`,
    [incomingDocId, '01', JSON.stringify(payload)],
  );
}

async function updateLastSyncedSuccess(p: pg.Pool, unitId: number, env: 'sandbox' | 'prod'): Promise<void> {
  await p.query(
    `SELECT * FROM edoc.fn_lgsp_agency_config_update_last_synced($1::integer, $2::varchar, $3::timestamptz, NULL::text)`,
    [unitId, env, new Date().toISOString()],
  );
}

async function updateLastSyncError(p: pg.Pool, unitId: number, env: 'sandbox' | 'prod', errMsg: string): Promise<void> {
  try {
    await p.query(
      `UPDATE edoc.lgsp_agency_config
         SET last_sync_error = $3, updated_at = NOW()
       WHERE unit_id = $1 AND environment = $2`,
      [unitId, env, errMsg.slice(0, 1000)],
    );
  } catch (err) {
    logger.warn({ unitId, env, err: (err as Error).message }, 'Failed to write last_sync_error');
  }
}

// ============================================================
// MinIO upload helper
// ============================================================

async function uploadAttachmentToMinio(
  buffer: Buffer,
  objectKey: string,
  contentType: string,
): Promise<void> {
  const mc = getMinio();
  await mc.putObject(MINIO_BUCKET, objectKey, buffer, buffer.length, {
    'Content-Type': contentType || 'application/octet-stream',
  });
}

// ============================================================
// Mapping helper: ParsedEdxml + LgspReceivedFull -> IncomingDocInsertInput (CONTEXT D-06)
// ============================================================

function mapEdxmlToInsertInput(
  parsed: ParsedEdxml,
  docFull: LgspReceivedFull,
  unitId: number,
): IncomingDocInsertInput {
  const mh = parsed.messageHeader;
  const publishUnit = mh.from.organName || docFull.sender_org_name || mh.from.organId;
  const notation = mh.code.codeNumber || docFull.edoc_code || '';
  const documentCode = mh.code.codeNotation || docFull.edoc_code || '';
  const subject = mh.subject || docFull.edoc_abstract || '';
  const signer = mh.signerInfo.signer || '';
  const signDate = mh.promulgationInfo.promulgationDate || null;
  const numberPaper =
    mh.otherInfo.pageAmount && Number.isFinite(mh.otherInfo.pageAmount)
      ? Math.max(1, mh.otherInfo.pageAmount)
      : 1;
  const recipientsText = `${mh.from.organName || mh.from.organId} -> ${mh.to.organName || mh.to.organId}`;

  return {
    unit_id: unitId,
    external_doc_id: docFull.lgsp_doc_id,
    lgsp_sender_org_code: mh.from.organId || docFull.sender_org_code || '',
    publish_unit: publishUnit,
    notation,
    document_code: documentCode,
    abstract: subject,
    signer,
    sign_date: signDate,
    publish_date: signDate,
    number_paper: numberPaper,
    recipients_text: recipientsText,
  };
}

// ============================================================
// Main handler
// ============================================================

interface DnSyncResult {
  docs_seen: number;
  docs_inserted: number;
  docs_skipped: number;
  docs_failed: number;
  attachments_uploaded: number;
  attachments_skipped: number;
}

async function handleDnSync(job: Job<LgspReceiveDnJobData>): Promise<DnSyncResult> {
  const emptyResult: DnSyncResult = {
    docs_seen: 0,
    docs_inserted: 0,
    docs_skipped: 0,
    docs_failed: 0,
    attachments_uploaded: 0,
    attachments_skipped: 0,
  };

  if (job.name !== LGSP_RECEIVE_DN_JOB_NAME) {
    // Wrong job name for this worker — skip silently (tick worker handles its own).
    return emptyResult;
  }

  const { unit_id, environment } = job.data;
  const signingSecretKey = process.env.SIGNING_SECRET_KEY;
  if (!signingSecretKey) {
    throw new Error('SIGNING_SECRET_KEY env var not set — cannot decrypt LGSP credentials');
  }
  const p = getPool();
  const result: DnSyncResult = { ...emptyResult };

  let creds;
  try {
    creds = await loadLgspCredentials(p, unit_id, environment, signingSecretKey);
  } catch (err) {
    const msg = (err as Error).message;
    logger.warn({ unit_id, environment, err: msg }, 'LGSP credential not loadable — skipping DN');
    // Not an error to retry — config is genuinely missing. Mark + return.
    await updateLastSyncError(p, unit_id, environment, `credential not loadable: ${msg}`);
    return result;
  }

  // Compute date window: fromDate = last_synced_at OR NOW-7d. toDate = NOW.
  const now = new Date();
  const fallbackFrom = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
  const fromDate = creds.lastSyncedAt ? new Date(creds.lastSyncedAt) : fallbackFrom;
  // Guard: if last_synced_at is older than 7 days, still use NOW-7d (LGSP rejects wide windows)
  const effectiveFrom = fromDate < fallbackFrom ? fallbackFrom : fromDate;
  const fromYmd = formatLgspDate(effectiveFrom);
  const toYmd = formatLgspDate(now);

  logger.info({ unit_id, environment, fromYmd, toYmd }, 'LGSP DN sync: querying list');

  let summaries;
  try {
    summaries = await syncReceivedList(creds, fromYmd, toYmd);
  } catch (err) {
    const msg = `syncReceivedList failed: ${(err as Error).message}`;
    await updateLastSyncError(p, unit_id, environment, msg);
    throw new Error(msg); // BullMQ retry
  }
  result.docs_seen = summaries.length;
  logger.info({ unit_id, environment, count: summaries.length }, 'LGSP DN sync: got list');

  for (const sum of summaries) {
    try {
      // Pre-check: already in DB? (cheap; avoids redundant getEdoc fetch)
      const existingId = await findExistingByLgspDocId(p, sum.lgsp_doc_id);
      if (existingId) {
        result.docs_skipped += 1;
        continue;
      }

      // Fetch full edXML
      const full = await getEdocFull(creds, sum.lgsp_doc_id);
      if (!full) {
        logger.warn({ unit_id, lgspDocId: sum.lgsp_doc_id }, 'getEdoc returned null — skipping');
        result.docs_failed += 1;
        continue;
      }

      // Parse
      let parsed: ParsedEdxml;
      try {
        parsed = parseEdxml(full.edxml);
      } catch (err) {
        logger.warn(
          { unit_id, lgspDocId: sum.lgsp_doc_id, err: (err as Error).message },
          'parseEdxml failed — skipping doc',
        );
        result.docs_failed += 1;
        continue;
      }

      // Auto-register sender (D-08)
      await autoRegisterSender(
        p,
        parsed.messageHeader.from.organId || full.sender_org_code || sum.from_org_code,
        parsed.messageHeader.from.organName || full.sender_org_name || '',
      );

      // INSERT incoming_docs
      const insertInput = mapEdxmlToInsertInput(parsed, full, unit_id);
      const ins = await insertIncomingDoc(p, insertInput);
      if (ins.skipped) {
        result.docs_skipped += 1;
        logger.info({ unit_id, lgspDocId: sum.lgsp_doc_id }, ins.message);
        continue;
      }
      if (!ins.inserted || !ins.id) {
        logger.warn(
          { unit_id, lgspDocId: sum.lgsp_doc_id, msg: ins.message },
          'insertIncomingDoc failed — skipping',
        );
        result.docs_failed += 1;
        continue;
      }
      const newDocId = ins.id;

      // Attachments
      for (const att of parsed.attachments) {
        if (att.content.length > MAX_ATTACHMENT_BYTES) {
          result.attachments_skipped += 1;
          logger.warn(
            { unit_id, lgspDocId: sum.lgsp_doc_id, fileName: att.fileName, bytes: att.content.length },
            'Attachment exceeds 50MB — skipping (D-07)',
          );
          continue;
        }
        const objectKey = `lgsp/${sum.lgsp_doc_id}/${att.fileName}`;
        try {
          await uploadAttachmentToMinio(att.content, objectKey, att.mimeType ?? 'application/octet-stream');
          await insertAttachmentRow(p, {
            incoming_doc_id: newDocId,
            file_name: att.fileName,
            file_path: objectKey,
            file_size: att.content.length,
            content_type: att.mimeType ?? 'application/octet-stream',
          });
          result.attachments_uploaded += 1;
        } catch (err) {
          logger.warn(
            { unit_id, lgspDocId: sum.lgsp_doc_id, fileName: att.fileName, err: (err as Error).message },
            'Attachment upload/insert failed — skipping',
          );
          result.attachments_skipped += 1;
        }
      }

      // Outbox status '01' (Phase 36 worker consumes)
      try {
        await insertOutboxStatus01(p, newDocId, {
          lgsp_doc_id: sum.lgsp_doc_id,
          sender_org_code: parsed.messageHeader.from.organId,
          ack_received_at: new Date().toISOString(),
        });
      } catch (err) {
        logger.warn(
          { unit_id, lgspDocId: sum.lgsp_doc_id, err: (err as Error).message },
          'Outbox INSERT failed (status 01) — Phase 36 may not fire callback',
        );
      }

      result.docs_inserted += 1;
      logger.info(
        { unit_id, lgspDocId: sum.lgsp_doc_id, newDocId, attachments: parsed.attachments.length },
        'LGSP doc imported',
      );
    } catch (err) {
      // Per-doc error: log + continue (don't fail entire DN sync because of 1 bad doc)
      logger.error(
        { unit_id, lgspDocId: sum.lgsp_doc_id, err: (err as Error).message },
        'Doc processing failed (continuing with next)',
      );
      result.docs_failed += 1;
    }
  }

  // SUCCESS path: update last_synced_at + clear error (D-10 + D-11)
  try {
    await updateLastSyncedSuccess(p, unit_id, environment);
  } catch (err) {
    logger.warn(
      { unit_id, environment, err: (err as Error).message },
      'Failed to update last_synced_at',
    );
  }

  logger.info({ unit_id, environment, ...result }, 'LGSP DN sync complete');
  return result;
}

export function startLgspReceiveDnWorker(): Worker<LgspReceiveDnJobData> {
  const worker = new Worker<LgspReceiveDnJobData>(
    LGSP_RECEIVE_QUEUE_NAME,
    async (job) => handleDnSync(job),
    {
      connection: getConnection(),
      concurrency: LGSP_RECEIVE_DN_CONCURRENCY,
      autorun: true,
    },
  );

  worker.on('completed', (job, result) => {
    if (job.name === LGSP_RECEIVE_DN_JOB_NAME) {
      logger.info({ jobId: job.id, unit_id: job.data?.unit_id, result }, 'LGSP DN worker completed');
    }
  });

  worker.on('failed', async (job, err) => {
    if (!job || job.name !== LGSP_RECEIVE_DN_JOB_NAME) return;
    const attemptsMade = job.attemptsMade ?? 0;
    const maxAttempts = LGSP_RECEIVE_DN_MAX_ATTEMPTS;
    logger.warn(
      { jobId: job.id, unit_id: job.data?.unit_id, attemptsMade, maxAttempts, err: err?.message },
      'LGSP DN worker job failed',
    );
    // Final-failure path: also persist error to last_sync_error so admin sees it (Phase 37 UI)
    if (attemptsMade >= maxAttempts) {
      try {
        await updateLastSyncError(
          getPool(),
          job.data?.unit_id,
          job.data?.environment,
          `Retry exhausted (${attemptsMade}/${maxAttempts}): ${err?.message ?? 'unknown'}`,
        );
      } catch (e) {
        logger.warn({ err: (e as Error).message }, 'Failed to persist final retry exhausted error');
      }
    }
  });

  worker.on('error', (err) => {
    logger.error({ err: err.message }, 'LGSP receive DN worker error');
  });

  logger.info(
    {
      queue: LGSP_RECEIVE_QUEUE_NAME,
      concurrency: LGSP_RECEIVE_DN_CONCURRENCY,
      maxAttempts: LGSP_RECEIVE_DN_MAX_ATTEMPTS,
    },
    'LGSP receive DN worker started',
  );
  return worker;
}

export async function stopLgspReceiveDnWorker(worker: Worker<LgspReceiveDnJobData>): Promise<void> {
  try {
    await worker.close();
  } catch (err) {
    logger.warn({ err: (err as Error).message }, 'Error closing DN worker');
  }
  try {
    if (pool) {
      await pool.end();
      pool = null;
    }
  } catch (err) {
    logger.warn({ err: (err as Error).message }, 'Error closing DN pool');
  }
  try {
    if (connection) {
      connection.disconnect();
      connection = null;
    }
  } catch (err) {
    logger.warn({ err: (err as Error).message }, 'Error closing DN connection');
  }
}
