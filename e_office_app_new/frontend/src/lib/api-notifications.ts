/**
 * API client cho bell notifications (Phase 13 — Plan 13-02).
 *
 * Consume endpoints backend Plan 13-01 (repositories/notifications.repository.ts +
 * routes/notifications.ts, mount tại /api/notifications với authenticate middleware):
 *
 *   GET    /api/notifications?page=1&page_size=10
 *   GET    /api/notifications/unread-count
 *   PATCH  /api/notifications/:id/read
 *   PATCH  /api/notifications/read-all
 *
 * Axios instance @/lib/api có baseURL='/api' sẵn → path dùng '/notifications/...'
 * KHÔNG '/api/notifications/...' (tránh double /api/, khớp convention Plan 12-02).
 *
 * Field naming: snake_case khớp BE output (CLAUDE.md checklist #1 — SP trả snake_case
 * thì FE KHÔNG rename sang camelCase).
 */

import { api } from './api';

// =============================================================================
// Types
// =============================================================================

/**
 * Phần tử notification trả về cho bell dropdown.
 * Snake_case khớp SP output fn_notification_list + route handler mapping
 * (repositories/notifications.repository.ts — NotificationListRow, minus total_count).
 */
export interface PersonalNotification {
  id: number;
  type: string;        // 'sign_completed' | 'sign_failed' (Phase 13 scope)
  title: string;
  message: string | null;
  link: string | null;
  metadata: Record<string, unknown> | null;
  is_read: boolean;
  created_at: string;  // ISO 8601 — pg driver trả string (CLAUDE.md checklist #8)
  read_at: string | null;
}

export interface ListResponse {
  success: boolean;
  data: PersonalNotification[];
  pagination: {
    total: number;
    page: number;
    pageSize: number;
  };
}

export interface UnreadCountResponse {
  success: boolean;
  data: { count: number };
}

export interface MarkOneReadResponse {
  success: boolean;
  data: { id: number; is_read: boolean; message: string };
}

export interface MarkAllReadResponse {
  success: boolean;
  data: { updated_count: number; message: string };
}

// =============================================================================
// API calls
// =============================================================================

/**
 * List notifications của user hiện tại (staff_id từ JWT), paginated newest-first.
 * @param page 1-based; BE clamp min 1
 * @param pageSize 1..100; BE cap 100
 */
export async function listNotifications(
  page: number = 1,
  pageSize: number = 10,
): Promise<ListResponse> {
  const { data } = await api.get<ListResponse>('/notifications', {
    params: { page, page_size: pageSize },  // snake_case backend convention
  });
  return data;
}

/** Unread count cho badge. */
export async function unreadCount(): Promise<number> {
  const { data } = await api.get<UnreadCountResponse>('/notifications/unread-count');
  return Number(data?.data?.count ?? 0);
}

/**
 * Mark 1 notification đã đọc. Owner check BE-side (IDOR mitigation T-13-02).
 * BE trả 404 cho cả not-found + owner-mismatch (không leak existence).
 */
export async function markRead(id: number): Promise<void> {
  await api.patch<MarkOneReadResponse>(`/notifications/${id}/read`);
}

/** Mark tất cả notification của current user đã đọc. */
export async function markAllRead(): Promise<{ updated_count: number }> {
  const { data } = await api.patch<MarkAllReadResponse>('/notifications/read-all');
  return { updated_count: Number(data?.data?.updated_count ?? 0) };
}
