import multer from 'multer';

const MAX_FILE_SIZE = Number(process.env.MAX_FILE_SIZE) || 50 * 1024 * 1024; // 50MB default

export const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_FILE_SIZE },
  // Fix: Multer decode originalname = latin1 default -> ten file tieng Viet mojibake.
  // Convert latin1 bytes thanh utf-8 thuan tuy cho dung ten file Unicode.
  fileFilter: (_req, file, cb) => {
    file.originalname = Buffer.from(file.originalname, 'latin1').toString('utf8');
    cb(null, true);
  },
});
