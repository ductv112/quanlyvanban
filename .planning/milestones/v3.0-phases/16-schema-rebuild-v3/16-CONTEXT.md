# Phase 16: Schema rebuild v3.0 — Context

**Gathered:** 2026-04-23 (auto-mode, derived from Phase 15 DESIGN.md user-approved)
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement schema thay đổi từ DESIGN.md (Phase 15). Tạo file mới `database/schema/000_schema_v3.0.sql`, archive v2.0, update deploy scripts + seed files, reset DB clean, verify SP count + login admin.

**Out of scope:**
- Phase 17: Implement new SPs (release, send, approve, unapprove, recipients_create)
- Phase 18: Real LGSP HTTP client
- Phase 19: UI rewrite
- Phase 20: Regression UAT toàn bộ

</domain>

<decisions>
## Decisions

### Schema file approach
- **D-01:** Copy v2.0 file → modify in-place (không rebuild from scratch). 95% nội dung giữ nguyên, chỉ patch 3 bảng core + 2 bảng mới + DROP cũ.
- **D-02:** Move v2.0 sang `database/archive/v2.0-finalized/` (theo CLAUDE.md DB Migration Strategy bump version)
- **D-03:** SPs phụ thuộc cột bị DROP (is_handling, is_inter_doc, inter_doc_id) — Phase 16 update tối thiểu (chỉ remove reference) để schema apply được. Phase 17 implement lại đầy đủ.

### Migration approach
- **D-04:** Reset DB clean (user approved D-2026-04-23) — không migration data preserve
- **D-05:** Test idempotent: apply 2 lần phải zero error (theo CLAUDE.md rule)
- **D-06:** Verify SP count sau apply: ≥ 480 SPs (baseline v2.0 = 501, drop 9 inter_incoming SPs = 492 floor, có thể thêm 5-10 SPs phụ trợ)

### Seed updates
- **D-07:** `002_demo_data.sql` cập nhật schema mới — không INSERT inter_incoming_docs nữa, INSERT incoming_docs với source_type ENUM thay thế
- **D-08:** Seed `inter_organizations` (8 cơ quan demo) trong file mới hoặc append `001_required_data.sql`

### Auto-test scope sau reset DB
- **D-09:** Verify checklist:
  1. SP count ≥ 480
  2. Bảng `inter_incoming_docs` không tồn tại (\dt should fail)
  3. Bảng `outgoing_doc_recipients` + `inter_organizations` tồn tại
  4. Cột `incoming_docs.source_type` exists với ENUM type
  5. Backend start không crash (`npm run dev` smoke test)
  6. Login admin qua API `/api/auth/login` (curl test)
  7. Query SP `fn_incoming_doc_get_list(unit_id=1, ...)` không lỗi

</decisions>

<canonical_refs>
## Canonical References

- `.planning/phases/15-audit-design-data-model/15-DESIGN.md` — primary spec, user-approved
- `e_office_app_new/database/schema/000_schema_v2.0.sql` — file baseline để patch
- `CLAUDE.md` §"DB Migration Strategy (v2.0+)" — rules bump version + idempotent
- `e_office_app_new/deploy/reset-db-windows.ps1` — script reset DB
- `e_office_app_new/database/seed/001_required_data.sql` + `002_demo_data.sql` — seed files

</canonical_refs>

<deferred>
## Deferred to other phases

- New SPs implementation (release, send, approve) → Phase 17
- Real LGSP HTTP client → Phase 18
- UI rewrite + recipient picker → Phase 19
- Full regression UAT → Phase 20

</deferred>
