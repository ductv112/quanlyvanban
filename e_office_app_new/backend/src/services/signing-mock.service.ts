// ============================================================
// Signing Mock Service — Per D-05, D-07
// Mocks SmartCA and EsignNEAC signing flows
// SmartCA: 2-step (initiate -> OTP verify)
// EsignNEAC: 1-step (immediate sign)
// ============================================================

import { randomUUID } from 'crypto';
import pino from 'pino';
import { digitalSignatureRepository } from '../repositories/digital-signature.repository.js';
import type {
  ISigningService,
  SmartCASignParams,
  EsignNEACParams,
  SignResult,
} from './signing.service.js';

const logger = pino({ name: 'signing-mock' });

export const signingMockService: ISigningService = {

  async signSmartCA(params: SmartCASignParams): Promise<SignResult> {
    logger.info(
      { doc_id: params.doc_id, doc_type: params.doc_type, staff_id: params.staff_id },
      'MOCK: Initiating SmartCA signing for doc %d',
      params.doc_id,
    );

    // Create signature record with status 'signing' (awaiting OTP)
    const result = await digitalSignatureRepository.create(
      params.doc_id,
      params.doc_type,
      params.staff_id,
      'smart_ca',
      params.file_path,
    );

    if (!result.success) {
      return { success: false, message: result.message };
    }

    // Update status to 'signing' (pending OTP)
    await digitalSignatureRepository.updateStatus(
      result.id,
      'signing',
      null, null, null, null, null,
    );

    return {
      success: true,
      signature_id: result.id,
      requires_otp: true,
      message: 'MOCK: OTP sent to registered phone',
    };
  },

  async verifyOTP(signatureId: number, otp: string): Promise<SignResult> {
    logger.info(
      { signatureId, otp },
      'MOCK: Verifying OTP for signature %d',
      signatureId,
    );

    const certSerial = `MOCK-CERT-${Date.now()}`;
    const certSubject = 'CN=Nguyen Van A, O=UBND tinh Lao Cai';
    const certIssuer = 'CN=VNPT-CA, O=VNPT Group';
    const signedPath = `signed/${randomUUID()}.pdf`;

    // Update signature to 'signed' with certificate info
    const result = await digitalSignatureRepository.updateStatus(
      signatureId,
      'signed',
      certSerial,
      certSubject,
      certIssuer,
      signedPath,
      null,
    );

    if (!result.success) {
      return { success: false, message: result.message };
    }

    return {
      success: true,
      signature_id: signatureId,
      message: 'MOCK: Document signed successfully via SmartCA',
      certificate_serial: certSerial,
      certificate_subject: certSubject,
      signed_file_path: signedPath,
    };
  },

  async signEsignNEAC(params: EsignNEACParams): Promise<SignResult> {
    logger.info(
      { doc_id: params.doc_id, doc_type: params.doc_type, ca_provider: params.ca_provider },
      'MOCK: EsignNEAC signing for doc %d via %s',
      params.doc_id,
      params.ca_provider,
    );

    // Create signature record
    const result = await digitalSignatureRepository.create(
      params.doc_id,
      params.doc_type,
      params.staff_id,
      'esign_neac',
      params.file_path,
    );

    if (!result.success) {
      return { success: false, message: result.message };
    }

    const certSerial = `MOCK-NEAC-${Date.now()}`;
    const certSubject = `CN=Nguyen Van A, O=UBND tinh Lao Cai, CA=${params.ca_provider}`;
    const certIssuer = `CN=${params.ca_provider}, O=EsignNEAC`;
    const signedPath = `signed/${randomUUID()}.pdf`;

    // Immediately sign (no OTP step for EsignNEAC)
    await digitalSignatureRepository.updateStatus(
      result.id,
      'signed',
      certSerial,
      certSubject,
      certIssuer,
      signedPath,
      null,
    );

    return {
      success: true,
      signature_id: result.id,
      message: 'MOCK: Document signed via EsignNEAC',
      certificate_serial: certSerial,
      certificate_subject: certSubject,
      signed_file_path: signedPath,
    };
  },
};
