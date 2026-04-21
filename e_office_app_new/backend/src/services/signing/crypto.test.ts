/**
 * Integration test cho crypto.ts — yêu cầu qlvb_postgres đang chạy với pgcrypto extension.
 * Run: SIGNING_SECRET_KEY=test_key_min_16_chars_random_xyz_aaa npx tsx --test src/services/signing/crypto.test.ts
 */

import { describe, it, after } from 'node:test';
import assert from 'node:assert/strict';

// Set test env TRƯỚC khi import module (getSecretKey đọc env tại call time nhưng
// an toàn hơn nếu set ngay từ đầu để không phụ thuộc thứ tự import)
process.env.SIGNING_SECRET_KEY =
  process.env.SIGNING_SECRET_KEY || 'test_key_min_16_chars_random_xyz_aaa';

// Load .env cho pool connection (pool.ts đọc PG_* từ process.env)
// Nếu .env không tồn tại thì pool sẽ dùng default localhost (OK cho test)
try {
  const dotenv = await import('dotenv');
  dotenv.config();
} catch {
  // dotenv không có cũng không sao — fallback dùng default
}

const { encryptSecret, decryptSecret, maskSecret } = await import('./crypto.js');
const { pool } = await import('../../lib/db/pool.js');

after(async () => {
  // Đóng pool để test process exit sạch
  await pool.end();
});

describe('encryptSecret + decryptSecret roundtrip', () => {
  it('encrypt rồi decrypt ra plaintext gốc', async () => {
    const plain = 'my_super_secret_client_secret_2026';
    const cipher = await encryptSecret(plain);
    assert.ok(Buffer.isBuffer(cipher), 'encrypt phải trả Buffer');
    assert.ok(cipher.length > 16, 'cipher phải > 16 bytes');

    const decrypted = await decryptSecret(cipher);
    assert.equal(decrypted, plain, 'roundtrip phải ra plaintext gốc');
  });

  it('encrypt cùng plaintext 2 lần trả cipher khác nhau (random IV)', async () => {
    const plain = 'hello_world';
    const cipher1 = await encryptSecret(plain);
    const cipher2 = await encryptSecret(plain);
    assert.notDeepEqual(cipher1, cipher2, 'pgp_sym_encrypt phải random IV');
    // Nhưng decrypt cả 2 ra giống nhau
    const plain1 = await decryptSecret(cipher1);
    const plain2 = await decryptSecret(cipher2);
    assert.equal(plain1, plain);
    assert.equal(plain2, plain);
  });

  it('encrypt plaintext rỗng throw Error', async () => {
    await assert.rejects(() => encryptSecret(''), /Plaintext rỗng/);
  });

  it('decrypt Buffer rỗng throw Error', async () => {
    await assert.rejects(() => decryptSecret(Buffer.alloc(0)), /không hợp lệ/);
  });

  it('decrypt cipher corrupt throw Error', async () => {
    await assert.rejects(
      () => decryptSecret(Buffer.from('garbage_not_real_cipher_data_here')),
      /Không thể decrypt/,
    );
  });

  it('encrypt plaintext tiếng Việt có dấu — roundtrip giữ nguyên', async () => {
    const plain = 'Chữ ký số bí mật — năm 2026';
    const cipher = await encryptSecret(plain);
    const decrypted = await decryptSecret(cipher);
    assert.equal(decrypted, plain);
  });
});

describe('maskSecret', () => {
  it('mask empty string', () => {
    assert.equal(maskSecret(''), '');
  });
  it('mask short string (<=4)', () => {
    assert.equal(maskSecret('abc'), '***');
    assert.equal(maskSecret('abcd'), '***');
  });
  it('mask medium string (<=8)', () => {
    assert.equal(maskSecret('abcdef'), 'ab***');
  });
  it('mask long string', () => {
    assert.equal(maskSecret('secret_2026'), 'se***26');
  });
});
