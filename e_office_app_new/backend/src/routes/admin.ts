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

const router = Router();

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
    if (parentId && map.has(parentId)) {
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
    const unitId = req.query.unit_id ? Number(req.query.unit_id) : null;
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
    const unitId = req.query.unit_id ? Number(req.query.unit_id) : null;
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
    } = req.body;

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
    } = req.body;

    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên đơn vị là bắt buộc' });
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
    res.json({ success: true, data: { updated: true } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /don-vi/:id
router.delete('/don-vi/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
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
router.get('/nguoi-dung', async (req: Request, res: Response) => {
  try {
    const unitId = req.query.unit_id ? Number(req.query.unit_id) : null;
    const departmentId = req.query.department_id ? Number(req.query.department_id) : null;
    const keyword = (req.query.keyword as string) || '';
    const isLocked = req.query.is_locked !== undefined ? req.query.is_locked === 'true' : null;
    const page = Number(req.query.page) || 1;
    const pageSize = Number(req.query.pageSize) || 20;

    const rows = await staffRepository.getList(unitId, departmentId, keyword, isLocked, page, pageSize);
    const total = rows.length > 0 ? Number(rows[0].total_count) : 0;
    const totalPages = Math.ceil(total / pageSize);

    res.json({ success: true, data: rows, total, page, pageSize, totalPages });
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
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /nguoi-dung
router.post('/nguoi-dung', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const {
      department_id, unit_id, position_id, username, password,
      first_name, last_name, gender, birth_date, email, phone, mobile,
      address, id_card, id_card_date, id_card_place,
      is_admin, is_represent_unit, is_represent_department,
    } = req.body;

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
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const {
      department_id, unit_id, position_id,
      first_name, last_name, gender, birth_date, email, phone, mobile,
      address, id_card, id_card_date, id_card_place,
      is_admin, is_represent_unit, is_represent_department,
    } = req.body;

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

// PUT /nguoi-dung/:id/nhom-quyen
router.put('/nguoi-dung/:id/nhom-quyen', async (req: Request, res: Response) => {
  try {
    const staffId = Number(req.params.id);
    const { roleIds } = req.body;
    await roleRepository.assignStaffRoles(staffId, roleIds ?? []);
    res.json({ success: true, data: { assigned: true } });
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
    const data = await roleRepository.getList(unitId, keyword);
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /nhom-quyen
router.post('/nhom-quyen', async (req: Request, res: Response) => {
  try {
    const { staffId, unitId } = (req as AuthRequest).user;
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

    const id = await roleRepository.create(unit_id ?? unitId, name, description ?? '', staffId);
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
