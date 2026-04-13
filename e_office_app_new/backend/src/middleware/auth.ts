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
