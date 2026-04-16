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

// POST /:id/nhan-ban-giao — Nhận bàn giao (pending → received)
router.post('/:id/nhan-ban-giao', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const doc = await interIncomingRepository.getById(id);
    if (!doc) { res.status(404).json({ success: false, message: 'Không tìm thấy văn bản' }); return; }
    if (doc.status !== 'pending') { res.status(400).json({ success: false, message: 'Chỉ nhận bàn giao VB đang chờ xử lý' }); return; }
    await interIncomingRepository.updateStatus(id, 'received');
    res.json({ success: true, message: 'Nhận bàn giao thành công' });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /:id/chuyen-lai — Từ chối / Chuyển lại (pending → returned)
router.post('/:id/chuyen-lai', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const doc = await interIncomingRepository.getById(id);
    if (!doc) { res.status(404).json({ success: false, message: 'Không tìm thấy văn bản' }); return; }
    if (doc.status !== 'pending') { res.status(400).json({ success: false, message: 'Chỉ chuyển lại VB đang chờ xử lý' }); return; }
    await interIncomingRepository.updateStatus(id, 'returned');
    res.json({ success: true, message: 'Chuyển lại văn bản thành công' });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /:id/hoan-thanh — Hoàn thành (received → completed)
router.post('/:id/hoan-thanh', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const doc = await interIncomingRepository.getById(id);
    if (!doc) { res.status(404).json({ success: false, message: 'Không tìm thấy văn bản' }); return; }
    if (doc.status !== 'received') { res.status(400).json({ success: false, message: 'Chỉ hoàn thành VB đã nhận bàn giao' }); return; }
    await interIncomingRepository.updateStatus(id, 'completed');
    res.json({ success: true, message: 'Đã hoàn thành xử lý văn bản liên thông' });
  } catch (error) {
    handleDbError(error, res);
  }
});

export default router;
