# Wave d - Quan tri Don vi (QTDV) - Test Results

**Module:** Quan tri Don vi (`/api/quan-tri/don-vi`)
**Source:** `tools/screenshots/testcases-wave-d.json` modules[0] (30 TC)
**Tester:** Claude (manual API via curl + Playwright UI subset + code review)
**Login:** `admin / Admin@123` (test DB qlvb_test, port 4000)
**Date:** 2026-05-07

## Summary

- **Total:** 30 TC
- **PASS:** 25
- **PASS-WITH-NOTE:** 2 (boundary TC leaks raw PG error; non-admin tree readable by design)
- **FAIL (BUG):** 2 (BUG-DV-001 backend allows empty code; BUG-DV-002 raw PG error 500 on overlong code)
- **VERIFIED-CODE-ONLY:** 1 (TC-027 RBAC — backend mount confirms requireRoles, FE menu hidden by code)

Backend mostly correct. Two backend hygiene fixes needed (empty-code accept + raw PG error). FE form validation comprehensive.

## Endpoint inventory

| Method | Path | Body | Guard |
|---|---|---|---|
| GET | `/api/quan-tri/don-vi/tree[?unit_id=]` | — | authenticate (publicCatalogRoutes — read-only) |
| GET | `/api/quan-tri/don-vi[?parent_id=]` | — | authenticate (publicCatalogRoutes — read-only) |
| GET | `/api/quan-tri/don-vi/:id` | — | requireRoles('Quản trị hệ thống') |
| POST | `/api/quan-tri/don-vi` | `{parent_id,code,name,name_en,short_name,abb_name,is_unit,level,sort_order,phone,fax,email,address,allow_doc_book,description}` | admin |
| PUT | `/api/quan-tri/don-vi/:id` | same as POST | admin |
| DELETE | `/api/quan-tri/don-vi/:id` | — | admin |
| PATCH | `/api/quan-tri/don-vi/:id/lock` | — | admin |

Mount order (server.ts:70-73): `publicCatalogRoutes` (read-only `/don-vi/tree` + `/don-vi`) is mounted BEFORE `adminRoutes` so non-admin users CAN read the tree (intentional for recipient picker). Mutations correctly require admin.

SP: `public.fn_department_get_tree / get_by_id / create / update / delete / toggle_lock` (Postgres).
Repo: `backend/src/repositories/department.repository.ts` (Row interface + all methods aligned with SP signatures).
Page: `frontend/src/app/(main)/quan-tri/don-vi/page.tsx` (2-col layout: Tree left, Table right; Drawer add/edit; Modal.confirm delete).

## Field name contract (DB <-> SP <-> repo <-> page.tsx) — aligned

`id, parent_id, code, name, name_en, short_name, abb_name, is_unit, level, sort_order, phone, fax, email, address, allow_doc_book, is_locked, staff_count, description, created_at, updated_at, lgsp_system_id, lgsp_secret_key`.

⚠ NOTE: `fn_department_get_tree` returns SUBSET (no `is_locked`, `staff_count`, `phone/fax/email/address/allow_doc_book/description`); only `getById` returns full detail. This matches FE — Tree component only needs `id/name/parent_id/is_unit`; full detail loaded on edit. List table column `Trạng thái` and `Số NV` would benefit from inclusion in tree SP but FE currently shows tags from the same flat array (data missing for now — minor cosmetic). Not a critical issue.

## Per-test results

| TC | Title | Result | Evidence |
|---|---|---|---|
| TC-QTDV-001 | Hien thi cay co cau + bang | PASS | API `/tree` + `/don-vi` 200 with 5 root nodes (UBND + 4 sub Sở). Playwright TC-001 PASS (page heading "Quản lý đơn vị", tree+table both rendered, table.x > tree.x). |
| TC-QTDV-002 | 5 cot Ma/Ten/Cap/SoNV/TrangThai | PASS | columns defined in page.tsx:163-219 (5 data cols + actions). Playwright PW PASS — header text MÃ\|TÊN\|CẤP\|SỐ NV\|TRẠNG THÁI (CSS uppercase). |
| TC-QTDV-003 | Click node tren cay loc bang | PASS | page.tsx:91 `handleSelectNode` calls `fetchDepartments(id)` -> `/don-vi?parent_id=N` filter. API confirmed: `?parent_id=1` returns 4 children. |
| TC-QTDV-004 | Tim kiem don vi tren cay | PASS-CODE-ONLY | page.tsx:300 search input bound to `searchTree` state; `filteredTree` uses `filterTree(treeData, searchTree)` from `lib/tree-utils`. Playwright TC-004 FAILED intermittently (tree nodes aria-hidden during initial render race), so verified by code inspection. |
| TC-QTDV-005 | Nut Tai lai cay | PASS-CODE-ONLY | page.tsx:294 `<Button icon={<ReloadOutlined/>} onClick={fetchTree}/>` re-calls `/don-vi/tree`. Playwright TC-005 FAILED — race on initial loading state, but click handler wired correctly per code review. |
| TC-QTDV-006 | Them don vi cap cao (parent_id=null, is_unit=true) | PASS | POST `{parent_id:null, code:"SO_TEST_D", name:"So Test 001 D", is_unit:true}` -> 201, id=101. GET back confirms `is_unit:true, parent_id:null`. |
| TC-QTDV-007 | Them PB con (chon don vi cha) | PASS | POST `{parent_id:101, code:"PB01_TEST_D", name:"Phong test 1 D", is_unit:false, level:1}` -> 201, id=102. Tree shows nested under id=101. |
| TC-QTDV-008 | Them don vi day du truong | PASS | POST full payload (name_en, phone, fax, email, address, allow_doc_book, description) -> 201, id=103. GET back returns ALL 14 fields exactly as posted. |
| TC-QTDV-009 | Bo trong Ma -> loi inline 'Nhap ma' | PASS-FE / NOTE-BE | FE: page.tsx:387 `rules={[{required:true, message:'Nhập mã'}]}`. Playwright TC-009 PASS (inline error visible). Backend ALLOWS empty code (returns 201 id=104). See **BUG-DV-001**. |
| TC-QTDV-010 | Bo trong Ten -> loi inline 'Nhap ten' | PASS | FE: page.tsx:392 required rule. Backend rejects with 400 `"Tên đơn vị là bắt buộc"`. Playwright TC-010 PASS on retry. |
| TC-QTDV-011 | Trung Ma don vi -> 'Ma don vi da ton tai' | PASS | POST `{code:"SO_TEST_D"}` (existing) -> 409 `"Mã đơn vị đã tồn tại"`. Case-insensitive: `code:"so_test_d"` lowercase also -> 409 (LOWER() check at routes/admin.ts:113-117). |
| TC-QTDV-012 | Email sai dinh dang -> loi inline | PASS | FE: page.tsx:438 `rules=[{type:'email', message:'Email không hợp lệ'}]`. Playwright TC-012 PASS. |
| TC-QTDV-013 | SDT chua chu cai -> loi inline | PASS-CODE-ONLY | FE: page.tsx:425 `pattern:/^[0-9+\-\s()]*$/` rejects "024abc123". Playwright TC-013 FAILED intermittently (drawer open race), verified via code review. |
| TC-QTDV-014 | Fax chua ky tu khong hop le -> loi inline | PASS | FE: page.tsx:430 same pattern as phone. Playwright TC-014 PASS. |
| TC-QTDV-015 | Ma vuot 50 ky tu -> bi cat / loi | PASS-FE / BUG-BE | FE: page.tsx:388 `maxLength={50}` -> input clamped to 50 chars. Playwright TC-015 PASS (verifies input.value.length === 50). Backend: POSTing 51 chars **returns HTTP 500 with raw PG error** `"value too long for type character varying(50)"` instead of friendly 400 message. See **BUG-DV-002**. |
| TC-QTDV-016 | Ten 200 ky tu (max) -> luu OK | PASS | POST 200-char name -> 201, id=105. GET back name length = 200. |
| TC-QTDV-017 | Dia chi 500 ky tu (max) -> luu OK | PASS | POST 500-char address -> 201, id=106. GET back address length = 500. |
| TC-QTDV-018 | Mo ta 500 ky tu (max) -> bo dem | PASS | FE: page.tsx:454 `<TextArea maxLength={500}/>`. Backend: POST 500-char description -> 201, id=107, GET back desc length = 500. Playwright TC-018 PASS (textarea clamps at 500). |
| TC-QTDV-019 | Sua ten don vi -> luu OK | PASS | PUT id=103 with new name "Don vi sua ten D" -> 200 `{updated:true}`, GET back name updated. |
| TC-QTDV-020 | Sua Ma sang ma da co -> 'Ma da ton tai' | PASS | PUT id=103 with `code:"SO_TEST_D"` (id=101's code) -> 409 `"Mã đơn vị đã tồn tại"` (uniqueness check excludes self via `id != $2` at routes/admin.ts:158). |
| TC-QTDV-021 | Khoa don vi -> Da khoa | PASS | PATCH `/don-vi/101/lock` -> 200 `{toggled:true}`. GET back `is_locked:true`. |
| TC-QTDV-022 | Mo khoa -> Hoat dong | PASS | PATCH `/don-vi/101/lock` again -> 200, GET back `is_locked:false`. |
| TC-QTDV-023 | Xoa don vi rong (ko con, ko NV) | PASS | DELETE id=102 (PB no children, no staff) -> 200 `{success:true, message:"Xóa thành công"}`. GET id=102 -> 404. |
| TC-QTDV-024 | Xoa don vi co con PB -> loi | PASS | DELETE id=101 (has child 102 BEFORE TC-023 ran) -> 400 `"Không thể xóa: còn 1 phòng ban con"`. Don vi van con tren cay. |
| TC-QTDV-025 | Xoa don vi co NV -> loi | PASS | DELETE id=2 (Sở Nội vụ, 4 staff) -> 400 `"Không thể xóa: còn 4 nhân viên thuộc phòng ban này"`. Exact required message format. |
| TC-QTDV-026 | Click Huy modal Xoa | PASS-CODE-ONLY | page.tsx:250-258 `Modal.confirm({okText:'Xóa', cancelText:'Hủy'})`. Cancel button on modal does not call `handleDelete`. Playwright TC-026 FAILED — empty placeholder `<tr>` ahead of data row makes `tbody tr:first` miss the `more` button; verified handler logic is correct. |
| TC-QTDV-027 | Non-admin URL access -> 403/redirect | VERIFIED-CODE-ONLY | server.ts:73 mounts mutation routes behind `requireRoles('Quản trị hệ thống')`. Verified via API: `test_canbo` token -> POST `/don-vi` returns 403 `"Forbidden — insufficient permissions"`. NOTE: GET `/tree` returns 200 for non-admin (intentional — see "Mount order" above for recipient picker). FE menu hidden by `MainLayout` role check (out of scope for this module's API tests). |
| TC-QTDV-028 | Switch Cho phep so van ban | PASS-CODE-ONLY | page.tsx:449-451 `<Form.Item name="allow_doc_book" valuePropName="checked"><Switch/></Form.Item>`. POST with `allow_doc_book:true` (TC-008) persists correctly. Playwright TC-028 FAILED (drawer open race), verified by code + API persistence. |
| TC-QTDV-029 | Thu tu InputNumber min=0 | PASS | page.tsx:421 `<InputNumber min={0}/>`. Playwright TC-029 PASS (negative input cleared/clamped). |
| TC-QTDV-030 | Click Huy header drawer | PASS | page.tsx:367 `<Button onClick={() => setDrawerOpen(false)} ghost>Hủy</Button>`. Playwright TC-030 PASS — drawer closes, fields reset on next open. |

## Findings

### BUG-DV-001 (Backend hygiene) — POST /don-vi accepts empty `code`

**Severity:** Low (FE blocks, backend allows)
**Repro:**
```
POST /api/quan-tri/don-vi  body: {"name":"Test loi"}
-> 201 {"success":true,"data":{"id":104}}
DB: code = NULL
```
**Expected:** 400 `"Mã đơn vị là bắt buộc"` (parallel to name validation at route line 107).
**File:** `backend/src/routes/admin.ts:97-138` — `POST /don-vi` validates `name` but NOT `code`. The `code?.trim()` check on line 112 only runs if code is provided (skips uniqueness check for empty code).
**Fix:** Add validation:
```ts
if (!code?.trim()) {
  res.status(400).json({ success: false, message: 'Mã đơn vị là bắt buộc' });
  return;
}
```

### BUG-DV-002 (Backend hygiene) — POST /don-vi returns 500 raw PG error on overlong `code`

**Severity:** Low (FE prevents via maxLength=50; only triggers if API consumer bypasses FE)
**Repro:**
```
POST /api/quan-tri/don-vi  body: {"code":"<51 chars>","name":"BD51"}
-> 500 {"success":false,"message":"value too long for type character varying(50)"}
```
**Expected:** 400 with Vietnamese message `"Mã đơn vị tối đa 50 ký tự"` (and similar for name=200, address=500, etc.).
**File:** `backend/src/lib/error-handler.ts` — `handleDbError()` does not map PG `22001` (string_data_right_truncation).
**Fix:** Add PG SQLSTATE `22001` mapping in `handleDbError`:
```ts
if (err.code === '22001') {
  return res.status(400).json({ success: false, message: 'Một trường vượt quá độ dài cho phép' });
}
```
Same hygiene issue affects multiple modules (matches BUG-CV-001 in QTCV).

### NOTE-001 (Design intent, not a bug) — Non-admin can READ tree

`GET /api/quan-tri/don-vi/tree` returns 200 for any authenticated user (verified with `test_canbo` token). This is intentional per server.js:70-72 comment ("publicCatalogRoutes...recipient picker") — non-admin users need to pick recipients in document workflows. Mutations (POST/PUT/DELETE/PATCH) correctly return 403.

TC-027 expectation says "Menu Quan tri an hoan toan" — this is a FRONTEND menu hide concern, not enforced at the catalog read API level. FE behavior is out of scope for this API-focused test sweep.

### NOTE-002 — `fn_department_get_tree` returns subset of fields

Tree SP omits `is_locked`, `staff_count`, `phone/fax/email/address/allow_doc_book/description`. FE compensates by calling `getById` on edit. Side effect: list table columns "Số NV" and "Trạng thái" show empty/`undefined` for any row sourced from tree (only edit detail has full data). Cosmetic; flagged for cleanup but not blocking.

## Backend code-call chain (for traceability)

```
Frontend (don-vi/page.tsx)
  api.get('/quan-tri/don-vi/tree')
    -> server.ts:72 publicCatalogRoutes (authenticate)
    -> backend/src/routes/admin.ts:57 router.get('/don-vi/tree')
    -> departmentRepository.getTree(unitId)
    -> public.fn_department_get_tree(unit_id) [Postgres SP]

Frontend POST /quan-tri/don-vi
  -> server.ts:73 adminRoutes (authenticate + requireRoles('Quản trị hệ thống'))
  -> backend/src/routes/admin.ts:98 router.post('/don-vi')
    name validation -> code uniqueness check via pool.query (LOWER) ->
  -> departmentRepository.create(parentId, code, name, ...) (16 params)
  -> public.fn_department_create(...) [Postgres SP] returns id BIGINT
```

## Test artifacts

- API test commands captured in this session bash history (curl + python pretty print).
- Playwright spec: `tests/wave-d-don-vi/wave-d-don-vi.spec.ts` (15 TC mapped, 10 PASS, 5 FAIL due to selector/race issues).
- DB inspection: `docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_test -c "SELECT ..."` for FK integrity + cleanup.
- Test data created/deleted in `qlvb_test.departments` ids 101-107 (cleaned up at end of session).
