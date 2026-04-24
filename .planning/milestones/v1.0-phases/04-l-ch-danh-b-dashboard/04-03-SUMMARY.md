---
phase: 04-l-ch-danh-b-dashboard
plan: "03"
subsystem: frontend/dashboard
tags: [dashboard, react-grid-layout, kpi-cards, widgets, drag-drop]
dependency_graph:
  requires: ["04-02"]
  provides: ["dashboard-live-data", "draggable-widgets"]
  affects: ["frontend/dashboard"]
tech_stack:
  added: ["react-grid-layout"]
  patterns: ["useContainerWidth hook", "ResponsiveLayouts type", "localStorage layout persistence"]
key_files:
  created: []
  modified:
    - e_office_app_new/frontend/src/app/(main)/dashboard/page.tsx
decisions:
  - "Used react-grid-layout v2 hooks API (useContainerWidth + width prop) instead of legacy WidthProvider HOC — required by new ESM package exports"
  - "dragConfig={{ handle }} replaces deprecated draggableHandle prop in new react-grid-layout API"
  - "Widgets fetch data independently — each has its own loading/error state for resilience"
metrics:
  duration: "~25 minutes"
  completed: "2026-04-14"
  tasks_completed: 1
  tasks_total: 1
  files_changed: 3
---

# Phase 04 Plan 03: Dashboard Live KPI Cards + Draggable Widgets Summary

**One-liner:** Replaced hardcoded placeholder dashboard with live API-driven KPI cards and 3 draggable widgets using react-grid-layout v2 hooks API with localStorage layout persistence.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Install react-grid-layout + rewrite dashboard | 8db81bd | dashboard/page.tsx, package.json, package-lock.json |

## What Was Built

### KPI Cards (4 stat cards)
- Fetches `GET /api/dashboard/stats` on mount via `useEffect`
- Displays 4 gradient cards: Văn bản đến chưa đọc (navy), Văn bản đi chưa duyệt (teal), Hồ sơ công việc (green), Việc sắp tới hạn (amber)
- Real counts from API response — no hardcoded values
- Click navigates: VB đến → `/van-ban-den`, VB đi → `/van-ban-di`, HSCV → `/ho-so-cong-viec`
- `Skeleton.Button` loading state while fetching
- Retains welcome header "Xin chào, {user.fullName}"

### Widget 1 — Văn bản mới nhận
- Fetches `GET /api/dashboard/recent-incoming?limit=5`
- Ant Design Table: Số hiệu, Trích yếu (ellipsis), Ngày nhận (dayjs format), Độ khẩn (Tag with color)
- Drag handle icon (HolderOutlined) in card title
- "Xem thêm" → `/van-ban-den`

### Widget 2 — Việc sắp tới hạn
- Fetches `GET /api/dashboard/upcoming-tasks?limit=5`
- Ant Design List: title, status Tag, Progress bar (progress_percent), deadline date
- "Xem thêm" → `/ho-so-cong-viec`

### Widget 3 — Văn bản đi mới
- Fetches `GET /api/dashboard/recent-outgoing?limit=5`
- Ant Design Table: Số hiệu, Trích yếu, Ngày gửi, Loại VB (Tag)
- "Xem thêm" → `/van-ban-di`

### react-grid-layout Configuration
- `useContainerWidth` hook provides `width` and `containerRef` (v2 API)
- Breakpoints: `{ lg: 1200, md: 996, sm: 768 }`
- Cols: `{ lg: 12, md: 10, sm: 6 }`, rowHeight: 60
- `dragConfig={{ handle: '.widget-drag-handle' }}` — drag via title icon
- `onLayoutChange` saves to `localStorage['dashboard-layout']`
- On mount, reads saved layout from localStorage; falls back to defaults

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] react-grid-layout v2 ESM exports WidthProvider differently**
- **Found during:** Task 1 (build error)
- **Issue:** Plan specified `WidthProvider(Responsive)` pattern but react-grid-layout v2 ESM build does not export `WidthProvider` or `Responsive` separately
- **Fix:** Used `ResponsiveGridLayout` direct import + `useContainerWidth` hook to provide `width` prop
- **Files modified:** dashboard/page.tsx
- **Commit:** 8db81bd

**2. [Rule 1 - Bug] draggableHandle prop renamed in v2**
- **Found during:** Task 1 (TypeScript error)
- **Issue:** `draggableHandle` prop does not exist on `ResponsiveGridLayoutProps` in v2
- **Fix:** Replaced with `dragConfig={{ handle: '.widget-drag-handle' }}`
- **Files modified:** dashboard/page.tsx
- **Commit:** 8db81bd

**3. [Rule 1 - Bug] Layout type requires readonly LayoutItem[]**
- **Found during:** Task 1 (TypeScript error)
- **Issue:** State typed as `{ [key: string]: Layout[] }` incompatible with `ResponsiveLayouts`
- **Fix:** Used `ResponsiveLayouts` type from react-grid-layout for state and callback
- **Files modified:** dashboard/page.tsx
- **Commit:** 8db81bd

## Known Stubs

None — all 3 widgets and 4 KPI cards fetch from real API endpoints. Data displays empty-state messages when API returns no data (not placeholder text).

## Threat Flags

None — no new network endpoints or auth paths introduced. Frontend only consumes existing `/api/dashboard/*` endpoints created in Plan 02.

## Self-Check: PASSED

- [x] `e_office_app_new/frontend/src/app/(main)/dashboard/page.tsx` — exists, 516 lines (> 150 minimum)
- [x] Commit 8db81bd — verified in git log
- [x] Build `npx next build` — completed successfully without errors
- [x] Pattern check: 10 matches for react-grid-layout, dashboard/stats, recent-incoming, upcoming-tasks, recent-outgoing, localStorage
