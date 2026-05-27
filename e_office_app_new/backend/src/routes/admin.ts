import { Router } from 'express';
import type { Request, Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { hashPassword, verifyPassword } from '../lib/auth/password.js';
import { pool } from '../lib/db/pool.js';
import { departmentRepository } from '../repositories/department.repository.js';
import { positionRepository } from '../repositories/position.repository.js';
import { staffRepository } from '../repositories/staff.repository.js';
import { roleRepository } from '../repositories/role.repository.js';
import { rightRepository } from '../repositories/right.repository.js';
import { handleDbError } from '../lib/error-handler.js';
import { resolveAncestorUnit } from '../lib/department-subtree.js';
import { rawQuery } from '../lib/db/query.js';

const router = Router();

// ============================================================
// MULTI-TENANT SCOPE (2026-05-26)
// ----------------------------------------------------------
// Rule: Scope theo VI TRI user trong cay to chuc (user.unit_id).
//   - is_admin=TRUE (system admin) -> KHONG scope, full access
//   - user.unit la ROOT unit (parent_id NULL, vd UBND tinh) -> KHONG scope, cross-DN
//   - else -> scope = user.unit_id (staff.unit_id luon la ancestor root unit cua dept,
//             nen filter exact match unit_id se match toan bo staff cua DN do)
//
// User dat o UBND (root, parent_id NULL) -> no scope -> cross-DN (adminso).
// User dat o DN.001 (parent_id=UBND) -> scope = 101 (admindn001).
// Cung 1 role "ADMIN Don vi" dung duoc cho ca 2 case — scope tu dong theo vi tri user.
//
// Returns:
//   - null = no scope (system admin OR user o root unit)
//   - number = unit_id phai scope vao
// ============================================================
async function getUserUnitScope(req: Request): Promise<number | null> {
  const user = (req as AuthRequest).user;
  if (user.isAdmin) return null;
  const rows = await rawQuery<{ parent_id: number | null }>(
    'SELECT parent_id FROM public.departments WHERE id = $1 AND is_deleted = FALSE',
    [user.unitId],
  );
  // Root unit (parent_id NULL hoac unit khong ton tai) -> no scope
  if (!rows[0] || rows[0].parent_id == null) return null;
  return user.unitId;
}

/**
 * Check deptId co nam trong subtree cua ancestorId khong (recursive parent walk).
 * Return TRUE neu deptId === ancestorId hoac la descendant cua ancestorId.
 */
async function isInSubtree(deptId: number, ancestorId: number): Promise<boolean> {
  if (deptId === ancestorId) return true;
  const rows = await rawQuery<{ ok: number }>(
    `WITH RECURSIVE ancestors AS (
       SELECT id, parent_id FROM public.departments WHERE id = $1 AND is_deleted = FALSE
       UNION ALL
       SELECT d.id, d.parent_id FROM public.departments d
       JOIN ancestors a ON d.id = a.parent_id
       WHERE d.is_deleted = FALSE
     )
     SELECT 1 AS ok FROM ancestors WHERE id = $2 LIMIT 1`,
    [deptId, ancestorId],
  );
  return rows.length > 0;
}

// ============================================================
// UTILITY: Build tree from flat list
// ============================================================
function buildTree<T extends { id: number; parent_id: number | null }>(flatList: T[]): (T & { children?: T[] })[] {
  const map = new Map<number, T & { children?: T[] }>();
  const roots: (T & { children?: T[] })[] = [];

  for (const item of flatList) {
    map.set(item.id, { ...item, children: [] });
  }

  for (const item of flatList) {
    const node = map.get(item.id)!;
    const parentId = item.parent_id;
    // Skip self-reference (parent_id === id) to prevent silent empty tree
    // when data has been corrupted by admin setting parent to itself.
    if (parentId && parentId !== item.id && map.has(parentId)) {
      map.get(parentId)!.children!.push(node);
    } else {
      roots.push(node);
    }
  }

  // Remove empty children arrays
  const clean = (nodes: (T & { children?: T[] })[]) => {
    for (const node of nodes) {
      if (node.children && node.children.length === 0) {
        delete node.children;
      } else if (node.children) {
        clean(node.children);
      }
    }
  };
  clean(roots);

  return roots;
}

// ============================================================
// DEPARTMENT (Đơn vị / Phòng ban)
// ============================================================

// GET /don-vi/tree — trả về cây phân cấp (cho Tree component)
router.get('/don-vi/tree', async (req: Request, res: Response) => {
  try {
    // Multi-tenant scope: neu user thuoc DN co lap (lgsp_org_code) -> force scope vao subtree DN do.
    // Admin + adminso (UBND/So, khong lgsp_org_code) -> no scope, respect query.unit_id.
    const scope = await getUserUnitScope(req);
    let unitId = req.query.unit_id ? Number(req.query.unit_id) : null;
    if (scope !== null) unitId = scope;

    const flatList = await departmentRepository.getTree(unitId);
    const tree = buildTree(flatList);
    res.json({ success: true, data: tree });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /don-vi — trả về flat list (cho Table component)
router.get('/don-vi', async (req: Request, res: Response) => {
  try {
    // Multi-tenant scope: same logic nhu /don-vi/tree
    const scope = await getUserUnitScope(req);
    let unitId = req.query.unit_id ? Number(req.query.unit_id) : null;
    if (scope !== null) unitId = scope;

    const data = await departmentRepository.getTree(unitId);
    // Filter by parent_id if provided
    const parentId = req.query.parent_id ? Number(req.query.parent_id) : null;
    const filtered = parentId ? data.filter(d => d.parent_id === parentId) : data;
    res.json({ success: true, data: filtered });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /don-vi/:id
router.get('/don-vi/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const data = await departmentRepository.getById(id);
    if (!data) {
      res.status(404).json({ success: false, message: 'Không tìm thấy đơn vị' });
      return;
    }
    // Multi-tenant scope: chan user DN co lap xem don vi ngoai subtree minh
    const scope = await getUserUnitScope(req);
    if (scope !== null && !(await isInSubtree(id, scope))) {
      res.status(403).json({ success: false, message: 'Không có quyền xem đơn vị ngoài phạm vi quản lý' });
      return;
    }
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /don-vi
router.post('/don-vi', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const {
      parent_id, code, name, name_en, short_name, abb_name,
      is_unit, level, sort_order, phone, fax, email, address,
      allow_doc_book, description,
      // BUG-F-001: tránh silent drop LGSP fields
      lgsp_system_id, lgsp_secret_key,
    } = req.body;

    // Multi-tenant scope: user DN co lap chi duoc tao phong ban TRUC TIEP duoi DN root.
    // KHONG cho deep hierarchy (phong -> to -> nhom) — chi 1 cap phong ban thoi.
    const scope = await getUserUnitScope(req);
    if (scope !== null) {
      if (parent_id == null) {
        res.status(403).json({ success: false, message: 'Phải chọn đơn vị cha trong phạm vi quản lý' });
        return;
      }
      // parent_id phai EXACTLY = scope (DN root), KHONG cho parent la phong con
      if (Number(parent_id) !== scope) {
        res.status(403).json({ success: false, message: 'Chỉ được tạo phòng ban trực tiếp dưới đơn vị của bạn' });
        return;
      }
      // Chan tao cap "Don vi" (is_unit=TRUE) — se tao tenant moi, pha scope semantic.
      if (is_unit === true) {
        res.status(403).json({ success: false, message: 'Không có quyền tạo cấp Đơn vị, chỉ được tạo Phòng ban' });
        return;
      }
    }

    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên đơn vị là bắt buộc' });
      return;
    }

    if (code?.trim()) {
      const existing = await pool.query(
        'SELECT id FROM departments WHERE LOWER(code) = LOWER($1) AND is_deleted = FALSE',
        [code.trim()]
      );
      if (existing.rows.length > 0) {
        res.status(409).json({ success: false, message: 'Mã đơn vị đã tồn tại' });
        return;
      }
    }

    // BUG-F-003: validate email format
    if (email && String(email).trim()) {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(String(email).trim())) {
        res.status(400).json({ success: false, message: 'Email đơn vị không đúng định dạng' });
        return;
      }
    }
    // BUG-F-002: validate phone/fax format
    const phoneRegex = /^[0-9+\-\s()]{6,20}$/;
    if (phone && String(phone).trim() && !phoneRegex.test(String(phone).trim())) {
      res.status(400).json({ success: false, message: 'Số điện thoại đơn vị không đúng định dạng' });
      return;
    }
    if (fax && String(fax).trim() && !phoneRegex.test(String(fax).trim())) {
      res.status(400).json({ success: false, message: 'Số fax không đúng định dạng' });
      return;
    }

    const id = await departmentRepository.create(
      parent_id ?? null, code, name, name_en ?? '', short_name ?? '', abb_name ?? '',
      is_unit ?? false, level ?? 0, sort_order ?? 0, phone ?? '', fax ?? '',
      email ?? '', address ?? '', allow_doc_book ?? false, description ?? '',
      staffId,
    );

    if (!id) {
      res.status(500).json({ success: false, message: 'Không thể tạo đơn vị' });
      return;
    }
    // BUG-F-001: persist LGSP fields nếu có (SP create không nhận)
    if (lgsp_system_id !== undefined || lgsp_secret_key !== undefined) {
      await pool.query(
        'UPDATE public.departments SET lgsp_system_id = $1, lgsp_secret_key = $2 WHERE id = $3',
        [
          lgsp_system_id ? String(lgsp_system_id).slice(0, 50) : null,
          lgsp_secret_key ? String(lgsp_secret_key).slice(0, 100) : null,
          id,
        ],
      );
    }
    res.status(201).json({ success: true, data: { id } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PUT /don-vi/:id
router.put('/don-vi/:id', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const {
      parent_id, code, name, name_en, short_name, abb_name,
      is_unit, level, sort_order, phone, fax, email, address,
      allow_doc_book, description,
      // BUG-F-001: tránh silent drop LGSP fields
      lgsp_system_id, lgsp_secret_key,
    } = req.body;

    // Multi-tenant scope: target id + parent_id moi (neu doi) deu phai trong subtree.
    const scope = await getUserUnitScope(req);
    if (scope !== null) {
      if (!(await isInSubtree(id, scope))) {
        res.status(403).json({ success: false, message: 'Không có quyền sửa đơn vị ngoài phạm vi quản lý' });
        return;
      }
      // Chan sua scope unit (DN goc) — DN tu sua scope cua chinh minh la danger.
      if (id === scope) {
        res.status(403).json({ success: false, message: 'Không thể sửa đơn vị gốc của doanh nghiệp' });
        return;
      }
      if (parent_id != null && !(await isInSubtree(Number(parent_id), scope))) {
        res.status(403).json({ success: false, message: 'Đơn vị cha mới nằm ngoài phạm vi quản lý' });
        return;
      }
      // KHONG cho user DN tu giai phong khoi subtree (set parent_id NULL = thanh root)
      if (parent_id == null) {
        res.status(403).json({ success: false, message: 'Không thể bỏ trống đơn vị cha' });
        return;
      }
      // Chan promote tu Phong ban -> Don vi (tao tenant moi)
      if (is_unit === true) {
        res.status(403).json({ success: false, message: 'Không có quyền nâng cấp thành Đơn vị, chỉ được giữ là Phòng ban' });
        return;
      }
    }

    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên đơn vị là bắt buộc' });
      return;
    }

    // Prevent self-reference: parent_id === id would corrupt tree (buildTree
    // pushes dept into its own children, never reaches roots → empty tree).
    if (parent_id != null && Number(parent_id) === id) {
      res.status(400).json({ success: false, message: 'Đơn vị cha không được là chính nó' });
      return;
    }

    if (code?.trim()) {
      const existing = await pool.query(
        'SELECT id FROM departments WHERE LOWER(code) = LOWER($1) AND is_deleted = FALSE AND id != $2',
        [code.trim(), id]
      );
      if (existing.rows.length > 0) {
        res.status(409).json({ success: false, message: 'Mã đơn vị đã tồn tại' });
        return;
      }
    }

    const updated = await departmentRepository.update(
      id, parent_id ?? null, code, name, name_en ?? '', short_name ?? '', abb_name ?? '',
      is_unit ?? false, level ?? 0, sort_order ?? 0, phone ?? '', fax ?? '',
      email ?? '', address ?? '', allow_doc_book ?? false, description ?? '',
      staffId,
    );

    if (!updated) {
      res.status(404).json({ success: false, message: 'Không tìm thấy đơn vị' });
      return;
    }
    // BUG-F-001: persist LGSP fields nếu có (SP update không nhận)
    if (lgsp_system_id !== undefined || lgsp_secret_key !== undefined) {
      await pool.query(
        'UPDATE public.departments SET lgsp_system_id = $1, lgsp_secret_key = $2 WHERE id = $3',
        [
          lgsp_system_id !== undefined ? (lgsp_system_id ? String(lgsp_system_id).slice(0, 50) : null) : undefined,
          lgsp_secret_key !== undefined ? (lgsp_secret_key ? String(lgsp_secret_key).slice(0, 100) : null) : undefined,
          id,
        ],
      );
    }
    res.json({ success: true, data: { updated: true } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /don-vi/:id
router.delete('/don-vi/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    // Multi-tenant scope: chi xoa duoc don vi trong subtree minh.
    // Cung chan xoa don vi LA scope unit (id === scope) -> tu pha goc cua minh.
    const scope = await getUserUnitScope(req);
    if (scope !== null) {
      if (id === scope) {
        res.status(403).json({ success: false, message: 'Không thể xóa đơn vị gốc của doanh nghiệp' });
        return;
      }
      if (!(await isInSubtree(id, scope))) {
        res.status(403).json({ success: false, message: 'Không có quyền xóa đơn vị ngoài phạm vi quản lý' });
        return;
      }
    }
    const result = await departmentRepository.delete(id);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { message: result.message } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PATCH /don-vi/:id/lock
router.patch('/don-vi/:id/lock', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    // Multi-tenant scope: chi khoa/mo duoc don vi trong subtree minh
    const scope = await getUserUnitScope(req);
    if (scope !== null && !(await isInSubtree(id, scope))) {
      res.status(403).json({ success: false, message: 'Không có quyền thao tác đơn vị ngoài phạm vi quản lý' });
      return;
    }
    const toggled = await departmentRepository.toggleLock(id);
    if (!toggled) {
      res.status(404).json({ success: false, message: 'Không tìm thấy đơn vị' });
      return;
    }
    res.json({ success: true, data: { toggled: true } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// POSITION (Chức vụ)
// ============================================================

// GET /chuc-vu
router.get('/chuc-vu', async (req: Request, res: Response) => {
  try {
    const keyword = (req.query.keyword as string) || '';
    const page = Number(req.query.page) || 1;
    const pageSize = Number(req.query.pageSize) || 20;

    const rows = await positionRepository.getList(keyword, page, pageSize);
    const total = rows.length > 0 ? Number(rows[0].total_count) : 0;
    const totalPages = Math.ceil(total / pageSize);

    res.json({ success: true, data: rows, total, page, pageSize, totalPages });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /chuc-vu
router.post('/chuc-vu', async (req: Request, res: Response) => {
  try {
    const { name, code, sort_order, description, is_leader, is_handle_document } = req.body;

    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên chức vụ là bắt buộc' });
      return;
    }

    if (code?.trim()) {
      const existing = await pool.query(
        'SELECT id FROM positions WHERE LOWER(code) = LOWER($1)',
        [code.trim()]
      );
      if (existing.rows.length > 0) {
        res.status(409).json({ success: false, message: 'Mã chức vụ đã tồn tại' });
        return;
      }
    }

    const id = await positionRepository.create(name, code ?? '', sort_order ?? 0, description ?? '', is_leader ?? false, is_handle_document ?? false);
    if (!id) {
      res.status(500).json({ success: false, message: 'Không thể tạo chức vụ' });
      return;
    }
    res.status(201).json({ success: true, data: { id } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PUT /chuc-vu/:id
router.put('/chuc-vu/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const { name, code, sort_order, description, is_active, is_leader, is_handle_document } = req.body;

    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên chức vụ là bắt buộc' });
      return;
    }

    if (code?.trim()) {
      const existing = await pool.query(
        'SELECT id FROM positions WHERE LOWER(code) = LOWER($1) AND id != $2',
        [code.trim(), id]
      );
      if (existing.rows.length > 0) {
        res.status(409).json({ success: false, message: 'Mã chức vụ đã tồn tại' });
        return;
      }
    }

    const updated = await positionRepository.update(id, name, code ?? '', sort_order ?? 0, description ?? '', is_active ?? true, is_leader ?? false, is_handle_document ?? false);
    if (!updated) {
      res.status(404).json({ success: false, message: 'Không tìm thấy chức vụ' });
      return;
    }
    res.json({ success: true, data: { updated: true } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /chuc-vu/:id
router.delete('/chuc-vu/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const result = await positionRepository.delete(id);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { message: result.message } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// STAFF (Người dùng)
// ============================================================

// GET /nguoi-dung
// Helper: chan non-admin sua/xoa user co is_admin=true HOAC user ngoai scope subtree.
// Tra ve true neu BLOCK (caller phai return ngay), false neu OK tiep tuc.
async function blockIfModifyingAdmin(req: Request, res: Response, targetId: number): Promise<boolean> {
  const currentUser = (req as AuthRequest).user;
  if (currentUser.isAdmin) return false; // admin co quyen sua/xoa moi user
  const target = await staffRepository.getById(targetId);
  if (!target) {
    res.status(404).json({ success: false, message: 'Không tìm thấy người dùng' });
    return true;
  }
  if (target.is_admin) {
    res.status(403).json({ success: false, message: 'Không có quyền thao tác với tài khoản quản trị hệ thống' });
    return true;
  }
  // Multi-tenant scope check: non-admin chi sua/xoa duoc user trong subtree minh
  const scope = await getUserUnitScope(req);
  if (scope !== null && target.unit_id !== scope) {
    res.status(403).json({ success: false, message: 'Không có quyền thao tác người dùng ngoài phạm vi quản lý' });
    return true;
  }
  return false;
}

router.get('/nguoi-dung', async (req: Request, res: Response) => {
  try {
    let unitId = req.query.unit_id ? Number(req.query.unit_id) : null;
    let departmentId = req.query.department_id ? Number(req.query.department_id) : null;
    // Khi co department_id, auto-resolve unit_id tu ancestor cua dept (luon chinh xac).
    // Tranh case page truyen unit_id=admin's unit nhung click dept khac don vi -> SP filter sai.
    // (Note: admin route nay shadow boi public-catalog.ts mount truoc — fix da apply o ca 2 noi.)
    // Auto-promote: neu caller truyen unit_id=X nhung X la phong con (is_unit=false),
    // tu nang cap thanh filter ancestor unit + narrow xuong dung phong do — tranh
    // filter `s.unit_id=phong-id` tra 0 row (vi staff.unit_id luon la ancestor unit).
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
    }

    // Multi-tenant scope: force unit_id = user.unit_id neu user khong o root.
    // adminso (UBND root) -> scope=null -> respect query.unit_id (cross-DN).
    // admindn001 (DN.001) -> scope=101 -> force unitId=101, ignore query.
    const scope = await getUserUnitScope(req);
    if (scope !== null) {
      unitId = scope;
      // Neu query co department_id, validate dept thuoc scope subtree
      if (departmentId && !(await isInSubtree(departmentId, scope))) {
        // Dept khong thuoc scope -> reset ve null, tra ket qua rong
        departmentId = null;
      }
    }

    const keyword = (req.query.keyword as string) || '';
    const isLocked = req.query.is_locked !== undefined ? req.query.is_locked === 'true' : null;
    const page = Number(req.query.page) || 1;
    const pageSize = Number(req.query.pageSize) || 20;

    const rows = await staffRepository.getList(unitId, departmentId, keyword, isLocked, page, pageSize);
    // An tai khoan is_admin=true khoi danh sach cho non-admin (vd Admin So) — bao ve khoi
    // viec xoa/sua nham admin. Admin tu thay duoc TAT CA user (KHONG filter).
    const currentUser = (req as AuthRequest).user;
    const filteredRows = currentUser.isAdmin ? rows : rows.filter((r) => !r.is_admin);
    const total = filteredRows.length > 0 ? Number(filteredRows[0].total_count) : 0;
    const totalPages = Math.ceil(total / pageSize);

    res.json({ success: true, data: filteredRows, total, page, pageSize, totalPages });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /nguoi-dung/:id
router.get('/nguoi-dung/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const data = await staffRepository.getById(id);
    if (!data) {
      res.status(404).json({ success: false, message: 'Không tìm thấy người dùng' });
      return;
    }
    // Chan non-admin xem chi tiet tai khoan admin (defense in depth)
    const currentUser = (req as AuthRequest).user;
    if (data.is_admin && !currentUser.isAdmin) {
      res.status(403).json({ success: false, message: 'Không có quyền xem tài khoản quản trị hệ thống' });
      return;
    }
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /nguoi-dung
router.post('/nguoi-dung', async (req: Request, res: Response) => {
  try {
    const currentUser = (req as AuthRequest).user;
    const { staffId } = currentUser;
    const {
      department_id, unit_id, position_id, username, password,
      first_name, last_name, gender, birth_date, email, phone, mobile,
      address, id_card, id_card_date, id_card_place,
      is_admin, is_represent_unit, is_represent_department,
    } = req.body;

    // Chan non-admin tao tai khoan voi flag is_admin=true
    if (is_admin && !currentUser.isAdmin) {
      res.status(403).json({ success: false, message: 'Không có quyền tạo tài khoản quản trị hệ thống' });
      return;
    }

    // Multi-tenant scope: validate unit_id moi phai khop scope (subtree user.unit)
    const scope = await getUserUnitScope(req);
    if (scope !== null) {
      if (Number(unit_id) !== scope) {
        res.status(403).json({ success: false, message: 'Không có quyền tạo người dùng ngoài phạm vi quản lý' });
        return;
      }
      // Department phai trong subtree cua scope
      if (department_id && !(await isInSubtree(Number(department_id), scope))) {
        res.status(403).json({ success: false, message: 'Phòng ban nằm ngoài phạm vi quản lý' });
        return;
      }
    }

    // Password policy (only on create, when password is provided)
    if (password) {
      if (password.length < 6) {
        res.status(400).json({ success: false, message: 'Mật khẩu phải có ít nhất 6 ký tự' });
        return;
      }
      if (!/[A-Z]/.test(password) || !/[a-z]/.test(password) || !/[0-9]/.test(password)) {
        res.status(400).json({ success: false, message: 'Mật khẩu phải chứa chữ hoa, chữ thường và số' });
        return;
      }
    }

    // Username validation
    if (!username || username.trim().length < 3) {
      res.status(400).json({ success: false, message: 'Tên đăng nhập phải có ít nhất 3 ký tự' });
      return;
    }
    // BUG-F-ND-001: validate username ≤ 50 ký tự (DB VARCHAR(50))
    if (username.trim().length > 50) {
      res.status(400).json({ success: false, message: 'Tên đăng nhập không được vượt quá 50 ký tự' });
      return;
    }
    if (!/^[a-zA-Z0-9._-]+$/.test(username.trim())) {
      res.status(400).json({ success: false, message: 'Tên đăng nhập chỉ chứa chữ cái, số, dấu chấm, gạch ngang' });
      return;
    }

    // Required fields
    if (!last_name?.trim() || !first_name?.trim()) {
      res.status(400).json({ success: false, message: 'Họ và tên là bắt buộc' });
      return;
    }
    if (!department_id || !unit_id) {
      res.status(400).json({ success: false, message: 'Đơn vị và phòng ban là bắt buộc' });
      return;
    }

    // Email validation (if provided)
    if (email && email.trim()) {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(email.trim())) {
        res.status(400).json({ success: false, message: 'Email không đúng định dạng' });
        return;
      }
    }

    // Phone validation (if provided)
    if (phone && phone.trim()) {
      const phoneRegex = /^[0-9+\-\s()]{8,15}$/;
      if (!phoneRegex.test(phone.trim())) {
        res.status(400).json({ success: false, message: 'Số điện thoại không đúng định dạng' });
        return;
      }
    }
    if (mobile && mobile.trim()) {
      const phoneRegex = /^[0-9+\-\s()]{8,15}$/;
      if (!phoneRegex.test(mobile.trim())) {
        res.status(400).json({ success: false, message: 'Số di động không đúng định dạng' });
        return;
      }
    }

    const normalizedUsername = username.trim().toLowerCase().replace(/\s+/g, '');
    const passwordHash = hashPassword(password || 'Admin@123');

    const result = await staffRepository.create(
      department_id, unit_id, position_id, normalizedUsername, passwordHash,
      first_name, last_name, gender ?? 0, birth_date ?? null,
      email ?? '', phone ?? '', mobile ?? '', address ?? '',
      id_card ?? '', id_card_date ?? null, id_card_place ?? '',
      is_admin ?? false, is_represent_unit ?? false, is_represent_department ?? false,
      staffId,
    );

    if (!result || result.id === 0) {
      res.status(409).json({ success: false, message: result?.message || 'Không thể tạo người dùng' });
      return;
    }

    res.status(201).json({ success: true, data: { id: result.id }, message: 'Thêm thành công' });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PUT /nguoi-dung/:id
router.put('/nguoi-dung/:id', async (req: Request, res: Response) => {
  try {
    const currentUser = (req as AuthRequest).user;
    const { staffId } = currentUser;
    const id = Number(req.params.id);

    // Chan non-admin sua tai khoan is_admin=true
    if (await blockIfModifyingAdmin(req, res, id)) return;

    const {
      department_id, unit_id, position_id,
      first_name, last_name, gender, birth_date, email, phone, mobile,
      address, id_card, id_card_date, id_card_place,
      is_admin, is_represent_unit, is_represent_department,
    } = req.body;

    // Multi-tenant scope: KHONG cho doi unit_id/department_id ra ngoai scope
    const putScope = await getUserUnitScope(req);
    if (putScope !== null) {
      if (Number(unit_id) !== putScope) {
        res.status(403).json({ success: false, message: 'Không thể chuyển người dùng ra ngoài phạm vi quản lý' });
        return;
      }
      if (department_id && !(await isInSubtree(Number(department_id), putScope))) {
        res.status(403).json({ success: false, message: 'Phòng ban nằm ngoài phạm vi quản lý' });
        return;
      }
    }

    // Chan non-admin nang quyen 1 user thanh is_admin=true (escalation)
    if (is_admin && !currentUser.isAdmin) {
      res.status(403).json({ success: false, message: 'Không có quyền cấp quyền quản trị hệ thống' });
      return;
    }

    // Required fields
    if (!last_name?.trim() || !first_name?.trim()) {
      res.status(400).json({ success: false, message: 'Họ và tên là bắt buộc' });
      return;
    }
    if (!department_id || !unit_id) {
      res.status(400).json({ success: false, message: 'Đơn vị và phòng ban là bắt buộc' });
      return;
    }

    // Email validation (if provided)
    if (email && email.trim()) {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(email.trim())) {
        res.status(400).json({ success: false, message: 'Email không đúng định dạng' });
        return;
      }

      // Email unique check (excluding current user)
      const emailExists = await pool.query(
        'SELECT id FROM staff WHERE LOWER(email) = LOWER($1) AND is_deleted = FALSE AND id != $2',
        [email.trim(), id]
      );
      if (emailExists.rows.length > 0) {
        res.status(409).json({ success: false, message: 'Email đã được sử dụng' });
        return;
      }
    }

    // Phone validation (if provided)
    if (phone && phone.trim()) {
      const phoneRegex = /^[0-9+\-\s()]{8,15}$/;
      if (!phoneRegex.test(phone.trim())) {
        res.status(400).json({ success: false, message: 'Số điện thoại không đúng định dạng' });
        return;
      }
    }
    if (mobile && mobile.trim()) {
      const phoneRegex = /^[0-9+\-\s()]{8,15}$/;
      if (!phoneRegex.test(mobile.trim())) {
        res.status(400).json({ success: false, message: 'Số di động không đúng định dạng' });
        return;
      }
    }

    const updated = await staffRepository.update(
      id, department_id, unit_id, position_id,
      first_name, last_name, gender ?? 0, birth_date ?? null,
      email ?? '', phone ?? '', mobile ?? '', address ?? '',
      id_card ?? '', id_card_date ?? null, id_card_place ?? '',
      is_admin ?? false, is_represent_unit ?? false, is_represent_department ?? false,
      staffId,
    );

    if (!updated) {
      res.status(404).json({ success: false, message: 'Không tìm thấy người dùng' });
      return;
    }
    res.json({ success: true, data: { updated: true } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /nguoi-dung/:id
router.delete('/nguoi-dung/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    // Chan non-admin xoa tai khoan is_admin=true
    if (await blockIfModifyingAdmin(req, res, id)) return;

    const deleted = await staffRepository.delete(id);
    if (!deleted) {
      res.status(404).json({ success: false, message: 'Không tìm thấy người dùng' });
      return;
    }
    res.json({ success: true, data: { deleted: true } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PATCH /nguoi-dung/:id/lock
router.patch('/nguoi-dung/:id/lock', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    // Chan non-admin khoa/mo khoa tai khoan is_admin=true
    if (await blockIfModifyingAdmin(req, res, id)) return;

    const toggled = await staffRepository.toggleLock(id);
    if (!toggled) {
      res.status(404).json({ success: false, message: 'Không tìm thấy người dùng' });
      return;
    }
    res.json({ success: true, data: { toggled: true } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PATCH /nguoi-dung/:id/reset-password
router.patch('/nguoi-dung/:id/reset-password', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    // Chan non-admin reset password tai khoan is_admin=true
    if (await blockIfModifyingAdmin(req, res, id)) return;

    const passwordHash = hashPassword('Admin@123');
    const reset = await staffRepository.resetPassword(id, passwordHash);
    if (!reset) {
      res.status(404).json({ success: false, message: 'Không tìm thấy người dùng' });
      return;
    }
    res.json({ success: true, message: 'Đã reset mật khẩu về mặc định (Admin@123)' });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PATCH /nguoi-dung/:id/change-password
router.patch('/nguoi-dung/:id/change-password', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const { oldPassword, newPassword } = req.body;

    if (!oldPassword || !newPassword) {
      res.status(400).json({ success: false, message: 'Mật khẩu cũ và mật khẩu mới là bắt buộc' });
      return;
    }

    if (oldPassword === newPassword) {
      res.status(400).json({ success: false, message: 'Mật khẩu mới không được trùng với mật khẩu hiện tại' });
      return;
    }

    if (newPassword.length < 6 || !/[A-Z]/.test(newPassword) || !/[a-z]/.test(newPassword) || !/[0-9]/.test(newPassword)) {
      res.status(400).json({ success: false, message: 'Mật khẩu mới phải có ít nhất 6 ký tự, chứa chữ hoa, chữ thường và số' });
      return;
    }

    const result = await pool.query('SELECT password_hash FROM public.staff WHERE id = $1 AND is_deleted = FALSE', [id]);
    const staff = result.rows[0];
    if (!staff) {
      res.status(404).json({ success: false, message: 'Không tìm thấy người dùng' });
      return;
    }

    const isValid = verifyPassword(oldPassword, staff.password_hash);
    if (!isValid) {
      res.status(400).json({ success: false, message: 'Mật khẩu hiện tại không đúng' });
      return;
    }

    const newPasswordHash = hashPassword(newPassword);
    const reset = await staffRepository.resetPassword(id, newPasswordHash);
    if (!reset) {
      res.status(500).json({ success: false, message: 'Không thể đổi mật khẩu' });
      return;
    }
    res.json({ success: true, data: { changed: true } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /nguoi-dung/:id/nhom-quyen
router.get('/nguoi-dung/:id/nhom-quyen', async (req: Request, res: Response) => {
  try {
    const staffId = Number(req.params.id);
    const data = await roleRepository.getStaffRoles(staffId);
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// Role 5 = "Quan tri he thong" (seed/001 line 109) — co TAT CA rights -> equivalent
// voi is_admin=true ve mat permission. Chan non-admin gan/giu role 5 cho user khac
// de tranh privilege escalation (Admin So co the tao user voi role 5 -> user do co
// quyen full admin).
const SYSTEM_ADMIN_ROLE_ID = 5;

// PUT /nguoi-dung/:id/nhom-quyen
router.put('/nguoi-dung/:id/nhom-quyen', async (req: Request, res: Response) => {
  try {
    const currentUser = (req as AuthRequest).user;
    const staffId = Number(req.params.id);
    // Chan non-admin thay doi quyen tai khoan is_admin=true
    if (await blockIfModifyingAdmin(req, res, staffId)) return;

    const { roleIds } = req.body;
    const requestedRoleIds: number[] = Array.isArray(roleIds) ? roleIds.map((id) => Number(id)) : [];

    // Privilege escalation guard: non-admin KHONG duoc gan role "Quan tri he thong" (role 5)
    if (!currentUser.isAdmin && requestedRoleIds.includes(SYSTEM_ADMIN_ROLE_ID)) {
      res.status(403).json({
        success: false,
        message: 'Không có quyền gán nhóm quyền "Quản trị hệ thống" cho người dùng khác',
      });
      return;
    }

    await roleRepository.assignStaffRoles(staffId, requestedRoleIds);
    res.json({ success: true, data: { assigned: true } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// LOOKUP endpoints (cho dropdown trong form tao/sua user)
// ----------------------------------------------------------
// Tach khoi /nhom-quyen + /chuc-vu (require right "Phan quyen" / "Chuc vu") ->
// chi can authenticated + co right "Nguoi dung" goi 2 dropdown nay.
// Admin So co right "Nguoi dung" nhung KHONG can right "Phan quyen"/"Chuc vu"
// (de menu 2 muc do an khoi UI) van chon duoc role + position khi tao user.
// ============================================================

// GET /lookup/roles
// An role 5 (Quan tri he thong) khoi dropdown cho non-admin -> UX defense.
// Backend PUT /nguoi-dung/:id/nhom-quyen van check lai (chot chan cung).
router.get('/lookup/roles', async (req: Request, res: Response) => {
  try {
    const currentUser = (req as AuthRequest).user;
    const unitId = req.query.unit_id ? Number(req.query.unit_id) : null;
    const all = await roleRepository.getList(unitId, '');
    const filtered = currentUser.isAdmin ? all : all.filter((r) => r.id !== SYSTEM_ADMIN_ROLE_ID);
    res.json({ success: true, data: filtered });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /lookup/positions — pageSize lon de lay tat ca (it record ~10-20)
router.get('/lookup/positions', async (_req: Request, res: Response) => {
  try {
    const data = await positionRepository.getList('', 1, 500);
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// ROLE (Nhóm quyền)
// ============================================================

// GET /nhom-quyen
router.get('/nhom-quyen', async (req: Request, res: Response) => {
  try {
    const unitId = req.query.unit_id ? Number(req.query.unit_id) : null;
    const keyword = (req.query.keyword as string) || '';
    const page = Math.max(1, Number(req.query.page) || 1);
    const pageSize = Math.max(1, Math.min(200, Number(req.query.pageSize) || Number(req.query.page_size) || 20));
    const all = await roleRepository.getList(unitId, keyword);
    const total = all.length;
    const data = all.slice((page - 1) * pageSize, page * pageSize);
    res.json({ success: true, data, pagination: { total, page, pageSize } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /nhom-quyen
router.post('/nhom-quyen', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const { name, description, unit_id } = req.body;

    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên nhóm quyền là bắt buộc' });
      return;
    }

    const existing = await pool.query(
      'SELECT id FROM roles WHERE LOWER(name) = LOWER($1)',
      [name.trim()]
    );
    if (existing.rows.length > 0) {
      res.status(409).json({ success: false, message: 'Tên nhóm quyền đã tồn tại' });
      return;
    }

    const id = await roleRepository.create(unit_id ?? ancestorUnitId, name, description ?? '', staffId);
    if (!id) {
      res.status(500).json({ success: false, message: 'Không thể tạo nhóm quyền' });
      return;
    }
    res.status(201).json({ success: true, data: { id } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PUT /nhom-quyen/:id
router.put('/nhom-quyen/:id', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const { name, description } = req.body;

    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên nhóm quyền là bắt buộc' });
      return;
    }

    const existing = await pool.query(
      'SELECT id FROM roles WHERE LOWER(name) = LOWER($1) AND id != $2',
      [name.trim(), id]
    );
    if (existing.rows.length > 0) {
      res.status(409).json({ success: false, message: 'Tên nhóm quyền đã tồn tại' });
      return;
    }

    const updated = await roleRepository.update(id, name, description ?? '', staffId);
    if (!updated) {
      res.status(404).json({ success: false, message: 'Không tìm thấy nhóm quyền' });
      return;
    }
    res.json({ success: true, data: { updated: true } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /nhom-quyen/:id
router.delete('/nhom-quyen/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const result = await roleRepository.delete(id);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { message: result.message } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /nhom-quyen/:id/quyen
router.get('/nhom-quyen/:id/quyen', async (req: Request, res: Response) => {
  try {
    const roleId = Number(req.params.id);
    const data = await roleRepository.getRights(roleId);
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PUT /nhom-quyen/:id/quyen
router.put('/nhom-quyen/:id/quyen', async (req: Request, res: Response) => {
  try {
    const roleId = Number(req.params.id);
    const { rightIds } = req.body;
    await roleRepository.assignRights(roleId, rightIds ?? []);
    res.json({ success: true, data: { assigned: true } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// RIGHT (Chức năng / Quyền)
// ============================================================

// GET /chuc-nang/tree — trả về cây phân cấp
router.get('/chuc-nang/tree', async (_req: Request, res: Response) => {
  try {
    const flatList = await rightRepository.getTree();
    const tree = buildTree(flatList);
    res.json({ success: true, data: tree });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /chuc-nang/menu
router.get('/chuc-nang/menu', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const data = await rightRepository.getByStaff(staffId);
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /chuc-nang
router.post('/chuc-nang', async (req: Request, res: Response) => {
  try {
    const {
      parent_id, name, name_of_menu, action_link, icon,
      sort_order, show_menu, default_page, show_in_app, description,
    } = req.body;

    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên chức năng là bắt buộc' });
      return;
    }

    const id = await rightRepository.create(
      parent_id ?? null, name, name_of_menu ?? '', action_link ?? '',
      icon ?? '', sort_order ?? 0, show_menu ?? true, default_page ?? false,
      show_in_app ?? false, description ?? '',
    );

    if (!id) {
      res.status(500).json({ success: false, message: 'Không thể tạo chức năng' });
      return;
    }
    res.status(201).json({ success: true, data: { id } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PUT /chuc-nang/:id
router.put('/chuc-nang/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const {
      parent_id, name, name_of_menu, action_link, icon,
      sort_order, show_menu, default_page, show_in_app, description,
    } = req.body;

    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên chức năng là bắt buộc' });
      return;
    }

    const updated = await rightRepository.update(
      id, parent_id ?? null, name, name_of_menu ?? '', action_link ?? '',
      icon ?? '', sort_order ?? 0, show_menu ?? true, default_page ?? false,
      show_in_app ?? false, description ?? '',
    );

    if (!updated) {
      res.status(404).json({ success: false, message: 'Không tìm thấy chức năng' });
      return;
    }
    res.json({ success: true, data: { updated: true } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /chuc-nang/:id
router.delete('/chuc-nang/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const result = await rightRepository.delete(id);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { message: result.message } });
  } catch (error) {
    handleDbError(error, res);
  }
});

export default router;
