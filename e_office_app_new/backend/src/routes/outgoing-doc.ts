import { Router, type Request, type Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { upload } from '../middleware/upload.js';
import { outgoingDocRepository } from '../repositories/outgoing-doc.repository.js';
import { incomingDocRepository } from '../repositories/incoming-doc.repository.js';
import { uploadFile, deleteFile, getFileUrl } from '../lib/minio/client.js';
import { v4 as uuidv4 } from 'uuid';
import { handleDbError } from '../lib/error-handler.js';
import { exportExcel } from '../lib/excel.js';
import { callFunction } from '../lib/db/query.js';
import { resolveDeptSubtree, resolveAncestorUnit } from '../lib/department-subtree.js';
import dayjs from 'dayjs';

const router = Router();

// ============================================================
// LIST + READ TRACKING
// ============================================================

router.get('/', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const {
      doc_book_id, doc_type_id, doc_field_id, urgent_id,
      approved, from_date, to_date, keyword,
      page, page_size, department_id,
    } = req.query;

    const filterDeptId = department_id ? Number(department_id) : undefined;
    const deptIds = await resolveDeptSubtree(departmentId, isAdmin, filterDeptId);

    const rows = await outgoingDocRepository.getList(0, staffId, {
      docBookId: doc_book_id ? Number(doc_book_id) : undefined,
      docTypeId: doc_type_id ? Number(doc_type_id) : undefined,
      docFieldId: doc_field_id ? Number(doc_field_id) : undefined,
      urgentId: urgent_id ? Number(urgent_id) : undefined,
      approved: approved !== undefined ? approved === 'true' : undefined,
      fromDate: from_date as string || undefined,
      toDate: to_date as string || undefined,
      keyword: keyword as string || undefined,
      page: page ? Number(page) : 1,
      pageSize: page_size ? Number(page_size) : 20,
      deptIds,
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

router.get('/chua-doc/count', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const deptIds = await resolveDeptSubtree(departmentId, isAdmin);
    const count = await outgoingDocRepository.countUnread(0, staffId, deptIds);
    res.json({ success: true, data: { count } });
  } catch (error) {
    handleDbError(error, res);
  }
});

router.patch('/danh-dau-da-doc', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const { doc_ids } = req.body;
    if (!Array.isArray(doc_ids) || doc_ids.length === 0) {
      res.status(400).json({ success: false, message: 'Danh sách văn bản không hợp lệ' });
      return;
    }
    const result = await outgoingDocRepository.markReadBulk(doc_ids.map(Number), staffId);
    res.json({ success: true, data: result });
  } catch (error) {
    handleDbError(error, res);
  }
});

router.get('/danh-dau-ca-nhan', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const rows = await outgoingDocRepository.getBookmarks(staffId);
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /xuat-excel — Xuất danh sách VB đi ra Excel
router.get('/xuat-excel', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const { doc_book_id, doc_type_id, from_date, to_date, keyword } = req.query;
    const deptIds = await resolveDeptSubtree(departmentId, isAdmin);

    const rows = await outgoingDocRepository.getList(0, staffId, {
      docBookId: doc_book_id ? Number(doc_book_id) : undefined,
      docTypeId: doc_type_id ? Number(doc_type_id) : undefined,
      fromDate: from_date as string || undefined,
      toDate: to_date as string || undefined,
      keyword: keyword as string || undefined,
      page: 1, pageSize: 10000,
      deptIds,
    });

    const fmtDate = (d: string) => d ? dayjs(d).format('DD/MM/YYYY') : '';
    const URGENT: Record<number, string> = { 1: 'Thường', 2: 'Khẩn', 3: 'Hỏa tốc' };

    await exportExcel(res, `VanBanDi_${dayjs().format('YYYYMMDD')}.xlsx`, 'Văn bản đi', [
      { header: 'STT', key: 'stt', width: 6 },
      { header: 'Số', key: 'number', width: 8 },
      { header: 'Ngày', key: 'received_date', width: 12 },
      { header: 'Số ký hiệu', key: 'notation', width: 18 },
      { header: 'Trích yếu', key: 'abstract', width: 40 },
      { header: 'Đơn vị soạn', key: 'drafting_unit_name', width: 20 },
      { header: 'Người soạn', key: 'drafting_user_name', width: 18 },
      { header: 'Người ký', key: 'signer', width: 18 },
      { header: 'Ngày ký', key: 'sign_date', width: 12 },
      { header: 'Loại VB', key: 'doc_type_name', width: 15 },
      { header: 'Sổ VB', key: 'doc_book_name', width: 15 },
      { header: 'Nơi nhận', key: 'recipients', width: 25 },
      { header: 'Độ khẩn', key: 'urgent', width: 10 },
      { header: 'Trạng thái', key: 'status', width: 12 },
    ], rows.map((r, i) => ({
      stt: i + 1,
      number: r.number,
      received_date: fmtDate(r.received_date),
      notation: r.notation || '',
      abstract: r.abstract || '',
      drafting_unit_name: r.drafting_unit_name || '',
      drafting_user_name: r.drafting_user_name || '',
      signer: r.signer || '',
      sign_date: fmtDate(r.sign_date),
      doc_type_name: r.doc_type_name || '',
      doc_book_name: r.doc_book_name || '',
      recipients: r.recipients || '',
      urgent: URGENT[r.urgent_id] || '',
      status: r.approved ? 'Đã duyệt' : 'Chờ duyệt',
    })));
  } catch (error) {
    handleDbError(error, res);
  }
});

router.get('/truong-bo-sung', async (req: Request, res: Response) => {
  try {
    const { doc_type_id } = req.query;
    if (!doc_type_id) { res.json({ success: true, data: [] }); return; }
    const rows = await callFunction('edoc.fn_doc_column_get_by_type', [Number(doc_type_id)]);
    res.json({ success: true, data: rows });
  } catch (error) { handleDbError(error, res); }
});

router.get('/so-tiep-theo', async (req: Request, res: Response) => {
  try {
    const { departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const { doc_book_id } = req.query;
    if (!doc_book_id) {
      res.status(400).json({ success: false, message: 'Sổ văn bản là bắt buộc' });
      return;
    }
    const nextNumber = await outgoingDocRepository.getNextNumber(Number(doc_book_id), ancestorUnitId);
    res.json({ success: true, data: { number: nextNumber } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// UNUSED NUMBERS (Số chưa phát hành) — MUST be before /:id
// ============================================================

router.get('/so-chua-phat-hanh', async (req: Request, res: Response) => {
  try {
    const { departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const { doc_book_id } = req.query;
    if (!doc_book_id) {
      res.status(400).json({ success: false, message: 'Sổ văn bản là bắt buộc' });
      return;
    }
    const rows = await outgoingDocRepository.getUnusedNumbers(ancestorUnitId, Number(doc_book_id));
    res.json({ success: true, data: rows.map(r => r.unused_number) });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// CRUD
// ============================================================

router.post('/', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const body = req.body;

    if (!body.abstract?.trim()) {
      res.status(400).json({ success: false, message: 'Trích yếu nội dung là bắt buộc' });
      return;
    }
    if (!body.doc_book_id) {
      res.status(400).json({ success: false, message: 'Sổ văn bản là bắt buộc' });
      return;
    }

    const result = await outgoingDocRepository.create({
      unitId: ancestorUnitId,
      receivedDate: body.received_date || null,
      number: body.number ? Number(body.number) : undefined,
      subNumber: body.sub_number || null,
      notation: body.notation || null,
      documentCode: body.document_code || null,
      abstract: body.abstract.trim(),
      draftingUnitId: body.drafting_unit_id ? Number(body.drafting_unit_id) : undefined,
      draftingUserId: body.drafting_user_id ? Number(body.drafting_user_id) : undefined,
      publishUnitId: body.publish_unit_id ? Number(body.publish_unit_id) : undefined,
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

router.get('/:id', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const doc = await outgoingDocRepository.getById(id, staffId);
    if (!doc) {
      res.status(404).json({ success: false, message: 'Không tìm thấy văn bản đi' });
      return;
    }
    res.json({ success: true, data: doc });
  } catch (error) {
    handleDbError(error, res);
  }
});

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

    const result = await outgoingDocRepository.update(id, {
      receivedDate: body.received_date || null,
      number: body.number ? Number(body.number) : undefined,
      subNumber: body.sub_number || null,
      notation: body.notation || null,
      documentCode: body.document_code || null,
      abstract: body.abstract.trim(),
      draftingUnitId: body.drafting_unit_id ? Number(body.drafting_unit_id) : undefined,
      draftingUserId: body.drafting_user_id ? Number(body.drafting_user_id) : undefined,
      publishUnitId: body.publish_unit_id ? Number(body.publish_unit_id) : undefined,
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

router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const result = await outgoingDocRepository.delete(id);
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
// DETAIL — Recipients + History
// ============================================================

router.get('/:id/nguoi-nhan', async (req: Request, res: Response) => {
  try {
    const rows = await outgoingDocRepository.getRecipients(Number(req.params.id));
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

router.get('/:id/lich-su', async (req: Request, res: Response) => {
  try {
    const rows = await outgoingDocRepository.getHistory(Number(req.params.id));
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// ATTACHMENTS
// ============================================================

router.get('/:id/dinh-kem', async (req: Request, res: Response) => {
  try {
    const rows = await outgoingDocRepository.getAttachments(Number(req.params.id));
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
    const minioPath = `outgoing/${docId}/${uuidv4()}.${ext}`;
    await uploadFile(minioPath, file.buffer, file.mimetype);

    const result = await outgoingDocRepository.createAttachment(
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

router.delete('/:id/dinh-kem/:attachmentId', async (req: Request, res: Response) => {
  try {
    const result = await outgoingDocRepository.deleteAttachment(Number(req.params.attachmentId));
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
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
    const attachments = await outgoingDocRepository.getAttachments(Number(req.params.id));
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
// SEND / DISTRIBUTE
// ============================================================

router.get('/:id/danh-sach-gui', async (req: Request, res: Response) => {
  try {
    const { departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const rows = await outgoingDocRepository.getSendableStaff(ancestorUnitId);
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

router.post('/:id/gui', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const docId = Number(req.params.id);
    const { staff_ids } = req.body;

    if (!Array.isArray(staff_ids) || staff_ids.length === 0) {
      res.status(400).json({ success: false, message: 'Vui lòng chọn ít nhất một người nhận' });
      return;
    }

    const { expired_date } = req.body;
    const result = await outgoingDocRepository.send(docId, staff_ids.map(Number), staffId, expired_date || undefined);
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
// BOOKMARKS
// ============================================================

router.post('/:id/danh-dau', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const docId = Number(req.params.id);
    const { note } = req.body;

    const result = await outgoingDocRepository.toggleBookmark(docId, staffId, note);
    res.json({ success: true, data: { is_bookmarked: result.is_bookmarked, message: result.message } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// APPROVE / UNAPPROVE
// ============================================================

router.patch('/:id/duyet', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const result = await outgoingDocRepository.approve(Number(req.params.id), staffId);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { message: result.message } });
  } catch (error) {
    handleDbError(error, res);
  }
});

router.patch('/:id/huy-duyet', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const result = await outgoingDocRepository.unapprove(Number(req.params.id), staffId);
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
// RETRACT / REJECT
// ============================================================

router.post('/:id/thu-hoi', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const { staff_ids } = req.body;
    const result = await outgoingDocRepository.retract(
      Number(req.params.id), staffId,
      Array.isArray(staff_ids) && staff_ids.length > 0 ? staff_ids.map(Number) : undefined,
    );
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { message: result.message } });
  } catch (error) {
    handleDbError(error, res);
  }
});

router.patch('/:id/tu-choi', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const { reason } = req.body;
    const result = await outgoingDocRepository.reject(Number(req.params.id), staffId, reason);
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
// CHECK NUMBER
// ============================================================

router.get('/:id/kiem-tra-so', async (req: Request, res: Response) => {
  try {
    const { departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const { doc_book_id, number } = req.query;
    if (!doc_book_id || !number) {
      res.status(400).json({ success: false, message: 'Thiếu tham số' });
      return;
    }
    const exists = await outgoingDocRepository.checkNumber(
      ancestorUnitId, Number(doc_book_id), Number(number), Number(req.params.id) || undefined,
    );
    res.json({ success: true, data: { exists } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// LEADER NOTES (Ý kiến lãnh đạo)
// ============================================================

router.get('/:id/y-kien', async (req: Request, res: Response) => {
  try {
    const rows = await outgoingDocRepository.getLeaderNotes(Number(req.params.id));
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

router.post('/:id/y-kien', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const docId = Number(req.params.id);
    const { content, expired_date, staff_ids } = req.body;
    if (!content?.trim()) {
      res.status(400).json({ success: false, message: 'Nội dung ý kiến là bắt buộc' });
      return;
    }
    if (Array.isArray(staff_ids) && staff_ids.length > 0) {
      const result = await incomingDocRepository.commentAndAssign(docId, staffId, content.trim(), 'outgoing', expired_date || undefined, staff_ids.map(Number));
      if (!result.success) { res.status(400).json({ success: false, message: result.message }); return; }
      res.status(201).json({ success: true, data: { id: result.id, message: result.message } });
    } else {
      const result = await outgoingDocRepository.createLeaderNote(docId, staffId, content.trim());
      if (!result.success) { res.status(400).json({ success: false, message: result.message }); return; }
      res.status(201).json({ success: true, data: { id: result.id } });
    }
  } catch (error) {
    handleDbError(error, res);
  }
});

router.delete('/:id/y-kien/:noteId', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const result = await outgoingDocRepository.deleteLeaderNote(Number(req.params.noteId), staffId);
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
// GIAO VIỆC (tạo HSCV từ VB đi)
// ============================================================

router.post('/:id/giao-viec', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const docId = Number(req.params.id);
    const { name, start_date, end_date, curator_ids, note } = req.body;

    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên hồ sơ công việc là bắt buộc' });
      return;
    }

    const result = await outgoingDocRepository.createHandlingDocFromDoc(
      docId, 'outgoing', name.trim(),
      start_date || null, end_date || null,
      curator_ids || [], note || null, staffId,
    );
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.status(201).json({ success: true, data: { id: result.id, message: result.message } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// LINK TO EXISTING HSCV
// ============================================================

router.get('/:id/danh-sach-hscv', async (req: Request, res: Response) => {
  try {
    const { departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const { keyword } = req.query;
    const hscvRows = await incomingDocRepository.getHandlingDocsForLink(ancestorUnitId, keyword as string || undefined);
    res.json({ success: true, data: hscvRows });
  } catch (error) {
    handleDbError(error, res);
  }
});

router.post('/:id/them-vao-hscv', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const docId = Number(req.params.id);
    const { handling_doc_id } = req.body;
    if (!handling_doc_id) {
      res.status(400).json({ success: false, message: 'Vui lòng chọn hồ sơ công việc' });
      return;
    }
    const result = await outgoingDocRepository.linkToHandlingDoc(Number(handling_doc_id), docId, staffId);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { id: result.id, message: result.message } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// LGSP — Gửi liên thông VB đi
// ============================================================

router.post('/:id/gui-lien-thong', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const docId = Number(req.params.id);
    const { org_codes } = req.body;
    if (!Array.isArray(org_codes) || org_codes.length === 0) {
      res.status(400).json({ success: false, message: 'Vui lòng chọn ít nhất một đơn vị' });
      return;
    }
    const results = [];
    for (const org of org_codes as { code: string; name: string }[]) {
      const result = await outgoingDocRepository.sendLgsp(docId, org.code, org.name, staffId);
      results.push(result);
    }
    const successCount = results.filter(r => r.success).length;
    res.json({ success: true, data: { message: `Đã gửi liên thông cho ${successCount} đơn vị` } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// CHUYỂN LƯU TRỮ
// ============================================================

router.get('/:id/luu-tru', async (req: Request, res: Response) => {
  try {
    const doc = await incomingDocRepository.getArchive('outgoing', Number(req.params.id));
    res.json({ success: true, data: doc });
  } catch (error) { handleDbError(error, res); }
});

router.post('/:id/chuyen-luu-tru', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const docId = Number(req.params.id);
    const result = await incomingDocRepository.createArchive('outgoing', docId, { ...req.body, archived_by: staffId });
    if (!result.success) { res.status(400).json({ success: false, message: result.message }); return; }
    res.json({ success: true, data: { id: result.id, message: result.message } });
  } catch (error) { handleDbError(error, res); }
});

export default router;
