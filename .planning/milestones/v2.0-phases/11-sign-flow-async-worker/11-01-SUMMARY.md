---
phase: 11-sign-flow-async-worker
plan: 01
subsystem: database
tags: [signing, stored-procedures, attachment-sign, permission-check, pl-pgsql, async-worker]

requires:
  - phase: 08-schema-foundation-pdf-signing-generic-layer
    provides: edoc.sign_transactions table + sign_provider_code/sign_transaction_id columns on 4 attachment_* tables
  - phase: 10-user-config-page-migrate-tab
    provides: staff_signing_config populated (user-level config ready)
provides:
  - "edoc.fn_attachment_finalize_sign — worker finalizes 1/4 attachment tables atomically"
  - "edoc.fn_attachment_can_sign — permission check with UNACCENT+LOWER signer match + admin bypass"
  - "edoc.fn_sign_transaction_list_by_staff — 3-tab list with doc_label + file_name + total_count window"
  - "edoc.fn_sign_transaction_count_by_staff — 3 badge counts"
  - "edoc.attachment_handling_docs: is_ca / ca_date / signed_file_path columns"
  - "backend/src/repositories/attachment-sign.repository.ts — typed methods for 4 SPs"
  - "backend/src/lib/signing/sign-helpers.ts — pure helpers buildSignedObjectKey + isValidAttachmentType + getFileExtension"
affects:
  - 11-02-queue-setup (consumes buildSignedObjectKey + attachmentSignRepository.finalizeSign)
  - 11-03-sign-api (consumes canSign + isValidAttachmentType)
  - 11-04-worker-completion (consumes finalizeSign + buildSignedObjectKey)
  - 11-05-list-endpoint (consumes listByStaff + countByStaff)
  - 12-menu-ky-so-danh-sach-ui (consumes list/count output via REST)

tech-stack:
  added: []
  patterns:
    - "Row interfaces verified via pg_get_function_result() BEFORE writing TypeScript (Wave 2 rule)"
    - "GET DIAGNOSTICS ROW_COUNT (not FOUND) for multi-branch UPDATE affected-row check"
    - "Multi-type attachment SP via IF/ELSIF chain with per-branch v_rows capture"
    - "LEFT JOIN 4 attachment tables + 4 doc tables in single list SP → 1 query for FE"
    - "doc_label composition in PL/pgSQL CASE — human-readable VB số / HSCV label without FE join"

key-files:
  created:
    - e_office_app_new/database/migrations/045_sign_flow_attachment_helpers.sql
    - e_office_app_new/backend/src/repositories/attachment-sign.repository.ts
    - e_office_app_new/backend/src/lib/signing/sign-helpers.ts
  modified:
    - edoc.attachment_handling_docs (ALTER: +is_ca, +ca_date, +signed_file_path)

key-decisions:
  - "GET DIAGNOSTICS ROW_COUNT thay FOUND — `FOUND` là special variable PL/pgSQL, không phải DIAGNOSTICS item; IF/ELSIF branches cần v_rows INT capture riêng"
  - "Permission check bao gồm approver (không chỉ signer) — outgoing/drafting có cả 2 field VARCHAR; cho phép approver cũng ký (match .NET legacy flow)"
  - "Admin bypass kép: role 'Quản trị hệ thống' HOẶC staff.is_admin = TRUE — support cả role-based và flag-based admin"
  - "doc_label tạo trong SP (không để FE compose) — 1 query = 1 row hiển thị, giảm latency Phase 12"
  - "failed tab gộp 3 status (failed+expired+cancelled) — UI user chỉ cần biết 'không thành công', chi tiết lý do ở error_message"
  - "buildSignedObjectKey giữ original key nguyên vẹn (pattern signed/{type}/{txnId}/{basename}) — audit trail + rollback"

patterns-established:
  - "SP Row interface: verify qua pg_get_function_result(oid) TRƯỚC khi viết TS (Wave 2 rule)"
  - "Multi-branch UPDATE SP: GET DIAGNOSTICS ROW_COUNT sau mỗi branch, check tổng ở cuối"
  - "Permission SP trả kèm file_path/file_name để caller skip query thứ 2"
  - "Helper module pure (no I/O) cho unit test dễ dàng downstream"

requirements-completed:
  - SIGN-03
  - SIGN-08
  - ASYNC-05

duration: 5min
started: 2026-04-21T10:09:52Z
completed: 2026-04-21T10:15:40Z
---

# Phase 11 Plan 01: Migration 045 + attachment-sign repo + sign-helpers Summary

**4 sign-flow SPs (finalize / can-sign / list / count) + ALTER attachment_handling_docs + typed repo + pure MinIO key helper — published DB contract for Plans 02-05**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-21T10:09:52Z
- **Completed:** 2026-04-21T10:15:40Z
- **Tasks:** 2
- **Files created:** 3

## Accomplishments

- Migration 045 applied to dev DB — 4 new SPs in `edoc` schema + 3 new columns on `edoc.attachment_handling_docs`
- Row interfaces typed from `pg_get_function_result()` output (zero guesswork)
- Pure helper module in new `lib/signing/` directory for downstream unit tests
- Permission model consolidates signer/approver/created_by/admin in single SP — callers pass only (attachment_id, type, staff_id)
- `doc_label` composed in PL/pgSQL CASE — Phase 12 UI renders tab list with 0 frontend joins

## Task Commits

1. **Task 1: Migration 045 — 4 new SPs + ALTER attachment_handling_docs** — `3fdb239` (feat)
2. **Task 2: Repository + helper module** — `762b5a6` (feat)

## Files Created/Modified

- `e_office_app_new/database/migrations/045_sign_flow_attachment_helpers.sql` — 4 SPs + ALTER (398 lines)
- `e_office_app_new/backend/src/repositories/attachment-sign.repository.ts` — typed repo with CanSignResult / SignTransactionListRow / SignTransactionCounts / SignListTab exports (~140 lines)
- `e_office_app_new/backend/src/lib/signing/sign-helpers.ts` — isValidAttachmentType / buildSignedObjectKey / getFileExtension (~70 lines)
- DB: `edoc.attachment_handling_docs` ALTER (+is_ca BOOLEAN, +ca_date TIMESTAMPTZ, +signed_file_path VARCHAR(1000))

## Exact SP Row Shapes (from pg_get_function_result)

```sql
-- edoc.fn_attachment_finalize_sign
TABLE(success boolean, message text)

-- edoc.fn_attachment_can_sign
TABLE(can_sign boolean, reason text, file_path character varying, file_name character varying)

-- edoc.fn_sign_transaction_list_by_staff
TABLE(
  id bigint, provider_code varchar, provider_name varchar,
  attachment_id bigint, attachment_type varchar, file_name varchar,
  doc_id bigint, doc_type varchar, doc_label text,
  status varchar, error_message text,
  created_at timestamptz, completed_at timestamptz, total_count bigint
)

-- edoc.fn_sign_transaction_count_by_staff
TABLE(pending_count bigint, completed_count bigint, failed_count bigint)
```

TypeScript Row interfaces in `attachment-sign.repository.ts` match these exactly (snake_case, no alias).

## Decisions Made

- **GET DIAGNOSTICS ROW_COUNT over FOUND** — `FOUND` is a PL/pgSQL special variable, not a DIAGNOSTICS item. Discovered when initial migration threw `unrecognized GET DIAGNOSTICS item at or near "FOUND"`. Replaced with `DECLARE v_rows INT; ... GET DIAGNOSTICS v_rows = ROW_COUNT;` per branch.
- **Approver included in permission check** — plan mentioned `signer` only, but `outgoing_docs` / `drafting_docs` have both `signer VARCHAR` and `approver VARCHAR`. Added approver check (auto Rule 2 — missing critical). Without this, approvers cannot sign the docs they're supposed to approve, blocking real workflow.
- **Admin bypass via both role name AND is_admin flag** — codebase has `public.roles` where admin role is named "Quản trị hệ thống" (Vietnamese with diacritics), plus `staff.is_admin BOOLEAN` for legacy flag. EXISTS check covers both.
- **handling_docs.signer is INT (not VARCHAR)** — confirmed via `\d edoc.handling_docs`. Separate branch in SP with `v_signer_int INT` comparison, NOT unaccent/lower name match.
- **doc_label composed server-side** — reduces Phase 12 FE to a single `.map()` render with no post-processing joins.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `GET DIAGNOSTICS v_found = FOUND` is invalid PL/pgSQL syntax**

- **Found during:** Task 1 (first migration apply)
- **Issue:** `ERROR:  unrecognized GET DIAGNOSTICS item at or near "FOUND"` — `FOUND` is a special implicit variable in PL/pgSQL, not a DIAGNOSTICS field. Valid DIAGNOSTICS items are `ROW_COUNT`, `RESULT_OID`, `PG_CONTEXT`.
- **Fix:** Changed `DECLARE v_found BOOLEAN; ... GET DIAGNOSTICS v_found = FOUND` → `DECLARE v_rows INT := 0; ... GET DIAGNOSTICS v_rows = ROW_COUNT;` across all 4 IF/ELSIF branches. Final check becomes `IF v_rows = 0 THEN RETURN QUERY SELECT FALSE, 'Không tìm thấy file đính kèm';`.
- **Files modified:** `e_office_app_new/database/migrations/045_sign_flow_attachment_helpers.sql` (fn_attachment_finalize_sign body)
- **Verification:** Re-ran migration — all 4 SPs CREATE FUNCTION success. `SELECT * FROM edoc.fn_attachment_finalize_sign(99999, 'outgoing', 'x', 'Y', 1)` returns `(f, 'Không tìm thấy file đính kèm')` correctly.
- **Committed in:** 3fdb239 (Task 1 commit — single squashed commit after fix)

**2. [Rule 2 - Missing Critical] Approver permission not in plan — added to fn_attachment_can_sign**

- **Found during:** Task 1 (writing fn_attachment_can_sign body)
- **Issue:** Plan only specified signer + created_by + admin check. But `outgoing_docs` and `drafting_docs` have both `signer VARCHAR` AND `approver VARCHAR` fields — in legacy .NET flow, approvers are also authorized to sign. Without approver branch, a trình-ký flow where approver signs would fail with "Bạn không có quyền ký văn bản này".
- **Fix:** Added `OR (v_approver_name IS NOT NULL AND LOWER(unaccent(v_approver_name)) = LOWER(unaccent(v_staff_name)))` to permission predicate for both 'outgoing' and 'drafting' branches.
- **Files modified:** Same migration file (can_sign SP body)
- **Verification:** SP compiles; smoke test with invalid attachment returns correct error.
- **Committed in:** 3fdb239 (Task 1)

**3. [Rule 2 - Missing Critical] Admin flag check added — staff.is_admin as secondary admin source**

- **Found during:** Task 1 (writing admin EXISTS subquery)
- **Issue:** Plan said "has role 'Quản trị hệ thống'". But the codebase also has a legacy `staff.is_admin BOOLEAN` column from pre-role era. Using role alone would deny sign permission for admins who weren't migrated into the role table.
- **Fix:** Combined check: `EXISTS(role_of_staff JOIN roles WHERE name='Quản trị hệ thống') OR COALESCE(s.is_admin, FALSE)`.
- **Files modified:** Same migration file (can_sign SP — v_is_admin assignment)
- **Verification:** SP applies cleanly. Real staff admin check will validate in Plan 03 integration.
- **Committed in:** 3fdb239 (Task 1)

---

**Total deviations:** 3 auto-fixed (1 bug, 2 missing critical)
**Impact on plan:** All fixes are defensive correctness — migration would have thrown at RUN time without fix #1, and permission check would incorrectly deny legitimate users without fixes #2 and #3. Zero scope creep, zero architectural change.

## Issues Encountered

- None beyond the 3 deviations above. All SPs smoke-tested successfully in docker.

## How Downstream Plans Consume This

**Plan 11-02 (queue setup)** — uses `buildSignedObjectKey(originalKey, type, txnId)` when enqueuing a sign job to deterministically compute the MinIO destination key from the job payload.

**Plan 11-03 (sign API)** — uses `attachmentSignRepository.canSign(id, type, staffId)` BEFORE enqueue. `staffId` MUST come from `req.user.staffId` (JWT), NEVER from body — mitigates T-11-01 Tampering. Returns `{can_sign, reason, file_path, file_name}` so the route can immediately fetch the MinIO object without a second query.

**Plan 11-04 (worker completion)** — uses `attachmentSignRepository.finalizeSign({attachmentId, attachmentType, signedFilePath, signProviderCode, signTransactionId})` after embedding the signature and uploading the signed PDF to MinIO. Atomic transition for the attachment row — even if `sign_transactions.complete` also runs in same worker step.

**Plan 11-05 (list endpoint)** — mounts `GET /api/ky-so/danh-sach?tab=pending|completed|failed&page=N&pageSize=M` backed by `attachmentSignRepository.listByStaff(staffId, tab, page, pageSize)`. Badge count endpoint `GET /api/ky-so/counts` uses `countByStaff(staffId)`.

**Phase 12 (menu UX)** — UI reads `SignTransactionListRow[]` and renders `doc_label` as the primary column — no client-side join needed (migration 045 already composed the human-readable "VB đi số 42" / "HSCV: Name" string).

## Unaccent Extension Status

Extension `unaccent` is installed and working:

```sql
SELECT unaccent('Nguyễn Văn Á');  -- → 'Nguyen Van A'
```

No fallback to LOWER-only needed. Vietnamese-case-insensitive signer-name comparison is live.

## Next Plan Readiness

- DB contract published: 4 SPs callable, 3 new columns on handling attachment table
- Repository published: 4 typed methods + 4 interfaces + SignListTab type
- Helper published: 3 pure functions, ready for unit tests
- No blockers for Plan 11-02 (queue setup) — all its prerequisites shipped

## Self-Check

Verified before declaring complete:
- `edoc.fn_attachment_finalize_sign` — exists, 2-col return shape matches repo
- `edoc.fn_attachment_can_sign` — exists, 4-col return shape matches `CanSignResult`
- `edoc.fn_sign_transaction_list_by_staff` — exists, 14-col return matches `SignTransactionListRow`
- `edoc.fn_sign_transaction_count_by_staff` — exists, 3-col return matches `SignTransactionCounts`
- `edoc.attachment_handling_docs` — has is_ca, ca_date, signed_file_path columns
- Smoke test `fn_sign_transaction_count_by_staff(1)` returns `(0, 0, 0)` — OK
- Smoke test `fn_attachment_can_sign(99999, 'incoming', 1)` returns `(f, 'Không được ký số văn bản đến', null, null)` — OK
- `buildSignedObjectKey('documents/outgoing/2026/x.pdf', 'outgoing', 99)` === `'signed/outgoing/99/x.pdf'` — OK

---
*Phase: 11-sign-flow-async-worker*
*Completed: 2026-04-21*
