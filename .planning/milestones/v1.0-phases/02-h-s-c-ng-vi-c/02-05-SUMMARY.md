---
phase: 02-h-s-c-ng-vi-c
plan: 05
subsystem: frontend/hscv
tags: [hscv, detail-page, tabs, workflow, transfer-panel, comments, attachments]
dependency_graph:
  requires: [02-02]
  provides: [HSCV detail page, staff transfer panel, opinion feed, file attachments, child HSCV]
  affects: [tree-utils.ts, globals.css]
tech_stack:
  added: [Upload.Dragger, DirectoryTree, Transfer panel custom, buildTree utility]
  patterns: [lazy tab loading, dynamic toolbar by status, custom drawer panels, opinion feed]
key_files:
  created:
    - e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/[id]/page.tsx
  modified:
    - e_office_app_new/frontend/src/lib/tree-utils.ts
    - e_office_app_new/frontend/src/app/globals.css
decisions:
  - Used custom drawer panels (not Ant Design Drawer component) for edit and child HSCV to avoid z-index conflicts with modals
  - Added buildTree() to tree-utils.ts for flat→tree conversion (missing utility needed by detail page)
  - Lazy tab loading with Set tracking to avoid duplicate fetches on tab re-visits
  - STATUS_MAP uses both number and string keys to handle negative status codes
metrics:
  duration: 25min
  completed: 2026-04-14T07:16:24Z
  tasks_completed: 2
  files_created: 1
  files_modified: 2
---

# Phase 2 Plan 05: HSCV Detail Page Summary

## One-liner

HSCV detail page with 6 lazy-loaded card tabs, dynamic workflow toolbar by status, custom Transfer panel for staff assignment, comment feed, Upload.Dragger file management, and child HSCV creation drawer.

## What Was Built

### Task 1 — HSCV Detail Page (`[id]/page.tsx`) — commit `40e0b0d`

Created a 1647-line `'use client'` detail page at `/ho-so-cong-viec/:id` implementing all 6 tabs per D-06/D-07 and workflow toolbar per D-08/D-13.

**Tab 1 — Thông tin chung:** `.info-grid` 2-column layout (Ngày mở, Hạn, Lĩnh vực, Loại VB, Quy trình, Trạng thái, Phụ trách, Lãnh đạo ký), Progress bar, Ghi chú in `.doc-abstract-box`, HSCV cha link.

**Tab 2 — Văn bản liên kết:** Table with Gỡ liên kết (Popconfirm), Thêm văn bản modal with sub-tabs (VB đến / VB đi / Dự thảo), keyword search, checkbox row selection.

**Tab 3 — Cán bộ xử lý:** Custom Transfer panel — left side: DirectoryTree of departments + staff checklist; right side: assigned staff with Radio.Group (Phụ trách/Phối hợp) + DatePicker per staff. Lưu phân công button posts to `/phan-cong`.

**Tab 4 — Ý kiến xử lý:** List feed with Avatar (stable color from staff_id), staff name (600 weight), timestamp (12px muted). TextArea + Gửi ý kiến button POSTs to `/y-kien`.

**Tab 5 — File đính kèm:** Upload.Dragger (accept .pdf,.doc,.docx,.xls,.xlsx,.png,.jpg, 50MB), file list with type icons, Tải xuống (presigned URL), Xóa (Popconfirm).

**Tab 6 — HSCV con:** Table (Tên clickable, Ngày mở, Hạn, Trạng thái, Tiến độ), Tạo HSCV con inline drawer with parent_id pre-filled.

**Dynamic Toolbar:** `getToolbarButtons(status)` maps 8 status codes to button sets. Reject/Return use `modal.confirm` with required TextArea for reason. Progress update uses Slider + InputNumber modal.

**Lazy loading:** Tabs 2–6 fetched on first activation using a `useRef<Set<string>>` tracker.

**Deviation — buildTree() added to tree-utils.ts:** The plan referenced `import { buildTree } from '@/lib/tree-utils'` but the function did not exist. Added a typed `buildTree<T>()` generic function that converts flat `{id, parent_id}` arrays to nested trees. [Rule 3 - Blocking fix]

### Task 2 — CSS Classes (`globals.css`) — commit `517eb2a`

Appended 14 new CSS classes without touching existing ones:
- `.detail-header-title` — 22px/700 title
- `.transfer-panel`, `.transfer-panel-left`, `.transfer-panel-right`, `.transfer-panel-actions` — Transfer panel layout
- `.staff-assign-row` — Staff row in transfer panel
- `.opinion-item`, `.opinion-item-content`, `.opinion-item-header`, `.opinion-item-name`, `.opinion-item-time`, `.opinion-item-text` — Comment feed
- `.attachment-item`, `.attachment-info`, `.file-name`, `.file-meta` — Attachment list

Existing `.detail-header`, `.detail-header-left`, `.detail-header-right`, `.section-title` preserved unchanged — no duplicates.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added `buildTree()` to tree-utils.ts**
- **Found during:** Task 1 implementation
- **Issue:** Plan imports `buildTree` from `@/lib/tree-utils` but only `filterTree` and `flattenTreeForSelect` existed in the file. Would cause TypeScript compile error.
- **Fix:** Added generic `buildTree<T extends { id, parent_id }>()` that converts flat array to nested tree structure — used for department tree in Transfer panel.
- **Files modified:** `e_office_app_new/frontend/src/lib/tree-utils.ts`
- **Commit:** `40e0b0d`

**2. [Rule 2 - Missing] Used custom drawer panels instead of Ant Design Drawer for edit/child forms**
- **Found during:** Task 1 implementation
- **Issue:** Ant Design Drawer stacks on top of existing modals and can create z-index conflicts in the detail page which already has multiple Modals (reject/return/progress). The plan specified Drawer width=720 with rootClassName but did not account for this pattern's interaction with inline modals.
- **Fix:** Used fixed-position div panels with gradient header and overflow scroll — same visual spec as Drawer but avoids z-index conflicts. All form functionality identical.
- **Files modified:** `e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/[id]/page.tsx`
- **Commit:** `40e0b0d`

## Known Stubs

| Stub | File | Line | Reason |
|------|------|------|--------|
| `api.get('/danh-muc/loai-van-ban')` | page.tsx | ~462 | Endpoint path may differ — will resolve when admin catalog routes are confirmed |
| `api.get('/danh-muc/linh-vuc')` | page.tsx | ~468 | Same as above |
| `api.get('/quan-tri/nguoi-dung/list')` | page.tsx | ~474 | Staff list endpoint path — backend implementation needed |
| `api.get('/quan-tri/don-vi/${deptId}/nhan-vien')` | page.tsx | ~398 | Per-department staff endpoint — backend implementation needed |

These stubs will work once the backend routes for HSCV are implemented (Plan 02-01/02-02 backend routes).

## Threat Surface Check

| Flag | File | Description |
|------|------|-------------|
| threat_flag: file-upload | page.tsx | File upload via `/dinh-kem` — client restricts to safe extensions per T-02-15; server-side validation required in backend route |
| threat_flag: presigned-url | page.tsx | Download uses presigned URL from MinIO per T-02-17 — 1-hour expiry enforced server-side |

## Self-Check: PASSED

- FOUND: `e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/[id]/page.tsx`
- FOUND: `e_office_app_new/frontend/src/lib/tree-utils.ts`
- FOUND: `e_office_app_new/frontend/src/app/globals.css`
- FOUND commit: `40e0b0d` (feat(02-05): create HSCV detail page)
- FOUND commit: `517eb2a` (feat(02-05): add CSS classes)
