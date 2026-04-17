import { createHash } from 'node:crypto';
import { authRepository } from '../repositories/auth.repository.js';
import { verifyPassword } from '../lib/auth/password.js';
import { signAccessToken, signRefreshToken, verifyToken } from '../lib/auth/jwt.js';
import type { TokenPayload } from '../lib/auth/jwt.js';

function hashToken(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}

function parseRoles(rolesStr: string): string[] {
  return rolesStr ? rolesStr.split(',').map((r) => r.trim()) : [];
}

interface LoginResult {
  accessToken: string;
  refreshToken: string;
  user: {
    staffId: number;
    unitId: number;
    departmentId: number;
    username: string;
    fullName: string;
    email: string;
    phone: string;
    image: string;
    isAdmin: boolean;
    positionName: string;
    departmentName: string;
    unitName: string;
    roles: string[];
  };
}

export const authService = {
  async login(
    username: string,
    password: string,
    ipAddress: string,
    userAgent: string,
  ): Promise<LoginResult> {
    const staff = await authRepository.findByUsername(username);

    if (!staff) {
      await authRepository.logLogin(null, username, ipAddress, userAgent, false);
      throw new AuthError('Tên đăng nhập hoặc mật khẩu không đúng', 401);
    }

    if (staff.is_deleted) {
      await authRepository.logLogin(staff.staff_id, username, ipAddress, userAgent, false);
      throw new AuthError('Tài khoản đã bị xóa', 401);
    }

    if (staff.is_locked) {
      await authRepository.logLogin(staff.staff_id, username, ipAddress, userAgent, false);
      throw new AuthError('Tài khoản đã bị khóa', 403);
    }

    const valid = verifyPassword(password, staff.password_hash);
    if (!valid) {
      await authRepository.logLogin(staff.staff_id, username, ipAddress, userAgent, false);
      throw new AuthError('Tên đăng nhập hoặc mật khẩu không đúng', 401);
    }

    const roles = parseRoles(staff.roles);

    // Generate tokens
    const accessToken = await signAccessToken({
      staffId: staff.staff_id,
      departmentId: staff.department_id,
      username: staff.username,
      roles,
      isAdmin: staff.is_admin,
    });

    const refreshToken = await signRefreshToken(staff.staff_id);

    // Save refresh token hash
    const tokenHash = hashToken(refreshToken);
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days
    await authRepository.saveRefreshToken(staff.staff_id, tokenHash, expiresAt);

    // Log success
    await authRepository.logLogin(staff.staff_id, username, ipAddress, userAgent, true);

    return {
      accessToken,
      refreshToken,
      user: {
        staffId: staff.staff_id,
        unitId: staff.unit_id,
        departmentId: staff.department_id,
        username: staff.username,
        fullName: staff.full_name,
        email: staff.email || '',
        phone: staff.phone || '',
        image: staff.image || '',
        isAdmin: staff.is_admin,
        positionName: staff.position_name || '',
        departmentName: staff.department_name || '',
        unitName: staff.unit_name || '',
        roles,
      },
    };
  },

  async refresh(oldRefreshToken: string): Promise<{ accessToken: string; refreshToken: string }> {
    // Verify JWT signature first
    let payload: TokenPayload;
    try {
      payload = await verifyToken(oldRefreshToken);
    } catch {
      throw new AuthError('Refresh token không hợp lệ', 401);
    }

    // Check token in DB
    const tokenHash = hashToken(oldRefreshToken);
    const staff = await authRepository.verifyRefreshToken(tokenHash);

    if (!staff) {
      throw new AuthError('Refresh token đã hết hạn hoặc bị thu hồi', 401);
    }

    if (staff.is_locked || staff.is_deleted) {
      await authRepository.revokeAllTokens(staff.staff_id);
      throw new AuthError('Tài khoản đã bị khóa', 403);
    }

    const roles = parseRoles(staff.roles);

    // Revoke old token
    await authRepository.revokeRefreshToken(tokenHash);

    // Issue new tokens (token rotation)
    const accessToken = await signAccessToken({
      staffId: staff.staff_id,
      departmentId: staff.department_id,
      username: staff.username,
      roles,
      isAdmin: staff.is_admin,
    });

    const newRefreshToken = await signRefreshToken(staff.staff_id);
    const newTokenHash = hashToken(newRefreshToken);
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    await authRepository.saveRefreshToken(staff.staff_id, newTokenHash, expiresAt);

    return { accessToken, refreshToken: newRefreshToken };
  },

  async logout(refreshToken: string): Promise<void> {
    const tokenHash = hashToken(refreshToken);
    await authRepository.revokeRefreshToken(tokenHash);
  },

  async getMe(staffId: number) {
    const profile = await authRepository.getProfile(staffId);
    if (!profile) {
      throw new AuthError('Không tìm thấy thông tin người dùng', 404);
    }

    return {
      staffId: profile.staff_id,
      unitId: profile.unit_id,
      departmentId: profile.department_id,
      username: profile.username,
      fullName: profile.full_name,
      email: profile.email || '',
      phone: profile.phone || '',
      image: profile.image || '',
      isAdmin: profile.is_admin,
      gender: profile.gender,
      birthDate: profile.birth_date,
      address: profile.address || '',
      positionId: profile.position_id,
      positionName: profile.position_name || '',
      departmentName: profile.department_name || '',
      unitName: profile.unit_name || '',
      roles: parseRoles(profile.roles),
      lastLoginAt: profile.last_login_at,
      createdAt: profile.created_at,
    };
  },
};

export class AuthError extends Error {
  constructor(
    message: string,
    public statusCode: number,
  ) {
    super(message);
    this.name = 'AuthError';
  }
}
