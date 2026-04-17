---
phase: 05-kho-l-u-tr-t-i-li-u-h-p
plan: "02"
subsystem: backend-api
tags: [backend, repository, routes, archive, documents, contracts, minio, esto, iso, cont]
dependency_graph:
  requires:
    - esto.fn_* (22 functions from 05-01)
    - iso.fn_* (9 functions from 05-01)
    - cont.fn_* (10 functions from 05-01)
  provides:
    - archiveRepository
    - documentRepository
    - contractRepository
    - GET/POST/PUT/DELETE /api/kho-luu-tru/kho
    - GET/POST/PUT/DELETE /api/kho-luu-tru/phong
    - GET/POST/PUT/DELETE /api/kho-luu-tru/ho-so
    - GET/POST/PATCH /api/kho-luu-tru/muon-tra (+ approve/reject/checkout/return)
    - GET/POST/PUT/DELETE /api/tai-lieu/danh-muc
    - GET/POST/PUT/DELETE /api/tai-lieu
    - GET/POST/PUT/DELETE /api/hop-dong/loai
    - GET/POST/PUT/DELETE /api/hop-dong
    - GET/POST/DELETE /api/hop-dong/:id/dinh-kem
  affects:
    - e_office_app_new/backend/src/lib/error-handler.ts (6 new constraint mappings)
tech_stack:
  added: []
  patterns:
    - Repository pattern with callFunction/callFunctionOne wrapping stored procedures
    - MinIO file upload via multer memoryStorage + uploadFile() utility
    - UUID-based path namespacing in MinIO (tai-lieu/{uuid}/{filename}, hop-dong/{contractId}/{uuid}/{filename})
    - AuthRequest JWT extraction for unitId (multi-tenancy) and staffId (ownership)
    - handleDbError centralized error mapping
key_files:
  created:
    - e_office_app_new/backend/src/repositories/archive.repository.ts
    - e_office_app_new/backend/src/repositories/document.repository.ts
    - e_office_app_new/backend/src/repositories/contract.repository.ts
    - e_office_app_new/backend/src/routes/archive.ts
    - e_office_app_new/backend/src/routes/document.ts
    - e_office_app_new/backend/src/routes/contract.ts
  modified:
    - e_office_app_new/backend/src/lib/error-handler.ts
decisions:
  - "Contract attachments use rawQuery INSERT (no SP exists in 017 migration) — consistent with plan intent to route all data access via SP where SP exists"
  - "getBorrowRequestById returns array (not single row) because SP LEFT JOINs borrow_request_records produces multiple rows per request"
  - "Document file upload cleans up MinIO on DB failure to prevent orphaned objects"
metrics:
  completed_date: "2026-04-14"
  tasks_completed: 2
  tasks_total: 2
  files_created: 6
  files_modified: 1
---

# Phase 5 Plan 02: Backend API (Archive, Documents, Contracts) Summary

**One-liner:** Three repository files + three route files wiring archive/document/contract stored procedures to REST API endpoints — 20 archive methods/endpoints, 8 document methods/9 endpoints, 10 contract methods/11 endpoints, error-handler updated with 6 new constraint names.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Archive repository + routes (warehouse, fond, record, borrow) | ed270d2 | archive.repository.ts, routes/archive.ts |
| 2 | Document + Contract repositories + routes + error-handler update | 8304b87 | document.repository.ts, contract.repository.ts, routes/document.ts, routes/contract.ts, error-handler.ts |

## What Was Built

### Task 1 — Archive (esto schema)

**archive.repository.ts** — 20 methods:
- Warehouse: `getWarehouseTree`, `getWarehouseById`, `createWarehouse`, `updateWarehouse`, `deleteWarehouse`
- Fond: `getFondTree`, `getFondById`, `createFond`, `updateFond`, `deleteFond`
- Record: `getRecordList` (paginated), `getRecordById`, `createRecord`, `updateRecord`, `deleteRecord`
- Borrow: `getBorrowRequestList`, `getBorrowRequestById`, `createBorrowRequest`, `approveBorrowRequest`, `rejectBorrowRequest`, `checkoutBorrowRequest`, `returnBorrowRequest`

**routes/archive.ts** — 20 endpoints under `/api/kho-luu-tru`:
- `/kho` (GET tree, GET by id, POST, PUT, DELETE)
- `/phong` (GET tree, GET by id, POST, PUT, DELETE)
- `/ho-so` (GET list, GET by id, POST, PUT, DELETE)
- `/muon-tra` (GET list, GET by id, POST create, PATCH approve/reject/checkout/return)

### Task 2 — Documents + Contracts (iso/cont schemas)

**document.repository.ts** — 8 methods:
- Categories: `getCategoryTree`, `createCategory`, `updateCategory`, `deleteCategory`
- Documents: `getDocumentList`, `getDocumentById`, `createDocument`, `updateDocument`, `deleteDocument`

**routes/document.ts** — 9 endpoints under `/api/tai-lieu`:
- `/danh-muc` (GET tree, POST, PUT/:id, DELETE/:id)
- `/` (GET list, GET/:id, POST with MinIO upload, PUT/:id with optional re-upload, DELETE/:id soft delete)

**contract.repository.ts** — 10 methods + rawQuery attachment helpers:
- Contract types: `getContractTypeList`, `createContractType`, `updateContractType`, `deleteContractType`
- Contracts: `getContractList`, `getContractById`, `createContract`, `updateContract`, `deleteContract`
- Attachments: `getContractAttachments`, `addContractAttachment` (rawQuery), `deleteContractAttachment` (rawQuery)

**routes/contract.ts** — 11 endpoints under `/api/hop-dong`:
- `/loai` (GET, POST, PUT/:id, DELETE/:id)
- `/` (GET list, GET/:id, POST, PUT/:id, DELETE/:id)
- `/:id/dinh-kem` (GET, POST with MinIO upload, DELETE/:attachmentId)

**error-handler.ts** — 6 new constraint mappings added:
- `uq_warehouses_code`, `uq_fonds_code` (esto)
- `uq_doc_categories_code` (iso)
- `uq_contract_types_code` (cont)
- `uq_rooms_code`, `uq_room_schedule_staff` (edoc — pre-added for Plan 03)

## Threat Model Mitigations Applied

| Threat ID | Mitigation Applied |
|-----------|-------------------|
| T-05-06 | `upload.single('file')` with Multer 50MB limit on all document/attachment upload endpoints |
| T-05-07 | All list queries pass `unitId` from JWT — `getRecordList`, `getBorrowRequestList`, `getDocumentList`, `getContractList` all filter by unit |
| T-05-08 | `created_user_id` / `createdUserId` always sourced from `(req as AuthRequest).user.staffId` — never from `req.body` |
| T-05-09 | Contract attachment upload uses same multer middleware with 50MB limit |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing SP] Contract attachment insert uses rawQuery**
- **Found during:** Task 2 — `cont.fn_contract_add_attachment` does not exist in migration 017
- **Issue:** Plan specified repository method but no stored procedure was created for this action
- **Fix:** Used `rawQuery` directly for `INSERT INTO cont.contract_attachments` and `DELETE ... RETURNING`. This is the established escape-hatch pattern in the codebase (`rawQuery` defined in query.ts for exactly this purpose).
- **Files modified:** contract.repository.ts

**2. [Rule 2 - Type Safety] getBorrowRequestById returns array**
- **Found during:** Task 1 — SP `esto.fn_borrow_request_get_by_id` LEFT JOINs `borrow_request_records` producing multiple rows (one per record in the borrow request)
- **Fix:** Returns `BorrowRequestDetailRow[]` instead of single row, route returns the full array. This accurately represents the SP's output shape.
- **Files modified:** archive.repository.ts, routes/archive.ts

## Known Stubs

None — all repository methods call actual stored procedures or rawQuery with correct parameters. No placeholder data or TODO markers.

## Self-Check

### Files Exist
- `e_office_app_new/backend/src/repositories/archive.repository.ts` — FOUND
- `e_office_app_new/backend/src/repositories/document.repository.ts` — FOUND
- `e_office_app_new/backend/src/repositories/contract.repository.ts` — FOUND
- `e_office_app_new/backend/src/routes/archive.ts` — FOUND
- `e_office_app_new/backend/src/routes/document.ts` — FOUND
- `e_office_app_new/backend/src/routes/contract.ts` — FOUND
- `e_office_app_new/backend/src/lib/error-handler.ts` (modified) — FOUND

### Acceptance Criteria Verified
- archiveRepository exported: YES
- `esto.fn_warehouse_get_tree` called: YES
- `esto.fn_record_get_list` called: YES
- `esto.fn_borrow_request_approve` called: YES
- `router.get('/kho'` in archive.ts: YES
- `router.post('/muon-tra'` in archive.ts: YES
- `router.patch('/muon-tra/:id/approve'` in archive.ts: YES
- `router.patch('/muon-tra/:id/return'` in archive.ts: YES
- documentRepository exported: YES
- `iso.fn_document_get_list` called: YES
- contractRepository exported: YES
- `cont.fn_contract_get_list` called: YES
- `router.post('/')` + `upload.single` in document.ts: YES
- `router.get('/loai'` in contract.ts: YES
- `uq_warehouses_code` in error-handler.ts: YES
- `uq_rooms_code` in error-handler.ts: YES
- TypeScript compiles without errors in new files: YES (pre-existing errors in handling-doc-report.ts and workflow.ts unrelated)

### Commits Verified
- ed270d2 — feat(05-02): archive repository + routes: FOUND
- 8304b87 — feat(05-02): document + contract repositories, routes, error-handler update: FOUND

## Self-Check: PASSED
