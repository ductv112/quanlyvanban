---
phase: 21-automation-foundation
plan: 01
subsystem: testing
tags: [vitest, playwright, supertest, nock, wait-on, automation, ci]

requires:
  - phase: none
    provides: First plan in phase 21 (Wave 1 — no dependencies)

provides:
  - Vitest 2.1.9 unit + integration test runner configured in backend dir
  - Playwright 1.59.1 + Chromium 1217 binary at root for E2E
  - supertest 7.x + nock 14.x for backend integration HTTP intercept
  - wait-on 8.x for CI port readiness gating
  - .env.test.example template with full mock server config (8181/8182/8183)
  - tests/setup.ts safety guard (rejects PG_DATABASE without 'test' suffix)
  - Two vitest configs (unit fast + integration with forks pool / 30s timeout)
  - Root npm scripts orchestrating tests across both tiers

affects: [phase-21-02, phase-21-03, phase-21-04, phase-21-05, phase-21-06, phase-22, phase-23]

tech-stack:
  added: [vitest@2.1.9, "@vitest/coverage-v8@2.1.9", supertest@7.x, "@types/supertest@6.x", nock@14.x, wait-on@8.x, "@playwright/test@1.59.1", dotenv@17.x (root)]
  patterns:
    - "Two-tier test runner: Vitest at backend dir (unit + integration), Playwright at root (E2E)"
    - "TEST SAFETY guard pattern: setup.ts throws if PG_DATABASE missing 'test' substring (prevents accidental dev DB writes)"
    - "Separate vitest.config.ts (unit, fast 5s) + vitest.integration.config.ts (forks pool, 30s timeout)"
    - "ESM-aware config: backend ESM uses import.meta when needed; root CJS Playwright uses __dirname directly"
    - "--passWithNoTests flag on test:unit/test:integration so plans 21-02..06 can land empty configs without breaking CI"

key-files:
  created:
    - e_office_app_new/backend/vitest.config.ts
    - e_office_app_new/backend/vitest.integration.config.ts
    - e_office_app_new/backend/tests/setup.ts
    - e_office_app_new/backend/tests/.gitignore
    - playwright.config.ts
    - tests/.gitignore
    - .env.test.example
    - package.json (root)
    - package-lock.json (root)
  modified:
    - e_office_app_new/backend/package.json (6 new devDeps + 4 new test scripts)
    - e_office_app_new/backend/package-lock.json (lockfile regen with vitest tree)
    - .gitignore (root, added test artifacts entries)

key-decisions:
  - "Vitest 2.x (not 3.x) — backend on TS 6.x; vitest 3 requires TS ≥6.4 stable not yet GA in our toolchain"
  - "Playwright 1.59.1 (latest stable as of 2026-05-06) at root only, not in backend/frontend dirs — avoids dep conflict with Next.js test utilities"
  - "Excluded src/**/*.test.ts from vitest unit config — 3 legacy files use node:test runner, incompatible with vitest"
  - "Added --passWithNoTests to test:unit/test:integration scripts — plans 21-02..06 incrementally add specs; CI must not fail on empty"
  - "Chromium binary only (no firefox/webkit) — smoke PR target Chromium per AUTOMATION_TEST_PLAN section 5.4 (keep < 8min)"
  - "Skipped --with-deps on Windows local install — system libs only needed in CI ubuntu-latest"

patterns-established:
  - "Test stack install via npm install: 1× root (Playwright) + 1× e_office_app_new/backend (Vitest stack). QA onboarding ≤ 30 min per RPT-07."
  - "Safety guard for test isolation: throw on dev DB before any DB connection opens"
  - "Reporter triple stack: list (terminal) + json (Excel sync parser input) + html (debug fail trace)"

requirements-completed: [AUTO-01]

duration: 12min
completed: 2026-05-06
---

# Phase 21 Plan 01: Test Stack Setup Summary

**Vitest 2.1.9 + Playwright 1.59.1 + supertest 7.x + nock 14.x installed across two tiers (backend dir + root), with TEST SAFETY guard preventing accidental writes to dev DB**

## Performance

- **Duration:** 12 min 8 sec
- **Started:** 2026-05-06T03:36:27Z
- **Completed:** 2026-05-06T03:48:35Z
- **Tasks:** 3 (all complete)
- **Files modified:** 11 (9 created + 2 modified)

## Accomplishments

- Backend test runner stack ready: `npx vitest --version` → 2.1.9; supertest/nock/wait-on require() OK
- Root Playwright stack ready: `npx playwright --version` → 1.59.1; Chromium 1217 binary downloaded to `%LOCALAPPDATA%\ms-playwright`
- Two vitest configs separating unit (fast 5s, scoped to lib coverage) from integration (forks pool 4 workers, 30s timeout, scoped to routes+repos+services coverage)
- TEST SAFETY guard verified: `PG_DATABASE=qlvb_dev` → vitest throws with Vietnamese error message; `PG_DATABASE=qlvb_test` → tests run normally
- `.env.test.example` template covers all dependencies QA needs (qlvb_test DB, MinIO documents-test bucket, mock servers 8181/8182/8183, deterministic 32-char JWT/SIGNING secrets)
- Root npm scripts orchestrate tests across both tiers via `npm --prefix e_office_app_new/backend run` proxying

## Task Commits

Each task was committed atomically:

1. **Task 1: Add deps + scripts to backend/package.json** — `91d7697` (feat)
2. **Task 2: Configure vitest unit + integration + safety guard** — `d657bd5` (feat)
3. **Task 3: Add Playwright 1.59.1 root + .env.test.example + tests/.gitignore** — `58be97d` (feat)

## Files Created/Modified

### Created (9 files)
- `e_office_app_new/backend/vitest.config.ts` — Vitest unit config (5s timeout, lib/* coverage, includes tests/unit/**)
- `e_office_app_new/backend/vitest.integration.config.ts` — Vitest integration config (30s timeout, forks pool max 4 workers, routes+repos+services coverage)
- `e_office_app_new/backend/tests/setup.ts` — Loads `.env.test`, throws TEST SAFETY error if PG_DATABASE missing 'test' substring, sets NODE_ENV=test
- `e_office_app_new/backend/tests/.gitignore` — Ignores results/, coverage/, .auth/, *.json (allows fixtures/**)
- `playwright.config.ts` — Root Playwright config (workers 4 local / 2 CI, fullyParallel, locale vi-VN, tz Asia/Ho_Chi_Minh, retain-on-failure for trace+video)
- `tests/.gitignore` — Ignores results/, .auth/, snapshot diff artifacts
- `.env.test.example` — Full QA template (40+ env vars covering server/PG/Mongo/Redis/MinIO/JWT/mock servers/Playwright)
- `package.json` (root) — qlvb-test-orchestrator with @playwright/test ^1.50.0, @types/node ^20.0.0, dotenv ^17.0.0
- `package-lock.json` (root) — npm 10 lockfile generated by install

### Modified (2 files)
- `e_office_app_new/backend/package.json` — Added 6 devDeps (vitest, @vitest/coverage-v8, supertest, @types/supertest, nock, wait-on) + 4 scripts (test:unit, test:integration, test:watch, test:db:reset). Used `--passWithNoTests` flag.
- `.gitignore` (root) — Appended 5 entries (tests/results/, tests/.auth/, tests/coverage/, playwright-report/, .env.test) — preserved existing entries.

## Decisions Made

- **Vitest 2.x not 3.x** — backend toolchain pins TS 6.0.2 stable; vitest 3 requires recent TS feature support, deferring upgrade to a future plan
- **Playwright 1.59.1 (latest)** — well above the ≥1.50 minimum required by plan; native ESM/CJS dual support means root config works without `"type":"module"`
- **--passWithNoTests on test scripts** — plans 21-02 through 21-06 will incrementally add specs; CI must not fail when only the config exists
- **Excluded `src/**` from vitest** — 3 legacy `.test.ts` files in `src/services/signing/` use `node:test` runner with `describe` from `node:test`, incompatible with vitest. Left those untouched (run via `tsx --test` per their header comments)
- **Chromium-only browser install** — smoke PR gate per plan only targets Chromium for <8min budget; firefox/webkit deferred to nightly (phase 22)
- **No `--with-deps` on Windows local** — system libs (libgbm, libasound2) only needed on Linux CI; will be added in plan 21-06 CI workflow

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Vitest unit config picked up incompatible legacy test files in src/**
- **Found during:** Task 2 (verifying `npx vitest run` exits 0 with valid config)
- **Issue:** Plan specified `include: ['tests/unit/**/*.test.ts', 'src/**/*.test.ts']`. The `src/**` glob matched 3 existing files (`src/services/signing/{crypto,pdf-signer,provider}.test.ts`) which use `node:test` runner with `describe`/`it` from `node:test`, NOT vitest. Vitest reported "No test suite found" and exited 1 for each — blocking config validation.
- **Fix:** Changed `include` to `['tests/unit/**/*.test.ts']` only and added `'src/**'` to `exclude`. Legacy tests continue to run via `npx tsx --test` per their inline header comments (separate runner, no conflict).
- **Files modified:** `e_office_app_new/backend/vitest.config.ts`
- **Verification:** `PG_DATABASE=qlvb_test npx vitest run --passWithNoTests` exits 0 with "No test files found".
- **Committed in:** `d657bd5` (Task 2 commit)

**2. [Rule 2 - Missing Critical] Added --passWithNoTests to test:unit/test:integration scripts**
- **Found during:** Task 2 (running `npm run test:unit` after fixing include glob)
- **Issue:** Plan didn't specify behavior when zero tests exist. Vitest 2.x defaults to exit code 1 with "No test files found" — would fail CI on plans 21-02 through 21-06 that haven't yet authored specs.
- **Fix:** Added `--passWithNoTests` flag to both `test:unit` and `test:integration` scripts in `e_office_app_new/backend/package.json`.
- **Files modified:** `e_office_app_new/backend/package.json`
- **Verification:** `cd e_office_app_new/backend && PG_DATABASE=qlvb_test npm run test:unit` exits 0.
- **Committed in:** `d657bd5` (Task 2 commit)

**3. [Rule 3 - Blocking] Removed `import.meta.url` ESM shim from playwright.config.ts**
- **Found during:** Task 3 (running `npx playwright test --list` to verify config parses)
- **Issue:** Plan template suggested `import { fileURLToPath } from 'url'; const __filename = fileURLToPath(import.meta.url);` but root `package.json` does NOT set `"type": "module"`. Playwright loaded the config via CJS, where `import.meta` is a syntax error. Resulted in: `SyntaxError: Cannot use 'import.meta' outside a module`.
- **Fix:** Removed the ESM shim. CJS provides `__dirname` natively, which `dotenvConfig({ path: path.resolve(__dirname, '.env.test') })` uses directly.
- **Files modified:** `playwright.config.ts`
- **Verification:** `npx playwright test --list` exits 0 (config parses, "Total: 0 tests in 0 files").
- **Committed in:** `58be97d` (Task 3 commit)

---

**Total deviations:** 3 auto-fixed (1 missing critical, 2 blocking)
**Impact on plan:** All three are config-correctness fixes for the test runners themselves. No scope creep — every change is required for the test stack to function. The plan template's ESM shim was a portability assumption that didn't hold at root (CJS) but was correct for backend (ESM).

## Issues Encountered

- **PowerShell `$env:` syntax not handled by Bash tool** — first `npm install` attempt at backend used PS-style `$env:NODE_ENV='development'`; Bash tool stripped `$` prefix. Switched to bash `NODE_ENV=development npm install` syntax which works in both PS and bash. Resolved on first retry.
- **No interactive prompts encountered** — both npm installs and Chromium download ran non-interactively as expected.

## User Setup Required

None — no external service configuration required for plan 21-01. The `.env.test.example` template is ready for QA to copy when they begin running tests in plan 21-02.

## Next Phase Readiness

- **Plan 21-02 (DB fixtures):** Can now author `database/seed/003_test_fixtures.sql` and a `tools/test-db-reset.ts` script; `test:db:reset` npm script alias is wired.
- **Plan 21-03 (mock servers):** `.env.test.example` already has `SMARTCA_BASE_URL`, `MYSIGN_BASE_URL`, `LGSP_ENDPOINT` placeholders pointing to ports 8181/8182/8183.
- **Plan 21-04 (auth fixtures):** `playwright.config.ts` has commented `globalSetup` placeholder ready to wire `tests/globalSetup.ts`.
- **Plan 21-05 (smoke + Excel parser):** Test runners working, JSON reporters configured (`tests/results/playwright-results.json` + `tests/results/vitest-{unit,integration}.json`) ready as input to Excel sync tool.
- **Plan 21-06 (CI workflow):** Stack stable, can wire `.github/workflows/test-pr.yml` with `npx playwright install chromium --with-deps` step on `ubuntu-latest`.
- **Concerns:** None blocking. The 3 legacy `.test.ts` files in `src/services/signing/` should eventually migrate to vitest (separate plan, not this milestone).

## Self-Check: PASSED

- `cd e_office_app_new/backend && npx vitest --version` → `vitest/2.1.9 win32-x64 node-v22.16.0` ✓
- `cd D:/ProjectAI/quanlyvanban && npx playwright --version` → `Version 1.59.1` ✓
- `cd e_office_app_new/backend && npx tsc --noEmit` → exit 0, no output (no TS errors) ✓
- `grep "test:smoke" package.json` → `"test:smoke": "playwright test --grep @smoke",` ✓
- `ls tests/.gitignore .env.test.example` → both files present ✓
- All 3 task commits exist on main: `91d7697`, `d657bd5`, `58be97d` ✓
- Chromium 1217 binary present in `%LOCALAPPDATA%\ms-playwright\` ✓

---
*Phase: 21-automation-foundation*
*Completed: 2026-05-06*
