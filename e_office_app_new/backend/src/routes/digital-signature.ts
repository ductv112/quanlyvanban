import { Router, type Request, type Response } from 'express';
import { digitalSignatureRepository } from '../repositories/digital-signature.repository.js';
import { handleDbError } from '../lib/error-handler.js';
import { streamFileToResponse } from '../lib/minio/client.js';

const router = Router();

// ============================================================
// GET /preview — Presigned URL cho preview file truoc khi ky
// Query: file_path
// ============================================================
router.get('/preview', async (req: Request, res: Response) => {
  try {
    const filePath = req.query.file_path as string;
    if (!filePath) {
      res.status(400).json({ success: false, message: 'file_path la bat buoc' });
      return;
    }
    // Stream inline qua backend proxy de browser preview (MinIO noi bo, browser khong truy cap duoc)
    const fileName = filePath.split('/').pop() || 'preview.pdf';
    const ext = (fileName.split('.').pop() || '').toLowerCase();
    const mime = ext === 'pdf' ? 'application/pdf' : ext === 'docx' ? 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' : 'application/octet-stream';
    await streamFileToResponse(res, filePath, fileName, mime, true);
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// GET /doc/:docId/:docType — Lay chu ky so theo van ban
// ============================================================
router.get('/doc/:docId/:docType', async (req: Request, res: Response) => {
  try {
    const docId = Number(req.params.docId);
    const docType = req.params.docType as string;

    const rows = await digitalSignatureRepository.getByDoc(docId, docType);
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// GET /:id — Lay chu ky so theo ID
// BUG-PERM-006: validate numeric id trước khi gọi DB để tránh shadowing
// path khác (VD: /tai-khoan-ca-nhan) gây "invalid bigint NaN" 500
// ============================================================
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const idStr = String(req.params.id);
    if (!/^\d+$/.test(idStr)) {
      res.status(404).json({ success: false, message: 'Đường dẫn không hợp lệ' });
      return;
    }
    const id = Number(idStr);
    const row = await digitalSignatureRepository.getById(id);

    if (!row) {
      res.status(404).json({ success: false, message: 'Khong tim thay ban ghi ky so' });
      return;
    }

    res.json({ success: true, data: row });
  } catch (error) {
    handleDbError(error, res);
  }
});

export default router;
