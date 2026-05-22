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
// Phase 37.4 fix #5: backend producer chi can TICK queue (manual sync-now enqueue tick job).
// DN queue cua worker, backend KHONG enqueue truc tiep child job.
export const LGSP_RECEIVE_TICK_QUEUE_NAME = 'lgsp-receive-tick';
/** @deprecated Phase 37.4: backward compat alias */
export const LGSP_RECEIVE_QUEUE_NAME = LGSP_RECEIVE_TICK_QUEUE_NAME;
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

let queue: Queue<LgspReceiveTickJobData> | null = null;

// Phase 37.4 fix #5: backend producer only manages TICK queue (manual sync-now route).
// DN queue belongs to worker module (tick worker enqueues child DN job sang DN queue).
export function getLgspReceiveQueue(): Queue<LgspReceiveTickJobData> {
  if (!queue) {
    queue = new Queue<LgspReceiveTickJobData>(LGSP_RECEIVE_TICK_QUEUE_NAME, {
      connection: getRedisConnection(),
      defaultJobOptions: {
        removeOnComplete: { count: 500 },
        removeOnFail: { count: 2000 },
      },
    });
    logger.info(
      {
        queue: LGSP_RECEIVE_TICK_QUEUE_NAME,
        dnMaxAttempts: LGSP_RECEIVE_DN_MAX_ATTEMPTS,
        dnBackoffDelayMs: LGSP_RECEIVE_DN_BACKOFF_DELAY,
        tickIntervalMs: LGSP_RECEIVE_TICK_INTERVAL_MS,
      },
      'LGSP receive tick queue initialized',
    );
  }
  return queue;
}

/**
 * Manual enqueue (Plan 35-03 `POST /api/lgsp/sync-now` calls this).
 * Default trigger_source='manual'. Job runs as soon as a tick worker is free.
 *
 * v3.2.2 fix #M8: dedup manual+cron overlap.
 * - Truoc: moi click "Sync ngay" -> 1 tick job moi -> spawn N DN job per click.
 *   Neu user spam click HOAC trung thoi diem cron fire -> DN queue flood, DB hammered.
 * - Sau: kiem tra waiting+active tick job. Neu da co -> return existing jobId voi flag.
 *   Cho phep cron repeat job thuc thi parallel voi manual chi khi can thiet.
 */
export async function enqueueReceiveTick(data?: LgspReceiveTickJobData): Promise<string> {
  const q = getLgspReceiveQueue();

  // Dedup: neu tick job dang waiting/active -> reuse
  try {
    const waiting = await q.getWaiting(0, 5);
    const active = await q.getActive(0, 5);
    const existing = [...waiting, ...active].find((j) => j.name === LGSP_RECEIVE_TICK_JOB_NAME);
    if (existing) {
      logger.info(
        {
          existingJobId: existing.id,
          existingTrigger: (existing.data as LgspReceiveTickJobData)?.trigger_source,
          newTrigger: data?.trigger_source ?? 'manual',
        },
        'LGSP receive tick already pending/active — dedup, returning existing job id',
      );
      return String(existing.id);
    }
  } catch (err) {
    logger.warn(
      { err: (err as Error).message },
      'Tick dedup pre-check failed (continuing to add new job)',
    );
  }

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
