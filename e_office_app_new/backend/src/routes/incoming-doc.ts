import { Router, type Request, type Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { upload } from '../middleware/upload.js';
import { incomingDocRepository } from '../repositories/incoming-doc.repository.js';
import { uploadFile, deleteFile, getFileUrl } from '../lib/minio/client.js';
import { v4 as uuidv4 } from 'uuid';
import { handleDbError } from '../lib/error-handler.js';

const router = Router();

// ============================================================
// 3.1 LIST + READ TRACKING
// ============================================================

// GET / — Danh sách VB đến (phân trang + filter)
router.get('/', async (req: Request, res: Response) => {
  try {
    const { staffId, unitId } = (req as AuthRequest).user;
    const {
      doc_book_id, doc_type_id, doc_field_id, urgent_id,
      is_read, approved, from_date, to_date, keyword,
      page, page_size,
    } = req.query;

    const rows = await incomingDocRepository.getList(unitId, staffId, {
      docBookId: doc_book_id ? Number(doc_book_id) : undefined,
      docTypeId: doc_type_id ? Number(doc_type_id) : undefined,
      docFieldId: doc_field_id ? Number(doc_field_id) : undefined,
      urgentId: urgent_id ? Number(urgent_id) : undefined,
      isRead: is_read !== undefined ? is_read === 'true' : undefined,
      approved: approved !== undefined ? approved === 'true' : undefined,
      fromDate: from_date as string || undefined,
      toDate: to_date as string || undefined,
      keyword: keyword as string || undefined,
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

// GET /chua-doc/count — Đếm chưa đọc (cho badge)
router.get('/chua-doc/count', async (req: Request, res: Response) => {
  try {
    const { staffId, unitId } = (req as AuthRequest).user;
    const count = await incomingDocRepository.countUnread(unitId, staffId);
    res.json({ success: true, data: { count } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PATCH /danh-dau-da-doc — Đánh dấu đã đọc hàng loạt
router.patch('/danh-dau-da-doc', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const { doc_ids } = req.body;
    if (!Array.isArray(doc_ids) || doc_ids.length === 0) {
      res.status(400).json({ success: false, message: 'Danh sách văn bản không hợp lệ' });
      return;
    }
    const result = await incomingDocRepository.markReadBulk(doc_ids.map(Number), staffId);
    res.json({ success: true, data: result });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /danh-dau-ca-nhan — DS VB đánh dấu cá nhân
router.get('/danh-dau-ca-nhan', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const rows = await incomingDocRepository.getBookmarks(staffId, 'incoming');
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /so-den-tiep-theo — Lấy số đến tiếp theo
router.get('/so-den-tiep-theo', async (req: Request, res: Response) => {
  try {
    const { unitId } = (req as AuthRequest).user;
    const { doc_book_id } = req.query;
    if (!doc_book_id) {
      res.status(400).json({ success: false, message: 'Sổ văn bản là bắt buộc' });
      return;
    }
    const nextNumber = await incomingDocRepository.getNextNumber(Number(doc_book_id), unitId);
    res.json({ success: true, data: { number: nextNumber } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// 3.2 CRUD
// ============================================================

// POST / — Tạo VB đến
router.post('/', async (req: Request, res: Response) => {
  try {
    const { staffId, unitId } = (req as AuthRequest).user;
    const body = req.body;

    if (!body.abstract?.trim()) {
      res.status(400).json({ success: false, message: 'Trích yếu nội dung là bắt buộc' });
      return;
    }
    if (!body.doc_book_id) {
      res.status(400).json({ success: false, message: 'Sổ văn bản là bắt buộc' });
      return;
    }

    const result = await incomingDocRepository.create({
      unitId,
      receivedDate: body.received_date || null,
      number: body.number ? Number(body.number) : undefined,
      notation: body.notation || null,
      documentCode: body.document_code || null,
      abstract: body.abstract.trim(),
      publishUnit: body.publish_unit || null,
      publishDate: body.publish_date || null,
      signer: body.signer || null,
      signDate: body.sign_date || null,
      docBookId: Number(body.doc_book_id),
      docTypeId: body.doc_type_id ? Number(body.doc_type_id) : undefined,
      docFieldId: body.doc_field_id ? Number(body.doc_field_id) : undefined,
      secretId: body.secret_id ? Number(body.secret_id) : 1,
      urgentId: body.urgent_id ? Number(body.urgent_id) : 1,
      numberPaper: body.number_paper ? Number(body.number_paper) : 1,
      numberCopies: body.number_copies ? Number(body.number_copies) : 1,
      expiredDate: body.expired_date || null,
      recipients: body.recipients || null,
      isReceivedPaper: body.is_received_paper ?? false,
      createdBy: staffId,
    });

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.status(201).json({ success: true, data: { id: result.id } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /:id — Chi tiết VB đến
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const doc = await incomingDocRepository.getById(id, staffId);
    if (!doc) {
      res.status(404).json({ success: false, message: 'Không tìm thấy văn bản đến' });
      return;
    }
    res.json({ success: true, data: doc });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PUT /:id — Cập nhật VB đến
router.put('/:id', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const body = req.body;

    if (!body.abstract?.trim()) {
      res.status(400).json({ success: false, message: 'Trích yếu nội dung là bắt buộc' });
      return;
    }
    if (!body.doc_book_id) {
      res.status(400).json({ success: false, message: 'Sổ văn bản là bắt buộc' });
      return;
    }

    const result = await incomingDocRepository.update(id, {
      receivedDate: body.received_date || null,
      number: body.number ? Number(body.number) : undefined,
      notation: body.notation || null,
      documentCode: body.document_code || null,
      abstract: body.abstract.trim(),
      publishUnit: body.publish_unit || null,
      publishDate: body.publish_date || null,
      signer: body.signer || null,
      signDate: body.sign_date || null,
      docBookId: Number(body.doc_book_id),
      docTypeId: body.doc_type_id ? Number(body.doc_type_id) : undefined,
      docFieldId: body.doc_field_id ? Number(body.doc_field_id) : undefined,
      secretId: body.secret_id ? Number(body.secret_id) : 1,
      urgentId: body.urgent_id ? Number(body.urgent_id) : 1,
      numberPaper: body.number_paper ? Number(body.number_paper) : 1,
      numberCopies: body.number_copies ? Number(body.number_copies) : 1,
      expiredDate: body.expired_date || null,
      recipients: body.recipients || null,
      isReceivedPaper: body.is_received_paper ?? false,
      updatedBy: staffId,
    });

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { updated: true } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /:id — Xóa VB đến
router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const result = await incomingDocRepository.delete(id);
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
// 3.3 DETAIL — Recipients + History
// ============================================================

// GET /:id/nguoi-nhan
router.get('/:id/nguoi-nhan', async (req: Request, res: Response) => {
  try {
    const rows = await incomingDocRepository.getRecipients(Number(req.params.id));
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /:id/lich-su
router.get('/:id/lich-su', async (req: Request, res: Response) => {
  try {
    const rows = await incomingDocRepository.getHistory(Number(req.params.id));
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// 3.4 ATTACHMENTS
// ============================================================

// GET /:id/dinh-kem
router.get('/:id/dinh-kem', async (req: Request, res: Response) => {
  try {
    const rows = await incomingDocRepository.getAttachments(Number(req.params.id));
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /:id/dinh-kem — Upload file
router.post('/:id/dinh-kem', upload.single('file'), async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const docId = Number(req.params.id);
    const file = req.file;

    if (!file) {
      res.status(400).json({ success: false, message: 'Vui lòng chọn file' });
      return;
    }

    // Upload to MinIO
    const ext = file.originalname.split('.').pop() || '';
    const minioPath = `incoming/${docId}/${uuidv4()}.${ext}`;
    await uploadFile(minioPath, file.buffer, file.mimetype);

    // Save to DB
    const result = await incomingDocRepository.createAttachment(
      docId, file.originalname, minioPath, file.size, file.mimetype, staffId,
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

// DELETE /:id/dinh-kem/:attachmentId
router.delete('/:id/dinh-kem/:attachmentId', async (req: Request, res: Response) => {
  try {
    const result = await incomingDocRepository.deleteAttachment(Number(req.params.attachmentId));
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    // Delete from MinIO (best-effort)
    if (result.file_path) {
      try { await deleteFile(result.file_path); } catch { /* ignore MinIO errors */ }
    }
    res.json({ success: true, data: { message: result.message } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /:id/dinh-kem/:attachmentId/download — Presigned URL
router.get('/:id/dinh-kem/:attachmentId/download', async (req: Request, res: Response) => {
  try {
    const attachments = await incomingDocRepository.getAttachments(Number(req.params.id));
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

// ============================================================
// 3.5 SEND / DISTRIBUTE
// ============================================================

// GET /:id/danh-sach-gui — DS cán bộ có thể gửi
router.get('/:id/danh-sach-gui', async (req: Request, res: Response) => {
  try {
    const { unitId } = (req as AuthRequest).user;
    const rows = await incomingDocRepository.getSendableStaff(unitId);
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /:id/gui — Gửi VB cho cán bộ
router.post('/:id/gui', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const docId = Number(req.params.id);
    const { staff_ids } = req.body;

    if (!Array.isArray(staff_ids) || staff_ids.length === 0) {
      res.status(400).json({ success: false, message: 'Vui lòng chọn ít nhất một người nhận' });
      return;
    }

    const result = await incomingDocRepository.send(docId, staff_ids.map(Number), staffId);
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
// 3.6 LEADER NOTES
// ============================================================

// GET /:id/but-phe
router.get('/:id/but-phe', async (req: Request, res: Response) => {
  try {
    const rows = await incomingDocRepository.getLeaderNotes(Number(req.params.id));
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /:id/but-phe
router.post('/:id/but-phe', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const docId = Number(req.params.id);
    const { content } = req.body;

    if (!content?.trim()) {
      res.status(400).json({ success: false, message: 'Nội dung bút phê là bắt buộc' });
      return;
    }

    const result = await incomingDocRepository.createLeaderNote(docId, staffId, content.trim());
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.status(201).json({ success: true, data: { id: result.id } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /:id/but-phe/:noteId
router.delete('/:id/but-phe/:noteId', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const result = await incomingDocRepository.deleteLeaderNote(Number(req.params.noteId), staffId);
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
// 3.7 BOOKMARKS
// ============================================================

// POST /:id/danh-dau — Toggle bookmark
router.post('/:id/danh-dau', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const docId = Number(req.params.id);
    const { note } = req.body;

    const result = await incomingDocRepository.toggleBookmark('incoming', docId, staffId, note);
    res.json({ success: true, data: { is_bookmarked: result.is_bookmarked, message: result.message } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// 3.8 RETRACT (Thu hồi)
// ============================================================

// POST /:id/thu-hoi — Thu hồi VB đến (xóa người nhận, reset duyệt)
router.post('/:id/thu-hoi', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const result = await incomingDocRepository.retract(Number(req.params.id), staffId);
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
// 3.9 APPROVE / UNAPPROVE / RECEIVE PAPER
// ============================================================

// PATCH /:id/duyet
router.patch('/:id/duyet', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const result = await incomingDocRepository.approve(Number(req.params.id), staffId);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { message: result.message } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PATCH /:id/huy-duyet
router.patch('/:id/huy-duyet', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const result = await incomingDocRepository.unapprove(Number(req.params.id), staffId);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { message: result.message } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PATCH /:id/nhan-ban-giay
router.patch('/:id/nhan-ban-giay', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const result = await incomingDocRepository.receivePaper(Number(req.params.id), staffId);
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
// 3.x VB DEN ACTIONS — Giao viec, Nhan ban giao, Chuyen lai, Huy duyet
// ============================================================

// POST /:id/giao-viec — Tao ho so cong viec tu VB den
router.post('/:id/giao-viec', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const docId = Number(req.params.id);
    const { name, start_date, end_date, curator_ids, note } = req.body;

    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên hồ sơ công việc là bắt buộc' });
      return;
    }
    if (!Array.isArray(curator_ids) || curator_ids.length === 0) {
      res.status(400).json({ success: false, message: 'Vui lòng chọn ít nhất một người thực hiện' });
      return;
    }

    const result = await incomingDocRepository.createHandlingDocFromDoc(
      docId, 'incoming', name.trim(),
      start_date ?? null, end_date ?? null,
      curator_ids.map(Number), note ?? null,
      staffId,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.status(201).json({ success: true, data: result, message: 'Giao việc thành công' });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /:id/nhan-ban-giao — Nhan ban giao VB den
router.post('/:id/nhan-ban-giao', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const docId = Number(req.params.id);

    const result = await incomingDocRepository.handover(docId, staffId);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, message: 'Nhận bàn giao thành công' });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /:id/chuyen-lai — Chuyen lai VB den (yeu cau ly do)
router.post('/:id/chuyen-lai', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const docId = Number(req.params.id);
    const { reason } = req.body;

    if (!reason?.trim()) {
      res.status(400).json({ success: false, message: 'Lý do chuyển lại là bắt buộc' });
      return;
    }
    if (reason.trim().length < 10) {
      res.status(400).json({ success: false, message: 'Lý do chuyển lại phải có ít nhất 10 ký tự' });
      return;
    }

    const result = await incomingDocRepository.returnDoc(docId, staffId, reason.trim());
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, message: 'Chuyển lại văn bản thành công' });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /:id/huy-duyet — Huy duyet VB den
router.post('/:id/huy-duyet', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const docId = Number(req.params.id);

    const result = await incomingDocRepository.cancelApprove(docId, staffId);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, message: 'Đã hủy duyệt văn bản' });
  } catch (error) {
    handleDbError(error, res);
  }
});

export default router;
