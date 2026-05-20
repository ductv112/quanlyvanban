# Wave g — Permission Tests (50 TC)

**Date:** 2026-05-07
**Scope:** Cross-unit Isolation (15) + Role Matrix (30) + Token & Session (5)
**Tester:** Claude (automated via Python urllib + curl pattern)
**Backend:** http://localhost:4000 (qlvb_test)
**Test users:** admin, test_admin, test_vanthu (unit 2), test_lanhdao (unit 2), test_canbo (unit 2 dept 2), test_canbo_x (unit 3 dept 3)

## Summary

| Bucket | TC | PASS | FAIL | SKIP | VERIFY |
|---|---|---|---|---|---|
| Cross-unit Isolation | 15 | 7 | 3 | 1 | 4 |
| Role Matrix | 30 | 14 | 7 | 5 | 4 |
| Token & Session | 5 | 4 | 1 | 0 | 0 |
| **Total** | **50** | **25** | **11** | **6** | **8** |

**Pass rate (excluding SKIP):** 25 / 44 = **57%** — significant RBAC + multi-tenancy gaps.

After re-validation (see `## False positives flagged then dismissed` below), 3 of the 11 FAILs were re-classified as PASS (intentional public picker endpoint). Net: **22 PASS / 8 FAIL** of executed TCs.

## Bugs found (8 unique, after dedup)

| ID | Sev | TC | Description |
|---|---|---|---|
| **BUG-PERM-001** | **HIGH** | XU-002, XU-003 | `GET /api/van-ban-den/:id` does NOT enforce `unit_id` ownership. canbo_x (unit 3) successfully reads full payload of doc id=90001 (unit 2) — abstract, attachments meta, doc_book, signer, all fields. PUT/DELETE on the same doc correctly return 403 — only the GET is broken. Same family as Wave c BUG-HSCV-001. |
| **BUG-PERM-002** | **HIGH** | XU-008 | `POST /api/van-ban-den` does NOT validate that submitted `doc_book_id` belongs to caller's unit. canbo_x (unit 3) created VB id=90008 using unit 2's `doc_book_id=4`. Tampering exploit — server-side cross-unit FK guard missing. |
| **BUG-PERM-003** | **HIGH** | RM-006 | `POST /api/van-ban-den` has NO role guard. Cán bộ thường (test_canbo) created VB id=90009 successfully — per HDSD only Văn thư + Admin should be able to create incoming docs. Mount line `app.use('/api/van-ban-den', authenticate, …)` is missing `requireRoles('Văn thư', 'Quản trị hệ thống')`. |
| **BUG-PERM-004** | **HIGH** | RM-026 | `DELETE /api/van-ban-den/:id` has NO role guard. Lãnh đạo (test_lanhdao) successfully DELETEd a VB (HTTP 200). Per HDSD only Văn thư + Admin can delete. Cán bộ subsequent DELETE got 404 (already deleted by lãnh đạo). |
| **BUG-PERM-005** | medium | RM-010 | `POST /api/ky-so/sign` only requires `authenticate` — no `requireRoles('Ban Lãnh đạo', 'Quản trị hệ thống')`. Văn thư reaches business-logic layer (HTTP 400 "missing fields") instead of being blocked at RBAC layer (HTTP 403). Defense-in-depth concern: anyone with JWT can attempt sign. |
| **BUG-PERM-006** | medium | (RM-015 side-effect) | `GET /api/ky-so/tai-khoan-ca-nhan` returns **HTTP 500 `invalid input syntax for type bigint: "NaN"`**. Route `/api/ky-so/tai-khoan/:id` swallows the literal segment `ca-nhan` as `:id`. Frontend or HDSD references the path `/ky-so/tai-khoan-ca-nhan`, which doesn't exist server-side (real endpoint is `/api/ky-so/tai-khoan` singular). Same shape as Wave c BUG-HSCV-002. |
| **BUG-PERM-007** | medium | RM-019, RM-020 | `GET /api/ho-so-cong-viec/bao-cao` returns **HTTP 500 `invalid input syntax for type bigint: "NaN"`**. Same root cause: `/api/ho-so-cong-viec/:id` parses "bao-cao" as bigint id. Route ordering bug — HSCV report endpoint either missing or shadowed by `:id`. |
| **BUG-PERM-008** | **HIGH** | TK-005 | **Refresh token rotation is broken**. After a successful `POST /api/auth/refresh`, the OLD refresh-token cookie is STILL accepted on a 2nd `/refresh` call (also HTTP 200 with new tokens). Per CLAUDE.md auth design, refresh tokens must be single-use (rotation). Currently any leaked refresh token can be re-used indefinitely until 7d expiry. Compare CLAUDE.md "Token rotation on refresh (old token revoked, new token issued)" — implementation does not match design. |

## Tests passed (notable)

- **Cross-unit list filtering** (XU-001, XU-004, XU-007, XU-009, XU-014): list endpoints correctly scope by unit_id from JWT.
- **Cross-unit write protection** (XU-011, XU-012): PUT/DELETE on cross-unit resources correctly return 403.
- **Admin gating on real admin endpoints** (RM-011, RM-012, RM-013, RM-014, RM-017, RM-025): vanthu/lanhdao/canbo all blocked from `/quan-tri/nhom-quyen`, `/quan-tri/quyen`, `/quan-tri/chuc-vu`, `/quan-tri/don-vi/:id` PUT, `/quan-tri/nguoi-dung/:id/reset-password`, `/quan-tri/nguoi-dung/:id/nhom-quyen`, `/ky-so/cau-hinh`.
- **Admin multi-role union** (RM-021): admin user with `['Ban Lãnh đạo','Quản trị hệ thống']` can call BOTH admin and signing endpoints.
- **JWT token security** (TK-001, TK-002, TK-003): missing/expired/tampered tokens all rejected with 401. HS256 signature verification works.
- **Refresh after logout** (TK-004): refresh token correctly revoked on logout.

## False positives flagged then dismissed

These initial FAILs were re-validated and confirmed as **intended behavior**:

- **RM-001/002/003** (cán bộ/văn thư/lãnh đạo accessing `/api/quan-tri/nguoi-dung`): this endpoint is intentionally a **public recipient picker** mounted before the admin guard via `routes/public-catalog.ts`. It auto-scopes by caller's `unit_id` (line 131-132) and returns only `id, full_name, unit_id, department_id, position_id` — no sensitive fields. Real admin user-management endpoints (`POST/PUT/DELETE /nguoi-dung`, GET `/nhom-quyen`, etc.) ARE properly gated and DO return 403 to non-admin roles (verified separately).
- **RM-024** (cán bộ accessing `/quan-tri/nguoi-dung`): same as above.
- **XU-006** (vanthu reading `/api/quan-tri/don-vi`): by design — public catalog endpoint exposes don-vi tree to all authenticated users for picker UX.
- **XU-013** (admin sees both unit 2 and unit 3): admin/parent-unit hierarchical visibility — by design (`isAdmin=true` skips unit scope).

## Skipped (require fixtures or destructive setup)

- XU-015 (LGSP cross-unit send/receive): requires multi-step LGSP scenario.
- RM-018 (HSCV chủ trì vs tham gia): requires fixture with 2 staff in same unit.
- RM-022 (role removed mid-session): destructive (would mutate test_canbo).
- RM-023 (account locked mid-session): destructive.
- RM-029 (Trưởng phòng giao việc): no Trưởng phòng role fixture.
- RM-030 (`is_represent_unit` user): no such fixture.

## Verify (manual review)

- XU-005 (cross-department isolation within same unit): canbo dept 2 sees 2 HSCV — needs cross-dept scenario fixture to assert what's hidden.
- XU-010 (loại VB shared vs unit-specific): canbo_x got 0 doc types (HTTP 403) — separate access issue, not the test's intent.
- RM-027/028 (delete published VB rejected): VB id=90100 not in fixture, test inconclusive — needs a fixture with `status='Đã phát hành'`.

## Files

- `_run_tests.py` — 50-TC runner (urllib, login matrix, scope checks, tampering)
- `_results.json` — machine-readable summary

## Cumulative v3.1 status (post Wave g)

| | Wave a | Wave b | Wave c | Wave d | Wave e | Wave f | **Wave g** | Cumulative |
|---|---|---|---|---|---|---|---|---|
| TC | 83 | 181 | 203 | ? | ? | ? | **50** | (see prior wave reports) |
| PASS | 78 | 131 | 154 | — | — | — | **25** | — |
| FAIL | 2 | — | — | — | — | — | **8** (after dedup) | — |
| Bugs | — | — | 9 unique | — | — | — | **8 unique** | — |

## Recommendations (for future fix phase)

1. **Critical (block release):**
   - Add `unit_id` ownership check to `GET /api/van-ban-den/:id` (BUG-PERM-001).
   - Add server-side validation in `POST /api/van-ban-den` that submitted `doc_book_id`, `doc_type_id`, `doc_field_id` belong to caller's unit (BUG-PERM-002).
   - Fix refresh token rotation — invalidate old refresh token on `/refresh` success (BUG-PERM-008).

2. **High priority:**
   - Add `requireRoles('Văn thư', 'Quản trị hệ thống')` to `POST /api/van-ban-den` and `DELETE /api/van-ban-den/:id` (BUG-PERM-003, -004).
   - Add `requireRoles('Ban Lãnh đạo', 'Quản trị hệ thống')` to `POST /api/ky-so/sign` for defense-in-depth (BUG-PERM-005).

3. **Quality of life:**
   - Disambiguate `:id` route catchers — explicit non-numeric route segments (`bao-cao`, `ca-nhan`) must be defined BEFORE `/:id` handler, or guard `:id` with `(\d+)` regex (BUG-PERM-006, -007). Same pattern as Wave c BUG-HSCV-002.
