import { callFunction, callFunctionOne } from '../lib/db/query.js';
import type { DbResult } from './doc-book.repository.js';
import type { SignAttachmentType } from './sign-transaction.repository.js';

// ============================================================
// Row interfaces — match SPs trong migration 045 EXACTLY (snake_case).
// Đã verify bằng `SELECT pg_get_function_result(oid) FROM pg_proc`:
//
//   fn_attachment_finalize_sign    → (success boolean, message text)
//   fn_attachment_can_sign         → (can_sign boolean, reason text, file_path varchar, file_name varchar)
//   fn_sign_transaction_list_by_staff → (id bigint, provider_code varchar, provider_name varchar,
//                                        attachment_id bigint, attachment_type varchar, file_name varchar,
//                                        doc_id bigint, doc_type varchar, doc_label text,
//                                        status varchar, error_message text,
//                                        created_at timestamptz, completed_at timestamptz, total_count bigint)
//   fn_sign_transaction_count_by_staff → (pending_count bigint, completed_count bigint, failed_count bigint)
// ============================================================

/** edoc.fn_attachment_can_sign output. */
export interface CanSignResult {
  can_sign: boolean;
  reason: string | null;
  file_path: string | null;
  file_name: string | null;
}

/** edoc.fn_sign_transaction_list_by_staff output (1 row per transaction + total_count window). */
export interface SignTransactionListRow {
  id: number;
  provider_code: string;
  provider_name: string | null;
  attachment_id: number;
  attachment_type: string;
  file_name: string | null;
  doc_id: number | null;
  doc_type: string | null;
  doc_label: string | null;
  /**
   * NOTE: SP dùng `"status"` (quoted) vì status là reserved word, nhưng pg driver
   * trả key plain `status` trong JSON → TS field = `status` không cần quote.
   */
  status: string;
  error_message: string | null;
  created_at: string;
  completed_at: string | null;
  total_count: number;
}

/** edoc.fn_sign_transaction_count_by_staff output. */
export interface SignTransactionCounts {
  pending_count: number;
  completed_count: number;
  failed_count: number;
}

/** Valid tab values cho fn_sign_transaction_list_by_staff (failed gộp expired+cancelled). */
export type SignListTab = 'pending' | 'completed' | 'failed';

// ============================================================
// Repository
// ============================================================

export const attachmentSignRepository = {
  /**
   * Finalize attachment sau khi worker embed signature + upload MinIO OK.
   * Update is_ca/ca_date/signed_file_path/sign_provider_code/sign_transaction_id
   * cho 1 trong 4 bảng attachment_* theo `attachmentType`.
   */
  async finalizeSign(params: {
    attachmentId: number;
    attachmentType: SignAttachmentType;
    signedFilePath: string;
    signProviderCode: string;
    signTransactionId: number;
  }): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_attachment_finalize_sign',
      [
        params.attachmentId,
        params.attachmentType,
        params.signedFilePath,
        params.signProviderCode,
        params.signTransactionId,
      ],
    );
    return row ?? { success: false, message: 'Không thể cập nhật file đính kèm' };
  },

  /**
   * Permission check TRƯỚC khi enqueue sign job.
   *
   * CRITICAL: `staffId` PHẢI từ JWT (`req.user.staffId`), KHÔNG từ body
   * (mitigate T-11-01 Tampering — xem threat model Plan 11-01).
   *
   * Trả `{can_sign, reason, file_path, file_name}` — route dùng luôn
   * `file_path` để download MinIO (tránh query lần 2).
   */
  async canSign(
    attachmentId: number,
    attachmentType: SignAttachmentType,
    staffId: number,
  ): Promise<CanSignResult> {
    const row = await callFunctionOne<CanSignResult>(
      'edoc.fn_attachment_can_sign',
      [attachmentId, attachmentType, staffId],
    );
    return (
      row ?? {
        can_sign: false,
        reason: 'Không tìm thấy file đính kèm',
        file_path: null,
        file_name: null,
      }
    );
  },

  /**
   * List transactions theo tab (pending / completed / failed).
   * Failed gộp status IN ('failed','expired','cancelled') — khớp tab UI Phase 12.
   * SP filter `WHERE staff_id = p_staff_id` — mitigate T-11-03 Info Disclosure.
   */
  async listByStaff(
    staffId: number,
    tab: SignListTab,
    page: number,
    pageSize: number,
  ): Promise<SignTransactionListRow[]> {
    return callFunction<SignTransactionListRow>(
      'edoc.fn_sign_transaction_list_by_staff',
      [staffId, tab, page, pageSize],
    );
  },

  /** Badge counts cho 3 tab UI — 1 row với 3 BIGINT. */
  async countByStaff(staffId: number): Promise<SignTransactionCounts> {
    const row = await callFunctionOne<SignTransactionCounts>(
      'edoc.fn_sign_transaction_count_by_staff',
      [staffId],
    );
    return (
      row ?? { pending_count: 0, completed_count: 0, failed_count: 0 }
    );
  },
};
