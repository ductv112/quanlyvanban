---
phase: 02-h-s-c-ng-vi-c
plan: "07"
subsystem: frontend
tags: [hscv, bao-cao, kpi, charts, excel-export]
dependency_graph:
  requires: [02-03]
  provides: [bao-cao-page]
  affects: [ho-so-cong-viec-module]
tech_stack:
  added: []
  patterns: [ant-design-charts, exceljs-client-side-export, stat-card-pattern]
key_files:
  created:
    - e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/bao-cao/page.tsx
  modified: []
key_decisions:
  - Empty state shown for charts when no data — prevents rendering errors before API is live
  - Department Select fetches from /quan-tri/don-vi — reuses existing endpoint
  - Report tab state change triggers re-fetch automatically via useCallback dependency
metrics:
  duration_minutes: 12
  completed_date: "2026-04-14"
  tasks_completed: 1
  tasks_total: 1
  files_changed: 1
requirements: [HSCV-09, HSCV-10]
---

# Phase 02 Plan 07: KPI Dashboard and Reports Page Summary

**One-liner:** KPI dashboard with 6 gradient stat cards, Column/Pie charts via @ant-design/charts, 3 report tabs (by-unit/by-staff/by-assigner) with RangePicker filter and client-side ExcelJS export.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create KPI dashboard section with stat cards and charts | 8687025 | ho-so-cong-viec/bao-cao/page.tsx (+619 lines) |

## What Was Built

The `/ho-so-cong-viec/bao-cao` page provides management with a full reporting view:

**KPI Section (D-18):** 6 gradient stat cards in a 6-column responsive Row using `.stat-card` CSS classes. Cards: Tổng số (#1B3A5C), Chuyển kỳ trước (#475569), Kỳ này (#0891B2), Hoàn thành (#059669), Đang thực hiện (#D97706), Quá hạn % (#DC2626). Each shows Skeleton.Avatar + Skeleton.Input during loading.

**Charts Section (D-19):** Two side-by-side Cards (Col span={12}):
- `Column` bar chart (Ant Design Charts) — HSCV count per unit, color #1B3A5C, height 300px
- `Pie` donut chart (innerRadius=0.6) — status distribution (Hoàn thành/Đang thực hiện/Quá hạn), colors match status tag color map

**Report Tabs (D-20):** Ant Design Tabs type="card" with 3 tabs: Theo đơn vị (FileSearchOutlined), Theo cán bộ (UserOutlined), Theo người giao (TeamOutlined). Tab change triggers re-fetch automatically.

**Filter Row (D-21):** Unit Select (160px from /quan-tri/don-vi), RangePicker DD/MM/YYYY (220px), "Tìm kiếm" primary button, "Xuất Excel" button (color #059669).

**Table:** 6 columns — name (flex), Tổng (80px center), Hoàn thành (100px, #059669), Đang xử lý (100px, #0891B2), Quá hạn (80px, #DC2626), Tỷ lệ hoàn thành % (130px, Progress with strokeColor=#0891B2).

**Excel Export (D-22):** ExcelJS client-side workbook. Header row styled with bold white text on #1B3A5C background. Columns mapped from reportData. Dynamic tab label in first column header. Downloads as `bao-cao-hscv-YYYYMMDD.xlsx`.

## API Endpoints Consumed

| Endpoint | Purpose |
|----------|---------|
| GET /ho-so-cong-viec/thong-ke/kpi | KPI card values |
| GET /ho-so-cong-viec/thong-ke/bao-cao/theo-don-vi | By-unit report table |
| GET /ho-so-cong-viec/thong-ke/bao-cao/theo-can-bo | By-staff report table |
| GET /ho-so-cong-viec/thong-ke/bao-cao/theo-nguoi-giao | By-assigner report table |
| GET /quan-tri/don-vi | Unit Select options |

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — page renders correctly with empty states when API is not yet implemented. Charts show "Chưa có dữ liệu biểu đồ" placeholder, table shows "Không có dữ liệu thống kê". These are intentional empty states, not stubs blocking functionality.

## Threat Surface Scan

No new security-relevant surface introduced beyond what the plan's threat model already covers. API calls are scoped by JWT unitId on the backend (T-02-20 mitigated at API layer). Excel is fully client-side from already-displayed data (T-02-21 accepted).

## Self-Check: PASSED

- File exists: `e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/bao-cao/page.tsx` — FOUND (619 lines)
- Commit 8687025 exists in git log — FOUND
