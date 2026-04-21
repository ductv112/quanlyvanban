/**
 * Ephemeral MinIO store cho placeholder PDF — cầu nối giữa POST /api/ky-so/sign
 * và worker (Plan 11-04) finalize.
 *
 * Why MinIO (không phải Redis):
 *   - Placeholder PDF có thể 200KB+ (PAdES placeholder = PDF gốc + ~16KB padding).
 *   - Redis dành cho small job payloads, không phải blob data.
 *   - MinIO đã có sẵn trong stack + đã lưu attachment gốc → re-use hạ tầng.
 *
 * Lifecycle:
 *   1. POST /sign ghi placeholder → 'signing-placeholders/{txnId}.pdf'
 *   2. Worker getPlaceholder(txnId) để retrieve buffer
 *   3. Worker removePlaceholder(txnId) sau khi finalize / fail / cancel
 *
 * Cleanup on failure:
 *   - Route POST /sign call removePlaceholder nếu provider.signHash throw (post-put).
 *   - Worker call removePlaceholder unconditionally trong terminal branches.
 *   - Nếu worker crash mid-flow → placeholder orphan → deploy cần add lifecycle
 *     policy trên MinIO prefix 'signing-placeholders/' auto-expire sau 24h.
 *     (Documented trong Plan 11-08 deployment hardening.)
 *
 * SECURITY:
 *   - Placeholder chứa PDF đã có /Contents <00000...> → KHÔNG có signature thực.
 *     Không leak PII hơn file gốc (chỉ là file gốc + header placeholder).
 *   - Key chứa txnId (not staffId) → không leak ownership qua key name.
 */

import { minioClient } from '../minio/client.js';

const BUCKET = process.env.MINIO_BUCKET || 'documents';
export const PLACEHOLDER_PREFIX = 'signing-placeholders';

/** Compute MinIO key cho placeholder của 1 transaction. */
function keyFor(txnId: number): string {
  return `${PLACEHOLDER_PREFIX}/${txnId}.pdf`;
}

/** Stream → Buffer helper (MinIO getObject trả Readable stream). */
async function streamToBuffer(stream: NodeJS.ReadableStream): Promise<Buffer> {
  const chunks: Buffer[] = [];
  for await (const chunk of stream) {
    chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk as string));
  }
  return Buffer.concat(chunks);
}

/**
 * Ghi placeholder PDF vào MinIO tại key deterministic theo txnId.
 * Idempotent: overwrite nếu key đã tồn tại (rare case: retry cùng txnId).
 */
export async function putPlaceholder(txnId: number, buffer: Buffer): Promise<void> {
  await minioClient.putObject(BUCKET, keyFor(txnId), buffer, buffer.length, {
    'Content-Type': 'application/pdf',
  });
}

/**
 * Đọc placeholder từ MinIO → Buffer. Worker dùng để embed signature.
 * Throws nếu key không tồn tại (cancelled/cleaned up).
 */
export async function getPlaceholder(txnId: number): Promise<Buffer> {
  const stream = await minioClient.getObject(BUCKET, keyFor(txnId));
  return streamToBuffer(stream);
}

/**
 * Xóa placeholder. Best-effort — không throw nếu key đã gone.
 * Gọi bởi worker trong tất cả terminal paths (complete/fail/cancel/expire).
 */
export async function removePlaceholder(txnId: number): Promise<void> {
  try {
    await minioClient.removeObject(BUCKET, keyFor(txnId));
  } catch {
    // Not fatal — object có thể đã bị xóa hoặc chưa kịp tạo.
  }
}

/**
 * Helper worker dùng để download file ORIGINAL từ MinIO (không phải placeholder).
 * Key là `canSign().file_path` — đường dẫn gốc của attachment.
 *
 * Route POST /sign cũng dùng helper này để load file PDF gốc trước khi
 * `prepareSignPdf()`.
 */
export async function downloadOriginalPdf(originalKey: string): Promise<Buffer> {
  const stream = await minioClient.getObject(BUCKET, originalKey);
  return streamToBuffer(stream);
}
