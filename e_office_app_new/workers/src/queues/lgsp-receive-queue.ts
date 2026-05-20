// ============================================================
// LGSP Receive Queue constants + job data types - Phase 35 Plan 35-02
// REQ: LGSP-RECV-01
// CONTEXT D-01 (BullMQ repeat 5min), D-02 (tick + dn split), D-04 (concurrencies),
//         D-11 (DN retry 3x exponential)
// Mirror pattern: workers/src/queues/lgsp-send-queue.ts (Phase 34)
// ============================================================

export const LGSP_RECEIVE_QUEUE_NAME = 'lgsp-receive';

/** Parent tick job — fires every 5 min OR manual via /api/lgsp/sync-now. Spawns N child receive-dn jobs. */
export const LGSP_RECEIVE_TICK_JOB_NAME = 'receive-tick';

/** Child job — 1 DN end-to-end sync (list + getEdoc loop + INSERT + MinIO + outbox). */
export const LGSP_RECEIVE_DN_JOB_NAME = 'receive-dn';

/** Concurrency: only 1 tick at a time to avoid race when cron + manual trigger fire close together. */
export const LGSP_RECEIVE_TICK_CONCURRENCY = 1;

/** Concurrency: 3 DNs sync in parallel (D-04 — mirror Phase 34 send worker; avoid spamming LGSP). */
export const LGSP_RECEIVE_DN_CONCURRENCY = 3;

/** Tick rarely fails (DB query only). attempts=1 means no retry — next scheduled tick covers it. */
export const LGSP_RECEIVE_TICK_MAX_ATTEMPTS = 1;

/** DN retry: 3 attempts exponential 30s/60s/120s (D-11). Resume from last_synced_at on next tick. */
export const LGSP_RECEIVE_DN_MAX_ATTEMPTS = 3;
export const LGSP_RECEIVE_DN_BACKOFF_DELAY = 30_000;

/** Repeat interval — every 5 minutes (D-01). */
export const LGSP_RECEIVE_TICK_INTERVAL_MS = 5 * 60 * 1000;

/** Deterministic jobId for the repeat scheduler — BullMQ uses this to prevent duplicate cron schedulers. */
export const LGSP_RECEIVE_TICK_REPEAT_JOB_ID = 'lgsp-receive-tick-singleton';

/** Per-DN job timeout — list (30s) + N x getEdoc (60s each, max 50 docs) + uploads = generous 10 min cap. */
export const LGSP_RECEIVE_DN_JOB_TIMEOUT_MS = 10 * 60 * 1000;

/** Tick job carries no data — it just triggers the fan-out. */
export interface LgspReceiveTickJobData {
  /** Optional: who triggered (cron / manual route). Reserved for observability. */
  trigger_source?: 'cron' | 'manual';
  /** Optional: caller staffId when manual route fires. */
  triggered_by_staff_id?: number;
}

/** DN job — 1 active LGSP agency config row to sync. */
export interface LgspReceiveDnJobData {
  unit_id: number;
  environment: 'sandbox' | 'prod';
}
