// ============================================================
// LGSP Send Queue — backend producer side (Phase 34 — CONTEXT D-10, D-15)
//
// Route POST /api/outgoing-doc/:id/gui-noi-bo (Plan 34-03) goi enqueueLgspSendJob()
// 1 lan / external recipient sau khi SP fn_outgoing_doc_send_to_recipients commit success.
//
// Worker consumer: workers/src/jobs/lgsp-send-worker.ts trong workers/ module
// (terminal #3 dev, PM2 prod). Backend chi enqueue — KHONG init Worker.
//
// REPLACES Phase 18 inline `lgspSendQueue` trong lib/queue/client.ts. Plan 34-03
// se sua route Plan 17 dung enqueueLgspSendJob mới — cleanup pattern.
// ============================================================

import { Queue } from 'bullmq';
import pino from 'pino';
import { getRedisConnection } from './redis-connection.js';

const logger = pino({ name: 'lgsp-send-queue' });

// MUST match workers/src/queues/lgsp-send-queue.ts constants — duplicated consciously
// vi workers + backend la 2 module rieng (KHONG share import path).
export const LGSP_SEND_QUEUE_NAME = 'lgsp-send';
export const LGSP_SEND_JOB_NAME = 'send-edoc-recipient';
export const LGSP_SEND_MAX_ATTEMPTS = 5;
export const LGSP_SEND_BACKOFF_DELAY_MS = 30_000;

/** Keep last 1000 successful jobs in Redis cho debug / audit. */
export const LGSP_SEND_JOB_REMOVE_ON_COMPLETE = 1000;

/** Keep last 5000 failed jobs (higher — failures need investigation). */
export const LGSP_SEND_JOB_REMOVE_ON_FAIL = 5000;

/**
 * Job data shape — MUST match `LgspSendJobData` trong workers/src/queues/lgsp-send-queue.ts.
 *
 * IDs only — worker re-fetch fresh outgoing_doc + attachments + sender info per attempt
 * (D-14 credential rotation, D-06 attachment may have grown).
 */
export interface LgspSendJobData {
  /** outgoing_doc_recipients.id (BIGINT) — 1 job = 1 external recipient (D-02) */
  recipient_id: number;
  /** outgoing_docs.id (BIGINT) */
  outgoing_doc_id: number;
  /** lgsp_tracking.id (BIGINT) — created by SP fn_outgoing_doc_send_to_recipients */
  tracking_id: number;
  /** Root unit_id cua DN gui (departments.id) */
  sender_unit_id: number;
  /** Environment — Plan 34-03 route resolve from lgsp_agency_config.is_active per (unit, env) */
  environment: 'sandbox' | 'prod';
}

let _queue: Queue<LgspSendJobData> | null = null;

/**
 * Lazy-init singleton Queue. Safe to call repeatedly.
 * Returns same typed Queue<LgspSendJobData> each call.
 */
export function getLgspSendQueue(): Queue<LgspSendJobData> {
  if (_queue) return _queue;
  _queue = new Queue<LgspSendJobData>(LGSP_SEND_QUEUE_NAME, {
    connection: getRedisConnection(),
    defaultJobOptions: {
      attempts: LGSP_SEND_MAX_ATTEMPTS,
      backoff: {
        type: 'exponential',
        delay: LGSP_SEND_BACKOFF_DELAY_MS,
      },
      removeOnComplete: { count: LGSP_SEND_JOB_REMOVE_ON_COMPLETE },
      removeOnFail: { count: LGSP_SEND_JOB_REMOVE_ON_FAIL },
    },
  });
  logger.info(
    {
      queue: LGSP_SEND_QUEUE_NAME,
      attempts: LGSP_SEND_MAX_ATTEMPTS,
      backoffDelayMs: LGSP_SEND_BACKOFF_DELAY_MS,
    },
    'LGSP send queue initialized',
  );
  return _queue;
}

/**
 * Enqueue 1 LGSP send job per external recipient.
 *
 * `jobId = lgsp-send-{tracking_id}` — BullMQ dedupe trong cung queue, tranh
 * double-enqueue khi route handler bi retry/replay accidentally.
 *
 * @param data IDs only — worker fetch fresh outgoing_doc + attachments per attempt
 * @returns BullMQ job id (string)
 */
export async function enqueueLgspSendJob(
  data: LgspSendJobData,
): Promise<string> {
  const queue = getLgspSendQueue();
  const jobId = `lgsp-send-${data.tracking_id}`;
  const job = await queue.add(LGSP_SEND_JOB_NAME, data, { jobId });
  logger.info(
    {
      jobId: job.id ?? jobId,
      recipient_id: data.recipient_id,
      outgoing_doc_id: data.outgoing_doc_id,
      tracking_id: data.tracking_id,
      sender_unit_id: data.sender_unit_id,
      environment: data.environment,
    },
    'Enqueued LGSP send job',
  );
  return job.id ?? jobId;
}

/**
 * Graceful shutdown — goi tu server.ts SIGTERM handler.
 * Closes Queue, doesn't disconnect shared Redis (closeRedisConnection() handle that).
 */
export async function closeLgspSendQueue(): Promise<void> {
  if (_queue) {
    try {
      await _queue.close();
    } catch (err) {
      logger.warn({ err }, 'Error closing LGSP send queue');
    }
    _queue = null;
  }
}
