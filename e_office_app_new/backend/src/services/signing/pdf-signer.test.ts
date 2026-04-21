/**
 * Unit tests cho pdf-signer.ts
 *
 * Run:
 *   cd e_office_app_new/backend
 *   npx tsx --test src/services/signing/pdf-signer.test.ts
 */

import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { PDFDocument } from 'pdf-lib';
import forge from 'node-forge';

import {
  addSignaturePlaceholder,
  computePdfHash,
  prepareSignPdf,
  signPdf,
} from './pdf-signer.js';

/**
 * Helper: tạo PDF tối giản 1 trang chứa text "Test PDF".
 *
 * IMPORTANT: `useObjectStreams: false` bắt buộc — `@signpdf/placeholder-plain`
 * chỉ parse được classic xref table (không hỗ trợ cross-reference streams).
 * Nếu để default (useObjectStreams=true), plainAddPlaceholder sẽ fail với
 * "Expected xref at NaN but found other content."
 */
async function createSamplePdf(): Promise<Buffer> {
  const doc = await PDFDocument.create();
  const page = doc.addPage([400, 400]);
  page.drawText('Test PDF for signing', { x: 50, y: 350, size: 20 });
  const bytes = await doc.save({ useObjectStreams: false });
  return Buffer.from(bytes);
}

/**
 * Helper: tạo PKCS7 detached signature mock bằng self-signed cert.
 * Dùng node-forge để generate hợp lệ (dù không trust chain).
 */
function createMockPkcs7Signature(dataToSign: Buffer): string {
  // Generate self-signed RSA cert
  const keys = forge.pki.rsa.generateKeyPair(2048);
  const cert = forge.pki.createCertificate();
  cert.publicKey = keys.publicKey;
  cert.serialNumber = '01';
  cert.validity.notBefore = new Date();
  cert.validity.notAfter = new Date(Date.now() + 365 * 24 * 60 * 60 * 1000);
  const attrs = [{ name: 'commonName', value: 'Test Signer' }];
  cert.setSubject(attrs);
  cert.setIssuer(attrs);
  cert.sign(keys.privateKey, forge.md.sha256.create());

  // Build PKCS7 detached
  const p7 = forge.pkcs7.createSignedData();
  p7.content = forge.util.createBuffer(dataToSign.toString('binary'));
  p7.addCertificate(cert);
  p7.addSigner({
    key: keys.privateKey,
    certificate: cert,
    digestAlgorithm: forge.pki.oids.sha256,
    // node-forge accepts Date for signingTime at runtime, but @types/node-forge
    // types declare `value?: string`. Cast to any to bypass the type mismatch.
    authenticatedAttributes: [
      { type: forge.pki.oids.contentType, value: forge.pki.oids.data },
      { type: forge.pki.oids.messageDigest },
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      { type: forge.pki.oids.signingTime, value: new Date() as any },
    ],
  });
  p7.sign({ detached: true });

  const der = forge.asn1.toDer(p7.toAsn1()).getBytes();
  return forge.util.encode64(der);
}

describe('addSignaturePlaceholder', () => {
  it('thêm placeholder /ByteRange vào PDF', async () => {
    const pdf = await createSamplePdf();
    const result = addSignaturePlaceholder(pdf, { reason: 'Test' });
    assert.ok(Buffer.isBuffer(result), 'result phải là Buffer');
    const content = result.toString('binary');
    assert.match(content, /\/ByteRange\s*\[/, 'phải có /ByteRange marker');
    assert.match(content, /\/Contents\s*</, 'phải có /Contents marker');
    assert.ok(result.length > pdf.length, 'PDF sau khi thêm placeholder phải lớn hơn');
  });

  it('throw khi input không phải PDF', () => {
    assert.throws(
      () => addSignaturePlaceholder(Buffer.from('not a pdf')),
      /không phải PDF hợp lệ/,
    );
  });

  it('throw khi Buffer rỗng', () => {
    assert.throws(
      () => addSignaturePlaceholder(Buffer.alloc(0)),
      /không hợp lệ/,
    );
  });
});

describe('computePdfHash', () => {
  it('trả hash SHA256 hex 64 ký tự + byteRange 4 phần tử', async () => {
    const pdf = await createSamplePdf();
    const placeholderPdf = addSignaturePlaceholder(pdf);
    const result = computePdfHash(placeholderPdf);
    assert.equal(result.hash.length, 64, 'SHA256 hex phải 64 ký tự');
    assert.match(result.hash, /^[0-9a-f]{64}$/, 'phải là lowercase hex');
    assert.equal(result.byteRange.length, 4, 'byteRange phải có 4 số');
    assert.ok(
      result.byteRange.every((n) => Number.isInteger(n) && n >= 0),
      'mỗi số phải là non-negative integer',
    );
  });

  it('throw khi PDF chưa có placeholder', async () => {
    const pdf = await createSamplePdf();
    assert.throws(() => computePdfHash(pdf), /không có signature placeholder/);
  });
});

describe('prepareSignPdf', () => {
  it('combine addPlaceholder + computeHash', async () => {
    const pdf = await createSamplePdf();
    const result = prepareSignPdf(pdf, { reason: 'Test' });
    assert.ok(result.hash);
    assert.ok(Buffer.isBuffer(result.placeholderPdf));
    assert.equal(result.byteRange.length, 4);
  });
});

describe('signPdf', () => {
  it('embed mock PKCS7 signature thành công', async () => {
    const pdf = await createSamplePdf();
    const prep = prepareSignPdf(pdf, { reason: 'Test' });

    // Dùng byte range bytes làm "data to sign" (PKCS7 content = byte range data)
    const [s1, l1, s2, l2] = prep.byteRange;
    const dataToSign = Buffer.concat([
      prep.placeholderPdf.subarray(s1, s1 + l1),
      prep.placeholderPdf.subarray(s2, s2 + l2),
    ]);
    const mockSig = createMockPkcs7Signature(dataToSign);

    const result = await signPdf(prep.placeholderPdf, mockSig);
    assert.ok(Buffer.isBuffer(result.signedPdf), 'signedPdf phải là Buffer');
    assert.equal(
      result.signedPdf.length,
      prep.placeholderPdf.length,
      'signed PDF phải cùng size với placeholder PDF (signature fill vào vùng sẵn có)',
    );
    assert.equal(result.finalHash.length, 64, 'finalHash phải là SHA256 hex (64 chars)');

    // Verify signature đã fill (không còn toàn 0x00 trong /Contents)
    const signedContent = result.signedPdf.toString('binary');
    const contentMatch = signedContent.match(/\/Contents\s*<([0-9a-fA-F]+)>/);
    assert.ok(contentMatch, 'phải có /Contents <hex>');
    const hexContent = contentMatch![1];
    assert.ok(
      !/^0+$/.test(hexContent),
      '/Contents không được toàn 0 (signature chưa fill)',
    );
  });

  it('throw khi signatureBase64 rỗng', async () => {
    const pdf = await createSamplePdf();
    const placeholder = addSignaturePlaceholder(pdf);
    await assert.rejects(() => signPdf(placeholder, ''), /không hợp lệ/);
  });

  it('throw khi signature không phải base64', async () => {
    const pdf = await createSamplePdf();
    const placeholder = addSignaturePlaceholder(pdf);
    await assert.rejects(
      () => signPdf(placeholder, '!!!not_base64@@@'),
      /base64 hợp lệ/,
    );
  });

  it('throw khi PDF chưa có placeholder', async () => {
    const pdf = await createSamplePdf();
    const validBase64 = Buffer.from('fake').toString('base64');
    await assert.rejects(() => signPdf(pdf, validBase64), /signature placeholder/);
  });
});
