# Quick Task 260418-jsd — Research: Fix 6 Gap HDSD còn lại

**Researched:** 2026-04-18
**Domain:** HDSD compliance — ký số mock OTP, gửi trục CP mock, mở rộng form chuyển lưu trữ VB đi, hủy HSCV riêng, chuyển tiếp ý kiến HSCV, chuyển tiếp HSCV (transfer ownership)
**Confidence:** HIGH (hầu hết infra đã có; chủ yếu cần glue code + schema nhỏ)

## Summary

6 gap này tiếp nối P0/P1 (task `260418-hlj` đã hoàn thành 2 gap SmartCA UI + thu hồi + HSCV mở lại/lấy số). Tin tốt: **phần lớn backend + schema đã sẵn sàng**:

- Mock ký số per-attachment (`fn_attachment_mock_sign/verify`) đã tồn tại — chỉ thiếu UI + Modal OTP.
- `fn_lgsp_tracking_create` đã support multi-direction — cần fork thành endpoint "Gửi trục CP" (hoặc thêm `channel` column).
- `esto.fn_document_archive_create` có 13 param đủ dùng — VB đến đã dùng form đầy đủ, VB đi CHƯA có modal.
- `fn_handling_doc_get_next_number/assign_number/reopen` đã deploy từ task `hlj`.
- HSCV page đã có nút "Hủy HSCV" nhưng dùng `action=change, new_status=-3` không thu lý do.
- `opinion_handling_docs` table hiện chỉ có `content/staff_id` — chưa hỗ trợ forward chain.
- `handling_docs.curator` đã là field ownership — cần endpoint transfer + history table mới.

**Primary recommendation:** Thực thi **tuần tự 6 task** (tránh parallel — đã dính bug Phase 5). Tạo 1-2 migration file tổng (`quick_260418_jsd_*.sql`), tái sử dụng SPs/patterns từ task `hlj` để đảm bảo consistency. Toàn bộ mock endpoint phải có `// TODO Phase 2: tích hợp thực` comment.

## Phase Requirements

| ID     | Mô tả                                                                                                    | Research Support                                                                 |
| ------ | -------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| TC-011 | UI ký số mock OTP trên VB đi + VB dự thảo                                                                | Gap A — mock SP sẵn, chỉ cần Modal OTP + button integration                      |
| TC-045 | Gửi trục CP (mock) trên VB đi                                                                            | Gap B — fork pattern LGSP hiện có                                                |
| TC-046 | Mở rộng form chuyển lưu trữ VB đi (copy từ VB đến)                                                       | Gap C — endpoint `/chuyen-luu-tru` đã có; chỉ thiếu Drawer UI                    |
| TC-066 | Hủy HSCV thành action riêng (cần lý do)                                                                  | Gap D — cần SP `fn_handling_doc_cancel` + schema cột mới `cancel_reason`         |
| TC-067 | Chuyển tiếp ý kiến HSCV (forward opinion to another staff)                                               | Gap E — mở rộng `opinion_handling_docs` + SP `fn_opinion_forward`                |
| TC-068 | Chuyển tiếp HSCV (transfer ownership — curator change)                                                   | Gap F — cần SP + history table mới                                               |

---

## Gap A — TC-011: UI ký số mock OTP

### Current State

- **Backend mock sẵn**: `backend/src/routes/digital-signature.ts` đã có `POST /mock/sign` + `POST /mock/verify` (gọi `edoc.fn_attachment_mock_sign` / `fn_attachment_mock_verify`). Route mounted tại `/api/ky-so` (line 91 server.ts).
- **DB sẵn**: `attachment_outgoing_docs` và `attachment_drafting_docs` đã có 3 cột: `is_ca BOOLEAN`, `ca_date TIMESTAMPTZ`, `signed_file_path VARCHAR(1000)` (migration 027 — đã áp dụng).
- **Frontend chưa có**: Page `/van-ban-di/[id]` (511 lines) + `/van-ban-du-thao/[id]` (500 lines) chưa có nút "Ký số" trên attachment rows.
- **SP mock hiện tại**: `fn_attachment_mock_sign(p_attachment_id, p_attachment_type, p_signed_by)` — set `is_ca=true, ca_date=NOW(), signed_file_path=file_path`. **KHÔNG nhận OTP**. Verify là no-op (luôn trả valid nếu `is_ca=true`).

### What's Missing

1. Nút "Ký số" trên mỗi attachment row (VB đi + VB dự thảo).
2. Modal OTP giả lập: nhập 6 digits → gọi `/ky-so/mock/sign` sau khi "xác thực OTP" (FE-side simulation — không gọi backend verify).
3. Tag "Đã ký số" hiển thị khi `is_ca=true` + badge "Chưa ký" khi `is_ca=false`.
4. **Không cần schema mới** — chỉ extend `attachment_outgoing_docs` row interface (BE) + UI (FE).

### Implementation Plan

| Step | File                                                                                       | Action                                                                                                |
| ---- | ------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------- |
| A.1  | `backend/src/repositories/outgoing-doc.repository.ts`                                      | Verify `getAttachments()` SP trả về `is_ca, ca_date, signed_file_path` (nếu chưa → bổ sung SP)       |
| A.2  | `backend/src/repositories/drafting-doc.repository.ts`                                      | Tương tự — đảm bảo attachment query trả 3 field `is_ca/ca_date/signed_file_path`                     |
| A.3  | `frontend/src/app/(main)/van-ban-di/[id]/page.tsx`                                         | Thêm nút "Ký số" trong column "Thao tác" của attachment table; Modal OTP (6-digit `<Input.OTP>`)      |
| A.4  | `frontend/src/app/(main)/van-ban-du-thao/[id]/page.tsx`                                    | Copy pattern từ A.3                                                                                   |

**Modal OTP pattern (AntD 6.3.5):**

```tsx
import { Input } from 'antd';
// AntD 5.13+ support <Input.OTP length={6} />
<Modal title="Xác thực OTP để ký số" open={otpOpen} onOk={handleVerify} onCancel={() => setOtpOpen(false)}
  okText="Xác nhận ký" cancelText="Hủy" confirmLoading={signing}>
  <p>Nhập mã OTP (6 chữ số) đã gửi đến số điện thoại đăng ký SmartCA:</p>
  <Input.OTP length={6} value={otp} onChange={setOtp} />
</Modal>
```

FE-side flow: nhấn nút → Modal OTP → nhập 6 digits → nhấn "Xác nhận ký" → gọi `POST /api/ky-so/mock/sign` với `{attachment_id, attachment_type}` → success → reload attachments. **Không gọi verify endpoint** trong flow ký (chỉ dùng khi preview "Xác thực chữ ký").

### Pitfalls / Questions

- `<Input.OTP>` có trong AntD 5.13+. AntD 6.3.5 kế thừa. Nếu lỗi import thử fallback `<Input maxLength={6}>`.
- **NHỚ**: mock bỏ qua validation OTP thực — user nhập bất kỳ 6 digits đều pass. Để comment `// TODO Phase 2: gọi BE verify OTP thực`.
- `attachment_type` phải match đúng SP expectation: `'outgoing'` cho VB đi, `'drafting'` cho VB dự thảo.
- Check nếu hiện tại SP `fn_outgoing_doc_get_attachments` có trả `is_ca/ca_date` — nếu không, thêm DROP/CREATE (per CLAUDE.md rule 2).

**Estimated complexity:** Small (90% đã sẵn, chỉ UI glue)

---

## Gap B — TC-045: Gửi trục CP (mock)

### Current State

- **Backend LGSP pattern sẵn**: `outgoing-doc.ts:708` — `POST /:id/gui-lien-thong` nhận `{org_codes: [{code, name}]}`, loop gọi `outgoingDocRepository.sendLgsp(docId, code, name, staffId)` → `edoc.fn_lgsp_tracking_create`.
- **DB table**: `edoc.lgsp_tracking` — có `direction CHECK IN ('send','receive')` nhưng **KHÔNG có cột phân biệt kênh** (LGSP tỉnh vs Trục Chính Phủ).
- **Frontend**: `/van-ban-di/[id]/page.tsx:238` nút "Gửi liên thông" chỉ hiện khi `doc.approved=true`. Modal `lgspModalOpen` load orgs từ `/van-ban-den/1/lgsp/don-vi`.

### What's Missing

1. Cột phân biệt kênh trong `lgsp_tracking`: `channel VARCHAR(20) DEFAULT 'lgsp' CHECK IN ('lgsp','cp')`.
2. SP mới `fn_lgsp_tracking_create_cp` HOẶC mở rộng SP hiện có thêm tham số `p_channel`.
3. Endpoint mới: `POST /api/van-ban-di/:id/gui-truc-cp` — mock, chọn bộ/ngành trung ương thay vì LGSP tỉnh.
4. Nút "Gửi trục CP" + Modal tương tự LGSP trên VB đi detail page.
5. Danh sách bộ/ngành mock (hardcode 5-10 mục: Văn phòng CP, Bộ Nội vụ, Bộ Tài chính, Bộ Tư pháp, Bộ GDĐT...).

### Implementation Plan

| Step | File                                                                   | Action                                                                                                       |
| ---- | ---------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| B.1  | `database/migrations/quick_260418_jsd_truc_cp.sql`                     | `ALTER TABLE edoc.lgsp_tracking ADD COLUMN channel VARCHAR(20) DEFAULT 'lgsp'` + `CHECK`; DROP/CREATE SP `fn_lgsp_tracking_create` thêm `p_channel`         |
| B.2  | `backend/src/repositories/outgoing-doc.repository.ts`                  | Thêm method `sendCp(docId, destOrgCode, destOrgName, createdBy)` gọi SP với `channel='cp'`                  |
| B.3  | `backend/src/routes/outgoing-doc.ts` (sau line 727)                    | Endpoint `POST /:id/gui-truc-cp` — nhận `{org_codes}`, hardcode list orgs hoặc reuse từ FE                   |
| B.4  | `frontend/src/app/(main)/van-ban-di/[id]/page.tsx`                     | Button "Gửi trục CP" (green, kế "Gửi liên thông"); Modal riêng `cpModalOpen` với hardcoded list bộ/ngành     |

### Pitfalls / Questions

- **Reserved word**: `channel` không phải reserved → OK. Nhưng `direction` cũng không phải.
- **Mock data source**: hardcode FE-side (simpler) HOẶC seed vào `lgsp_organizations` với `parent_code='CP'` marker. **Khuyến nghị FE-side** (đỡ migration data).
- **Button visibility**: "Gửi trục CP" chỉ hiện khi `doc.approved=true`, giống LGSP.
- **Cần review**: lý tưởng thì FE đọc danh sách bộ/ngành CP từ 1 endpoint `/lgsp/co-quan-cp` — trả array tĩnh. Nếu làm nhanh → FE hardcode.

**Estimated complexity:** Small (70% copy pattern từ LGSP)

---

## Gap C — TC-046: Chuyển lưu trữ VB đi — mở rộng form

### Current State

- **Backend đã có endpoint**: `outgoing-doc.ts:740` — `POST /:id/chuyen-luu-tru` gọi `incomingDocRepository.createArchive('outgoing', ...)` → `esto.fn_document_archive_create`.
- **SP đã full 13 param**: `warehouse_id, fond_id, record_id, file_catalog, file_notation, doc_ordinal, language, autograph, keyword, format, confidence_level, is_original, archived_by`.
- **VB đến làm đúng**: `van-ban-den/[id]/page.tsx:876-901` có Drawer đầy đủ form với tất cả 13 field. Đây là template chuẩn.
- **VB đi page CHƯA có modal/form**: hoàn toàn thiếu UI chuyển lưu trữ. Chỉ có Tag hiển thị trạng thái `archive_status` (line 332).

### What's Missing

1. **Button "Chuyển lưu trữ"** trên toolbar VB đi detail (conditional: `!doc.archive_status`).
2. **Drawer form đầy đủ** — copy nguyên đoạn 876-901 từ VB đến sang VB đi.
3. **Load dropdowns**: warehouses + fonds (hiện VB đến đã có `fetchWarehouses/fetchFonds`).
4. **Không cần thêm schema/SP** — endpoint + SP đã có.

### Implementation Plan

| Step | File                                                     | Action                                                                                                       |
| ---- | -------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| C.1  | `frontend/src/app/(main)/van-ban-di/[id]/page.tsx`       | Import `Drawer, Row, Col, Select, InputNumber, Checkbox, Form`; state `archiveForm, archiveModalOpen, warehouseOptions, fondOptions`; `fetchWarehouses()`, `fetchFonds()`; `handleOpenArchive()`, `handleArchive()` |
| C.2  | Same file                                                | Thêm button toolbar "Chuyển lưu trữ" conditional `{doc.approved && !doc.archive_status && ...}`              |
| C.3  | Same file                                                | Thêm Drawer (copy nguyên từ VB đến line 876-901) — đổi endpoint `/van-ban-di/${docId}/chuyen-luu-tru`       |

### Pitfalls / Questions

- **Endpoint dropdowns**: VB đến dùng gì để load `warehouseOptions/fondOptions`? Check `van-ban-den/[id]/page.tsx` cho `fetchWarehouses` — có thể dùng lại `/kho-luu-tru/kho-options` hoặc `/kho-luu-tru/phong-options`. Nếu không có → đọc và tái sử dụng.
- **Drawer size**: VB đến dùng `size={640}` — giữ nguyên cho consistency.
- **`form.setFieldsValue` default**: VB đến set `{ language: 'Tiếng Việt', format: 'Điện tử', is_original: true }` khi mở — PHẢI giữ defaults này.
- **Tag trạng thái**: sau khi chuyển lưu trữ, `archive_status=true` → ẩn nút + đổi Tag.

**Estimated complexity:** Small (90% copy-paste; chỉ cần verify endpoint dropdowns)

---

## Gap D — TC-066: Hủy HSCV action riêng (có lý do)

### Current State

- **HSCV đã có nút "Hủy HSCV"**: `ho-so-cong-viec/[id]/page.tsx:262` — nhưng chỉ dùng `{action: 'change', newStatus: -3}` qua endpoint `PATCH /:id/trang-thai`.
- **SP `fn_handling_doc_change_status` chung** — KHÔNG thu lý do cho hành động hủy (chỉ reject/return).
- **Schema `handling_docs` KHÔNG có cột** `cancel_reason`, `cancelled_at`, `cancelled_by`.
- **Status code -3** đã được dùng semantic "đã hủy" nhưng chưa enforced.

### What's Missing

1. **Cột mới** trên `handling_docs`: `cancel_reason TEXT`, `cancelled_at TIMESTAMPTZ`, `cancelled_by INT REFERENCES public.staff(id)`.
2. **SP mới** `edoc.fn_handling_doc_cancel(p_id BIGINT, p_user_id INT, p_reason TEXT)` — set `status=-3`, lưu reason + audit fields.
3. **Endpoint mới**: `POST /api/ho-so-cong-viec/:id/huy` (tách khỏi `/trang-thai`).
4. **Frontend**: thay đổi button "Hủy HSCV" trong case -1/-2 (có thể cả case 0/1 nếu nghiệp vụ cần) → `action='cancel'` → Modal input lý do.
5. **Hiển thị lý do hủy** trên detail khi `status=-3` (tương tự Gap 2 thu hồi).

### Implementation Plan

| Step | File                                                         | Action                                                                                                                              |
| ---- | ------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------- |
| D.1  | `database/migrations/quick_260418_jsd_hscv_cancel.sql`       | `ALTER TABLE edoc.handling_docs ADD COLUMN cancel_reason TEXT, cancelled_at TIMESTAMPTZ, cancelled_by INT`; CREATE FUNCTION `fn_handling_doc_cancel`; DROP/CREATE `fn_handling_doc_get_by_id` thêm 3 field |
| D.2  | `backend/src/repositories/handling-doc.repository.ts`        | Thêm method `cancel(id, staffId, reason)` gọi SP; update `HscvDetailRow` interface thêm 3 field                                     |
| D.3  | `backend/src/routes/handling-doc.ts`                         | Endpoint `POST /:id/huy` (sau `/lay-so`)                                                                                           |
| D.4  | `frontend/src/app/(main)/ho-so-cong-viec/[id]/page.tsx`      | Đổi button trong `getToolbarButtons` case -1/-2 → `{action: 'cancel'}`; thêm handler `handleCancel()` dùng `modal.confirm` + `TextArea`; Card hiển thị `cancel_reason` + `cancelled_at` khi `status=-3` |

### Pitfalls / Questions

- **Status -3 đã tồn tại?** Check: `handling_docs.status SMALLINT DEFAULT 0`. Status CHECK không có trong schema → ok thêm `-3`. Nhưng **kiểm tra các SP khác** có ràng buộc `status IN (...)` không.
- **Validation**: reason phải non-empty (pattern giống reject/return trong `/trang-thai`).
- **DROP/CREATE `fn_handling_doc_get_by_id`** (lần 3 — sau hlj đã DROP/CREATE thêm 4 field). Cần giữ tất cả field cũ + thêm 3 field mới.
- **Reserved word**: `"order"`, `"position"` không dính. Nhưng `cancelled_by` OK.
- **Nghiệp vụ**: nút "Hủy" nên hiện ở status nào? HDSD cũ thường cho phép hủy status 0/1/-1/-2 (chưa duyệt, chưa hoàn thành). NOT 4 (hoàn thành). Plan nên clarify với user hoặc default = case -1,-2 (đã có).

**Estimated complexity:** Medium (schema + SP + route + UI đổi)

---

## Gap E — TC-067: Chuyển tiếp ý kiến HSCV

### Current State

- **Table hiện tại `opinion_handling_docs`**: `id, handling_doc_id, staff_id, content, attachment_path, created_at`. **KHÔNG có forward fields**.
- **SP `fn_opinion_create(p_doc_id, p_staff_id, p_content, p_opinion_type)`** — `opinion_type` đã tồn tại nhưng column DB CHƯA có. Chỉ trong function signature, INSERT bỏ qua.
- **SP `fn_opinion_get_list`** trả: `id, staff_id, staff_name, content, attachment_path, created_at`.
- **Endpoint**: `GET /:id/y-kien`, `POST /:id/y-kien` (handling-doc.ts:256-289).
- **Frontend tab "Ý kiến xử lý"** (line 1360+) render linear list với avatar + name + time + content.

### What's Missing

1. **Mở rộng `opinion_handling_docs`**: thêm `forwarded_to_staff_id INT`, `forwarded_at TIMESTAMPTZ`, `forward_note TEXT`, `parent_opinion_id BIGINT` (để thread).
2. **SP mới** `fn_opinion_forward(p_opinion_id, p_from_staff_id, p_to_staff_id, p_note)` — tạo bản ghi mới liên kết parent.
3. **Endpoint mới**: `POST /api/ho-so-cong-viec/:id/y-kien/:opinionId/chuyen-tiep`.
4. **Mở rộng `fn_opinion_get_list`** trả thêm `forwarded_to_staff_id, forwarded_to_name, forward_note, parent_opinion_id` + tree render.
5. **Frontend**: thêm nút "Chuyển tiếp" trên mỗi opinion item; Modal chọn staff + note; render thread indent khi `parent_opinion_id != null`.

### Implementation Plan

| Step | File                                                            | Action                                                                                                                                 |
| ---- | --------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| E.1  | `database/migrations/quick_260418_jsd_opinion_forward.sql`      | `ALTER TABLE edoc.opinion_handling_docs ADD COLUMN forwarded_to_staff_id INT, forwarded_at TIMESTAMPTZ, forward_note TEXT, parent_opinion_id BIGINT REFERENCES edoc.opinion_handling_docs(id)`; CREATE `fn_opinion_forward`; DROP/CREATE `fn_opinion_get_list` |
| E.2  | `backend/src/repositories/handling-doc.repository.ts`           | Method `forwardOpinion(opinionId, fromStaffId, toStaffId, note)`; update `OpinionRow` interface                                        |
| E.3  | `backend/src/routes/handling-doc.ts`                            | `POST /:id/y-kien/:opinionId/chuyen-tiep`                                                                                              |
| E.4  | `frontend/src/app/(main)/ho-so-cong-viec/[id]/page.tsx`         | Nút "Chuyển tiếp" trên opinion-item; Modal Select staff (từ `/quan-tri/don-vi/:deptId/nhan-vien` hoặc all-staff endpoint) + note; CSS indent cho child opinions |

### Pitfalls / Questions

- **Staff picker**: dùng endpoint nào? Có thể reuse pattern `handleDeptSelect` đã có (line 809) — user chọn đơn vị rồi chọn cán bộ. Hoặc đơn giản hóa: Select flat list toàn unit.
- **Thread UI**: nếu `parent_opinion_id IS NOT NULL` → indent 24px + icon "↪"; giữ flat list nếu không muốn phức tạp.
- **FK cascade**: `parent_opinion_id REFERENCES opinion_handling_docs(id)` — on delete SET NULL (không CASCADE để giữ forward history).
- **Mở rộng `fn_opinion_get_list`**: DROP trước vì RETURNS TABLE đổi (bài học từ `hlj`).

**Estimated complexity:** Medium (schema + SP + UI Modal + thread rendering)

---

## Gap F — TC-068: Chuyển tiếp HSCV (transfer ownership)

### Current State

- **`handling_docs.curator INT REFERENCES public.staff(id)`** là cột ownership duy nhất (line 758 schema).
- **Không có history table** cho HSCV (không tìm thấy `handling_doc_history` hay tương tự).
- **Không có endpoint transfer** — chỉ có `PATCH /trang-thai` (status transitions) và `POST /phan-cong` (multi-staff assignment).
- **Frontend**: curator hiển thị ở line 1134 `{detail.curator_name || '—'}` read-only; edit qua Drawer "Sửa HSCV" (line 1690).
- **Notification pattern**: `notificationRepository.createLog` tồn tại (notification.ts:153) — có thể gọi khi transfer.

### What's Missing

1. **Schema mới**: `handling_doc_history` table log ownership transfers:
   ```sql
   CREATE TABLE edoc.handling_doc_history (
     id BIGSERIAL PRIMARY KEY,
     handling_doc_id BIGINT REFERENCES edoc.handling_docs(id) ON DELETE CASCADE,
     action VARCHAR(50) NOT NULL, -- 'transfer','cancel','reopen',...
     from_staff_id INT REFERENCES public.staff(id),
     to_staff_id INT REFERENCES public.staff(id),
     note TEXT,
     created_by INT REFERENCES public.staff(id),
     created_at TIMESTAMPTZ DEFAULT NOW()
   );
   ```
2. **SP mới**: `edoc.fn_handling_doc_transfer(p_id BIGINT, p_from_staff_id INT, p_to_staff_id INT, p_note TEXT, p_by INT)` — update `curator`, insert history.
3. **Endpoint mới**: `POST /api/ho-so-cong-viec/:id/chuyen-tiep`.
4. **Frontend**: nút "Chuyển tiếp HSCV" trên toolbar (conditional — khi user là curator hiện tại hoặc admin); Modal chọn staff mới + note.
5. **(Optional, có thể defer)** Notification: gửi notify cho `to_staff_id` khi transfer. Reuse pattern từ `notificationRepository.createLog`.

### Implementation Plan

| Step | File                                                                     | Action                                                                                                                          |
| ---- | ------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------- |
| F.1  | `database/migrations/quick_260418_jsd_hscv_transfer.sql`                 | `CREATE TABLE edoc.handling_doc_history`; CREATE SP `fn_handling_doc_transfer`; CREATE SP `fn_handling_doc_get_history` (list) |
| F.2  | `backend/src/repositories/handling-doc.repository.ts`                    | Methods `transfer(id, fromStaffId, toStaffId, note, byStaffId)`, `getHistory(id)`                                               |
| F.3  | `backend/src/routes/handling-doc.ts`                                     | `POST /:id/chuyen-tiep`, `GET /:id/lich-su`                                                                                     |
| F.4  | `frontend/src/app/(main)/ho-so-cong-viec/[id]/page.tsx`                  | Button "Chuyển tiếp HSCV" trên toolbar (case 1,3 — khi đang xử lý); Modal Select staff + TextArea note; tab "Lịch sử" (extend existing "Xem lịch sử") |

### Pitfalls / Questions

- **Staff picker scope**: cùng department? Cùng unit? Toàn hệ thống? **Khuyến nghị: cùng unit_id** (multi-tenancy), tái sử dụng pattern tree dept + staff list như panel phân công.
- **Permission**: chỉ curator hiện tại hoặc admin được transfer. FE check: `user.staffId === detail.curator_id || isAdmin`.
- **BIGSERIAL**: `handling_docs.id` là BIGSERIAL → SP param `p_id BIGINT` (bài học từ `hlj`).
- **Lịch sử xem**: hiện FE nút "Xem lịch sử" (case 4 toolbar line 252) chỉ `message.info('Tính năng xem lịch sử đang phát triển')` — đây là cơ hội implement luôn → dùng `fn_handling_doc_get_history`.
- **Notification**: nếu có thời gian, gọi `notificationRepository.createLog` với `event_type='hscv_transferred'` cho `to_staff_id`. KHÔNG bắt buộc vì notification system còn stub (worker chưa process).
- **Update status?**: transfer KHÔNG đổi `status`. Chỉ đổi `curator` + log history + clear relevant `staff_handling_docs` records (optional — có thể để curator cũ vẫn phối hợp).

**Estimated complexity:** Medium (schema + 2 SPs + route + UI + history tab)

---

## Don't Hand-Roll

| Problem                      | Don't Build                         | Use Instead                                                          | Why                                              |
| ---------------------------- | ----------------------------------- | -------------------------------------------------------------------- | ------------------------------------------------ |
| OTP 6-digit input            | Custom `<Input maxLength={6}>`     | AntD `<Input.OTP length={6} />`                                      | Built-in focus management, paste support (AntD 5.13+) |
| Vietnamese error mapping     | Custom try/catch per route          | `handleDbError` in `lib/error-handler.ts`                            | Consistent error codes (23505, 23503, 23502...)  |
| MinIO presigned URL          | Raw AWS SDK                         | `getFileUrl(path, 3600)` in `lib/minio/client.ts`                    | Wrapper đã handle bucket + expiry                |
| Attachment signing logic     | Raw UPDATE                          | `edoc.fn_attachment_mock_sign(...)`                                  | Đã exist, 3 attachment types handled             |
| Staff picker tree            | Custom dept tree                    | Reuse `transfer-panel` pattern + `/quan-tri/don-vi/:id/nhan-vien`    | Đã có trong HSCV detail                          |

## Common Pitfalls (theo CLAUDE.md + bài học hlj)

### 1. BIGSERIAL → BIGINT param
`handling_docs.id`, `opinion_handling_docs.id`, `lgsp_tracking.id` đều BIGSERIAL. SP param PHẢI `p_id BIGINT`. `staff.id` là SERIAL → INT OK.

### 2. DROP/CREATE khi RETURNS TABLE thay đổi
Gap D mở rộng `fn_handling_doc_get_by_id` (thêm 3 field cancel_*). Gap E mở rộng `fn_opinion_get_list` (thêm 4 field forward_*). **PHẢI DROP trước**:
```sql
DROP FUNCTION IF EXISTS edoc.fn_handling_doc_get_by_id(BIGINT);
CREATE OR REPLACE FUNCTION ... (*.full signature*)
```

### 3. Column ambiguity in SP
Gap D SP `fn_handling_doc_cancel` nếu SELECT INTO từ bảng có cột `"number"`, `"status"` → alias bảng (`h.`). Bài học từ `hlj`.

### 4. Reserved words
Không đụng trong 6 gap (cột mới: `cancel_reason`, `cancelled_at`, `forward_note`, `parent_opinion_id` — OK). Nhưng trong RETURNS TABLE vẫn check.

### 5. Frontend field names (copy từ SP output)
SP `fn_opinion_get_list` sau mở rộng trả `forwarded_to_staff_id` → FE PHẢI dùng tên này, KHÔNG rename thành `forwardedTo` hay `forward_target`.

### 6. Next.js 16 specificity
Project dùng Next.js 16.2.3 (xem `frontend/AGENTS.md`): "This is NOT the Next.js you know". Khi Edit page files PHẢI đọc file source trực tiếp thay vì dùng training knowledge. Có thể có API changes (App Router patterns, `useParams`, `useRouter`).

### 7. AntD 6 Drawer
`size={640}` không `width={640}` (đã enforce trong CLAUDE.md).

## Runtime State Inventory

| Category                   | Items Found                                                                           | Action Required                                                    |
| -------------------------- | ------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| Stored data                | `attachment_outgoing_docs.is_ca`, `attachment_drafting_docs.is_ca` đã có (mock sign)  | Không action — FE chỉ gọi mock endpoint                           |
| Live service config        | `lgsp_organizations` có một số org được seed                                          | Gap B: hardcode FE-side cho CP (không cần seed DB)                 |
| OS-registered state        | None                                                                                  | —                                                                  |
| Secrets/env vars           | None — toàn bộ mock                                                                   | —                                                                  |
| Build artifacts            | None                                                                                  | —                                                                  |

Không có migration data cho 6 gap này (tất cả mới 100%).

## Environment Availability

Không có external tool/service mới. Dependencies hiện tại đủ:
- PostgreSQL 16 (docker-compose)
- Express 5 + Next.js 16 dev servers
- MinIO (nếu đã chạy, chỉ dùng cho signed_file_path — mock sử dụng `= file_path`)

## Validation Architecture

Dự án **không có test framework** (package.json không có jest/vitest). Verification thủ công:

### Per-gap manual smoke test (trước commit)

**Gap A:**
- `docker exec postgres psql -d qlvb -c "SELECT * FROM edoc.fn_attachment_mock_sign(1, 'outgoing', 1);"` → success=true.
- FE: upload file VB đi → nhấn "Ký số" → nhập 6 digit bất kỳ → tag "Đã ký" hiện.

**Gap B:**
- `docker exec ... psql -c "SELECT * FROM edoc.fn_lgsp_tracking_create(1, NULL, 'send', 'CP.VPCP', 'Văn phòng Chính phủ', NULL, 1);"` → success nếu đã ALTER TABLE.
- Sau alter: check `\d+ edoc.lgsp_tracking` có cột `channel`.

**Gap C:**
- FE VB đi detail: nhấn "Chuyển lưu trữ" → Drawer mở → chọn kho+phông → Save → Tag "Đã lưu trữ" hiện.
- DB: `SELECT * FROM esto.document_archives WHERE doc_type='outgoing' AND doc_id=X;`.

**Gap D:**
- `docker exec ... psql -c "SELECT * FROM edoc.fn_handling_doc_cancel(5, 1, 'Lý do test');"` → success, status=-3.
- `SELECT cancel_reason, cancelled_at FROM edoc.handling_docs WHERE id=5;` → có giá trị.

**Gap E:**
- DB: `SELECT * FROM edoc.fn_opinion_forward(1, 1, 2, 'Chuyển để xử lý');` → success, row mới với `parent_opinion_id=1`.
- FE: tab Ý kiến → nhấn "Chuyển tiếp" → chọn staff + note → Save → opinion mới hiện indent.

**Gap F:**
- DB: `SELECT * FROM edoc.fn_handling_doc_transfer(5, 1, 2, 'Chuyển giao', 1);` → success.
- `SELECT curator FROM edoc.handling_docs WHERE id=5;` → = 2.
- `SELECT * FROM edoc.handling_doc_history WHERE handling_doc_id=5 ORDER BY created_at DESC LIMIT 1;` → row mới `action='transfer'`.

### Phase gate
- `npm run type-check` (BE + FE) — cho phép errors pre-existing, KHÔNG thêm lỗi mới (bài học từ `hlj`).
- Manual browser UAT cho từng gap.

## Assumptions Log

| #  | Claim                                                                                                              | Section | Risk if Wrong                                                  |
| -- | ------------------------------------------------------------------------------------------------------------------ | ------- | -------------------------------------------------------------- |
| A1 | Mock OTP FE-only (không gọi BE verify cho 6 digits)                                                                | Gap A   | Nếu HDSD yêu cầu BE validate format → thêm check ở BE dễ       |
| A2 | `<Input.OTP>` render OK trong AntD 6.3.5                                                                           | Gap A   | Fallback `<Input maxLength={6}>` nếu không render              |
| A3 | Hardcode FE-side danh sách bộ/ngành CP (không cần seed DB)                                                         | Gap B   | Nếu cần động → thêm `parent_code='CP'` vào `lgsp_organizations`|
| A4 | VB đến có endpoint load warehouses/fonds dropdown — VB đi copy dùng được                                           | Gap C   | Nếu endpoint khác → điều chỉnh URL                             |
| A5 | Status `-3` cho "đã hủy" không bị SP khác check/block                                                              | Gap D   | Nếu có SP check `status IN (0,1,2,3,4,-1,-2)` → lỗi constraint |
| A6 | Button "Hủy HSCV" chỉ hiện ở case -1/-2 (giữ nguyên hiện tại)                                                      | Gap D   | Nếu user muốn hủy ở status khác → extend `getToolbarButtons`    |
| A7 | Forward opinion dùng thread bằng `parent_opinion_id` (flat DB, tree render FE-side)                                 | Gap E   | Nếu business cần N-level chain → OK vì self-FK hỗ trợ          |
| A8 | Transfer HSCV chỉ đổi `curator`, không đổi `staff_handling_docs`                                                   | Gap F   | Nếu phải re-assign tất cả staff → complex hơn                  |
| A9 | Transfer trong scope cùng `unit_id` (multi-tenancy)                                                                | Gap F   | Nếu cross-unit allowed → bỏ filter                             |

## Open Questions

1. **Hủy HSCV — status nào được phép?** Hiện UI chỉ cho case -1/-2. Nếu user nghiệp vụ muốn hủy ngay status 0 (Mới) hoặc 1 (Đang xử lý) → mở rộng `getToolbarButtons`.
   - Recommendation: **giữ nguyên case -1/-2** cho quick task (minimize scope); note deferred.
2. **Chuyển tiếp ý kiến — N-level chain?** Có thể forward → forward → forward.
   - Recommendation: **OK** (DB self-FK hỗ trợ); UI chỉ render 1 level indent (không recursive).
3. **Transfer HSCV — cross-unit?** Chuyển HSCV sang đơn vị khác có hợp lệ?
   - Recommendation: **giới hạn cùng unit** (an toàn, đúng multi-tenancy); user có thể hỏi thêm.
4. **Mock OTP — phone nào?** Có thể lấy từ `staff.sign_phone` để hiển thị trong Modal ("đã gửi OTP đến 84xxx").
   - Recommendation: đọc `user.sign_phone` từ auth store nếu có, hiển thị masked.

## Sources

### Primary (HIGH confidence — codebase grep + read)
- `backend/src/routes/digital-signature.ts` — mock/sign, mock/verify endpoints (line 145-177)
- `backend/src/routes/outgoing-doc.ts:708` — LGSP gui-lien-thong pattern
- `backend/src/routes/handling-doc.ts:463` — trang-thai handler
- `database/migrations/000_full_schema.sql:737` — handling_docs table
- `database/migrations/000_full_schema.sql:16436` — document_archives + fn_document_archive_create
- `database/migrations/000_full_schema.sql:13790` — lgsp_tracking table
- `database/migrations/000_full_schema.sql:16697` — fn_attachment_mock_sign
- `frontend/src/app/(main)/van-ban-den/[id]/page.tsx:876-901` — archive Drawer pattern
- `frontend/src/app/(main)/ho-so-cong-viec/[id]/page.tsx:211-267` — toolbar button structure
- `.planning/quick/260418-hlj-.../260418-hlj-01-SUMMARY.md` — lesson learned table

### Secondary (MEDIUM — assumption from docs)
- AntD 6.3.5 kế thừa `<Input.OTP>` từ v5.13+ (documented in ant-design changelog)

## Metadata

**Confidence breakdown:**
- Gap A: HIGH — mock SP + endpoint đã deployed, chỉ UI glue
- Gap B: HIGH — pattern LGSP y hệt
- Gap C: HIGH — copy thẳng từ VB đến
- Gap D: MEDIUM — schema mới + SP mới, cần test carefully
- Gap E: MEDIUM — schema mở rộng + UI thread cần tính toán
- Gap F: MEDIUM — 2 SPs + history table mới

**Research date:** 2026-04-18
**Valid until:** 2026-04-25 (ngắn hạn — demo cuối tuần)

## Project Constraints (from CLAUDE.md)

- **KHÔNG tự commit** — chỉ commit khi user yêu cầu rõ ràng.
- **Tech stack fixed**: Next.js 16 + Express 5 + PostgreSQL 16 + Stored Procedures (no ORM).
- **Business logic đối chiếu source cũ .NET** trước khi implement — task này là HDSD-driven, ít cần đọc .NET (6 gap đều là mock hoặc extend pattern đã có).
- **AntD 6 migration**: `size` thay `width` cho Drawer; `<Input.OTP>` chuẩn; không dùng `<List>` deprecated.
- **Tiếng Việt có dấu** cho toàn bộ UI text + API error messages.
- **Sequential execution** cho 6 gap — KHÔNG parallel (bài học Phase 5).
- **Per-wave integration check** — sau mỗi gap, chạy type-check + manual smoke test trước khi sang gap tiếp theo.
- **DROP/CREATE** khi RETURNS TABLE signature đổi — không dùng CREATE OR REPLACE.
- **BIGSERIAL tables → BIGINT param** cho SP (`handling_docs.id`, `opinion_handling_docs.id`, `lgsp_tracking.id`).
- **All SP names prefixed `{schema}.fn_{module}_{action}`** (snake_case).
- **Quote reserved words** trong RETURNS TABLE (`"number"`, `"status"`, `"order"`, ...).
- **Max length trên Input** khớp VARCHAR(N) của DB (bài học CLAUDE.md rule 9).
- **Required validation** cho NOT NULL columns (rule 10).
- **setBackendFieldError** cho unique constraint (rule 13).
