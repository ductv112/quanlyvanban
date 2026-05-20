# Phase 31 Wave g+h UI follow-up — Playwright execution

**Date:** 2026-05-07
**Tester:** Claude (Agent 2 — Playwright UI)
**Backend:** http://localhost:4000 (qlvb_test)
**Frontend:** http://localhost:3000 (qlvb_test)
**Storage states:** `tests/.auth/{admin,vanthu,lanhdao,canbo,canboX}.json` (5 user fixtures)

## Scope

Cover the SKIP TCs from Wave g (`28-RESULTS.md` — 6 SKIP) and Wave h (`29-RESULTS.md` — 2 SKIP) that have a real **UI verification angle**. Wave g executor was urllib/curl backend-only; Wave h executor was Python urllib backend flow without browser steps. The follow-up here exercises browser flows that the previous waves could not.

The original Wave g/h SKIPs themselves remain SKIP for their stated reasons (no Trưởng phòng fixture, destructive lock-account-mid-session, time-travel delegation, ký-số provider not configured). What this phase adds is **derived UI coverage** that exercises the same RBAC/menu-hide and multi-step composite-flow concerns from a browser angle.

## Summary

| Spec | TC | PASS | FAIL | SKIP |
|---|---|---|---|---|
| `tests/wave-gh-ui/permission-menu-ui.spec.ts` (Wave g UI) | 8 | 8 | 0 | 0 |
| `tests/wave-gh-ui/e2e-flow-ui.spec.ts` (Wave h UI) | 5 | 5 | 0 | 0 |
| **Total** | **13** | **13** | **0** | **0** |

**Pass rate: 13/13 = 100%.** Total runtime ~1m36s on single worker.

## Per-TC results

### Wave g — Permission menu hide UI (8 TC)

| TC | Status | Note |
|---|---|---|
| TC-PERM-MENU-UI-01 | PASS | Admin: 4 group sidebar (NGHIỆP VỤ, KÝ SỐ, ĐỐI TÁC, HỆ THỐNG) + Quản trị + Danh mục + Cấu hình ký số hệ thống visible |
| TC-PERM-MENU-UI-02 | PASS | Văn thư: 3 group, KHÔNG có HỆ THỐNG, KHÔNG có Quản trị/Danh mục/Cấu hình ký số |
| TC-PERM-MENU-UI-03 | PASS | Lãnh đạo: 3 group, KHÔNG có HỆ THỐNG, KHÔNG có Quản trị |
| TC-PERM-MENU-UI-04 | PASS | Cán bộ: 3 group, KHÔNG có Quản trị/Danh mục/Cấu hình ký số; THẤY Văn bản đến + Tài khoản ký số cá nhân + Hồ sơ công việc |
| TC-PERM-MENU-UI-05 | PASS | Cán bộ KHÔNG thấy submenu "Lịch lãnh đạo" |
| TC-PERM-MENU-UI-06 | PASS | canbo_x (đơn vị khác) — same restriction, 3 group, KHÔNG có HỆ THỐNG |
| TC-PERM-MENU-UI-07 | PASS | Cán bộ goto `/quan-tri/don-vi` — backend trả 403 hoặc UI hiện empty state |
| TC-PERM-MENU-UI-08 | PASS | Cán bộ goto `/quan-tri/nguoi-dung` — sidebar vẫn render, UI không crash |

### Wave h — E2E composite UI flow (5 TC)

| TC | Status | Note |
|---|---|---|
| TC-E2E-FLOW-UI-01 | PASS | Văn thư xem `/van-ban-den` list (.ant-table render) + open chi tiết VB id=90001 không crash |
| TC-E2E-FLOW-UI-02 | PASS | Lãnh đạo open chi tiết VB id=90002 (fixture Wave h CDF-002) — header "Số đến: 90002" + back arrow render |
| TC-E2E-FLOW-UI-03 | PASS | Lãnh đạo dashboard render KPI widget (.stat-card / .ant-statistic) |
| TC-E2E-FLOW-UI-04 | PASS | Cán bộ vào `/ho-so-cong-viec` + `/van-ban-du-thao` — table render đúng |
| TC-E2E-FLOW-UI-05 | PASS | Logout flow: dropdown → "Đăng xuất" → modal confirm → click → redirect `/login` |

## Findings & UI reality probes

Khi viết test, Agent 2 đã probe DOM thực tế và phát hiện một số mismatch giữa giả định ban đầu vs UI hiện tại. Đây không phải bug — chỉ là context cho future test work:

1. **Sidebar groups thực tế (sau Phase 1 HIDDEN_ROUTES filter):**
   - admin: `NGHIỆP VỤ | KÝ SỐ | ĐỐI TÁC | HỆ THỐNG` (4 group)
   - vanthu / lanhdao / canbo / canbo_x: `NGHIỆP VỤ | KÝ SỐ | ĐỐI TÁC` (3 group)
   - **QUẢN LÝ** group bị filter (tất cả children — kho-luu-tru, tai-lieu, hop-dong, cuoc-hop — đều trong `HIDDEN_ROUTES`)
   - **TÍCH HỢP** group bị filter (`/lgsp`, `/lgsp/co-quan`, `/thong-bao-kenh` đều trong `HIDDEN_ROUTES`)

2. **VB chi tiết page (`/van-ban-den/:id`) dùng inline styles, KHÔNG có class `.detail-header` / `.page-card` / `.ant-card`.** Test probe bằng text content "Số đến: NNNNN" hoặc icon `.anticon-arrow-left` thay vì class selector.

3. **VB đến list (`/van-ban-den`) có `<h2>DANH SÁCH VĂN BẢN ĐẾN</h2>` với `visibility: hidden` (screen-reader-only).** Không dùng được làm anchor. Dùng `.ant-table` thay thế.

4. **Logout modal dùng `.ant-modal-confirm` (App.useApp `modal.confirm()`), KHÔNG phải `.ant-modal-content` thông thường.** Cần filter bằng `hasText` trong `.ant-modal-confirm`.

5. **Header user dropdown menu dùng `.ant-dropdown-menu-item` + class `.ant-dropdown-menu-item-danger` cho "Đăng xuất".** Không dùng được `getByRole('menuitem', { name: /Đăng xuất/ })` vì sidebar cũng có nhiều menuitem khác — cần selector cụ thể hơn.

## Files created

- `tests/wave-gh-ui/permission-menu-ui.spec.ts` — 8 TC permission menu hide (5 role × 1-2 scenario)
- `tests/wave-gh-ui/e2e-flow-ui.spec.ts` — 5 TC composite E2E UI flow (vanthu → lanhdao → canbo → logout)
- `.planning/phases/31-fix-gom-ui/31-RESULTS-gh-ui.md` — this file

## Cumulative status (post Wave g+h UI follow-up)

| Wave | Source | TC | PASS | FAIL |
|---|---|---|---|---|
| Wave a UI (Phase 22) | Playwright | 22 | 22 | 0 |
| Wave g UI follow-up (Phase 31) | Playwright | 8 | 8 | 0 |
| Wave h UI follow-up (Phase 31) | Playwright | 5 | 5 | 0 |
| **Total UI Playwright** | | **35** | **35** | **0** |

Wave g/h backend-only execution remains as previously reported (`28-RESULTS.md` 25/44 PASS, `29-RESULTS.md` 15/19 PASS). These UI follow-up tests are **additive** — they exercise the menu-hide and multi-step UI angles that backend curl/urllib can't.

## Recommendations

1. **Consider adding `.detail-header`, `.detail-header-title`, `.page-card` CSS classes to VB chi tiết page** (`van-ban-den/[id]/page.tsx`). Current inline-style approach makes UI tests fragile and less scannable.

2. **Add `data-testid` attributes** for key interactive elements (logout button, sidebar group, modal confirm) to reduce reliance on Ant Design internal class selectors which may change between AntD 6.x → 7.x.

3. **Document HIDDEN_ROUTES feature flag** in deployment docs — Phase 1 hides QUẢN LÝ + TÍCH HỢP groups, which is "expected" behavior right now but may surprise future testers / KH.
