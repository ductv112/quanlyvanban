/**
 * BullMQ Queue for the async sign flow (Phase 11+).
 *
 * Producer side only — no Worker in this module. Plan 11-04 adds the Worker
 * that consumes `poll-sign-status` jobs.
 *
 * Flow (happy path):
 *   1. Route POST /api/ky-so/sign creates sign_transactions row + calls
 *      provider.signHash.
 *   2. Route calls enqueuePollSignStatus({ signTransactionId, providerTransactionId,
 *      placeholderPdfKey, attempt: 1 }) with delay=5s.
 *   3. Worker consumes the job → polls provider → if still pending, re-enqueues
 *      attempt+1 with +5s delay.
 *   4. When provider returns signed hash → worker embeds signature, uploads
 *      signed PDF to MinIO, updates DB (finalizeSign), emits Socket event.
 *   5. If provider failed/expired → worker marks transaction failed + emits
 *      Socket event.
 *   6. If attempt > MAX_POLL_ATTEMPTS → worker marks the transaction expired.
 */

import { Queue } from 'bullmq';
import pino from 'pino';
import { getRedisConnection } from './redis-connection.js';
import {
  SIGNING_QUEUE_NAME,
  POLL_SIGN_STATUS,
  POLL_INTERVAL_MS,
  JOB_REMOVE_ON_COMPLETE,
  JOB_REMOVE_ON_FAIL,
  type PollSignStatusJob,
} from './types.js';

const logger = pino({ name: 'signing-queue' });

// Re-export queue name so callers (worker in Plan 04, cancel route) do not
// need a second import path.
export { SIGNING_QUEUE_NAME } from './types.js';

/**
 * Module-level singleton. Lazy-initialized on first access so the backend
 * can boot even when the sign feature is unused (no Redis ping cost at
 * startup, and unit tests that never touch signing do not need Redis).
 */
let _queue: Queue<PollSignStatusJob> | null = null;

/**
 * Returns the singleton Queue instance. Safe to call repeatedly.
 * Caller receives the same typed Queue<PollSignStatusJob> each call.
 */
export function getSigningQueue(): Queue<PollSignStatusJob> {
  if (_queue) return _queue;
  _queue = new Queue<PollSignStatusJob>(SIGNING_QUEUE_NAME, {
    connection: getRedisConnection(),
    defaultJobOptions: {
      removeOnComplete: { count: JOB_REMOVE_ON_COMPLETE },
      removeOnFail: { count: JOB_REMOVE_ON_FAIL },
      // We implement retry manually by re-enqueuing attempt+1 in the worker —
      // gives finer control (custom delay, DB state checks). BullMQ's built-in
      // retry ignores our attempt counter.
      attempts: 1,
    },
  });
  logger.info({ queue: SIGNING_QUEUE_NAME }, 'BullMQ signing queue initialized');
  return _queue;
}

/**
 * Enqueue a `poll-sign-status` job.
 *
 * jobId = `poll-{signTransactionId}-{attempt}` — BullMQ dedupes on jobId within
 * the same queue, so accidental double-enqueue for the same (txn, attempt)
 * tuple is a no-op rather than a duplicate poll. Mitigates T-11-06 (DoS).
 *
 * @param payload  Typed job data (IDs + MinIO key only — no PDF bytes).
 * @param delayMs  Milliseconds to wait before Worker picks up. Default
 *                 POLL_INTERVAL_MS (5s) — used both for initial enqueue from
 *                 the sign route and for re-enqueue from the worker.
 * @returns BullMQ job id (falls back to the computed jobId string).
 */
export async function enqueuePollSignStatus(
  payload: PollSignStatusJob,
  delayMs: number = POLL_INTERVAL_MS,
): Promise<string> {
  const queue = getSigningQueue();
  const jobId = `poll-${payload.signTransactionId}-${payload.attempt}`;
  const job = await queue.add(POLL_SIGN_STATUS, payload, {
    jobId,
    delay: delayMs,
  });
  logger.debug(
    {
      jobId: job.id,
      signTransactionId: payload.signTransactionId,
      attempt: payload.attempt,
      delayMs,
    },
    'Enqueued poll-sign-status job',
  );
  return job.id ?? jobId;
}

/**
 * Cancel all pending (delayed) poll jobs for a given transaction id.
 *
 * Called from the "Hủy ký" endpoint (Plan 11-06) when the user cancels a
 * transaction that is still within the 3-minute window. Any jobs currently
 * executing (active state) cannot be cancelled mid-flight — the Worker itself
 * guards against finalizing a cancelled transaction by checking the DB
 * sign_transactions.status at the start of each handler run.
 *
 * @returns Count of jobs removed.
 */
export async function cancelPollJobsForTransaction(
  signTransactionId: number,
): Promise<number> {
  const queue = getSigningQueue();
  const delayed = await queue.getDelayed();
  let removed = 0;
  for (const job of delayed) {
    if (job.data?.signTransactionId === signTransactionId) {
      try {
        await job.remove();
        removed++;
      } catch {
        // Job transitioned to active during iteration — let the Worker
        // short-circuit via DB status check.
      }
    }
  }
  logger.info(
    { signTransactionId, removed },
    'Cancelled pending poll-sign-status jobs for transaction',
  );
  return removed;
}

/**
 * Graceful shutdown — call from server.ts SIGTERM/SIGINT handler.
 * Closes the Queue and releases the shared Redis connection.
 */
export async function closeSigningQueue(): Promise<void> {
  if (_queue) {
    try {
      await _queue.close();
    } catch (err) {
      logger.warn({ err }, 'Error closing signing queue');
    }
    _queue = null;
  }
}
