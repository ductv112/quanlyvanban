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
};
