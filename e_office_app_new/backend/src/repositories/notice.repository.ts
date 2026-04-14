import { callFunction, callFunctionOne } from '../lib/db/query.js';

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
};
