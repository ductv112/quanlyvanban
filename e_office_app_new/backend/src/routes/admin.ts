import { Router } from 'express';
import type { Request, Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { hashPassword } from '../lib/auth/password.js';
import { departmentRepository } from '../repositories/department.repository.js';
import { positionRepository } from '../repositories/position.repository.js';
import { staffRepository } from '../repositories/staff.repository.js';
import { roleRepository } from '../repositories/role.repository.js';
import { rightRepository } from '../repositories/right.repository.js';

const router = Router();

// ============================================================
// DEPARTMENT (Đơn vị / Phòng ban)
// ============================================================

// GET /don-vi/tree
router.get('/don-vi/tree', async (req: Request, res: Response) => {
  try {
    const unitId = Number(req.query.unit_id) || 0;
    const data = await departmentRepository.getTree(unitId);
    res.json({ success: true, data });
  } catch (error) {
    res.status(500).json({ success: false, message: (error as Error).message });
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
    res.status(500).json({ success: false, message: (error as Error).message });
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

    const id = await departmentRepository.create(
      parent_id ?? null, code, name, name_en ?? '', short_name ?? '', abb_name ?? '',
      is_unit ?? false, level ?? 0, sort_order ?? 0, phone ?? '', fax ?? '',
      email ?? '', address ?? '', allow_doc_book ?? false, description ?? '',
      staffId,
    );

    res.status(201).json({ success: true, data: { id } });
  } catch (error) {
    res.status(500).json({ success: false, message: (error as Error).message });
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
    res.status(500).json({ success: false, message: (error as Error).message });
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
    res.status(500).json({ success: false, message: (error as Error).message });
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
    res.status(500).json({ success: false, message: (error as Error).message });
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
    res.status(500).json({ success: false, message: (error as Error).message });
  }
});

// POST /chuc-vu
router.post('/chuc-vu', async (req: Request, res: Response) => {
  try {
    const { name, code, sort_order, description } = req.body;
    const id = await positionRepository.create(name, code ?? '', sort_order ?? 0, description ?? '');
    res.status(201).json({ success: true, data: { id } });
  } catch (error) {
    res.status(500).json({ success: false, message: (error as Error).message });
  }
});

// PUT /chuc-vu/:id
router.put('/chuc-vu/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const { name, code, sort_order, description, is_active } = req.body;
    const updated = await positionRepository.update(id, name, code ?? '', sort_order ?? 0, description ?? '', is_active ?? true);
    if (!updated) {
      res.status(404).json({ success: false, message: 'Không tìm thấy chức vụ' });
      return;
    }
    res.json({ success: true, data: { updated: true } });
  } catch (error) {
    res.status(500).json({ success: false, message: (error as Error).message });
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
    res.status(500).json({ success: false, message: (error as Error).message });
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
    res.status(500).json({ success: false, message: (error as Error).message });
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
    res.status(500).json({ success: false, message: (error as Error).message });
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

    if (!username || !password) {
      res.status(400).json({ success: false, message: 'Tên đăng nhập và mật khẩu là bắt buộc' });
      return;
    }

    const passwordHash = hashPassword(password);

    const result = await staffRepository.create(
      department_id, unit_id, position_id, username, passwordHash,
      first_name, last_name, gender ?? 0, birth_date ?? null,
      email ?? '', phone ?? '', mobile ?? '', address ?? '',
      id_card ?? '', id_card_date ?? null, id_card_place ?? '',
      is_admin ?? false, is_represent_unit ?? false, is_represent_department ?? false,
      staffId,
    );

    if (!result) {
      res.status(400).json({ success: false, message: 'Không thể tạo người dùng' });
      return;
    }

    res.status(201).json({ success: true, data: result });
  } catch (error) {
    res.status(500).json({ success: false, message: (error as Error).message });
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
    res.status(500).json({ success: false, message: (error as Error).message });
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
    res.status(500).json({ success: false, message: (error as Error).message });
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
    res.status(500).json({ success: false, message: (error as Error).message });
  }
});

// PATCH /nguoi-dung/:id/reset-password
router.patch('/nguoi-dung/:id/reset-password', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const { password } = req.body;

    if (!password) {
      res.status(400).json({ success: false, message: 'Mật khẩu mới là bắt buộc' });
      return;
    }

    const passwordHash = hashPassword(password);
    const reset = await staffRepository.resetPassword(id, passwordHash);
    if (!reset) {
      res.status(404).json({ success: false, message: 'Không tìm thấy người dùng' });
      return;
    }
    res.json({ success: true, data: { reset: true } });
  } catch (error) {
    res.status(500).json({ success: false, message: (error as Error).message });
  }
});

// GET /nguoi-dung/:id/nhom-quyen
router.get('/nguoi-dung/:id/nhom-quyen', async (req: Request, res: Response) => {
  try {
    const staffId = Number(req.params.id);
    const data = await roleRepository.getStaffRoles(staffId);
    res.json({ success: true, data });
  } catch (error) {
    res.status(500).json({ success: false, message: (error as Error).message });
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
    res.status(500).json({ success: false, message: (error as Error).message });
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
    res.status(500).json({ success: false, message: (error as Error).message });
  }
});

// POST /nhom-quyen
router.post('/nhom-quyen', async (req: Request, res: Response) => {
  try {
    const { staffId, unitId } = (req as AuthRequest).user;
    const { name, description, unit_id } = req.body;
    const id = await roleRepository.create(unit_id ?? unitId, name, description ?? '', staffId);
    res.status(201).json({ success: true, data: { id } });
  } catch (error) {
    res.status(500).json({ success: false, message: (error as Error).message });
  }
});

// PUT /nhom-quyen/:id
router.put('/nhom-quyen/:id', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const { name, description } = req.body;
    const updated = await roleRepository.update(id, name, description ?? '', staffId);
    if (!updated) {
      res.status(404).json({ success: false, message: 'Không tìm thấy nhóm quyền' });
      return;
    }
    res.json({ success: true, data: { updated: true } });
  } catch (error) {
    res.status(500).json({ success: false, message: (error as Error).message });
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
    res.status(500).json({ success: false, message: (error as Error).message });
  }
});

// GET /nhom-quyen/:id/quyen
router.get('/nhom-quyen/:id/quyen', async (req: Request, res: Response) => {
  try {
    const roleId = Number(req.params.id);
    const data = await roleRepository.getRights(roleId);
    res.json({ success: true, data });
  } catch (error) {
    res.status(500).json({ success: false, message: (error as Error).message });
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
    res.status(500).json({ success: false, message: (error as Error).message });
  }
});

// ============================================================
// RIGHT (Chức năng / Quyền)
// ============================================================

// GET /chuc-nang/tree
router.get('/chuc-nang/tree', async (_req: Request, res: Response) => {
  try {
    const data = await rightRepository.getTree();
    res.json({ success: true, data });
  } catch (error) {
    res.status(500).json({ success: false, message: (error as Error).message });
  }
});

// GET /chuc-nang/menu
router.get('/chuc-nang/menu', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const data = await rightRepository.getByStaff(staffId);
    res.json({ success: true, data });
  } catch (error) {
    res.status(500).json({ success: false, message: (error as Error).message });
  }
});

// POST /chuc-nang
router.post('/chuc-nang', async (req: Request, res: Response) => {
  try {
    const {
      parent_id, name, name_of_menu, action_link, icon,
      sort_order, show_menu, default_page, show_in_app, description,
    } = req.body;

    const id = await rightRepository.create(
      parent_id ?? null, name, name_of_menu ?? '', action_link ?? '',
      icon ?? '', sort_order ?? 0, show_menu ?? true, default_page ?? false,
      show_in_app ?? false, description ?? '',
    );

    res.status(201).json({ success: true, data: { id } });
  } catch (error) {
    res.status(500).json({ success: false, message: (error as Error).message });
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
    res.status(500).json({ success: false, message: (error as Error).message });
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
    res.status(500).json({ success: false, message: (error as Error).message });
  }
});

export default router;
