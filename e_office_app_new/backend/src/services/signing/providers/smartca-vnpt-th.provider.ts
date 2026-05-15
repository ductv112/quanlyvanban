/**
 * SmartCA VNPT Tích hợp (TH) adapter — gói tích hợp dùng TOTP, không cần app mobile.
 *
 * KHÁC SmartCA Thường (smartca-vnpt.provider.ts):
 *   - Endpoint v2 (`/sca/sp769/v2/*`) thay vì v1
 *   - Sign flow là **SYNC 2-step**: /sign → /confirm (KHÔNG cần polling)
 *   - Body kèm `password` user + `otp` (TOTP HMAC-SHA1, 30s, 6 digits)
 *   - SAD (Signature Activation Data) JWT TTL 299s, dùng làm input cho /confirm
 *
 * MỤC ĐÍCH: chỉ dùng cho **DEV TEST E2E** verify code Node.js đúng chuẩn PAdES.
 *   KHÔNG khuyến nghị bật cho khách hàng cuối — rủi ro bảo mật (server giữ password
 *   user + TOTP secret).
 *
 * USER-LEVEL CREDENTIALS:
 *   Đọc trực tiếp từ env vars (KHÔNG qua staff_signing_config table):
 *     SMARTCA_TH_USER_ID
 *     SMARTCA_TH_USER_PASSWORD
 *     SMARTCA_TH_TOTP_SECRET (base64-encoded)
 *
 * COMPATIBILITY với Phase 11 worker:
 *   Worker pattern là async polling (getSignStatus mỗi 5s). Provider TH sign sync
 *   trong 1 call, nên cache signature_value trong Map<providerTxnId, signatureBase64>.
 *   Worker poll 1 lần → adapter trả completed + signature → worker embed ngay.
 *
 * Tham chiếu doc: `docs/ky_so_analysis/03_smartca_tichhop.md`
 * Sample code: `docs/huong_dan_tich_hop_ky_so_SmartCA_tich_hop/PHP_Example_SmartCATH_Curl/`
 */

import { createHmac, randomUUID } from 'node:crypto';
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

const VNPT_STATUS_OK = 200;

/**
 * In-memory cache: providerTxnId -> signature_value base64.
 * Sau signHash sync 2-step, store signature ở đây. getSignStatus lookup → trả completed.
 * TTL ~5 phút (cleanup tự động khi lookup) — đủ cho worker poll attempt đầu tiên.
 */
const signatureCache = new Map<string, { signatureBase64: string; storedAt: number }>();
const CACHE_TTL_MS = 5 * 60 * 1000;

function cacheSet(txnId: string, signatureBase64: string): void {
  signatureCache.set(txnId, { signatureBase64, storedAt: Date.now() });
}

function cacheGet(txnId: string): string | null {
  const entry = signatureCache.get(txnId);
  if (!entry) return null;
  if (Date.now() - entry.storedAt > CACHE_TTL_MS) {
    signatureCache.delete(txnId);
    return null;
  }
  return entry.signatureBase64;
}

// ============================================================================
// TOTP generator — HMAC-SHA1, 30s step, 6 digits (RFC 6238)
// ============================================================================

/**
 * Sinh OTP TOTP từ base64 secret theo chuẩn của VNPT SmartCA Tích hợp.
 * Sample code PHP: `models/OTPService.php` — keyRegeneration=30s, otpLength=6, HmacSHA1.
 */
function generateTotp(secretBase64: string, step = 30, digits = 6): string {
  const secret = Buffer.from(secretBase64, 'base64');
  const counter = Math.floor(Date.now() / 1000 / step);
  const counterBuf = Buffer.alloc(8);
  counterBuf.writeBigInt64BE(BigInt(counter), 0);
  const hmac = createHmac('sha1', secret).update(counterBuf).digest();
  const offset = hmac[hmac.length - 1] & 0x0f;
  const code =
    (((hmac[offset] & 0x7f) << 24) |
      ((hmac[offset + 1] & 0xff) << 16) |
      ((hmac[offset + 2] & 0xff) << 8) |
      (hmac[offset + 3] & 0xff)) %
    Math.pow(10, digits);
  return code.toString().padStart(digits, '0');
}

// ============================================================================
// Response shapes
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

interface VnptV2SignResponse {
  status_code: number;
  message?: string;
  data?: {
    transaction_id: string;
    tran_code?: string;
    sad?: string;
    expired_in?: number;
  };
}

interface VnptV2ConfirmResponse {
  status_code: number;
  message?: string;
  data?: {
    transaction_id?: string;
    expired_in?: number;
    signatures?: Array<{
      doc_id: string;
      signature_value: string;
      timestamp_signature?: unknown;
    }>;
  };
}

// ============================================================================
// Helpers
// ============================================================================

function joinUrl(baseUrl: string, path: string): string {
  const b = baseUrl.endsWith('/') ? baseUrl.slice(0, -1) : baseUrl;
  const p = path.startsWith('/') ? path : '/' + path;
  return b + p;
}

/** Đọc env user-level credentials. Throw khi thiếu (dev test setup chưa đủ). */
function readUserCredsFromEnv(): { userId: string; password: string; totpSecret: string } {
  const userId = process.env.SMARTCA_TH_USER_ID;
  const password = process.env.SMARTCA_TH_USER_PASSWORD;
  const totpSecret = process.env.SMARTCA_TH_TOTP_SECRET;
  if (!userId || !password || !totpSecret) {
    throw new Error(
      'SmartCA TH chưa cấu hình đủ env vars (SMARTCA_TH_USER_ID, SMARTCA_TH_USER_PASSWORD, SMARTCA_TH_TOTP_SECRET) — chỉ dùng cho dev test',
    );
  }
  return { userId, password, totpSecret };
}

// ============================================================================
// Factory
// ============================================================================

export function createSmartCaVnptThProvider(httpClient?: HttpClient): SigningProvider {
  const http: HttpClient = httpClient ?? createDefaultHttpClient();

  return {
    code: 'SMARTCA_VNPT_TH',

    // --------------------------------------------------------------------
    // CFG-03: test connection — dùng v1/credentials/get_certificate
    // (TH chỉ override v2 cho sign/confirm; get_certificate vẫn dùng v1)
    // --------------------------------------------------------------------
    async testConnection(admin: AdminCredentials): Promise<TestConnectionResult> {
      try {
        validateHttpsBaseUrl(admin.baseUrl);

        const url = joinUrl(admin.baseUrl, '/sca/sp769/v1/credentials/get_certificate');
        const body = {
          sp_id: admin.clientId,
          sp_password: admin.clientSecretPlaintext,
          user_id: 'test_connection',
          serial_number: '',
          transaction_id: randomUUID(),
        };

        const response = await http.post<VnptGetCertResponse>(url, body);

        if (response.status_code === VNPT_STATUS_OK) {
          const cert = response.data?.user_certificates?.[0];
          return {
            success: true,
            message: 'Kết nối SmartCA VNPT Tích hợp thành công',
            certificateSubject: cert?.cert_subject,
          };
        }

        const msg = (response.message ?? '').toLowerCase();
        if (msg.includes('not found') || msg.includes('not exist') || msg.includes('user')) {
          return {
            success: true,
            message: 'Kết nối SmartCA VNPT Tích hợp thành công (credentials hợp lệ)',
          };
        }

        return {
          success: false,
          message: `SmartCA VNPT TH từ chối: ${response.message ?? 'không rõ lỗi'}`,
        };
      } catch (err: unknown) {
        const raw = err instanceof Error ? err.message : String(err);
        const safe = raw.replace(admin.clientSecretPlaintext, '***');
        return {
          success: false,
          message: `Không kết nối được SmartCA VNPT TH: ${safe}`,
        };
      }
    },

    // --------------------------------------------------------------------
    // CFG-05: list certs — dùng v1/credentials/get_certificate
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
          `SmartCA VNPT TH không trả cert: ${response.message ?? 'status_code=' + response.status_code}`,
        );
      }

      const certs = response.data?.user_certificates ?? [];
      return certs.map((c) => ({
        credentialId: c.cert_id ?? c.serial_number,
        subject: c.cert_subject,
        serialNumber: c.serial_number,
        validFrom: c.cert_valid_from,
        validTo: c.cert_valid_to,
        certificateBase64: c.cert_data,
        status: c.cert_status ?? 'unknown',
      }));
    },

    // --------------------------------------------------------------------
    // SIGN: gửi hash → sync 2-step (sign + confirm) → cache signature
    // --------------------------------------------------------------------
    async signHash(
      admin: AdminCredentials,
      _user: UserConfig,
      req: SignHashRequest,
    ): Promise<SignHashResult> {
      validateHttpsBaseUrl(admin.baseUrl);

      // TH ignore _user.userId — đọc từ env (dev test)
      const envUser = readUserCredsFromEnv();
      const otp = generateTotp(envUser.totpSecret);

      // Step 1: POST /v2/signatures/sign
      const signUrl = joinUrl(admin.baseUrl, '/sca/sp769/v2/signatures/sign');
      const signTxnId = randomUUID();
      const signBody = {
        sp_id: admin.clientId,
        sp_password: admin.clientSecretPlaintext,
        user_id: envUser.userId,
        password: envUser.password,
        otp,
        transaction_id: signTxnId,
        sign_files: [
          {
            data_to_be_signed: req.hashHex,
            doc_id: req.documentId,
            file_type: 'pdf',
            sign_type: 'hash',
          },
        ],
      };

      const signResp = await http.post<VnptV2SignResponse>(signUrl, signBody);

      if (signResp.status_code !== VNPT_STATUS_OK || !signResp.data?.sad) {
        throw new Error(
          `SmartCA TH /sign reject: ${signResp.message ?? 'status_code=' + signResp.status_code}`,
        );
      }

      const { sad, transaction_id: vnptTxnId } = signResp.data;
      if (!vnptTxnId) {
        throw new Error('SmartCA TH /sign không trả transaction_id');
      }

      // Step 2: POST /v2/signatures/confirm ngay (SAD TTL 299s)
      const confirmUrl = joinUrl(admin.baseUrl, '/sca/sp769/v2/signatures/confirm');
      const confirmBody = {
        sp_id: admin.clientId,
        sp_password: admin.clientSecretPlaintext,
        user_id: envUser.userId,
        password: envUser.password,
        transaction_id: vnptTxnId,
        sad,
      };

      const confirmResp = await http.post<VnptV2ConfirmResponse>(confirmUrl, confirmBody);

      if (confirmResp.status_code !== VNPT_STATUS_OK) {
        throw new Error(
          `SmartCA TH /confirm reject: ${confirmResp.message ?? 'status_code=' + confirmResp.status_code}`,
        );
      }

      const signatureValue = confirmResp.data?.signatures?.[0]?.signature_value;
      if (!signatureValue) {
        throw new Error('SmartCA TH /confirm không trả signature_value');
      }

      // Cache signature → worker poll attempt 1 sẽ thấy completed
      cacheSet(vnptTxnId, signatureValue);

      return { providerTransactionId: vnptTxnId };
    },

    // --------------------------------------------------------------------
    // POLL: lookup cache, trả completed ngay (TH sync — không thực sự poll provider)
    // --------------------------------------------------------------------
    async getSignStatus(
      _admin: AdminCredentials,
      _user: UserConfig,
      providerTxnId: string,
    ): Promise<GetStatusResult> {
      const signatureBase64 = cacheGet(providerTxnId);
      if (signatureBase64) {
        // Cleanup sau khi lấy — single-use
        signatureCache.delete(providerTxnId);
        return { status: 'completed', signatureBase64 };
      }
      return {
        status: 'failed',
        errorMessage:
          'SmartCA TH cache miss — signature đã được tiêu thụ hoặc transaction expired',
      };
    },
  };
}

/** Singleton — production code dùng đây. Test inject mock qua factory. */
export const smartcaVnptThProvider: SigningProvider = createSmartCaVnptThProvider();
