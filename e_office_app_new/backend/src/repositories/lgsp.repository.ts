import { callFunction, callFunctionOne, rawQuery } from '../lib/db/query.js';

// ============================================================
// Row interfaces — match SP RETURNS TABLE columns exactly
// ============================================================

/** edoc.fn_lgsp_org_get_list output */
export interface LgspOrgRow {
  id: number;
  org_code: string;
  org_name: string;
  parent_code: string | null;
  address: string | null;
  email: string | null;
  phone: string | null;
  is_active: boolean;
  synced_at: string;
  total_count: number;
}

/** edoc.fn_lgsp_tracking_get_list output */
export interface LgspTrackingRow {
  id: number;
  outgoing_doc_id: number | null;
  incoming_doc_id: number | null;
  direction: string;
  lgsp_doc_id: string | null;
  dest_org_code: string | null;
  dest_org_name: string | null;
  status: string;
  error_message: string | null;
  sent_at: string | null;
  received_at: string | null;
  created_at: string;
  total_count: number;
}

/** edoc.fn_lgsp_tracking_get_by_doc output */
export interface LgspTrackingByDocRow {
  id: number;
  direction: string;
  lgsp_doc_id: string | null;
  dest_org_code: string | null;
  dest_org_name: string | null;
  status: string;
  error_message: string | null;
  sent_at: string | null;
  created_at: string;
}

/** Mutation result from fn_lgsp_org_sync, fn_lgsp_tracking_create */
export interface MutationResultRow {
  success: boolean;
  message: string;
  id: number;
}

/** Update result from fn_lgsp_tracking_update_status */
export interface UpdateResultRow {
  success: boolean;
  message: string;
}

/**
 * Phase 37: Row đầy đủ để admin "Gửi lại" send job — cần outgoing_doc_id để re-enqueue.
 * JOIN outgoing_doc_recipients (qua generated_lgsp_tracking_id) để lấy recipient_id;
 * JOIN outgoing_docs để lấy sender_unit_id; JOIN lgsp_agency_config để resolve active env.
 */
export interface LgspTrackingFullRow {
  id: number;
  outgoing_doc_id: number;
  recipient_id: number;
  sender_unit_id: number;
  environment: 'sandbox' | 'prod';
  status: string;
  error_message: string | null;
}

/**
 * Phase 37 Plan 37-02: Dashboard overview row per root unit (DN).
 *
 * Aggregate count today (DATE = CURRENT_DATE) cho 4 metric:
 *   - send: lgsp_tracking direction='send' grouped by outgoing_docs.unit_id
 *   - receive: incoming_docs WHERE source_type='external_lgsp' grouped by unit_id
 *   - outbox: lgsp_status_outbox JOIN incoming_docs grouped by unit_id
 *
 * 6 DN (Lạng Sơn) × 2 env config → 6 row (env stacked horizontally trong cùng row,
 * NULL nếu DN chưa cấu hình env đó).
 *
 * Source: GET /api/admin/lgsp-overview cho Plan 37-04 dashboard UI.
 */
export interface LgspOverviewRow {
  unit_id: number;
  unit_name: string;
  lgsp_org_code: string | null;
  prod_config_id: number | null;
  prod_is_active: boolean | null;
  prod_last_synced_at: string | null;
  prod_last_sync_error: string | null;
  sandbox_config_id: number | null;
  sandbox_is_active: boolean | null;
  sandbox_last_synced_at: string | null;
  sandbox_last_sync_error: string | null;
  send_today_total: number;
  send_today_success: number;
  send_today_error: number;
  send_today_pending: number;
  receive_today_total: number;
  outbox_today_pending: number;
  outbox_today_error: number;
}

// ============================================================
// lgspRepository
// ============================================================

export const lgspRepository = {

  // ==========================================
  // CO QUAN LIEN THONG (ORGANIZATIONS)
  // ==========================================

  /**
   * Upsert co quan lien thong — calls edoc.fn_lgsp_org_sync
   */
  async syncOrg(
    orgCode: string,
    orgName: string,
    parentCode: string | null,
    address: string | null,
    email: string | null,
    phone: string | null,
  ): Promise<MutationResultRow> {
    const row = await callFunctionOne<MutationResultRow>(
      'edoc.fn_lgsp_org_sync',
      [orgCode, orgName, parentCode, address, email, phone],
    );
    return row ?? { success: false, message: 'Khong the dong bo co quan', id: 0 };
  },

  /**
   * Danh sach co quan lien thong — calls edoc.fn_lgsp_org_get_list
   */
  async getOrgList(
    search: string | null,
    page: number,
    pageSize: number,
  ): Promise<LgspOrgRow[]> {
    return callFunction<LgspOrgRow>(
      'edoc.fn_lgsp_org_get_list',
      [search, page, pageSize],
    );
  },

  // ==========================================
  // TRACKING LIEN THONG
  // ==========================================

  /**
   * Tao tracking record — calls edoc.fn_lgsp_tracking_create
   */
  async createTracking(
    outgoingDocId: number | null,
    direction: string,
    destOrgCode: string | null,
    destOrgName: string | null,
    edxmlContent: string | null,
    createdBy: number | null,
  ): Promise<MutationResultRow> {
    const row = await callFunctionOne<MutationResultRow>(
      'edoc.fn_lgsp_tracking_create',
      [outgoingDocId, direction, destOrgCode, destOrgName, edxmlContent, createdBy],
    );
    return row ?? { success: false, message: 'Khong the tao tracking', id: 0 };
  },

  /**
   * Cap nhat trang thai tracking — calls edoc.fn_lgsp_tracking_update_status
   */
  async updateTrackingStatus(
    id: number,
    status: string,
    lgspDocId: string | null,
    errorMessage: string | null,
  ): Promise<UpdateResultRow> {
    const row = await callFunctionOne<UpdateResultRow>(
      'edoc.fn_lgsp_tracking_update_status',
      [id, status, lgspDocId, errorMessage],
    );
    return row ?? { success: false, message: 'Khong the cap nhat tracking' };
  },

  /**
   * Danh sach tracking — calls edoc.fn_lgsp_tracking_get_list
   */
  async getTrackingList(
    direction: string | null,
    status: string | null,
    page: number,
    pageSize: number,
  ): Promise<LgspTrackingRow[]> {
    return callFunction<LgspTrackingRow>(
      'edoc.fn_lgsp_tracking_get_list',
      [direction, status, page, pageSize],
    );
  },

  /**
   * Tracking theo van ban di — calls edoc.fn_lgsp_tracking_get_by_doc
   */
  async getTrackingByDoc(
    outgoingDocId: number,
  ): Promise<LgspTrackingByDocRow[]> {
    return callFunction<LgspTrackingByDocRow>(
      'edoc.fn_lgsp_tracking_get_by_doc',
      [outgoingDocId],
    );
  },

  // ==========================================
  // Phase 37 — Admin retry methods
  // ==========================================

  /**
   * Phase 37: Lấy tracking row + outgoing_doc_id + recipient_id + sender_unit_id + active env.
   * JOIN outgoing_doc_recipients qua generated_lgsp_tracking_id (Phase 34 wiring) để lấy recipient_id.
   * JOIN lgsp_agency_config để resolve environment đang active của sender (preferring 'prod').
   *
   * Trả null nếu tracking không tồn tại HOẶC không có config LGSP active cho đơn vị gửi.
   */
  async getTrackingForRetry(trackingId: number): Promise<LgspTrackingFullRow | null> {
    const rows = await rawQuery<{
      id: string;
      outgoing_doc_id: string;
      recipient_id: string | null;
      sender_unit_id: number | null;
      environment: 'sandbox' | 'prod' | null;
      status: string;
      error_message: string | null;
    }>(
      `SELECT t.id                          AS id,
              t.outgoing_doc_id             AS outgoing_doc_id,
              r.id                          AS recipient_id,
              od.unit_id                    AS sender_unit_id,
              ac.environment                AS environment,
              t.status                      AS status,
              t.error_message               AS error_message
         FROM edoc.lgsp_tracking t
         JOIN edoc.outgoing_docs od ON od.id = t.outgoing_doc_id
    LEFT JOIN edoc.outgoing_doc_recipients r
              ON r.generated_lgsp_tracking_id = t.id
    LEFT JOIN edoc.lgsp_agency_config ac
              ON ac.unit_id = od.unit_id
             AND ac.is_active = TRUE
        WHERE t.id = $1
        ORDER BY (ac.environment = 'prod') DESC NULLS LAST
        LIMIT 1`,
      [trackingId],
    );
    if (rows.length === 0) return null;
    const r = rows[0];
    if (r.recipient_id == null || r.sender_unit_id == null || r.environment == null) {
      return null;
    }
    return {
      id: Number(r.id),
      outgoing_doc_id: Number(r.outgoing_doc_id),
      recipient_id: Number(r.recipient_id),
      sender_unit_id: Number(r.sender_unit_id),
      environment: r.environment,
      status: r.status,
      error_message: r.error_message,
    };
  },

  /**
   * Phase 37: Reset tracking về 'pending' + clear error_message để worker xử lý lại.
   *
   * Guard: chỉ reset row có status='error' (idempotent).
   */
  async resetTrackingForRetry(trackingId: number): Promise<UpdateResultRow> {
    const rows = await rawQuery<{ id: string }>(
      `UPDATE edoc.lgsp_tracking
          SET status = 'pending',
              error_message = NULL
        WHERE id = $1 AND status = 'error'
        RETURNING id`,
      [trackingId],
    );
    if (rows.length === 0) {
      return {
        success: false,
        message: 'Không tìm thấy tracking đang lỗi với id này',
      };
    }
    return { success: true, message: 'Đã reset tracking, worker sẽ gửi lại' };
  },

  // ==========================================
  // Phase 37 Plan 37-02 — Admin overview dashboard
  // ==========================================

  /**
   * Phase 37 Plan 37-02: Get overview stats per root unit (6 DN Lạng Sơn).
   *
   * Strategy:
   *   - Base CTE = root unit có `lgsp_org_code IS NOT NULL` (6 DN)
   *   - LEFT JOIN `lgsp_agency_config` per env (prod/sandbox stacked horizontally)
   *   - LEFT JOIN aggregation send (lgsp_tracking direction='send' grouped by outgoing_docs.unit_id)
   *   - LEFT JOIN aggregation receive (incoming_docs WHERE source_type='external_lgsp' grouped by unit_id)
   *   - LEFT JOIN aggregation outbox (lgsp_status_outbox JOIN incoming_docs grouped by unit_id)
   *
   * Verified schema (2026-05-21 \d):
   *   - lgsp_tracking: status ∈ {pending, processing, success, error}; direction ∈ {send, receive}
   *   - lgsp_status_outbox: sent_status ∈ {pending, success, error}
   *   - incoming_docs: source_type enum doc_source_type — value 'external_lgsp' (Phase 35)
   *   - departments.lgsp_org_code VARCHAR(13) NULL — root unit Lạng Sơn DN
   *
   * Used by GET /api/admin/lgsp-overview (Plan 37-02 route, Plan 37-04 frontend UI).
   *
   * Phase 37.5 fix HIGH #3:
   * - Optional unitIds filter (caller passes user's accessible units) — admin global = NULL/empty,
   *   non-admin scoped = [unitId list]. Prevents cross-DN data leak khi multi-tenant.
   * - Replace `created_at::date = CURRENT_DATE` (functional cast, KHÔNG dùng index) bằng
   *   `created_at >= date_trunc('day', NOW())` (range query, dùng index trên created_at).
   */
  async getOverviewStats(unitIds?: number[]): Promise<LgspOverviewRow[]> {
    const useFilter = Array.isArray(unitIds) && unitIds.length > 0;
    const unitFilter = useFilter
      ? 'WHERE ru.unit_id = ANY($1::bigint[])'
      : '';
    const params = useFilter ? [unitIds] : [];
    return rawQuery<LgspOverviewRow>(
      `WITH root_units AS (
          SELECT id::bigint AS unit_id, name AS unit_name, lgsp_org_code
            FROM public.departments
           WHERE lgsp_org_code IS NOT NULL
        ),
        send_today AS (
          SELECT od.unit_id::bigint AS unit_id,
                 COUNT(*)::bigint AS total,
                 COUNT(*) FILTER (WHERE t.status = 'success')::bigint AS success,
                 COUNT(*) FILTER (WHERE t.status = 'error')::bigint   AS error,
                 COUNT(*) FILTER (WHERE t.status = 'pending')::bigint AS pending
            FROM edoc.lgsp_tracking t
            JOIN edoc.outgoing_docs od ON od.id = t.outgoing_doc_id
           WHERE t.direction = 'send'
             AND t.created_at >= date_trunc('day', NOW())
           GROUP BY od.unit_id
        ),
        receive_today AS (
          SELECT ind.unit_id::bigint AS unit_id,
                 COUNT(*)::bigint AS total
            FROM edoc.incoming_docs ind
           WHERE ind.source_type = 'external_lgsp'
             AND ind.created_at >= date_trunc('day', NOW())
           GROUP BY ind.unit_id
        ),
        outbox_today AS (
          SELECT ind.unit_id::bigint AS unit_id,
                 COUNT(*) FILTER (WHERE o.sent_status = 'pending')::bigint AS pending,
                 COUNT(*) FILTER (WHERE o.sent_status = 'error')::bigint   AS error
            FROM edoc.lgsp_status_outbox o
            JOIN edoc.incoming_docs ind ON ind.id = o.incoming_doc_id
           WHERE o.created_at >= date_trunc('day', NOW())
           GROUP BY ind.unit_id
        )
        SELECT ru.unit_id,
               ru.unit_name,
               ru.lgsp_org_code,
               prod.id::bigint                AS prod_config_id,
               prod.is_active                 AS prod_is_active,
               prod.last_synced_at            AS prod_last_synced_at,
               prod.last_sync_error           AS prod_last_sync_error,
               sb.id::bigint                  AS sandbox_config_id,
               sb.is_active                   AS sandbox_is_active,
               sb.last_synced_at              AS sandbox_last_synced_at,
               sb.last_sync_error             AS sandbox_last_sync_error,
               COALESCE(st.total,   0)::bigint   AS send_today_total,
               COALESCE(st.success, 0)::bigint   AS send_today_success,
               COALESCE(st.error,   0)::bigint   AS send_today_error,
               COALESCE(st.pending, 0)::bigint   AS send_today_pending,
               COALESCE(rt.total,   0)::bigint   AS receive_today_total,
               COALESCE(ot.pending, 0)::bigint   AS outbox_today_pending,
               COALESCE(ot.error,   0)::bigint   AS outbox_today_error
          FROM root_units ru
          LEFT JOIN edoc.lgsp_agency_config prod
                 ON prod.unit_id = ru.unit_id AND prod.environment = 'prod'
          LEFT JOIN edoc.lgsp_agency_config sb
                 ON sb.unit_id = ru.unit_id AND sb.environment = 'sandbox'
          LEFT JOIN send_today    st ON st.unit_id = ru.unit_id
          LEFT JOIN receive_today rt ON rt.unit_id = ru.unit_id
          LEFT JOIN outbox_today  ot ON ot.unit_id = ru.unit_id
         ${unitFilter}
         ORDER BY ru.lgsp_org_code`,
      params,
    );
  },
};
