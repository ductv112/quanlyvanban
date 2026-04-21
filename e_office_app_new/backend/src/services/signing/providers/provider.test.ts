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
import type { HttpClient } from './http-client.js';
import { createSmartCaVnptProvider } from './smartca-vnpt.provider.js';
import { createMysignViettelProvider } from './mysign-viettel.provider.js';

// ============================================================================
// Mock HttpClient helper — ghi lại call, trả response cài sẵn
// ============================================================================

interface RecordedCall {
  url: string;
  body: Record<string, unknown>;
  headers?: Record<string, string>;
}

/**
 * Tạo mock client:
 *   - `response` = object trả về (hoặc array of objects — nếu nhiều call, trả theo order)
 *   - `calls` = mảng recorded
 */
function makeMockClient(
  responses: unknown | unknown[],
): { client: HttpClient; calls: RecordedCall[] } {
  const calls: RecordedCall[] = [];
  const responseList: unknown[] = Array.isArray(responses) ? responses : [responses];
  let idx = 0;

  const client: HttpClient = {
    async post<T = unknown>(
      url: string,
      body: Record<string, unknown>,
      headers?: Record<string, string>,
    ): Promise<T> {
      calls.push({ url, body, headers });
      const r = responseList[Math.min(idx, responseList.length - 1)] as T;
      idx += 1;
      return r;
    },
  };

  return { client, calls };
}

const SMARTCA_ADMIN: AdminCredentials = {
  baseUrl: 'https://gwsca.vnpt.vn',
  clientId: 'sp_test',
  clientSecretPlaintext: 'secret_plaintext',
  profileId: null,
};

const MYSIGN_ADMIN: AdminCredentials = {
  baseUrl: 'https://remotesigning.viettel.vn',
  clientId: 'mysign_client',
  clientSecretPlaintext: 'mysign_secret',
  profileId: 'adss:ras:profile:001',
};

// ============================================================================
// Interface shape tests (giữ nguyên từ Task 1)
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

// ============================================================================
// SmartCA VNPT adapter tests
// ============================================================================

describe('SmartCA VNPT adapter', () => {
  it('code = SMARTCA_VNPT', () => {
    const { client } = makeMockClient({});
    const provider = createSmartCaVnptProvider(client);
    assert.equal(provider.code, 'SMARTCA_VNPT');
  });

  it('testConnection POST đúng URL /sca/sp769/v1/credentials/get_certificate', async () => {
    const { client, calls } = makeMockClient({
      status_code: 0,
      message: 'success',
      data: {
        user_certificates: [
          {
            cert_id: 'CERT-001',
            cert_subject: 'CN=Test Person',
            serial_number: '123',
            cert_valid_from: '2026-01-01',
            cert_valid_to: '2027-01-01',
            cert_data: 'MIIE...',
          },
        ],
      },
    });

    const provider = createSmartCaVnptProvider(client);
    const result = await provider.testConnection(SMARTCA_ADMIN);

    assert.equal(calls.length, 1);
    assert.equal(
      calls[0]!.url,
      'https://gwsca.vnpt.vn/sca/sp769/v1/credentials/get_certificate',
      'URL phải là /sca/sp769/v1/credentials/get_certificate',
    );
    assert.equal(result.success, true);
  });

  it('testConnection body có keys sp_id/sp_password/user_id/serial_number/transaction_id', async () => {
    const { client, calls } = makeMockClient({ status_code: 0, data: { user_certificates: [] } });
    const provider = createSmartCaVnptProvider(client);
    await provider.testConnection(SMARTCA_ADMIN);

    const body = calls[0]!.body;
    assert.equal(body.sp_id, 'sp_test', 'sp_id = clientId');
    assert.equal(body.sp_password, 'secret_plaintext', 'sp_password = plaintext secret');
    assert.equal(body.user_id, 'test_connection');
    assert.ok('serial_number' in body, 'phải có serial_number key');
    assert.ok('transaction_id' in body, 'phải có transaction_id key');
  });

  it('signHash POST đúng URL /sca/sp769/v1/signatures/sign + body có sign_files array', async () => {
    const { client, calls } = makeMockClient({
      status_code: 0,
      data: { transaction_id: 'VNPT-TXN-abc', tran_code: 'OK' },
    });
    const provider = createSmartCaVnptProvider(client);
    const result = await provider.signHash(
      SMARTCA_ADMIN,
      { userId: 'user123' },
      { hashHex: 'deadbeef', documentName: 'test.pdf', documentId: '42' },
    );

    assert.equal(result.providerTransactionId, 'VNPT-TXN-abc');
    assert.equal(calls[0]!.url, 'https://gwsca.vnpt.vn/sca/sp769/v1/signatures/sign');
    const body = calls[0]!.body as { sign_files?: Array<Record<string, string>> };
    assert.ok(Array.isArray(body.sign_files), 'sign_files phải là array');
    assert.equal(body.sign_files?.[0]?.data_to_be_signed, 'deadbeef');
    assert.equal(body.sign_files?.[0]?.doc_id, '42');
    assert.equal(body.sign_files?.[0]?.file_type, 'pdf');
    assert.equal(body.sign_files?.[0]?.sign_type, 'hash');
  });

  it('getSignStatus URL có /status suffix + POST method + empty body', async () => {
    const { client, calls } = makeMockClient({
      data: { transaction_id: 'VNPT-TXN-abc', signatures: null },
    });
    const provider = createSmartCaVnptProvider(client);
    const result = await provider.getSignStatus(SMARTCA_ADMIN, { userId: 'u' }, 'VNPT-TXN-abc');

    assert.equal(
      calls[0]!.url,
      'https://gwsca.vnpt.vn/sca/sp769/v1/signatures/sign/VNPT-TXN-abc/status',
    );
    assert.equal(result.status, 'pending', 'signatures=null → pending');
  });

  it('getSignStatus signatures[0].signature_value → completed', async () => {
    const { client } = makeMockClient({
      data: {
        transaction_id: 'VNPT-TXN-abc',
        signatures: [
          { doc_id: '42', signature_value: 'BASE64_SIG_HERE', timestamp_signature: null },
        ],
      },
    });
    const provider = createSmartCaVnptProvider(client);
    const result = await provider.getSignStatus(SMARTCA_ADMIN, { userId: 'u' }, 'VNPT-TXN-abc');

    assert.equal(result.status, 'completed');
    assert.equal(result.signatureBase64, 'BASE64_SIG_HERE');
  });

  it('listCertificates map field snake_case → camelCase', async () => {
    const { client } = makeMockClient({
      status_code: 0,
      data: {
        user_certificates: [
          {
            cert_id: 'CERT-001',
            cert_status: 'active',
            serial_number: 'SN-123',
            cert_subject: 'CN=Nguyễn Văn A',
            cert_valid_from: '2026-01-01',
            cert_valid_to: '2027-01-01',
            cert_data: 'MIIE_pem_data',
          },
        ],
      },
    });
    const provider = createSmartCaVnptProvider(client);
    const certs = await provider.listCertificates(SMARTCA_ADMIN, { userId: '0987654321' });

    assert.equal(certs.length, 1);
    assert.equal(certs[0]!.credentialId, 'CERT-001');
    assert.equal(certs[0]!.subject, 'CN=Nguyễn Văn A');
    assert.equal(certs[0]!.serialNumber, 'SN-123');
    assert.equal(certs[0]!.certificateBase64, 'MIIE_pem_data');
    assert.equal(certs[0]!.status, 'active');
  });

  it('reject http:// baseUrl (trừ localhost) — threat T-09-04', async () => {
    const { client } = makeMockClient({ status_code: 0, data: { user_certificates: [] } });
    const provider = createSmartCaVnptProvider(client);
    const result = await provider.testConnection({
      ...SMARTCA_ADMIN,
      baseUrl: 'http://evil.example.com',
    });
    assert.equal(result.success, false);
    assert.match(result.message, /HTTPS/);
  });
});

// ============================================================================
// MySign Viettel adapter tests
// ============================================================================

describe('MySign Viettel adapter', () => {
  it('code = MYSIGN_VIETTEL', () => {
    const { client } = makeMockClient({});
    const provider = createMysignViettelProvider(client);
    assert.equal(provider.code, 'MYSIGN_VIETTEL');
  });

  it('login POST đúng URL /vtss/service/ras/v1/login + body có client_id/user_id/client_secret/profile_id', async () => {
    const { client, calls } = makeMockClient({
      access_token: 'eyJ.test.token',
      token_type: 'Bearer',
      expires_in: '3600',
    });

    const provider = createMysignViettelProvider(client);
    const result = await provider.testConnection(MYSIGN_ADMIN);

    assert.equal(calls.length, 1);
    assert.equal(calls[0]!.url, 'https://remotesigning.viettel.vn/vtss/service/ras/v1/login');
    assert.equal(calls[0]!.body.client_id, 'mysign_client');
    assert.equal(calls[0]!.body.user_id, 'test_connection');
    assert.equal(calls[0]!.body.client_secret, 'mysign_secret');
    assert.equal(calls[0]!.body.profile_id, 'adss:ras:profile:001');
    assert.equal(result.success, true);
  });

  it('listCertificates đi qua login → Bearer header đúng + URL /vtss/service/certificates/info', async () => {
    const { client, calls } = makeMockClient([
      // 1. Login response
      { access_token: 'TOKEN_XYZ', token_type: 'Bearer' },
      // 2. Certificates list response
      [
        {
          credential_id: 'cred_001',
          cert: {
            status: 'active',
            certificates: ['MIIE_chain_1', 'MIIE_chain_2'],
            subjectDN: 'UID=CMND:0123,CN=KH TEST',
            issuerDN: 'CN=Viettel-CA',
            serialNumber: '111681',
            validFrom: '20221017043150+0000',
            validTo: '20230117043150+0000',
          },
        },
      ],
    ]);

    const provider = createMysignViettelProvider(client);
    const certs = await provider.listCertificates(MYSIGN_ADMIN, { userId: 'CMT_0123456789' });

    assert.equal(calls.length, 2, 'phải có 2 HTTP call: login + certificates');
    assert.equal(calls[1]!.url, 'https://remotesigning.viettel.vn/vtss/service/certificates/info');
    assert.equal(
      calls[1]!.headers?.Authorization,
      'Bearer TOKEN_XYZ',
      'Authorization header phải có Bearer token',
    );
    // Body shape
    assert.equal(calls[1]!.body.certificates, 'chain');
    assert.equal(calls[1]!.body.certInfo, true);
    assert.equal(calls[1]!.body.authInfo, true);
    // Mapping result
    assert.equal(certs.length, 1);
    assert.equal(certs[0]!.credentialId, 'cred_001');
    assert.equal(certs[0]!.subject, 'UID=CMND:0123,CN=KH TEST');
    assert.equal(certs[0]!.certificateBase64, 'MIIE_chain_1');
  });

  it('signHash body dùng key "credentialID" (chữ D hoa) + hashAlgo/signAlgo chuẩn postman', async () => {
    const { client, calls } = makeMockClient([
      { access_token: 'TOKEN', token_type: 'Bearer' },
      { transactionId: 'VT-TXN-uuid-123' },
    ]);

    const provider = createMysignViettelProvider(client);
    const result = await provider.signHash(
      MYSIGN_ADMIN,
      { userId: 'CMT_0123456789', credentialId: 'cred_001' },
      { hashHex: '3dad8d6c', documentName: 'test.pdf', documentId: '42' },
    );

    assert.equal(result.providerTransactionId, 'VT-TXN-uuid-123');
    assert.equal(calls[1]!.url, 'https://remotesigning.viettel.vn/vtss/service/signHash');

    const body = calls[1]!.body;
    assert.ok('credentialID' in body, 'PHẢI có key credentialID (chữ D hoa) — case sensitive');
    assert.equal(body.credentialID, 'cred_001');
    assert.equal(body.hashAlgo, '2.16.840.1.101.3.4.2.1', 'hashAlgo phải là SHA-256 OID');
    assert.equal(body.signAlgo, '1.2.840.113549.1.1.1', 'signAlgo phải là RSA OID');
    assert.equal(body.async, 1, 'async=1 cho async flow');
    assert.equal(body.numSignatures, 1);
    assert.deepEqual(body.hash, ['3dad8d6c']);

    // headers: Bearer token
    assert.equal(calls[1]!.headers?.Authorization, 'Bearer TOKEN');
  });

  it('signHash reject khi thiếu credentialId', async () => {
    const { client } = makeMockClient({ access_token: 'TOKEN' });
    const provider = createMysignViettelProvider(client);
    await assert.rejects(
      () =>
        provider.signHash(
          MYSIGN_ADMIN,
          { userId: 'CMT_01' }, // không có credentialId
          { hashHex: 'abc', documentName: 'test.pdf', documentId: '1' },
        ),
      /credentialId/,
    );
  });

  it('getSignStatus URL /vtss/service/requests/status + body {transactionId} + status parsing', async () => {
    const { client, calls } = makeMockClient([
      { access_token: 'TOK' },
      {
        signatures: ['v1c1a5u0...with\r\n\r\nnewlines==', 'sig2=='],
        status: '1',
      },
    ]);

    const provider = createMysignViettelProvider(client);
    const result = await provider.getSignStatus(
      MYSIGN_ADMIN,
      { userId: 'u1' },
      'VT-TXN-uuid-123',
    );

    assert.equal(calls[1]!.url, 'https://remotesigning.viettel.vn/vtss/service/requests/status');
    assert.equal(calls[1]!.body.transactionId, 'VT-TXN-uuid-123');
    assert.equal(result.status, 'completed');
    // Whitespace/CRLF bị strip
    assert.equal(result.signatureBase64, 'v1c1a5u0...withnewlines==');
  });

  it('getSignStatus status="0" → pending', async () => {
    const { client } = makeMockClient([
      { access_token: 'TOK' },
      { signatures: null, status: '0' },
    ]);
    const provider = createMysignViettelProvider(client);
    const result = await provider.getSignStatus(MYSIGN_ADMIN, { userId: 'u' }, 'TXN');
    assert.equal(result.status, 'pending');
  });
});
