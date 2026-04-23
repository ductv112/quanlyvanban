/**
 * Phase 13 — Bell Notification repository (public.notifications)
 *
 * Persistent bell notifications cho sign_completed + sign_failed events (D-01 → D-07).
 * KHÁC với `notification.repository.ts` (edoc.fn_notification_log_* / _pref_* / device_token_*)
 *   — file đó là multichannel notification infra (email/SMS/push logs, prefs).
 * File này là persistent bell notification UI-facing (table public.notifications).
 *
 * SP namespace: public.fn_notification_{create|list|unread_count|mark_read|mark_all_read}
 * Consumer:
 *   - workers/signing-poll.worker.ts (persist notification TRƯỚC emit Socket)
 *   - routes/notifications.ts (GET list + GET unread-count + PATCH mark-read)
 */

import { callFunction, callFunctionOne } from '../lib/db/query.js';

// =============================================================================
// Row types — snake_case khớp SP output (CLAUDE.md checklist #1)
// =============================================================================

export interface NotificationListRow {
  id: number;
  staff_id: number;
  type: string;
  title: string;
  message: string | null;
  link: string | null;
  metadata: Record<string, unknown> | null;
  is_read: boolean;
  created_at: string;   // ISO string — pg driver trả string (CLAUDE.md checklist #8)
  read_at: string | null;
  total_count: number;
}

export interface NotificationCreateResult {
  success: boolean;
  message: string;
  id: number;
}

export interface NotificationActionResult {
  success: boolean;
  message: string;
}

export interface MarkAllReadResult {
  success: boolean;
  message: string;
  updated_count: number;
}

// =============================================================================
// Repository (const object — pattern thống nhất dự án)
// =============================================================================

/**
 * Bell notification repository (Phase 13).
 * Exported tên khác với `notificationRepository` trong `notification.repository.ts`
 * để tránh collision khi 2 file cùng được import.
 */
export const bellNotificationRepository = {
  /**
   * Tạo notification mới.
   * Gọi từ worker (signing-poll.worker.ts) + route handlers nếu cần.
   */
  async create(
    staffId: number,
    type: string,
    title: string,
    message: string | null,
    link: string | null,
    metadata: Record<string, unknown> | null,
  ): Promise<NotificationCreateResult> {
    const row = await callFunctionOne<NotificationCreateResult>(
      'public.fn_notification_create',
      [staffId, type, title, message, link, metadata],
    );
    return row ?? { success: false, message: 'Không tạo được thông báo', id: 0 };
  },

  /**
   * List notifications của staff, paginated (newest first).
   * Backend convert page → offset trước khi gọi SP (SP chỉ nhận limit/offset).
   */
  async list(
    staffId: number,
    page: number,
    pageSize: number,
  ): Promise<NotificationListRow[]> {
    const offset = Math.max(0, (page - 1) * pageSize);
    return callFunction<NotificationListRow>('public.fn_notification_list', [
      staffId,
      pageSize,
      offset,
    ]);
  },

  /**
   * Unread count (dùng cho badge).
   */
  async unreadCount(staffId: number): Promise<number> {
    const row = await callFunctionOne<{ count: string | number }>(
      'public.fn_notification_unread_count',
      [staffId],
    );
    return Number(row?.count ?? 0);
  },

  /**
   * Mark 1 notification đã đọc. Owner check qua staff_id (IDOR mitigation T-13-02/03).
   */
  async markRead(id: number, staffId: number): Promise<NotificationActionResult> {
    const row = await callFunctionOne<NotificationActionResult>(
      'public.fn_notification_mark_read',
      [id, staffId],
    );
    return row ?? { success: false, message: 'Không tìm thấy thông báo' };
  },

  /**
   * Mark tất cả notification của staff đã đọc.
   */
  async markAllRead(staffId: number): Promise<MarkAllReadResult> {
    const row = await callFunctionOne<MarkAllReadResult>(
      'public.fn_notification_mark_all_read',
      [staffId],
    );
    return row ?? { success: true, message: 'Đã đánh dấu tất cả đã đọc', updated_count: 0 };
  },
};
