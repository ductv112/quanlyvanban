/**
 * Route: /api/ky-so/cau-hinh* — Admin config cho 2 provider ký số.
 *
 * 6 endpoints (all require role 'Quản trị hệ thống', mount trong server.ts):
 *   GET    /                       — list 2 providers + stats + mask secret
 *   POST   /test-connection        — test credentials (không persist DB)
 *   POST   /                       — upsert provider config (encrypt secret)
 *   PUT    /:id                    — update config (re-encrypt nếu có secret mới)
 *   PATCH  /:id/active             — set active (auto-deactivate others)
 *   DELETE /:id                    — delete config (block nếu đang active)
 *
 * SECURITY boundary (T-09-07 Information Disclosure):
 *   - Body POST/PUT nhận PLAINTEXT `client_secret` → encryptSecret() TRƯỚC khi
 *     gọi repository.upsert() → repository nhận BYTEA Buffer → lưu DB.
 *   - Response KHÔNG BAO GIỜ chứa key `client_secret` — chỉ `client_secret_masked: '***'`.
 *   - Admin UI hiển thị '***' + placeholder "Nhập để thay đổi" — user submit bỏ trống
 *     thì PUT handler giữ nguyên ciphertext cũ (reuse existing Buffer).
 *
 * Test-connection dispatcher pattern:
 *   - Dùng getProviderByCode(provider_code) PURE dispatcher — không cần DB lookup
 *     (credentials đến từ body). Cho phép Admin thử credentials TRƯỚC khi lưu.
 */

import { Router } from 'express';
import type { Request, Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import {
  signingProviderConfigRepository,
  type SigningProviderConfigListRow,
  type SigningProviderConfigFullRow,
} from '../repositories/signing-provider-config.repository.js';
import { encryptSecret } from '../services/signing/crypto.js';
import { getProviderByCode } from '../services/signing/providers/provider-factory.js';
import type { ProviderCode } from '../services/signing/providers/provider.interface.js';
import { rawQuery } from '../lib/db/query.js';
import { handleDbError } from '../lib/error-handler.js';

const router = Router();

// ============================================================================
// Constants
// ============================================================================

const VALID_CODES: ProviderCode[] = ['SMARTCA_VNPT', 'MYSIGN_VIETTEL'];

const PROVIDER_NAMES: Record<ProviderCode, string> = {
  SMARTCA_VNPT: 'SmartCA VNPT',
  MYSIGN_VIETTEL: 'MySign Viettel',
};

// ============================================================================
// Helpers
// ============================================================================

interface StatsRow {
  total_users: number;
  verified_users: number;
  monthly_transactions: number;
  monthly_completed: number;
  monthly_failed: number;
}

const EMPTY_STATS: StatsRow = {
  total_users: 0,
  verified_users: 0,
  monthly_transactions: 0,
  monthly_completed: 0,
  monthly_failed: 0,
};

async function getStatsForProvider(code: string): Promise<StatsRow> {
  const rows = await rawQuery<StatsRow>(
    'SELECT * FROM public.fn_signing_stats($1)',
    [code],
  );
  return rows[0] ?? EMPTY_STATS;
}

function validateProviderCode(code: unknown): code is ProviderCode {
  return typeof code === 'string' && (VALID_CODES as readonly string[]).includes(code);
}

/** Validate base URL: HTTPS mandatory except localhost (dev mock server) */
function validateBaseUrl(url: unknown): string | null {
  if (typeof url !== 'string' || !url.trim()) return 'base_url là bắt buộc';
  const trimmed = url.trim();
  if (!trimmed.startsWith('https://') && !trimmed.startsWith('http://localhost')) {
    return 'base_url phải là HTTPS (trừ localhost)';
  }
  return null;
}

/** Non-empty trimmed string check */
function isNonEmptyString(v: unknown, maxLen = 500): v is string {
  return typeof v === 'string' && v.trim().length > 0 && v.trim().length <= maxLen;
}

// ============================================================================
// 1. GET /  — list providers (always 2 rows) + stats + mask
// ============================================================================

router.get('/', async (_req: Request, res: Response) => {
  try {
    const existing = await signingProviderConfigRepository.list();
    const byCode = new Map<string, SigningProviderConfigListRow>();
    for (const row of existing) {
      byCode.set(row.provider_code, row);
    }

    // Compute stats in parallel for 2 providers
    const [statsSmartca, statsMysign] = await Promise.all([
      getStatsForProvider('SMARTCA_VNPT'),
      getStatsForProvider('MYSIGN_VIETTEL'),
    ]);
    const statsByCode: Record<string, StatsRow> = {
      SMARTCA_VNPT: statsSmartca,
      MYSIGN_VIETTEL: statsMysign,
    };

    let activeCode: ProviderCode | null = null;
    const providers = VALID_CODES.map((code) => {
      const row = byCode.get(code);
      if (row?.is_active) activeCode = code;
      if (row) {
        return {
          id: row.id,
          provider_code: row.provider_code,
          provider_name: row.provider_name,
          base_url: row.base_url,
          client_id: row.client_id,
          profile_id: row.profile_id,
          extra_config: row.extra_config ?? {},
          is_active: row.is_active,
          last_tested_at: row.last_tested_at,
          test_result: row.test_result,
          created_at: row.created_at,
          updated_at: row.updated_at,
          has_secret: true,
          client_secret_masked: '***',
          stats: statsByCode[code] ?? EMPTY_STATS,
        };
      }
      // Never-configured provider: return skeleton so UI can render both rows
      return {
        id: null,
        provider_code: code,
        provider_name: PROVIDER_NAMES[code],
        base_url: null,
        client_id: null,
        profile_id: null,
        extra_config: {},
        is_active: false,
        last_tested_at: null,
        test_result: null,
        created_at: null,
        updated_at: null,
        has_secret: false,
        client_secret_masked: null,
        stats: statsByCode[code] ?? EMPTY_STATS,
      };
    });

    res.json({
      success: true,
      data: {
        providers,
        active_code: activeCode,
      },
    });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================================
// 2. POST /test-connection — test credentials without persisting
// ============================================================================

router.post('/test-connection', async (req: Request, res: Response) => {
  try {
    const body = req.body ?? {};

    if (!validateProviderCode(body.provider_code)) {
      res.status(400).json({ success: false, message: 'provider_code không hợp lệ' });
      return;
    }
    const urlErr = validateBaseUrl(body.base_url);
    if (urlErr) {
      res.status(400).json({ success: false, message: urlErr });
      return;
    }
    if (!isNonEmptyString(body.client_id, 200)) {
      res.status(400).json({ success: false, message: 'client_id là bắt buộc' });
      return;
    }
    if (typeof body.client_secret !== 'string' || body.client_secret.length < 1) {
      res.status(400).json({ success: false, message: 'client_secret là bắt buộc' });
      return;
    }

    const provider = getProviderByCode(body.provider_code);

    let result;
    try {
      result = await provider.testConnection({
        baseUrl: body.base_url.trim(),
        clientId: body.client_id.trim(),
        clientSecretPlaintext: body.client_secret,
        profileId: typeof body.profile_id === 'string' ? body.profile_id.trim() : null,
      });
    } catch (err: unknown) {
      // Network / timeout / axios-like error — adapter's testConnection should
      // return {success:false} but we add a safety net here.
      const msg = err instanceof Error ? err.message : 'Lỗi không xác định';
      res.status(502).json({
        success: false,
        message: 'Không kết nối được provider: ' + msg,
      });
      return;
    }

    res.json({
      success: true,
      data: {
        test_result: result.success ? 'OK' : 'FAILED',
        message: result.message,
        certificate_subject: result.certificateSubject ?? null,
      },
    });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================================
// 3. POST / — upsert provider config (encrypt secret, optional set_active)
// ============================================================================

router.post('/', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const body = req.body ?? {};

    if (!validateProviderCode(body.provider_code)) {
      res.status(400).json({ success: false, message: 'provider_code không hợp lệ' });
      return;
    }
    if (!isNonEmptyString(body.provider_name, 100)) {
      res.status(400).json({ success: false, message: 'provider_name là bắt buộc (≤ 100 ký tự)' });
      return;
    }
    const urlErr = validateBaseUrl(body.base_url);
    if (urlErr) {
      res.status(400).json({ success: false, message: urlErr });
      return;
    }
    if (!isNonEmptyString(body.client_id, 200)) {
      res.status(400).json({ success: false, message: 'client_id là bắt buộc (≤ 200 ký tự)' });
      return;
    }
    if (typeof body.client_secret !== 'string' || body.client_secret.length < 8) {
      res.status(400).json({ success: false, message: 'client_secret tối thiểu 8 ký tự' });
      return;
    }

    // Encrypt PLAINTEXT → BYTEA immediately (T-09-07 boundary)
    const cipher = await encryptSecret(body.client_secret);

    const upsertResult = await signingProviderConfigRepository.upsert({
      providerCode: body.provider_code,
      providerName: body.provider_name.trim(),
      baseUrl: body.base_url.trim(),
      clientId: body.client_id.trim(),
      clientSecret: cipher,
      profileId: typeof body.profile_id === 'string' && body.profile_id.trim() !== ''
        ? body.profile_id.trim()
        : null,
      extraConfig: body.extra_config && typeof body.extra_config === 'object'
        ? body.extra_config
        : {},
      lastTestedAt: null,
      testResult: null,
      updatedBy: staffId,
    });

    if (!upsertResult.success) {
      res.status(400).json({ success: false, message: upsertResult.message });
      return;
    }

    // Optional activate after save
    if (body.set_active === true) {
      const activateResult = await signingProviderConfigRepository.setActive(
        body.provider_code,
        staffId,
      );
      if (!activateResult.success) {
        // Config saved but activation failed — return 201 but warn in message
        res.status(201).json({
          success: true,
          message: 'Lưu cấu hình thành công. Kích hoạt thất bại: ' + activateResult.message,
          data: { id: upsertResult.id },
        });
        return;
      }
    }

    res.status(201).json({
      success: true,
      message: 'Lưu cấu hình thành công',
      data: { id: upsertResult.id },
    });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================================
// 4. PUT /:id — update existing (re-encrypt only if new secret provided)
// ============================================================================

router.put('/:id', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) {
      res.status(400).json({ success: false, message: 'ID không hợp lệ' });
      return;
    }
    const body = req.body ?? {};

    if (!validateProviderCode(body.provider_code)) {
      res.status(400).json({ success: false, message: 'provider_code không hợp lệ' });
      return;
    }
    if (!isNonEmptyString(body.provider_name, 100)) {
      res.status(400).json({ success: false, message: 'provider_name là bắt buộc' });
      return;
    }
    const urlErr = validateBaseUrl(body.base_url);
    if (urlErr) {
      res.status(400).json({ success: false, message: urlErr });
      return;
    }
    if (!isNonEmptyString(body.client_id, 200)) {
      res.status(400).json({ success: false, message: 'client_id là bắt buộc' });
      return;
    }

    // Existing row lookup — need current encrypted secret if body omits it
    const existing: SigningProviderConfigFullRow | null =
      await signingProviderConfigRepository.getByCode(body.provider_code);
    if (!existing || existing.id !== id) {
      res.status(404).json({ success: false, message: 'Không tìm thấy cấu hình' });
      return;
    }

    // Re-encrypt only if client_secret provided (non-empty string ≥ 8 chars)
    let cipher = existing.client_secret;
    if (typeof body.client_secret === 'string' && body.client_secret.length > 0) {
      if (body.client_secret.length < 8) {
        res.status(400).json({ success: false, message: 'client_secret tối thiểu 8 ký tự' });
        return;
      }
      cipher = await encryptSecret(body.client_secret);
    }

    const upsertResult = await signingProviderConfigRepository.upsert({
      providerCode: body.provider_code,
      providerName: body.provider_name.trim(),
      baseUrl: body.base_url.trim(),
      clientId: body.client_id.trim(),
      clientSecret: cipher,
      profileId: typeof body.profile_id === 'string' && body.profile_id.trim() !== ''
        ? body.profile_id.trim()
        : null,
      extraConfig: body.extra_config && typeof body.extra_config === 'object'
        ? body.extra_config
        : (existing.extra_config ?? {}),
      lastTestedAt: existing.last_tested_at,
      testResult: existing.test_result,
      updatedBy: staffId,
    });

    if (!upsertResult.success) {
      res.status(400).json({ success: false, message: upsertResult.message });
      return;
    }

    res.json({ success: true, message: 'Cập nhật thành công' });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================================
// 5. PATCH /:id/active — set this provider active (auto-deactivate others)
// ============================================================================

router.patch('/:id/active', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) {
      res.status(400).json({ success: false, message: 'ID không hợp lệ' });
      return;
    }

    // Look up provider_code from id (setActive SP takes provider_code, not id)
    interface CodeRow { provider_code: string; }
    const rows = await rawQuery<CodeRow>(
      'SELECT provider_code FROM public.signing_provider_config WHERE id = $1',
      [id],
    );
    if (rows.length === 0) {
      res.status(404).json({ success: false, message: 'Không tìm thấy cấu hình' });
      return;
    }

    const activateResult = await signingProviderConfigRepository.setActive(
      rows[0].provider_code,
      staffId,
    );
    if (!activateResult.success) {
      res.status(400).json({ success: false, message: activateResult.message });
      return;
    }

    res.json({ success: true, message: 'Kích hoạt provider thành công' });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================================
// 6. DELETE /:id — delete config (block if currently active)
// ============================================================================

router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) {
      res.status(400).json({ success: false, message: 'ID không hợp lệ' });
      return;
    }

    interface ActiveRow { is_active: boolean; }
    const rows = await rawQuery<ActiveRow>(
      'SELECT is_active FROM public.signing_provider_config WHERE id = $1',
      [id],
    );
    if (rows.length === 0) {
      res.status(404).json({ success: false, message: 'Không tìm thấy cấu hình' });
      return;
    }
    if (rows[0].is_active) {
      res.status(409).json({
        success: false,
        message: 'Không thể xóa provider đang được kích hoạt. Vui lòng chuyển sang provider khác trước.',
      });
      return;
    }

    await rawQuery(
      'DELETE FROM public.signing_provider_config WHERE id = $1',
      [id],
    );

    res.json({ success: true, message: 'Xóa thành công' });
  } catch (error) {
    handleDbError(error, res);
  }
});

export default router;
