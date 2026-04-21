/**
 * BullMQ Worker: poll-sign-status (Phase 11, Plan 04)
 *
 * Consumer của BullMQ queue `signing` — xử lý job `poll-sign-status` enqueued
 * bởi route POST /api/ky-so/sign (Plan 03) + bởi chính worker khi re-queue cho
 * poll tiếp theo.
 *
 * Job flow (per job instance):
 *   1. Đọc sign_transactions row theo ID.
 *   2. Short-circuit nếu status !== 'pending' (user đã cancel / đã complete — idempotent).
 *   3. Load provider credentials + user config (verify còn hợp lệ).
 *   4. Call provider.getSignStatus(providerTxnId).
 *   5. Branch theo status:
 *        pending + attempt < MAX    → incrementRetry + re-enqueue attempt+1 (delay 5s)
 *        pending + attempt >= MAX   → updateStatus('expired') + emit + notice + cleanup
 *        completed                  → getPlaceholder → signPdf → uploadFile →
 *                                     finalizeSign + transaction.complete → emit + notice + cleanup
 *        failed / expired           → updateStatus + emit + notice + cleanup
 *
 * Concurrency = 1 (default, configurable via WORKER_CONCURRENCY) — serialize để tránh
 *   provider rate-limiting + đơn giản tracing. BullMQ v5 Worker tự pull job kế tiếp
 *   khi job hiện tại xong.
 *
 * Graceful shutdown (server.ts → stopSigningWorker):
 *   - worker.close() chờ job đang chạy xong (tối đa 30s) rồi disconnect Redis.
 *   - Job pending/delayed trong Redis vẫn giữ — boot kế tiếp Worker tự resume.
 *
 * Feature flag WORKER_ENABLED=false:
 *   - startSigningWorker() return null + log warning. Backend boot OK, không consume
 *     sign jobs. Dùng cho CI / env không có Redis / debug sync flow.
 *
 * Threat model:
 *   - T-11-13 Tampering (Redis job payload): re-read DB status mỗi job, bỏ qua nếu
 *     !pending. Attacker inject job cho txn đã cancelled = no-op.
 *   - T-11-15 DoS (worker stuck on provider): provider adapter có AbortController 15s
 *     timeout (Phase 9). Try/catch wrap getSignStatus → count as retry.
 *   - T-11-16 Repudiation: signed PDF lưu key riêng (buildSignedObjectKey), placeholder
 *     xóa, DB row persist forever với signature_base64 + signed_file_path.
 */

import { Worker, type Job } from 'bullmq';
import pino from 'pino';
import {
  SIGNING_QUEUE_NAME,
  POLL_INTERVAL_MS,
  MAX_POLL_ATTEMPTS,
  type PollSignStatusJob,
} from '../lib/queue/types.js';
import { createRedisConnection } from '../lib/queue/redis-connection.js';
import { enqueuePollSignStatus } from '../lib/queue/signing-queue.js';
import {
  signTransactionRepository,
  type SignAttachmentType,
} from '../repositories/sign-transaction.repository.js';
import { staffSigningConfigRepository } from '../repositories/staff-signing-config.repository.js';
import { attachmentSignRepository } from '../repositories/attachment-sign.repository.js';
import { noticeRepository } from '../repositories/notice.repository.js';
import { getProviderByCodeWithCredentials } from '../services/signing/providers/provider-factory.js';
import type { ProviderCode } from '../services/signing/providers/provider.interface.js';
import { signPdf } from '../services/signing/pdf-signer.js';
import { getPlaceholder, removePlaceholder } from '../lib/signing/placeholder-store.js';
import { buildSignedObjectKey } from '../lib/signing/sign-helpers.js';
import { emitSignCompleted, emitSignFailed } from '../lib/signing/sign-events.js';
import { minioClient } from '../lib/minio/client.js';

const BUCKET = process.env.MINIO_BUCKET || 'documents';
const logger = pino({
  name: 'signing-worker',
  level: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
  transport: process.env.NODE_ENV !== 'production' ? { target: 'pino-pretty' } : undefined,
});

let worker: Worker<PollSignStatusJob> | null = null;

/** Narrow string provider_code thành ProviderCode union — throw nếu không support. */
function toProviderCode(code: string): ProviderCode {
  if (code === 'SMARTCA_VNPT' || code === 'MYSIGN_VIETTEL') {
    return code;
  }
  throw new Error(`Provider code không hỗ trợ: ${code}`);
}

/**
 * Upload PDF đã ký lên MinIO tại signedKey.
 * Tách function để error trong upload được catch riêng + log rõ bước.
 */
async function uploadSignedPdf(key: string, buffer: Buffer): Promise<void> {
  await minioClient.putObject(BUCKET, key, buffer, buffer.length, {
    'Content-Type': 'application/pdf',
  });
}

/**
 * Xử lý failure path (shared cho expired/failed branches).
 *   1. updateStatus (pending → terminal)
 *   2. removePlaceholder (cleanup MinIO — best-effort)
 *   3. emitSignFailed (Socket — best-effort, user online nhận ngay)
 *   4. noticeRepository.createForStaff (bell — persistent fallback)
 *
 * Best-effort: bất kỳ bước 3-4 nào fail cũng không throw lên BullMQ (job vẫn thành
 * công từ góc nhìn worker — DB là source of truth).
 */
async function handleFailure(
  txnId: number,
  staffId: number,
  providerCode: string,
  attachmentId: number,
  attachmentType: string,
  status: 'failed' | 'expired',
  errorMessage: string,
): Promise<void> {
  // Trim error message — sign_transactions.error_message VARCHAR(500) per schema
  const errMsg = (errorMessage || '').trim().slice(0, 500) || 'Lỗi không xác định';

  // 1. DB — source of truth
  const updRes = await signTransactionRepository.updateStatus(txnId, status, errMsg);
  if (!updRes.success) {
    logger.warn(
      { txnId, status, msg: updRes.message },
      'updateStatus reported failure (có thể transaction đã ở terminal state)',
    );
  }

  // 2. Cleanup MinIO placeholder
  await removePlaceholder(txnId);

  // 3. Socket emit
  emitSignFailed(staffId, {
    transaction_id: txnId,
    provider_code: providerCode,
    attachment_id: attachmentId,
    attachment_type: attachmentType,
    error_message: errMsg,
    status,
  });

  // 4. Bell notification (persistent)
  try {
    await noticeRepository.createForStaff(
      staffId,
      status === 'expired' ? 'Ký số hết hạn' : 'Ký số thất bại',
      status === 'expired'
        ? `Giao dịch ký số #${txnId} đã hết hạn sau 3 phút không xác nhận: ${errMsg}`
        : `Giao dịch ký số #${txnId} thất bại: ${errMsg}`,
      'SIGN_RESULT',
    );
  } catch (err) {
    logger.warn({ err, txnId }, 'Failed to create failure notification');
  }
}

/**
 * Re-enqueue cho poll attempt kế tiếp (hoặc expire nếu đã đạt MAX).
 * Extract helper để 2 nơi (catch block + pending branch) dùng chung logic.
 */
async function rescheduleOrExpire(
  job: Job<PollSignStatusJob>,
  txnId: number,
  staffId: number,
  providerCode: string,
  attachmentId: number,
  attachmentType: string,
  currentAttempt: number,
  expireReason: string,
): Promise<void> {
  if (currentAttempt >= MAX_POLL_ATTEMPTS) {
    await handleFailure(
      txnId,
      staffId,
      providerCode,
      attachmentId,
      attachmentType,
      'expired',
      expireReason,
    );
    return;
  }
  await signTransactionRepository.incrementRetry(txnId);
  await enqueuePollSignStatus(
    {
      signTransactionId: txnId,
      providerTransactionId: job.data.providerTransactionId,
      placeholderPdfKey: job.data.placeholderPdfKey,
      attempt: currentAttempt + 1,
    },
    POLL_INTERVAL_MS,
  );
}

/**
 * Processor chính của BullMQ Worker.
 * BullMQ call function này với mỗi job từ queue `signing`.
 */
async function processJob(job: Job<PollSignStatusJob>): Promise<void> {
  const { signTransactionId, providerTransactionId, attempt } = job.data;
  const ctx = { jobId: job.id, txnId: signTransactionId, attempt };
  logger.info(ctx, 'Processing poll-sign-status job');

  // ==========================================================================
  // 1. Re-read DB (source of truth — mitigate T-11-13 tampered job payload)
  // ==========================================================================
  const txn = await signTransactionRepository.getById(signTransactionId);
  if (!txn) {
    logger.warn(ctx, 'Transaction không tồn tại — skip');
    await removePlaceholder(signTransactionId);
    return;
  }
  if (txn.status !== 'pending') {
    logger.info(
      { ...ctx, status: txn.status },
      'Transaction không còn pending — skip (đã cancel/complete)',
    );
    await removePlaceholder(signTransactionId);
    return;
  }

  // ==========================================================================
  // 2. Load user config (verify còn hợp lệ — user có thể đã xóa/revoke config
  //    giữa chừng; admin có thể đã unset is_verified)
  // ==========================================================================
  const userConfig = await staffSigningConfigRepository.get(txn.staff_id, txn.provider_code);
  if (!userConfig || !userConfig.is_verified) {
    await handleFailure(
      signTransactionId,
      txn.staff_id,
      txn.provider_code,
      txn.attachment_id,
      txn.attachment_type,
      'failed',
      'Cấu hình ký số của người dùng không còn hợp lệ (đã xóa hoặc bị hủy xác thực)',
    );
    return;
  }

  // ==========================================================================
  // 3. Get provider instance + credentials (reload mỗi lần — admin có thể
  //    cập nhật credentials giữa chừng; T-11-17 accept)
  // ==========================================================================
  let providerCodeNarrow: ProviderCode;
  try {
    providerCodeNarrow = toProviderCode(txn.provider_code);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    await handleFailure(
      signTransactionId,
      txn.staff_id,
      txn.provider_code,
      txn.attachment_id,
      txn.attachment_type,
      'failed',
      msg,
    );
    return;
  }

  const active = await getProviderByCodeWithCredentials(providerCodeNarrow);
  if (!active) {
    await handleFailure(
      signTransactionId,
      txn.staff_id,
      txn.provider_code,
      txn.attachment_id,
      txn.attachment_type,
      'failed',
      'Provider đã bị xóa hoặc vô hiệu hóa — liên hệ Quản trị hệ thống',
    );
    return;
  }

  // ==========================================================================
  // 4. Poll provider status
  // ==========================================================================
  let statusRes;
  try {
    statusRes = await active.provider.getSignStatus(
      active.credentials,
      { userId: userConfig.user_id, credentialId: userConfig.credential_id },
      providerTransactionId,
    );
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    logger.warn({ ...ctx, err: msg }, 'provider.getSignStatus threw — treating as transient retry');
    await rescheduleOrExpire(
      job,
      signTransactionId,
      txn.staff_id,
      txn.provider_code,
      txn.attachment_id,
      txn.attachment_type,
      attempt,
      `Hết thời gian chờ sau ${MAX_POLL_ATTEMPTS} lần thử (3 phút). Lỗi cuối: ${msg}`,
    );
    return;
  }

  // ==========================================================================
  // 5. Branch theo provider status
  // ==========================================================================
  if (statusRes.status === 'pending') {
    await rescheduleOrExpire(
      job,
      signTransactionId,
      txn.staff_id,
      txn.provider_code,
      txn.attachment_id,
      txn.attachment_type,
      attempt,
      'Hết thời gian chờ xác nhận OTP (3 phút)',
    );
    logger.debug({ ...ctx, providerStatus: 'pending' }, 'Still pending — re-queued or expired');
    return;
  }

  if (statusRes.status === 'failed' || statusRes.status === 'expired') {
    await handleFailure(
      signTransactionId,
      txn.staff_id,
      txn.provider_code,
      txn.attachment_id,
      txn.attachment_type,
      statusRes.status,
      statusRes.errorMessage ?? 'Provider không trả về lý do cụ thể',
    );
    return;
  }

  // ==========================================================================
  // 6. status === 'completed' — embed signature + upload + finalize
  // ==========================================================================
  if (statusRes.status !== 'completed') {
    // Exhaustive check — defensive
    await handleFailure(
      signTransactionId,
      txn.staff_id,
      txn.provider_code,
      txn.attachment_id,
      txn.attachment_type,
      'failed',
      `Trạng thái provider không xác định: ${String(statusRes.status)}`,
    );
    return;
  }

  const signatureBase64 = statusRes.signatureBase64;
  if (!signatureBase64 || signatureBase64.trim() === '') {
    await handleFailure(
      signTransactionId,
      txn.staff_id,
      txn.provider_code,
      txn.attachment_id,
      txn.attachment_type,
      'failed',
      'Provider trả completed nhưng không có signature_base64',
    );
    return;
  }

  // 6a. Load placeholder
  let placeholderBuf: Buffer;
  try {
    placeholderBuf = await getPlaceholder(signTransactionId);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    await handleFailure(
      signTransactionId,
      txn.staff_id,
      txn.provider_code,
      txn.attachment_id,
      txn.attachment_type,
      'failed',
      `Không thể đọc placeholder PDF: ${msg}`,
    );
    return;
  }

  // 6b. Embed signature
  let signed;
  try {
    signed = await signPdf(placeholderBuf, signatureBase64);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    await handleFailure(
      signTransactionId,
      txn.staff_id,
      txn.provider_code,
      txn.attachment_id,
      txn.attachment_type,
      'failed',
      `Không thể embed signature vào PDF: ${msg}`,
    );
    return;
  }

  // 6c. Resolve attachmentType narrow + file info (reuse canSign SP — returns file_path + file_name)
  const attachmentTypeNarrow = txn.attachment_type as SignAttachmentType;
  const canSignRes = await attachmentSignRepository.canSign(
    txn.attachment_id,
    attachmentTypeNarrow,
    txn.staff_id,
  );
  const originalKey = canSignRes.file_path ?? `unknown/${txn.attachment_id}.pdf`;
  const fileName = canSignRes.file_name ?? `attachment-${txn.attachment_id}`;
  const signedKey = buildSignedObjectKey(originalKey, attachmentTypeNarrow, signTransactionId);

  // 6d. Upload signed PDF
  try {
    await uploadSignedPdf(signedKey, signed.signedPdf);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    await handleFailure(
      signTransactionId,
      txn.staff_id,
      txn.provider_code,
      txn.attachment_id,
      txn.attachment_type,
      'failed',
      `Không thể upload signed PDF: ${msg}`,
    );
    return;
  }

  // 6e. DB transition 1: complete sign_transactions
  const completeRes = await signTransactionRepository.complete(
    signTransactionId,
    signatureBase64,
    signedKey,
  );
  if (!completeRes.success) {
    logger.error(
      { ...ctx, msg: completeRes.message },
      'signTransaction.complete failed — attempting finalize anyway',
    );
    // Không bail: attempt finalize attachment để user không bị kẹt trạng thái.
  }

  // 6f. DB transition 2: finalize attachment (is_ca=true, ca_date=now, signed_file_path)
  const finalizeRes = await attachmentSignRepository.finalizeSign({
    attachmentId: txn.attachment_id,
    attachmentType: attachmentTypeNarrow,
    signedFilePath: signedKey,
    signProviderCode: txn.provider_code,
    signTransactionId: signTransactionId,
  });
  if (!finalizeRes.success) {
    logger.warn({ ...ctx, msg: finalizeRes.message }, 'finalizeSign reported failure');
  }

  // 6g. Cleanup placeholder
  await removePlaceholder(signTransactionId);

  // 6h. Socket + bell
  emitSignCompleted(txn.staff_id, {
    transaction_id: signTransactionId,
    provider_code: txn.provider_code,
    attachment_id: txn.attachment_id,
    attachment_type: txn.attachment_type,
    doc_id: txn.doc_id,
    doc_type: txn.doc_type,
    signed_file_path: signedKey,
    completed_at: new Date().toISOString(),
  });

  try {
    await noticeRepository.createForStaff(
      txn.staff_id,
      'Ký số thành công',
      `Giao dịch ký số #${signTransactionId} (${fileName}) đã hoàn tất lúc ${new Date().toLocaleString('vi-VN')}.`,
      'SIGN_RESULT',
    );
  } catch (err) {
    logger.warn({ err, txnId: signTransactionId }, 'Failed to create completion notification');
  }

  logger.info({ ...ctx, signedKey }, 'Sign completed successfully');
}

// ============================================================================
// Public API — start/stop được gọi từ server.ts
// ============================================================================

/**
 * Start BullMQ Worker. Idempotent — call nhiều lần chỉ tạo 1 worker.
 *
 * Feature flags (env):
 *   - WORKER_ENABLED=false       → return null, log DISABLED
 *   - WORKER_CONCURRENCY=<N>     → override concurrency (default 1)
 *
 * @returns Worker instance nếu start OK, null nếu disabled hoặc đã chạy.
 */
export function startSigningWorker(): Worker<PollSignStatusJob> | null {
  if (process.env.WORKER_ENABLED === 'false') {
    logger.warn('Signing worker DISABLED (WORKER_ENABLED=false) — sign jobs sẽ không được xử lý');
    return null;
  }
  if (worker) {
    logger.warn('Signing worker đã start — bỏ qua call trùng');
    return worker;
  }

  const concurrency = Number(process.env.WORKER_CONCURRENCY) || 1;

  worker = new Worker<PollSignStatusJob>(SIGNING_QUEUE_NAME, processJob, {
    connection: createRedisConnection(),
    concurrency,
    autorun: true,
  });

  worker.on('failed', (job, err) => {
    logger.error(
      { jobId: job?.id, err: err?.message ?? String(err) },
      'Worker job failed (exception trong processJob)',
    );
  });
  worker.on('completed', (job) => {
    logger.debug({ jobId: job.id }, 'Worker job completed');
  });
  worker.on('error', (err) => {
    logger.error({ err: err.message }, 'Worker error event');
  });

  logger.info(
    { queue: SIGNING_QUEUE_NAME, concurrency },
    'Signing worker started',
  );
  return worker;
}

/**
 * Graceful shutdown — chờ job đang chạy xong (tối đa timeoutMs) rồi đóng Worker
 * + Redis connection. Gọi từ server.ts SIGTERM/SIGINT handler.
 *
 * @param timeoutMs Max thời gian chờ close (default 30s).
 */
export async function stopSigningWorker(timeoutMs: number = 30_000): Promise<void> {
  if (!worker) return;
  logger.info({ timeoutMs }, 'Stopping signing worker...');
  const w = worker;
  worker = null;
  await Promise.race([
    w.close(),
    new Promise<void>((resolve) => setTimeout(resolve, timeoutMs)),
  ]);
  logger.info('Signing worker stopped');
}
