# Phase 31 — Wave d & e UI fix-gom (con SKIP UI) — Test Results

**Tester:** Claude Code AI (Playwright UI tester)
**Date:** 2026-05-07
**Backend:** http://localhost:4000 (env=test, db=qlvb_test)
**Frontend:** http://localhost:3000
**Login fixture:** `test_admin / Test@123` (admin storage state)

## Scope

Cover các UI test case ở status **SKIP / MANUAL_UI / chưa Playwright** từ Wave d (Quản trị) và Wave e (Danh mục).
Các UI TC đã có spec hiện hữu (`tests/wave-d-don-vi/`, `tests/wave-d-nguoi-dung/`, `tests/wave-e-so-van-ban/`, `tests/wave-e-nguoi-ky/`) **không cover lại** ở phase này.

**Source files đọc:**
- `.planning/phases/25-execute-wave-d/25-RESULTS-{don-vi,chuc-vu,nguoi-dung,nhom-quyen}.md`
- `.planning/phases/26-execute-wave-e/26-RESULTS-{so-vb,loai-vb,linh-vuc,nguoi-ky}.md`

## Summary

| Status | Count |
|---|---|
| **PASS** | 39 |
| **FAIL** | 0 |
| **TOTAL** | 39 |

Tất cả 39 TC PASS sau khi fix selector / timing issues qua 4 vòng iterate.

## Per-TC Results

### Wave d — Quản trị

#### qt-don-vi-ui.spec.ts (3 TC bo sung)
| TC | Title | Result |
|---|---|---|
| TC-QTDV-003 | Click node trên cây -> bảng re-fetch theo parent_id | PASS |
| TC-QTDV-016 | Tên 200 ký tự — maxLength=200 clamps input | PASS |
| TC-QTDV-017 | Địa chỉ 500 ký tự — maxLength=500 clamps input | PASS |

> Đã có spec hiện hữu (wave-d-don-vi) cover: 001, 002, 004, 005, 009, 010, 012, 013, 014, 015, 018, 026, 028, 029, 030.

#### qt-chuc-vu-ui.spec.ts (8 TC — file mới hoàn toàn)
| TC | Title | Result |
|---|---|---|
| TC-QTCV-001 | Bang có cột Mã/Tên/Thứ tự/Số NV/Lãnh đạo/XL VB/Trạng thái | PASS |
| TC-QTCV-002 | Pagination footer + showSizeChanger + Tổng N | PASS |
| TC-QTCV-003 | Search keyword lọc bảng | PASS |
| TC-QTCV-007 | Drawer Thêm — Empty Tên -> inline 'Nhập tên chức vụ' | PASS |
| TC-QTCV-008 | Drawer Thêm — Empty Mã -> inline 'Nhập mã' | PASS |
| TC-QTCV-018 | Switch Trạng thái default = Hoạt động (ON) | PASS |
| TC-QTCV-019 | Switch "Được xử lý văn bản" default = Có (ON) | PASS |
| TC-QTCV-018b | Switch "Chức vụ lãnh đạo" default = Không (OFF) | PASS |

#### qt-nguoi-dung-ui.spec.ts (5 TC bổ sung)
| TC | Title | Result |
|---|---|---|
| TC-QTND-006 | Filter trạng thái = Hoạt động trả ≥1 row | PASS |
| TC-QTND-008 | Drawer Thêm mở với tiêu đề + form rỗng (username + password) | PASS |
| TC-QTND-021 | Empty form -> inline error cho Họ và tên đệm | PASS |
| TC-QTND-022 | Empty form -> inline error cho Tên | PASS |
| TC-QTND-023 | Email sai định dạng -> inline 'Email không đúng định dạng' | PASS |

> Đã có spec hiện hữu (wave-d-nguoi-dung) cover: 001, 002, 003, 005, 007, 011, 031, 035, 036, 038, 044, 045, 050.

#### qt-nhom-quyen-ui.spec.ts (6 TC — file mới hoàn toàn)
| TC | Title | Result |
|---|---|---|
| TC-QTNQ-001 | Bảng có cột Tên nhóm/Mô tả/Số người dùng/Ngày tạo | PASS |
| TC-QTNQ-002 | Card header + nút Thêm + search input | PASS |
| TC-QTNQ-007 | Empty name -> inline error 'Nhập tên nhóm quyền' | PASS |
| TC-QTNQ-005 | Drawer Thêm — fill name + Thêm mới -> drawer đóng | PASS |
| TC-QTNQ-013 | Click "Phân quyền" -> Drawer title + Tree checkable | PASS |
| TC-QTNQ-021 | Modal cancel xóa -> đóng, role vẫn còn | PASS |

### Wave e — Danh mục

#### dm-so-vb-ui.spec.ts (3 TC bổ sung)
| TC | Title | Result |
|---|---|---|
| TC-DMSV-006 | Drawer Thêm — empty Tên sổ -> inline error | PASS |
| TC-DMSV-022 | Tab active có underline / highlight đúng tab | PASS |
| TC-DMSV-013 | Drawer Sửa — open from menu -> form fields visible | PASS |

> Đã có spec hiện hữu (wave-e-so-van-ban) cover: 001, 002, 003, 016, 018, 019, 020.

#### dm-loai-vb-ui.spec.ts (5 TC — file mới hoàn toàn)
| TC | Title | Result |
|---|---|---|
| TC-DMLV-001 | Hiển thị 3 tab + default = Văn bản đến | PASS |
| TC-DMLV-007 | Drawer Thêm — Empty Mã -> inline 'Nhập mã loại văn bản' | PASS |
| TC-DMLV-008 | Drawer Thêm — Empty Tên -> inline 'Nhập tên loại văn bản' | PASS |
| TC-DMLV-019 | Drawer Sửa tiêu đề "Cập nhật loại văn bản" + form pre-filled | PASS |
| TC-DMLV-020 | Cancel Drawer Sửa — drawer đóng, no save | PASS |
| TC-DMLV-014 | Drawer Thêm: Loại cha select có showSearch + dropdown opens | PASS |

#### dm-linh-vuc-ui.spec.ts (5 TC — file mới hoàn toàn)
| TC | Title | Result |
|---|---|---|
| TC-DMLN-001 | Header + table + filter + headers Mã/Tên/Thứ tự/Trạng thái | PASS |
| TC-DMLN-006 | Drawer Thêm KHÔNG có field "Trạng thái" (chỉ ở Edit) | PASS |
| TC-DMLN-007 | Drawer Thêm — Empty Mã -> inline 'Nhập mã lĩnh vực' | PASS |
| TC-DMLN-008 | Drawer Thêm — Empty Tên -> inline 'Nhập tên lĩnh vực' | PASS |
| TC-DMLN-012 | Drawer Sửa CO field "Trạng thái" (Switch) | PASS |

#### dm-nguoi-ky-ui.spec.ts (3 TC bổ sung)
| TC | Title | Result |
|---|---|---|
| TC-DMNK-002 | Không chọn dept -> bảng + headers visible | PASS |
| TC-DMNK-004 | Tìm kiếm phòng ban trên cây — input filter works | PASS |
| TC-DMNK-018 | Modal Thêm — Select có showSearch (`.ant-select-show-search`) | PASS |

> Đã có spec hiện hữu (wave-e-nguoi-ky) cover: 001, 005, 006, 007, 008, 009, 011, 014, 016.

## Files Created

```
D:\ProjectAI\quanlyvanban\tests\wave-de-ui\
├── qt-don-vi-ui.spec.ts          (3 TC)
├── qt-chuc-vu-ui.spec.ts         (8 TC) - module file mới
├── qt-nguoi-dung-ui.spec.ts      (5 TC)
├── qt-nhom-quyen-ui.spec.ts      (6 TC) - module file mới
├── dm-so-vb-ui.spec.ts           (3 TC)
├── dm-loai-vb-ui.spec.ts         (6 TC) - module file mới
├── dm-linh-vuc-ui.spec.ts        (5 TC) - module file mới
└── dm-nguoi-ky-ui.spec.ts        (3 TC)

Total: 8 spec files, 39 TC
```

## Run Command

```bash
npx playwright test tests/wave-de-ui/ --workers=1 --project=chromium --reporter=line
```

**Final result:** `39 passed (4.2m)` — 100% pass rate.

## Key Findings & Lessons

### Lesson 1 — Drawer mở chậm trên trang nặng table+tree
- Test fail vào `.ant-drawer-open` timeout khi page chưa load xong React state. Fix bằng:
  - `await page.waitForSelector('table thead th', { timeout: 15000 })`
  - `await page.waitForLoadState('networkidle').catch(() => {})`
  - `await page.waitForTimeout(800)` trước khi click button Thêm
  - Tăng drawer-open timeout từ 8s → 12s

### Lesson 2 — `getByRole('menuitem', { name: /^Sửa$/ })` không match được item có icon
- AntD Dropdown.Menu với `icon: <EditOutlined />` + `label: 'Sửa'` thì menuitem text bao gồm cả accessible name của icon.
- Fix: dùng `page.locator('.ant-dropdown-menu-item').filter({ hasText: 'Sửa' })` thay vì `getByRole`.

### Lesson 3 — AntD 6 Switch trong Form
- `aria-checked` attribute trên `button[role="switch"]` đúng để verify.
- Cần `await page.waitForTimeout(500)` sau drawer mở để form `setFieldsValue` áp dụng default.
- Filter form-item bằng index (nth/first/last) bền hơn `hasText` (vì Switch text "Có/Không" có thể conflict).

### Lesson 4 — AntD 6 Select showSearch detection
- Class `.ant-select-show-search` là indicator chính xác (không cần click mở dropdown).
- Click vào `.ant-select-selector` có thể bị overlay block trong Modal khi background tree expand thay đổi viewport.
- Verify-by-class chiến lược ổn hơn click-to-open-dropdown.

### Lesson 5 — Label collision với column header
- `getByLabel('Tên', { exact: true })` có thể match cả column header (`<th>Tên</th>`) nếu Playwright role logic include header.
- Fix: dùng placeholder-based selector: `input[placeholder="VD: Khoa học công nghệ"]`.

## BUG cũ vẫn tồn tại (đã ghi nhận ở Wave d/e RESULTS — không phải mới)

Các UI test PASS nhưng vẫn highlight các bug đã ghi nhận:
- **BUG-DV-001/002** (don-vi backend hygiene) — TC-QTDV-016/017 PASS ở UI nhưng backend vẫn raw PG error nếu bypass FE.
- **BUG-DMLV-001/002** (loai-vb shadow route) — TC-DMLV-001 PASS hiển thị tab nhưng table cells vẫn hiển thị "—" vì missing fields.
- **BUG-DMLN-001/002/003** (linh-vuc shadow route) — TC-DMLN-001/012 PASS layout nhưng filter inactive records không xuất hiện.
- **BUG-VT-001** (nhom-quyen pagination) — TC-QTNQ-002 PASS card header nhưng "Tổng N" có thể hiển thị undefined nếu backend chưa trả total.

Tất cả không phải bug mới — chỉ ghi nhận để truy vết.

## Test Artifacts

- Spec files: 8 files trong `tests/wave-de-ui/`
- Run results: `tests/results/playwright-results.json`
- Trace/screenshots: `tests/results/artifacts/` (chỉ tạo khi fail — clean state hiện tại)
