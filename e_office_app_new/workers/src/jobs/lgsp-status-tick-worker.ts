// ============================================================
// LGSP Status Tick Worker - Phase 36 Plan 36-02
// REQ: LGSP-STATUS-09
// CONTEXT D-05 (BullMQ repeat 30s), D-06 (per-event jobs), D-07 (tick concurrency=1)
//
// Handler: query edoc.fn_lgsp_status_outbox_get_pending(100) -> for each row enqueue 'status-event'.
// No HTTP work here (delegated to status-event). Tick failures don't retry -- next 30s tick covers it.
// ============================================================
import { Queue, Worker, Job } from 'bullmq';
import IORedis from 'ioredis';
import pino from 'pino';
import {
  LGSP_STATUS_QUEUE_NAME,
  LGSP_STATUS_TICK_JOB_NAME,
  LGSP_STATUS_EVENT_JOB_NAME,
  LGSP_STATUS_TICK_CONCURRENCY,
  LGSP_STATUS_TICK_MAX_ATTEMPTS,
  LGSP_STATUS_EVENT_MAX_ATTEMPTS,
  LGSP_STATUS_EVENT_BACKOFF_DELAY,
  LGSP_STATUS_TICK_BATCH_SIZE,
  type LgspStatusTickJobData,
  type LgspStatusEventJobData,
} from '../queues/lgsp-status-queue.js';
import { getSharedPgPool } from '../lib/pg-pool.js';

const logger = pino({ name: 'lgsp-status-tick-worker' });

let connection: IORedis | null = null;
let eventQueue: Queue<LgspStatusEventJobData> | null = null;

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

// v3.2.2 fix #M10: dung shared pg pool
const getPool = getSharedPgPool;

function getEventQueue(): Queue<LgspStatusEventJobData> {
  if (!eventQueue) {
    eventQueue = new Queue<LgspStatusEventJobData>(LGSP_STATUS_QUEUE_NAME, {
      connection: getConnection(),
      defaultJobOptions: {
        attempts: LGSP_STATUS_EVENT_MAX_ATTEMPTS,
        backoff: { type: 'exponential', delay: LGSP_STATUS_EVENT_BACKOFF_DELAY },
        removeOnComplete: { count: 500 },
        removeOnFail: { count: 2000 },
      },
    });
  }
  return eventQueue;
}

/**
 * Tick handler: query pending outbox events -> enqueue 1 status-event job per row.
 * Only processes jobs with job.name === 'status-tick' (filters same-queue 'status-event' jobs).
 */
async function handleTick(
  job: Job<LgspStatusTickJobData>,
): Promise<{ enqueued: number; pending_count: number }> {
  if (job.name !== LGSP_STATUS_TICK_JOB_NAME) {
    return { enqueued: 0, pending_count: 0 };
  }

  const tickId = job.id ?? `tick-${Date.now()}`;
  const trigger = job.data?.trigger_source ?? 'cron';

  // Query pending events via Phase 33 SP. FIFO by created_at (D-12).
  // SP filters sent_status='pending' AND (next_retry_at IS NULL OR next_retry_at <= NOW()).
  const rs = await getPool().query<{
    id: string;
    incoming_doc_id: string;
    target_status: string;
    payload: Record<string, unknown>;
    retry_count: number;
    next_retry_at: string | null;
    created_at: string;
  }>(`SELECT * FROM edoc.fn_lgsp_status_outbox_get_pending($1)`, [LGSP_STATUS_TICK_BATCH_SIZE]);

  if (rs.rows.length === 0) {
    // Empty outbox -- quiet log to avoid spam at 30s cadence. Only log when something happens.
    return { enqueued: 0, pending_count: 0 };
  }

  logger.info(
    { tickId, trigger, pending: rs.rows.length },
    'LGSP status tick: enqueuing event jobs',
  );

  // Lookup doc.unit_id for each row (1 query per batch -- IN clause).
  // We need unit_id to populate event job data (lookup later in event handler).
  const docIds = rs.rows.map((r) => Number(r.incoming_doc_id));
  const ownerRs = await getPool().query<{ id: string; unit_id: string }>(
    `SELECT id, unit_id FROM edoc.incoming_docs WHERE id = ANY($1::bigint[])`,
    [docIds],
  );
  const docToUnit = new Map<number, number>();
  for (const r of ownerRs.rows) {
    docToUnit.set(Number(r.id), Number(r.unit_id));
  }

  const evQ = getEventQueue();
  let enqueued = 0;
  for (const row of rs.rows) {
    const outboxId = Number(row.id);
    const docId = Number(row.incoming_doc_id);
    const unitId = docToUnit.get(docId);
    if (typeof unitId !== 'number') {
      logger.warn(
        { outboxId, docId },
        'Skip status event -- doc not found (will be CASCADE deleted soon)',
      );
      continue;
    }
    // Deterministic jobId chan duplicate enqueue khi tick lay overlap rows
    // (vd: trong khoang 30s tick, 1 event chua kip xu ly thi tick sau van thay).
    const jobId = `lgsp-status-event-${outboxId}`;
    try {
      await evQ.add(
        LGSP_STATUS_EVENT_JOB_NAME,
        {
          outbox_id: outboxId,
          incoming_doc_id: docId,
          unit_id: unitId,
          target_status: row.target_status,
          payload: row.payload,
        },
        { jobId },
      );
      enqueued += 1;
    } catch (err) {
      logger.warn(
        { outboxId, docId, err: (err as Error).message },
        'Failed to enqueue status-event job',
      );
    }
  }

  logger.info(
    { tickId, trigger, pending_count: rs.rows.length, enqueued },
    'LGSP status tick: fan-out complete',
  );
  return { enqueued, pending_count: rs.rows.length };
}

export function startLgspStatusTickWorker(): Worker<LgspStatusTickJobData> {
  const worker = new Worker<LgspStatusTickJobData>(
    LGSP_STATUS_QUEUE_NAME,
    async (job) => handleTick(job),
    {
      connection: getConnection(),
      concurrency: LGSP_STATUS_TICK_CONCURRENCY,
      autorun: true,
    },
  );

  worker.on('completed', (job, result) => {
    if (job.name === LGSP_STATUS_TICK_JOB_NAME && (result as { enqueued?: number } | undefined)?.enqueued && (result as { enqueued: number }).enqueued > 0) {
      logger.info({ jobId: job.id, result }, 'LGSP status tick completed');
    }
  });
  worker.on('failed', (job, err) => {
    if (job?.name === LGSP_STATUS_TICK_JOB_NAME) {
      logger.error({ jobId: job?.id, err: err?.message }, 'LGSP status tick failed');
    }
  });
  worker.on('error', (err) => {
    logger.error({ err: err.message }, 'LGSP status tick worker error');
  });

  logger.info(
    {
      queue: LGSP_STATUS_QUEUE_NAME,
      concurrency: LGSP_STATUS_TICK_CONCURRENCY,
      maxAttempts: LGSP_STATUS_TICK_MAX_ATTEMPTS,
    },
    'LGSP status tick worker started',
  );
  return worker;
}

export async function stopLgspStatusTickWorker(
  worker: Worker<LgspStatusTickJobData>,
): Promise<void> {
  try { await worker.close(); } catch (err) { logger.warn({ err: (err as Error).message }, 'Error closing tick worker'); }
  try { if (eventQueue) { await eventQueue.close(); eventQueue = null; } } catch (err) { logger.warn({ err: (err as Error).message }, 'Error closing event queue (from tick worker)'); }
  // v3.2.2 fix #M10: shared pool close handled in index.ts SIGTERM
  try { if (connection) { connection.disconnect(); connection = null; } } catch (err) { logger.warn({ err: (err as Error).message }, 'Error disconnecting tick connection'); }
}
