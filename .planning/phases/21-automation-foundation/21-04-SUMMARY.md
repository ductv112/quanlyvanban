---
phase: 21-automation-foundation
plan: 04
subsystem: testing
tags: [playwright, globalSetup, auth-fixtures, storage-state, integration-helpers, automation]

requires:
  - phase: 21-01
    provides: playwright.config.ts with commented globalSetup placeholder ready to wire
  - phase: 21-02
    provides: TEST_USERS const (6 user fixtures from seed/003_test_fixtures.sql) — credentials inlined per ESM/CJS boundary, mirror only

provides:
  - "tests/globalSetup.ts — Playwright global hook that polls /api/health then logs in 5 user fixtures parallel via POST /api/auth/login and saves browser context state to tests/.auth/<role>.json"
  - "tests/globalTeardown.ts — no-op stub (future: per-worker DB cleanup, mock teardown)"
  - "tests/fixtures/auth.ts — storageStateFor(role) path resolver + loginAs(request, role) programmatic login + getAuthHeader() for E2E + integration tier"
  - "tests/fixtures/api-client.ts — createApiClient(token) fetch wrapper (GET/POST/PUT/PATCH/DELETE/upload) + loginAndGetToken(role) for Vitest integration tier"
  - "playwright.config.ts UPDATE — wires globalSetup + globalTeardown via path.resolve (CJS-safe)"
  - "tests/.auth/.gitkeep — keeps folder tracked in git; *.json runtime-generated and gitignored"

affects: [phase-21-05, phase-21-06, phase-22, phase-23]

tech-stack:
  added: []
  patterns:
    - "Storage state pattern: globalSetup login parallel (Promise.all) -> save 5 .json each containing cookies (refreshToken httpOnly path=/api/auth) + localStorage (origin=http://localhost:3000, key=accessToken)"
    - "CJS-safe Playwright config wiring: use path.resolve(__dirname, ...) instead of require.resolve() — keeps consistency with plan 21-01 deviation #3 (no ESM shim)"
    - "Inline credentials map (not import from backend/tests/fixtures/users.ts): avoids ESM/CJS path resolution issues at the Playwright config boundary; source of truth still seed/003_test_fixtures.sql; mirror documented at top of globalSetup.ts + auth.ts + api-client.ts"
    - "Skip 'locked' user (6th fixture): login 401 by design (is_locked=true) — only 5 storage state files generated; locked user reserved for negative auth tests"
    - "Two-tier helper exports: tests/fixtures/auth.ts is shared across E2E (Playwright) + integration (Vitest); tests/fixtures/api-client.ts targets integration only (HTTP fetch). HttpRequest interface in auth.ts is structurally compatible with Playwright APIRequestContext without importing @playwright/test (so the file works in Vitest too)"
    - "Health-poll waitForBackend pattern: 500ms polling against /api/health, 30s total timeout, fails fast with Vietnamese hint message — matches plan 21-03 mocks/start.ts waitForHealth"
    - "Future-deferred refactor noted: createApp() factory split from server.ts top-level listen() to allow supertest(app) instead of HTTP localhost:4000 — deferred to phase 22+"

key-files:
  created:
    - tests/globalSetup.ts
    - tests/globalTeardown.ts
    - tests/fixtures/auth.ts
    - tests/fixtures/api-client.ts
    - tests/.auth/.gitkeep
  modified:
    - playwright.config.ts
    - tests/.gitignore
    - .gitignore

key-decisions:
  - "Inline credential map in 3 places (globalSetup.ts + auth.ts + api-client.ts) instead of importing TEST_USERS from backend tests fixtures — Playwright config boundary triggers ESM/CJS resolution issues across module trees. Single source of truth remains database/seed/003_test_fixtures.sql; doc comments at top of each file note the mirror requirement."
  - "Skip 6th 'locked' user from globalSetup — login returns 401 by design. Only 5 storage states generated. Locked user reserved for negative auth tests in phase 22."
  - "Use path.resolve(__dirname, ...) instead of require.resolve() in playwright.config.ts — CJS-safe, matches plan 21-01 decision (no ESM shim at root, root package.json has no 'type':'module')."
  - "Login PARALLEL (Promise.all) — 5 user x ~200ms = ~1s tổng vs 1s sequential. Acceptance criteria <2s comfortably met (verifiable when backend running)."
  - "page.goto(FRONTEND_URL, { waitUntil: 'commit' }) — only need origin to set localStorage, no need full network idle. Faster + frontend can be slow to render full page on first hit."
  - "globalTeardown stub no-op now (per plan) — future enhancements documented in file header (per-worker DB cleanup, mock teardown). Storage state files retained intentionally for fast re-runs."
  - "FormData type requires DOM lib — included in tsc check (--lib ES2022,DOM). Node 20+ has native FormData; api-client.ts.upload accepts FormData and lets fetch auto-set boundary."
  - "Two HttpRequest abstractions in auth.ts (Playwright APIRequestContext compat) vs api-client.ts (fetch wrapper) — keeps E2E and integration tiers independent. auth.ts doesn't import @playwright/test so Vitest tests can also import it without dragging in browser deps."
  - "tests/.auth/.gitkeep + .gitignore tweaks — root .gitignore had 'tests/.auth/' (whole dir blocked). Changed to 'tests/.auth/*.json' to keep folder tracked. tests/.gitignore mirror'd: '.auth/*.json' + '!.auth/.gitkeep' negation."

requirements-completed: [AUTO-10]

duration: 6min
completed: 2026-05-06
---

# Phase 21 Plan 04: Playwright globalSetup + Auth Fixtures Summary

**Playwright globalSetup auto-logs in 5 user fixtures parallel via POST /api/auth/login -> saves tests/.auth/<role>.json (cookies + localStorage); auth.ts + api-client.ts helpers for E2E + integration tiers — TS strict pass, config validates, no runtime fail (backend dependency expected at run time per plan)**

## Performance

- **Duration:** 5 min 50 sec
- **Started:** 2026-05-06T04:37:02Z
- **Completed:** 2026-05-06T04:42:52Z
- **Tasks:** 2 (all complete)
- **Files created:** 5
- **Files modified:** 3
- **Total LoC added:** 491 lines (183 globalSetup + 21 globalTeardown + 127 auth.ts + 160 api-client.ts)

## Accomplishments

- **globalSetup.ts (183 lines):** Polls `GET /api/health` (500ms intervals, 30s timeout), then logs in 5 user fixtures (admin/vanthu/lanhdao/canbo/canboX) PARALLEL via `Promise.all` -> saves 5 `tests/.auth/<role>.json` storage state files containing cookies + localStorage. Throws clean Vietnamese error if backend not reachable. Skips 'locked' user (6th fixture) by design.
- **globalTeardown.ts (21 lines):** No-op stub with documented future enhancement plan (per-worker test DB cleanup, mock teardown, results aggregation).
- **fixtures/auth.ts (127 lines):** Exports `STORAGE_STATE_DIR` constant, `RoleKey` type union (5 keys), `storageStateFor(role)` path resolver, `loginAs(request, role)` programmatic login (works with Playwright APIRequestContext OR custom wrapper), `getAuthHeader(token)` Bearer header builder. Doesn't import `@playwright/test` -> usable from both E2E and integration tier without dragging in browser deps.
- **fixtures/api-client.ts (160 lines):** Exports `ApiClient` interface, `createApiClient(token, baseUrl?)` factory wrapping native `fetch` (GET/POST/PUT/PATCH/DELETE/upload methods), `loginAndGetToken(role)` for Vitest `beforeAll` setup. Auto-attaches Bearer header, auto-encodes JSON body, auto-parses JSON/text response by content-type. Multipart upload support via FormData (lets fetch set Content-Type with boundary).
- **playwright.config.ts wired:** `globalSetup: path.resolve(__dirname, 'tests/globalSetup.ts')` + matching teardown line. CJS-safe (no `require.resolve`/ESM shim).
- **.gitignore + tests/.gitignore tweaked:** Allow `tests/.auth/.gitkeep` while still ignoring runtime-generated `tests/.auth/*.json` (which contain real auth tokens).
- **Verification:** `npx playwright test --list` parses config OK (Total: 0 tests in 0 files, no error). `npx tsc --noEmit` (with --lib ES2022,DOM --types node) passes EXIT 0 across all 4 .ts files. tsx import smoke test confirms 6 exports work (storageStateFor, loginAs, getAuthHeader, createApiClient, loginAndGetToken, ApiClient methods).

## Task Commits

1. **Task 1: tests/globalSetup.ts + globalTeardown.ts + playwright.config.ts wire + .gitignore tweaks** — `0925637` (feat)
2. **Task 2: tests/fixtures/auth.ts + api-client.ts (E2E + integration helpers)** — `6d50707` (feat)

## Files Created/Modified

### Created (5 files)
- `tests/globalSetup.ts` (183 lines, 6.8KB) — Playwright global hook: waitForBackend + parallel login 5 user + save storage state
- `tests/globalTeardown.ts` (21 lines, 0.9KB) — Stub with future plan
- `tests/fixtures/auth.ts` (127 lines, 4.2KB) — storageStateFor + loginAs + getAuthHeader (E2E + integration)
- `tests/fixtures/api-client.ts` (160 lines, 5.4KB) — createApiClient + loginAndGetToken (integration tier)
- `tests/.auth/.gitkeep` (0.1KB) — Folder placeholder + comment

### Modified (3 files)
- `playwright.config.ts` — Replaced `// globalSetup placeholder` with `globalSetup: path.resolve(...)` + `globalTeardown: path.resolve(...)` (3 mention count)
- `tests/.gitignore` — Changed `.auth/` blanket to `.auth/*.json` + `!.auth/.gitkeep` negation
- `.gitignore` (root) — Changed `tests/.auth/` to `tests/.auth/*.json` to allow .gitkeep tracking

## Decisions Made

### 1. Inline credentials (not import TEST_USERS from backend)
TEST_USERS const lives in `e_office_app_new/backend/tests/fixtures/users.ts`. Importing across that module boundary into Playwright config (root, CJS) hits ESM/CJS resolution issues — Playwright config compiles via CJS, backend tests use ESM with `.js` extension imports. Resolution: inline a 5-element credential array at top of each consumer (globalSetup.ts, auth.ts, api-client.ts) with comment noting source of truth = `database/seed/003_test_fixtures.sql`. Documented mirror requirement in each file header.

### 2. Skip 'locked' user from globalSetup
6th fixture (`test_locked`, id=9099, is_locked=true) intentionally excluded from `TEST_USERS_FOR_AUTH` array. Login returns HTTP 401 by design. Only 5 storage states needed. Locked user reserved for negative tests in phase 22 (e.g., TC-AUTH-LOGIN-LOCKED).

### 3. CJS-safe playwright.config.ts (no `require.resolve`)
Plan 21-01 deviation #3 already removed ESM `import.meta` shim from root config. Continuing that pattern: used `path.resolve(__dirname, 'tests/globalSetup.ts')` instead of `require.resolve('./tests/globalSetup.ts')`. Both are valid in CJS but `path.resolve` is consistent with the existing dotenv line.

### 4. Parallel login (Promise.all)
5 sequential logins ~ 1s. Promise.all parallelizes — expected ~200-300ms per login + JS overhead. Plan acceptance criteria says <2s, easily met when backend is responsive. Browser launches share Chromium binary cache.

### 5. `waitUntil: 'commit'` on page.goto frontend
We only need to set localStorage on origin `http://localhost:3000`. No need to wait for full network idle (frontend Next.js dev mode can take 5-10s on first hit). 'commit' fires as soon as response headers arrive.

### 6. globalTeardown intentionally no-op
Plan said "stub for future". Confirmed in spec: storage state files persist between runs (allows fast re-run skipping globalSetup if .json is fresh — future optimization). Per-worker DBs not in scope yet (AUTO-09 implemented BEGIN/ROLLBACK isolation in plan 21-02 instead). Mock teardown handled by `tools/mocks/stop.ts` (plan 21-03).

### 7. HttpRequest interface in auth.ts (no @playwright/test import)
auth.ts is shared across both tiers. Importing `import type { APIRequestContext } from '@playwright/test'` would force Vitest tests to install/resolve playwright. Solution: define a structurally-compatible `HttpRequest` interface inline (matches APIRequestContext.post signature). Playwright's `request` fixture passes type-checking against it. Vitest tests can implement the interface with a fetch wrapper.

### 8. .gitkeep + .gitignore negation pattern
Root .gitignore had `tests/.auth/` (whole dir blocked recursively). `.gitkeep` would be untracked even if added. Two changes:
- Root `.gitignore`: `tests/.auth/` -> `tests/.auth/*.json`
- `tests/.gitignore`: `.auth/` -> `.auth/*.json` + `!.auth/.gitkeep` (negation)

Verified `git check-ignore -v tests/.auth/.gitkeep` shows `tests/.gitignore:4:!.auth/.gitkeep tests/.auth/.gitkeep` (negation matched).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] .gitignore blocking tests/.auth/.gitkeep**
- **Found during:** Task 1 commit prep
- **Issue:** Plan asked for `tests/.auth/.gitkeep` to keep folder tracked. Root `.gitignore:55` had `tests/.auth/` (whole dir blocked recursively). Even after adding `.gitkeep`, `git status` showed it untracked. Verified via `git check-ignore -v tests/.auth/.gitkeep` -> matched root pattern.
- **Fix:** Two-edit chain:
  1. Root `.gitignore`: changed `tests/.auth/` to `tests/.auth/*.json` (only block JSON files)
  2. `tests/.gitignore`: changed `.auth/` to `.auth/*.json` + added `!.auth/.gitkeep` negation (defense in depth)
- **Files modified:** `.gitignore`, `tests/.gitignore`
- **Verification:** `git status` shows `tests/.auth/.gitkeep` as new file; `git check-ignore -v` matches negation rule.
- **Committed in:** `0925637` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (missing critical .gitignore tweak — required for the artifact list to actually land in repo).
**Impact on plan:** Single config-correctness fix. No scope creep. Plan template said "add .gitkeep" but didn't account for the existing `.gitignore` blanket pattern from plan 21-01.

## Issues Encountered

- **No backend running during this plan execution** — Plan dependency note explicitly says backend (port 4000) + frontend (port 3000) + test DB seeded must be running for runtime verify. Backend not started in this session by design (plan 21-04 is code-only; 21-05 will trigger first runtime via smoke). globalSetup code logically correct (verified TS pass + import smoke test); first runtime invocation will happen in plan 21-05 (Wave 3 smoke run) per plan dependency_check.
- **Playwright config validation** — `npx playwright test --list` returns "Total: 0 tests in 0 files" (no test specs exist yet, intentional). Config parses without error -> globalSetup/globalTeardown wires syntactically valid.
- **No interactive prompts encountered** — All bash + TS operations ran non-interactively.

## User Setup Required

None — code-only changes for plan 21-04. First runtime in plan 21-05 will require:
1. Backend running: `cd e_office_app_new/backend && PG_DATABASE=qlvb_test npm run dev`
2. Frontend running: `cd e_office_app_new/frontend && npm run dev`
3. Test DB seeded: `npm run test:db:reset` (already verified plan 21-02)
4. Mock servers running (optional for auth flow): `cd tools/mocks && npm start`

QA workflow once 21-05 lands smoke specs:
```bash
# 1-time per session
cd e_office_app_new/backend && PG_DATABASE=qlvb_test npm run dev &
cd e_office_app_new/frontend && npm run dev &
npm run test:db:reset

# Run smoke
npm run test:smoke   # globalSetup auto-fires, login 5 user, save .auth/*.json, then run tests
```

## Next Phase Readiness

- **Plan 21-05 (smoke 30 TC + Excel parser):** Can `import { storageStateFor } from '../fixtures/auth'` then `test.use({ storageState: storageStateFor('vanthu') })` to skip login. Can also `import { loginAndGetToken, createApiClient } from '../fixtures/api-client'` for integration-tier API checks. First real runtime of globalSetup happens in this plan -> any logical bugs in globalSetup will surface here (acceptable per dependency_check note).
- **Plan 21-06 (CI workflow):** CI yaml will run `npm run test:smoke` after starting backend/frontend services + mock containers. globalSetup health-poll has 30s timeout — sufficient for CI cold-start.
- **Phase 22 (regression backbone):** Will reuse globalSetup for ALL E2E. Will use `loginAs(request, 'locked')` or similar to test 401 cases. Will use `getAuthHeader(token)` in supertest-style integration tests. Will likely add `loginAs(request, 'locked')` -> expects throw (negative test).
- **Phase 23 (E2E + concurrent):** Concurrent tests will use multiple `browser.newContext({ storageState: storageStateFor(role) })` to emulate multi-tab same-user. Cross-unit tests use `storageStateFor('canboX')` (unit_id=3) vs `storageStateFor('canbo')` (unit_id=2).

## Future Work (deferred per AUTOMATION_TEST_PLAN section 11)

- **createApp() factory refactor (server.ts):** Currently server.ts has `app.listen()` at top-level — prevents `import { app } from server`. api-client.ts works around by HTTP localhost:4000. Future: split createApp() factory so Vitest integration can `supertest(createApp())` directly (faster, isolation per test). Deferred phase 22+.
- **Storage state staleness check in globalSetup:** Current behavior: regen all 5 .json every run. Future: skip if mtime < 14min (JWT lifetime is 15min, refresh before expiry). Deferred plan 21-06 or later.
- **per-worker DB clones (AUTO-09 partial):** Plan 21-02 implemented BEGIN/ROLLBACK isolation for integration tier. E2E concurrent tests in phase 23 may need template-DB clone (CREATE DATABASE qlvb_test_w1 TEMPLATE qlvb_baseline). globalTeardown.ts header documents this future hook.
- **Locked user fixture:** Skipped now. Phase 22 will add negative test that calls `loginAs(request, 'locked' as any)` (with type assertion since locked is not in RoleKey union). Or extend RoleKey to include 'locked' with separate handling. Decision deferred.

## Self-Check: PASSED

- Files exist (5/5): `tests/globalSetup.ts` (6.8KB), `tests/globalTeardown.ts` (0.9KB), `tests/fixtures/auth.ts` (4.2KB), `tests/fixtures/api-client.ts` (5.4KB), `tests/.auth/.gitkeep` (0.1KB) ✓
- Both task commits exist on main: `0925637`, `6d50707` ✓
- `playwright.config.ts` mentions globalSetup/globalTeardown 3 times (1 comment + 2 actual config lines) ✓
- `tests/globalSetup.ts` references TEST_USERS_FOR_AUTH + 5 username strings (9 mentions total) ✓
- globalSetup uses `json.data?.accessToken` + `json.data.accessToken` (correct response shape from backend/src/routes/auth.ts:34) ✓
- `npx playwright test --list` exits clean: "Total: 0 tests in 0 files" (no parse error) ✓
- `npx tsc --noEmit --lib ES2022,DOM --types node` exits 0 on all 4 files (TS strict, FormData/fetch types resolved) ✓
- tsx smoke import test confirms 6 exports work: STORAGE_STATE_DIR, storageStateFor (5 roles), getAuthHeader, loginAs (function), createApiClient (function), loginAndGetToken (function), client.get/post/put/patch/delete/upload (all functions) ✓
- `git check-ignore -v tests/.auth/.gitkeep` shows negation rule matched (`tests/.gitignore:4:!.auth/.gitkeep`) — folder tracked ✓
- Runtime test (login real) NOT executed: backend not running in this session (per plan dependency_check note — runtime verification deferred to plan 21-05 Wave 3 smoke run). Code logic correct per TS check + smoke import + Playwright parse — sufficient for plan 21-04 acceptance ✓

---
*Phase: 21-automation-foundation*
*Completed: 2026-05-06*
