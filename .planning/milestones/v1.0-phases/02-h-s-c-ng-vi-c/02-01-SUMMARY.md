---
phase: 02-h-s-c-ng-vi-c
plan: 01
subsystem: database/migrations
tags: [database, stored-procedures, hscv, workflow, postgresql]
dependency_graph:
  requires: []
  provides:
    - "edoc.fn_handling_doc_get_list"
    - "edoc.fn_handling_doc_create"
    - "edoc.fn_handling_doc_update"
    - "edoc.fn_handling_doc_delete"
    - "edoc.fn_handling_doc_submit"
    - "edoc.fn_handling_doc_approve"
    - "edoc.fn_handling_doc_reject"
    - "edoc.fn_handling_doc_return"
    - "edoc.fn_handling_doc_complete"
    - "edoc.doc_flows table"
    - "edoc.doc_flow_steps table"
    - "edoc.fn_doc_flow_get_list"
    - "edoc.fn_handling_doc_kpi"
    - "edoc.fn_report_handling_by_unit"
  affects:
    - "e_office_app_new/backend (repositories will call these functions)"
    - "e_office_app_new/frontend (pages depend on these via API)"
tech_stack:
  added: []
  patterns:
    - "CREATE OR REPLACE FUNCTION edoc.fn_* RETURNS TABLE pattern"
    - "Status transition guard: SELECT status then validate before UPDATE"
    - "T-02-01 threat mitigated: each transition SP validates current state"
    - "T-02-02 threat mitigated: delete only when status=0"
    - "T-02-03 threat mitigated: all list queries filter by p_unit_id"
    - "T-02-04 threat mitigated: progress validated 0-100 in SP"
key_files:
  created:
    - e_office_app_new/database/migrations/010_sprint5_handling_doc_sps.sql
    - e_office_app_new/database/migrations/011_sprint6_workflow_tables_sps.sql
  modified: []
decisions:
  - "Status transitions enforce strict state machine (0→2 submit, 2→3 approve, 2→-1 reject, 1/2→-2 return, 3→4 complete)"
  - "fn_handling_doc_assign_staff uses ON CONFLICT DO NOTHING to allow partial re-assignment"
  - "fn_doc_flow_step_assign_staff uses DELETE+INSERT pattern (replace-all) for atomic staff reassignment"
  - "fn_doc_flow_delete guards against in-use workflows by checking handling_docs.workflow_id"
  - "KPI prev_period counts HSCV created before p_from_date with status NOT IN (4,-1)"
metrics:
  duration: "~10 minutes"
  completed_date: "2026-04-14"
  tasks_completed: 2
  files_created: 2
---

# Phase 2 Plan 01: Database Stored Procedures for HSCV Module Summary

HSCV Sprint 5+6 DB foundation — 40 objects (23 functions + 4 tables + 13 functions) covering full HSCV lifecycle, workflow designer, KPI and 3 report queries.

## What Was Built

### Task 1 — Sprint 5 HSCV Core (010_sprint5_handling_doc_sps.sql)

23 stored functions in `edoc` schema:

**Listing & Counts:**
- `fn_handling_doc_get_list` — full filter (filter_type, status, keyword, date range, pagination, window count)
- `fn_handling_doc_count_by_status` — 10 filter_type counts for sidebar badges

**CRUD:**
- `fn_handling_doc_get_by_id` — full detail with all joined names
- `fn_handling_doc_create` — validates name required + end_date >= start_date
- `fn_handling_doc_update` — only allowed at status=0 (Mới)
- `fn_handling_doc_delete` — only allowed at status=0 (T-02-02)

**Assignments:**
- `fn_handling_doc_get_staff` — joined staff/positions/departments
- `fn_handling_doc_assign_staff` — bulk assign with role_type (1=phụ trách, 2=phối hợp), ON CONFLICT DO NOTHING
- `fn_handling_doc_remove_staff`

**Opinions:**
- `fn_opinion_get_list` — chronological, joined staff name
- `fn_opinion_create`

**Linked Docs:**
- `fn_handling_doc_get_linked_docs` — doc_type dispatch (incoming/outgoing/drafting)
- `fn_handling_doc_link_doc` — validates doc_type, prevents duplicate
- `fn_handling_doc_unlink_doc`

**Attachments & Children:**
- `fn_handling_doc_get_attachments`
- `fn_handling_doc_get_children`

**Status Transitions (T-02-01):**
- `fn_handling_doc_change_status` — generic
- `fn_handling_doc_submit` — status 0/1 → 2
- `fn_handling_doc_approve` — status 2 → 3
- `fn_handling_doc_reject` — status 2 → -1 (reason required)
- `fn_handling_doc_return` — status 1/2 → -2 (reason required)
- `fn_handling_doc_complete` — status 3 → 4, sets complete_date + progress=100
- `fn_handling_doc_update_progress` — validates 0-100 range (T-02-04)

### Task 2 — Sprint 6 Workflow + KPI + Reports (011_sprint6_workflow_tables_sps.sql)

**4 new tables:**
- `edoc.doc_flows` — workflow definitions with UNIQUE(unit_id, name, version)
- `edoc.doc_flow_steps` — steps with step_type CHECK constraint (start/process/end)
- `edoc.doc_flow_step_links` — connections between steps, UNIQUE(from_step_id, to_step_id)
- `edoc.doc_flow_step_staff` — staff assignments per step

**17 stored functions:**
- Workflow CRUD: `fn_doc_flow_get_list/get_by_id/create/update/delete`
- Step management: `fn_doc_flow_step_get_list/create/update/delete`
- Step linking: `fn_doc_flow_step_link_create/delete`
- Staff per step: `fn_doc_flow_step_get_staff`, `fn_doc_flow_step_assign_staff` (replace-all)
- KPI: `fn_handling_doc_kpi` — total/prev_period/current_period/completed/in_progress/overdue/%
- Reports: `fn_report_handling_by_unit`, `fn_report_handling_by_resolver`, `fn_report_handling_by_assigner`

## Deviations from Plan

None — plan executed exactly as written. All threat model mitigations (T-02-01 through T-02-04) applied as specified.

## Known Stubs

None — these are pure SQL migration files, no UI stubs.

## Threat Surface Scan

No new network endpoints or auth paths introduced. These are database-layer SQL files only.

## Self-Check: PASSED

- `e_office_app_new/database/migrations/010_sprint5_handling_doc_sps.sql` — FOUND
- `e_office_app_new/database/migrations/011_sprint6_workflow_tables_sps.sql` — FOUND
- Commit `2114bf6` — Task 1 (23 Sprint 5 functions)
- Commit `3cd61a5` — Task 2 (4 tables + 17 Sprint 6 functions)
