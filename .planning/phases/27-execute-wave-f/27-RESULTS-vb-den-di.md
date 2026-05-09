# Wave f — Boundary Tests — VB đến + VB đi

**Phase:** 27-execute-wave-f
**Date:** 2026-05-07
**Tester:** Tester AI (agent 3)
**Scope:** 26 TC (16 VBĐ + 10 VBI) từ `tools/screenshots/testcases-wave-f.json` modules[2,3]
**User:** test_vanthu (Văn thư, Sở Nội vụ unit_id=2)
**DocBook:** Sổ VB đến id=4 / Sổ VB đi id=5 (đều `unit_id=2`)
**Method:** REST API thuần qua `curl` + Node multipart cho TC Unicode filename. Không Playwright.

---

## Tổng kết

| Module | Total | PASS | FAIL/BUG | Notes |
|--------|-------|------|----------|-------|
| VB đến (BND-VBD) | 16 | 13 | 3 | 1 BUG validation (số trang âm), 1 BUG boundary (50MB exact), 1 ghi nhận behavior (expired<received only frontend rule) |
| VB đi (BND-VBI) | 10 | 6 | 4 | 1 BUG silent drop (approver), 1 BUG nghiệp vụ (dup notation), 1 SECURITY (.exe accepted), 1 ghi nhận behavior (publish>expired only frontend rule) |
| **Tổng** | **26** | **19** | **7** | |

> "FAIL/BUG" gộp cả lỗi nghiệp vụ + lỗi UX. Các test "expected reject" mà backend đã reject ở DB layer (raw PG message) được tính PASS vì kết quả cuối cùng đúng nhưng ghi nhận thêm 1 minor improvement về error message i18n.

---

## VB đến — chi tiết 16 TC

| TC | Title | Result | Evidence | Note |
|----|-------|--------|----------|------|
| TC-BND-VBD-001 | notation 100 chars | **PASS** | id=90006 saved with `length(notation)=100` | |
| TC-BND-VBD-002 | notation 101 chars | **PASS** | reject `value too long for type character varying(100)` | Raw PG msg, không user-friendly Vietnamese — minor BUG-F-VB-007 |
| TC-BND-VBD-003 | publish_unit 500 | **PASS** | id=90007, `length=500` | |
| TC-BND-VBD-004 | publish_unit 501 | **PASS** | reject (raw PG msg) | Same minor as 002 |
| TC-BND-VBD-005 | signer 200 | **PASS** | id=90008, `length(signer)=200` | |
| TC-BND-VBD-006 | signer 201 | **PASS** | reject (raw PG msg) | Same minor as 002 |
| TC-BND-VBD-007 | number_paper = 0 | **PASS (behavior)** | id=90009, persisted = **1** (default) | Repository fallback `body.number_paper ? Number(body.number_paper) : 1` — `0` is falsy → coerced về 1. Acceptable behavior. |
| TC-BND-VBD-008 | number_paper = -1 | **FAIL — BUG-F-VB-001** | id=90010, persisted = **-1** | Backend KHÔNG validate số âm. Cột `INTEGER` không có CHECK constraint. |
| TC-BND-VBD-009 | number_paper = 999999 | **PASS** | id=90011, persisted = 999999 | |
| TC-BND-VBD-010 | expired = received (cùng ngày) | **PASS** | id=90012 | |
| TC-BND-VBD-011 | expired < received | **FAIL — BUG-F-VB-002** | id=90013 lưu OK với `expired_date < received_date` | Backend KHÔNG enforce date rule. Theo TC notes là frontend rule (CLAUDE.md mục #12), nhưng API trực tiếp bypass được → cần thêm SP-side validation hoặc backend-side check. |
| TC-BND-VBD-012 | upload 50MB exact | **FAIL — BUG-F-VB-003** | HTTP 500 `{"success":false,"message":"File too large"}` | Multer config `limits: { fileSize: MAX_FILE_SIZE }` reject khi `>=` limit. File **đúng 50MB (52428800 bytes)** bị reject. Cross-check: 49MB OK, 50MB-1byte (52428799) OK, 50MB exact FAIL. → Limit phải là `> 50MB` (strict greater) chứ không phải `>=`. |
| TC-BND-VBD-013 | upload 51MB | **PASS** | HTTP 500 `{"success":false,"message":"File too large"}` | Đúng nghiệp vụ reject. Tuy nhiên status code nên là **413 Payload Too Large** thay vì 500. Tham chiếu chung BUG-F-VB-007. |
| TC-BND-VBD-014 | upload empty file (0 byte) | **PASS (behavior)** | HTTP 201 attachment id=1, file_size=0 | Hệ thống chấp nhận. Tester ghi nhận hành vi — tuỳ nghiệp vụ có cần reject không. |
| TC-BND-VBD-015 | upload 10× 5MB | **PASS** | 10 attachments id=2..11, mỗi file 5242880 bytes | Endpoint hiện tại single-file (`upload.single('file')`), nên FE sẽ phải gửi 10 request liên tiếp. Tested OK. |
| TC-BND-VBD-016 | filename Unicode + dấu cách | **PASS** | attachment id=14, `file_name = "Quyết định số 123 — Khẩn cấp.pdf"` (đầy đủ dấu) | Multer fileFilter latin1→utf8 đã hoạt động đúng. |

---

## VB đi — chi tiết 10 TC

| TC | Title | Result | Evidence | Note |
|----|-------|--------|----------|------|
| TC-BND-VBI-001 | notation 100 | **PASS** | id=90004, `length(notation)=100` | |
| TC-BND-VBI-002 | sub_number 20 | **PASS** | id=90005, `length(sub_number)=20` | |
| TC-BND-VBI-003 | sub_number 21 | **PASS** | reject `value too long for type character varying(20)` | Raw PG msg |
| TC-BND-VBI-004 | document_code 100 | **PASS** | id=90006, `length(document_code)=100` | |
| TC-BND-VBI-005 | approver 200 chars | **FAIL — BUG-F-VB-004** | id=90007, `length(approver)=NULL` | Body `approver` bị **silent drop**. `outgoingDocRepository.create()` không nhận param `approver` (chỉ có signer/draftingUserId). Route `outgoing-doc.ts:287` cũng không spread `approver`. Field `approver VARCHAR(255)` tồn tại trong DB nhưng không được set qua POST → frontend nhập approver sẽ mất dữ liệu mà không cảnh báo. |
| TC-BND-VBI-006 | duplicate notation cùng book | **FAIL — BUG-F-VB-005** | id=90008 + 90009 cùng `notation='100/QD-UBND-WAVEF'` cùng `doc_book_id=5` | Backend không có unique constraint `(doc_book_id, notation)` cũng không có app-level check. Vi phạm yêu cầu nghiệp vụ "Số ký hiệu duy nhất trong sổ". |
| TC-BND-VBI-007 | publish_date > expired_date | **FAIL — BUG-F-VB-002 (cùng nguyên nhân)** | id=90010 lưu với publish=2026-06-01, expired=2026-05-01 | Backend không check date rule, giống VBD-011 (chỉ frontend rule). |
| TC-BND-VBI-008 | upload .docx + .pdf | **PASS** | attachments id=1 (.docx, content_type=`application/octet-stream`), id=2 (.pdf, `application/pdf`) | Cả 2 file lưu OK. Lưu ý: .docx được upload với MIME default `application/octet-stream` (curl không tự detect). FE thực tế sẽ gửi MIME chuẩn. |
| TC-BND-VBI-009 | upload .exe (bảo mật) | **FAIL — BUG-F-VB-006 (SECURITY)** | attachment id=3, file_name=`malware.exe`, content_type=`application/octet-stream`, HTTP 201 | **Backend không có whitelist file extension hoặc MIME**. `middleware/upload.ts` chỉ có `fileFilter` convert filename encoding latin1→utf8, KHÔNG reject loại file. Mọi loại file (.exe, .bat, .cmd, .sh, .msi, .scr...) đều được upload và lưu vào MinIO. Đây là lỗ hổng bảo mật — cán bộ có thể tải xuống file thực thi từ VB. |
| TC-BND-VBI-010 | recipients 10000 chars (TEXT) | **PASS** | id=90011 | Cột `TEXT` không giới hạn, chấp nhận thoải mái. |

---

## Bugs found (7)

### BUG-F-VB-001 — `number_paper` cho phép số âm trên VB đến
- **Severity:** Medium
- **TC:** TC-BND-VBD-008
- **Steps:** POST `/api/van-ban-den` body `{"number_paper": -1, ...}`
- **Expected:** Backend reject "Số trang phải >= 1" hoặc DB CHECK constraint reject
- **Actual:** id=90010 saved với `number_paper=-1`
- **Root cause:** Cột `number_paper INTEGER DEFAULT 1` không có CHECK constraint. Repository chỉ `Number(body.number_paper)` không validate range.
- **Fix:** thêm `CHECK (number_paper >= 0)` trong DDL + validate ở route handler trước khi gọi SP.

### BUG-F-VB-002 — Backend không enforce rule `expired_date >= received_date` (VBĐ) / `>= publish_date` (VBI)
- **Severity:** Medium
- **TC:** TC-BND-VBD-011, TC-BND-VBI-007
- **Steps:** POST với expired_date < received_date (hoặc publish_date)
- **Expected:** Backend reject hoặc raise validation error
- **Actual:** Bản ghi lưu thành công với date sai logic
- **Root cause:** Cả 2 SP `fn_incoming_doc_create` và `fn_outgoing_doc_create` không có check date relationship. Frontend rule (CLAUDE.md #12) chỉ chặn ở UI, API trực tiếp bypass.
- **Fix:** Thêm validation trong SP: `IF p_expired_date IS NOT NULL AND p_expired_date < p_received_date THEN RAISE EXCEPTION ...`. Hoặc thêm CHECK constraint table-level.

### BUG-F-VB-003 — Multer reject file đúng 50MB (boundary inclusive bug)
- **Severity:** High (boundary edge case nhưng tài liệu hứa "tối đa 50MB")
- **TC:** TC-BND-VBD-012
- **Steps:** Upload file 52428800 bytes (đúng 50MB)
- **Expected:** Upload OK (theo CLAUDE.md "multer limit 50MB")
- **Actual:** HTTP 500 `{"success":false,"message":"File too large"}`
- **Cross-check:** 49MB OK, 50MB-1byte (52428799) OK, 50MB exact FAIL, 51MB FAIL.
- **Root cause:** Multer `limits.fileSize` so sánh `>=` không phải `>`. File ĐÚNG limit bị reject.
- **Fix:** trong `middleware/upload.ts`, đặt `MAX_FILE_SIZE = 50 * 1024 * 1024 + 1` hoặc đổi documentation nói "limit 49.99MB". Chuẩn: nâng env default lên `50 * 1024 * 1024 + 1` để 50MB-exact pass.

### BUG-F-VB-004 — Field `approver` trên VB đi bị silent drop
- **Severity:** High (data loss — user nhập nhưng không lưu, không có warning)
- **TC:** TC-BND-VBI-005
- **Steps:** POST `/api/van-ban-di` body `{"approver": "<200 chars>", ...}`
- **Expected:** Lưu approver vào cột `approver VARCHAR(255)`
- **Actual:** id=90007 lưu OK nhưng `approver = NULL` trong DB.
- **Root cause:**
  - Route `routes/outgoing-doc.ts` POST `/` không truyền `body.approver` cho `outgoingDocRepository.create()`.
  - Repository `create()` interface không có field `approver`.
  - Cột DB `approver VARCHAR(255)` tồn tại trong `edoc.outgoing_docs` (created_at đầu Phase tổng hợp).
- **Fix:** Thêm `approver: body.approver || null` vào route + thêm param trong repository.create() + thêm param trong SP `fn_outgoing_doc_create`. Ngoài ra Frontend Drawer Tạo VB đi nếu có field "Người duyệt" thì cũng đang silent fail.

### BUG-F-VB-005 — Duplicate notation trong cùng `doc_book` không bị chặn
- **Severity:** High (vi phạm nghiệp vụ — 2 VB cùng số ký hiệu trong 1 sổ)
- **TC:** TC-BND-VBI-006
- **Steps:** POST 2 lần với `notation='100/QD-UBND-WAVEF'` cùng `doc_book_id=5`
- **Expected:** Lần 2 reject "Số ký hiệu đã tồn tại trong sổ này" + inline field error
- **Actual:** Cả 2 lần thành công (id=90008, 90009).
- **Root cause:** Bảng `edoc.outgoing_docs` không có unique constraint `(doc_book_id, notation)` (tham khảo `\d edoc.outgoing_docs` chỉ có UNIQUE PK `id`). SP `fn_outgoing_doc_create` không pre-check.
- **Fix:** Thêm partial unique index `CREATE UNIQUE INDEX uq_outgoing_doc_book_notation ON edoc.outgoing_docs (doc_book_id, notation) WHERE notation IS NOT NULL AND notation <> '' AND status <> 'rejected'`. Cập nhật route `handleDbError` → map 23505 → "Số ký hiệu đã tồn tại trong sổ này". Bổ sung `setBackendFieldError` trên FE Drawer (CLAUDE.md mục #13).
- **Note:** Áp dụng đồng nhất cho VB đến (cùng nguyên nhân tiềm ẩn).

### BUG-F-VB-006 — Upload chấp nhận mọi extension, kể cả `.exe` (SECURITY)
- **Severity:** High — Security
- **TC:** TC-BND-VBI-009
- **Steps:** Upload `malware.exe` (header MZ\x90)
- **Expected:** Backend reject với "Loại file không được phép"
- **Actual:** HTTP 201, lưu vào MinIO + DB (`content_type=application/octet-stream`)
- **Root cause:** `middleware/upload.ts` chỉ có `fileFilter` để fix encoding tên file, KHÔNG có whitelist MIME/extension.
- **Fix:** Thêm whitelist trong `fileFilter`:
  ```ts
  const ALLOWED_EXT = new Set(['pdf','doc','docx','xls','xlsx','ppt','pptx','txt','jpg','jpeg','png','gif','zip','rar','7z']);
  const ext = file.originalname.split('.').pop()?.toLowerCase();
  if (!ALLOWED_EXT.has(ext)) return cb(new Error('Loại file không được phép: .' + ext));
  ```
- **Centralized fix:** Áp dụng cho tất cả upload endpoint (VB đến/đi/dự thảo/HSCV/đính kèm bút phê) vì cùng dùng `middleware/upload.ts`.

### BUG-F-VB-007 — Error message không Vietnamese friendly + sai HTTP status code
- **Severity:** Low (UX)
- **TC:** TC-BND-VBD-002, 004, 006; TC-BND-VBI-003 (raw PG msg); TC-BND-VBD-013 (HTTP 500 thay vì 413)
- **Symptoms:**
  - `{"success":false,"message":"value too long for type character varying(100)"}` thay vì "Số ký hiệu tối đa 100 ký tự"
  - `{"success":false,"message":"File too large"}` HTTP 500 thay vì 413 Payload Too Large
- **Root cause:**
  - Route `incoming-doc.ts` `handleDbError(error)` không xử lý SQLSTATE 22001 (string_data_right_truncation).
  - Global error handler `server.ts:117` luôn return 500 bất kể loại lỗi (dev mode `err.message`).
- **Fix:** 
  1. Thêm case 22001 trong `handleDbError`: parse field name nếu có thể, return Vietnamese msg.
  2. Trong route upload, wrap với try/catch riêng để check `err instanceof multer.MulterError && err.code === 'LIMIT_FILE_SIZE'` → return HTTP 413 + "Kích thước file vượt quá giới hạn cho phép (50MB)".
  3. Centralize: thêm dedicated multer error middleware sau mỗi `upload.single()` chain.

---

## Records cleanup (info)

Test artifacts created (id ≥ 90004 cho outgoing, ≥ 90006 cho incoming):
- VB đến mới: 90006..90014 (9 bản ghi + 16 attachments dưới 90014)
- VB đi mới: 90004..90012 (9 bản ghi + 3 attachments dưới 90012)

Không touch fixtures 90001..90005. Tất cả ID test ≥ 90600 yêu cầu (do agent dùng auto-increment, ID thực tế từ 90004/90006 lên do counter sequence). Không destructive — chỉ tạo data mới.

---

## Files referenced

- Test fixtures: `D:/qlvb_test_artifacts/`
- Test scripts: `D:/qlvb_test_artifacts/run_vbden.sh`, `run_vbden_uploads.sh`, `run_vbdi.sh`, `run_vbdi_uploads.sh`, `test_vn_filename.js`
- Source verified:
  - `e_office_app_new/backend/src/middleware/upload.ts` (multer config)
  - `e_office_app_new/backend/src/routes/incoming-doc.ts:286-343` (POST create)
  - `e_office_app_new/backend/src/routes/outgoing-doc.ts:272-321` (POST create — missing approver)
  - `e_office_app_new/backend/src/repositories/outgoing-doc.repository.ts:105-130` (no approver param)
  - `e_office_app_new/backend/src/server.ts:61` (express.json 50mb), `:117-125` (global error handler)
- Schema: `\d edoc.incoming_docs` + `\d edoc.outgoing_docs` (no CHECK constraint, no unique notation)
