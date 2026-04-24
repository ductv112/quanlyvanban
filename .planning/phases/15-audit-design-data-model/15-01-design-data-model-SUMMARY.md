---
phase: 15
plan: "15-01"
title: Audit & Design Data Model v3.0 — DESIGN.md ready
completed: 2026-04-23
status: complete
output_files:
  - .planning/phases/15-audit-design-data-model/15-DESIGN.md
requirements_completed:
  - DM-01
  - DM-02
  - DM-03
  - DM-04
  - DM-05
  - DM-06
  - DM-07
one_liner: "Phase 15 design — schema v3.0 chuẩn hoá data model 3 bảng văn bản (24 cột thêm, 6 cột drop), gộp inter_incoming_docs, recipients table, ban hành/gửi tách bước, approver 1 cấp, 7 SP signatures preview, ERD diagram, breaking change analysis 10 modules"
---

# Plan 15-01 Summary — Audit & Design Data Model v3.0

## What Was Built

**Output:** `15-DESIGN.md` (38KB, 12 sections, comprehensive data model design)

### Sections delivered

1. **GAP Analysis** — Bảng so sánh schema v2.0 vs source .NET cũ vs v3.0 mới: 24 cột thêm, 6 cột drop, 3 cột mở rộng
2. **`incoming_docs` v3.0** — CREATE TABLE đầy đủ với 8 cột mới (source_type ENUM, is_unit_send, unit_send, previous_outgoing_doc_id, external_doc_id, recall fields)
3. **`outgoing_docs` v3.0** — CREATE TABLE với 5 cột mới (is_released, released_date, previous_outgoing_doc_id, status, approved_at)
4. **`drafting_docs` v3.0** — CREATE TABLE với 3 cột mới (status, previous_outgoing_doc_id, approved_at) — giữ is_released/released_date đã có v2.0
5. **2 bảng mới**: `outgoing_doc_recipients` (multi-recipient + ENUM type) + `inter_organizations` (rename từ lgsp_organizations)
6. **Tables/Columns DROPPED**: inter_incoming_docs + attachment_inter_incoming_docs + 3 cột legacy (is_handling, is_inter_doc, inter_doc_id) + 9 SPs liên quan
7. **Lifecycle Workflow** — Mermaid stateDiagram + status values cho 3 bảng + transition rules
8. **SP Signatures Preview** — 7 SPs cho Phase 17 (drafting_doc_approve/unapprove/release, outgoing_doc_release/send, recipients_create, lgsp sync)
9. **ERD Diagram** — Mermaid erDiagram thể hiện 10 entities + relationships
10. **Breaking Change Impact Analysis** — 10 modules × risk level (3 High, 4 Medium, 3 Low) × mitigation plan
11. **Migration Strategy v2.0 → v3.0** — 5 bước cụ thể (bump file, update scripts, reset DB, verify SP count, update CLAUDE.md)
12. **Approval Gate** — 11-item checklist cho user review

## Key Decisions Implemented

Tất cả 25 decisions từ `15-CONTEXT.md` đã được integrate:

- **Schema strategy:** Reset DB clean, bump v2.0 → v3.0, idempotent pattern, targeted DROP
- **Data model `incoming_docs`:** source_type ENUM 3 values, is_unit_send + unit_send tách rõ, previous_outgoing_doc_id FK, external_doc_id UNIQUE INDEX (partial), gộp recall flow từ inter_incoming_docs
- **Data model `outgoing_docs` + `drafting_docs`:** drafting_unit_id vs publish_unit_id (đã có v2.0), thêm is_released + released_date + status text + previous_outgoing_doc_id
- **Approver:** VARCHAR(255) text như source cũ, 1 cấp boolean + approved_at timestamp
- **Recipients:** 1 bảng outgoing_doc_recipients + ENUM recipient_type với XOR CHECK constraint
- **Inter organizations:** rename từ lgsp_organizations, self-FK parent_id, UNIQUE code

## Verification Results

- ✅ Tất cả 7 REQ-IDs (DM-01..DM-07) covered trong design
- ✅ 12 sections theo checklist Plan 15-01
- ✅ GAP table với 30+ rows (≥ 20 yêu cầu)
- ✅ 3 bảng core + 2 bảng mới có CREATE TABLE syntax đầy đủ runnable PostgreSQL
- ✅ 7 SP signatures với mô tả nghiệp vụ chi tiết (≥ 5 yêu cầu)
- ✅ ERD mermaid có 10 entities + relationships
- ✅ Breaking change table 10 modules (≥ 5 yêu cầu)
- ✅ Migration strategy 5 bước
- ✅ Approval gate ở cuối DESIGN.md
- ✅ KHÔNG sửa file source code (`e_office_app_new/`)
- ✅ KHÔNG run SQL trên DB

## Anti-patterns avoided

- ✅ Không run SQL trên DB
- ✅ Không modify source code
- ✅ Không generate migration script preserve data (user chọn reset clean)
- ✅ Không skip audit Task 1 (đã đọc 6 bảng schema v2.0 chi tiết)

## Next Steps

**STOP — Phase 16 cần USER REVIEW + APPROVE trước khi reset DB destructive.**

User checklist (11 items) ở cuối `15-DESIGN.md` Section 12 (Approval Gate):
- Review từng section (1-11)
- Tick checklist nếu đồng ý
- Reply "Approved Phase 15 — proceed Phase 16" hoặc "Edit section X"

Sau khi approve → `/gsd-execute-phase 16` sẽ:
1. Bump master schema file v2.0 → v3.0
2. Reset DB clean
3. Apply new schema
4. Seed 001 + 002 với schema mới

## Files Touched

**Created:**
- `.planning/phases/15-audit-design-data-model/15-DESIGN.md` (1,054 lines)
- `.planning/phases/15-audit-design-data-model/15-01-design-data-model-SUMMARY.md` (this file)

**No source code changes** — Phase 15 là design only.
