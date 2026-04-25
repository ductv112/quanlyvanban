/**
 * Bell notification helper — Phase 13 mở rộng (incoming_doc_assigned, task_assigned,
 *   leader_note_received).
 *
 * Centralize logic:
 *   1. Persist row vào public.notifications (qua bellNotificationRepository.create)
 *   2. Emit Socket.IO event `new_notification` (NEW_NOTIFICATION) tới user_{staffId}
 *
 * Best-effort: cả 2 bước đều wrap try/catch — bell fail KHÔNG được rollback main op
 *   (route handler đã DB success rồi). Chỉ log warn.
 *
 * Pattern theo workers/signing-poll.worker.ts: persist TRƯỚC emit để offline user
 *   thấy khi login lại.
 *
 * Filter:
 *   - Skip self-notify (sender không nhận thông báo về chính mình).
 *   - Skip null/undefined target (defensive).
 *   - Dedup target list (1 người không nhận 2 thông báo cùng lúc — nhưng KHÔNG dedup
 *     cross-call: spec nói nếu user A giao B 2 lần liên tiếp -> 2 notif là expected).
 */

import pino from 'pino';
import { bellNotificationRepository } from '../../repositories/notifications.repository.js';
import { emitToUser, SOCKET_EVENTS } from '../socket.js';

const logger = pino({
  name: 'bell-emit',
  level: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
});

/** Loại bell notification mới mở rộng (ngoài sign_completed/sign_failed). */
export type BellNotificationType =
  | 'incoming_doc_assigned'
  | 'task_assigned'
  | 'leader_note_received'
  | 'sign_completed'
  | 'sign_failed';

export interface BellNotifyParams {
  /** Danh sách staff nhận — sẽ tự động loại sender + dedup */
  targetStaffIds: Array<number | null | undefined>;
  /** Sender — bị loại khỏi targets */
  senderStaffId: number;
  type: BellNotificationType;
  /** Max ~60 ký tự (sẽ tự cắt nếu dài hơn) */
  title: string;
  /** Max ~200 ký tự (sẽ tự cắt) */
  message: string;
  /** Frontend route, KHÔNG phải URL absolute hoặc API path. VD: `/van-ban-den/123` */
  link: string;
  /** Optional metadata để FE/UX dùng sau (vd hscv_id, doc_id) */
  metadata?: Record<string, unknown> | null;
}

/** Cắt chuỗi an toàn (giữ ký tự cuối nếu dài quá). */
function truncate(s: string, max: number): string {
  if (!s) return s;
  return s.length > max ? `${s.slice(0, max - 1)}…` : s;
}

/**
 * Tạo bell notification cho nhiều người + emit socket event.
 * Best-effort — không throw.
 *
 * @returns số người đã được tạo notification thành công
 */
export async function notifyBell(params: BellNotifyParams): Promise<number> {
  const {
    targetStaffIds,
    senderStaffId,
    type,
    title,
    message,
    link,
    metadata,
  } = params;

  // Filter: skip null/undefined, skip sender, dedup
  const cleaned = Array.from(
    new Set(
      targetStaffIds
        .filter((x): x is number => typeof x === 'number' && Number.isFinite(x) && x > 0)
        .map((x) => Number(x)),
    ),
  ).filter((id) => id !== senderStaffId);

  if (cleaned.length === 0) return 0;

  const safeTitle = truncate(title, 60);
  const safeMessage = truncate(message, 200);

  let success = 0;
  for (const targetStaffId of cleaned) {
    try {
      // 1. Persist (DB là source of truth — offline user thấy khi login)
      const res = await bellNotificationRepository.create(
        targetStaffId,
        type,
        safeTitle,
        safeMessage,
        link,
        metadata ?? null,
      );
      if (!res.success) {
        logger.warn(
          { targetStaffId, type, msg: res.message },
          'Bell notification create returned failure',
        );
        continue;
      }
      success += 1;

      // 2. Emit socket — best-effort, user online thấy realtime
      try {
        emitToUser(targetStaffId, SOCKET_EVENTS.NEW_NOTIFICATION, {
          id: res.id,
          type,
          title: safeTitle,
          message: safeMessage,
          link,
          metadata: metadata ?? null,
          created_at: new Date().toISOString(),
          is_read: false,
        });
      } catch (err) {
        logger.warn({ err, targetStaffId, type }, 'Socket emit new_notification failed');
      }
    } catch (err) {
      logger.warn({ err, targetStaffId, type }, 'Bell notification create threw — skipping');
    }
  }

  return success;
}
