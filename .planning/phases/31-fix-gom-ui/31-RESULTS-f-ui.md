---
phase: 31-fix-gom-ui
agent: Wave f UI gom (Playwright)
source: .planning/phases/27-execute-wave-f/27-RESULTS-*.md
spec_file: tests/wave-f-ui/boundary-ui.spec.ts
mode: Playwright UI E2E (chromium, storage state admin)
date: 2026-05-07
---

# Wave f UI — Cover SKIP UI TCs (Playwright)

## Summary

| Metric | Value |
|---|---|
| SKIP UI TCs found in Wave f | **1** |
| TCs covered by Playwright | **1** |
| PASS | **1** |
| FAIL | **0** |
| Spec files created | **1** (`tests/wave-f-ui/boundary-ui.spec.ts`) |
| Run time | 14.8s |

## SKIP UI TC source extraction

Đã quét 4 sub-results Wave f:

| Sub-result | SKIP UI count | Note |
|---|---|---|
| `27-RESULTS-auth-notif-admin.md` | **1** | TC-BND-AUTH-006 (confirmPassword FE rule) |
| `27-RESULTS-vb-den-di.md` | 0 | "Method: REST API thuần — Không Playwright" (intent: API only) |
| `27-RESULTS-duthao-hscv-kyso.md` | 0 | 2 NOT-TESTABLE là GAP (display-only column, missing seed) — không phải UI gap |
| `27-RESULTS-nguoi-dung-danh-muc.md` | 0 | Không có SKIP/UI |

→ Wave f là batch boundary VARCHAR + file upload qua API thuần. UI gap cực ít (đúng dự đoán scope: 3-15, thực tế 1).

## TC Detail

### TC-BND-AUTH-006 — confirmPassword không khớp newPassword hiển thị lỗi FE — **PASS**

- **Source SKIP reason:** "confirmPassword check chỉ ở FE (Form rule), backend không nhận field này"
- **UI location:** `/thong-tin-ca-nhan` → tab "Đổi mật khẩu" (default)
- **Form rules tested (FE only):**
  - `oldPassword`: required
  - `newPassword`: required + min 6 + pattern `(?=.*[a-z])(?=.*[A-Z])(?=.*\d)`
  - `confirmPassword`: required + custom validator so sánh với `newPassword`
- **3 sub-cases verified:**
  1. ✅ `confirm = ""` → inline error "Xác nhận mật khẩu mới"
  2. ✅ `confirm = "NewPass2"` (khác `"NewPass1"`) → inline error "Mật khẩu xác nhận không khớp" + KHÔNG có toast "Đổi mật khẩu thành công" (chứng minh BE không bị gọi)
  3. ✅ `confirm = "NewPass1"` (khớp) → lỗi "không khớp" biến mất (rule pass)
- **Safety:** KHÔNG click submit ở case (c) — tránh đổi password thật của `test_admin`.
- **Locator note:** `getByLabel('Mật khẩu mới')` collide với `'Xác nhận mật khẩu mới'` (strict-mode fail). Phải dùng `page.locator('#newPassword')` / `#confirmPassword` (id từ Form.Item name).

## Files

- **Spec:** `D:/ProjectAI/quanlyvanban/tests/wave-f-ui/boundary-ui.spec.ts` (88 lines, 1 test)
- **Frontend tested:** `e_office_app_new/frontend/src/app/(main)/thong-tin-ca-nhan/page.tsx` (passwordPanel — line 108-176)

## Run command

```bash
cd D:/ProjectAI/quanlyvanban
npx playwright test tests/wave-f-ui/ --reporter=line --workers=1
```

Output:
```
[1/1] tests/wave-f-ui/boundary-ui.spec.ts:34:7 › Wave F UI — Đổi mật khẩu confirmPassword @wave-f-ui › TC-BND-AUTH-006
1 passed (14.8s)
```

## Action Items

- ✅ Wave f UI gap đã đóng (1/1 TC SKIP UI → PASS).
- Không phát sinh bug FE mới qua test này (Form rule hoạt động đúng).
- Re-baseline TC-BND-AUTH-006 trong Excel master testcase: thêm note "Cover bằng Playwright tests/wave-f-ui/boundary-ui.spec.ts".

## Cumulative impact

- Trước: Wave f 75/94 PASS = 79.8% (1 SKIP đếm ngoài denominator).
- Sau gom UI: 76/95 PASS = 80.0% (1 SKIP UI → PASS, đưa vào denominator).
- Cumulative v3.1 (765 TC): 604/766 = 78.9% (chưa kể fix bug đang chờ).
