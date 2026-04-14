import { Router, type Request, type Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { notificationRepository } from '../repositories/notification.repository.js';
import { emailQueue, smsQueue, fcmQueue, zaloQueue } from '../lib/queue/client.js';
import { handleDbError } from '../lib/error-handler.js';

const router = Router();

// ============================================================
// POST /device-tokens — Dang ky device token
// Body: { device_token, device_type }
// ============================================================
router.post('/device-tokens', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const { device_token, device_type } = req.body;

    if (!device_token) {
      res.status(400).json({ success: false, message: 'device_token la bat buoc' });
      return;
    }

    const result = await notificationRepository.upsertDeviceToken(
      staffId,
      device_token,
      device_type || 'web',
    );

    res.status(201).json(result);
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// GET /device-tokens — Danh sach device tokens cua user
// ============================================================
router.get('/device-tokens', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const rows = await notificationRepository.getDeviceTokensByStaff(staffId);
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// DELETE /device-tokens/:id — Xoa device token (ownership check via staffId)
// ============================================================
router.delete('/device-tokens/:id', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);

    const result = await notificationRepository.deleteDeviceToken(id, staffId);
    if (!result.success) {
      res.status(404).json(result);
      return;
    }

    res.json(result);
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// GET /logs — Danh sach log thong bao cua user
// Query: channel, send_status, page, pageSize
// ============================================================
router.get('/logs', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const { channel, send_status, page, pageSize } = req.query;

    const rows = await notificationRepository.getLogList(
      staffId,
      (channel as string) || null,
      (send_status as string) || null,
      Number(page) || 1,
      Number(pageSize) || 20,
    );

    const total = rows.length > 0 ? rows[0].total_count : 0;
    res.json({
      success: true,
      data: rows,
      pagination: {
        total,
        page: Number(page) || 1,
        pageSize: Number(pageSize) || 20,
      },
    });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// GET /preferences — Lay cau hinh thong bao cua user
// ============================================================
router.get('/preferences', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const rows = await notificationRepository.getPreferences(staffId);
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// PUT /preferences — Cap nhat cau hinh thong bao
// Body: { channel, is_enabled }
// ============================================================
router.put('/preferences', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const { channel, is_enabled } = req.body;

    if (!channel) {
      res.status(400).json({ success: false, message: 'channel la bat buoc' });
      return;
    }

    const result = await notificationRepository.upsertPreference(
      staffId,
      channel,
      is_enabled !== false,
    );

    res.json(result);
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// POST /send-test — Debug: gui test notification qua 4 kenh
// Body: { title, body, ref_type?, ref_id? }
// ============================================================
router.post('/send-test', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const { title, body, ref_type, ref_id } = req.body;

    const channels = ['fcm', 'zalo', 'sms', 'email'] as const;
    const logIds: number[] = [];

    for (const channel of channels) {
      // Create notification log record
      const log = await notificationRepository.createLog(
        staffId,
        channel,
        'test',
        title || 'Test notification',
        body || 'Day la thong bao thu nghiem',
        ref_type || null,
        ref_id ? Number(ref_id) : null,
      );

      if (log.success) {
        logIds.push(log.id);

        const jobData = {
          staff_id: staffId,
          channel,
          event_type: 'test',
          title: title || 'Test notification',
          body: body || 'Day la thong bao thu nghiem',
          ref_type: ref_type || null,
          ref_id: ref_id ? Number(ref_id) : null,
          notification_log_id: log.id,
        };

        // Enqueue to respective channel queue
        if (channel === 'fcm') await fcmQueue.add('push', jobData);
        else if (channel === 'zalo') await zaloQueue.add('send', jobData);
        else if (channel === 'sms') await smsQueue.add('send', jobData);
        else if (channel === 'email') await emailQueue.add('send', jobData);
      }
    }

    res.status(201).json({
      success: true,
      message: `Da gui test notification qua ${logIds.length} kenh`,
      data: { log_ids: logIds },
    });
  } catch (error) {
    handleDbError(error, res);
  }
});

export default router;
