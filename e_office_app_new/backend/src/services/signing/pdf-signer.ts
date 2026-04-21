/**
 * Generic PDF signing layer — Pure JS (không spawn Java/DotNet).
 * Dùng chung cho cả SmartCA VNPT và MySign Viettel (Phase 9+).
 *
 * Flow:
 *   1. addSignaturePlaceholder(pdf)  → PDF có `/Contents <placeholder>` (bytes 0x00)
 *   2. computePdfHash(placeholderPdf) → SHA256 byte range hex
 *   3. Client call provider.sign(hash) → nhận PKCS7 detached base64
 *   4. signPdf(placeholderPdf, signatureBase64) → PDF đã ký hoàn chỉnh
 *
 * Output PDF verify được bằng Adobe Reader (PAdES PKCS7 detached).
 *
 * Note về @signpdf/signpdf v3 API:
 *   SignPdf.sign(pdfBuffer, signer: Signer) yêu cầu 1 `Signer` instance có
 *   async sign(pdf, signingTime) → Buffer PKCS7 raw.
 *   Với use case "signature đã có sẵn từ provider bên ngoài", ta tạo
 *   `PrecomputedSigner` — signer trả về sẵn buffer signature, không ký thật.
 */

import { createHash } from 'node:crypto';
import { SignPdf } from '@signpdf/signpdf';
import { Signer } from '@signpdf/utils';
import { plainAddPlaceholder } from '@signpdf/placeholder-plain';
import type {
  PdfHashResult,
  PdfSignResult,
  PlaceholderOptions,
} from './types.js';

const DEFAULT_SIGNATURE_LENGTH = 16384; // PKCS7 detached thường ~8KB, 16KB để an toàn

/**
 * Signer adapter: trả về signature pre-computed (từ SmartCA / MySign).
 * Bắt buộc phải extend `Signer` vì `SignPdf.sign` dùng instanceof check.
 */
class PrecomputedSigner extends Signer {
  private readonly signatureBuffer: Buffer;

  constructor(signatureBuffer: Buffer) {
    super();
    this.signatureBuffer = signatureBuffer;
  }

  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  async sign(_pdfBuffer: Buffer, _signingTime?: Date): Promise<Buffer> {
    return this.signatureBuffer;
  }
}

/**
 * Thêm signature placeholder vào PDF (PAdES compliant).
 * Placeholder là chuỗi 0x00 (dạng hex "00000...") dài `signatureLength` bytes
 * tại `/Contents <...>`.
 *
 * @throws Error nếu PDF malformed
 */
export function addSignaturePlaceholder(
  pdfBuffer: Buffer,
  options: PlaceholderOptions = {},
): Buffer {
  if (!Buffer.isBuffer(pdfBuffer) || pdfBuffer.length === 0) {
    throw new Error('PDF buffer không hợp lệ (rỗng hoặc không phải Buffer)');
  }

  const header = pdfBuffer.subarray(0, Math.min(8, pdfBuffer.length)).toString('ascii');
  if (!header.startsWith('%PDF-')) {
    throw new Error('File không phải PDF hợp lệ (thiếu header %PDF-)');
  }

  try {
    const withPlaceholder = plainAddPlaceholder({
      pdfBuffer,
      reason: options.reason ?? 'Ký số điện tử',
      contactInfo: options.contactInfo ?? '',
      name: options.name ?? 'E-Office User',
      location: options.location ?? 'Vietnam',
      signatureLength: options.signatureLength ?? DEFAULT_SIGNATURE_LENGTH,
    });
    return withPlaceholder;
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    throw new Error(`Không thể thêm signature placeholder vào PDF: ${msg}`);
  }
}

/**
 * Parse `/ByteRange [ a b c d ]` từ PDF buffer.
 * Trả array 4 số integer hoặc throw nếu không tìm thấy.
 *
 * Lưu ý: placeholder ban đầu có dạng `/ByteRange [0 /********** 0 /**********]`
 * — tức các giá trị thực chưa được fill. Sau khi SignPdf.sign thực thi,
 * chúng được thay bằng giá trị số cụ thể. Ta match cả 2 dạng.
 */
function extractByteRange(pdfBuffer: Buffer): number[] {
  const content = pdfBuffer.toString('binary');
  // Match "/ByteRange [ x y z w ]" với x/y/z/w là số hoặc "/**...*" placeholder
  // Trước khi fill: [0 /********** 0 /**********]
  // Sau khi fill:   [0 100 200 300]
  const numericMatch = content.match(
    /\/ByteRange\s*\[\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s*\]/,
  );
  if (numericMatch) {
    return [
      parseInt(numericMatch[1], 10),
      parseInt(numericMatch[2], 10),
      parseInt(numericMatch[3], 10),
      parseInt(numericMatch[4], 10),
    ];
  }

  // Placeholder chưa fill — cần compute byte range từ vị trí `/Contents <...>`
  const byteRangePos = content.indexOf('/ByteRange');
  if (byteRangePos === -1) {
    throw new Error('PDF không có signature placeholder (không tìm thấy /ByteRange)');
  }

  const contentsStart = content.indexOf('/Contents <', byteRangePos);
  if (contentsStart === -1) {
    throw new Error('PDF không có signature placeholder (không tìm thấy /Contents)');
  }
  const placeholderOpen = content.indexOf('<', contentsStart);
  const placeholderClose = content.indexOf('>', placeholderOpen);
  if (placeholderOpen === -1 || placeholderClose === -1) {
    throw new Error('PDF placeholder `/Contents <...>` malformed');
  }

  // ByteRange: [0, placeholderOpen, placeholderClose+1, totalLen - (placeholderClose+1)]
  return [
    0,
    placeholderOpen,
    placeholderClose + 1,
    pdfBuffer.length - (placeholderClose + 1),
  ];
}

/**
 * Tính SHA256 hash của PDF byte range (không bao gồm vùng `/Contents <...>`).
 * Hash này gửi cho provider để ký (provider trả PKCS7 detached).
 *
 * Input: PDF đã có placeholder (từ `addSignaturePlaceholder`).
 * Nếu truyền PDF chưa có placeholder → throw.
 */
export function computePdfHash(placeholderPdf: Buffer): PdfHashResult {
  if (!Buffer.isBuffer(placeholderPdf) || placeholderPdf.length === 0) {
    throw new Error('PDF buffer không hợp lệ');
  }

  const byteRange = extractByteRange(placeholderPdf);
  const [start1, len1, start2, len2] = byteRange;

  // SHA256 of byte range: (start1..start1+len1) concat (start2..start2+len2)
  const hasher = createHash('sha256');
  hasher.update(placeholderPdf.subarray(start1, start1 + len1));
  hasher.update(placeholderPdf.subarray(start2, start2 + len2));
  const hash = hasher.digest('hex');

  return {
    hash,
    placeholderPdf,
    byteRange,
  };
}

/**
 * Convenience: addSignaturePlaceholder + computePdfHash in 1 step.
 *
 * Input: PDF gốc (chưa có placeholder).
 * Output: hash + placeholderPdf (để pass sau này vào signPdf) + byteRange.
 */
export function prepareSignPdf(
  pdfBuffer: Buffer,
  options: PlaceholderOptions = {},
): PdfHashResult {
  const withPlaceholder = addSignaturePlaceholder(pdfBuffer, options);
  return computePdfHash(withPlaceholder);
}

/**
 * Embed PKCS7 detached signature (base64) vào PDF placeholder.
 *
 * @param placeholderPdf PDF buffer đã có placeholder (từ addSignaturePlaceholder).
 * @param signatureBase64 PKCS7 detached signature (base64) từ provider SmartCA/MySign.
 * @returns PdfSignResult { signedPdf, finalHash }
 * @throws Error nếu PDF không có placeholder hoặc signature không hợp lệ.
 */
export async function signPdf(
  placeholderPdf: Buffer,
  signatureBase64: string,
): Promise<PdfSignResult> {
  if (!Buffer.isBuffer(placeholderPdf)) {
    throw new Error('placeholderPdf phải là Buffer');
  }
  if (typeof signatureBase64 !== 'string' || signatureBase64.trim() === '') {
    throw new Error('signatureBase64 không hợp lệ (rỗng hoặc không phải string)');
  }

  // Validate base64 format (cho phép whitespace/newlines — sẽ strip)
  const cleaned = signatureBase64.replace(/\s/g, '');
  const base64Pattern = /^[A-Za-z0-9+/]+={0,2}$/;
  if (!base64Pattern.test(cleaned)) {
    throw new Error('signatureBase64 không phải base64 hợp lệ');
  }

  let signatureBuffer: Buffer;
  try {
    signatureBuffer = Buffer.from(cleaned, 'base64');
    if (signatureBuffer.length === 0) {
      throw new Error('Signature decode ra 0 bytes');
    }
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    throw new Error(`Không thể decode signature base64: ${msg}`);
  }

  // Verify placeholder exists trước khi ký
  extractByteRange(placeholderPdf); // throws if no placeholder

  try {
    const signer = new PrecomputedSigner(signatureBuffer);
    const signPdfInstance = new SignPdf();
    const signedPdf = await signPdfInstance.sign(placeholderPdf, signer);

    const signedBuffer = Buffer.isBuffer(signedPdf) ? signedPdf : Buffer.from(signedPdf);
    const finalHash = createHash('sha256').update(signedBuffer).digest('hex');

    return {
      signedPdf: signedBuffer,
      finalHash,
    };
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    // Nếu lỗi từ SignPdf là về placeholder → map sang message tiếng Việt
    if (/ByteRange|placeholder|not found/i.test(msg)) {
      throw new Error(`PDF không có signature placeholder hợp lệ: ${msg}`);
    }
    throw new Error(`Không thể embed signature vào PDF: ${msg}`);
  }
}
