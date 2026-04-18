import { Router, type Request, type Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { upload } from '../middleware/upload.js';
import { interIncomingRepository } from '../repositories/inter-incoming.repository.js';
import { uploadFile, deleteFile, getFileUrl } from '../lib/minio/client.js';
import { v4 as uuidv4 } from 'uuid';
import { handleDbError } from '../lib/error-handler.js';
import { resolveAncestorUnit } from '../lib/department-subtree.js';

const router = Router();

// ============================================================
// Van ban lien thong (inter-incoming docs)
// ============================================================

// GET / — Danh sach VB lien thong (phan trang + filter)
router.get('/', async (req: Request, res: Response) => {
  try {
    const { departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const { keyword, status, from_date, to_date, doc_type_id, page, page_size } = req.query;

    const rows = await interIncomingRepository.getList(ancestorUnitId, {
      keyword: keyword as string || undefined,
      status: status as string || undefined,
      fromDate: from_date as string || undefined,
      toDate: to_date as string || undefined,
      docTypeId: doc_type_id ? Number(doc_type_id) : undefined,
      page: page ? Number(page) : 1,
      pageSize: page_size ? Number(page_size) : 20,
    });

    const total = rows[0]?.total_count ?? 0;
    res.json({
      success: true,
      data: rows,
      pagination: {
        total: Number(total),
        page: page ? Number(page) : 1,
        pageSize: page_size ? Number(page_size) : 20,
      },
    });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /:id — Chi tiet VB lien thong
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const doc = await interIncomingRepository.getById(id);
    if (!doc) {
      res.status(404).json({ success: false, message: 'Không tìm thấy văn bản liên thông' });
      return;
    }
    res.json({ success: true, data: doc });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /:id/nhan-ban-giao — Nhận bàn giao (pending → received)
router.post('/:id/nhan-ban-giao', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const result = await interIncomingRepository.receive(id, staffId);
    if (!result || !result.success) {
      res.status(400).json({ success: false, message: result?.message || 'Thao tác thất bại' });
      return;
    }
    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /:id/chuyen-lai — Từ chối / Chuyển lại (pending → returned)
router.post('/:id/chuyen-lai', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const { reason } = req.body;
    const result = await interIncomingRepository.returnDoc(id, staffId, reason);
    if (!result || !result.success) {
      res.status(400).json({ success: false, message: result?.message || 'Thao tác thất bại' });
      return;
    }
    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /:id/hoan-thanh — Hoàn thành (received → completed)
router.post('/:id/hoan-thanh', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const result = await interIncomingRepository.complete(id, staffId);
    if (!result || !result.success) {
      res.status(400).json({ success: false, message: result?.message || 'Thao tác thất bại' });
      return;
    }
    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// HDSD 2.3 — Recall flow (Đồng ý / Từ chối thu hồi)
// ============================================================

// POST /:id/dong-y-thu-hoi — Đồng ý thu hồi (recall_requested → recalled + soft-delete incoming_docs liên kết)
router.post('/:id/dong-y-thu-hoi', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    if (!Number.isInteger(id) || id <= 0) {
      res.status(400).json({ success: false, message: 'ID không hợp lệ' });
      return;
    }
    const result = await interIncomingRepository.recallApprove(id, staffId);
    if (!result || !result.success) {
      res.status(400).json({ success: false, message: result?.message || 'Thao tác thất bại' });
      return;
    }
    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /:id/tu-choi-thu-hoi — Từ chối thu hồi (restore status_before_recall, fallback 'received')
router.post('/:id/tu-choi-thu-hoi', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const reason = String(req.body?.reason || '').trim();
    if (!Number.isInteger(id) || id <= 0) {
      res.status(400).json({ success: false, message: 'ID không hợp lệ' });
      return;
    }
    if (!reason) {
      res.status(400).json({ success: false, message: 'Vui lòng nhập lý do từ chối thu hồi' });
      return;
    }
    const result = await interIncomingRepository.recallReject(id, staffId, reason);
    if (!result || !result.success) {
      res.status(400).json({ success: false, message: result?.message || 'Thao tác thất bại' });
      return;
    }
    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// ATTACHMENTS — File đính kèm VB liên thông
// ============================================================

router.get('/:id/dinh-kem', async (req: Request, res: Response) => {
  try {
    const rows = await interIncomingRepository.getAttachments(Number(req.params.id));
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

router.post('/:id/dinh-kem', upload.single('file'), async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const docId = Number(req.params.id);
    const file = req.file;

    if (!file) {
      res.status(400).json({ success: false, message: 'Vui lòng chọn file' });
      return;
    }

    const ext = file.originalname.split('.').pop() || '';
    const minioPath = `inter-incoming/${docId}/${uuidv4()}.${ext}`;
    await uploadFile(minioPath, file.buffer, file.mimetype);

    const { description } = req.body;
    const result = await interIncomingRepository.createAttachment(
      docId, file.originalname, minioPath, file.size, file.mimetype, description || null, staffId,
    );

    if (!result || !result.success) {
      res.status(400).json({ success: false, message: result?.message || 'Lỗi tải lên' });
      return;
    }
    res.status(201).json({ success: true, data: { id: result.id } });
  } catch (error) {
    handleDbError(error, res);
  }
});

router.delete('/:id/dinh-kem/:attachmentId', async (req: Request, res: Response) => {
  try {
    const result = await interIncomingRepository.deleteAttachment(Number(req.params.attachmentId));
    if (!result || !result.success) {
      res.status(400).json({ success: false, message: result?.message || 'Lỗi xóa file' });
      return;
    }
    if (result.file_path) {
      try { await deleteFile(result.file_path); } catch { /* ignore */ }
    }
    res.json({ success: true, data: { message: result.message } });
  } catch (error) {
    handleDbError(error, res);
  }
});

router.get('/:id/dinh-kem/:attachmentId/download', async (req: Request, res: Response) => {
  try {
    const attachments = await interIncomingRepository.getAttachments(Number(req.params.id));
    const att = attachments.find(a => a.id === Number(req.params.attachmentId));
    if (!att) {
      res.status(404).json({ success: false, message: 'Không tìm thấy file' });
      return;
    }
    const url = await getFileUrl(att.file_path, 3600);
    res.json({ success: true, data: { url, file_name: att.file_name } });
  } catch (error) {
    handleDbError(error, res);
  }
});

export default router;
