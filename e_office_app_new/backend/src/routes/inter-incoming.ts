import { Router, type Request, type Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { interIncomingRepository } from '../repositories/inter-incoming.repository.js';
import { handleDbError } from '../lib/error-handler.js';

const router = Router();

// ============================================================
// Van ban lien thong (inter-incoming docs)
// ============================================================

// GET / — Danh sach VB lien thong (phan trang + filter)
router.get('/', async (req: Request, res: Response) => {
  try {
    const { unitId } = (req as AuthRequest).user;
    const { keyword, status, from_date, to_date, page, page_size } = req.query;

    const rows = await interIncomingRepository.getList(unitId, {
      keyword: keyword as string || undefined,
      status: status as string || undefined,
      fromDate: from_date as string || undefined,
      toDate: to_date as string || undefined,
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

// GET /:id — Chi tiet VB lien thong
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const doc = await interIncomingRepository.getById(id);
    if (!doc) {
      res.status(404).json({ success: false, message: 'Không tìm thấy văn bản liên thông' });
      return;
    }
    res.json({ success: true, data: doc });
  } catch (error) {
    handleDbError(error, res);
  }
});

export default router;
