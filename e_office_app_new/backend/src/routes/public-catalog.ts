// Public catalog routes — readable cho mọi user authenticated
// Phase 17 v3.0: cần cho recipient picker (multi-select departments) trong form VB đi
import { Router, type Request, type Response } from 'express';
import { rawQuery } from '../lib/db/query.js';
import { handleDbError } from '../lib/error-handler.js';

const router = Router();

interface DeptRow {
  id: number;
  parent_id: number | null;
  code: string | null;
  name: string;
  short_name: string | null;
  is_unit: boolean;
  level: number | null;
  sort_order: number | null;
}

// GET /don-vi — flat list cho Select component
router.get('/don-vi', async (_req: Request, res: Response) => {
  try {
    const rows = await rawQuery<DeptRow>(
      `SELECT id, parent_id, code, name, short_name, is_unit, level, sort_order
       FROM public.departments
       WHERE COALESCE(is_locked, false) = false
       ORDER BY sort_order NULLS LAST, name`,
    );
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /don-vi/tree — tree (con lồng vào parent) cho Tree/TreeSelect component
router.get('/don-vi/tree', async (_req: Request, res: Response) => {
  try {
    const rows = await rawQuery<DeptRow>(
      `SELECT id, parent_id, code, name, short_name, is_unit, level, sort_order
       FROM public.departments
       WHERE COALESCE(is_locked, false) = false
       ORDER BY sort_order NULLS LAST, name`,
    );
    // Build tree
    const map = new Map<number, DeptRow & { children: any[] }>();
    rows.forEach((r) => map.set(r.id, { ...r, children: [] }));
    const roots: any[] = [];
    rows.forEach((r) => {
      const node = map.get(r.id)!;
      if (r.parent_id && map.has(r.parent_id)) {
        map.get(r.parent_id)!.children.push(node);
      } else {
        roots.push(node);
      }
    });
    res.json({ success: true, data: roots });
  } catch (error) {
    handleDbError(error, res);
  }
});

// Phase 19 v3.0 fix: catalog read endpoints cho non-admin (form CRUD VB cần)
// Logic copy từ admin-catalog.ts nhưng KHÔNG yêu cầu admin role.
import type { AuthRequest } from '../middleware/auth.js';
import { resolveAncestorUnit } from '../lib/department-subtree.js';

// GET /so-van-ban — list sổ văn bản
router.get('/so-van-ban', async (req: Request, res: Response) => {
  try {
    const { departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const typeId = req.query.type_id ? Number(req.query.type_id) : null;
    const uId = req.query.unit_id ? Number(req.query.unit_id) : ancestorUnitId;
    const rows = await rawQuery<{ id: number; name: string; type_id: number; unit_id: number }>(
      `SELECT id, name, type_id, unit_id FROM edoc.doc_books
       WHERE COALESCE(is_deleted, false) = false
         AND ($1::int IS NULL OR type_id = $1)
         AND unit_id = $2
       ORDER BY sort_order NULLS LAST, name`,
      [typeId, uId],
    );
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /loai-van-ban/tree — tree loại VB
router.get('/loai-van-ban/tree', async (_req: Request, res: Response) => {
  try {
    const rows = await rawQuery<{ id: number; parent_id: number | null; code: string; name: string }>(
      `SELECT id, parent_id, code, name FROM edoc.doc_types
       WHERE COALESCE(is_deleted, false) = false
       ORDER BY sort_order NULLS LAST, name`,
    );
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /linh-vuc — list lĩnh vực
router.get('/linh-vuc', async (_req: Request, res: Response) => {
  try {
    const rows = await rawQuery<{ id: number; code: string; name: string }>(
      `SELECT id, code, name FROM edoc.doc_fields
       WHERE COALESCE(is_active, true) = true
       ORDER BY sort_order NULLS LAST, name`,
    );
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /nguoi-dung — list staff (read-only) cho dropdown 'Người soạn thảo'
// Phase 19 v3.0 fix: non-admin user mở form CRUD VB cần load staff dropdown
router.get('/nguoi-dung', async (req: Request, res: Response) => {
  try {
    const unitId = req.query.unit_id ? Number(req.query.unit_id) : null;
    const departmentId = req.query.department_id ? Number(req.query.department_id) : null;
    const keyword = ((req.query.keyword as string) || '').trim();
    const rows = await rawQuery<{ id: number; full_name: string; unit_id: number; department_id: number | null }>(
      `SELECT id, full_name, unit_id, department_id FROM public.staff
       WHERE COALESCE(is_locked, false) = false
         AND ($1::int IS NULL OR unit_id = $1)
         AND ($2::int IS NULL OR department_id = $2)
         AND ($3 = '' OR full_name ILIKE '%' || $3 || '%')
       ORDER BY full_name`,
      [unitId, departmentId, keyword],
    );
    res.json({ success: true, data: rows, total: rows.length });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /co-quan-lien-thong — danh sách cơ quan ngoài LGSP cho recipient picker
// Phase 18 v3.0
router.get('/co-quan-lien-thong', async (_req: Request, res: Response) => {
  try {
    const rows = await rawQuery<{ id: number; code: string; name: string; lgsp_organ_id: string | null }>(
      `SELECT id, code, name, lgsp_organ_id
       FROM edoc.inter_organizations
       WHERE COALESCE(is_active, true) = true
       ORDER BY name`,
    );
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

export default router;
