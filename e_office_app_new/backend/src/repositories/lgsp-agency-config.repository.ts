import { callFunction, callFunctionOne } from '../lib/db/query.js';
import type { DbResult, DbResultWithId } from './doc-book.repository.js';

// ============================================================
// Row interfaces — match SP RETURNS TABLE columns EXACTLY (snake_case)
// Source of truth: e_office_app_new/database/schema/000_schema_v3.0.sql Phase 33 section
// ============================================================

/**
 * `edoc.fn_lgsp_agency_config_list` output (admin UI list — KHÔNG có secret_key_encrypted).
 *
 * JOIN với departments để hiển thị unit_name + lgsp_org_code (để admin biết DN nào).
 */
export interface LgspAgencyConfigListRow {
  id: number;
  unit_id: number;
  unit_name: string;
  lgsp_org_code: string | null;
  environment: 'sandbox' | 'prod';
  system_id: string;
  base_url: string;
  is_active: boolean;
  last_synced_at: string | null;
  last_sync_error: string | null;
  created_at: string;
  updated_at: string;
}

/**
 * `edoc.fn_lgsp_agency_config_get_by_id` / `_get_by_unit_id` output (FULL — có secret_key_encrypted BYTEA).
 *
 * Backend service decrypt bằng `services/signing/crypto.decryptSecret(secret_key_encrypted)` khi cần.
 * KHÔNG trả qua HTTP response — chỉ dùng nội bộ trong factory.
 */
export interface LgspAgencyConfigFullRow {
  id: number;
  unit_id: number;
  environment: 'sandbox' | 'prod';
  system_id: string;
  secret_key_encrypted: Buffer;
  base_url: string;
  is_active: boolean;
  last_synced_at: string | null;
  last_sync_error: string | null;
}

/**
 * `edoc.fn_lgsp_agency_config_get_all_active` output (subset — Phase 35 cron loop).
 */
export interface LgspAgencyConfigActiveRow {
  id: number;
  unit_id: number;
  environment: 'sandbox' | 'prod';
  system_id: string;
  secret_key_encrypted: Buffer;
  base_url: string;
  last_synced_at: string | null;
}

// ============================================================
// Repository — export const object (KHÔNG class)
// ============================================================

export const lgspAgencyConfigRepository = {
  /**
   * List tất cả config (Admin UI). KHÔNG trả `secret_key_encrypted` để tránh leak BYTEA qua response.
   */
  async list(): Promise<LgspAgencyConfigListRow[]> {
    return callFunction<LgspAgencyConfigListRow>(
      'edoc.fn_lgsp_agency_config_list',
      [],
    );
  },

  /**
   * Lấy config FULL (bao gồm `secret_key_encrypted` BYTEA) theo id.
   * Dùng cho admin edit form (display masked + cho phép giữ secret cũ nếu user không nhập mới).
   */
  async getById(id: number): Promise<LgspAgencyConfigFullRow | null> {
    return callFunctionOne<LgspAgencyConfigFullRow>(
      'edoc.fn_lgsp_agency_config_get_by_id',
      [id],
    );
  },

  /**
   * Lấy config FULL theo unit_id + environment. Cho service factory `getLgspService(unit_id)` lookup.
   *
   * @param unitId Root unit id (PHẢI là root — trigger enforce)
   * @param environment Default 'prod'. Phase 33-04 service factory chọn env theo NODE_ENV hoặc query param.
   */
  async getByUnitId(
    unitId: number,
    environment: 'sandbox' | 'prod' = 'prod',
  ): Promise<LgspAgencyConfigFullRow | null> {
    return callFunctionOne<LgspAgencyConfigFullRow>(
      'edoc.fn_lgsp_agency_config_get_by_unit_id',
      [unitId, environment],
    );
  },

  /**
   * Lấy tất cả config đang active. Cho Phase 35 cron loop.
   *
   * @param environment Optional filter — null = lấy cả prod + sandbox active
   */
  async getAllActive(environment?: 'sandbox' | 'prod'): Promise<LgspAgencyConfigActiveRow[]> {
    return callFunction<LgspAgencyConfigActiveRow>(
      'edoc.fn_lgsp_agency_config_get_all_active',
      [environment ?? null],
    );
  },

  /**
   * Upsert config. `secretKeyEncrypted` PHẢI đã encrypt bằng
   * `services/signing/crypto.encryptSecret(plaintext)` TRƯỚC khi gọi method này.
   */
  async upsert(params: {
    unitId: number;
    environment: 'sandbox' | 'prod';
    systemId: string;
    secretKeyEncrypted: Buffer; // ENCRYPTED (BYTEA)
    baseUrl: string;
    updatedBy: number;
  }): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>(
      'edoc.fn_lgsp_agency_config_upsert',
      [
        params.unitId,
        params.environment,
        params.systemId,
        params.secretKeyEncrypted,
        params.baseUrl,
        params.updatedBy,
      ],
    );
    return row ?? { success: false, message: 'Không thể lưu cấu hình LGSP', id: 0 };
  },

  /**
   * Set active toggle. Phase 37 admin UI dùng — bật/tắt LGSP per row.
   * KHÔNG atomic single-active như signing (mỗi DN có thể có 2 row active: prod + sandbox độc lập).
   */
  async setActive(id: number, isActive: boolean, updatedBy: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_lgsp_agency_config_set_active',
      [id, isActive, updatedBy],
    );
    return row ?? { success: false, message: 'Không thể cập nhật trạng thái LGSP' };
  },

  /**
   * Update last_synced_at + last_sync_error. Phase 35 cron callback sau mỗi vòng.
   *
   * @param error Optional error message — null nếu vòng cron success
   */
  async updateLastSynced(
    unitId: number,
    environment: 'sandbox' | 'prod',
    lastSyncedAt: string,
    error?: string | null,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_lgsp_agency_config_update_last_synced',
      [unitId, environment, lastSyncedAt, error ?? null],
    );
    return row ?? { success: false, message: 'Không thể cập nhật last_synced' };
  },

  /**
   * Phase 37: GetByIdWithDecryptedSecret — admin "Test connection" cần plaintext secret.
   * Decrypt qua services/signing/crypto.decryptSecret. KHÔNG expose qua HTTP response —
   * chỉ dùng nội bộ trong route handler (admin test connection / re-instantiate LGSP service).
   *
   * @returns null nếu không tìm thấy. Throws nếu decrypt fail (SIGNING_SECRET_KEY sai/missing).
   */
  async getByIdWithDecryptedSecret(id: number): Promise<{
    id: number;
    unit_id: number;
    environment: 'sandbox' | 'prod';
    system_id: string;
    base_url: string;
    is_active: boolean;
    secret_key_plaintext: string;
  } | null> {
    const row = await callFunctionOne<LgspAgencyConfigFullRow>(
      'edoc.fn_lgsp_agency_config_get_by_id',
      [id],
    );
    if (!row) return null;
    // Lazy import tránh circular dep với services/lgsp.service
    const { decryptSecret } = await import('../services/signing/crypto.js');
    const plaintext = await decryptSecret(row.secret_key_encrypted);
    return {
      id: Number(row.id),
      unit_id: Number(row.unit_id),
      environment: row.environment,
      system_id: row.system_id,
      base_url: row.base_url,
      is_active: row.is_active,
      secret_key_plaintext: plaintext,
    };
  },
};
