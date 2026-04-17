# Codebase Concerns

**Analysis Date:** 2026-04-14 (refreshed after Phase 4 completion)

## Tech Debt

**Monolithic Route Files:**
- Issue: Two route files contain all business logic inline (validation, DB queries, response formatting) instead of using a service layer.
- Files: `admin-catalog.ts` (1447 lines), `admin.ts` (853 lines)
- Impact: Difficult to test, reuse, or refactor. Code review is painful.
- Fix: Extract each catalog entity's handlers into separate route files. Create service layer.

**Oversized Frontend Page Components:**
- Issue: Many pages are 400-1670 lines of monolithic single-file components combining table, drawer, form, tree, and all state management.
- Top offenders:
  - `ho-so-cong-viec/[id]/page.tsx` — **1670 lines** (HSCV detail, 6 tabs)
  - `quan-tri/quy-trinh/[id]/thiet-ke/page.tsx` — 786 lines (ReactFlow designer)
  - `quan-tri/nguoi-dung/page.tsx` — 785 lines
  - `ho-so-cong-viec/page.tsx` — 713 lines
  - `van-ban-den/[id]/page.tsx` — 662 lines
  - `van-ban-du-thao/page.tsx` — 644 lines
  - `ho-so-cong-viec/bao-cao/page.tsx` — 619 lines
  - `dashboard/page.tsx` — 541 lines
  - `tin-nhan/page.tsx` — 516 lines
  - `quan-tri/nhom-lam-viec/page.tsx` — 508 lines
- Fix: Extract drawer forms, table columns, and tab panels into sub-components.

**Duplicated Types Across Detail Pages:**
- Issue: `Attachment`, `HistoryEvent`, and status tag helper interfaces/functions are duplicated across multiple detail pages (van-ban-den, van-ban-du-thao, van-ban-di, van-ban-lien-thong, ho-so-cong-viec).
- Impact: Changes must be applied in 4-5 places.
- Fix: Extract to `frontend/src/types/document.ts` and `frontend/src/lib/doc-utils.ts`.

**Tree Utils Mostly Extracted (Phase 1 fix):**
- Status: `buildTree`, `filterTree`, `flattenTreeForSelect` extracted to `frontend/src/lib/tree-utils.ts`. Most admin pages now import from shared module.
- Remaining: Check if `loai-van-ban/page.tsx` still has inline tree utils.

**Error Handler Extracted (Phase 1 fix):**
- Status: `handleDbError` extracted to `backend/src/lib/error-handler.ts`. All route files import the shared version.

**Unimplemented Background Workers:**
- Issue: All 4 BullMQ workers (email, SMS, LGSP, FCM) are stubs with no implementation.
- Files: `workers/src/index.ts`
- Impact: No email/SMS/push notifications. Jobs enqueued will silently produce no effect.

**MongoDB and Redis Clients Unused:**
- Issue: MongoDB client and Redis client defined but never imported by application code. Redis only used in health check.
- Impact: Dead code. MongoDB dependency (~2MB) provides no benefit. Redis caching utils (`getOrCache`, `invalidateCache`) exist but unused.

**Zod Installed but Never Used:**
- Issue: Zod v4.3.6 in backend deps but no file imports it. All validation is manual `if (!name?.trim())` checks.
- Impact: Inconsistent validation. Easy to miss required fields.

**Shared Package Not Consumed:**
- Issue: `shared/` package has types and constants, but neither backend nor frontend imports from it.
- Impact: Types duplicated between frontend and backend. API response shapes may drift.

**All Frontend Pages Are Client Components:**
- Issue: Every page uses `'use client'` (40+ pages). Zero server components.
- Impact: Larger JS bundle, no SSR benefits. Acceptable for internal admin dashboard.

## Security Considerations

**JWT Secret Fallback to Hardcoded Value:**
- Risk: **CRITICAL** — If `JWT_SECRET` env var is missing, falls back to `'fallback-secret'` visible in source.
- File: `backend/src/lib/auth/jwt.ts`
- Fix: Throw on startup if `JWT_SECRET` not set. Add env validation in `server.ts`.

**No Startup Environment Validation:**
- Risk: Server starts silently with missing env vars (DB connection, JWT secret, MinIO config).
- Fix: Add startup check that validates all required env vars before listening.

**Access Token in localStorage (XSS Risk):**
- Risk: Any XSS gives attackers full access to the token.
- Files: `frontend/src/stores/auth.store.ts`, `frontend/src/lib/api.ts`
- Mitigation: Refresh token correctly uses httpOnly cookie. Helmet on backend.

**No Rate Limiting:**
- Risk: Login brute force is trivial. API abuse can cause resource exhaustion.
- Fix: Add `express-rate-limit` — 5 attempts/min on login, 100 req/min general.

**requireRoles Middleware Exists but Rarely Used:**
- Risk: `requireRoles()` in `middleware/auth.ts` is imported only in `calendar.ts`. All other admin routes are unprotected — any authenticated user can access admin endpoints.
- Fix: Apply `requireRoles('ADMIN')` to admin routes.

**No File Upload Validation:**
- Risk: Multer accepts any file type with 50MB limit. No extension/MIME validation.
- Mitigation: Files stored in MinIO with presigned URLs (not served directly).
- Fix: Add `fileFilter` restricting to allowed extensions.

**No CSRF Protection:**
- Risk: No CSRF tokens. Relies on CORS origin checking only.
- Mitigation: CORS + SameSite=lax provides reasonable protection for internal app.

**No Audit Logging:**
- Risk: No record of who changed what. Critical for government document management.
- Fix: Create `audit_log` table + middleware for all CUD operations.

## Performance Bottlenecks

**No Database Query Caching:**
- Problem: Every request hits PostgreSQL directly. Catalog data (positions, departments, doc types) fetched on every page load.
- Redis caching utils exist but are never called.

**Large JSON Payload Limit:**
- Problem: Express JSON parser set to `50mb`. Combined with multer 50MB = 100MB+ per request in memory.
- Fix: Reduce JSON limit to 1-5MB. Consider streaming uploads to MinIO.

**Frontend Fetches Without Pagination on Some Pages:**
- Problem: Some admin catalog pages load all records. Tables like `dia-ban` (addresses) could grow to thousands.
- Fix: Server-side pagination for large tables.

**Socket.IO Uses globalThis Pattern:**
- Problem: `(globalThis as any).__io = io` for cross-module access. Not type-safe, no cleanup.
- Fix: Use dependency injection or module-level singleton with proper typing.

**No Code Splitting:**
- Problem: All 40+ pages bundled as client components. No dynamic imports for heavy components like ReactFlow.
- Fix: `dynamic(() => import(...), { ssr: false })` for ReactFlow and other heavy libs.

## Code Quality Issues

**`any` Usage:**
- ~180+ `any` usages across frontend files and some backend route files.
- Most common: `catch (err: any)`, `as any` type assertions, untyped API responses.

**Silent Catch Blocks:**
- ~50+ catch blocks that either swallow errors silently or only log to console.
- Risk: Errors hidden from users, difficult debugging.

**Missing Error Boundaries:**
- No React error boundaries anywhere in the frontend.
- A single component crash takes down the entire page.

**Missing Loading States:**
- No Suspense boundaries or loading.tsx files for route transitions.
- Pages show blank until data loads.

**No Route Param Validation:**
- Detail pages use `useParams()` to get `id` but never validate it's a valid number before API calls.
- Fix: Add `parseInt` + NaN check before fetch.

## Architecture Concerns

**No Service Layer (Backend):**
- Routes call repositories directly. Business logic (validation, authorization, orchestration) lives inline in route handlers.
- Only `auth.service.ts` exists as a service.
- Impact: Cannot reuse business logic across routes.

**Express 5 Early Adoption:**
- Backend uses Express 5 (RC). API may have breaking changes before stable release.
- Risk: Low — the project uses standard Express patterns that are stable.

**Memory-Based Upload:**
- Multer uses `memoryStorage()` — entire files buffered in RAM before MinIO upload.
- Risk: Concurrent large uploads can exhaust server memory.
- Fix: Switch to multer disk storage or stream directly to MinIO.

## Operational Concerns

**No Containerization:**
- No Dockerfile or docker-compose.yml for the application.
- Only PostgreSQL runs in Docker (via init scripts).

**No Migration Runner:**
- SQL migrations run manually in numeric order. No tool tracks which have been applied.
- Risk: Missed migrations in deployment, no rollback capability.

**Logging Gaps:**
- `handleDbError` returns error to client but doesn't log it server-side.
- Only the global error handler in `server.ts` logs via pino.
- Fix: Add `logger.error(error)` in handleDbError before responding.

**No Health Check Depth:**
- `health.ts` checks PostgreSQL, Redis, MongoDB, MinIO. But Redis and MongoDB aren't used.
- Fix: Only check services actually in use.

## Test Coverage Gaps

**Zero Automated Tests:**
- No test files exist. No test runner configured.
- Only `test_sprint3.sh` for manual curl testing of Sprint 3 endpoints.
- Risk: Any refactoring could introduce regressions with no safety net.
- Priority: Auth flow, repositories, admin CRUD operations.
- See [TESTING.md](TESTING.md) for detailed analysis.

## Fragile Areas

**Authentication Flow:**
- Files: `jwt.ts`, `auth.ts` (route), `auth.store.ts`, `api.ts`
- Token refresh logic in Axios interceptor has no guard against infinite retry loops if refresh endpoint returns 401.

**Admin Catalog Route:**
- File: `admin-catalog.ts` (1447 lines)
- 12 entity CRUD operations in one file. No tests.

**HSCV Detail Page:**
- File: `ho-so-cong-viec/[id]/page.tsx` (1670 lines)
- Largest file in codebase. 6 tabs, complex state. Extremely difficult to modify safely.

---

*Concerns audit: 2026-04-14 (refreshed)*
