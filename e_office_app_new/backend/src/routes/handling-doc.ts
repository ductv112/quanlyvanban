import { Router, type Request, type Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { upload } from '../middleware/upload.js';
import { handlingDocRepository } from '../repositories/handling-doc.repository.js';
import { signerRepository } from '../repositories/signer.repository.js';
import { lgspStatusOutboxRepository } from '../repositories/lgsp-status-outbox.repository.js';
import { uploadFile, deleteFile, getFileUrl, streamFileToResponse } from '../lib/minio/client.js';
import { handleAttachmentPreview } from '../lib/attachment-preview.js';
import { rawQuery } from '../lib/db/query.js';
import { v4 as uuidv4 } from 'uuid';
import { handleDbError } from '../lib/error-handler.js';
import { resolveDeptSubtree, resolveAncestorUnit } from '../lib/department-subtree.js';
import { notifyBell } from '../lib/notifications/bell-emit.js';

const router = Router();

/**
 * Phase 36 Plan 36-03: helper fire outbox 06 cho TAT CA incoming docs nguon LGSP gan voi HSCV.
 *
 * Schema thuc te: edoc.handling_doc_links (handling_doc_id, doc_type, doc_id) -- KHONG phai
 * handling_doc_documents nhu plan goc. doc_type='incoming' link toi edoc.incoming_docs.
 *
 * 1 HSCV co the gan nhieu VB den nguon LGSP -- fire outbox 06 cho moi VB.
 * UNIQUE constraint (incoming_doc_id, target_status) Phase 36-01 chan duplicate.
 *
 * Best-effort: hook failure log warn nhung KHONG fail user action (D-03).
 */
async function fireHscvCompleteOutbox(
  handlingDocId: number,
  req: Request,
): Promise<void> {
  try {
    const rows = await rawQuery<{
      incoming_doc_id: number;
      external_doc_id: string | null;
      lgsp_sender_org_code: string | null;
    }>(
      `SELECT d.id AS incoming_doc_id,
              d.external_doc_id,
              d.lgsp_sender_org_code
         FROM edoc.handling_doc_links hdl
         JOIN edoc.incoming_docs d ON d.id = hdl.doc_id
        WHERE hdl.handling_doc_id = $1
          AND hdl.doc_type = 'incoming'
          AND d.source_type = 'external_lgsp'`,
      [handlingDocId],
    );
    for (const r of rows) {
      try {
        const result = await lgspStatusOutboxRepository.insertEvent({
          incoming_doc_id: Number(r.incoming_doc_id),
          target_status: '06',
          payload: {
            lgsp_doc_id: r.external_doc_id ?? null,
            sender_org_code: r.lgsp_sender_org_code ?? null,
            handling_doc_id: handlingDocId,
            trigger: 'hscv_complete',
          },
        });
        if (result === null) {
          req.log?.info(
            { handlingDocId, incomingDocId: r.incoming_doc_id },
            'HSCV complete LGSP outbox 06: dedup skip',
          );
        } else if (result.success) {
          req.log?.info(
            { handlingDocId, incomingDocId: r.incoming_doc_id, outboxId: result.id },
            'HSCV complete: LGSP outbox 06 enqueued',
          );
        } else {
          req.log?.warn(
            { handlingDocId, incomingDocId: r.incoming_doc_id, message: result.message },
            'HSCV complete LGSP outbox 06: SP returned success=false',
          );
        }
      } catch (err) {
        req.log?.warn(
          { err, handlingDocId, incomingDocId: r.incoming_doc_id },
          'HSCV complete LGSP outbox hook failed for one doc -- continuing',
        );
      }
    }
  } catch (err) {
    req.log?.warn(
      { err, handlingDocId },
      'HSCV complete LGSP outbox hook query failed -- HSCV complete still succeeded',
    );
  }
}

// ============================================================
// Gap F (HDSD III.2.7) — Staff picker cùng đơn vị (Chuyển tiếp HSCV)
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

// GET /lanh-dao-cung-don-vi — Lay danh sach Nguoi ky cua don vi user.
// Endpoint NAY khong require admin (mount duoi authenticate only) — non-admin
// nhu nguyenvanb tao HSCV van load duoc dropdown "Lanh dao ky" tu bang
// edoc.signers. Tuong tu /nhan-vien-cung-don-vi nhung chi tra signer.
router.get('/lanh-dao-cung-don-vi', async (req: Request, res: Response) => {
  try {
    const { departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    if (!Number.isInteger(ancestorUnitId) || ancestorUnitId <= 0) {
      res.status(400).json({ success: false, message: 'Không xác định được đơn vị' });
      return;
    }
    const list = await signerRepository.getList(ancestorUnitId, null);
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
      filter_type, status, keyword, from_date, to_date, page, page_size, field_id,
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
        // BUG #73: pass field_id (Lĩnh vực) filter xuống SP
        docFieldId: field_id ? Number(field_id) : undefined,
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
    const body = req.body;

    if (!body.name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên hồ sơ công việc là bắt buộc' });
      return;
    }

    // unit_id phai lay tu ancestor cua department_id (cua HSCV), KHONG phai
    // unit cua creator. Tranh inconsistency khi admin (unit=1) tao HSCV gan
    // cho dept khac unit (vd dept=2 So Noi vu) -> stored unit_id=1, list filter
    // boi dept_subtree match nhung detail filter boi unit_id thi 403.
    const finalDeptId = body.department_id ? Number(body.department_id) : departmentId;
    const finalUnitId = await resolveAncestorUnit(finalDeptId);

    const result = await handlingDocRepository.create({
      unitId: finalUnitId,
      departmentId: finalDeptId,
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

    // Bell notification — best-effort. Curator được giao là người chính phụ trách HSCV.
    try {
      const curatorId = body.curator_id ? Number(body.curator_id) : null;
      if (curatorId) {
        const senderRows = await rawQuery<{ full_name: string }>(
          'SELECT full_name FROM public.staff WHERE id = $1', [staffId],
        );
        const senderName = senderRows[0]?.full_name?.trim() || 'Cán bộ';
        await notifyBell({
          targetStaffIds: [curatorId],
          senderStaffId: staffId,
          type: 'task_assigned',
          title: 'Bạn được giao xử lý hồ sơ công việc',
          message: `${senderName} đã giao bạn xử lý "${body.name.trim()}"`,
          link: `/ho-so-cong-viec/${result.id}`,
          metadata: { hscv_id: result.id, role: 'curator', sender_id: staffId },
        });
      }
    } catch (err) {
      req.log?.warn({ err, hscvId: result.id }, 'Bell notification (task_assigned/create) failed');
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
    // BUG-PERM-007: validate numeric id để tránh path shadowing (VD: /bao-cao)
    const idStr = String(req.params.id);
    if (!/^\d+$/.test(idStr)) {
      res.status(404).json({ success: false, message: 'Đường dẫn không hợp lệ' });
      return;
    }
    const id = Number(idStr);
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
//
// BUG #77 follow-up (2026-05-19): Frontend gửi per-staff payload
//   { staff: [{staff_id, role, deadline}, ...] }
// vì UI cho phép mỗi cán bộ có role (Phụ trách/Phối hợp) + deadline riêng.
// Backward-compat: vẫn accept format cũ { staff_ids, role_type, deadline }
// (seed_sprint5.js + 1 số legacy caller).
router.post('/:id/phan-cong', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const docId = Number(req.params.id);
    const { staff, staff_ids, role_type, deadline } = req.body;

    // Chuẩn hoá payload về list { staff_id, role, deadline }
    type Assignment = { staff_id: number; role: number; deadline: string | null };
    let assignments: Assignment[] = [];
    if (Array.isArray(staff) && staff.length > 0) {
      assignments = staff.map((s: any) => ({
        staff_id: Number(s.staff_id),
        role: s.role ? Number(s.role) : 1,
        deadline: s.deadline || null,
      })).filter((a) => Number.isFinite(a.staff_id) && a.staff_id > 0);
    } else if (Array.isArray(staff_ids) && staff_ids.length > 0) {
      assignments = staff_ids.map((sid: any) => ({
        staff_id: Number(sid),
        role: role_type ? Number(role_type) : 1,
        deadline: deadline || null,
      })).filter((a) => Number.isFinite(a.staff_id) && a.staff_id > 0);
    }

    if (assignments.length === 0) {
      res.status(400).json({ success: false, message: 'Vui lòng chọn ít nhất một cán bộ' });
      return;
    }
    if (assignments.length > 50) {
      res.status(400).json({ success: false, message: 'Không được phân công quá 50 cán bộ cùng lúc' });
      return;
    }
    const uniqueIds = new Set(assignments.map((a) => a.staff_id));
    if (uniqueIds.size !== assignments.length) {
      res.status(400).json({ success: false, message: 'Danh sách cán bộ phân công có giá trị trùng — vui lòng kiểm tra lại' });
      return;
    }

    // Nhóm theo (role, deadline) để gọi SP assignStaff cho từng nhóm (SP nhận
    // array staff_ids chung 1 role/1 deadline). Per-staff customization giữ
    // được mà không phải sửa SP.
    const groups = new Map<string, { role: number; deadline: string | null; ids: number[] }>();
    for (const a of assignments) {
      const k = `${a.role}|${a.deadline ?? ''}`;
      const g = groups.get(k) ?? { role: a.role, deadline: a.deadline, ids: [] };
      g.ids.push(a.staff_id);
      groups.set(k, g);
    }

    let lastMessage = '';
    for (const g of groups.values()) {
      const result = await handlingDocRepository.assignStaff(
        docId, g.ids, g.role, g.deadline, staffId,
      );
      if (!result.success) {
        res.status(400).json({ success: false, message: result.message });
        return;
      }
      lastMessage = result.message;
    }
    const result = { success: true, message: lastMessage } as const;

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    // Mảng dùng tiếp ở notification block bên dưới
    const allStaffIds = assignments.map((a) => a.staff_id);

    // Bell notification — best-effort. Cán bộ được phân công vào HSCV (phụ trách
    // hoặc phối hợp tuỳ role_type) đều nhận thông báo.
    try {
      const senderRows = await rawQuery<{ full_name: string }>(
        'SELECT full_name FROM public.staff WHERE id = $1', [staffId],
      );
      const docRows = await rawQuery<{ name: string | null }>(
        'SELECT name FROM edoc.handling_docs WHERE id = $1', [docId],
      );
      const senderName = senderRows[0]?.full_name?.trim() || 'Cán bộ';
      const hscvName = docRows[0]?.name?.trim() || `HSCV #${docId}`;
      // BUG #77 follow-up: assignments có thể mixed role → notification dùng
      // role của staff đầu tiên làm label chung (giữ message tóm tắt).
      const firstRole = assignments[0]?.role ?? 1;
      const roleLabel = firstRole === 2 ? 'phối hợp' : 'xử lý';
      await notifyBell({
        targetStaffIds: allStaffIds,
        senderStaffId: staffId,
        type: 'task_assigned',
        title: 'Bạn được giao xử lý hồ sơ công việc',
        message: `${senderName} đã giao bạn ${roleLabel} "${hscvName}"`,
        link: `/ho-so-cong-viec/${docId}`,
        metadata: { hscv_id: docId, role_type: firstRole, sender_id: staffId },
      });
    } catch (err) {
      req.log?.warn({ err, hscvId: docId }, 'Bell notification (task_assigned/assign) failed');
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
    // BUG-HSCV-WF-003: validate ≤ 2000 ký tự
    if (content.trim().length > 2000) {
      res.status(400).json({ success: false, message: 'Nội dung ý kiến không được vượt quá 2000 ký tự' });
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

// GET /:id/dinh-kem/:attachmentId/download — Tai file dinh kem HSCV qua backend proxy
// (Truoc day HSCV thieu endpoint nay — them de dong nhat voi 3 module VB con lai)
router.get('/:id/dinh-kem/:attachmentId/download', async (req: Request, res: Response) => {
  try {
    const attachments = await handlingDocRepository.getAttachments(Number(req.params.id));
    const att = attachments.find(a => Number(a.id) === Number(req.params.attachmentId));
    if (!att) {
      res.status(404).json({ success: false, message: 'Không tìm thấy file' });
      return;
    }
    await streamFileToResponse(res, att.file_path, att.file_name, att.content_type);
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /:id/dinh-kem/:attachmentId/preview — Xem truc tiep file dinh kem HSCV (inline)
// PDF/anh/text -> stream inline; Office -> convert qua LibreOffice -> stream PDF
router.get('/:id/dinh-kem/:attachmentId/preview', async (req: Request, res: Response) => {
  try {
    const attachments = await handlingDocRepository.getAttachments(Number(req.params.id));
    const att = attachments.find(a => Number(a.id) === Number(req.params.attachmentId));
    if (!att) {
      res.status(404).json({ success: false, message: 'Không tìm thấy file' });
      return;
    }
    await handleAttachmentPreview(res, {
      filePath: att.file_path,
      contentType: att.content_type ?? null,
      attachmentId: Number(att.id),
      fileName: att.file_name,
    });
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
    // BUG-HSCV-WF-002: validate reason ≤ 500 ký tự
    if (reason && reason.toString().trim().length > 500) {
      res.status(400).json({ success: false, message: 'Lý do không được vượt quá 500 ký tự' });
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

    // Phase 36 Plan 36-03: neu action=complete -> fire LGSP outbox 06 cho VB cha nguon LGSP.
    // Best-effort: query handling_doc_links + JOIN incoming_docs filter source_type='external_lgsp',
    // INSERT outbox row cho moi VB. UNIQUE constraint Phase 36-01 chan duplicate.
    if (action === 'complete') {
      await fireHscvCompleteOutbox(id, req);
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

// POST /:id/chuyen-tiep — Chuyển tiếp HSCV (Gap F HDSD III.2.7)
// 2026-05-22: multi-recipient. Body: { to_staff_ids: number[], note?: string }.
// Backward compat: chấp nhận to_staff_id (single) cũ → wrap thành array.
router.post('/:id/chuyen-tiep', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const note = String(req.body?.note || '').trim();
    if (!Number.isInteger(id) || id <= 0) {
      res.status(400).json({ success: false, message: 'ID không hợp lệ' });
      return;
    }

    // Chuẩn hoá payload: ưu tiên to_staff_ids (array), fallback to_staff_id cũ
    const raw = Array.isArray(req.body?.to_staff_ids)
      ? req.body.to_staff_ids
      : req.body?.to_staff_id != null
        ? [req.body.to_staff_id]
        : [];
    const toStaffIds = raw
      .map((v: unknown) => Number(v))
      .filter((n: number) => Number.isInteger(n) && n > 0);
    if (toStaffIds.length === 0) {
      res.status(400).json({ success: false, message: 'Vui lòng chọn ít nhất một người nhận' });
      return;
    }
    const unique = Array.from(new Set<number>(toStaffIds));
    if (unique.length > 50) {
      res.status(400).json({ success: false, message: 'Không được chuyển tiếp quá 50 cán bộ cùng lúc' });
      return;
    }

    const result = await handlingDocRepository.transfer(id, staffId, unique, note, staffId);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, message: result.message, forwarded_count: result.forwarded_count });
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
    // BUG-HSCV-WF-002: validate reason ≤ 500 ký tự
    if (reason.length > 500) {
      res.status(400).json({ success: false, message: 'Lý do hủy không được vượt quá 500 ký tự' });
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
