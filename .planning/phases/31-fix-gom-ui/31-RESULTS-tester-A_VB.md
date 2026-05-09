# Tester Bug Fixes — Module Văn bản (A_VB)

**Scope:** 26 bugs trong `tools/test-report/_tester-bugs-A_VB.json` covering Văn bản dự thảo + Văn bản đến + Văn bản đi.

**Date:** 2026-05-09
**Branch:** main
**Stack:** Backend (port 4000) + Frontend (Next.js 16, port 3000) — KHÔNG sửa SP/schema, chỉ FE + BE route handlers.

## Tóm tắt

- **Tổng số bug:** 26
- **Đã fix:** 26 (100%)
- **Skip:** 0
- **High priority:** 5/5 fixed (BUG #9, #10, #36, #37, #40)
- **Critical:** 1/1 fixed (BUG #41)

## Commit history

| Commit | Bugs |
|---|---|
| `a223622` | #9, #10, #36, #37, #61, #1, #56 (BE Excel filter ids + form-confirm helper + CSS dropdown align) |
| `8595713` | #3, #4, #5, #6, #8, #9, #10, #11, #24 (VB dự thảo) |
| `240d7c8` | #28, #33, #34, #35, #36, #37, #40, #41 (VB đến + nhận bản giấy BE relax) |
| `e49bfe5` | #55, #57, #58, #59, #60, #61, #62 (VB đi) |

## Bug-by-bug status

| Bug # | Priority | Module | Status | Files modified | Commit |
|---|---|---|---|---|---|
| 1 | Low | Dropdown phòng ban căn lề | FIXED | `frontend/src/app/globals.css` | a223622 |
| 3 | Low | VB dự thảo - Thêm mới: ô Số không có placeholder | FIXED | `(main)/van-ban-du-thao/page.tsx` | 8595713 |
| 4 | Medium | VB dự thảo - Sổ văn bản dropdown thiếu icon X | FIXED | `(main)/van-ban-du-thao/page.tsx` | 8595713 |
| 5 | Medium | VB dự thảo - Hạn xử lý < ngày ký/ban hành không báo lỗi | FIXED | `(main)/van-ban-du-thao/page.tsx` | 8595713 |
| 6 | Medium | VB dự thảo - Reset filter không clear ô search | FIXED | `(main)/van-ban-du-thao/page.tsx` | 8595713 |
| 8 | Medium | VB dự thảo - Thêm mới: click Hủy không có dialog xác nhận | FIXED | `(main)/van-ban-du-thao/page.tsx` + `lib/form-confirm.ts` | 8595713 |
| 9 | High | VB dự thảo - Excel xuất toàn bộ thay vì items đã chọn | FIXED | BE `routes/drafting-doc.ts` + FE `(main)/van-ban-du-thao/page.tsx` | a223622+8595713 |
| 10 | High | VB dự thảo - Excel cross-page selection | FIXED | Same as #9 (giải pháp chung qua `ids`) | a223622+8595713 |
| 11 | Medium | VB dự thảo - Sửa: click Hủy không có dialog xác nhận | FIXED | `(main)/van-ban-du-thao/page.tsx` | 8595713 |
| 24 | Medium | VB dự thảo - Sửa thông tin: click Hủy không có dialog | FIXED | Same as #11 (cùng handler) | 8595713 |
| 28 | Medium | VB đến - Thêm mới: bản giấy không có placeholder | FIXED | `(main)/van-ban-den/page.tsx` | 240d7c8 |
| 33 | Medium | VB đến - Reset filter không clear ô search | FIXED | `(main)/van-ban-den/page.tsx` | 240d7c8 |
| 34 | Medium | VB đến - Thêm mới: click Hủy không có dialog | FIXED | `(main)/van-ban-den/page.tsx` | 240d7c8 |
| 35 | Medium | VB đến - Số đến vẫn cho nhập (cần disable + auto-fill) | FIXED | `(main)/van-ban-den/page.tsx` (disabled + tooltip) | 240d7c8 |
| 36 | High | VB đến - Excel xuất toàn bộ thay vì items đã chọn | FIXED | BE `routes/incoming-doc.ts` + FE | a223622+240d7c8 |
| 37 | High | VB đến - Excel cross-page selection | FIXED | Same as #36 | a223622+240d7c8 |
| 40 | High | VB đến - Sửa: Nơi gửi + Số phụ không hiển thị giá trị đã nhập | FIXED | `(main)/van-ban-den/page.tsx` (fetch full detail trong openDrawer) | 240d7c8 |
| 41 | Critical | VB đến - Nhận bản giấy báo lỗi | FIXED | BE `routes/incoming-doc.ts` (relax permission: cho phép canEdit) + FE detail page | 240d7c8 |
| 55 | Medium | VB đi - Sửa: click Hủy không có dialog | FIXED | `(main)/van-ban-di/page.tsx` | e49bfe5 |
| 56 | Low | VB đi - Dropdown phòng ban căn lề | FIXED | Same as #1 (CSS chung) | a223622 |
| 57 | Low | VB đi - Thêm mới: Số đi không có placeholder | FIXED | `(main)/van-ban-di/page.tsx` | e49bfe5 |
| 58 | Medium | VB đi - Sổ văn bản dropdown thiếu icon X | FIXED | `(main)/van-ban-di/page.tsx` | e49bfe5 |
| 59 | Medium | VB đi - Reset filter không clear ô search | FIXED | `(main)/van-ban-di/page.tsx` | e49bfe5 |
| 60 | Medium | VB đi - Thêm mới: click Hủy không có dialog | FIXED | `(main)/van-ban-di/page.tsx` | e49bfe5 |
| 61 | Medium/High | VB đi - Excel xuất toàn bộ thay vì items đã chọn | FIXED | BE `routes/outgoing-doc.ts` + FE | a223622+e49bfe5 |
| 62 | Medium | VB đi - Sửa: click Hủy không có dialog | FIXED | Same as #55 | e49bfe5 |

## Pattern reuse — central code

### 1. `lib/form-confirm.ts` — confirmCloseIfDirty

Hàm chung dùng cho **7 bugs** (#8, #11, #24, #34, #55, #60, #62):
```ts
export function confirmCloseIfDirty(
  form: FormInstance,
  modal: ModalHookAPI,
  onConfirmClose: () => void,
  opts?: { title?: string; content?: string },
): void
```
- Check `form.isFieldsTouched()` → nếu true thì show `modal.confirm()` cảnh báo, nếu false thì close luôn.
- Áp dụng cho cả Drawer `onClose` và button "Hủy" trong drawer extra.

### 2. BE Excel `?ids=...` query param — 5 bugs (#9, #10, #36, #37, #61)

3 endpoint `/xuat-excel` (drafting/incoming/outgoing) cùng pattern:
```ts
const idList = ids ? String(ids).split(',').map(Number).filter(...) : null;
let rows = idList
  ? (await repo.getList(filters)).filter(r => idSet.has(Number(r.id)))
  : await repo.getList(filtersFromQuery);
```
- Permissions vẫn áp dụng (filter post-getList chứ không bypass repo).
- FE: nếu `selectedRowKeys.length > 0` → gửi `params.ids = selectedRowKeys.join(',')`, không gửi filter khác.

### 3. CSS `.ant-select-dropdown / .ant-select-tree-list ... text-align: left !important` — 2 bugs (#1, #56)

Buộc tất cả option items căn trái — phòng case parent CSS có `text-align: center`.

### 4. Controlled `Input.Search` — 3 bugs (#6, #33, #59)

Trước: chỉ `onSearch` → user gõ rồi nhấn Enter mới update keyword. Reset filter set `keyword=''` không reflect lên input.
Sau: thêm `value={keyword} onChange={(e) => setKeyword(e.target.value)}` → controlled → reset filter clear input ngay.

## Notable fixes — chi tiết

### BUG #40 — VB đến sửa: Nơi gửi + Số phụ không hiển thị

**Root cause:** SP `fn_incoming_doc_get_list` (list endpoint) **không** trả về `sub_number` và `sents`. SP `fn_incoming_doc_get_by_id` (detail endpoint) trả về đủ.

**Fix (FE):** trong `openDrawer(record)`, khi `record` có giá trị → fetch thêm `/van-ban-den/:id` để merge full detail vào form data. Fallback nếu fetch fail → dùng list record (degrade gracefully).

```tsx
let fullRecord: any = record;
try {
  const { data: detailRes } = await api.get(`/van-ban-den/${record.id}`);
  if (detailRes?.data) fullRecord = { ...record, ...detailRes.data };
} catch { /* fallback */ }
form.setFieldsValue({ ...fullRecord, sents: fullRecord.sents ? [fullRecord.sents] : [], ... });
```

### BUG #41 — VB đến nhận bản giấy báo lỗi

**Root cause:** BE route `/:id/nhan-ban-giay` chỉ cho phép `canApprove` (lãnh đạo). Nghiệp vụ đúng: **văn thư** (cùng đơn vị + `is_handle_document`) là người trực tiếp nhận bản giấy ở phòng văn thư, không phải lãnh đạo.

**Fix (BE):** relax check thành `canApprove || canEdit`. Đồng thời (FE) dropdown ở detail page cũng show button cho `canEdit` users.

```ts
if (!loaded.perms.canApprove && !loaded.perms.canEdit) {
  res.status(403).json({ success: false, message: 'Không có quyền xác nhận nhận bản giấy' });
  return;
}
```

### BUG #5 — VB dự thảo hạn xử lý validation

Form rule với `dependencies={['sign_date', 'publish_date']}` + custom validator:
- Hạn xử lý phải >= ngày ký
- Hạn xử lý phải >= ngày ban hành
- Hiển thị inline error trên Form.Item, không dùng `message.error()` trong handleSave.

### BUG #35 — Số đến disabled

Đổi `<InputNumber>` → `disabled` + tooltip "Hệ thống tự cấp số tiếp theo của sổ văn bản. Không nhập tay." Đã có sẵn API `/so-den-tiep-theo` (gọi qua `fetchNextNumber()` khi user chọn sổ văn bản). User KHÔNG còn nhập tay → tránh duplicate số.

## Verification

- **TS check FE:** PASS cho code tôi sửa. Có 5 errors PRE-EXISTING (không liên quan PR này): `flattenTreeForSelect` type signature mismatch + `Modal size` prop ở `ho-so-cong-viec/[id]/page.tsx` (đã có trước commit gần nhất, không do bug fix này).
- **TS check BE:** PASS (zero errors).
- **Frontend build:** PASS (production build complete with 36 routes).
- **BE Excel ids endpoint smoke test:** `GET /api/van-ban-den/xuat-excel?ids=1001,1002,1003` → 200 OK, 7387 bytes (3 rows). Pass.
- **BE health:** all services connected (postgres, redis, minio).

## Files modified

### Backend (3 files)
- `backend/src/routes/drafting-doc.ts` — Excel ids filter
- `backend/src/routes/incoming-doc.ts` — Excel ids filter + nhan-ban-giay relax permission
- `backend/src/routes/outgoing-doc.ts` — Excel ids filter

### Frontend (5 files)
- `frontend/src/lib/form-confirm.ts` — **NEW** — shared confirmCloseIfDirty helper
- `frontend/src/app/globals.css` — CSS for dropdown alignment
- `frontend/src/app/(main)/van-ban-du-thao/page.tsx` — 9 bug fixes
- `frontend/src/app/(main)/van-ban-den/page.tsx` — 8 bug fixes
- `frontend/src/app/(main)/van-ban-di/page.tsx` — 7 bug fixes
- `frontend/src/app/(main)/van-ban-den/[id]/page.tsx` — 1 line for BUG #41 (button visible cho canEdit) — file này có user changes pre-existing chưa staged, my single-line edit đã apply đúng vị trí.

## Note for tester

- BUG #1, #56 — nếu vẫn thấy lệch lề, nguyên nhân có thể là zoom level browser. CSS đã ép `text-align: left !important`.
- BUG #41 — sau fix này: cả văn thư (người tạo VB / cùng đơn vị handle_document) **và** lãnh đạo đều đánh dấu được nhận bản giấy. Trước: chỉ lãnh đạo.
- BUG #35 — Số đến giờ disabled, user phải chọn "Sổ văn bản" trước → số được auto-fill. Nếu user xóa sổ văn bản → số xóa luôn.
