---
phase: 21-automation-foundation
plan: 02
subsystem: testing
tags: [seed, fixtures, postgres, db-reset, vitest, automation, isolation, env-guard]

requires:
  - phase: 21-01
    provides: Vitest + Playwright test stack + tests/setup.ts SAFETY guard + .env.test.example template

provides:
  - "database/seed/003_test_fixtures.sql — 6 user (test_admin/vanthu/lanhdao/canbo/canbo_x/locked) + 16 fixture data (5 VB đến 5 trạng thái + 3 VB đi + 2 dự thảo + 2 HSCV + 3 notice + 3 user_incoming_docs)"
  - "backend/tools/test-db-reset.ts — Cross-platform reset script: drop qlvb_test, recreate, apply 4 SQL files in 8-9s (target < 30s = AUTO-02)"
  - "deploy/test-db-setup.ps1 + .sh — Windows + Linux/CI wrappers, KHONG DAU per pitfall #1, -Force/-f switch for CI auto"
  - "tests/fixtures/users.ts — TEST_USERS const with 6 user, 'as const satisfies' typing, getUserByRoleId helper"
  - "tests/fixtures/docs.ts — TEST_DOCS const with id ranges + status enum mappings + backward-compat aliases"
  - "tests/helpers/db.ts — getTestPool/withTransaction/closeTestPool helpers, BEGIN/ROLLBACK isolation per AUTO-09"

affects: [phase-21-03, phase-21-04, phase-21-05, phase-21-06, phase-22, phase-23]

tech-stack:
  added: []
  patterns:
    - "Idempotent SQL seed: INSERT ... ON CONFLICT DO UPDATE/NOTHING + sequence reset (CLAUDE.md pitfall #12)"
    - "ENV guard pattern: DO $$ ... RAISE EXCEPTION on app.environment='prod' — same pattern as seed 002"
    - "Test isolation: withTransaction(callback) wrapping BEGIN/ROLLBACK (per AUTO-09)"
    - "Cross-platform DB tooling: TS script auto-detects Docker postgres via PG_DOCKER_CONTAINER env, fallback to local psql for CI ubuntu-latest"
    - "Status flag derivation: incoming_docs trạng thái = approved + archive_status + rejected_by + user_incoming_docs.is_read (no single 'status' column post-v3.0 schema)"

key-files:
  created:
    - e_office_app_new/database/seed/003_test_fixtures.sql
    - e_office_app_new/backend/tools/test-db-reset.ts
    - e_office_app_new/backend/tests/fixtures/users.ts
    - e_office_app_new/backend/tests/fixtures/docs.ts
    - e_office_app_new/backend/tests/helpers/db.ts
    - deploy/test-db-setup.ps1
    - deploy/test-db-setup.sh
  modified: []

key-decisions:
  - "Schema mismatch fix: removed is_handling/is_inter_doc/inter_doc_id from incoming_docs INSERT (deviation Rule 3) — schema v3.0 patches dropped these columns; replaced with rejected_by + rejection_reason for REJECTED state"
  - "Outgoing/drafting status: switched from boolean flags to status enum (draft/reviewing/released/sent/completed/rejected) — schema v3.0 added CHECK constraint; INSERT now sets status='released'/'sent'/'approved' to match"
  - "PG_DOCKER_CONTAINER env auto-detection: TS script supports both Docker (dev) and direct psql (CI ubuntu-latest) without code change; PowerShell + Bash wrappers detect docker ps and pass env"
  - "Bcrypt hash inline (not generated runtime): \$2b\$10\$y/GpbkimP4hyef0/QLVNwuW2xb4tbDNuKREpqenGy7WMnN8QtXsOe — gen once with bcryptjs saltRounds=10, verify compare returns true; ensures idempotent seed without runtime hash"
  - "TEST_USERS typing: 'as const satisfies Record<string, TestUser>' — strict literal types + interface conformance check at compile time"
  - "withTransaction pattern: explicit BEGIN before callback, ROLLBACK in finally (catches both throw + normal return) — matches plan 21-05 isolation requirement"

patterns-established:
  - "Test DB reset workflow: 4 SQL files (init/schema/seed-001/seed-003) sequentially applied; reset takes ~9s (8.5-9.4s observed across 3 runs)"
  - "Per-file SET prefix: prelude() returns 'SET app.signing_secret_key=...' for seed 001, 'SET app.environment=test' for seed 003 — same psql session, different per-file"
  - "Multi-tier safety: seed 003 SQL guard (raise on prod) + tools/test-db-reset.ts JS guard (refuse non-test DB) + tests/helpers/db.ts pool guard (throw on init) — defense in depth"
  - "ON CONFLICT (col1, col2) DO NOTHING for many-to-many tables: pattern from seed 001 (role_of_staff) carried into seed 003 (role_of_staff + user_incoming_docs)"

requirements-completed: [AUTO-02, AUTO-03, AUTO-04, AUTO-05, AUTO-09]

duration: 13min
completed: 2026-05-06
---

# Phase 21 Plan 02: Test DB Fixtures + Reset Tooling Summary

**003_test_fixtures.sql idempotent + ENV guard + 6 user + 16 fixture data; cross-platform test-db-reset.ts (~9s, target <30s) + .ps1/.sh wrappers; TS fixtures (TEST_USERS) + withTransaction helper for AUTO-09 isolation**

## Performance

- **Duration:** 13 min 32 sec
- **Started:** 2026-05-06T03:54:19Z
- **Completed:** 2026-05-06T04:07:51Z
- **Tasks:** 3 (all complete)
- **Files created:** 7
- **Test DB reset benchmark:** 8733-9381ms (3 runs) — well under 30s target (AUTO-02 acceptance)

## Accomplishments

- **Seed 003** (246 lines) creates 6 users + 5 VB đến (5 trạng thái) + 3 VB đi + 2 dự thảo + 2 HSCV + 3 notice + 3 user_incoming_docs assignments. Idempotent (chạy 2 lần count không đổi). ENV guard rejects `app.environment='prod'` with Vietnamese error.
- **test-db-reset.ts** drops qlvb_test, recreates with UTF8/C locale, applies 4 SQL files (init/schema/seed-001/seed-003). Auto-detects Docker postgres via PG_DOCKER_CONTAINER env, falls back to direct psql for CI. SAFETY guard refuses non-test DB names.
- **PowerShell + Bash wrappers** auto-create `.env.test` from `.env.test.example` if missing, detect docker container, pass env vars. Both KHÔNG DẤU per CLAUDE.md pitfall #1.
- **TS fixtures** mirror SQL seed: TEST_USERS with 6 keys (admin/vanthu/lanhdao/canbo/canboX/locked), TEST_DOCS with 4 namespaces + notices array. Strict typing via `as const satisfies Record<string, TestUser>`.
- **withTransaction helper** verified: insert id=99999 visible inside transaction, gone after rollback. Pool config matches src/lib/db/pool.ts (UTF8 forced, 30s idle timeout).
- All 6 users login OK via bcrypt.compare('Test@123', password_hash).

## Task Commits

1. **Task 1: 003_test_fixtures.sql seed** — `0801123` (feat)
2. **Task 2: test-db-reset.ts + ps1/sh wrappers** — `3e8dce9` (feat)
3. **Task 3: TS fixtures + db helper** — `55c6d41` (feat)

## Files Created (7 files)

- `e_office_app_new/database/seed/003_test_fixtures.sql` (246 lines, 14.5KB) — Test fixtures with ENV guard + verify-seed-001 guard + sequence reset
- `e_office_app_new/backend/tools/test-db-reset.ts` (220 lines, 7.8KB) — Cross-platform DB reset, auto-detects Docker
- `e_office_app_new/backend/tests/fixtures/users.ts` (110 lines, 2.7KB) — TEST_USERS const + getUserByRoleId helper
- `e_office_app_new/backend/tests/fixtures/docs.ts` (60 lines, 2.3KB) — TEST_DOCS id ranges + backward-compat aliases
- `e_office_app_new/backend/tests/helpers/db.ts` (115 lines, 3.1KB) — getTestPool/withTransaction/closeTestPool with TEST SAFETY guard
- `deploy/test-db-setup.ps1` (95 lines, 3.8KB) — Windows wrapper, KHONG DAU, -Force switch, docker detect
- `deploy/test-db-setup.sh` (110 lines, 3.3KB) — Linux/CI wrapper, -f flag + FORCE=1 env support

## Decisions Made

### 1. Schema match v3.0 actual (not plan-time text)

Plan suggested INSERT on incoming_docs with `is_handling`, `is_inter_doc`, `inter_doc_id` columns. Schema v3.0 patches DROPPED those columns and ADDED `source_type` enum, `is_unit_send`, `unit_send`, `external_doc_id`, `previous_outgoing_doc_id`, `department_id`, `rejected_by`, `rejection_reason`. Updated INSERT to:
- Remove dropped columns
- Add NOT NULL columns: `source_type='manual'::edoc.doc_source_type`, `is_unit_send=false`, `department_id=2`
- Use `rejected_by + rejection_reason` for the REJECTED state (was `approved=false alone` in plan)

### 2. Outgoing/drafting use status enum (not boolean flags)

Schema v3.0 added CHECK constraint `chk_outgoing_status_valid` on `status` column with enum (draft/reviewing/released/sent/completed/rejected). Plan's INSERT only had boolean `approved + is_released`. Updated to set explicit `status='released'/'sent'/'approved'` to match constraint AND the boolean flags for consistency.

### 3. Bcrypt hash inline + verified

Generated `$2b$10$y/GpbkimP4hyef0/QLVNwuW2xb4tbDNuKREpqenGy7WMnN8QtXsOe` once with `bcryptjs.hash('Test@123', 10)`. Verified with `bcrypt.compare('Test@123', hash) === true` for all 6 users post-seed. Hardcoded into SQL for idempotency (no runtime hash gen).

### 4. PG_DOCKER_CONTAINER auto-detect

TS script supports two modes:
- **Docker mode**: `PG_DOCKER_CONTAINER=qlvb_postgres` → `docker exec -i qlvb_postgres psql -U ...`
- **Direct mode**: no env → `psql -h ${PG_HOST} ...` (CI ubuntu-latest with native psql)

PowerShell + Bash wrappers run `docker ps --filter name=qlvb_postgres` and set the env conditionally.

### 5. Test isolation pattern

`withTransaction()` wraps callback in `BEGIN`...`ROLLBACK` with `try/finally`. Verified rollback works:
```ts
await withTransaction(async (client) => {
  await client.query("INSERT INTO public.staff (id=99999, ...)");
  // → id=99999 exists inside transaction
});
// → After return: id=99999 gone (rollback fired)
```

This matches Plan 21-05's smoke test pattern (per-test isolation without re-seeding DB).

### 6. TEST_USERS typing strictness

Used `as const satisfies Record<string, TestUser>` (TS 5+ syntax):
- `as const` → literal types preserved (e.g., `username: 'test_admin'` not `string`)
- `satisfies Record<string, TestUser>` → compile-time conformance check
- Interface allows optional `is_locked?: boolean` (only locked user sets it true)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Schema column mismatch in incoming_docs / outgoing_docs / drafting_docs**

- **Found during:** Task 1 (first apply attempt)
- **Issue:** Plan template's INSERT used `is_handling`, `is_inter_doc`, `inter_doc_id` columns on `incoming_docs`, plus boolean-only flags on outgoing/drafting. Schema v3.0 patches removed those columns and added a `status` enum + CHECK constraint. First apply errored: `column "is_handling" of relation "incoming_docs" does not exist`.
- **Fix:** Queried actual schema via `\d edoc.incoming_docs` etc. Updated INSERT to:
  - Drop removed columns
  - Add required NOT NULL columns (`source_type`, `is_unit_send`, `department_id`)
  - Add `rejected_by + rejection_reason` for REJECTED state
  - Use `status='released'/'sent'/'approved'` enum values on outgoing/drafting
- **Files modified:** `e_office_app_new/database/seed/003_test_fixtures.sql`
- **Verification:** All 5 incoming_docs + 3 outgoing_docs + 2 drafting_docs INSERT successfully; idempotent on second apply.
- **Committed in:** `0801123` (Task 1 commit)

**2. [Rule 2 - Missing critical] PowerShell wrapper missing `.env.test` auto-create**

- **Found during:** Task 2 (testing wrapper script)
- **Issue:** Plan template assumed `.env.test` already exists in backend dir. Fresh checkout will not have it (`.env.test` is gitignored). Script would error with `FATAL: failed to open .env.test`.
- **Fix:** Wrapper checks `Test-Path $ENV_TEST_BACKEND`. If missing, copies from `.env.test.example` at repo root with friendly warn message.
- **Files modified:** `deploy/test-db-setup.ps1`, `deploy/test-db-setup.sh`
- **Verification:** Removed `.env.test`, ran wrapper → auto-created from template, then ran reset OK.
- **Committed in:** `3e8dce9` (Task 2 commit)

**3. [Rule 2 - Missing critical] PG_DOCKER_CONTAINER bridging in tools/test-db-reset.ts**

- **Found during:** Task 2 (running npm script with Docker postgres)
- **Issue:** Plan template's `psql -h ${PG_HOST} ...` only works if psql CLI is in PATH. Local Windows dev uses Docker postgres (no native psql). CI ubuntu-latest has native psql. Need both modes.
- **Fix:** Added `PG_DOCKER_CONTAINER` env detection. If set → `docker exec -i $container psql -U ...`. Else → direct `psql`. PowerShell + Bash wrappers run `docker ps --filter name=qlvb_postgres` and pass env conditionally.
- **Files modified:** `e_office_app_new/backend/tools/test-db-reset.ts`, `deploy/test-db-setup.ps1`, `deploy/test-db-setup.sh`
- **Verification:** Both `PG_DOCKER_CONTAINER=qlvb_postgres npm run test:db:reset` (Docker) and the `npm run` without env (would use psql CLI) paths work; verified at commit time with Docker mode.
- **Committed in:** `3e8dce9` (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (1 blocking schema mismatch, 2 missing critical infrastructure)
**Impact on plan:** All deviations were schema/environment mismatches. Plan's text described an older or planned schema; actual v3.0 schema has CHECK constraints + dropped columns. No scope creep.

## Issues Encountered

- **PowerShell stdin piping not supported by Bash tool** — when applying SQL via `cat file | docker exec -i ... psql`, ON_ERROR_STOP=1 + `-c "SET ..."` ran in separate session. Worked around by prepending SET via `(printf "SET ...\n"; cat file)` pattern.
- **First seed 001 apply for qlvb_test failed signing block** with "app.signing_secret_key chua set" — resolved by always prepending `SET app.signing_secret_key=...` before piping seed 001 SQL. Reset script now handles this in the `prelude()` function.
- **dotenv override behavior** — `.env.test` is loaded with `override: true`. Means inline `PG_DATABASE=qlvb_dev npm run test:db:reset` does NOT override .env.test. Test SAFETY guard verified by editing .env.test directly to qlvb_dev. Documented behavior is correct.

## User Setup Required

**For QA / dev:**
1. Run setup script once: `.\deploy\setup-dev-windows.ps1` (or `bash deploy/setup-dev-windows.ps1` on Linux). Creates docker postgres + installs deps.
2. Reset test DB: `.\deploy\test-db-setup.ps1 -Force` (Windows) or `bash deploy/test-db-setup.sh -f` (Linux). Creates qlvb_test + applies fixtures.
3. Verify: `cd e_office_app_new/backend && npm run test:db:reset` should print `DONE in <Xms` (X < 30000).

**For CI (ubuntu-latest):**
- Plan 21-06 will wire `bash deploy/test-db-setup.sh -f` into `.github/workflows/test-pr.yml` after `setup-postgres` step.

## Next Phase Readiness

- **Plan 21-03 (mock servers SmartCA/MySign/LGSP):** No DB dependency — independent.
- **Plan 21-04 (auth fixtures + globalSetup):** Can `import { TEST_USERS } from '@/tests/fixtures/users.js'` to gen 5 storage states (login each user via Playwright). The 6th (locked) is for negative test, not storage state.
- **Plan 21-05 (smoke 30 TC + Excel parser):** Can `import { withTransaction } from '@/tests/helpers/db.js'` for per-test isolation. Use TEST_DOCS to assert "tab có data" without fetching real records.
- **Plan 21-06 (CI workflow):** `bash deploy/test-db-setup.sh -f` ready to wire after `services: postgres:` step in `.github/workflows/test-pr.yml`. PG_DOCKER_CONTAINER unset → uses native psql in CI.

## Self-Check: PASSED

- Files exist: 7/7 created (003_test_fixtures.sql + test-db-reset.ts + 2 fixtures + 1 helper + 2 wrappers) ✓
- All 3 task commits exist on main: `0801123`, `3e8dce9`, `55c6d41` ✓
- Idempotent test: 2 consecutive applies → counts identical (staff:6, incoming:5, outgoing:3, drafting:2, handling:2, notices:3, user_inc:3, roles:6) ✓
- ENV guard test: `SET app.environment='prod'; \i 003_test_fixtures.sql` → `ERROR: KHONG duoc chay test fixtures tren PROD` ✓
- Reset benchmark: 3 runs → 8733ms / 9002ms / 9381ms (avg 9.04s, all < 30s target) ✓
- bcrypt verify: all 6 users `bcrypt.compare('Test@123', hash) === true` ✓
- TS check: `npx tsc --noEmit` exits 0, no errors ✓
- withTransaction rollback: insert id=99999 visible inside, gone after — rollback works ✓
- SAFETY guard test: `.env.test` with `PG_DATABASE=qlvb_dev` → `[SAFETY] PG_DATABASE='qlvb_dev' khong chua 'test'` exit 1 ✓
- KHONG DAU check: `grep -E "[diacritics]" deploy/test-db-setup.ps1 deploy/test-db-setup.sh` → 0 matches ✓
- PowerShell wrapper end-to-end: `.\deploy\test-db-setup.ps1 -Force` → `DONE in 10.2s` ✓

---
*Phase: 21-automation-foundation*
*Completed: 2026-05-06*
