/**
 * Helpers cho tính năng xem trực tiếp file đính kèm.
 *
 * Modal preview fetch file qua axios (responseType: 'blob') → tạo blob URL →
 * set vào iframe / img / pre. Cookie auth được giữ qua axios interceptor.
 */

/** Module type — quyết định API path prefix */
export type PreviewModule = 'van-ban-den' | 'van-ban-di' | 'van-ban-du-thao' | 'ho-so-cong-viec';

const MODULE_API_PREFIX: Record<PreviewModule, string> = {
  'van-ban-den': '/van-ban-den',
  'van-ban-di': '/van-ban-di',
  'van-ban-du-thao': '/van-ban-du-thao',
  'ho-so-cong-viec': '/ho-so-cong-viec',
};

/** Build API path cho preview endpoint (relative to api baseURL) */
export function buildPreviewUrl(
  module: PreviewModule,
  docId: number | string,
  attachmentId: number | string,
): string {
  return `${MODULE_API_PREFIX[module]}/${docId}/dinh-kem/${attachmentId}/preview`;
}

/** Build API path cho download endpoint (fallback khi preview unsupported) */
export function buildDownloadUrl(
  module: PreviewModule,
  docId: number | string,
  attachmentId: number | string,
): string {
  return `${MODULE_API_PREFIX[module]}/${docId}/dinh-kem/${attachmentId}/download`;
}

/** Native preview kinds (xác định cách render trong Modal) */
export type PreviewKind = 'pdf' | 'image' | 'text' | 'office' | 'unsupported';

const NATIVE_PDF = 'application/pdf';
const IMAGE_PREFIX = 'image/';
const TEXT_PREFIX = 'text/';
const OFFICE_MIMES = new Set<string>([
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.ms-excel',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'application/vnd.ms-powerpoint',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'application/rtf', 'text/rtf',
  'application/vnd.oasis.opendocument.text',
  'application/vnd.oasis.opendocument.spreadsheet',
  'application/vnd.oasis.opendocument.presentation',
]);

/**
 * Phán đoán preview kind từ MIME + file extension fallback.
 * MIME ưu tiên — extension chỉ dùng khi MIME thiếu (vì SP có thể chưa lưu).
 */
export function getPreviewKind(mime: string | null | undefined, fileName: string): PreviewKind {
  const m = (mime || '').toLowerCase().split(';')[0].trim();
  if (m === NATIVE_PDF) return 'pdf';
  if (m.startsWith(IMAGE_PREFIX)) return 'image';
  if (m.startsWith(TEXT_PREFIX)) return 'text';
  if (OFFICE_MIMES.has(m)) return 'office';

  // Fallback theo extension nếu MIME thiếu
  const ext = (fileName.split('.').pop() || '').toLowerCase();
  if (ext === 'pdf') return 'pdf';
  if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg'].includes(ext)) return 'image';
  if (['txt', 'csv', 'log', 'md'].includes(ext)) return 'text';
  if (['doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'rtf', 'odt', 'ods', 'odp'].includes(ext)) return 'office';

  return 'unsupported';
}

/** Có thể preview hay không */
export function isPreviewable(mime: string | null | undefined, fileName: string): boolean {
  return getPreviewKind(mime, fileName) !== 'unsupported';
}

/** Alias cho consistency với backend isPreviewableMime */
export function isPreviewableMime(mime: string | null | undefined): boolean {
  if (!mime) return false;
  const m = mime.toLowerCase().split(';')[0].trim();
  return m === NATIVE_PDF
    || m.startsWith(IMAGE_PREFIX)
    || m.startsWith(TEXT_PREFIX)
    || OFFICE_MIMES.has(m);
}
