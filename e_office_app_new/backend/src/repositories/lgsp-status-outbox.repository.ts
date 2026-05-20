import { callFunction, callFunctionOne } from '../lib/db/query.js';
import type { DbResult, DbResultWithId } from './doc-book.repository.js';

// ============================================================
// Row interfaces — match SP RETURNS TABLE columns EXACTLY (snake_case)
// Source of truth: e_office_app_new/database/schema/000_schema_v3.0.sql Phase 33 section
// ============================================================

/** 9 mã trạng thái QĐ 28/2018 — Phase 36 sẽ wire auto-fire logic */
export type LgspTargetStatus = '01' | '02' | '03' | '04' | '05' | '06' | '13' | '15' | '16';

/** `edoc.fn_lgsp_status_outbox_get_pending` output (worker poll) */
export interface LgspStatusOutboxPendingRow {
  id: number;
  incoming_doc_id: number;
  target_status: LgspTargetStatus;
  payload: Record<string, unknown>;
  retry_count: number;
  next_retry_at: string | null;
  created_at: string;
}

// ============================================================
// Repository — export const object (KHÔNG class)
// ============================================================

export const lgspStatusOutboxRepository = {
  /**
   * Insert outbox event. Phase 36 backend services gọi method này khi trigger status change.
   *
   * @param payload JSONB — Phase 36 worker đọc khi đẩy lên trục
   *   { lgsp_doc_id, sender_org_code, reason?, ... }
   */
  async insert(
    incomingDocId: number,
    targetStatus: LgspTargetStatus,
    payload: Record<string, unknown>,
  ): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>(
      'edoc.fn_lgsp_status_outbox_insert',
      [incomingDocId, targetStatus, payload],
    );
    return row ?? { success: false, message: 'Không thể tạo outbox event', id: 0 };
  },

  /**
   * Poll pending events. Phase 36 worker gọi mỗi 30s.
   *
   * Returns oldest pending first (partial index `WHERE sent_status='pending' ORDER BY created_at`).
   * Filter `next_retry_at IS NULL OR next_retry_at <= NOW()` — không poll lại event đang chờ retry.
   *
   * @param limit Default 10 (batch size để tránh worker overload)
   */
  async getPending(limit: number = 10): Promise<LgspStatusOutboxPendingRow[]> {
    return callFunction<LgspStatusOutboxPendingRow>(
      'edoc.fn_lgsp_status_outbox_get_pending',
      [limit],
    );
  },

  /**
   * Mark event success sau khi worker đẩy thành công lên trục.
   *
   * @param sentAt Optional — default NOW() trong SP
   */
  async markSent(id: number, sentAt?: string): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_lgsp_status_outbox_mark_sent',
      [id, sentAt ?? null],
    );
    return row ?? { success: false, message: 'Không thể đánh dấu outbox sent' };
  },

  /**
   * Mark event error sau khi worker fail.
   *
   * - `nextRetryAt = TIMESTAMPTZ` → giữ sent_status='pending' để retry
   * - `nextRetryAt = null` → final fail, set sent_status='error' (giving up)
   *
   * Phase 36 worker tính `nextRetryAt` theo exponential backoff (1m, 5m, 30m, 2h, 6h) — max 5 retry.
   */
  async markError(
    id: number,
    errorMessage: string,
    nextRetryAt: string | null,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_lgsp_status_outbox_mark_error',
      [id, errorMessage, nextRetryAt],
    );
    return row ?? { success: false, message: 'Không thể đánh dấu outbox error' };
  },
};
