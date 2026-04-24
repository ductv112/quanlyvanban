import { Router, type Request, type Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { upload } from '../middleware/upload.js';
import { draftingDocRepository } from '../repositories/drafting-doc.repository.js';
import { incomingDocRepository } from '../repositories/incoming-doc.repository.js';
import { uploadFile, deleteFile, getFileUrl, streamFileToResponse } from '../lib/minio/client.js';
import { v4 as uuidv4 } from 'uuid';
import { handleDbError } from '../lib/error-handler.js';
import { exportExcel } from '../lib/excel.js';
import { callFunction, rawQuery } from '../lib/db/query.js';
import { resolveDeptSubtree, resolveAncestorUnit } from '../lib/department-subtree.js';
import { computeDraftingPermissions, computePermsWithContext, getUserPermissionContext, type DocPermissionContext } from '../lib/permissions/drafting-doc.js';
import dayjs from 'dayjs';

/**
 * Load doc + compute permissions. Trả null nếu doc không tồn tại.
 * Dùng cho 7 mutation endpoint.
 */
async function loadDocAndPerms(
  docId: number,
  userCtx: DocPermissionContext,
) {
  const doc = await draftingDocRepository.getById(docId, userCtx.staffId);
  if (!doc) return null;
  const perms = await computeDraftingPermissions(userCtx, {
    id: doc.id,
    drafting_user_id: doc.drafting_user_id ?? null,
    unit_id: doc.unit_id,
  });
  return { doc, perms };
}

const router = Router();

// ============================================================
// LIST + READ TRACKING
// ============================================================

// GET / — Danh sách VB dự thảo (phân trang + filter)
router.get('/', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const {
      doc_book_id, doc_type_id, doc_field_id, urgent_id,
      is_released, approved, from_date, to_date, keyword,
      page, page_size, department_id,
    } = req.query;

    const filterDeptId = department_id ? Number(department_id) : undefined;
    const deptIds = await resolveDeptSubtree(departmentId, isAdmin, filterDeptId);

    const rows = await draftingDocRepository.getList(0, staffId, {
      docBookId: doc_book_id ? Number(doc_book_id) : undefined,
      docTypeId: doc_type_id ? Number(doc_type_id) : undefined,
      docFieldId: doc_field_id ? Number(doc_field_id) : undefined,
      urgentId: urgent_id ? Number(urgent_id) : undefined,
      isReleased: is_released !== undefined ? is_released === 'true' : undefined,
      approved: approved !== undefined ? approved === 'true' : undefined,
      fromDate: from_date as string || undefined,
      toDate: to_date as string || undefined,
      keyword: keyword as string || undefined,
      page: page ? Number(page) : 1,
      pageSize: page_size ? Number(page_size) : 20,
      deptIds,
    });

    // Enrich rejected_by info
    if (rows.length > 0) {
      const ids = rows.map(r => r.id);
      const rejections = await rawQuery<{ id: number; rejected_by: number | null; rejection_reason: string | null }>(
        `SELECT id, rejected_by, rejection_reason FROM edoc.drafting_docs WHERE id = ANY($1)`, [ids]
      );
      const rejMap = new Map(rejections.map(r => [r.id, r]));
      rows.forEach((r: any) => { const rej = rejMap.get(r.id); r.rejected_by = rej?.rejected_by ?? null; r.rejection_reason = rej?.rejection_reason ?? null; });
    }

    // Enrich permissions per row (batch — 1 query load user ctx, pure compute per row)
    if (rows.length > 0) {
      const userCtx = await getUserPermissionContext({ staffId, departmentId, isAdmin });
      rows.forEach((r: any) => {
        r.permissions = computePermsWithContext(userCtx, {
          id: r.id,
          drafting_user_id: r.drafting_user_id ?? null,
          unit_id: r.unit_id,
        });
      });
    }

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

// GET /chua-doc/count
router.get('/chua-doc/count', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const deptIds = await resolveDeptSubtree(departmentId, isAdmin);
    const count = await draftingDocRepository.countUnread(0, staffId, deptIds);
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
    const result = await draftingDocRepository.markReadBulk(doc_ids.map(Number), staffId);
    res.json({ success: true, data: result });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /danh-dau-ca-nhan — DS VB đánh dấu cá nhân
router.get('/danh-dau-ca-nhan', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const rows = await draftingDocRepository.getBookmarks(staffId);
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /xuat-excel — Xuất danh sách VB dự thảo ra Excel
router.get('/xuat-excel', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const { doc_book_id, doc_type_id, from_date, to_date, keyword } = req.query;
    const deptIds = await resolveDeptSubtree(departmentId, isAdmin);

    const rows = await draftingDocRepository.getList(0, staffId, {
      docBookId: doc_book_id ? Number(doc_book_id) : undefined,
      docTypeId: doc_type_id ? Number(doc_type_id) : undefined,
      fromDate: from_date as string || undefined,
      toDate: to_date as string || undefined,
      keyword: keyword as string || undefined,
      page: 1, pageSize: 10000,
      deptIds,
    });

    const fmtDate = (d: string) => d ? dayjs(d).format('DD/MM/YYYY') : '';

    await exportExcel(res, `VanBanDuThao_${dayjs().format('YYYYMMDD')}.xlsx`, 'Văn bản dự thảo', [
      { header: 'STT', key: 'stt', width: 6 },
      { header: 'Số', key: 'number', width: 8 },
      { header: 'Ký hiệu', key: 'notation', width: 18 },
      { header: 'Trích yếu', key: 'abstract', width: 40 },
      { header: 'Đơn vị soạn', key: 'drafting_unit_name', width: 20 },
      { header: 'Người soạn', key: 'drafting_user_name', width: 18 },
      { header: 'Người ký', key: 'signer', width: 18 },
      { header: 'Loại VB', key: 'doc_type_name', width: 15 },
      { header: 'Sổ VB', key: 'doc_book_name', width: 15 },
      { header: 'Nơi nhận', key: 'recipients', width: 25 },
      { header: 'Trạng thái', key: 'status', width: 15 },
    ], rows.map((r, i) => ({
      stt: i + 1,
      number: r.number,
      notation: r.notation || '',
      abstract: r.abstract || '',
      drafting_unit_name: r.drafting_unit_name || '',
      drafting_user_name: r.drafting_user_name || '',
      signer: r.signer || '',
      doc_type_name: r.doc_type_name || '',
      doc_book_name: r.doc_book_name || '',
      recipients: r.recipients || '',
      status: r.is_released ? 'Đã phát hành' : r.approved ? 'Đã duyệt' : 'Dự thảo',
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

// GET /so-tiep-theo — Lấy số tiếp theo
router.get('/so-tiep-theo', async (req: Request, res: Response) => {
  try {
    const { departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const { doc_book_id } = req.query;
    if (!doc_book_id) {
      res.status(400).json({ success: false, message: 'Sổ văn bản là bắt buộc' });
      return;
    }
    const nextNumber = await draftingDocRepository.getNextNumber(Number(doc_book_id), ancestorUnitId);
    res.json({ success: true, data: { number: nextNumber } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// CRUD
// ============================================================

// POST / — Tạo VB dự thảo
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

    const result = await draftingDocRepository.create({
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

// GET /:id — Chi tiết
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const doc = await draftingDocRepository.getById(id, staffId);
    if (!doc) {
      res.status(404).json({ success: false, message: 'Không tìm thấy văn bản dự thảo' });
      return;
    }
    const rej = await rawQuery<{ rejected_by: number | null; rejection_reason: string | null }>(
      `SELECT rejected_by, rejection_reason FROM edoc.drafting_docs WHERE id = $1`, [id]
    );
    if (rej[0]) { (doc as any).rejected_by = rej[0].rejected_by; (doc as any).rejection_reason = rej[0].rejection_reason; }

    // Compute permissions và gắn vào response
    const permissions = await computeDraftingPermissions(
      { staffId, departmentId, isAdmin },
      { id: doc.id, drafting_user_id: doc.drafting_user_id ?? null, unit_id: doc.unit_id },
    );
    (doc as any).permissions = permissions;

    res.json({ success: true, data: doc });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PUT /:id — Cập nhật
router.put('/:id', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const body = req.body;

    // Permission guard
    const loaded = await loadDocAndPerms(id, { staffId, departmentId, isAdmin });
    if (!loaded) {
      res.status(404).json({ success: false, message: 'Không tìm thấy văn bản dự thảo' });
      return;
    }
    if (!loaded.perms.canEdit) {
      res.status(403).json({ success: false, message: 'Không có quyền sửa văn bản này' });
      return;
    }

    if (!body.abstract?.trim()) {
      res.status(400).json({ success: false, message: 'Trích yếu nội dung là bắt buộc' });
      return;
    }
    if (!body.doc_book_id) {
      res.status(400).json({ success: false, message: 'Sổ văn bản là bắt buộc' });
      return;
    }

    const result = await draftingDocRepository.update(id, {
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

// DELETE /:id
router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const id = Number(req.params.id);

    // Permission guard
    const loaded = await loadDocAndPerms(id, { staffId, departmentId, isAdmin });
    if (!loaded) {
      res.status(404).json({ success: false, message: 'Không tìm thấy văn bản dự thảo' });
      return;
    }
    if (!loaded.perms.canEdit) {
      res.status(403).json({ success: false, message: 'Không có quyền xóa văn bản này' });
      return;
    }

    const result = await draftingDocRepository.delete(id);
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
    const rows = await draftingDocRepository.getRecipients(Number(req.params.id));
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

router.get('/:id/lich-su', async (req: Request, res: Response) => {
  try {
    const rows = await draftingDocRepository.getHistory(Number(req.params.id));
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
    const rows = await draftingDocRepository.getAttachments(Number(req.params.id));
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
    const minioPath = `drafting/${docId}/${uuidv4()}.${ext}`;
    await uploadFile(minioPath, file.buffer, file.mimetype);

    const result = await draftingDocRepository.createAttachment(
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
    const result = await draftingDocRepository.deleteAttachment(Number(req.params.attachmentId));
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
    const attachments = await draftingDocRepository.getAttachments(Number(req.params.id));
    const att = attachments.find(a => Number(a.id) === Number(req.params.attachmentId));
    if (!att) {
      res.status(404).json({ success: false, message: 'Không tìm thấy file' });
      return;
    }
    // Stream file qua backend proxy — MinIO nội bộ, browser không truy cập trực tiếp
    await streamFileToResponse(res, att.file_path, att.file_name, (att as any).mime_type);
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// SEND / DISTRIBUTE
// ============================================================

router.get('/:id/danh-sach-gui', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const rows = await draftingDocRepository.getSendableStaff(ancestorUnitId, staffId);
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

router.post('/:id/gui', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const docId = Number(req.params.id);

    // Permission guard
    const loaded = await loadDocAndPerms(docId, { staffId, departmentId, isAdmin });
    if (!loaded) {
      res.status(404).json({ success: false, message: 'Không tìm thấy văn bản dự thảo' });
      return;
    }
    if (!loaded.perms.canSend) {
      res.status(403).json({ success: false, message: 'Không có quyền gửi văn bản này' });
      return;
    }

    const { staff_ids } = req.body;

    if (!Array.isArray(staff_ids) || staff_ids.length === 0) {
      res.status(400).json({ success: false, message: 'Vui lòng chọn ít nhất một người nhận' });
      return;
    }

    const { expired_date } = req.body;
    const result = await draftingDocRepository.send(docId, staff_ids.map(Number), staffId, expired_date || undefined);
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

    const result = await draftingDocRepository.toggleBookmark(docId, staffId, note);
    res.json({ success: true, data: { is_bookmarked: result.is_bookmarked, message: result.message } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// APPROVE / UNAPPROVE / REJECT / RELEASE
// ============================================================

router.patch('/:id/duyet', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const docId = Number(req.params.id);

    // Permission guard
    const loaded = await loadDocAndPerms(docId, { staffId, departmentId, isAdmin });
    if (!loaded) {
      res.status(404).json({ success: false, message: 'Không tìm thấy văn bản dự thảo' });
      return;
    }
    if (!loaded.perms.canApprove) {
      res.status(403).json({ success: false, message: 'Không có quyền duyệt văn bản này' });
      return;
    }

    // Phase 17 v3.0: lấy fullName từ DB staff (JWT không có fullName)
    const staffRows = await rawQuery<{ full_name: string }>('SELECT full_name FROM public.staff WHERE id = $1', [staffId]);
    const approverName = staffRows[0]?.full_name || `Staff #${staffId}`;
    const result = await draftingDocRepository.approve(docId, staffId, approverName);
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
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const docId = Number(req.params.id);

    // Permission guard
    const loaded = await loadDocAndPerms(docId, { staffId, departmentId, isAdmin });
    if (!loaded) {
      res.status(404).json({ success: false, message: 'Không tìm thấy văn bản dự thảo' });
      return;
    }
    if (!loaded.perms.canApprove) {
      res.status(403).json({ success: false, message: 'Không có quyền hủy duyệt văn bản này' });
      return;
    }

    const result = await draftingDocRepository.unapprove(docId, staffId);
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
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const docId = Number(req.params.id);

    // Permission guard
    const loaded = await loadDocAndPerms(docId, { staffId, departmentId, isAdmin });
    if (!loaded) {
      res.status(404).json({ success: false, message: 'Không tìm thấy văn bản dự thảo' });
      return;
    }
    if (!loaded.perms.canApprove) {
      res.status(403).json({ success: false, message: 'Không có quyền từ chối văn bản này' });
      return;
    }

    const { reason } = req.body;
    const result = await draftingDocRepository.reject(docId, staffId, reason);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { message: result.message } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /:id/thu-hoi — Thu hồi VB dự thảo (xóa người nhận, reset duyệt)
router.post('/:id/thu-hoi', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const docId = Number(req.params.id);

    // Permission guard
    const loaded = await loadDocAndPerms(docId, { staffId, departmentId, isAdmin });
    if (!loaded) {
      res.status(404).json({ success: false, message: 'Không tìm thấy văn bản dự thảo' });
      return;
    }
    if (!loaded.perms.canRetract) {
      res.status(403).json({ success: false, message: 'Không có quyền thu hồi văn bản này' });
      return;
    }

    const { staff_ids } = req.body ?? {};
    const result = await draftingDocRepository.retract(
      docId, staffId,
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

// POST /:id/phat-hanh — Phát hành → tạo VB đi
router.post('/:id/phat-hanh', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const docId = Number(req.params.id);

    // Permission guard
    const loaded = await loadDocAndPerms(docId, { staffId, departmentId, isAdmin });
    if (!loaded) {
      res.status(404).json({ success: false, message: 'Không tìm thấy văn bản dự thảo' });
      return;
    }
    if (!loaded.perms.canRelease) {
      res.status(403).json({ success: false, message: 'Không có quyền phát hành văn bản này' });
      return;
    }

    const result = await draftingDocRepository.release(docId, staffId);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({
      success: true,
      data: {
        message: result.message,
        outgoing_doc_id: result.outgoing_doc_id,
      },
    });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// LEADER NOTES (Ý kiến lãnh đạo)
// ============================================================

router.get('/:id/y-kien', async (req: Request, res: Response) => {
  try {
    const rows = await draftingDocRepository.getLeaderNotes(Number(req.params.id));
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
      const result = await incomingDocRepository.commentAndAssign(docId, staffId, content.trim(), 'drafting', expired_date || undefined, staff_ids.map(Number));
      if (!result.success) { res.status(400).json({ success: false, message: result.message }); return; }
      res.status(201).json({ success: true, data: { id: result.id, message: result.message } });
    } else {
      const result = await draftingDocRepository.createLeaderNote(docId, staffId, content.trim());
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
    const result = await draftingDocRepository.deleteLeaderNote(Number(req.params.noteId), staffId);
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
