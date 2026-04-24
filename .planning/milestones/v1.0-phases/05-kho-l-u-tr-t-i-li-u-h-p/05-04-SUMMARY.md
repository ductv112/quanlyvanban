---
phase: 05-kho-l-u-tr-t-i-li-u-h-p
plan: "04"
subsystem: frontend-archive
tags: [frontend, archive, kho-luu-tru, muon-tra, react, antd]
dependency_graph:
  requires: [05-02]
  provides: [archive-frontend-pages]
  affects: [frontend-routing]
tech_stack:
  added: []
  patterns:
    - Two-column layout (tree + table) following don-vi/page.tsx pattern
    - Drawer with rootClassName=drawer-gradient for all add/edit forms
    - buildTree() for hierarchical warehouse/fond data
    - Status-conditional Dropdown actions per table row
    - Checkbox list with inline search for ho-so selection in borrow drawer
key_files:
  created:
    - e_office_app_new/frontend/src/app/(main)/kho-luu-tru/page.tsx
    - e_office_app_new/frontend/src/app/(main)/kho-luu-tru/muon-tra/page.tsx
  modified: []
decisions:
  - Used buildTree() from tree-utils.ts for both warehouse and fond hierarchies
  - Drawer type discriminated via drawerType state ('warehouse' | 'fond' | 'record') to share one Drawer instance
  - Borrow request record selection uses inline checkbox list (not Transfer) for simpler UX
  - Reject action opens Modal with TextArea for rejection notice before PATCH /reject
metrics:
  duration_minutes: 35
  completed_date: "2026-04-14"
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 0
---

# Phase 5 Plan 04: Archive Frontend Pages Summary

**One-liner:** Archive module frontend — Kho/Phong tree management with CRUD Dropdowns, ho-so luu tru table, and full mượn/trả lifecycle (create, approve, reject, checkout, return).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Archive main page — Kho/Phong tree + Ho so luu tru list + Drawer CRUD | cd7529e | kho-luu-tru/page.tsx |
| 2 | Borrow/Return page — request list + create/approve/reject/checkout/return flow | 360a200 | muon-tra/page.tsx |

## What Was Built

### Task 1: kho-luu-tru/page.tsx (1038 lines)

Two-column layout:

**Left panel** — Tabs with two tree views:
- "Kho lưu trữ" tab: Ant Design Tree built from `buildTree()` on warehouse flat data from `GET /api/kho-luu-tru/kho`. Each node shows `{code} - {name}` with a `MoreOutlined` Dropdown for "Thêm kho con", "Sửa", "Xóa".
- "Phông lưu trữ" tab: Same pattern for fond data from `GET /api/kho-luu-tru/phong`. Each node shows `{fond_code} - {fond_name}`.

**Right panel** — Table of Hồ sơ lưu trữ:
- Fetches from `GET /api/kho-luu-tru/ho-so` with filters for `fond_id`, `warehouse_id`, `keyword`, pagination.
- Columns: STT, Mã hồ sơ, Tên hồ sơ, Phông, Kho, Ngày bắt đầu, Ngày hoàn thành, Số tài liệu, Thao tác.
- Clicking a tree node filters the record table automatically.

**Shared Drawer** (width 720, `rootClassName="drawer-gradient"`):
- `drawerType` state discriminates between `'warehouse'`, `'fond'`, and `'record'` form sets.
- Warehouse form: code, name, phone_number, address, description, parent_id Select.
- Fond form: fond_code, fond_name, fond_history, archives_time, paper_total, paper_digital, description, parent_id Select.
- Record form: file_code, title, fond_id, warehouse_id, in_charge_staff_id, start_date, complete_date, total_doc, maintenance, language, format, keyword, description.

### Task 2: muon-tra/page.tsx (668 lines)

**List page:**
- Status Tabs filter: Tất cả / Mới / Đã duyệt / Đã mượn / Đã trả / Từ chối
- Keyword search + fetch from `GET /api/kho-luu-tru/muon-tra`
- Status Tags rendered from `STATUS_MAP` with 5 statuses (0=Mới, 1=Đã duyệt, 2=Đã mượn, 3=Đã trả, -1=Từ chối)

**Action column (status-conditional):**
- Status 0 (Mới): Duyệt → `PATCH .../approve`, Từ chối → Modal with notice → `PATCH .../reject`, Xóa
- Status 1 (Đã duyệt): Cho mượn → confirm → `PATCH .../checkout`
- Status 2 (Đã mượn): Trả lại → confirm → `PATCH .../return`
- Status 3 / -1: No actions shown

**Create Borrow Request Drawer** (width 720, `rootClassName="drawer-gradient"`):
- Fields: name, borrow_date (DatePicker), emergency (Select: Bình thường/Khẩn), notice (TextArea)
- Ho so selection: checkbox list with inline keyword search, loads from `GET /api/kho-luu-tru/ho-so`
- Submits `POST /api/kho-luu-tru/muon-tra` with `record_ids` array

## Acceptance Criteria Verification

### kho-luu-tru/page.tsx
- [x] File exists at correct path
- [x] Contains `'use client'`
- [x] Contains `api.get('/kho-luu-tru/kho'`
- [x] Contains `api.get('/kho-luu-tru/phong'`
- [x] Contains `api.get('/kho-luu-tru/ho-so'`
- [x] Contains `buildTree`
- [x] Contains `<Tree` component
- [x] Contains `<Table` component
- [x] Contains `<Drawer` with `rootClassName="drawer-gradient"`
- [x] Contains `page-header` CSS class
- [x] Contains Vietnamese labels: Kho luu tru, Phong luu tru, Ho so luu tru
- [x] TypeScript compilation: no errors in this file

### muon-tra/page.tsx
- [x] File exists at correct path
- [x] Contains `'use client'`
- [x] Contains `api.get('/kho-luu-tru/muon-tra'`
- [x] Contains `api.patch` calls for approve, reject, checkout, return
- [x] Contains `api.post('/kho-luu-tru/muon-tra'`
- [x] Contains status Tag rendering with 5 statuses
- [x] Contains `<Drawer` for create borrow request with `rootClassName="drawer-gradient"`
- [x] Contains Vietnamese labels
- [x] TypeScript compilation: no errors in this file

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — both pages make real API calls to the backend endpoints created in plan 05-02.

## Threat Flags

No new security surface introduced. All API calls go through the authenticated `api` axios instance with JWT. The approve button (T-05-14) is correctly rendered only when `record.status === 0`, satisfying the frontend mitigation requirement. Backend SP validates status transitions.

## Self-Check

### Created files exist:
- `e_office_app_new/frontend/src/app/(main)/kho-luu-tru/page.tsx` — FOUND (1038 lines)
- `e_office_app_new/frontend/src/app/(main)/kho-luu-tru/muon-tra/page.tsx` — FOUND (668 lines)

### Commits exist:
- `cd7529e` — feat(05-04): archive main page — FOUND
- `360a200` — feat(05-04): borrow/return page — FOUND

## Self-Check: PASSED
