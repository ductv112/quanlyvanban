// ============================================================
// LGSP Receive Queue - backend producer side - Phase 35 Plan 35-02
// REQ: LGSP-RECV-01
// CONTEXT D-01 (repeat 5min), D-03 (manual route enqueue tick)
//
// Mirror pattern: backend/src/lib/queue/lgsp-send-queue.ts (Phase 34)
//
// Exports:
//   - getLgspReceiveQueue(): lazy singleton Queue
//   - enqueueReceiveTick(data?): used by POST /api/lgsp/sync-now (Plan 35-03)
//   - registerReceiveTickRepeatJob(): called from server.ts on startup
//   - closeLgspReceiveQueue(): called from SIGTERM cleanup chain in server.ts
// ============================================================
import { Queue } from 'bullmq';
import pino from 'pino';
import { getRedisConnection } from './redis-connection.js';

const logger = pino({ name: 'lgsp-receive-queue' });

// Constants — duplicated from workers/src/queues/lgsp-receive-queue.ts (separate module per Approach B)
export const LGSP_RECEIVE_QUEUE_NAME = 'lgsp-receive';
export const LGSP_RECEIVE_TICK_JOB_NAME = 'receive-tick';
export const LGSP_RECEIVE_DN_JOB_NAME = 'receive-dn';
export const LGSP_RECEIVE_TICK_MAX_ATTEMPTS = 1;
export const LGSP_RECEIVE_DN_MAX_ATTEMPTS = 3;
export const LGSP_RECEIVE_DN_BACKOFF_DELAY = 30_000;
export const LGSP_RECEIVE_TICK_INTERVAL_MS = 5 * 60 * 1000;
export const LGSP_RECEIVE_TICK_REPEAT_JOB_ID = 'lgsp-receive-tick-singleton';

export interface LgspReceiveTickJobData {
  trigger_source?: 'cron' | 'manual';
  triggered_by_staff_id?: number;
}
export interface LgspReceiveDnJobData {
  unit_id: number;
  environment: 'sandbox' | 'prod';
}

let queue: Queue<LgspReceiveTickJobData | LgspReceiveDnJobData> | null = null;

export function getLgspReceiveQueue(): Queue<LgspReceiveTickJobData | LgspReceiveDnJobData> {
  if (!queue) {
    queue = new Queue<LgspReceiveTickJobData | LgspReceiveDnJobData>(
      LGSP_RECEIVE_QUEUE_NAME,
      {
        connection: getRedisConnection(),
        defaultJobOptions: {
          removeOnComplete: { count: 500 },
          removeOnFail: { count: 2000 },
        },
      },
    );
    logger.info(
      {
        queue: LGSP_RECEIVE_QUEUE_NAME,
        dnMaxAttempts: LGSP_RECEIVE_DN_MAX_ATTEMPTS,
        dnBackoffDelayMs: LGSP_RECEIVE_DN_BACKOFF_DELAY,
        tickIntervalMs: LGSP_RECEIVE_TICK_INTERVAL_MS,
      },
      'LGSP receive queue initialized',
    );
  }
  return queue;
}

/**
 * Manual enqueue (Plan 35-03 `POST /api/lgsp/sync-now` calls this).
 * Default trigger_source='manual'. Job runs as soon as a tick worker is free.
 */
export async function enqueueReceiveTick(data?: LgspReceiveTickJobData): Promise<string> {
  const q = getLgspReceiveQueue();
  const j = await q.add(
    LGSP_RECEIVE_TICK_JOB_NAME,
    {
      trigger_source: data?.trigger_source ?? 'manual',
      triggered_by_staff_id: data?.triggered_by_staff_id,
    },
    {
      attempts: LGSP_RECEIVE_TICK_MAX_ATTEMPTS,
      removeOnComplete: { count: 500 },
    },
  );
  logger.info(
    {
      jobId: j.id,
      trigger: data?.trigger_source ?? 'manual',
      staffId: data?.triggered_by_staff_id,
    },
    'Enqueued LGSP receive tick',
  );
  return String(j.id);
}

/**
 * Idempotent registration of the 5-min repeat scheduler.
 * Called once from server.ts startup. BullMQ uses the deterministic jobId to prevent dup schedulers.
 */
export async function registerReceiveTickRepeatJob(): Promise<void> {
  const q = getLgspReceiveQueue();
  try {
    // Remove any pre-existing repeat (idempotent — handles config changes / restarts)
    const existing = await q.getRepeatableJobs();
    for (const r of existing) {
      if (r.name === LGSP_RECEIVE_TICK_JOB_NAME) {
        try {
          await q.removeRepeatableByKey(r.key);
          logger.info({ key: r.key }, 'Removed pre-existing LGSP receive tick repeat scheduler');
        } catch (err) {
          logger.warn(
            { err: (err as Error).message },
            'Failed to remove pre-existing repeat scheduler (continuing)',
          );
        }
      }
    }
  } catch (err) {
    logger.warn(
      { err: (err as Error).message },
      'getRepeatableJobs failed (continuing to add)',
    );
  }

  await q.add(
    LGSP_RECEIVE_TICK_JOB_NAME,
    { trigger_source: 'cron' },
    {
      repeat: { every: LGSP_RECEIVE_TICK_INTERVAL_MS },
      jobId: LGSP_RECEIVE_TICK_REPEAT_JOB_ID,
      attempts: LGSP_RECEIVE_TICK_MAX_ATTEMPTS,
      removeOnComplete: { count: 200 },
    },
  );
  logger.info(
    { intervalMs: LGSP_RECEIVE_TICK_INTERVAL_MS, jobId: LGSP_RECEIVE_TICK_REPEAT_JOB_ID },
    'Registered LGSP receive tick repeat scheduler',
  );
}

export async function closeLgspReceiveQueue(): Promise<void> {
  if (queue) {
    try {
      await queue.close();
      queue = null;
    } catch (err) {
      logger.warn(
        { err: (err as Error).message },
        'Error closing LGSP receive queue',
      );
    }
  }
}
