import { Router, type Request, type Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { messageRepository } from '../repositories/message.repository.js';
import { handleDbError } from '../lib/error-handler.js';

const router = Router();

// ============================================================
// GET /inbox — Hộp thư đến
// ============================================================
router.get('/inbox', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const { keyword, page, page_size } = req.query;

    const rows = await messageRepository.getInbox(
      staffId,
      keyword as string || null,
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
// GET /sent — Hộp thư đã gửi
// ============================================================
router.get('/sent', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const { keyword, page, page_size } = req.query;

    const rows = await messageRepository.getSent(
      staffId,
      keyword as string || null,
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
// GET /trash — Thùng rác
// ============================================================
router.get('/trash', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const { page, page_size } = req.query;

    const rows = await messageRepository.getTrash(
      staffId,
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
// GET /unread-count — Đếm tin chưa đọc
// ============================================================
router.get('/unread-count', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const count = await messageRepository.countUnread(staffId);
    res.json({ success: true, data: { count } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// GET /:id — Chi tiết tin nhắn (tự động đánh dấu đã đọc)
// ============================================================
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const message = await messageRepository.getById(id, staffId);
    if (!message) {
      res.status(404).json({ success: false, message: 'Không tìm thấy tin nhắn' });
      return;
    }
    res.json({ success: true, data: message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// POST / — Gửi tin nhắn mới
// ============================================================
router.post('/', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const { to_staff_ids, subject, content, parent_id } = req.body;

    // Validate
    if (!Array.isArray(to_staff_ids) || to_staff_ids.length === 0) {
      res.status(400).json({ success: false, message: 'Vui lòng chọn ít nhất một người nhận' });
      return;
    }
    if (!subject?.trim()) {
      res.status(400).json({ success: false, message: 'Tiêu đề tin nhắn là bắt buộc' });
      return;
    }
    if (subject.trim().length > 200) {
      res.status(400).json({ success: false, message: 'Tiêu đề không được vượt quá 200 ký tự' });
      return;
    }
    if (!content?.trim()) {
      res.status(400).json({ success: false, message: 'Nội dung tin nhắn là bắt buộc' });
      return;
    }

    const result = await messageRepository.create(
      staffId,
      to_staff_ids.map(Number),
      subject.trim(),
      content.trim(),
      parent_id ? Number(parent_id) : null,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }

    // Emit realtime event to recipients — socket module loaded lazily to avoid circular deps
    // emitToUsers call is wired in Task 3 (socket.ts) after initSocket is set up
    try {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const socketModule = (globalThis as any).__socketModule;
      if (socketModule?.emitToUsers) {
        socketModule.emitToUsers(to_staff_ids.map(Number), 'new_message', {
          messageId: result.id,
          from: staffId,
          subject: subject.trim(),
        });
      }
    } catch {
      // Socket failures must NOT block API response
    }

    res.status(201).json({ success: true, data: { id: result.id } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// POST /:id/reply — Trả lời tin nhắn
// ============================================================
router.post('/:id/reply', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const messageId = Number(req.params.id);
    const { content } = req.body;

    if (!content?.trim()) {
      res.status(400).json({ success: false, message: 'Nội dung trả lời là bắt buộc' });
      return;
    }

    const result = await messageRepository.reply(messageId, staffId, content.trim());
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
// DELETE /:id — Xóa tin nhắn (soft delete)
// ============================================================
router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);

    const result = await messageRepository.delete(id, staffId);
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
