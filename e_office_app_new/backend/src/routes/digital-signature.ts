import { Router, type Request, type Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { digitalSignatureRepository } from '../repositories/digital-signature.repository.js';
import { getSigningService } from '../services/signing.service.js';
import { handleDbError } from '../lib/error-handler.js';
import { getFileUrl } from '../lib/minio/client.js';

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
    const url = await getFileUrl(filePath, 3600);
    res.json({ success: true, data: { url } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// POST /sign/smart-ca — Ky so qua SmartCA (2-step: initiate -> OTP)
// Body: { doc_id, doc_type, file_path }
// ============================================================
router.post('/sign/smart-ca', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const { doc_id, doc_type, file_path } = req.body;

    if (!doc_id || !doc_type) {
      res.status(400).json({ success: false, message: 'doc_id va doc_type la bat buoc' });
      return;
    }

    const service = await getSigningService();
    const result = await service.signSmartCA({
      doc_id: Number(doc_id),
      doc_type,
      staff_id: staffId,
      file_path: file_path || null,
    });

    res.status(result.success ? 201 : 400).json(result);
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// POST /sign/esign-neac — Ky so qua EsignNEAC (1-step)
// Body: { doc_id, doc_type, file_path, ca_provider }
// ============================================================
router.post('/sign/esign-neac', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const { doc_id, doc_type, file_path, ca_provider } = req.body;

    if (!doc_id || !doc_type) {
      res.status(400).json({ success: false, message: 'doc_id va doc_type la bat buoc' });
      return;
    }

    const service = await getSigningService();
    const result = await service.signEsignNEAC({
      doc_id: Number(doc_id),
      doc_type,
      staff_id: staffId,
      file_path: file_path || null,
      ca_provider: ca_provider || 'vnpt-ca',
    });

    res.status(result.success ? 201 : 400).json(result);
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// POST /sign/verify-otp — Xac thuc OTP cho SmartCA
// Body: { signature_id, otp }
// ============================================================
router.post('/sign/verify-otp', async (req: Request, res: Response) => {
  try {
    const { signature_id, otp } = req.body;

    if (!signature_id || !otp) {
      res.status(400).json({ success: false, message: 'signature_id va otp la bat buoc' });
      return;
    }

    const service = await getSigningService();
    const result = await service.verifyOTP(Number(signature_id), otp);

    res.status(result.success ? 200 : 400).json(result);
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
// ============================================================
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
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

// ============================================================
// MOCK: Ký số giả lập per-attachment
// ============================================================

router.post('/mock/sign', async (req: Request, res: Response) => {
  try {
    const { attachment_id, attachment_type } = req.body;
    if (!attachment_id || !attachment_type) {
      res.status(400).json({ success: false, message: 'attachment_id và attachment_type là bắt buộc' });
      return;
    }
    const { callFunctionOne } = await import('../lib/db/query.js');
    const result = await callFunctionOne<{ success: boolean; message: string }>(
      'edoc.fn_attachment_mock_sign', [Number(attachment_id), attachment_type, (req as AuthRequest).user.staffId],
    );
    res.json({ success: result?.success ?? false, message: result?.message ?? 'Lỗi' });
  } catch (error) {
    handleDbError(error, res);
  }
});

router.post('/mock/verify', async (req: Request, res: Response) => {
  try {
    const { attachment_id, attachment_type } = req.body;
    if (!attachment_id || !attachment_type) {
      res.status(400).json({ success: false, message: 'attachment_id và attachment_type là bắt buộc' });
      return;
    }
    const { callFunctionOne } = await import('../lib/db/query.js');
    const result = await callFunctionOne<{ is_valid: boolean; signer_name: string; sign_date: string; message: string }>(
      'edoc.fn_attachment_mock_verify', [Number(attachment_id), attachment_type],
    );
    res.json({ success: true, data: result });
  } catch (error) {
    handleDbError(error, res);
  }
});

export default router;
