/**
 * Route: /api/ky-so/cau-hinh* — Admin config cho 2 provider ký số.
 *
 * 5 endpoints active (all require role 'Quản trị hệ thống', mount trong server.ts):
 *   GET    /                       — list 2 providers + stats + mask secret + has_secret flag
 *   POST   /test-connection        — test credentials (không persist DB)
 *   POST   /:id/test-saved         — test config đã lưu trong DB (decrypt + persist result)
 *   PUT    /:id                    — update config (re-encrypt nếu có secret mới)
 *   PATCH  /:id/active             — set active (auto-deactivate others)
 *
 * 2 endpoints DISABLED (fix patch Phase 9 Plan 03 — chỉ có 2 provider cố định):
 *   POST   /                       — 405 Method Not Allowed
 *   DELETE /:id                    — 405 Method Not Allowed
 *
 * LÝ DO disable POST + DELETE:
 *   Hệ thống CHỈ hỗ trợ 2 provider cố định (SmartCA VNPT + MySign Viettel) — được
 *   seed sẵn bởi migration 043. Admin KHÔNG tạo/xóa provider mới, chỉ sửa 2 row
 *   có sẵn qua PUT + kích hoạt qua PATCH.
 *
 * SECURITY boundary (T-09-07 Information Disclosure):
 *   - Body PUT nhận PLAINTEXT `client_secret` → encryptSecret() TRƯỚC khi
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
import { encryptSecret, decryptSecret } from '../services/signing/crypto.js';
import { getProviderByCode } from '../services/signing/providers/provider-factory.js';
import type { ProviderCode } from '../services/signing/providers/provider.interface.js';
import { rawQuery } from '../lib/db/query.js';
import { handleDbError } from '../lib/error-handler.js';

/**
 * Sentinel plaintext dùng trong migration 043 để seed provider "chưa cấu hình"
 * (MySign Viettel mặc định). Provider có ciphertext decrypt ra string này → UI
 * hiển thị is "chưa cấu hình" và KHÔNG cho test với saved secret.
 */
const PLACEHOLDER_SECRET = 'placeholder_not_configured';

const router = Router();

// ============================================================================
// Constants
// ============================================================================

const VALID_CODES: ProviderCode[] = ['SMARTCA_VNPT', 'MYSIGN_VIETTEL'];

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

/**
 * Check provider có "secret thật" hay không:
 *   - base_url + client_id PHẢI non-empty
 *   - decrypted secret PHẢI khác sentinel PLACEHOLDER_SECRET (migration 043 seed)
 *
 * Ignore decrypt errors → trả false (an toàn, tránh leak lỗi crypto qua GET list).
 */
async function detectHasSecret(row: SigningProviderConfigFullRow): Promise<boolean> {
  if (!row.base_url || row.base_url.trim() === '') return false;
  if (!row.client_id || row.client_id.trim() === '') return false;
  if (!Buffer.isBuffer(row.client_secret) || row.client_secret.length === 0) return false;
  try {
    const plain = await decryptSecret(row.client_secret);
    return plain !== PLACEHOLDER_SECRET && plain.trim().length >= 8;
  } catch {
    return false;
  }
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

    // Enforce data integrity: 2 provider cố định PHẢI tồn tại (seed bởi migration 043).
    // Nếu thiếu → DB chưa seed đúng → trả 500 để Admin biết phải chạy migration.
    const missingCodes = VALID_CODES.filter((code) => !byCode.has(code));
    if (missingCodes.length > 0) {
      res.status(500).json({
        success: false,
        message:
          'Database chưa seed provider mặc định. Chạy migration 043_seed_default_providers.sql '
          + `(thiếu: ${missingCodes.join(', ')}).`,
      });
      return;
    }

    // Compute stats + has_secret flag in parallel cho 2 providers.
    // has_secret = provider có base_url + client_id + decrypted secret KHÁC placeholder
    // (migration 043 seed MySign với sentinel 'placeholder_not_configured').
    const [statsSmartca, statsMysign, fullSmartca, fullMysign] = await Promise.all([
      getStatsForProvider('SMARTCA_VNPT'),
      getStatsForProvider('MYSIGN_VIETTEL'),
      signingProviderConfigRepository.getByCode('SMARTCA_VNPT'),
      signingProviderConfigRepository.getByCode('MYSIGN_VIETTEL'),
    ]);
    const statsByCode: Record<string, StatsRow> = {
      SMARTCA_VNPT: statsSmartca,
      MYSIGN_VIETTEL: statsMysign,
    };
    const fullByCode: Record<string, SigningProviderConfigFullRow | null> = {
      SMARTCA_VNPT: fullSmartca,
      MYSIGN_VIETTEL: fullMysign,
    };

    // detectHasSecret decrypt BYTEA → tính toán tuần tự cho 2 row (nhanh vì chỉ 2 call)
    const hasSecretSmartca = fullSmartca ? await detectHasSecret(fullSmartca) : false;
    const hasSecretMysign = fullMysign ? await detectHasSecret(fullMysign) : false;
    const hasSecretByCode: Record<string, boolean> = {
      SMARTCA_VNPT: hasSecretSmartca,
      MYSIGN_VIETTEL: hasSecretMysign,
    };

    let activeCode: ProviderCode | null = null;
    const providers = VALID_CODES.map((code) => {
      const row = byCode.get(code)!; // non-null guaranteed by missingCodes check above
      if (row.is_active) activeCode = code;
      const hasSecret = hasSecretByCode[code] ?? false;
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
        has_secret: hasSecret,
        client_secret_masked: hasSecret ? '***' : null,
        stats: statsByCode[code] ?? EMPTY_STATS,
      };
    });
    // Suppress unused-warn: fullByCode retained cho tương lai (debug/log), explicit reference
    void fullByCode;

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
// 2b. POST /:id/test-saved — test với credentials đã lưu trong DB (không cần user nhập)
// ============================================================================

/**
 * Test connection cho provider đã cấu hình: đọc ciphertext từ DB → decrypt →
 * gọi `provider.testConnection()`. Sau khi test, UPDATE `last_tested_at` +
 * `test_result` để UI hiển thị đúng trạng thái.
 *
 * Khác với /test-connection (body chứa plaintext credentials): endpoint này chỉ
 * cần id provider — credentials lấy từ DB. Dùng khi Admin muốn verify config đã
 * lưu từ trước còn hoạt động (VD: reconnect sau khi provider rotate key bên họ,
 * hoặc check định kỳ).
 *
 * Guard: nếu provider chưa cấu hình (base_url/client_id rỗng hoặc secret là
 * placeholder) → trả 400 với thông báo hướng dẫn Admin nhập credentials trước.
 */
router.post('/:id/test-saved', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) {
      res.status(400).json({ success: false, message: 'ID không hợp lệ' });
      return;
    }

    // Lookup provider_code từ id trước (SP getByCode không có by id)
    interface CodeRow { provider_code: string; }
    const idRows = await rawQuery<CodeRow>(
      'SELECT provider_code FROM public.signing_provider_config WHERE id = $1',
      [id],
    );
    if (idRows.length === 0) {
      res.status(404).json({ success: false, message: 'Không tìm thấy cấu hình' });
      return;
    }
    const providerCode = idRows[0].provider_code;

    if (!validateProviderCode(providerCode)) {
      res.status(400).json({ success: false, message: 'provider_code không hợp lệ' });
      return;
    }

    // Lấy full config (bao gồm client_secret BYTEA) từ DB
    const existing: SigningProviderConfigFullRow | null =
      await signingProviderConfigRepository.getByCode(providerCode);
    if (!existing) {
      res.status(404).json({ success: false, message: 'Không tìm thấy cấu hình' });
      return;
    }

    // Guard: chưa cấu hình đủ (base_url hoặc client_id rỗng)
    if (!existing.base_url || existing.base_url.trim() === ''
        || !existing.client_id || existing.client_id.trim() === '') {
      res.status(400).json({
        success: false,
        message:
          'Provider chưa cấu hình, vui lòng nhập Base URL + Client ID + Client Secret '
          + 'trước khi test',
      });
      return;
    }

    // Decrypt secret; nếu cipher không hợp lệ hoặc là placeholder → 400
    let plaintextSecret: string;
    try {
      plaintextSecret = await decryptSecret(existing.client_secret);
    } catch {
      res.status(400).json({
        success: false,
        message:
          'Không giải mã được Client Secret đã lưu (có thể SIGNING_SECRET_KEY đã đổi). '
          + 'Vui lòng nhập lại Client Secret qua form Sửa.',
      });
      return;
    }
    if (plaintextSecret === PLACEHOLDER_SECRET || plaintextSecret.trim().length < 8) {
      res.status(400).json({
        success: false,
        message:
          'Provider chưa cấu hình, vui lòng nhập Base URL + Client ID + Client Secret '
          + 'trước khi test',
      });
      return;
    }

    const provider = getProviderByCode(providerCode);
    const startedAt = Date.now();

    let result;
    try {
      result = await provider.testConnection({
        baseUrl: existing.base_url.trim(),
        clientId: existing.client_id.trim(),
        clientSecretPlaintext: plaintextSecret,
        profileId: existing.profile_id ?? null,
      });
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Lỗi không xác định';
      // Persist failed result (để UI badge "Lỗi kết nối")
      try {
        await rawQuery(
          `UPDATE public.signing_provider_config
             SET last_tested_at = NOW(), test_result = $1, updated_by = $2, updated_at = NOW()
             WHERE id = $3`,
          [`FAILED: ${msg}`.slice(0, 1000), staffId, id],
        );
      } catch {
        // Ignore persistence error — primary error đã trả về client
      }
      res.status(502).json({
        success: false,
        message: 'Không kết nối được provider: ' + msg,
      });
      return;
    }

    const durationMs = Date.now() - startedAt;
    const testResultStr = result.success ? 'OK' : `FAILED: ${result.message}`.slice(0, 1000);

    // Persist `last_tested_at` + `test_result` để UI card reflect đúng
    try {
      await rawQuery(
        `UPDATE public.signing_provider_config
           SET last_tested_at = NOW(), test_result = $1, updated_by = $2, updated_at = NOW()
           WHERE id = $3`,
        [testResultStr, staffId, id],
      );
    } catch {
      // Persistence lỗi không fatal — test result vẫn trả về cho UI
    }

    res.json({
      success: true,
      data: {
        ok: result.success,
        test_result: result.success ? 'OK' : 'FAILED',
        message: result.message,
        certificate_subject: result.certificateSubject ?? null,
        duration_ms: durationMs,
      },
    });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================================
// 3. POST / — DISABLED (fix patch 09-03): chỉ có 2 provider cố định
// ============================================================================

router.post('/', (_req: Request, res: Response) => {
  res.status(405).json({
    success: false,
    message:
      'Không được tạo provider mới — hệ thống chỉ hỗ trợ 2 provider cố định '
      + '(SmartCA VNPT + MySign Viettel). Vui lòng dùng PUT để cập nhật cấu hình.',
  });
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
// 6. DELETE /:id — DISABLED (fix patch 09-03): provider cố định không cho xóa
// ============================================================================

router.delete('/:id', (_req: Request, res: Response) => {
  res.status(405).json({
    success: false,
    message:
      'Không được xóa provider cố định — hệ thống chỉ hỗ trợ 2 provider '
      + '(SmartCA VNPT + MySign Viettel). Nếu muốn tạm dừng, hãy kích hoạt provider khác.',
  });
});

export default router;
