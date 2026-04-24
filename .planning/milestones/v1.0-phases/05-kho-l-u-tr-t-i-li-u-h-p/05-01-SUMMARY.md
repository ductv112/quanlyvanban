---
phase: 05-kho-l-u-tr-t-i-li-u-h-p
plan: "01"
subsystem: database-migrations
tags: [database, migrations, esto, iso, cont, edoc, archive, documents, contracts, meetings]
dependency_graph:
  requires: []
  provides:
    - esto.warehouses
    - esto.fonds
    - esto.records
    - esto.borrow_requests
    - esto.borrow_request_records
    - iso.document_categories
    - iso.documents
    - cont.contract_types
    - cont.contracts
    - cont.contract_attachments
    - edoc.rooms
    - edoc.meeting_types
    - edoc.room_schedules
    - edoc.room_schedule_staff
    - edoc.room_schedule_attachments
    - edoc.room_schedule_questions
    - edoc.room_schedule_answers
    - edoc.room_schedule_votes
    - esto.fn_* (22 functions)
    - iso.fn_* (9 functions)
    - cont.fn_* (10 functions)
    - edoc.fn_room_* + edoc.fn_meeting_type_* + edoc.fn_vote_* (26 functions)
  affects: []
tech_stack:
  added:
    - esto schema tables (5 tables)
    - iso schema tables (2 tables)
    - cont schema tables (3 tables)
    - edoc meeting tables (8 tables)
  patterns:
    - RETURNS TABLE(success BOOLEAN, message TEXT, id *) for write operations
    - Paginated lists with COUNT(*) OVER() window function
    - Soft delete via is_deleted = true
    - State machine transitions with current-state validation
    - UNIQUE constraints for data integrity (vote, borrow_request_records)
key_files:
  created:
    - e_office_app_new/database/migrations/016_sprint11_archive_storage.sql
    - e_office_app_new/database/migrations/017_sprint12_documents_contracts.sql
    - e_office_app_new/database/migrations/018_sprint13_meetings.sql
  modified: []
decisions:
  - "esto schema uses soft delete (is_deleted) for warehouses; hard delete for records after borrow check"
  - "Vote uniqueness enforced by UNIQUE(question_id, staff_id) on room_schedule_votes table"
  - "borrow_request_approve/fn_room_schedule_approve both validate current state before transition"
  - "room_schedule_delete only allowed when approved=0 per threat model T-05-05"
  - "fn_room_schedule_stats returns 3 result sets in one function call (by_month, by_room, by_meeting_type)"
metrics:
  completed_date: "2026-04-14"
  tasks_completed: 3
  tasks_total: 3
  files_created: 3
  files_modified: 0
---

# Phase 5 Plan 01: Database Migrations (Sprint 11-13) Summary

**One-liner:** PostgreSQL migrations for archive/storage (esto), documents/contracts (iso/cont), and paperless meetings (edoc) — 18 tables + 67 stored functions across 3 migration files.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Sprint 11 archive/storage migration (esto) | ec62473 | 016_sprint11_archive_storage.sql |
| 2 | Sprint 12 documents/contracts migration (iso/cont) | aba35ee | 017_sprint12_documents_contracts.sql |
| 3 | Sprint 13 meetings migration (edoc) | be6ccdd | 018_sprint13_meetings.sql |

## What Was Built

### Migration 016 — Sprint 11 Archive/Storage (esto schema)

**5 tables:**
- `esto.warehouses` — Kho lưu trữ (tree structure, soft delete)
- `esto.fonds` — Phông lưu trữ (tree structure with parent_id)
- `esto.records` — Hồ sơ lưu trữ (hard delete, foreign keys to fonds + warehouses)
- `esto.borrow_requests` — Yêu cầu mượn/trả (status machine: 0→1→2→3 or -1)
- `esto.borrow_request_records` — Link yêu cầu mượn → hồ sơ

**22 stored functions:**
- Warehouse: get_tree, get_by_id, create, update, delete
- Fond: get_tree, get_by_id, create, update, delete
- Record: get_list (paginated), get_by_id, create, update, delete
- Borrow: get_list, get_by_id, create, approve, reject, checkout, return

### Migration 017 — Sprint 12 Documents & Contracts (iso/cont schemas)

**5 tables:**
- `iso.document_categories` — Danh mục tài liệu (tree structure)
- `iso.documents` — Tài liệu chung (soft delete, file metadata)
- `cont.contract_types` — Loại hợp đồng (tree structure)
- `cont.contracts` — Hợp đồng (status machine: 0=Mới, 1=Đang thực hiện, 2=Hoàn thành, -1=Hủy)
- `cont.contract_attachments` — Đính kèm hợp đồng (CASCADE delete)

**19 stored functions:**
- Doc categories: get_tree, create, update, delete (checks children + documents)
- Documents: get_list (paginated), get_by_id, create, update, delete (soft)
- Contract types: get_list, create, update, delete (checks contracts linked)
- Contracts: get_list (paginated), get_by_id, create, update, delete (status=0 only), get_attachments

### Migration 018 — Sprint 13 Meetings (edoc schema)

**8 tables:**
- `edoc.rooms` — Phòng họp (soft delete)
- `edoc.meeting_types` — Loại cuộc họp (soft delete)
- `edoc.room_schedules` — Lịch họp / Cuộc họp (approved + meeting_status state machines)
- `edoc.room_schedule_staff` — Thành viên họp (UNIQUE per schedule+staff)
- `edoc.room_schedule_attachments` — Tài liệu họp
- `edoc.room_schedule_questions` — Câu hỏi biểu quyết (UUID primary key)
- `edoc.room_schedule_answers` — Đáp án biểu quyết (UUID primary key)
- `edoc.room_schedule_votes` — Phiếu biểu quyết (UNIQUE question_id+staff_id)

**26 stored functions:**
- Rooms: get_list, create, update, delete
- Meeting types: get_list, create, update, delete
- Room schedules: get_list, get_by_id, create, update, delete, approve, reject
- Staff: get_staff, assign_staff (bulk), remove_staff
- Voting: question_get_list, question_create, answer_create, vote_cast, question_start, question_stop, vote_get_results
- Stats: room_schedule_stats (3 result sets: by_month, by_room, by_meeting_type)

## Threat Model Mitigations Applied

All T-05-xx threats from plan's threat model were mitigated:

| Threat ID | Mitigation Applied |
|-----------|-------------------|
| T-05-01 | `esto.fn_borrow_request_approve` validates `status = 0` before transition to 1 |
| T-05-02 | `edoc.fn_room_schedule_approve` validates `approved = 0` before transition to 1 |
| T-05-03 | `UNIQUE(question_id, staff_id)` constraint on `edoc.room_schedule_votes` + ON CONFLICT UPDATE in `fn_vote_cast` |
| T-05-04 | All list functions filter by `p_unit_id` parameter |
| T-05-05 | `edoc.fn_room_schedule_delete` returns error if `approved <> 0` |

## Deviations from Plan

### Auto-fixed Issues

None — plan executed as designed.

### Notes

- 016 migration: The worktree `git reset --soft` caused `.planning/phases/05-*` files to appear as staged deletions. These were restored in a separate commit (b64608e) before proceeding. Planning files in main repo were never affected.
- Function count slightly higher than planned: 67 actual vs ~66 planned (iso.fn_doc_category_get_tree counted separately from update).

## Known Stubs

None — all migration files contain complete, runnable SQL. No placeholder values or TODO markers.

## Self-Check

### Files Exist
- `e_office_app_new/database/migrations/016_sprint11_archive_storage.sql` — FOUND
- `e_office_app_new/database/migrations/017_sprint12_documents_contracts.sql` — FOUND
- `e_office_app_new/database/migrations/018_sprint13_meetings.sql` — FOUND

### Acceptance Criteria Verified
- ✓ 016: CREATE TABLE esto.warehouses, fonds, records, borrow_requests, borrow_request_records
- ✓ 016: esto.fn_warehouse_get_tree, fn_fond_get_tree, fn_record_get_list, fn_borrow_request_create/approve/return
- ✓ 017: CREATE TABLE iso.document_categories, documents, cont.contract_types, contracts, contract_attachments
- ✓ 017: iso.fn_document_get_list, cont.fn_contract_get_list, cont.fn_contract_type_get_list
- ✓ 018: CREATE TABLE edoc.rooms, meeting_types, room_schedules, room_schedule_staff, questions, answers, votes
- ✓ 018: edoc.fn_room_get_list, fn_room_schedule_get_list/approve, fn_vote_cast, fn_vote_get_results, fn_room_schedule_stats

## Self-Check: PASSED
