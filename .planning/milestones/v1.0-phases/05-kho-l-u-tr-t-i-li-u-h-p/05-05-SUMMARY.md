---
phase: 05-kho-l-u-tr-t-i-li-u-h-p
plan: "05"
subsystem: frontend
tags: [document-management, contract-management, file-upload, minio, antd]
dependency_graph:
  requires: [05-02]
  provides: [tai-lieu-page, hop-dong-page]
  affects: [frontend-navigation]
tech_stack:
  added: []
  patterns: [two-panel-tree-table, formdata-multipart-upload, status-tag-mapping, drawer-gradient]
key_files:
  created:
    - e_office_app_new/frontend/src/app/(main)/tai-lieu/page.tsx
    - e_office_app_new/frontend/src/app/(main)/hop-dong/page.tsx
  modified: []
decisions:
  - Used buildTree from tree-utils for category tree rendering with custom titleRender for context menus
  - Status delete guard: delete action only shown in contract dropdown when status=0
  - Contract detail uses separate Drawer (not inline expand) to keep table clean
  - Divider orientation prop removed (TS strict compat with AntD 6 Orientation type)
metrics:
  duration_minutes: 25
  completed_date: "2026-04-14T14:25:57Z"
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 0
---

# Phase 05 Plan 05: Document & Contract Frontend Pages Summary

**One-liner:** Document management (category tree + file upload/download) and Contract management (type filter + CRUD + attachment upload) frontend pages wired to MinIO-backed API.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Document management page | b559e36 | tai-lieu/page.tsx (687 lines) |
| 2 | Contract management page | de34fd1 | hop-dong/page.tsx (907 lines) |

## What Was Built

### Task 1: tai-lieu/page.tsx
Two-panel layout with:
- **Left panel (280px):** Document category tree built with `buildTree()` from tree-utils. Each tree node has a `titleRender` with a Dropdown context menu (Them danh muc con, Sua, Xoa). Click to filter documents by `category_id`. Search box filters tree client-side via `filterTree()`.
- **Right panel:** Document table with columns STT, Ten tai lieu, Danh muc, File (download link), Kich thuoc (formatted bytes->KB/MB), Tu khoa, Nguoi tao, Ngay tao, Thao tac.
- **Category Drawer (520px):** CRUD for categories with TreeSelect parent picker.
- **Document Drawer (720px):** Upload.Dragger for file selection; on save uses `FormData` with `Content-Type: multipart/form-data` to POST `/tai-lieu`. Edit mode: file optional.
- Download: fetches detail endpoint to get presigned URL, opens in new tab.

### Task 2: hop-dong/page.tsx
Single-column layout with:
- **Filter row:** contract_type_id Select, status Select (4 statuses), keyword search.
- **Contract table:** STT, Ma, Ten hop dong, Loai, Doi tac, Ngay ky, So tien (formatted with Intl.NumberFormat), Trang thai (Tag with STATUS_MAP), Ngay tao, Thao tac.
- **Contract type Drawer (600px):** Full CRUD table with inline add form; double-click row to edit.
- **Contract CRUD Drawer (720px):** 2-column Row/Col layout, DatePicker fields (sign_date, input_date, receive_date), currency selector, status selector.
- **Contract detail Drawer (720px):** Summary info + attachment section with Upload + upload button + attachment table (download/delete per row).
- Status-gated delete: Xoa action only shown in Dropdown when `record.status === 0`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed Divider orientation TypeScript error**
- **Found during:** Task 2 TypeScript check
- **Issue:** `orientation="left"` on AntD 6 Divider raises `Type '"left"' is not assignable to type 'Orientation | undefined'`
- **Fix:** Removed orientation prop, used plain `<Divider>` 
- **Files modified:** hop-dong/page.tsx line 871
- **Commit:** de34fd1 (included in task commit)

## Known Stubs

None. Both pages wire real API endpoints and display live data.

## Threat Flags

No new security surface beyond what was modeled. File upload enforces `maxCount={1}` on client and relies on multer 50MB limit on server (T-05-16 mitigated at API layer per 05-02). Contract list filtered by `unit_id` at API level (T-05-17 accepted).

## Self-Check: PASSED

- [x] `e_office_app_new/frontend/src/app/(main)/tai-lieu/page.tsx` exists (687 lines)
- [x] `e_office_app_new/frontend/src/app/(main)/hop-dong/page.tsx` exists (907 lines)
- [x] Commit b559e36 exists (tai-lieu page)
- [x] Commit de34fd1 exists (hop-dong page)
- [x] TypeScript check: 0 errors in new files
- [x] Pre-existing build errors (missing @ant-design/charts, @xyflow/react, react-grid-layout) are from other pages, not from this plan
