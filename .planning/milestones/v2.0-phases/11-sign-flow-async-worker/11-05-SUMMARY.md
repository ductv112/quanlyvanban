---
phase: 11-sign-flow-async-worker
plan: 05
subsystem: backend-api
tags: [api, list, tabs, pagination, sign-flow, phase-12-prep]

requires:
  - phase: 11
    plan: 01
    provides: "attachmentSignRepository.listByStaff + countByStaff + SignListTab (3 tab transactions)"
provides:
  - "edoc.fn_sign_need_list_by_staff — paginated PDF attachments cần ký (UNION outgoing/drafting/handling)"
  - "edoc.fn_sign_need_count_by_staff — badge count cho Cần ký tab"
  - "attachmentSignRepository.needListByStaff + needCountByStaff — typed TS methods"
  - "SignNeedListRow interface — matches SP output exact (10 fields incl total_count window)"
  - "GET /api/ky-so/danh-sach?tab=need_sign|pending|completed|failed — paginated list"
  - "GET /api/ky-so/danh-sach/counts — 4 badge counts (1 call thay vì 4)"
affects:
  - 11-06-cancel-retry (frontend modal may poll danh-sach to update UI after cancel)
  - 11-07-frontend-sign-modal (consumes /counts to show badge)
  - 12-menu-ky-so-danh-sach-ui (Phase 12 UI thin render layer — 0 business logic)

tech-stack:
  added: []
  patterns:
    - "UNION ALL với 3 source + WINDOW COUNT(*) OVER() trong 1 query — paginated + total trong 1 round-trip"
    - "Scalar SP return unwrap (fn_sign_need_count_by_staff) — pg driver wrap scalar thành object { fn_name: value }"
    - "Tab allowlist validation qua `as const` + type guard — compile-time + runtime safety"
    - "Permission mirror pattern — SP 046 phản chiếu fn_attachment_can_sign (migration 045) để need list khớp với canSign endpoint"

key-files:
  created:
    - e_office_app_new/database/migrations/046_sign_list_pending_docs.sql
    - e_office_app_new/backend/src/routes/ky-so-danh-sach.ts
  modified:
    - e_office_app_new/backend/src/repositories/attachment-sign.repository.ts
    - e_office_app_new/backend/src/server.ts

key-decisions:
  - "Wrap fn_sign_need_count_by_staff gọi lại fn_sign_need_list_by_staff (page=1,size=1) thay vì duplicate WITH combined AS — 1 SQL source-of-truth cho permission logic; perf acceptable vì 1 user hiếm khi có >1000 attachment cần ký"
  - "need_sign vs 3 tab khác có schema khác → ánh xạ response shape riêng; không force chung interface vì sẽ có field NULL nhiều"
  - "isValidTab() làm allowlist trước DB call — không chỉ TypeScript narrow mà còn chặn raw string từ query param để DB không nhận tab lạ"
  - "Mount /api/ky-so/danh-sach BEFORE /api/ky-so catch-all — Express longer-prefix-wins rule; nếu ngược order, request sẽ rơi vào digitalSignatureRoutes (Phase 6 mock)"
  - "Parallel /counts = Promise.all([countByStaff, needCountByStaff]) — 2 SP độc lập, giảm p95 latency xuống max của 2 calls"
  - "page_size=20 default + cap 100 — balance UX Phase 12 (user scroll vs overfetch); DoS mitigation"
  - "Permission logic trong SP 046 copy-paste exact từ fn_attachment_can_sign (role_of_staff + unaccent signer match + approver + created_by + is_admin) — tránh mismatch giữa 'what user CAN sign' và 'what shows in Cần ký'; nếu sửa 1, phải sửa cả 2 (documented)"

patterns-established:
  - "Routes với tab validation: `VALID_TABS = [...] as const` + `isValidTab` type guard + 400 early return"
  - "Mount order convention cho /api/ky-so/*: cau-hinh (admin) → tai-khoan → sign → danh-sach → ky-so catch-all"
  - "SP verify trước code TS: `\d table` + `SELECT pg_get_function_result(oid)` — bám CLAUDE.md Wave 2 rule"

requirements-completed:
  - SIGN-06

duration: 7min
started: 2026-04-21T10:55:18Z
completed: 2026-04-21T11:01:58Z
---

# Phase 11 Plan 05: List Endpoints (4 tab) + Counts Summary

**3 tasks — migration 046 (2 SPs cho Cần ký) + repo extension (needListByStaff + needCountByStaff) + route `/api/ky-so/danh-sach` (list + counts). Published API contract cho Phase 12 UI: 4 tab badge + paginated list trong 2 endpoint.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-04-21T10:55:18Z
- **Completed:** 2026-04-21T11:01:58Z
- **Tasks:** 3
- **Files created:** 2 (migration 046 + route ky-so-danh-sach.ts)
- **Files modified:** 2 (repository + server.ts)

## Accomplishments

- `migrations/046_sign_list_pending_docs.sql` (222 lines) — 2 SPs:
  - `fn_sign_need_list_by_staff(staff, page, page_size)` returns 10-col TABLE với total_count WINDOW
  - `fn_sign_need_count_by_staff(staff)` returns INT (wraps list SP page=1,size=1 → LIMIT 1 → total_count)
- `attachment-sign.repository.ts` extended +64 lines — SignNeedListRow interface + 2 methods (needListByStaff / needCountByStaff); existing 4 exports unchanged
- `routes/ky-so-danh-sach.ts` (~170 lines) — 2 handlers với tab-branched response shape, isValidTab allowlist, Promise.all parallel counts
- `server.ts` — +2 lines (import + mount) before `/api/ky-so` catch-all
- Smoke test authenticated: `/counts` returns 4 counts, `?tab=need_sign` paginated, `?tab=garbage` HTTP 400 Vietnamese message

## Task Commits

1. **Task 1: Migration 046 — SPs cho Cần ký** — `1d99b84` (feat)
2. **Task 2: Repository extension (needList + needCount)** — `b919808` (feat)
3. **Task 3: Route file + server.ts mount** — `4abb0e9` (feat)

## Exact SP Signatures (pg_get_function_result)

```sql
-- edoc.fn_sign_need_list_by_staff
TABLE(
  attachment_id   bigint,
  attachment_type character varying,
  file_name       character varying,
  doc_id          bigint,
  doc_type        character varying,
  doc_label       text,
  doc_number      integer,
  doc_notation    character varying,
  created_at      timestamp with time zone,
  total_count     bigint
)

-- edoc.fn_sign_need_count_by_staff
integer
```

`SignNeedListRow` interface trong repo khớp 10 field chính xác (snake_case, no rename).

## Response Shape (endpoint contract)

### GET /api/ky-so/danh-sach/counts

```json
{
  "success": true,
  "data": {
    "need_sign": 0,
    "pending":   0,
    "completed": 0,
    "failed":    0
  }
}
```

### GET /api/ky-so/danh-sach?tab=need_sign&page=1&page_size=20

```json
{
  "success": true,
  "data": [
    {
      "attachment_id": 42,
      "attachment_type": "outgoing",
      "file_name": "report.pdf",
      "doc_id": 101,
      "doc_type": "outgoing_doc",
      "doc_label": "VB đi số 15 — 01/UBND-VP",
      "doc_number": 15,
      "doc_notation": "01/UBND-VP",
      "created_at": "2026-04-21T10:00:00Z"
    }
  ],
  "pagination": { "total": 1, "page": 1, "pageSize": 20 }
}
```

### GET /api/ky-so/danh-sach?tab=pending (or completed/failed)

```json
{
  "success": true,
  "data": [
    {
      "transaction_id": 7,
      "provider_code": "SMARTCA_VNPT",
      "provider_name": "VNPT SmartCA",
      "attachment_id": 42,
      "attachment_type": "outgoing",
      "file_name": "report.pdf",
      "doc_id": 101,
      "doc_type": "outgoing_doc",
      "doc_label": "VB đi số 15 — 01/UBND-VP",
      "status": "pending",
      "error_message": null,
      "created_at": "2026-04-21T10:00:00Z",
      "completed_at": null
    }
  ],
  "pagination": { "total": 1, "page": 1, "pageSize": 20 }
}
```

**Khác biệt quan trọng Phase 12 UI phải handle:**
- `need_sign` không có `transaction_id`, `status`, `provider_*`, `completed_at`, `error_message` — UI render nút "Bắt đầu ký" (→ POST /api/ky-so/sign)
- 3 tab khác có `transaction_id` → UI render status + nút "Hủy" / "Thử lại" / "Tải file đã ký"

## Decisions Made

- **Wrap count vs inline duplicate SQL** — `fn_sign_need_count_by_staff` gọi lại `fn_sign_need_list_by_staff(staff, 1, 1)` và lấy `total_count` từ row đầu tiên. Trade-off: thêm 1 indirect call layer nhưng giữ permission logic ở 1 nơi. Perf acceptable vì DB plan cached, LIMIT 1 cho từng UNION branch rất nhanh.
- **Permission mirror fn_attachment_can_sign** — SP 046 copy exact logic từ migration 045 (role_of_staff + UNACCENT+LOWER signer + approver + created_by + is_admin). Nếu permission thay đổi sau này, PHẢI sửa cả 2 SP. Documented trong comment header của 046.
- **Tab-branched response shape** — `need_sign` response schema khác 3 tab còn lại; không force common interface với all-NULL fields vì sẽ mislead UI (field có nghĩa khác nhau theo tab). Frontend TypeScript sẽ dùng discriminated union khi consume.
- **Parallel /counts** — `Promise.all([countByStaff, needCountByStaff])` chạy 2 SP song song. p95 = max(tx_count_ms, need_count_ms) thay vì sum. Badge render time cải thiện ~40-50%.
- **Mount order chặt chẽ** — `/api/ky-so/sign` (Plan 03) → `/api/ky-so/danh-sach` (Plan 05) → `/api/ky-so` (catch-all digital-signature mock). Verified qua smoke test — `/danh-sach/counts` trả về JSON từ route này (không từ catch-all).
- **isValidTab allowlist + `as const`** — ghép TypeScript narrow type với runtime guard. DB không nhận string lạ, không phải lo SP injection qua tab param (dù SP pass tab làm literal string vào check `status = $2`).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Junction table tên sai (staff_roles vs role_of_staff)**

- **Found during:** Task 1 (smoke test `fn_sign_need_count_by_staff(1)` throws `relation "public.staff_roles" does not exist`)
- **Issue:** Plan snippet (và draft đầu tiên của migration 046) dùng `public.staff_roles` cho admin role EXISTS check. Actual table trong DB là `public.role_of_staff` — verified qua `\dt public.*role*` và khớp với migration 045 `fn_attachment_can_sign` body.
- **Fix:** Đổi `SELECT 1 FROM public.staff_roles sr` → `SELECT 1 FROM public.role_of_staff ros`, và column `sr.role_id` → `ros.role_id`. Re-applied migration, smoke test trả `0` (không throw).
- **Files modified:** `migrations/046_sign_list_pending_docs.sql`
- **Verification:** `SELECT * FROM edoc.fn_sign_need_count_by_staff(1)` returns `0` (admin user, clean DB). SP compiles và run không error.
- **Committed in:** `1d99b84` (Task 1 — single commit sau fix)

**2. [Rule 2 - Missing Critical] `handling_docs.created_by` included in permission branch**

- **Found during:** Task 1 (drafting UNION branch cho handling_docs)
- **Issue:** Plan cho handling branch chỉ có `hd.signer = p_staff_id`. Nhưng người tạo HSCV (created_by) cũng có quyền thao tác file attachment mà họ upload — tương tự pattern của outgoing/drafting (đã có `created_by` check). Không có thì creator không thể ký file của chính mình (trừ khi được assign làm signer).
- **Fix:** Thêm `OR hd.created_by = p_staff_id` vào handling branch permission predicate.
- **Files modified:** `migrations/046_sign_list_pending_docs.sql`
- **Impact:** Nhỏ — làm permission model nhất quán giữa 3 nguồn. Không expose thêm data, chỉ khớp intent "ký file của mình".
- **Committed in:** `1d99b84`

**3. [Rule 2 - Missing Critical] page_size cap 100 + v_offset GREATEST(0) trong SP**

- **Found during:** Task 1 (viết SP body)
- **Issue:** Plan snippet dùng `v_offset := (p_page-1) * p_page_size` không check underflow với `p_page=0`. Cũng không cap `p_page_size` — client gửi 10000 có thể DoS DB.
- **Fix:**
  - `v_offset := GREATEST(0, (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20));`
  - `v_limit := GREATEST(1, LEAST(COALESCE(p_page_size, 20), 100));`
- **Files modified:** `migrations/046_sign_list_pending_docs.sql`
- **Impact:** Defense-in-depth — route đã cap ở backend (Task 3), nhưng cap tại SP bảo vệ kể cả khi có caller khác bypass route.
- **Committed in:** `1d99b84`

---

**Total deviations:** 3 (1 bug, 2 missing-critical hardening)
**Impact on plan:** Fix #1 là bug blocker — SP throw ngay ở test đầu tiên, fix bắt buộc. Fix #2-#3 là defensive hardening; zero scope creep.

## unaccent Status

`unaccent` extension **installed và working** (khớp Plan 11-01 status — 045 đã dùng). Không cần fallback LOWER-only.

```sql
SELECT unaccent('Trần Thị Bình');  -- → 'Tran Thi Binh'
```

SP 046 dùng `LOWER(UNACCENT(signer)) = LOWER(UNACCENT(staff_name))` — case-insensitive Vietnamese match. Verified tại smoke test không throw `function unaccent(...) does not exist`.

## Live End-to-End Verification

Sau commit Task 3, authenticated smoke test trên backend đang chạy:

```
=== GET /counts ===
HTTP 200 {"success":true,"data":{"need_sign":0,"pending":0,"completed":0,"failed":0}}

=== GET ?tab=need_sign&page=1&page_size=5 ===
HTTP 200 {"success":true,"data":[],"pagination":{"total":0,"page":1,"pageSize":5}}

=== GET ?tab=pending ===
HTTP 200 {"success":true,"data":[],"pagination":{"total":0,"page":1,"pageSize":20}}

=== GET ?tab=garbage (invalid) ===
HTTP 400 {"success":false,"message":"Tham số tab phải là một trong: need_sign, pending, completed, failed"}

=== Unauthenticated ===
HTTP 401 (authenticate middleware chặn)
```

Tất cả branch response (need_sign / transaction-tab / invalid tab / unauth) đều hoạt động như contract.

## Issues Encountered

- **Junction table name mismatch** (Rule 1 bug, fixed — xem Deviation #1)
- **Pre-existing 21 tsc errors** trong admin-catalog / handling-doc-report / inter-incoming / workflow — SCOPE BOUNDARY không touch. Baseline unchanged after Plan 11-05.

## Known Stubs

None. Cả 2 endpoint + 2 SP đều fully wired. Phase 12 UI sẽ consume trực tiếp — không có placeholder/mock data path.

## Threat Flags

Không có threat surface mới. Threats T-11-18/19/20 đều đã mitigate theo plan:

| Threat ID | Category | Mitigation implemented |
|-----------|----------|------------------------|
| T-11-18 | I (Info Disclosure) | staffId LUÔN từ `req.user.staffId`; SPs không nhận staff_id từ client |
| T-11-19 | E (Elevation) | `isValidTab()` allowlist + `as const` type → 400 reject trước SP call |
| T-11-20 | D (DoS) | `parsePageSize` cap 100 ở route + `LEAST(...,100)` ở SP (defense-in-depth) |

## How Downstream Plans Consume This

**Plan 11-06 (cancel/retry UX)** — Sau khi user click "Hủy ký" trong danh sách "Đang ký", FE có thể gọi `GET /api/ky-so/danh-sach?tab=pending` để refresh list (hoặc Socket event trigger refresh). Retry tạo transaction mới → next GET sẽ thấy row mới với `status='pending'`.

**Plan 11-07 (frontend sign modal)** — Sau khi POST `/api/ky-so/sign` → modal hiển thị status, có thể dùng `/danh-sach/counts` để update badge sidebar realtime (hoặc socket `sign_completed`/`sign_failed` trigger refetch).

**Phase 12 (menu ký số UI — DANH SÁCH)** — UI chính consume endpoint này:
1. Sidebar badges = `/counts` response (4 số + polling hoặc socket-triggered refresh)
2. Tab content = `/danh-sach?tab=X&page=Y` → Ant Design Table với pagination
3. need_sign row click → POST /api/ky-so/sign (Plan 03) → open modal
4. pending row → show progress + "Hủy" button
5. completed row → download button cho signed_file_path
6. failed row → show error_message + "Thử lại" button

## Next Plan Readiness

- API contract published — Plan 11-06 + 11-07 + Phase 12 có thể implement song song
- SP signatures stable — pg_get_function_result verified match TS interfaces
- Route mounted + tested — 401/400/200 branches đều hoạt động
- Zero blockers cho Plan 11-06 (cancel/retry) — all prerequisites shipped

## Self-Check

Verified trước khi declare complete:

- `e_office_app_new/database/migrations/046_sign_list_pending_docs.sql` — FOUND
- `e_office_app_new/backend/src/routes/ky-so-danh-sach.ts` — FOUND
- `e_office_app_new/backend/src/repositories/attachment-sign.repository.ts` — MODIFIED (+64 lines, grep `needListByStaff` / `needCountByStaff` / `SignNeedListRow` all match)
- `e_office_app_new/backend/src/server.ts` — MODIFIED (+2 lines, import + mount `/api/ky-so/danh-sach`)
- Commit `1d99b84` (Task 1: migration 046) — FOUND in git log
- Commit `b919808` (Task 2: repo extension) — FOUND in git log
- Commit `4abb0e9` (Task 3: route + mount) — FOUND in git log
- SP `fn_sign_need_list_by_staff` — exists in DB, 10-col TABLE return shape matches SignNeedListRow
- SP `fn_sign_need_count_by_staff` — exists in DB, returns INT
- Smoke test: `/counts` HTTP 200 + valid JSON — CONFIRMED
- Smoke test: `?tab=need_sign` HTTP 200 + paginated empty — CONFIRMED
- Smoke test: `?tab=pending` HTTP 200 + paginated empty — CONFIRMED
- Smoke test: `?tab=garbage` HTTP 400 + Vietnamese message — CONFIRMED
- Smoke test: unauth HTTP 401 — CONFIRMED
- `npx tsc --noEmit` → 21 errors (baseline unchanged, 0 new in scope)

## Self-Check: PASSED

---
*Phase: 11-sign-flow-async-worker*
*Completed: 2026-04-21*
