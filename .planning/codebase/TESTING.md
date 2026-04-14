# Testing Patterns

**Analysis Date:** 2026-04-14

## Test Framework

**Runner:** None installed.

Neither the backend nor frontend has a test framework configured:
- No `jest`, `vitest`, `mocha`, or `playwright` in `package.json` dependencies
- No `jest.config.*` or `vitest.config.*` files exist
- No `.test.ts`, `.spec.ts`, `.test.tsx`, or `.spec.tsx` files in project source code
- ESLint `lint` script exists in frontend (`npm run lint`) but no `test` script in either package

**Assertion Library:** None

**Run Commands:**
```bash
# Frontend only — linting (no tests)
cd e_office_app_new/frontend && npm run lint

# Backend — no lint or test scripts
cd e_office_app_new/backend && npm run dev   # development only
```

## Manual API Testing

The project uses **shell scripts with curl** for manual API integration testing instead of automated test suites.

**Location:** `e_office_app_new/backend/test_sprint4.sh`

**Pattern:**
```bash
#!/bin/bash
set -e

BASE="http://localhost:4000"

# Login to get token
LOGIN=$(curl -s -X POST "$BASE/api/auth/login" \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"Admin@123"}')
TOKEN=$(node -e "console.log(JSON.parse(process.argv[1]).data.accessToken)" "$LOGIN")
AUTH="Authorization: Bearer $TOKEN"

# Custom assert function
assert_json() {
  local TEST_NAME="$1"
  local EXPR="$2"        # JavaScript expression evaluated against response JSON
  local RESPONSE="$3"
  # Uses node -e to evaluate and prints pass/fail
}

# Example test
RESPONSE=$(curl -s -X GET "$BASE/api/van-ban-du-thao" -H "$AUTH")
assert_json "List drafting docs" "j.success === true" "$RESPONSE"
```

**Characteristics:**
- Requires running backend server (`npm run dev`)
- Requires seeded database (matching seed scripts like `e_office_app_new/backend/seed_sprint4.js`)
- Tests are sprint-scoped: one shell script per sprint
- Uses `node -e` for JSON assertion evaluation
- Reports pass/fail count at end
- Idempotent design (safe to re-run)

## Test File Organization

**Location:** No test directory structure exists.

**Current state:**
- No `__tests__/` directories
- No co-located test files
- No test utilities, fixtures, or factories

## Coverage

**Requirements:** None enforced. No coverage tooling installed.

## What Exists vs What's Missing

### Exists

| Area | Status |
|------|--------|
| Manual API smoke tests | Shell scripts with curl (`test_sprint4.sh`) |
| Frontend linting | ESLint with Next.js config |
| TypeScript strict mode | Both backend and frontend |
| Runtime validation | Zod available in deps (not widely used yet) |

### Missing — Critical Gaps

**Backend Unit Tests:**
- No tests for repositories (DB query wrappers)
- No tests for services (`auth.service.ts` has complex logic untested)
- No tests for `handleDbError` error mapping
- No tests for middleware (`authenticate`, `requireRoles`)
- No tests for `buildTree` utility (duplicated in `admin.ts` and `admin-catalog.ts`)
- Files at risk: `e_office_app_new/backend/src/services/auth.service.ts`, `e_office_app_new/backend/src/lib/auth/jwt.ts`, `e_office_app_new/backend/src/lib/db/query.ts`

**Backend Integration Tests:**
- Shell scripts cover happy paths only
- No error path testing (invalid tokens, constraint violations, concurrent access)
- No automated CI-compatible test runner

**Frontend Tests:**
- No component tests for any page
- No tests for `e_office_app_new/frontend/src/lib/api.ts` interceptor logic (token refresh flow)
- No tests for `e_office_app_new/frontend/src/stores/auth.store.ts` state management
- No E2E tests (no Playwright/Cypress)

**Database Tests:**
- No tests for stored procedures
- No migration rollback testing
- Files: `e_office_app_new/database/migrations/*.sql`

## Recommended Test Setup

If testing is to be added, the recommended approach based on the existing stack:

### Backend (Vitest — recommended for ESM TypeScript)

```bash
# Install
npm install -D vitest @vitest/coverage-v8
```

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';
export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    include: ['src/**/*.test.ts'],
  },
});
```

**Priority test targets:**
1. `e_office_app_new/backend/src/services/auth.service.ts` — login, refresh, token rotation
2. `e_office_app_new/backend/src/lib/auth/jwt.ts` — sign/verify tokens
3. `e_office_app_new/backend/src/lib/db/query.ts` — callFunction, withTransaction
4. `handleDbError` — PostgreSQL error code mapping (extract to shared module first)
5. `buildTree` — tree construction from flat list (extract to shared utility first)

### Frontend (Vitest + React Testing Library)

```bash
# Install
npm install -D vitest @testing-library/react @testing-library/jest-dom jsdom
```

**Priority test targets:**
1. `e_office_app_new/frontend/src/lib/api.ts` — interceptor logic
2. `e_office_app_new/frontend/src/stores/auth.store.ts` — auth state transitions
3. Form validation patterns in admin pages

### E2E (Playwright)

Not installed. Would be valuable for testing the full login flow, CRUD operations, and drawer interactions.

## Mocking

**Framework:** Not applicable (no tests exist)

**If added, mock targets would be:**
- `pg` pool for backend repository tests
- `e_office_app_new/backend/src/lib/db/pool.ts` — database connection
- `e_office_app_new/frontend/src/lib/api.ts` — Axios instance for frontend tests
- `localStorage` for auth store tests

## Seed Data

Test data is managed through seed scripts:
- `e_office_app_new/backend/seed_sprint4.js` — Sprint 4 test data
- Database migrations in `e_office_app_new/database/migrations/` — schema setup

No fixture factories or test data builders exist.

---

*Testing analysis: 2026-04-14*
