import { Router } from 'express';
import type { Request, Response } from 'express';
import { authService, AuthError } from '../services/auth.service.js';
import { authenticate, type AuthRequest } from '../middleware/auth.js';

const router = Router();

// POST /api/auth/login
router.post('/login', async (req: Request, res: Response) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      res.status(400).json({ success: false, message: 'Vui lòng nhập tên đăng nhập và mật khẩu' });
      return;
    }

    const ipAddress = (req.headers['x-forwarded-for'] as string) || req.ip || '';
    const userAgent = req.headers['user-agent'] || '';

    const result = await authService.login(username, password, ipAddress, userAgent);

    // Set refresh token as httpOnly cookie
    res.cookie('refreshToken', result.refreshToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days
      path: '/api/auth',
    });

    res.json({
      success: true,
      data: {
        accessToken: result.accessToken,
        user: result.user,
      },
    });
  } catch (error) {
    if (error instanceof AuthError) {
      res.status(error.statusCode).json({ success: false, message: error.message });
      return;
    }
    throw error;
  }
});

// POST /api/auth/refresh
router.post('/refresh', async (req: Request, res: Response) => {
  try {
    const refreshToken = req.cookies?.refreshToken;
    if (!refreshToken) {
      res.status(401).json({ success: false, message: 'Không tìm thấy refresh token' });
      return;
    }

    const result = await authService.refresh(refreshToken);

    // Set new refresh token cookie (rotation)
    res.cookie('refreshToken', result.refreshToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      maxAge: 7 * 24 * 60 * 60 * 1000,
      path: '/api/auth',
    });

    res.json({
      success: true,
      data: { accessToken: result.accessToken },
    });
  } catch (error) {
    if (error instanceof AuthError) {
      // Clear invalid cookie
      res.clearCookie('refreshToken', { path: '/api/auth' });
      res.status(error.statusCode).json({ success: false, message: error.message });
      return;
    }
    throw error;
  }
});

// POST /api/auth/logout
router.post('/logout', async (req: Request, res: Response) => {
  try {
    const refreshToken = req.cookies?.refreshToken;
    if (refreshToken) {
      await authService.logout(refreshToken);
    }

    res.clearCookie('refreshToken', { path: '/api/auth' });
    res.json({ success: true, message: 'Đăng xuất thành công' });
  } catch {
    // Always clear cookie even if DB operation fails
    res.clearCookie('refreshToken', { path: '/api/auth' });
    res.json({ success: true, message: 'Đăng xuất thành công' });
  }
});

// GET /api/auth/me
router.get('/me', authenticate, async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const profile = await authService.getMe(staffId);

    res.json({ success: true, data: profile });
  } catch (error) {
    if (error instanceof AuthError) {
      res.status(error.statusCode).json({ success: false, message: error.message });
      return;
    }
    throw error;
  }
});

export default router;
