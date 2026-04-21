import { callFunction, callFunctionOne } from '../lib/db/query.js';
import type { DbResult } from './doc-book.repository.js';

// ============================================================
// Row interfaces — match fn_staff_signing_config_* SPs (snake_case từ DB)
// Source of truth: database/migrations/040_signing_schema.sql
// ============================================================

/**
 * public.fn_staff_signing_config_list_by_staff output.
 * KHÔNG có `certificate_data` (TEXT) — list row nhẹ, lấy full bằng `get()`.
 */
export interface StaffSigningConfigListRow {
  staff_id: number;
  provider_code: string;
  user_id: string;
  credential_id: string | null;
  certificate_subject: string | null;
  certificate_serial: string | null;
  is_verified: boolean;
  last_verified_at: string | null;
  last_error: string | null;
  created_at: string;
  updated_at: string;
}

/**
 * public.fn_staff_signing_config_get output (có `certificate_data` TEXT).
 * Dùng cho sign flow cần base64 certificate gốc.
 */
export interface StaffSigningConfigFullRow {
  staff_id: number;
  provider_code: string;
  user_id: string;
  credential_id: string | null;
  certificate_data: string | null;
  certificate_subject: string | null;
  certificate_serial: string | null;
  is_verified: boolean;
  last_verified_at: string | null;
}

// ============================================================
// Repository
// ============================================================

export const staffSigningConfigRepository = {
  /**
   * List tất cả config của 1 staff (composite PK (staff_id, provider_code) cho phép
   * 1 user có config cho nhiều provider song song — VD user configured cả SmartCA + MySign).
   */
  async listByStaff(staffId: number): Promise<StaffSigningConfigListRow[]> {
    return callFunction<StaffSigningConfigListRow>(
      'public.fn_staff_signing_config_list_by_staff',
      [staffId],
    );
  },

  /** Lấy config cụ thể 1 staff + 1 provider (dùng cho sign flow). */
  async get(
    staffId: number,
    providerCode: string,
  ): Promise<StaffSigningConfigFullRow | null> {
    return callFunctionOne<StaffSigningConfigFullRow>(
      'public.fn_staff_signing_config_get',
      [staffId, providerCode],
    );
  },

  /**
   * Upsert config user. SP dùng COALESCE cho certificate fields — partial update
   * giữ nguyên certificate cũ khi chỉ đổi `user_id` / `credential_id`.
   */
  async upsert(params: {
    staffId: number;
    providerCode: string;
    userId: string;
    credentialId: string | null;
    certificateData: string | null;
    certificateSubject: string | null;
    certificateSerial: string | null;
    isVerified: boolean;
    lastVerifiedAt: string | null;
    lastError: string | null;
  }): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'public.fn_staff_signing_config_upsert',
      [
        params.staffId,
        params.providerCode,
        params.userId,
        params.credentialId,
        params.certificateData,
        params.certificateSubject,
        params.certificateSerial,
        params.isVerified,
        params.lastVerifiedAt,
        params.lastError,
      ],
    );
    return row ?? { success: false, message: 'Không thể lưu cấu hình cá nhân' };
  },

  /** Xóa config (composite key staff_id + provider_code). */
  async delete(staffId: number, providerCode: string): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'public.fn_staff_signing_config_delete',
      [staffId, providerCode],
    );
    return row ?? { success: false, message: 'Không tìm thấy cấu hình' };
  },
};
