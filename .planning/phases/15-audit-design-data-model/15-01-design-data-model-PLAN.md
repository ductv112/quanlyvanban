---
phase: 15
plan: "15-01"
title: Audit & Design Data Model v3.0 — Output DESIGN.md
created: 2026-04-23
status: ready
mode: design-only (no code, no DB reset)
requirements:
  - DM-01
  - DM-02
  - DM-03
  - DM-04
  - DM-05
  - DM-06
  - DM-07
depends_on: []
estimated_duration: 60-90 minutes
output_files:
  - .planning/phases/15-audit-design-data-model/15-DESIGN.md
  - .planning/phases/15-audit-design-data-model/15-01-SUMMARY.md
---

# Plan 15-01: Audit & Design Data Model v3.0

## Goal

Sản phẩm cuối: **`15-DESIGN.md`** — design document chốt cụ thể schema v3.0 cho Phase 16 implement. Phase 15 KHÔNG viết SQL chạy được, KHÔNG reset DB, KHÔNG sửa code. Chỉ design doc với:

1. Audit gap schema v2.0 hiện tại vs source .NET cũ vs nghiệp vụ chốt với user
2. Schema mới cho 3 bảng `incoming_docs` / `outgoing_docs` / `drafting_docs` (cột mới, ENUM, FK)
3. Schema bảng mới `outgoing_doc_recipients` + `inter_organizations`
4. Bảng/cột bị drop (`inter_incoming_docs`, `attachment_inter_incoming_docs`, một số legacy fields)
5. Lifecycle workflow (Drafting → Ban hành → Gửi) với status values
6. SP signatures preview (cho Phase 17 implement)
7. ERD diagram (mermaid)
8. Migration strategy (reset DB clean, bump master schema v2.0 → v3.0)
9. Breaking change impact analysis trên 5 module xuống dòng (HSCV, ký số, dashboard, báo cáo, frontend)

## Context Recap

**Decisions chốt từ CONTEXT.md (D-01 → D-25):**
- Reset DB clean (user approved 2026-04-23) — không migration data
- Bump master schema `000_schema_v2.0.sql` → `000_schema_v3.0.sql`
- Gộp `inter_incoming_docs` vào `incoming_docs` với `source_type ENUM('internal','external_lgsp','manual')`
- 1 bảng `outgoing_doc_recipients` + recipient_type ENUM (`'internal_unit'|'external_org'`)
- Approver = VARCHAR text (như source cũ), 1 cấp boolean Approved
- Tách rõ `drafting_unit_id` vs `publish_unit_id` trong outgoing
- Lifecycle status text VARCHAR + boolean `is_released`

**Canonical refs (đọc trước khi design):**
- `.planning/phases/15-audit-design-data-model/15-CONTEXT.md` — 25 decisions
- `e_office_app_new/database/schema/000_schema_v2.0.sql` — schema baseline (20,168 lines)
- `docs/source_code_cu/sources/OneWin.Data.Object/Base/edoc/{IncomingDoc,OutgoingDoc,DraftingDoc}.cs` — source nghiệp vụ
- `CLAUDE.md` §"DB Migration Strategy (v2.0+)" — schema rules

## Tasks

### Task 1: Audit Schema v2.0 Hiện Tại (15-20 min)

**Subtask 1.1:** Read `e_office_app_new/database/schema/000_schema_v2.0.sql` cho:
- 3 bảng core: `edoc.incoming_docs`, `edoc.outgoing_docs`, `edoc.drafting_docs`
- Bảng phụ: `edoc.inter_incoming_docs`, `edoc.attachment_inter_incoming_docs`
- Bảng LGSP: `edoc.lgsp_tracking`, `edoc.lgsp_organizations`
- Liệt kê đầy đủ columns + data types + constraints + indexes hiện tại

**Subtask 1.2:** Đọc source .NET cũ files:
- `docs/source_code_cu/sources/OneWin.Data.Object/Base/edoc/IncomingDoc.cs`
- `docs/source_code_cu/sources/OneWin.Data.Object/Base/edoc/OutgoingDoc.cs`
- `docs/source_code_cu/sources/OneWin.Data.Object/Base/edoc/DraftingDoc.cs`
- Liệt kê đầy đủ properties + map sang DB columns

**Subtask 1.3:** Tạo bảng so sánh GAP trong DESIGN.md:

| Field | Source .NET cũ | Schema v2.0 hiện tại | Schema v3.0 mới | Lý do |
|-------|----------------|----------------------|------------------|-------|
| (e.g.) `is_unit_send` | ✓ Có | ✗ Thiếu | ✓ Thêm | Phân biệt nội bộ vs ngoài |

**Verification:** Bảng GAP có ≥ 20 rows phủ tất cả cột thiếu/thừa của 3 bảng core.

### Task 2: Design 3 Bảng Core v3.0 (15-20 min)

**Subtask 2.1:** DESIGN.md section "Schema v3.0 — incoming_docs" với CREATE TABLE đầy đủ:
- Tất cả cột v2.0 hiện tại (giữ lại)
- Cột mới: `source_type ENUM`, `is_unit_send`, `unit_send`, `previous_outgoing_doc_id`, `external_doc_id`, `approver`, `approved`, `approved_at`, recall fields (gộp từ inter_incoming_docs)
- Cột bị drop: `IsHandling`, `IsInterDoc`, `MoveAnnouncement` (legacy không dùng)
- Indexes: composite index trên (source_type, status), partial unique index trên external_doc_id WHERE source_type='external_lgsp'
- Foreign keys với ON DELETE behavior rõ ràng
- COMMENT ON COLUMN cho mỗi cột mới

**Subtask 2.2:** DESIGN.md section "Schema v3.0 — outgoing_docs" với:
- Tách `drafting_unit_id` + `publish_unit_id` (2 FK riêng tới departments)
- Thêm `is_released`, `released_date`, `previous_outgoing_doc_id`, `approver`, `approved`, `approved_at`
- Status text VARCHAR + CHECK constraint `IN ('draft','released','sent','completed')`

**Subtask 2.3:** DESIGN.md section "Schema v3.0 — drafting_docs" với:
- `drafting_unit_id`, `publish_unit_id` (giống outgoing)
- Thêm `is_released`, `released_date`, `previous_outgoing_doc_id`, `approver`, `approved`, `approved_at`
- Status text VARCHAR + CHECK constraint `IN ('draft','reviewing','approved','released')`

**Verification:** Mỗi section có CREATE TABLE đầy đủ runnable PostgreSQL syntax (chỉ design, chưa run). Số cột/table ≥ 25.

### Task 3: Design Bảng Mới (10-15 min)

**Subtask 3.1:** DESIGN.md section "Schema v3.0 — outgoing_doc_recipients" với:
- Schema chi tiết theo D-17 trong CONTEXT.md
- ENUM `recipient_type AS ENUM('internal_unit','external_org')`
- CHECK constraint XOR (internal_unit XOR external_org)
- Index `(outgoing_doc_id, sent_status)` cho query worker LGSP
- ON DELETE CASCADE từ outgoing_docs

**Subtask 3.2:** DESIGN.md section "Schema v3.0 — inter_organizations" với:
- Schema theo D-18 trong CONTEXT.md
- Self-FK `parent_id` cho cây cơ quan
- UNIQUE INDEX trên `code`
- Note: rename từ `lgsp_organizations` (Phase 16 sẽ migrate data)

**Subtask 3.3:** DESIGN.md section "Drop tables in v3.0":
- `inter_incoming_docs` → data migrate vào `incoming_docs` với `source_type='external_lgsp'`
- `attachment_inter_incoming_docs` → migrate vào `attachments` polymorphic với `entity_type='incoming'`
- `lgsp_organizations` → rename thành `inter_organizations` (sau migrate)
- Note: vì reset DB clean nên không cần migration script — chỉ document lý do drop

**Verification:** Có 2 CREATE TABLE mới + section "Drop tables" liệt kê 3 bảng + lý do.

### Task 4: Lifecycle Workflow + SP Signatures Preview (10-15 min)

**Subtask 4.1:** DESIGN.md section "Lifecycle Workflow" với:
- Sơ đồ mermaid 3 trạng thái chuyển đổi (drafting → outgoing → incoming)
- Bảng status values cho mỗi table với meaning
- Rules transition (VD: `is_released=true` mới được Send, `approved=true` mới được Release)

**Subtask 4.2:** DESIGN.md section "Stored Procedure Signatures (Preview for Phase 17)":
- 5 SP signatures theo D-23 trong CONTEXT.md
- Mỗi SP có: tên đầy đủ schema.fn_*, parameters với data type, RETURNS TABLE columns, mô tả nghiệp vụ ngắn (3-5 dòng)
- Note: chỉ preview — implementation ở Phase 17

**Verification:** 5 SP signatures có signature đầy đủ + description.

### Task 5: ERD Diagram + Breaking Change Analysis (15-20 min)

**Subtask 5.1:** DESIGN.md section "ERD Diagram" với mermaid:
- 3 bảng core + 2 bảng mới + bảng `attachments` + `departments` + `staff`
- Relationships: drafting → outgoing (PreviousOutgoingDocId), outgoing → incoming (PreviousOutgoingDocId), outgoing → recipients → unit/inter_organization
- FK arrows + cardinality
- Note: chỉ vẽ phần thay đổi v3.0, không cần ERD toàn DB

**Subtask 5.2:** DESIGN.md section "Breaking Change Impact Analysis" — 1 bảng cho mỗi module xuống dòng:

| Module | Affected Tables/SPs | Risk | Mitigation Plan |
|--------|--------------------|------|-----------------|
| HSCV | `handling_docs`, `attachment_handling_docs` | Medium | Verify FK liên kết qua attachment_id, không trực tiếp tới inter_incoming_docs |
| Ký số v2.0 | `attachments.entity_type='incoming'` polymorphic | Low | entity_type values không thay đổi, an toàn |
| Dashboard | `fn_dashboard_stats_*` | High | Verify SP đếm `incoming_docs` mới gộp 3 source_type → có thể cần GROUP BY source_type |
| Báo cáo Excel | `reports/*.repository.ts` | Medium | Verify column names khớp; có thể cần update query alias |
| Frontend pages | `/van-ban-den`, `/van-ban-di`, `/van-ban-du-thao`, `/van-ban-lien-thong` | High | Phase 19 rewrite UI — DESIGN.md flag risk + Phase 20 regression test |

**Subtask 5.3:** DESIGN.md section "Migration Strategy v2.0 → v3.0":
- Bước 1: Bump master schema file
- Bước 2: Move `database/schema/000_schema_v2.0.sql` → `database/archive/v2.0-finalized/`
- Bước 3: Reset DB qua `deploy/reset-db-windows.ps1` (user approved)
- Bước 4: Apply schema mới + seed 001 + 002
- Bước 5: Verify SP count ≥ baseline

**Verification:** ERD mermaid render đúng (no syntax error). Breaking change table có ≥ 5 rows (5 modules).

### Task 6: Write DESIGN.md + SUMMARY.md (5-10 min)

**Subtask 6.1:** Tổng hợp tất cả Tasks 1-5 vào file `15-DESIGN.md`:
- Frontmatter: phase, version, status, requirements
- Section order theo Tasks 1-5
- Table of contents ở đầu
- Cuối file: "Approval gate" — yêu cầu user review + approve trước khi run Phase 16

**Subtask 6.2:** Write `15-01-SUMMARY.md` với:
- one_liner: "Phase 15 design — schema v3.0 chuẩn hoá data model 3 bảng văn bản, gộp inter_incoming_docs, recipients table, ban hành/gửi tách bước, approver 1 cấp"
- requirements_completed: DM-01..DM-07
- decisions: list 25 decisions từ CONTEXT.md đã được implement trong DESIGN.md
- next_steps: "User review DESIGN.md → approve → /gsd-execute-phase 16 to implement"

## Verification Checklist

- [ ] `15-DESIGN.md` tồn tại tại `.planning/phases/15-audit-design-data-model/15-DESIGN.md`
- [ ] DESIGN.md có 9 sections theo Tasks 1-5 + TOC
- [ ] Bảng GAP ≥ 20 rows (Task 1)
- [ ] CREATE TABLE syntax cho 3 bảng core + 2 bảng mới đầy đủ runnable PostgreSQL syntax (Task 2-3)
- [ ] 5 SP signatures với mô tả nghiệp vụ (Task 4)
- [ ] ERD mermaid diagram thể hiện relationships (Task 5)
- [ ] Breaking change table ≥ 5 modules với mitigation plan (Task 5)
- [ ] Migration strategy 5 bước cụ thể (Task 5)
- [ ] `15-01-SUMMARY.md` tồn tại với one_liner + requirements_completed
- [ ] KHÔNG sửa file source code (không touch `e_office_app_new/`)
- [ ] KHÔNG run SQL trên DB
- [ ] User approval gate ở cuối DESIGN.md

## Anti-Patterns to Avoid

- ❌ Run SQL trên DB → Phase 15 là design only, Phase 16 mới implement
- ❌ Modify source code (`e_office_app_new/`) → DESIGN.md is documentation only
- ❌ Generate code stubs hoặc placeholder code (TS/SQL)
- ❌ Skip audit Task 1 và jump thẳng vào design — phải đọc schema v2.0 + source .NET cũ trước
- ❌ Quên section "Breaking Change Impact Analysis" — đây là điểm CRITICAL cho Phase 20 regression
- ❌ Tạo migration script preserve data (user explicit chọn reset DB clean)

## Definition of Done

Phase 15 done khi:
1. `15-DESIGN.md` written với đủ 9 sections + 25 decisions integrated
2. `15-01-SUMMARY.md` written
3. Atomic commit với message `docs(15-01): design data model v3.0 — DESIGN.md ready for review`
4. Báo user → user review DESIGN.md → user approve mới sang Phase 16

**KHÔNG auto-advance sang Phase 16** vì Phase 16 reset DB destructive — phải có user approval gate.
