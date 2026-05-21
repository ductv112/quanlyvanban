/**
 * Admin LGSP routes — Phase 37 Plan 37-01.
 *
 * Mount tại /api/admin/* (server.ts wrap với authenticate + requireRoles('Quản trị hệ thống')).
 * Tất cả endpoints REQUIRE admin role — non-admin user → 403 Forbidden.
 *
 * Endpoints (9):
 *   GET    /lgsp-agency-config              List 12 row (KHÔNG decrypt — secret mask '***')
 *   PUT    /lgsp-agency-config/:id          Update credential (encrypt + invalidate cache)
 *   PATCH  /lgsp-agency-config/:id/active   Toggle is_active
 *   POST   /lgsp-status-outbox/:id/retry    Reset outbox event lỗi
 *   POST   /lgsp-tracking/:id/retry         Reset tracking + re-enqueue send job
 *   GET    /inter-organizations             List CRUD catalog
 *   POST   /inter-organizations             Create
 *   PUT    /inter-organizations/:id         Update
 *   DELETE /inter-organizations/:id         Delete
 *
 * (Test connection + overview endpoint → Plan 37-02 sẽ extend cùng file)
 */

import { Router, type Request, type Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { lgspAgencyConfigRepository } from '../repositories/lgsp-agency-config.repository.js';
import { lgspStatusOutboxRepository } from '../repositories/lgsp-status-outbox.repository.js';
import { lgspRepository } from '../repositories/lgsp.repository.js';
import { interOrganizationRepository } from '../repositories/inter-organization.repository.js';
import { encryptSecret } from '../services/signing/crypto.js';
import { invalidateLgspServiceCache } from '../services/lgsp.service.js';
import { enqueueLgspSendJob } from '../lib/queue/lgsp-send-queue.js';
import { handleDbError } from '../lib/error-handler.js';

const router = Router();

// ============================================================
// GET /lgsp-agency-config — List 12 row (KHÔNG decrypt secret)
// ============================================================
router.get('/lgsp-agency-config', async (_req: Request, res: Response) => {
  try {
    const rows = await lgspAgencyConfigRepository.list();
    // SP fn_lgsp_agency_config_list KHÔNG trả secret_key_encrypted. Add explicit mask
    // 'secret_key_masked' để UI rõ ràng (hiển thị "***" trong column secret).
    const masked = rows.map((r) => ({ ...r, secret_key_masked: '***' }));
    res.json({ success: true, data: masked });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// PUT /lgsp-agency-config/:id — Update credential
// Body: { systemId?, secretKey?, baseUrl?, environment? }
//   secretKey OPTIONAL — nếu undefined hoặc rỗng → giữ nguyên ciphertext cũ
// ============================================================
router.put('/lgsp-agency-config/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const { staffId } = (req as AuthRequest).user;
    const { systemId, secretKey, baseUrl, environment } = req.body as {
      systemId?: string;
      secretKey?: string;
      baseUrl?: string;
      environment?: 'sandbox' | 'prod';
    };

    const existing = await lgspAgencyConfigRepository.getById(id);
    if (!existing) {
      res.status(404).json({ success: false, message: 'Không tìm thấy cấu hình LGSP' });
      return;
    }

    // Encrypt secret nếu user nhập mới, else giữ ciphertext cũ
    let secretKeyEncrypted: Buffer;
    if (typeof secretKey === 'string' && secretKey.trim() !== '') {
      secretKeyEncrypted = await encryptSecret(secretKey.trim());
    } else {
      secretKeyEncrypted = existing.secret_key_encrypted;
    }

    const result = await lgspAgencyConfigRepository.upsert({
      unitId: Number(existing.unit_id),
      environment: (environment ?? existing.environment) as 'sandbox' | 'prod',
      systemId: (systemId ?? existing.system_id).slice(0, 13),
      secretKeyEncrypted,
      baseUrl: (baseUrl ?? existing.base_url).slice(0, 500),
      updatedBy: staffId,
    });

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }

    // Invalidate cache cho cả 2 env (defensive — admin có thể đổi env)
    invalidateLgspServiceCache(Number(existing.unit_id));

    res.json({ success: true, message: 'Đã cập nhật cấu hình LGSP', id: result.id });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// PATCH /lgsp-agency-config/:id/active — Toggle is_active
// Body: { is_active: boolean }
// ============================================================
router.patch('/lgsp-agency-config/:id/active', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const { staffId } = (req as AuthRequest).user;
    const isActive = req.body?.is_active === true;

    const existing = await lgspAgencyConfigRepository.getById(id);
    if (!existing) {
      res.status(404).json({ success: false, message: 'Không tìm thấy cấu hình LGSP' });
      return;
    }

    const result = await lgspAgencyConfigRepository.setActive(id, isActive, staffId);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }

    invalidateLgspServiceCache(Number(existing.unit_id), existing.environment);

    res.json({
      success: true,
      message: isActive ? 'Đã bật kết nối LGSP' : 'Đã tắt kết nối LGSP',
    });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// POST /lgsp-status-outbox/:id/retry — Reset outbox event lỗi
// ============================================================
router.post('/lgsp-status-outbox/:id/retry', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const result = await lgspStatusOutboxRepository.resetForRetry(id);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// POST /lgsp-tracking/:id/retry — Reset tracking + re-enqueue send job
// ============================================================
router.post('/lgsp-tracking/:id/retry', async (req: Request, res: Response) => {
  try {
    const trackingId = Number(req.params.id);
    const tracking = await lgspRepository.getTrackingForRetry(trackingId);
    if (!tracking) {
      res.status(404).json({
        success: false,
        message: 'Không tìm thấy tracking hoặc đơn vị gửi chưa có LGSP config active',
      });
      return;
    }

    const resetResult = await lgspRepository.resetTrackingForRetry(trackingId);
    if (!resetResult.success) {
      res.status(400).json({ success: false, message: resetResult.message });
      return;
    }

    // Re-enqueue lgsp-send job (mirror Phase 34-03 enqueue payload)
    await enqueueLgspSendJob({
      recipient_id: tracking.recipient_id,
      outgoing_doc_id: tracking.outgoing_doc_id,
      tracking_id: tracking.id,
      sender_unit_id: tracking.sender_unit_id,
      environment: tracking.environment,
    });

    res.json({
      success: true,
      message: 'Đã reset tracking, worker sẽ gửi lại trong vài giây',
    });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// GET /inter-organizations — List (search, isActive filter, pagination)
// ============================================================
router.get('/inter-organizations', async (req: Request, res: Response) => {
  try {
    const search = (req.query.search as string) || null;
    const isActiveQ = req.query.is_active;
    const isActive =
      isActiveQ === 'true' ? true : isActiveQ === 'false' ? false : null;
    const page = Number(req.query.page) || 1;
    const pageSize = Math.min(Number(req.query.pageSize) || 20, 100);

    const rows = await interOrganizationRepository.listForAdmin({
      search,
      isActive,
      page,
      pageSize,
    });
    const total = rows.length > 0 ? Number(rows[0].total_count) : 0;
    res.json({
      success: true,
      data: rows,
      pagination: { total, page, pageSize },
    });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// POST /inter-organizations — Create new
// Body: { code, name, lgsp_organ_id?, parent_id?, is_active?, address?, email?, phone? }
// ============================================================
router.post('/inter-organizations', async (req: Request, res: Response) => {
  try {
    const b = req.body as Record<string, unknown>;
    const code = String(b.code ?? '').trim();
    const name = String(b.name ?? '').trim();
    if (!code) {
      res.status(400).json({ success: false, message: 'Mã cơ quan không được trống' });
      return;
    }
    if (!name) {
      res.status(400).json({ success: false, message: 'Tên cơ quan không được trống' });
      return;
    }

    const result = await interOrganizationRepository.createForAdmin({
      code,
      name,
      lgspOrganId: (b.lgsp_organ_id as string) ?? null,
      parentId: b.parent_id == null ? null : Number(b.parent_id),
      isActive: b.is_active === false ? false : true,
      address: (b.address as string) ?? null,
      email: (b.email as string) ?? null,
      phone: (b.phone as string) ?? null,
    });
    if (!result.success) {
      res.status(409).json({ success: false, message: result.message });
      return;
    }
    res.status(201).json({ success: true, message: result.message, id: result.id });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// PUT /inter-organizations/:id — Update
// ============================================================
router.put('/inter-organizations/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const b = req.body as Record<string, unknown>;
    const result = await interOrganizationRepository.updateForAdmin(id, {
      code: b.code as string | undefined,
      name: b.name as string | undefined,
      lgspOrganId: b.lgsp_organ_id as string | null | undefined,
      parentId: b.parent_id === undefined ? undefined : b.parent_id == null ? null : Number(b.parent_id),
      isActive: typeof b.is_active === 'boolean' ? (b.is_active as boolean) : undefined,
      address: b.address as string | null | undefined,
      email: b.email as string | null | undefined,
      phone: b.phone as string | null | undefined,
    });
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// DELETE /inter-organizations/:id — Delete
// ============================================================
router.delete('/inter-organizations/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const result = await interOrganizationRepository.deleteForAdmin(id);
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
