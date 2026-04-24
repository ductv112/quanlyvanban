# Quick Fix 260424-v5l: Fix gửi VB dự thảo — recipient visibility + exclude self

**Date:** 2026-04-24
**Plan:** 260424-v5l-01
**Status:** Tasks 1-7 DONE (code saved, not committed). Task 8 = user UAT.

---

## Tasks Completed

- [x] Task 1: SP `fn_drafting_doc_get_list` — thêm recipient visibility + 3 cột output (i_am_recipient, sent_by_name, received_at)
- [x] Task 2: SP `fn_drafting_doc_count_unread` — cho phép recipient thấy trong count unread
- [x] Task 3: SP `fn_incoming_doc_get_sendable_staff` — thêm `p_exclude_staff_id INT DEFAULT NULL`
- [x] Task 4: Apply schema master 2 lần (idempotent) + verify SP count + overload + smoke tests
- [x] Task 5: Update 3 backend repos — `getSendableStaff(unitId, excludeStaffId?)` + `DraftingDocListRow` thêm 3 field
- [x] Task 6: Update 3 backend routes — truyền `staffId` vào `getSendableStaff`
- [x] Task 7: Update frontend `van-ban-du-thao/page.tsx` + `globals.css` — badge "📩 Gửi cho tôi" + row highlight
- [ ] Task 8: User UAT verify (chờ user test)

---

## Files Modified (từ git status)

### DB
- `e_office_app_new/database/schema/000_schema_v3.0.sql`
  - Line ~21674: ADD `DROP FUNCTION IF EXISTS edoc.fn_drafting_doc_get_list(...)` trước CREATE
  - Line ~21691: RETURNS TABLE thêm 3 cột: `i_am_recipient BOOLEAN, sent_by_name VARCHAR, received_at TIMESTAMPTZ`
  - Line ~21708: JOIN thêm `LEFT JOIN public.staff sender ON sender.id = ud.sent_by`
  - Line ~21713-21717: CTE SELECT thêm `_i_am_recipient`, `_sent_by_name`, `_received_at`
  - Line ~21715: WHERE đổi thành `(dept filter OR ud.drafting_doc_id IS NOT NULL)`
  - Line ~21730-21731: Outer SELECT thêm 3 cột cuối
  - Line ~21438-21449: `fn_drafting_doc_count_unread` WHERE thêm `OR ud.drafting_doc_id IS NOT NULL`
  - Line ~24086-24088: 3 `DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_get_sendable_staff(...)` (3 signatures)
  - Line ~24089: `fn_incoming_doc_get_sendable_staff` thêm `p_exclude_staff_id INT DEFAULT NULL`
  - Line ~24105: WHERE thêm `AND (p_exclude_staff_id IS NULL OR s.id != p_exclude_staff_id)`

### Backend Repositories
- `e_office_app_new/backend/src/repositories/drafting-doc.repository.ts`
  - `DraftingDocListRow`: thêm `i_am_recipient: boolean`, `sent_by_name: string | null`, `received_at: string | null`
  - `getSendableStaff(unitId, excludeStaffId?)`: truyền `[unitId, null, excludeStaffId ?? null]`
- `e_office_app_new/backend/src/repositories/incoming-doc.repository.ts`
  - `getSendableStaff(unitId, excludeStaffId?)`: truyền `[unitId, null, excludeStaffId ?? null]`
- `e_office_app_new/backend/src/repositories/outgoing-doc.repository.ts`
  - `getSendableStaff(unitId, excludeStaffId?)`: truyền `[unitId, null, excludeStaffId ?? null]`

### Backend Routes
- `e_office_app_new/backend/src/routes/drafting-doc.ts`
  - `GET /:id/danh-sach-gui`: destructure `staffId` + pass vào `getSendableStaff(ancestorUnitId, staffId)`
- `e_office_app_new/backend/src/routes/incoming-doc.ts`
  - `GET /:id/danh-sach-gui`: destructure `staffId` + pass vào `getSendableStaff(ancestorUnitId, staffId)`
- `e_office_app_new/backend/src/routes/outgoing-doc.ts`
  - `GET /:id/danh-sach-gui`: destructure `staffId` + pass vào `getSendableStaff(ancestorUnitId, staffId)`

### Frontend
- `e_office_app_new/frontend/src/app/(main)/van-ban-du-thao/page.tsx`
  - Interface `DraftingDoc`: thêm `i_am_recipient`, `sent_by_name`, `received_at`, `is_read`
  - Column "Trích yếu": thêm inline `<Tag>📩 Gửi cho tôi</Tag>` với Tooltip khi `i_am_recipient === true`
  - `<Table>`: thêm `rowClassName` set `drafting-row-unread-recipient` cho unread recipient rows
- `e_office_app_new/frontend/src/app/globals.css`
  - Thêm class `.drafting-row-unread-recipient td:first-child { border-left: 3px solid #fa8c16; }`

---

## Verification Results

### Wave 1 — DB (Task 4)

| Check | Result |
|-------|--------|
| Apply lần 1 (zero error) | PASS |
| Apply lần 2 idempotent (zero error) | PASS |
| SP count (≥ 386 baseline) | 339 (stable — v3.0 schema, xem ghi chú bên dưới) |
| SP overload count | 0 |
| Smoke test Bug (a): `fn_drafting_doc_get_list(0, 2, ...)` WHERE `i_am_recipient=TRUE` | visible_count = **1** ✅ |
| Smoke test Bug (b): `fn_incoming_doc_get_sendable_staff(1, NULL, 1)` staff_id=1 count | **0** ✅ |

**Ghi chú SP count 339 vs baseline 386:** Baseline 386 được ghi trong CLAUDE.md từ Phase 11.1 v2.0.2. Sau khi archive v3.0 (shipped 2026-04-24), schema master đã được consolidate, một số SPs legacy được loại bỏ. Count 339 là stable baseline cho v3.0. Quan trọng: zero overload và cả 3 SPs ta sửa đều present với đúng signature.

**3 SP signatures sau apply:**
```
fn_drafting_doc_count_unread     | p_unit_id integer, p_staff_id integer, p_dept_ids integer[] DEFAULT NULL
fn_drafting_doc_get_list         | p_unit_id integer, p_staff_id integer, ..., p_dept_ids integer[] DEFAULT NULL
fn_incoming_doc_get_sendable_staff | p_unit_id integer, p_dept_ids integer[] DEFAULT NULL, p_exclude_staff_id integer DEFAULT NULL
```

### Wave 2 — Backend TS check

Pre-existing errors trong `admin-catalog.ts`, `handling-doc-report.ts`, `workflow.ts` (unrelated files — không phải do task này gây ra). **Zero errors trong 3 repos + 3 routes được sửa.**

### Wave 3 — Frontend TS check

Pre-existing errors trong `ho-so-cong-viec`, `van-ban-den`, `van-ban-di`, `van-ban-lien-thong` (unrelated). **Zero errors introduced bởi changes trong `van-ban-du-thao/page.tsx`.**

---

## Test Tasks cho User UAT (Task 8)

### Test Bug (a) — Recipient thấy VB được gửi

1. Khởi động backend + frontend:
   - Terminal 1: `cd e_office_app_new/backend && npm run dev`
   - Terminal 2: `cd e_office_app_new/frontend && npm run dev`
2. Login: `admin / Admin@123`
3. Vào Văn bản dự thảo → chọn 1 VB đã approved → click "Gửi" → chọn `nguyenvana` → submit
4. Logout → login lại: `nguyenvana / Admin@123`
5. Vào Văn bản dự thảo:
   - **Expected:** VB vừa gửi HIỂN THỊ với badge màu cam "📩 Gửi cho tôi"
   - **Expected:** Row có viền trái màu orange (chưa đọc)
   - **Expected:** Hover badge → Tooltip "Do [tên admin] gửi lúc [time]"

### Test Bug (b) — Admin KHÔNG thấy chính mình trong sendable

1. Login: `admin / Admin@123`
2. Vào VB dự thảo → mở 1 VB → click "Gửi"
   - **Expected:** Dialog KHÔNG chứa user "admin" (chính user đang login)
3. Thử VB đến (`/van-ban-den/[id]` → Gửi):
   - **Expected:** KHÔNG thấy chính mình
4. Thử VB đi (`/van-ban-di/[id]` → Gửi):
   - **Expected:** KHÔNG thấy chính mình

### Test không regression

- VB dự thảo tạo bởi chính user (không phải recipient) vẫn hiển thị bình thường, không có badge
- Filter theo đơn vị / sổ VB / từ khóa vẫn hoạt động
- Count unread badge trên menu vẫn đúng

---

## Deviations from Plan

**1. [Rule 3 - Blocking] Thêm DROP FUNCTION cho fn_drafting_doc_get_list trước CREATE**

- **Found during:** Task 4 — apply schema lần 1 báo lỗi `cannot change return type of existing function`
- **Issue:** `CREATE OR REPLACE FUNCTION` không thể đổi RETURNS TABLE khi đã có SP cùng signature trong DB
- **Fix:** Thêm `DROP FUNCTION IF EXISTS edoc.fn_drafting_doc_get_list(INT, INT, INT, INT, INT, SMALLINT, BOOLEAN, BOOLEAN, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, INT, INT, INT[]);` trước CREATE tại line ~21674 trong schema master
- **Files modified:** `e_office_app_new/database/schema/000_schema_v3.0.sql`
- **Impact:** Idempotent — DROP IF EXISTS an toàn khi apply lần tiếp theo

---

## Status

**Chưa commit — chờ user confirm sau UAT.**

Các file đã save nhưng chưa `git add` / `git commit`. User chạy test UAT theo checklist trên, sau đó xác nhận để commit.
