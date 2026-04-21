import { callFunction, callFunctionOne, rawQuery } from '../lib/db/query.js';
import { resolveAncestorUnit } from '../lib/department-subtree.js';

// ============ Row types ============

export interface NoticeListRow {
  id: number;
  unit_id: number;
  title: string;
  content: string;
  notice_type: string | null;
  created_by: number;
  // NOTE: fn_notice_get_list does NOT return created_by_name — only created_by
  created_at: string;
  is_read: boolean;
  total_count: number;
}

export interface NoticeActionResult {
  success: boolean;
  message: string;
}

export interface NoticeCreateResult {
  success: boolean;
  message: string;
  id: number;
}

export interface MarkAllReadResult {
  success: boolean;
  message: string;
  count: number;
}

// ============ Repository ============

export const noticeRepository = {

  async getList(
    unitId: number,
    staffId: number,
    isRead: boolean | null,
    page: number,
    pageSize: number,
  ): Promise<NoticeListRow[]> {
    return callFunction<NoticeListRow>('edoc.fn_notice_get_list', [
      unitId, staffId, isRead ?? null, page, pageSize,
    ]);
  },

  async create(
    unitId: number,
    title: string,
    content: string,
    noticeType: string | null,
    createdBy: number,
  ): Promise<NoticeCreateResult> {
    const row = await callFunctionOne<NoticeCreateResult>('edoc.fn_notice_create', [
      unitId, title, content, noticeType, createdBy,
    ]);
    return row ?? { success: false, message: 'Không thể tạo thông báo', id: 0 };
  },

  async markRead(noticeId: number, staffId: number): Promise<NoticeActionResult> {
    const row = await callFunctionOne<NoticeActionResult>('edoc.fn_notice_mark_read', [
      noticeId, staffId,
    ]);
    return row ?? { success: false, message: 'Không tìm thấy thông báo' };
  },

  async markAllRead(staffId: number, unitId: number): Promise<MarkAllReadResult> {
    const row = await callFunctionOne<MarkAllReadResult>('edoc.fn_notice_mark_all_read', [
      staffId, unitId,
    ]);
    return row ?? { success: true, message: 'Đã đánh dấu đã đọc', count: 0 };
  },

  async countUnread(staffId: number): Promise<number> {
    const row = await callFunctionOne<{ count: bigint }>('edoc.fn_notice_count_unread', [staffId]);
    return row ? Number(row.count) : 0;
  },

  /**
   * Tạo thông báo cá nhân cho 1 staff (Phase 11 — sign result notification).
   *
   * Pragmatic v2.0: reuse `fn_notice_create` (unit-wide) với `notice_type='SIGN_RESULT'`.
   * Flow:
   *   1. Tra `staff.department_id` bằng raw query (không có SP dedicated).
   *   2. `resolveAncestorUnit(departmentId)` → ancestor unit (is_unit=true).
   *   3. `fn_notice_create(unitId, title, content, 'SIGN_RESULT', staffId)` — dùng staffId
   *      làm `created_by` để `fn_notice_get_list` filter "notice mình tạo + notice cùng unit".
   *
   * Hạn chế v2.0: notice chia sẻ unit-wide (các user cùng đơn vị cũng thấy trong list
   * của họ). Trade-off chấp nhận được vì: (a) sign result rare, (b) title chứa tên user
   * cụ thể, (c) tránh migration schema mới cho Phase 11.
   *
   * TODO v2.1: thêm SP `fn_notice_create_personal(staff_id, ...)` lưu field `target_staff_id`
   * trên edoc.notice — strict per-user audience, không spam unit.
   */
  async createForStaff(
    staffId: number,
    title: string,
    content: string,
    noticeType: string = 'SIGN_RESULT',
  ): Promise<NoticeCreateResult> {
    // 1. Tra department_id của staff
    const deptRows = await rawQuery<{ department_id: number | null }>(
      'SELECT department_id FROM public.staff WHERE id = $1 LIMIT 1',
      [staffId],
    );
    const departmentId = deptRows[0]?.department_id;
    if (!departmentId) {
      return { success: false, message: 'Staff không có department_id', id: 0 };
    }

    // 2. Resolve ancestor unit (catalog-owning đơn vị cha)
    const unitId = await resolveAncestorUnit(departmentId);
    if (!unitId) {
      return { success: false, message: 'Không tìm thấy đơn vị của staff', id: 0 };
    }

    // 3. Reuse create() — single source of truth
    return this.create(unitId, title, content, noticeType, staffId);
  },
};
