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
      staffId, // Recipient visibility — VB den dang ky boi unit khac van hien neu user la recipient
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
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const { limit } = req.query;
    const deptIds = await resolveDeptSubtree(departmentId, isAdmin);

    const rows = await dashboardRepository.getUpcomingTasks(
      staffId,
      limit ? Number(limit) : 10,
      deptIds,
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

// ============================================================
// GET /stats-extra — Stat cards bổ sung (dự thảo, tin nhắn, thông báo, họp)
// ============================================================
router.get('/stats-extra', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const deptIds = await resolveDeptSubtree(departmentId, isAdmin);

    const data = await dashboardRepository.getStatsExtra(staffId, deptIds);
    res.json({
      success: true,
      data: data ?? { drafting_pending: 0, message_unread: 0, notice_unread: 0, today_meetings: 0 },
    });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// GET /doc-by-month — Biểu đồ cột VB đến/đi theo tháng
// ============================================================
router.get('/doc-by-month', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const deptIds = await resolveDeptSubtree(departmentId, isAdmin);
    const months = req.query.months ? Number(req.query.months) : 6;

    const rows = await dashboardRepository.getDocByMonth(deptIds, months, staffId);
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// GET /task-by-status — Biểu đồ tròn HSCV theo trạng thái
// ============================================================
router.get('/task-by-status', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const deptIds = await resolveDeptSubtree(departmentId, isAdmin);

    const rows = await dashboardRepository.getTaskByStatus(staffId, deptIds);
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// GET /top-departments — Top 5 phòng ban nhiều VB nhất
// ============================================================
router.get('/top-departments', async (req: Request, res: Response) => {
  try {
    const { departmentId, isAdmin } = (req as AuthRequest).user;
    const deptIds = await resolveDeptSubtree(departmentId, isAdmin);
    const limit = req.query.limit ? Number(req.query.limit) : 5;

    const rows = await dashboardRepository.getTopDepartments(deptIds, limit);
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// GET /recent-notices — Thông báo mới nhất (widget)
// ============================================================
router.get('/recent-notices', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const deptIds = await resolveDeptSubtree(departmentId, isAdmin);
    const limit = req.query.limit ? Number(req.query.limit) : 5;

    const rows = await dashboardRepository.getRecentNotices(staffId, deptIds, limit);
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// GET /calendar-today — Lịch hôm nay + 7 ngày tới
// ============================================================
router.get('/calendar-today', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const deptIds = await resolveDeptSubtree(departmentId, isAdmin);
    const days = req.query.days ? Number(req.query.days) : 7;

    const rows = await dashboardRepository.getCalendarToday(staffId, deptIds, days);
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// GET /ontime-rate — Tỷ lệ xử lý đúng hạn (KPI admin)
// ============================================================
router.get('/ontime-rate', async (req: Request, res: Response) => {
  try {
    const { departmentId, isAdmin } = (req as AuthRequest).user;
    const deptIds = await resolveDeptSubtree(departmentId, isAdmin);

    const data = await dashboardRepository.getOntimeRate(deptIds);
    res.json({
      success: true,
      data: data ?? { total_completed: 0, ontime_count: 0, overdue_count: 0, ontime_percent: 0 },
    });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// GET /doc-by-department — VB theo đơn vị/phòng ban (admin)
// ============================================================
router.get('/doc-by-department', async (req: Request, res: Response) => {
  try {
    const { departmentId, isAdmin } = (req as AuthRequest).user;
    const deptIds = await resolveDeptSubtree(departmentId, isAdmin);

    const rows = await dashboardRepository.getDocByDepartment(deptIds);
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

export default router;
