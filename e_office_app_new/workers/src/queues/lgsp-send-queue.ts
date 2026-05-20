// ============================================================
// LGSP Send Queue — workers-side constants + types (Phase 34)
//
// Worker only consumes — Queue instance khong init trong workers process.
// Backend producer init Queue: backend/src/lib/queue/lgsp-send-queue.ts
//
// CONTEXT pin:
//   D-04: concurrency = 3
//   D-10: attempts = 5, exponential backoff delay 30s -> 30/60/120/240/480s
//   D-15: worker chay trong workers/ module (terminal #3 dev, PM2 prod)
// ============================================================

/** Queue name — phai match `backend/src/lib/queue/lgsp-send-queue.ts` */
export const LGSP_SEND_QUEUE_NAME = 'lgsp-send';

/** Job name — phai match producer enqueue helper */
export const LGSP_SEND_JOB_NAME = 'send-edoc-recipient';

/** Worker concurrency — CONTEXT D-04 (3 parallel jobs / worker process) */
export const LGSP_SEND_CONCURRENCY = 3;

/** Max retry attempts — CONTEXT D-10 */
export const LGSP_SEND_MAX_ATTEMPTS = 5;

/**
 * Exponential backoff base delay (ms).
 *
 * BullMQ formula: delay × 2^(attempt-1)
 *   Attempt 1 fail -> wait 30s -> attempt 2
 *   Attempt 2 fail -> wait 60s -> attempt 3
 *   Attempt 3 fail -> wait 120s -> attempt 4
 *   Attempt 4 fail -> wait 240s -> attempt 5
 *   Attempt 5 fail -> wait 480s -> EXHAUSTED (on('failed') handler mark tracking error per D-13)
 */
export const LGSP_SEND_BACKOFF_DELAY = 30_000;

/** Job timeout (ms) — handler must finish trong gioi han nay (60s LGSP + 30s build/MinIO) */
export const LGSP_SEND_JOB_TIMEOUT = 90_000;

/**
 * Job data shape — IDs only (worker re-fetch fresh from DB + MinIO per attempt).
 *
 * Backend producer (backend/src/lib/queue/lgsp-send-queue.ts) duplicate interface
 * vi 2 module rieng (KHONG share import path).
 */
export interface LgspSendJobData {
  /** outgoing_doc_recipients.id (BIGINT) — 1 job = 1 external recipient (granularity D-02) */
  recipient_id: number;
  /** outgoing_docs.id (BIGINT) */
  outgoing_doc_id: number;
  /** lgsp_tracking.id (BIGINT) — created by SP fn_outgoing_doc_send_to_recipients */
  tracking_id: number;
  /** Root unit_id cua DN gui (departments.id, must have lgsp_org_code) */
  sender_unit_id: number;
  /** Environment — lookup lgsp_agency_config WHERE unit_id=X AND environment=this */
  environment: 'sandbox' | 'prod';
}
