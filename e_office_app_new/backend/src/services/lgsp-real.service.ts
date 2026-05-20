// ============================================================
// LGSP Real Service — implements ILgspService với apiltvb.langson.gov.vn
// Phase 18 v3.0: replace lgsp-mock.service.ts khi MOCK_EXTERNAL=false
// Phase 33 refactor: constructor injection credential thay vì đọc env hardcoded
//   - Nếu truyền `credentials` vào constructor → per-unit instance (factory dùng)
//   - Nếu không truyền → fallback đọc env (Phase 18 backward compat — test/mock)
// ============================================================
import type {
  ILgspService,
  LgspReceivedDoc,
  LgspSendResult,
  LgspOrganization,
} from './lgsp.service.js';

interface LoginResponse {
  success: boolean;
  message: string;
  token: string;
  data?: { id: string; username: string; name: string; token: string };
}

interface SendEdocResponse {
  success: boolean;
  message: string;
  docId?: string;
  data?: { status: string; errorCode: string; errorDesc: string; docId: string };
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
 * Lưu ý: `username` / `password` / `applicationCode` (LGSP login) vẫn đọc env trong `getToken()` —
 * 6 DN Lạng Sơn dùng chung 1 LGSP user. Nếu sau này per-unit cần user riêng, thêm field optional ở đây
 * và override trong `getToken()`.
 */
export interface LgspCredentials {
  baseUrl: string;          // VD: 'https://apiltvb.langson.gov.vn'
  systemId: string;         // VD: 'H37.DN.001'
  secretKey: string;        // PLAINTEXT (đã decrypt từ BYTEA)
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

  async getToken(): Promise<string> {
    if (this.cachedToken && Date.now() < this.tokenExpiresAt) return this.cachedToken;

    // Phase 18 login flow giữ nguyên — username/password vẫn đọc env (per-unit chưa cần)
    // Phase 33: nếu credentials inject → systemId/secretKey override, nhưng username/password
    //           vẫn dùng env (giả định 6 DN dùng cùng 1 user LGSP, hoặc per-unit add field sau)
    const username = process.env.LGSP_USERNAME;
    const password = process.env.LGSP_PASSWORD;
    const applicationCode = process.env.LGSP_APPLICATION_CODE;
    if (!username || !password || !applicationCode) {
      throw new Error('LGSP credentials missing (LGSP_USERNAME / LGSP_PASSWORD / LGSP_APPLICATION_CODE)');
    }

    const res = await this.fetchJson<LoginResponse>(`${this.endpoint}/api/lgspedoc/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password, applicationCode }),
    });

    if (!res.success || !res.token) {
      throw new Error(`LGSP login failed: ${res.message}`);
    }

    this.cachedToken = res.token;
    this.tokenExpiresAt = Date.now() + TOKEN_TTL_MS;
    return this.cachedToken;
  }

  async sendDocument(edxmlContent: string, destOrgCode: string): Promise<LgspSendResult> {
    const token = await this.getToken();
    // LGSP spec: edxml gửi qua filePath. Vì backend giữ trong memory, ghi tạm xuống disk hoặc
    // gửi qua endpoint khác (tùy implementation thực tế của LGSP). Dưới đây giả định endpoint
    // accept inline edxml content qua field `edocContent` (cần verify với LGSP support khi triển khai).
    const res = await this.fetchJson<SendEdocResponse>(`${this.endpoint}/api/lgspedoc/send-edoc`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        token,
        edocContent: edxmlContent,
        messageType: 'edoc',
        systemId: this.systemId,
        secretKey: this.secretKey,
        destOrgCode, // forward đến LGSP để route
      }),
    });

    return {
      success: !!res.success,
      lgsp_doc_id: res.docId || res.data?.docId || '',
      message: res.message || res.data?.errorDesc || 'unknown',
    };
  }

  async receiveDocuments(): Promise<LgspReceivedDoc[]> {
    const token = await this.getToken();
    const today = new Date();
    const fromDate = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000) // 7 ngày qua
      .toISOString().slice(0, 10);
    const toDate = today.toISOString().slice(0, 10);

    const url = `${this.endpoint}/api/lgspedoc/received-edocs?token=${encodeURIComponent(token)}` +
      `&messageType=edoc&fromDate=${fromDate}&toDate=${toDate}` +
      `&systemId=${encodeURIComponent(this.systemId)}&secretKey=${encodeURIComponent(this.secretKey)}`;

    const res = await this.fetchJson<ReceivedEdocsResponse>(url);
    if (!res.success || !Array.isArray(res.data)) return [];

    // Filter docs status='initial' (chưa xử lý) — fetch chi tiết từng doc
    const initialDocs = res.data.filter((d) => d.status === 'initial');
    const detailed = await Promise.all(initialDocs.map((d) => this.getDocumentDetail(token, d.docId)));
    return detailed.filter((d): d is LgspReceivedDoc => d !== null);
  }

  private async getDocumentDetail(token: string, docId: string): Promise<LgspReceivedDoc | null> {
    try {
      const url = `${this.endpoint}/api/lgspedoc/get-edoc?token=${encodeURIComponent(token)}&docId=${encodeURIComponent(docId)}`;
      const res = await this.fetchJson<GetEdocResponse>(url);
      if (!res.success || !res.data) return null;
      return {
        lgsp_doc_id: res.data.docId,
        doc_code: res.data.edocCode || '',
        doc_abstract: res.data.edocAbstract || '',
        sender_org_code: res.data.from || '',
        sender_org_name: res.data.fromName || '',
        edxml_content: res.data.edxml || '',
        attachments: (res.data.attachments || []).map((a) => ({
          file_name: a.fileName,
          file_content: a.fileContent,
        })),
      };
    } catch {
      return null;
    }
  }

  async syncOrganizations(): Promise<LgspOrganization[]> {
    const token = await this.getToken();
    const url = `${this.endpoint}/api/lgspedoc/organizations?token=${encodeURIComponent(token)}`;
    try {
      const res = await this.fetchJson<OrgListResponse>(url);
      if (!res.success || !Array.isArray(res.data)) return [];
      return res.data.map((o) => ({
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
