// Public catalog routes — readable cho mọi user authenticated
// Phase 17 v3.0: cần cho recipient picker (multi-select departments) trong form VB đi
import { Router, type Request, type Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { rawQuery } from '../lib/db/query.js';
import { handleDbError } from '../lib/error-handler.js';
import { rightRepository } from '../repositories/right.repository.js';

const router = Router();

// BUG-VT-005: GET /chuc-nang/menu — non-admin user phải fetch được menu của chính họ
// Mounted ở public-catalog (sau requireRolesOrNext) nên non-admin sẽ rơi vào đây.
router.get('/chuc-nang/menu', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const data = await rightRepository.getByStaff(staffId);
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

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

// GET /don-vi/:id/nhan-vien — list cán bộ trong 1 đơn vị (cho HSCV "Cán bộ xử lý" picker)
// Frontend HSCV detail → tab "Cán bộ xử lý" → click node đơn vị trên cây → load danh sách.
// Mount ở public-catalog để cả admin + chuyên viên đều dùng được.
//
// BUG #77 (2026-05-19): Click parent dept (UNIT level / cha) không hiển thị cán bộ
// vì SQL chỉ filter department_id = parent. YC: phải show cán bộ ở subtree (cha + con cháu)
// để admin chọn được nhanh, đặc biệt với UBND có nhiều phòng con.
// Dùng fn_get_department_subtree(p_dept_id) → INT[] subtree ids.
router.get('/don-vi/:id/nhan-vien', async (req: Request, res: Response) => {
  try {
    const deptId = Number(req.params.id);
    if (!deptId) {
      res.status(400).json({ success: false, message: 'Thiếu mã đơn vị' });
      return;
    }
    const rows = await rawQuery<{ id: number; full_name: string; position_name: string | null; department_name: string | null }>(
      `SELECT s.id, s.full_name, p.name AS position_name, d.name AS department_name
       FROM public.staff s
       LEFT JOIN public.positions p ON p.id = s.position_id
       LEFT JOIN public.departments d ON d.id = s.department_id
       WHERE s.department_id = ANY(public.fn_get_department_subtree($1::int))
         AND COALESCE(s.is_deleted, false) = false
         AND COALESCE(s.is_locked, false) = false
       ORDER BY d.sort_order NULLS LAST, d.name, s.last_name, s.first_name`,
      [deptId],
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
      // Skip self-reference (parent_id === id) to prevent empty tree from corrupt data
      if (r.parent_id && r.parent_id !== r.id && map.has(r.parent_id)) {
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

// GET /nguoi-dung — list staff (read-only) cho dropdown 'Người soạn thảo' / recipient picker / cấu hình gửi nhanh
// Phase 19 v3.0 fix: non-admin user mở form CRUD VB cần load staff dropdown
// Shadow admin route /quan-tri/nguoi-dung (mount trước) — phải trả đủ position_name + department_name để form admin render đúng.
// Phase 31 BUG #17/#18/#52/#53: them filter is_deleted=false va is_locked param de
// Quan ly nguoi dung filter trang thai dung (admin route co Phase 31 fix nhung non-admin
// user voi role 'Van thu' van fall-through xuong day).
router.get('/nguoi-dung', async (req: Request, res: Response) => {
  try {
    const { departmentId: callerDeptId, isAdmin } = (req as AuthRequest).user;
    let unitId = req.query.unit_id ? Number(req.query.unit_id) : null;
    let departmentId = req.query.department_id ? Number(req.query.department_id) : null;
    // Resolve unit_id theo thu tu uu tien:
    // 1. Co department_id -> ancestor cua dept (luon chinh xac)
    // 2. Co unit_id query -> kiem tra is_unit. Neu la phong con (is_unit=false),
    //    auto-promote: filter theo ancestor unit + narrow xuong dung phong do.
    //    Ly do: nhieu caller dung `user.departmentId` (raw dept_id, co the la phong con)
    //    lam unit_id query — `staff.unit_id` cua moi nhan su deu la ancestor unit (trigger
    //    trg_staff_auto_unit_id auto resolve), nen filter exact `s.unit_id = phong-id`
    //    se tra 0 row. Tu nang cap o backend de mot fix bao het callers.
    // 3. Non-admin + khong filter -> auto-scope vao don vi cua user (de tranh
    //    pick nhan su cross-unit). Admin -> giu null = thay het.
    if (departmentId) {
      unitId = await resolveAncestorUnit(departmentId);
    } else if (unitId) {
      const check = await rawQuery<{ is_unit: boolean; ancestor_unit_id: number }>(
        `SELECT COALESCE(is_unit, false) AS is_unit,
                public.fn_get_ancestor_unit(id) AS ancestor_unit_id
         FROM public.departments WHERE id = $1 AND COALESCE(is_deleted, false) = false`,
        [unitId],
      );
      if (check[0] && !check[0].is_unit) {
        departmentId = unitId;
        unitId = check[0].ancestor_unit_id;
      }
    } else if (!isAdmin) {
      unitId = await resolveAncestorUnit(callerDeptId);
    }
    const keyword = ((req.query.keyword as string) || '').trim();
    // BUG #52/#53: respect is_locked filter — null = tat ca, true = chi khoa, false = chi hoat dong.
    // Mac dinh public picker chi tra active (is_locked=false) de tranh chon nguoi da khoa.
    let isLockedFilter: boolean | null = false;
    if (req.query.is_locked !== undefined) {
      isLockedFilter = req.query.is_locked === 'true' ? true : req.query.is_locked === 'false' ? false : null;
    }
    const rows = await rawQuery<{
      id: number;
      full_name: string;
      unit_id: number;
      department_id: number | null;
      position_id: number | null;
      position_name: string | null;
      department_name: string | null;
      is_locked: boolean;
    }>(
      `SELECT s.id, s.full_name, s.unit_id, s.department_id, s.position_id,
              p.name AS position_name, d.name AS department_name,
              s.is_locked
       FROM public.staff s
       LEFT JOIN public.positions p ON p.id = s.position_id
       LEFT JOIN public.departments d ON d.id = s.department_id
       WHERE COALESCE(s.is_deleted, false) = false
         AND ($4::boolean IS NULL OR COALESCE(s.is_locked, false) = $4)
         AND ($1::int IS NULL OR s.unit_id = $1)
         AND ($2::int IS NULL OR s.department_id = $2)
         AND ($3 = '' OR s.full_name ILIKE '%' || $3 || '%')
       ORDER BY s.full_name`,
      [unitId, departmentId, keyword, isLockedFilter],
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
