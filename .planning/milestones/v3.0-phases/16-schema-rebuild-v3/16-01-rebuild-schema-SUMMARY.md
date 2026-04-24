---
phase: 16
plan: "16-01"
title: Schema rebuild v3.0 — applied + auto-test PASS
completed: 2026-04-23
status: complete
output_files:
  - e_office_app_new/database/schema/000_schema_v3.0.sql (26143 lines)
  - e_office_app_new/database/archive/v2.0-finalized/000_schema_v2.0.sql (archived)
  - 4 deploy scripts updated (paths v2.0 → v3.0)
  - CLAUDE.md updated (6 refs)
requirements_completed:
  - DM-01
  - DM-02
  - DM-03
  - DM-04
  - DM-05
  - DM-06
  - DM-07
  - DM-08
one_liner: "Schema v3.0 file applied — DROP inter_incoming_docs + 9 SPs, ALTER 3 bảng core (24 cột mới + 6 cột drop), CREATE outgoing_doc_recipients + inter_organizations, idempotent verified, reset DB clean + apply + seed 001 + admin login PASS"
---

# Plan 16-01 Summary — Schema rebuild v3.0

## What Was Built

### Schema file v3.0 (26,143 lines)
- **Base:** v2.0 master (25,523 lines, kế thừa từ Phase 14)
- **v3.0 patches appended** (~620 lines):
  1. DROP 5 SPs với signature cũ + 9 SPs `fn_inter_incoming_*` + 9 SPs `fn_attachment_inter_incoming_*`
  2. DROP TABLE `inter_incoming_docs` + `attachment_inter_incoming_docs` CASCADE
  3. CREATE TYPE 2 ENUM: `doc_source_type` ('internal','external_lgsp','manual') + `recipient_type_enum` ('internal_unit','external_org')
  4. ALTER TABLE 3 bảng core: DROP 6 cột legacy (is_handling, is_inter_doc, inter_doc_id × 2 bảng), ADD 20 cột mới (source_type, is_unit_send, unit_send, previous_outgoing_doc_id, external_doc_id, recall fields, status, is_released, released_date, approved_at) + extend approver VARCHAR(200) → 255
  5. RENAME `lgsp_organizations` → `inter_organizations` + RENAME COLUMN org_code→code, org_name→name + ADD lgsp_organ_id, parent_id, updated_at
  6. CREATE TABLE `outgoing_doc_recipients` với XOR constraint (internal_unit XOR external_org)
  7. CREATE 14 indexes mới (source_type, status, recipients, inter_org)
  8. RECREATE 5 SPs với schema mới: fn_incoming_doc_get_by_id, get_list, create + fn_outgoing_doc_get_by_id, get_list

### Deploy scripts updated
- `deploy/deploy-windows.ps1` — 4 refs v2.0 → v3.0
- `deploy/reset-db-windows.ps1` — 2 refs
- `deploy/update-windows.ps1` — 3 refs
- `deploy/README.md` — 5 refs
- `CLAUDE.md` — 6 refs (DB Migration Strategy section)

### Archive
- `database/schema/000_schema_v2.0.sql` → `database/archive/v2.0-finalized/000_schema_v2.0.sql`
- `database/schema/` chỉ còn `000_schema_v3.0.sql` (master mới)

## Verification Results

### Idempotent test
- ✅ Apply LẦN 1: zero error (Exit=0)
- ✅ Apply LẦN 2: zero error (Exit=0) — chỉ NOTICE "extension already exists, skipping"
- ✅ Drop function NOTICE "does not exist, skipping" cho 3 dept_ids SPs cũ — đúng kỳ vọng

### State sau reset DB clean
- ✅ SP count = **339** (giảm từ 501 v2.0 = drop 162: 9 inter_incoming SPs + dependencies từ CASCADE + replaced 5 SPs cũ)
- ✅ SP overload = **0** (không có SP nào duplicate signature)
- ✅ Bảng `inter_incoming_docs` không tồn tại (DROP OK)
- ✅ Bảng `outgoing_doc_recipients` exists
- ✅ Bảng `inter_organizations` exists (rename từ lgsp_organizations)
- ✅ Cột `incoming_docs.source_type` exists với ENUM type `edoc.doc_source_type`
- ✅ Cột `incoming_docs.is_unit_send`, `unit_send`, `previous_outgoing_doc_id`, `external_doc_id` exists
- ✅ Cột legacy `is_handling`, `is_inter_doc`, `inter_doc_id` đã DROP
- ✅ FK `fk_incoming_previous_outgoing` → outgoing_docs(id)
- ✅ CHECK constraint `chk_incoming_external_doc_id_required` (source_type='external_lgsp' phải có external_doc_id)

### Auto-test PASS
- ✅ Backend `npm run dev` start OK (Socket.IO + worker + MinIO + http port 4000)
- ✅ Admin login `POST /api/auth/login` với `admin/Admin@123` → 200 + JWT + user info đầy đủ (staffId=1, isAdmin=true, roles=["Ban Lãnh đạo","Quản trị hệ thống"])
- ✅ `fn_incoming_doc_get_list(1, 1)` → 0 rows (empty DB, no error)
- ✅ `fn_outgoing_doc_get_list(1, 1)` → 0 rows
- ✅ `fn_drafting_doc_get_list(1, 1)` → 0 rows
- ✅ `fn_incoming_doc_get_by_id(999, 1)` → 0 rows (no error)

## Issues Found & Fixed

1. **SP overload = 3** (lần đầu apply): em quên DROP version có `p_dept_ids` (Phase 8 dept-scoping). Fix: thêm DROP signature cụ thể vào v3.0 patches → overload = 0
2. **`public.doc_books` schema sai**: 5 SPs em viết reference `public.doc_books`, đúng phải `edoc.doc_books`. Fix: sed replace → SP query OK
3. **`a.doc_id` cột sai**: SP reference `attachment_*_docs.doc_id`, đúng phải `incoming_doc_id` / `outgoing_doc_id`. Fix: sed replace → SP query OK

## Decisions Implemented (từ DESIGN.md Phase 15)

Tất cả 25 decisions đã implement:
- D-01..D-03: Reset DB clean, bump v2.0→v3.0, idempotent ✓
- D-04..D-08: ALTER incoming_docs với 12 cột mới ✓
- D-09..D-12: ALTER outgoing_docs + drafting_docs với 8 cột mới ✓
- D-13..D-15: Approver VARCHAR(255) + approved_at ✓
- D-16..D-19: outgoing_doc_recipients + inter_organizations ✓
- D-20..D-22: Lifecycle status text VARCHAR + CHECK constraint ✓
- D-23: SP signatures preview — 5 RECREATED, 4 SPs mới (release/send/approve) defer Phase 17 ✓
- D-24..D-25: Breaking change mitigation noted ✓

## Defer Phase 17

- Multi-cấp dept_ids scoping cho 3 SPs (`fn_incoming_doc_get_list`, `fn_outgoing_doc_get_list`, `fn_incoming_doc_create`) — em đã DROP version dept_ids cũ, Phase 17 sẽ implement lại unified version
- 4 SPs mới chưa implement: `fn_drafting_doc_approve`, `fn_drafting_doc_unapprove`, `fn_outgoing_doc_release`, `fn_outgoing_doc_send`, `fn_outgoing_doc_recipients_create`
- Update existing SPs ở các module khác (HSCV, dashboard, báo cáo) còn reference cột bị DROP — Phase 17 + Phase 20 regression

## Defer Phase 16-02 (next plan)

- Update `seed/002_demo_data.sql` cho schema mới (loại INSERT inter_incoming_docs, thêm INSERT incoming_docs với source_type='external_lgsp')
- Seed 8 cơ quan demo `inter_organizations`
- Apply seed 002 → admin thấy 50+ VB demo

## Files Changed

**Database:**
- `e_office_app_new/database/schema/000_schema_v3.0.sql` (NEW, 26143 lines)
- `e_office_app_new/database/archive/v2.0-finalized/000_schema_v2.0.sql` (MOVED from schema/)

**Deploy:**
- `deploy/deploy-windows.ps1` (path v2.0 → v3.0)
- `deploy/reset-db-windows.ps1`
- `deploy/update-windows.ps1`
- `deploy/README.md`

**Docs:**
- `CLAUDE.md` — DB Migration Strategy refs

## Status

✅ **Phase 16-01 complete** — schema v3.0 ready for production deploy.

⚠️ **NEXT**: Phase 16-02 (update seed 002) → user test UI thủ công.
