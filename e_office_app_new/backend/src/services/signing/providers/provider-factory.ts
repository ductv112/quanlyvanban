/**
 * Provider factory — dispatch theo provider_code + fetch credentials từ DB.
 *
 * Thiết kế:
 *   - `getProviderByCode(code)` — PURE dispatcher (không gọi DB). Dùng khi caller
 *     đã có credentials sẵn (VD: test connection với credentials user vừa nhập
 *     trong Admin form, chưa lưu DB).
 *   - `getActiveProviderWithCredentials()` — đọc provider active từ DB, decrypt
 *     client_secret, build AdminCredentials tuple. Null nếu chưa có provider active.
 *   - `getProviderByCodeWithCredentials(code)` — đọc config của 1 provider cụ thể
 *     (có thể chưa active). Dùng khi Admin test connection của provider đã lưu
 *     nhưng chưa kích hoạt.
 *
 * SECURITY (threat T-09-03 Tampering):
 *   `getProviderByCode` dùng `switch` với `default: throw` — KHÔNG dynamic import
 *   theo string (ngăn code injection nếu DB `provider_code` bị tampered).
 */

import { signingProviderConfigRepository } from '../../../repositories/signing-provider-config.repository.js';
import { decryptSecret } from '../crypto.js';
import { smartcaVnptProvider } from './smartca-vnpt.provider.js';
import { mysignViettelProvider } from './mysign-viettel.provider.js';
import type { AdminCredentials, ProviderCode, SigningProvider } from './provider.interface.js';

// ============================================================================
// Pure dispatcher — không gọi DB
// ============================================================================

/**
 * Trả singleton adapter theo code. Throw nếu code không hỗ trợ.
 *
 * NOTE: Accept `string` (không phải `ProviderCode`) để caller có thể truyền
 *   raw value từ DB/request body mà không cần cast. Switch default sẽ throw
 *   với value không hợp lệ — an toàn với user input.
 */
export function getProviderByCode(code: string): SigningProvider {
  switch (code) {
    case 'SMARTCA_VNPT':
      return smartcaVnptProvider;
    case 'MYSIGN_VIETTEL':
      return mysignViettelProvider;
    default:
      throw new Error('Provider không hỗ trợ: ' + code);
  }
}

// ============================================================================
// DB-backed factory — fetch + decrypt
// ============================================================================

/**
 * Combined result: provider instance + decrypted AdminCredentials — ready-to-call.
 * Phase 9/11 route/worker nhận được tuple này và gọi trực tiếp:
 *   `await provider.signHash(credentials, user, req)`
 */
export interface ProviderWithCredentials {
  provider: SigningProvider;
  credentials: AdminCredentials;
}

/**
 * Lấy provider đang active trong DB + decrypt credentials.
 *
 * @returns null nếu chưa có provider active (Admin chưa cấu hình CFG-01)
 * @throws Error nếu provider_code trong DB không hỗ trợ (DB bị tampered?)
 *                hoặc decrypt thất bại (sai SIGNING_SECRET_KEY?)
 */
export async function getActiveProviderWithCredentials(): Promise<ProviderWithCredentials | null> {
  const active = await signingProviderConfigRepository.getActive();
  if (!active) return null;

  const plaintextSecret = await decryptSecret(active.client_secret);
  const provider = getProviderByCode(active.provider_code);

  const credentials: AdminCredentials = {
    baseUrl: active.base_url,
    clientId: active.client_id,
    clientSecretPlaintext: plaintextSecret,
    profileId: active.profile_id,
  };

  return { provider, credentials };
}

/**
 * Lấy provider theo code (kể cả không active) + decrypt credentials.
 * Dùng cho Admin test-connection sau khi đã lưu config nhưng chưa kích hoạt.
 *
 * @returns null nếu chưa có config cho code này
 */
export async function getProviderByCodeWithCredentials(
  code: ProviderCode,
): Promise<ProviderWithCredentials | null> {
  const row = await signingProviderConfigRepository.getByCode(code);
  if (!row) return null;

  const plaintextSecret = await decryptSecret(row.client_secret);
  const provider = getProviderByCode(code);

  const credentials: AdminCredentials = {
    baseUrl: row.base_url,
    clientId: row.client_id,
    clientSecretPlaintext: plaintextSecret,
    profileId: row.profile_id,
  };

  return { provider, credentials };
}
