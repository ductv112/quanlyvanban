---
phase: 03-li-n-th-ng-tin-nh-n
plan: "02"
subsystem: backend-api
tags: [inter-incoming, incoming-doc, actions, giao-viec, repository, express-routes]
dependency_graph:
  requires: ["03-01"]
  provides: ["/api/van-ban-lien-thong GET list+detail", "/api/van-ban-den/:id/giao-viec", "/api/van-ban-den/:id/nhan-ban-giao", "/api/van-ban-den/:id/chuyen-lai", "/api/van-ban-den/:id/huy-duyet"]
  affects: ["frontend-inter-incoming-page", "frontend-incoming-doc-toolbar"]
tech_stack:
  added: []
  patterns: ["repository-pattern", "express-router", "callFunctionOne", "JWT-staffId-extraction"]
key_files:
  created:
    - e_office_app_new/backend/src/repositories/inter-incoming.repository.ts
    - e_office_app_new/backend/src/routes/inter-incoming.ts
  modified:
    - e_office_app_new/backend/src/repositories/incoming-doc.repository.ts
    - e_office_app_new/backend/src/routes/incoming-doc.ts
    - e_office_app_new/backend/src/server.ts
decisions:
  - "staffId extracted from JWT (not request body) for all action endpoints — prevents impersonation (T-03-04)"
  - "chuyen-lai validates reason min 10 chars server-side (T-03-05)"
  - "inter-incoming list filters by unitId from JWT — users only see their unit docs (T-03-07)"
  - "huy-duyet role check deferred to Phase 7 RBAC as accepted risk (T-03-06)"
metrics:
  duration_minutes: 15
  completed_date: "2026-04-14"
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 3
---

# Phase 03 Plan 02: Inter-incoming API + Incoming Doc Actions Summary

## One-liner

REST endpoints for VB liên thông list/detail and 4 incoming doc action endpoints (giao việc, nhận bàn giao, chuyển lại, hủy duyệt) with JWT-based staffId extraction and server-side validation.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Inter-incoming repository + routes | 9e67a8c | inter-incoming.repository.ts, inter-incoming.ts, server.ts |
| 2 | Incoming doc action endpoints | 7036fc2 | incoming-doc.repository.ts, incoming-doc.ts |

## What Was Built

### Task 1: Inter-incoming Repository + Routes

Created `inter-incoming.repository.ts` with:
- `InterIncomingListRow` and `InterIncomingDetailRow` row type interfaces
- `getList(unitId, filters)` — calls `edoc.fn_inter_incoming_get_list` filtered by unitId from JWT
- `getById(id)` — calls `edoc.fn_inter_incoming_get_by_id`

Created `inter-incoming.ts` route with:
- `GET /` — paginated list with keyword, status, from_date, to_date, page, page_size filters
- `GET /:id` — detail with 404 on not found

Updated `server.ts`:
- Mounted `/api/van-ban-lien-thong` with `authenticate` middleware

### Task 2: Incoming Doc Action Endpoints

Added 4 repository methods to `incoming-doc.repository.ts`:
- `createHandlingDocFromDoc(docId, docType, name, startDate, endDate, curatorIds, note, createdBy)` → `edoc.fn_handling_doc_create_from_doc`
- `handover(docId, staffId)` → `edoc.fn_incoming_doc_handover`
- `returnDoc(docId, returnedBy, reason)` → `edoc.fn_incoming_doc_return`
- `cancelApprove(docId, cancelledBy)` → `edoc.fn_incoming_doc_cancel_approve`

Added 4 POST routes to `incoming-doc.ts`:
- `POST /:id/giao-viec` — validates name + curator_ids required, returns 201 on success
- `POST /:id/nhan-ban-giao` — no body needed, returns 200
- `POST /:id/chuyen-lai` — validates reason present and min 10 chars
- `POST /:id/huy-duyet` — no body needed, staffId from JWT

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — all endpoints delegate to stored procedures. Frontend wiring is out of scope for this plan.

## Threat Flags

None — all threat mitigations from plan's threat model applied as designed.

## Self-Check: PASSED

- `e_office_app_new/backend/src/repositories/inter-incoming.repository.ts` — FOUND
- `e_office_app_new/backend/src/routes/inter-incoming.ts` — FOUND
- Commit 9e67a8c — FOUND
- Commit 7036fc2 — FOUND
- TypeScript: no errors in new/modified files
