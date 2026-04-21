/**
 * Route: /api/ky-so/danh-sach — Sign list cho user hiện tại (Phase 11 Plan 05).
 *
 * Endpoints (authenticate only — user nào cũng xem list của mình):
 *   GET  /         — Paginated list theo tab (need_sign / pending / completed / failed)
 *   GET  /counts   — 4 badge counts cho sidebar Phase 12
 *
 * Tab semantics:
 *   need_sign — VB/HSCV attachment PDF user có quyền ký, chưa ký, chưa có pending txn
 *                (backed by edoc.fn_sign_need_list_by_staff — Plan 11-05 migration 046)
 *   pending   — sign_transactions WHERE status='pending' AND staff_id = me
 *   completed — sign_transactions WHERE status='completed' AND staff_id = me
 *   failed    — sign_transactions WHERE status IN ('failed','expired','cancelled') AND staff_id = me
 *                (3 tab sau backed by edoc.fn_sign_transaction_list_by_staff — Plan 11-01 migration 045)
 *
 * Security (khớp threat model plan 11-05):
 *   - T-11-18 Info Disclosure: staffId LUÔN từ JWT (req.user.staffId), KHÔNG từ query
 *   - T-11-19 Elevation: isValidTab() allowlist chặn value lạ → 400 trước khi call SP
 *   - T-11-20 DoS: pageSize cap 100, page default 1 nếu non-numeric
 *
 * Response shape khác giữa tab:
 *   need_sign    → { attachment_id, attachment_type, file_name, doc_*, created_at }
 *   3 tab khác   → { transaction_id, provider_*, attachment_*, doc_*, status, error_message, created_at, completed_at }
 */

import { Router, type Request, type Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { handleDbError } from '../lib/error-handler.js';
import {
  attachmentSignRepository,
  type SignListTab,
} from '../repositories/attachment-sign.repository.js';

const router = Router();

// ============================================================================
// Constants / helpers
// ============================================================================

const VALID_TABS = ['need_sign', 'pending', 'completed', 'failed'] as const;
type ValidTab = typeof VALID_TABS[number];

function isValidTab(v: unknown): v is ValidTab {
  return typeof v === 'string' && (VALID_TABS as readonly string[]).includes(v);
}

const DEFAULT_PAGE_SIZE = 20;
const MAX_PAGE_SIZE = 100;

function parsePage(raw: unknown): number {
  const n = Number(raw);
  return Number.isFinite(n) && n >= 1 ? Math.floor(n) : 1;
}

function parsePageSize(raw: unknown): number {
  const n = Number(raw);
  if (!Number.isFinite(n) || n < 1) return DEFAULT_PAGE_SIZE;
  return Math.min(MAX_PAGE_SIZE, Math.floor(n));
}

// ============================================================================
// GET /counts — 4 badge counts for sidebar
// ============================================================================
// Ghép 2 SP: fn_sign_transaction_count_by_staff (pending/completed/failed)
// + fn_sign_need_count_by_staff (need_sign). Parallel call giảm latency.
// ============================================================================
router.get('/counts', async (req: Request, res: Response): Promise<void> => {
  try {
    const { staffId } = (req as AuthRequest).user;

    const [txnCounts, needCount] = await Promise.all([
      attachmentSignRepository.countByStaff(staffId),
      attachmentSignRepository.needCountByStaff(staffId),
    ]);

    res.json({
      success: true,
      data: {
        need_sign: Number(needCount ?? 0),
        pending: Number(txnCounts.pending_count ?? 0),
        completed: Number(txnCounts.completed_count ?? 0),
        failed: Number(txnCounts.failed_count ?? 0),
      },
    });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================================
// GET / — paginated list by tab
// Query: ?tab=need_sign|pending|completed|failed, page=1, page_size=20
// ============================================================================
router.get('/', async (req: Request, res: Response): Promise<void> => {
  try {
    const { staffId } = (req as AuthRequest).user;

    // Tab validation BEFORE DB call (T-11-19 Elevation)
    const tabRaw = String(req.query.tab ?? 'need_sign');
    if (!isValidTab(tabRaw)) {
      res.status(400).json({
        success: false,
        message: `Tham số tab phải là một trong: ${VALID_TABS.join(', ')}`,
      });
      return;
    }

    const page = parsePage(req.query.page);
    const pageSize = parsePageSize(req.query.page_size);

    // --------------------------------------------------------------------
    // Branch 1: need_sign — attachment-level rows, no transaction_id
    // --------------------------------------------------------------------
    if (tabRaw === 'need_sign') {
      const rows = await attachmentSignRepository.needListByStaff(
        staffId,
        page,
        pageSize,
      );
      const total = Number(rows[0]?.total_count ?? 0);

      res.json({
        success: true,
        data: rows.map((r) => ({
          attachment_id: Number(r.attachment_id),
          attachment_type: r.attachment_type,
          file_name: r.file_name,
          doc_id: r.doc_id !== null ? Number(r.doc_id) : null,
          doc_type: r.doc_type,
          doc_label: r.doc_label,
          doc_number: r.doc_number,
          doc_notation: r.doc_notation,
          created_at: r.created_at,
        })),
        pagination: { total, page, pageSize },
      });
      return;
    }

    // --------------------------------------------------------------------
    // Branch 2: pending | completed | failed — transaction-level rows
    // --------------------------------------------------------------------
    const tab: SignListTab = tabRaw as SignListTab;
    const rows = await attachmentSignRepository.listByStaff(
      staffId,
      tab,
      page,
      pageSize,
    );
    const total = Number(rows[0]?.total_count ?? 0);

    res.json({
      success: true,
      data: rows.map((r) => ({
        transaction_id: Number(r.id),
        provider_code: r.provider_code,
        provider_name: r.provider_name,
        attachment_id: Number(r.attachment_id),
        attachment_type: r.attachment_type,
        file_name: r.file_name,
        doc_id: r.doc_id !== null ? Number(r.doc_id) : null,
        doc_type: r.doc_type,
        doc_label: r.doc_label,
        status: r.status,
        error_message: r.error_message,
        created_at: r.created_at,
        completed_at: r.completed_at,
      })),
      pagination: { total, page, pageSize },
    });
  } catch (error) {
    handleDbError(error, res);
  }
});

export default router;
