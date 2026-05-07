# Wave f Boundary Tests — Results: Auth + Notif + Admin (5 modules)

**Generated:** 2026-05-07
**Tester:** Tester AI (automated via REST API)
**Source TCs:** `tools/screenshots/testcases-wave-f.json` modules [0,1,7,8,10]
**Total TCs:** 27
**Method:** API-level boundary tests (Python urllib + admin/test_canbo JWT)

## Summary

| Status | Count | % |
|---|---:|---:|
| PASS | 22 | 81% |
| FAIL | 4 | 15% |
| SKIP | 1 | 4% |
| **Total** | **27** | **100%** |

## Schema vs Test-Case Mismatches Discovered

| Field | TC Assumption | Actual DB | Actual Backend Behavior |
|---|---|---|---|
| `edoc.notices.title` | VARCHAR(200) | VARCHAR(300) | Route validates `> 300` |
| `public.roles.name` | VARCHAR(200) | VARCHAR(100) | Route relies on DB constraint |

→ Test cases `TC-BND-NOTIF-002` & `TC-BND-QTNQ-001` need re-baseline against actual schema.

## Bugs Found

### BUG-F-001 — `lgsp_system_id` / `lgsp_secret_key` không được lưu khi tạo đơn vị
- **Severity:** Medium
- **Endpoint:** `POST /api/quan-tri/don-vi`
- **File:** `backend/src/routes/admin.ts:101-105` (destructure body)
- **Symptom:** Body có 2 field này nhưng route không destructure, không truyền cho `departmentRepository.create()` → field bị bỏ qua silent
- **Repro:** POST `{ code, name, parent_id, lgsp_system_id: 'L'*50, lgsp_secret_key: 'S'*100 }` → 201 OK, nhưng GET `/don-vi/:id` cho thấy 2 field NULL
- **Lib:** Cùng lỗi tại `PUT /don-vi/:id` (admin.ts:145-149)
- **Fix:** Thêm 2 field vào destructure + extend `departmentRepository.create/update` signature, hoặc tạo SP riêng `fn_department_lgsp_set`
- **Liên quan TC:** TC-BND-QTDV-010 (PASS theo HTTP, nhưng functionality fail)

### BUG-F-002 — Backend không validate format phone (`/^[0-9+\-\s()]*$/`)
- **Severity:** Low (defense-in-depth)
- **Endpoint:** `POST /api/quan-tri/don-vi`
- **Symptom:** Backend chấp nhận `phone='0912abc678'` (chứa chữ cái)
- **Hiện tại:** Validation chỉ ở Frontend (Form rule). Bypass FE → backend save invalid data
- **Liên quan TC:** TC-BND-QTDV-007 (FAIL — TC expect reject)
- **Fix:** Thêm regex check trong route handler hoặc SP `fn_department_create`

### BUG-F-003 — Backend không validate format email
- **Severity:** Low (defense-in-depth)
- **Endpoint:** `POST /api/quan-tri/don-vi`
- **Symptom:** Backend chấp nhận `email='abc.gmail.com'` (thiếu `@`)
- **Hiện tại:** Validation chỉ ở Frontend
- **Liên quan TC:** TC-BND-QTDV-009 (FAIL — TC expect reject)
- **Fix:** Thêm `if (email && !/^\S+@\S+\.\S+$/.test(email))` trong route hoặc dùng zod schema

### BUG-F-004 — VARCHAR overflow trả HTTP 500 + raw PG message
- **Severity:** Medium (UX + security: leak DB internals)
- **Endpoints:** `POST /quan-tri/don-vi`, `POST /quan-tri/chuc-vu`
- **Symptom:**
  - `code` 51 ký tự → `500 "value too long for type character varying(50)"`
  - `abb_name` 21 ký tự → `500 "value too long for type character varying(20)"`
  - `name` 101 ký tự (chuc-vu) → `500 "value too long for type character varying(100)"`
- **Expected:** HTTP 400 với message tiếng Việt: `"Mã không được vượt quá 50 ký tự"`
- **Cause:** `handleDbError()` trong `lib/error-handler.ts` chưa map PostgreSQL SQLSTATE `22001` (string_data_right_truncation)
- **Fix:** Thêm case `22001` trong handler:
  ```ts
  if (err.code === '22001') {
    return res.status(400).json({ success: false, message: 'Dữ liệu nhập vào quá dài' });
  }
  ```
- **Liên quan TC:** QTDV-002, QTDV-005, QTCV-002 (PASS theo expected reject, nhưng quality issue)

## Per-TC Results

### Module 0: Auth — Đổi mật khẩu (6 TC)

| TC | Verdict | Note |
|---|---|---|
| TC-BND-AUTH-001 | PASS | 6 ký tự `Abcd12` (hoa+thường+số) → 200 OK |
| TC-BND-AUTH-002 | PASS | 5 ký tự → 400 "ít nhất 6 ký tự" |
| TC-BND-AUTH-003 | PASS | `abcd12` (thiếu hoa) → 400 reject |
| TC-BND-AUTH-004 | PASS | `AbcDef` (thiếu số) → 400 reject |
| TC-BND-AUTH-005 | PASS | new=old → 400 "không được trùng" |
| TC-BND-AUTH-006 | SKIP | confirmPassword check chỉ ở FE (Form rule), backend không nhận field này |

**Note bổ sung:** Backend route yêu cầu cả chữ thường (`/[a-z]/.test`) — không khớp 100% với expected message của TC ("chữ hoa và số") nhưng quy định mạnh hơn nên TC-001 vẫn PASS với input có cả 3.

### Module 1: Thông báo nội bộ — Notices (4 TC)

| TC | Verdict | Note |
|---|---|---|
| TC-BND-NOTIF-001 | PASS | title 200 ký tự → 201 OK (DB cho phép tới 300) |
| TC-BND-NOTIF-002 | **FAIL** | title 201 ký tự → 201 OK (TC giả định limit=200, thực tế DB+route=300). Bonus 301 chars → 400 "Tiêu đề không được vượt quá 300 ký tự" |
| TC-BND-NOTIF-003 | PASS | title 1 ký tự → 201 OK |
| TC-BND-NOTIF-004 | PASS | content 5000 ký tự → 201 OK |

### Module 7: Quản trị Đơn vị — Departments (10 TC)

| TC | Verdict | Note |
|---|---|---|
| TC-BND-QTDV-001 | PASS | code 50 → 201 OK |
| TC-BND-QTDV-002 | PASS | code 51 → 500 (PG raw) — see BUG-F-004 |
| TC-BND-QTDV-003 | PASS | name 200 + name_en 200 → 201 OK |
| TC-BND-QTDV-004 | PASS | abb_name 20 → 201 OK |
| TC-BND-QTDV-005 | PASS | abb_name 21 → 500 (PG raw) — see BUG-F-004 |
| TC-BND-QTDV-006 | PASS | phone `+84-(24)-1234-5678` → 201 OK |
| TC-BND-QTDV-007 | **FAIL** | phone `0912abc678` → 201 OK — see BUG-F-002 |
| TC-BND-QTDV-008 | PASS | email 97 ký tự (`a*91 + @x.com`) → 201 OK |
| TC-BND-QTDV-009 | **FAIL** | email `abc.gmail.com` → 201 OK — see BUG-F-003 |
| TC-BND-QTDV-010 | PASS-with-bug | dept tạo OK nhưng lgsp_system_id/lgsp_secret_key bị bỏ qua — see BUG-F-001 |

### Module 8: Quản trị Chức vụ — Positions (4 TC)

| TC | Verdict | Note |
|---|---|---|
| TC-BND-QTCV-001 | PASS | name 100 ký tự → 201 OK |
| TC-BND-QTCV-002 | PASS | name 101 → 500 (PG raw) — see BUG-F-004 |
| TC-BND-QTCV-003 | PASS | code 20 → 201 OK |
| TC-BND-QTCV-004 | PASS | name rỗng → 400 "Tên chức vụ là bắt buộc" |

### Module 10: Quản trị Nhóm quyền — Roles (3 TC)

| TC | Verdict | Note |
|---|---|---|
| TC-BND-QTNQ-001 | **FAIL** | name 200 ký tự → 500 PG overflow (DB roles.name=VARCHAR(100), TC giả định 200). Bonus name=100 → 201 OK |
| TC-BND-QTNQ-002 | PASS | rightIds=[] → 200 OK (không bắt buộc 1+) |
| TC-BND-QTNQ-003 | PASS | gán tất cả 22 quyền → 200 OK |

## Action Items

1. **Fix BUG-F-001** (lgsp fields): bổ sung destructure + repo signature, hoặc tách SP riêng. Priority: **Medium**.
2. **Fix BUG-F-004** (HTTP 500 → 400): thêm SQLSTATE `22001` mapping trong `lib/error-handler.ts`. Priority: **Medium** (UX + security).
3. **Triage BUG-F-002/003** (FE-only validation): quyết định có require backend validation cho phone/email không (defense-in-depth). Priority: **Low**.
4. **Re-baseline TC-BND-NOTIF-002 & TC-BND-QTNQ-001**: cập nhật giá trị biên cho khớp DB schema thật (300 cho notices.title, 100 cho roles.name).
5. **Bổ sung TC-BND-AUTH-006**: thực hiện E2E qua UI (Playwright) vì là FE Form rule, không test được qua API.
