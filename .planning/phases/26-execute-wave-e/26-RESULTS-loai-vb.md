# Wave E — Module DMLV (Loại văn bản) — Test Results

**Tester:** AI Agent  
**Date:** 2026-05-07  
**Module:** Quản lý loại văn bản (`/quan-tri/loai-van-ban`)  
**Endpoint base:** `/api/quan-tri/loai-van-ban`  
**Total TC:** 20 (TC-DMLV-001..020)  
**Login:** `admin / Admin@123`  
**DB target:** `qlvb_test`

---

## Summary

| Status | Count |
|---|---|
| **PASS** | 11 |
| **FAIL (BUG)** | 5 |
| **UI-only (skip API)** | 4 |
| **TOTAL** | 20 |

**Bugs filed:** 4 (1 CRITICAL, 1 HIGH, 2 MEDIUM)

---

## Test Results

| TC | Title | Category | Priority | Result | Notes |
|---|---|---|---|---|---|
| TC-DMLV-001 | Hiển thị 3 tab | UI | High | **SKIP-UI** | Tab UI render — không test qua API. (Frontend đã có 3 tab) |
| TC-DMLV-002 | Chuyển tab lọc theo type_id | UI | High | **FAIL** | API `/loai-van-ban/tree?type_id=N` luôn trả 8 records bất kể N=1/2/3. → **BUG-DMLV-001** |
| TC-DMLV-003 | Hiển thị đầy đủ các cột + expand cây | UI | Med | **FAIL** | API tree chỉ trả 4 fields `{id, parent_id, code, name}` — thiếu `notation_type`, `sort_order`. Cột "Ký hiệu" + "Thứ tự" trên UI sẽ luôn render placeholder. → **BUG-DMLV-002** |
| TC-DMLV-004 | Cột Ký hiệu render mapping enum | UI | Med | **FAIL** | Hậu quả của BUG-DMLV-002 — `notation_type` không được trả về nên cột Ký hiệu không bao giờ render đúng "Số/Ký hiệu" hay "Số-Ký hiệu". |
| TC-DMLV-005 | Thêm loại gốc với data hợp lệ | Pos | High | **PASS** | `POST` với `{type_id:1, parent_id:null, code:"TC005NQ", name:"Nghi quyet TC005", notation_type:1}` → `201 {success:true, id:21}` |
| TC-DMLV-006 | Thêm loại con có Loại cha | Pos | High | **PASS** | `POST` với `parent_id:21` → `201 {success:true, id:22}` |
| TC-DMLV-007 | Bỏ trống Mã | Neg | High | **PASS** | `400 {message:"Mã loại văn bản là bắt buộc"}` |
| TC-DMLV-008 | Bỏ trống Tên | Neg | High | **PASS** | `400 {message:"Tên loại văn bản là bắt buộc"}` |
| TC-DMLV-009 | Mã 21 ký tự (boundary +1) | Bnd | Med | **PASS** | `400 {message:"Mã loại văn bản không được vượt quá 20 ký tự"}` |
| TC-DMLV-010 | Tên 201 ký tự | Bnd | Med | **PASS** | `400 {message:"Tên loại văn bản không được vượt quá 200 ký tự"}` |
| TC-DMLV-011 | Trùng Mã loại văn bản | Neg | High | **PASS** | `400 {message:"Mã loại văn bản đã tồn tại"}` |
| TC-DMLV-012 | Sửa — chọn chính mình làm Loại cha | Neg | High | **PASS** | `400 {message:"Không thể chọn chính mình làm cha"}` (DB SP có check) |
| TC-DMLV-013 | Sửa thay đổi Kiểu ký hiệu | Pos | Med | **PASS** | `PUT /21 {notation_type:2}` → success. DB confirm `notation_type=2`. **NHƯNG**: hậu quả BUG-DMLV-002 → user không nhìn thấy giá trị mới trên grid. |
| TC-DMLV-014 | Search Loại cha trong dropdown | UI | Low | **SKIP-UI** | Frontend dropdown filter — Ant Design Select `optionFilterProp="label"`, không cần API |
| TC-DMLV-015 | Xóa loại không có con + không tham chiếu | Pos | High | **PASS** | `DELETE /22` → `200 {message:"Xoa loai van ban thanh cong"}`. Soft delete (set is_deleted=true). |
| TC-DMLV-016 | Xóa loại đang có loại con | Neg | High | **PASS** | `DELETE /21` (có child id=23) → `400 {message:"Không thể xóa: còn 1 loại văn bản con"}` |
| TC-DMLV-017 | Xóa loại đang được tham chiếu bởi VB | Neg | High | **FAIL** | **CRITICAL DATA BUG**: SP `fn_doc_type_delete` KHÔNG check FK reference từ `incoming_docs.doc_type_id` / `outgoing_docs.doc_type_id` / `drafting_docs.doc_type_id`. Soft-delete vẫn thực hiện → tạo orphan FK. → **BUG-DMLV-003** |
| TC-DMLV-018 | Boundary — Mã 20 ký tự | Bnd | Low | **PASS** | `POST` với code=`"CCCC...C"` (20 chars) → `201 {success:true, id:24}` |
| TC-DMLV-019 | Drawer tiêu đề khi Sửa (UI) + getById đầy đủ | UI | Low | **PASS** | `GET /24` trả full record với all 10 fields including `notation_type, sort_order, parent_id, type_id` — form Sửa fill được dữ liệu. (UI title text không test qua API.) |
| TC-DMLV-020 | Hủy Drawer Sửa không lưu | UI | Med | **SKIP-UI** | Frontend drawer close — không cần API |

---

## Bugs

### BUG-DMLV-001 — CRITICAL — API tree không filter theo `type_id` (3 tabs hỏng)

**TC ảnh hưởng:** TC-DMLV-002, TC-DMLV-001 (gián tiếp), TC-DMLV-003 (gián tiếp)  
**Severity:** Critical  
**Endpoint:** `GET /api/quan-tri/loai-van-ban/tree?type_id=N`

**Mô tả:** API trả về toàn bộ 8 loại văn bản bất kể `type_id=1/2/3`. Cả 3 tab (VB đến / VB đi / VB dự thảo) đều hiển thị y hệt nhau → user không thể phân loại loại văn bản theo nhóm.

**Root cause:** `server.ts` line 72 mount `publicCatalogRoutes` TRƯỚC `adminCatalogRoutes` cho cùng prefix `/api/quan-tri`. Express Router dùng first-match → request hit handler trong `routes/public-catalog.ts` line 89-100 thay vì `routes/admin-catalog.ts` line 202-211.

```typescript
// server.ts (BUG):
app.use('/api/quan-tri', authenticate, publicCatalogRoutes);  // line 72 — wins
app.use('/api/quan-tri', authenticate, requireRoles('Quản trị hệ thống'), adminCatalogRoutes);  // line 74 — never reached for /loai-van-ban/tree
```

`public-catalog.ts` `GET /loai-van-ban/tree` dùng raw query không filter `type_id`:
```typescript
SELECT id, parent_id, code, name FROM edoc.doc_types
WHERE COALESCE(is_deleted, false) = false
ORDER BY sort_order NULLS LAST, name
```

**Steps to reproduce:**
```bash
curl -H "Authorization: Bearer $TOKEN" "http://localhost:4000/api/quan-tri/loai-van-ban/tree?type_id=1"
# Expected: chỉ records có type_id=1
# Actual: trả tất cả 8 records (cả type_id=1, 2, 3)
```

**Fix đề xuất:**
1. Loại bỏ `GET /loai-van-ban/tree` khỏi `public-catalog.ts` (route admin có rồi)
2. **Hoặc** chuyển logic admin (filter type_id + buildTree) lên public-catalog
3. **Hoặc** rename route admin thành `/loai-van-ban/admin-tree` để tránh collision

**Files:**
- `e_office_app_new/backend/src/routes/public-catalog.ts:88-100` (route gây xung đột)
- `e_office_app_new/backend/src/server.ts:72-74` (thứ tự mount)
- `e_office_app_new/backend/src/routes/admin-catalog.ts:201-211` (route đúng — bị shadow)

---

### BUG-DMLV-002 — CRITICAL — API tree thiếu fields `notation_type`, `sort_order`, `is_default`

**TC ảnh hưởng:** TC-DMLV-003, TC-DMLV-004, TC-DMLV-013 (gián tiếp — update OK nhưng không hiển thị)  
**Severity:** Critical  
**Endpoint:** `GET /api/quan-tri/loai-van-ban/tree`

**Mô tả:** Response chỉ trả 4 fields `{id, parent_id, code, name}`. Frontend grid render cột "Ký hiệu" và "Thứ tự" → cell luôn empty (placeholder `—`) vì `record.notation_type` và `record.sort_order` đều là `undefined`.

**Root cause:** Cùng nguồn gốc với BUG-DMLV-001 — route bị shadow bởi `public-catalog.ts` (chỉ SELECT 4 cột).

**Hệ quả nghiệp vụ:** TC-DMLV-013 — admin update `notation_type` từ 1 → 2 thành công ở DB nhưng UI grid không bao giờ hiển thị giá trị mới. User tưởng update không có hiệu lực → nhập lại nhiều lần → spam DB.

**Fix:** Cùng fix với BUG-DMLV-001.

---

### BUG-DMLV-003 — CRITICAL — Soft delete loại văn bản KHÔNG check FK reference

**TC ảnh hưởng:** TC-DMLV-017  
**Severity:** Critical (data integrity)  
**Endpoint:** `DELETE /api/quan-tri/loai-van-ban/:id`  
**SP:** `edoc.fn_doc_type_delete(p_id integer)`

**Mô tả:** SP chỉ check children (`parent_id = p_id`), KHÔNG check FK references trong `edoc.incoming_docs.doc_type_id`, `edoc.outgoing_docs.doc_type_id`, `edoc.drafting_docs.doc_type_id`. Cho phép xóa (soft) loại văn bản đang được dùng → tạo orphan FK → văn bản đến/đi/dự thảo không còn tham chiếu loại hợp lệ.

**Steps to reproduce:**
```bash
# 1. Tạo loại VB mới (id=23)
# 2. Cập nhật incoming_doc 90001: doc_type_id=23
docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_test -c "UPDATE edoc.incoming_docs SET doc_type_id=23 WHERE id=90001;"

# 3. Xóa loại 23 → ĐÁNG LẼ phải báo lỗi FK
curl -X DELETE -H "Authorization: Bearer $TOKEN" "http://localhost:4000/api/quan-tri/loai-van-ban/23"
# Actual: {"success":true,"data":{"message":"Xoa loai van ban thanh cong"}}

# 4. Verify orphan
docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_test -c "
SELECT i.id, i.doc_type_id, dt.code, dt.is_deleted
FROM edoc.incoming_docs i
LEFT JOIN edoc.doc_types dt ON dt.id = i.doc_type_id
WHERE i.id = 90001;
"
# Result:
#   id   | doc_type_id |    code    | is_deleted
# -------+-------------+------------+------------
#  90001 |          23 | TC016CHILD | t          ← orphan FK
```

**Fix đề xuất:** Thêm check vào SP `edoc.fn_doc_type_delete`:
```sql
-- After child check, before UPDATE:
IF EXISTS(SELECT 1 FROM edoc.incoming_docs WHERE doc_type_id = p_id AND COALESCE(is_deleted, false) = false)
   OR EXISTS(SELECT 1 FROM edoc.outgoing_docs WHERE doc_type_id = p_id AND COALESCE(is_deleted, false) = false)
   OR EXISTS(SELECT 1 FROM edoc.drafting_docs WHERE doc_type_id = p_id AND COALESCE(is_deleted, false) = false) THEN
  RETURN QUERY SELECT FALSE, 'Không thể xóa: loại văn bản đang được sử dụng'::TEXT;
  RETURN;
END IF;
```

**File:** `e_office_app_new/database/schema/000_schema_v3.0.sql:2312-2333` (SP `fn_doc_type_delete`)

---

### BUG-DMLV-004 — MEDIUM — Frontend gửi notation_type là string, backend cast `Number()` ra `0`

**TC ảnh hưởng:** TC-DMLV-005 (gián tiếp), TC-DMLV-013 (gián tiếp)  
**Severity:** Medium (data inconsistency frontend↔backend)  
**File:** `e_office_app_new/frontend/src/app/(main)/quan-tri/loai-van-ban/page.tsx:325-328`

**Mô tả:** Frontend Select options dùng string values:
```tsx
options={[
  { value: '', label: 'Không có' },
  { value: 'so/ky_hieu', label: 'Số/Ký hiệu' },     // ← string
  { value: 'so-ky_hieu', label: 'Số-Ký hiệu' },     // ← string
]}
```

Backend route admin-catalog.ts:256: `Number(notation_type) || 0` → `Number('so/ky_hieu') = NaN` → fallback `0`. Kết quả: user chọn "Số/Ký hiệu" hoặc "Số-Ký hiệu" qua UI thì DB lưu `0` (Không có).

DB column: `notation_type smallint` (0/1/2). API test với numeric `1`/`2` thì DB lưu đúng — nhưng từ frontend UI, user không có cách nào set giá trị 1/2.

**Render column** (`page.tsx:179-180`) còn check 3 dạng đồng thời (`v === 1 || v === '1' || v === 'so/ky_hieu'`) → tự gây confusion, nói lên đây là legacy code chưa được refactor.

**Fix đề xuất:** Đồng bộ frontend dùng số:
```tsx
options={[
  { value: 0, label: 'Không có' },
  { value: 1, label: 'Số/Ký hiệu' },
  { value: 2, label: 'Số-Ký hiệu' },
]}
```
Và đơn giản render:
```tsx
render: (v: number) => v === 1 ? 'Số/Ký hiệu' : v === 2 ? 'Số-Ký hiệu' : <span style={{ color: '#9CA3AF' }}>—</span>
```

---

## Verification Notes

- **DB table `edoc.doc_types`** dùng pattern soft-delete (`is_deleted boolean`) — khác với hard delete một số module khác. Cần audit toàn bộ SPs `fn_*_delete` xem còn module nào miss FK check tương tự.
- **Tab UI** hiển thị 3 tab cứng (`TAB_ITEMS` array) — không cần backend trả config tab → TC-DMLV-001 PASS theo spec.
- **Test data cleanup:** Đã xóa các record thử nghiệm id 21, 22, 23, 24 (soft delete) và reset incoming_docs.doc_type_id back về 1.

## Recommended Fix Priority

1. **BUG-DMLV-001 + BUG-DMLV-002** (CRITICAL — same root cause, single fix): Loại bỏ `GET /loai-van-ban/tree` khỏi `public-catalog.ts` HOẶC reorder mount để admin route win.
2. **BUG-DMLV-003** (CRITICAL — data integrity): Add FK check vào SP `fn_doc_type_delete`.
3. **BUG-DMLV-004** (MEDIUM — UX): Sync frontend Select values với DB enum.
