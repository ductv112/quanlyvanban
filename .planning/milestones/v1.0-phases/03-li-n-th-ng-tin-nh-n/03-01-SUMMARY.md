---
phase: 03-li-n-th-ng-tin-nh-n
plan: "01"
subsystem: database
tags: [migration, postgresql, stored-procedures, inter-incoming, messages, notices]
dependency_graph:
  requires: []
  provides:
    - edoc.inter_incoming_docs table + 7 SPs (Sprint 7)
    - edoc.messages + message_recipients + notices + notice_reads tables + 13 SPs (Sprint 8)
  affects:
    - 03-02 (backend repositories depend on these SPs)
    - 03-03 (API routes depend on these repositories)
    - 03-04 (frontend pages depend on API routes)
tech_stack:
  added: []
  patterns:
    - PostgreSQL stored functions with SECURITY DEFINER
    - RETURNS TABLE for paginated list functions with total_count window
    - ON CONFLICT DO NOTHING for idempotent inserts
    - Soft delete pattern (is_deleted flag) for messages
    - Thread pattern via parent_id self-reference on messages
key_files:
  created:
    - e_office_app_new/database/migrations/012_sprint7_inter_incoming.sql
    - e_office_app_new/database/migrations/013_sprint8_messages_notices.sql
  modified: []
decisions:
  - Used handling_doc_links (existing table) instead of plan-referenced handling_doc_documents — same FK pattern, correct table name
  - fn_message_delete performs soft delete only for requesting staff_id copy — cannot delete other users copies (T-03-01 threat mitigation)
  - fn_message_get_by_id filters by p_staff_id (sender OR recipient) — prevents info disclosure (T-03-02 mitigation)
metrics:
  duration: "~12 minutes"
  completed: "2026-04-14T07:53:56Z"
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 0
---

# Phase 03 Plan 01: Sprint 7+8 Database Migrations Summary

**One-liner:** PostgreSQL migrations creating VB lien thong, tin nhan, and thong bao tables with 20 stored functions across Sprint 7 (inter-agency docs + incoming doc actions) and Sprint 8 (internal messaging + system notices).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Sprint 7 migration — VB lien thong tables + incoming doc action SPs | 7e2cc13 | 012_sprint7_inter_incoming.sql |
| 2 | Sprint 8 migration — Messages + Notices tables + SPs | 5287403 | 013_sprint8_messages_notices.sql |

## What Was Built

### Migration 012 — Sprint 7 (7 functions)

**Table: edoc.inter_incoming_docs**
19 columns including unit_id, notation, document_code, abstract, publish_unit, publish_date, signer, sign_date, expired_date, doc_type_id, status, source_system, external_doc_id. 3 indexes on unit_id, received_date, status.

**Stored Functions:**
1. `edoc.fn_inter_incoming_get_list` — paginated list with keyword/status/date filters, total_count
2. `edoc.fn_inter_incoming_get_by_id` — single row detail
3. `edoc.fn_inter_incoming_create` — insert with unit validation, returns (success, message, id)
4. `edoc.fn_handling_doc_create_from_doc` — creates HSCV from incoming/outgoing/drafting doc, auto-links via handling_doc_links, assigns multiple curators via staff_handling_docs
5. `edoc.fn_incoming_doc_handover` — records staff handover receipt via user_incoming_docs upsert
6. `edoc.fn_incoming_doc_return` — validates non-empty reason, records via leader_notes, resets approved=FALSE
7. `edoc.fn_incoming_doc_cancel_approve` — validates doc is approved before reversing, sets approved=FALSE

### Migration 013 — Sprint 8 (13 functions)

**Tables created:**
- `edoc.messages` — message header with parent_id threading (NULL=original, set=reply)
- `edoc.message_recipients` — per-recipient copy with is_read/is_deleted soft delete, unique constraint
- `edoc.notices` — system notices per unit with notice_type
- `edoc.notice_reads` — idempotent read tracking with unique constraint

**Message Functions (8):**
1. `edoc.fn_message_get_inbox` — inbox (is_deleted=FALSE, parent_id=NULL), sender name, is_read flag
2. `edoc.fn_message_get_sent` — sent messages with recipient names via STRING_AGG
3. `edoc.fn_message_get_trash` — deleted messages (is_deleted=TRUE)
4. `edoc.fn_message_get_by_id` — detail + auto UPDATE is_read=TRUE for recipient
5. `edoc.fn_message_create` — insert + FOREACH loop over INT[] recipients
6. `edoc.fn_message_reply` — new message with parent_id + all original recipients + sender
7. `edoc.fn_message_delete` — soft delete only requesting staff copy (T-03-01)
8. `edoc.fn_message_count_unread` — badge count for notification header

**Notice Functions (5):**
9. `edoc.fn_notice_get_list` — with is_read flag via LEFT JOIN notice_reads, p_is_read filter
10. `edoc.fn_notice_create` — insert with title+content validation
11. `edoc.fn_notice_mark_read` — ON CONFLICT DO NOTHING idempotent
12. `edoc.fn_notice_mark_all_read` — bulk CTE insert + returns count of newly-read notices
13. `edoc.fn_notice_count_unread` — bell icon badge count

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Used correct FK table name for HSCV document link**
- **Found during:** Task 1 implementation
- **Issue:** Plan referenced `edoc.handling_doc_documents` in fn_handling_doc_create_from_doc, but the actual table created in migration 002 is `edoc.handling_doc_links` with columns (handling_doc_id, doc_type, doc_id)
- **Fix:** Used `edoc.handling_doc_links` with the correct schema — functionally identical
- **Files modified:** 012_sprint7_inter_incoming.sql

## Threat Mitigations Applied

| Threat ID | Mitigation Applied |
|-----------|-------------------|
| T-03-01 | fn_message_delete soft-deletes only for requesting staff_id — other users' copies unaffected |
| T-03-02 | fn_message_get_by_id WHERE clause: from_staff_id = p_staff_id OR EXISTS(recipient) — only sender/recipients can read |
| T-03-03 | fn_notice_create has no role check — accepted per plan (handled at API middleware layer) |

## Verification Results

Both migrations ran without errors against PostgreSQL 16 (qlvb_dev database).

All 20 functions confirmed created:
- 3 fn_inter_incoming_* functions
- 4 fn_incoming_doc_* action functions (handover, return, cancel_approve) + fn_handling_doc_create_from_doc
- 8 fn_message_* functions
- 5 fn_notice_* functions

All 5 new tables confirmed:
- edoc.inter_incoming_docs
- edoc.messages
- edoc.message_recipients
- edoc.notices
- edoc.notice_reads

## Known Stubs

None — all stored functions are fully implemented with real SQL logic.

## Self-Check: PASSED

- [x] 012_sprint7_inter_incoming.sql exists and was applied
- [x] 013_sprint8_messages_notices.sql exists and was applied
- [x] Commit 7e2cc13 exists (Task 1)
- [x] Commit 5287403 exists (Task 2)
- [x] 20 total functions in edoc schema (verified via information_schema.routines query)
- [x] 5 new tables confirmed in edoc schema
