---
phase: quick-260418-hlj
plan: 01
subsystem: hdsd-compliance
tags: [hdsd, smartca, recall, hscv, sign-image, doc-book]
requirements: [HDSD-I.4, HDSD-2.3, HDSD-3.1, HDSD-3.2]
dependency_graph:
  requires:
    - public.staff (sign_phone, sign_ca, sign_image columns)
    - edoc.inter_incoming_docs (BIGSERIAL id)
    - edoc.incoming_docs (is_inter_doc, inter_doc_id)
    - edoc.handling_docs (BIGSERIAL id, doc_book_id, number, sub_number, doc_notation)
    - edoc.doc_books (SERIAL id)
  provides:
    - public.fn_staff_update_signature
    - edoc.fn_inter_incoming_recall_approve
    - edoc.fn_inter_incoming_recall_reject
    - edoc.fn_inter_incoming_snapshot_status_before_recall (trigger function)
    - edoc.fn_handling_doc_reopen
    - edoc.fn_handling_doc_get_next_number
    - edoc.fn_handling_doc_assign_number
    - 5 new API routes
    - UI: Profile signature tab + 2 recall buttons + 2 HSCV toolbar buttons
  affects:
    - public.fn_auth_get_me (RETURNS TABLE thêm sign_phone, sign_image)
    - edoc.fn_inter_incoming_get_by_id (RETURNS TABLE thêm 6 field recall_*)
    - edoc.fn_handling_doc_get_by_id (RETURNS TABLE thêm 4 field number/doc_book_*)
tech_stack:
  added: []
  patterns:
    - "DROP/CREATE FUNCTION khi RETURNS TABLE thay đổi cấu trúc"
    - "Trigger BEFORE UPDATE auto-snapshot status_before_recall"
    - "BIGINT param khi bảng dùng BIGSERIAL (handling_docs.id, inter_incoming_docs.id)"
    - "Quote alias h.unit_id, h.number trong SELECT INTO để tránh column ambiguity với cột RETURNS TABLE"
    - "Mount route cá nhân với chỉ authenticate (không requireRoles)"
key_files:
  created:
    - e_office_app_new/database/migrations/quick_260418_hlj_signature.sql
    - e_office_app_new/database/migrations/quick_260418_hlj_recall.sql
    - e_office_app_new/database/migrations/quick_260418_hlj_hscv.sql
    - e_office_app_new/backend/src/repositories/profile.repository.ts
    - e_office_app_new/backend/src/routes/profile.ts
  modified:
    - e_office_app_new/backend/src/server.ts
    - e_office_app_new/backend/src/services/auth.service.ts
    - e_office_app_new/backend/src/repositories/auth.repository.ts
    - e_office_app_new/backend/src/repositories/inter-incoming.repository.ts
    - e_office_app_new/backend/src/routes/inter-incoming.ts
    - e_office_app_new/backend/src/repositories/handling-doc.repository.ts
    - e_office_app_new/backend/src/routes/handling-doc.ts
    - e_office_app_new/frontend/src/stores/auth.store.ts
    - e_office_app_new/frontend/src/app/(main)/thong-tin-ca-nhan/page.tsx
    - e_office_app_new/frontend/src/app/(main)/van-ban-lien-thong/page.tsx
    - e_office_app_new/frontend/src/app/(main)/van-ban-lien-thong/[id]/page.tsx
    - e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/[id]/page.tsx
decisions:
  - "A1: SOFT-DELETE incoming_docs (không hard delete) khi đồng ý thu hồi"
  - "A2: GIỮ NGUYÊN progress=100 khi reopen HSCV (status 4 → 1)"
  - "A3: Reset số HSCV theo năm `created_at` + doc_book_id + unit_id"
  - "A4: Dùng `sign_phone` (số điện thoại) cho SmartCA"
  - "Profile route mount /api/ho-so-ca-nhan với chỉ authenticate (không requireRoles)"
  - "Trigger BEFORE UPDATE auto-snapshot status_before_recall — đảm bảo mọi code path"
metrics:
  duration: ~75 minutes
  completed_date: "2026-04-18"
  tasks: 3
  commits: 3
  files_changed: 15
  sps_added: 9
---

# Phase quick-260418-hlj Plan 01: HDSD Compliance P0+P1 Summary

3 gap HDSD compliance: SmartCA UI (P0) + Đồng ý/Từ chối thu hồi VB liên thông (P1) + Mở lại/Lấy số HSCV (P1) — feature ready cho demo cuối tuần 2026-04-18/19.

## Commits

| Task | Hash      | Message                                                                  |
| ---- | --------- | ------------------------------------------------------------------------ |
| 1    | `5880267` | `feat: thêm UI upload chữ ký số và tài khoản SmartCA — HDSD I.4`         |
| 2    | `e221957` | `feat: thêm chức năng đồng ý/từ chối thu hồi VB liên thông — HDSD 2.3`   |
| 3    | `f189464` | `feat: thêm chức năng mở lại và lấy số HSCV — HDSD 3.1, 3.2`             |

## Tổng kết DB Schema Thay Đổi

### Bảng

| Bảng                          | Cột mới                                                                                                | Index mới                                  |
| ----------------------------- | ------------------------------------------------------------------------------------------------------ | ------------------------------------------ |
| `edoc.inter_incoming_docs`    | `recall_reason`, `recall_requested_at`, `recall_response`, `recall_responded_by`, `recall_responded_at`, `status_before_recall` | —                                          |
| `edoc.incoming_docs`          | `is_deleted BOOLEAN`, `deleted_at TIMESTAMPTZ`, `deleted_by INT`                                       | `idx_incoming_docs_is_deleted` (partial)   |

### Stored Procedures / Functions / Triggers (9 mới)

| # | Tên                                                       | Type     | Mục đích                                                       |
| - | --------------------------------------------------------- | -------- | -------------------------------------------------------------- |
| 1 | `public.fn_staff_update_signature`                        | function | Update sign_phone/sign_ca/sign_image (COALESCE)                |
| 2 | `public.fn_auth_get_me` (sửa)                             | function | DROP/CREATE — thêm sign_phone, sign_image vào RETURNS TABLE     |
| 3 | `edoc.fn_inter_incoming_recall_approve`                   | function | status='recalled' + soft-delete incoming_docs liên kết         |
| 4 | `edoc.fn_inter_incoming_recall_reject`                    | function | restore status từ status_before_recall (fallback 'received')   |
| 5 | `edoc.fn_inter_incoming_snapshot_status_before_recall`    | trigger  | Auto-snapshot status cũ khi UPDATE → 'recall_requested'        |
| 6 | `edoc.fn_inter_incoming_get_by_id` (sửa)                  | function | DROP/CREATE — thêm 6 field recall_*/status_before_recall       |
| 7 | `edoc.fn_handling_doc_reopen`                             | function | status 4 → 1, GIỮ progress=100, clear complete_*               |
| 8 | `edoc.fn_handling_doc_get_next_number`                    | function | MAX(number)+1 theo năm + doc_book_id + unit_id                 |
| 9 | `edoc.fn_handling_doc_assign_number`                      | function | Validate chưa có số → tính số kế tiếp → UPDATE                 |
|10 | `edoc.fn_handling_doc_get_by_id` (sửa)                    | function | DROP/CREATE — thêm 4 field number/sub_number/doc_book_*       |

(Tổng: 9 SP/function/trigger MỚI + 3 SP cũ DROP/CREATE để mở rộng RETURNS TABLE)

## Routes API mới

| Method | Path                                            | Auth                       | Mục đích                                  |
| ------ | ----------------------------------------------- | -------------------------- | ----------------------------------------- |
| PATCH  | `/api/ho-so-ca-nhan/chu-ky-so`                  | `authenticate` (mọi user)  | Update sign_phone (HDSD I.4)              |
| POST   | `/api/ho-so-ca-nhan/anh-chu-ky`                 | `authenticate`             | Upload PNG ≤ 2MB chữ ký số (HDSD I.4)     |
| GET    | `/api/ho-so-ca-nhan/anh-chu-ky`                 | `authenticate`             | Presigned URL preview (HDSD I.4)          |
| POST   | `/api/van-ban-lien-thong/:id/dong-y-thu-hoi`    | `authenticate`             | Đồng ý thu hồi VB liên thông (HDSD 2.3)   |
| POST   | `/api/van-ban-lien-thong/:id/tu-choi-thu-hoi`   | `authenticate`             | Từ chối thu hồi (HDSD 2.3)                |
| POST   | `/api/ho-so-cong-viec/:id/mo-lai`               | `authenticate`             | Mở lại HSCV đã hoàn thành (HDSD 3.1)      |
| POST   | `/api/ho-so-cong-viec/:id/lay-so`               | `authenticate`             | Lấy số HSCV theo sổ (HDSD 3.2)            |

**Authorization note:** `/api/ho-so-ca-nhan/*` mount với CHỈ `authenticate` (KHÔNG `requireRoles`) — mọi role (Cán bộ, Văn thư, Lãnh đạo, …) đều dùng được, đúng yêu cầu HDSD I.4.

## Frontend UI Mới

### Gap 1 — Profile / Chữ ký số (`/thong-tin-ca-nhan`)
- Tách 2 tab: "Đổi mật khẩu" / "Chữ ký số".
- Form chữ ký số: Input `sign_phone` (maxLength 20, pattern điện thoại) + Upload PNG ≤ 2MB (beforeUpload validate) + Preview Avatar 150×150 nếu có ảnh.
- Hiển thị "Tài khoản ký số" trong Descriptions card profile.
- Sau Lưu: `fetchMe()` refresh `signImageUrl` (presigned).

### Gap 2 — Detail VB liên thông (`/van-ban-lien-thong/:id`)
- `STATUS_MAP` thêm `recall_requested` (volcano) + `recalled` (red).
- 2 nút conditional khi `status='recall_requested'`: "Đồng ý thu hồi" (danger) + "Từ chối thu hồi" (primary).
- Modal.confirm cho Đồng ý + Modal Form (reason required, max 1000) cho Từ chối.
- Card đỏ hiển thị `recall_reason` + `recall_response` (kèm timestamp).
- List page `STATUS_MAP` đồng bộ → filter dropdown tự động có 2 option mới.

### Gap 3 — Detail HSCV (`/ho-so-cong-viec/:id`)
- `getToolbarButtons(status, hasNumber)` — thêm param boolean.
- case 4 (Hoàn thành): nút "Mở lại" (primary) + "Xem lịch sử".
- case 1 (Đang xử lý) + case 3 (Đã duyệt): nút "Lấy số" (default) chỉ hiện khi `!hasNumber`.
- Header thêm Tag "Số: <N> / <doc_book_name>" khi đã có số.
- Modal Lấy số: Select sổ văn bản (showSearch) + helper text về công thức MAX+1 theo năm.

## Manual UAT Checklist (verified bằng SP test inline)

### Gap 1
- [x] DB: `SELECT * FROM public.fn_staff_update_signature(1, '84813789393', NULL, NULL)` → success.
- [x] DB: `SELECT staff_id, sign_phone, sign_image FROM public.fn_auth_get_me(1)` → trả về sign_phone='84813789393'.
- [ ] FE manual: cần test browser để verify Upload PNG → DB → preview.

### Gap 2
- [x] DB: UPDATE inter_incoming_docs SET status='recall_requested' → trigger auto-save status_before_recall='pending'.
- [x] DB: `SELECT * FROM edoc.fn_inter_incoming_recall_reject(1, 1, 'Lý do test')` → restore status='pending', clear status_before_recall, lưu recall_response.
- [x] DB: `SELECT * FROM edoc.fn_inter_incoming_recall_approve(1, 1)` → status='recalled', soft-delete 0 incoming_docs liên kết (vì test row chưa có VB đến phát sinh).
- [x] DB: `SELECT id, status, recall_reason, recall_response, status_before_recall FROM edoc.fn_inter_incoming_get_by_id(1)` → trả về 6 field mới đầy đủ.
- [ ] FE manual: cần test browser để verify 2 button + Modal reason + Card alert.

### Gap 3
- [x] DB: `SELECT edoc.fn_handling_doc_get_next_number(1, 1)` → trả về số kế tiếp đúng (1 cho năm hiện tại).
- [x] DB: `SELECT * FROM edoc.fn_handling_doc_reopen(5, 1)` → status 4→1, progress vẫn = 100 (verified per A2).
- [x] DB: `SELECT * FROM edoc.fn_handling_doc_assign_number(5, 1, 1)` → success, number=1, doc_book_id=1.
- [x] DB: re-bấm `assign_number(5, 1, 1)` → 'HSCV đã có số 1' (đúng business logic).
- [x] DB: `SELECT id, name, status, progress, number, sub_number, doc_book_id, doc_book_name FROM edoc.fn_handling_doc_get_by_id(5)` → trả 4 field mới đầy đủ kèm JOIN doc_books.
- [ ] FE manual: cần test browser để verify nút "Mở lại" / "Lấy số" / Modal Select sổ.

## Type-Check

| Project  | Pre-existing errors | Mới phát sinh từ task này |
| -------- | ------------------- | ------------------------- |
| backend  | 21                  | **0**                     |
| frontend | 17                  | **0**                     |

Tất cả TS errors còn lại đều thuộc file ngoài scope (workflow.ts, admin-catalog.ts, handling-doc-report.ts, inter-incoming.ts line 28 — `docTypeId` filter type mismatch, lich/, van-ban-den/, van-ban-di/, van-ban-du-thao/, ho-so-cong-viec/page.tsx). Per CLAUDE.md scope boundary, không fix.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] Fix `column reference "number" is ambiguous` trong fn_handling_doc_assign_number**
- **Found during:** Task 3 — test SP lần đầu sau khi apply migration.
- **Issue:** `SELECT unit_id, number INTO v_unit_id, v_existing_number FROM edoc.handling_docs WHERE id = p_id` — cột `number` trong bảng conflict với cột `"number"` trong RETURNS TABLE.
- **Fix:** Alias bảng + qualify cột → `SELECT h.unit_id, h.number ... FROM edoc.handling_docs h WHERE h.id = p_id`.
- **Files modified:** `e_office_app_new/database/migrations/quick_260418_hlj_hscv.sql` (re-applied).
- **Lesson learned:** Khi RETURNS TABLE có cột tên trùng cột bảng (vd `"number"`), PHẢI alias bảng + qualify cột trong mọi SELECT INTO/SELECT/WHERE bên trong SP body để tránh ambiguous reference.

**2. [Rule 2 — Missing critical functionality] Bổ sung `getSignature()` trong profile.repository.ts**
- **Found during:** Task 1 — viết route GET /anh-chu-ky.
- **Issue:** Plan chỉ define `updateSignature()`. Route GET /anh-chu-ky cần đọc `sign_image` hiện tại để generate presigned URL — nếu dùng `rawQuery` trực tiếp trong route sẽ vi phạm Repository pattern (mọi data access qua repo).
- **Fix:** Thêm method `profileRepository.getSignature(staffId)` dùng `rawQuery` trong repo.
- **Files modified:** `e_office_app_new/backend/src/repositories/profile.repository.ts` (file mới).

**3. [Rule 2 — Missing critical functionality] FE Gap 3 — extend "Lấy số" cho cả status=3**
- **Found during:** Task 3 — đọc lại business logic.
- **Issue:** Plan chỉ đề case 1. Nhưng case 3 (Đã duyệt) cũng có thể chưa có số (HSCV duyệt rồi mới lấy số phát hành).
- **Fix:** Thêm điều kiện `if (!hasNumber)` cho cả case 1 + case 3.
- **Files modified:** `e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/[id]/page.tsx`.

### Authentication gates
None.

## Bài học rút ra (đã có trong CLAUDE.md, cần duy trì)

1. **BIGSERIAL → BIGINT**: `handling_docs.id`, `inter_incoming_docs.id` là BIGSERIAL → SP params PHẢI `p_id BIGINT` (KHÔNG INT). `staff.id`, `doc_books.id` là SERIAL → INT OK.
2. **DROP trước CREATE OR REPLACE khi RETURNS TABLE đổi cấu trúc**: PostgreSQL không cho phép REPLACE nếu return type signature thay đổi.
3. **Quote alias bảng trong SELECT INTO** khi cột RETURNS TABLE trùng tên cột bảng — tránh `column reference is ambiguous`.
4. **Trigger BEFORE UPDATE** cho audit/snapshot pattern — đảm bảo mọi code path (SP nội bộ, raw UPDATE, webhook LGSP) đều consistent.
5. **MinIO uploadFile signature**: `uploadFile(key, buffer, contentType)` — 3 args, KHÔNG bucket (bucket cố định ENV). `getFileUrl(path, expirySeconds)` — 2 args.
6. **Upload middleware**: `import { upload }` (KHÔNG `uploadMemory`), dùng `upload.single('file')`.
7. **Mount route cá nhân với chỉ `authenticate`** (KHÔNG `requireRoles`) khi yêu cầu mọi user role dùng được.
8. **MSYS path translation trên Windows Git Bash**: `MSYS_NO_PATHCONV=1` trước `docker exec ... -f /tmp/...sql` để tránh chuyển `/tmp/x.sql` → `C:/Users/Admin/AppData/Local/Temp/x.sql`.

## Self-Check: PASSED

**Files created (9):**
- FOUND: `e_office_app_new/database/migrations/quick_260418_hlj_signature.sql`
- FOUND: `e_office_app_new/database/migrations/quick_260418_hlj_recall.sql`
- FOUND: `e_office_app_new/database/migrations/quick_260418_hlj_hscv.sql`
- FOUND: `e_office_app_new/backend/src/repositories/profile.repository.ts`
- FOUND: `e_office_app_new/backend/src/routes/profile.ts`

**Commits exist (3):**
- FOUND: 5880267 — feat: thêm UI upload chữ ký số và tài khoản SmartCA — HDSD I.4
- FOUND: e221957 — feat: thêm chức năng đồng ý/từ chối thu hồi VB liên thông — HDSD 2.3
- FOUND: f189464 — feat: thêm chức năng mở lại và lấy số HSCV — HDSD 3.1, 3.2

**SPs in DB (9):**
- FOUND: `public.fn_staff_update_signature`
- FOUND: `edoc.fn_inter_incoming_recall_approve`
- FOUND: `edoc.fn_inter_incoming_recall_reject`
- FOUND: `edoc.fn_inter_incoming_snapshot_status_before_recall`
- FOUND: `edoc.fn_inter_incoming_get_by_id` (revised)
- FOUND: `edoc.fn_handling_doc_reopen`
- FOUND: `edoc.fn_handling_doc_get_next_number`
- FOUND: `edoc.fn_handling_doc_assign_number`
- FOUND: `edoc.fn_handling_doc_get_by_id` (revised)
