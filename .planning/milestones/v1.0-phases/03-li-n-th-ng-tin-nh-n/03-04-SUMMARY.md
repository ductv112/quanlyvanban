---
phase: 03-li-n-th-ng-tin-nh-n
plan: "04"
subsystem: frontend
tags: [van-ban-lien-thong, giao-viec, frontend, sprint7]
dependency_graph:
  requires: ["03-02"]
  provides: [van-ban-lien-thong-list, van-ban-lien-thong-detail, giao-viec-drawer]
  affects: [van-ban-den-detail]
tech_stack:
  added: []
  patterns: [Popconfirm-action, Modal-with-Form, Drawer-prefill, multi-select-staff]
key_files:
  created:
    - e_office_app_new/frontend/src/app/(main)/van-ban-lien-thong/page.tsx
    - e_office_app_new/frontend/src/app/(main)/van-ban-lien-thong/[id]/page.tsx
  modified:
    - e_office_app_new/frontend/src/app/(main)/van-ban-den/[id]/page.tsx
decisions:
  - "Giao viec always visible in toolbar (not conditional on approved state) — any document can be assigned work"
  - "fetchStaffOptions called on drawer open (not on page load) to avoid unnecessary API call"
  - "Huy duyet uses POST not PATCH (matching existing nhan-ban-giao and chuyen-lai endpoints pattern)"
metrics:
  duration_seconds: 615
  completed_date: "2026-04-14"
  tasks_completed: 2
  files_changed: 3
requirements: [VBLT-01, VBLT-02, VBLT-03]
---

# Phase 03 Plan 04: VB Liên thông pages + Giao việc toolbar Summary

**One-liner:** VB liên thông list (8 columns, filters) + detail (3 action buttons) pages created, plus Giao việc drawer and 4 toolbar actions added to VB đến detail page.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | VB liên thông list + detail pages | 49f27cb | van-ban-lien-thong/page.tsx, van-ban-lien-thong/[id]/page.tsx |
| 2 | Add Giao việc + action buttons to VB đến detail | f14a935 | van-ban-den/[id]/page.tsx |

## What Was Built

### Task 1: VB liên thông pages

**List page** (`/van-ban-lien-thong`):
- Table with 8 columns per UI spec: STT, Ngày nhận, Ký hiệu (bold #1B3A5C), Trích yếu (ellipsis + Tooltip), Hạn trả lời (red if overdue), Đơn vị phát hành, Người ký, Trạng thái (Tag)
- Filter row: keyword search, Loại VB Select, Trạng thái Select, RangePicker ngày nhận, reset button
- Row click navigates to `/van-ban-lien-thong/[id]`
- Status map: pending/received/processing/completed/returned/cancelled with colors
- Empty state with Vietnamese copywriting per UI spec

**Detail page** (`/van-ban-lien-thong/[id]`):
- `.detail-header` toolbar with 3 action buttons
- "Nhận bàn giao" — Popconfirm + success green (#059669) + POST `/van-ban-den/{id}/nhan-ban-giao`
- "Chuyển lại" — Modal.confirm with TextArea (required, 500 char limit) + POST `/van-ban-den/{id}/chuyen-lai`
- "Hủy duyệt" — Popconfirm danger + POST `/van-ban-den/{id}/huy-duyet`
- Info grid: 2-column layout with `.info-grid`, `.info-grid-full`, `.doc-abstract-box` CSS classes
- Overdue hạn trả lời highlighted in #DC2626

### Task 2: VB đến detail — Giao việc + 4 toolbar actions

**Giao việc Drawer:**
- ThunderboltOutlined icon, accent teal (#0891B2), always visible in toolbar
- Width 720, `rootClassName="drawer-gradient"` per project convention
- Pre-fills: `name` from `doc.abstract`, `end_date` from `doc.expired_date`
- Staff multi-select: fetches `/quan-tri/nhan-vien` on drawer open, filterOption search
- Ghi chú TextArea (optional, 500 chars)
- Footer: "Tạo và giao việc" (primary) | "Hủy" (ghost)
- POST `/api/van-ban-den/{id}/giao-viec` with { name, start_date, end_date, curator_ids, note }

**4 new toolbar buttons:**
1. Giao việc — opens drawer
2. Nhận bàn giao — Popconfirm + POST `/nhan-ban-giao`
3. Chuyển lại — Modal + Form + TextArea (required) + POST `/chuyen-lai`
4. Hủy duyệt — Popconfirm danger + POST `/huy-duyet`

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

The following API endpoints are called by these pages but may not yet have backend implementations:
- `GET /api/van-ban-lien-thong` — list endpoint
- `GET /api/van-ban-lien-thong/:id` — detail endpoint
- `POST /api/van-ban-den/:id/giao-viec` — giao việc action
- `POST /api/van-ban-den/:id/nhan-ban-giao` — nhận bàn giao action
- `POST /api/van-ban-den/:id/chuyen-lai` — chuyển lại action

These are frontend-only pages calling API endpoints that backend implements. If the backend sprint 7 endpoints are not yet deployed, these pages will show error states gracefully (message.error on catch).

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: unvalidated-curator-ids | van-ban-den/[id]/page.tsx | curator_ids array sent to server without client-side size limit — server must validate |

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| van-ban-lien-thong/page.tsx exists (250 lines, min 120) | PASS |
| van-ban-lien-thong/[id]/page.tsx exists (331 lines, min 150) | PASS |
| van-ban-den/[id]/page.tsx exists (modified) | PASS |
| 03-04-SUMMARY.md created | PASS |
| Task 1 commit 49f27cb | PASS |
| Task 2 commit f14a935 | PASS |
| TypeScript: no errors in new/modified files | PASS |
