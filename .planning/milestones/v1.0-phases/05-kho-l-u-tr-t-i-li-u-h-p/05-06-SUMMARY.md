---
phase: 05-kho-l-u-tr-t-i-li-u-h-p
plan: "06"
subsystem: frontend/cuoc-hop
tags: [meeting, voting, socket-io, charts, sidebar]
dependency_graph:
  requires: [05-03]
  provides: [cuoc-hop-pages, phase5-sidebar]
  affects: [MainLayout.tsx]
tech_stack:
  added: ["@ant-design/charts (installed from package.json)"]
  patterns: [Socket.IO realtime voting, @ant-design/charts Column/Pie]
key_files:
  created:
    - e_office_app_new/frontend/src/app/(main)/cuoc-hop/page.tsx
    - e_office_app_new/frontend/src/app/(main)/cuoc-hop/[id]/page.tsx
    - e_office_app_new/frontend/src/app/(main)/cuoc-hop/thong-ke/page.tsx
  modified:
    - e_office_app_new/frontend/src/components/layout/MainLayout.tsx
decisions:
  - "@ant-design/charts was in package.json but not installed — ran npm install to resolve (pre-existing gap)"
  - "Socket.IO voting uses getSocket()/initSocket() from lib/socket.ts to reuse existing connection"
metrics:
  duration: "~25 minutes"
  completed: "2026-04-14"
  tasks_completed: 2
  files_changed: 4
---

# Phase 05 Plan 06: Meeting Frontend Pages Summary

**One-liner:** Meeting list+detail+stats pages with Socket.IO realtime voting, @ant-design/charts, and full Phase 5 sidebar navigation wired in.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Meeting list page + room/type management + create/approve flow | b521647 | cuoc-hop/page.tsx |
| 2 | Meeting detail + stats + sidebar + CSS | c119721 | cuoc-hop/[id]/page.tsx, thong-ke/page.tsx, MainLayout.tsx |

## What Was Built

### Task 1: Meeting List Page (`cuoc-hop/page.tsx`)
- Meeting schedule table with filters: room, approved status, date range, keyword
- **Room Management Drawer** (width 600): CRUD for meeting rooms with sub-modal form
- **Meeting Type Drawer** (width 600): CRUD for meeting types with sub-modal form
- **Create/Edit Meeting Drawer** (width 720, drawer-gradient): 2-column form with all fields (name, room, type, dates, times, master/secretary staff pickers, online link, component, content)
- Actions dropdown: View detail, Edit, Approve (PATCH /approve), Reject (Modal with rejection reason, PATCH /reject), Delete (only if unapproved)
- Status tags: Approved (chưa/đã/từ chối), Meeting Status (chưa/đang/đã/hủy)

### Task 2: Meeting Detail Page (`cuoc-hop/[id]/page.tsx`)
- **4 Tabs:** Thông tin chung, Thành viên, Tài liệu, Biểu quyết
- **Thông tin chung:** Descriptions grid with all meeting fields, approve/reject/start/end actions
- **Thành viên:** Staff table with role tags, add via multi-select modal (user_type: thành viên/chủ tọa/thư ký), remove individual staff
- **Tài liệu:** File list with download/delete, Upload.Dragger for file upload
- **Biểu quyết:** Vote questions list, add question modal, add answer modal, start/stop voting controls, Radio.Group (single) or Checkbox.Group (multi) for casting votes, Progress bars for results display
- **Socket.IO realtime:** Listens to `vote_update` and `vote_status_change` events, auto-refreshes questions and results

### Task 2: Statistics Page (`cuoc-hop/thong-ke/page.tsx`)
- Year selector (current year ± 4 years)
- Summary stat cards: Total, Approved, Pending, Rejected
- **3 Charts** using `@ant-design/charts`:
  1. Column chart: meetings by month (all 12 months shown)
  2. Pie chart: meetings by room
  3. Column chart: meetings by meeting type
- Colors: primary #1B3A5C, accent #0891B2

### Task 2: MainLayout.tsx — Phase 5 Sidebar
Added 4 new menu groups after `/danh-ba`:
- **Kho lưu trữ** (DatabaseOutlined) with children: Danh mục kho/phông (`/kho-luu-tru`), Mượn/trả hồ sơ (`/kho-luu-tru/muon-tra`)
- **Tài liệu** (FileTextOutlined) — `/tai-lieu`
- **Hợp đồng** (AuditOutlined) — `/hop-dong`
- **Cuộc họp** (TeamOutlined) with children: Danh sách (`/cuoc-hop`), Thống kê (`/cuoc-hop/thong-ke`)
- Breadcrumb map updated for all new routes

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Installed @ant-design/charts missing from node_modules**
- **Found during:** Task 2 — TypeScript reported `Cannot find module '@ant-design/charts'`
- **Issue:** Package was listed in `package.json` (^2.6.7) but not installed in `node_modules/` — same issue affecting `ho-so-cong-viec/bao-cao/page.tsx` (pre-existing)
- **Fix:** Ran `npm install @ant-design/charts` in frontend directory
- **Files modified:** `package-lock.json` (auto-updated)
- **Commit:** c119721

**2. [Rule 2 - Missing icons] Added AuditOutlined and DatabaseOutlined imports**
- **Found during:** Task 2 — MainLayout needed new icons for Hợp đồng and Kho lưu trữ
- **Fix:** Added `DatabaseOutlined` and `AuditOutlined` to existing icon imports in MainLayout.tsx
- **Files modified:** `e_office_app_new/frontend/src/components/layout/MainLayout.tsx`

## Checkpoint: Human Verification Required

**This plan has `autonomous: false` — Task 3 is a human verification checkpoint.**

After starting backend (`cd e_office_app_new/backend && npm run dev`) and frontend (`cd e_office_app_new/frontend && npm run dev`):

1. Open http://localhost:3000, login
2. **Sidebar** should show: Kho lưu trữ (with sub-items), Tài liệu, Hợp đồng, Cuộc họp (with sub-items)
3. **Cuộc họp** → Meeting list with filter row, "Đăng ký cuộc họp" button, "Phòng họp" button, "Loại cuộc họp" button
4. **Cuộc họp/[id]** → 4 tabs: Thông tin chung, Thành viên, Tài liệu, Biểu quyết
5. **Cuộc họp/thống kê** → Year selector + 3 charts
6. **Realtime voting:** Open meeting detail while a vote is active — chart should update when someone votes

## Threat Surface Scan

| Flag | File | Description |
|------|------|-------------|
| threat_flag: vote_spoofing | cuoc-hop/[id]/page.tsx | Vote UI sends answer_id — backend must extract staff_id from JWT (T-05-18, mitigate disposition confirmed) |

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| cuoc-hop/page.tsx exists | FOUND |
| cuoc-hop/[id]/page.tsx exists | FOUND |
| cuoc-hop/thong-ke/page.tsx exists | FOUND |
| 05-06-SUMMARY.md exists | FOUND |
| Commit b521647 exists | FOUND |
| Commit c119721 exists | FOUND |
| api.get('/cuoc-hop') in list page | PASS |
| api.get('/cuoc-hop/phong-hop') in list page | PASS |
| api.get('/cuoc-hop/loai-cuoc-hop') in list page | PASS |
| api.post('/cuoc-hop') in list page | PASS |
| api.patch in list page (approve/reject) | PASS |
| socket.on('vote_update') in detail page | PASS |
| @ant-design/charts Column + Pie in stats page | PASS |
| kho-luu-tru in MainLayout sidebar | PASS |
| cuoc-hop in MainLayout sidebar | PASS |
| Next.js build succeeds | PASS |
