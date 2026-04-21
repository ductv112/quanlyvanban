import { callFunction, callFunctionOne } from '../lib/db/query.js';
import type { DbResult, DbResultWithId } from './doc-book.repository.js';

// ============================================================
// Row interfaces — match SP RETURNS TABLE columns EXACTLY (snake_case)
// Source of truth: database/migrations/040_signing_schema.sql
// ============================================================

/** public.fn_signing_provider_config_list output (KHÔNG có client_secret — che plaintext từ UI) */
export interface SigningProviderConfigListRow {
  id: number;
  provider_code: string;
  provider_name: string;
  base_url: string;
  client_id: string;
  profile_id: string | null;
  extra_config: Record<string, unknown>;
  is_active: boolean;
  last_tested_at: string | null;
  test_result: string | null;
  created_at: string;
  updated_at: string;
}

/** public.fn_signing_provider_config_get_by_code output (có client_secret BYTEA cho backend decrypt) */
export interface SigningProviderConfigFullRow {
  id: number;
  provider_code: string;
  provider_name: string;
  base_url: string;
  client_id: string;
  client_secret: Buffer;
  profile_id: string | null;
  extra_config: Record<string, unknown>;
  is_active: boolean;
  last_tested_at: string | null;
  test_result: string | null;
}

/** public.fn_signing_provider_config_get_active output (subset — sign flow runtime) */
export interface SigningProviderConfigActiveRow {
  id: number;
  provider_code: string;
  provider_name: string;
  base_url: string;
  client_id: string;
  client_secret: Buffer;
  profile_id: string | null;
  extra_config: Record<string, unknown>;
}

// ============================================================
// Repository
// ============================================================

export const signingProviderConfigRepository = {
  /**
   * List tất cả provider config (Admin UI). KHÔNG trả `client_secret` để tránh lộ
   * ciphertext qua response.
   */
  async list(): Promise<SigningProviderConfigListRow[]> {
    return callFunction<SigningProviderConfigListRow>(
      'public.fn_signing_provider_config_list',
      [],
    );
  },

  /**
   * Lấy config đầy đủ (bao gồm `client_secret` BYTEA) theo provider_code.
   * Backend sẽ decrypt bằng `services/signing/crypto.decryptSecret` trước khi
   * gọi provider API.
   */
  async getByCode(providerCode: string): Promise<SigningProviderConfigFullRow | null> {
    return callFunctionOne<SigningProviderConfigFullRow>(
      'public.fn_signing_provider_config_get_by_code',
      [providerCode],
    );
  },

  /** Lấy provider đang active (0 hoặc 1 row — partial unique index `WHERE is_active = TRUE`). */
  async getActive(): Promise<SigningProviderConfigActiveRow | null> {
    return callFunctionOne<SigningProviderConfigActiveRow>(
      'public.fn_signing_provider_config_get_active',
      [],
    );
  },

  /**
   * Upsert config. `clientSecret` PHẢI đã encrypt bằng
   * `services/signing/crypto.encryptSecret(plaintext)` trước khi gọi method này.
   */
  async upsert(params: {
    providerCode: string;
    providerName: string;
    baseUrl: string;
    clientId: string;
    clientSecret: Buffer; // ENCRYPTED (BYTEA)
    profileId: string | null;
    extraConfig: Record<string, unknown> | null;
    lastTestedAt: string | null;
    testResult: string | null;
    updatedBy: number;
  }): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>(
      'public.fn_signing_provider_config_upsert',
      [
        params.providerCode,
        params.providerName,
        params.baseUrl,
        params.clientId,
        params.clientSecret,
        params.profileId,
        params.extraConfig ?? {},
        params.lastTestedAt,
        params.testResult,
        params.updatedBy,
      ],
    );
    return row ?? { success: false, message: 'Không thể lưu cấu hình provider', id: 0 };
  },

  /**
   * Set provider active. Atomic: SP deactivate tất cả provider, rồi activate provider
   * được chọn (partial unique index trên `is_active = TRUE` đảm bảo single-active).
   */
  async setActive(providerCode: string, updatedBy: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'public.fn_signing_provider_config_set_active',
      [providerCode, updatedBy],
    );
    return row ?? { success: false, message: 'Không thể kích hoạt provider' };
  },
};
