import { callFunction, callFunctionOne } from '../lib/db/query.js';

// ============================================================
// Row interfaces — match SP RETURNS TABLE columns exactly
// ============================================================

/** edoc.fn_device_token_get_by_staff output */
export interface DeviceTokenRow {
  id: number;
  device_token: string;
  device_type: string;
  is_active: boolean;
  created_at: string;
}

/** edoc.fn_notification_log_get_list output */
export interface NotificationLogRow {
  id: number;
  staff_id: number;
  channel: string;
  event_type: string;
  title: string | null;
  body: string | null;
  ref_type: string | null;
  ref_id: number | null;
  send_status: string;
  error_message: string | null;
  sent_at: string | null;
  created_at: string;
  total_count: number;
}

/** edoc.fn_notification_pref_get_by_staff output */
export interface NotificationPrefRow {
  id: number;
  channel: string;
  is_enabled: boolean;
}

/** Mutation result from upsert/create SPs */
export interface MutationResultRow {
  success: boolean;
  message: string;
  id: number;
}

/** Update/delete result */
export interface UpdateResultRow {
  success: boolean;
  message: string;
}

// ============================================================
// notificationRepository
// ============================================================

export const notificationRepository = {

  // ==========================================
  // DEVICE TOKENS
  // ==========================================

  /**
   * Upsert device token — calls edoc.fn_device_token_upsert
   */
  async upsertDeviceToken(
    staffId: number,
    deviceToken: string,
    deviceType: string,
  ): Promise<MutationResultRow> {
    const row = await callFunctionOne<MutationResultRow>(
      'edoc.fn_device_token_upsert',
      [staffId, deviceToken, deviceType],
    );
    return row ?? { success: false, message: 'Khong the luu device token', id: 0 };
  },

  /**
   * Lay device tokens theo staff — calls edoc.fn_device_token_get_by_staff
   */
  async getDeviceTokensByStaff(
    staffId: number,
  ): Promise<DeviceTokenRow[]> {
    return callFunction<DeviceTokenRow>(
      'edoc.fn_device_token_get_by_staff',
      [staffId],
    );
  },

  /**
   * Xoa device token — calls edoc.fn_device_token_delete
   */
  async deleteDeviceToken(
    id: number,
    staffId: number,
  ): Promise<UpdateResultRow> {
    const row = await callFunctionOne<UpdateResultRow>(
      'edoc.fn_device_token_delete',
      [id, staffId],
    );
    return row ?? { success: false, message: 'Khong the xoa device token' };
  },

  // ==========================================
  // NOTIFICATION LOGS
  // ==========================================

  /**
   * Tao log thong bao — calls edoc.fn_notification_log_create
   */
  async createLog(
    staffId: number,
    channel: string,
    eventType: string,
    title: string | null,
    body: string | null,
    refType: string | null,
    refId: number | null,
  ): Promise<MutationResultRow> {
    const row = await callFunctionOne<MutationResultRow>(
      'edoc.fn_notification_log_create',
      [staffId, channel, eventType, title, body, refType, refId],
    );
    return row ?? { success: false, message: 'Khong the tao log thong bao', id: 0 };
  },

  /**
   * Cap nhat trang thai thong bao — calls edoc.fn_notification_log_update_status
   */
  async updateLogStatus(
    id: number,
    sendStatus: string,
    errorMessage: string | null,
  ): Promise<UpdateResultRow> {
    const row = await callFunctionOne<UpdateResultRow>(
      'edoc.fn_notification_log_update_status',
      [id, sendStatus, errorMessage],
    );
    return row ?? { success: false, message: 'Khong the cap nhat trang thai thong bao' };
  },

  /**
   * Danh sach log thong bao — calls edoc.fn_notification_log_get_list
   */
  async getLogList(
    staffId: number | null,
    channel: string | null,
    sendStatus: string | null,
    page: number,
    pageSize: number,
  ): Promise<NotificationLogRow[]> {
    return callFunction<NotificationLogRow>(
      'edoc.fn_notification_log_get_list',
      [staffId, channel, sendStatus, page, pageSize],
    );
  },

  // ==========================================
  // NOTIFICATION PREFERENCES
  // ==========================================

  /**
   * Upsert cau hinh thong bao — calls edoc.fn_notification_pref_upsert
   */
  async upsertPreference(
    staffId: number,
    channel: string,
    isEnabled: boolean,
  ): Promise<MutationResultRow> {
    const row = await callFunctionOne<MutationResultRow>(
      'edoc.fn_notification_pref_upsert',
      [staffId, channel, isEnabled],
    );
    return row ?? { success: false, message: 'Khong the cap nhat cau hinh thong bao', id: 0 };
  },

  /**
   * Lay cau hinh thong bao theo staff — calls edoc.fn_notification_pref_get_by_staff
   */
  async getPreferences(
    staffId: number,
  ): Promise<NotificationPrefRow[]> {
    return callFunction<NotificationPrefRow>(
      'edoc.fn_notification_pref_get_by_staff',
      [staffId],
    );
  },
};
