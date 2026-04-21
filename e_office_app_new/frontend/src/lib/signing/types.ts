/**
 * Frontend TypeScript types cho Phase 11 sign flow.
 * Mirror shapes từ backend routes 11-03 + 11-04 (POST /api/ky-so/sign, GET /:id,
 * POST /:id/cancel, Socket.IO events sign_completed / sign_failed).
 *
 * Shared cho SignModal component + useSigning hook + detail page consumers
 * (Plans 11-07/08/09 sẽ wire hook vào VB đi, VB dự thảo, HSCV).
 */

/** Loại attachment — match backend `SignAttachmentType` (sign-transaction.repository). */
export type AttachmentType = 'outgoing' | 'drafting' | 'handling' | 'incoming';

/** Terminal + pending states cho sign_transactions.status. */
export type TxnStatus = 'pending' | 'completed' | 'failed' | 'cancelled' | 'expired';

/** Provider code enum — match backend `ProviderCode`. */
export type ProviderCode = 'SMARTCA_VNPT' | 'MYSIGN_VIETTEL';

/** Request body khi POST /api/ky-so/sign. */
export interface SignPayload {
  attachment_id: number;
  attachment_type: AttachmentType;
  doc_id?: number;
  sign_reason?: string;
  sign_location?: string;
}

/** Response 201 data từ POST /api/ky-so/sign. */
export interface SignResponseData {
  transaction_id: number;
  provider_transaction_id: string;
  provider_code: ProviderCode;
  /** Backend không luôn trả provider_message — optional */
  provider_message?: string | null;
  elapsed_ms: number;
}

/** Response data từ GET /api/ky-so/sign/:id (full transaction snapshot). */
export interface TxnStatusData {
  id: number;
  status: TxnStatus;
  provider_code: string;
  provider_txn_id: string | null;
  attachment_id: number;
  attachment_type: string;
  doc_id: number | null;
  doc_type: string | null;
  error_message: string | null;
  retry_count: number;
  created_at: string;
  started_at: string | null;
  completed_at: string | null;
  expires_at: string | null;
  signed_file_path: string | null;
}

/**
 * Payload trên Socket.IO event 'sign_completed'.
 * Emit từ backend workers/signing-poll.worker.ts → room `user_{staffId}`.
 */
export interface SignCompletedEvent {
  transaction_id: number;
  provider_code: string;
  attachment_id: number;
  attachment_type: string;
  doc_id: number | null;
  doc_type: string | null;
  signed_file_path: string;
  /** ISO 8601 */
  completed_at: string;
}

/**
 * Payload trên Socket.IO event 'sign_failed'.
 * Emit từ backend khi provider reject, expire, hoặc user cancel.
 */
export interface SignFailedEvent {
  transaction_id: number;
  provider_code: string;
  attachment_id: number;
  attachment_type: string;
  error_message: string;
  /** Terminal status: failed | expired | cancelled */
  status: 'failed' | 'expired' | 'cancelled';
}
