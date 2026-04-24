---
phase: 02-h-s-c-ng-vi-c
plan: 02
subsystem: backend
tags: [hscv, repository, rest-api, express, postgresql]
dependency_graph:
  requires: [02-01]
  provides: [HSCV-REST-API]
  affects: [server.ts, error-handler.ts]
tech_stack:
  added: []
  patterns: [repository-pattern, express-router, minio-upload, rawQuery-for-missing-SP]
key_files:
  created:
    - e_office_app_new/backend/src/repositories/handling-doc.repository.ts
    - e_office_app_new/backend/src/routes/handling-doc.ts
  modified:
    - e_office_app_new/backend/src/server.ts
    - e_office_app_new/backend/src/lib/error-handler.ts
decisions:
  - "Used rawQuery for attachment insert/delete because no SP exists for attachment_handling_docs CRUD"
  - "Cross-tenant guard added to GET /:id — checks doc.unit_id === JWT unitId (T-02-07)"
  - "Staff assignment limit of 50 enforced in route to mitigate T-02-08 DoS risk"
metrics:
  duration: ~15min
  completed: 2026-04-14
  tasks_completed: 2
  files_created: 2
  files_modified: 2
---

# Phase 02 Plan 02: HSCV Backend Repository + Routes Summary

**One-liner:** Express REST API for Hồ sơ công việc with 20 endpoints, MinIO attachment upload, and threat mitigations from the STRIDE register.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create handling-doc repository | 69574b8 | handling-doc.repository.ts (new) |
| 2 | Create route + mount in server.ts + update error-handler | fe4f83f | handling-doc.ts (new), server.ts, error-handler.ts |

## What Was Built

### Repository (`handling-doc.repository.ts`)

- 7 row interfaces matching the SP return shapes from `010_sprint5_handling_doc_sps.sql`
- `handlingDocRepository` const object with 21 typed methods covering all HSCV operations
- Method groups: list/count, CRUD, staff assignment, opinions, linked docs, attachments, children, status transitions (submit/approve/reject/return/complete/updateProgress/changeStatus)
- All SP parameter orders verified against migration SQL

### Route File (`handling-doc.ts`) — 20 endpoints

```
GET    /                              Paginated list with filter_type, status, keyword, dates
GET    /count-by-status               Badge counts per filter_type
POST   /                              Create HSCV
GET    /:id                           Detail (cross-tenant guard)
PUT    /:id                           Update (status=0 only, enforced by SP)
DELETE /:id                           Delete (status=0 only, enforced by SP)
GET    /:id/can-bo                    Staff assignment list
POST   /:id/phan-cong                 Assign staff (max 50)
DELETE /:id/phan-cong/:staffId        Remove staff assignment
GET    /:id/y-kien                    Opinion list
POST   /:id/y-kien                    Add opinion
GET    /:id/van-ban-lien-ket          Linked docs list
POST   /:id/lien-ket-van-ban          Link a document
DELETE /:id/lien-ket-van-ban/:linkId  Unlink document
GET    /:id/dinh-kem                  Attachment list
POST   /:id/dinh-kem                  Upload attachment (MinIO + rawQuery)
DELETE /:id/dinh-kem/:attachmentId    Delete attachment (MinIO + rawQuery)
GET    /:id/hscv-con                  Child HSCV list
PATCH  /:id/trang-thai                Status transition (submit/approve/reject/return/complete/change)
PATCH  /:id/tien-do                   Update progress 0-100
```

### server.ts

- Added `import handlingDocRoutes from './routes/handling-doc.js'`
- Uncommented + activated `app.use('/api/ho-so-cong-viec', authenticate, handlingDocRoutes)`

### error-handler.ts

- Added `handling_doc_links_handling_doc_id_doc_type_doc_id_key` → `'Văn bản này đã được liên kết'`

## Threat Mitigations Applied

| Threat | Mitigation |
|--------|-----------|
| T-02-05 Spoofing status transitions | `staffId` always extracted from `(req as AuthRequest).user`, never from body |
| T-02-06 File upload tampering | Content-type whitelist validated before MinIO upload |
| T-02-07 Cross-tenant info disclosure | GET /:id checks `doc.unit_id === JWT unitId`, returns 403 if mismatch |
| T-02-08 DoS via phan-cong | `staff_ids.length > 50` returns 400 |
| T-02-09 Status elevation | Action enum validated against `['submit','approve','reject','return','complete','change']` |

## Deviations from Plan

### Auto-added: Missing critical functionality

**1. [Rule 2 - Security] Cross-tenant guard on GET /:id**
- **Found during:** Task 2 — T-02-07 in threat model assigned `mitigate` disposition
- **Issue:** Plan noted threat but did not explicitly list the unitId check in route action
- **Fix:** Added `if (doc.unit_id !== unitId) → 403` guard after getById call
- **Files modified:** `handling-doc.ts`
- **Commit:** fe4f83f

**2. [Rule 2 - Security] Content-type whitelist for file uploads**
- **Found during:** Task 2 — T-02-06 assigned `mitigate` disposition
- **Fix:** Added `allowedTypes` array check before MinIO upload; returns 400 for unsupported types
- **Files modified:** `handling-doc.ts`
- **Commit:** fe4f83f

**3. [Rule 1 - Bug] rawQuery used for attachment CRUD (no SP exists)**
- **Found during:** Task 2 — `fn_attachment_handling_*` SPs do not exist in migration SQL
- **Fix:** Used `rawQuery` for INSERT and DELETE on `edoc.attachment_handling_docs` directly
- **Files modified:** `handling-doc.ts`
- **Commit:** fe4f83f

## Known Stubs

None — all repository methods map to real SPs and all route handlers call real data sources.

## Self-Check: PASSED
