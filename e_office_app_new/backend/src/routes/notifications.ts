/**
 * Phase 13 — Bell Notification routes (/api/notifications)
 *
 * Persistent personal bell notification (khác `notificationRoutes` — mounted ở
 * /api/thong-bao-kenh cho multichannel config). KHÁC `noticeRoutes` — mounted ở
 * /api/thong-bao cho unit-wide edoc.notice (legacy).
 *
 * Endpoints:
 *   GET    /api/notifications?page=1&page_size=10   — paginated list (newest first)
 *   GET    /api/notifications/unread-count          — badge count
 *   PATCH  /api/notifications/read-all              — mark all read (must BEFORE /:id/read)
 *   PATCH  /api/notifications/:id/read              — mark one read (owner-only)
 *
 * Threat mitigations:
 *   - T-13-01 URL tampering: page/page_size clamp với Number.isFinite + floor + min 1 + cap 100
 *   - T-13-02/03 IDOR: staffId TỪ JWT (không từ body/query); SP filter by staff_id
 *   - T-13-04 Info leak: 404 cho cả not-found và owner-mismatch (không leak existence)
 */

import { Router, type Request, type Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { bellNotificationRepository } from '../repositories/notifications.repository.js';
import { handleDbError } from '../lib/error-handler.js';

const router = Router();

// =============================================================================
// GET / — List paginated notifications (newest first)
// Query: page, page_size (snake_case khớp convention dự án)
// =============================================================================
router.get('/', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const rawPage = Number(req.query.page ?? 1);
    const rawPageSize = Number(req.query.page_size ?? 10);

    // Guard URL tampering (T-13-01)
    const page = Number.isFinite(rawPage) && rawPage >= 1 ? Math.floor(rawPage) : 1;
    const pageSize = Number.isFinite(rawPageSize) && rawPageSize >= 1
      ? Math.min(Math.floor(rawPageSize), 100)
      : 10;

    const rows = await bellNotificationRepository.list(staffId, page, pageSize);
    const total = rows.length > 0 ? Number(rows[0].total_count) : 0;

    res.json({
      success: true,
      data: rows.map((r) => ({
        id: r.id,
        type: r.type,
        title: r.title,
        message: r.message,
        link: r.link,
        metadata: r.metadata,
        is_read: r.is_read,
        created_at: r.created_at,
        read_at: r.read_at,
      })),
      pagination: { total, page, pageSize },
    });
  } catch (error) {
    handleDbError(error, res);
  }
});

// =============================================================================
// GET /unread-count — Badge count
// =============================================================================
router.get('/unread-count', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const count = await bellNotificationRepository.unreadCount(staffId);
    res.json({ success: true, data: { count } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// =============================================================================
// PATCH /read-all — Mark all read
// NOTE: PHẢI đặt TRƯỚC /:id/read để tránh route shadowing (pattern notice.ts)
// =============================================================================
router.patch('/read-all', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const result = await bellNotificationRepository.markAllRead(staffId);
    res.json({
      success: true,
      data: { updated_count: result.updated_count, message: result.message },
    });
  } catch (error) {
    handleDbError(error, res);
  }
});

// =============================================================================
// PATCH /:id/read — Mark one read (owner-only check trong SP via staff_id)
// =============================================================================
router.patch('/:id/read', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id < 1) {
      res.status(400).json({ success: false, message: 'ID không hợp lệ' });
      return;
    }

    const result = await bellNotificationRepository.markRead(id, staffId);
    if (!result.success) {
      // Owner-check failure (IDOR T-13-02/03) hoặc not-found — cùng trả 404
      // không leak existence (T-13-04)
      res.status(404).json({ success: false, message: result.message });
      return;
    }
    res.json({
      success: true,
      data: { id, is_read: true, message: result.message },
    });
  } catch (error) {
    handleDbError(error, res);
  }
});

export default router;
