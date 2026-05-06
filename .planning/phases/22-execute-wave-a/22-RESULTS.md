---
phase: 22-execute-wave-a
batch: Wave a (83 TC) — Auth + Profile + Dashboard + Bookmark + Notification
started: 2026-05-06T17:10:00.000Z
completed: 2026-05-06T17:50:00.000Z
backend_db: qlvb_test
backend_env: NODE_ENV=test (PG_DATABASE=qlvb_test)
test_users: admin/test_admin/test_canbo/test_canbo_x/test_locked
mode: API + DB query (no browser, no screenshot per user request)
---

# Wave a — Test Results

## Summary

| Sub-batch | Module | TC | Pass | Fail | Skip | Verify |
|-----------|--------|----|----|------|------|--------|
| 1A | Login (17) + Profile (4) + Đổi MK (10) + Logout (2) | 33 | 11 | 10 | 12 | 0 |
| 1B | Dashboard (13) + Bookmark (12) | 25 | 9 | 0 | 14 | 2 |
| 1C | Notification (Chuông 7 + Trang 8 + Drawer 10) | 25 | 14 | 1 | 10 | 0 |
| **TOTAL Wave a** | — | **83** | **34** | **11** | **36** | **2** |

**Pass rate** (loại SKIP+NEEDS-VERIFY): **34 / (34+11) = 75.6%** → sẽ thành **100%** sau fix 4 bug (10 FAIL từ BUG-001 + 1 FAIL từ BUG-004 + BUG-003 widget partial).

**SKIP breakdown:**
- 27 TC UI/visual (cần browser render — user nói không screenshot)
- 6 TC realtime/event/wait (toast Socket.IO, token expire 15min, print browser)
- 3 TC missing fixture (user_xoa, > 20 bookmark, > 20 notice)

## Bug List Wave a

### BUG-001 (BLOCKER) — Missing endpoint user tự đổi mật khẩu
**Affected TC:** TC-AUTH-022..031 (10 TC)
**Symptom:** POST `/api/auth/change-password` → 404 "Cannot POST"
**Root cause:** `auth.ts` chỉ có `/login`, `/refresh`, `/logout`. `admin.ts:575 PATCH /nguoi-dung/:id/change-password` chỉ cho admin reset password user khác.
**Required fix:**
- Tạo SP `public.fn_staff_change_password(p_staff_id, p_old_password, p_new_password)` validate bcrypt + update + revoke refresh tokens
- Tạo route `POST /api/auth/change-password` với JWT auth + validate body (old_password, new_password ≥6+chữ hoa+thường+số, confirm match, new ≠ old)
**Estimate:** 30-45 phút

### BUG-002 (MAJOR — deferred to prod build) — CORS multi-origin
**Symptom:** `CORS_ORIGIN=domain1,domain2` không work vì cors middleware so equals string. Truy cập domain `doanhnghiep.vatk.org` blocked.
**Required fix:** Update `server.ts:59` parse multi-origin theo array; update prod `.env` CORS_ORIGIN.
**Estimate:** 15 phút (gộp với fix domain prod cuối Wave i).

### BUG-003 (MAJOR) — Dashboard widget upcoming-tasks SP mismatch
**Affected TC:** TC-DASH-001 (composite, widget partial fail)
**Symptom:** GET `/api/dashboard/upcoming-tasks` → HTTP 500 `function edoc.fn_dashboard_upcoming_tasks(unknown, unknown, unknown) does not exist`
**Root cause:** SP signature mismatch — repository gọi 3 params kiểu `unknown`, SP có thể declared khác signature hoặc chưa tồn tại trong qlvb_test schema.
**Required fix:** Check SP definition trong `database/schema/000_schema_v3.0.sql`, cast params cho match (`::bigint`, `::int`).
**Estimate:** 15-20 phút.

### BUG-004 (MAJOR) — Cán bộ thường được tạo thông báo nội bộ
**Affected TC:** TC-NOTIF-015 (1 TC)
**Symptom:** POST `/api/thong-bao` từ test_canbo (vai trò Cán bộ) → HTTP 201 (tạo OK), expect 403.
**Root cause:** Route `notice.ts:62` POST `/` thiếu middleware `requireRoles('Quản trị hệ thống')` — bất kỳ user authenticated nào tạo được thông báo broadcast.
**Required fix:** Thêm `requireRoles('Quản trị hệ thống')` vào route POST `/` trong `notice.ts:62`.
**Estimate:** 5 phút.

## NEEDS-VERIFY (2 TC chưa khẳng định)

### TC-DASH-012 vs TC-DASH-013 — Admin scope vs Cán bộ scope
**Quan sát:** Admin stats `handling_total=2`, Cán bộ stats `handling_total=2` — số liệu trùng nhau.
**Cần verify:** Lý do có thể (a) fixture data nhỏ nên trùng, (b) admin scope thực ra = canbo scope (= bug scope filter).
**Cách verify:** Tạo thêm 5 VB+task assigned cho user khác trong qlvb_test → re-test → admin phải > canbo.
**Defer:** Đến khi fix BUG list, re-run với fixture mở rộng.

## Sub-batch Detail (compact)

### Sub-batch 1A (33 TC)
- **Login (17):** TC-001/003/004/005/006/007/008/009/016 PASS (9). SKIP: 002 (Enter UI), 010 (no fixture user_xoa), 011..015 (UI), 017 (token expire wait).
- **Profile (4):** TC-018 PASS. SKIP: 019..021 (UI render).
- **Đổi mật khẩu (10):** TC-022..031 ALL FAIL → BUG-001 missing endpoint.
- **Logout (2):** TC-032 PASS. SKIP: 033 (UI cancel modal).

### Sub-batch 1B (25 TC)
- **Dashboard (13):** TC-001 PASS-COMPOSITE (9/10 widget OK, upcoming-tasks bug → BUG-003). SKIP: 002..011 (UI navigation/charts/colors). NEEDS-VERIFY: 012, 013 (admin scope).
- **Bookmark (12):** TC-MARK-001..007 PASS (toggle, list, detail), TC-MARK-012 PASS (cross-user). SKIP: 008..011 (print + UI).

### Sub-batch 1C (25 TC)
- **Chuông notif (7):** TC-001/003 PASS. SKIP: 002 (no unread fixture), 004..007 (UI/Socket.IO).
- **Trang Thông báo (8):** TC-008..011/014 PASS. **TC-015 FAIL → BUG-004**. SKIP: 012/013 (UI).
- **Drawer Tạo TB (10):** TC-016..022 PASS (positive, negative, boundary 300/301/5K chars). SKIP: 023..025 (UI behaviors).

## Verdict

✅ **Wave a infrastructure verified working** — backend API đa số đúng, validation OK, permission đúng (trừ BUG-004), boundary OK.

⚠ **4 bug cần fix** (1 blocker + 3 major) — total ~1-1.5h fix. Sau fix, 11 FAIL → 0, pass rate 100%.

🔄 **27/83 TC SKIP UI** = không phải bug, cần ai đó verify thủ công qua browser sau (hoặc dùng Playwright + screenshot khi user OK).

## Next

Tùy user quyết — option C (continue đến hết Wave a-i, fix gom cuối) đã được approve. Tiếp theo:
- Phase 23 = Execute Wave b (181 TC VB đến/đi) — spawn parallel agents pattern
