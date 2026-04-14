# Testing Patterns

**Analysis Date:** 2026-04-14 (refreshed after Phase 4 completion)

## Test Framework

**Runner:** None installed.

Neither the backend nor frontend has a test framework configured:
- No `jest`, `vitest`, `mocha`, or `playwright` in `package.json` dependencies
- No `jest.config.*` or `vitest.config.*` files exist
- No `.test.ts`, `.spec.ts`, `.test.tsx`, or `.spec.tsx` files in project source code
- ESLint `lint` script exists in frontend (`npm run lint`) but no `test` script in either package

**Run Commands:**
```bash
# Frontend only — linting (no tests)
cd e_office_app_new/frontend && npm run lint

# Backend — no lint or test scripts
cd e_office_app_new/backend && npm run dev   # development only
```

## Manual API Testing

### Shell Script: `test_sprint3.sh`

**Location:** `e_office_app_new/backend/test_sprint3.sh`

**Pattern:**
```bash
#!/bin/bash
set -e
BASE="http://localhost:4000"

# Login to get token
LOGIN=$(curl -s -X POST "$BASE/api/auth/login" ...)
TOKEN=$(node -e "console.log(JSON.parse(process.argv[1]).data.accessToken)" "$LOGIN")
AUTH="Authorization: Bearer $TOKEN"

# Custom assert function
assert_json() {
  local TEST_NAME="$1"
  local EXPR="$2"        # JavaScript expression evaluated against response JSON
  local RESPONSE="$3"
}

# Tests
RESPONSE=$(curl -s -X GET "$BASE/api/van-ban-den" -H "$AUTH")
assert_json "List incoming docs" "j.success === true" "$RESPONSE"
```

**Covers:** Sprint 3 incoming document endpoints (list, create, update, detail, workflow actions). ~25 test sections for CRUD operations and edge cases.

**Characteristics:**
- Requires running backend server (`npm run dev`)
- Requires seeded database
- Uses `node -e` for JSON assertion evaluation
- Reports pass/fail count at end
- Idempotent design (safe to re-run)
- Only covers happy paths — no error path testing

### Seed Script: `seed_sprint5.js`

**Location:** `e_office_app_new/backend/seed_sprint5.js`

**Purpose:** Creates test data for HSCV module testing:
- Workflows with steps and links
- Handling documents (dossiers)
- Assignments and opinions
- Document links between HSCV and incoming/outgoing docs

### Demo Seed: `seed_demo.sql`

**Location:** `e_office_app_new/database/seed_demo.sql`

**Purpose:** SQL-based demo data for general testing.

## What Exists vs What's Missing

### Exists

| Area | Status |
|------|--------|
| Manual API smoke tests | `test_sprint3.sh` (Sprint 3 only) |
| Seed data scripts | `seed_sprint5.js`, `seed_demo.sql` |
| Frontend linting | ESLint with Next.js config |
| TypeScript strict mode | Both backend and frontend |
| Runtime validation | Zod in deps (not used) |

### Missing — Critical Gaps

**Backend Unit Tests:**
- No tests for any of the 30 repositories
- No tests for auth service (complex login/refresh logic)
- No tests for shared error-handler.ts constraint mapping
- No tests for middleware (authenticate, requireRoles)
- No tests for tree-utils, socket.ts
- Files at risk: `auth.service.ts`, `jwt.ts`, `query.ts`, `error-handler.ts`

**Backend Integration Tests:**
- `test_sprint3.sh` covers Sprint 3 only — Sprints 4-10 have no test scripts
- No error path testing (invalid tokens, constraint violations, concurrent access)
- No automated CI-compatible test runner

**Frontend Tests:**
- No component tests for any of the 40+ pages
- No tests for `api.ts` interceptor logic (token refresh flow)
- No tests for `auth.store.ts` state management
- No E2E tests (no Playwright/Cypress)

**Database Tests:**
- No tests for stored procedures
- No migration rollback testing

## Recommended Test Setup

### Backend (Vitest — recommended for ESM TypeScript)

```bash
npm install -D vitest @vitest/coverage-v8
```

**Priority test targets:**
1. `auth.service.ts` — login, refresh, token rotation
2. `jwt.ts` — sign/verify tokens
3. `error-handler.ts` — constraint mapping
4. `query.ts` — callFunction, withTransaction
5. Repository methods — correct SP calls with correct params

### Frontend (Vitest + React Testing Library)

```bash
npm install -D vitest @testing-library/react @testing-library/jest-dom jsdom
```

**Priority test targets:**
1. `api.ts` — interceptor and refresh logic
2. `auth.store.ts` — auth state transitions
3. Form validation patterns in admin pages

### E2E (Playwright)

Not installed. Would be valuable for testing full login → CRUD → drawer flows.

## Mocking Targets

If tests are added:
- `pg` pool for backend repository tests
- `lib/db/pool.ts` — database connection
- `lib/api.ts` — Axios instance for frontend tests
- `localStorage` for auth store tests
- `globalThis.__io` for socket.ts tests

---

*Testing analysis: 2026-04-14 (refreshed)*
