// ============================================================
// Signing Service Interface + Factory
// Per D-05: MOCK_EXTERNAL=true env flag controls mock vs real
// Supports SmartCA (VNPT) and EsignNEAC signing methods
// ============================================================

export interface SmartCASignParams {
  doc_id: number;
  doc_type: 'outgoing' | 'drafting';
  staff_id: number;
  file_path: string;  // MinIO path of original file
}

export interface EsignNEACParams {
  doc_id: number;
  doc_type: 'outgoing' | 'drafting';
  staff_id: number;
  file_path: string;
  ca_provider: string;  // e.g. 'viettel-ca', 'vnpt-ca', 'bkav-ca'
}

export interface SignResult {
  success: boolean;
  signature_id?: number;
  message: string;
  requires_otp?: boolean;  // SmartCA requires OTP step
  certificate_serial?: string;
  certificate_subject?: string;
  signed_file_path?: string;
}

export interface ISigningService {
  signSmartCA(params: SmartCASignParams): Promise<SignResult>;
  signEsignNEAC(params: EsignNEACParams): Promise<SignResult>;
  verifyOTP(signatureId: number, otp: string): Promise<SignResult>;
}

/**
 * Factory: returns mock service when MOCK_EXTERNAL=true.
 * Returns real service (throws for now) otherwise.
 */
export async function getSigningService(): Promise<ISigningService> {
  if (process.env.MOCK_EXTERNAL === 'true') {
    const mod = await import('./signing-mock.service.js');
    return mod.signingMockService;
  }
  throw new Error('Real signing service not implemented yet — set MOCK_EXTERNAL=true');
}
