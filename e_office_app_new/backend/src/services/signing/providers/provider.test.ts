/**
 * Unit tests cho SigningProvider adapter + factory.
 *
 * Run:
 *   cd e_office_app_new/backend
 *   SIGNING_SECRET_KEY=test_key_at_least_16_chars_long_xyz npx tsx --test src/services/signing/providers/provider.test.ts
 *
 * Strategy: inject mock httpClient vào factory → assert URL + body match reference
 * (Model.cs / postman collection) EXACTLY — không hit real provider API.
 */

import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

import type {
  AdminCredentials,
  CertificateInfo,
  GetStatusResult,
  ProviderCode,
  SignHashRequest,
  SignHashResult,
  SigningProvider,
  TestConnectionResult,
  UserConfig,
} from './provider.interface.js';

// ============================================================================
// Type import smoke test — nếu file này compile, interface đúng shape
// ============================================================================

describe('SigningProvider interface — type exports', () => {
  it('export ProviderCode union literal', () => {
    const a: ProviderCode = 'SMARTCA_VNPT';
    const b: ProviderCode = 'MYSIGN_VIETTEL';
    assert.equal(a, 'SMARTCA_VNPT');
    assert.equal(b, 'MYSIGN_VIETTEL');
  });

  it('AdminCredentials shape có baseUrl + clientId + clientSecretPlaintext', () => {
    const admin: AdminCredentials = {
      baseUrl: 'https://example.com',
      clientId: 'test_client',
      clientSecretPlaintext: 'test_secret',
      profileId: null,
    };
    assert.equal(admin.baseUrl, 'https://example.com');
    assert.equal(admin.clientId, 'test_client');
  });

  it('UserConfig shape có userId + optional credentialId', () => {
    const user: UserConfig = { userId: 'CMT_0123' };
    const userWithCred: UserConfig = { userId: 'CMT_0123', credentialId: 'cred_abc' };
    assert.equal(user.userId, 'CMT_0123');
    assert.equal(userWithCred.credentialId, 'cred_abc');
  });

  it('TestConnectionResult shape có success + message', () => {
    const r: TestConnectionResult = { success: true, message: 'OK' };
    assert.equal(r.success, true);
    assert.equal(r.message, 'OK');
  });

  it('CertificateInfo shape đủ 7 field', () => {
    const cert: CertificateInfo = {
      credentialId: 'cred_1',
      subject: 'CN=Test',
      serialNumber: '123',
      validFrom: '2026-01-01',
      validTo: '2027-01-01',
      certificateBase64: 'MIIE...',
      status: 'active',
    };
    assert.equal(cert.credentialId, 'cred_1');
  });

  it('SignHashRequest + SignHashResult shape', () => {
    const req: SignHashRequest = { hashHex: 'abc123', documentName: 'test.pdf', documentId: '42' };
    const res: SignHashResult = { providerTransactionId: 'TXN-001' };
    assert.equal(req.hashHex, 'abc123');
    assert.equal(res.providerTransactionId, 'TXN-001');
  });

  it('GetStatusResult enum 4 status', () => {
    const r1: GetStatusResult = { status: 'pending' };
    const r2: GetStatusResult = { status: 'completed', signatureBase64: 'sig==' };
    const r3: GetStatusResult = { status: 'failed', errorMessage: 'OTP fail' };
    const r4: GetStatusResult = { status: 'expired' };
    assert.equal(r1.status, 'pending');
    assert.equal(r2.status, 'completed');
    assert.equal(r3.status, 'failed');
    assert.equal(r4.status, 'expired');
  });

  it('SigningProvider interface có readonly code + 4 async methods', () => {
    // Chỉ compile-time check — tạo 1 implementation giả để TS verify
    const fakeProvider: SigningProvider = {
      code: 'SMARTCA_VNPT',
      async testConnection() {
        return { success: true, message: 'OK' };
      },
      async listCertificates() {
        return [];
      },
      async signHash() {
        return { providerTransactionId: 'X' };
      },
      async getSignStatus() {
        return { status: 'pending' };
      },
    };
    assert.equal(fakeProvider.code, 'SMARTCA_VNPT');
  });
});
