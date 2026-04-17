---
phase: 02-h-s-c-ng-vi-c
plan: "04"
subsystem: frontend
tags: [hscv, list-page, filter-tabs, crud-drawer, table, next-js]
dependency_graph:
  requires: [02-02]
  provides: [HSCV list page UI at /ho-so-cong-viec]
  affects: [ho-so-cong-viec/page.tsx]
tech_stack:
  added: []
  patterns:
    - Tabs with Badge counts for status filtering
    - Progress column in table with strokeColor
    - Overdue date detection with ExclamationCircleOutlined
key_files:
  created:
    - e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/page.tsx
  modified: []
decisions:
  - Used modal.confirm (not Popconfirm) for delete per CLAUDE.md pattern
  - STATUS_MAP keys are numbers matching DB status values (0,1,2,3,4,-1,-2)
  - fetchOptions uses Promise.all with .catch per-request to prevent single failure blocking all dropdowns
  - Skeleton shown on initialLoading, Table loading prop for subsequent fetches
metrics:
  duration: ~10 minutes
  completed: 2026-04-14
  tasks_completed: 1
  tasks_total: 1
  files_changed: 1
---

# Phase 02 Plan 04: HSCV List Page Summary

HSCV list page (`/ho-so-cong-viec`) with 10 filter tabs + badge counts, paginated data table with progress/overdue indicators, and 720px Drawer for create/edit CRUD operations.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create HSCV list page with filter tabs, table, and CRUD drawer | b59d6c5 | e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/page.tsx |

## What Was Built

**File:** `e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/page.tsx` (713 lines)

### Filter Tabs (D-01)
- 10 tabs: Tất cả, Tôi tạo, Bị từ chối, Trả về bổ sung, Chưa XL phụ trách, Chưa XL phối hợp, Trình ký, Đang giải quyết, Đề xuất hoàn thành, Đã hoàn thành
- Badge counts from `GET /ho-so-cong-viec/count-by-status`
- Active tab badge color `#0891B2`, inactive `#94A3B8`

### Table Columns (D-03)
9 columns: STT, Tên hồ sơ (clickable link to detail), Ngày mở, Hạn giải quyết (overdue highlight), Trạng thái (Tag), Phụ trách, Lãnh đạo ký, Tiến độ (Progress), Thao tác (Dropdown)

### Filter Row
Input search (240px), Select Lĩnh vực (160px), Select Đơn vị (160px), RangePicker (220px), Tìm kiếm + Đặt lại buttons

### Drawer (D-04, D-05)
- `width={720}`, `rootClassName="drawer-gradient"`, `validateTrigger="onSubmit"`
- 10 form fields in 2-column layout
- End date validation: must be >= start date (checked before submit)
- POST `/ho-so-cong-viec` for create, PUT `/ho-so-cong-viec/:id` for edit

### Delete Pattern
`Modal.confirm` with `okType="danger"`, `okText="Xóa"`, `cancelText="Hủy bỏ"` per CLAUDE.md

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

The following API endpoints are called but do not yet have confirmed backend implementations. The frontend is wired correctly; functionality depends on backend sprint:

| Stub | File | Reason |
|------|------|--------|
| GET /ho-so-cong-viec | page.tsx | Backend endpoint not yet verified in this phase |
| POST /ho-so-cong-viec | page.tsx | Backend endpoint not yet verified in this phase |
| GET /ho-so-cong-viec/count-by-status | page.tsx | Backend endpoint not yet verified |
| GET /quan-tri/quy-trinh | page.tsx | Workflow endpoint may not exist yet |

These stubs do not prevent the plan's goal (UI structure) from being achieved — the page renders correctly and makes the correct API calls.

## Threat Flags

No new threat surface introduced beyond what is in the plan's threat model. The page uses the shared `api` axios instance with JWT interceptor (T-02-13 mitigated).

## Self-Check: PASSED

- [x] `e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/page.tsx` — FOUND (713 lines)
- [x] Commit b59d6c5 — FOUND
- [x] All acceptance criteria verified via grep
