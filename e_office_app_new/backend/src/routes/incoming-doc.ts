import { Router, type Request, type Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { upload } from '../middleware/upload.js';
import { incomingDocRepository } from '../repositories/incoming-doc.repository.js';
import { uploadFile, deleteFile, getFileUrl, streamFileToResponse } from '../lib/minio/client.js';
import { v4 as uuidv4 } from 'uuid';
import { handleDbError } from '../lib/error-handler.js';
import { exportExcel } from '../lib/excel.js';
import { callFunction, callFunctionOne, rawQuery } from '../lib/db/query.js';
import { resolveDeptSubtree, resolveAncestorUnit } from '../lib/department-subtree.js';
import {
  computeIncomingPermissions,
  computeIncomingPermsWithContext,
} from '../lib/permissions/incoming-doc.js';
import { getUserPermissionContext, type DocPermissionContext } from '../lib/permissions/_shared.js';
import dayjs from 'dayjs';

const router = Router();

/** Load doc ownership + compute perms. Dùng rawQuery lean — không cần full getById. */
async function loadDocAndPerms(docId: number, userCtx: DocPermissionContext) {
  const rows = await rawQuery<{ id: number; unit_id: number; created_by: number | null }>(
    `SELECT id, unit_id, created_by FROM edoc.incoming_docs WHERE id = $1`, [docId],
  );
  if (rows.length === 0) return null;
  const doc = rows[0];
  const perms = await computeIncomingPermissions(userCtx, doc);
  return { doc, perms };
}

// ============================================================
// 3.1 LIST + READ TRACKING
// ============================================================

// GET / — Danh sách VB đến (phân trang + filter)
router.get('/', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const {
      doc_book_id, doc_type_id, doc_field_id, urgent_id,
      is_read, approved, from_date, to_date, keyword,
      signer: q_signer, from_number, to_number,
      page, page_size, department_id,
    } = req.query;

    const filterDeptId = department_id ? Number(department_id) : undefined;
    const deptIds = await resolveDeptSubtree(departmentId, isAdmin, filterDeptId);

    const rows = await incomingDocRepository.getList(0, staffId, {
      docBookId: doc_book_id ? Number(doc_book_id) : undefined,
      docTypeId: doc_type_id ? Number(doc_type_id) : undefined,
      docFieldId: doc_field_id ? Number(doc_field_id) : undefined,
      urgentId: urgent_id ? Number(urgent_id) : undefined,
      isRead: is_read !== undefined ? is_read === 'true' : undefined,
      approved: approved !== undefined ? approved === 'true' : undefined,
      fromDate: from_date as string || undefined,
      toDate: to_date as string || undefined,
      keyword: keyword as string || undefined,
      signer: q_signer as string || undefined,
      fromNumber: from_number ? Number(from_number) : undefined,
      toNumber: to_number ? Number(to_number) : undefined,
      page: page ? Number(page) : 1,
      pageSize: page_size ? Number(page_size) : 20,
      deptIds,
    });

    // Enrich rejected_by info
    if (rows.length > 0) {
      const ids = rows.map(r => r.id);
      const rejections = await rawQuery<{ id: number; rejected_by: number | null; rejection_reason: string | null }>(
        `SELECT id, rejected_by, rejection_reason FROM edoc.incoming_docs WHERE id = ANY($1)`, [ids]
      );
      const rejMap = new Map(rejections.map(r => [r.id, r]));
      rows.forEach((r: any) => { const rej = rejMap.get(r.id); r.rejected_by = rej?.rejected_by ?? null; r.rejection_reason = rej?.rejection_reason ?? null; });
    }

    // Enrich permissions per row (batch — 1 query load user ctx, pure compute per row)
    if (rows.length > 0) {
      const userCtx = await getUserPermissionContext({ staffId, departmentId, isAdmin });
      rows.forEach((r: any) => {
        r.permissions = computeIncomingPermsWithContext(userCtx, {
          id: r.id,
          unit_id: r.unit_id,
          created_by: r.created_by ?? null,
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

// GET /chua-doc/count — Đếm chưa đọc (cho badge)
router.get('/chua-doc/count', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const deptIds = await resolveDeptSubtree(departmentId, isAdmin);
    const count = await incomingDocRepository.countUnread(0, staffId, deptIds);
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

// GET /xuat-excel — Xuất danh sách VB đến ra Excel
router.get('/xuat-excel', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const { doc_book_id, doc_type_id, from_date, to_date, keyword } = req.query;
    const deptIds = await resolveDeptSubtree(departmentId, isAdmin);

    const rows = await incomingDocRepository.getList(0, staffId, {
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
    const SECRET: Record<number, string> = { 1: 'Thường', 2: 'Mật', 3: 'Tối mật', 4: 'Tuyệt mật' };

    await exportExcel(res, `VanBanDen_${dayjs().format('YYYYMMDD')}.xlsx`, 'Văn bản đến', [
      { header: 'STT', key: 'stt', width: 6 },
      { header: 'Số đến', key: 'number', width: 10 },
      { header: 'Ngày đến', key: 'received_date', width: 12 },
      { header: 'Số ký hiệu', key: 'notation', width: 18 },
      { header: 'Trích yếu', key: 'abstract', width: 40 },
      { header: 'CQ ban hành', key: 'publish_unit', width: 25 },
      { header: 'Người ký', key: 'signer', width: 18 },
      { header: 'Ngày ban hành', key: 'publish_date', width: 12 },
      { header: 'Loại VB', key: 'doc_type_name', width: 15 },
      { header: 'Lĩnh vực', key: 'doc_field_name', width: 15 },
      { header: 'Sổ VB', key: 'doc_book_name', width: 15 },
      { header: 'Độ khẩn', key: 'urgent', width: 10 },
      { header: 'Độ mật', key: 'secret', width: 10 },
      { header: 'Trạng thái', key: 'status', width: 12 },
    ], rows.map((r, i) => ({
      stt: i + 1,
      number: r.number,
      received_date: fmtDate(r.received_date),
      notation: r.notation || '',
      abstract: r.abstract || '',
      publish_unit: r.publish_unit || '',
      signer: r.signer || '',
      publish_date: fmtDate(r.publish_date),
      doc_type_name: r.doc_type_name || '',
      doc_field_name: r.doc_field_name || '',
      doc_book_name: r.doc_book_name || '',
      urgent: URGENT[r.urgent_id] || '',
      secret: SECRET[r.secret_id] || '',
      status: r.approved ? 'Đã duyệt' : 'Chờ duyệt',
    })));
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /truong-bo-sung — Lấy custom fields theo loại VB
router.get('/truong-bo-sung', async (req: Request, res: Response) => {
  try {
    const { doc_type_id } = req.query;
    if (!doc_type_id) { res.json({ success: true, data: [] }); return; }
    const rows = await callFunction('edoc.fn_doc_column_get_by_type', [Number(doc_type_id)]);
    res.json({ success: true, data: rows });
  } catch (error) { handleDbError(error, res); }
});

// GET /so-den-tiep-theo — Lấy số đến tiếp theo
router.get('/so-den-tiep-theo', async (req: Request, res: Response) => {
  try {
    const { departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const { doc_book_id } = req.query;
    if (!doc_book_id) {
      res.status(400).json({ success: false, message: 'Sổ văn bản là bắt buộc' });
      return;
    }
    const nextNumber = await incomingDocRepository.getNextNumber(Number(doc_book_id), ancestorUnitId);
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

    const result = await incomingDocRepository.create({
      unitId: ancestorUnitId,
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
      sents: body.sents || null,
      isReceivedPaper: body.is_received_paper ?? false,
      createdBy: staffId,
      departmentId, // Phase 20 v3.0 fix: gắn với phòng/đơn vị của user → resolveDeptSubtree filter list match được
    });

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    // Lưu extra_fields nếu có
    if (body.extra_fields && Object.keys(body.extra_fields).length > 0) {
      await callFunctionOne('edoc.fn_doc_save_extra_fields', ['incoming', result.id, JSON.stringify(body.extra_fields)]);
    }
    // Phase 20 v3.0: Lưu sub_number nếu có (SP cũ không nhận param này → UPDATE riêng)
    if (body.sub_number) {
      await rawQuery('UPDATE edoc.incoming_docs SET sub_number = $1 WHERE id = $2', [String(body.sub_number).slice(0, 20), result.id]);
    }
    res.status(201).json({ success: true, data: { id: result.id } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /:id — Chi tiết VB đến
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const doc = await incomingDocRepository.getById(id, staffId);
    if (!doc) {
      res.status(404).json({ success: false, message: 'Không tìm thấy văn bản đến' });
      return;
    }
    // Lấy extra_fields + rejection info + sub_number (Phase 20 v3.0)
    const extraRows = await rawQuery<{ extra_fields: Record<string, unknown>; rejected_by: number | null; rejection_reason: string | null; sub_number: string | null }>(
      'SELECT extra_fields, rejected_by, rejection_reason, sub_number FROM edoc.incoming_docs WHERE id = $1', [id],
    ).catch(() => []);
    // Phase 19 v3.0 fix Bug 8: nếu VB đến là internal (auto-sinh từ outgoing) → fill recipients text từ outgoing recipients (tên các đơn vị nhận trong outgoing gốc)
    let recipientsSummary = (doc as any).recipients;
    if ((doc as any).source_type === 'internal' && (doc as any).previous_outgoing_doc_id) {
      const recipNames = await rawQuery<{ name: string }>(
        `SELECT COALESCE(d.name, o.name) AS name
         FROM edoc.outgoing_doc_recipients r
         LEFT JOIN public.departments d ON r.recipient_unit_id = d.id
         LEFT JOIN edoc.inter_organizations o ON r.recipient_org_id = o.id
         WHERE r.outgoing_doc_id = $1
         ORDER BY r.id`, [(doc as any).previous_outgoing_doc_id]
      );
      if (recipNames.length > 0) {
        recipientsSummary = recipNames.map(r => r.name).filter(Boolean).join('; ');
      }
    }
    // Compute permissions
    const permissions = await computeIncomingPermissions(
      { staffId, departmentId, isAdmin },
      {
        id: (doc as any).id,
        unit_id: (doc as any).unit_id,
        created_by: (doc as any).created_by ?? null,
      },
    );
    res.json({ success: true, data: { ...doc, recipients: recipientsSummary, sub_number: extraRows[0]?.sub_number ?? null, extra_fields: extraRows[0]?.extra_fields || {}, rejected_by: extraRows[0]?.rejected_by ?? null, rejection_reason: extraRows[0]?.rejection_reason ?? null, permissions } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PUT /:id — Cập nhật VB đến
router.put('/:id', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const body = req.body;

    // Permission guard (canEdit) — phải check trước source_type để user không có quyền thấy 403 ngay
    const loaded = await loadDocAndPerms(id, { staffId, departmentId, isAdmin });
    if (!loaded) { res.status(404).json({ success: false, message: 'Không tìm thấy văn bản đến' }); return; }
    if (!loaded.perms.canEdit) { res.status(403).json({ success: false, message: 'Không có quyền sửa văn bản đến này' }); return; }

    // Phase 20 v3.0: chỉ cho sửa VB đến source_type='manual' (do văn thư tự nhập)
    // VB đến internal (auto-sinh từ Sở khác) hoặc external_lgsp KHÔNG được sửa nội dung gốc
    const srcRows = await rawQuery<{ source_type: string }>('SELECT source_type FROM edoc.incoming_docs WHERE id = $1', [id]);
    if (srcRows.length === 0) { res.status(404).json({ success: false, message: 'Không tìm thấy văn bản đến' }); return; }
    if (srcRows[0].source_type !== 'manual') {
      res.status(403).json({ success: false, message: 'Văn bản đến từ ' + (srcRows[0].source_type === 'internal' ? 'đơn vị nội bộ' : 'LGSP') + ' không được sửa nội dung gốc. Chỉ có thể tiếp nhận / phân công xử lý / từ chối.' });
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
      sents: body.sents || null,
      isReceivedPaper: body.is_received_paper ?? false,
      updatedBy: staffId,
    });

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    // Lưu extra_fields nếu có
    if (body.extra_fields !== undefined) {
      await callFunctionOne('edoc.fn_doc_save_extra_fields', ['incoming', id, JSON.stringify(body.extra_fields || {})]);
    }
    // Phase 20 v3.0: Update sub_number (SP cũ không support)
    if (body.sub_number !== undefined) {
      await rawQuery('UPDATE edoc.incoming_docs SET sub_number = $1 WHERE id = $2', [body.sub_number ? String(body.sub_number).slice(0, 20) : null, id]);
    }
    res.json({ success: true, data: { updated: true } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /:id — Xóa VB đến
router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const loaded = await loadDocAndPerms(id, { staffId, departmentId, isAdmin });
    if (!loaded) { res.status(404).json({ success: false, message: 'Không tìm thấy văn bản đến' }); return; }
    if (!loaded.perms.canEdit) { res.status(403).json({ success: false, message: 'Không có quyền xóa văn bản đến này' }); return; }
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

// GET /:id/dinh-kem/:attachmentId/download — Stream file qua backend proxy
router.get('/:id/dinh-kem/:attachmentId/download', async (req: Request, res: Response) => {
  try {
    const attachments = await incomingDocRepository.getAttachments(Number(req.params.id));
    const att = attachments.find(a => Number(a.id) === Number(req.params.attachmentId));
    if (!att) {
      res.status(404).json({ success: false, message: 'Không tìm thấy file' });
      return;
    }
    await streamFileToResponse(res, att.file_path, att.file_name, (att as any).mime_type);
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
    const { staffId, departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const rows = await incomingDocRepository.getSendableStaff(ancestorUnitId, staffId);
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /:id/gui — Gửi VB cho cán bộ
router.post('/:id/gui', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const docId = Number(req.params.id);
    const loaded = await loadDocAndPerms(docId, { staffId, departmentId, isAdmin });
    if (!loaded) { res.status(404).json({ success: false, message: 'Không tìm thấy văn bản đến' }); return; }
    if (!loaded.perms.canSend) { res.status(403).json({ success: false, message: 'Không có quyền gửi văn bản đến này' }); return; }
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

// POST /:id/but-phe — Bút phê (đơn thuần hoặc kết hợp phân công)
router.post('/:id/but-phe', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const docId = Number(req.params.id);
    const { content, expired_date, staff_ids } = req.body;

    if (!content?.trim()) {
      res.status(400).json({ success: false, message: 'Nội dung bút phê là bắt buộc' });
      return;
    }

    // Nếu có staff_ids → dùng combo SP (bút phê + phân công)
    if (Array.isArray(staff_ids) && staff_ids.length > 0) {
      const result = await incomingDocRepository.commentAndAssign(
        docId, staffId, content.trim(), 'incoming',
        expired_date || undefined, staff_ids.map(Number),
      );
      if (!result.success) {
        res.status(400).json({ success: false, message: result.message });
        return;
      }
      res.status(201).json({ success: true, data: { id: result.id, message: result.message } });
    } else {
      const result = await incomingDocRepository.createLeaderNote(docId, staffId, content.trim());
      if (!result.success) {
        res.status(400).json({ success: false, message: result.message });
        return;
      }
      res.status(201).json({ success: true, data: { id: result.id } });
    }
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
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const docId = Number(req.params.id);
    const loaded = await loadDocAndPerms(docId, { staffId, departmentId, isAdmin });
    if (!loaded) { res.status(404).json({ success: false, message: 'Không tìm thấy văn bản đến' }); return; }
    if (!loaded.perms.canRetract) { res.status(403).json({ success: false, message: 'Không có quyền thu hồi văn bản đến này' }); return; }
    const result = await incomingDocRepository.retract(docId, staffId);
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
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const docId = Number(req.params.id);
    const loaded = await loadDocAndPerms(docId, { staffId, departmentId, isAdmin });
    if (!loaded) { res.status(404).json({ success: false, message: 'Không tìm thấy văn bản đến' }); return; }
    if (!loaded.perms.canApprove) { res.status(403).json({ success: false, message: 'Không có quyền duyệt văn bản đến này' }); return; }
    const result = await incomingDocRepository.approve(docId, staffId);
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
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const docId = Number(req.params.id);
    const loaded = await loadDocAndPerms(docId, { staffId, departmentId, isAdmin });
    if (!loaded) { res.status(404).json({ success: false, message: 'Không tìm thấy văn bản đến' }); return; }
    if (!loaded.perms.canApprove) { res.status(403).json({ success: false, message: 'Không có quyền hủy duyệt văn bản đến này' }); return; }
    const result = await incomingDocRepository.unapprove(docId, staffId);
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
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const docId = Number(req.params.id);
    const loaded = await loadDocAndPerms(docId, { staffId, departmentId, isAdmin });
    if (!loaded) { res.status(404).json({ success: false, message: 'Không tìm thấy văn bản đến' }); return; }
    if (!loaded.perms.canApprove) { res.status(403).json({ success: false, message: 'Không có quyền xác nhận nhận bản giấy' }); return; }
    const { received_paper_date } = req.body;
    const result = await incomingDocRepository.receivePaper(docId, staffId, received_paper_date || undefined);
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
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const docId = Number(req.params.id);
    const loaded = await loadDocAndPerms(docId, { staffId, departmentId, isAdmin });
    if (!loaded) { res.status(404).json({ success: false, message: 'Không tìm thấy văn bản đến' }); return; }
    if (!loaded.perms.canApprove) { res.status(403).json({ success: false, message: 'Không có quyền giao xử lý văn bản đến này' }); return; }
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
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const docId = Number(req.params.id);
    const loaded = await loadDocAndPerms(docId, { staffId, departmentId, isAdmin });
    if (!loaded) { res.status(404).json({ success: false, message: 'Không tìm thấy văn bản đến' }); return; }
    if (!loaded.perms.canRetract) { res.status(403).json({ success: false, message: 'Không có quyền chuyển lại văn bản đến này' }); return; }
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

// ============================================================
// LINK TO EXISTING HSCV
// ============================================================

// GET /:id/danh-sach-hscv — DS HSCV sẵn có để link
router.get('/:id/danh-sach-hscv', async (req: Request, res: Response) => {
  try {
    const { departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const { keyword } = req.query;
    const rows = await incomingDocRepository.getHandlingDocsForLink(ancestorUnitId, keyword as string || undefined);
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /:id/them-vao-hscv — Link VB đến vào HSCV sẵn có
router.post('/:id/them-vao-hscv', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const docId = Number(req.params.id);
    const loaded = await loadDocAndPerms(docId, { staffId, departmentId, isAdmin });
    if (!loaded) { res.status(404).json({ success: false, message: 'Không tìm thấy văn bản đến' }); return; }
    if (!loaded.perms.canApprove) { res.status(403).json({ success: false, message: 'Không có quyền thêm vào hồ sơ công việc' }); return; }
    const { handling_doc_id } = req.body;
    if (!handling_doc_id) {
      res.status(400).json({ success: false, message: 'Vui lòng chọn hồ sơ công việc' });
      return;
    }
    const result = await incomingDocRepository.linkToHandlingDoc(Number(handling_doc_id), docId, 'incoming', staffId);
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
// LGSP — Gửi liên thông
// ============================================================

// GET /lgsp/don-vi — DS đơn vị LGSP
router.get('/:id/lgsp/don-vi', async (req: Request, res: Response) => {
  try {
    const { search } = req.query;
    const rows = await incomingDocRepository.getLgspOrganizations(search as string || undefined);
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /:id/gui-lien-thong — Gửi VB đến qua LGSP
router.post('/:id/gui-lien-thong', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const docId = Number(req.params.id);
    const loaded = await loadDocAndPerms(docId, { staffId, departmentId, isAdmin });
    if (!loaded) { res.status(404).json({ success: false, message: 'Không tìm thấy văn bản đến' }); return; }
    if (!loaded.perms.canApprove) { res.status(403).json({ success: false, message: 'Không có quyền gửi liên thông văn bản đến này' }); return; }
    const { org_codes } = req.body;
    if (!Array.isArray(org_codes) || org_codes.length === 0) {
      res.status(400).json({ success: false, message: 'Vui lòng chọn ít nhất một đơn vị' });
      return;
    }
    const results = [];
    for (const org of org_codes as { code: string; name: string }[]) {
      const result = await incomingDocRepository.sendLgsp({
        incomingDocId: docId, direction: 'send',
        destOrgCode: org.code, destOrgName: org.name, createdBy: staffId,
      });
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
    const doc = await incomingDocRepository.getArchive('incoming', Number(req.params.id));
    res.json({ success: true, data: doc });
  } catch (error) { handleDbError(error, res); }
});

router.get('/:id/luu-tru/phong', async (req: Request, res: Response) => {
  try {
    const { departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const fonds = await incomingDocRepository.getFonds(ancestorUnitId);
    res.json({ success: true, data: fonds });
  } catch (error) { handleDbError(error, res); }
});

router.get('/:id/luu-tru/kho', async (req: Request, res: Response) => {
  try {
    const { departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const warehouses = await incomingDocRepository.getWarehouses(ancestorUnitId);
    res.json({ success: true, data: warehouses });
  } catch (error) { handleDbError(error, res); }
});

router.post('/:id/chuyen-luu-tru', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const docId = Number(req.params.id);
    const loaded = await loadDocAndPerms(docId, { staffId, departmentId, isAdmin });
    if (!loaded) { res.status(404).json({ success: false, message: 'Không tìm thấy văn bản đến' }); return; }
    if (!loaded.perms.canApprove) { res.status(403).json({ success: false, message: 'Không có quyền chuyển lưu trữ văn bản này' }); return; }
    const result = await incomingDocRepository.createArchive('incoming', docId, { ...req.body, archived_by: staffId });
    if (!result.success) { res.status(400).json({ success: false, message: result.message }); return; }
    res.json({ success: true, data: { id: result.id, message: result.message } });
  } catch (error) { handleDbError(error, res); }
});

export default router;
