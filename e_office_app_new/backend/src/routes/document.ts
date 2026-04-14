import { Router, type Request, type Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import type { AuthRequest } from '../middleware/auth.js';
import { upload } from '../middleware/upload.js';
import { documentRepository } from '../repositories/document.repository.js';
import { uploadFile, deleteFile } from '../lib/minio/client.js';
import { handleDbError } from '../lib/error-handler.js';

const router = Router();

// ============================================================
// DANH MỤC TÀI LIỆU (DOCUMENT CATEGORIES)
// ============================================================

// GET /danh-muc — Cây danh mục tài liệu
router.get('/danh-muc', async (req: Request, res: Response) => {
  try {
    const { unitId } = (req as AuthRequest).user;
    const data = await documentRepository.getCategoryTree(unitId);
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /danh-muc — Tạo danh mục
router.post('/danh-muc', async (req: Request, res: Response) => {
  try {
    const { staffId, unitId } = (req as AuthRequest).user;
    const b = req.body;

    if (!b.name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên danh mục là bắt buộc' });
      return;
    }

    const result = await documentRepository.createCategory(
      b.parent_id ?? 0,
      b.code ?? null,
      b.name.trim(),
      b.date_process ?? null,
      b.description ?? null,
      b.version ?? null,
      unitId,
      staffId,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.status(201).json({ success: true, message: result.message, data: { id: result.id } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PUT /danh-muc/:id — Cập nhật danh mục
router.put('/danh-muc/:id', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const b = req.body;

    if (!b.name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên danh mục là bắt buộc' });
      return;
    }

    const result = await documentRepository.updateCategory(
      id,
      b.parent_id ?? 0,
      b.code ?? null,
      b.name.trim(),
      b.date_process ?? null,
      b.status ?? 1,
      b.description ?? null,
      b.version ?? null,
      staffId,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /danh-muc/:id — Xóa danh mục
router.delete('/danh-muc/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const result = await documentRepository.deleteCategory(id);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// TÀI LIỆU (DOCUMENTS)
// ============================================================

// GET / — Danh sách tài liệu (phân trang)
// T-05-07: filter by unitId from JWT
router.get('/', async (req: Request, res: Response) => {
  try {
    const { unitId } = (req as AuthRequest).user;
    const categoryId = req.query.category_id ? Number(req.query.category_id) : null;
    const keyword = (req.query.keyword as string) || null;
    const page = Number(req.query.page) || 1;
    const pageSize = Number(req.query.page_size) || 20;

    const rows = await documentRepository.getDocumentList(unitId, categoryId, keyword, page, pageSize);
    const total = rows.length > 0 ? Number(rows[0].total_count) : 0;
    res.json({ success: true, data: rows, total, page, page_size: pageSize });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /:id — Chi tiết tài liệu
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const data = await documentRepository.getDocumentById(id);
    if (!data) {
      res.status(404).json({ success: false, message: 'Không tìm thấy tài liệu' });
      return;
    }
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST / — Tạo tài liệu (với file upload tùy chọn)
// T-05-06: Multer 50MB limit + mime type validation
router.post('/', upload.single('file'), async (req: Request, res: Response) => {
  try {
    const { staffId, unitId } = (req as AuthRequest).user;
    const b = req.body;

    if (!b.title?.trim()) {
      res.status(400).json({ success: false, message: 'Tiêu đề tài liệu là bắt buộc' });
      return;
    }

    let fileName: string | null = null;
    let filePath: string | null = null;
    let fileSize: number | null = null;
    let mimeType: string | null = null;

    // Upload file to MinIO if provided
    if (req.file) {
      const originalName = req.file.originalname;
      const fileUuid = uuidv4();
      const objectPath = `tai-lieu/${fileUuid}/${originalName}`;

      await uploadFile(objectPath, req.file.buffer, req.file.mimetype);

      fileName = originalName;
      filePath = objectPath;
      fileSize = req.file.size;
      mimeType = req.file.mimetype;
    }

    const result = await documentRepository.createDocument(
      unitId,
      b.category_id ? Number(b.category_id) : null,
      b.title.trim(),
      b.description ?? null,
      fileName,
      filePath,
      fileSize,
      mimeType,
      b.keyword ?? null,
      b.status ? Number(b.status) : 1,
      staffId, // T-05-08: always from JWT
    );

    if (!result.success) {
      // Clean up uploaded file on DB failure
      if (filePath) {
        await deleteFile(filePath).catch(() => null);
      }
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.status(201).json({ success: true, message: result.message, data: { id: result.id } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PUT /:id — Cập nhật tài liệu (file upload tùy chọn)
// T-05-06: Multer 50MB limit
router.put('/:id', upload.single('file'), async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const b = req.body;

    if (!b.title?.trim()) {
      res.status(400).json({ success: false, message: 'Tiêu đề tài liệu là bắt buộc' });
      return;
    }

    let fileName: string | null = null;
    let filePath: string | null = null;
    let fileSize: number | null = null;
    let mimeType: string | null = null;

    if (req.file) {
      const originalName = req.file.originalname;
      const fileUuid = uuidv4();
      const objectPath = `tai-lieu/${fileUuid}/${originalName}`;

      await uploadFile(objectPath, req.file.buffer, req.file.mimetype);

      fileName = originalName;
      filePath = objectPath;
      fileSize = req.file.size;
      mimeType = req.file.mimetype;
    }

    const result = await documentRepository.updateDocument(
      id,
      b.category_id ? Number(b.category_id) : null,
      b.title.trim(),
      b.description ?? null,
      fileName,
      filePath,
      fileSize,
      mimeType,
      b.keyword ?? null,
      b.status ? Number(b.status) : 1,
      staffId,
    );

    if (!result.success) {
      if (filePath) {
        await deleteFile(filePath).catch(() => null);
      }
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /:id — Xóa tài liệu (soft delete)
router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const result = await documentRepository.deleteDocument(id);
    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

export default router;
