// ============================================================
// LGSP Mock Service — Per D-00c, D-01
// Returns realistic Vietnamese mock data for development
// ============================================================

import pino from 'pino';
import { redis } from '../lib/redis/client.js';
import type {
  ILgspService,
  LgspReceivedDoc,
  LgspSendResult,
  LgspOrganization,
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

const MOCK_DOCS: LgspReceivedDoc[] = [
  {
    lgsp_doc_id: 'LGSP-MOCK-001',
    doc_code: '145/UBND-VP',
    doc_abstract: 'V/v tang cuong phong chong bao lut nam 2026',
    sender_org_code: 'H01.01',
    sender_org_name: 'UBND tinh Lao Cai',
    edxml_content: '<edXML><header><subject>V/v tang cuong phong chong bao lut nam 2026</subject></header></edXML>',
    attachments: [{ file_name: 'cong_van_145.pdf', file_content: 'base64-mock-content' }],
  },
  {
    lgsp_doc_id: 'LGSP-MOCK-002',
    doc_code: '89/STC-NSNN',
    doc_abstract: 'V/v bo sung kinh phi thuc hien nhiem vu cap bach',
    sender_org_code: 'H01.01.02',
    sender_org_name: 'So Tai chinh tinh Lao Cai',
    edxml_content: '<edXML><header><subject>V/v bo sung kinh phi thuc hien nhiem vu cap bach</subject></header></edXML>',
    attachments: [],
  },
];

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

  async receiveDocuments(): Promise<LgspReceivedDoc[]> {
    // Randomly return 0-2 documents to simulate real polling behavior
    const count = Math.floor(Math.random() * 3);
    const docs = MOCK_DOCS.slice(0, count);
    logger.info(`MOCK: Polling LGSP — found ${docs.length} documents`);
    return docs;
  },

  async sendDocument(edxmlContent: string, destOrgCode: string): Promise<LgspSendResult> {
    logger.info(`MOCK: Sending document to ${destOrgCode}`);
    return {
      success: true,
      lgsp_doc_id: `LGSP-${Date.now()}`,
      message: 'Mock: Document sent successfully',
    };
  },

  async syncOrganizations(): Promise<LgspOrganization[]> {
    logger.info(`MOCK: Synced ${MOCK_ORGS.length} organizations`);
    return MOCK_ORGS;
  },
};
