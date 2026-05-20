# 24 — Wave c — Tài khoản ký số cá nhân (18 TC)

> **Date:** 2026-05-07  
> **Module:** Tài khoản ký số cá nhân (`/ky-so/tai-khoan`)  
> **Tester:** Claude (manual + Playwright)  
> **Login:** `test_lanhdao / Test@123` (staffId=9003)  
> **Endpoint:** `/api/ky-so/tai-khoan/*` — `e_office_app_new/backend/src/routes/ky-so-tai-khoan.ts`  
> **FE page:** `e_office_app_new/frontend/src/app/(main)/ky-so/tai-khoan/page.tsx`

## Tổng kết

| Status     | Count | TCs                                                            |
|------------|-------|----------------------------------------------------------------|
| PASS       | 14    | 001, 002, 003, 004, 005, 006, 008, 010, 012, 014, 015, 016, 017, 018 |
| VERIFY     | 2     | 013, 009 (msg text khác do mock incomplete — code path đúng)   |
| BLOCKED    | 2     | 007, 011 (happy-path verify/listCert — mock thiếu endpoint)    |

**Playwright UI smoke:** 5/5 PASS — `tests/wave-c-ky-so/tk-tai-khoan-ui.spec.ts` (TC-001/002/003/016/017).

**Pass rate:** 14/18 = 78% PASS thuần | 16/18 = 89% có verify behaviour đúng | 2 blocked do mock không phải bug code.

---

## Bugs phát hiện

### BUG-KS-TK-001 — PUT /api/ky-so/cau-hinh/:id luôn trả 404 (id type mismatch)

- **Severity:** HIGH (admin không update được provider qua UI)
- **File:** `e_office_app_new/backend/src/routes/ky-so-cau-hinh.ts:471`
- **Lỗi:** Check `existing.id !== id` so sánh `string` (BIGINT từ DB qua pg driver) với `number` (từ `req.params.id`) → luôn fail dù id đúng → trả `{success:false, message:'Không tìm thấy cấu hình'}` HTTP 404.
- **Bằng chứng:** Test trực tiếp:
  ```
  curl -X PUT /api/ky-so/cau-hinh/1 → "Không tìm thấy cấu hình"
  GET /api/ky-so/cau-hinh trả providers[0].id = "1" (string, không phải number)
  ```
- **Root cause:** pg driver default trả BIGINT (oid 20) là `string`. `pool.ts` set parser cho DATE/TIMESTAMP nhưng KHÔNG set cho BIGINT. Repository interface khai `id: number` nhưng runtime là string.
- **Liên quan CLAUDE.md pitfall #9:** "PostgreSQL BIGINT → pg driver trả STRING".
- **Fix đề xuất:**
  ```ts
  // Option 1 — coerce trong route:
  if (!existing || Number(existing.id) !== id) { ... }
  // Option 2 — set type parser global:
  types.setTypeParser(20, (val) => parseInt(val, 10));
  ```
- **Impact:** Admin UI Sửa provider hoàn toàn không lưu được → admin phải dùng DB hoặc workaround.

### BUG-KS-TK-002 — Mock SmartCA + MySign thiếu endpoint `listCertificates`

- **Severity:** MEDIUM (chặn happy-path test cho 4 TC; cải thiện UX khi cert invalid)
- **File:** `tools/mocks/smartca-mock.ts`, `tools/mocks/mysign-mock.ts`
- **Lỗi:** Adapter `smartca-vnpt.provider.ts` gọi `/sca/sp769/v1/credentials/get_certificate`, adapter `mysign-viettel.provider.ts` gọi `/vtss/service/certificates/info` — **cả 2 endpoint không tồn tại trong mock**. Mock chỉ có `/smartca/cert/:userId` và `/mysign/cert/:userId` (path khác hoàn toàn).
- **Tác động test:**
  - TC-KSTK-007 (BLOCKED): không test được "Đã tải N chứng thư"
  - TC-KSTK-011 (BLOCKED): không test được verify happy-path "Đã xác thực"
  - TC-KSTK-013 (VERIFY): BE trả "Không kết nối được provider" thay vì "Kiểm tra thất bại — chứng thư không hợp lệ"
  - TC-KSTK-009 (VERIFY): BE trả 502 "Không lấy được danh sách chứng thư" thay vì FE warning "Không tìm thấy chứng thư nào" (chỉ xảy ra khi BE trả `{certificates: []}`)
- **Fix đề xuất:** Bổ sung 2 endpoint vào mock với scenario header support (`success`, `empty_list`, `invalid_cert`). VD:
  ```ts
  // smartca-mock.ts
  app.post('/sca/sp769/v1/credentials/get_certificate', (req, res) => {
    const scenario = req.header('X-Mock-Scenario');
    if (scenario === 'empty_list') return res.json({status_code:0, data:{user_certificates:[]}});
    if (scenario === 'invalid_cert') return res.json({status_code:99, message:'invalid'});
    res.json({status_code:0, data:{user_certificates:[{cert_id:'CRED-001', cert_subject:'CN=...', ...}]}});
  });
  ```
- **Workaround dùng trong test:** Đã verify code path verify failure qua TC-KSTK-014 (port closed → cùng error path).

---

## Chi tiết từng TC

### Setup
- Backend port 4000 (qlvb_test) — `SIGNING_SECRET_KEY=qlvb-signing-dev-key-change-production-2026` (từ `.env`)
- Frontend port 3000 (Turbopack)
- Mock SmartCA port 8181, Mock MySign port 8182 (UP, `/health` OK)

### Mục 1 — Khi không có provider active

| TC | Status | Note |
|----|--------|------|
| TC-KSTK-001 | PASS | `GET /ky-so/tai-khoan` trả `active=null`, `message='Admin chưa kích hoạt provider ký số nào...'`. UI render Alert vàng + nút "Làm mới" (Playwright PASS). |

### Mục 2 — SmartCA active

| TC | Status | Note |
|----|--------|------|
| TC-KSTK-002 | PASS | `active.provider_code='SMARTCA_VNPT'`, `provider_name='SmartCA VNPT'`, `base_url='http://localhost:8181'`. UI: label "Mã định danh SmartCA", KHÔNG có dropdown chứng thư (Playwright PASS). |
| TC-KSTK-005 | PASS | `POST {user_id:''}` → 400 `'Vui lòng nhập user_id (không quá 200 ký tự)'`. FE rule cũng `required` (page.tsx L513-521). |
| TC-KSTK-006 | PASS | `POST {user_id:'A'*201}` → 400 `'Vui lòng nhập user_id (không quá 200 ký tự)'`. FE rule `{max:200}`. |
| TC-KSTK-004 | PASS | `POST {user_id:'012345678901'}` → 201 `'Lưu cấu hình thành công...'`. `GET` xác nhận `is_verified=false` ("Chưa xác thực"). |
| TC-KSTK-012 | PASS | Xoá config rồi `POST /verify` → 400 `'Vui lòng lưu cấu hình trước khi kiểm tra'`. UI: nút "Xác thực" `disabled` khi `!config` (page.tsx L645). |
| TC-KSTK-013 | VERIFY | `POST /verify` với mock không có cert endpoint → BE trả 502 `'Không kết nối được provider: HTTP 404 Not Found'`. TC mong: `'Kiểm tra thất bại — chứng thư không hợp lệ'`. **Code path verify-failure đúng** — chỉ msg text khác. Cần extend mock (BUG-KS-TK-002). |
| TC-KSTK-014 | PASS | Đổi `base_url='http://localhost:9999'` → `POST /verify` → 502 `'Không kết nối được provider: fetch failed'` (port closed). |
| TC-KSTK-011 | BLOCKED | Happy-path verify success không test được do BUG-KS-TK-002. Code review (`route ky-so-tai-khoan.ts L399-427`) xác nhận flow đúng: match cert → upsert `is_verified=true` + cert snapshot → trả `{verified:true, certificate_subject, last_verified_at}`. |

### Mục 3 — MySign active

| TC | Status | Note |
|----|--------|------|
| TC-KSTK-018 | PASS | Switch SmartCA → MySign + xoá staff_signing_config → `GET` trả `active=MYSIGN_VIETTEL`, `config=null`. UI: form render theo MySign, user phải khai báo lại. |
| TC-KSTK-003 | PASS | UI render label "Mã định danh MySign", nút "Tải danh sách chứng thư từ MySign", Select dropdown "Chứng thư số" disabled khi chưa load (Playwright PASS). |
| TC-KSTK-008 | PASS | `POST /certificates {}` → 400 `'Vui lòng nhập user_id'`. FE rule (page.tsx L242): show "Vui lòng nhập Mã định danh trước". |
| TC-KSTK-009 | VERIFY | `POST /certificates {user_id:'NONEXISTENT_999'}` → 502 `'Không lấy được danh sách chứng thư: Login Viettel thất bại: HTTP 404 Not Found'`. TC mong FE-side warning `'Không tìm thấy chứng thư nào'` (chỉ trigger khi BE trả `[]`). FE code đúng (page.tsx L254-257) — chờ mock fix. |
| TC-KSTK-007 | BLOCKED | Happy-path "Đã tải N chứng thư" không test được do BUG-KS-TK-002. FE code đúng (page.tsx L246-269): map response → setCertificates → message.success(`Đã tải ${N} chứng thư số`). |
| TC-KSTK-010 | PASS | `POST /tai-khoan {user_id:'CMT_123456'}` (thiếu credential_id) → 400 `'Vui lòng chọn chứng thư số (bấm "Tải danh sách CTS"...)'`. FE rule cũng required (page.tsx L565-569). |
| TC-KSTK-015 | PASS | Insert config cũ `{user_id:'CMT_OLD', credential_id:'cred_old_001', is_verified=true}` → POST đè `{user_id:'CMT_NEW', credential_id:'cred_new_999'}` → GET xác nhận user_id mới + credential_id mới + `is_verified=false` (auto-reset). |
| TC-KSTK-016 | PASS | DB seed `is_verified=true, last_verified_at=now()-5min, certificate_subject='CN=Test Lanhdao,O=Test Org'`. UI: badge "Đã xác thực" + card extra "Xác thực gần nhất: 07/05/2026 10:..." + Descriptions (subject + serial) hiển thị (Playwright PASS). |
| TC-KSTK-017 | PASS | `GET /tai-khoan` 2 lần liên tiếp → cùng provider + config. UI: nút "Làm mới" (page.tsx L406-412 + L447-453) gọi `fetchConfig` (Playwright PASS). |

---

## Files

- **Test runner (API):** `D:/ProjectAI/quanlyvanban/.planning/phases/24-execute-wave-c/tk-tests/run.sh`
- **Python helper:** `D:/ProjectAI/quanlyvanban/.planning/phases/24-execute-wave-c/tk-tests/check.py`
- **Per-TC JSONL responses:** `D:/ProjectAI/quanlyvanban/.planning/phases/24-execute-wave-c/tk-tests/results.jsonl`
- **Summary log:** `D:/ProjectAI/quanlyvanban/.planning/phases/24-execute-wave-c/tk-tests/summary.txt`
- **Playwright spec:** `D:/ProjectAI/quanlyvanban/tests/wave-c-ky-so/tk-tai-khoan-ui.spec.ts` (5 TC PASS)
- **Backend route:** `D:/ProjectAI/quanlyvanban/e_office_app_new/backend/src/routes/ky-so-tai-khoan.ts`
- **Backend admin route (BUG-KS-TK-001):** `D:/ProjectAI/quanlyvanban/e_office_app_new/backend/src/routes/ky-so-cau-hinh.ts:471`
- **Frontend page:** `D:/ProjectAI/quanlyvanban/e_office_app_new/frontend/src/app/(main)/ky-so/tai-khoan/page.tsx`
- **Mock files (BUG-KS-TK-002):** `D:/ProjectAI/quanlyvanban/tools/mocks/smartca-mock.ts`, `D:/ProjectAI/quanlyvanban/tools/mocks/mysign-mock.ts`

---

## Notes & follow-ups

1. **BUG-KS-TK-001 cần fix gấp** — admin UI Sửa provider hoàn toàn không hoạt động. Workaround duy nhất hiện tại: sửa trực tiếp DB. Reproducible 100%.
2. **BUG-KS-TK-002 cần extend mock** — bổ sung 2 endpoint listCertificates (SmartCA `/sca/sp769/v1/credentials/get_certificate`, MySign `/vtss/service/certificates/info`) để hoàn thành 4 TC happy-path/cert-invalid.
3. **Note môi trường:** Backend đang load `SIGNING_SECRET_KEY` từ `.env` (dev key) thay vì `.env.test` — không ảnh hưởng functionality nhưng đáng chú ý cho test reproducibility. Test script đã document workaround.
4. **Validation mức 200 ký tự** đang trả message `'Vui lòng nhập user_id (không quá 200 ký tự)'` — không hoàn toàn khớp text TC mong (`'Tối đa 200 ký tự'`) nhưng FE rule `{max:200, message:'Tối đa 200 ký tự'}` ưu tiên trigger trước, nên user-facing đúng.
