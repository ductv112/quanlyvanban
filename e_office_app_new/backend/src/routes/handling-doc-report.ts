import { Router } from 'express';
import type { Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { handlingDocReportRepository } from '../repositories/handling-doc-report.repository.js';
import { handleDbError } from '../lib/error-handler.js';
import { resolveAncestorUnit } from '../lib/department-subtree.js';

const router = Router();

// ============================================================
// KPI & BÁO CÁO HỒ SƠ CÔNG VIỆC
// ============================================================

// GET /kpi — KPI tổng quan hồ sơ công việc
router.get('/kpi', async (req: AuthRequest, res: Response) => {
  try {
    const ancestorUnitId = await resolveAncestorUnit(req.user!.departmentId);
    const fromDate = req.query.from_date ? String(req.query.from_date) : null;
    const toDate = req.query.to_date ? String(req.query.to_date) : null;

    const kpi = await handlingDocReportRepository.getKpi(ancestorUnitId, fromDate, toDate);
    res.json({ success: true, data: kpi });
  } catch (err) {
    handleDbError(err, res);
  }
});

// GET /bao-cao/theo-don-vi — Báo cáo theo đơn vị/phòng ban
router.get('/bao-cao/theo-don-vi', async (req: AuthRequest, res: Response) => {
  try {
    const ancestorUnitId = await resolveAncestorUnit(req.user!.departmentId);
    const fromDate = req.query.from_date ? String(req.query.from_date) : null;
    const toDate = req.query.to_date ? String(req.query.to_date) : null;

    const rows = await handlingDocReportRepository.reportByUnit(ancestorUnitId, fromDate, toDate);
    res.json({ success: true, data: rows });
  } catch (err) {
    handleDbError(err, res);
  }
});

// GET /bao-cao/theo-can-bo — Báo cáo theo cán bộ giải quyết
router.get('/bao-cao/theo-can-bo', async (req: AuthRequest, res: Response) => {
  try {
    const ancestorUnitId = await resolveAncestorUnit(req.user!.departmentId);
    const fromDate = req.query.from_date ? String(req.query.from_date) : null;
    const toDate = req.query.to_date ? String(req.query.to_date) : null;

    const rows = await handlingDocReportRepository.reportByResolver(ancestorUnitId, fromDate, toDate);
    res.json({ success: true, data: rows });
  } catch (err) {
    handleDbError(err, res);
  }
});

// GET /bao-cao/theo-nguoi-giao — Báo cáo theo người giao việc
router.get('/bao-cao/theo-nguoi-giao', async (req: AuthRequest, res: Response) => {
  try {
    const ancestorUnitId = await resolveAncestorUnit(req.user!.departmentId);
    const fromDate = req.query.from_date ? String(req.query.from_date) : null;
    const toDate = req.query.to_date ? String(req.query.to_date) : null;

    const rows = await handlingDocReportRepository.reportByAssigner(ancestorUnitId, fromDate, toDate);
    res.json({ success: true, data: rows });
  } catch (err) {
    handleDbError(err, res);
  }
});

export default router;
