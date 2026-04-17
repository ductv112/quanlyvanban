# KẾ HOẠCH FIX — e-Office Test Report

> **Ngày:** 2026-04-17
> **Tổng:** 182 tests | 164 PASS (90.1%) | 8 WARN | 10 FAIL
> **Sau audit sâu:** Phát hiện thêm root cause cho các WARN → thực tế có 13 items cần fix

---

## TỔNG HỢP TẤT CẢ ISSUES (sắp theo thứ tự fix)

### NHÓM A: Seed Data & SP Fixes (fix trước — chuẩn data)

| # | Vấn đề | File cần sửa | Root Cause | Ước l��ợng |
|---|--------|-------------|------------|-----------|
| A1 | SP `fn_doc_column_get_all` trả 500 | `database/migrations/028_*` hoặc tạo migration mới | RETURNS TABLE khai báo `type_id integer` nhưng cột thật l�� `smallint` | ~5 phút |
| A2 | Seed thiếu calendar events cho admin | `database/seed_full_demo.sql` | 8 events seed nhưng không có event personal cho staff_id=1 (admin) | ~5 phút |
| A3 | Seed thiếu SMS/email templates | `database/seed_full_demo.sql` | Bảng `sms_templates`, `email_templates` tồn tại nhưng 0 rows | ~10 phút |
| A4 | Seed thiếu provinces/districts/communes | `database/seed_full_demo.sql` | Bảng tồn tại nhưng 0 rows → trang Địa bàn trống | ~10 phút |
| A5 | Seed thiếu configurations | `database/seed_full_demo.sql` | Bảng `configurations` có 0 rows → trang Cấu hình trống | ~5 phút |

### NHÓM B: Backend Route Fixes (fix nhanh, impact lớn)

| # | Vấn đề | File cần sửa | Root Cause | Ước lượng |
|---|--------|-------------|------------|-----------|
| B1 | **[CRITICAL]** Thiếu `requireRoles` trên admin routes | `backend/src/server.ts` | Mọi user đã login đều truy cập được `/quan-tri/*` | ~5 phút |
| B2 | Doc books list trả 0 | `backend/src/routes/admin-catalog.ts:65` | `type_id` default `0` thay vì `null` → SP filter `type_id = 0` | ~2 phút |
| B3 | HSCV list trả 0 cho admin | `backend/src/routes/handling-doc.ts:26` | Truyền `departmentId` từ JWT thay vì `null` → handling_docs có `department_id = NULL` nên filter miss | ~2 phút |
| B4 | VB Đi số chưa phát hành 500 NaN | `backend/src/routes/outgoing-doc.ts` | Parameter `unitId` hoặc `year` parse thành NaN | ~10 phút |
| B5 | Route `/quan-tri/dia-ban` — 404 | `backend/src/routes/admin-catalog.ts` | Route chưa được implement (bảng DB là `provinces/districts/communes`, không phải `territories`) | ~30 phút |
| B6 | Route `/quan-tri/mau-thong-bao` — 404 | `backend/src/routes/admin-catalog.ts` | Route chưa được implement cho SMS/email templates | ~30 phút |
| B7 | Route `/cuoc-hop/types` bị catch bởi `/:id` | `backend/src/routes/meeting.ts` | Static route `/types` phải đặt TRƯỚC dynamic `/:id` | ~5 phút |
| B8 | Route `/ky-so/certificates` bị catch bởi `/:id` | `backend/src/routes/digital-signature.ts` | Tương tự B7 | ~5 phút |
| B9 | Route `/lich/holidays` — 404 | `backend/src/routes/calendar.ts` | Route chưa có, frontend cần lấy ngày nghỉ từ work calendar | ~15 phút |
| B10 | Dashboard `/tasks` path sai | Frontend hoặc backend | Route đúng là `/upcoming-tasks`, frontend gọi sai path | ~2 phút |

---

## THỨ TỰ FIX ĐỀ XUẤT

### Wave 1: SP + Seed (chuẩn data trước) — ~35 phút
```
A1 → Fix SP fn_doc_column_get_all (type_id smallint)
A2 → Seed calendar events cho admin
A3 → Seed SMS/email templates
A4 → Seed provinces/districts/communes (63 tỉnh + sample quận/huyện)
A5 → Seed configurations
→ Chạy migration + re-seed → verify data
```

### Wave 2: Quick backend fixes — ~25 phút
```
B1 → Thêm requireRoles vào server.ts
B2 → Fix type_id default 0 → null
B3 → Fix departmentId → null
B4 → Fix NaN parsing outgoing-doc
B7 → Reorder meeting routes
B8 → Reorder digital-signature routes
B10 → Fix dashboard tasks path
```

### Wave 3: New routes (nếu kịp) — ~75 phút
```
B5 → Route /quan-tri/dia-ban (provinces/districts/communes)
B6 → Route /quan-tri/mau-thong-bao (templates CRUD)
B9 → Route /lich/holidays
```

---

## CHI TIẾT FIX CHO TỪNG ITEM

### A1: Fix SP `fn_doc_column_get_all`
```sql
-- Trong RETURNS TABLE, đổi type_id từ integer → smallint
CREATE OR REPLACE FUNCTION edoc.fn_doc_column_get_all()
RETURNS TABLE(id integer, type_id smallint, ...)  -- smallint, không phải integer
```

### A2: Seed calendar events cho admin
```sql
INSERT INTO public.calendar_events (staff_id, title, description, start_time, end_time, scope, ...)
VALUES (1, 'Họp giao ban đầu tuần', '...', '2026-04-21 08:00', '2026-04-21 09:00', 'personal', ...);
```

### B1: Thêm requireRoles
```typescript
// server.ts — thêm sau authenticate middleware
app.use('/api/quan-tri', authenticate, requireRoles('Quản trị hệ thống'), adminRouter);
app.use('/api/quan-tri', authenticate, requireRoles('Quản trị hệ thống'), adminCatalogRouter);
```

### B2: Fix doc_books type_id
```typescript
// admin-catalog.ts line 65
// Trước: const typeId = req.query.type_id ? Number(req.query.type_id) : 0;
// Sau:
const typeId = req.query.type_id ? Number(req.query.type_id) : null;
```

### B3: Fix HSCV departmentId
```typescript
// handling-doc.ts line 26
// Trước: departmentId ?? null,
// Sau: req.query.department_id ? Number(req.query.department_id) : null,
```

### B4: Fix outgoing-doc NaN
```typescript
// outgoing-doc.ts — getUnusedNumbers
// Kiểm tra Number(req.query.doc_book_id) không phải NaN
const docBookId = Number(req.query.doc_book_id);
if (isNaN(docBookId)) { return res.status(400).json({...}); }
```

### B7 + B8: Reorder static routes
```typescript
// meeting.ts — đặt /loai-cuoc-hop TRƯỚC /:id
router.get('/loai-cuoc-hop', ...);  // TRƯỚC
router.get('/:id', ...);           // SAU
```

---

## SAU KHI FIX

1. Reset DB: `docker-compose down -v && docker-compose up -d`
2. Chạy tất cả migrations + seed mới
3. Chạy lại test suite → target 95%+ PASS
