import { Router, type Request, type Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { archiveRepository } from '../repositories/archive.repository.js';
import { handleDbError } from '../lib/error-handler.js';

const router = Router();

// ============================================================
// KHO LƯU TRỮ (WAREHOUSE)
// ============================================================

// GET /kho — Cây kho lưu trữ
router.get('/kho', async (req: Request, res: Response) => {
  try {
    const { unitId } = (req as AuthRequest).user;
    const data = await archiveRepository.getWarehouseTree(unitId);
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /kho/:id — Chi tiết kho
router.get('/kho/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const data = await archiveRepository.getWarehouseById(id);
    if (!data) {
      res.status(404).json({ success: false, message: 'Không tìm thấy kho lưu trữ' });
      return;
    }
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /kho — Tạo kho
router.post('/kho', async (req: Request, res: Response) => {
  try {
    const { staffId, unitId } = (req as AuthRequest).user;
    const b = req.body;

    if (!b.name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên kho là bắt buộc' });
      return;
    }

    const result = await archiveRepository.createWarehouse(
      unitId,
      b.type_id ?? null,
      b.code ?? null,
      b.name.trim(),
      b.phone_number ?? null,
      b.address ?? null,
      b.status ?? true,
      b.description ?? null,
      b.parent_id ?? 0,
      b.is_unit ?? false,
      b.warehouse_level ?? 0,
      b.limit_child ?? 0,
      b.position ?? null,
      staffId,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.status(201).json({ success: true, message: result.message, data: { id: result.id } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PUT /kho/:id — Cập nhật kho
router.put('/kho/:id', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const b = req.body;

    if (!b.name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên kho là bắt buộc' });
      return;
    }

    const result = await archiveRepository.updateWarehouse(
      id,
      b.type_id ?? null,
      b.code ?? null,
      b.name.trim(),
      b.phone_number ?? null,
      b.address ?? null,
      b.status ?? true,
      b.description ?? null,
      b.parent_id ?? 0,
      b.is_unit ?? false,
      b.warehouse_level ?? 0,
      b.limit_child ?? 0,
      b.position ?? null,
      staffId,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /kho/:id — Xóa kho
router.delete('/kho/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const result = await archiveRepository.deleteWarehouse(id);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// PHÔNG LƯU TRỮ (FOND)
// ============================================================

// GET /phong — Cây phông lưu trữ
router.get('/phong', async (req: Request, res: Response) => {
  try {
    const { unitId } = (req as AuthRequest).user;
    const data = await archiveRepository.getFondTree(unitId);
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /phong/:id — Chi tiết phông
router.get('/phong/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const data = await archiveRepository.getFondById(id);
    if (!data) {
      res.status(404).json({ success: false, message: 'Không tìm thấy phông lưu trữ' });
      return;
    }
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /phong — Tạo phông
router.post('/phong', async (req: Request, res: Response) => {
  try {
    const { staffId, unitId } = (req as AuthRequest).user;
    const b = req.body;

    if (!b.fond_name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên phông là bắt buộc' });
      return;
    }

    const result = await archiveRepository.createFond(
      unitId,
      b.parent_id ?? 0,
      b.fond_code ?? null,
      b.fond_name.trim(),
      b.fond_history ?? null,
      b.archives_time ?? null,
      b.paper_total ?? null,
      b.paper_digital ?? null,
      b.keys_group ?? null,
      b.other_type ?? null,
      b.language ?? null,
      b.lookup_tools ?? null,
      b.coppy_number ?? null,
      b.status ?? 1,
      b.description ?? null,
      b.version ?? null,
      staffId,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.status(201).json({ success: true, message: result.message, data: { id: result.id } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PUT /phong/:id — Cập nhật phông
router.put('/phong/:id', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const b = req.body;

    if (!b.fond_name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên phông là bắt buộc' });
      return;
    }

    const result = await archiveRepository.updateFond(
      id,
      b.parent_id ?? 0,
      b.fond_code ?? null,
      b.fond_name.trim(),
      b.fond_history ?? null,
      b.archives_time ?? null,
      b.paper_total ?? null,
      b.paper_digital ?? null,
      b.keys_group ?? null,
      b.other_type ?? null,
      b.language ?? null,
      b.lookup_tools ?? null,
      b.coppy_number ?? null,
      b.status ?? 1,
      b.description ?? null,
      b.version ?? null,
      staffId,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /phong/:id — Xóa phông
router.delete('/phong/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const result = await archiveRepository.deleteFond(id);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// HỒ SƠ LƯU TRỮ (RECORD)
// ============================================================

// GET /ho-so — Danh sách hồ sơ (phân trang)
// T-05-07: filter by unitId from JWT — no cross-unit access
router.get('/ho-so', async (req: Request, res: Response) => {
  try {
    const { unitId } = (req as AuthRequest).user;
    const fondId = req.query.fond_id ? Number(req.query.fond_id) : null;
    const warehouseId = req.query.warehouse_id ? Number(req.query.warehouse_id) : null;
    const keyword = (req.query.keyword as string) || null;
    const page = Number(req.query.page) || 1;
    const pageSize = Number(req.query.page_size) || 20;

    const rows = await archiveRepository.getRecordList(unitId, fondId, warehouseId, keyword, page, pageSize);
    const total = rows.length > 0 ? Number(rows[0].total_count) : 0;
    res.json({ success: true, data: rows, total, page, page_size: pageSize });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /ho-so/:id — Chi tiết hồ sơ
router.get('/ho-so/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const data = await archiveRepository.getRecordById(id);
    if (!data) {
      res.status(404).json({ success: false, message: 'Không tìm thấy hồ sơ lưu trữ' });
      return;
    }
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /ho-so — Tạo hồ sơ
router.post('/ho-so', async (req: Request, res: Response) => {
  try {
    const { staffId, unitId } = (req as AuthRequest).user;
    const b = req.body;

    if (!b.title?.trim()) {
      res.status(400).json({ success: false, message: 'Tiêu đề hồ sơ là bắt buộc' });
      return;
    }
    if (!b.fond_id) {
      res.status(400).json({ success: false, message: 'Phông lưu trữ là bắt buộc' });
      return;
    }
    if (!b.warehouse_id) {
      res.status(400).json({ success: false, message: 'Kho lưu trữ là bắt buộc' });
      return;
    }

    const result = await archiveRepository.createRecord(
      unitId,
      Number(b.fond_id),
      Number(b.warehouse_id),
      b.file_code ?? null,
      b.file_catalog ?? null,
      b.file_notation ?? null,
      b.title.trim(),
      b.maintenance ?? null,
      b.rights ?? null,
      b.language ?? null,
      b.start_date ?? null,
      b.complete_date ?? null,
      b.total_doc ?? null,
      b.description ?? null,
      b.infor_sign ?? null,
      b.keyword ?? null,
      b.total_paper ?? null,
      b.page_number ?? null,
      b.format ?? 0,
      b.archive_date ?? null,
      b.in_charge_staff_id ?? staffId,
      b.reception_date ?? null,
      b.reception_from ?? 0,
      b.transfer_staff ?? null,
      b.is_document_original ?? null,
      b.number_of_copy ?? null,
      b.doc_field_id ?? null,
      staffId,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.status(201).json({ success: true, message: result.message, data: { id: result.id } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PUT /ho-so/:id — Cập nhật hồ sơ
router.put('/ho-so/:id', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const b = req.body;

    if (!b.title?.trim()) {
      res.status(400).json({ success: false, message: 'Tiêu đề hồ sơ là bắt buộc' });
      return;
    }

    const result = await archiveRepository.updateRecord(
      id,
      Number(b.fond_id),
      Number(b.warehouse_id),
      b.file_code ?? null,
      b.file_catalog ?? null,
      b.file_notation ?? null,
      b.title.trim(),
      b.maintenance ?? null,
      b.rights ?? null,
      b.language ?? null,
      b.start_date ?? null,
      b.complete_date ?? null,
      b.total_doc ?? null,
      b.description ?? null,
      b.infor_sign ?? null,
      b.keyword ?? null,
      b.total_paper ?? null,
      b.page_number ?? null,
      b.format ?? 0,
      b.archive_date ?? null,
      b.in_charge_staff_id ?? staffId,
      b.reception_date ?? null,
      b.reception_from ?? 0,
      b.transfer_staff ?? null,
      b.is_document_original ?? null,
      b.number_of_copy ?? null,
      b.doc_field_id ?? null,
      staffId,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /ho-so/:id — Xóa hồ sơ
router.delete('/ho-so/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const result = await archiveRepository.deleteRecord(id);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// YÊU CẦU MƯỢN/TRẢ (BORROW REQUEST)
// ============================================================

// GET /muon-tra — Danh sách yêu cầu mượn
// T-05-07: filter by unitId from JWT — no cross-unit access
router.get('/muon-tra', async (req: Request, res: Response) => {
  try {
    const { unitId } = (req as AuthRequest).user;
    const status = req.query.status !== undefined ? Number(req.query.status) : null;
    const keyword = (req.query.keyword as string) || null;
    const page = Number(req.query.page) || 1;
    const pageSize = Number(req.query.page_size) || 20;

    const rows = await archiveRepository.getBorrowRequestList(unitId, status, keyword, page, pageSize);
    const total = rows.length > 0 ? Number(rows[0].total_count) : 0;
    res.json({ success: true, data: rows, total, page, page_size: pageSize });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /muon-tra/:id — Chi tiết yêu cầu mượn
router.get('/muon-tra/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const rows = await archiveRepository.getBorrowRequestById(id);
    if (!rows || rows.length === 0) {
      res.status(404).json({ success: false, message: 'Không tìm thấy yêu cầu mượn' });
      return;
    }
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /muon-tra — Tạo yêu cầu mượn
router.post('/muon-tra', async (req: Request, res: Response) => {
  try {
    // T-05-08: created_user_id sourced from JWT staffId, never from request body
    const { staffId, unitId } = (req as AuthRequest).user;
    const b = req.body;

    if (!b.name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên yêu cầu là bắt buộc' });
      return;
    }

    const recordIds: number[] = Array.isArray(b.record_ids) ? b.record_ids.map(Number) : [];

    const result = await archiveRepository.createBorrowRequest(
      b.name.trim(),
      unitId,
      b.emergency ?? null,
      b.notice ?? null,
      b.borrow_date ?? null,
      staffId, // T-05-08: always from JWT
      recordIds,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.status(201).json({ success: true, message: result.message, data: { id: result.id } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PATCH /muon-tra/:id/approve — Duyệt yêu cầu mượn
router.patch('/muon-tra/:id/approve', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const result = await archiveRepository.approveBorrowRequest(id, staffId);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PATCH /muon-tra/:id/reject — Từ chối yêu cầu mượn
router.patch('/muon-tra/:id/reject', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const { notice } = req.body;
    const result = await archiveRepository.rejectBorrowRequest(id, staffId, notice ?? null);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PATCH /muon-tra/:id/checkout — Xác nhận mượn
router.patch('/muon-tra/:id/checkout', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const result = await archiveRepository.checkoutBorrowRequest(id, staffId);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PATCH /muon-tra/:id/return — Xác nhận trả
router.patch('/muon-tra/:id/return', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const result = await archiveRepository.returnBorrowRequest(id, staffId);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

export default router;
