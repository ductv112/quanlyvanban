import { Router, type Request, type Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import type { AuthRequest } from '../middleware/auth.js';
import { upload } from '../middleware/upload.js';
import { contractRepository } from '../repositories/contract.repository.js';
import { uploadFile, deleteFile } from '../lib/minio/client.js';
import { handleDbError } from '../lib/error-handler.js';

const router = Router();

// ============================================================
// LOẠI HỢP ĐỒNG (CONTRACT TYPES)
// ============================================================

// GET /loai — Danh sách loại hợp đồng
router.get('/loai', async (req: Request, res: Response) => {
  try {
    const { unitId } = (req as AuthRequest).user;
    const data = await contractRepository.getContractTypeList(unitId);
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /loai — Tạo loại hợp đồng
router.post('/loai', async (req: Request, res: Response) => {
  try {
    const { staffId, unitId } = (req as AuthRequest).user;
    const b = req.body;

    if (!b.name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên loại hợp đồng là bắt buộc' });
      return;
    }

    const result = await contractRepository.createContractType(
      unitId,
      b.parent_id ?? 0,
      b.code ?? null,
      b.name.trim(),
      b.note ?? null,
      b.sort_order ?? 0,
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

// PUT /loai/:id — Cập nhật loại hợp đồng
router.put('/loai/:id', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const b = req.body;

    if (!b.name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên loại hợp đồng là bắt buộc' });
      return;
    }

    const result = await contractRepository.updateContractType(
      id,
      b.parent_id ?? 0,
      b.code ?? null,
      b.name.trim(),
      b.note ?? null,
      b.sort_order ?? 0,
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

// DELETE /loai/:id — Xóa loại hợp đồng
router.delete('/loai/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const result = await contractRepository.deleteContractType(id);
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
// HỢP ĐỒNG (CONTRACTS)
// ============================================================

// GET / — Danh sách hợp đồng (phân trang)
// T-05-07: filter by unitId from JWT
router.get('/', async (req: Request, res: Response) => {
  try {
    const { unitId } = (req as AuthRequest).user;
    const contractTypeId = req.query.contract_type_id ? Number(req.query.contract_type_id) : null;
    const status = req.query.status !== undefined ? Number(req.query.status) : null;
    const keyword = (req.query.keyword as string) || null;
    const page = Number(req.query.page) || 1;
    const pageSize = Number(req.query.page_size) || 20;

    const rows = await contractRepository.getContractList(unitId, contractTypeId, status, keyword, page, pageSize);
    const total = rows.length > 0 ? Number(rows[0].total_count) : 0;
    res.json({ success: true, data: rows, total, page, page_size: pageSize });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /:id — Chi tiết hợp đồng
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const data = await contractRepository.getContractById(id);
    if (!data) {
      res.status(404).json({ success: false, message: 'Không tìm thấy hợp đồng' });
      return;
    }
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST / — Tạo hợp đồng
router.post('/', async (req: Request, res: Response) => {
  try {
    // T-05-08: created_user_id sourced from JWT staffId, never from request body
    const { staffId, unitId } = (req as AuthRequest).user;
    const b = req.body;

    if (!b.name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên hợp đồng là bắt buộc' });
      return;
    }

    const result = await contractRepository.createContract(
      b.code_index ?? null,
      b.contract_type_id ? Number(b.contract_type_id) : null,
      b.department_id ? Number(b.department_id) : null,
      b.type_of_contract ?? 0,
      b.contact_id ? Number(b.contact_id) : null,
      b.contact_name ?? null,
      unitId,
      b.code ?? null,
      b.sign_date ?? null,
      b.input_date ?? null,
      b.receive_date ?? null,
      b.name.trim(),
      b.signer ?? null,
      b.number ?? null,
      b.ballot ?? null,
      b.marker ?? null,
      b.curator_name ?? null,
      b.currency ?? null,
      b.transporter ?? null,
      b.staff_id ? Number(b.staff_id) : null,
      b.note ?? null,
      b.status ?? 0,
      b.amount ?? null,
      b.payment_amount ?? null,
      staffId, // T-05-08: always from JWT
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

// PUT /:id — Cập nhật hợp đồng
router.put('/:id', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const b = req.body;

    if (!b.name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên hợp đồng là bắt buộc' });
      return;
    }

    const result = await contractRepository.updateContract(
      id,
      b.code_index ?? null,
      b.contract_type_id ? Number(b.contract_type_id) : null,
      b.department_id ? Number(b.department_id) : null,
      b.type_of_contract ?? 0,
      b.contact_id ? Number(b.contact_id) : null,
      b.contact_name ?? null,
      b.code ?? null,
      b.sign_date ?? null,
      b.input_date ?? null,
      b.receive_date ?? null,
      b.name.trim(),
      b.signer ?? null,
      b.number ?? null,
      b.ballot ?? null,
      b.marker ?? null,
      b.curator_name ?? null,
      b.currency ?? null,
      b.transporter ?? null,
      b.staff_id ? Number(b.staff_id) : null,
      b.note ?? null,
      b.status ?? 0,
      b.amount ?? null,
      b.payment_amount ?? null,
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

// DELETE /:id — Xóa hợp đồng (chỉ khi status=0)
router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const result = await contractRepository.deleteContract(id);
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
// ĐÍNH KÈM HỢP ĐỒNG (CONTRACT ATTACHMENTS)
// ============================================================

// GET /:id/dinh-kem — Danh sách đính kèm
router.get('/:id/dinh-kem', async (req: Request, res: Response) => {
  try {
    const contractId = Number(req.params.id);
    const data = await contractRepository.getContractAttachments(contractId);
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /:id/dinh-kem — Upload đính kèm hợp đồng
// T-05-09: Multer 50MB limit per file
router.post('/:id/dinh-kem', upload.single('file'), async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const contractId = Number(req.params.id);

    if (!req.file) {
      res.status(400).json({ success: false, message: 'File đính kèm là bắt buộc' });
      return;
    }

    const originalName = req.file.originalname;
    const fileUuid = uuidv4();
    const objectPath = `hop-dong/${contractId}/${fileUuid}/${originalName}`;

    await uploadFile(objectPath, req.file.buffer, req.file.mimetype);

    const attachment = await contractRepository.addContractAttachment(
      contractId,
      originalName,
      objectPath,
      req.file.size,
      req.file.mimetype,
      staffId, // T-05-08: always from JWT
    );

    res.status(201).json({ success: true, message: 'Tải lên đính kèm thành công', data: { id: attachment.id } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /:id/dinh-kem/:attachmentId — Xóa đính kèm
router.delete('/:id/dinh-kem/:attachmentId', async (req: Request, res: Response) => {
  try {
    const attachmentId = Number(req.params.attachmentId);
    const result = await contractRepository.deleteContractAttachment(attachmentId);

    if (!result.found) {
      res.status(404).json({ success: false, message: 'Không tìm thấy đính kèm' });
      return;
    }

    // Clean up MinIO file
    if (result.file_path) {
      await deleteFile(result.file_path).catch(() => null);
    }

    res.json({ success: true, message: 'Xóa đính kèm thành công' });
  } catch (error) {
    handleDbError(error, res);
  }
});

export default router;
