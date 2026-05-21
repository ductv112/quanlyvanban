// ============================================================
// LGSP Mock Service — Per D-00c, D-01
// Returns realistic Vietnamese mock data for development
// ============================================================

import pino from 'pino';
import { redis } from '../lib/redis/client.js';
import type {
  ILgspService,
  LgspSendResult,
  LgspOrganization,
  LgspReceivedDocSummary,
  LgspReceivedDocFull,
} from './lgsp.service.js';

const logger = pino({ name: 'lgsp-mock' });

const MOCK_ORGS: LgspOrganization[] = [
  { org_code: 'H01.01', org_name: 'UBND tinh Lao Cai', parent_code: null, address: '668 Hoang Lien, TP Lao Cai', email: 'ubnd@laocai.gov.vn', phone: '02143820000' },
  { org_code: 'H01.01.01', org_name: 'So Noi vu tinh Lao Cai', parent_code: 'H01.01', address: '628 Hoang Lien, TP Lao Cai', email: 'sonoivu@laocai.gov.vn', phone: '02143821001' },
  { org_code: 'H01.01.02', org_name: 'So Tai chinh tinh Lao Cai', parent_code: 'H01.01', address: '600 Hoang Lien, TP Lao Cai', email: 'sotaichinh@laocai.gov.vn', phone: '02143821002' },
  { org_code: 'H01.01.03', org_name: 'So Ke hoach va Dau tu tinh Lao Cai', parent_code: 'H01.01', address: '500 Hoang Lien, TP Lao Cai', email: 'sokhdt@laocai.gov.vn', phone: '02143821003' },
  { org_code: 'H01.01.04', org_name: 'So Tu phap tinh Lao Cai', parent_code: 'H01.01', address: '520 Hoang Lien, TP Lao Cai', email: 'sotuphap@laocai.gov.vn', phone: '02143821004' },
  { org_code: 'H01.01.05', org_name: 'So Giao duc va Dao tao tinh Lao Cai', parent_code: 'H01.01', address: '530 Hoang Lien, TP Lao Cai', email: 'sogddt@laocai.gov.vn', phone: '02143821005' },
  { org_code: 'H01.01.06', org_name: 'So Y te tinh Lao Cai', parent_code: 'H01.01', address: '540 Hoang Lien, TP Lao Cai', email: 'soyte@laocai.gov.vn', phone: '02143821006' },
  { org_code: 'H01.01.07', org_name: 'So Cong thuong tinh Lao Cai', parent_code: 'H01.01', address: '550 Hoang Lien, TP Lao Cai', email: 'socongthuong@laocai.gov.vn', phone: '02143821007' },
];

// Phase 35: mock data theo shape moi /v1/syncReceivedEdocList + /v1/getEdoc
const MOCK_DOC_SUMMARIES: LgspReceivedDocSummary[] = [
  {
    lgsp_doc_id: 'LGSP-MOCK-001',
    from_org_code: 'H01.01',
    to_org_code: 'H01.01.99',
    status: 'initial',
    status_desc: 'Chua xu ly',
    created_time: '2026-05-20 08:00:00',
    updated_time: '2026-05-20 08:00:00',
  },
  {
    lgsp_doc_id: 'LGSP-MOCK-002',
    from_org_code: 'H01.01.02',
    to_org_code: 'H01.01.99',
    status: 'initial',
    status_desc: 'Chua xu ly',
    created_time: '2026-05-20 09:00:00',
    updated_time: '2026-05-20 09:00:00',
  },
];

function buildMockEdxml(docId: string, senderCode: string, senderName: string, subject: string): string {
  return `<?xml version="1.0" encoding="UTF-8"?><EdXMLEnvelope xmlns="http://www.go.vn/eDoc"><MessageHeader><From><OrganId>${senderCode}</OrganId><OrganName>${senderName}</OrganName></From><To><OrganId>H01.01.99</OrganId><OrganName>Mock Receiver</OrganName></To><Code><CodeNumber>1</CodeNumber><CodeNotation>MOCK</CodeNotation></Code><PromulgationInfo><Promulgator>${senderName}</Promulgator><PromulgationDate>2026-05-20</PromulgationDate></PromulgationInfo><DocumentType>Cong van</DocumentType><Subject>${subject}</Subject><SignerInfo><Signer>Mock signer</Signer><Position>GD</Position><Competence>Truc tiep</Competence></SignerInfo><OtherInfo><PageAmount>1</PageAmount></OtherInfo><DocumentId>${docId}</DocumentId></MessageHeader></EdXMLEnvelope>`;
}

export const lgspMockService: ILgspService = {
  async getToken(): Promise<string> {
    // Cache mock token in Redis with 29-minute TTL per Sprint 14.1 spec
    const cached = await redis.get('lgsp:token');
    if (cached) {
      logger.info('MOCK: LGSP OAuth2 token retrieved from cache');
      return cached;
    }

    const token = `mock-lgsp-token-${Date.now()}`;
    await redis.setex('lgsp:token', 1740, token); // 29 minutes
    logger.info('MOCK: LGSP OAuth2 token issued');
    return token;
  },

  async receiveDocuments(
    fromDateYmd: string,
    toDateYmd: string,
  ): Promise<LgspReceivedDocSummary[]> {
    // Randomly return 0-2 documents to simulate real polling behavior
    const count = Math.floor(Math.random() * 3);
    const docs = MOCK_DOC_SUMMARIES.slice(0, count);
    logger.info(
      { fromDate: fromDateYmd, toDate: toDateYmd, count: docs.length },
      'MOCK: Polling LGSP syncReceivedEdocList',
    );
    return docs;
  },

  async getEdocById(docId: string): Promise<LgspReceivedDocFull | null> {
    // Mock: return a deterministic full payload (no real DB lookup)
    const summary = MOCK_DOC_SUMMARIES.find((d) => d.lgsp_doc_id === docId);
    const sender = summary?.from_org_code || 'H01.01';
    const senderName = sender === 'H01.01' ? 'UBND tinh Lao Cai' : 'So Tai chinh tinh Lao Cai';
    const subject = `Mock doc ${docId}`;
    const edxml = buildMockEdxml(docId, sender, senderName, subject);
    logger.info({ docId, sender, bytes: edxml.length }, 'MOCK: getEdocById');
    return {
      lgsp_doc_id: docId,
      sender_org_code: sender,
      sender_org_name: senderName,
      edoc_code: 'MOCK-CODE',
      edoc_abstract: subject,
      edxml,
      attachments: [],
    };
  },

  async sendDocument(
    edxmlBuffer: Buffer,
    destOrgCode: string,
    docCode: string,
  ): Promise<LgspSendResult> {
    logger.info(
      { destOrgCode, docCode, bytes: edxmlBuffer.length },
      'MOCK: Sending document',
    );
    return {
      success: true,
      lgsp_doc_id: `LGSP-${Date.now()}`,
      message: 'Mock: Document sent successfully',
      errorCode: '0',
    };
  },

  async syncOrganizations(): Promise<LgspOrganization[]> {
    logger.info(`MOCK: Synced ${MOCK_ORGS.length} organizations`);
    return MOCK_ORGS;
  },

  async updateStatus(docId: string, status: string): Promise<LgspSendResult> {
    // Phase 36 (Plan 36-01): mock mirror real signature.
    // Always returns success -- worker dev test khong can goi LGSP real.
    logger.info({ docId, status }, 'MOCK: updateStatus called');
    return {
      success: true,
      lgsp_doc_id: docId,
      message: 'Mock: Status updated successfully',
      errorCode: '0',
    };
  },
};
