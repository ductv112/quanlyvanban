import type { Response } from 'express';
import { streamFileToResponse } from './minio/client.js';
import { convertOfficeToPdf, isOfficeMime } from './office-converter.js';

/** MIME được preview NATIVE (không cần convert) */
const NATIVE_PREVIEW_MIME = new Set<string>([
  'application/pdf',
  'image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/bmp', 'image/svg+xml',
  'text/plain', 'text/csv',
]);

export function isPreviewableMime(mime: string | null | undefined): boolean {
  if (!mime) return false;
  const m = mime.toLowerCase().split(';')[0].trim();
  return NATIVE_PREVIEW_MIME.has(m) || isOfficeMime(m);
}

/**
 * Branch theo MIME:
 *  - PDF / image / text → stream inline luôn
 *  - Office (doc/docx/xls/...) → convert → stream PDF inline
 *  - MIME khác → trả 415 Unsupported (JSON), KHÔNG stream
 *
 * AuthN/AuthZ: caller phải kiểm tra quyền + load attachment row TRƯỚC khi gọi helper này.
 *
 * @param params.filePath MinIO path của file (đã verify ownership)
 * @param params.contentType MIME của file (từ AttachmentRow.content_type hoặc mime_type)
 * @param params.attachmentId DB id (dùng cache key cho Office convert)
 * @param params.fileName Tên file gốc (cho header Content-Disposition)
 */
export async function handleAttachmentPreview(
  res: Response,
  params: {
    filePath: string;
    contentType: string | null | undefined;
    attachmentId: number;
    fileName: string;
  },
): Promise<void> {
  const mime = (params.contentType || '').toLowerCase().split(';')[0].trim();

  if (NATIVE_PREVIEW_MIME.has(mime)) {
    await streamFileToResponse(res, params.filePath, params.fileName, mime, /* inline */ true);
    return;
  }

  if (isOfficeMime(mime)) {
    const previewPath = await convertOfficeToPdf(params.filePath, params.attachmentId);
    // Đổi extension trong filename: foo.docx → foo.pdf
    const pdfFileName = params.fileName.replace(/\.[^.]+$/, '') + '.pdf';
    await streamFileToResponse(res, previewPath, pdfFileName, 'application/pdf', /* inline */ true);
    return;
  }

  res.status(415).json({
    success: false,
    message: 'Loại file không hỗ trợ xem trực tiếp. Vui lòng tải xuống để mở bằng ứng dụng phù hợp.',
  });
}
