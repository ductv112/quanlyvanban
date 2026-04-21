/**
 * Pure helpers for sign flow — no I/O, no DB. Easy to unit test.
 *
 * Phase 11, Plan 01 — downstream plans (02 queue, 03 route, 04 worker, 05 list)
 * import from here:
 *   - `isValidAttachmentType` — guard before calling SPs
 *   - `buildSignedObjectKey`  — consistent MinIO path cho file đã ký
 *   - `getFileExtension`      — UI display (icon per file type)
 */

import type { SignAttachmentType } from '../../repositories/sign-transaction.repository.js';

const VALID_TYPES: readonly SignAttachmentType[] = [
  'incoming',
  'outgoing',
  'drafting',
  'handling',
] as const;

/** Type guard cho giá trị đến từ request body / query. */
export function isValidAttachmentType(value: unknown): value is SignAttachmentType {
  return typeof value === 'string' && (VALID_TYPES as readonly string[]).includes(value);
}

/**
 * Build MinIO key cho file đã ký.
 * Pattern: `signed/{type}/{txnId}/{basename}`.
 *
 * VD: `originalKey='documents/outgoing/2026/quyet-dinh-42.pdf'`, `txnId=99`
 *  → `'signed/outgoing/99/quyet-dinh-42.pdf'`
 *
 * Giữ nguyên original key bên cạnh (KHÔNG overwrite) — audit trail + rollback
 * nếu ký lại cần file gốc.
 *
 * Throws nếu `originalKey` rỗng/null hoặc `signTransactionId` không phải số dương.
 */
export function buildSignedObjectKey(
  originalKey: string,
  attachmentType: SignAttachmentType,
  signTransactionId: number,
): string {
  if (!originalKey || typeof originalKey !== 'string') {
    throw new Error('originalKey không hợp lệ');
  }
  if (!isValidAttachmentType(attachmentType)) {
    throw new Error('attachmentType không hợp lệ');
  }
  if (!Number.isFinite(signTransactionId) || !Number.isInteger(signTransactionId) || signTransactionId <= 0) {
    throw new Error('signTransactionId phải là số nguyên dương');
  }

  // Lấy basename (phần sau dấu `/` cuối cùng). Fallback `signed.pdf` nếu originalKey
  // kết thúc bằng `/` (không nên xảy ra nhưng defensive).
  const parts = originalKey.split('/');
  const basename = parts[parts.length - 1] || 'signed.pdf';

  return `signed/${attachmentType}/${signTransactionId}/${basename}`;
}

/**
 * Extract extension (lowercase, không dấu chấm).
 * VD: `'report.PDF'` → `'pdf'`. `'file_khong_ext'` → `''`.
 */
export function getFileExtension(fileName: string): string {
  if (!fileName || typeof fileName !== 'string') return '';
  const dot = fileName.lastIndexOf('.');
  if (dot === -1 || dot === fileName.length - 1) return '';
  return fileName.slice(dot + 1).toLowerCase();
}
