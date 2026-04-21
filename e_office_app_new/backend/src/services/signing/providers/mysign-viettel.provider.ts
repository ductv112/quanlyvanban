/**
 * MySign Viettel adapter — implements SigningProvider cho `https://remotesigning.viettel.vn`.
 *
 * Reference: docs/huong_dan_tich_hop_ky_so_MySign_Viettel/Viettel Mysign Gateway.postman_collection.json
 * - Login                → POST /vtss/service/ras/v1/login           → access_token (Bearer)
 * - List certs           → POST /vtss/service/certificates/info     (Bearer)
 * - Sign hash (async)    → POST /vtss/service/signHash               (Bearer, async=1)
 * - Poll status          → POST /vtss/service/requests/status        (Bearer)
 *
 * Thiết kế:
 *   - Mỗi method do 1 lần _login() → lấy access_token (không cache — stateless,
 *     tránh race condition trong Phase 11 worker đa concurrency). Production
 *     optimization (Redis token cache với TTL expires_in) deferred sau.
 *   - Factory `createMysignViettelProvider(httpClient?)` accept mock cho test.
 *   - CRITICAL: body signHash dùng `credentialID` (chữ D hoa) — case-sensitive,
 *     match postman literal.
 *   - hashAlgo = '2.16.840.1.101.3.4.2.1' (SHA-256 OID)
 *     signAlgo = '1.2.840.113549.1.1.1' (RSA OID)
 *
 * SECURITY: không log `client_secret` hoặc `access_token` (threat T-09-02).
 */

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

// ============================================================================
// Response shapes — từ postman collection
// ============================================================================

interface ViettelLoginResponse {
  access_token: string;
  refresh_token?: string;
  token_type?: string;
  expires_in?: string;
}

interface ViettelCertItem {
  credential_id: string;
  description?: string;
  key?: {
    status?: string;
    algo?: string[];
    len?: string;
  };
  cert?: {
    status?: string;
    certificates?: string[];
    issuerDN?: string;
    serialNumber?: string;
    subjectDN?: string;
    validFrom?: string;
    validTo?: string;
  };
  authMode?: string;
}

type ViettelCertListResponse = ViettelCertItem[];

interface ViettelSignHashResponse {
  transactionId?: string;
  // Có thể nhận được `signatures` nếu async=0 (sync mode) — adapter không dùng sync
  signatures?: string[];
}

interface ViettelStatusResponse {
  signatures?: string[] | null;
  /** '1' = ký xong, '0' = chờ OTP, other = fail */
  status?: string;
  message?: string;
}

// ============================================================================
// Helpers
// ============================================================================

function joinUrl(baseUrl: string, path: string): string {
  const b = baseUrl.endsWith('/') ? baseUrl.slice(0, -1) : baseUrl;
  const p = path.startsWith('/') ? path : '/' + path;
  return b + p;
}

/** Scrub access_token / client_secret khi cần ném error. */
function redact(msg: string, secrets: string[]): string {
  let safe = msg;
  for (const s of secrets) {
    if (s && s.length >= 3) {
      safe = safe.split(s).join('***');
    }
  }
  return safe;
}

// ============================================================================
// Factory
// ============================================================================

/**
 * Tạo adapter MySign Viettel mới với optional httpClient (dùng cho test mock).
 * Production code nên dùng singleton `mysignViettelProvider` ở cuối file.
 */
export function createMysignViettelProvider(httpClient?: HttpClient): SigningProvider {
  const http: HttpClient = httpClient ?? createDefaultHttpClient();

  // ------------------------------------------------------------------
  // Helper nội bộ: login → access_token
  // ------------------------------------------------------------------
  async function login(admin: AdminCredentials, userId: string): Promise<string> {
    const url = joinUrl(admin.baseUrl, '/vtss/service/ras/v1/login');
    const body = {
      client_id: admin.clientId,
      user_id: userId,
      client_secret: admin.clientSecretPlaintext,
      profile_id: admin.profileId ?? '',
    };

    try {
      const response = await http.post<ViettelLoginResponse>(url, body);
      if (!response.access_token || typeof response.access_token !== 'string') {
        throw new Error('Login Viettel thất bại: không nhận được access_token');
      }
      return response.access_token;
    } catch (err: unknown) {
      const raw = err instanceof Error ? err.message : String(err);
      const safe = redact(raw, [admin.clientSecretPlaintext]);
      throw new Error(`Login Viettel thất bại: ${safe}`);
    }
  }

  return {
    code: 'MYSIGN_VIETTEL',

    // --------------------------------------------------------------------
    // CFG-03: test connection — chỉ cần login thành công là OK
    // --------------------------------------------------------------------
    async testConnection(admin: AdminCredentials): Promise<TestConnectionResult> {
      try {
        validateHttpsBaseUrl(admin.baseUrl);

        // User ID thật mới login được. Khi admin test connection, dùng
        // user_id giả — MySign có thể reject vì user không tồn tại nhưng
        // nếu error message chứa "user_id" / "user not exist" thì credentials
        // vẫn OK (chỉ user_id là invalid — CFG-05 concern, không phải CFG-03).
        const token = await login(admin, 'test_connection');

        if (token && token.length > 0) {
          return {
            success: true,
            message: 'Kết nối MySign Viettel thành công',
          };
        }
        return {
          success: false,
          message: 'MySign Viettel trả access_token rỗng',
        };
      } catch (err: unknown) {
        const msg = err instanceof Error ? err.message : String(err);
        const safe = redact(msg, [admin.clientSecretPlaintext]);
        const lower = safe.toLowerCase();

        // Nếu lỗi chỉ vì user_id → credentials vẫn OK
        if (
          lower.includes('user_id') ||
          lower.includes('user not exist') ||
          lower.includes('user not found')
        ) {
          return {
            success: true,
            message: 'Kết nối MySign Viettel thành công (credentials hợp lệ, user_id test không tồn tại)',
          };
        }

        // Nếu lỗi liên quan client_id / client_secret / unauthorized → credentials SAI
        return {
          success: false,
          message: `Không kết nối được MySign Viettel: ${safe}`,
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

      const token = await login(admin, user.userId);

      const url = joinUrl(admin.baseUrl, '/vtss/service/certificates/info');
      const body = {
        client_id: admin.clientId,
        client_secret: admin.clientSecretPlaintext,
        profile_id: admin.profileId ?? '',
        user_id: user.userId,
        certInfo: true,
        authInfo: true,
        certificates: 'chain',
      };

      const response = await http.post<ViettelCertListResponse>(url, body, {
        Authorization: `Bearer ${token}`,
      });

      if (!Array.isArray(response)) {
        throw new Error('MySign Viettel không trả list cert hợp lệ');
      }

      return response.map((item) => ({
        credentialId: item.credential_id,
        subject: item.cert?.subjectDN ?? '',
        serialNumber: item.cert?.serialNumber ?? '',
        validFrom: item.cert?.validFrom ?? '',
        validTo: item.cert?.validTo ?? '',
        certificateBase64: (item.cert?.certificates && item.cert.certificates[0]) ?? '',
        status: item.cert?.status ?? 'unknown',
      }));
    },

    // --------------------------------------------------------------------
    // SIGN-03: gửi hash async → nhận transactionId
    // --------------------------------------------------------------------
    async signHash(
      admin: AdminCredentials,
      user: UserConfig,
      req: SignHashRequest,
    ): Promise<SignHashResult> {
      validateHttpsBaseUrl(admin.baseUrl);

      if (!user.credentialId) {
        throw new Error(
          'MySign Viettel yêu cầu credentialId — user chưa chọn chứng chỉ số (CFG-05)',
        );
      }

      const token = await login(admin, user.userId);

      const url = joinUrl(admin.baseUrl, '/vtss/service/signHash');
      // CRITICAL: key `credentialID` CHỮ D HOA — match postman literal (không phải credential_id)
      const body = {
        client_id: admin.clientId,
        client_secret: admin.clientSecretPlaintext,
        credentialID: user.credentialId,
        numSignatures: 1,
        documents: [
          {
            document_id: req.documentId,
            document_name: req.documentName,
          },
        ],
        hash: [req.hashHex],
        hashAlgo: '2.16.840.1.101.3.4.2.1', // SHA-256 OID
        signAlgo: '1.2.840.113549.1.1.1', // RSA OID
        async: 1, // async flow — nhận transactionId, poll status sau
      };

      const response = await http.post<ViettelSignHashResponse>(url, body, {
        Authorization: `Bearer ${token}`,
      });

      if (!response.transactionId || typeof response.transactionId !== 'string') {
        throw new Error(
          'MySign Viettel không trả transactionId — kiểm tra credentials và credentialId',
        );
      }

      return { providerTransactionId: response.transactionId };
    },

    // --------------------------------------------------------------------
    // SIGN-05: poll status
    // --------------------------------------------------------------------
    async getSignStatus(
      admin: AdminCredentials,
      user: UserConfig,
      providerTxnId: string,
    ): Promise<GetStatusResult> {
      validateHttpsBaseUrl(admin.baseUrl);

      const token = await login(admin, user.userId);

      const url = joinUrl(admin.baseUrl, '/vtss/service/requests/status');
      const body = { transactionId: providerTxnId };

      const response = await http.post<ViettelStatusResponse>(url, body, {
        Authorization: `Bearer ${token}`,
      });

      // Postman: status='1' → signed, status='0' → pending
      if (response.status === '1') {
        const sig = response.signatures?.[0];
        if (!sig) {
          return {
            status: 'failed',
            errorMessage: 'MySign báo completed nhưng thiếu signature',
          };
        }
        // Strip CRLF/newline trong base64 (postman response có \r\n)
        return {
          status: 'completed',
          signatureBase64: sig.replace(/\s+/g, ''),
        };
      }

      if (response.status === '0') {
        return { status: 'pending' };
      }

      return {
        status: 'failed',
        errorMessage: response.message ?? `Status không xác định: ${response.status ?? 'null'}`,
      };
    },
  };
}

/** Singleton — dùng cho production. */
export const mysignViettelProvider: SigningProvider = createMysignViettelProvider();
