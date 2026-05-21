// ============================================================
// LGSP Status Queue constants + job data types - Phase 36 Plan 36-02
// REQ: LGSP-STATUS-09
// CONTEXT D-05 (BullMQ repeat 30s), D-06 (per-event jobs), D-07 (concurrencies),
//         D-09 (5 retry exponential 30s base)
// Mirror pattern: workers/src/queues/lgsp-receive-queue.ts (Phase 35-02)
// ============================================================

export const LGSP_STATUS_QUEUE_NAME = 'lgsp-status';

/** Tick job — fires every 30s. Queries pending outbox -> enqueues N child status-event jobs. */
export const LGSP_STATUS_TICK_JOB_NAME = 'status-tick';

/** Event job — 1 outbox row = 1 job. Calls /v1/updateStatus + marks outbox. */
export const LGSP_STATUS_EVENT_JOB_NAME = 'status-event';

/** Concurrency: only 1 tick at a time (race-safe -- DB lock not needed). */
export const LGSP_STATUS_TICK_CONCURRENCY = 1;

/** Concurrency: 5 events in parallel (D-07 -- payload nho ~200 bytes, fast RPC, no LGSP spam). */
export const LGSP_STATUS_EVENT_CONCURRENCY = 5;

/** Tick rarely fails -- attempts=1 (next 30s tick covers it). */
export const LGSP_STATUS_TICK_MAX_ATTEMPTS = 1;

/** Event retry: 5 attempts exponential 30s/60s/120s/240s/480s (D-09 mirror Phase 34). */
export const LGSP_STATUS_EVENT_MAX_ATTEMPTS = 5;
export const LGSP_STATUS_EVENT_BACKOFF_DELAY = 30_000;

/** Repeat interval -- every 30 seconds (D-05). */
export const LGSP_STATUS_TICK_INTERVAL_MS = 30 * 1000;

/** Deterministic jobId for repeat scheduler -- BullMQ uses this to prevent dup schedulers. */
export const LGSP_STATUS_TICK_REPEAT_JOB_ID = 'lgsp-status-tick-singleton';

/** Per-event job timeout -- single RPC call (POST /v1/updateStatus + parse JSON) = generous 60s. */
export const LGSP_STATUS_EVENT_JOB_TIMEOUT_MS = 60 * 1000;

/** Batch size cho tick handler poll (D-12 FIFO best-effort). */
export const LGSP_STATUS_TICK_BATCH_SIZE = 100;

/** Tick job carries no data -- it just triggers the fan-out (D-06). */
export interface LgspStatusTickJobData {
  trigger_source?: 'cron' | 'manual';
  triggered_by_staff_id?: number;
}

/** Event job -- 1 outbox row to send to LGSP. */
export interface LgspStatusEventJobData {
  outbox_id: number;
  incoming_doc_id: number;
  unit_id: number;
  target_status: string;     // QD 28 code: '02' | '03' | '04' | '05' | '06' | '13' | '15' | '16'
  payload: Record<string, unknown>;  // { lgsp_doc_id, sender_org_code, reason?, ... }
}
