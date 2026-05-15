/**
 * SmartCA VNPT adapter — implements SigningProvider cho `https://gwsca.vnpt.vn`.
 *
 * Reference: docs/source_code_cu/sources/OneWin.WebApp/SmartCA_VNPT/Model.cs
 * - _getAccountCert → POST /sca/sp769/v1/credentials/get_certificate
 * - _sign           → POST /sca/sp769/v1/signatures/sign
 * - _getStatus      → POST /sca/sp769/v1/signatures/sign/{txn_id}/status (empty body)
 *
 * Note: Model.cs dùng POST cho /status (qua `Query(new Object{}, uri)`). Không phải GET.
 * Body các request dùng key:
 *   sp_id       = client_id
 *   sp_password = client_secret (plaintext)
 *   user_id     = userId bên provider (số ĐT / CMND)
 *
 * Design:
 *   - Factory `createSmartCaVnptProvider(httpClient?)` nhận optional HttpClient
 *     để inject mock trong test. Mặc định dùng Node `fetch`.
 *   - Stateless — mỗi call POST riêng, không cache gì.
 *   - SECURITY: không log plaintext `sp_password` (mask khi throw error).
 */

import { randomUUID } from 'node:crypto';
import type {
  AdminCredentials,
  CertificateInfo,
  GetStatusResult,
  SignHashRequest,
  SignHashResult,
  SigningProvider,
  TestConnectionResult,
  UserConfig,
} from './provider.interface.js';
import { createDefaultHttpClient, type HttpClient, validateHttpsBaseUrl } from './http-client.js';

// VNPT SP769 dùng HTTP-style status codes (200 = OK), không phải JSON-RPC style (0 = OK).
// Sample PHP chính thức: `if($msg->status_code != 200)` — tham chiếu
// `Sample.SmartCA-769-PHP.Curl/signature_curl.php:140`.
const VNPT_STATUS_OK = 200;

// ============================================================================
// Response shapes từ VNPT (copy từ Model.cs — snake_case)
// ============================================================================

interface VnptUserCertificate {
  service_type?: string;
  service_name?: string;
  cert_id?: string;
  cert_status?: string;
  serial_number: string;
  cert_subject: string;
  cert_valid_from: string;
  cert_valid_to: string;
  cert_data: string;
}

interface VnptGetCertResponse {
  status_code: number;
  message?: string;
  data?: {
    user_certificates?: VnptUserCertificate[];
  };
}

interface VnptSignResponse {
  status_code: number;
  message?: string;
  data?: {
    transaction_id: string;
    tran_code?: string;
  };
}

interface VnptStatusResponse {
  status_code?: number;
  message?: string;
  data?: {
    transaction_id?: string;
    signatures?: Array<{
      doc_id: string;
      signature_value: string;
      timestamp_signature?: unknown;
    }> | null;
  };
}

// ============================================================================
// Helper
// ============================================================================

/** Join baseUrl + path, đảm bảo không có double slash. */
function joinUrl(baseUrl: string, path: string): string {
  const b = baseUrl.endsWith('/') ? baseUrl.slice(0, -1) : baseUrl;
  const p = path.startsWith('/') ? path : '/' + path;
  return b + p;
}

/**
 * Scrub `sp_password` trong body khi cần ném error — KHÔNG log plaintext.
 * (Internal — không export)
 */
function scrubSecret(body: Record<string, unknown>): Record<string, unknown> {
  const clone = { ...body };
  if ('sp_password' in clone) clone.sp_password = '***';
  return clone;
}

// ============================================================================
// Factory
// ============================================================================

/**
 * Tạo adapter SmartCA VNPT mới với optional httpClient (dùng cho test mock).
 * Production code nên dùng singleton `smartcaVnptProvider` ở cuối file.
 */
export function createSmartCaVnptProvider(httpClient?: HttpClient): SigningProvider {
  const http: HttpClient = httpClient ?? createDefaultHttpClient();

  return {
    code: 'SMARTCA_VNPT',

    // --------------------------------------------------------------------
    // CFG-03: test connection Admin
    // --------------------------------------------------------------------
    async testConnection(admin: AdminCredentials): Promise<TestConnectionResult> {
      try {
        validateHttpsBaseUrl(admin.baseUrl);

        const url = joinUrl(admin.baseUrl, '/sca/sp769/v1/credentials/get_certificate');
        const body = {
          sp_id: admin.clientId,
          sp_password: admin.clientSecretPlaintext,
          user_id: 'test_connection', // user giả — provider return error "not found"
          serial_number: '',
          transaction_id: randomUUID(),
        };

        const response = await http.post<VnptGetCertResponse>(url, body);

        // VNPT trả status_code=200 khi credentials đúng.
        // user_id giả → message "not found" / "user not exist", credentials vẫn pass.
        // client_id/secret sai → status_code khác 200 + message "invalid"/"unauthorized".
        if (response.status_code === VNPT_STATUS_OK) {
          const cert = response.data?.user_certificates?.[0];
          return {
            success: true,
            message: 'Kết nối SmartCA VNPT thành công',
            certificateSubject: cert?.cert_subject,
          };
        }

        const msg = (response.message ?? '').toLowerCase();
        // "not found" / "user not exist" → credentials OK, user_id giả không tồn tại
        if (msg.includes('not found') || msg.includes('not exist') || msg.includes('user')) {
          return {
            success: true,
            message: 'Kết nối SmartCA VNPT thành công (credentials hợp lệ)',
          };
        }

        return {
          success: false,
          message: `SmartCA VNPT từ chối: ${response.message ?? 'không rõ lỗi'}`,
        };
      } catch (err: unknown) {
        const msg = err instanceof Error ? err.message : String(err);
        // Mask sp_password nếu bị include trong error (phòng hờ)
        const safe = msg.replace(admin.clientSecretPlaintext, '***');
        return {
          success: false,
          message: `Không kết nối được SmartCA VNPT: ${safe}`,
        };
      }
    },

    // --------------------------------------------------------------------
    // CFG-05 / Phase 10: list certs của user
    // --------------------------------------------------------------------
    async listCertificates(
      admin: AdminCredentials,
      user: UserConfig,
    ): Promise<CertificateInfo[]> {
      validateHttpsBaseUrl(admin.baseUrl);

      const url = joinUrl(admin.baseUrl, '/sca/sp769/v1/credentials/get_certificate');
      const body = {
        sp_id: admin.clientId,
        sp_password: admin.clientSecretPlaintext,
        user_id: user.userId,
        serial_number: '',
        transaction_id: randomUUID(),
      };

      const response = await http.post<VnptGetCertResponse>(url, body);

      if (response.status_code !== VNPT_STATUS_OK) {
        throw new Error(
          `SmartCA VNPT không trả cert: ${response.message ?? 'status_code=' + response.status_code}`,
        );
      }

      const certs = response.data?.user_certificates ?? [];
      return certs.map((c) => ({
        credentialId: c.cert_id ?? c.serial_number, // fallback dùng serial nếu cert_id null
        subject: c.cert_subject,
        serialNumber: c.serial_number,
        validFrom: c.cert_valid_from,
        validTo: c.cert_valid_to,
        certificateBase64: c.cert_data,
        status: c.cert_status ?? 'unknown',
      }));
    },

    // --------------------------------------------------------------------
    // SIGN-03: gửi hash → nhận transaction_id để poll
    // --------------------------------------------------------------------
    async signHash(
      admin: AdminCredentials,
      user: UserConfig,
      req: SignHashRequest,
    ): Promise<SignHashResult> {
      validateHttpsBaseUrl(admin.baseUrl);

      const url = joinUrl(admin.baseUrl, '/sca/sp769/v1/signatures/sign');
      const body = {
        sp_id: admin.clientId,
        sp_password: admin.clientSecretPlaintext,
        user_id: user.userId,
        transaction_desc: req.documentName,
        transaction_id: randomUUID(),
        sign_files: [
          {
            data_to_be_signed: req.hashHex,
            doc_id: req.documentId,
            file_type: 'pdf',
            sign_type: 'hash',
          },
        ],
        serial_number: '',
      };

      const response = await http.post<VnptSignResponse>(url, body);

      if (response.status_code !== VNPT_STATUS_OK || !response.data?.transaction_id) {
        // Scrub secret trong body snapshot trước khi throw (debug an toàn)
        void scrubSecret(body);
        throw new Error(
          `SmartCA VNPT reject sign: ${response.message ?? 'status_code=' + response.status_code}`,
        );
      }

      return { providerTransactionId: response.data.transaction_id };
    },

    // --------------------------------------------------------------------
    // SIGN-05: poll status — Model.cs dùng POST với empty body
    // --------------------------------------------------------------------
    async getSignStatus(
      admin: AdminCredentials,
      _user: UserConfig,
      providerTxnId: string,
    ): Promise<GetStatusResult> {
      validateHttpsBaseUrl(admin.baseUrl);

      const url = joinUrl(
        admin.baseUrl,
        `/sca/sp769/v1/signatures/sign/${encodeURIComponent(providerTxnId)}/status`,
      );

      const response = await http.post<VnptStatusResponse>(url, {});

      const sigs = response.data?.signatures;
      // Model.cs: "transactionStatus == null || transactionStatus.signatures == null" → chưa confirm
      if (!sigs || sigs.length === 0) {
        return { status: 'pending' };
      }

      const first = sigs[0];
      if (first && first.signature_value) {
        return {
          status: 'completed',
          signatureBase64: first.signature_value,
        };
      }

      return {
        status: 'failed',
        errorMessage: response.message ?? 'Không có signature_value trong response',
      };
    },
  };
}

/** Singleton — dùng cho production. Test inject mock qua factory. */
export const smartcaVnptProvider: SigningProvider = createSmartCaVnptProvider();
