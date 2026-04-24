---
phase: 16
plan: "16-01"
title: Rebuild Master Schema v3.0 + Reset DB + Auto Test
created: 2026-04-23
status: ready
requirements:
  - DM-01..DM-08
depends_on:
  - phase 15 (DESIGN.md approved)
estimated_duration: 60-90 minutes
---

# Plan 16-01: Rebuild Schema v3.0 + Reset DB

## Goal

Implement schema theo `15-DESIGN.md`. Tạo file `database/schema/000_schema_v3.0.sql`, update deploy scripts, reset DB clean, verify auto-test pass.

## Tasks

### Task 1: Identify SPs reference cột bị DROP (5 min)
- Grep schema v2.0 cho: `is_handling`, `is_inter_doc`, `inter_doc_id`, `inter_incoming_docs`
- Liệt kê SPs cần update/drop

### Task 2: Build schema v3.0 file (20-30 min)
- Copy `000_schema_v2.0.sql` → `000_schema_v3.0.sql`
- Apply patches:
  1. CREATE TYPE `doc_source_type`, `recipient_type_enum`
  2. DROP TABLE `inter_incoming_docs` + `attachment_inter_incoming_docs` (early)
  3. DROP FUNCTION 9 fn_inter_incoming_*
  4. ALTER TABLE `incoming_docs`: DROP 3 cột legacy, ADD 11 cột mới (source_type, is_unit_send, unit_send, previous_outgoing_doc_id, external_doc_id, recall_*, approved_at)
  5. ALTER TABLE `outgoing_docs`: DROP 3 cột legacy, ADD 5 cột mới (status, is_released, released_date, previous_outgoing_doc_id, approved_at)
  6. ALTER TABLE `drafting_docs`: ADD 3 cột mới (status, previous_outgoing_doc_id, approved_at)
  7. CREATE TABLE `outgoing_doc_recipients`
  8. RENAME `lgsp_organizations` → `inter_organizations` + thêm cột mới (lgsp_organ_id, parent_id, address, email, phone)
  9. UPDATE existing SPs có reference cột bị DROP — minimal patch (remove reference, không implement đầy đủ)

### Task 3: Test idempotent (5-10 min)
- `docker exec -i qlvb_postgres psql -f - < 000_schema_v3.0.sql` (LẦN 1)
- Apply lại LẦN 2 — phải zero error
- Verify SP overload = 0
- Verify SP count ≥ 480

### Task 4: Update deploy scripts (5 min)
- `deploy/reset-db-windows.ps1`: path v2.0 → v3.0
- `deploy/deploy-windows.ps1`: same
- `deploy/update-windows.ps1`: same
- `deploy/README.md`: update doc

### Task 5: Update seed/002_demo_data.sql (10-15 min)
- Remove INSERT vào `inter_incoming_docs` + `attachment_inter_incoming_docs`
- Add INSERT vào `incoming_docs` với `source_type='external_lgsp'` thay thế
- Add INSERT vào `inter_organizations` (8 cơ quan demo)
- Add INSERT vào `outgoing_doc_recipients` cho 1-2 outgoing demo

### Task 6: Reset DB + apply + seed (5 min)
- `cd deploy && powershell.exe ./reset-db-windows.ps1` (Windows)
- HOẶC qua docker direct: drop + create schemas + apply schema + seed 001 + seed 002

### Task 7: Auto-test (5-10 min)
- `npm run dev` backend smoke (chỉ verify start, không crash)
- `curl POST /api/auth/login` admin/admin → expect 200 + JWT
- `curl GET /api/van-ban-den?unit_id=1` với JWT → expect 200 (có thể empty list)
- Query SP trực tiếp: `fn_incoming_doc_get_list`, `fn_outgoing_doc_get_list`, `fn_drafting_doc_get_list`

### Task 8: Write SUMMARY.md + commit

## Verification Checklist

- [ ] File `database/schema/000_schema_v3.0.sql` exists
- [ ] File `database/archive/v2.0-finalized/000_schema_v2.0.sql` exists (moved)
- [ ] Apply 2 lần idempotent zero error
- [ ] SP count ≥ 480
- [ ] SP overload = 0
- [ ] Bảng `inter_incoming_docs` không tồn tại
- [ ] Bảng `outgoing_doc_recipients` + `inter_organizations` tồn tại
- [ ] Cột `incoming_docs.source_type` ENUM exists
- [ ] Deploy scripts updated path v3.0
- [ ] Seed 002 không reference inter_incoming_docs
- [ ] Backend start không crash
- [ ] Admin login OK qua API
- [ ] 3 SP fn_*_get_list query không lỗi

## Anti-Patterns to Avoid

- ❌ DROP `LIKE 'fn_%'` broad (bài học Phase 11.1) — chỉ DROP SP cụ thể theo signature
- ❌ Tạo migration script preserve data (user chọn reset clean)
- ❌ Skip idempotent test (phải apply 2 lần OK)
- ❌ Implement SPs mới ở Phase 16 (defer Phase 17)
- ❌ Touch UI/frontend code (defer Phase 19)
