import { Router, type Request, type Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { directoryRepository } from '../repositories/directory.repository.js';
import { handleDbError } from '../lib/error-handler.js';
import { resolveAncestorUnit } from '../lib/department-subtree.js';

const router = Router();

// ============================================================
// GET / — Danh bạ nhân viên (phân trang, tìm kiếm)
// T-04-07: only returns public contact fields, no password_hash or sensitive data
// ============================================================
router.get('/', async (req: Request, res: Response) => {
  try {
    // Enforce ancestor unit for multi-tenancy by default
    const { departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const { unit_id, department_id, search, page, page_size } = req.query;

    // Use query param unit_id if provided, else fall back to ancestor unit
    const targetUnitId = unit_id ? Number(unit_id) : ancestorUnitId;
    const departmentIdVal = department_id ? Number(department_id) : null;
    const searchVal = (search as string) || null;
    const pageVal = page ? Number(page) : 1;
    const pageSizeVal = page_size ? Number(page_size) : 20;

    const rows = await directoryRepository.getList(
      targetUnitId,
      departmentIdVal,
      searchVal,
      pageVal,
      pageSizeVal,
    );

    const total = rows[0]?.total_count ?? 0;
    res.json({
      success: true,
      data: rows,
      pagination: {
        total: Number(total),
        page: pageVal,
        pageSize: pageSizeVal,
      },
    });
  } catch (error) {
    handleDbError(error, res);
  }
});

export default router;
