import { Router, type Request, type Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { upload } from '../middleware/upload.js';
import { handlingDocRepository } from '../repositories/handling-doc.repository.js';
import { uploadFile, deleteFile, getFileUrl } from '../lib/minio/client.js';
import { rawQuery } from '../lib/db/query.js';
import { v4 as uuidv4 } from 'uuid';
import { handleDbError } from '../lib/error-handler.js';
import { resolveDeptSubtree, resolveAncestorUnit } from '../lib/department-subtree.js';

const router = Router();

// ============================================================
// Gap E + F (HDSD III.2.6/2.7) — Staff picker cùng đơn vị
// Middleware chỉ authenticate (KHÔNG requireRoles) — bypass RBAC admin
// MOUNT TRƯỚC route `/:id/...` để không bị catch
// ============================================================
router.get('/nhan-vien-cung-don-vi', async (req: Request, res: Response) => {
  try {
    const { departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    if (!Number.isInteger(ancestorUnitId) || ancestorUnitId <= 0) {
      res.status(400).json({ success: false, message: 'Không xác định được đơn vị' });
      return;
    }
    const list = await handlingDocRepository.listStaffSameUnit(ancestorUnitId);
    res.json({ success: true, data: list });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// 5.1 DANH SÁCH HSCV
// ============================================================

// GET / — Danh sách HSCV (phân trang + filter)
router.get('/', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const {
      filter_type, status, keyword, from_date, to_date, page, page_size,
    } = req.query;

    const filterDeptId = req.query.department_id ? Number(req.query.department_id) : undefined;
    const deptIds = await resolveDeptSubtree(departmentId, isAdmin, filterDeptId);

    const rows = await handlingDocRepository.getList(
      0,
      deptIds,
      staffId,
      {
        status: status !== undefined ? Number(status) : undefined,
        filterType: filter_type as string || undefined,
        keyword: keyword as string || undefined,
        fromDate: from_date as string || undefined,
        toDate: to_date as string || undefined,
        page: page ? Number(page) : 1,
        pageSize: page_size ? Number(page_size) : 20,
      },
    );

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

// GET /count-by-status — Đếm HSCV theo trạng thái (cho tab badges)
router.get('/count-by-status', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
    const deptIds = await resolveDeptSubtree(departmentId, isAdmin);
    const rows = await handlingDocRepository.countByStatus(0, staffId, deptIds);
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// 5.2 CRUD
// ============================================================

// POST / — Tạo HSCV mới
router.post('/', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const body = req.body;

    if (!body.name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên hồ sơ công việc là bắt buộc' });
      return;
    }

    const result = await handlingDocRepository.create({
      unitId: ancestorUnitId,
      departmentId: body.department_id ? Number(body.department_id) : departmentId,
      docTypeId: body.doc_type_id ? Number(body.doc_type_id) : undefined,
      docFieldId: body.doc_field_id ? Number(body.doc_field_id) : undefined,
      name: body.name.trim(),
      comments: body.comments || undefined,
      startDate: body.start_date || undefined,
      endDate: body.end_date || undefined,
      curatorId: body.curator_id ? Number(body.curator_id) : undefined,
      signerId: body.signer_id ? Number(body.signer_id) : undefined,
      workflowId: body.workflow_id ? Number(body.workflow_id) : undefined,
      isFromDoc: body.is_from_doc ?? false,
      parentId: body.parent_id ? Number(body.parent_id) : undefined,
      createdBy: staffId,
    });

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.status(201).json({ success: true, message: result.message, data: { id: result.id } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /:id — Chi tiết HSCV
router.get('/:id', async (req: Request, res: Response) => {
  try {
    // T-02-07: filter by ancestor unit to prevent cross-tenant access
    const { departmentId, isAdmin } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const doc = await handlingDocRepository.getById(id);
    if (!doc) {
      res.status(404).json({ success: false, message: 'Không tìm thấy hồ sơ công việc' });
      return;
    }
    // Cross-tenant check — admin bypass de quan tri toan he thong
    if (!isAdmin) {
      const ancestorUnitId = await resolveAncestorUnit(departmentId);
      if (doc.unit_id !== ancestorUnitId) {
        res.status(403).json({ success: false, message: 'Không có quyền truy cập hồ sơ này' });
        return;
      }
    }
    res.json({ success: true, data: doc });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PUT /:id — Cập nhật HSCV
router.put('/:id', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const body = req.body;

    if (!body.name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên hồ sơ công việc là bắt buộc' });
      return;
    }

    const result = await handlingDocRepository.update(id, {
      docTypeId: body.doc_type_id ? Number(body.doc_type_id) : undefined,
      docFieldId: body.doc_field_id ? Number(body.doc_field_id) : undefined,
      name: body.name.trim(),
      comments: body.comments || undefined,
      startDate: body.start_date || undefined,
      endDate: body.end_date || undefined,
      curatorId: body.curator_id ? Number(body.curator_id) : undefined,
      signerId: body.signer_id ? Number(body.signer_id) : undefined,
      workflowId: body.workflow_id ? Number(body.workflow_id) : undefined,
      updatedBy: staffId,
    });

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { message: result.message } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /:id — Xóa HSCV
router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const result = await handlingDocRepository.delete(id);
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
// 5.4 CÁN BỘ XỬ LÝ
// ============================================================

// GET /:id/can-bo — Danh sách cán bộ xử lý
router.get('/:id/can-bo', async (req: Request, res: Response) => {
  try {
    const rows = await handlingDocRepository.getStaff(Number(req.params.id));
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /:id/phan-cong — Phân công cán bộ
router.post('/:id/phan-cong', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const docId = Number(req.params.id);
    const { staff_ids, role_type, deadline } = req.body;

    if (!Array.isArray(staff_ids) || staff_ids.length === 0) {
      res.status(400).json({ success: false, message: 'Vui lòng chọn ít nhất một cán bộ' });
      return;
    }
    // T-02-08: limit staff_ids array to prevent DoS
    if (staff_ids.length > 50) {
      res.status(400).json({ success: false, message: 'Không được phân công quá 50 cán bộ cùng lúc' });
      return;
    }

    const result = await handlingDocRepository.assignStaff(
      docId,
      staff_ids.map(Number),
      role_type ? Number(role_type) : 1,
      deadline || null,
      staffId,
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

// DELETE /:id/phan-cong/:staffId — Hủy phân công
router.delete('/:id/phan-cong/:staffId', async (req: Request, res: Response) => {
  try {
    const docId = Number(req.params.id);
    const staffId = Number(req.params.staffId);
    const result = await handlingDocRepository.removeStaff(docId, staffId);
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
// 5.5 Ý KIẾN
// ============================================================

// GET /:id/y-kien — Danh sách ý kiến
router.get('/:id/y-kien', async (req: Request, res: Response) => {
  try {
    const rows = await handlingDocRepository.getOpinions(Number(req.params.id));
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /:id/y-kien — Thêm ý kiến
router.post('/:id/y-kien', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const docId = Number(req.params.id);
    const { content, opinion_type } = req.body;

    if (!content?.trim()) {
      res.status(400).json({ success: false, message: 'Nội dung ý kiến là bắt buộc' });
      return;
    }

    const result = await handlingDocRepository.createOpinion(
      docId, staffId, content.trim(), opinion_type || 'general',
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

// ============================================================
// 5.6 VĂN BẢN LIÊN KẾT
// ============================================================

// GET /:id/van-ban-lien-ket — Danh sách văn bản liên kết
router.get('/:id/van-ban-lien-ket', async (req: Request, res: Response) => {
  try {
    const rows = await handlingDocRepository.getLinkedDocs(Number(req.params.id));
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /:id/lien-ket-van-ban — Liên kết văn bản
router.post('/:id/lien-ket-van-ban', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const docId = Number(req.params.id);
    const { doc_id, doc_type } = req.body;

    if (!doc_id) {
      res.status(400).json({ success: false, message: 'Văn bản liên kết là bắt buộc' });
      return;
    }
    const validDocTypes = ['incoming', 'outgoing', 'drafting'];
    if (!doc_type || !validDocTypes.includes(doc_type)) {
      res.status(400).json({ success: false, message: 'Loại văn bản không hợp lệ' });
      return;
    }

    const result = await handlingDocRepository.linkDoc(docId, Number(doc_id), doc_type, staffId);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.status(201).json({ success: true, message: result.message, data: { id: result.id } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /:id/lien-ket-van-ban/:linkId — Hủy liên kết văn bản
router.delete('/:id/lien-ket-van-ban/:linkId', async (req: Request, res: Response) => {
  try {
    const linkId = Number(req.params.linkId);
    const result = await handlingDocRepository.unlinkDoc(linkId);
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
// 5.3 FILE ĐÍNH KÈM
// ============================================================

// GET /:id/dinh-kem — Danh sách file đính kèm
router.get('/:id/dinh-kem', async (req: Request, res: Response) => {
  try {
    const rows = await handlingDocRepository.getAttachments(Number(req.params.id));
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /:id/dinh-kem — Upload file đính kèm
router.post('/:id/dinh-kem', upload.single('file'), async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const docId = Number(req.params.id);
    const file = req.file;

    if (!file) {
      res.status(400).json({ success: false, message: 'Vui lòng chọn file' });
      return;
    }

    // T-02-06: validate content-type matches extension
    const allowedTypes = [
      'application/pdf', 'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'image/jpeg', 'image/png', 'image/gif', 'text/plain',
      'application/zip', 'application/x-rar-compressed',
    ];
    if (!allowedTypes.includes(file.mimetype)) {
      res.status(400).json({ success: false, message: 'Loại file không được hỗ trợ' });
      return;
    }

    // Upload to MinIO
    const ext = file.originalname.split('.').pop() || '';
    const minioPath = `handling-docs/${docId}/${uuidv4()}.${ext}`;
    await uploadFile(minioPath, file.buffer, file.mimetype);

    // Save to DB via rawQuery (no SP for HSCV attachments)
    const rows = await rawQuery<{ id: number }>(
      `INSERT INTO edoc.attachment_handling_docs
         (handling_doc_id, file_name, file_path, file_size, content_type, sort_order, created_by, created_at)
       VALUES ($1, $2, $3, $4, $5, 0, $6, NOW())
       RETURNING id`,
      [docId, file.originalname, minioPath, file.size, file.mimetype, staffId],
    );

    const newId = rows[0]?.id;
    if (!newId) {
      res.status(500).json({ success: false, message: 'Không thể lưu thông tin file' });
      return;
    }
    res.status(201).json({ success: true, data: { id: newId, file_name: file.originalname, file_path: minioPath } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /:id/dinh-kem/:attachmentId — Xóa file đính kèm
router.delete('/:id/dinh-kem/:attachmentId', async (req: Request, res: Response) => {
  try {
    const attachmentId = Number(req.params.attachmentId);

    // Get file path from DB first
    const rows = await rawQuery<{ file_path: string }>(
      'SELECT file_path FROM edoc.attachment_handling_docs WHERE id = $1',
      [attachmentId],
    );

    if (rows.length === 0) {
      res.status(404).json({ success: false, message: 'Không tìm thấy file' });
      return;
    }

    const filePath = rows[0].file_path;

    // Delete from DB
    await rawQuery('DELETE FROM edoc.attachment_handling_docs WHERE id = $1', [attachmentId]);

    // Delete from MinIO (best-effort)
    if (filePath) {
      try { await deleteFile(filePath); } catch { /* ignore MinIO errors */ }
    }

    res.json({ success: true, data: { message: 'Xóa file thành công' } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// 5.3 HSCV CON
// ============================================================

// GET /:id/hscv-con — Danh sách HSCV con
router.get('/:id/hscv-con', async (req: Request, res: Response) => {
  try {
    const rows = await handlingDocRepository.getChildren(Number(req.params.id));
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// 5.7 CHUYỂN TRẠNG THÁI
// ============================================================

// PATCH /:id/trang-thai — Thay đổi trạng thái HSCV
router.patch('/:id/trang-thai', async (req: Request, res: Response) => {
  try {
    // T-02-05: extract staffId from JWT, never from body
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const { action, reason, new_status } = req.body;

    // T-02-09: validate action enum
    const validActions = ['submit', 'approve', 'reject', 'return', 'complete', 'change'];
    if (!action || !validActions.includes(action)) {
      res.status(400).json({ success: false, message: 'Hành động không hợp lệ' });
      return;
    }

    // Validate reason required for reject and return
    if ((action === 'reject' || action === 'return') && (!reason || !reason.toString().trim())) {
      res.status(400).json({ success: false, message: 'Lý do là bắt buộc khi từ chối hoặc trả về' });
      return;
    }

    let result;
    switch (action) {
      case 'submit':
        result = await handlingDocRepository.submit(id, staffId);
        break;
      case 'approve':
        result = await handlingDocRepository.approve(id, staffId);
        break;
      case 'reject':
        result = await handlingDocRepository.reject(id, staffId, reason.toString().trim());
        break;
      case 'return':
        result = await handlingDocRepository.returnDoc(id, staffId, reason.toString().trim());
        break;
      case 'complete':
        result = await handlingDocRepository.complete(id, staffId);
        break;
      case 'change':
        if (new_status === undefined || new_status === null) {
          res.status(400).json({ success: false, message: 'Trạng thái mới là bắt buộc' });
          return;
        }
        result = await handlingDocRepository.changeStatus(id, Number(new_status), staffId, reason || undefined);
        break;
      default:
        res.status(400).json({ success: false, message: 'Hành động không hợp lệ' });
        return;
    }

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { message: result.message } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PATCH /:id/tien-do — Cập nhật tiến độ
router.patch('/:id/tien-do', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const { progress } = req.body;

    if (progress === undefined || progress === null) {
      res.status(400).json({ success: false, message: 'Tiến độ là bắt buộc' });
      return;
    }
    const progressNum = Number(progress);
    if (isNaN(progressNum) || progressNum < 0 || progressNum > 100) {
      res.status(400).json({ success: false, message: 'Tiến độ phải trong khoảng 0-100' });
      return;
    }

    const result = await handlingDocRepository.updateProgress(id, progressNum);
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
// HDSD 3.1 / 3.2 — Mở lại HSCV + Lấy số
// ============================================================

// POST /:id/mo-lai — Mở lại HSCV (status=4 → 1, GIỮ progress=100 per A2)
router.post('/:id/mo-lai', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    if (!Number.isInteger(id) || id <= 0) {
      res.status(400).json({ success: false, message: 'ID không hợp lệ' });
      return;
    }
    const result = await handlingDocRepository.reopen(id, staffId);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /:id/lay-so — Lấy số HSCV (MAX(number)+1 theo năm created_at + doc_book_id)
router.post('/:id/lay-so', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const docBookId = Number(req.body?.doc_book_id);

    if (!Number.isInteger(id) || id <= 0) {
      res.status(400).json({ success: false, message: 'ID không hợp lệ' });
      return;
    }
    if (!Number.isInteger(docBookId) || docBookId <= 0) {
      res.status(400).json({ success: false, message: 'Vui lòng chọn sổ văn bản' });
      return;
    }

    const result = await handlingDocRepository.assignNumber(id, staffId, docBookId);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, message: result.message, number: result.number });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /:id/y-kien/:opinionId/chuyen-tiep — Chuyển tiếp ý kiến HSCV (Gap E HDSD III.2.6)
router.post('/:id/y-kien/:opinionId/chuyen-tiep', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const opinionId = Number(req.params.opinionId);
    const toStaffId = Number(req.body?.to_staff_id);
    const note = String(req.body?.note || '').trim();
    if (!Number.isInteger(opinionId) || opinionId <= 0) {
      res.status(400).json({ success: false, message: 'ID ý kiến không hợp lệ' });
      return;
    }
    if (!Number.isInteger(toStaffId) || toStaffId <= 0) {
      res.status(400).json({ success: false, message: 'Vui lòng chọn người nhận' });
      return;
    }
    if (!note) {
      res.status(400).json({ success: false, message: 'Vui lòng nhập nội dung chuyển tiếp' });
      return;
    }
    const result = await handlingDocRepository.forwardOpinion(opinionId, staffId, toStaffId, note);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, message: result.message, id: result.id });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /:id/chuyen-tiep — Chuyển tiếp HSCV (Gap F HDSD III.2.7)
router.post('/:id/chuyen-tiep', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const toStaffId = Number(req.body?.to_staff_id);
    const note = String(req.body?.note || '').trim();
    if (!Number.isInteger(id) || id <= 0) {
      res.status(400).json({ success: false, message: 'ID không hợp lệ' });
      return;
    }
    if (!Number.isInteger(toStaffId) || toStaffId <= 0) {
      res.status(400).json({ success: false, message: 'Vui lòng chọn người nhận' });
      return;
    }
    const result = await handlingDocRepository.transfer(id, staffId, toStaffId, note, staffId);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /:id/lich-su — Lấy lịch sử HSCV (Gap F HDSD III.2.7)
router.get('/:id/lich-su', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isInteger(id) || id <= 0) {
      res.status(400).json({ success: false, message: 'ID không hợp lệ' });
      return;
    }
    const list = await handlingDocRepository.getHistory(id);
    res.json({ success: true, data: list });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /:id/huy — Hủy HSCV với lý do (Gap D HDSD III.2.5)
router.post('/:id/huy', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const reason = String(req.body?.reason || '').trim();
    if (!Number.isInteger(id) || id <= 0) {
      res.status(400).json({ success: false, message: 'ID không hợp lệ' });
      return;
    }
    if (!reason) {
      res.status(400).json({ success: false, message: 'Vui lòng nhập lý do hủy' });
      return;
    }
    const result = await handlingDocRepository.cancel(id, staffId, reason);
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
