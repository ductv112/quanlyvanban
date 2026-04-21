/**
 * Job payload types + policy constants for the `signing` BullMQ queue.
 *
 * ASYNC-02 poll policy: every 5s, max 36 attempts = 3 minutes total.
 * This matches edoc.sign_transactions.expires_at (= created_at + 3 minutes)
 * so worker gives up exactly when DB considers transaction expired.
 *
 * Each attempt enqueues a new job with delay = POLL_INTERVAL_MS. Worker reads
 * the job, polls the provider, either re-enqueues with attempt+1 or finalizes.
 */

/** Queue name — shared between Queue (producer) and Worker (consumer in Plan 04). */
export const SIGNING_QUEUE_NAME = 'signing';

/** Job name for poll-status jobs. Keep explicit so additional job types can be added later. */
export const POLL_SIGN_STATUS = 'poll-sign-status';

/** 5 seconds between polls — matches ASYNC-02 spec. */
export const POLL_INTERVAL_MS = 5_000;

/** 36 attempts × 5s = 180s = 3 minutes total. Matches sign_transactions.expires_at window. */
export const MAX_POLL_ATTEMPTS = 36;

/** Keep last 1000 successful jobs in Redis for debugging / audit trail. */
export const JOB_REMOVE_ON_COMPLETE = 1000;

/** Keep last 5000 failed jobs (higher cap than success — failures need investigation). */
export const JOB_REMOVE_ON_FAIL = 5000;

/**
 * Payload for `poll-sign-status` job.
 *
 * Only IDs + MinIO key travel through Redis — NO PDF content, NO certificate
 * material, NO user credentials. Worker re-fetches everything by ID on each
 * attempt (fresh status, current DB state).
 */
export interface PollSignStatusJob {
  /** DB PK of edoc.sign_transactions row. Worker uses this to look up txn state + attachment info. */
  signTransactionId: number;

  /** Provider-returned transaction id (SmartCA txn_id or MySign transaction_id). Used when polling status. */
  providerTransactionId: string;

  /** MinIO object key of PDF with signature placeholder (saved by Plan 03 before enqueue). */
  placeholderPdfKey: string;

  /** Which attempt this is (1..MAX_POLL_ATTEMPTS). Used for jobId dedupe + expiry detection. */
  attempt: number;
}
