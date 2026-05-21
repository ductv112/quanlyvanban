// ============================================================
// LGSP Status Event Worker - Phase 36 Plan 36-02
// REQ: LGSP-STATUS-09
// CONTEXT D-06 (per-event jobs), D-07 (concurrency=5),
//         D-09 (5 retry exp 30s), D-10 (4xx no-retry classify), D-11 (mark error on exhaust)
//
// Handler: 1 outbox row -> resolve owner -> load creds -> POST /v1/updateStatus -> mark success/error.
// Classification per D-10:
//   - Success (errorCode='0' or json.success=true) -> markSent(outbox_id)
//   - LGSP 4xx errorCode in error-codes.ts -> markError (final, no retry)
//   - Network/5xx/timeout -> throw -> BullMQ retry (5 attempts exp 30s base)
//   - Exhausted (attemptsMade >= max) -> on('failed') -> markError final
// ============================================================
import { Worker, Job } from 'bullmq';
import IORedis from 'ioredis';
import pg from 'pg';
import pino from 'pino';
import {
  LGSP_STATUS_QUEUE_NAME,
  LGSP_STATUS_EVENT_JOB_NAME,
  LGSP_STATUS_EVENT_CONCURRENCY,
  LGSP_STATUS_EVENT_MAX_ATTEMPTS,
  type LgspStatusEventJobData,
} from '../queues/lgsp-status-queue.js';
import {
  resolveDocOwner,
  loadLgspCredentials,
  updateStatus,
} from '../lgsp/lgsp-status-service.js';
import { LgspSendError, isLgspNonRetryableError } from '../lgsp/error-codes.js';

const { Pool } = pg;

const logger = pino({ name: 'lgsp-status-event-worker' });

let connection: IORedis | null = null;
let pool: pg.Pool | null = null;

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

async function markOutboxSuccess(outboxId: number): Promise<void> {
  try {
    await getPool().query(
      `SELECT * FROM edoc.fn_lgsp_status_outbox_mark_sent($1, NULL)`,
      [outboxId],
    );
  } catch (err) {
    logger.warn(
      { outboxId, err: (err as Error).message },
      'markSent SP call failed (event still considered success)',
    );
  }
}

/**
 * Mark outbox error. `nextRetryAt = null` -> final fail (sent_status='error').
 * `nextRetryAt = <timestamp>` -> retry pending. Phase 36 chi dung BullMQ retry, KHONG dung next_retry_at
 * (BullMQ tu reschedule per backoff config). markError with NULL = final state.
 */
async function markOutboxError(outboxId: number, message: string): Promise<void> {
  const truncated = (message || 'Unknown error').slice(0, 1000);
  try {
    await getPool().query(
      `SELECT * FROM edoc.fn_lgsp_status_outbox_mark_error($1, $2, NULL)`,
      [outboxId, truncated],
    );
  } catch (err) {
    logger.warn(
      { outboxId, err: (err as Error).message },
      'markError SP call failed',
    );
  }
}

/**
 * Handle 1 status-event job. Filter by job.name (same queue shared with status-tick).
 */
async function handleStatusEvent(
  job: Job<LgspStatusEventJobData>,
): Promise<{ outbox_id: number; status: 'success' | 'error' | 'retried' }> {
  if (job.name !== LGSP_STATUS_EVENT_JOB_NAME) {
    return { outbox_id: 0, status: 'success' };
  }
  const {
    outbox_id: outboxId,
    incoming_doc_id: docId,
    unit_id: jobUnitId,
    target_status: targetStatus,
    payload,
  } = job.data;
  const attempt = job.attemptsMade + 1;

  logger.info(
    { outboxId, docId, targetStatus, attempt },
    'LGSP status event: processing',
  );

  // 1. Resolve owner (re-resolve per attempt -- D-14 supports admin enable/disable mid-flight).
  // KHONG dung jobUnitId truc tiep -- doc co the bi xoa hoac unit_id thay doi (rare).
  const owner = await resolveDocOwner(getPool(), docId);
  if (!owner) {
    const msg = `Doc ${docId} not found or unit has no active LGSP config`;
    logger.warn({ outboxId, docId }, msg);
    await markOutboxError(outboxId, msg);
    return { outbox_id: outboxId, status: 'error' };
  }
  // Sanity: jobUnitId tu tick co the lech neu doc dieu chinh unit_id between tick + event.
  if (owner.unit_id !== jobUnitId) {
    logger.info(
      { outboxId, jobUnitId, resolvedUnitId: owner.unit_id },
      'unit_id changed since tick enqueue -- using fresh resolution',
    );
  }

  // 2. Load credentials fresh (per-attempt -- D-14 rotation).
  const signingKey = process.env.SIGNING_SECRET_KEY ?? '';
  let credentials;
  try {
    credentials = await loadLgspCredentials(
      getPool(),
      owner.unit_id,
      owner.environment,
      signingKey,
    );
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    logger.warn({ outboxId, unitId: owner.unit_id, env: owner.environment, err: msg }, 'loadLgspCredentials failed -- mark error (no retry)');
    await markOutboxError(outboxId, `Credential load failed: ${msg}`);
    return { outbox_id: outboxId, status: 'error' };
  }

  // 3. Extract docId from payload (Phase 35 receive INSERT-ed via Phase 33 SP with key 'lgsp_doc_id').
  const lgspDocId = typeof payload?.lgsp_doc_id === 'string' ? payload.lgsp_doc_id : '';
  if (!lgspDocId) {
    const msg = `payload.lgsp_doc_id missing or not string for outbox ${outboxId}`;
    logger.warn({ outboxId, payload }, msg);
    await markOutboxError(outboxId, msg);
    return { outbox_id: outboxId, status: 'error' };
  }

  // 4. Call POST /v1/updateStatus.
  try {
    const result = await updateStatus(credentials, lgspDocId, targetStatus);
    if (result.success) {
      await markOutboxSuccess(outboxId);
      logger.info(
        { outboxId, docId, lgspDocId, targetStatus, attempt },
        'LGSP status event: success',
      );
      return { outbox_id: outboxId, status: 'success' };
    }
    // success=false response -- classify by errorCode.
    if (isLgspNonRetryableError(result.errorCode)) {
      // 4xx LGSP -- mark error final, no throw.
      await markOutboxError(outboxId, result.message);
      logger.warn(
        { outboxId, docId, lgspDocId, targetStatus, errorCode: result.errorCode, attempt },
        'LGSP status event: 4xx error (no retry)',
      );
      return { outbox_id: outboxId, status: 'error' };
    }
    // Unknown errorCode -- treat as retryable to be safe.
    throw new LgspSendError(
      `LGSP /v1/updateStatus failed (will retry): ${result.message}`,
      result.errorCode,
    );
  } catch (err) {
    if (err instanceof LgspSendError && isLgspNonRetryableError(err.code)) {
      await markOutboxError(outboxId, err.vietnameseMessage);
      logger.warn(
        { outboxId, docId, lgspDocId, errorCode: err.code, attempt },
        'LGSP status event: caught 4xx error (no retry)',
      );
      return { outbox_id: outboxId, status: 'error' };
    }
    // Retryable -- log + throw to BullMQ.
    const msg = err instanceof Error ? err.message : String(err);
    logger.warn(
      { outboxId, docId, attempt, maxAttempts: LGSP_STATUS_EVENT_MAX_ATTEMPTS, err: msg },
      'LGSP status event: retryable error (will retry per backoff)',
    );
    throw err;
  }
}

export function startLgspStatusEventWorker(): Worker<LgspStatusEventJobData> {
  const worker = new Worker<LgspStatusEventJobData>(
    LGSP_STATUS_QUEUE_NAME,
    async (job) => handleStatusEvent(job),
    {
      connection: getConnection(),
      concurrency: LGSP_STATUS_EVENT_CONCURRENCY,
      autorun: true,
    },
  );

  worker.on('completed', (job, result) => {
    if (job.name === LGSP_STATUS_EVENT_JOB_NAME) {
      const r = result as { status?: string; outbox_id?: number } | undefined;
      if (r?.status === 'success' || r?.status === 'error') {
        logger.info({ jobId: job.id, outboxId: r.outbox_id, status: r.status }, 'event completed');
      }
    }
  });

  // D-11: on('failed') final attempt -- mark outbox error 'Retry exhausted: <last>'
  worker.on('failed', async (job, err) => {
    if (!job || job.name !== LGSP_STATUS_EVENT_JOB_NAME) return;
    const data = job.data as LgspStatusEventJobData;
    const attemptsMade = job.attemptsMade ?? 0;
    const maxAttempts = LGSP_STATUS_EVENT_MAX_ATTEMPTS;
    if (attemptsMade >= maxAttempts) {
      const msg = `Retry exhausted (${attemptsMade}/${maxAttempts}): ${err?.message ?? 'unknown'}`;
      try {
        await markOutboxError(data.outbox_id, msg);
        logger.error(
          { jobId: job.id, outboxId: data.outbox_id, attemptsMade, maxAttempts, err: err?.message },
          'LGSP status event: retry exhausted -- mark final error',
        );
      } catch (markErr) {
        logger.error(
          { jobId: job.id, err: (markErr as Error).message },
          'Failed to mark outbox error after retry exhaust',
        );
      }
    }
    // attemptsMade < max -- BullMQ se reschedule, KHONG can mark error o day.
  });

  worker.on('error', (err) => {
    logger.error({ err: err.message }, 'LGSP status event worker error');
  });

  logger.info(
    {
      queue: LGSP_STATUS_QUEUE_NAME,
      concurrency: LGSP_STATUS_EVENT_CONCURRENCY,
      maxAttempts: LGSP_STATUS_EVENT_MAX_ATTEMPTS,
    },
    'LGSP status event worker started',
  );
  return worker;
}

export async function stopLgspStatusEventWorker(
  worker: Worker<LgspStatusEventJobData>,
): Promise<void> {
  try { await worker.close(); } catch (err) { logger.warn({ err: (err as Error).message }, 'Error closing event worker'); }
  try { if (pool) { await pool.end(); pool = null; } } catch (err) { logger.warn({ err: (err as Error).message }, 'Error ending event pool'); }
  try { if (connection) { connection.disconnect(); connection = null; } } catch (err) { logger.warn({ err: (err as Error).message }, 'Error disconnecting event connection'); }
}
