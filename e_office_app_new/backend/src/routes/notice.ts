import { Router, type Request, type Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { noticeRepository } from '../repositories/notice.repository.js';
import { handleDbError } from '../lib/error-handler.js';
import { resolveAncestorUnit } from '../lib/department-subtree.js';

const router = Router();

// ============================================================
// GET / — Danh sách thông báo (phân trang)
// ============================================================
router.get('/', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const { is_read, page, page_size } = req.query;

    let isReadFilter: boolean | null = null;
    if (is_read === 'true') isReadFilter = true;
    else if (is_read === 'false') isReadFilter = false;

    const rows = await noticeRepository.getList(
      ancestorUnitId,
      staffId,
      isReadFilter,
      page ? Number(page) : 1,
      page_size ? Number(page_size) : 20,
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

// ============================================================
// GET /unread-count — Đếm thông báo chưa đọc
// ============================================================
router.get('/unread-count', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const count = await noticeRepository.countUnread(staffId, ancestorUnitId);
    res.json({ success: true, data: { count } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// POST / — Tạo thông báo mới
// ============================================================
router.post('/', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const { title, content, notice_type } = req.body;

    if (!title?.trim()) {
      res.status(400).json({ success: false, message: 'Tiêu đề thông báo là bắt buộc' });
      return;
    }
    if (title.trim().length > 300) {
      res.status(400).json({ success: false, message: 'Tiêu đề không được vượt quá 300 ký tự' });
      return;
    }
    if (!content?.trim()) {
      res.status(400).json({ success: false, message: 'Nội dung thông báo là bắt buộc' });
      return;
    }

    // created_by MUST come from JWT, never from request body (T-03-11 mitigation)
    const result = await noticeRepository.create(
      ancestorUnitId,
      title.trim(),
      content.trim(),
      notice_type || null,
      staffId,
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

// ============================================================
// PATCH /mark-all-read — Đánh dấu tất cả đã đọc
// NOTE: Must be before /:id/read to avoid route shadowing
// ============================================================
router.patch('/mark-all-read', async (req: Request, res: Response) => {
  try {
    const { staffId, departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const result = await noticeRepository.markAllRead(staffId, ancestorUnitId);
    res.json({ success: true, data: { count: result.count, message: result.message } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// PATCH /:id/read — Đánh dấu một thông báo đã đọc
// ============================================================
router.patch('/:id/read', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const noticeId = Number(req.params.id);

    const result = await noticeRepository.markRead(noticeId, staffId);
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
