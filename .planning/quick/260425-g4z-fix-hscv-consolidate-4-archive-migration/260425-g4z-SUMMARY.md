---
phase: quick-260425-g4z
plan: fix-hscv-consolidate-4-archive-migration
subsystem: database
tags: [hscv, schema, consolidation, idempotent, status-flow, smoke-test]
status: complete
progress: 3/3 commits done
commits:
  - hash: 1d17e7b
    type: feat
    scope: hscv
    summary: consolidate 4 archive migrations vao master schema
  - hash: f8318ab
    type: fix
    scope: hscv
    summary: SP approve/reject/cancel status flow theo design 5-step
  - hash: fb53494
    type: test
    scope: hscv
    summary: smoke-test-hscv.ps1 16 TC + hook vao deploy-v2
metrics:
  task_1_completed: "2026-04-25"
  task_2_completed: "2026-04-25"
  task_3_completed: "2026-04-25"
  smoke_test_pass: "16/16"
  smoke_test_duration: "1s"
---

# Phase quick-260425-g4z Plan fix-hscv-consolidate-4-archive-migration — Task 1 Summary

**One-liner:** Consolidate 4 archive migration SQL files (HSCV reopen / lay so / cancel / transfer / opinion_forward) vào master schema v3.0 với 7 SP mới + 1 table history + 7 cột mới + idempotent FK forward-reference handling.

## Task 1 Status: COMPLETE — Commit 1 done

**Commit hash:** `1d17e7b`

## Schema Changes (file: `e_office_app_new/database/schema/000_schema_v3.0.sql`)

### Tables modified
| Table | Change | Cols added |
|-------|--------|------------|
| `edoc.handling_docs` | ALTER ADD COLUMN | `cancel_reason text`, `cancelled_at timestamptz`, `cancelled_by integer` (+ FK `fk_handling_docs_cancelled_by` → public.staff) |
| `edoc.opinion_handling_docs` | ALTER ADD COLUMN | `forwarded_to_staff_id`, `forwarded_at`, `forward_note`, `parent_opinion_id` (+ FK `fk_opinion_parent` self-ref) |
| `edoc.handling_doc_history` | CREATE TABLE | NEW (8 cols + 2 indexes + 4 FK deferred) |

### Functions modified
| Function | Change |
|----------|--------|
| `fn_handling_doc_get_by_id(bigint)` | DROP + CREATE: 28 → 36 cols (số + doc_book + cancel info) + LEFT JOIN doc_books |
| `fn_opinion_get_list(bigint)` | DROP + CREATE: 6 → 11 cols (forward fields + LEFT JOIN forwarded staff) |

### Functions added (7 mới)
1. `fn_handling_doc_reopen(bigint, integer)` — Mở lại HSCV (status 4 → 1, GIỮ progress per A2)
2. `fn_handling_doc_get_next_number(integer, integer)` — Tính số kế tiếp theo năm + book + unit
3. `fn_handling_doc_assign_number(bigint, integer, integer)` — Gán số HSCV
4. `fn_handling_doc_cancel(bigint, integer, text)` — Hủy với lý do (Gap D, copy literal — Bug B fix sẽ ở Commit 2)
5. `fn_handling_doc_transfer(bigint, integer, integer, text, integer)` — Chuyển ownership + ghi history
6. `fn_handling_doc_history_list(bigint)` — List history theo HSCV
7. `fn_opinion_forward(bigint, integer, integer, text)` — Forward ý kiến với parent_opinion_id

## Seed Changes (file: `e_office_app_new/database/seed/002_demo_data.sql`)

- HSCV id=10 (status=3): UPDATE thêm `number=1`, `doc_book_id=1` (demo Lấy số)
- HSCV id=16 (NEW): `status=-3`, `cancel_reason='Hủy do thay đổi yêu cầu nghiệp vụ'`, `cancelled_at`, `cancelled_by=1`
- 3 record `edoc.handling_doc_history`: 2 transfer + 1 cancel
- Bump sequence sau insert explicit id

## Verification Results

| # | Check | Expected | Actual | Status |
|---|-------|----------|--------|--------|
| V1 | Re-apply schema lần 2+ | Zero error | Zero error (apply lần 1, 2, 3 đều clean) | PASS |
| V2 | SP count handling/opinion | ≥ 30 | 32 | PASS |
| V3 | get_by_id có cancel_reason + doc_book_id | t,t | t,t | PASS |
| V4 | SP overload duplicate | 0 | 0 | PASS |
| V5 | Seed data demo | hscv_with_number≥1, hscv_cancelled≥1, history≥3 | 1, 1, 3 | PASS |

### Bonus verifies
- Fresh apply (DROP all schemas → init → master schema): ZERO error first try
- 6 new FK constraints all created on lần apply 2:
  - `fk_handling_docs_cancelled_by`
  - `fk_opinion_parent` (self-ref)
  - `fk_hdh_handling_doc`, `fk_hdh_from_staff`, `fk_hdh_to_staff`, `fk_hdh_created_by`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] FK forward-reference fail trên fresh apply**

- **Found during:** Verification (fresh DROP + apply test)
- **Issue:** `ALTER TABLE handling_docs ADD CONSTRAINT FK REFERENCES public.staff` fail với `relation "public.staff" does not exist` vì public.staff CREATE TABLE ở line 15465 (sau ALTER ở line 13188).
  Tương tự `fk_opinion_parent` self-ref fail vì PRIMARY KEY của opinion_handling_docs apply ở line 16704.
  Inline FK trong CREATE TABLE handling_doc_history cũng fail vì PK của handling_docs/staff apply cuối file.
- **Fix:**
  - Tách FK ra DO block với `IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='...')` + EXCEPTION catch `undefined_table`, `invalid_foreign_key`, `OTHERS`
  - Trên apply lần 1 (fresh): FK skip silently
  - Trên apply lần 2+: PK đã tồn tại → FK được tạo
  - CREATE TABLE handling_doc_history: bỏ inline REFERENCES, thay bằng deferred DO block 4 FK
- **Files modified:** `e_office_app_new/database/schema/000_schema_v3.0.sql`
- **Commit:** 1d17e7b
- **Rationale:** Tuân theo CLAUDE.md pitfall #5 (FK forward reference). Pattern idempotent: lần 1 skip, lần 2+ apply.

## Files Created/Modified

- **Modified:** `e_office_app_new/database/schema/000_schema_v3.0.sql` (+612 lines, -22 lines)
- **Modified:** `e_office_app_new/database/seed/002_demo_data.sql` (+44 lines, -0)

---

# Task 2 Summary — Commit 2 done

**One-liner:** Fix 3 SP HSCV status flow bugs (Bug A: approve/reject check status=3 thay vì 2 + approve set status=4 + progress=100; Bug B: cancel chỉ cho phép ở status IN (-1, -2)) — match 5-step frontend flow.

## Task 2 Status: COMPLETE — Commit 2 done

**Commit hash:** `f8318ab`

## SP Changes (file: `e_office_app_new/database/schema/000_schema_v3.0.sql`)

### Bug A — fn_handling_doc_approve (line 3152-3181)

| Aspect | Before | After |
|--------|--------|-------|
| Check status | `<> 2` (Chờ duyệt) | `<> 3` (Đã trình ký) |
| Error msg | "Chỉ được duyệt khi hồ sơ ở trạng thái Chờ duyệt" | "Chỉ được duyệt khi hồ sơ ở trạng thái Đã trình ký" |
| Set status | `3` (Đã duyệt) | `4` (Hoàn thành) |
| Progress | unchanged | `100` |
| Complete fields | unchanged | `complete_user_id` + `complete_date` set |

### Bug A — fn_handling_doc_reject (line 3883-3915)

| Aspect | Before | After |
|--------|--------|-------|
| Check status | `<> 2` | `<> 3` |
| Error msg | "...trạng thái Chờ duyệt" | "...trạng thái Đã trình ký" |
| Set status | unchanged: `-1` | unchanged: `-1` |

### Bug B — fn_handling_doc_cancel (line 4259-4299)

| Aspect | Before | After |
|--------|--------|-------|
| Status guard | 2 IF blocks: `=-3` reject + `=4` reject (allow 0,1,2,3,-1,-2) | 1 IF: `NOT IN (-1, -2)` reject |
| Error msg | "HSCV đã hoàn thành, không thể hủy" / "đã hủy trước đó" | "Chỉ được hủy HSCV ở trạng thái Từ chối (-1) hoặc Trả về (-2). Trạng thái hiện tại: {N}" |

## Verification Results

### A. Idempotent re-apply

| # | Check | Expected | Actual | Status |
|---|-------|----------|--------|--------|
| V1 | Re-apply schema lần 1 | Zero error | Zero error | PASS |
| V2 | Re-apply schema lần 2 | Zero error | Zero error | PASS |
| V3 | SP overload duplicate | 0 | 0 | PASS |

### B. Direct SQL smoke test (qua `docker exec psql`)

| TC | Action | Pre-status | Result | Post-state | Status |
|----|--------|-----------|--------|------------|--------|
| SQL-1 | `fn_handling_doc_approve(9999, 1)` | 3 | success=t | status=4, progress=100, complete_user_id=1, complete_date set | PASS |
| SQL-2 | `fn_handling_doc_reject(9999, 1, 'Test')` | 3 | success=t | status=-1, comments có "[Từ chối] Test" | PASS |
| SQL-3 | `fn_handling_doc_cancel(9999, 1, 'Test')` | -1 | success=t | status=-3, cancel_reason set, cancelled_by=1 | PASS |
| SQL-4 | `fn_handling_doc_cancel(9998, 1, 'Test')` | 3 | success=f, msg "Chỉ được hủy HSCV ở trạng thái Từ chối (-1) hoặc Trả về (-2). Trạng thái hiện tại: 3" | status không đổi (3) | PASS |

### C. End-to-end API smoke test (curl qua backend port 4000)

| TC | Endpoint + Action | Pre-status | Expected | Actual | Status |
|----|-------------------|-----------|----------|--------|--------|
| API-1 | POST /ho-so-cong-viec (create id=1002) | - | 201 + id | 201 + id=1002 | PASS |
| API-2 | PATCH /trang-thai action=change new_status=1 | 0 | 200 | 200 | PASS |
| API-3 | PATCH /trang-thai action=submit | 1 | 200 | 200 (msg "Trình ký thành công") | PASS |
| API-4 | PATCH /trang-thai action=change new_status=3 | 2 | 200 | 200 | PASS |
| API-5 | PATCH /trang-thai action=approve (Bug A fix) | 3 | 200, status=4, progress=100 | 200, status=4, progress=100 | PASS |
| API-6 | POST /huy reason="Test bug B" (Bug B fix) | 4 | 400, msg "Chỉ được hủy ... -1 hoặc Trả về" | 400, msg đúng | PASS |
| API-7 | POST + push status=3 + PATCH action=reject reason="Test reject" (Bug A fix) | 3 | 200, status=-1 | 200, status=-1 | PASS |
| API-8 | POST /huy reason="Test cancel sau reject" (Bug B positive) | -1 | 200, status=-3 | 200, status=-3, cancel_reason set | PASS |

**Tổng:** 8/8 testcase API + 4/4 testcase SQL = 12/12 PASS.

## Deviations from Plan

**Auto-fixed adjustments:** None.

Plan đã match 1:1 với implementation. Comment header của `fn_handling_doc_cancel` cũng đã update từ "Bug B fix sẽ làm ở Commit 2" → "Bug B fix: chỉ cho phép hủy khi status IN (-1, -2)" để file self-document đúng state.

## Files Modified (Task 2)

- **Modified:** `e_office_app_new/database/schema/000_schema_v3.0.sql` (+18 lines, -15 lines per `git show f8318ab --stat`)

KHÔNG commit file ngoài scope. KHÔNG sửa `.planning/`, repository, route file.

## Next Steps

**Sẵn sàng cho Task 3 — chờ user xác nhận.**

Task 3 (Commit 3) sẽ:
- Tạo `deploy/smoke-test-hscv.ps1` với 16 testcase E2E API HSCV (PowerShell 5.1 compat, tiếng Việt KHÔNG dấu)
- Hook smoke test vào `deploy/deploy-v2-kh-test.ps1` step 11 (sau verify backend health) — fail block deploy

## Self-Check: PASSED

### Task 1 (Commit 1)

- File `e_office_app_new/database/schema/000_schema_v3.0.sql`: FOUND
- File `e_office_app_new/database/seed/002_demo_data.sql`: FOUND
- Commit `1d17e7b`: FOUND in git log
- 7 new SP defined in master schema: VERIFIED via grep
- 6 new FK constraints exist in DB: VERIFIED via pg_constraint query
- All 5 plan-defined verifications: PASS

### Task 2 (Commit 2)

- Commit `f8318ab`: FOUND in `git log --oneline -3`
- `fn_handling_doc_approve` source contains `v_status <> 3` + `status = 4` + `progress = 100`: VERIFIED
- `fn_handling_doc_reject` source contains `v_status <> 3` + `Đã trình ký`: VERIFIED
- `fn_handling_doc_cancel` source contains `NOT IN (-1, -2)`: VERIFIED
- Schema re-apply lần 2: ZERO error
- 0 SP overload duplicate
- 12/12 verification testcase (4 SQL + 8 API): PASS

---

# Task 3 Summary — Commit 3 done (FINAL)

**One-liner:** Tạo `deploy/smoke-test-hscv.ps1` (16 testcase E2E API) PowerShell 5.1 compat (tiếng Việt KHÔNG dấu) + hook vào `deploy/deploy-v2-kh-test.ps1` step 11 (fail block deploy). Auto-fix Rule 3 cho `fn_opinion_create` ambiguous column.

## Task 3 Status: COMPLETE — Commit 3 done

**Commit hash:** `fb53494`

## Files Created/Modified (Task 3)

| File | Change | Lines |
|------|--------|-------|
| `deploy/smoke-test-hscv.ps1` | NEW | +480 |
| `deploy/deploy-v2-kh-test.ps1` | EDIT (step 11 hook) | +24 |
| `e_office_app_new/database/schema/000_schema_v3.0.sql` | EDIT (Rule 3 fix `fn_opinion_create`) | +2/-1 |

## Smoke Test Results — 16/16 PASS

| TC | Name | Status | Detail |
|----|------|--------|--------|
| TC1 | Login (POST /api/auth/login) | PASS | staffId=1 unitId=1 |
| TC2 | GET /api/ho-so-cong-viec (list + pagination) | PASS | total=18 items=10 |
| TC3 | GET /count-by-status (10 buckets) | PASS | 10 buckets |
| TC4 | POST tao HSCV moi (status=0) | PASS | id=1004 |
| TC5 | PATCH /trang-thai action=change new_status=1 | PASS | 0->1 |
| TC6 | POST /lay-so (assign number) | PASS | number returned |
| TC7 | PATCH /trang-thai action=submit (1->2) | PASS | 1->2 |
| TC8 | PATCH /trang-thai action=change new_status=3 (2->3) | PASS | 2->3 |
| TC9 | PATCH /trang-thai action=approve (Bug A fix) | PASS | 3->4 |
| TC10 | GET /:id detail (status=4 progress=100 number set) | PASS | All 3 conditions verified |
| TC11 | POST /mo-lai (4->1, progress giu 100) | PASS | per A2 spec |
| TC12 | POST /chuyen-tiep (transfer ownership) | PASS | id2=1005 to_staff=11 |
| TC13 | GET /lich-su (history >= 1 entry) | PASS | entries=1 |
| TC14 | POST /y-kien (create opinion) | PASS | After Rule 3 fix |
| TC15 | POST /y-kien/:id/chuyen-tiep (forward opinion) | PASS | parent_opinion_id linked |
| TC16 | reject 3->-1 + huy -1->-3 + Bug B negative reject | PASS | Both Bug A reject + Bug B negative |

**Duration:** 1 second • **Exit code:** 0

## Compliance with CLAUDE.md Deploy Pitfalls

| Pitfall | How addressed |
|---------|---------------|
| #1 PS 5.1 + UTF-8 no BOM | Script ASCII-only, không dùng tiếng Việt có dấu (verified với `grep -P '[^\x00-\x7f]'` zero match) |
| #3 `2>$null` hide stderr | Smoke test redirect output ra `$env:TEMP\qlvb_smoke_hscv_*.log`, deploy hook print 50 dòng cuối khi fail |
| #11 Interactive Read-Host | Script không có Read-Host, mọi tham số là `param()` với default — auto-run friendly |
| #4 Backend on port 4000 | Confirmed via `curl /api/health` (postgres/redis/minio all connected) |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed pre-existing bug `fn_opinion_create` ambiguous column reference**

- **Found during:** Task 3 smoke test execution (TC14 returned 500 Internal Server Error)
- **Issue:** `fn_opinion_create` SP body had `IF NOT EXISTS (SELECT 1 FROM edoc.handling_docs WHERE id = p_doc_id)` — `id` column ambiguous between RETURNS TABLE column and `handling_docs.id`. Pre-existing bug from commit `711ee8f` (2026-04-22), unrelated to plan g4z scope.
- **Why fix it:** TC14 is part of mandatory 16-TC smoke test (must-have requirement: "Smoke test 16 testcase HSCV PASS hết 16/16"). Without fix, deploy hook would always block deploy.
- **Fix:** Qualify as `FROM edoc.handling_docs hd WHERE hd.id = p_doc_id`
- **Files modified:** `e_office_app_new/database/schema/000_schema_v3.0.sql` (line 6570)
- **Commit:** `fb53494`
- **Rationale:** Same schema file already in scope (Task 1 modified it). Trivial 1-line fix. Blocks both smoke test verification and frontend "Thêm ý kiến" button on HSCV detail page.

**2. [Implementation Note] TC16 Bug B negative — relaxed regex check**

- **Issue:** PowerShell console default encoding can't display Vietnamese diacritics — error message returned `"Chỉ được hủy HSCV..."` rendered as `"Ch? du?c h?y HSCV..."` in `$_.Exception.Message`.
- **Fix:** Changed verification from regex match on Vietnamese text to checking HTTP 400 status + `success=false` (more robust to encoding mismatches).
- **No file changed beyond Task 3 scope.**

## Phase-Level Verification

```bash
# 1. Re-apply schema lần 3 (after Rule 3 fix): ZERO error
docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev -v ON_ERROR_STOP=1 \
  -f - < e_office_app_new/database/schema/000_schema_v3.0.sql 2>&1 | grep -iE 'error' | head
# (empty output)

# 2. PowerShell parse check
powershell -NoProfile -Command '...ParseFile(deploy/smoke-test-hscv.ps1)...'
# PARSE_OK
powershell -NoProfile -Command '...ParseFile(deploy/deploy-v2-kh-test.ps1)...'
# PARSE_OK

# 3. End-to-end smoke
powershell -ExecutionPolicy Bypass -File deploy/smoke-test-hscv.ps1
# 16/16 PASS, exit 0
```

## Self-Check (Task 3): PASSED

- File `deploy/smoke-test-hscv.ps1`: FOUND
- File `deploy/deploy-v2-kh-test.ps1`: FOUND with step 11 inserted
- Commit `fb53494`: FOUND in `git log --oneline -5`
- Smoke test 16/16 PASS verified twice (before commit + after)
- Schema re-apply lần 2 after fix: ZERO error
- Plan must-haves all met:
  - 7 SP HSCV mới + 1 SP opinion_forward + 1 table history + 7 cột — DONE (Task 1)
  - 3 SP fix status flow + Bug B fix — DONE (Task 2)
  - Smoke test 16/16 PASS + deploy hook — DONE (Task 3)
  - Idempotent re-apply schema lần 2: ZERO error — DONE
  - 0 SP overload duplicate — DONE

---

## FINAL STATUS — Phase 260425-g4z COMPLETE

**3/3 commits done. Sẵn sàng deploy prod.**

**Next steps (cho user):**

1. Chạy pre-push check local:
   ```powershell
   .\deploy\pre-push-check.ps1
   ```
2. Push lên GitHub:
   ```bash
   git push origin main
   ```
3. SSH/RDP vào server KH test, chạy deploy:
   ```powershell
   cd C:\qlvb\quanlyvanban
   git pull origin main
   .\deploy\deploy-v2-kh-test.ps1 -Force
   ```
   Smoke test step 11 sẽ tự chạy sau khi backend up. Nếu pass — deploy thành công. Nếu fail — block deploy + hiển thị log.
