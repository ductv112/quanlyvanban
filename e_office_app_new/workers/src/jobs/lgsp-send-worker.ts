// ============================================================
// LGSP Send Worker (Phase 34 — CONTEXT D-02, D-04, D-10, D-11, D-13, D-14, D-15)
//
// Consumer cho BullMQ queue 'lgsp-send' job 'send-edoc-recipient'.
// 1 job = 1 external recipient (granularity per-recipient — fail khong drag sibling).
//
// Flow per job attempt:
//   1. Load outgoing_doc + recipient + sender unit info + doc_type
//   2. Load attachments tu MinIO -> base64 (loi tung file -> skip + warn, KHONG fail toan bo)
//   3. buildEdxml() -> Buffer + destOrgCode + docCode
//   4. getLgspService(sender_unit_id, env) — fresh per attempt (CONTEXT D-14 credential rotation)
//   5. svc.sendDocument(buffer, destOrgCode, docCode)
//   6. Success -> UPDATE lgsp_tracking status='success' + lgsp_doc_id (via SP fn_lgsp_tracking_update_status)
//   7. LGSP 4xx errorCode in {10,15,18,19,20,21,22,23} -> UPDATE status='error' + Vietnamese msg,
//      KHONG throw -> BullMQ ko retry (CONTEXT D-11)
//   8. Network/timeout/5xx -> throw -> BullMQ retry per CONTEXT D-10 backoff (30/60/120/240/480s)
//
// worker.on('failed') sau exhausted 5 attempts -> UPDATE status='error' + 'Retry exhausted: <last>'
// per CONTEXT D-13.
//
// CONTEXT D-15: chay trong workers/ module (terminal #3 dev, PM2 prod).
// Backend producer: backend/src/lib/queue/lgsp-send-queue.ts goi enqueueLgspSendJob().
// ============================================================

import { Worker } from 'bullmq';
import IORedis from 'ioredis';
import pino from 'pino';
import { Client as MinioClient } from 'minio';

import {
  LGSP_SEND_QUEUE_NAME,
  LGSP_SEND_CONCURRENCY,
  LGSP_SEND_MAX_ATTEMPTS,
  type LgspSendJobData,
} from '../queues/lgsp-send-queue.js';

// APPROACH B (decision Plan 34-02): workers self-contained — duplicate 3 module LGSP
// vao workers/src/lgsp/. Approach A (import backend) gay tsc rootDir cascade error
// vi backend code import transitively redis/jose/repo voi rootDir conflict.
// Trade-off: lost single source of truth, but isolated build + clean tsconfig.
// PHAI sync 2 file backend/src/services/lgsp/{edxml-builder,error-codes}.ts khi sua.
import {
  buildEdxml,
  type BuildEdxmlInput,
} from '../lgsp/edxml-builder.js';
import {
  LgspSendError,
  isLgspNonRetryableError,
} from '../lgsp/error-codes.js';
import {
  loadLgspCredentials,
  sendDocument as lgspSend,
} from '../lgsp/lgsp-send-service.js';
import { getSharedPgPool } from '../lib/pg-pool.js';

// ============================================================
// Module-level singletons (1 instance per worker process)
// ============================================================

const logger = pino({
  name: 'lgsp-send-worker',
  level: process.env.LOG_LEVEL || 'info',
  transport:
    process.env.NODE_ENV !== 'production'
      ? { target: 'pino-pretty' }
      : undefined,
});

const connection = new IORedis({
  host: process.env.REDIS_HOST || 'localhost',
  port: Number(process.env.REDIS_PORT) || 6379,
  password: process.env.REDIS_PASSWORD,
  maxRetriesPerRequest: null,
  enableReadyCheck: false,
});

connection.on('error', (err) => {
  logger.error({ err: err.message }, 'Redis connection error (lgsp-send-worker)');
});

// v3.2.2 fix #M10: dung shared pg pool thay vi tao pool rieng
const pool = getSharedPgPool();

const minioClient = new MinioClient({
  endPoint: process.env.MINIO_ENDPOINT || 'localhost',
  port: Number(process.env.MINIO_PORT) || 9000,
  useSSL: process.env.MINIO_USE_SSL === 'true',
  accessKey: process.env.MINIO_ACCESS_KEY || '',
  secretKey: process.env.MINIO_SECRET_KEY || '',
});
const MINIO_BUCKET = process.env.MINIO_BUCKET || 'documents';

// ============================================================
// DB row interfaces — match schema 000_schema_v3.0.sql snake_case EXACTLY
// ============================================================

interface OutgoingDocForSend {
  id: string | number;
  unit_id: number;
  notation: string | null;
  document_code: string | null;
  abstract: string | null;
  publish_date: string | null;
  signer: string | null;
  sign_date: string | null;
  number_paper: number | null;
  doc_type_id: number | null;
}

interface RecipientForSend {
  id: string | number;
  recipient_org_id: string | number;
  dest_code: string;
  dest_name: string;
}

interface SenderInfo {
  org_code: string | null; // departments.lgsp_org_code
  org_name: string; // departments.name
}

interface AttachmentForSend {
  file_name: string;
  file_path: string;
  content_type: string | null;
}

// ============================================================
// DB query helpers (worker self-contained — raw SQL, khong qua repo)
// ============================================================

async function loadOutgoingDoc(
  docId: number,
): Promise<OutgoingDocForSend | null> {
  const res = await pool.query<OutgoingDocForSend>(
    `SELECT id, unit_id, notation, document_code, abstract,
            publish_date::text AS publish_date,
            signer,
            sign_date::text AS sign_date,
            number_paper, doc_type_id
       FROM edoc.outgoing_docs
      WHERE id = $1`,
    [docId],
  );
  return res.rows[0] ?? null;
}

async function loadRecipient(
  recipientId: number,
): Promise<RecipientForSend | null> {
  // recipient_type='external_org' bat buoc — internal_unit khong di qua LGSP worker
  const res = await pool.query<RecipientForSend>(
    `SELECT r.id, r.recipient_org_id,
            o.code AS dest_code,
            o.name AS dest_name
       FROM edoc.outgoing_doc_recipients r
       JOIN edoc.inter_organizations o ON r.recipient_org_id = o.id
      WHERE r.id = $1
        AND r.recipient_type = 'external_org'::edoc.recipient_type_enum`,
    [recipientId],
  );
  return res.rows[0] ?? null;
}

async function loadSender(senderUnitId: number): Promise<SenderInfo | null> {
  const res = await pool.query<SenderInfo>(
    `SELECT lgsp_org_code AS org_code, name AS org_name
       FROM public.departments
      WHERE id = $1`,
    [senderUnitId],
  );
  return res.rows[0] ?? null;
}

async function loadDocTypeName(
  docTypeId: number | null,
): Promise<string | null> {
  if (!docTypeId) return null;
  const res = await pool.query<{ name: string }>(
    `SELECT name FROM edoc.doc_types WHERE id = $1`,
    [docTypeId],
  );
  return res.rows[0]?.name ?? null;
}

async function loadAttachments(
  docId: number,
): Promise<AttachmentForSend[]> {
  const res = await pool.query<AttachmentForSend>(
    `SELECT file_name, file_path, content_type
       FROM edoc.attachment_outgoing_docs
      WHERE outgoing_doc_id = $1
      ORDER BY sort_order, id`,
    [docId],
  );
  return res.rows;
}

async function loadAttachmentBuffer(filePath: string): Promise<Buffer> {
  const stream = await minioClient.getObject(MINIO_BUCKET, filePath);
  const chunks: Buffer[] = [];
  for await (const chunk of stream) {
    chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
  }
  return Buffer.concat(chunks);
}

async function updateTrackingStatus(
  trackingId: number,
  status: 'success' | 'error',
  lgspDocId: string | null,
  errorMessage: string | null,
): Promise<void> {
  await pool.query(
    `SELECT * FROM edoc.fn_lgsp_tracking_update_status($1, $2, $3, $4)`,
    [trackingId, status, lgspDocId, errorMessage],
  );
}

// ============================================================
// Worker handler (1 invocation per job attempt)
// ============================================================

async function handleSendJob(data: LgspSendJobData): Promise<void> {
  const {
    recipient_id,
    outgoing_doc_id,
    tracking_id,
    sender_unit_id,
    environment,
  } = data;
  const logCtx = {
    recipient_id,
    outgoing_doc_id,
    tracking_id,
    sender_unit_id,
    environment,
  };

  logger.info(logCtx, 'LGSP send job start');

  // 1. Load doc + recipient + sender
  const doc = await loadOutgoingDoc(outgoing_doc_id);
  if (!doc) {
    await updateTrackingStatus(
      tracking_id,
      'error',
      null,
      `Outgoing doc id=${outgoing_doc_id} khong ton tai`,
    );
    logger.error(logCtx, 'Outgoing doc not found — marked tracking error');
    return;
  }

  const recipient = await loadRecipient(recipient_id);
  if (!recipient) {
    await updateTrackingStatus(
      tracking_id,
      'error',
      null,
      `Recipient id=${recipient_id} khong ton tai hoac khong phai external_org`,
    );
    logger.error(logCtx, 'Recipient not found — marked tracking error');
    return;
  }

  const sender = await loadSender(sender_unit_id);
  if (!sender) {
    await updateTrackingStatus(
      tracking_id,
      'error',
      null,
      `Sender unit_id=${sender_unit_id} khong ton tai`,
    );
    logger.error(logCtx, 'Sender unit not found — marked tracking error');
    return;
  }
  if (!sender.org_code) {
    await updateTrackingStatus(
      tracking_id,
      'error',
      null,
      `Sender unit_id=${sender_unit_id} chua co lgsp_org_code (chua cau hinh LGSP)`,
    );
    logger.error(logCtx, 'Sender lgsp_org_code missing');
    return;
  }

  const docTypeName = await loadDocTypeName(doc.doc_type_id);

  // 2. Load attachments base64 (skip-on-error per CONTEXT D-06)
  const attMetas = await loadAttachments(outgoing_doc_id);
  const attachments: BuildEdxmlInput['attachments'] = [];
  for (const att of attMetas) {
    try {
      const buf = await loadAttachmentBuffer(att.file_path);
      // CONTEXT D-06: file >5MB van inline + warn (6 DN small scale)
      if (buf.length > 5 * 1024 * 1024) {
        logger.warn(
          { ...logCtx, fileName: att.file_name, bytes: buf.length },
          'Attachment >5MB — van inline base64, theo doi RAM',
        );
      }
      attachments.push({
        fileName: att.file_name,
        fileType: att.content_type || 'application/octet-stream',
        contentBase64: buf.toString('base64'),
      });
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      logger.warn(
        { ...logCtx, attachment: att.file_name, err: msg },
        'Failed to load attachment from MinIO — skipping (partial send tot hon fail toan bo)',
      );
    }
  }

  // 3. Build edXML envelope
  const edxml = buildEdxml({
    senderOrgCode: sender.org_code,
    senderOrgName: sender.org_name,
    destOrgCode: recipient.dest_code,
    destOrgName: recipient.dest_name,
    notation: doc.notation,
    documentCode: doc.document_code,
    abstract: doc.abstract,
    publishDate: doc.publish_date,
    signer: doc.signer,
    signDate: doc.sign_date,
    // outgoing_docs schema v3.0 KHONG co column signer_position — fallback null (builder map N/A per D-09)
    signerPosition: null,
    docTypeName,
    numberPaper: doc.number_paper,
    // outgoing_docs.appendix khong co — null -> builder for appendix optional
    appendix: null,
    attachments,
  });
  logger.info(
    {
      ...logCtx,
      docId: edxml.docId,
      docCode: edxml.docCode,
      bytes: edxml.buffer.length,
      attachmentCount: attachments.length,
    },
    'edXML envelope built',
  );

  // Phase 37.5 debug: dump XML buffer ra file de forward cho LGSP support inspect.
  // Toggle bang env LGSP_DUMP_XML=1; mac dinh OFF de tranh I/O thua tren prod.
  if (process.env.LGSP_DUMP_XML === '1') {
    try {
      const { writeFileSync } = await import('fs');
      const { join } = await import('path');
      const dumpDir = process.env.LGSP_DUMP_DIR || (process.platform === 'win32' ? 'C:\\Temp' : '/tmp');
      const dumpPath = join(dumpDir, `lgsp-sent-${tracking_id}-${Date.now()}.xml`);
      writeFileSync(dumpPath, edxml.buffer);
      logger.info({ ...logCtx, dumpPath }, 'edXML buffer dumped to file for debug');
    } catch (dumpErr: unknown) {
      const msg = dumpErr instanceof Error ? dumpErr.message : String(dumpErr);
      logger.warn({ ...logCtx, err: msg }, 'edXML dump fail (non-fatal)');
    }
  }

  // 4. Resolve LGSP credentials (fresh per attempt — CONTEXT D-14 credential rotation)
  //    Worker decrypt qua pg pgp_sym_decrypt INLINE — KHONG cache (per-attempt is fresh
  //    by design, fresh DB read picks up admin rotate giua attempt).
  let credentials;
  try {
    credentials = await loadLgspCredentials(
      pool,
      sender_unit_id,
      environment,
      process.env.SIGNING_SECRET_KEY || '',
    );
  } catch (err: unknown) {
    // Credential missing / disabled / decrypt fail / placeholder secret
    // -> no-retry (LGSP cau hinh ko thay doi giua attempt thi retry vo nghia)
    const msg = err instanceof Error ? err.message : String(err);
    await updateTrackingStatus(
      tracking_id,
      'error',
      null,
      `LGSP credential error: ${msg.slice(0, 500)}`,
    );
    logger.error(
      { ...logCtx, err: msg },
      'loadLgspCredentials failed — marked tracking error (no-retry)',
    );
    return;
  }

  // 5. Send via LGSP /v1/sendEdoc
  try {
    const result = await lgspSend(
      credentials,
      edxml.buffer,
      edxml.destOrgCode,
      edxml.docCode,
    );

    if (result.success) {
      // 6. Success — update tracking + lgsp_doc_id
      await updateTrackingStatus(
        tracking_id,
        'success',
        result.lgsp_doc_id || edxml.docId,
        null,
      );
      logger.info(
        {
          ...logCtx,
          lgsp_doc_id: result.lgsp_doc_id || edxml.docId,
          message: result.message,
        },
        'LGSP send SUCCESS',
      );
      return;
    }

    // 7. result.success=false — LGSP server da reject deterministic.
    //    Dump 200 byte dau cua edXML buffer de debug (UTF-8 + base64 fallback).
    //    success=false LUON = no-retry kể cả errorCode unknown — server reject co chu y,
    //    retry chi ton 16 phut backoff vo nghia (Phase 37.5 fix sau khi gap XML format reject
    //    voi errorCode=undefined hop le tu LGSP Lang Son).
    const xmlHead = edxml.buffer.subarray(0, 200).toString('utf8');
    const xmlHeadB64 = edxml.buffer.subarray(0, 200).toString('base64');
    logger.warn(
      {
        ...logCtx,
        errorCode: result.errorCode || 'undefined',
        message: result.message,
        lgsp_doc_id: result.lgsp_doc_id,
        edxml_bytes: edxml.buffer.length,
        edxml_head_utf8: xmlHead,
        edxml_head_base64: xmlHeadB64,
      },
      'LGSP send FAIL (success=false — no retry, deterministic reject)',
    );
    await updateTrackingStatus(
      tracking_id,
      'error',
      result.lgsp_doc_id || null,
      result.message,
    );
    return;
  } catch (err: unknown) {
    // 8. Error path — classify retry vs no-retry
    if (
      err instanceof LgspSendError &&
      err.code &&
      isLgspNonRetryableError(err.code)
    ) {
      // 4xx LgspSendError thrown by service — treat same as result.success=false branch
      await updateTrackingStatus(
        tracking_id,
        'error',
        null,
        err.vietnameseMessage,
      );
      logger.warn(
        { ...logCtx, errorCode: err.code, message: err.vietnameseMessage },
        'LgspSendError 4xx — no retry per D-11',
      );
      return;
    }
    // Network / timeout / 5xx / unknown -> throw -> BullMQ retry per D-10 backoff
    const msg = err instanceof Error ? err.message : String(err);
    logger.error(
      { ...logCtx, err: msg },
      'LGSP send transient error — BullMQ will retry per D-10 backoff',
    );
    throw err;
  }
}

// ============================================================
// Worker instantiation + lifecycle
// ============================================================

export function startLgspSendWorker(): Worker<LgspSendJobData> {
  const worker = new Worker<LgspSendJobData>(
    LGSP_SEND_QUEUE_NAME,
    async (job) => {
      await handleSendJob(job.data);
    },
    {
      connection,
      concurrency: LGSP_SEND_CONCURRENCY,
    },
  );

  worker.on('completed', (job) => {
    logger.debug(
      { jobId: job.id, attemptsMade: job.attemptsMade },
      'LGSP send job completed',
    );
  });

  // CONTEXT D-13: retry exhausted -> mark tracking error
  worker.on('failed', async (job, err) => {
    if (!job) {
      logger.error({ err: err.message }, 'Worker failed event with no job');
      return;
    }
    const attemptsMade = job.attemptsMade ?? 0;
    const maxAttempts = job.opts?.attempts ?? LGSP_SEND_MAX_ATTEMPTS;

    if (attemptsMade < maxAttempts) {
      // Will retry — just log
      logger.debug(
        {
          jobId: job.id,
          attemptsMade,
          maxAttempts,
          err: err.message,
        },
        'LGSP send attempt failed — BullMQ will retry per D-10 backoff',
      );
      return;
    }

    // Exhausted — mark tracking error per CONTEXT D-13
    const data = job.data as LgspSendJobData;
    try {
      await updateTrackingStatus(
        data.tracking_id,
        'error',
        null,
        `Retry exhausted (${attemptsMade}/${maxAttempts}): ${err.message.slice(0, 500)}`,
      );
      logger.error(
        {
          jobId: job.id,
          ...data,
          attemptsMade,
          maxAttempts,
          err: err.message,
        },
        'LGSP send EXHAUSTED — marked tracking error',
      );
    } catch (updErr: unknown) {
      const updMsg =
        updErr instanceof Error ? updErr.message : String(updErr);
      logger.error(
        { jobId: job.id, ...data, updErr: updMsg },
        'Failed to update tracking after retry exhaustion',
      );
    }
  });

  worker.on('error', (err) => {
    logger.error({ err: err.message }, 'LGSP send worker error');
  });

  logger.info(
    {
      queue: LGSP_SEND_QUEUE_NAME,
      concurrency: LGSP_SEND_CONCURRENCY,
      maxAttempts: LGSP_SEND_MAX_ATTEMPTS,
    },
    'LGSP send worker started',
  );

  return worker;
}

/**
 * Graceful shutdown — call from workers/src/index.ts SIGTERM handler.
 * Closes BullMQ Worker, pg pool, Redis connection.
 */
export async function stopLgspSendWorker(
  worker: Worker<LgspSendJobData>,
): Promise<void> {
  try {
    await worker.close();
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    logger.warn({ err: msg }, 'Error closing LGSP send worker');
  }
  try {
    await pool.end();
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    logger.warn({ err: msg }, 'Error closing pg pool');
  }
  try {
    connection.disconnect();
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    logger.warn({ err: msg }, 'Error disconnecting Redis');
  }
}
