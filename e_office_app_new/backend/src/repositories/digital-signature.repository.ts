import { callFunction, callFunctionOne } from '../lib/db/query.js';

// ============================================================
// Row interfaces — match SP RETURNS TABLE columns exactly
// ============================================================

/** edoc.fn_digital_signature_get_by_doc / fn_digital_signature_get_by_id output */
export interface DigitalSignatureRow {
  id: number;
  doc_id: number;
  doc_type: string;
  staff_id: number;
  staff_name: string;
  sign_method: string;
  certificate_serial: string | null;
  certificate_subject: string | null;
  certificate_issuer: string | null;
  signed_file_path: string | null;
  original_file_path: string | null;
  sign_status: string;
  error_message: string | null;
  signed_at: string | null;
  created_at: string;
}

/** edoc.fn_digital_signature_create output */
export interface MutationResultRow {
  success: boolean;
  message: string;
  id: number;
}

/** edoc.fn_digital_signature_update_status output */
export interface UpdateResultRow {
  success: boolean;
  message: string;
}

// ============================================================
// digitalSignatureRepository
// ============================================================

export const digitalSignatureRepository = {

  /**
   * Tao yeu cau ky so — calls edoc.fn_digital_signature_create
   */
  async create(
    docId: number,
    docType: string,
    staffId: number,
    signMethod: string,
    originalFilePath: string | null,
  ): Promise<MutationResultRow> {
    const row = await callFunctionOne<MutationResultRow>(
      'edoc.fn_digital_signature_create',
      [docId, docType, staffId, signMethod, originalFilePath],
    );
    return row ?? { success: false, message: 'Khong the tao yeu cau ky so', id: 0 };
  },

  /**
   * Cap nhat trang thai ky so — calls edoc.fn_digital_signature_update_status
   */
  async updateStatus(
    id: number,
    signStatus: string,
    certificateSerial: string | null,
    certificateSubject: string | null,
    certificateIssuer: string | null,
    signedFilePath: string | null,
    errorMessage: string | null,
  ): Promise<UpdateResultRow> {
    const row = await callFunctionOne<UpdateResultRow>(
      'edoc.fn_digital_signature_update_status',
      [id, signStatus, certificateSerial, certificateSubject, certificateIssuer, signedFilePath, errorMessage],
    );
    return row ?? { success: false, message: 'Khong the cap nhat trang thai ky so' };
  },

  /**
   * Lay chu ky so theo van ban — calls edoc.fn_digital_signature_get_by_doc
   */
  async getByDoc(
    docId: number,
    docType: string,
  ): Promise<DigitalSignatureRow[]> {
    return callFunction<DigitalSignatureRow>(
      'edoc.fn_digital_signature_get_by_doc',
      [docId, docType],
    );
  },

  /**
   * Lay chu ky so theo ID — calls edoc.fn_digital_signature_get_by_id
   */
  async getById(
    id: number,
  ): Promise<DigitalSignatureRow | null> {
    return callFunctionOne<DigitalSignatureRow>(
      'edoc.fn_digital_signature_get_by_id',
      [id],
    );
  },
};
