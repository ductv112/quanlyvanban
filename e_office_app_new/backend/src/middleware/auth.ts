import type { Request, Response, NextFunction } from 'express';
import { verifyToken, type TokenPayload } from '../lib/auth/jwt.js';
import { rawQuery } from '../lib/db/query.js';

export interface AuthRequest extends Request {
  user: TokenPayload;
}

export function authenticate(req: Request, res: Response, next: NextFunction): void {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    res.status(401).json({ success: false, message: 'Unauthorized' });
    return;
  }

  const token = authHeader.slice(7);
  verifyToken(token)
    .then((payload) => {
      (req as AuthRequest).user = payload;
      next();
    })
    .catch(() => {
      res.status(401).json({ success: false, message: 'Token expired or invalid' });
    });
}

export function requireRoles(...roles: string[]) {
  return (req: Request, res: Response, next: NextFunction): void => {
    const user = (req as AuthRequest).user;
    if (!user) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }
    const hasRole = roles.some((role) => user.roles.includes(role));
    if (!hasRole) {
      res.status(403).json({ success: false, message: 'Forbidden — insufficient permissions' });
      return;
    }
    next();
  };
}

/**
 * Variant of requireRoles that — instead of returning 403 on permission fail —
 * skips to the next mounted router (Express `next('router')`).
 *
 * Use case: 2 routers mounted on the same prefix (e.g. /api/quan-tri):
 *   - adminCatalogRoutes (rich admin endpoints)
 *   - publicCatalogRoutes (read-only catalog for non-admin form pickers)
 *
 * Mount admin FIRST with this middleware so admin users get full handler;
 * non-admin users fall through to public-catalog (which has its own filtering).
 *
 * This resolves the "shadow mount" bug (BUG-CATALOG-SHADOW) without breaking
 * non-admin form pickers that depend on /api/quan-tri/nguoi-dung etc.
 */
export function requireRolesOrNext(...roles: string[]) {
  return (req: Request, res: Response, next: NextFunction): void => {
    const user = (req as AuthRequest).user;
    if (!user) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }
    const hasRole = roles.some((role) => user.roles.includes(role));
    if (!hasRole) {
      // Skip to next mounted router instead of returning 403
      next('router');
      return;
    }
    next();
  };
}

/**
 * Map admin path prefix → right_id (public.rights table).
 * Mỗi entry là path prefix của route → quyền tương ứng user cần để CRUD.
 */
const ADMIN_PATH_RIGHT_MAP: { prefix: string; rightId: number }[] = [
  // admin.ts
  { prefix: '/don-vi', rightId: 14 },        // Đơn vị
  { prefix: '/chuc-vu', rightId: 17 },        // Chức vụ
  { prefix: '/nguoi-dung', rightId: 15 },     // Người dùng
  { prefix: '/nhom-quyen', rightId: 16 },     // Nhóm quyền
  { prefix: '/lookup', rightId: 15 },         // Lookup endpoints (dropdown role/position khi tao user — gan voi right Nguoi dung de Admin So co right 15 goi duoc, KHONG can right Phan quyen/Chuc vu)
  { prefix: '/chuc-nang', rightId: 13 },      // Quản trị (root)
  // admin-catalog.ts — tất cả thuộc nhóm "Danh mục" (right 18)
  { prefix: '/loai-van-ban', rightId: 18 },
  { prefix: '/linh-vuc', rightId: 18 },
  { prefix: '/so-van-ban', rightId: 18 },
  { prefix: '/nguoi-ky', rightId: 18 },
  { prefix: '/co-quan', rightId: 18 },
  { prefix: '/dia-ban', rightId: 18 },
  { prefix: '/mau-email', rightId: 18 },
  { prefix: '/mau-sms', rightId: 18 },
  { prefix: '/thuoc-tinh-van-ban', rightId: 18 },
  { prefix: '/nhom-lam-viec', rightId: 18 },
  { prefix: '/uy-quyen', rightId: 18 },
  { prefix: '/cau-hinh-truong', rightId: 13 }, // Cấu hình thuộc Quản trị
  { prefix: '/cau-hinh', rightId: 13 },
  { prefix: '/lich-lam-viec', rightId: 6 },    // Lịch làm việc
];

/**
 * Helper: check user có right cụ thể qua role_of_staff × action_of_role.
 */
async function userHasRight(staffId: number, rightId: number): Promise<boolean> {
  try {
    const rows = await rawQuery<{ ok: number }>(
      `SELECT 1 AS ok FROM public.role_of_staff rs
        JOIN public.action_of_role ar ON ar.role_id = rs.role_id
        WHERE rs.staff_id = $1 AND ar.right_id = $2
        LIMIT 1`,
      [staffId, rightId],
    );
    return rows.length > 0;
  } catch {
    return false;
  }
}

/**
 * Middleware single-right: check user có right_id cụ thể (vd: cấu hình ký số).
 * Pass → next(). Fail → 403 Forbidden.
 *
 * v3.2.2 fix #M9: TRUOC tra next('router') -> fall through -> Express khong tim
 * route match -> 404 Not Found. Sai semantic — user co quyen XEM endpoint nhung
 * thieu RIGHT cu the. 404 lam user nghi route khong ton tai (huong loi sai).
 * Sau: 403 Forbidden voi message tieng Viet -> client biet ro la auth issue,
 * khong rebreak path tim kiem route.
 *
 * Ten ham "OrNext" giu nguyen de tranh churn import — semantic now la "OrForbidden"
 * (chi LGSP routes su dung, khong co fall-through router phia sau).
 */
export function requireRightOrNext(rightId: number) {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    const user = (req as AuthRequest).user;
    if (!user) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }
    if (await userHasRight(user.staffId, rightId)) {
      next();
      return;
    }
    res.status(403).json({
      success: false,
      message: 'Khong co quyen truy cap chuc nang nay',
    });
  };
}

/**
 * Path-aware permission middleware: check action_of_role table cho user
 * theo right_id tương ứng với path prefix.
 *
 * - User có role "Quản trị hệ thống" → bypass (vì admin role đã có sẵn 22 rights).
 *   Tuy nhiên check tự nhiên qua action_of_role cũng pass; bypass chỉ là optimization.
 * - User có rights phù hợp (qua role_of_staff → action_of_role) → next().
 * - User không có rights → next('router') → fall through sang publicCatalog
 *   (chỉ phục vụ GET read-only) hoặc 404 nếu publicCatalog cũng không có route.
 *
 * Path không match prefix nào → next('router') (chấp nhận skipping admin guards
 * và để adminRoutes/adminCatalogRoutes router tự handle hoặc fall through tiếp).
 */
export function requireRightByPathOrNext() {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    const user = (req as AuthRequest).user;
    if (!user) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }
    const path = req.path;
    const match = ADMIN_PATH_RIGHT_MAP.find((m) => path === m.prefix || path.startsWith(`${m.prefix}/`));
    if (!match) {
      // Path không thuộc admin-guarded scope → fall through để router khác xử lý.
      next('router');
      return;
    }
    if (await userHasRight(user.staffId, match.rightId)) {
      next();
      return;
    }
    next('router');
  };
}
