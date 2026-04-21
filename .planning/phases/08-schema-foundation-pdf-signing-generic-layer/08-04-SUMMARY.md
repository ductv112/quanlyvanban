---
phase: 08-schema-foundation-pdf-signing-generic-layer
plan: 04
subsystem: backend
tags: [signing, crypto, pgcrypto, pgp-sym-encrypt, repository, stored-procedures, wave-2, tdd]

# Dependency graph
requires:
  - phase: 08-01
    provides: 3 signing tables + 15 stored functions (public.signing_provider_config, public.staff_signing_config, edoc.sign_transactions)
  - phase: 08-03
    provides: services/signing/ directory (types.ts + pdf-signer.ts already present)
provides:
  - services/signing/crypto.ts — encryptSecret / decryptSecret / maskSecret (pgcrypto wrappers)
  - services/signing/crypto.test.ts — 10 unit tests (roundtrip, random IV, Vietnamese diacritics, mask)
  - repositories/signing-provider-config.repository.ts — 5 methods matching 5 provider SPs
  - repositories/staff-signing-config.repository.ts — 4 methods matching 4 staff config SPs
  - repositories/sign-transaction.repository.ts — 6 methods matching 6 transaction SPs
  - .env.example documented with SIGNING_SECRET_KEY requirement
affects: [Phase 9 (admin config API consumes signingProviderConfigRepository + crypto.encryptSecret), Phase 10 (user config page consumes staffSigningConfigRepository), Phase 11 (sign flow consumes signTransactionRepository + pdf-signer)]

# Tech tracking
tech-stack:
  added: []  # No new Node deps — pgcrypto already enabled in migration 000
  patterns:
    - "Wave 2 rule applied: queried live DB (\\d table) + SP RETURNS TABLE before writing Row interfaces"
    - "Row interface names match SP column output EXACTLY (snake_case, no camelCase aliasing)"
    - "IncrementRetryRow uses new_retry_count (matches SP signature — renamed to avoid PL/pgSQL ambiguity)"
    - "Repository method signatures use camelCase params object for clean caller API while DB types stay snake_case"
    - "Crypto fail-fast: throw on empty/short SIGNING_SECRET_KEY instead of defaulting to weak key"
    - "Node built-in test runner (node:test via tsx) — reused pattern from Plan 08-03"
    - "Random IV verified: pgp_sym_encrypt same plaintext twice produces different ciphertext (test coverage)"

key-files:
  created:
    - e_office_app_new/backend/src/services/signing/crypto.ts
    - e_office_app_new/backend/src/services/signing/crypto.test.ts
    - e_office_app_new/backend/src/repositories/signing-provider-config.repository.ts
    - e_office_app_new/backend/src/repositories/staff-signing-config.repository.ts
    - e_office_app_new/backend/src/repositories/sign-transaction.repository.ts
  modified:
    - e_office_app_new/backend/.env.example (added SIGNING_SECRET_KEY documentation)

key-decisions:
  - "pgp_sym_encrypt qua rawQuery (không AES-256-GCM Node) — pgcrypto đã sẵn, key rotation trong 1 UPDATE SQL, backup/restore DB consistent"
  - "SIGNING_SECRET_KEY fail-fast: throw nếu unset hoặc < 16 chars — tránh vô tình encrypt bằng key yếu"
  - "Matched IncrementRetryRow → new_retry_count (không phải retry_count) — SP RETURNS TABLE rename để tránh PL/pgSQL column ambiguity (bug đã fix tại Plan 08-01, lần này repository tuân thủ đúng tên SP trả về)"
  - "3 Row interface cho provider config (List / Full / Active) — phân biệt rõ output của 3 SP khác nhau, List KHÔNG có client_secret để tránh lộ ciphertext"
  - "client_secret: Buffer (không string) — khớp BYTEA type từ pg driver; encrypt/decrypt phải dùng crypto.ts helper"
  - "Discriminated union type SignAttachmentType + SignTerminalStatus — type-safe hơn string literals ở call site"

patterns-established:
  - "Pattern: Wave 2 Row interfaces — query \\d table + pg_get_function_result trước khi gõ tên cột"
  - "Pattern: Crypto helper module cho tables có column sensitive — wrap pgp_sym_encrypt qua rawQuery + env key validation"
  - "Pattern: TDD với node:test cho pure backend module — tests chạy được standalone với DATABASE_URL"

requirements-completed: [MIG-01, MIG-02]

# Metrics
duration: ~5min
completed: 2026-04-21
---

# Phase 8 Plan 4: Signing Crypto + Repositories Summary

**Crypto helper (pgp_sym_encrypt/decrypt wrappers + 10 unit tests) + 3 repositories consuming 15 stored functions from Plan 08-01 — all Row interfaces match SP RETURNS TABLE column names exactly (snake_case, queried live from DB). Phase 9+ can now implement admin/user/worker layers on top of this backend foundation.**

## Performance

- **Duration:** ~5 min (315s — read context + 2 tasks + env docs + commits + SUMMARY)
- **Started:** 2026-04-21T06:50:42Z
- **Completed:** 2026-04-21T06:55:57Z
- **Tasks:** 2 (plus 1 env documentation chore commit)
- **Files created:** 5 (crypto.ts, crypto.test.ts, 3 repositories)
- **Files modified:** 1 (.env.example)
- **Total lines added:** ~538 lines of production TS + 95 lines test

## Accomplishments

- **Crypto layer ready**: `encryptSecret('plaintext') → Buffer` and `decryptSecret(Buffer) → 'plaintext'` roundtrip verified with 10 unit tests (including Vietnamese diacritics, random IV check, error cases).
- **3 repositories complete** with 15 typed methods total:
  - `signingProviderConfigRepository` — 5 methods (list, getByCode, getActive, upsert, setActive)
  - `staffSigningConfigRepository` — 4 methods (listByStaff, get, upsert, delete)
  - `signTransactionRepository` — 6 methods (create, setProviderTxn, complete, updateStatus, incrementRetry, getById)
- **Zero new TypeScript errors introduced** (21 pre-existing errors in `routes/*.ts` unchanged — same count as Plan 08-03 baseline).
- **SP signatures verified live**: Used `pg_get_function_result()` to confirm `fn_sign_transaction_increment_retry` actually returns `new_retry_count` (not `retry_count` as the plan draft suggested) — applied CLAUDE.md Wave 2 rule to catch this mismatch before runtime.
- **Env var documented** (`SIGNING_SECRET_KEY` min 16 chars, backup warning in `.env.example`).

## Task Commits

Each task committed atomically:

1. **Task 1: Crypto helper + unit tests** — `f89e123` (feat)
2. **Task 2: 3 repositories** — `cb3a781` (feat)
3. **Env documentation** — `ff8b37f` (chore)

**Plan metadata commit:** _pending_ (docs: complete plan)

## Files Created/Modified

- `e_office_app_new/backend/src/services/signing/crypto.ts` — **created** (143 lines)
  - `encryptSecret(plaintext: string) → Promise<Buffer>` — pgp_sym_encrypt wrapper
  - `decryptSecret(cipher: Buffer) → Promise<string>` — pgp_sym_decrypt wrapper
  - `maskSecret(plaintext: string) → string` — UI display helper (no crypto)
  - Private `getSecretKey()` — fail-fast env validation
- `e_office_app_new/backend/src/services/signing/crypto.test.ts` — **created** (95 lines, 10 tests)
  - 6 encrypt/decrypt tests (roundtrip, random IV, 3 error cases, Vietnamese diacritics)
  - 4 mask tests (empty, short, medium, long)
- `e_office_app_new/backend/src/repositories/signing-provider-config.repository.ts` — **created** (133 lines)
  - 3 Row interfaces (List, Full, Active) with `client_secret: Buffer` for BYTEA
- `e_office_app_new/backend/src/repositories/staff-signing-config.repository.ts` — **created** (112 lines)
  - 2 Row interfaces (List without certificate_data, Full with certificate_data)
- `e_office_app_new/backend/src/repositories/sign-transaction.repository.ts` — **created** (150 lines)
  - `SignTransactionRow` (17 fields from fn_sign_transaction_get_by_id)
  - `IncrementRetryRow` with `new_retry_count` matching actual SP signature
  - Exported `SignAttachmentType` + `SignTerminalStatus` union types for type-safe call sites
- `e_office_app_new/backend/.env.example` — **modified** (+6 lines documenting `SIGNING_SECRET_KEY`)

## Decisions Made

- **pgp_sym_encrypt via rawQuery over Node-side AES-256-GCM**: pgcrypto is already enabled (migration 000), so no new Node dependency needed. Key rotation becomes a single atomic SQL UPDATE. Backup/restore consistency — the ciphertext and related metadata live in one place. Node-side crypto would duplicate logic already present in PostgreSQL.
- **SIGNING_SECRET_KEY fail-fast, not default**: Threw an error for unset or < 16-char keys instead of falling back to a weak hardcoded default. Rationale: a default would let the app start "working" in dev with a known-weak key, which could accidentally ship to staging or production. Better to force explicit configuration at deploy time.
- **Matched `IncrementRetryRow.new_retry_count` to actual SP** (not plan draft `retry_count`): Plan 08-01's SUMMARY mentions this was a Rule 1 bug fix — the SP was renamed to `new_retry_count` to avoid PL/pgSQL column ambiguity (table has its own `retry_count`). Before writing the Row interface, I ran `pg_get_function_result()` live and confirmed the actual return type. This is exactly what CLAUDE.md's Wave 2 rule mandates.
- **3 separate Row interfaces for provider config** (List / Full / Active): The 3 SPs genuinely return different column sets — List excludes `client_secret` to prevent ciphertext leaking through Admin UI responses, while Full includes it for backend decrypt. Collapsing them into one interface would require optional fields everywhere and hide the security intent.
- **`client_secret: Buffer` (not `string`)**: pg driver returns BYTEA columns as Node Buffer. Typing it as string would silently coerce and break pgp_sym_decrypt on read. This also makes the encrypt-before-upsert contract explicit at the type system level.
- **Exported `SignAttachmentType` and `SignTerminalStatus` union types**: Call sites (Phase 11 sign flow, Phase 12 UI filters) will benefit from compile-time validation instead of raw string literals. CHECK constraints in DB already enforce these — TypeScript types just lift that enforcement to the editor.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] Fixed stale SP signature in plan interface spec**
- **Found during:** Task 2 — pre-verification via `pg_get_function_result()`
- **Issue:** The plan's `<interfaces>` block documented `fn_sign_transaction_increment_retry` as returning `TABLE(success BOOLEAN, retry_count INT)`. Running `SELECT pg_get_function_result(oid) FROM pg_proc WHERE proname = 'fn_sign_transaction_increment_retry'` returned `TABLE(success boolean, new_retry_count integer)`. Plan 08-01's own SUMMARY mentions this rename (Rule 1 fix during that plan) — the plan 08-04 draft simply didn't propagate the updated name.
- **Fix:** `IncrementRetryRow` uses `new_retry_count: number`. Method return type and fallback literal `{ success: false, new_retry_count: 0 }` both aligned.
- **Files modified:** `e_office_app_new/backend/src/repositories/sign-transaction.repository.ts`
- **Verification:** `npx tsc --noEmit` — zero errors. Would have been a runtime `undefined` return field if the plan draft had been followed literally.
- **Committed in:** Task 2 (`cb3a781`)

**2. [Rule 2 — Missing Critical] Added `.env.example` entry for `SIGNING_SECRET_KEY`**
- **Found during:** Post-task review (before SUMMARY)
- **Issue:** Plan didn't explicitly require `.env.example` update, but `crypto.ts` throws immediately on startup if `SIGNING_SECRET_KEY` is missing. Without documentation, next developer or production deploy would hit a confusing runtime error.
- **Fix:** Added `# --- Signing (pgcrypto key for client_secret encryption — Phase 8+)` section to `.env.example` with warning that key loss = inability to decrypt stored client_secrets.
- **Files modified:** `e_office_app_new/backend/.env.example`
- **Verification:** File diff shows 6-line addition at end.
- **Committed in:** Separate chore commit (`ff8b37f`)

### Intentional Enhancements (beyond plan text)

- Added a **6th test case** for Vietnamese diacritics roundtrip (`'Chữ ký số bí mật — năm 2026'`) to catch potential UTF-8 encoding bugs in pg_sym_encrypt path. Passed.
- Added `after(async () => { await pool.end() })` hook in test file so `node --test` exits cleanly without orphan connections (minor DX improvement — avoids test runner hang).
- Exported `SignAttachmentType` and `SignTerminalStatus` union types from `sign-transaction.repository.ts` — not in the plan but useful for Phase 11+ call sites that will pass these values.

---

**Total deviations:** 1 Rule 1 bug (plan draft used stale SP signature), 1 Rule 2 missing critical (env doc), 3 intentional minor enhancements.
**Impact on plan:** Public API shape of all 3 repositories matches the plan's `<must_haves>` exactly (method names, parameter names, return types). The Rule 1 fix prevented a silent runtime `undefined` return. Rule 2 fix prevents a confusing deploy error. No scope creep.

## Verification Results

### Automated verification (Task 1)
- `crypto.ts` has all 3 exports (`encryptSecret`, `decryptSecret`, `maskSecret`) — `grep` confirmed
- `pgp_sym_encrypt` and `pgp_sym_decrypt` present in rawQuery calls — confirmed
- `SIGNING_SECRET_KEY` env read — confirmed in `getSecretKey()`
- `npx tsc --noEmit` — zero errors in `services/signing/crypto.ts`
- `SIGNING_SECRET_KEY=test_key_min_16_chars_random_xyz_aaa npx tsx --test src/services/signing/crypto.test.ts` → **10/10 pass** (2 suites, 6 roundtrip + 4 mask)

### Automated verification (Task 2)
- All 3 repository files created in `src/repositories/`
- All 15 SP names present in their respective files — `grep` confirmed
- All Row interfaces use snake_case column names matching `\d schema.table`
- `client_secret: Buffer` confirmed in both Full and Active row types
- `status: string` (not quoted) in `SignTransactionRow` — matches pg driver's JSON output
- `npx tsc --noEmit` — zero new errors (21 pre-existing in `routes/*.ts` unchanged, confirmed against Plan 08-03 baseline count)

### Live DB smoke test
```
docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "
  SELECT COUNT(*) FROM public.fn_signing_provider_config_list();
  SELECT COUNT(*) FROM public.fn_staff_signing_config_list_by_staff(1);
"
```
→ Both SPs return `0` rows (empty tables, expected), **no errors**. Confirms SPs are callable exactly as the repositories invoke them.

## API Reference for Phase 9+

**Admin config API (Phase 9) will consume:**
```typescript
import { signingProviderConfigRepository } from '@/repositories/signing-provider-config.repository.js';
import { encryptSecret, decryptSecret, maskSecret } from '@/services/signing/crypto.js';

// Admin POST /api/signing/provider-config
const cipher = await encryptSecret(req.body.client_secret);  // plaintext from UI
const result = await signingProviderConfigRepository.upsert({
  providerCode: 'SMARTCA_VNPT',
  providerName: 'SmartCA VNPT',
  baseUrl: 'https://gwsca.vnpt.vn/sca/sp769/v1',
  clientId: req.body.client_id,
  clientSecret: cipher,       // BYTEA
  profileId: null,
  extraConfig: {},
  lastTestedAt: null,
  testResult: null,
  updatedBy: req.user.staffId,
});

// Admin GET /api/signing/provider-config/active (for sign flow)
const active = await signingProviderConfigRepository.getActive();
if (active) {
  const plaintextSecret = await decryptSecret(active.client_secret);  // back to string
  // ... pass to provider adapter
}
```

**User config API (Phase 10):**
```typescript
import { staffSigningConfigRepository } from '@/repositories/staff-signing-config.repository.js';

const configs = await staffSigningConfigRepository.listByStaff(req.user.staffId);  // list all providers
const single  = await staffSigningConfigRepository.get(req.user.staffId, 'SMARTCA_VNPT');
```

**Sign flow (Phase 11):**
```typescript
import { signTransactionRepository, type SignAttachmentType } from '@/repositories/sign-transaction.repository.js';

// User clicks "Ký số" → tạo transaction
const txn = await signTransactionRepository.create({
  staffId: req.user.staffId,
  providerCode: 'SMARTCA_VNPT',
  attachmentId: 12345,
  attachmentType: 'outgoing',
  docId: 678,
  docType: 'outgoing_doc',
  fileHashSha256: hashHex,   // từ pdf-signer.computePdfHash()
});
if (!txn.success) throw new Error(txn.message);

// Sau khi provider trả txn_id
await signTransactionRepository.setProviderTxn(txn.id, 'SMARTCA-TXN-abc123');

// Worker poll 5s → complete khi provider done
await signTransactionRepository.complete(txn.id, signatureBase64, 'signed/xxx.pdf');
```

## Issues Encountered

- **None.** Clean run — no blockers, no infra issues. Plan 08-01's schema verification paid off: all 15 SPs already existed in DB and return expected columns.
- Minor: Plan draft had a stale SP signature (`retry_count` vs `new_retry_count`) — caught by live DB query per CLAUDE.md Wave 2 rule before writing the interface. Had I trusted the plan blindly, would have been a silent runtime bug later.

## User Setup Required

For production deployment:
1. Set `SIGNING_SECRET_KEY` in `.env` to a random 32+ character string (e.g., `openssl rand -base64 48 | tr -d '=/+' | head -c 48`)
2. **Back up the key securely** — if lost, stored `client_secret` ciphertexts become unrecoverable
3. For local dev: the `.env.example` value works but should be changed before any staging rollout

No external services, no DB changes, no container restarts needed — all runtime env-based.

## Next Phase Readiness

- **Ready for Phase 9 (Admin config API + provider adapters)**:
  - `signingProviderConfigRepository.upsert()` accepts encrypted BYTEA directly
  - `encryptSecret()` wraps plaintext from Admin form body
  - `getActive()` returns the single active provider with decrypted-ready ciphertext
  - `maskSecret()` available for read-back responses that shouldn't reveal stored secret
- **Ready for Phase 10 (User config page)**:
  - `staffSigningConfigRepository.listByStaff(staffId)` — table data for "Tài khoản cá nhân" page
  - `upsert()` supports partial certificate update (SP uses COALESCE — user can update user_id without re-uploading cert)
- **Ready for Phase 11 (Sign flow + worker)**:
  - `signTransactionRepository.create()` → `setProviderTxn()` → `complete()` / `updateStatus()` full lifecycle
  - `incrementRetry()` for BullMQ worker poll loop
  - `getById()` returns all 17 columns needed for modal ký countdown + audit
  - Pairs with `services/signing/pdf-signer.ts` (from Plan 08-03) to compute hash + embed signature
- **Phase 8 is now 4/4 COMPLETE** (schema + PDF helpers + generic signer + crypto+repositories).

## Self-Check: PASSED

Verified:
- File `e_office_app_new/backend/src/services/signing/crypto.ts` exists (143 lines, > 80 min required)
- File `e_office_app_new/backend/src/services/signing/crypto.test.ts` exists (95 lines, 10 tests)
- File `e_office_app_new/backend/src/repositories/signing-provider-config.repository.ts` exists (133 lines)
- File `e_office_app_new/backend/src/repositories/staff-signing-config.repository.ts` exists (112 lines)
- File `e_office_app_new/backend/src/repositories/sign-transaction.repository.ts` exists (150 lines)
- File `e_office_app_new/backend/.env.example` modified with SIGNING_SECRET_KEY section
- Commit `f89e123` exists in git log: `feat(08-04): add crypto helper (pgp_sym_encrypt/decrypt) + unit tests`
- Commit `cb3a781` exists in git log: `feat(08-04): add 3 signing repositories (provider + staff config + transactions)`
- Commit `ff8b37f` exists in git log: `chore(08-04): document SIGNING_SECRET_KEY env var in .env.example`
- `SIGNING_SECRET_KEY=... npx tsx --test crypto.test.ts` → **10 pass, 0 fail**
- All 5 provider SP names present in `signing-provider-config.repository.ts`: list, get_by_code, get_active, upsert, set_active
- All 4 staff SP names present in `staff-signing-config.repository.ts`: list_by_staff, get, upsert, delete
- All 6 transaction SP names present in `sign-transaction.repository.ts`: create, set_provider_txn, complete, update_status, increment_retry, get_by_id
- `IncrementRetryRow.new_retry_count` matches actual `pg_get_function_result()` output
- `client_secret: Buffer` (BYTEA) in both Full and Active row types
- `npx tsc --noEmit` — zero new errors (21 pre-existing in `routes/*.ts` unchanged)
- Live psql smoke test of 2 SPs ran cleanly (0 rows, 0 errors)

---
*Phase: 08-schema-foundation-pdf-signing-generic-layer*
*Completed: 2026-04-21*
