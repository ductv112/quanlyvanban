---
phase: 37-admin-ui-catalog-go-live
plan: 04
subsystem: frontend
tags: [frontend, ui, admin, lgsp, inter-organizations, crud, sync, catalog, phase-37]

# Dependency graph
requires:
  - phase: 37-admin-ui-catalog-go-live
    plan: 01
    provides: 4 admin CRUD endpoints /api/admin/inter-organizations (GET list paginated + POST/PUT/DELETE) + interOrganizationRepository.listForAdmin/createForAdmin/updateForAdmin/deleteForAdmin
  - phase: 37-admin-ui-catalog-go-live
    plan: 02
    provides: POST /api/admin/inter-organizations/sync endpoint (lookup 1 DN is_active=TRUE -> svc.syncOrganizations -> upsert)
provides:
  - "REWRITE page /lgsp/co-quan thanh full CRUD admin: Table list + filter 3-state + search + Drawer Add/Edit + Popconfirm Delete + Modal confirm Sync"
  - "Pattern wire 5 endpoint admin namespace (4 CRUD + 1 sync)"
  - "Filter is_active 3-state mapping UI: '' (Tat ca) / 'true' (Da xac nhan) / 'false' (Tu dang ky)"
  - "Modal sync result inline (total/created/updated/failed) thay vi toast ngan goi"
affects: [37-06-frontend-menu-unhide-retry]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Admin role guard inline tai entry (useAuthStore.user.isAdmin || roles.includes('Quan tri he thong')) -> conditional render button CRUD + cot Hanh dong (KHONG redirect, non-admin van xem list)"
    - "Filter state 3-state union type ('' | 'true' | 'false') + Select options array -> backend nhan is_active query param string 'true'/'false' (route parse line 211 admin-lgsp.ts)"
    - "Search controlled input 2-state: searchInput (typing) -> setSearch (commit on Enter / button Tim / clear) -> useEffect debounce free + KHONG refetch moi keystroke"
    - "Modal.confirm cho destructive bulk action (sync) voi inline content giai thich precondition -> Modal.success inline ket qua cu the (total/created/updated/failed) tot hon toast"
    - "Drawer 720 AntD 6 size= (KHONG width=) + rootClassName='drawer-gradient' + extra footer Luu/Huy + Form validateTrigger='onSubmit'"
    - "Conditional column actions (...isAdmin ? [{...}] : []) -> non-admin KHONG thay cot Hanh dong"
    - "setBackendFieldError map specific 23505 message 'Ma co quan da ton tai' -> inline field error tren field code"
    - "code disabled khi edit (UNIQUE constraint + FK tham chieu tu outgoing_doc_recipients)"

key-files:
  created:
    - .planning/phases/37-admin-ui-catalog-go-live/37-04-SUMMARY.md
  modified:
    - e_office_app_new/frontend/src/app/(main)/lgsp/co-quan/page.tsx (REWRITE 184 -> 689 lines)

key-decisions:
  - "Admin role guard inline thay vi redirect (mirror Plan 37-03 pattern) -> non-admin van xem list cho phep transparent visibility, chi an button CRUD + cot Hanh dong"
  - "Sync UX flow: Modal.confirm voi precondition warning -> Modal.success inline ket qua chi tiet (total/created/updated/failed) -> KHONG dung toast ngan vi admin can biet so luong dong bo cu the"
  - "Search controlled 2-state (searchInput controlled + search committed) -> tim chinh xac khi user xong typing (Enter / nut Tim / clear) thay vi debounce -> tranh refetch moi keystroke"
  - "Filter useEffect reset ve page 1 khi search/filter doi -> tranh ket qua trong khi filter mat (page=2 -> tu nhien data filter chi co page 1)"
  - "Field code disabled khi edit -> UNIQUE constraint + FK tham chieu tu outgoing_doc_recipients (Plan 37-01 deleteForAdmin SQLSTATE 23503 handler chung minh FK ton tai)"
  - "Form payload always full fields (KHONG partial like /cau-hinh) -> backend PUT updateForAdmin partial logic da skip undefined fields, nhung frontend gui full giup explicit + de debug"
  - "Tooltip 'Tu dang ky' tag giai thich UX cho admin biet ly do row chua active (Phase 35 auto-INSERT)"

patterns-established:
  - "Admin catalog page pattern: list + filter status 3-state + search + Drawer CRUD + Popconfirm Delete + button bulk sync voi Modal confirm/result -> reusable cho future admin catalog (department types, signers...)"
  - "Sync button UX: Modal.confirm precondition warning -> async API -> Modal.success inline result counts -> KHONG goi de bao sync"

requirements-completed: [LGSP-UI-05, LGSP-UI-06]

# Metrics
duration: ~7 min
completed: 2026-05-21
---

# Phase 37 Plan 04: Frontend Admin Catalog Page /lgsp/co-quan Summary

**REWRITE page /lgsp/co-quan (184 -> 689 lines) — Phase 18 read-only stub -> full CRUD admin: Table + filter 3-state (Tat ca / Da xac nhan / Tu dang ky) + search + Drawer Add/Edit + Popconfirm Delete + button "Dong bo tu truc LGSP" voi Modal confirm/result — wire 5 endpoint admin namespace tu Plan 37-01/02**

## Performance

- **Duration:** ~7 min
- **Started:** 2026-05-21
- **Completed:** 2026-05-21
- **Tasks:** 2/2 (Task 2 verification-only, no commit)
- **Files modified:** 1 (REWRITE)

## Accomplishments

- **REWRITE** `e_office_app_new/frontend/src/app/(main)/lgsp/co-quan/page.tsx` (Phase 18 184 dòng → Phase 37 689 dòng):
  - Admin role guard inline (`useAuthStore` — check `user?.isAdmin || roles.includes('Quản trị hệ thống')`) → non-admin KHÔNG thấy button CRUD + cột Hành động (vẫn xem được list)
  - Header section: title "Cơ quan liên thông" với icon `BankOutlined` + Space buttons (admin only): "Thêm mới" + "Đồng bộ từ trục LGSP"
  - Filter row: Row gutter responsive với 3 cột:
    - Input search prefix `SearchOutlined` (controlled `searchInput` + commit on Enter/clear → `setSearch`)
    - Select 3-state: Tất cả / Đã xác nhận / Tự đăng ký
    - Space: Button "Tìm" + Tooltip "Làm mới" icon button
  - Table 7 column (8 nếu admin):
    - Mã cơ quan (monospace bold, width 160)
    - Tên cơ quan (ellipsis) + Tag LGSP nếu `lgsp_organ_id` non-null
    - Trạng thái: Tag green "Đã xác nhận" / Tooltip Tag orange "Tự đăng ký" (giải thích Phase 35 auto-INSERT)
    - Địa chỉ (ellipsis), Email (ellipsis), Điện thoại
    - Ngày tạo (dayjs DD/MM/YYYY HH:mm)
    - Hành động (admin only): Sửa + Popconfirm Xóa
  - Pagination 20/page, showSizeChanger [20/50/100], showTotal "Tổng N cơ quan"
  - Drawer 720 (AntD 6 `size={720}`, `rootClassName="drawer-gradient"`) "Thêm/Sửa cơ quan ngoài":
    - Row 2 col: Mã cơ quan (disabled khi edit, maxLength=100) + Mã LGSP (lgsp_organ_id, maxLength=100, hint extra)
    - Tên cơ quan (required, maxLength=500)
    - Địa chỉ TextArea rows=2 showCount maxLength=500
    - Row 2 col: Email (type=email validator, maxLength=200) + Điện thoại (pattern phone validator, maxLength=50)
    - Switch is_active "Đã xác nhận" / "Tự đăng ký" với extra hint giải thích semantic
    - Footer: Lưu (loading) + Hủy buttons trong `extra`
  - Modal.confirm "Đồng bộ danh sách cơ quan từ trục LGSP":
    - Content giải thích endpoint `/v1/getAgenciesList` + precondition "cần ít nhất 1 cấu hình LGSP đang bật"
    - okText "Đồng bộ ngay" → POST `/admin/inter-organizations/sync`
    - Modal.success inline result với UL counts: Tổng X, Thêm mới Y, Cập nhật Z, [Lỗi N nếu >0]
- **5 endpoint integration:**
  - `GET /admin/inter-organizations?search=&is_active=&page=&pageSize=` (Plan 37-01) — load list paginated
  - `POST /admin/inter-organizations` (Plan 37-01) — create với body full payload
  - `PUT /admin/inter-organizations/:id` (Plan 37-01) — update với body full payload
  - `DELETE /admin/inter-organizations/:id` (Plan 37-01) — delete sau Popconfirm
  - `POST /admin/inter-organizations/sync` (Plan 37-02) — batch sync sau Modal.confirm
- **maxLength match DB VARCHAR** (verified Plan 37-01 repository comments): code=100, name=500, lgsp_organ_id=100, address=500, email=200, phone=50
- **setBackendFieldError** map 'Mã cơ quan đã tồn tại' (23505 unique violation) → inline field error
- **TypeScript strict:** 0 NEW error trong file mới (4 pre-existing Phase 33-05 errors filtered per CLAUDE.md scope boundary)
- **Production build frontend:** PASS (exit 0, `Compiled successfully in 38.5s`, route `/lgsp/co-quan` compiled static `○`)

## Task Commits

1. **Task 1: REWRITE page.tsx /lgsp/co-quan full CRUD admin** — `3d397aa` (feat) — 601 insertions / 95 deletions, file final 689 lines
2. **Task 2: Production build verify** — verification only, no commit (build PASS exit 0)

## Files Created/Modified

- `e_office_app_new/frontend/src/app/(main)/lgsp/co-quan/page.tsx` **(REWRITE)** — 184 → 689 dòng. Phase 18 stub `/lgsp/organizations` GET-only + chỉ button sync simple → Phase 37 full CRUD admin với 5 endpoint integration + Modal/Drawer/Popconfirm patterns.

## Decisions Made

1. **Admin role guard inline thay vì redirect** — mirror Plan 37-03 pattern. Non-admin user vào page vẫn thấy list (transparent visibility — biết hệ thống có cơ quan nào liên thông), chỉ KHÔNG thấy button CRUD (Thêm/Sửa/Xóa/Sync) + KHÔNG thấy cột Hành động. Backend đã enforce admin role tại `requireRoles('Quản trị hệ thống')` middleware nên data không leak. UX thân thiện hơn redirect đột ngột.

2. **Sync UX flow: Modal.confirm → Modal.success inline result** — KHÔNG dùng toast ngắn vì admin cần biết số lượng đồng bộ cụ thể (Tổng/Thêm mới/Cập nhật/Lỗi). Modal.confirm có content giải thích endpoint + precondition (cần ≥1 cấu hình LGSP bật) → tránh admin bị surprised khi sync fail vì chưa cấu hình.

3. **Search controlled 2-state (searchInput + search committed)** — searchInput là controlled state typing, search là committed state trigger fetch. User typing không refetch mỗi keystroke. Commit qua: (a) Enter, (b) button "Tìm", (c) clear input. Trade-off chấp nhận: KHÔNG có debounce auto-search, user phải explicit commit. Lý do: dataset list cơ quan ngoài thường nhỏ (< 100 row), search exact intent tốt hơn fuzzy auto.

4. **Filter useEffect reset về page 1 khi search/filter đổi** — `useEffect([search, isActiveFilter])` gọi `fetchData(1, pagination.pageSize)`. Tránh edge case: user đang ở page 3 với filter "Tất cả" → đổi filter "Tự đăng ký" → kết quả filter chỉ có 5 row (page 1) → nếu giữ page=3 thì empty result confusing.

5. **Field code disabled khi edit** — Plan 37-01 deleteForAdmin handler có SQLSTATE 23503 (FK violation) check → chứng minh FK constraint từ `outgoing_doc_recipients` (hoặc table khác) tham chiếu `inter_organizations.code` hoặc `.id`. Disable code khi edit tránh corruption FK chain. Admin muốn đổi code → xóa + tạo mới (sẽ bị block nếu có FK ref).

6. **Form payload always full fields** — KHÔNG dùng partial logic như `/lgsp/cau-hinh` (chỉ truyền secretKey khi user nhập mới). Lý do: inter_organizations field nhẹ (string ngắn, không sensitive như password). Backend PUT updateForAdmin có skip-undefined logic → safe. Frontend full payload giúp explicit + dễ debug Network tab.

7. **Tooltip 'Tự đăng ký' tag giải thích Phase 35 auto-INSERT** — admin click tag thấy giải thích "Cơ quan này được tự động đăng ký khi hệ thống nhận văn bản từ trục LGSP. Admin cần xác nhận để cho phép gửi văn bản đi." → context rõ ràng tránh admin xóa nhầm row important.

## Deviations from Plan

**Minor deviation - Filter row layout:** Skeleton plan dùng `<Space wrap>` flat. Implementation dùng `<Row gutter>` với responsive Col → tốt hơn cho mobile + tablet (auto stack vertical < md). Logic giữ nguyên.

**Minor deviation - Sync result UX:** Skeleton plan dùng `msg.success(res.message)` toast. Implementation upgrade thành `Modal.success` inline với UL counts chi tiết (Tổng/Thêm mới/Cập nhật/Lỗi) → admin thấy ngay impact của sync action không cần check log. Justification: Rule 2 (auto-add critical functionality — bulk action cần visible feedback).

**Minor deviation - 2-state search input:** Skeleton plan dùng controlled `setSearch` direct mỗi keystroke. Implementation tách thành `searchInput` (controlled typing) + `search` (committed fetch trigger) → tránh refetch spam. Justification: Rule 1 (auto-fix perf issue tiềm năng — list page typing refetch mỗi keystroke = waste).

## Issues Encountered

- **(None)** — backend endpoints (Plan 37-01 + 37-02) đã đầy đủ + tested. Pattern AntD 6 đã ổn định từ /lgsp/cau-hinh (Plan 37-03 analog 735 lines). Repository interface `InterOrgFullRow` (Plan 37-01) đầy đủ tất cả field UI cần. Implementation thẳng theo skeleton plan với 3 minor UX upgrades.

## Acceptance Criteria — All PASS

| Check | Result |
|---|---|
| File exists | ✓ `e_office_app_new/frontend/src/app/(main)/lgsp/co-quan/page.tsx` |
| File length ≥ 300 lines | ✓ 689 lines (skeleton min 300, plan target 350+) |
| Grep `Cơ quan liên thông` | ✓ matched (header title) |
| Grep `Đồng bộ từ trục LGSP` | ✓ matched (button label) |
| Grep `Tự đăng ký` | ✓ matched (tag label + select option + tooltip) |
| Grep `Đã xác nhận` | ✓ matched (tag label + select option) |
| Grep `admin/inter-organizations` | ✓ matched (5 endpoint paths) |
| Grep `/sync` | ✓ matched (POST sync endpoint) |
| Grep `Popconfirm` | ✓ matched (delete per project convention) |
| Grep `size={720}` | ✓ matched (Drawer AntD 6) |
| Grep `validateTrigger="onSubmit"` | ✓ matched (Form) |
| Grep `setBackendFieldError` | ✓ matched (inline field error mapper) |
| `npx tsc --noEmit` 0 NEW error in this file | ✓ 0 matches for `lgsp/co-quan` in TS output |
| `npm run build` exit 0 | ✓ PASS + `Compiled successfully in 38.5s` + route `/lgsp/co-quan` compiled `○` static |

## User Setup Required

None — page sẵn sàng (nhưng vẫn ẩn trong sidebar bởi `hidden-routes.ts` — Plan 37-06 sẽ unhide).

Manual visual test (defer Plan 37-07 E2E full):
1. Backend running dev + admin login
2. Tạm sửa `hidden-routes.ts` xóa `/lgsp/co-quan` (hoặc gõ URL trực tiếp `http://localhost:3000/lgsp/co-quan`)
3. Verify Table load list với rows hiện có
4. Filter dropdown: chọn "Tự đăng ký" → list chỉ hiển thị row `is_active=false` (Phase 35 auto-INSERT)
5. Search "BNV" hoặc mã cơ quan cụ thể → Enter / button "Tìm" → list filter
6. Click "Thêm mới" → Drawer mở (code editable, lgsp_organ_id trống) → nhập form → Lưu → toast "Đã thêm cơ quan ngoài" + list refresh
7. Click "Sửa" trên row → Drawer mở với prefilled (code DISABLED — extra hint giải thích) → đổi name → Lưu → toast "Đã cập nhật cơ quan ngoài"
8. Click "Xóa" trên row → Popconfirm "Xóa cơ quan ngoài?" → confirm → toast "Đã xóa cơ quan ngoài"
9. Click "Đồng bộ từ trục LGSP" → Modal confirm với precondition warning → "Đồng bộ ngay" → Modal.success với counts cụ thể (Tổng/Thêm mới/Cập nhật/Lỗi)
10. Non-admin login → vào URL trực tiếp → vẫn xem được list nhưng KHÔNG thấy 2 button top + KHÔNG thấy cột Hành động

## Next Phase Readiness

- **Plan 37-05 (frontend overview dashboard `/lgsp`)** unblocked — pattern admin guard từ page này có thể reuse, pattern card stats + sync button có thể mirror
- **Plan 37-06 (frontend menu unhide + retry button)** unblocked — page này sẽ được unhide trong `hidden-routes.ts` cùng với `/lgsp` (overview) — sidebar entry existing line 273-274 MainLayout.tsx đã có Phase 18

## Known Stubs

None — page là production-ready, KHÔNG có placeholder/TODO/mock data. Tất cả data flow từ backend real endpoints (Plan 37-01 + 37-02 đã ship + tested).

## Threat Flags

None — page admin-only (CRUD button + actions column ẩn cho non-admin), backend mount tại `/api/admin/*` đã wrap `authenticate + requireRoles('Quản trị hệ thống')` (Plan 37-01 mount), không có surface mới tại trust boundary. Read list cho mọi authenticated user (transparent — biết hệ thống có cơ quan nào liên thông) — đây là design choice không phải vulnerability.

## Self-Check: PASSED

**Files created/modified verified:**
- FOUND: e_office_app_new/frontend/src/app/(main)/lgsp/co-quan/page.tsx (689 lines)

**Commits verified:**
- FOUND: 3d397aa (Task 1 — REWRITE page.tsx)

**Acceptance criteria check:** All 14 criteria PASS (see table above)

---
*Phase: 37-admin-ui-catalog-go-live*
*Completed: 2026-05-21*
