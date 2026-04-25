import { Router } from 'express';
import type { Request, Response } from 'express';
import { callFunction, callFunctionOne } from '../lib/db/query.js';
import type { AuthRequest } from '../middleware/auth.js';
import { docBookRepository } from '../repositories/doc-book.repository.js';
import { docTypeRepository } from '../repositories/doc-type.repository.js';
import { docFieldRepository } from '../repositories/doc-field.repository.js';
import { docColumnRepository } from '../repositories/doc-column.repository.js';
import { organizationRepository } from '../repositories/organization.repository.js';
import { signerRepository } from '../repositories/signer.repository.js';
import { workGroupRepository } from '../repositories/work-group.repository.js';
import { delegationRepository } from '../repositories/delegation.repository.js';
import { addressRepository } from '../repositories/address.repository.js';
import { workCalendarRepository } from '../repositories/work-calendar.repository.js';
import { templateRepository } from '../repositories/template.repository.js';
import { configRepository } from '../repositories/config.repository.js';
import { handleDbError } from '../lib/error-handler.js';
import { resolveAncestorUnit } from '../lib/department-subtree.js';

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
// 2.1 DOC BOOK (Sổ văn bản)
// ============================================================

// GET /so-van-ban
router.get('/so-van-ban', async (req: Request, res: Response) => {
  try {
    const { departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const typeId = req.query.type_id ? Number(req.query.type_id) : null;
    const uId = req.query.unit_id ? Number(req.query.unit_id) : ancestorUnitId;
    const data = await docBookRepository.getList(typeId, uId);
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /so-van-ban/:id
router.get('/so-van-ban/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const data = await docBookRepository.getById(id);
    if (!data) {
      res.status(404).json({ success: false, message: 'Không tìm thấy sổ văn bản' });
      return;
    }
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /so-van-ban
router.post('/so-van-ban', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const { type_id, unit_id, name, is_default, description } = req.body;

    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên sổ văn bản là bắt buộc' });
      return;
    }
    if (name.trim().length > 200) {
      res.status(400).json({ success: false, message: 'Tên sổ văn bản không được vượt quá 200 ký tự' });
      return;
    }
    if (!type_id) {
      res.status(400).json({ success: false, message: 'Loại văn bản là bắt buộc' });
      return;
    }

    const result = await docBookRepository.create(
      type_id,
      unit_id ?? ancestorUnitId,
      name.trim(),
      is_default ?? false,
      description ?? '',
      staffId,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.status(201).json({ success: true, data: { id: result.id } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PUT /so-van-ban/:id
router.put('/so-van-ban/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const { name, is_default, description, sort_order } = req.body;

    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên sổ văn bản là bắt buộc' });
      return;
    }
    if (name.trim().length > 200) {
      res.status(400).json({ success: false, message: 'Tên sổ văn bản không được vượt quá 200 ký tự' });
      return;
    }

    const result = await docBookRepository.update(
      id,
      name.trim(),
      is_default ?? false,
      description ?? '',
      sort_order ?? 0,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { updated: true } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /so-van-ban/:id
router.delete('/so-van-ban/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const result = await docBookRepository.delete(id);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { message: result.message } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PATCH /so-van-ban/:id/mac-dinh
router.patch('/so-van-ban/:id/mac-dinh', async (req: Request, res: Response) => {
  try {
    const { departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const id = Number(req.params.id);
    const { type_id, unit_id } = req.body;

    const result = await docBookRepository.setDefault(id, type_id ?? 0, unit_id ?? ancestorUnitId);
    if (!result) {
      res.status(404).json({ success: false, message: 'Không tìm thấy sổ văn bản' });
      return;
    }
    res.json({ success: true, data: { updated: true } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// 2.2 DOC TYPE (Loại văn bản)
// ============================================================

// GET /loai-van-ban/tree
router.get('/loai-van-ban/tree', async (req: Request, res: Response) => {
  try {
    const typeId = req.query.type_id ? Number(req.query.type_id) : null;
    const flatList = await docTypeRepository.getTree(typeId);
    const tree = buildTree(flatList);
    res.json({ success: true, data: tree });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /loai-van-ban/:id
router.get('/loai-van-ban/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const data = await docTypeRepository.getById(id);
    if (!data) {
      res.status(404).json({ success: false, message: 'Không tìm thấy loại văn bản' });
      return;
    }
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /loai-van-ban
router.post('/loai-van-ban', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const { type_id, parent_id, name, code, notation_type, sort_order } = req.body;

    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên loại văn bản là bắt buộc' });
      return;
    }
    if (name.trim().length > 200) {
      res.status(400).json({ success: false, message: 'Tên loại văn bản không được vượt quá 200 ký tự' });
      return;
    }
    if (!code?.trim()) {
      res.status(400).json({ success: false, message: 'Mã loại văn bản là bắt buộc' });
      return;
    }
    if (code.trim().length > 20) {
      res.status(400).json({ success: false, message: 'Mã loại văn bản không được vượt quá 20 ký tự' });
      return;
    }

    const result = await docTypeRepository.create(
      type_id ?? 0,
      parent_id ?? null,
      name.trim(),
      code.trim(),
      Number(notation_type) || 0,
      sort_order ?? 0,
      staffId,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.status(201).json({ success: true, data: { id: result.id } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PUT /loai-van-ban/:id
router.put('/loai-van-ban/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const { parent_id, name, code, notation_type, sort_order } = req.body;

    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên loại văn bản là bắt buộc' });
      return;
    }
    if (name.trim().length > 200) {
      res.status(400).json({ success: false, message: 'Tên loại văn bản không được vượt quá 200 ký tự' });
      return;
    }
    if (!code?.trim()) {
      res.status(400).json({ success: false, message: 'Mã loại văn bản là bắt buộc' });
      return;
    }
    if (code.trim().length > 20) {
      res.status(400).json({ success: false, message: 'Mã loại văn bản không được vượt quá 20 ký tự' });
      return;
    }

    const result = await docTypeRepository.update(
      id,
      parent_id ?? null,
      name.trim(),
      code.trim(),
      Number(notation_type) || 0,
      sort_order ?? 0,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { updated: true } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /loai-van-ban/:id
router.delete('/loai-van-ban/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const result = await docTypeRepository.delete(id);
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
// 2.3 DOC FIELD (Lĩnh vực)
// ============================================================

// GET /linh-vuc
router.get('/linh-vuc', async (req: Request, res: Response) => {
  try {
    const { departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const uId = req.query.unit_id ? Number(req.query.unit_id) : ancestorUnitId;
    const keyword = (req.query.keyword as string) || '';
    const data = await docFieldRepository.getList(uId, keyword);
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /linh-vuc/:id
router.get('/linh-vuc/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const data = await docFieldRepository.getById(id);
    if (!data) {
      res.status(404).json({ success: false, message: 'Không tìm thấy lĩnh vực' });
      return;
    }
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /linh-vuc
router.post('/linh-vuc', async (req: Request, res: Response) => {
  try {
    const { departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const { unit_id, code, name } = req.body;

    if (!code?.trim()) {
      res.status(400).json({ success: false, message: 'Mã lĩnh vực là bắt buộc' });
      return;
    }
    if (code.trim().length > 20) {
      res.status(400).json({ success: false, message: 'Mã lĩnh vực không được vượt quá 20 ký tự' });
      return;
    }
    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên lĩnh vực là bắt buộc' });
      return;
    }
    if (name.trim().length > 200) {
      res.status(400).json({ success: false, message: 'Tên lĩnh vực không được vượt quá 200 ký tự' });
      return;
    }

    const result = await docFieldRepository.create(unit_id ?? ancestorUnitId, code.trim(), name.trim());

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.status(201).json({ success: true, data: { id: result.id } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PUT /linh-vuc/:id
router.put('/linh-vuc/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const { code, name, sort_order, is_active } = req.body;

    if (!code?.trim()) {
      res.status(400).json({ success: false, message: 'Mã lĩnh vực là bắt buộc' });
      return;
    }
    if (code.trim().length > 20) {
      res.status(400).json({ success: false, message: 'Mã lĩnh vực không được vượt quá 20 ký tự' });
      return;
    }
    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên lĩnh vực là bắt buộc' });
      return;
    }
    if (name.trim().length > 200) {
      res.status(400).json({ success: false, message: 'Tên lĩnh vực không được vượt quá 200 ký tự' });
      return;
    }

    const result = await docFieldRepository.update(
      id,
      code.trim(),
      name.trim(),
      sort_order ?? 0,
      is_active ?? true,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { updated: true } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /linh-vuc/:id
router.delete('/linh-vuc/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const result = await docFieldRepository.delete(id);
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
// 2.4 DOC COLUMN (Thuộc tính văn bản)
// ============================================================

// GET /thuoc-tinh-van-ban
router.get('/thuoc-tinh-van-ban', async (req: Request, res: Response) => {
  try {
    const typeId = req.query.type_id ? Number(req.query.type_id) : null;
    const data = await docColumnRepository.getList(typeId);
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PUT /thuoc-tinh-van-ban/:id
router.put('/thuoc-tinh-van-ban/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const { label, is_mandatory, is_show_all, sort_order } = req.body;

    const result = await docColumnRepository.update(
      id,
      label ?? '',
      is_mandatory ?? false,
      is_show_all ?? false,
      sort_order ?? 0,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { updated: true } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PATCH /thuoc-tinh-van-ban/:id/toggle
router.patch('/thuoc-tinh-van-ban/:id/toggle', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const result = await docColumnRepository.toggleVisibility(id);
    if (!result) {
      res.status(404).json({ success: false, message: 'Không tìm thấy thuộc tính' });
      return;
    }
    res.json({ success: true, data: { toggled: true } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// 2.5 ORGANIZATION (Cơ quan)
// ============================================================

// GET /co-quan
router.get('/co-quan', async (req: Request, res: Response) => {
  try {
    const { departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const uId = req.query.unit_id ? Number(req.query.unit_id) : ancestorUnitId;
    const data = await organizationRepository.get(uId);
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PUT /co-quan
router.put('/co-quan', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const {
      unit_id, code, name, address, phone, fax, email,
      email_doc, secretary, chairman_number, level, is_exchange,
    } = req.body;

    const uId = unit_id ?? ancestorUnitId;
    if (!uId) {
      res.status(400).json({ success: false, message: 'Đơn vị là bắt buộc' });
      return;
    }
    if (name && name.trim().length > 200) {
      res.status(400).json({ success: false, message: 'Tên cơ quan không được vượt quá 200 ký tự' });
      return;
    }
    if (email && email.trim().length > 100) {
      res.status(400).json({ success: false, message: 'Email không được vượt quá 100 ký tự' });
      return;
    }
    if (phone && phone.trim().length > 20) {
      res.status(400).json({ success: false, message: 'Số điện thoại không được vượt quá 20 ký tự' });
      return;
    }

    const result = await organizationRepository.upsert(
      uId,
      code ?? '',
      name ?? '',
      address ?? '',
      phone ?? '',
      fax ?? '',
      email ?? '',
      email_doc ?? '',
      secretary ?? '',
      chairman_number ?? '',
      level ?? 0,
      is_exchange ?? false,
      staffId,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { updated: true } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// 2.6 SIGNER (Người ký)
// ============================================================

// GET /nguoi-ky
router.get('/nguoi-ky', async (req: Request, res: Response) => {
  try {
    const { departmentId } = (req as AuthRequest).user;
    const callerUnitId = await resolveAncestorUnit(departmentId);
    const deptIdFilter = req.query.department_id ? Number(req.query.department_id) : null;
    // Resolve unit_id theo dept duoc click (admin co the quan ly signers cua moi don vi).
    // Ru tien thu tu: ancestor cua department_id (luon chinh xac) > explicit unit_id query > unit cua user.
    // Lan truoc bug: page truyen unit_id=user's unit nhung admin click dept khac don vi -> SP filter sai.
    let uId: number;
    if (deptIdFilter) {
      uId = await resolveAncestorUnit(deptIdFilter);
    } else if (req.query.unit_id) {
      uId = Number(req.query.unit_id);
    } else {
      uId = callerUnitId;
    }
    const data = await signerRepository.getList(uId, deptIdFilter);
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /nguoi-ky
router.post('/nguoi-ky', async (req: Request, res: Response) => {
  try {
    const { departmentId: callerDeptId } = (req as AuthRequest).user;
    const callerUnitId = await resolveAncestorUnit(callerDeptId);
    const { unit_id, department_id, staff_id } = req.body;

    if (!staff_id) {
      res.status(400).json({ success: false, message: 'Nhân viên là bắt buộc' });
      return;
    }

    // Resolve unit_id chinh xac:
    // - Neu client gui department_id -> ancestor cua dept (luon dung)
    // - Else neu client gui unit_id -> dung
    // - Else fallback unit cua admin
    let resolvedUnitId: number;
    if (department_id) {
      resolvedUnitId = await resolveAncestorUnit(Number(department_id));
    } else if (unit_id) {
      resolvedUnitId = Number(unit_id);
    } else {
      resolvedUnitId = callerUnitId;
    }

    if (!resolvedUnitId) {
      res.status(400).json({ success: false, message: 'Đơn vị là bắt buộc' });
      return;
    }

    const result = await signerRepository.create(
      resolvedUnitId,
      department_id ? Number(department_id) : null,
      Number(staff_id),
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.status(201).json({ success: true, data: { id: result.id } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /nguoi-ky/:id
router.delete('/nguoi-ky/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const result = await signerRepository.delete(id);
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
// 2.7 WORK GROUP (Nhóm làm việc)
// ============================================================

// GET /nhom-lam-viec
router.get('/nhom-lam-viec', async (req: Request, res: Response) => {
  try {
    const { departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const uId = req.query.unit_id ? Number(req.query.unit_id) : ancestorUnitId;
    const data = await workGroupRepository.getList(uId);
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /nhom-lam-viec/:id — must be before /:id/thanh-vien
router.get('/nhom-lam-viec/:id', async (req: Request, res: Response) => {
  try {
    // Skip if the "id" is actually "thanh-vien" sub-path (handled by next route)
    if (req.params.id === 'thanh-vien') return;
    const id = Number(req.params.id);
    const data = await workGroupRepository.getById(id);
    if (!data) {
      res.status(404).json({ success: false, message: 'Không tìm thấy nhóm làm việc' });
      return;
    }
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /nhom-lam-viec
router.post('/nhom-lam-viec', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const { unit_id, name, function: func, sort_order } = req.body;

    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên nhóm làm việc là bắt buộc' });
      return;
    }
    if (name.trim().length > 200) {
      res.status(400).json({ success: false, message: 'Tên nhóm làm việc không được vượt quá 200 ký tự' });
      return;
    }

    const result = await workGroupRepository.create(
      unit_id ?? ancestorUnitId,
      name.trim(),
      func ?? '',
      sort_order ?? 0,
      staffId,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.status(201).json({ success: true, data: { id: result.id } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PUT /nhom-lam-viec/:id
router.put('/nhom-lam-viec/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const { name, function: func, sort_order } = req.body;

    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên nhóm làm việc là bắt buộc' });
      return;
    }
    if (name.trim().length > 200) {
      res.status(400).json({ success: false, message: 'Tên nhóm làm việc không được vượt quá 200 ký tự' });
      return;
    }

    const result = await workGroupRepository.update(
      id,
      name.trim(),
      func ?? '',
      sort_order ?? 0,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { updated: true } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /nhom-lam-viec/:id
router.delete('/nhom-lam-viec/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const result = await workGroupRepository.delete(id);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { message: result.message } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /nhom-lam-viec/:id/thanh-vien
router.get('/nhom-lam-viec/:id/thanh-vien', async (req: Request, res: Response) => {
  try {
    const groupId = Number(req.params.id);
    const data = await workGroupRepository.getMembers(groupId);
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PUT /nhom-lam-viec/:id/thanh-vien
router.put('/nhom-lam-viec/:id/thanh-vien', async (req: Request, res: Response) => {
  try {
    const groupId = Number(req.params.id);
    const { staff_ids } = req.body;

    if (!Array.isArray(staff_ids)) {
      res.status(400).json({ success: false, message: 'Danh sách nhân viên không hợp lệ' });
      return;
    }

    const result = await workGroupRepository.assignMembers(groupId, staff_ids);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { updated: true } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// 2.8 DELEGATION (Ủy quyền)
// ============================================================

// GET /uy-quyen
router.get('/uy-quyen', async (req: Request, res: Response) => {
  try {
    const { departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const uId = req.query.unit_id ? Number(req.query.unit_id) : ancestorUnitId;
    const staffId = req.query.staff_id ? Number(req.query.staff_id) : null;
    const data = await delegationRepository.getList(uId, staffId);
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /uy-quyen
router.post('/uy-quyen', async (req: Request, res: Response) => {
  try {
    const { from_staff_id, to_staff_id, start_date, end_date, note } = req.body;

    if (!from_staff_id) {
      res.status(400).json({ success: false, message: 'Người ủy quyền là bắt buộc' });
      return;
    }
    if (!to_staff_id) {
      res.status(400).json({ success: false, message: 'Người được ủy quyền là bắt buộc' });
      return;
    }
    if (!start_date) {
      res.status(400).json({ success: false, message: 'Ngày bắt đầu là bắt buộc' });
      return;
    }
    if (!end_date) {
      res.status(400).json({ success: false, message: 'Ngày kết thúc là bắt buộc' });
      return;
    }

    const result = await delegationRepository.create(
      from_staff_id,
      to_staff_id,
      start_date,
      end_date,
      note ?? '',
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.status(201).json({ success: true, data: { id: result.id } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /uy-quyen/:id
router.delete('/uy-quyen/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const result = await delegationRepository.revoke(id);
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
// 2.9 ADDRESS (Địa bàn)
// ============================================================

// --- Province (Tỉnh/Thành phố) ---

// GET /dia-ban/tinh
router.get('/dia-ban/tinh', async (req: Request, res: Response) => {
  try {
    const keyword = (req.query.keyword as string) || '';
    const data = await addressRepository.provinceGetList(keyword);
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /dia-ban/tinh
router.post('/dia-ban/tinh', async (req: Request, res: Response) => {
  try {
    const { name, code } = req.body;

    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên tỉnh/thành phố là bắt buộc' });
      return;
    }
    if (name.trim().length > 200) {
      res.status(400).json({ success: false, message: 'Tên tỉnh/thành phố không được vượt quá 200 ký tự' });
      return;
    }
    if (!code?.trim()) {
      res.status(400).json({ success: false, message: 'Mã tỉnh/thành phố là bắt buộc' });
      return;
    }
    if (code.trim().length > 20) {
      res.status(400).json({ success: false, message: 'Mã tỉnh/thành phố không được vượt quá 20 ký tự' });
      return;
    }

    const result = await addressRepository.provinceCreate(name.trim(), code.trim());
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.status(201).json({ success: true, data: { id: result.id } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PUT /dia-ban/tinh/:id
router.put('/dia-ban/tinh/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const { name, code, is_active } = req.body;

    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên tỉnh/thành phố là bắt buộc' });
      return;
    }
    if (name.trim().length > 200) {
      res.status(400).json({ success: false, message: 'Tên tỉnh/thành phố không được vượt quá 200 ký tự' });
      return;
    }
    if (!code?.trim()) {
      res.status(400).json({ success: false, message: 'Mã tỉnh/thành phố là bắt buộc' });
      return;
    }
    if (code.trim().length > 20) {
      res.status(400).json({ success: false, message: 'Mã tỉnh/thành phố không được vượt quá 20 ký tự' });
      return;
    }

    const result = await addressRepository.provinceUpdate(id, name.trim(), code.trim(), is_active ?? true);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { updated: true } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /dia-ban/tinh/:id
router.delete('/dia-ban/tinh/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const result = await addressRepository.provinceDelete(id);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { message: result.message } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// --- District (Quận/Huyện) ---

// GET /dia-ban/huyen
router.get('/dia-ban/huyen', async (req: Request, res: Response) => {
  try {
    const provinceId = req.query.province_id ? Number(req.query.province_id) : 0;
    const keyword = (req.query.keyword as string) || '';
    const data = await addressRepository.districtGetList(provinceId, keyword);
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /dia-ban/huyen
router.post('/dia-ban/huyen', async (req: Request, res: Response) => {
  try {
    const { province_id, name, code } = req.body;

    if (!province_id) {
      res.status(400).json({ success: false, message: 'Tỉnh/thành phố là bắt buộc' });
      return;
    }
    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên quận/huyện là bắt buộc' });
      return;
    }
    if (name.trim().length > 200) {
      res.status(400).json({ success: false, message: 'Tên quận/huyện không được vượt quá 200 ký tự' });
      return;
    }
    if (!code?.trim()) {
      res.status(400).json({ success: false, message: 'Mã quận/huyện là bắt buộc' });
      return;
    }
    if (code.trim().length > 20) {
      res.status(400).json({ success: false, message: 'Mã quận/huyện không được vượt quá 20 ký tự' });
      return;
    }

    const result = await addressRepository.districtCreate(province_id, name.trim(), code.trim());
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.status(201).json({ success: true, data: { id: result.id } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PUT /dia-ban/huyen/:id
router.put('/dia-ban/huyen/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const { name, code, is_active } = req.body;

    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên quận/huyện là bắt buộc' });
      return;
    }
    if (name.trim().length > 200) {
      res.status(400).json({ success: false, message: 'Tên quận/huyện không được vượt quá 200 ký tự' });
      return;
    }
    if (!code?.trim()) {
      res.status(400).json({ success: false, message: 'Mã quận/huyện là bắt buộc' });
      return;
    }
    if (code.trim().length > 20) {
      res.status(400).json({ success: false, message: 'Mã quận/huyện không được vượt quá 20 ký tự' });
      return;
    }

    const result = await addressRepository.districtUpdate(id, name.trim(), code.trim(), is_active ?? true);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { updated: true } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /dia-ban/huyen/:id
router.delete('/dia-ban/huyen/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const result = await addressRepository.districtDelete(id);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { message: result.message } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// --- Commune (Xã/Phường) ---

// GET /dia-ban/xa
router.get('/dia-ban/xa', async (req: Request, res: Response) => {
  try {
    const districtId = req.query.district_id ? Number(req.query.district_id) : 0;
    const keyword = (req.query.keyword as string) || '';
    const data = await addressRepository.communeGetList(districtId, keyword);
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /dia-ban/xa
router.post('/dia-ban/xa', async (req: Request, res: Response) => {
  try {
    const { district_id, name, code } = req.body;

    if (!district_id) {
      res.status(400).json({ success: false, message: 'Quận/huyện là bắt buộc' });
      return;
    }
    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên xã/phường là bắt buộc' });
      return;
    }
    if (name.trim().length > 200) {
      res.status(400).json({ success: false, message: 'Tên xã/phường không được vượt quá 200 ký tự' });
      return;
    }
    if (!code?.trim()) {
      res.status(400).json({ success: false, message: 'Mã xã/phường là bắt buộc' });
      return;
    }
    if (code.trim().length > 20) {
      res.status(400).json({ success: false, message: 'Mã xã/phường không được vượt quá 20 ký tự' });
      return;
    }

    const result = await addressRepository.communeCreate(district_id, name.trim(), code.trim());
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.status(201).json({ success: true, data: { id: result.id } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PUT /dia-ban/xa/:id
router.put('/dia-ban/xa/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const { name, code, is_active } = req.body;

    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên xã/phường là bắt buộc' });
      return;
    }
    if (name.trim().length > 200) {
      res.status(400).json({ success: false, message: 'Tên xã/phường không được vượt quá 200 ký tự' });
      return;
    }
    if (!code?.trim()) {
      res.status(400).json({ success: false, message: 'Mã xã/phường là bắt buộc' });
      return;
    }
    if (code.trim().length > 20) {
      res.status(400).json({ success: false, message: 'Mã xã/phường không được vượt quá 20 ký tự' });
      return;
    }

    const result = await addressRepository.communeUpdate(id, name.trim(), code.trim(), is_active ?? true);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { updated: true } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /dia-ban/xa/:id
router.delete('/dia-ban/xa/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const result = await addressRepository.communeDelete(id);
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
// 2.10 WORK CALENDAR (Lịch làm việc)
// ============================================================

// GET /lich-lam-viec
router.get('/lich-lam-viec', async (req: Request, res: Response) => {
  try {
    const year = req.query.year ? Number(req.query.year) : new Date().getFullYear();
    const data = await workCalendarRepository.get(year);
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /lich-lam-viec
router.post('/lich-lam-viec', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const { date, description } = req.body;

    if (!date) {
      res.status(400).json({ success: false, message: 'Ngày là bắt buộc' });
      return;
    }

    const result = await workCalendarRepository.setHoliday(date, description ?? '', staffId);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.status(201).json({ success: true, data: { updated: true } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /lich-lam-viec
router.delete('/lich-lam-viec', async (req: Request, res: Response) => {
  try {
    const { date } = req.body;

    if (!date) {
      res.status(400).json({ success: false, message: 'Ngày là bắt buộc' });
      return;
    }

    const result = await workCalendarRepository.removeHoliday(date);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { removed: true } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// 2.11 TEMPLATES (Mẫu SMS / Mẫu Email)
// ============================================================

// --- SMS Templates ---

// GET /mau-sms
router.get('/mau-sms', async (req: Request, res: Response) => {
  try {
    const { departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const uId = req.query.unit_id ? Number(req.query.unit_id) : ancestorUnitId;
    const data = await templateRepository.smsGetList(uId);
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /mau-sms
router.post('/mau-sms', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const { unit_id, name, content, description } = req.body;

    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên mẫu SMS là bắt buộc' });
      return;
    }
    if (name.trim().length > 200) {
      res.status(400).json({ success: false, message: 'Tên mẫu SMS không được vượt quá 200 ký tự' });
      return;
    }

    const result = await templateRepository.smsCreate(
      unit_id ?? ancestorUnitId,
      name.trim(),
      content ?? '',
      description ?? '',
      staffId,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.status(201).json({ success: true, data: { id: result.id } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PUT /mau-sms/:id
router.put('/mau-sms/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const { name, content, description, is_active } = req.body;

    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên mẫu SMS là bắt buộc' });
      return;
    }
    if (name.trim().length > 200) {
      res.status(400).json({ success: false, message: 'Tên mẫu SMS không được vượt quá 200 ký tự' });
      return;
    }

    const result = await templateRepository.smsUpdate(
      id,
      name.trim(),
      content ?? '',
      description ?? '',
      is_active ?? true,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { updated: true } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /mau-sms/:id
router.delete('/mau-sms/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const result = await templateRepository.smsDelete(id);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { message: result.message } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// --- Email Templates ---

// GET /mau-email
router.get('/mau-email', async (req: Request, res: Response) => {
  try {
    const { departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const uId = req.query.unit_id ? Number(req.query.unit_id) : ancestorUnitId;
    const data = await templateRepository.emailGetList(uId);
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /mau-email
router.post('/mau-email', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const { unit_id, name, subject, content, description } = req.body;

    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên mẫu email là bắt buộc' });
      return;
    }
    if (name.trim().length > 200) {
      res.status(400).json({ success: false, message: 'Tên mẫu email không được vượt quá 200 ký tự' });
      return;
    }

    const result = await templateRepository.emailCreate(
      unit_id ?? ancestorUnitId,
      name.trim(),
      subject ?? '',
      content ?? '',
      description ?? '',
      staffId,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.status(201).json({ success: true, data: { id: result.id } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PUT /mau-email/:id
router.put('/mau-email/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const { name, subject, content, description, is_active } = req.body;

    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên mẫu email là bắt buộc' });
      return;
    }
    if (name.trim().length > 200) {
      res.status(400).json({ success: false, message: 'Tên mẫu email không được vượt quá 200 ký tự' });
      return;
    }

    const result = await templateRepository.emailUpdate(
      id,
      name.trim(),
      subject ?? '',
      content ?? '',
      description ?? '',
      is_active ?? true,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { updated: true } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /mau-email/:id
router.delete('/mau-email/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const result = await templateRepository.emailDelete(id);
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
// 2.12 CONFIGURATION (Cấu hình)
// ============================================================

// GET /cau-hinh
router.get('/cau-hinh', async (req: Request, res: Response) => {
  try {
    const { departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const uId = req.query.unit_id ? Number(req.query.unit_id) : ancestorUnitId;
    const data = await configRepository.getList(uId);
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PUT /cau-hinh
router.put('/cau-hinh', async (req: Request, res: Response) => {
  try {
    const { departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const { unit_id, key, value, description } = req.body;

    if (!key?.trim()) {
      res.status(400).json({ success: false, message: 'Khóa cấu hình là bắt buộc' });
      return;
    }

    const result = await configRepository.upsert(
      unit_id ?? ancestorUnitId,
      key.trim(),
      value ?? '',
      description ?? '',
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { updated: true } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// DOC COLUMNS — Cấu hình trường form per loại VB
// ============================================================

router.get('/cau-hinh-truong', async (req: Request, res: Response) => {
  try {
    const { type_id } = req.query;
    if (type_id) {
      const rows = await callFunction('edoc.fn_doc_column_get_by_type', [Number(type_id)]);
      res.json({ success: true, data: rows });
    } else {
      const rows = await callFunction('edoc.fn_doc_column_get_all', []);
      res.json({ success: true, data: rows });
    }
  } catch (error) { handleDbError(error, res); }
});

router.post('/cau-hinh-truong', async (req: Request, res: Response) => {
  try {
    const { id, type_id, column_name, label, data_type, max_length, sort_order, is_mandatory, description } = req.body;
    const row = await callFunctionOne('edoc.fn_doc_column_save', [
      id ?? null, type_id ?? null, column_name ?? null, label, data_type ?? 'text',
      max_length ?? null, sort_order ?? 0, is_mandatory ?? false, description ?? null,
    ]);
    const result = row as { success: boolean; message: string; id: number } | null;
    if (!result?.success) { res.status(400).json({ success: false, message: result?.message || 'Lỗi' }); return; }
    res.json({ success: true, data: { id: result.id, message: result.message } });
  } catch (error) { handleDbError(error, res); }
});

router.delete('/cau-hinh-truong/:id', async (req: Request, res: Response) => {
  try {
    const row = await callFunctionOne('edoc.fn_doc_column_delete', [Number(req.params.id)]);
    const result = row as { success: boolean; message: string } | null;
    if (!result?.success) { res.status(400).json({ success: false, message: result?.message || 'Lỗi' }); return; }
    res.json({ success: true, data: { message: result.message } });
  } catch (error) { handleDbError(error, res); }
});

// ============================================================
// 2.12 MẪU THÔNG BÁO — SMS Templates
// ============================================================

// GET /mau-sms
router.get('/mau-sms', async (req: Request, res: Response) => {
  try {
    const { departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const data = await templateRepository.smsGetList(ancestorUnitId);
    res.json({ success: true, data });
  } catch (error) { handleDbError(error, res); }
});

// POST /mau-sms
router.post('/mau-sms', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const { name, content, description } = req.body;
    const result = await templateRepository.smsCreate(ancestorUnitId, name, content, description || '', staffId);
    if (!result.success) { res.status(400).json({ success: false, message: result.message }); return; }
    res.status(201).json({ success: true, data: { id: result.id, message: result.message } });
  } catch (error) { handleDbError(error, res); }
});

// PUT /mau-sms/:id
router.put('/mau-sms/:id', async (req: Request, res: Response) => {
  try {
    const { name, content, description, is_active } = req.body;
    const result = await templateRepository.smsUpdate(Number(req.params.id), name, content, description || '', is_active ?? true);
    if (!result.success) { res.status(400).json({ success: false, message: result.message }); return; }
    res.json({ success: true, data: { message: result.message } });
  } catch (error) { handleDbError(error, res); }
});

// DELETE /mau-sms/:id
router.delete('/mau-sms/:id', async (req: Request, res: Response) => {
  try {
    const result = await templateRepository.smsDelete(Number(req.params.id));
    if (!result.success) { res.status(400).json({ success: false, message: result.message }); return; }
    res.json({ success: true, data: { message: result.message } });
  } catch (error) { handleDbError(error, res); }
});

// ============================================================
// 2.13 MẪU THÔNG BÁO — Email Templates
// ============================================================

// GET /mau-email
router.get('/mau-email', async (req: Request, res: Response) => {
  try {
    const { departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const data = await templateRepository.emailGetList(ancestorUnitId);
    res.json({ success: true, data });
  } catch (error) { handleDbError(error, res); }
});

// POST /mau-email
router.post('/mau-email', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const { name, subject, content, description } = req.body;
    const result = await templateRepository.emailCreate(ancestorUnitId, name, subject || '', content, description || '', staffId);
    if (!result.success) { res.status(400).json({ success: false, message: result.message }); return; }
    res.status(201).json({ success: true, data: { id: result.id, message: result.message } });
  } catch (error) { handleDbError(error, res); }
});

// PUT /mau-email/:id
router.put('/mau-email/:id', async (req: Request, res: Response) => {
  try {
    const { name, subject, content, description, is_active } = req.body;
    const result = await templateRepository.emailUpdate(Number(req.params.id), name, subject || '', content, description || '', is_active ?? true);
    if (!result.success) { res.status(400).json({ success: false, message: result.message }); return; }
    res.json({ success: true, data: { message: result.message } });
  } catch (error) { handleDbError(error, res); }
});

// DELETE /mau-email/:id
router.delete('/mau-email/:id', async (req: Request, res: Response) => {
  try {
    const result = await templateRepository.emailDelete(Number(req.params.id));
    if (!result.success) { res.status(400).json({ success: false, message: result.message }); return; }
    res.json({ success: true, data: { message: result.message } });
  } catch (error) { handleDbError(error, res); }
});

export default router;
