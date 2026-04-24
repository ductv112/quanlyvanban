# Phase 4: Lịch, Danh bạ & Dashboard - Context

**Gathered:** 2026-04-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Lịch 3 loại (cá nhân, cơ quan, lãnh đạo), danh bạ điện thoại, và dashboard hoàn thiện với 4 KPI cards dữ liệu thật + 3 widget + kéo thả layout (react-grid-layout). Sprint 9 + Sprint 10. Requirements: CAL-01 → CAL-04, DASH-01 → DASH-03.

</domain>

<decisions>
## Implementation Decisions

### Lịch cá nhân (CAL-01)
- **D-01:** Dùng **Ant Design Calendar** component (month/week view).
- **D-02:** Click ngày → Popover tạo sự kiện nhanh. Double-click → Drawer chi tiết.
- **D-03:** Event cards hiển thị trên calendar với màu tùy chọn (color picker trong form).
- **D-04:** Route: `/lich/ca-nhan` trong (main) group.

### Lịch cơ quan (CAL-02)
- **D-05:** Calendar view tương tự lịch cá nhân nhưng scope unit. Chỉ admin/văn thư được tạo.
- **D-06:** Có view "Rút gọn" (list tuần) — toggle giữa calendar view và list view.
- **D-07:** Route: `/lich/co-quan`.

### Lịch lãnh đạo (CAL-03)
- **D-08:** Calendar view riêng cho lãnh đạo. Cấu hình quyền xem.
- **D-09:** Route: `/lich/lanh-dao`.

### Danh bạ (CAL-04)
- **D-10:** Table: Họ tên, Chức vụ, Phòng ban, SĐT, Email. Dùng data từ bảng staff có sẵn.
- **D-11:** Filter: Select đơn vị/phòng ban (dùng tree-utils), search by name.
- **D-12:** Route: `/danh-ba`.

### Dashboard KPI (DASH-01)
- **D-13:** 4 KPI cards gradient (reuse `.stat-card` CSS): VB đến chưa đọc, VB đi chưa duyệt, HSCV tổng, Việc sắp tới hạn.
- **D-14:** Click KPI card → navigate tới danh sách tương ứng.
- **D-15:** Dữ liệu thật từ `fn_dashboard_get_stats`.

### Dashboard Widgets (DASH-02)
- **D-16:** Widget "Văn bản mới nhận": Table 5-10 dòng gần nhất + link "Xem thêm".
- **D-17:** Widget "Việc sắp tới hạn": List (Tên, Ngày mở, Trạng thái, Tiến độ %) + link "Xem thêm".
- **D-18:** Widget "Văn bản đi mới": Table gần nhất.

### Widget Layout (DASH-03)
- **D-19:** Dùng **react-grid-layout** cho kéo thả sắp xếp widget.
- **D-20:** Lưu layout vào **localStorage** (không cần server-side lưu trữ).
- **D-21:** Responsive breakpoints: lg (1200px), md (996px), sm (768px).

### Claude's Discretion
- Calendar component customization (cell render, event popover design)
- react-grid-layout widget sizing defaults
- Dashboard widget card design details
- Lịch repeat_type options (daily, weekly, monthly, none)

</decisions>

<canonical_refs>
## Canonical References

### Sprint Specs
- `e_office_app_new/ROADMAP.md` §Sprint 9 (lines 768-810) — Lịch 3 loại + Danh bạ
- `e_office_app_new/ROADMAP.md` §Sprint 10 (lines 813-840) — Dashboard widgets + react-grid-layout

### Existing Code
- `e_office_app_new/frontend/src/app/(main)/dashboard/page.tsx` — Current dashboard (placeholder KPI cards)
- `e_office_app_new/frontend/src/lib/tree-utils.ts` — buildTree for department filter
- `e_office_app_new/frontend/src/app/globals.css` — .stat-card, .page-card CSS classes

### Project Conventions
- `e_office_app_new/docs/quy_uoc_chung.md` — Validation, naming conventions
- `.planning/codebase/CONVENTIONS.md` — Code style patterns

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Dashboard page exists with placeholder KPI cards — needs replacement with real data
- `.stat-card` CSS class from globals.css (gradient cards)
- `tree-utils.ts` — department tree for danh bạ filter
- `api.ts`, `auth.store.ts` — standard patterns
- Ant Design Calendar component available

### Integration Points
- Replace existing dashboard/page.tsx with real data widgets
- Add 3 new route groups: `/lich/*`, `/danh-ba`
- Sidebar menu entries for lịch and danh bạ

</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 04-l-ch-danh-b-dashboard*
*Context gathered: 2026-04-14*
