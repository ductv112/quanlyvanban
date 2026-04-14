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
 * Factory: returns mock service when MOCK_EXTERNAL=true or LGSP_ENDPOINT not set.
 * Returns real service (throws for now) otherwise.
 */
export async function getLgspService(): Promise<ILgspService> {
  if (process.env.MOCK_EXTERNAL === 'true' || !process.env.LGSP_ENDPOINT) {
    const mod = await import('./lgsp-mock.service.js');
    return mod.lgspMockService;
  }
  // TODO: real LGSP implementation with actual OAuth2 + REST calls
  throw new Error('Real LGSP service not implemented yet — set MOCK_EXTERNAL=true');
}
