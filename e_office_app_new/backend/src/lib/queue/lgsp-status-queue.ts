// ============================================================
// LGSP Status Queue - backend producer side - Phase 36 Plan 36-02
// REQ: LGSP-STATUS-09
// CONTEXT D-05 (repeat 30s), D-06 (per-event jobs)
//
// Mirror pattern: backend/src/lib/queue/lgsp-receive-queue.ts (Phase 35-02)
//
// Exports:
//   - getLgspStatusQueue(): lazy singleton Queue
//   - enqueueStatusTick(data?): used by future admin manual trigger (Phase 37 optional)
//   - registerStatusTickRepeatJob(): called from server.ts startup (Plan 36-03 wires)
//   - closeLgspStatusQueue(): called from SIGTERM cleanup chain in server.ts (Plan 36-03 wires)
// ============================================================
import { Queue } from 'bullmq';
import pino from 'pino';
import { getRedisConnection } from './redis-connection.js';

const logger = pino({ name: 'lgsp-status-queue' });

// Constants -- duplicated from workers/src/queues/lgsp-status-queue.ts (separate module per Approach B)
export const LGSP_STATUS_QUEUE_NAME = 'lgsp-status';
export const LGSP_STATUS_TICK_JOB_NAME = 'status-tick';
export const LGSP_STATUS_EVENT_JOB_NAME = 'status-event';
export const LGSP_STATUS_TICK_MAX_ATTEMPTS = 1;
export const LGSP_STATUS_EVENT_MAX_ATTEMPTS = 5;
export const LGSP_STATUS_EVENT_BACKOFF_DELAY = 30_000;
export const LGSP_STATUS_TICK_INTERVAL_MS = 30 * 1000;
export const LGSP_STATUS_TICK_REPEAT_JOB_ID = 'lgsp-status-tick-singleton';

export interface LgspStatusTickJobData {
  trigger_source?: 'cron' | 'manual';
  triggered_by_staff_id?: number;
}
export interface LgspStatusEventJobData {
  outbox_id: number;
  incoming_doc_id: number;
  unit_id: number;
  target_status: string;
  payload: Record<string, unknown>;
}

let queue: Queue<LgspStatusTickJobData | LgspStatusEventJobData> | null = null;

export function getLgspStatusQueue(): Queue<LgspStatusTickJobData | LgspStatusEventJobData> {
  if (!queue) {
    queue = new Queue<LgspStatusTickJobData | LgspStatusEventJobData>(
      LGSP_STATUS_QUEUE_NAME,
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
        queue: LGSP_STATUS_QUEUE_NAME,
        eventMaxAttempts: LGSP_STATUS_EVENT_MAX_ATTEMPTS,
        eventBackoffDelayMs: LGSP_STATUS_EVENT_BACKOFF_DELAY,
        tickIntervalMs: LGSP_STATUS_TICK_INTERVAL_MS,
      },
      'LGSP status queue initialized',
    );
  }
  return queue;
}

/**
 * Manual enqueue (Phase 37 admin "Push status now" can call this).
 * Default trigger_source='manual'. Job runs as soon as a tick worker is free.
 */
export async function enqueueStatusTick(data?: LgspStatusTickJobData): Promise<string> {
  const q = getLgspStatusQueue();
  const j = await q.add(
    LGSP_STATUS_TICK_JOB_NAME,
    {
      trigger_source: data?.trigger_source ?? 'manual',
      triggered_by_staff_id: data?.triggered_by_staff_id,
    },
    {
      attempts: LGSP_STATUS_TICK_MAX_ATTEMPTS,
      removeOnComplete: { count: 500 },
    },
  );
  logger.info(
    {
      jobId: j.id,
      trigger: data?.trigger_source ?? 'manual',
      staffId: data?.triggered_by_staff_id,
    },
    'Enqueued LGSP status tick',
  );
  return String(j.id);
}

/**
 * Idempotent registration of the 30s repeat scheduler.
 * Called once from server.ts startup (Plan 36-03). BullMQ uses deterministic jobId to prevent dup.
 */
export async function registerStatusTickRepeatJob(): Promise<void> {
  const q = getLgspStatusQueue();
  try {
    const existing = await q.getRepeatableJobs();
    for (const r of existing) {
      if (r.name === LGSP_STATUS_TICK_JOB_NAME) {
        try {
          await q.removeRepeatableByKey(r.key);
          logger.info({ key: r.key }, 'Removed pre-existing LGSP status tick repeat scheduler');
        } catch (err) {
          logger.warn({ err: (err as Error).message }, 'Failed to remove pre-existing repeat scheduler (continuing)');
        }
      }
    }
  } catch (err) {
    logger.warn({ err: (err as Error).message }, 'getRepeatableJobs failed (continuing to add)');
  }

  await q.add(
    LGSP_STATUS_TICK_JOB_NAME,
    { trigger_source: 'cron' },
    {
      repeat: { every: LGSP_STATUS_TICK_INTERVAL_MS },
      jobId: LGSP_STATUS_TICK_REPEAT_JOB_ID,
      attempts: LGSP_STATUS_TICK_MAX_ATTEMPTS,
      removeOnComplete: { count: 200 },
    },
  );
  logger.info(
    { intervalMs: LGSP_STATUS_TICK_INTERVAL_MS, jobId: LGSP_STATUS_TICK_REPEAT_JOB_ID },
    'Registered LGSP status tick repeat scheduler',
  );
}

export async function closeLgspStatusQueue(): Promise<void> {
  if (queue) {
    try {
      await queue.close();
      queue = null;
    } catch (err) {
      logger.warn({ err: (err as Error).message }, 'Error closing LGSP status queue');
    }
  }
}
