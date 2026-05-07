# Wave f Boundary — Du thao + HSCV + Ky so (20 TC)

**Agent:** Tester AI (Agent 2)
**Date:** 2026-05-07
**Scope:** modules[4,5,6,16] from `tools/screenshots/testcases-wave-f.json`
**Backend:** http://localhost:4000 (env=test, DB=qlvb_test)
**Accounts:** admin/Admin@123, test_canbo/Test@123 (id=9004, dept=2), test_lanhdao/Test@123 (id=9003, dept=2)

## Summary

| Module | Total | PASS | FAIL/BUG | NOT TESTABLE |
|---|---|---|---|---|
| 4 — Van ban du thao | 4 | 3 | 1 | 0 |
| 5 — Ho so cong viec | 9 | 6 | 1 | 2 |
| 6 — Cau hinh ky so HT | 5 | 2 | 3 (blocked) | 0 |
| 16 — Tai khoan ky so CN | 2 | 2 | 0 | 0 |
| **Total** | **20** | **13** | **5** | **2** |

PASS rate: 13/20 = 65%. Excluding NOT TESTABLE (no write API): 13/18 = 72%.

---

## Module 4 — Van ban du thao (4 TC)

### TC-BND-VBT-001 — notation 100 + abstract 5000 — PASS
- POST `/api/van-ban-du-thao` with `notation` len=100, `abstract` len=5000.
- Response: `{"success":true,"data":{"id":"90003"}}`.
- DB verify (`edoc.drafting_docs`): `notation_len=100`, `abstract_len=5000`. OK.

### TC-BND-VBT-002 — reject_reason 5000 chars — PASS
- PATCH `/api/van-ban-du-thao/90003/tu-choi` with `reason` len=5000 as `test_lanhdao`.
- Response: `{"success":true,"data":{"message":"Da tu choi van ban du thao"}}`.
- DB verify: `rejection_reason` len=5000, `rejected_by=9003`. OK.
- Note: minor business issue — `status` not changed to `'rejected'` after reject (still `'draft'`). SP `fn_drafting_doc_reject` only sets `rejection_reason + rejected_by`. Out of scope for boundary test.

### TC-BND-VBT-003 — sub_number 20 chars — PASS
- POST with `sub_number` len=20.
- DB verify: `sub_number` stored as 20-char string. OK.

### TC-BND-VBT-004 — number_copies = 0 — BUG (silent default)
- POST with `number_copies: 0`.
- Response: success, `id=90005`. DB stores `number_copies=1`.
- **BUG-F-DT-001 (Low):** Falsy check `body.number_copies ? Number(body.number_copies) : 1` in `routes/drafting-doc.ts:258` and `:348` silently coerces `0` to default `1`. TC says "ghi nhan thuc te" — TC accepts default but UX-confusing (user sends 0, system records 1, no warning). Recommend: use `body.number_copies !== undefined && body.number_copies !== null ? Number(body.number_copies) : 1` OR validate `number_copies >= 1` and return 400.

---

## Module 5 — Ho so cong viec (9 TC)

### TC-BND-HSCV-001 — name 500 chars — PASS
- POST `/api/ho-so-cong-viec` with `name` len=500.
- Response: success, `id=9003`. DB `name_len=500`. OK.

### TC-BND-HSCV-002 — name 501 chars — PASS (rejected) but message UX-poor
- POST with `name` len=501.
- Response: `{"success":false,"message":"value too long for type character varying(500)"}`.
- **BUG-F-HSCV-001 (Medium):** Raw PostgreSQL error message in English leaks to client. Should be Vietnamese, e.g., "Ten ho so khong duoc qua 500 ky tu". Fix at `handleDbError` to map `22001 string_data_right_truncation` → VN message. Acceptance: TC says "form chan hoac backend bao loi" — backend rejects, so functional PASS, but error UX is weak.

### TC-BND-HSCV-003 — name empty — PASS
- POST with `name: ""`.
- Response: `{"success":false,"message":"Ten ho so cong viec la bat buoc"}`. OK.

### TC-BND-HSCV-004 — start_date = end_date — PASS
- POST with `start_date = end_date = 2026-05-05`.
- Response: success, `id=9004`. DB stores both dates equal. OK.

### TC-BND-HSCV-005 — start_date > end_date — PASS
- POST with `start_date=2026-06-01, end_date=2026-05-01`.
- Response: `{"success":false,"message":"Han giai quyet phai sau hoac bang ngay mo"}`. OK (validated by SP).

### TC-BND-HSCV-006 — doc_notation 100 chars — NOT TESTABLE
- Column `doc_notation VARCHAR(100)` exists in `edoc.handling_docs`.
- SP `fn_handling_doc_create` and `fn_handling_doc_update` signatures do NOT include `p_doc_notation`. Route `POST/PUT /api/ho-so-cong-viec` doesn't accept `doc_notation` in body.
- **GAP-F-HSCV-001 (Low):** Display-only column with no write API. Either add `doc_notation` to SP+route+UI, or drop the column. Recommend: defer until business requirement clarified.

### TC-BND-HSCV-007 — comments 10000 chars — PASS
- POST with `comments` len=10000.
- Response: success, `id=9005`. DB `comments_len=10000`. OK (TEXT type, no boundary).

### TC-BND-HSCV-008 — 50 file upload — PASS (performance OK)
- 50 sequential uploads of small text files via POST `/api/ho-so-cong-viec/9007/dinh-kem`.
- All 50 succeeded. Elapsed: 20s (avg 400ms/file). DB count = 50. List endpoint returned all 50.
- Performance note: 400ms/file is acceptable for sequential. Consider async/parallel if UX requires faster.

### TC-BND-HSCV-009 — workflow step 50 chars — NOT TESTABLE
- Column `step VARCHAR(50)` exists in `edoc.handling_docs`.
- No write API exposes `step` (only auto-set when `workflow_id` triggers — but no test workflow with 50-char step in seed).
- **GAP-F-HSCV-002 (Low):** Skipped. Workflow step length not testable without seeding a workflow with VARCHAR(50) step name.

---

## Module 6 — Cau hinh ky so he thong (5 TC)

### TC-BND-KSCH-001 — provider_name 100 chars — BLOCKED by BUG-F-KS-001
- PUT `/api/ky-so/cau-hinh/1` with `provider_name` len=100.
- Response: `{"success":false,"message":"Khong tim thay cau hinh"}`. **404 ERROR** despite valid id.
- DB direct UPDATE confirms VARCHAR(100) accepts 100 chars (`pn_len=100`).
- **BUG-F-KS-001 (HIGH):** Type mismatch in id comparison at `routes/ky-so-cau-hinh.ts:471`:
  ```ts
  if (!existing || existing.id !== id) { 404 }
  ```
  `existing.id` is STRING (BIGINT from `pg` driver), `id` is NUMBER (`Number(req.params.id)`). `"1" !== 1` → true → 404 always. Fix: `Number(existing.id) !== id`.

### TC-BND-KSCH-002 — base_url 500 chars — BLOCKED by BUG-F-KS-001
- Same root cause. DB direct UPDATE confirms VARCHAR(500) accepts 500 chars.

### TC-BND-KSCH-003 — base_url HTTP (not HTTPS) — PASS
- PUT with `base_url: "http://demo.smartca.vn"`.
- Response: `{"success":false,"message":"base_url phai la HTTPS (tru localhost)"}`. OK.
- Validation runs BEFORE the buggy id check, so this works.

### TC-BND-KSCH-004 — client_id 200 + client_secret 200 — BLOCKED by BUG-F-KS-001
- Same root cause.

### TC-BND-KSCH-005 — provider_code = 'CUSTOM' — PASS
- PUT with `provider_code: "CUSTOM"`.
- Response: `{"success":false,"message":"provider_code khong hop le"}`. Backend validates against allowlist `['SMARTCA_VNPT','MYSIGN_VIETTEL']` BEFORE reaching id check.
- DB-level CHECK constraint `chk_provider_code` also rejects (verified independently).

---

## Module 16 — Tai khoan ky so ca nhan (2 TC)

Pre-step: activated SmartCA provider via direct DB UPDATE (because PUT API blocked by BUG-F-KS-001). Set `is_active=true`, `client_secret = pgp_sym_encrypt('mySecretLong12345678', 'qlvb-signing-dev-key-change-production-2026')`.

### TC-BND-KSTK-001 — user_id 200 + credential_id 200 — PASS
- POST `/api/ky-so/tai-khoan` as `test_canbo` with both fields len=200.
- Response: `{"success":true,"message":"Luu cau hinh thanh cong. Vui long bam \"Kiem tra\" de xac thuc."}`.
- DB verify: `staff_signing_config(staff_id=9004, provider_code='SMARTCA_VNPT', uid_len=200, cid_len=200)`. OK.

### TC-BND-KSTK-002 — user_id empty — PASS
- POST with `user_id: ""`.
- Response: `{"success":false,"message":"Vui long nhap user_id (khong qua 200 ky tu)"}`. OK.

---

## Bugs Summary

| Bug ID | Severity | Module | Issue |
|---|---|---|---|
| **BUG-F-KS-001** | **HIGH** | Cau hinh ky so | `routes/ky-so-cau-hinh.ts:471` — type mismatch `existing.id !== id` (string vs number). Blocks ALL provider PUT updates. Fix: `Number(existing.id) !== id`. Affects TC-KSCH-001, 002, 004 (3 TCs blocked). |
| **BUG-F-HSCV-001** | Medium | HSCV | `handleDbError` doesn't map PostgreSQL `22001 string_data_right_truncation` to VN message. Raw "value too long for type character varying(500)" leaked to UI. |
| **BUG-F-DT-001** | Low | Du thao | `routes/drafting-doc.ts:258,348` falsy check on `number_copies` silently coerces `0` to `1`. Recommend explicit `!= null` check or `>= 1` validation. |

## Gaps (NOT TESTABLE)

| Gap ID | Module | Issue |
|---|---|---|
| GAP-F-HSCV-001 | HSCV | `doc_notation VARCHAR(100)` column exists but no write API exposes it. SP `fn_handling_doc_create/update` lacks `p_doc_notation`. |
| GAP-F-HSCV-002 | HSCV | `step VARCHAR(50)` column exists but only set indirectly via workflow association; no test workflow seeded with 50-char step. |

## Side Effects of Testing

- Inserted test fixtures (staff 9001-9005, 9099 + role assignments) in `qlvb_test`. Required because `test_canbo`/`test_lanhdao` login worked (JWT issued) but DB rows were missing — `database/seed/003_test_fixtures.sql` has a downstream bug (`sent_by` column doesn't exist in `user_incoming_docs`) that aborts the whole transaction. Loaded only the staff+roles INSERTs.
- Created drafting docs id=90003-90005 in `qlvb_test`.
- Created handling docs id=9003-9007 (90007 has 50 attachments) in `qlvb_test`.
- Updated `signing_provider_config` row id=1 (SmartCA) to `is_active=true` with mock secret in `qlvb_test`.
- No production data touched.
