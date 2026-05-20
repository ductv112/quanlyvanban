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
};
