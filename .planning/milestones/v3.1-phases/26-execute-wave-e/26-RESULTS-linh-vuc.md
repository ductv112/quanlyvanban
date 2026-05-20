# Wave E — DMLN (Quản lý Lĩnh vực) Test Results

**Date**: 2026-05-07
**Tester**: Claude Code AI
**Module**: Quản lý lĩnh vực (`/quan-tri/linh-vuc`)
**Backend**: `e_office_app_new/backend/src/routes/admin-catalog.ts` (lines 332-451) + repository `doc-field.repository.ts` + SP `edoc.fn_doc_field_*`
**Frontend**: `e_office_app_new/frontend/src/app/(main)/quan-tri/linh-vuc/page.tsx`
**Login**: `admin / Admin@123` (unitId=1)

## Summary

| Result | Count | TC IDs |
|---|---|---|
| PASS | 11 | 005, 006, 007, 008, 009, 010, 011, 012*, 014, 015, 004 |
| FAIL | 4 | 001, 002, 003, 013* (admin-side) |
| TOTAL | 15 | |

(*) TC-012 backend PASS but frontend has issue due to BUG-DMLN-001.
(*) TC-013 PASS for non-admin dropdown (public route correct), but admin-side data flow is broken.

**Pass rate**: 11/15 = 73%

## Critical bugs (3)

### BUG-DMLN-001 — Admin GET `/api/quan-tri/linh-vuc` shadowed by public-catalog route → returns only `{id, code, name}`, missing `unit_id, sort_order, is_active`

- **Severity**: HIGH
- **Files**:
  - `backend/src/server.ts` line 72: `app.use('/api/quan-tri', authenticate, publicCatalogRoutes)` mounted **before** `adminCatalogRoutes` (line 74)
  - `backend/src/routes/public-catalog.ts` lines 102-114: defines `GET /linh-vuc` returning only `id, code, name` filtered by `is_active=true` and `ORDER BY sort_order, name`
  - `backend/src/routes/admin-catalog.ts` lines 332-344: defines proper admin `GET /linh-vuc` returning all fields — **never reached** because Express matches first registered route
- **Repro**: `curl /api/quan-tri/linh-vuc?unit_id=1` returns `[{id, code, name}]` only — `sort_order`, `is_active`, `unit_id` stripped
- **Impact on UI**:
  - Bảng admin: cột "Thứ tự" hiển thị `undefined`, cột "Trạng thái" luôn render Tag dựa trên `undefined` (= falsy → "Ngừng" đỏ cho TẤT CẢ records, kể cả active)
  - Edit drawer: `form.setFieldsValue(record)` không có `is_active`/`sort_order` → Switch trạng thái luôn off, InputNumber thứ tự luôn 0
  - Delete sau Edit có thể ghi `is_active=false` (mặc định Switch off) → vô tình deactivate field đang active
- **Suggested fix**: Trong `public-catalog.ts` đổi route từ `/linh-vuc` sang `/linh-vuc-public` HOẶC reorder — mount `adminCatalogRoutes` trước `publicCatalogRoutes`. Pattern "longer-prefix-wins" comment ở server.ts không đúng — Express dùng "first-registered-wins".

### BUG-DMLN-002 — Search keyword query param ignored

- **Severity**: HIGH
- **Cause**: hệ quả của BUG-DMLN-001. Public route `public-catalog.ts:103` hard-code `WHERE COALESCE(is_active, true) = true` không đọc `req.query.keyword`
- **Repro**: `curl /api/quan-tri/linh-vuc?unit_id=1&keyword=Hanh` trả về toàn bộ 5 active records, không filter
- **Impact**: TC-DMLN-003 fails — user gõ "Khoa" + Enter → bảng không lọc
- **Fix**: Same as BUG-DMLN-001

### BUG-DMLN-003 — Admin không thể xem/sửa/xóa lĩnh vực đang ở trạng thái "Ngừng"

- **Severity**: HIGH
- **Cause**: hệ quả của BUG-DMLN-001. Public route filter `WHERE is_active=true` ẩn record inactive khỏi bảng admin
- **Repro**:
  1. Tạo lĩnh vực KHCN (id=21)
  2. PUT `/quan-tri/linh-vuc/21` với `is_active=false`
  3. GET `/quan-tri/linh-vuc?unit_id=1` → KHCN biến mất khỏi list
  4. Admin không có cách nào (ngoài DB) để re-activate
- **Fix**: Same as BUG-DMLN-001. Admin route must NOT filter by `is_active`.

## Detailed results

| TC | Title | Category | Pri | Result | Notes |
|---|---|---|---|---|---|
| 001 | Hiển thị danh sách lĩnh vực của đơn vị | UI | High | **FAIL** | API trả thiếu cột → Trạng thái + Thứ tự render undefined → BUG-DMLN-001 |
| 002 | Trạng thái Hoạt động/Ngừng màu khác nhau | UI | Medium | **FAIL** | Do BUG-DMLN-001, `is_active=undefined` → mọi record render Tag đỏ "Ngừng" |
| 003 | Tìm kiếm theo từ khóa khi nhấn Enter | Positive | High | **FAIL** | BUG-DMLN-002 — keyword param bị bỏ qua, bảng không lọc |
| 004 | Click kính lúp không trigger search | UI | Low | PASS | `Input.Search` không có `enterButton`, prefix `SearchOutlined` chỉ trang trí. Code review confirmed |
| 005 | Thêm lĩnh vực mới với dữ liệu hợp lệ | Positive | High | PASS | POST returned `{success:true, data:{id:21}}`, default is_active=true |
| 006 | Drawer Thêm KHÔNG có trường Trạng thái | UI | Medium | PASS | Code page.tsx line 282-286: `{editingRecord && <Form.Item label="Trạng thái" ...>}` — chỉ render khi sửa |
| 007 | Bỏ trống Mã khi Thêm | Negative | High | PASS | API trả `Mã lĩnh vực là bắt buộc`, frontend map → inline error trên field `code` (line 80) |
| 008 | Bỏ trống Tên khi Thêm | Negative | High | PASS | API trả `Tên lĩnh vực là bắt buộc`, frontend map → inline error trên field `name` (line 84) |
| 009 | Mã vượt 20 ký tự | Boundary | Medium | PASS | API trả `Mã lĩnh vực không được vượt quá 20 ký tự` — frontend cũng có maxLength={20} |
| 010 | Tên vượt 200 ký tự | Boundary | Medium | PASS | API trả `Tên lĩnh vực không được vượt quá 200 ký tự` — frontend cũng có maxLength={200} |
| 011 | Trùng Mã trong cùng đơn vị | Negative | High | PASS | API trả `Mã lĩnh vực đã tồn tại trong đơn vị`, mapped to `code` field error |
| 012 | Sửa - bật/tắt trạng thái | Positive | High | PASS (backend) / partial fail (UI) | PUT `is_active=false` lưu DB OK. NHƯNG: do BUG-DMLN-001, list không reload đúng → record biến mất khỏi UI sau khi save |
| 013 | Lĩnh vực Ngừng không xuất hiện ở dropdown form Tạo VB | Positive | Medium | PASS | Public route filter `is_active=true` đúng cho dropdown — đây CHÍNH LÀ nguyên nhân BUG-DMLN-003 (admin nhìn nhầm route này) |
| 014 | Xóa lĩnh vực không tham chiếu | Positive | High | PASS | DELETE id=21 → `Xoa linh vuc thanh cong` |
| 015 | Xóa lĩnh vực đang được tham chiếu | Negative | High | PASS | DELETE id=1 (HC) → `Không thể thực hiện: dữ liệu đang được tham chiếu` (FK 23503 → message tiếng Việt thân thiện) |

## API endpoint inventory verified

| Method | Path | Purpose | Status |
|---|---|---|---|
| GET | `/api/quan-tri/linh-vuc` | List | shadowed (BUG-DMLN-001) |
| GET | `/api/quan-tri/linh-vuc/:id` | Detail | OK (no shadow) |
| POST | `/api/quan-tri/linh-vuc` | Create | OK |
| PUT | `/api/quan-tri/linh-vuc/:id` | Update | OK |
| DELETE | `/api/quan-tri/linh-vuc/:id` | Delete | OK |

## SP inventory

- `edoc.fn_doc_field_get_list(unit_id, keyword, dept_id)` — returns full row including `sort_order, is_active, created_at`. **Working correctly**, but unreached due to route shadow.
- `edoc.fn_doc_field_get_by_id`, `_create`, `_update`, `_delete` — all working as expected.

## Recommendations (priority order)

1. **Fix BUG-DMLN-001 immediately** — single change in `server.ts` (reorder mounts) OR `public-catalog.ts` (rename route to `/linh-vuc-public`). Resolves BUG-002 and BUG-003 simultaneously.
2. After fix, re-run TC-001/002/003/012/013 — all expected to PASS.
3. Add a regression test: `GET /api/quan-tri/linh-vuc` response includes `is_active` and `sort_order` keys.
4. Consider adding admin-only filter param `?include_inactive=true` if business wants to support both views from same endpoint.
