import { Router, type Request, type Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { dashboardRepository } from '../repositories/dashboard.repository.js';
import { handleDbError } from '../lib/error-handler.js';

const router = Router();

// ============================================================
// GET /stats — Thống kê KPI Dashboard (4 chỉ số)
// T-04-06: filter by unitId from JWT to enforce multi-tenancy
// ============================================================
router.get('/stats', async (req: Request, res: Response) => {
  try {
    // T-04-06: staffId and unitId come from JWT only
    const { staffId, unitId } = (req as AuthRequest).user;

    // fn_dashboard_get_stats signature: (p_staff_id, p_unit_id) — staffId first
    const stats = await dashboardRepository.getStats(staffId, unitId);
    res.json({
      success: true,
      data: stats ?? {
        incoming_unread: 0,
        outgoing_pending: 0,
        handling_total: 0,
        handling_overdue: 0,
      },
    });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// GET /recent-incoming — Văn bản đến mới nhất
// T-04-06: filtered by unitId from JWT
// ============================================================
router.get('/recent-incoming', async (req: Request, res: Response) => {
  try {
    const { staffId, unitId } = (req as AuthRequest).user;
    const { limit } = req.query;

    // fn_dashboard_recent_incoming signature: (p_unit_id, p_limit)
    const rows = await dashboardRepository.getRecentIncoming(
      unitId,
      limit ? Number(limit) : 10,
    );
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// GET /upcoming-tasks — Việc sắp tới hạn
// ============================================================
router.get('/upcoming-tasks', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const { limit } = req.query;

    const rows = await dashboardRepository.getUpcomingTasks(
      staffId,
      limit ? Number(limit) : 10,
    );
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// GET /recent-outgoing — Văn bản đi mới nhất
// T-04-06: filtered by unitId from JWT
// ============================================================
router.get('/recent-outgoing', async (req: Request, res: Response) => {
  try {
    const { staffId, unitId } = (req as AuthRequest).user;
    const { limit } = req.query;

    // fn_dashboard_recent_outgoing signature: (p_unit_id, p_limit)
    const rows = await dashboardRepository.getRecentOutgoing(
      unitId,
      limit ? Number(limit) : 10,
    );
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

export default router;
