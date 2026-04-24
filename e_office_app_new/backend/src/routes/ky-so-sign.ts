/**
 * Route: /api/ky-so/sign — Async sign flow entry point (Phase 11).
 *
 * 4 endpoints (chỉ cần `authenticate` — KHÔNG requireRoles vì mọi user đều
 * có thể ký nếu có quyền trên attachment cụ thể):
 *   POST   /              — Bắt đầu flow ký (< 1s response, enqueue poll job)
 *   POST   /:id/cancel    — Hủy transaction đang pending
 *   GET    /:id/download  — Presigned URL cho file đã ký (owner-or-admin)
 *   GET    /:id           — Xem trạng thái transaction (frontend fallback polling)
 *
 * SECURITY:
 *   - T-11-01 Tampering: staffId LUÔN từ `req.user.staffId` (JWT), KHÔNG bao giờ
 *     từ body. attachment_id đi vào canSign() → DB enforce ACL signer/approver.
 *   - T-11-02 Elevation: `incoming` attachment_type bị reject ngay — VB đến
 *     KHÔNG ký số (nghiệp vụ cơ quan nhà nước).
 *   - T-11-03 Info Disclosure: GET /:id owner-only (so sánh `txn.staff_id`
 *     với `req.user.staffId`) → user không đọc được transaction của người khác.
 *   - T-12-01 Info Disclosure: GET /:id/download owner-or-admin only + chỉ completed
 *   - T-12-02 Info Disclosure: reject txn chưa complete / không có signed_file_path
 *   - T-12-06 Info Disclosure: Cache-Control: no-store chặn browser cache URL
 *
 * Rate limit (T-12-03) deferred Phase 14 — accept risk cho v2.0 demo
 * (authenticated endpoint, staff nội bộ, không public).
 *
 * Performance target: POST / < 1s typical:
 *   - DB lookups (provider + config): ~50ms
 *   - MinIO download PDF (10-500KB): ~100-500ms
 *   - prepareSignPdf (pure JS, SHA256): ~50ms
 *   - provider.signHash (HTTPS Viettel/VNPT): ~300-800ms
 *   - DB create + setProviderTxn + queue.add: ~100ms
 *   Worst case ~1.5s (acceptable). Typical: 500-700ms.
 *
 * Error mapping:
 *   400 — validation / provider chưa active / user chưa verify / PDF invalid
 *   403 — canSign=false (không có quyền)
 *   404 — attachment / transaction không tồn tại
 *   500 — MinIO download fail / putPlaceholder fail
 *   502 — provider.signHash reject / network timeout
 */

import { Router, type Request, type Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { handleDbError } from '../lib/error-handler.js';
import {
  signTransactionRepository,
  type SignAttachmentType,
} from '../repositories/sign-transaction.repository.js';
import { attachmentSignRepository } from '../repositories/attachment-sign.repository.js';
import { staffSigningConfigRepository } from '../repositories/staff-signing-config.repository.js';
import { getActiveProviderWithCredentials } from '../services/signing/providers/provider-factory.js';
import { prepareSignPdf } from '../services/signing/pdf-signer.js';
import {
  downloadOriginalPdf,
  putPlaceholder,
  removePlaceholder,
  PLACEHOLDER_PREFIX,
} from '../lib/signing/placeholder-store.js';
import { streamFileToResponse } from '../lib/minio/client.js';
import {
  enqueuePollSignStatus,
  cancelPollJobsForTransaction,
} from '../lib/queue/signing-queue.js';
import { isValidAttachmentType } from '../lib/signing/sign-helpers.js';

const router = Router();

// ============================================================================
// Constants / mappers
// ============================================================================

/**
 * Map attachment_type → doc_type lưu trong sign_transactions.
 * SP `fn_sign_transaction_create` expect doc_type làm khóa nhận dạng loại văn bản
 * liên kết (Phase 8 schema). Mapping đảm bảo audit trail đầy đủ.
 */
const ATTACHMENT_TO_DOC_TYPE: Record<SignAttachmentType, string> = {
  incoming: 'incoming_doc',
  outgoing: 'outgoing_doc',
  drafting: 'drafting_doc',
  handling: 'handling_doc',
};

// Giới hạn length cho reason/location — metadata vào PDF placeholder, tránh overflow
const MAX_METADATA_LEN = 200;

// ============================================================================
// Helpers
// ============================================================================

/** Trim + slice an toàn cho metadata user-supplied (reason/location). */
function safeMetadata(raw: unknown, fallback: string): string {
  if (typeof raw !== 'string') return fallback;
  const trimmed = raw.trim();
  if (!trimmed) return fallback;
  return trimmed.slice(0, MAX_METADATA_LEN);
}

// ============================================================================
// POST / — Start sign flow
// Body: { attachment_id, attachment_type, doc_id?, sign_reason?, sign_location? }
// Returns 201 with { transaction_id, provider_transaction_id, provider_code, elapsed_ms }
// ============================================================================
router.post('/', async (req: Request, res: Response) => {
  const startedAt = Date.now();
  try {
    // SECURITY T-11-01: staffId CHỈ từ JWT, không bao giờ từ body
    const { staffId } = (req as AuthRequest).user;
    const {
      attachment_id,
      attachment_type,
      doc_id,
      sign_reason,
      sign_location,
    } = req.body ?? {};

    // ---- 0. Validate input
    const attachmentIdNum = Number(attachment_id);
    if (!Number.isFinite(attachmentIdNum) || attachmentIdNum <= 0) {
      res.status(400).json({
        success: false,
        message: 'attachment_id không hợp lệ',
      });
      return;
    }
    if (!isValidAttachmentType(attachment_type)) {
      res.status(400).json({
        success: false,
        message: 'attachment_type phải là một trong: incoming, outgoing, drafting, handling',
      });
      return;
    }
    // SECURITY T-11-02: VB đến KHÔNG ký số (nghiệp vụ cơ quan nhà nước)
    if (attachment_type === 'incoming') {
      res.status(400).json({
        success: false,
        message: 'Không được ký số văn bản đến',
      });
      return;
    }

    // ---- 1. Provider active check (Admin đã cấu hình CFG-01?)
    const active = await getActiveProviderWithCredentials();
    if (!active) {
      res.status(400).json({
        success: false,
        message:
          'Hệ thống chưa cấu hình provider ký số. Vui lòng liên hệ Quản trị viên.',
      });
      return;
    }
    const providerCode = active.provider.code;

    // ---- 2. User signing config verified (CFG-05/06)?
    const userConfig = await staffSigningConfigRepository.get(staffId, providerCode);
    if (!userConfig) {
      res.status(400).json({
        success: false,
        message:
          'Bạn chưa cấu hình tài khoản ký số. Vui lòng vào "Tài khoản ký số cá nhân" để cấu hình.',
      });
      return;
    }
    if (!userConfig.is_verified) {
      res.status(400).json({
        success: false,
        message:
          'Tài khoản ký số chưa được xác thực. Vui lòng bấm "Kiểm tra" trong trang Tài khoản ký số cá nhân.',
      });
      return;
    }

    // ---- 3. Permission check + lấy file_path/file_name (1 query)
    const canSign = await attachmentSignRepository.canSign(
      attachmentIdNum,
      attachment_type,
      staffId,
    );
    if (!canSign.can_sign) {
      res.status(403).json({
        success: false,
        message: canSign.reason ?? 'Bạn không có quyền ký file này',
      });
      return;
    }
    if (!canSign.file_path) {
      res.status(404).json({
        success: false,
        message: 'Không tìm thấy đường dẫn file đính kèm',
      });
      return;
    }
    const fileName = canSign.file_name ?? 'document.pdf';

    // ---- 4. Basic mime check (extension-based)
    if (!fileName.toLowerCase().endsWith('.pdf')) {
      res.status(400).json({
        success: false,
        message: 'Chỉ hỗ trợ ký file PDF. File hiện tại không phải định dạng PDF.',
      });
      return;
    }

    // ---- 5. Download PDF gốc từ MinIO
    let pdfBuffer: Buffer;
    try {
      pdfBuffer = await downloadOriginalPdf(canSign.file_path);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      res.status(500).json({
        success: false,
        message: 'Không thể tải file PDF từ MinIO: ' + msg,
      });
      return;
    }

    // ---- 6. Compute hash + placeholder PDF (pure JS)
    let hashResult;
    try {
      hashResult = prepareSignPdf(pdfBuffer, {
        reason: safeMetadata(sign_reason, 'Ký phê duyệt văn bản'),
        location: safeMetadata(sign_location, 'Vietnam'),
        name: 'E-Office signer',
      });
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      res.status(400).json({
        success: false,
        message: 'File PDF không hợp lệ hoặc không tương thích ký số: ' + msg,
      });
      return;
    }

    // ---- 7. Create DB transaction FIRST (cần txnId để build placeholder key + provider documentId)
    const createResult = await signTransactionRepository.create({
      staffId,
      providerCode,
      attachmentId: attachmentIdNum,
      attachmentType: attachment_type,
      docId: Number.isFinite(Number(doc_id)) ? Number(doc_id) : null,
      docType: ATTACHMENT_TO_DOC_TYPE[attachment_type],
      fileHashSha256: hashResult.hash,
    });
    if (!createResult.success) {
      res.status(400).json({
        success: false,
        message: createResult.message,
      });
      return;
    }
    const txnId = createResult.id;

    // ---- 8. Lưu placeholder PDF vào MinIO (worker sẽ đọc lại khi finalize)
    try {
      await putPlaceholder(txnId, hashResult.placeholderPdf);
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      // Transaction đã được tạo — mark failed để audit trail đầy đủ
      await signTransactionRepository.updateStatus(
        txnId,
        'failed',
        ('Không thể lưu placeholder PDF: ' + msg).slice(0, 1000),
      );
      res.status(500).json({
        success: false,
        message: 'Lỗi lưu tạm file PDF: ' + msg,
      });
      return;
    }

    // ---- 9. Gọi provider.signHash — nhận providerTxnId (OTP push tới app user)
    let signHashResult;
    try {
      signHashResult = await active.provider.signHash(
        active.credentials,
        {
          userId: userConfig.user_id,
          credentialId: userConfig.credential_id,
        },
        {
          hashHex: hashResult.hash,
          documentName: fileName,
          documentId: String(txnId),
        },
      );
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : String(err);
      // Rollback: mark failed + cleanup placeholder (không ai sẽ dùng nữa)
      await signTransactionRepository.updateStatus(
        txnId,
        'failed',
        ('Provider từ chối: ' + msg).slice(0, 1000),
      );
      await removePlaceholder(txnId);
      res.status(502).json({
        success: false,
        message: 'Provider từ chối yêu cầu ký: ' + msg,
      });
      return;
    }

    // ---- 10. Lưu provider_txn_id + enqueue poll job (delay 5s)
    await signTransactionRepository.setProviderTxn(
      txnId,
      signHashResult.providerTransactionId,
    );
    await enqueuePollSignStatus({
      signTransactionId: txnId,
      providerTransactionId: signHashResult.providerTransactionId,
      placeholderPdfKey: `${PLACEHOLDER_PREFIX}/${txnId}.pdf`,
      attempt: 1,
    });

    // ---- 11. Return fast — user gets transaction_id ngay
    const elapsedMs = Date.now() - startedAt;
    res.status(201).json({
      success: true,
      data: {
        transaction_id: txnId,
        provider_transaction_id: signHashResult.providerTransactionId,
        provider_code: providerCode,
        elapsed_ms: elapsedMs,
      },
      message:
        'Yêu cầu ký đã được gửi. Vui lòng xác nhận OTP trên ứng dụng di động.',
    });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================================
// POST /:id/cancel — Hủy transaction đang pending
// Only owner can cancel; only status='pending' can be cancelled.
// ============================================================================
router.post('/:id/cancel', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) {
      res.status(400).json({ success: false, message: 'ID không hợp lệ' });
      return;
    }

    const txn = await signTransactionRepository.getById(id);
    if (!txn) {
      res.status(404).json({
        success: false,
        message: 'Không tìm thấy giao dịch ký số',
      });
      return;
    }
    // SECURITY T-11-03: owner-only
    if (txn.staff_id !== staffId) {
      res.status(403).json({
        success: false,
        message: 'Bạn không có quyền hủy giao dịch này',
      });
      return;
    }
    if (txn.status !== 'pending') {
      res.status(400).json({
        success: false,
        message: `Giao dịch không thể hủy (trạng thái hiện tại: ${txn.status})`,
      });
      return;
    }

    // Mark DB cancelled
    const result = await signTransactionRepository.updateStatus(
      id,
      'cancelled',
      'Hủy bởi người dùng',
    );
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }

    // Best-effort remove delayed jobs + placeholder (worker cũng guard bằng DB status check)
    try {
      await cancelPollJobsForTransaction(id);
    } catch {
      // non-fatal — worker sẽ DB-check và short-circuit
    }
    await removePlaceholder(id);

    res.json({
      success: true,
      data: { transaction_id: id },
      message: 'Đã hủy giao dịch ký số',
    });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================================
// GET /:id/download — Presigned URL cho file PDF đã ký (owner-or-admin only)
// Response: { success: true, data: { url, file_name, expires_in: 600 } }
// TTL 600s (10 phút), header Cache-Control: no-store (T-12-06).
// Rate limit (T-12-03) deferred Phase 14 — accept risk cho v2.0 demo.
// ============================================================================
router.get('/:id/download', async (req: Request, res: Response) => {
  try {
    const { staffId, isAdmin } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) {
      res.status(400).json({ success: false, message: 'ID không hợp lệ' });
      return;
    }

    const txn = await signTransactionRepository.getById(id);
    if (!txn) {
      res.status(404).json({
        success: false,
        message: 'Không tìm thấy giao dịch ký số',
      });
      return;
    }
    // SECURITY T-12-01: owner-or-admin only (mitigate info disclosure)
    if (txn.staff_id !== staffId && !isAdmin) {
      res.status(403).json({
        success: false,
        message: 'Bạn không có quyền tải file của giao dịch này',
      });
      return;
    }
    // SECURITY T-12-02: chỉ cho download khi đã hoàn tất + có signed file
    if (txn.status !== 'completed' || !txn.signed_file_path) {
      res.status(404).json({
        success: false,
        message: 'Giao dịch chưa có file đã ký',
      });
      return;
    }

    // T-12-06: Ngăn browser/proxy cache
    res.setHeader('Cache-Control', 'no-store');

    // file_name: prefix 'signed_' vào segment cuối của signed_file_path
    const segments = txn.signed_file_path.split('/');
    const lastSegment = segments[segments.length - 1] || 'signed.pdf';
    const fileName = lastSegment.startsWith('signed_') ? lastSegment : `signed_${lastSegment}`;

    // Stream file đã ký qua backend proxy (MinIO nội bộ, browser không truy cập trực tiếp)
    await streamFileToResponse(res, txn.signed_file_path, fileName, 'application/pdf');
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================================
// GET /:id — Xem trạng thái transaction (owner only, cho frontend polling)
// ============================================================================
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id <= 0) {
      res.status(400).json({ success: false, message: 'ID không hợp lệ' });
      return;
    }

    const txn = await signTransactionRepository.getById(id);
    if (!txn) {
      res.status(404).json({
        success: false,
        message: 'Không tìm thấy giao dịch ký số',
      });
      return;
    }
    // SECURITY T-11-03: owner-only
    if (txn.staff_id !== staffId) {
      res.status(403).json({
        success: false,
        message: 'Không có quyền xem giao dịch này',
      });
      return;
    }

    res.json({
      success: true,
      data: {
        id: txn.id,
        status: txn.status,
        provider_code: txn.provider_code,
        provider_txn_id: txn.provider_txn_id,
        attachment_id: txn.attachment_id,
        attachment_type: txn.attachment_type,
        doc_id: txn.doc_id,
        doc_type: txn.doc_type,
        error_message: txn.error_message,
        retry_count: txn.retry_count,
        created_at: txn.created_at,
        started_at: txn.started_at,
        completed_at: txn.completed_at,
        expires_at: txn.expires_at,
        signed_file_path: txn.signed_file_path,
      },
    });
  } catch (error) {
    handleDbError(error, res);
  }
});

export default router;
