/**
 * SigningProvider — Strategy pattern interface cho các provider ký số.
 *
 * Mỗi provider (SmartCA VNPT, MySign Viettel, FPT CA sau này) phải implement
 * interface này để Phase 9 route + Phase 11 worker có thể gọi đồng nhất mà không
 * cần biết provider cụ thể.
 *
 * Thiết kế:
 *   - 4 methods: testConnection / listCertificates / signHash / getSignStatus
 *   - Stateless — không cache token, không share state giữa call (tránh race trong
 *     BullMQ worker multi-concurrency)
 *   - AdminCredentials chứa plaintext `clientSecretPlaintext` — factory đã decrypt
 *     từ BYTEA trước khi pass vào. Adapter KHÔNG log plaintext.
 *   - UserConfig chứa `userId` (+ optional `credentialId` cho MySign multi-cert)
 *
 * Consumer:
 *   - Phase 9 Plan 02: `route POST /quan-tri/cau-hinh-ky-so/test-connection` → provider.testConnection()
 *   - Phase 10: `route GET /ca-nhan/chung-chi-so` → provider.listCertificates()
 *   - Phase 11 worker: `provider.signHash()` + poll `provider.getSignStatus()`
 */

// ============================================================================
// Type aliases
// ============================================================================

/** Danh sách provider được hỗ trợ trong v2.0 — union literal type-safe */
export type ProviderCode = 'SMARTCA_VNPT' | 'MYSIGN_VIETTEL';

/**
 * Kết quả test connection (CFG-03 — Admin lưu config + test).
 * Hiển thị UI: success=true badge xanh "Kết nối OK", false badge đỏ kèm message.
 */
export interface TestConnectionResult {
  /** true = credentials hợp lệ, provider reachable */
  success: boolean;
  /** Thông báo tiếng Việt cho UI — luôn có (không null) */
  message: string;
  /** Optional: subject của cert test trả về (khi provider tự động trả) */
  certificateSubject?: string;
}

/**
 * Thông tin chứng chỉ số của user — list từ provider (Phase 10).
 * Field names chuẩn hóa giữa 2 provider (SmartCA: `cert_id`/`cert_subject`,
 * MySign: `credential_id`/`cert.subjectDN` → map về shape dưới).
 */
export interface CertificateInfo {
  /** ID duy nhất của credential/cert — SmartCA=cert_id, MySign=credential_id */
  credentialId: string;
  /** CN + tổ chức — hiển thị UI "Nguyễn Văn A (Sở Nội vụ)" */
  subject: string;
  /** Serial number của cert (hex hoặc decimal) */
  serialNumber: string;
  /** ISO 8601 date string — từ khi cert có hiệu lực */
  validFrom: string;
  /** ISO 8601 date string — cert hết hạn */
  validTo: string;
  /** Cert DER base64 (để hiển thị chi tiết hoặc lưu lại cho audit) */
  certificateBase64: string;
  /** Trạng thái cert — 'active' | 'expired' | 'revoked' | ... (tùy provider) */
  status: string;
}

/**
 * Request ký hash (SIGN-03 — Phase 11).
 * Chỉ ký HASH, không ký trực tiếp PDF — pdf-signer.ts đã compute hash trước.
 */
export interface SignHashRequest {
  /** SHA256 hex 64 ký tự của byte range PDF (từ computePdfHash) */
  hashHex: string;
  /** Tên file hiển thị trên app ký (VD: "QD-123-2026.pdf") */
  documentName: string;
  /** ID tham chiếu (sign_transactions.id stringified) — provider echo lại để map */
  documentId: string;
}

/**
 * Kết quả signHash — provider đã accept và trả transaction_id để poll.
 * signHash là ASYNC flow: provider gửi push tới app user, user nhập OTP,
 * signature chỉ có khi getSignStatus trả completed.
 */
export interface SignHashResult {
  /** Transaction ID của provider — dùng làm key cho getSignStatus */
  providerTransactionId: string;
}

/**
 * Kết quả poll status (SIGN-05 — Phase 11 worker).
 * Status machine:
 *   pending   → user chưa xác thực app (vẫn đang chờ)
 *   completed → có signature_value → worker embed vào PDF
 *   failed    → user reject hoặc provider error
 *   expired   → timeout bên provider (thường 3-5 phút)
 */
export interface GetStatusResult {
  /** Trạng thái hiện tại của transaction */
  status: 'pending' | 'completed' | 'failed' | 'expired';
  /** PKCS7 detached signature base64 — chỉ có khi status='completed' */
  signatureBase64?: string;
  /** Thông báo lỗi tiếng Việt — có khi status='failed' hoặc 'expired' */
  errorMessage?: string;
}

/**
 * Credentials cấp hệ thống (Admin config — CFG-01 / CFG-02).
 * Factory đã decrypt `clientSecretPlaintext` từ BYTEA trước khi truyền.
 *
 * SECURITY: adapter KHÔNG log, KHÔNG trả về field này trong error message.
 */
export interface AdminCredentials {
  /** Base URL provider — VD: 'https://gwsca.vnpt.vn' (no trailing slash) */
  baseUrl: string;
  /** client_id (SmartCA: sp_id, MySign: client_id) */
  clientId: string;
  /** client_secret PLAINTEXT (đã decrypt) — gửi trong body request */
  clientSecretPlaintext: string;
  /** profile_id — CHỈ MySign Viettel (null với SmartCA) */
  profileId?: string | null;
}

/**
 * Config cấp user (CFG-05 / CFG-06 — Phase 10).
 * `userId` là định danh user bên provider (SmartCA: số ĐT/CMND,
 *  MySign: CMT_xxx hoặc custom).
 */
export interface UserConfig {
  /** User ID đăng ký với provider */
  userId: string;
  /** MySign multi-cert: user chọn cert nào để ký — null cho SmartCA */
  credentialId?: string | null;
}

// ============================================================================
// SigningProvider interface
// ============================================================================

/**
 * Signature của 1 provider adapter. Factory tạo instance + inject httpClient
 * để test có thể mock HTTP mà không hit real API.
 */
export interface SigningProvider {
  /** Code định danh — dùng để match với DB `signing_provider_config.provider_code` */
  readonly code: ProviderCode;

  /**
   * Test kết nối với provider dùng credentials hệ thống (CFG-03).
   * Không ký gì thật — chỉ gọi endpoint "nhẹ" (SmartCA get_certificate với user
   * test, MySign login) để verify client_id/secret hợp lệ.
   *
   * Không throw — luôn return object {success, message}. Exception thành failed.
   */
  testConnection(admin: AdminCredentials): Promise<TestConnectionResult>;

  /**
   * Liệt kê tất cả cert user sở hữu (CFG-05 — Phase 10).
   * User dùng để chọn credential_id khi có nhiều cert (MySign case).
   * Với SmartCA: thường chỉ 1 cert → UI chỉ hiển thị info.
   */
  listCertificates(admin: AdminCredentials, user: UserConfig): Promise<CertificateInfo[]>;

  /**
   * Gửi request ký hash tới provider (SIGN-03 — Phase 11).
   * Async flow: trả về ngay `providerTransactionId` (chưa có signature).
   * User nhận push trên app, xác thực OTP → status mới chuyển completed.
   */
  signHash(
    admin: AdminCredentials,
    user: UserConfig,
    req: SignHashRequest,
  ): Promise<SignHashResult>;

  /**
   * Poll status của transaction đã signHash (SIGN-05 — Phase 11 worker).
   * Worker gọi mỗi 5s, max 3 phút (BullMQ delayed job).
   * Status='completed' → worker embed signature vào PDF qua pdf-signer.signPdf().
   */
  getSignStatus(
    admin: AdminCredentials,
    user: UserConfig,
    providerTxnId: string,
  ): Promise<GetStatusResult>;
}
