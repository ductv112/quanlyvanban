import { Router, type Request, type Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { sendConfigRepository } from '../repositories/send-config.repository.js';
import { handleDbError } from '../lib/error-handler.js';

const router = Router();

// GET / — Lấy danh sách cấu hình gửi nhanh của user đăng nhập
router.get('/', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const { config_type } = req.query;
    const rows = await sendConfigRepository.getByUser(staffId, (config_type as string) || 'doc');
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST / — Lưu cấu hình gửi nhanh (bulk replace)
router.post('/', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const { config_type, target_user_ids } = req.body;
    if (!Array.isArray(target_user_ids)) {
      res.status(400).json({ success: false, message: 'Danh sách người nhận không hợp lệ' });
      return;
    }
    const result = await sendConfigRepository.save(
      staffId,
      config_type || 'doc',
      target_user_ids.map(Number),
    );
    res.json({ success: true, data: result });
  } catch (error) {
    handleDbError(error, res);
  }
});

export default router;
