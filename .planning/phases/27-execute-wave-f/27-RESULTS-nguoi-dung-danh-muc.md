# Wave f — Boundary Tests — Người dùng + 4 Danh mục + Cấu hình gửi nhanh

**Tester:** Agent 2 (AI)
**Date:** 2026-05-07
**Backend:** http://localhost:4000 (DB: qlvb_test)
**Login:** admin / Admin@123 (staffId=1, isAdmin=true)
**Scope:** Wave f modules[9, 11, 12, 13, 14, 15] = 24 testcases
**Method:** Direct API test via curl + DB verification via psql

---

## Summary

| Module | Total | PASS | FAIL/BUG | NOTE |
|---|---:|---:|---:|---:|
| 9. Quản trị Người dùng | 12 | 9 | 3 | TC-002, TC-004, TC-007 |
| 11. Sổ văn bản | 2 | 2 | 0 | |
| 12. Loại văn bản | 3 | 3 | 0 | (status code minor) |
| 13. Lĩnh vực | 2 | 2 | 0 | |
| 14. Người ký | 3 | 3 | 0 | (sort_order ignored on create) |
| 15. Cấu hình gửi nhanh | 2 | 2 | 0 | TC-002 limited by data |
| **TOTAL** | **24** | **21** | **3** | **3 BUGS** |

---

## Detailed Results

### Module 9: Quản trị Người dùng — `POST /api/quan-tri/nguoi-dung`

| TC ID | Title | Status | Actual | Expected |
|---|---|---|---|---|
| TC-BND-QTND-001 | username 50 chars | **PASS** | 201, id=9106 | 201 OK |
| TC-BND-QTND-002 | username 51 chars | **FAIL — BUG-F-ND-001** | 500 raw PG error: `value too long for type character varying(50)` | 400 Vietnamese friendly msg |
| TC-BND-QTND-003 | username trùng 'admin' | **PASS** | 409 "Tên đăng nhập đã tồn tại" | 409 OK |
| TC-BND-QTND-004 | first_name 50 + last_name 50 (full_name STORED 100 overflow) | **FAIL — BUG-F-ND-002** | 500 raw PG: `value too long for type character varying(100)` | 400 friendly msg về full_name |
| TC-BND-QTND-005 | last_name rỗng | **PASS** | 400 "Họ và tên là bắt buộc" | 400 required |
| TC-BND-QTND-006 | email 100 chars valid | **PASS** | 201, id=9108 | OK |
| TC-BND-QTND-007 | phone 20 + mobile 20 (DB VARCHAR(20)) | **FAIL — BUG-F-ND-003** | 400 "Số điện thoại không đúng định dạng" — regex `{8,15}` chặn 20 ký tự | OK theo DB limit |
| TC-BND-QTND-008 | id_card 12 chars | **PASS** | 201, id=9109 | OK |
| TC-BND-QTND-009 | id_card_place 200 chars | **PASS** | 201, id=9110 | OK |
| TC-BND-QTND-010 | birth_date = 2050-01-01 (tương lai) | **PASS** (no rule) | 201, id=9111 — no validation | Accept w/o rule, doc gap |
| TC-BND-QTND-011 | birth_date = 1900-01-01 | **PASS** (no rule) | 201, id=9112 | OK |
| TC-BND-QTND-012 | Reset password user (test_canbo) | **PASS partial** | 200 reset OK, login với Admin@123 thành công. Nhưng `password_changed` vẫn = `false` (đúng nghiệp vụ — buộc đổi pass lần đầu) | OK |

### Module 11: Danh mục Sổ văn bản — `POST /api/quan-tri/so-van-ban`

| TC ID | Title | Status | Actual |
|---|---|---|---|
| TC-BND-DMSV-001 | name 200 chars | **PASS** | 201, id=51 |
| TC-BND-DMSV-002 | name 201 chars | **PASS** | 400 "Tên sổ văn bản không được vượt quá 200 ký tự" (validated tại route) |

### Module 12: Danh mục Loại văn bản — `POST /api/quan-tri/loai-van-ban`

| TC ID | Title | Status | Actual |
|---|---|---|---|
| TC-BND-DMLV-001 | code 20 + name 200 | **PASS** | 201, id=21 |
| TC-BND-DMLV-002 | code 21 chars | **PASS** | 400 "Mã loại văn bản không được vượt quá 20 ký tự" |
| TC-BND-DMLV-003 | code='QD' trùng | **PASS** | 400 "Mã loại văn bản đã tồn tại" — minor: spec mong 409 nhưng route trả 400 (vì SP tự reject thay vì PG unique violation đụng `handleDbError`); thông điệp đúng tiếng Việt |

### Module 13: Danh mục Lĩnh vực — `POST /api/quan-tri/linh-vuc`

| TC ID | Title | Status | Actual |
|---|---|---|---|
| TC-BND-DMLN-001 | code 20 + name 200 | **PASS** | 201, id=21 |
| TC-BND-DMLN-002 | code='  TESTLN  ' (có space) | **PASS** | 201, lưu code='TESTLN' (6 chars), backend trim đúng |

### Module 14: Danh mục Người ký — `POST /api/quan-tri/nguoi-ky`

| TC ID | Title | Status | Actual |
|---|---|---|---|
| TC-BND-DMNK-001 | thêm staff 9001 vào unit 1, sort_order default | **PASS** | 201, id=1, sort_order=0 |
| TC-BND-DMNK-002 | thêm lại staff 9001 vào unit 1 (duplicate UNIQUE) | **PASS** | 400 "Nhân viên đã có trong danh sách người ký" |
| TC-BND-DMNK-003 | sort_order = -1 | **PASS partial** | 201, nhưng backend bỏ qua field `sort_order` từ body, lưu mặc định = 0. API không expose sort_order trên POST. Doc gap |

### Module 15: Cấu hình gửi nhanh — `POST /api/cau-hinh-gui-nhanh`

| TC ID | Title | Status | Actual |
|---|---|---|---|
| TC-BND-CHGN-001 | 0 recipients | **PASS** | 200 "Đã lưu 0 người nhận" — backend chấp nhận empty (không enforce min 1) |
| TC-BND-CHGN-002 | 100 recipients | **PASS partial** | DB qlvb_test chỉ có 13 staff (12 ngoài admin) → tested với 12 IDs, save OK ("Đã lưu 12 người nhận"). Cần data lớn hơn để verify ngưỡng 100 thực tế |

---

## Bug Tickets

### BUG-F-ND-001 — Username overflow trả 500 raw PG error
- **Severity:** Medium
- **Endpoint:** `POST /api/quan-tri/nguoi-dung`
- **Repro:** body `{"username":"<51 chars>",...}`
- **Actual:** HTTP 500, body `{"success":false,"message":"value too long for type character varying(50)"}` — tiếng Anh, raw PG message
- **Expected:** HTTP 400, body `{"success":false,"message":"Tên đăng nhập tối đa 50 ký tự"}`
- **Root cause:** Route `admin.ts` POST /nguoi-dung không validate `username.length > 50` trước khi gọi SP. Nên khi vượt giới hạn → PG raise → handleDbError default rơi vào path 500 với raw message (do `process.env.NODE_ENV !== 'production'`).
- **Fix:** Thêm validation `if (username.trim().length > 50) return 400 'Tên đăng nhập không được vượt quá 50 ký tự'` (giống pattern các route admin-catalog).

### BUG-F-ND-002 — full_name STORED VARCHAR(100) overflow chưa có guard
- **Severity:** High (schema design + UX)
- **Endpoint:** `POST /api/quan-tri/nguoi-dung`
- **Repro:** body `{"first_name":"<50 chars>","last_name":"<50 chars>",...}` → PG generate full_name = first_name + ' ' + last_name = 101 chars
- **Actual:** HTTP 500 `"value too long for type character varying(100)"`
- **Expected:** Có 1 trong 2 hướng:
  1. **Fix schema:** mở rộng `full_name` → `VARCHAR(150)` (≥ first_name 50 + space 1 + last_name 50 = 101)
  2. **Validate route:** chặn `first_name.length + last_name.length + 1 > 100` trước khi gọi SP, trả 400 "Tổng độ dài họ và tên không vượt quá 100 ký tự"
- **Note:** TC-BND-QTND-004 trong spec chính thức đánh dấu đây là "edge case schema design" cần verify. Đã verify → có bug.

### BUG-F-ND-003 — Phone regex `{8,15}` không khớp DB VARCHAR(20)
- **Severity:** Medium
- **Endpoint:** `POST /api/quan-tri/nguoi-dung` (cả PUT)
- **Repro:** body `{"phone":"+84-0123456789012345"}` (đúng 20 ký tự, DB cho phép)
- **Actual:** HTTP 400 "Số điện thoại không đúng định dạng" — backend regex `^[0-9+\-\s()]{8,15}$` cap 15 chars
- **Expected:** Accept lên tới 20 chars (khớp DB column VARCHAR(20))
- **Fix:** Sửa regex thành `^[0-9+\-\s()]{8,20}$` (cả `phone` và `mobile`)
- **Tham chiếu:** CLAUDE.md mục #11 "Số điện thoại — `pattern: /^[0-9+\-\s()]*$/`" — không có rule độ dài, nhưng hiện tại backend giới hạn 15.

---

## Documentation Gaps (Non-bug findings — UX/spec gaps)

| Gap ID | Module | Issue | Recommendation |
|---|---|---|---|
| GAP-F-ND-A | QTND-010 / QTND-011 | Không có rule `birth_date <= today` hoặc `birth_date >= 1900` | Thêm validation tại frontend (Form rules) hoặc backend (route) — dependency với CLAUDE.md "Date range validation" |
| GAP-F-ND-B | QTND-012 | Sau reset password, `password_changed` flag không reset về `false` (đã sẵn = `false` ở record cũ) | Verify SP `fn_staff_reset_password` set `password_changed = FALSE` → đảm bảo user buộc đổi pass lần kế |
| GAP-F-DMLV-A | DMLV-003 | Unique violation trả HTTP 400 thay vì 409 (theo convention REST) | Fix trong SP/route: throw để rớt vào `handleDbError` (auto map 23505 → 409 + message) thay vì SP return success:false |
| GAP-F-DMNK-A | DMNK-003 | API POST `/nguoi-ky` không hỗ trợ `sort_order` từ client | Hoặc: thêm param + validate `min 0` tại route; hoặc document rõ "sort_order chỉ chỉnh sửa qua endpoint riêng nếu có" |
| GAP-F-CHGN-A | CHGN-001 | Backend chấp nhận lưu cấu hình rỗng (0 người nhận) — UI cần guard `min 1` nếu nghiệp vụ yêu cầu | Frontend Form rule hoặc backend check theo nghiệp vụ |
| GAP-F-CHGN-B | CHGN-002 | DB qlvb_test chỉ có 13 staff → không test được boundary thực tế 100. Cần seed thêm để test perf/load | Khi seed test cho wave này, đảm bảo ≥ 100 staff |

---

## Test data created (cleanup notes)

Created test users (id 9106, 9108, 9109, 9110, 9111, 9112) trong `qlvb_test`. Created doc_book id=51, doc_type id=21, doc_field id=21+22, signers id=1+2. Cấu hình gửi nhanh cho admin với 12 user.

Các test data này ở DB `qlvb_test` (không phải prod/dev). Có thể giữ lại làm seed cho regression hoặc xóa khi reset DB sau wave g.
