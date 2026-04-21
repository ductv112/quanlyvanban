/**
 * Crypto helper cho signing credentials.
 *
 * Wrap PostgreSQL pgcrypto `pgp_sym_encrypt` / `pgp_sym_decrypt` qua rawQuery.
 * Dùng để encrypt `signing_provider_config.client_secret` (BYTEA) trước khi
 * lưu DB — plaintext không bao giờ tồn tại trong DB.
 *
 * Key management:
 * - Lấy từ env `SIGNING_SECRET_KEY` — deploy setup PHẢI set key ngẫu nhiên (>= 32 ký tự khuyến nghị)
 * - Rotate key: chạy SQL
 *     UPDATE signing_provider_config
 *        SET client_secret = pgp_sym_encrypt(pgp_sym_decrypt(client_secret, OLD_KEY), NEW_KEY)
 * - Backup DB cũng backup luôn ciphertext — khôi phục DB chỉ giải mã được nếu có key
 *
 * Usage:
 *   import { encryptSecret, decryptSecret } from './crypto.js';
 *   const cipher = await encryptSecret('my_client_secret');   // Buffer
 *   const plain  = await decryptSecret(cipher);               // 'my_client_secret'
 *
 * Vì sao dùng pgp_sym_encrypt qua SQL (không AES-256-GCM Node-side)?
 * - pgcrypto đã có sẵn (migration 000), không cần thêm Node dependency
 * - Key rotation đơn giản, atomic bằng 1 câu UPDATE
 * - Backup/restore DB consistent — ciphertext và metadata cùng 1 nơi
 */

import { rawQuery } from '../../lib/db/query.js';

// ============================================================================
// Interface nội bộ cho row trả về từ rawQuery
// ============================================================================

interface EncryptRow {
  cipher: Buffer;
}

interface DecryptRow {
  plaintext: string;
}

// ============================================================================
// Helper: đọc + validate SIGNING_SECRET_KEY từ env (fail-fast, không default)
// ============================================================================

/**
 * Lấy secret key từ env. Throw nếu chưa set hoặc quá ngắn (fail-fast — không default value
 * để tránh vô tình encrypt bằng key yếu trong production).
 */
function getSecretKey(): string {
  const key = process.env.SIGNING_SECRET_KEY;
  if (!key || key.trim() === '') {
    throw new Error(
      'Env SIGNING_SECRET_KEY chưa được set — cấu hình trong .env trước khi start backend',
    );
  }
  if (key.length < 16) {
    throw new Error('SIGNING_SECRET_KEY quá ngắn (tối thiểu 16 ký tự, khuyến nghị 32+)');
  }
  return key;
}

// ============================================================================
// Public API
// ============================================================================

/**
 * Encrypt plaintext string → BYTEA Buffer dùng `pgp_sym_encrypt` (pgcrypto).
 *
 * pgp_sym_encrypt tự động random IV → 2 lần encrypt cùng plaintext trả ciphertext khác nhau.
 *
 * @param plaintext Chuỗi cần encrypt (không được rỗng)
 * @returns Buffer chứa ciphertext (lưu trực tiếp vào cột BYTEA)
 * @throws Error nếu plaintext rỗng hoặc env `SIGNING_SECRET_KEY` chưa set
 */
export async function encryptSecret(plaintext: string): Promise<Buffer> {
  if (typeof plaintext !== 'string' || plaintext === '') {
    throw new Error('Plaintext rỗng — không thể encrypt');
  }

  const key = getSecretKey();

  const rows = await rawQuery<EncryptRow>(
    'SELECT pgp_sym_encrypt($1::TEXT, $2::TEXT) AS cipher',
    [plaintext, key],
  );

  if (!rows[0] || !Buffer.isBuffer(rows[0].cipher)) {
    throw new Error('Encrypt thất bại — pgp_sym_encrypt không trả Buffer');
  }

  return rows[0].cipher;
}

/**
 * Decrypt BYTEA cipher → plaintext string dùng `pgp_sym_decrypt` (pgcrypto).
 *
 * @param cipher Buffer BYTEA (lấy từ DB hoặc từ encryptSecret)
 * @returns Plaintext string
 * @throws Error nếu cipher rỗng, không phải Buffer, hoặc key sai (pg sẽ raise)
 */
export async function decryptSecret(cipher: Buffer): Promise<string> {
  if (!Buffer.isBuffer(cipher) || cipher.length === 0) {
    throw new Error('Cipher Buffer không hợp lệ (rỗng hoặc không phải Buffer)');
  }

  const key = getSecretKey();

  try {
    const rows = await rawQuery<DecryptRow>(
      'SELECT pgp_sym_decrypt($1::BYTEA, $2::TEXT) AS plaintext',
      [cipher, key],
    );

    if (!rows[0] || typeof rows[0].plaintext !== 'string') {
      throw new Error('Decrypt thất bại — pgp_sym_decrypt không trả plaintext');
    }

    return rows[0].plaintext;
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    // pgp_sym_decrypt raise nếu cipher corrupt hoặc key sai (PG error 39000 / custom)
    throw new Error(`Không thể decrypt: ${msg}`);
  }
}

/**
 * Mask plaintext để hiển thị UI — không ảnh hưởng encrypt/decrypt, chỉ tiện dùng
 * trong layer route khi trả về client (VD: hiển thị "ab***yz" cho client_id đã set).
 *
 * Quy tắc:
 * - Rỗng → ''
 * - <= 4 ký tự → '***'
 * - 5..8 ký tự → '{2 ký tự đầu}***'
 * - > 8 ký tự → '{2 ký tự đầu}***{2 ký tự cuối}'
 *
 * @param plaintext Chuỗi cần mask
 * @returns Chuỗi đã mask
 */
export function maskSecret(plaintext: string): string {
  if (!plaintext || plaintext.length === 0) return '';
  if (plaintext.length <= 4) return '***';
  if (plaintext.length <= 8) return plaintext.slice(0, 2) + '***';
  return plaintext.slice(0, 2) + '***' + plaintext.slice(-2);
}
