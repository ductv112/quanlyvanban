import { callFunction, callFunctionOne } from '../lib/db/query.js';

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
};
