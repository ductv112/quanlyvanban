---
phase: quick-260418-hlj
verified: 2026-04-18T14:00:00Z
status: human_needed
score: 17/17 must-haves verified (code level); 3 behavior items cần human UAT trên browser
---

# Verification Report — HDSD Compliance P0+P1

**Task goal:** 3 gap HDSD compliance được implement đầy đủ:

1. Ký số SmartCA UI trong trang Thông tin tài khoản (HDSD I.4)
2. Đồng ý / Từ chối thu hồi VB liên thông (HDSD 2.3)
3. HSCV Mở lại + Lấy số (HDSD 3.1, 3.2)

**Verified:** 2026-04-18
**Status:** HUMAN_NEEDED — toàn bộ code-level must-haves PASSED, còn 3 item cần test browser (UI interaction)

---

## Status: HUMAN_NEEDED

Tất cả must-haves (truths, artifacts, key_links) trong PLAN.md được verify PASSED trên codebase + DB thực tế. Tuy nhiên 3 item cần human UAT trên browser vì chỉ kiểm tra được qua trình duyệt (Upload UX, Modal, Button conditional render).

---

## Checked must_haves

### Gap 1 — SmartCA UI (HDSD I.4)

| # | Truth / Artifact | Status | Evidence |
|---|------------------|--------|----------|
| 1 | Frontend `thong-tin-ca-nhan/page.tsx` có Tab "Chữ ký số" với Upload + Input `sign_phone` | ✓ PASS | Dòng 199–247: `<Form form={signForm}>` với `Input name="sign_phone" maxLength={20}`, `<Upload {...uploadProps}>`, Avatar preview khi `user.signImageUrl` |
| 2 | Upload props validate PNG ≤ 2MB, không auto-upload | ✓ PASS | Dòng 57–70: `beforeUpload` check `type==='image/png'` + `size < 2MB` + `Upload.LIST_IGNORE` |
| 3 | Mount `/api/ho-so-ca-nhan/*` với CHỈ `authenticate` | ✓ PASS | `server.ts:81` — `app.use('/api/ho-so-ca-nhan', authenticate, profileRoutes)` (KHÔNG `requireRoles`) |
| 4 | File `backend/src/routes/profile.ts` với 3 endpoint (PATCH chu-ky-so, POST anh-chu-ky, GET anh-chu-ky) | ✓ PASS | `profile.ts` dòng 22, 81, 126 — đủ 3 endpoint, validate MIME + size, dùng `upload.single('file')` + `uploadFile(key, buffer, contentType)` 3 args |
| 5 | SP `public.fn_staff_update_signature` tồn tại | ✓ PASS | DB query: `public | fn_staff_update_signature | TABLE(success boolean, message text) | p_id INT, p_sign_phone VARCHAR, p_sign_ca TEXT, p_sign_image VARCHAR` |
| 6 | Cột `public.staff.sign_phone`, `sign_ca`, `sign_image` tồn tại | ✓ PASS | DB query: 3 cột đủ (sign_phone VARCHAR, sign_ca TEXT, sign_image VARCHAR) |
| 7 | `fn_auth_get_me` RETURNS TABLE có `sign_phone` + `sign_image` | ✓ PASS | DB query: return type cuối cùng `..., sign_phone character varying, sign_image character varying` |
| 8 | `auth.service.ts` generate presigned URL cho `sign_image` | ✓ PASS | Dòng 163–196: `if (profile.sign_image) signImageUrl = await getFileUrl(profile.sign_image, 3600)` |
| 9 | Auth store có `signPhone/signImage/signImageUrl` | ✓ PASS | `auth.store.ts:21–23`: 3 field có trong `UserInfo` |

### Gap 2 — Thu hồi VB liên thông (HDSD 2.3)

| # | Truth / Artifact | Status | Evidence |
|---|------------------|--------|----------|
| 10 | Routes POST `/:id/dong-y-thu-hoi` + `/tu-choi-thu-hoi` trong inter-incoming.ts | ✓ PASS | `inter-incoming.ts:117, 137` — 2 route handler, gọi `recallApprove/recallReject` |
| 11 | SP `fn_inter_incoming_recall_approve`, `fn_inter_incoming_recall_reject` tồn tại (param BIGINT) | ✓ PASS | DB query: `fn_inter_incoming_recall_approve(p_id bigint, p_user_id integer)` + `fn_inter_incoming_recall_reject(p_id bigint, p_user_id integer, p_reason text)` — BIGINT đúng |
| 12 | Cột `recall_reason`, `recall_requested_at`, `recall_response`, `recall_responded_at`, `recall_responded_by`, `status_before_recall` trên `inter_incoming_docs` | ✓ PASS | DB query: 6 cột đủ (5 recall_* + status_before_recall VARCHAR(50)) |
| 13 | Cột `is_deleted`, `deleted_at`, `deleted_by` trên `incoming_docs` + partial index | ✓ PASS | DB query: 3 cột đủ + `idx_incoming_docs_is_deleted` tồn tại |
| 14 | Trigger `trg_inter_incoming_snapshot_status_before_recall` tồn tại | ✓ PASS | DB query: `trg_inter_incoming_snapshot_status_before_recall | edoc.inter_incoming_docs` |
| 15 | `fn_inter_incoming_get_by_id` RETURNS TABLE có 5+ field recall_* | ✓ PASS | DB query: return type có `recall_reason text, recall_requested_at timestamptz, recall_response text, recall_responded_by integer, recall_responded_at timestamptz, status_before_recall varchar` (6 field) |
| 16 | Frontend detail VB liên thông có 2 button conditional render khi `status='recall_requested'` | ✓ PASS | `van-ban-lien-thong/[id]/page.tsx:306–318`: `{doc.status === 'recall_requested' && (...)} ` chứa Button "Đồng ý thu hồi" + "Từ chối thu hồi" |
| 17 | Detail page hiển thị `recall_reason` + `recall_response` khi có | ✓ PASS | Dòng 324–360: card đỏ hiển thị `doc.recall_reason` + `doc.recall_response` + timestamps |
| 18 | List page `STATUS_MAP` có `recall_requested` + `recalled` | ✓ PASS | `van-ban-lien-thong/page.tsx:32–39`: `STATUS_MAP` chứa đủ `recall_requested (volcano)` + `recalled (red)`; filter options tạo từ `Object.entries(STATUS_MAP)` → tự động có option mới |

### Gap 3 — HSCV Mở lại + Lấy số (HDSD 3.1, 3.2)

| # | Truth / Artifact | Status | Evidence |
|---|------------------|--------|----------|
| 19 | Routes POST `/:id/mo-lai` + `/:id/lay-so` trong handling-doc.ts | ✓ PASS | `handling-doc.ts:555, 575` — 2 route handler, validate ID + docBookId, gọi `reopen/assignNumber` |
| 20 | SP `fn_handling_doc_reopen`, `fn_handling_doc_get_next_number`, `fn_handling_doc_assign_number` tồn tại (param BIGINT cho id) | ✓ PASS | DB query: `fn_handling_doc_reopen(p_id bigint, p_user_id integer)`, `fn_handling_doc_assign_number(p_id bigint, p_user_id integer, p_doc_book_id integer)`, `fn_handling_doc_get_next_number(p_doc_book_id integer, p_unit_id integer)` — BIGINT đúng cho id |
| 21 | `fn_handling_doc_assign_number` có fix alias `h.number` để tránh ambiguous reference | ✓ PASS | `SELECT h.unit_id, h.number INTO v_unit_id, v_existing_number FROM edoc.handling_docs h WHERE h.id = p_id` — alias bảng + qualify cột đúng |
| 22 | `fn_handling_doc_get_by_id` RETURNS TABLE có `number, sub_number, doc_book_id, doc_book_name` | ✓ PASS | DB query: return type cuối `..., number integer, sub_number character varying, doc_book_id integer, doc_book_name character varying` (4 field mới đủ) |
| 23 | Frontend HSCV detail có button "Mở lại" khi status=4 | ✓ PASS | `ho-so-cong-viec/[id]/page.tsx:248–253`: `case 4 → [{ label: 'Mở lại', type: 'primary', action: 'reopen' }, ...]` |
| 24 | Frontend HSCV detail có button "Lấy số" khi status=1 HOẶC 3 AND number IS NULL | ✓ PASS | Dòng 219–246: `case 1` + `case 3` đều push `{ label: 'Lấy số', action: 'get_number' }` khi `!hasNumber` |
| 25 | Handler `handleReopen` gọi POST `/ho-so-cong-viec/:id/mo-lai` | ✓ PASS | Dòng 619: `await api.post(`/ho-so-cong-viec/${id}/mo-lai`)` |
| 26 | Handler "Lấy số" gọi POST `/ho-so-cong-viec/:id/lay-so` với `doc_book_id` | ✓ PASS | Dòng 644, 676: `api.post(`/ho-so-cong-viec/${id}/lay-so`, { doc_book_id: ... })` |

### Critical rules compliance

| Rule | Status | Evidence |
|------|--------|----------|
| Route `/api/ho-so-ca-nhan` KHÔNG dùng `requireRoles` admin | ✓ PASS | `server.ts:81`: `app.use('/api/ho-so-ca-nhan', authenticate, profileRoutes)` — chỉ `authenticate` |
| Upload middleware dùng `upload` (không `uploadMemory`) | ✓ PASS | `profile.ts:5`: `import { upload } from '../middleware/upload.js'`; `upload.single('file')` |
| MinIO `uploadFile` dùng 3 args (không bucket) | ✓ PASS | `profile.ts:101`: `uploadFile(key, req.file.buffer, 'image/png')`; signature `lib/minio/client.ts:18`: `uploadFile(path, buffer, contentType)` |
| SP params BIGINT cho `handling_docs.id` + `inter_incoming_docs.id` (BIGSERIAL) | ✓ PASS | Tất cả 5 SP mới có `p_id bigint` |

### Key links (data flow verification)

| Link | Status |
|------|--------|
| Frontend thong-tin-ca-nhan → `/api/ho-so-ca-nhan/chu-ky-so + /anh-chu-ky` (axios PATCH/POST) | ✓ WIRED (line 90, 98) |
| Backend routes/profile.ts → `public.fn_staff_update_signature` (callFunctionOne) | ✓ WIRED (profile.repository.ts:29) |
| Frontend van-ban-lien-thong/[id] → `/dong-y-thu-hoi + /tu-choi-thu-hoi` (axios POST) | ✓ WIRED (line 194, 211) |
| `fn_inter_incoming_recall_approve` → `edoc.incoming_docs` soft-delete | ✓ WIRED (SP body contains `UPDATE edoc.incoming_docs SET is_deleted=TRUE WHERE is_inter_doc=TRUE AND inter_doc_id=p_id`) |
| `fn_inter_incoming_recall_reject` → `edoc.inter_incoming_docs` restore via `COALESCE(status_before_recall, 'received')` | ✓ WIRED |
| Frontend ho-so-cong-viec/[id] → `/mo-lai + /lay-so` (axios POST) | ✓ WIRED (line 619, 644, 676) |
| `fn_handling_doc_assign_number` → `handling_docs.number` MAX+1 theo năm `created_at` + `doc_book_id` | ✓ WIRED (SP body dùng `EXTRACT(YEAR FROM created_at)` + doc_book_id filter, gọi `fn_handling_doc_get_next_number`) |

---

## Gaps found

Không có gap nào ở code/DB level. Tất cả 26 must-haves + 4 critical rules + 7 key links đều verified PASSED.

---

## Items needing human check

3 item chỉ kiểm tra được trên browser (UI interaction thực tế):

### 1. Gap 1 — Upload ảnh chữ ký PNG trên browser

**Test:**
1. Login bất kỳ user (Cán bộ / Văn thư / Lãnh đạo)
2. Vào `/thong-tin-ca-nhan` → Tab "Chữ ký số"
3. Chọn file PNG hợp lệ (< 2MB) → click "Lưu thông tin ký số"
4. Reload trang → kiểm tra Avatar 150×150 hiển thị đúng ảnh vừa upload
5. Test negative: chọn JPG → phải báo lỗi "Chỉ chấp nhận file PNG"
6. Test negative: chọn PNG > 2MB → phải báo lỗi "Kích thước ảnh tối đa 2MB"

**Expected:**

- Upload thành công → message "Cập nhật thành công"
- `auth.signImageUrl` được refresh (presigned URL MinIO)
- Reload trang vẫn thấy ảnh (presigned URL regenerate từ `/auth/me`)

**Why human:** Tương tác Upload component + validation + round-trip MinIO → presigned URL phải test trên browser thực tế.

### 2. Gap 2 — 2 button "Đồng ý / Từ chối thu hồi" conditional render

**Test:**
1. Tạo 1 VB liên thông + set `status='recall_requested'` qua DB (hoặc gọi API mock source system)
2. Mở detail page VB liên thông đó → kiểm tra 2 button xuất hiện
3. Click "Đồng ý thu hồi" → Modal.confirm → xác nhận
4. Verify: status chuyển thành `recalled` + VB đến phát sinh (nếu có) bị soft-delete
5. Test case 2: set status='recall_requested' lần nữa → click "Từ chối thu hồi" → Modal nhập lý do (required, max 1000) → gửi
6. Verify: status restore về `status_before_recall` (hoặc fallback `'received'`) + `recall_response` hiển thị trong card đỏ
7. Verify List page: filter dropdown có 2 option mới "Đang yêu cầu thu hồi" + "Đã thu hồi"

**Expected:**

- 2 button xuất hiện ĐÚNG điều kiện `status === 'recall_requested'` và ẨN ở status khác
- Modal từ chối: reason required validation hoạt động
- Sau action, page reload hiển thị status mới + card lý do
- Filter trên list page render đủ 6 option (pending / received / completed / returned / recall_requested / recalled)

**Why human:** Modal.confirm + Modal Form + conditional render + page refresh logic phải test trên browser.

### 3. Gap 3 — "Mở lại" + "Lấy số" + Modal Select sổ

**Test:**
1. Mở 1 HSCV có `status=4` (Hoàn thành) → verify header có button "Mở lại"
2. Click "Mở lại" → Popconfirm xác nhận
3. Verify: status chuyển `1`, `progress=100` GIỮ NGUYÊN (không reset về 0)
4. Mở 1 HSCV có `status=1` và `number IS NULL` → verify header có button "Lấy số"
5. Click "Lấy số" → Modal Select sổ văn bản → chọn sổ → submit
6. Verify: `number` được set = MAX+1 theo năm `created_at` + `doc_book_id`
7. Verify: Header hiển thị Tag "Số: N / doc_book_name"
8. Test: click "Lấy số" lần 2 → phải báo "HSCV đã có số N" (business logic assign_number kiểm tra duplicate)
9. Test case 2: mở HSCV `status=3` và `number IS NULL` → verify cũng có button "Lấy số"
10. Test case 3: mở HSCV `status=4` và `number IS NULL` → KHÔNG có button "Lấy số" (chỉ "Mở lại" + "Xem lịch sử")

**Expected:**

- Button "Mở lại" chỉ hiện ở status=4
- Button "Lấy số" chỉ hiện ở status=1 hoặc 3, AND `!hasNumber`
- Modal Select sổ có `showSearch` và helper text về công thức MAX+1 theo năm
- Reopen giữ progress=100 (A2 decision)
- Assign number re-run phải idempotent (báo "đã có số N")

**Why human:** Toolbar button conditional render dựa trên state detail + Modal workflow + Popconfirm + side-effect trên header phải test browser.

---

## Gaps Summary

**Code/DB level:** 26/26 must-haves PASSED, 0 gap.

**Browser UX:** 3 item cần human UAT — đều là visual / interaction / end-to-end flow. Không có regression hoặc anti-pattern phát hiện trong scan.

**Anti-patterns:** Không có TODO/FIXME/placeholder trong file mới tạo (`profile.ts`, `profile.repository.ts`, 3 migrations `quick_260418_hlj_*.sql`). 17 FE + 21 BE pre-existing TS errors đã document trong SUMMARY.md và thuộc file ngoài scope (workflow.ts, admin-catalog.ts, handling-doc-report.ts, lich/, van-ban-den/, van-ban-di/, van-ban-du-thao/, ho-so-cong-viec/page.tsx).

**Deviations note:** 2 auto-fix trong SUMMARY (ambiguity fix + extend "Lấy số" cho status=3) đều verify thấy trong codebase (alias `h.number` + case 3 có `!hasNumber` branch).

---

_Verified: 2026-04-18T14:00:00Z_
_Verifier: Claude (gsd-verifier)_
