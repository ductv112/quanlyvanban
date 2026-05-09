import type { Request, Response, NextFunction } from 'express';
import type { AuthRequest } from './auth.js';

/**
 * Phase 31 fix(BUG-VB-DI-001/002, BUG-DT-005): Attachment edit permission guard.
 *
 * POST/DELETE attachment routes ban đầu KHÔNG check trạng thái VB → cho phép user
 * thay đổi attachment trên VB đã được duyệt/phát hành/hoàn thành. Vi phạm
 * nghiệp vụ: VB đã release ra ngoài thì không được sửa.
 *
 * Middleware này load doc bằng loadFn (truyền từ route, vì mỗi loại VB có
 * repository khác nhau), sau đó check `canEdit`:
 *   - approved === true   → 403 (đã duyệt, không sửa)
 *   - is_released === true → 403 (đã phát hành, không sửa)
 *   - status released/completed → 403
 * Nếu OK, attach `req.doc` và call next.
 *
 * Usage:
 *   router.post('/:id/dinh-kem',
 *     loadDocAndCanEdit(id => outgoingDocRepository.getById(id, ctxStaffId)),
 *     upload.single('file'),
 *     async (req, res) => { ... }
 *   );
 */

export interface DocEditableShape {
  id?: number | string;
  approved?: boolean;
  is_released?: boolean;
  status?: string;
  // Allow extra fields without breaking type
  [key: string]: unknown;
}

/**
 * Load doc by id (from req.params.id) and reject with 403 if it's been
 * approved/released/completed.
 *
 * @param loadFn  Async fn that loads doc by id (and optionally staffId for ACL).
 *                Receives (id, req) — implementor can pull staffId/etc from req.
 */
export function loadDocAndCanEdit(
  loadFn: (id: number, req: AuthRequest) => Promise<DocEditableShape | null>,
) {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const id = Number(req.params.id);
      if (!Number.isFinite(id) || id <= 0) {
        res.status(400).json({ success: false, message: 'ID không hợp lệ' });
        return;
      }

      const doc = await loadFn(id, req as AuthRequest);
      if (!doc) {
        res.status(404).json({ success: false, message: 'Không tìm thấy văn bản' });
        return;
      }

      // Reject if doc has been approved / released / completed
      const isLocked =
        doc.approved === true ||
        doc.is_released === true ||
        doc.status === 'released' ||
        doc.status === 'completed' ||
        doc.status === 'approved';

      if (isLocked) {
        res.status(403).json({
          success: false,
          message: 'Văn bản đã duyệt/phát hành — không thể chỉnh sửa file đính kèm',
        });
        return;
      }

      // Stash doc on req for downstream handler reuse
      (req as AuthRequest & { doc?: DocEditableShape }).doc = doc;
      next();
    } catch (err) {
      next(err);
    }
  };
}
