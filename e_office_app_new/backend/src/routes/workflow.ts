import { Router } from 'express';
import type { Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { workflowRepository } from '../repositories/workflow.repository.js';
import { handleDbError } from '../lib/error-handler.js';
import { resolveAncestorUnit } from '../lib/department-subtree.js';

const router = Router();

// ============================================================
// QUY TRÌNH (Workflow / Doc Flow)
// ============================================================

// GET / — Danh sách quy trình
router.get('/', async (req: AuthRequest, res: Response) => {
  try {
    const ancestorUnitId = await resolveAncestorUnit(req.user!.departmentId);
    const docFieldId = req.query.doc_field_id ? Number(req.query.doc_field_id) : null;
    const isActive = req.query.is_active !== undefined
      ? req.query.is_active === 'true'
      : null;

    const rows = await workflowRepository.getList(ancestorUnitId, docFieldId, isActive);
    res.json({ success: true, data: rows });
  } catch (err) {
    handleDbError(err, res);
  }
});

// POST / — Tạo quy trình mới
router.post('/', async (req: AuthRequest, res: Response) => {
  try {
    const ancestorUnitId = await resolveAncestorUnit(req.user!.departmentId);
    const staffId = req.user!.staffId;
    const { name, version, doc_field_id } = req.body;

    if (!name || String(name).trim() === '') {
      res.status(400).json({ success: false, message: 'Tên quy trình không được để trống' });
      return;
    }

    const result = await workflowRepository.create(
      ancestorUnitId,
      String(name),
      version ? String(version) : null,
      doc_field_id ? Number(doc_field_id) : null,
      staffId,
    );

    if (!result?.success) {
      res.status(400).json({ success: false, message: result?.message || 'Tạo quy trình thất bại' });
      return;
    }

    res.status(201).json({ success: true, message: result.message, id: result.id });
  } catch (err) {
    handleDbError(err, res);
  }
});

// GET /:id — Chi tiết quy trình
router.get('/:id', async (req: AuthRequest, res: Response) => {
  try {
    const id = Number(req.params.id);
    const flow = await workflowRepository.getById(id);

    if (!flow) {
      res.status(404).json({ success: false, message: 'Quy trình không tồn tại' });
      return;
    }

    const steps = await workflowRepository.getSteps(id);
    res.json({ success: true, data: { flow, steps } });
  } catch (err) {
    handleDbError(err, res);
  }
});

// PUT /:id — Cập nhật quy trình
router.put('/:id', async (req: AuthRequest, res: Response) => {
  try {
    const id = Number(req.params.id);
    const { name, version, doc_field_id, is_active } = req.body;

    if (!name || String(name).trim() === '') {
      res.status(400).json({ success: false, message: 'Tên quy trình không được để trống' });
      return;
    }

    const result = await workflowRepository.update(
      id,
      String(name),
      version ? String(version) : null,
      doc_field_id ? Number(doc_field_id) : null,
      is_active !== undefined ? Boolean(is_active) : null,
    );

    if (!result?.success) {
      res.status(400).json({ success: false, message: result?.message || 'Cập nhật quy trình thất bại' });
      return;
    }

    res.json({ success: true, message: result.message });
  } catch (err) {
    handleDbError(err, res);
  }
});

// DELETE /:id — Xóa quy trình
router.delete('/:id', async (req: AuthRequest, res: Response) => {
  try {
    const id = Number(req.params.id);
    const result = await workflowRepository.delete(id);

    if (!result?.success) {
      res.status(400).json({ success: false, message: result?.message || 'Xóa quy trình thất bại' });
      return;
    }

    res.json({ success: true, message: result.message });
  } catch (err) {
    handleDbError(err, res);
  }
});

// GET /:id/full — Toàn bộ quy trình (designer): flow + steps + links
router.get('/:id/full', async (req: AuthRequest, res: Response) => {
  try {
    const id = Number(req.params.id);
    const flow = await workflowRepository.getById(id);

    if (!flow) {
      res.status(404).json({ success: false, message: 'Quy trình không tồn tại' });
      return;
    }

    const steps = await workflowRepository.getSteps(id);
    const stepIds = steps.map(s => s.id);
    const links = await workflowRepository.getStepLinks(stepIds);

    res.json({ success: true, data: { flow, steps, links } });
  } catch (err) {
    handleDbError(err, res);
  }
});

// ============================================================
// BƯỚC QUY TRÌNH (Steps)
// ============================================================

// POST /:id/steps — Tạo bước mới
router.post('/:id/steps', async (req: AuthRequest, res: Response) => {
  try {
    const flowId = Number(req.params.id);
    const {
      step_name, step_order, step_type,
      allow_sign, deadline_days, position_x, position_y,
    } = req.body;

    if (!step_name || String(step_name).trim() === '') {
      res.status(400).json({ success: false, message: 'Tên bước không được để trống' });
      return;
    }

    const result = await workflowRepository.createStep(
      flowId,
      String(step_name),
      Number(step_order ?? 0),
      String(step_type ?? 'process'),
      Boolean(allow_sign ?? false),
      Number(deadline_days ?? 0),
      Number(position_x ?? 0),
      Number(position_y ?? 0),
    );

    if (!result?.success) {
      res.status(400).json({ success: false, message: result?.message || 'Tạo bước thất bại' });
      return;
    }

    res.status(201).json({ success: true, message: result.message, id: result.id });
  } catch (err) {
    handleDbError(err, res);
  }
});

// PUT /steps/:stepId — Cập nhật bước
router.put('/steps/:stepId', async (req: AuthRequest, res: Response) => {
  try {
    const stepId = Number(req.params.stepId);
    const {
      step_name, step_order, step_type,
      allow_sign, deadline_days, position_x, position_y,
    } = req.body;

    if (!step_name || String(step_name).trim() === '') {
      res.status(400).json({ success: false, message: 'Tên bước không được để trống' });
      return;
    }

    const result = await workflowRepository.updateStep(
      stepId,
      String(step_name),
      Number(step_order ?? 0),
      String(step_type ?? 'process'),
      Boolean(allow_sign ?? false),
      Number(deadline_days ?? 0),
      Number(position_x ?? 0),
      Number(position_y ?? 0),
    );

    if (!result?.success) {
      res.status(400).json({ success: false, message: result?.message || 'Cập nhật bước thất bại' });
      return;
    }

    res.json({ success: true, message: result.message });
  } catch (err) {
    handleDbError(err, res);
  }
});

// DELETE /steps/:stepId — Xóa bước
router.delete('/steps/:stepId', async (req: AuthRequest, res: Response) => {
  try {
    const stepId = Number(req.params.stepId);
    const result = await workflowRepository.deleteStep(stepId);

    if (!result?.success) {
      res.status(400).json({ success: false, message: result?.message || 'Xóa bước thất bại' });
      return;
    }

    res.json({ success: true, message: result.message });
  } catch (err) {
    handleDbError(err, res);
  }
});

// ============================================================
// LIÊN KẾT BƯỚC (Step Links)
// ============================================================

// POST /step-links — Tạo liên kết giữa các bước
router.post('/step-links', async (req: AuthRequest, res: Response) => {
  try {
    const { from_step_id, to_step_id } = req.body;

    if (!from_step_id || !to_step_id) {
      res.status(400).json({ success: false, message: 'from_step_id và to_step_id là bắt buộc' });
      return;
    }

    const result = await workflowRepository.createStepLink(
      Number(from_step_id),
      Number(to_step_id),
    );

    if (!result?.success) {
      res.status(400).json({ success: false, message: result?.message || 'Tạo liên kết thất bại' });
      return;
    }

    res.status(201).json({ success: true, message: result.message, id: result.id });
  } catch (err) {
    handleDbError(err, res);
  }
});

// DELETE /step-links/:linkId — Xóa liên kết
router.delete('/step-links/:linkId', async (req: AuthRequest, res: Response) => {
  try {
    const linkId = Number(req.params.linkId);
    const result = await workflowRepository.deleteStepLink(linkId);

    if (!result?.success) {
      res.status(400).json({ success: false, message: result?.message || 'Xóa liên kết thất bại' });
      return;
    }

    res.json({ success: true, message: result.message });
  } catch (err) {
    handleDbError(err, res);
  }
});

// ============================================================
// CÁN BỘ THỰC HIỆN BƯỚC (Step Staff)
// ============================================================

// GET /steps/:stepId/staff — Danh sách cán bộ thực hiện bước
router.get('/steps/:stepId/staff', async (req: AuthRequest, res: Response) => {
  try {
    const stepId = Number(req.params.stepId);
    const rows = await workflowRepository.getStepStaff(stepId);
    res.json({ success: true, data: rows });
  } catch (err) {
    handleDbError(err, res);
  }
});

// POST /steps/:stepId/staff — Gán cán bộ cho bước (thay thế toàn bộ)
router.post('/steps/:stepId/staff', async (req: AuthRequest, res: Response) => {
  try {
    const stepId = Number(req.params.stepId);
    const { staff_ids } = req.body;

    if (!Array.isArray(staff_ids)) {
      res.status(400).json({ success: false, message: 'staff_ids phải là mảng số nguyên' });
      return;
    }

    const result = await workflowRepository.assignStepStaff(stepId, staff_ids.map(Number));

    if (!result?.success) {
      res.status(400).json({ success: false, message: result?.message || 'Gán cán bộ thất bại' });
      return;
    }

    res.json({ success: true, message: result.message });
  } catch (err) {
    handleDbError(err, res);
  }
});

export default router;
