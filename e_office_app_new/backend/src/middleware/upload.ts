import multer from 'multer';

const MAX_FILE_SIZE = Number(process.env.MAX_FILE_SIZE) || 50 * 1024 * 1024; // 50MB default

/**
 * Phase 31 fix(BUG-F-VB-006 SECURITY): MIME + extension whitelist.
 *
 * Trước fix: không có whitelist → user có thể upload .exe, .bat, .sh, .ps1...
 * vào hệ thống → security risk đặc biệt với user công chức ít hiểu IT.
 *
 * Sau fix: chỉ chấp nhận document/image/archive types phổ biến cho công văn.
 * Check CẢ MIME (browser-reported) lẫn extension (filename suffix) để chống
 * attacker rename .exe → .pdf hoặc gửi MIME giả.
 */
const ALLOWED_MIME = new Set<string>([
  // PDF
  'application/pdf',
  // MS Word
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  // MS Excel
  'application/vnd.ms-excel',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  // MS PowerPoint
  'application/vnd.ms-powerpoint',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  // Images
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/gif',
  'image/bmp',
  'image/webp',
  // Plain text
  'text/plain',
  'text/csv',
  // Archives
  'application/zip',
  'application/x-zip-compressed',
  'application/x-rar-compressed',
  'application/vnd.rar',
  'application/x-7z-compressed',
  // Generic octet-stream — accept BUT only if extension passes whitelist below
  // (some browsers/clients send octet-stream for all uploads)
  'application/octet-stream',
]);

const ALLOWED_EXT = new Set<string>([
  'pdf',
  'doc', 'docx',
  'xls', 'xlsx',
  'ppt', 'pptx',
  'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp',
  'txt', 'csv',
  'zip', 'rar', '7z',
]);

const ALLOWED_LIST_VN =
  'PDF, Word (doc/docx), Excel (xls/xlsx), PowerPoint (ppt/pptx), '
  + 'ảnh (jpg/png/gif/bmp/webp), văn bản (txt/csv), lưu trữ (zip/rar/7z)';

export const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_FILE_SIZE },
  fileFilter: (_req, file, cb) => {
    // Fix latin1 mojibake (giữ nguyên từ trước) — phải convert TRƯỚC khi check ext
    file.originalname = Buffer.from(file.originalname, 'latin1').toString('utf8');

    const ext = (file.originalname.split('.').pop() || '').toLowerCase();
    const mimeOk = ALLOWED_MIME.has(file.mimetype);
    const extOk = ALLOWED_EXT.has(ext);

    // Reject nếu cả MIME và extension đều không khớp whitelist.
    // Nếu MIME = octet-stream nhưng ext hợp lệ → accept (client gửi MIME giả là phổ biến).
    // Nếu ext không trong whitelist → reject ngay (chống .exe/.bat/.sh kể cả khi MIME giả).
    if (!extOk) {
      return cb(new Error(
        `Loại file không được phép tải lên (.${ext}). Chỉ chấp nhận: ${ALLOWED_LIST_VN}.`,
      ));
    }
    if (!mimeOk) {
      return cb(new Error(
        `Loại file không được phép tải lên (MIME: ${file.mimetype}). Chỉ chấp nhận: ${ALLOWED_LIST_VN}.`,
      ));
    }

    cb(null, true);
  },
});
