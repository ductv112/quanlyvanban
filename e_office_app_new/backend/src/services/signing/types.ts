/**
 * Generic PDF signing types — shared between pdf-signer và adapter layers (Phase 9+).
 *
 * Các type này là "contract" giữa generic layer (pdf-signer.ts) và các provider
 * adapter (SmartCA VNPT / MySign Viettel) — mọi adapter phải trả về PKCS7 detached
 * signature base64, sau đó gọi signPdf() để embed vào PDF placeholder.
 */

/**
 * Metadata embed vào signature placeholder.
 * Hiển thị trong Adobe Reader "Signature Properties" panel.
 */
export interface SignatureMetadata {
  /** Lý do ký (hiển thị trong PDF) — VD: "Phê duyệt văn bản" */
  reason?: string;

  /** Email/thông tin liên lạc */
  contactInfo?: string;

  /** Tên người ký — VD: "Nguyễn Văn A" */
  name?: string;

  /** Địa điểm ký — VD: "Hà Nội" */
  location?: string;
}

/**
 * Kết quả computePdfHash: PDF đã có placeholder + SHA256 byte range.
 * Client gọi provider với `hash`, provider trả PKCS7 signature base64.
 * Sau đó dùng `placeholderPdf` + signature để embed → output final PDF.
 */
export interface PdfHashResult {
  /** SHA256 hex của byte range (PAdES) — gửi cho provider để ký */
  hash: string;

  /** PDF Buffer đã insert placeholder `/Contents <...>` — giữ lại để embed signature */
  placeholderPdf: Buffer;

  /** Byte range array [start1, len1, start2, len2] — debug/verify PAdES compliance */
  byteRange: number[];
}

/**
 * Kết quả sau khi embed signature vào placeholder.
 */
export interface PdfSignResult {
  /** PDF buffer đã ký hoàn chỉnh — verify được bằng Adobe Reader */
  signedPdf: Buffer;

  /** SHA256 hex của PDF final (để log/audit) */
  finalHash: string;
}

/**
 * Options cho `addSignaturePlaceholder()` — wrapper quanh @signpdf/placeholder-plain.
 */
export interface PlaceholderOptions extends SignatureMetadata {
  /**
   * Độ dài placeholder (bytes). PKCS7 detached thường ~8KB, set 16384 để an toàn.
   * @default 16384
   */
  signatureLength?: number;
}
