import { callFunction, callFunctionOne } from '../lib/db/query.js';

export interface StaffLoginRow {
  staff_id: number;
  username: string;
  password_hash: string;
  full_name: string;
  email: string;
  phone: string;
  image: string;
  is_admin: boolean;
  is_locked: boolean;
  is_deleted: boolean;
  department_id: number;
  unit_id: number;
  position_name: string;
  department_name: string;
  unit_name: string;
  roles: string; // comma-separated
}

export interface StaffProfileRow extends Omit<StaffLoginRow, 'password_hash'> {
  gender: number;
  birth_date: string;
  address: string;
  position_id: number;
  last_login_at: string;
  created_at: string;
  sign_phone: string | null;
  sign_image: string | null;
}

export const authRepository = {
  async findByUsername(username: string): Promise<StaffLoginRow | null> {
    return callFunctionOne<StaffLoginRow>('public.fn_auth_login', [username]);
  },

  async logLogin(
    staffId: number | null,
    username: string,
    ipAddress: string,
    userAgent: string,
    success: boolean,
  ): Promise<void> {
    await callFunction('public.fn_auth_log_login', [staffId, username, ipAddress, userAgent, success]);
  },

  async saveRefreshToken(staffId: number, tokenHash: string, expiresAt: Date): Promise<void> {
    await callFunction('public.fn_auth_save_refresh_token', [staffId, tokenHash, expiresAt]);
  },

  async verifyRefreshToken(tokenHash: string): Promise<StaffLoginRow | null> {
    return callFunctionOne<StaffLoginRow>('public.fn_auth_verify_refresh_token', [tokenHash]);
  },

  async revokeRefreshToken(tokenHash: string): Promise<void> {
    await callFunction('public.fn_auth_logout', [tokenHash]);
  },

  async revokeAllTokens(staffId: number): Promise<void> {
    await callFunction('public.fn_auth_logout_all', [staffId]);
  },

  async getProfile(staffId: number): Promise<StaffProfileRow | null> {
    return callFunctionOne<StaffProfileRow>('public.fn_auth_get_me', [staffId]);
  },
};
