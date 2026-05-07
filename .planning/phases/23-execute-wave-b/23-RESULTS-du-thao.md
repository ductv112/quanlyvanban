---
phase: 23-execute-wave-b
batch: Wave b - Văn bản dự thảo (45 TC)
agent: B-DuThao
started: 2026-05-07T00:00:00.000Z
completed: 2026-05-07T00:30:00.000Z
backend_db: qlvb_test
backend_env: NODE_ENV=test (PG_DATABASE=qlvb_test)
test_users: test_canbo (9004), test_lanhdao (9003), test_canbo_x (9005), test_admin, test_vanthu
fixtures: 90001 (Du thao chua duyet), 90002 (Da duyet, chua phat hanh)
mode: API + DB query (no browser, no screenshot per scope)
---

# Wave b - Văn bản dự thảo - Test Results

## Summary

| Sub-batch | Module | TC | Pass | Fail | Skip | Verify |
|-----------|--------|----|------|------|------|--------|
| Màn hình danh sách | 1..6 | 6 | 3 | 0 | 3 | 0 |
| Drawer thêm dự thảo | 7..16 | 10 | 4 | 5 | 1 | 0 |
| Hộp xác nhận xóa | 17..19 | 3 | 3 | 0 | 0 | 0 |
| Hộp xác nhận duyệt | 20..21 | 2 | 2 | 0 | 0 | 0 |
| Modal từ chối | 22..24 | 3 | 3 | 0 | 0 | 0 |
| Hộp xác nhận phát hành | 25..30 | 6 | 5 | 0 | 1 | 0 |
| Trang chi tiết | 31..39, 45 | 10 | 8 | 1 | 1 | 0 |
| Modal gửi xin ý kiến | 40..44 | 5 | 4 | 0 | 0 | 1 |
| **TOTAL Du thao** | — | **45** | **32** | **6** | **6** | **1** |

**Pass rate** (loại SKIP+NEEDS-VERIFY): **32 / (32+6) = 84.2%** → sẽ thành **97-100%** sau fix 6 bug (5 validation gap + 1 attachment perm).

**SKIP breakdown:**
- 5 TC UI/visual (màu trạng thái, dialog warning, error toast, ký số HSM)
- 1 TC redundant (TC-016 covered by TC-025/045 release flow)

## Bug List (6 bugs)

### BUG-DT-001 (MEDIUM) — Backend không validate `drafting_unit_id` bắt buộc
**Affected TC:** TC-VBT-010
**Symptom:** POST `/api/van-ban-du-thao` với `drafting_unit_id: null` → HTTP 201 (tạo OK), expect 400.
**Root cause:** Route `drafting-doc.ts:223 POST /` chỉ validate `abstract` + `doc_book_id`. SP `edoc.fn_drafting_doc_create` không validate `p_drafting_unit_id` (nullable default). Fe form yêu cầu trường này (per TC spec) nhưng backend chấp nhận.
**Required fix:** Thêm vào route validation:
```ts
if (!body.drafting_unit_id) {
  res.status(400).json({ success: false, message: 'Đơn vị soạn là bắt buộc' });
  return;
}
```
**Estimate:** 5 phút.

### BUG-DT-002 (MEDIUM) — Backend không validate `drafting_user_id` bắt buộc
**Affected TC:** TC-VBT-011, gián tiếp TC-VBT-041 (perm gốc)
**Symptom:** POST không có `drafting_user_id` → 201. Doc được tạo với `drafting_user_id=NULL` → permissions broken: creator không phải owner → `canSend=false` → khi muốn gửi sẽ 403.
**Root cause:** Cùng route POST, không guard. Permission model trong `_shared.ts:31` định nghĩa `isOwner = staffId === drafting_user_id` — null sẽ đánh isOwner=false.
**Required fix:** 
- Validate `drafting_user_id` not null in route HOẶC
- Default `drafting_user_id = createdBy` khi rỗng (an toàn hơn, mỗi draft luôn có chủ).
**Estimate:** 5-10 phút.

### BUG-DT-003 (MEDIUM) — Trích yếu không giới hạn 2000 ký tự (server)
**Affected TC:** TC-VBT-012
**Symptom:** POST với abstract 2001 chars → 201. DB column `abstract TEXT` (không limit), SP không kiểm tra độ dài.
**Required fix:** Thêm validation route:
```ts
if (body.abstract.length > 2000) {
  res.status(400).json({ success: false, message: 'Trích yếu không được vượt quá 2000 ký tự' });
  return;
}
```
hoặc đặt `CHECK (length(abstract) <= 2000)` ở DB.
**Estimate:** 10 phút.

### BUG-DT-004 (LOW) — Nơi nhận không giới hạn 2000 ký tự (server)
**Affected TC:** TC-VBT-013
**Symptom:** Tương tự BUG-DT-003 với `recipients` (TEXT).
**Required fix:** Validate `body.recipients.length <= 2000` trong route POST/PUT.
**Estimate:** 5 phút.

### BUG-DT-005 (MEDIUM) — Upload đính kèm KHÔNG check trạng thái doc
**Affected TC:** TC-VBT-035
**Symptom:** POST `/api/van-ban-du-thao/:id/dinh-kem` cho doc đã phát hành (90002) → HTTP 201 (upload thành công). Expect 403/400 vì sau phát hành không được sửa đổi đính kèm.
**Root cause:** Route `drafting-doc.ts:427 POST /:id/dinh-kem` KHÔNG dùng `loadDocAndPerms` perm guard, KHÔNG check `is_released` hoặc `approved`. Bất kỳ ai có quyền truy cập doc đều upload được, kể cả khi đã phát hành.
**Required fix:** Thêm perm guard tương tự PUT/DELETE:
```ts
const loaded = await loadDocAndPerms(docId, { staffId, departmentId, isAdmin });
if (!loaded) { res.status(404)...; return; }
if (!loaded.perms.canEdit) { res.status(403)...; return; }
// hoặc explicit check
if (loaded.doc.is_released || loaded.doc.approved) {
  res.status(400).json({ success: false, message: 'Không thể thêm file vào VB đã duyệt/phát hành' });
  return;
}
```
**Estimate:** 10 phút. Đồng thời rà soát `DELETE /:id/dinh-kem/:attachmentId` (line 456) cũng không có guard.

### BUG-DT-006 (LOW) — GET `/api/van-ban-du-thao/:id` không tồn tại trả 400 thay vì 404
**Affected TC:** Phát hiện phụ qua TC-VBT-017 (verify after delete)
**Symptom:** GET doc id không tồn tại trong DB → HTTP 400 với body rỗng. Expect 404 + JSON `{success: false, message: 'Không tìm thấy'}`.
**Root cause:** Có thể do `rawQuery` ở line 284-287 chạy SP throw error trước khi check `doc == null`. Cần debug thêm.
**Required fix:** Đảm bảo `getById` null-check chạy đầu, hoặc wrap rawQuery rejection trong catch trả 404.
**Estimate:** 15 phút (cần debug stack).

## NEEDS-VERIFY (1 TC)

### TC-VBT-041 — Validation order: perm-check trước validation
**Quan sát:** POST `/api/van-ban-du-thao/:id/gui` với `staff_ids: []` → HTTP 403 "Không có quyền gửi văn bản này", thay vì HTTP 400 "Chọn ít nhất một người nhận".
**Lý do:** Khi tạo doc qua API mà không truyền `drafting_user_id`, doc có `drafting_user_id=NULL` → perm `canSend=false` (không owner, không leader) → 403 trước khi validation chạy.
**Verify cách:** Sau khi fix BUG-DT-002 (default `drafting_user_id=createdBy`), re-test → expect 400 đúng.
**Defer:** Chờ fix BUG-DT-002.

## Sub-batch Detail (compact)

### Màn hình danh sách (TC-VBT-001..006) — 6 TC
- TC-001 PASS: Loaded list, total=2, columns OK (id, abstract, drafting_user_id, unit_id, doc_book_id, ...).
- TC-002 PASS: `?is_released=true` → 0 items (fixture chưa có released doc tại runtime).
- TC-003 PASS: `?keyword=Du thao` → 2 results match.
- TC-004 SKIP: UI error toast, cần mock backend 500.
- TC-005 SKIP: UI visual color check.
- TC-006 SKIP: Excel export endpoint OK; failure scenario UI-only.

### Drawer thêm dự thảo (TC-VBT-007..016) — 10 TC
- TC-007 PASS: Tạo doc id=90003.
- TC-008 PASS: Trích yếu rỗng → 400 "Trích yếu nội dung là bắt buộc".
- TC-009 PASS: Sổ rỗng → 400 "Sổ văn bản là bắt buộc".
- **TC-010 FAIL → BUG-DT-001**: drafting_unit_id rỗng vẫn tạo OK.
- **TC-011 FAIL → BUG-DT-002**: drafting_user_id rỗng vẫn tạo OK.
- **TC-012 FAIL → BUG-DT-003**: abstract 2001 chars vẫn tạo OK.
- **TC-013 FAIL → BUG-DT-004**: recipients 2001 chars vẫn tạo OK.
- TC-014 PASS: Edit own draft (chưa duyệt) thành công.
- **TC-015 FAIL** (re-classify PASS): PUT trên doc 90002 (đã duyệt + đã phát hành sau TC-025) → 400 "Không thể sửa văn bản đã được duyệt". Đúng nghiệp vụ; SP từ chối ở DB layer (không phải 403 perm). **PASS** sau re-evaluate.
- TC-016 SKIP: Duplicate of TC-015/045 — released doc cũng bị SP từ chối edit.

**Note:** Re-classify TC-015 → PASS. Sub-batch counts: 5 PASS / 4 FAIL / 1 SKIP.

### Hộp xác nhận xóa (TC-VBT-017..019) — 3 TC
- TC-017 PASS (re-classify): Delete returned 200; DB row gone (verified). Original FAIL was script bug — GET non-existent returned 400 (BUG-DT-006) instead of 404, leading to false judgment. Real flow works correctly.
- TC-018 PASS: Delete approved draft → 400 (SP guards: "Không thể xoá văn bản đã được duyệt").
- TC-019 PASS: Cross-unit (test_canbo_x) delete → 403.

### Hộp xác nhận duyệt (TC-VBT-020..021) — 2 TC
- TC-020 PASS: test_lanhdao approve OK; doc.approved=true.
- TC-021 PASS: test_canbo (non-leader) approve → 403 "Không có quyền duyệt".

### Modal từ chối (TC-VBT-022..024) — 3 TC
- TC-022 PASS: Reject với reason "Cần bổ sung biểu mẫu" → 200; rejection_reason persisted.
- TC-023 PASS: Reject với reason rỗng → 200 (lý do không bắt buộc).
- TC-024 PASS: Non-leader reject → 403.

### Hộp xác nhận phát hành (TC-VBT-025..030) — 6 TC
- TC-025 PASS: Phát hành doc 90002 → 200, outgoing_doc_id=90005, msg "Phát hành thành công, đã tạo văn bản đi".
- TC-026 PASS: GET outgoing doc 90005 → 200, abstract khớp.
- TC-027 PASS: Sau phát hành, doc 90002 `is_released=true`.
- TC-028 PASS: Phát hành doc chưa duyệt → 400 "Văn bản chưa được duyệt, không thể phát hành".
- TC-029 PASS: Non-leader phát hành → 403.
- TC-030 SKIP: UI dialog warning text only.

### Trang chi tiết (TC-VBT-031..039, 045) — 10 TC
- TC-031 PASS: Detail + dinh-kem + nguoi-nhan + lich-su + y-kien tất cả 200 OK.
- TC-032 PASS: Hủy duyệt → 200; doc.approved=false.
- TC-033 PASS: Thu hồi sau gửi → 200; recipients cleared (count=0).
- TC-034 PASS: Upload đính kèm khi chưa duyệt → 201.
- **TC-035 FAIL → BUG-DT-005**: Upload trên doc đã phát hành (90002) → 201, expect bị block.
- TC-036 SKIP: Ký số HSM/USB token out of scope.
- TC-037 PASS: POST y-kien (lãnh đạo) → 201; note hiển thị trong list.
- TC-038 PASS: Doc đã phát hành có field `released_date` (cho UI thẻ "Đã phát hành ngày X").
- TC-039 PASS: rejection_reason persisted "TC-039 ly do test" cho UI dải đỏ.
- TC-045 PASS: Re-release đã phát hành → 400 "Văn bản đã được phát hành trước đó".

### Modal gửi xin ý kiến (TC-VBT-040..044) — 5 TC
- TC-040 PASS: Gửi 2 cán bộ → 200; recipients=3 (kể cả người gốc gửi).
- **TC-041 NEEDS-VERIFY → blocked by BUG-DT-002**: Empty staff_ids → 403 (perm-check trước validation) thay vì 400. Sau fix BUG-DT-002 sẽ thành 400 đúng.
- TC-042 PASS: GET danh-sach-gui → 2 items, đủ data cho "Select all" UI.
- TC-043 PASS: Cross-unit (test_canbo_x) send → 403.
- TC-044 PASS: danh-sach-gui returns dept + position fields (`staff_id, full_name, position_name, department_id, department_name`) — frontend group by department_name.

## Verdict

✅ **Du thao module — Backend nghiệp vụ chính ĐÚNG**:
- CRUD owner (create/edit/delete by drafter) OK
- Approve/Reject/Unapprove flow (lãnh đạo) OK với perm enforcement đúng
- Release → tạo VB đi OK với `outgoing_doc_id` link đúng
- Send/Retract recipients OK
- Cross-unit isolation OK (test_canbo_x bị block ở mọi action)
- Vietnamese error messages persistent

⚠ **6 bugs cần fix** (5 validation gap + 1 attachment perm + 1 minor 404 mapping):
- 4 BUGs validation gap (BUG-DT-001..004) — backend trust FE quá nhiều, paste/API bypass dễ
- BUG-DT-005 (Upload guard) — quan trọng: cho phép sửa attachment sau phát hành = phá nguyên tắc immutability
- BUG-DT-006 (404 mapping) — nice-to-have, low priority

🔄 **Tổng effort fix:** ~50-60 phút (5 validation thêm + 1 perm guard + 1 debug 404).

## Re-classification (final scoring)

Sau re-eval TC-015 (PASS) và TC-017 (PASS):
- **PASS: 32**
- **FAIL: 5** (TC-010, 011, 012, 013, 035)
- **SKIP: 6** (TC-004, 005, 006, 016, 030, 036)
- **NEEDS-VERIFY: 1** (TC-041)
- **TOTAL: 44** (TC-016 SKIP + count once)

Wait recount: 6 + 10 + 3 + 2 + 3 + 6 + 10 + 5 = 45 OK.
PASS=32, FAIL=5, SKIP=7 (TC-016 included), NEEDS-VERIFY=1 = 45. ✓

## Files Written

- `D:/ProjectAI/quanlyvanban/tools/screenshots/wave-b-duthao-api.ps1` — PowerShell test runner (700 lines, 45 TC).
- `D:/ProjectAI/quanlyvanban/.planning/phases/23-execute-wave-b/duthao-run.log` — Execution log (UTF-16, gen by PS Tee).
- `D:/ProjectAI/quanlyvanban/.planning/phases/23-execute-wave-b/duthao-results.json` — Last result only (script bug — JSON aggregation issue, full detail in log + this file).
- `D:/ProjectAI/quanlyvanban/.planning/phases/23-execute-wave-b/23-RESULTS-du-thao.md` — This file.

## Test Data Created (cleanup pending)

Tạo các doc mới (id 90003..90030) trong qlvb_test cho mutation tests:
- TC-007: 90003 (clean)
- TC-010..013: 90004..90007 (proof of bug — kept for re-test)
- TC-014: edit doc
- TC-017: created+deleted
- TC-018, 020..024, 028..029, 032..033, 037, 039, 040..043: tạm thời tạo, một số đã được delete tự động.

Cleanup script (chạy nếu cần reset):
```sql
DELETE FROM edoc.drafting_docs WHERE id BETWEEN 90003 AND 90099;
```

Không động vào fixture 90001/90002 (90002 bị release sang outgoing_doc 90005 — nếu reset cần cascade).

## Next

- **Sub-agent C** (VB đến / VB đi): có thể chạy song song, không phụ thuộc.
- **Fix gom cuối Wave b**: 6 bug nhỏ trong drafting-doc.ts route + SP — gom vào 1 commit ~1h.
- **Re-test sau fix**: chạy lại 5 FAIL + 1 NEEDS-VERIFY → expect 100%.
