/**
 * Route: /api/ky-so/tai-khoan* — User-level signing config (CFG-05, CFG-06).
 *
 * 4 endpoints, `authenticate` middleware ONLY (không requireRoles — mọi user
 * quản lý config cá nhân của chính họ):
 *   GET    /             — lấy config hiện tại + active provider metadata
 *   POST   /             — upsert config user (user_id + optional credential_id)
 *   POST   /certificates — list cert từ provider (MySign — "Tải danh sách CTS")
 *   POST   /verify       — verify config bằng listCertificates + lưu cert snapshot
 *
 * SECURITY — T-10-01 Tampering:
 *   staffId LUÔN lấy từ JWT (`req.user.staffId`), KHÔNG BAO GIỜ từ body. User A
 *   KHÔNG THỂ update / verify / đọc config của user B vì JWT payload là nguồn
 *   duy nhất của staffId.
 *
 * SECURITY — T-10-02 Elevation of Privilege:
 *   Route này mount với `authenticate` only (KHÔNG requireRoles) — xem server.ts.
 *   Đặt BEFORE `/api/ky-so` generic để request `/tai-khoan/*` rơi vào router này
 *   chứ không phải digital-signature routes. Admin guard cho `/cau-hinh` mount
 *   riêng, không leak sang đây.
 *
 * SECURITY — T-10-03/04 Information Disclosure:
 *   GET / response KHÔNG trả `certificate_data` (TEXT base64 ~2-4KB) — chỉ
 *   subject/serial/is_verified đủ cho UI. POST /certificates map
 *   `toClientCert()` cũng loại bỏ `certificateBase64` khỏi payload list.
 */

import { Router } from 'express';
import type { Request, Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { staffSigningConfigRepository } from '../repositories/staff-signing-config.repository.js';
import { getActiveProviderWithCredentials } from '../services/signing/providers/provider-factory.js';
import type { CertificateInfo } from '../services/signing/providers/provider.interface.js';
import { handleDbError } from '../lib/error-handler.js';

const router = Router();

// ============================================================================
// Constants
// ============================================================================

const PROVIDER_NAMES: Record<string, string> = {
  SMARTCA_VNPT: 'SmartCA VNPT',
  MYSIGN_VIETTEL: 'MySign Viettel',
};

// ============================================================================
// Helpers
// ============================================================================

/** Non-empty trimmed string check (mặc định max 200 ký tự theo schema VARCHAR) */
function isNonEmptyString(v: unknown, maxLen = 200): v is string {
  return typeof v === 'string' && v.trim().length > 0 && v.trim().length <= maxLen;
}

/**
 * Map CertificateInfo (camelCase từ adapter) → snake_case shape cho FE.
 *
 * Loại bỏ `certificateBase64` (T-10-04 Information Disclosure) — list UI chỉ cần
 * subject/serial/valid_to để hiển thị Select option, không cần cert public key.
 */
function toClientCert(c: CertificateInfo) {
  return {
    credential_id: c.credentialId,
    subject: c.subject,
    serial_number: c.serialNumber,
    valid_from: c.validFrom,
    valid_to: c.validTo,
    status: c.status,
  };
}

// ============================================================================
// 1. GET / — lấy active provider metadata + user config hiện tại
// ============================================================================

/**
 * Response shape:
 *   - Admin chưa kích hoạt provider → { active: null, config: null, message: "..." }
 *   - Provider active OK nhưng user chưa có config → { active: {...}, config: null }
 *   - Provider active OK + user có config → { active: {...}, config: {...} }
 *
 * Không trả `certificate_data` (TEXT ~base64) — UI không cần hiển thị raw cert.
 */
router.get('/', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;

    const active = await getActiveProviderWithCredentials();
    if (!active) {
      res.json({
        success: true,
        data: {
          active: null,
          config: null,
          message:
            'Admin chưa kích hoạt provider ký số nào. Vui lòng liên hệ Quản trị viên.',
        },
      });
      return;
    }

    const providerCode = active.provider.code;
    const providerName = PROVIDER_NAMES[providerCode] ?? providerCode;

    const config = await staffSigningConfigRepository.get(staffId, providerCode);

    res.json({
      success: true,
      data: {
        active: {
          provider_code: providerCode,
          provider_name: providerName,
          base_url: active.credentials.baseUrl,
        },
        config: config
          ? {
              staff_id: config.staff_id,
              provider_code: config.provider_code,
              user_id: config.user_id,
              credential_id: config.credential_id,
              certificate_subject: config.certificate_subject,
              certificate_serial: config.certificate_serial,
              is_verified: config.is_verified,
              last_verified_at: config.last_verified_at,
            }
          : null,
      },
    });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================================
// 2. POST / — upsert user config (CFG-05)
// ============================================================================

/**
 * Body: { user_id: string, credential_id?: string | null }
 *
 * Business rules:
 *   - MYSIGN_VIETTEL: `credential_id` BẮT BUỘC (multi-cert flow — user phải chọn
 *     cert cụ thể sau khi bấm "Tải danh sách CTS").
 *   - SMARTCA_VNPT: `credential_id` KHÔNG BẮT BUỘC (thường chỉ 1 cert/user).
 *   - Auto-reset `is_verified=false` + `last_verified_at=null` + `last_error=null`:
 *     mỗi lần user save config coi như config MỚI, phải bấm "Kiểm tra" để verify
 *     lại. SP COALESCE giữ nguyên `certificate_*` cũ (có thể user chỉ đổi 1 field
 *     minor, vẫn muốn giữ cert snapshot cũ cho audit).
 */
router.post('/', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const body = req.body ?? {};

    if (!isNonEmptyString(body.user_id, 200)) {
      res.status(400).json({
        success: false,
        message: 'Vui lòng nhập user_id (không quá 200 ký tự)',
      });
      return;
    }

    const active = await getActiveProviderWithCredentials();
    if (!active) {
      res.status(400).json({
        success: false,
        message:
          'Admin chưa kích hoạt provider ký số nào. Vui lòng liên hệ Quản trị viên.',
      });
      return;
    }

    const providerCode = active.provider.code;

    // MySign bắt buộc có credential_id; SmartCA thì optional
    let credentialId: string | null = null;
    if (providerCode === 'MYSIGN_VIETTEL') {
      if (!isNonEmptyString(body.credential_id, 200)) {
        res.status(400).json({
          success: false,
          message:
            'Vui lòng chọn chứng thư số (bấm "Tải danh sách CTS" để lấy danh sách trước)',
        });
        return;
      }
      credentialId = body.credential_id.trim();
    } else if (isNonEmptyString(body.credential_id, 200)) {
      // SmartCA có thể có credential_id (cert cụ thể) nhưng không bắt buộc
      credentialId = body.credential_id.trim();
    }

    const result = await staffSigningConfigRepository.upsert({
      staffId,
      providerCode,
      userId: body.user_id.trim(),
      credentialId,
      // Pass null cho certificate_* → SP COALESCE giữ nguyên snapshot cũ (nếu có)
      certificateData: null,
      certificateSubject: null,
      certificateSerial: null,
      // Reset verify status — user PHẢI bấm "Kiểm tra" sau mỗi lần save
      isVerified: false,
      lastVerifiedAt: null,
      lastError: null,
    });

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }

    res.status(201).json({
      success: true,
      message: 'Lưu cấu hình thành công. Vui lòng bấm "Kiểm tra" để xác thực.',
    });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================================
// 3. POST /certificates — fetch cert list từ provider (MySign — "Tải danh sách CTS")
// ============================================================================

/**
 * Body: { user_id: string }
 *
 * Gọi `active.provider.listCertificates(admin_creds, { userId })` để lấy danh
 * sách cert của user_id bên provider. MySign có thể trả nhiều cert → user
 * chọn bằng Select trên UI; SmartCA thường trả 1 cert.
 *
 * Không ghi DB — đây là READ-only endpoint để populate dropdown.
 *
 * NOTE: user_id đến từ body (không phải JWT) vì user có thể test với user_id
 * KHÁC trước khi save. Không cần staffId ở đây — không mutate DB.
 */
router.post('/certificates', async (req: Request, res: Response) => {
  try {
    const body = req.body ?? {};

    if (!isNonEmptyString(body.user_id, 200)) {
      res.status(400).json({
        success: false,
        message: 'Vui lòng nhập user_id',
      });
      return;
    }

    const active = await getActiveProviderWithCredentials();
    if (!active) {
      res.status(400).json({
        success: false,
        message:
          'Admin chưa kích hoạt provider ký số nào. Vui lòng liên hệ Quản trị viên.',
      });
      return;
    }

    let certs: CertificateInfo[];
    try {
      certs = await active.provider.listCertificates(active.credentials, {
        userId: body.user_id.trim(),
      });
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Lỗi không xác định';
      res.status(502).json({
        success: false,
        message: 'Không lấy được danh sách chứng thư: ' + msg,
      });
      return;
    }

    res.json({
      success: true,
      data: {
        certificates: certs.map(toClientCert),
      },
    });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================================
// 4. POST /verify — verify config + lưu cert snapshot (CFG-06)
// ============================================================================

/**
 * No body required (hoặc empty `{}`).
 *
 * Flow:
 *   1. Đọc config hiện tại (staffId + active.provider.code). Nếu chưa có → 400.
 *   2. Call `provider.listCertificates(admin_creds, { userId, credentialId })`.
 *   3. Match cert:
 *      - MYSIGN_VIETTEL: filter theo `credentialId`, fail nếu không thấy.
 *      - SMARTCA_VNPT: lấy cert đầu tiên (thường chỉ 1).
 *   4. Upsert với `is_verified=true` + snapshot cert (subject/serial/data) +
 *      `last_verified_at=now`.
 *   5. Nếu không match → upsert `is_verified=false` + `last_error=msg` nhưng
 *      trả HTTP 200 (verify fail là expected, KHÔNG phải server error).
 *   6. Nếu listCertificates throw (network/auth) → upsert failure + trả 502.
 */
router.post('/verify', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;

    const active = await getActiveProviderWithCredentials();
    if (!active) {
      res.status(400).json({
        success: false,
        message:
          'Admin chưa kích hoạt provider ký số nào. Vui lòng liên hệ Quản trị viên.',
      });
      return;
    }

    const providerCode = active.provider.code;

    // Step 1 — đọc config hiện tại
    const config = await staffSigningConfigRepository.get(staffId, providerCode);
    if (!config) {
      res.status(400).json({
        success: false,
        message: 'Vui lòng lưu cấu hình trước khi kiểm tra',
      });
      return;
    }

    // Step 2 — gọi listCertificates (có thể throw network/auth error)
    let certs: CertificateInfo[];
    try {
      certs = await active.provider.listCertificates(active.credentials, {
        userId: config.user_id,
        credentialId: config.credential_id,
      });
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Lỗi không xác định';
      // Persist failure (non-fatal nếu repo upsert cũng lỗi)
      try {
        await staffSigningConfigRepository.upsert({
          staffId,
          providerCode,
          userId: config.user_id,
          credentialId: config.credential_id,
          certificateData: null,
          certificateSubject: null,
          certificateSerial: null,
          isVerified: false,
          lastVerifiedAt: null,
          lastError: msg.slice(0, 1000),
        });
      } catch {
        // ignore — primary error vẫn trả về client
      }
      res.status(502).json({
        success: false,
        message: 'Không kết nối được provider: ' + msg,
      });
      return;
    }

    // Step 3 — tìm cert khớp
    let matched: CertificateInfo | undefined;
    if (providerCode === 'MYSIGN_VIETTEL') {
      matched = certs.find((c) => c.credentialId === config.credential_id);
    } else {
      // SmartCA: lấy cert đầu tiên (thường chỉ 1 cert/user)
      matched = certs[0];
    }

    if (!matched) {
      const errMsg =
        providerCode === 'MYSIGN_VIETTEL'
          ? 'Không tìm thấy chứng thư khớp credential_id đã chọn. Vui lòng tải lại danh sách CTS.'
          : 'Không tìm thấy chứng thư nào cho user_id này';

      await staffSigningConfigRepository.upsert({
        staffId,
        providerCode,
        userId: config.user_id,
        credentialId: config.credential_id,
        certificateData: null,
        certificateSubject: null,
        certificateSerial: null,
        isVerified: false,
        lastVerifiedAt: null,
        lastError: errMsg,
      });

      // 200 OK với verified=false — verify fail là expected state, không phải server error
      res.json({
        success: true,
        data: { verified: false, message: errMsg },
      });
      return;
    }

    // Step 4 — cert OK, lưu snapshot
    const nowIso = new Date().toISOString();
    const upsertResult = await staffSigningConfigRepository.upsert({
      staffId,
      providerCode,
      userId: config.user_id,
      credentialId: config.credential_id,
      certificateData: matched.certificateBase64,
      certificateSubject: matched.subject,
      certificateSerial: matched.serialNumber,
      isVerified: true,
      lastVerifiedAt: nowIso,
      lastError: null,
    });

    if (!upsertResult.success) {
      res.status(400).json({ success: false, message: upsertResult.message });
      return;
    }

    res.json({
      success: true,
      data: {
        verified: true,
        certificate_subject: matched.subject,
        cert_valid_to: matched.validTo,
        last_verified_at: nowIso,
      },
    });
  } catch (error) {
    handleDbError(error, res);
  }
});

export default router;
