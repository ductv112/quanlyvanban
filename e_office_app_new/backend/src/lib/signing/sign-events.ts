/**
 * Socket.IO events specific to sign flow (Phase 11).
 * Extends lib/socket.ts SOCKET_EVENTS với 2 sign-specific events.
 *
 * Room target: `user_{staffId}` — mỗi user tự join room này khi Socket.IO
 * connect (xem lib/socket.ts connection handler). JWT middleware của Socket.IO
 * enforce chỉ user đã authenticate mới nhận được event — user A không thể
 * subscribe room user_B (mitigate T-11-14 Information Disclosure).
 *
 * Frontend contract (dùng bởi Plan 06 SignModal + bell notification):
 *   - sign_completed: { transaction_id, provider_code, attachment_id,
 *                       attachment_type, doc_id, doc_type, signed_file_path,
 *                       completed_at }
 *   - sign_failed:    { transaction_id, provider_code, attachment_id,
 *                       attachment_type, error_message, status }
 *
 * Consumer:
 *   - workers/signing-poll.worker.ts gọi emitSignCompleted/emitSignFailed
 *   - frontend Plan 07 SignModal listen event để close modal + refresh UI
 */

import { emitToUser } from '../socket.js';

export const SIGN_EVENTS = {
  SIGN_COMPLETED: 'sign_completed',
  SIGN_FAILED: 'sign_failed',
} as const;

export type SignEventName = (typeof SIGN_EVENTS)[keyof typeof SIGN_EVENTS];

/** Payload emit khi worker đã embed signature + upload signed PDF thành công. */
export interface SignCompletedPayload {
  transaction_id: number;
  provider_code: string;
  attachment_id: number;
  attachment_type: string;
  doc_id: number | null;
  doc_type: string | null;
  signed_file_path: string;
  /** ISO 8601 string — thời điểm worker finalize */
  completed_at: string;
}

/** Payload emit khi worker fail/expire/cancel transaction. */
export interface SignFailedPayload {
  transaction_id: number;
  provider_code: string;
  attachment_id: number;
  attachment_type: string;
  error_message: string;
  /** Terminal status từ sign_transactions — giúp FE phân biệt expire vs reject */
  status: 'failed' | 'expired' | 'cancelled';
}

/**
 * Emit sign_completed tới user (room user_{staffId}).
 * Silently fail nếu Socket.IO chưa init hoặc user offline — emit chỉ là best-effort
 * kênh real-time; bell notification (Phase 11 Task 3) là kênh persistent.
 */
export function emitSignCompleted(staffId: number, payload: SignCompletedPayload): void {
  emitToUser(staffId, SIGN_EVENTS.SIGN_COMPLETED, payload);
}

/**
 * Emit sign_failed tới user (room user_{staffId}).
 * Silently fail tương tự emitSignCompleted — bell notification là fallback.
 */
export function emitSignFailed(staffId: number, payload: SignFailedPayload): void {
  emitToUser(staffId, SIGN_EVENTS.SIGN_FAILED, payload);
}
