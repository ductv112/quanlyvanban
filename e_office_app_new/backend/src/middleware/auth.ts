import type { Request, Response, NextFunction } from 'express';
import { verifyToken, type TokenPayload } from '../lib/auth/jwt.js';

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
