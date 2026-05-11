---
phase: 32-hdsd-audit-update
plan: 04
subsystem: docs/hdsd
tags: [docs, hdsd, audit, ky-so, dang-nhap, index]
requires:
  - 32-01-AUDIT-REPORT
provides:
  - HDSD Ký số (3 file) verified clean vs current code
  - HDSD Đăng nhập + Thông tin cá nhân verified clean vs current code
  - HDSD_index.md TOC fixed (3 broken links removed, items renumbered)
affects:
  - docs/hdsd/HDSD_index.md
tech-stack:
  added: []
  patterns:
    - Audit-driven doc update — "No change" verdicts trusted from Plan 01 AUDIT_REPORT
    - Broken-link detection via regex scan over markdown table cells
key-files:
  created: []
  modified:
    - docs/hdsd/HDSD_index.md
decisions:
  - Trust AUDIT_REPORT verdict "No change" for 4 of 5 files (3 Ký số + Đăng nhập) — content already matches current code, no diff applied
  - Replace 3 non-existent HSCV file references (danh_sach/chi_tiet/bao_cao) with single existing HDSD_ho_so_cong_viec.md
  - Renumber TOC items 10-20 to fill gaps caused by 3-files-to-1-file consolidation
  - Skip audit-suggested "Tin nhắn" removal — string does not exist in current HDSD_index.md (audit note was stale)
metrics:
  duration: 7m
  completed: 2026-05-11
---

# Phase 32 Plan 04: Ký số + Đăng nhập + Index HDSD Summary

Verified 4 HDSD files (3 Ký số + Đăng nhập) clean against current code per Plan 01 audit, and fixed 3 broken HSCV links in HDSD_index.md by consolidating to the single existing `HDSD_ho_so_cong_viec.md` file and renumbering TOC items 10-20.

## Tasks Completed

| Task | Name                                              | Status            | Commit  | Files                              |
| ---- | ------------------------------------------------- | ----------------- | ------- | ---------------------------------- |
| 1    | Update 3 Ký số HDSD files per audit               | Verified clean    | (none)  | (no diff — audit verdict "No change") |
| 2    | Update HDSD_dang_nhap_va_thong_tin_ca_nhan.md     | Verified clean    | (none)  | (no diff — version string "2.0" matches login code) |
| 3    | Update HDSD_index.md TOC                          | Fixed broken links | c119309 | docs/hdsd/HDSD_index.md            |

## Task 1 — 3 Ký số HDSD files (Verified clean)

Files checked:
- `docs/hdsd/HDSD_ky_so_cau_hinh.md` (173 dòng) — Cấu hình ký số hệ thống (2 provider cards SmartCA VNPT + MySign Viettel, Drawer sửa cấu hình, Modal kích hoạt)
- `docs/hdsd/HDSD_ky_so_danh_sach.md` (227 dòng) — Danh sách ký số (4 tab Cần ký/Đang xử lý/Đã ký/Thất bại, Banner Root CA Viettel, Modal Ký số 3:00 timeout)
- `docs/hdsd/HDSD_ky_so_tai_khoan.md` (95 dòng) — Tài khoản ký số cá nhân (Mã định danh, Chứng thư Select MySign, Lưu + Xác thực)

**Audit verdict (Plan 01 AUDIT-REPORT lines 168-199):** All 3 files "No change" — content already matches current code.

**Cross-check performed:**
- Provider list (SmartCA VNPT + MySign Viettel) — matches seed/001_required_data.sql
- Sign modal timeout 3:00 phút (180s) — matches client-side countdown in ký số module
- Field constraints (Base URL bắt buộc + Client ID ≤200 char + Client Secret ≥8 char + Profile ID required for MySign) — matches schema
- Hidden route `/ky-so/cau-hinh` admin only — matches MainLayout.tsx
- Banner Root CA Viettel always-visible — matches UI

No file diff applied. No commit created for this task.

## Task 2 — HDSD_dang_nhap_va_thong_tin_ca_nhan.md (Verified clean)

File checked:
- `docs/hdsd/HDSD_dang_nhap_va_thong_tin_ca_nhan.md` (162 dòng) — Đăng nhập + Thông tin cá nhân + Logout confirm

**Audit verdict (Plan 01 AUDIT-REPORT lines 157-166):** "Text update minor — verify + update version string ở mục 3.1".

**Cross-check performed:**
- Login UI version string — `e_office_app_new/frontend/src/app/(auth)/login/page.tsx` line 140 shows "Phiên bản 2.0 · Chuyển đổi số Doanh nghiệp" → matches HDSD line 51 exactly
- Login form fields (Tên đăng nhập + Mật khẩu + Ghi nhớ đăng nhập + Đăng nhập button) — matches
- Hidden/show password eye icon — matches `<Input.Password>` component
- Password validation rules (min 6 ký tự + chữ hoa + chữ thường + số) — matches auth.service.ts
- Profile page: 7-row info table + change password tab + logout confirm — matches code
- "Quên mật khẩu" — hệ thống không có chức năng tự khôi phục → cần liên hệ Quản trị để reset về Admin@123 — matches business rule

No diff needed. Version string is already correct ("2.0"), not stale. No commit created.

## Task 3 — HDSD_index.md TOC (Fixed broken links)

**Issue found (Rule 1 — Bug):** 3 link entries in section 5.3 "Hồ sơ công việc" pointed to files that don't exist:
- `HDSD_ho_so_cong_viec_danh_sach.md` — missing
- `HDSD_ho_so_cong_viec_chi_tiet.md` — missing
- `HDSD_ho_so_cong_viec_bao_cao.md` — missing

Actual existing file: `HDSD_ho_so_cong_viec.md` (single consolidated file, 802 dòng).

**Verification command output before fix:**
```
Missing: HDSD_ho_so_cong_viec_danh_sach.md
Missing: HDSD_ho_so_cong_viec_chi_tiet.md
Missing: HDSD_ho_so_cong_viec_bao_cao.md
Total missing: 3
```

**Fix applied:**
1. Replaced 3 rows in section 5.3 with single row pointing to `HDSD_ho_so_cong_viec.md`:
   - `| 9 | Hồ sơ công việc (danh sách + chi tiết + báo cáo) | [HDSD_ho_so_cong_viec.md](HDSD_ho_so_cong_viec.md) |`
2. Renumbered subsequent TOC items to remove gap (HSCV used #9-11, now only #9 → next section shifts from #12 to #10):
   - Section 5.4 Ký số: items 12→10, 13→11, 14→12
   - Section 5.5 Quản trị hệ thống: items 15→13, 16→14, 17→15, 18→16
   - Section 5.6 Danh mục: items 19→17, 20→18, 21→19, 22→20

**Verification after fix:**
```
Total missing: 0
```

All 20 TOC links resolve to existing files in `docs/hdsd/`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed 3 broken HSCV links in HDSD_index.md**
- **Found during:** Task 3 verification
- **Issue:** HDSD_index.md references 3 HSCV files (`danh_sach`, `chi_tiet`, `bao_cao`) that don't exist in the repo — actual file is a single consolidated `HDSD_ho_so_cong_viec.md`
- **Fix:** Replaced 3 broken link rows with 1 row pointing to existing file + renumbered subsequent TOC items to remove numbering gap
- **Files modified:** `docs/hdsd/HDSD_index.md`
- **Commit:** c119309

### Audit Notes Skipped

**Audit-suggested "Tin nhắn" removal** — AUDIT-REPORT (line 296) noted index references "Tin nhắn" at line 66 with hidden route `/tin-nhan`. **Verified false positive:** grep `Tin nhắn` in current HDSD_index.md returns zero matches. Audit note was stale (audit was written from an older index version). No change needed.

## Files Verified Clean (No Diff)

| File                                            | Audit verdict       | Reason                                                              |
| ----------------------------------------------- | ------------------- | ------------------------------------------------------------------- |
| docs/hdsd/HDSD_ky_so_cau_hinh.md                | No change           | 2 provider cards + Drawer + Activation Modal already match code     |
| docs/hdsd/HDSD_ky_so_danh_sach.md               | No change           | 4 tabs + Banner Root CA + Sign Modal 3:00 timeout match code        |
| docs/hdsd/HDSD_ky_so_tai_khoan.md               | No change           | Mã định danh + Chứng thư Select + Lưu/Xác thực buttons match code   |
| docs/hdsd/HDSD_dang_nhap_va_thong_tin_ca_nhan.md| Text update minor (skipped) | Version string "2.0" already current; all form fields match code |

## Self-Check

- [x] `docs/hdsd/HDSD_ky_so_cau_hinh.md` exists — FOUND
- [x] `docs/hdsd/HDSD_ky_so_danh_sach.md` exists — FOUND
- [x] `docs/hdsd/HDSD_ky_so_tai_khoan.md` exists — FOUND
- [x] `docs/hdsd/HDSD_dang_nhap_va_thong_tin_ca_nhan.md` exists — FOUND
- [x] `docs/hdsd/HDSD_index.md` exists — FOUND
- [x] Commit c119309 exists in git log — FOUND
- [x] All 20 HDSD_*.md links in HDSD_index.md resolve to existing files — verified by PowerShell regex scan

## Self-Check: PASSED
