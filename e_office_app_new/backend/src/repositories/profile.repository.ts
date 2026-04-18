import { callFunctionOne, rawQuery } from '../lib/db/query.js';

/**
 * Repository cho các thao tác trên profile cá nhân (HDSD I.4 — chữ ký số).
 * Routes mount tại /api/ho-so-ca-nhan với chỉ middleware authenticate.
 */

export interface UpdateSignatureResult {
  success: boolean;
  message: string;
}

export interface StaffSignatureRow {
  sign_phone: string | null;
  sign_image: string | null;
}

export const profileRepository = {
  /**
   * Cập nhật thông tin chữ ký số cho nhân viên.
   * Tham số NULL → giữ nguyên giá trị cũ (COALESCE trong SP).
   */
  async updateSignature(
    staffId: number,
    signPhone: string | null,
    signCa: string | null,
    signImage: string | null,
  ): Promise<UpdateSignatureResult | null> {
    return callFunctionOne<UpdateSignatureResult>(
      'public.fn_staff_update_signature',
      [staffId, signPhone, signCa, signImage],
    );
  },

  /**
   * Lấy sign_image hiện tại để tạo presigned URL preview.
   */
  async getSignature(staffId: number): Promise<StaffSignatureRow | null> {
    const rows = await rawQuery<StaffSignatureRow>(
      'SELECT sign_phone, sign_image FROM public.staff WHERE id = $1 AND is_deleted = FALSE',
      [staffId],
    );
    return rows[0] ?? null;
  },
};
