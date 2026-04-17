import { Router, type Request, type Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { dashboardRepository } from '../repositories/dashboard.repository.js';
import { handleDbError } from '../lib/error-handler.js';
import { resolveDeptSubtree } from '../lib/department-subtree.js';

const router = Router();

// ============================================================
// GET /stats — Thống kê KPI Dashboard (4 chỉ số)
// ============================================================
router.get('/stats', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const filterDeptId = req.query.department_id ? Number(req.query.department_id) : undefined;
    const deptIds = await resolveDeptSubtree(departmentId, isAdmin, filterDeptId);

    const stats = await dashboardRepository.getStats(staffId, 0, deptIds);
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
// ============================================================
router.get('/recent-incoming', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const { limit } = req.query;
    const filterDeptId = req.query.department_id ? Number(req.query.department_id) : undefined;
    const deptIds = await resolveDeptSubtree(departmentId, isAdmin, filterDeptId);

    const rows = await dashboardRepository.getRecentIncoming(
      0,
      limit ? Number(limit) : 10,
      deptIds,
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
// ============================================================
router.get('/recent-outgoing', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const { limit } = req.query;
    const filterDeptId = req.query.department_id ? Number(req.query.department_id) : undefined;
    const deptIds = await resolveDeptSubtree(departmentId, isAdmin, filterDeptId);

    const rows = await dashboardRepository.getRecentOutgoing(
      0,
      limit ? Number(limit) : 10,
      deptIds,
    );
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

export default router;
