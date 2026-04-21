import { callFunction, callFunctionOne } from '../lib/db/query.js';
import type { DbResult, DbResultWithId } from './doc-book.repository.js';

// ============================================================
// Row interfaces — match edoc.fn_sign_transaction_* SPs (snake_case từ DB)
// Source of truth: database/migrations/040_signing_schema.sql
//
// NOTE: SP dùng `"status"` (quoted double-quotes) vì `status` là reserved word.
// pg driver trả key plain `status` (không quote trong JSON row) → TS field = `status` bình thường.
// ============================================================

/** edoc.fn_sign_transaction_get_by_id output (full context cho worker + audit). */
export interface SignTransactionRow {
  id: number;
  staff_id: number;
  provider_code: string;
  provider_txn_id: string | null;
  attachment_id: number;
  attachment_type: string; // 'incoming' | 'outgoing' | 'drafting' | 'handling'
  doc_id: number | null;
  doc_type: string | null;
  file_hash_sha256: string | null;
  signature_base64: string | null;
  signed_file_path: string | null;
  status: string; // 'pending' | 'completed' | 'failed' | 'cancelled' | 'expired'
  error_message: string | null;
  retry_count: number;
  created_at: string;
  started_at: string | null;
  completed_at: string | null;
  expires_at: string | null;
}

/**
 * edoc.fn_sign_transaction_increment_retry output.
 *
 * NOTE: SP trả `new_retry_count` (KHÔNG phải `retry_count`) — vì RETURNS TABLE name
 * đặt khác tên cột để tránh PL/pgSQL ambiguity. Dùng đúng tên SP trả về, KHÔNG alias.
 */
export interface IncrementRetryRow {
  success: boolean;
  new_retry_count: number;
}

// Discriminated union type cho attachment_type (dùng ở call site để type-safe hơn)
export type SignAttachmentType = 'incoming' | 'outgoing' | 'drafting' | 'handling';

// Terminal failure statuses cho fn_sign_transaction_update_status
export type SignTerminalStatus = 'failed' | 'expired' | 'cancelled';

// ============================================================
// Repository
// ============================================================

export const signTransactionRepository = {
  /**
   * Tạo transaction mới (SP tự set `status='pending'`, `expires_at = NOW() + 3 phút`).
   * `attachment_type` CHECK: `incoming | outgoing | drafting | handling`.
   */
  async create(params: {
    staffId: number;
    providerCode: string;
    attachmentId: number;
    attachmentType: SignAttachmentType;
    docId: number | null;
    docType: string | null;
    fileHashSha256: string | null;
  }): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>(
      'edoc.fn_sign_transaction_create',
      [
        params.staffId,
        params.providerCode,
        params.attachmentId,
        params.attachmentType,
        params.docId,
        params.docType,
        params.fileHashSha256,
      ],
    );
    return row ?? { success: false, message: 'Không thể tạo giao dịch ký số', id: 0 };
  },

  /**
   * Lưu `provider_txn_id` (sau khi call provider API thành công — nhận lại ID phía provider).
   * SP cũng set `started_at = NOW()`. Chỉ update được nếu `status='pending'`.
   */
  async setProviderTxn(id: number, providerTxnId: string): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_sign_transaction_set_provider_txn',
      [id, providerTxnId],
    );
    return row ?? { success: false, message: 'Không thể cập nhật provider_txn_id' };
  },

  /**
   * Hoàn tất transaction (provider đã trả signature). SP set `status='completed'`,
   * lưu `signature_base64` + `signed_file_path` + `completed_at = NOW()`.
   * Chỉ update được nếu `status='pending'` (guard against double-complete).
   */
  async complete(
    id: number,
    signatureBase64: string,
    signedFilePath: string,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_sign_transaction_complete',
      [id, signatureBase64, signedFilePath],
    );
    return row ?? { success: false, message: 'Không thể hoàn tất giao dịch' };
  },

  /**
   * Chuyển transaction sang trạng thái terminal (failed / expired / cancelled).
   * Dùng 1 SP gộp cho 3 failure mode (SP validate `p_status IN (failed, expired, cancelled)`).
   * Chỉ update được nếu `status='pending'`.
   */
  async updateStatus(
    id: number,
    status: SignTerminalStatus,
    errorMessage: string | null,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_sign_transaction_update_status',
      [id, status, errorMessage],
    );
    return row ?? { success: false, message: 'Không thể cập nhật trạng thái' };
  },

  /**
   * Increment retry_count (worker mỗi lần poll provider thất bại tạm thời).
   * SP trả `{ success, new_retry_count }` — tên `new_retry_count` khác tên cột để
   * tránh PL/pgSQL ambiguity trong UPDATE statement.
   */
  async incrementRetry(id: number): Promise<IncrementRetryRow> {
    const row = await callFunctionOne<IncrementRetryRow>(
      'edoc.fn_sign_transaction_increment_retry',
      [id],
    );
    return row ?? { success: false, new_retry_count: 0 };
  },

  /** Lấy transaction full context theo ID (worker + audit + modal ký UI). */
  async getById(id: number): Promise<SignTransactionRow | null> {
    return callFunctionOne<SignTransactionRow>(
      'edoc.fn_sign_transaction_get_by_id',
      [id],
    );
  },
};
