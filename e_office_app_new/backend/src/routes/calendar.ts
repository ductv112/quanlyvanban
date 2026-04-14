import { Router, type Request, type Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { requireRoles } from '../middleware/auth.js';
import { calendarRepository } from '../repositories/calendar.repository.js';
import { handleDbError } from '../lib/error-handler.js';

const router = Router();

// ============================================================
// GET /events — Danh sách sự kiện lịch (theo phạm vi + khoảng ngày)
// ============================================================
router.get('/events', async (req: Request, res: Response) => {
  try {
    const { staffId, unitId } = (req as AuthRequest).user;
    const { scope, start, end } = req.query;

    const scopeVal = (scope as string) || 'personal';
    const startVal = (start as string) || new Date(Date.now() - 30 * 24 * 3600000).toISOString();
    const endVal = (end as string) || new Date(Date.now() + 60 * 24 * 3600000).toISOString();

    const rows = await calendarRepository.getList(scopeVal, unitId, staffId, startVal, endVal);
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// GET /events/:id — Chi tiết sự kiện lịch
// ============================================================
router.get('/events/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const event = await calendarRepository.getById(id);
    if (!event) {
      res.status(404).json({ success: false, message: 'Không tìm thấy sự kiện lịch' });
      return;
    }
    res.json({ success: true, data: event });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// POST /events — Tạo sự kiện lịch mới
// T-04-04: created_by MUST come from JWT staffId, never from body
// T-04-08: unit/leader scope requires admin/secretary role
// ============================================================
router.post('/events', async (req: Request, res: Response) => {
  try {
    // T-04-04: use staffId from JWT
    const { staffId, unitId, roles } = (req as AuthRequest).user;
    const body = req.body;

    if (!body.title?.trim()) {
      res.status(400).json({ success: false, message: 'Tiêu đề sự kiện là bắt buộc' });
      return;
    }
    if (!body.start_time) {
      res.status(400).json({ success: false, message: 'Thời gian bắt đầu là bắt buộc' });
      return;
    }
    if (!body.end_time) {
      res.status(400).json({ success: false, message: 'Thời gian kết thúc là bắt buộc' });
      return;
    }

    const scope = body.scope || 'personal';

    // T-04-08: only admin/secretary can create unit or leader scope events
    if (scope === 'unit' || scope === 'leader') {
      const allowedRoles = ['admin', 'secretary', 'van_thu', 'quan_tri'];
      const hasRole = allowedRoles.some((r) => roles.includes(r));
      if (!hasRole) {
        res.status(403).json({ success: false, message: 'Chỉ quản trị viên hoặc văn thư được tạo sự kiện cơ quan/lãnh đạo' });
        return;
      }
    }

    const result = await calendarRepository.create(
      body.title.trim(),
      body.description || null,
      body.start_time,
      body.end_time,
      body.all_day ?? false,
      body.color || null,
      body.repeat_type || 'none',
      scope,
      scope !== 'personal' ? unitId : null,
      staffId, // T-04-04: always from JWT
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
// PUT /events/:id — Cập nhật sự kiện lịch
// T-04-05: SP checks created_by = staffId for personal scope ownership
// ============================================================
router.put('/events/:id', async (req: Request, res: Response) => {
  try {
    // T-04-05: staffId from JWT for ownership verification
    const { staffId, unitId, roles } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const body = req.body;

    if (!body.title?.trim()) {
      res.status(400).json({ success: false, message: 'Tiêu đề sự kiện là bắt buộc' });
      return;
    }
    if (!body.start_time) {
      res.status(400).json({ success: false, message: 'Thời gian bắt đầu là bắt buộc' });
      return;
    }
    if (!body.end_time) {
      res.status(400).json({ success: false, message: 'Thời gian kết thúc là bắt buộc' });
      return;
    }

    const scope = body.scope || 'personal';

    // T-04-08: unit/leader scope requires admin role
    if (scope === 'unit' || scope === 'leader') {
      const allowedRoles = ['admin', 'secretary', 'van_thu', 'quan_tri'];
      const hasRole = allowedRoles.some((r) => roles.includes(r));
      if (!hasRole) {
        res.status(403).json({ success: false, message: 'Chỉ quản trị viên hoặc văn thư được chỉnh sửa sự kiện cơ quan/lãnh đạo' });
        return;
      }
    }

    const result = await calendarRepository.update(
      id,
      body.title.trim(),
      body.description || null,
      body.start_time,
      body.end_time,
      body.all_day ?? false,
      body.color || null,
      body.repeat_type || 'none',
      scope,
      scope !== 'personal' ? unitId : null,
      staffId, // T-04-05: passed to SP for ownership check
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

// ============================================================
// DELETE /events/:id — Xóa sự kiện lịch (soft delete)
// T-04-05: SP checks ownership before delete
// ============================================================
router.delete('/events/:id', async (req: Request, res: Response) => {
  try {
    // T-04-05: staffId from JWT for ownership verification
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);

    const result = await calendarRepository.delete(id, staffId);
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
