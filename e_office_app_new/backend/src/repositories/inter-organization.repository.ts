// ============================================================
// inter_organizations repository - Phase 35 Plan 35-01
// REQ: LGSP-RECV-05 (auto-register sender from LGSP -- CONTEXT D-08)
//
// Table: edoc.inter_organizations (Phase 18 catalog, schema/000_schema_v3.0.sql line 26450)
//   - id BIGINT PK
//   - code VARCHAR(100) UNIQUE (uq_inter_org_code line 26484)
//   - name VARCHAR(500)
//   - lgsp_organ_id VARCHAR(100) NULL
//   - parent_id BIGINT NULL (self-FK)
//   - is_active BOOLEAN DEFAULT TRUE (auto-register sets FALSE per D-08)
//   - created_at, updated_at TIMESTAMPTZ
// ============================================================
import { rawQuery } from '../lib/db/query.js';

export interface InterOrgRow {
  id: number;
  code: string;
  name: string;
  is_active: boolean;
}

export interface AutoRegisterResult {
  id: number;
  created: boolean; // true = new row inserted; false = existing row matched
}

/**
 * Phase 37: Full row cho Admin UI list/CRUD.
 *
 * Schema map (edoc.inter_organizations — verified \d 2026-05-21):
 *   - id BIGINT, code VARCHAR(100), name VARCHAR(500)
 *   - lgsp_organ_id VARCHAR(100) NULL, parent_id BIGINT NULL (self-FK)
 *   - is_active BOOLEAN DEFAULT TRUE, address VARCHAR(500), email VARCHAR(200), phone VARCHAR(50)
 *   - created_at, updated_at TIMESTAMPTZ
 *
 * `total_count` = total rows match filter (sau khi áp dụng search + isActive). Frontend đọc
 * `rows[0].total_count` cho pagination.
 */
export interface InterOrgFullRow {
  id: number;
  code: string;
  name: string;
  lgsp_organ_id: string | null;
  parent_id: number | null;
  is_active: boolean;
  address: string | null;
  email: string | null;
  phone: string | null;
  created_at: string;
  updated_at: string;
  total_count: number;
}

export interface InterOrgCreateFields {
  code: string;
  name: string;
  lgspOrganId?: string | null;
  parentId?: number | null;
  isActive?: boolean;
  address?: string | null;
  email?: string | null;
  phone?: string | null;
}

export const interOrganizationRepository = {
  /**
   * Phase 35 Plan 35-01: Look up by `code`, INSERT if missing.
   *
   * Used by Plan 35-02 worker when an inbound LGSP edXML carries a sender (From.OrganId)
   * that the admin has not yet added to the catalog. CONTEXT D-08: do NOT reject -- auto-register
   * with `is_active=FALSE`; admin verifies later via Phase 37 UI.
   *
   * Pattern: `INSERT ... ON CONFLICT (code) DO NOTHING` then `SELECT id` by code.
   * Avoids race conditions when two cron ticks land on the same sender concurrently.
   *
   * @returns { id, created } -- `created=true` when a new row was inserted, false when existing matched.
   */
  async autoRegisterFromLgsp(code: string, name: string): Promise<AutoRegisterResult> {
    const trimmedCode = code.slice(0, 100);
    const trimmedName = (name || code).slice(0, 500);

    const inserted = await rawQuery<{ id: string }>(
      `INSERT INTO edoc.inter_organizations (code, name, lgsp_organ_id, is_active, created_at, updated_at)
       VALUES ($1, $2, $1, FALSE, NOW(), NOW())
       ON CONFLICT (code) DO NOTHING
       RETURNING id`,
      [trimmedCode, trimmedName],
    );
    if (inserted.length > 0) {
      return { id: Number(inserted[0].id), created: true };
    }
    const existing = await rawQuery<{ id: string }>(
      'SELECT id FROM edoc.inter_organizations WHERE code = $1 LIMIT 1',
      [trimmedCode],
    );
    if (existing.length === 0) {
      throw new Error(
        `inter_organizations: code=${trimmedCode} inserted nor found (impossible -- check uq_inter_org_code constraint)`,
      );
    }
    return { id: Number(existing[0].id), created: false };
  },

  /**
   * Lookup by code -- returns null if not present.
   */
  async findByCode(code: string): Promise<InterOrgRow | null> {
    const rows = await rawQuery<InterOrgRow>(
      'SELECT id, code, name, is_active FROM edoc.inter_organizations WHERE code = $1 LIMIT 1',
      [code.slice(0, 100)],
    );
    return rows[0] ? { ...rows[0], id: Number(rows[0].id) } : null;
  },

  // ============================================================
  // Phase 37 — Admin CRUD methods
  // ============================================================

  /**
   * Phase 37 (Plan 37-01): List for admin UI — search by code/name, filter by isActive,
   * pagination via window function (total_count returned inline).
   */
  async listForAdmin(filters: {
    search?: string | null;
    isActive?: boolean | null;
    page: number;
    pageSize: number;
  }): Promise<InterOrgFullRow[]> {
    const offset = (filters.page - 1) * filters.pageSize;
    const rows = await rawQuery<InterOrgFullRow>(
      `WITH filtered AS (
        SELECT *
          FROM edoc.inter_organizations
         WHERE ($1::TEXT IS NULL OR code ILIKE '%' || $1 || '%' OR name ILIKE '%' || $1 || '%')
           AND ($2::BOOLEAN IS NULL OR is_active = $2)
       )
       SELECT id,
              code,
              name,
              lgsp_organ_id,
              parent_id,
              is_active,
              address,
              email,
              phone,
              created_at,
              updated_at,
              (SELECT COUNT(*) FROM filtered)::bigint AS total_count
         FROM filtered
        ORDER BY code ASC
        LIMIT $3 OFFSET $4`,
      [filters.search ?? null, filters.isActive ?? null, filters.pageSize, offset],
    );
    return rows.map((r) => ({
      ...r,
      id: Number(r.id),
      parent_id: r.parent_id == null ? null : Number(r.parent_id),
      total_count: Number(r.total_count),
    }));
  },

  /**
   * Phase 37 (Plan 37-01): Create new inter_organization (admin form).
   * Catch SQLSTATE 23505 (unique_violation on code) → return success:false.
   */
  async createForAdmin(
    fields: InterOrgCreateFields,
  ): Promise<{ success: boolean; message: string; id: number }> {
    try {
      const rows = await rawQuery<{ id: string }>(
        `INSERT INTO edoc.inter_organizations
           (code, name, lgsp_organ_id, parent_id, is_active, address, email, phone, created_at, updated_at)
         VALUES ($1, $2, $3, $4, COALESCE($5, TRUE), $6, $7, $8, NOW(), NOW())
         RETURNING id`,
        [
          fields.code.slice(0, 100),
          fields.name.slice(0, 500),
          fields.lgspOrganId ?? null,
          fields.parentId ?? null,
          fields.isActive ?? true,
          fields.address ?? null,
          fields.email ?? null,
          fields.phone ?? null,
        ],
      );
      return { success: true, message: 'Đã thêm cơ quan ngoài', id: Number(rows[0].id) };
    } catch (err: unknown) {
      const sqlState = (err as { code?: string }).code;
      if (sqlState === '23505') return { success: false, message: 'Mã cơ quan đã tồn tại', id: 0 };
      throw err;
    }
  },

  /**
   * Phase 37 (Plan 37-01): Update inter_organization. Partial update — chỉ set field có trong fields.
   * Empty fields → return success:false ('Không có trường nào để cập nhật').
   */
  async updateForAdmin(
    id: number,
    fields: Partial<InterOrgCreateFields>,
  ): Promise<{ success: boolean; message: string }> {
    const sets: string[] = [];
    const params: unknown[] = [];
    let i = 1;
    if (fields.code !== undefined) {
      sets.push(`code = $${i++}`);
      params.push(fields.code.slice(0, 100));
    }
    if (fields.name !== undefined) {
      sets.push(`name = $${i++}`);
      params.push(fields.name.slice(0, 500));
    }
    if (fields.lgspOrganId !== undefined) {
      sets.push(`lgsp_organ_id = $${i++}`);
      params.push(fields.lgspOrganId);
    }
    if (fields.parentId !== undefined) {
      sets.push(`parent_id = $${i++}`);
      params.push(fields.parentId);
    }
    if (fields.isActive !== undefined) {
      sets.push(`is_active = $${i++}`);
      params.push(fields.isActive);
    }
    if (fields.address !== undefined) {
      sets.push(`address = $${i++}`);
      params.push(fields.address);
    }
    if (fields.email !== undefined) {
      sets.push(`email = $${i++}`);
      params.push(fields.email);
    }
    if (fields.phone !== undefined) {
      sets.push(`phone = $${i++}`);
      params.push(fields.phone);
    }
    if (sets.length === 0) {
      return { success: false, message: 'Không có trường nào để cập nhật' };
    }
    sets.push(`updated_at = NOW()`);
    params.push(id);
    try {
      const rows = await rawQuery<{ id: string }>(
        `UPDATE edoc.inter_organizations SET ${sets.join(', ')} WHERE id = $${i} RETURNING id`,
        params,
      );
      if (rows.length === 0) {
        return { success: false, message: 'Không tìm thấy cơ quan ngoài' };
      }
      return { success: true, message: 'Đã cập nhật cơ quan ngoài' };
    } catch (err: unknown) {
      const sqlState = (err as { code?: string }).code;
      if (sqlState === '23505') return { success: false, message: 'Mã cơ quan đã tồn tại' };
      throw err;
    }
  },

  /**
   * Phase 37 (Plan 37-01): Delete inter_organization.
   * Catch SQLSTATE 23503 (FK violation — outgoing_doc_recipients reference) → message rõ ràng.
   */
  async deleteForAdmin(
    id: number,
  ): Promise<{ success: boolean; message: string }> {
    try {
      const rows = await rawQuery<{ id: string }>(
        'DELETE FROM edoc.inter_organizations WHERE id = $1 RETURNING id',
        [id],
      );
      if (rows.length === 0) {
        return { success: false, message: 'Không tìm thấy cơ quan ngoài' };
      }
      return { success: true, message: 'Đã xóa cơ quan ngoài' };
    } catch (err: unknown) {
      const sqlState = (err as { code?: string }).code;
      if (sqlState === '23503') {
        return {
          success: false,
          message: 'Không thể xóa: cơ quan đang được tham chiếu (văn bản đến/đi)',
        };
      }
      throw err;
    }
  },
};
