---
phase: 08-schema-foundation-pdf-signing-generic-layer
plan: 01
subsystem: database
tags: [postgres, pgcrypto, stored-procedures, signing, schema-migration, bytea-encryption, partial-unique-index]

# Dependency graph
requires:
  - phase: v1.0 (milestone shipped)
    provides: Base schema (public.staff, edoc.* attachment tables, pgcrypto extension)
provides:
  - public.signing_provider_config (admin-level, single-active via partial unique index)
  - public.staff_signing_config (user-level, composite PK multi-provider)
  - edoc.sign_transactions (audit log with 5-state enum + 4 indexes)
  - ALTER attachment_{incoming,outgoing,drafting,handling}_docs (sign_provider_code + sign_transaction_id FK)
  - 15 stored functions covering full CRUD for 3 tables + transaction lifecycle
affects: [08-02, 08-03, 08-04, Phase 9 (admin config), Phase 10 (user config), Phase 11 (sign flow + worker)]

# Tech tracking
tech-stack:
  added: []  # No new deps — pgcrypto was already enabled in 000_full_schema.sql
  patterns:
    - "Partial unique index for single-active constraint (WHERE is_active = TRUE)"
    - "BYTEA client_secret storage — encryption happens Node-side via pgp_sym_encrypt SQL wrapper"
    - "Composite PK (staff_id, provider_code) — user holds config for multiple providers in parallel"
    - "RETURNS TABLE column alias differs from table column to avoid PL/pgSQL ambiguity"
    - "DROP FUNCTION IF EXISTS guard before CREATE OR REPLACE when return type might change"

key-files:
  created:
    - e_office_app_new/database/migrations/040_signing_schema.sql
  modified: []

key-decisions:
  - "attachment_type CHECK extended to include 'handling' — required because plan's ALTER adds sign_transaction_id FK to attachment_handling_docs, so transactions MUST accept this type"
  - "client_secret is BYTEA (not TEXT) — enforces Node-side pgp_sym_encrypt before insert; plaintext never hits the table"
  - "is_active partial unique index instead of trigger-based single-active — simpler, database-level guarantee"
  - "On provider CHECK violation, providers whitelist is hardcoded (SMARTCA_VNPT, MYSIGN_VIETTEL) — adding a 3rd provider requires migration, intentional per milestone scope"
  - "fn_sign_transaction_update_status consolidates failed/expired/cancelled into one SP with enum param — avoids 3 near-identical functions"
  - "fn_staff_signing_config_upsert uses COALESCE for certificate fields — partial update keeps old cert when only user_id changes"

patterns-established:
  - "Pattern: Provider credential table with BYTEA client_secret + pgp_sym_encrypt at boundary"
  - "Pattern: State machine SP (create→set_provider_txn→complete OR update_status→terminal) with guard via WHERE status='pending'"
  - "Pattern: Single migration file containing schema + indexes + comments + SPs (not split per object) — easier to review end-to-end"

requirements-completed: [MIG-01, MIG-02]

# Metrics
duration: ~25min
completed: 2026-04-21
---

# Phase 8 Plan 1: Signing Schema Foundation Summary

**3 PostgreSQL tables (signing_provider_config, staff_signing_config, sign_transactions) with partial unique index for single-active provider, BYTEA encrypted credentials, and 15 stored functions covering provider CRUD, user config CRUD, and full transaction lifecycle (create→complete/fail/expire/cancel)**

## Performance

- **Duration:** ~25 min (Docker Desktop cold start + 2 tasks + E2E testing + 1 auto-fix)
- **Started:** 2026-04-21T06:18Z (approximate — based on STATE.md last_updated)
- **Completed:** 2026-04-21T06:45Z
- **Tasks:** 2
- **Files modified:** 1 (`040_signing_schema.sql`, 581 lines total)

## Accomplishments

- Three production-ready tables with full constraint coverage (CHECK, partial unique index, composite PK, FK cascade rules)
- 15 stored functions tested end-to-end on live qlvb_postgres container (5 provider + 4 staff + 6 transaction)
- BYTEA encryption round-trip verified with pgp_sym_encrypt / pgp_sym_decrypt (migration 040 keeps pgcrypto as hard requirement)
- Migration fully idempotent — verified by 3 consecutive re-runs with zero errors
- Attachment tables (4 total: incoming, outgoing, drafting, handling) now carry `sign_provider_code` + `sign_transaction_id` for audit traceability across provider switches

## Task Commits

Each task was committed atomically:

1. **Task 1: Schema (3 tables + 4 ALTER)** — `293a9f5` (feat)
2. **Task 2: 15 stored functions** — `0a7f401` (feat)

**Plan metadata:** _pending this commit_ (docs: complete plan)

## Files Created/Modified

- `e_office_app_new/database/migrations/040_signing_schema.sql` — **created** (581 lines)
  - Part 1 (lines 1-147): CREATE EXTENSION pgcrypto; 3 CREATE TABLE; 5 CREATE INDEX; 4 ALTER TABLE (adding 2 cols each); COMMENT
  - Part 2 (lines 148-581): 15 CREATE OR REPLACE FUNCTION (plus 1 DROP IF EXISTS guard for increment_retry)

## Decisions Made

- **Use BYTEA for client_secret (not TEXT)**: Forces Node-side encryption via `pgp_sym_encrypt` before INSERT. Prevents accidental plaintext storage even if a developer forgets the wrapper, since the column rejects VARCHAR.
- **Partial unique index `WHERE is_active = TRUE`**: Database-level guarantee of "at most one active provider" — cheaper and more robust than trigger-based logic. `set_active` SP performs UPDATE-all-to-FALSE then UPDATE-one-to-TRUE in atomic transaction boundary (implicit via single statement sequence within SP).
- **Composite PK `(staff_id, provider_code)` instead of surrogate BIGINT**: Natural key communicates intent — one config row per user per provider. User holding configs for both SMARTCA and MYSIGN simultaneously is supported (critical for migration period when Admin switches provider).
- **Extended `chk_sign_transaction_attachment_type` to include `'handling'`** (deviation from plan's initial 3-value list): Plan explicitly ALTERs `attachment_handling_docs` with `sign_transaction_id` FK; without `'handling'` in CHECK, a transaction for an HSCV attachment would be impossible to create.
- **`fn_sign_transaction_update_status` consolidates 3 failure modes into one SP with `p_status` param**: Avoids fn_fail/fn_expire/fn_cancel trio of near-identical functions. Enum validated inside SP.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 — Missing Critical] Added `'handling'` to `chk_sign_transaction_attachment_type` CHECK constraint**
- **Found during:** Task 1 (schema design review while writing SQL)
- **Issue:** Plan body listed `CHECK (attachment_type IN ('incoming','outgoing','drafting'))` but Task 1 also ALTERs `attachment_handling_docs` to add `sign_transaction_id` FK. Without `'handling'` in the allowed enum, any attempt to sign an HSCV (handling doc) attachment would fail with a CHECK violation — contradicting the ALTER statement.
- **Fix:** Added `'handling'` as fourth allowed value in both the table CHECK constraint and in `fn_sign_transaction_create` input validation. Updated comments to reflect "4 loại" instead of "3 loại".
- **Files modified:** `e_office_app_new/database/migrations/040_signing_schema.sql`
- **Verification:** E2E test created a transaction with `attachment_type='handling'` and `provider_code='MYSIGN_VIETTEL'`, successfully transitioned to `cancelled` via update_status.
- **Committed in:** Part of Task 1 (`293a9f5`) and Task 2 (`0a7f401`) commits.

**2. [Rule 1 — Bug] Fixed PL/pgSQL column ambiguity in `fn_sign_transaction_increment_retry`**
- **Found during:** Task 2 verification run
- **Issue:** Initial function definition used `RETURNS TABLE (success BOOLEAN, retry_count INT)` — the TABLE column name `retry_count` collided with the table column `retry_count` inside the `UPDATE ... SET retry_count = retry_count + 1` statement, producing `ERROR: column reference "retry_count" is ambiguous`.
- **Fix:** Renamed return column to `new_retry_count`; aliased the table as `t` in the UPDATE; qualified both references (`t.retry_count = t.retry_count + 1`). Added `DROP FUNCTION IF EXISTS ... (BIGINT)` guard before `CREATE OR REPLACE` because Postgres refuses to change return type of an existing function — required for safe re-runs after the signature change.
- **Files modified:** `e_office_app_new/database/migrations/040_signing_schema.sql`
- **Verification:** E2E test called `fn_sign_transaction_increment_retry(2)` twice — returned `new_retry_count=1` then `=2`. Underlying `edoc.sign_transactions.retry_count` column confirmed incremented.
- **Committed in:** Task 2 (`0a7f401`).

---

**Total deviations:** 2 auto-fixed (1 Rule 2 missing critical coverage, 1 Rule 1 bug)
**Impact on plan:** Both essential. Rule 2 fix was mandatory to honor the plan's own ALTER on `attachment_handling_docs` — without it, the schema would be internally inconsistent. Rule 1 fix was discovered only at runtime and required DROP-then-CREATE pattern to survive a return-type change. No scope creep.

## Issues Encountered

- **Docker Desktop was not running at session start** → Required boot via `"/c/Program Files/Docker/Docker/Docker Desktop.exe"` then polled `docker ps` until engine responded. Postgres container (`qlvb_postgres`) came up healthy in ~30s. Not a deviation — just startup friction.

## User Setup Required

None — no external services or environment variables required for this plan. Plan 04 in this phase will introduce `SIGNING_SECRET_KEY` env var for Node-side `pgp_sym_encrypt` wrapper (consumed by `signing_provider_config.client_secret`).

## Next Phase Readiness

- **Ready for Plan 08-02 (PDF byte-range helpers)**: Transactions table can now persist `file_hash_sha256` and `signature_base64` values that 08-02's helpers will compute.
- **Ready for Plan 08-03/08-04 (generic PDF signer + minio integration)**: `signed_file_path` column is in place for worker to persist MinIO object keys.
- **No blockers** for Phase 9 (admin config API): all 5 provider SPs exist and were verified via E2E test including full lifecycle of upsert → set_active swap → get_active → BYTEA decrypt round-trip.

## Self-Check: PASSED

Verified:
- File `e_office_app_new/database/migrations/040_signing_schema.sql` exists (581 lines, 1 file)
- Commit `293a9f5` exists in log: feat(08-01): add signing schema foundation (3 tables + 4 ALTER)
- Commit `0a7f401` exists in log: feat(08-01): add 15 stored functions for signing CRUD + transactions
- `\d public.signing_provider_config` returns table with `client_secret bytea`, `is_active boolean`, partial unique index
- `\d public.staff_signing_config` returns composite PK `(staff_id, provider_code)`
- `\d edoc.sign_transactions` returns 18 columns with `status` (reserved word handled), 4 indexes, 3 CHECK constraints, FK to staff + 4 incoming FKs from attachments
- All 4 attachment tables (incoming/outgoing/drafting/handling) have `sign_provider_code` + `sign_transaction_id`
- 15 stored functions listed in `pg_proc`
- E2E lifecycle test executed successfully (create → set_provider_txn → increment_retry×2 → complete; guard-against-double-complete; update_status for all 3 terminal states; invalid-status rejection)
- Migration idempotent: 3 consecutive re-runs produce zero ERROR lines

---
*Phase: 08-schema-foundation-pdf-signing-generic-layer*
*Completed: 2026-04-21*
