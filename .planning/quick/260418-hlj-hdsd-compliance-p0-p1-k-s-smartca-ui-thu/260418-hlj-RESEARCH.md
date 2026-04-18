# Research — HDSD Compliance P0+P1 (SmartCA UI / Thu hồi VB liên thông / HSCV Mở lại + Lấy số)

**Researched:** 2026-04-18
**Mode:** quick-task (3 gap, targeted)
**Confidence tổng:** MEDIUM-HIGH

---

## Tóm tắt điều hành

3 gap độc lập nhau (khác module, khác bảng DB, khác route) → có thể chạy **song song 3 agent** nếu chia rõ file scope. Mỗi gap đều có SP/schema sẵn một phần, nên chủ yếu là viết thêm SP + route + UI.

**Phát hiện quan trọng khi scan codebase:**
1. Bảng `public.staff` **đã có sẵn** `sign_phone`, `sign_ca`, `sign_image` — KHÔNG cần migration cột mới cho Gap 1.
2. `handling_docs` **đã có sẵn** `number`, `sub_number`, `notation` + `doc_book_id` — pattern "Lấy số" giống `fn_outgoing_doc_get_next_number` có thể tái dụng.
3. SigningModal (component) **đã tồn tại** ở `frontend/src/components/signing/SigningModal.tsx` — luồng ký số 2-step SmartCA đã chạy được. Gap 1 chỉ cần cấu hình account + ảnh chữ ký trong profile để backend đọc được.
4. `/api/quan-tri/nguoi-dung/:id/change-password` hiện đang mount dưới `requireRoles('Quản trị hệ thống')` — **đây là bug tiềm ẩn**: user thường tự đổi mật khẩu sẽ bị 403. Cần xác nhận khi làm Gap 1. (Để sau — ngoài phạm vi task này, nhưng phải tránh đặt endpoint mới vào `/quan-tri` để không lặp sai.)

---

## GAP 1 — Ký số SmartCA UI (Profile page)

### Current State

- Trang `frontend/src/app/(main)/thong-tin-ca-nhan/page.tsx` hiện chỉ có 2 cột: Profile info (read-only) + Đổi mật khẩu.
- DB `public.staff` **có sẵn** các cột: `sign_phone VARCHAR(20)` (tài khoản SmartCA), `sign_ca TEXT` (cert content), `sign_image VARCHAR(500)` (MinIO path).
- SP `public.fn_staff_update_avatar(p_id, p_image_path)` đã tồn tại — tham khảo pattern để viết SP update signature.
- Không có endpoint backend nào expose update avatar/sign_image/sign_phone — tức là SP có nhưng route chưa có.
- File cũ `UserInfo.cshtml` / `UserInfoController.js` xác nhận nghiệp vụ: upload PNG 150×150 vào `SignImage`, input text `SignPhone` là "Tài khoản ký số" (VD: `84813789393` — số điện thoại đăng ký SmartCA VNPT).
- `SigningModal` (ký số trong VB) đã hoạt động với `/api/ky-so/sign/smart-ca`, `/verify-otp`, `/esign-neac`.
- `backend/src/middleware/upload.ts` (multer memory 50MB) đã có sẵn. MinIO client có `uploadFile()`, `getFileUrl()`.

### What's Missing

1. **Backend:** 2 endpoint self-service cho user cập nhật profile (không yêu cầu role admin):
   - `PATCH /api/ho-so-ca-nhan/chu-ky-so` — update `sign_phone` (text) + `sign_ca` (optional text)
   - `POST /api/ho-so-ca-nhan/anh-chu-ky` — upload ảnh chữ ký PNG (multipart) → MinIO → update `sign_image`
2. **SP:** `public.fn_staff_update_signature(p_id, p_sign_phone, p_sign_ca, p_sign_image)` — update 3 cột trong một SP (tương tự `fn_staff_update_avatar`).
3. **Frontend:** Thêm section mới vào trang `thong-tin-ca-nhan/page.tsx` — có thể là Card thứ 3 hoặc Tab "Ký số":
   - Input text "Tài khoản ký số" (map `sign_phone`, maxLength=20, pattern số điện thoại).
   - Upload PNG 150×150 "Ảnh chữ ký" (hiển thị preview, cho thay/xóa).
4. **Auth store:** bổ sung `signPhone` / `signImage` vào `UserInfo` để form pre-fill; API `/auth/me` phải trả thêm 2 field này.

### Implementation Plan

**Thứ tự TUẦN TỰ (1 agent duy nhất làm 3 wave vì share files):**

**Wave 1 — DB SP (~ 10 min)**
- Tạo migration nhỏ hoặc dùng script run inline: `CREATE OR REPLACE FUNCTION public.fn_staff_update_signature(p_id INT, p_sign_phone VARCHAR, p_sign_ca TEXT, p_sign_image VARCHAR) RETURNS BOOLEAN`.
- Kiểm tra `\d public.staff` đã xác nhận cột tồn tại → **không cần ALTER TABLE**.
- Chạy trực tiếp bằng `docker exec qlvb_postgres psql ...` + test SP.

**Wave 2 — Backend (~ 20 min)**
- **Tạo route mới riêng**: `backend/src/routes/profile.ts` — mount tại `/api/ho-so-ca-nhan` với chỉ `authenticate` (KHÔNG `requireRoles`).
- Route 1: `PATCH /chu-ky-so` body `{ sign_phone, sign_ca? }` → lấy `staffId` từ JWT (KHÔNG cho body) → gọi SP.
- Route 2: `POST /anh-chu-ky` multipart field `file` → validate mimetype = `image/png` → upload MinIO path `signatures/${staffId}/${uuid}.png` → gọi SP update `sign_image`.
- Route 3: `GET /anh-chu-ky` → presigned URL 1h để preview (dùng `getFileUrl`).
- Thêm `getStaffSignature` vào repository hoặc mở rộng `fn_staff_get_by_id` trả thêm 3 field (đã trả rồi — xem `StaffDetailRow` line 59-61).
- Update `/api/auth/me` (xem `backend/src/services/auth.service.ts`): nếu chưa trả `sign_phone` / `sign_image` thì thêm.
- Mount `profileRoutes` trong `server.ts` sau block `/api/van-ban-den` với pattern: `app.use('/api/ho-so-ca-nhan', authenticate, profileRoutes);`

**Wave 3 — Frontend (~ 30 min)**
- Đọc lại `interface UserInfo` trong `stores/auth.store.ts`, thêm `signPhone?: string; signImage?: string;`.
- Page `thong-tin-ca-nhan/page.tsx`: thêm Card "Chữ ký số" (hoặc chuyển sang Tabs: "Đổi mật khẩu" / "Chữ ký số"). Ưu tiên Tabs để giữ layout gọn.
- Form Card "Chữ ký số":
  - `Input` (`sign_phone`) — label "Tài khoản ký số (SmartCA)", maxLength=20, pattern `^[0-9+\-\s()]*$`, placeholder "Ex: 84813789393".
  - `Upload` (single image) với `beforeUpload` validate: `file.type === 'image/png'` → message.error('Chỉ chấp nhận PNG'). Kiểm tra kích thước bằng `new Image()` + FileReader, yêu cầu 150×150 (hoặc cảnh báo nếu khác). Trả `false` trong `beforeUpload` để KHÔNG auto-upload — dùng custom submit bằng FormData.
  - Preview: `<Avatar shape="square" size={150} src={signImageUrl} />`. Nếu chưa có → placeholder.
  - Button "Lưu thông tin ký số" → 2 call (nếu có file mới thì upload trước, rồi patch text).
- Sau save: gọi `fetchMe()` để refresh store.

### Pitfalls

- **AntD 6 Upload**: KHÔNG dùng `action` prop — làm manual upload qua axios để đính kèm token JWT.
- **Validate 150×150**: dùng FileReader → `new Image()` → check `img.width === 150 && img.height === 150`. Nếu không đúng → `message.warning` nhưng vẫn cho submit (để linh hoạt). Hoặc strict reject theo HDSD cũ.
- **Mount đường đúng**: KHÔNG đặt route mới vào `/api/quan-tri/...` — sẽ dính `requireRoles('Quản trị hệ thống')`. Phải mount `/api/ho-so-ca-nhan` riêng với chỉ `authenticate`.
- **MinIO bucket path**: dùng `signatures/${staffId}/${uuid}.png` để tránh xung đột. Nếu user upload lại, optional: xóa file cũ bằng `deleteFile(old_path)`.
- **Field naming SP → repo → FE**: SP trả `sign_phone`, `sign_ca`, `sign_image` (đã kiểm tra `\d staff`). FE dùng `signPhone`, `signImage` (camelCase map trong auth store). **Nếu copy từ `StaffDetailRow`** → giữ snake_case.
- **reserved word check**: `sign_phone`, `sign_ca`, `sign_image` — không phải reserved word, OK.

---

## GAP 2 — VB liên thông: Đồng ý / Từ chối yêu cầu Thu hồi

### Current State

- Bảng `edoc.inter_incoming_docs` có cột `status VARCHAR(50)` với enum hiện tại: `pending`, `received`, `completed`, `returned` (có `'returned'` nhưng đó là "chuyển lại / từ chối bàn giao", không phải thu hồi).
- Route `/api/van-ban-lien-thong` có sẵn 3 action: `/nhan-ban-giao` (pending→received), `/chuyen-lai` (pending→returned), `/hoan-thanh` (received→completed).
- KHÔNG có logic "yêu cầu thu hồi" hiện tại — grep `recall|thu_hoi|withdraw` = không match.
- `lgsp_tracking` table tồn tại nhưng `direction` chỉ có `send`/`receive`, chưa có `recall_request`.
- HDSD cũ (theo nghiệp vụ LGSP chuẩn): cơ quan **gửi** có thể **yêu cầu thu hồi** VB đã gửi đi → VB phía **nhận** xuất hiện trạng thái "Đang yêu cầu thu hồi" → bên nhận ấn **Đồng ý** (VB bị xóa/ẩn) hoặc **Từ chối** (VB giữ nguyên, có phản hồi).

### What's Missing

1. **Status mới:** thêm 2 trạng thái vào `edoc.inter_incoming_docs.status`:
   - `recall_requested` — Đang yêu cầu thu hồi
   - `recalled` — Đã thu hồi (sau khi bên nhận đồng ý)
   - (Giữ nguyên `completed` cho trường hợp đã xử lý nên không thu hồi được nữa)
2. **Optional cột metadata:** `recall_reason TEXT`, `recall_requested_at TIMESTAMPTZ`, `recall_response TEXT`, `recall_responded_by INT`, `recall_responded_at TIMESTAMPTZ` — để audit trail và hiển thị.
3. **2 SP mới:**
   - `edoc.fn_inter_incoming_recall_approve(p_id, p_staff_id)` — validate `status = 'recall_requested'` → set `status = 'recalled'`, xóa (mark deleted hoặc cascade) VB đến đã phát sinh từ `fn_inter_incoming_receive`.
   - `edoc.fn_inter_incoming_recall_reject(p_id, p_staff_id, p_reason)` — validate status → set status về trạng thái trước đó (ví dụ lưu `status_before_recall`) hoặc đơn giản là `received`/`pending`, ghi `recall_response`.
4. **2 route mới** trong `routes/inter-incoming.ts`:
   - `POST /:id/dong-y-thu-hoi` body `{}` (reason optional)
   - `POST /:id/tu-choi-thu-hoi` body `{ reason: string }` (reason bắt buộc)
5. **Repository method** trong `inter-incoming.repository.ts`: `recallApprove()`, `recallReject()`.
6. **Frontend:** trong `van-ban-lien-thong/[id]/page.tsx` — thêm 2 button hiển thị có điều kiện khi `doc.status === 'recall_requested'`:
   - Button "Đồng ý thu hồi" (danger, `Popconfirm`)
   - Button "Từ chối thu hồi" → mở Modal nhập lý do bắt buộc
   - Cập nhật `STATUS_MAP`: thêm `recall_requested: { text: 'Đang yêu cầu thu hồi', color: 'volcano' }`, `recalled: { text: 'Đã thu hồi', color: 'red' }`.

### Implementation Plan

**Thứ tự TUẦN TỰ trong 1 agent (vì share file):**

**Wave 1 — DB (~ 15 min)**
- Migration mới hoặc inline script:
  - `ALTER TABLE edoc.inter_incoming_docs ADD COLUMN IF NOT EXISTS recall_reason TEXT, ADD COLUMN recall_requested_at TIMESTAMPTZ, ADD COLUMN recall_response TEXT, ADD COLUMN recall_responded_by INT, ADD COLUMN recall_responded_at TIMESTAMPTZ;` (hoặc cắt gọn chỉ 2 cột `recall_response` + `recall_responded_at` nếu muốn đơn giản).
  - Tạo 2 SP theo pattern `fn_inter_incoming_return` (line 8947-8972). Nhớ `SECURITY DEFINER`, trả `TABLE(success BOOLEAN, message TEXT)`.
  - **Phạm vi giới hạn:** Task này CHỈ làm UI Đồng ý/Từ chối khi `status='recall_requested'` đã tồn tại. Việc **khởi tạo** `recall_requested` (từ LGSP worker poll hoặc từ UI cơ quan gửi) là work khác. Vì vậy cần seed vài dòng test bằng SQL manual để test UI.
- Test 2 SP bằng psql trước khi code backend.

**Wave 2 — Backend (~ 15 min)**
- Thêm 2 method vào `inter-incoming.repository.ts`: `recallApprove(id, staffId)`, `recallReject(id, staffId, reason)`.
- Thêm 2 route vào `routes/inter-incoming.ts` (ngay sau `/hoan-thanh` — xem line 97-110 cho pattern):
  - `POST /:id/dong-y-thu-hoi` — giống `/hoan-thanh`
  - `POST /:id/tu-choi-thu-hoi` — giống `/chuyen-lai` (có body `reason`)
- Điều chỉnh `fn_inter_incoming_get_by_id` SP để trả thêm field `recall_reason`, `recall_requested_at` (cho FE hiển thị). Hoặc chấp nhận lướt qua — UI chỉ cần biết status.

**Wave 3 — Frontend (~ 20 min)**
- `LienThongDocDetailPage`: thêm 2 handler `handleDongYThuHoi`, `handleTuChoiThuHoi` (copy pattern `handleChuyenLai`).
- Thêm 2 button trong khu vực action (conditional render `doc.status === 'recall_requested'`).
- Modal "Từ chối thu hồi": giống `chuyenLaiOpen` modal, field `reason` required.
- Update `STATUS_MAP` trong cả `page.tsx` (list) và `[id]/page.tsx` (detail).
- Update `LienThongDocDetail` interface nếu trả thêm `recall_reason`.

### Pitfalls

- **Status cascade**: khi approve thu hồi, VB đến (`incoming_docs`) đã tạo từ `fn_inter_incoming_receive` vẫn còn! SP approve cần `DELETE FROM edoc.incoming_docs WHERE is_inter_doc=TRUE AND inter_doc_id=p_id` (đã có cột `is_inter_doc`, `inter_doc_id` — xem SP receive line 8921). Hoặc soft-delete nếu có cột; incoming_docs không có `is_deleted` (kiểm tra `\d edoc.incoming_docs` trước).
- **Validate status hiện tại**: SP phải check `v_status = 'recall_requested'` trước khi chuyển. Copy chính xác pattern từ `fn_inter_incoming_return`.
- **Seed test data**: Để test UI Đồng ý/Từ chối, chạy manual: `UPDATE edoc.inter_incoming_docs SET status='recall_requested', recall_reason='Test' WHERE id=1;`
- **Frontend status check**: `doc.status === 'recall_requested'` — phải match chính xác string (DB VARCHAR case-sensitive).
- **Router Dropdown vs separate buttons**: 2 action này có logic mutually exclusive → dùng 2 Button rời cho rõ ràng, hoặc Space với 2 Popconfirm. KHÔNG cần Dropdown.

---

## GAP 3 — HSCV: Mở lại + Lấy số

### Current State

- Bảng `edoc.handling_docs` dùng `status SMALLINT` — các giá trị đã dùng thực tế: `0, 1, 2, 4` (DB check). Enum: 0=Nháp, 1=Đang xử lý, 2=Đã gửi trình ký, 3=Đã duyệt, 4=Hoàn thành, 5=Tạm dừng, -1/-2=Trả về/Từ chối, -3=Đã hủy.
- Bảng có sẵn các cột cho "số văn bản": `number INT`, `sub_number VARCHAR(20)`, `notation VARCHAR(100)`, `doc_book_id INT` — tái dụng pattern giống outgoing_doc.
- SP "Lấy số" mẫu: `edoc.fn_outgoing_doc_get_next_number(p_doc_book_id, p_unit_id)` (line 6038-6054) — pattern chuẩn: `SELECT COALESCE(MAX(number),0)+1 ... WHERE doc_book_id=p_doc_book_id AND unit_id=p_unit_id AND EXTRACT(YEAR FROM received_date) = EXTRACT(YEAR FROM NOW())`.
- Hiện có các SP HSCV: `fn_handling_doc_submit`, `_approve`, `_reject`, `_return`, `_complete`, `_change_status` + `_update_progress`. Route `PATCH /ho-so-cong-viec/:id/trang-thai` nhận `action: submit|approve|reject|return|complete|change` (line 472).
- Frontend `ho-so-cong-viec/[id]/page.tsx` có toolbar buttons theo status (line 206-245):
  - status=4 (Hoàn thành): chỉ có "Xem lịch sử" — **CHƯA có "Mở lại"** → Gap này.
  - Các status khác không có "Lấy số" → Gap này.

### What's Missing

1. **"Mở lại" (status=4 → status=1):** cần SP `fn_handling_doc_reopen(p_id, p_staff_id)` validate `v_status=4` → set `status=1`, `complete_date=NULL`, `complete_user_id=NULL`, `progress=`(giữ nguyên hoặc reset 80).
2. **"Lấy số":** cần SP `fn_handling_doc_get_next_number(p_doc_book_id, p_unit_id)` + SP `fn_handling_doc_assign_number(p_id, p_doc_book_id, p_staff_id)`:
   - Validate HSCV có `doc_book_id` (nếu chưa → lỗi "Chưa chọn sổ văn bản").
   - Validate chưa có `number` (nếu đã có → cảnh báo "Đã lấy số rồi").
   - Tính `next_number = fn_handling_doc_get_next_number(doc_book_id, unit_id)`.
   - `UPDATE handling_docs SET number = next_number, updated_by = p_staff_id, updated_at = NOW() WHERE id = p_id`.
3. **Route:** mở rộng enum `validActions` trong `PATCH /ho-so-cong-viec/:id/trang-thai` (line 472 `handling-doc.ts`) → thêm `'reopen'`. Hoặc tạo 2 endpoint riêng:
   - `POST /ho-so-cong-viec/:id/mo-lai` — đơn giản, không body
   - `POST /ho-so-cong-viec/:id/lay-so` — body `{ doc_book_id }`
   
   Khuyến nghị: **tạo 2 endpoint riêng** để giữ contract rõ ràng (không mix vào trang-thai).
4. **Repository:** thêm `reopen()`, `assignNumber()`, `getNextNumber()` vào `handling-doc.repository.ts`.
5. **Frontend:** 
   - `getToolbarButtons(4)` — thêm `{ label: 'Mở lại', type: 'primary', action: 'reopen' }` trước "Xem lịch sử".
   - `getToolbarButtons(1)` và `(3)` — thêm `{ label: 'Lấy số', type: 'default', action: 'get_number' }` (vị trí hợp lý — trước "Hoàn thành" hoặc trong Dropdown).
   - Handler `handleReopen`: `api.post(/ho-so-cong-viec/${id}/mo-lai)` → refresh.
   - Handler `handleLaySo`: nếu `detail.doc_book_id` chưa có → mở `Modal` chọn sổ văn bản (`Select` tree từ `/quan-tri/so-van-ban`). Có rồi → `Popconfirm` xác nhận → `api.post(/ho-so-cong-viec/${id}/lay-so, { doc_book_id })` → hiển thị số mới bằng `message.success('Đã lấy số ${number}/${doc_book_code}')` và refresh.

### Implementation Plan

**Thứ tự TUẦN TỰ trong 1 agent:**

**Wave 1 — DB (~ 15 min)**
- Tạo 3 SP trong migration/inline script:
  - `fn_handling_doc_reopen(p_id, p_staff_id)` → pattern giống `fn_handling_doc_complete` (line 7806) nhưng điều kiện `v_status = 4` → set `status=1`.
  - `fn_handling_doc_get_next_number(p_doc_book_id, p_unit_id)` → copy `fn_outgoing_doc_get_next_number` (line 6038) nhưng bảng `edoc.handling_docs` + cột date phù hợp (`start_date` hoặc `created_at` — xem SP get list để quyết định field năm).
  - `fn_handling_doc_assign_number(p_id, p_doc_book_id, p_staff_id)` trả `TABLE(success BOOLEAN, message TEXT, number INT)`.
- Test cả 3 SP bằng psql.

**Wave 2 — Backend (~ 15 min)**
- Repository: thêm 3 method tương ứng.
- Route `handling-doc.ts`:
  - `POST /:id/mo-lai` → `reopen()` → trả `{ success, message }`.
  - `POST /:id/lay-so` body `{ doc_book_id }` → `assignNumber()` → trả `{ success, message, number }`.
- KHÔNG động vào `/trang-thai` endpoint hiện có (tránh break logic cũ).

**Wave 3 — Frontend (~ 20 min)**
- Update `getToolbarButtons()`:
  - case 4: thêm `{ label: 'Mở lại', type: 'primary', action: 'reopen' }`, `{ label: 'Lấy số', type: 'default', action: 'get_number' }` nếu chưa có số.
  - case 1, 3: thêm `{ label: 'Lấy số', ... }` conditional (check `detail.number === null`).
- Handler `handleButtonClick`: case `'reopen'` → Popconfirm → post. Case `'get_number'` → logic như plan trên.
- Hiển thị số văn bản trong detail: thêm field `number` + `doc_book_code` vào header hoặc tab Info. Xem SP `fn_handling_doc_get_by_id` trả `number` không — nếu chưa thì bổ sung (line 7047 — đọc và verify).
- Interface `HscvDetail` (line 45): bổ sung `number: number | null`, `sub_number: string | null`, `notation: string | null`, `doc_book_id: number | null`, `doc_book_name: string | null`.

### Pitfalls

- **HSCV `status`: type SMALLINT, FE dùng `number`** — giữ nguyên, không nhầm sang VARCHAR như `inter_incoming_docs.status`.
- **"Mở lại" sau Hoàn thành**: có thể vi phạm workflow nghiêm ngặt — confirm với sếp trước. Nếu cần audit → SP phải lưu ghi chú vào `comments` hoặc `leader_notes`.
- **Progress khi reopen**: đặt thành bao nhiêu? 80 (gần xong) hay giữ 100? Khuyến nghị 80 theo logic "mở lại để bổ sung".
- **"Lấy số" khi chưa có doc_book_id**: bắt buộc phải có `doc_book_id`. Nếu chưa gán → SP trả error → FE mở Modal chọn sổ rồi gọi lại. Hoặc FE check trước và mở Modal trực tiếp.
- **Năm tính next_number**: `fn_outgoing_doc_get_next_number` dùng `received_date`. HSCV dùng `start_date` hoặc `created_at` — chọn `created_at` cho đơn giản (luôn có giá trị). Verify bằng test SP.
- **reserved word check**: `number` là reserved trong nhiều DB nhưng KHÔNG phải trong PostgreSQL — OK. `order` thì reserved. Ở đây SP không dùng `ORDER`/`LIMIT` alias nên an toàn.
- **Concurrency lấy số**: 2 user cùng ấn "Lấy số" cùng lúc → race condition. Giải pháp: SP `assignNumber` nên `LOCK TABLE ... IN SHARE ROW EXCLUSIVE MODE` hoặc dùng `SELECT ... FOR UPDATE` trên doc_book. Hoặc đơn giản nhất: `UPDATE handling_docs SET number = (SELECT COALESCE(MAX(number),0)+1 FROM handling_docs WHERE doc_book_id=? AND unit_id=?)` — PostgreSQL MVCC sẽ handle. Demo không cần quá lo.

---

## Kế hoạch tổng thể 3 Gap

### Song song được không?

- **Gap 1 (Profile page / Staff)** — chỉ đụng: `staff` table, `profile.ts` route mới, `thong-tin-ca-nhan/page.tsx`, `auth.store.ts`, `auth.service.ts`. **Độc lập.**
- **Gap 2 (VB liên thông)** — đụng: `inter_incoming_docs` table, `inter-incoming.ts` route (sửa), `van-ban-lien-thong/[id]/page.tsx` (sửa). **Độc lập.**
- **Gap 3 (HSCV)** — đụng: `handling_docs` table, `handling-doc.ts` route (sửa), `ho-so-cong-viec/[id]/page.tsx` (sửa). **Độc lập.**

→ **Có thể song song 3 agent** (theo CLAUDE.md "Khi nào được chạy song song? — module hoàn toàn độc lập: không share file, không share bảng"). 3 gap này PASS tiêu chí.

Tuy nhiên vì cùng chạy migration vào DB có thể conflict sequence nếu tạo 1 file migration chung → giải pháp: **mỗi agent chạy SP trực tiếp bằng `docker exec psql` inline, không tạo file migration mới** (migration consolidated đã gộp vào `000_full_schema.sql`). Hoặc mỗi agent viết 1 SQL file riêng biệt tên rõ ràng.

### Thời gian ước tính

| Gap | DB | Backend | Frontend | Tổng |
|-----|-----|---------|----------|------|
| 1 — SmartCA UI | 10' | 20' | 30' | ~60' |
| 2 — Thu hồi | 15' | 15' | 20' | ~50' |
| 3 — HSCV Mở lại + Lấy số | 15' | 15' | 20' | ~50' |

Nếu 3 agent chạy song song: **~60-70 phút** (bottleneck Gap 1).

### Integration check sau mỗi Gap

Theo CLAUDE.md "Integration check sau MỖI wave":
- Sau Wave 1 (DB): test SP bằng `psql` → assert success=true với input hợp lệ, false với invalid.
- Sau Wave 2 (Backend): test endpoint bằng `curl` hoặc Postman với JWT valid.
- Sau Wave 3 (Frontend): mở browser, test happy path + error path.

---

## Checklist lỗi thường gặp (áp dụng riêng cho task này)

Đối chiếu `CLAUDE.md` checklist — các điểm đặc biệt cần chú ý:

- [ ] **#1 Field name mismatch**: SP phải trả đúng tên DB (snake_case). Copy interface từ SP output.
- [ ] **#2 API route path**: Gap 1 mount `/api/ho-so-ca-nhan` (KHÔNG `/quan-tri`), Gap 2-3 extend route hiện có.
- [ ] **#3 Query param**: dùng camelCase nhất quán với các route cũ (`pageSize`, không `page_size`).
- [ ] **#4 Reserved words**: không có vấn đề (kiểm tra: `number`, `sign_phone`, `status`, `recall_*` đều OK).
- [ ] **#5 Cột không tồn tại**: đã verify `\d public.staff` (sign_phone/sign_ca/sign_image có), `\d edoc.handling_docs` (number/doc_book_id có), `\d edoc.inter_incoming_docs` (status có, recall_* CẦN THÊM).
- [ ] **#7 AntD 6**: `Drawer` → `size`; Upload → manual với `beforeUpload` return false.
- [ ] **#8 Data type**: `sign_phone VARCHAR(20)` → FE `<Input>` + maxLength=20. `sign_image VARCHAR(500)` → maxLength=500 ở SP input. `handling_docs.number INTEGER` → FE `<InputNumber>` hiển thị (hoặc read-only).
- [ ] **#9 maxLength**: Gap 1: sign_phone=20, sign_image=500. Gap 2: recall_reason TEXT (no limit).
- [ ] **#10 NOT NULL → required**: reason khi "Từ chối thu hồi" bắt buộc (rules required).
- [ ] **#11 Format validation**: sign_phone pattern số điện thoại.
- [ ] **#13 setBackendFieldError**: Gap 1 cho Input sign_phone (nếu backend validate format).

---

## Sources (verified)

### HIGH confidence (verified by grep/psql)
- DB schema `public.staff` — `docker exec psql \d public.staff` (Gap 1 không cần migration cột)
- DB schema `edoc.inter_incoming_docs` — (Gap 2 cần thêm cột recall_*)
- DB schema `edoc.handling_docs` — có `number`, `sub_number`, `notation`, `doc_book_id`
- SP patterns: `fn_outgoing_doc_get_next_number` (line 6038), `fn_inter_incoming_return` (line 8947), `fn_handling_doc_complete` (line 7806)
- Route mount points — `server.ts` line 60-88 (`/api/quan-tri` requires admin role — KHÔNG dùng cho profile)
- Old system reference — `docs/source_code_cu/sources/OneWin.WebApp/Areas/Manager/Views/Department/UserInfo.cshtml` line 122, 131 confirmed SignImage 150px + SignPhone input

### MEDIUM confidence
- "Mở lại" từ status 4 là business choice — chưa confirm 100% với user, dùng progress=80 là assumption.
- Khi "Đồng ý thu hồi", việc cascade xóa incoming_docs đã tạo — dựa trên suy luận từ cột `is_inter_doc`, `inter_doc_id`. Cần user confirm behavior trước khi implement SP.

### Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Approve thu hồi → xóa `incoming_docs` có `is_inter_doc=TRUE AND inter_doc_id=p_id` | Gap 2 | Nếu nghiệp vụ chỉ soft-delete hoặc giữ lại → SP sai logic, data lost |
| A2 | "Mở lại" HSCV set progress=80 | Gap 3 | Nếu user muốn giữ 100 hoặc về 50 → cần sửa SP sau |
| A3 | "Lấy số" tính `MAX(number)+1` theo năm `created_at` | Gap 3 | Nếu đơn vị muốn reset số theo `start_date` hoặc không reset theo năm → số sai |
| A4 | SmartCA account input là `sign_phone` (số điện thoại) | Gap 1 | Old HDSD xác nhận (`SignPhone`), risk thấp |
| A5 | Ảnh chữ ký PNG 150×150 bắt buộc | Gap 1 | Có thể nghiệp vụ chấp nhận kích thước khác — recommend warning thay vì reject |
| A6 | 3 gap độc lập, chạy song song được | Tổng | Nếu user muốn TUẦN TỰ để audit step-by-step → phải chạy serial |

---

## Khuyến nghị chốt

1. **Confirm với user trước khi implement Gap 2:** hành vi approve thu hồi có xóa VB đến không?
2. **Chạy song song 3 agent** với 3 file scope rõ ràng — tiết kiệm thời gian demo cuối tuần.
3. **KHÔNG commit trong task này** — chờ user verify UI rồi mới commit (theo CLAUDE.md `feedback_commit_on_request`).
4. **Gap 1 quan trọng nhất** (block luồng ký số SmartCA) → ưu tiên cao nhất nếu chỉ làm được 1 gap.
