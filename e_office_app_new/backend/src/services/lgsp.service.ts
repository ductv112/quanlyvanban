// ============================================================
// LGSP Service Interface + Factory
// Per D-01: MOCK_EXTERNAL=true env flag controls mock vs real
// ============================================================

export interface LgspReceivedDoc {
  lgsp_doc_id: string;
  doc_code: string;
  doc_abstract: string;
  sender_org_code: string;
  sender_org_name: string;
  edxml_content: string;
  attachments: { file_name: string; file_content: string }[];
}

export interface LgspSendResult {
  success: boolean;
  lgsp_doc_id: string;
  message: string;
}

export interface LgspOrganization {
  org_code: string;
  org_name: string;
  parent_code: string | null;
  address: string | null;
  email: string | null;
  phone: string | null;
}

export interface ILgspService {
  getToken(): Promise<string>;
  receiveDocuments(): Promise<LgspReceivedDoc[]>;
  sendDocument(edxmlContent: string, destOrgCode: string): Promise<LgspSendResult>;
  syncOrganizations(): Promise<LgspOrganization[]>;
}

/**
 * Factory: switch giữa mock và real LGSP.
 * - MOCK_EXTERNAL=true HOẶC thiếu LGSP_ENDPOINT → mock service
 * - else → real service (Phase 18 v3.0): OAuth2 + REST tới apiltvb.langson.gov.vn
 */
export async function getLgspService(): Promise<ILgspService> {
  if (process.env.MOCK_EXTERNAL === 'true' || !process.env.LGSP_ENDPOINT) {
    const mod = await import('./lgsp-mock.service.js');
    return mod.lgspMockService;
  }
  const mod = await import('./lgsp-real.service.js');
  return mod.lgspRealService;
}
