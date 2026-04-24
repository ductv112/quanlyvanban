---
phase: 08-schema-foundation-pdf-signing-generic-layer
plan: 02
subsystem: database
tags: [postgres, migration, data-migration, schema-drop, idempotent, dynamic-sql]

# Dependency graph
requires:
  - phase: 08-01
    provides: public.staff_signing_config table (composite PK staff_id+provider_code)
provides:
  - Migration file that drops legacy public.staff.sign_phone after copying data
  - Confirmed-empty legacy sign_phone column removed from production schema
  - Baseline of 0 rows in staff_signing_config (demo DB had no sign_phone data)
affects: [08-03, 08-04, Phase 9 (admin config), Phase 10 (user config page — user must re-verify)]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Atomic DO block migration (PL/pgSQL): INSERT + verify + DROP in single transaction, auto-rollback via RAISE EXCEPTION"
    - "information_schema.columns guard for idempotency before touching legacy column"
    - "EXECUTE dynamic SQL to dodge PL/pgSQL compile-time parse of a column that may not exist on re-runs"
    - "ON CONFLICT DO NOTHING on composite PK (staff_id, provider_code) for race-safe re-run"

key-files:
  created:
    - e_office_app_new/database/migrations/041_migrate_sign_phone.sql
  modified: []

key-decisions:
  - "Keep sign_ca and sign_image in staff table (NOT dropped) — MIG-04 spec only targets sign_phone; sign_ca holds cert data for UI subject display, sign_image holds scanned signature stamp for PDF rendering"
  - "Force is_verified=FALSE on migrated rows — provider contract changed v1.0→v2.0; user must re-verify with real SmartCA/MySign provider in Phase 10"
  - "Hardcode provider_code='SMARTCA_VNPT' for all migrated rows — v1.0 only supported SmartCA, so legacy sign_phone by definition = SmartCA user_id"
  - "Use EXECUTE dynamic SQL (not static) — PL/pgSQL compiles static SELECT at block entry; without dynamic, 2nd run with dropped column would fail parse even though guard would have RETURNed early"
  - "RAISE EXCEPTION on target<source — single guard covers all failure modes (INSERT partial failure, ON CONFLICT blocking expected rows, etc.), plus triggers PL/pgSQL auto-rollback so column never drops on inconsistent state"

patterns-established:
  - "Pattern: Data migration DO block with (1) column-exists guard, (2) source count, (3) dynamic INSERT with ON CONFLICT DO NOTHING, (4) target count verify, (5) RAISE EXCEPTION on mismatch, (6) DROP COLUMN IF EXISTS — safely re-runnable forever"
  - "Pattern: Validate migration correctness via synthetic test — temporarily re-add column, seed, run, verify, clean up — when production DB has 0 source rows (avoids false confidence from no-op run)"

requirements-completed: [MIG-03, MIG-04]

# Metrics
duration: ~10min
completed: 2026-04-21
---

# Phase 8 Plan 2: Migrate staff.sign_phone → staff_signing_config Summary

**Atomic PL/pgSQL migration that copies legacy `public.staff.sign_phone` (v1.0 SmartCA user id) into `public.staff_signing_config` with `provider_code='SMARTCA_VNPT'` then drops the column — idempotent via information_schema guard + dynamic SQL, safe via target-count verify with auto-rollback.**

## Performance

- **Duration:** ~10 min (file creation + 3 DB runs including synthetic correctness test + commit)
- **Started:** 2026-04-21T~06:45Z (after Plan 01 completion at 06:45Z)
- **Completed:** 2026-04-21T~06:55Z
- **Tasks:** 1
- **Files modified:** 1 (`041_migrate_sign_phone.sql`, 92 lines)

## Accomplishments

- Migration 041 created, applied to `qlvb_postgres`, and verified idempotent on re-run
- Production-state outcome: `public.staff.sign_phone` column dropped; `sign_ca` + `sign_image` preserved as spec requires
- Demo DB baseline: 0 rows had `sign_phone` set → 0 rows inserted into `staff_signing_config` (expected — v1.0 shipped with mock signing, no user configured it)
- Synthetic correctness test (temporarily re-added column with 2 seeded rows): migration inserted both into `staff_signing_config` with correct `provider_code='SMARTCA_VNPT'` + `user_id` preserved + `is_verified=FALSE` + dropped column afterwards
- Idempotent re-run test: 2nd execution detected dropped column and skipped entirely (no error, no duplicate work)

## Task Commits

1. **Task 1: Migration 041 (atomic migrate + drop sign_phone)** — `9e39e3b` (feat)

**Plan metadata:** _pending this commit_ (docs: complete plan)

## Files Created/Modified

- `e_office_app_new/database/migrations/041_migrate_sign_phone.sql` — **created** (92 lines)
  - Single `DO $$ ... $$` block with column-exists guard → source count → dynamic INSERT → target count verify → conditional DROP
  - Final `DO` block for confirmation notice

## Decisions Made

- **Use EXECUTE dynamic SQL (not static SELECT/INSERT)**: PL/pgSQL parses static statements at block entry. On the 2nd idempotent run (column already dropped), static `WHERE sign_phone IS NOT NULL` would fail to parse even though the guard returns before executing it — because PL/pgSQL validates the block before running any statement. Dynamic `EXECUTE` skips that validation. Same reasoning applies to the INSERT.
- **`ON CONFLICT (staff_id, provider_code) DO NOTHING`**: Composite PK already enforces uniqueness. The ON CONFLICT is defense-in-depth for the edge case where migration partially ran, was interrupted, then re-run — second INSERT simply no-ops on rows already copied instead of throwing.
- **Target count >= source count check (not equality)**: Allows future-proofness — if an Admin manually seeds `staff_signing_config` via the new API between Plan 01 and this migration, their rows count toward target and the guard still passes. Only fewer-than-source triggers rollback.
- **Preserve `sign_ca` and `sign_image`**: Out of scope per MIG-04. `sign_ca` will be used for display (cert subject from v1.0 cached), `sign_image` for PDF stamp rendering. If dropped prematurely, Phase 11 PDF signer would need to re-fetch from provider on every sign.
- **No backup table before DROP**: Migration file comment documents the mapping; Git history preserves the prior schema. A backup table would linger and accumulate cruft with zero operational value.

## Deviations from Plan

None — plan executed exactly as written. The synthetic correctness test (temporarily add column + seed + run + clean up) was additive verification beyond the plan's `<verify>` block, added because the production DB had 0 eligible source rows and running on 0 rows cannot prove the INSERT path works.

## Issues Encountered

- **Git Bash path rewriting for `docker exec ... -f /tmp/...`**: First attempt `docker exec qlvb_postgres psql ... -f /tmp/041_migrate_sign_phone.sql` was rewritten by MSYS to `C:/Users/Admin/AppData/Local/Temp/041_...` causing psql to fail with "No such file or directory". Wrapped the command in `sh -c "..."` to defer path interpretation to the container's shell. Not a deviation — shell environment friction.

## User Setup Required

None — DB migration applied in development environment. Production rollout (when v2.0 ships) will run the same file via the project's manual migration protocol (user executes in production DB).

## Next Phase Readiness

- **Ready for Plan 08-03 (PDF byte-range helpers)**: Schema foundation fully complete. No column references to `staff.sign_phone` remain anywhere in DB. Downstream code (backend repos, frontend pages) writing against `staff_signing_config` can rely on the new schema as the single source of truth.
- **Plan 10 (User config page) dependency note**: When user opens the Ký số cá nhân tab, existing rows (if any had been migrated) will display as unverified. User must re-enter SmartCA user_id (can be same as before) and run Test connection before sending any sign request. This is intentional — the v1.0 mock signing never actually verified against the provider, so pre-migration rows should not be treated as trustworthy.

## Verification Log

```
# Pre-migration
public.staff.sign_phone   = VARCHAR(20) exists, 0 rows with non-empty value
public.staff_signing_config = empty (0 rows)

# 1st execution
Source: 0 staff có sign_phone non-empty
Inserted 0 rows vào staff_signing_config
Target count (SMARTCA_VNPT): 0
DROP COLUMN public.staff.sign_phone — hoàn tất
Migration 041 HOÀN TẤT: 0 rows migrated

# Post-1st-execution state
\d public.staff: sign_phone GONE, sign_ca + sign_image PRESENT
staff count: 10 (unchanged — no rows modified/deleted)

# 2nd execution (idempotent)
⚠️  Cột staff.sign_phone đã bị drop — skip (idempotent)
(exit 0, no DDL changes)

# Synthetic correctness test
ALTER TABLE public.staff ADD COLUMN sign_phone VARCHAR(20);  -- re-added
UPDATE 2 rows with sample phones (staff id=1,2)
Run migration:
  Source: 2 staff có sign_phone non-empty
  Inserted 2 rows vào staff_signing_config
  Target count (SMARTCA_VNPT): 2
  DROP COLUMN ... hoàn tất
SELECT from staff_signing_config:
  (1, SMARTCA_VNPT, 0987654321, is_verified=FALSE)
  (2, SMARTCA_VNPT, 0912345678, is_verified=FALSE)
DELETE from staff_signing_config WHERE provider_code='SMARTCA_VNPT' (cleanup)
Final idempotent re-run: skip (OK)
```

## Self-Check: PASSED

Verified:
- File `e_office_app_new/database/migrations/041_migrate_sign_phone.sql` exists (92 lines)
- Commit `9e39e3b` exists in git log: `feat(08-02): migrate staff.sign_phone -> staff_signing_config + DROP column`
- `information_schema.columns` query confirms `sign_phone` NOT in `public.staff` (only `sign_ca` + `sign_image` remain among the three legacy columns)
- `public.staff_signing_config` currently has 0 rows (correct post-cleanup baseline for demo DB)
- File content contains: `INSERT INTO public.staff_signing_config`, `ALTER TABLE public.staff DROP COLUMN IF EXISTS sign_phone`, `v_column_exists BOOLEAN`, two `EXECUTE` calls, `RAISE EXCEPTION` guard
- Migration ran to completion on qlvb_postgres (1st run: dropped column; 2nd run: idempotent skip; 3rd synthetic run: inserted 2 rows correctly and dropped)
- `public.staff` row count before (10) == after (10) — no data loss

---
*Phase: 08-schema-foundation-pdf-signing-generic-layer*
*Completed: 2026-04-21*
