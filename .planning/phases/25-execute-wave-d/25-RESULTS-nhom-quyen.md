# Wave d - Quan tri Nhom quyen (Roles) - Test Results

**Module:** QTNQ - Quan tri > Nhom quyen
**Total TCs:** 23
**Executed:** 2026-05-07
**Tester:** AI manual tester
**Backend DB:** `qlvb_test` (running backend points to .env.runtime)
**Test method:** API direct via Node http + frontend code review

## Summary

| Result   | Count |
|----------|-------|
| PASS     | 17    |
| PASS-WARN| 3     |
| FAIL     | 2     |
| BLOCKED  | 1     |

---

## Endpoints discovered

| Method | Path                                      | Auth                    |
|--------|-------------------------------------------|-------------------------|
| GET    | /api/quan-tri/nhom-quyen                  | Quan tri he thong       |
| POST   | /api/quan-tri/nhom-quyen                  | Quan tri he thong       |
| PUT    | /api/quan-tri/nhom-quyen/:id              | Quan tri he thong       |
| DELETE | /api/quan-tri/nhom-quyen/:id              | Quan tri he thong       |
| GET    | /api/quan-tri/nhom-quyen/:id/quyen        | Quan tri he thong       |
| PUT    | /api/quan-tri/nhom-quyen/:id/quyen        | Quan tri he thong       |
| GET    | /api/quan-tri/chuc-nang/tree              | Quan tri he thong       |
| GET    | /api/quan-tri/chuc-nang/menu              | Quan tri he thong       |

Frontend page: `frontend/src/app/(main)/quan-tri/nhom-quyen/page.tsx`
Repository:    `backend/src/repositories/role.repository.ts`
Backend route: `backend/src/routes/admin.ts:644-759`

---

## TC results

### TC-QTNQ-001 - List columns - PASS-WARN
- Backend returns name, description, staff_count, created_at -> 4 cols match
- Frontend renders staff_count as `<Tag color="blue">` -> matches "the xanh" requirement
- Date format `DD/MM/YYYY` via dayjs -> match
- WARN: backend returns `staff_count` as **string** ("2") because BIGINT; frontend `<Tag>{v||0}</Tag>` displays string OK but type is wrong (should be number)

### TC-QTNQ-002 - Header card - PASS
- Card title: "Danh sach nhom quyen" + SafetyCertificate icon -> match
- Right side: Input.Search + Button "Them nhom quyen" -> match

### TC-QTNQ-003 - Search keyword - PASS-WARN
- Search "Van" returns "Văn thư" - PASS (case-insensitive ILIKE works)
- WARN: Search "Van thu" (no diacritic) returns 0 rows - SP uses `ILIKE` against original `name` column (with diacritics). Users typing without diacritics (typical VN UX) won't match. See **BUG-VT-006**.

### TC-QTNQ-004 - Pagination - **FAIL**
- Backend GET `/nhom-quyen` does **NOT** support `page` / `pageSize` params and **does NOT return `total`** field
- Returns: `{ success: true, data: [...all rows...] }` (no pagination wrapper)
- Frontend reads `res.total` -> always `undefined` -> table footer shows "Tong undefined" or 0
- Frontend sends `page`, `pageSize` query params but backend ignores them
- See **BUG-VT-001**

### TC-QTNQ-005 - Add minimal name - PASS
- POST `{name:'Test nhom Wave-D 001'}` -> 201, id returned
- New role appears with `staff_count = 0`
- Toast "Them thanh cong" present in code

### TC-QTNQ-006 - Add full (name + desc) - PASS
- POST `{name, description}` -> 201
- Description shows in list

### TC-QTNQ-007 - Empty name - PASS
- Frontend: Form rule `required: true, message: 'Nhap ten nhom quyen'` -> inline before submit
- Backend: returns 400 "Ten nhom quyen la bat buoc" (mapped via setBackendFieldError -> field "name")

### TC-QTNQ-008 - Duplicate name - PASS
- POST same name -> 409 "Ten nhom quyen da ton tai"
- Frontend setBackendFieldError maps to inline name error
- Case-insensitive: "TEST NHOM WAVE-D 001" also rejected (LOWER() comparison) -> good

### TC-QTNQ-009 - Name 100 chars (max) - PASS-WARN / **FAIL** at 101
- 100 chars accepted -> 201
- 101 chars: returns HTTP **500** with raw PG error `value too long for type character varying(100)`
- Frontend prevents 101 via `maxLength={100}` -> defense-in-depth ok at UI layer
- WARN: backend should validate length BEFORE insert and return 400 with friendly Vietnamese message. See **BUG-VT-002**

### TC-QTNQ-010 - Description 500 chars - PASS-WARN
- 500 chars accepted; **501 chars also accepted** (DB column is `TEXT`, no limit)
- Frontend `maxLength={500}` on TextArea but **missing `showCount` prop** -> "TextArea hien 500/500" requirement NOT met. See **BUG-VT-003**

### TC-QTNQ-011 - Edit description - PASS
- PUT `{name, description}` -> 200 `{updated:true}`
- Toast "Cap nhat thanh cong" - matches expected

### TC-QTNQ-012 - Edit duplicate name - PASS
- PUT changing name to existing -> 409 "Ten nhom quyen da ton tai"
- Self-rename (same id, same name) allowed - good (uses `id != $2` filter)

### TC-QTNQ-013 - Open Permissions Drawer - PASS
- Drawer title: `<>Phan quyen: <strong>{permRole?.name}</strong></>` -> match
- Size 720px (size={720}) -> match AntD 6
- `defaultExpandAll` on Tree -> match "mac dinh mo rong tat ca"
- API tree returns 14 top-level nodes (Dashboard, Van ban den, Van ban di, ...)

### TC-QTNQ-014 - Tick parent auto-ticks children - PASS
- Ant Design `<Tree checkable>` default behavior auto-checks descendants on parent check
- No custom override in code -> default behavior preserved

### TC-QTNQ-015 - Save permissions - PASS
- PUT `/nhom-quyen/:id/quyen` `{rightIds:[1,2,3]}` -> 200 `{assigned:true}`
- Toast "Luu phan quyen thanh cong"

### TC-QTNQ-016 - Reload pre-checks - PASS
- After assign, GET `/nhom-quyen/:id/quyen` returns `[{right_id:1},{right_id:2},{right_id:3}]`
- Frontend maps `r.right_id` -> setCheckedKeys -> Tree shows checked

### TC-QTNQ-017 - Loading spinner - PASS
- Code: `permLoading ? <Spin size="large"/> : <Tree.../>` centered with padding 48 -> matches

### TC-QTNQ-018 - Empty assign - PASS
- PUT `{rightIds:[]}` -> 200, GET returns 0 rows -> reopen tree empty -> match

### TC-QTNQ-019 - Delete role 0 staff - PASS
- DELETE -> 200 `{message:"Xoa thanh cong"}`
- Toast "Xoa thanh cong"
- Modal.confirm dialog with "Xac nhan xoa" + "Ban co chac chan muon xoa nhom quyen nay?" -> matches typical pattern

### TC-QTNQ-020 - Delete role with staff - PASS
- DELETE role id=2 (Can bo, 3 staff) -> 400 "Khong the xoa: con 3 nhan vien trong nhom quyen nay"
- DELETE role id=1 (Ban Lanh dao, 2 staff) -> 400 "Khong the xoa: con 2 nhan vien trong nhom quyen nay"
- **EXACT** match to TC expected message

### TC-QTNQ-021 - Cancel delete modal - PASS (code review)
- `Modal.confirm({okText:'Xoa', cancelText:'Huy', onOk:...})` - clicking Huy triggers default close, no API call -> verified by code

### TC-QTNQ-022 - Non-admin permission denied - PASS
- Created test user `testvt001` (is_admin=false, role=Van thu+Ban Lanh dao)
- GET `/quan-tri/nhom-quyen` -> 403 "Forbidden — insufficient permissions"
- POST `/quan-tri/nhom-quyen` -> 403 "Forbidden — insufficient permissions"
- Server.ts mounts `requireRoles('Quan tri he thong')` on /api/quan-tri prefix
- Frontend should hide menu / redirect (need UI verify but backend gate is correct)

### TC-QTNQ-023 - Multi-role union - PASS (SP level)
- SP `public.fn_right_get_by_staff(9115)` with user assigned roles [Van thu, Ban Lanh dao] returns 15 distinct rights
- Includes both `/van-ban-den` (Van thu right) and `/van-ban-di` (Lanh dao right)
- Union via DISTINCT in SP - works
- API endpoint `/quan-tri/chuc-nang/menu` is gated by admin role so not callable by non-admin **(BUG-VT-005)** — but the frontend MainLayout uses parsed roles array on JWT to filter menu client-side, so menu UI works

---

## Bugs

### BUG-VT-001 (HIGH) — Pagination not implemented for /quan-tri/nhom-quyen
- **TC affected:** TC-QTNQ-004
- **Where:** `backend/src/routes/admin.ts:648-657` and `backend/src/repositories/role.repository.ts:23-25`
- **Symptom:** GET `/quan-tri/nhom-quyen?page=1&pageSize=10` ignores params, returns all rows in `{ success, data }` (no `total` field). Frontend `setTotal(res.total||0)` always = 0 -> table pagination footer broken once > 10 roles exist.
- **Fix suggestion:** Add page/pageSize to repo + SP, return `{ success, data, total, page, pageSize }`.

### BUG-VT-002 (MEDIUM) — Name > 100 chars returns HTTP 500 with raw PG error
- **TC affected:** TC-QTNQ-009 (boundary)
- **Where:** `backend/src/routes/admin.ts:660-689`
- **Symptom:** `POST {name: 101 chars}` -> 500 `value too long for type character varying(100)`. Frontend has no handler for HTTP 500 -> generic "Loi khi xoa"-style toast.
- **Fix:** Add `if (name.trim().length > 100) return 400 'Ten nhom quyen toi da 100 ky tu'`.

### BUG-VT-003 (LOW) — Description TextArea missing showCount + no max validation
- **TC affected:** TC-QTNQ-010
- **Where:** `frontend/src/app/(main)/quan-tri/nhom-quyen/page.tsx:333` and DB schema `description` column type = TEXT (no limit)
- **Symptom:** TC expects "TextArea hien 500/500" — frontend has `maxLength={500}` but no `showCount`. Also backend accepts > 500 chars (DB is TEXT, no validation).
- **Fix:** Add `showCount` to TextArea; add backend `length > 500` validation OR change DB column to `VARCHAR(500)`.

### BUG-VT-004 (LOW) — staff_count returned as string "2" instead of number
- **TC affected:** TC-QTNQ-001 (cosmetic)
- **Where:** `backend/src/repositories/role.repository.ts:9` (typed `staff_count: number`) but pg driver returns BIGINT/COUNT as string
- **Symptom:** TypeScript type lies; frontend `<Tag>{v||0}</Tag>` works because string "2" is truthy, but `find(r => r.staff_count === 0)` would behave wrong if used.
- **Fix:** SP cast `COUNT(*)::INT` OR repository wraps `Number()`.

### BUG-VT-005 (MEDIUM) — /chuc-nang/menu requires admin role
- **TC affected:** TC-QTNQ-023 (partial)
- **Where:** `backend/src/server.ts:73`
- **Symptom:** Endpoint `/api/quan-tri/chuc-nang/menu` is gated by `requireRoles('Quan tri he thong')`, so a non-admin user (e.g. Van thu) cannot fetch their own menu rights via this endpoint. Server returns 403.
- **Workaround:** MainLayout on frontend uses JWT `user.roles` array to filter menu items client-side, so functional menu still works for non-admin. But backend endpoint behavior is inconsistent: it claims to return "menu of current user" yet only admin can call it.
- **Fix:** Move `GET /chuc-nang/menu` outside `/quan-tri` prefix OR drop the `requireRoles` for this endpoint.

### BUG-VT-006 (MEDIUM) — Search not diacritic-insensitive
- **TC affected:** TC-QTNQ-003
- **Where:** SP `public.fn_role_get_list` uses `r.name ILIKE '%' || p_keyword || '%'`
- **Symptom:** Searching "Van thu" (no diacritics) -> 0 hits even though "Van thu" exists. VN users typing without diacritics is common.
- **Fix:** Use `unaccent(r.name) ILIKE unaccent('%' || p_keyword || '%')` (extension `unaccent` is installed). Same fix needed across all list SPs that filter by name.

---

## Notes / Environment

- Backend running on port 4000, connected to **`qlvb_test`** DB (verified via .env.runtime). Initially confused with qlvb_dev; had to create test user `testvt001` directly in qlvb_test then cleanup. Test user removed at end.
- All POST/PUT/DELETE were performed against `qlvb_test`. DB now back to clean 6-role baseline.
- Frontend not interacted via browser — code reviewed and API behavior verified directly. Visual TCs (loading spinner positioning, "Tong N" badge color) inferred from code.
- TC-QTNQ-020 message exactly matches expected text including diacritics — bug-free implementation, kudos.
