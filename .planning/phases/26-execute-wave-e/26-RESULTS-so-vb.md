# Wave E — Module DMSV (Quan ly So van ban) — RESULTS

**Module:** DMSV — Quan ly So van ban (`/quan-tri/so-van-ban`)
**Test cases:** 22 (TC-DMSV-001 .. TC-DMSV-022)
**Date executed:** 2026-05-07
**Tester:** Claude Code (manual API + Playwright UI subset)
**Login:** `admin / Admin@123` (production admin) + `test_admin / Test@123` (Playwright fixture, unit_id=1)

## Tong hop

| Status   | Count | TC IDs |
|----------|------:|--------|
| **PASS** |    18 | 001, 002, 003, 004, 005, 006, 007, 008, 010, 011, 012 (POST), 013, 014, 015, 016, 018, 019, 020, 021, 022 |
| **FAIL** |     3 | 003 (cot Mo ta + Mac dinh + Thu tu khong render gia tri), 009 (description >500 chap nhan), 017 (Xoa SO co FK ref van success) |
| **PARTIAL** | 1  | 012 — POST khong validate sort_order am (silently ignored = stored 0); PUT update CHAP NHAN sort_order am |
| **TOTAL** |   22 | |

> Note: TC-003 PASS ve mat **header columns hien dien** (Playwright assert OK), nhung **gia tri o cot Mo ta / Thu tu / Mac dinh hien thi sai** vi loi BUG-DMSV-001 (xem chi tiet ben duoi). Real-world impact: TC-003 expected_result "nhan 'Mac dinh' xanh" KHONG dat — phai count la FAIL.

Re-classified:

| Status   | Count |
|----------|------:|
| **PASS** | 16 |
| **FAIL** | 4 (003, 009, 012-PUT, 017) |
| **WARN** | 2 (TC-005/014 du PASS API + DB nhung UI badge khong hien xanh do BUG-DMSV-001) |
| **TOTAL**| 22 |

## Bugs

### BUG-DMSV-001 (HIGH) — `GET /api/quan-tri/so-van-ban` chi tra 4 cot, thieu `is_default`, `description`, `sort_order`

**Trigger:** Bat ky GET `/api/quan-tri/so-van-ban[?type_id=N]` voi user admin.

**Root cause:**
- File `e_office_app_new/backend/src/server.ts` line 71-74:
  ```ts
  app.use('/api/quan-tri', authenticate, publicCatalogRoutes);          // mount TRUOC
  app.use('/api/quan-tri', authenticate, requireRoles('Quản trị hệ thống'), adminCatalogRoutes);
  ```
- Express longest-prefix-wins → request GET `/api/quan-tri/so-van-ban` van match handler trong `publicCatalogRoutes` TRUOC khi den `adminCatalogRoutes`.
- Handler `publicCatalogRoutes` (file `e_office_app_new/backend/src/routes/public-catalog.ts:68-86`) chi `SELECT id, name, type_id, unit_id` — **THIEU** `description, sort_order, is_default`.

**Bang chung:**
- API response: `{"success":true,"data":[{"id":1,"name":"Sổ văn bản đến 2026","type_id":1,"unit_id":1}]}`
- Direct SP `edoc.fn_doc_book_get_list(1::smallint, 1, NULL)` tra ban DAY DU 9 cot.
- UI screenshot (test-failed-1.png) hien row "Sổ văn bản đến 2026" voi cot "MẶC ĐỊNH" = "Không" (sai — DB la `is_default=true`), "MÔ TẢ" trong, "THỨ TỰ" trong.

**Tac dong:**
- Trang `/quan-tri/so-van-ban` (`e_office_app_new/frontend/src/app/(main)/quan-tri/so-van-ban/page.tsx`) **KHONG bao gio** hien duoc:
  - Tag xanh "Mặc định" (luon hien xam "Không")
  - Cot "Mô tả"
  - Cot "Thứ tự"
- Test cases TC-DMSV-003, 005, 014, 022 expected "Mac dinh" xanh — UI **khong dat** du backend xu ly dung.

**Fix de xuat:**
- Option 1 (nhanh): Trong `routes/public-catalog.ts:74-80`, sua SELECT them `description, sort_order, is_default, created_at`.
- Option 2 (sach): Move `/so-van-ban` GET ra khoi `publicCatalogRoutes` (chi de cho non-admin form select) hoac doi response shape — admin route handler dung SP day du.
- Quy chuan ROADMAP doi cong dong: chua dong nhat — public-catalog la "form select reader cho non-admin". Nen them columns `description, sort_order, is_default` cho ca 2 endpoint.

---

### BUG-DMSV-002 (LOW) — POST + PUT `/so-van-ban` khong validate `description` length

**Trigger:** TC-DMSV-009 — POST body `description = "D"*501`.
**Result:** Server return 201 + ban ghi luu vao DB voi description.length=501.
**Root cause:** Cot `description` trong `edoc.doc_books` la `text` (no limit). Backend POST/PUT khong co length check. UI `<Input.TextArea maxLength={500}>` (frontend/src/app/(main)/quan-tri/so-van-ban/page.tsx:296) chi gioi han **client-side** — bypass tu Postman/cURL → server chap nhan.
**Fix:** Them `if (description?.length > 500) return res.status(400)...` o ca POST (line 96+) va PUT (line 134+) trong `admin-catalog.ts`. HOAC `ALTER TABLE edoc.doc_books ALTER COLUMN description TYPE VARCHAR(500)`.

---

### BUG-DMSV-003 (LOW) — PUT `/so-van-ban/:id` chap nhan `sort_order` am

**Trigger:** TC-DMSV-012 (variant on PUT) — PUT body `sort_order: -5`.
**Result:** Server return 200 success + DB stored `sort_order = -5`.
**Root cause:** No validation in route handler (`admin-catalog.ts:131-161`) hoac SP `edoc.fn_doc_book_update`. UI `<InputNumber min={0}>` chi prevent client-side.
**Note:** POST endpoint khong co bug nay vi POST handler khong forward sort_order toi SP create (mac du body co the chua) — UI khong show vi `sort_order` mac dinh = 0.
**Fix:** Them `if (sort_order < 0) return 400` o PUT handler.

---

### BUG-DMSV-004 (HIGH) — DELETE `/so-van-ban/:id` thanh cong khi So bi tham chieu boi `incoming_docs`

**Trigger:** TC-DMSV-017 — Tao incoming_doc voi `doc_book_id=1` (insert truc tiep), goi DELETE `/api/quan-tri/so-van-ban/1`.
**Result:** Server return 200 `{success: true, message: "Xoa so van ban thanh cong"}`. DB: `doc_books.id=1` co `is_deleted=true` (soft delete) du van con incoming_doc tham chieu.

**Root cause:** SP `edoc.fn_doc_book_delete(p_id integer)` chi check `IF NOT EXISTS (... is_deleted=false)` roi `UPDATE ... is_deleted=TRUE` — KHONG check FK references trong `incoming_docs` / `outgoing_docs` / `drafting_docs` / `handling_docs`.
```plpgsql
CREATE OR REPLACE FUNCTION edoc.fn_doc_book_delete(p_id integer)
 RETURNS TABLE(success boolean, message text)
AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.doc_books WHERE id = p_id AND is_deleted = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy sổ văn bản'::TEXT; RETURN;
  END IF;
  UPDATE edoc.doc_books SET is_deleted = TRUE WHERE id = p_id;  -- KHONG check FK
  RETURN QUERY SELECT TRUE, 'Xoa so van ban thanh cong'::TEXT;
END; $$;
```

**Tac dong nghiep vu:**
- Sau khi So bi soft-delete, VB den/di tham chieu So do van ton tai trong DB nhung So mat khoi UI list.
- Tao moi VB sau do KHONG con thay So nay → bang VB "Sổ" hien khac biet voi VB cu (data inconsistency).
- Khi can gia han nhiem ky / chuyen So → khong the lay lai So da bi xoa qua UI.

**Fix de xuat:** Sua SP de check FK truoc khi delete:
```plpgsql
IF EXISTS(SELECT 1 FROM edoc.incoming_docs WHERE doc_book_id = p_id)
   OR EXISTS(SELECT 1 FROM edoc.outgoing_docs WHERE doc_book_id = p_id)
   OR EXISTS(SELECT 1 FROM edoc.drafting_docs WHERE doc_book_id = p_id)
   OR EXISTS(SELECT 1 FROM edoc.handling_docs WHERE doc_book_id = p_id) THEN
  RETURN QUERY SELECT FALSE, 'Khong the xoa: So dang duoc su dung boi van ban'::TEXT; RETURN;
END IF;
```

---

## Chi tiet PASS/FAIL tung TC

| TC ID | Title | Status | Note |
|-------|-------|--------|------|
| 001 | Hien thi 3 tab (default = VB den) | PASS | Playwright verified |
| 002 | Switch tab → reload theo `type_id` | PASS | Network capture verified type_id=2,3 |
| 003 | Hien thi day du cot | **FAIL** | Header co cac cot, nhung gia tri Mo ta + Mac dinh + Thu tu KHONG render → BUG-DMSV-001 |
| 004 | Tao moi VB den, is_default=false | PASS | id=51 created |
| 005 | Tao moi voi is_default=true → toggle So cu | PASS | Backend SP `fn_doc_book_create` correctly un-defaults previous |
| 006 | Bo trong Ten so | PASS | Return 400 "Tên sổ văn bản là bắt buộc" |
| 007 | Ten 201 ky tu | PASS | Return 400 "Tên sổ văn bản không được vượt quá 200 ký tự" |
| 008 | Ten 200 ky tu (boundary) | PASS | id=52 created |
| 009 | Mo ta 501 ky tu | **FAIL** | Server chap nhan, store 501 ky tu → BUG-DMSV-002 |
| 010 | Trung ten cung type cung unit | PASS | Return 400 "Tên sổ văn bản đã tồn tại trong đơn vị" |
| 011 | Trung ten KHAC type → cho phep | PASS | id=54 created (type_id=2) |
| 012 | Sort_order am (POST) | PASS-passive | POST khong forward sort_order, default 0 ⇒ acceptable |
| 012b | Sort_order am (PUT) | **FAIL** | PUT chap nhan sort_order=-5 → BUG-DMSV-003 |
| 013 | Sua VB | PASS | Update success, description thay doi |
| 014 | setDefault qua menu 3 cham | PASS | API trigger swap default flag dung; **UI bug** so badge khong update vi BUG-DMSV-001 |
| 015 | Xoa SO khong tham chieu | PASS | Soft delete, list khong con hien |
| 016 | Cancel hop xac nhan xoa | PASS | Playwright verified — modal close, row van con |
| 017 | Xoa SO co tham chieu FK | **FAIL** | DELETE thanh cong dang le phai bao FK error → BUG-DMSV-004 |
| 018 | Drawer title "Them so van ban moi" | PASS | Playwright verified |
| 019 | Drawer title "Cap nhat so van ban" + form fill | PASS | Playwright verified |
| 020 | Cancel drawer them moi | PASS | Playwright verified |
| 021 | Sort theo `sort_order` tang dan | PASS | SP `fn_doc_book_get_list` ORDER BY sort_order |
| 022 | setDefault tren So da default (idempotent) | PASS | API success, no DB change |

## Files

- Source code (production):
  - `e_office_app_new/backend/src/server.ts` (mount order issue line 71-74)
  - `e_office_app_new/backend/src/routes/admin-catalog.ts` (admin handlers)
  - `e_office_app_new/backend/src/routes/public-catalog.ts` (con flicting handler line 68-86)
  - `e_office_app_new/backend/src/repositories/doc-book.repository.ts`
  - `e_office_app_new/frontend/src/app/(main)/quan-tri/so-van-ban/page.tsx`
- DB:
  - SP `edoc.fn_doc_book_get_list` (correct, returns 9 cols)
  - SP `edoc.fn_doc_book_delete` (BUG-DMSV-004 — no FK check)
- Tests created:
  - `tests/wave-e-so-van-ban/wave-e-so-van-ban.spec.ts` (7 Playwright UI tests, ALL PASS)

## Test artifacts

- Playwright run: `7 passed (37.9s)`
- API tests: 15 curl-based tests, all completed
- Test data cleaned up — DB restored to 15 seeded doc_books baseline

## Recommendations

1. **Fix BUG-DMSV-001 first** (HIGH) — toan bo cot Mo ta / Thu tu / Mac dinh dang bi an khoi UI quan tri. Affect all sprint demos.
2. **Fix BUG-DMSV-004** (HIGH) — soft-delete khong validate FK = data inconsistency.
3. BUG-DMSV-002 + 003 (LOW) — UI co maxLength/min nhung backend bypassable.
4. Recommend tach `publicCatalogRoutes` ra prefix khac nhu `/api/cong-khai/so-van-ban` de tranh route conflict.
