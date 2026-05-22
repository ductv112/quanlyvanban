import { Router, type Request, type Response } from 'express';
import { type AuthRequest, requireRightOrNext } from '../middleware/auth.js';
import { lgspRepository } from '../repositories/lgsp.repository.js';
import { enqueueReceiveTick } from '../lib/queue/lgsp-receive-queue.js';
import { handleDbError } from '../lib/error-handler.js';
import { parseIdParam } from '../lib/param-validation.js';

// Phase 37.1 + Phase 37.4 fix: granular permission per route
// RIGHT_LGSP_OVERVIEW (id=24) = /lgsp dashboard + sync-now + tracking read
// RIGHT_LGSP_CATALOG (id=25) = /lgsp/co-quan inter_organizations CRUD + sync
const requireOverview = requireRightOrNext(24);
const requireCatalog = requireRightOrNext(25);

const router = Router();

// ============================================================
// Phase 37.4 fix #3: POST /gui-lien-thong DEPRECATED 410 Gone
// Phase 18 cu enqueue job shape KHONG tuong thich worker moi
// (worker expect {recipient_id, sender_unit_id, environment} - Phase 34 contract).
// User goi nham endpoint nay -> tracking pending forever, job die im lang.
//
// Migration: dung flow Phase 34 — POST /api/van-ban-di/:id/gui-noi-bo (auto fire LGSP
// send job qua addLgspSendJob khi recipient_type='external_org').
// ============================================================
router.post('/gui-lien-thong', (_req: Request, res: Response) => {
  res.status(410).json({
    success: false,
    message:
      'Endpoint nay da deprecated (Phase 37.4). ' +
      'Dung POST /api/van-ban-di/:id/gui-noi-bo voi recipient_type=external_org ' +
      '(flow Phase 34 - auto fire LGSP send job).',
  });
});

// ============================================================
// GET /tracking — Danh sach tracking lien thong (Phase 37.4: requireOverview)
// Query: direction, status, page, pageSize
// ============================================================
router.get('/tracking', requireOverview, async (req: Request, res: Response) => {
  try {
    const { direction, status, page, pageSize } = req.query;

    const rows = await lgspRepository.getTrackingList(
      (direction as string) || null,
      (status as string) || null,
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
// GET /tracking/doc/:outgoingDocId — Tracking theo van ban di (Phase 37.4: requireOverview)
// ============================================================
router.get('/tracking/doc/:outgoingDocId', requireOverview, async (req: Request, res: Response) => {
  try {
    const outgoingDocId = parseIdParam(req, res, 'outgoingDocId');
    if (outgoingDocId === null) return;
    const rows = await lgspRepository.getTrackingByDoc(outgoingDocId);
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// GET /organizations — Danh sach co quan lien thong (Phase 37.4: requireCatalog)
// Query: search, page, pageSize
// ============================================================
router.get('/organizations', requireCatalog, async (req: Request, res: Response) => {
  try {
    const { search, page, pageSize } = req.query;

    const rows = await lgspRepository.getOrgList(
      (search as string) || null,
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
// Phase 37.4 fix #3: POST /organizations/sync DEPRECATED 410 Gone
// Endpoint moi: POST /api/admin/inter-organizations/sync (Phase 37 admin namespace,
// dung interOrganizationRepository.upsertFromLgsp - parse pagination shape moi).
// Endpoint cu day ghi schema cu (lgspRepository.syncOrg) - co the conflict data.
// ============================================================
router.post('/organizations/sync', (_req: Request, res: Response) => {
  res.status(410).json({
    success: false,
    message:
      'Endpoint nay da deprecated (Phase 37.4). ' +
      'Dung POST /api/admin/inter-organizations/sync (admin namespace - granular permission).',
  });
});

// ============================================================
// POST /sync-now - Admin manual trigger LGSP receive sync (Phase 35 Plan 03)
// Enqueues a 'receive-tick' job which spawns N 'receive-dn' child jobs
// (1 per active DN in lgsp_agency_config). Useful when admin doesn't want
// to wait for the 5-min cron interval (e.g. just after enabling a new DN).
//
// Returns 202 Accepted immediately - actual sync happens async via BullMQ.
// Phase 37 admin UI will add a "Sync ngay" button that hits this route.
//
// Role check: 'Quan tri he thong' (real DB role name, see public.roles).
// Plan text says 'admin' but the project uses Vietnamese role names; using
// the actual role name keeps the auth gate functional.
// ============================================================
router.post(
  '/sync-now',
  requireOverview, // Phase 37.1: granular right_id=24 thay vi requireRoles('Quan tri he thong')
  async (req: Request, res: Response) => {
    try {
      const { staffId } = (req as AuthRequest).user;
      const jobId = await enqueueReceiveTick({
        trigger_source: 'manual',
        triggered_by_staff_id: staffId,
      });
      res.status(202).json({
        success: true,
        message: 'Da xep hang dong bo LGSP - worker se chay trong giay lat',
        job_id: jobId,
      });
    } catch (error) {
      handleDbError(error, res);
    }
  },
);

// ============================================================
// POST /receive-poll - Phase 18 deprecated, forwards to /sync-now (Plan 35-03)
//
// Phase 18 inline receive-poll handler removed - the new BullMQ
// async pipeline via /sync-now replaces it. Kept here as 1-month deprecation
// window for any admin scripts that still call /receive-poll. Phase 37 will
// fully remove this forward.
// ============================================================
router.post(
  '/receive-poll',
  requireOverview, // Phase 37.1: granular right_id=24 thay vi requireRoles
  async (req: Request, res: Response) => {
    try {
      const { staffId } = (req as AuthRequest).user;
      const jobId = await enqueueReceiveTick({
        trigger_source: 'manual',
        triggered_by_staff_id: staffId,
      });
      res.status(202).json({
        success: true,
        message: 'DEPRECATED: use POST /api/lgsp/sync-now. Da xep hang dong bo.',
        job_id: jobId,
        deprecated: true,
      });
    } catch (error) {
      handleDbError(error, res);
    }
  },
);

export default router;
