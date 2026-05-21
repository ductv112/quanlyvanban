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
import { type AuthRequest, requireRightOrNext } from '../middleware/auth.js';
import { lgspAgencyConfigRepository } from '../repositories/lgsp-agency-config.repository.js';
import { lgspStatusOutboxRepository } from '../repositories/lgsp-status-outbox.repository.js';
import { lgspRepository } from '../repositories/lgsp.repository.js';
import { interOrganizationRepository } from '../repositories/inter-organization.repository.js';
import { encryptSecret } from '../services/signing/crypto.js';
import { invalidateLgspServiceCache, getLgspService } from '../services/lgsp.service.js';
import { createLgspRealService } from '../services/lgsp-real.service.js';
import { enqueueLgspSendJob } from '../lib/queue/lgsp-send-queue.js';
import { handleDbError } from '../lib/error-handler.js';

/**
 * Phase 37 Plan 37-02 helper: format Date sang LGSP API spec YYYY/MM/DD.
 * Spec yêu cầu slash separator (KHÔNG dash) per LTVB_API_TRUC_PROD Postman /v1/syncReceivedEdocList.
 */
function formatLgspDate(d: Date): string {
  const yyyy = d.getFullYear();
  const mm = String(d.getMonth() + 1).padStart(2, '0');
  const dd = String(d.getDate()).padStart(2, '0');
  return `${yyyy}/${mm}/${dd}`;
}

// Phase 37.1: granular permission — 3 right tuong ung 3 nhom endpoint
// (DB seed: public.rights id 23 parent + 24/25/26 children, auto-assigned cho role admin id=5)
const RIGHT_LGSP_OVERVIEW = 24; // /lgsp dashboard + sync-now
const RIGHT_LGSP_CATALOG = 25;  // /lgsp/co-quan inter_organizations CRUD + sync
const RIGHT_LGSP_CONFIG = 26;   // /lgsp/cau-hinh credential + test + retry buttons
const requireOverview = requireRightOrNext(RIGHT_LGSP_OVERVIEW);
const requireCatalog = requireRightOrNext(RIGHT_LGSP_CATALOG);
const requireConfig = requireRightOrNext(RIGHT_LGSP_CONFIG);

const router = Router();

// ============================================================
// GET /lgsp-agency-config — List 12 row (KHÔNG decrypt secret)
// ============================================================
router.get('/lgsp-agency-config', requireConfig, async (_req: Request, res: Response) => {
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
router.put('/lgsp-agency-config/:id', requireConfig, async (req: Request, res: Response) => {
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
router.patch('/lgsp-agency-config/:id/active', requireConfig, async (req: Request, res: Response) => {
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
router.post('/lgsp-status-outbox/:id/retry', requireConfig, async (req: Request, res: Response) => {
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
router.post('/lgsp-tracking/:id/retry', requireConfig, async (req: Request, res: Response) => {
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
router.get('/inter-organizations', requireCatalog, async (req: Request, res: Response) => {
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
router.post('/inter-organizations', requireCatalog, async (req: Request, res: Response) => {
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
router.put('/inter-organizations/:id', requireCatalog, async (req: Request, res: Response) => {
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
// GET /inter-organizations/:id/usage — Count refs for pre-delete Modal
// (outgoing_count: VB di tham chieu -> DB block xoa neu >0,
//  incoming_count: VB den LGSP voi sender code -> mat display name neu xoa)
// ============================================================
router.get('/inter-organizations/:id/usage', requireCatalog, async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const result = await interOrganizationRepository.getUsageCount(id);
    if (!result.found) {
      res.status(404).json({ success: false, message: 'Không tìm thấy cơ quan ngoài' });
      return;
    }
    res.json({ success: true, data: result });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// DELETE /inter-organizations/:id — Delete
// ============================================================
router.delete('/inter-organizations/:id', requireCatalog, async (req: Request, res: Response) => {
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

// ============================================================
// Phase 37 Plan 37-02 — 3 endpoint mới
// ============================================================

// ------------------------------------------------------------
// POST /lgsp-agency-config/:id/test — Test connection sandbox/prod thật
//
// Lookup credential decrypted → instantiate LGSPRealService riêng (KHÔNG cache)
// → call receiveDocuments(now-1d, now) lightweight read-only → trả về kết quả
// KHÔNG có side effect (KHÔNG INSERT incoming_docs, KHÔNG update last_synced_at)
//
// Response shape (CONTEXT D-02):
//   { success: true, data: { ok, message, http_status, response_summary: { count } | null } }
//
// success luôn = true (request OK), data.ok = true/false tùy LGSP response
// ------------------------------------------------------------
router.post('/lgsp-agency-config/:id/test', requireConfig, async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const config = await lgspAgencyConfigRepository.getByIdWithDecryptedSecret(id);
    if (!config) {
      res.status(404).json({ success: false, message: 'Không tìm thấy cấu hình LGSP' });
      return;
    }

    // Tạo instance riêng (KHÔNG cache singleton) — admin có thể edit credential rồi test ngay
    // Cache invalidate đã handle ở PUT /lgsp-agency-config/:id (Plan 37-01)
    const svc = createLgspRealService({
      baseUrl: config.base_url,
      systemId: config.system_id,
      secretKey: config.secret_key_plaintext,
    });

    const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const today = new Date();

    try {
      const result = await svc.receiveDocuments(formatLgspDate(yesterday), formatLgspDate(today));
      res.json({
        success: true,
        data: {
          ok: true,
          message: 'Kết nối LGSP thành công',
          http_status: 200,
          response_summary: { count: Array.isArray(result) ? result.length : 0 },
        },
      });
    } catch (err) {
      // LGSP gọi được nhưng credential sai / endpoint down — request OK, test fail
      const errAny = err as { code?: string; message?: string; status?: number };
      const vnMessage =
        errAny.code
          ? `${errAny.message ?? 'Lỗi LGSP'} (Mã ${errAny.code})`
          : errAny.message ?? 'Không thể kết nối LGSP';
      res.json({
        success: true,
        data: {
          ok: false,
          message: vnMessage,
          http_status: errAny.status ?? 0,
          response_summary: null,
        },
      });
    }
  } catch (error) {
    handleDbError(error, res);
  }
});

// ------------------------------------------------------------
// GET /lgsp-overview — Dashboard summary aggregated per DN
//
// Trả về 6 row (1 per root unit có lgsp_org_code) + tổng quan today.
// Frontend Plan 37-04 render grid 6 cards + 3 stat cards (gửi/nhận/callback today).
// ------------------------------------------------------------
router.get('/lgsp-overview', requireOverview, async (_req: Request, res: Response) => {
  try {
    const rows = await lgspRepository.getOverviewStats();
    const totals = rows.reduce(
      (acc, r) => ({
        send_today: acc.send_today + Number(r.send_today_total ?? 0),
        send_success: acc.send_success + Number(r.send_today_success ?? 0),
        send_error: acc.send_error + Number(r.send_today_error ?? 0),
        receive_today: acc.receive_today + Number(r.receive_today_total ?? 0),
        outbox_pending: acc.outbox_pending + Number(r.outbox_today_pending ?? 0),
        outbox_error: acc.outbox_error + Number(r.outbox_today_error ?? 0),
        active_count:
          acc.active_count + (r.prod_is_active ? 1 : 0) + (r.sandbox_is_active ? 1 : 0),
      }),
      {
        send_today: 0,
        send_success: 0,
        send_error: 0,
        receive_today: 0,
        outbox_pending: 0,
        outbox_error: 0,
        active_count: 0,
      },
    );
    res.json({ success: true, data: { units: rows, totals } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ------------------------------------------------------------
// POST /inter-organizations/sync — Batch sync danh sách từ LGSP
//
// Lookup 1 DN có lgsp_agency_config.is_active=TRUE đầu tiên để dùng credential
// → gọi LGSP service syncOrganizations() (Phase 18 ILgspService method)
// → UPSERT vào edoc.inter_organizations qua existing CRUD methods.
// ------------------------------------------------------------
router.post('/inter-organizations/sync', requireCatalog, async (_req: Request, res: Response) => {
  try {
    // Lookup 1 DN active đầu tiên (any env) — Phase 33 cache hit tốt nếu trùng env đang dùng
    const allConfigs = await lgspAgencyConfigRepository.list();
    const activeConfig = allConfigs.find((c) => c.is_active);
    if (!activeConfig) {
      res.status(400).json({
        success: false,
        message:
          'Cần ít nhất 1 cấu hình LGSP đang bật (is_active=TRUE) để gọi sync danh sách cơ quan ngoài',
      });
      return;
    }

    const svc = await getLgspService(Number(activeConfig.unit_id), activeConfig.environment);
    const orgs = await svc.syncOrganizations();

    let created = 0;
    let updated = 0;
    let failed = 0;
    for (const org of orgs) {
      const existing = await interOrganizationRepository.findByCode(org.org_code);
      if (existing) {
        const r = await interOrganizationRepository.updateForAdmin(existing.id, {
          name: org.org_name,
          address: org.address,
          email: org.email,
          phone: org.phone,
          isActive: true,
        });
        if (r.success) updated++;
        else failed++;
      } else {
        const r = await interOrganizationRepository.createForAdmin({
          code: org.org_code,
          name: org.org_name,
          lgspOrganId: org.org_code,
          address: org.address,
          email: org.email,
          phone: org.phone,
          isActive: true,
        });
        if (r.success) created++;
        else failed++;
      }
    }

    res.json({
      success: true,
      message: `Đồng bộ thành công: thêm mới ${created}, cập nhật ${updated}${failed > 0 ? `, lỗi ${failed}` : ''}`,
      data: { total: orgs.length, created, updated, failed },
    });
  } catch (error) {
    handleDbError(error, res);
  }
});

export default router;
