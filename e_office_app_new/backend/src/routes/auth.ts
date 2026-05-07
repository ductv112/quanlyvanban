import { Router } from 'express';
import type { Request, Response } from 'express';
import { authService, AuthError } from '../services/auth.service.js';
import { authenticate, type AuthRequest } from '../middleware/auth.js';
import { hashPassword, verifyPassword } from '../lib/auth/password.js';
import { callFunctionOne } from '../lib/db/query.js';

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

// POST /api/auth/change-password — đổi mật khẩu cá nhân (BUG-001 fix)
// Body: { old_password, new_password, confirm_password }
// Yêu cầu: JWT hợp lệ
router.post('/change-password', authenticate, async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const { old_password, new_password, confirm_password } = req.body || {};

    // 1. Validate input
    if (!old_password || !new_password || !confirm_password) {
      res.status(400).json({
        success: false,
        message: 'Vui lòng nhập đầy đủ mật khẩu cũ, mật khẩu mới và xác nhận mật khẩu',
      });
      return;
    }

    if (typeof old_password !== 'string' || typeof new_password !== 'string' || typeof confirm_password !== 'string') {
      res.status(400).json({ success: false, message: 'Định dạng mật khẩu không hợp lệ' });
      return;
    }

    if (new_password !== confirm_password) {
      res.status(400).json({
        success: false,
        message: 'Xác nhận mật khẩu không khớp với mật khẩu mới',
      });
      return;
    }

    if (new_password === old_password) {
      res.status(400).json({
        success: false,
        message: 'Mật khẩu mới không được trùng với mật khẩu cũ',
      });
      return;
    }

    if (new_password.length < 6) {
      res.status(400).json({
        success: false,
        message: 'Mật khẩu mới phải có ít nhất 6 ký tự',
      });
      return;
    }

    // Yêu cầu: chữ hoa + chữ thường + chữ số
    const strongPwRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{6,}$/;
    if (!strongPwRegex.test(new_password)) {
      res.status(400).json({
        success: false,
        message: 'Mật khẩu mới phải có ít nhất 1 chữ hoa, 1 chữ thường và 1 chữ số',
      });
      return;
    }

    // 2. Lay password_hash hien tai qua SP wrapper (tuan thu rule SP-only)
    const staffRow = await callFunctionOne<{ password_hash: string }>(
      'public.fn_auth_get_password_hash',
      [staffId],
    );

    if (!staffRow || !staffRow.password_hash) {
      res.status(404).json({ success: false, message: 'Không tìm thấy người dùng' });
      return;
    }
    const currentHash: string = staffRow.password_hash;

    // 3. bcrypt-compare old password (bcrypt non-deterministic, must compare in app layer)
    if (!verifyPassword(old_password, currentHash)) {
      res.status(400).json({ success: false, message: 'Mật khẩu cũ không đúng' });
      return;
    }

    // 4. Hash new password + call SP atomic update + revoke tokens
    const newHash = hashPassword(new_password);
    const result = await callFunctionOne<{ success: boolean; message: string }>(
      'public.fn_staff_change_password',
      [staffId, currentHash, newHash],
    );

    if (!result || !result.success) {
      res.status(400).json({
        success: false,
        message: result?.message || 'Đổi mật khẩu thất bại',
      });
      return;
    }

    // 4. Clear refresh cookie (force re-login moi devices vi SP da revoke all tokens)
    res.clearCookie('refreshToken', { path: '/api/auth' });

    res.json({ success: true, message: result.message });
  } catch (error) {
    if (error instanceof AuthError) {
      res.status(error.statusCode).json({ success: false, message: error.message });
      return;
    }
    throw error;
  }
});

export default router;
