---
phase: 32-hdsd-audit-update
plan: 05
subsystem: docs/hdsd
tags: [docs, hdsd, audit, quan-tri, admin]
requires:
  - 32-01-AUDIT-REPORT
provides:
  - 8 Quản trị HDSD verified clean vs current admin UI + hidden-routes (Phase 31)
affects: []
tech-stack:
  added: []
  patterns:
    - Audit-driven doc verification — trust Plan 01 AUDIT-REPORT "No change" verdicts
    - Cross-check admin page.tsx field interfaces + button sets vs HDSD tables
    - Verify hidden-routes.ts scope vs HDSD "Đối tượng sử dụng" descriptions
key-files:
  created: []
  modified: []
decisions:
  - Trust AUDIT-REPORT verdict "No change" for all 8 admin HDSD files — content already matches current code
  - All 8 Quản trị routes (don-vi, chuc-vu, nguoi-dung, nhom-quyen, so-van-ban, linh-vuc, loai-van-ban, nguoi-ky) are NOT in hidden-routes.ts → admin-visible, HDSDs correctly state "Đối tượng sử dụng: quản trị viên hệ thống" or "Người quản trị đơn vị"
  - Phase 31 fix-gom UI patterns (Dropdown MoreOutlined, Drawer size=720, Modal.confirm delete) already accurately described in all 8 HDSDs
metrics:
  duration: 5m
  completed: 2026-05-11
---

# Phase 32 Plan 05: Quản trị HDSD (8 file) Verification Summary

Verified 8 admin HDSD files clean against current Quản trị UI per Plan 01 audit — no diff applied, all files already accurately reflect Phase 31 fix-gom UI patterns and current schema constraints.

## Tasks Completed

| Task | Name                                                              | Status         | Commit | Files                                              |
| ---- | ----------------------------------------------------------------- | -------------- | ------ | -------------------------------------------------- |
| 1    | Update 4 core admin HDSD (đơn vị, chức vụ, người dùng, nhóm quyền) | Verified clean | (none) | (no diff — audit verdict "No change" for all 4)    |
| 2    | Update 4 catalog admin HDSD (sổ VB, lĩnh vực, loại VB, người ký)   | Verified clean | (none) | (no diff — audit verdict "No change" for all 4)    |

## Task 1 — 4 core admin HDSD files (Verified clean)

Files checked:

- `docs/hdsd/HDSD_quan_tri_don_vi.md` (184 dòng) — Đơn vị/Phòng ban tree + Drawer 720px + Khóa/Mở khóa/Xóa + Cấp Đơn vị/Phòng ban + Cho phép sổ văn bản
- `docs/hdsd/HDSD_quan_tri_chuc_vu.md` (165 dòng) — Chức vụ list + Drawer + Switch Chức vụ lãnh đạo / Được xử lý văn bản / Trạng thái
- `docs/hdsd/HDSD_quan_tri_nguoi_dung.md` (295 dòng) — Tree cây phòng ban + bảng người dùng + Drawer 2 cột (7+6 trường) + Phân quyền Drawer 480px + Reset mật khẩu Modal + Xóa Modal
- `docs/hdsd/HDSD_quan_tri_nhom_quyen.md` (191 dòng) — Danh sách nhóm quyền + Drawer (Tên + Mô tả) + Phân quyền Drawer cây checkbox

**Audit verdict (Plan 01 AUDIT-REPORT lines 201-243):** All 4 files "No change" — content already matches current code.

**Cross-check performed against `e_office_app_new/frontend/src/app/(main)/quan-tri/*/page.tsx`:**

- `don-vi/page.tsx` lines 1-100: `Department` interface (parent_id, code, name, name_en, short_name, is_unit, sort_order, phone, fax, email, address, allow_doc_book, description, is_locked, staff_count) — matches HDSD field list exactly
- `chuc-vu/page.tsx` lines 1-80: `Position` interface (code, name, sort_order, description, is_active, is_leader, is_handle_document) — matches HDSD field list exactly
- `nguoi-dung/page.tsx` lines 1-120: `Staff` interface (code, username, first_name, last_name, email, phone, mobile, gender, birth_date, address, unit_id, department_id, position_id, is_locked) — matches HDSD field list exactly; Drawer 2-cột bố cục cũng match
- `nhom-quyen/page.tsx` lines 1-100: `Role` interface (name, description, staff_count, created_at) — matches HDSD field list exactly; Right tree checkbox pattern matches
- All 4 pages use Dropdown + MoreOutlined for action menu (Phase 31 fix-gom pattern) — HDSD all describe "menu ba chấm cuối mỗi dòng" correctly
- All 4 pages use Drawer with `size={720}` for Add/Edit — HDSD all describe "Drawer rộng 720px" correctly
- All 4 pages use Modal.confirm for delete — HDSD all describe "Modal nhỏ nằm giữa màn hình" with "Xác nhận xóa" title correctly

**Hidden-routes verification** (`e_office_app_new/frontend/src/config/hidden-routes.ts`):

- `/quan-tri/don-vi` — NOT hidden → admin-visible. HDSD line 9: "Đối tượng sử dụng: quản trị viên hệ thống, văn thư cấp đơn vị" — correct
- `/quan-tri/chuc-vu` — NOT hidden → admin-visible. HDSD line 9: "Đối tượng sử dụng: quản trị viên hệ thống" — correct
- `/quan-tri/nguoi-dung` — NOT hidden → admin-visible. HDSD line 9: "Đối tượng sử dụng: quản trị viên hệ thống" — correct
- `/quan-tri/nhom-quyen` — NOT hidden → admin-visible. HDSD line 9: "Đối tượng sử dụng: quản trị viên hệ thống" — correct

No file diff applied. No commit created for this task.

## Task 2 — 4 catalog admin HDSD files (Verified clean)

Files checked:

- `docs/hdsd/HDSD_quan_tri_so_van_ban.md` (136 dòng) — 3 tab (VB đến/đi/dự thảo) + Drawer (Tên sổ + Mô tả + Thứ tự + Switch mặc định) + Đặt mặc định toggle
- `docs/hdsd/HDSD_quan_tri_linh_vuc.md` (118 dòng) — Bảng lĩnh vực + Drawer (Mã + Tên + Thứ tự + Switch trạng thái) + Tìm kiếm Enter
- `docs/hdsd/HDSD_quan_tri_loai_van_ban.md` (126 dòng) — 3 tab + bảng tree cha-con + Drawer (Loại cha + Mã + Tên + Kiểu ký hiệu Select + Thứ tự)
- `docs/hdsd/HDSD_quan_tri_nguoi_ky.md` (112 dòng) — Tree phòng ban + bảng người ký + Modal thêm (Select nhân viên) + Modal xóa (chỉ thùng rác, không Sửa)

**Audit verdict (Plan 01 AUDIT-REPORT lines 245-287):** All 4 files "No change" — content already matches current code.

**Cross-check performed against `e_office_app_new/frontend/src/app/(main)/quan-tri/*/page.tsx`:**

- `so-van-ban/page.tsx` lines 1-100: `DocBook` interface (unit_id, type_id, name, description, sort_order, is_default, created_by, created_at), TAB_ITEMS = ['Văn bản đến', 'Văn bản đi', 'Văn bản dự thảo'], handler `handleSetDefault` with `PATCH /:id/mac-dinh` — matches HDSD section 3.1 "Đặt mặc định" và 3 tab list exactly
- `linh-vuc/page.tsx` lines 1-80: `DocField` interface (unit_id, code, name, sort_order, is_active), search params `keyword` apply on Enter — matches HDSD section 2 (Mã 20 char + Tên 200 char + Thứ tự + Trạng thái)
- `loai-van-ban/page.tsx` lines 1-100: `DocType` interface (type_id, parent_id, code, name, description, sort_order, notation_type, is_default, children), `flattenTree` with level indent for Parent select, TAB_ITEMS same 3 tabs, notation_type values ['', 'Số/Ký hiệu', 'Số-Ký hiệu'] — matches HDSD section 2 "Kiểu ký hiệu có 3 lựa chọn" exactly
- `nguoi-ky/page.tsx` lines 1-100: `Signer` interface (staff_id, staff_name, position_name, department_name), Tree phòng ban + Modal thêm Select nhân viên + chỉ icon thùng rác xóa (KHÔNG có Sửa) — matches HDSD section 3.1 "Bảng danh sách người ký không có thao tác chỉnh sửa, chỉ có thao tác xóa" exactly
- `nguoi-ky/page.tsx` line 14: `trigger ở cơ sở dữ liệu` auto-sync khi nhân viên đổi phòng — match HDSD section 2 line 14

**Hidden-routes verification:**

- `/quan-tri/so-van-ban` — NOT hidden → admin-visible. HDSD line 7: "Người quản trị đơn vị sử dụng" — correct
- `/quan-tri/linh-vuc` — NOT hidden → admin-visible. HDSD line 7: "Người quản trị đơn vị sử dụng" — correct
- `/quan-tri/loai-van-ban` — NOT hidden → admin-visible. HDSD line 7: "Người quản trị đơn vị sử dụng" — correct
- `/quan-tri/nguoi-ky` — NOT hidden → admin-visible. HDSD line 7: "Người quản trị đơn vị sử dụng" — correct

No file diff applied. No commit created for this task.

## Deviations from Plan

None — plan executed exactly as audit prescribed (verdict "No change" for all 8 files).

## Files Verified Clean (No Diff)

| File                                       | Lines | Audit verdict | Cross-check evidence                                                              |
| ------------------------------------------ | ----- | ------------- | --------------------------------------------------------------------------------- |
| docs/hdsd/HDSD_quan_tri_don_vi.md          | 184   | No change     | Department interface (15 fields) + Drawer 720px + Cấp Đơn vị/Phòng ban — match    |
| docs/hdsd/HDSD_quan_tri_chuc_vu.md         | 165   | No change     | Position interface (7 fields) + 3 Switch (Leader/HandleDoc/Active) — match        |
| docs/hdsd/HDSD_quan_tri_nguoi_dung.md      | 295   | No change     | Staff interface (15 fields) + 2-cột Drawer + Phân quyền 480px + Reset Modal — match |
| docs/hdsd/HDSD_quan_tri_nhom_quyen.md      | 191   | No change     | Role interface (4 fields) + Phân quyền tree checkbox — match                      |
| docs/hdsd/HDSD_quan_tri_so_van_ban.md      | 136   | No change     | DocBook interface (8 fields) + 3 tab + Đặt mặc định toggle — match                |
| docs/hdsd/HDSD_quan_tri_linh_vuc.md        | 118   | No change     | DocField interface (5 fields) + Mã 20 char + Trạng thái switch — match            |
| docs/hdsd/HDSD_quan_tri_loai_van_ban.md    | 126   | No change     | DocType tree + 3 tab + notation_type 3 options — match                            |
| docs/hdsd/HDSD_quan_tri_nguoi_ky.md        | 112   | No change     | Signer + Tree phòng ban + Modal Add only / thùng rác Delete only (no Edit) — match |

## Self-Check

- [x] `docs/hdsd/HDSD_quan_tri_don_vi.md` exists — FOUND (184 lines)
- [x] `docs/hdsd/HDSD_quan_tri_chuc_vu.md` exists — FOUND (165 lines)
- [x] `docs/hdsd/HDSD_quan_tri_nguoi_dung.md` exists — FOUND (295 lines)
- [x] `docs/hdsd/HDSD_quan_tri_nhom_quyen.md` exists — FOUND (191 lines)
- [x] `docs/hdsd/HDSD_quan_tri_so_van_ban.md` exists — FOUND (136 lines)
- [x] `docs/hdsd/HDSD_quan_tri_linh_vuc.md` exists — FOUND (118 lines)
- [x] `docs/hdsd/HDSD_quan_tri_loai_van_ban.md` exists — FOUND (126 lines)
- [x] `docs/hdsd/HDSD_quan_tri_nguoi_ky.md` exists — FOUND (112 lines)
- [x] No git changes pending in `docs/hdsd/HDSD_quan_tri_*.md` — verified by `git status --short docs/hdsd/`
- [x] All 8 admin pages cross-checked against their HDSD files — Department/Position/Staff/Role/DocBook/DocField/DocType/Signer interfaces all match HDSD field lists

## Self-Check: PASSED
