import { callFunction, callFunctionOne, rawQuery } from '../lib/db/query.js';
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

/**
 * Phase 36 (Plan 36-01): row cho UI Timeline "Lich su trang thai LGSP".
 * Tat ca cot phai match snake_case tu rawQuery SELECT statement ben duoi.
 */
export interface LgspStatusOutboxHistoryRow {
  id: number;
  target_status: LgspTargetStatus;
  sent_status: 'pending' | 'success' | 'error';
  sent_at: string | null;
  retry_count: number;
  error_message: string | null;
  created_at: string;
}

/**
 * Phase 36 (Plan 36-01): named params cho insertEvent — clearer than positional.
 */
export interface InsertEventParams {
  incoming_doc_id: number;
  target_status: LgspTargetStatus;
  payload: Record<string, unknown>;
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

  /**
   * Phase 36 (Plan 36-01): wrapper goi `edoc.fn_lgsp_status_outbox_insert` (Phase 33 SP) +
   * catch SQLSTATE 23505 unique_violation (do UNIQUE constraint Phase 36-01-Task-1).
   *
   * - Success -> tra ve {success: true, id: <BIGINT>}
   * - Unique violation (dedup) -> tra ve null + log silent (caller xu ly NOOP, KHONG fail action)
   * - FK violation hoac other -> throw (caller log warn nhung KHONG fail user action -- D-03)
   *
   * UNIQUE constraint (incoming_doc_id, target_status) chan double-INSERT khi user spam
   * action (vd: bam "Tiep nhan" 2 lan nhanh). Idempotent — first action tao outbox, second
   * action no-op silently.
   */
  async insertEvent(params: InsertEventParams): Promise<DbResultWithId | null> {
    try {
      const row = await callFunctionOne<DbResultWithId>(
        'edoc.fn_lgsp_status_outbox_insert',
        [params.incoming_doc_id, params.target_status, params.payload],
      );
      if (!row) {
        return { success: false, message: 'Khong the tao outbox event', id: 0 };
      }
      // SP co the tra success=false (vd: check_violation, foreign_key_violation).
      // Pass-through cho caller xu ly.
      return row;
    } catch (err: unknown) {
      // pg driver throws DatabaseError with `code` field for SQLSTATE.
      const sqlState = (err as { code?: string } | undefined)?.code;
      if (sqlState === '23505') {
        // Unique violation -- dedup. Caller skip silently, retorna null.
        return null;
      }
      // 23503 FK violation, 23502 not-null, vv -- let caller decide.
      throw err;
    }
  },

  /**
   * Phase 36 (Plan 36-01): query history cua 1 incoming_doc cho UI Timeline (Plan 36-04).
   *
   * Returns ALL outbox events cho 1 doc, ORDER BY created_at ASC (chronological).
   * Includes pending + success + error rows (UI render khac mau per sent_status).
   *
   * Dung rawQuery thay vi SP rieng -- query don gian, khong can SP overhead.
   * Backend Plan 36-03 expose qua GET /api/van-ban-den/:id/lgsp-status-history.
   */
  async getDocStatusHistory(incomingDocId: number): Promise<LgspStatusOutboxHistoryRow[]> {
    return rawQuery<LgspStatusOutboxHistoryRow>(
      `SELECT id,
              target_status,
              sent_status,
              sent_at,
              retry_count,
              error_message,
              created_at
         FROM edoc.lgsp_status_outbox
        WHERE incoming_doc_id = $1
        ORDER BY created_at ASC`,
      [incomingDocId],
    );
  },
};
