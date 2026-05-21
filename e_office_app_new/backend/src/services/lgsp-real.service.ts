// ============================================================
// LGSP Real Service — implements ILgspService với apiltvb.langson.gov.vn
// Phase 18 v3.0: replace lgsp-mock.service.ts khi MOCK_EXTERNAL=false
// Phase 33 refactor: constructor injection credential thay vì đọc env hardcoded
//   - Nếu truyền `credentials` vào constructor → per-unit instance (factory dùng)
//   - Nếu không truyền → fallback đọc env (Phase 18 backward compat — test/mock)
// Phase 34 (Plan 34-01): sendDocument() rewrite dung dung LGSP API real:
//   - Endpoint POST {baseUrl}/v1/sendEdoc (KHONG /api/lgspedoc/send-edoc)
//   - Body multipart/form-data: edocFile (Buffer) + messageType=edoc
//   - Auth: HTTP headers X-SystemId + X-SecretKey (KHONG login token)
//   - Signature doi: (string, string) -> (Buffer, string, string)
//   - Error throw LgspSendError voi code 9 ma LGSP (D-12)
// ============================================================
import FormData from 'form-data';
import type {
  ILgspService,
  LgspSendResult,
  LgspOrganization,
  LgspReceivedDocSummary,
  LgspReceivedDocFull,
} from './lgsp.service.js';
import { LgspSendError, mapLgspError } from './lgsp/error-codes.js';

// Phase 37.3 fix (2026-05-22): LGSP Lang Son login endpoint /v1/auth/login authoritative shape
// (Postman LTVB_API_TRUC_PROD_TICHHOP collection). Token nested trong `data.token`, root co code/message.
// Field `code` may equal 200 hoac string. Token JWT len ~948 chars.
interface LoginResponse {
  code?: number | string;
  success?: boolean;       // Phase 18 legacy field
  message?: string;
  token?: string;          // Phase 18 legacy root-level token
  data?: {
    id?: string;
    username?: string;
    name?: string;
    token?: string;        // Phase 37: authoritative location
  };
}

/**
 * Phase 34: response shape 2 variants (Postman 03.sendEdoc + sandbox real test):
 *   Success: { success: true, message: 'OK', docId: '<uuid>' }
 *   Error:   { success: false, message: 'Loi', data: { docId: null, status: 'error', errorCode, errorDesc } }
 * All fields trong `data` optional vi server co the omit khi success.
 */
interface SendEdocResponse {
  success: boolean;
  message: string;
  docId?: string;
  data?: {
    docId?: string | null;
    status?: string;
    errorCode?: string;
    errorDesc?: string;
  };
}

interface ReceivedEdocItem {
  serviceType: string;
  createdTime: string;
  updatedTime: string;
  messageType: string;
  docId: string;
  from: string;
  to: string;
  status: string;
  statusDesc: string;
}

interface ReceivedEdocsResponse {
  success: boolean;
  message: string;
  count: number;
  data: ReceivedEdocItem[];
}

interface GetEdocResponse {
  success: boolean;
  message: string;
  data?: {
    docId: string;
    from: string;
    fromName?: string;
    edocCode?: string;
    edocAbstract?: string;
    edxml: string;
    attachments?: { fileName: string; fileContent: string }[];
  };
}

interface OrgListResponse {
  success: boolean;
  data: Array<{
    orgCode: string;
    orgName: string;
    parentCode?: string | null;
    address?: string | null;
    email?: string | null;
    phone?: string | null;
  }>;
}

const TOKEN_TTL_MS = 29 * 60 * 1000; // 29 phút (LGSP token expire 30')

/**
 * Credential để inject vào LGSPRealService.
 * Phase 33: lookup từ `edoc.lgsp_agency_config` qua repo, decrypt secret_key trước khi pass vào đây.
 *
 * Phase 37.3 (2026-05-22): Add `environment` field để getToken() pick per-env admin creds.
 *   - sandbox: LGSP_SANDBOX_USERNAME / LGSP_SANDBOX_PASSWORD / LGSP_SANDBOX_APPLICATION_CODE
 *   - prod:    LGSP_PROD_USERNAME    / LGSP_PROD_PASSWORD    / LGSP_PROD_APPLICATION_CODE
 *   - fallback (env=undefined): legacy LGSP_USERNAME / LGSP_PASSWORD / LGSP_APPLICATION_CODE
 */
export interface LgspCredentials {
  baseUrl: string;                          // VD: 'https://apiltvb.langson.gov.vn'
  systemId: string;                         // VD: 'H37.DN.001'
  secretKey: string;                        // PLAINTEXT (đã decrypt từ BYTEA)
  environment?: 'sandbox' | 'prod';         // Phase 37.3 — per-env admin cred selection
}

export class LGSPRealService implements ILgspService {
  private cachedToken: string | null = null;
  private tokenExpiresAt = 0;
  private readonly credentials: LgspCredentials | undefined;

  /**
   * @param credentials Nếu undefined → fallback đọc env (Phase 18 backward compat).
   *                    Nếu defined → per-unit instance (Phase 33 factory dùng).
   */
  constructor(credentials?: LgspCredentials) {
    this.credentials = credentials;
  }

  private get endpoint(): string {
    if (this.credentials) return this.credentials.baseUrl.replace(/\/$/, '');
    const ep = process.env.LGSP_ENDPOINT;
    if (!ep) throw new Error('LGSP_ENDPOINT is not set (no credentials provided)');
    return ep.replace(/\/$/, '');
  }

  private get systemId(): string {
    if (this.credentials) return this.credentials.systemId;
    return process.env.LGSP_SYSTEM_ID || '';
  }

  private get secretKey(): string {
    if (this.credentials) return this.credentials.secretKey;
    return process.env.LGSP_SECRET_KEY || '';
  }

  private async fetchJson<T>(url: string, init?: RequestInit, timeoutMs = 30000): Promise<T> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    try {
      const res = await fetch(url, { ...init, signal: controller.signal });
      const text = await res.text();
      if (!res.ok) throw new Error(`LGSP HTTP ${res.status}: ${text.slice(0, 300)}`);
      return JSON.parse(text) as T;
    } finally {
      clearTimeout(timer);
    }
  }

  // Phase 37.3 fix (2026-05-22): LGSP Lang Son authoritative login endpoint.
  // - Endpoint: /v1/auth/login?allow_anonymous=true (KHONG /api/lgspedoc/login legacy)
  // - Body: { username, password, applicationCode, otp:null, twoFactorProvider:null, typeObjs:[0,1] }
  // - Response: { code, message, data: { token, id, username, name, ... } }  -- token nested in data
  // - Per-env admin creds: LGSP_SANDBOX_* / LGSP_PROD_* (fallback legacy LGSP_USERNAME etc.)
  //
  // Token used as `Authorization: Bearer <token>` in ALL per-DN API calls (Phase 37.3 -- previously
  // omitted, caused HTTP 401 "licenseInfo:invalid" tu LGSP truc).
  async getToken(): Promise<string> {
    if (this.cachedToken && Date.now() < this.tokenExpiresAt) return this.cachedToken;

    // Phase 37.3: per-env admin credentials. Pick LGSP_SANDBOX_* or LGSP_PROD_* by environment.
    // Fallback to legacy LGSP_USERNAME / LGSP_PASSWORD / LGSP_APPLICATION_CODE (dev/test backward compat).
    const env = this.credentials?.environment;
    const envPrefix = env === 'prod' ? 'LGSP_PROD' : env === 'sandbox' ? 'LGSP_SANDBOX' : null;

    const username = (envPrefix && process.env[`${envPrefix}_USERNAME`]) || process.env.LGSP_USERNAME;
    const password = (envPrefix && process.env[`${envPrefix}_PASSWORD`]) || process.env.LGSP_PASSWORD;
    const applicationCode =
      (envPrefix && process.env[`${envPrefix}_APPLICATION_CODE`]) || process.env.LGSP_APPLICATION_CODE;

    if (!username || !password || !applicationCode) {
      const which = envPrefix ? `${envPrefix}_USERNAME/PASSWORD/APPLICATION_CODE` : 'LGSP_USERNAME/PASSWORD/APPLICATION_CODE';
      throw new Error(`LGSP admin credentials missing for env=${env ?? 'legacy'} (cần set ${which} trong backend/.env)`);
    }

    const res = await this.fetchJson<LoginResponse>(`${this.endpoint}/v1/auth/login?allow_anonymous=true`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username,
        password,
        applicationCode,
        otp: null,
        twoFactorProvider: null,
        typeObjs: [0, 1],
      }),
    });

    // Phase 37.3: token nested in res.data.token (Postman authoritative). Fallback res.token (legacy Phase 18).
    const token = res.data?.token || res.token;
    if (!token) {
      throw new Error(`LGSP login failed: ${res.message || 'no token in response'} (code=${res.code ?? 'n/a'})`);
    }

    this.cachedToken = token;
    this.tokenExpiresAt = Date.now() + TOKEN_TTL_MS;
    return this.cachedToken;
  }

  /**
   * Send edXML doc qua LGSP `/v1/sendEdoc` (Phase 34 - CONTEXT D-07).
   *
   * AUTHORITATIVE shape (Postman collection 03.sendEdoc):
   *   POST {baseUrl}/v1/sendEdoc
   *   Headers: X-SystemId, X-SecretKey
   *   Body: multipart/form-data
   *     edocFile: <Buffer> (Content-Type: application/xml, filename: {docCode}.edxml)
   *     messageType: 'edoc'
   *
   * Response variants:
   *   { success: true, message: 'OK', docId: '<uuid>' }
   *   { success: false, message: 'Loi', data: { docId, status, errorCode, errorDesc } }
   *
   * NO login/token flow cho document API - khac voi Phase 18 dung OAuth2 endpoint
   * `/api/lgspedoc/send-edoc`. Postman collection cua tinh Lang Son xac dinh ro
   * doc API dung HTTP headers, login token chi cho admin API (registerAgency, etc.).
   *
   * @param edxmlBuffer edXML envelope bytes (built boi edxml-builder.ts buildEdxml())
   * @param destOrgCode Code don vi nhan (cho log only - LGSP parse tu edXML MessageHeader.To)
   * @param docCode Notation/document_code (lam filename trong multipart, .edxml extension)
   * @returns LgspSendResult { success, lgsp_doc_id, message, errorCode }
   * @throws LgspSendError khi network/timeout/non-JSON response (no code = retryable per D-11)
   */
  async sendDocument(
    edxmlBuffer: Buffer,
    destOrgCode: string,
    docCode: string,
  ): Promise<LgspSendResult> {
    const sysId = this.systemId;
    const secret = this.secretKey;
    if (!sysId || !secret) {
      throw new LgspSendError(
        `LGSP credential missing: systemId=${sysId ? 'OK' : 'EMPTY'}, secretKey=${secret ? 'OK' : 'EMPTY'}`,
      );
    }

    // Sanitize docCode for filename - replace path chars + cap length + add extension
    const safeFilename =
      (docCode || 'edoc').replace(/[\\/:*?"<>|]/g, '_').slice(0, 100) + '.edxml';

    // Build multipart form (form-data lib)
    const form = new FormData();
    form.append('edocFile', edxmlBuffer, {
      filename: safeFilename,
      contentType: 'application/xml',
      knownLength: edxmlBuffer.length,
    });
    form.append('messageType', 'edoc');

    // form-data lib KHONG stream qua Node native fetch dung cach (LGSP sandbox tra
    // ve "Unexpected end of Stream, the content may have already been read..."
    // khi pass form-data stream truc tiep). Convert sang Buffer + set Content-Length
    // header de fetch send body fully.
    const formBuffer = form.getBuffer();
    const formHeaders = form.getHeaders();

    // Phase 37.3: lay admin Bearer token (per-env tu env vars) -- LGSP truc Lang Son yeu cau
    // ca 3 header: Authorization: Bearer + X-SystemId + X-SecretKey.
    const bearerToken = await this.getToken();

    // Fetch - Node 22+ native, 60s timeout (LGSP send may take long voi big attachments)
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 60000);
    try {
      const res = await fetch(`${this.endpoint}/v1/sendEdoc`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${bearerToken}`,
          'X-SystemId': sysId,
          'X-SecretKey': secret,
          ...formHeaders,
          'Content-Length': String(formBuffer.length),
        },
        // Buffer = Uint8Array — fetch BodyInit accept BufferSource, cast de TS happy.
        body: formBuffer as unknown as BodyInit,
        signal: controller.signal,
      });

      const text = await res.text();
      let json: SendEdocResponse;
      try {
        json = JSON.parse(text) as SendEdocResponse;
      } catch {
        // Server tra ve non-JSON (HTML error page, 502 Bad Gateway, ...)
        throw new LgspSendError(
          `LGSP /v1/sendEdoc HTTP ${res.status} non-JSON response: ${text.slice(0, 200)}`,
        );
      }

      // Parse 2 shape variants (Postman docs)
      const docId = json.docId || json.data?.docId || '';
      const errorCode = json.data?.errorCode;
      const rawMessage = json.message || json.data?.errorDesc || 'unknown';

      if (!json.success) {
        // No-throw - return result de worker biet update tracking status='error'
        // (no-retry per D-11 vi 4xx LGSP error la business error, retry vo nghia)
        return {
          success: false,
          lgsp_doc_id: docId || '',
          message: mapLgspError(errorCode, rawMessage),
          errorCode: errorCode || undefined,
        };
      }

      return {
        success: true,
        lgsp_doc_id: docId || '',
        message: rawMessage,
        errorCode: errorCode || '0',
      };
    } catch (err: unknown) {
      // AbortController / network / DNS / connection - throw de BullMQ retry
      if (err instanceof LgspSendError) throw err;
      const msg = err instanceof Error ? err.message : String(err);
      throw new LgspSendError(`LGSP /v1/sendEdoc network/timeout: ${msg}`);
    } finally {
      clearTimeout(timer);
    }
  }

  /**
   * Phase 35 (Plan 35-01): Fix Phase 18 BROKEN implementation.
   *
   * AUTHORITATIVE shape (Postman collection 04.syncReceivedEdocList):
   *   GET {baseUrl}/v1/syncReceivedEdocList?messageType=edoc&fromDate=YYYY/MM/DD&toDate=YYYY/MM/DD
   *   Headers: X-SystemId, X-SecretKey  (NO login token, NO body)
   *   Response: { success, message, count, data: [{ docId, from, to, status, statusDesc, ... }] }
   *
   * Caller (Plan 35-02 worker) is responsible for:
   *   - Computing fromDate = COALESCE(last_synced_at, NOW() - 7 days), toDate = NOW()
   *   - Formatting both as YYYY/MM/DD (NOT YYYY-MM-DD per LGSP spec)
   *   - Filtering out already-processed docs (status='initial' typically the only one need pull)
   *   - Calling getEdocById() for each new docId to fetch full payload
   */
  async receiveDocuments(
    fromDateYmd: string,
    toDateYmd: string,
  ): Promise<LgspReceivedDocSummary[]> {
    const sysId = this.systemId;
    const secret = this.secretKey;
    if (!sysId || !secret) {
      throw new Error(
        `LGSP credential missing for receiveDocuments: systemId=${sysId ? 'OK' : 'EMPTY'}, secretKey=${secret ? 'OK' : 'EMPTY'}`,
      );
    }
    const url =
      `${this.endpoint}/v1/syncReceivedEdocList` +
      `?messageType=edoc` +
      `&fromDate=${encodeURIComponent(fromDateYmd)}` +
      `&toDate=${encodeURIComponent(toDateYmd)}`;
    // Phase 37.3: LGSP truc Lang Son yeu cau Authorization: Bearer + X-SystemId + X-SecretKey.
    const bearerToken = await this.getToken();
    const res = await this.fetchJson<ReceivedEdocsResponse>(
      url,
      {
        method: 'GET',
        headers: {
          Authorization: `Bearer ${bearerToken}`,
          'X-SystemId': sysId,
          'X-SecretKey': secret,
          Accept: 'application/json',
        },
      },
      30000,
    );
    if (!res.success || !Array.isArray(res.data)) return [];
    return res.data.map((d) => ({
      lgsp_doc_id: d.docId,
      from_org_code: d.from,
      to_org_code: d.to,
      status: d.status,
      status_desc: d.statusDesc,
      created_time: d.createdTime,
      updated_time: d.updatedTime,
    }));
  }

  /**
   * Phase 35 (Plan 35-01): New method -- fetch single doc full payload by docId.
   *
   * AUTHORITATIVE shape (Postman collection 05.getEdoc):
   *   GET {baseUrl}/v1/getEdoc?docId=<uuid>
   *   Headers: X-SystemId, X-SecretKey
   *   Response: { success, message, data: { docId, from, fromName?, edocCode?, edocAbstract?,
   *                                          edxml: string, attachments?: [{ fileName, fileContent(base64) }] } }
   *
   * Returns null when LGSP says success=false or data is missing (doc may have been deleted).
   * Caller (Plan 35-02 worker) parses `edxml` via services/lgsp/edxml-parser.ts.
   */
  async getEdocById(docId: string): Promise<LgspReceivedDocFull | null> {
    const sysId = this.systemId;
    const secret = this.secretKey;
    if (!sysId || !secret) {
      throw new Error(
        `LGSP credential missing for getEdocById: systemId=${sysId ? 'OK' : 'EMPTY'}, secretKey=${secret ? 'OK' : 'EMPTY'}`,
      );
    }
    const url = `${this.endpoint}/v1/getEdoc?docId=${encodeURIComponent(docId)}`;
    // Phase 37.3: LGSP truc Lang Son yeu cau Authorization: Bearer + X-SystemId + X-SecretKey.
    const bearerToken = await this.getToken();
    const res = await this.fetchJson<GetEdocResponse>(
      url,
      {
        method: 'GET',
        headers: {
          Authorization: `Bearer ${bearerToken}`,
          'X-SystemId': sysId,
          'X-SecretKey': secret,
          Accept: 'application/json',
        },
      },
      60000, // bigger timeout — payload may include attachments
    );
    if (!res.success || !res.data) return null;
    return {
      lgsp_doc_id: res.data.docId,
      sender_org_code: res.data.from || '',
      sender_org_name: res.data.fromName || '',
      edoc_code: res.data.edocCode || '',
      edoc_abstract: res.data.edocAbstract || '',
      edxml: res.data.edxml || '',
      attachments: (res.data.attachments || []).map((a) => ({
        file_name: a.fileName,
        file_content_base64: a.fileContent,
      })),
    };
  }

  /**
   * Phase 36 (Plan 36-01): NEW method -- status callback ve LGSP truc (9 ma QD 28).
   *
   * AUTHORITATIVE shape (Postman collection 06.updateStatus):
   *   POST {baseUrl}/v1/updateStatus
   *   Headers: Content-Type: application/json, X-SystemId, X-SecretKey
   *   Body (JSON): { "docId": "<uuid>", "status": "<ma QD 28 hoac keyword>" }
   *
   * Postman sample dung "status": "done" (keyword). Phase 36 default dung MA SO QD 28
   * ('02','03','04','05','06') -- chuan re tu spec QD 28/2018/QD-TTg. Neu LGSP reject ma so
   * (errorCode 22 -- format khong dung), Plan 36-05 verification report flag de switch keyword map.
   *
   * Response variants (Postman + sandbox):
   *   { success: true, message: 'OK' }  -- no docId echo, no errorCode
   *   { success: false, message: 'Loi', data?: { errorCode, errorDesc } }
   *
   * Reuse LgspSendResult shape (lgsp.service.ts) -- Phase 36 worker xu ly errorCode classify
   * retry vs no-retry qua isLgspNonRetryableError() (Phase 34 error-codes.ts shared).
   *
   * @param docId LGSP doc UUID (lgsp_status_outbox.payload.lgsp_doc_id)
   * @param status Target status code per QD 28
   * @returns LgspSendResult { success, lgsp_doc_id (=docId echo), message, errorCode }
   * @throws LgspSendError khi network/timeout/non-JSON response
   */
  async updateStatus(docId: string, status: string): Promise<LgspSendResult> {
    const sysId = this.systemId;
    const secret = this.secretKey;
    if (!sysId || !secret) {
      throw new LgspSendError(
        `LGSP credential missing for updateStatus: systemId=${sysId ? 'OK' : 'EMPTY'}, secretKey=${secret ? 'OK' : 'EMPTY'}`,
      );
    }

    const url = `${this.endpoint}/v1/updateStatus`;
    const bodyJson = JSON.stringify({ docId, status });

    // Phase 37.3: LGSP truc Lang Son yeu cau Authorization: Bearer + X-SystemId + X-SecretKey.
    const bearerToken = await this.getToken();

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 30_000);
    try {
      const res = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${bearerToken}`,
          'X-SystemId': sysId,
          'X-SecretKey': secret,
          Accept: 'application/json',
        },
        body: bodyJson,
        signal: controller.signal,
      });

      const text = await res.text();
      let json: { success: boolean; message?: string; data?: { errorCode?: string; errorDesc?: string } };
      try {
        json = JSON.parse(text);
      } catch {
        throw new LgspSendError(
          `LGSP /v1/updateStatus HTTP ${res.status} non-JSON response: ${text.slice(0, 200)}`,
        );
      }

      const errorCode = json.data?.errorCode;
      const rawMessage = json.message || json.data?.errorDesc || 'unknown';

      if (!json.success) {
        // No-throw -- return result de worker biet mark outbox error
        return {
          success: false,
          lgsp_doc_id: docId,
          message: mapLgspError(errorCode, rawMessage),
          errorCode: errorCode || undefined,
        };
      }

      return {
        success: true,
        lgsp_doc_id: docId,
        message: rawMessage,
        errorCode: '0',
      };
    } catch (err: unknown) {
      if (err instanceof LgspSendError) throw err;
      const msg = err instanceof Error ? err.message : String(err);
      throw new LgspSendError(`LGSP /v1/updateStatus network/timeout: ${msg}`);
    } finally {
      clearTimeout(timer);
    }
  }

  // Phase 37.3 fix (2026-05-22): Doi endpoint tu legacy /api/lgspedoc/organizations sang
  // /v1/getAgenciesList (Postman authoritative). Authentication = Authorization: Bearer header
  // (KHONG con query param ?token=). Response shape co the la flat array hoac { success, data }.
  async syncOrganizations(): Promise<LgspOrganization[]> {
    const token = await this.getToken();
    const url = `${this.endpoint}/v1/getAgenciesList`;
    try {
      const res = await this.fetchJson<OrgListResponse | { data?: OrgListResponse['data'] } | OrgListResponse['data']>(
        url,
        {
          method: 'GET',
          headers: {
            Authorization: `Bearer ${token}`,
            Accept: 'application/json',
          },
        },
        30000,
      );
      // Postman shape: { code:200, data:[...] } | { success, data:[...] } | direct array
      const list: OrgListResponse['data'] | undefined = Array.isArray(res)
        ? res
        : (res as OrgListResponse).data;
      if (!Array.isArray(list)) return [];
      return list.map((o) => ({
        org_code: o.orgCode,
        org_name: o.orgName,
        parent_code: o.parentCode || null,
        address: o.address || null,
        email: o.email || null,
        phone: o.phone || null,
      }));
    } catch {
      return [];
    }
  }
}

/**
 * Phase 33 factory helper — tạo instance per-unit từ credential đã decrypt.
 *
 * Usage trong lgsp.service.ts:
 *   const config = await lgspAgencyConfigRepository.getByUnitId(unitId, env);
 *   const plaintext = await decryptSecret(config.secret_key_encrypted);
 *   const service = createLgspRealService({
 *     baseUrl: config.base_url,
 *     systemId: config.system_id,
 *     secretKey: plaintext,
 *   });
 */
export function createLgspRealService(credentials: LgspCredentials): LGSPRealService {
  return new LGSPRealService(credentials);
}

/**
 * Phase 18 backward compat — singleton dùng env vars (LGSP_ENDPOINT, LGSP_SYSTEM_ID, LGSP_SECRET_KEY,
 * LGSP_USERNAME, LGSP_PASSWORD, LGSP_APPLICATION_CODE).
 *
 * `routes/lgsp.ts` Phase 18 vẫn import singleton này qua factory `getLgspService()` (không truyền arg).
 */
export const lgspRealService = new LGSPRealService();
