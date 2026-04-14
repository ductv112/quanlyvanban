# Codebase Concerns

**Analysis Date:** 2026-04-14

## Tech Debt

**Monolithic Route Files:**
- Issue: Route handlers contain all business logic inline (validation, DB queries, response formatting) instead of using a service layer. Two files are excessively large.
- Files: `e_office_app_new/backend/src/routes/admin-catalog.ts` (1492 lines), `e_office_app_new/backend/src/routes/admin.ts` (891 lines)
- Impact: Difficult to test, reuse, or refactor. Adding new catalog entities requires editing a single massive file. Code review is painful.
- Fix approach: Extract each catalog entity's handlers into separate route files (e.g., `routes/admin/doc-book.ts`, `routes/admin/doc-type.ts`). Create a service layer between routes and repositories.

**Duplicated Tree Utilities Across Admin Pages:**
- Issue: `buildTree`, `filterTree`, `flattenTreeForSelect`, and `TreeNode` type are copy-pasted identically across 6+ admin page components instead of being shared utilities.
- Files: `e_office_app_new/frontend/src/app/(main)/quan-tri/don-vi/page.tsx`, `e_office_app_new/frontend/src/app/(main)/quan-tri/nguoi-dung/page.tsx`, `e_office_app_new/frontend/src/app/(main)/quan-tri/nguoi-ky/page.tsx`, `e_office_app_new/frontend/src/app/(main)/quan-tri/chuc-nang/page.tsx`, `e_office_app_new/frontend/src/app/(main)/quan-tri/loai-van-ban/page.tsx`, `e_office_app_new/frontend/src/app/(main)/quan-tri/nhom-quyen/page.tsx`
- Impact: Bug fixes must be applied in 6 places. Risk of diverging implementations.
- Fix approach: Extract to `e_office_app_new/frontend/src/lib/tree-utils.ts` (functions) and `e_office_app_new/frontend/src/types/tree.ts` (TreeNode type). Import in all pages.

**Duplicated Error Handler Pattern in Routes:**
- Issue: `handleDbError()` function is duplicated between `admin.ts` and `admin-catalog.ts` with the same PostgreSQL constraint-to-message mapping logic.
- Files: `e_office_app_new/backend/src/routes/admin-catalog.ts` (line 21), `e_office_app_new/backend/src/routes/admin.ts`
- Impact: Adding new constraint messages requires changes in multiple files.
- Fix approach: Extract to shared middleware or utility in `e_office_app_new/backend/src/lib/error-handler.ts`.

**Oversized Frontend Page Components:**
- Issue: Many admin pages are 300-800+ lines of monolithic single-file components combining table, drawer, form, tree, and all state management.
- Files: `e_office_app_new/frontend/src/app/(main)/quan-tri/nguoi-dung/page.tsx` (811 lines), `e_office_app_new/frontend/src/app/(main)/van-ban-du-thao/page.tsx` (644 lines), `e_office_app_new/frontend/src/app/(main)/quan-tri/nhom-lam-viec/page.tsx` (508 lines), `e_office_app_new/frontend/src/app/(main)/quan-tri/don-vi/page.tsx` (490 lines)
- Impact: Hard to maintain, test, and review. Slow IDE performance.
- Fix approach: Extract drawer forms, table columns, and tree panels into sub-components per page.

**Unimplemented Background Workers:**
- Issue: All 4 BullMQ workers (email, SMS, LGSP, FCM) are registered but contain only TODO stubs with no actual implementation.
- Files: `e_office_app_new/workers/src/index.ts` (lines 23, 33, 43, 53)
- Impact: No email notifications, no SMS alerts, no LGSP integration, no push notifications. Any code that enqueues jobs to these queues will silently succeed but produce no effect.
- Fix approach: Implement one worker at a time. Email (nodemailer) is highest priority as it blocks user notifications.

**MongoDB and Redis Clients Unused in Application Code:**
- Issue: MongoDB client (`mongoose.connect`) and Redis client (`ioredis`) are defined but never imported by any route or repository. MongoDB is imported nowhere. Redis is only imported in `health.ts` for health checks.
- Files: `e_office_app_new/backend/src/lib/mongodb/client.ts`, `e_office_app_new/backend/src/lib/redis/client.ts`
- Impact: Dead code. MongoDB dependency (mongoose) adds ~2MB to node_modules for no benefit. Redis caching utilities (`getOrCache`, `invalidateCache`) exist but are unused — all requests hit PostgreSQL directly.
- Fix approach: Either implement Redis caching for frequently-read catalog data (doc types, positions, departments) or remove the unused clients until needed. Do NOT remove the Redis client if workers depend on Redis for BullMQ.

**Zod Installed but Never Used:**
- Issue: Zod v4.3.6 is listed in `package.json` dependencies but no file imports from it. All request validation is done manually with `if (!name?.trim())` checks inline in route handlers.
- Files: `e_office_app_new/backend/package.json` (line 34)
- Impact: Inconsistent validation. Easy to miss required fields. No schema reuse between create/update endpoints.
- Fix approach: Define Zod schemas in `e_office_app_new/shared/src/schemas/` and use a validation middleware to parse `req.body` before handlers execute.

**All Frontend Pages Are Client Components:**
- Issue: Every page under `app/(main)/` uses `'use client'` directive (27 pages). Zero server components in the main app layout. This negates Next.js SSR/RSC benefits entirely.
- Files: All 27 files under `e_office_app_new/frontend/src/app/(main)/`
- Impact: Larger JS bundle sent to client, slower initial page loads, no SEO benefit from SSR. The app behaves as a traditional SPA despite using Next.js.
- Fix approach: This is acceptable for an internal admin dashboard where SEO is irrelevant. However, consider server components for layout shells and data fetching where possible.

**Shared Package Not Consumed:**
- Issue: A `shared/` package exists with types (`api.ts`, `auth.ts`) and constants, but neither backend nor frontend imports from it.
- Files: `e_office_app_new/shared/src/types/api.ts`, `e_office_app_new/shared/src/types/auth.ts`, `e_office_app_new/shared/src/constants/index.ts`
- Impact: Types are duplicated between frontend and backend instead of being shared. API response shapes may drift.
- Fix approach: Configure TypeScript path aliases or npm workspace linking so both backend and frontend import from `@shared/types`.

## Security Considerations

**JWT Secret Fallback to Hardcoded Value:**
- Risk: If `JWT_SECRET` env var is missing, the application silently falls back to `'fallback-secret'`, a publicly visible string in source code. Any attacker can forge valid JWT tokens.
- Files: `e_office_app_new/backend/src/lib/auth/jwt.ts` (line 3)
- Current mitigation: None. The fallback is used silently.
- Recommendations: Throw an error on startup if `JWT_SECRET` is not set. Add a startup check in `server.ts` that validates all required env vars before listening.

**Access Token Stored in localStorage (XSS Vulnerability):**
- Risk: The access token is stored in `localStorage` and attached to requests via an Axios interceptor. Any XSS vulnerability gives attackers full access to the token.
- Files: `e_office_app_new/frontend/src/stores/auth.store.ts` (lines 43, 57), `e_office_app_new/frontend/src/lib/api.ts` (lines 15-17, 33-34)
- Current mitigation: Refresh token is correctly stored as httpOnly cookie. Helmet is used on backend.
- Recommendations: Move access token to httpOnly cookie or use a BFF (Backend For Frontend) pattern. If localStorage must be used, ensure strict CSP headers prevent inline scripts.

**No Rate Limiting on Any Endpoint:**
- Risk: Login endpoint (`/api/auth/login`) and all API endpoints have no rate limiting. Brute force attacks on login are trivial. API abuse can cause resource exhaustion.
- Files: `e_office_app_new/backend/src/server.ts`, `e_office_app_new/backend/src/routes/auth.ts`
- Current mitigation: None.
- Recommendations: Add `express-rate-limit` middleware. At minimum: 5 attempts/minute on `/api/auth/login`, 100 requests/minute on general API endpoints.

**No RBAC Enforcement on Routes:**
- Risk: The `requireRoles()` middleware exists in `e_office_app_new/backend/src/middleware/auth.ts` (line 26) but is NEVER used in any route file. All authenticated users can access all admin endpoints.
- Files: `e_office_app_new/backend/src/middleware/auth.ts`, `e_office_app_new/backend/src/routes/admin.ts`, `e_office_app_new/backend/src/routes/admin-catalog.ts`
- Current mitigation: None. Authentication is enforced, but authorization is not.
- Recommendations: Apply `requireRoles('ADMIN')` to all admin routes. Define role constants and apply per-route.

**No File Upload Validation:**
- Risk: The multer upload middleware accepts any file type with a 50MB limit. No file extension or MIME type validation. Malicious files (executables, scripts) can be uploaded to MinIO.
- Files: `e_office_app_new/backend/src/middleware/upload.ts`
- Current mitigation: Files stored in MinIO with presigned URLs (not served directly), which limits direct execution risk.
- Recommendations: Add `fileFilter` to multer config restricting to allowed extensions (pdf, doc, docx, xls, xlsx, jpg, png). Validate MIME type server-side.

**No CSRF Protection:**
- Risk: No CSRF tokens are used. The backend relies on CORS origin checking only.
- Files: `e_office_app_new/backend/src/server.ts` (line 29)
- Current mitigation: CORS configured with specific origin and `credentials: true`. SameSite cookie is `lax`.
- Recommendations: For an internal app with cookie-based refresh tokens, CORS + SameSite=lax provides reasonable protection. Consider adding CSRF tokens if the app becomes externally accessible.

**No Audit Logging:**
- Risk: No record of who changed what and when. Critical for a government document management system where traceability is often legally required.
- Files: No audit logging code exists anywhere in the backend.
- Current mitigation: PostgreSQL stored procedures may track `created_by`/`updated_by` fields, but there is no dedicated audit trail table or middleware.
- Recommendations: Create an `audit_log` table. Add middleware or repository wrapper that logs all CUD operations with staff_id, action, entity, old_value, new_value, timestamp.

## Performance Bottlenecks

**No Database Query Caching:**
- Problem: Every API request hits PostgreSQL directly. Frequently-read catalog data (positions, departments, doc types, doc fields) is fetched on every page load.
- Files: `e_office_app_new/backend/src/lib/redis/client.ts` (caching utils exist but unused), all repository files under `e_office_app_new/backend/src/repositories/`
- Cause: Redis `getOrCache()` and `invalidateCache()` utilities are implemented but never called.
- Improvement path: Wrap catalog repository reads with `getOrCache()`. Invalidate on create/update/delete. Start with `position.repository.ts`, `doc-type.repository.ts`, `doc-field.repository.ts`.

**Large JSON Payload Limit:**
- Problem: Express JSON body parser is set to `50mb` limit. Combined with `multer` memory storage also at 50MB, a single request can consume 100MB+ of server memory.
- Files: `e_office_app_new/backend/src/server.ts` (line 31), `e_office_app_new/backend/src/middleware/upload.ts` (line 3)
- Cause: Generous defaults without considering concurrent uploads.
- Improvement path: Reduce JSON limit to 1-5MB (JSON payloads should not be 50MB). Keep file upload limit separate. Consider streaming uploads to MinIO instead of buffering in memory.

**Frontend Fetches All Records Without Pagination on Some Pages:**
- Problem: Admin catalog pages load all records into memory. For tables with few hundred rows this is acceptable, but `dia-ban` (addresses/regions) and `nguoi-dung` (users) could grow to thousands.
- Files: `e_office_app_new/frontend/src/app/(main)/quan-tri/dia-ban/page.tsx`, `e_office_app_new/frontend/src/app/(main)/quan-tri/nguoi-dung/page.tsx`
- Cause: `fetchData()` calls API without pagination params, loads full dataset into state.
- Improvement path: Implement server-side pagination for large tables. The stored procedures likely already support `LIMIT/OFFSET` parameters.

## Fragile Areas

**Admin Catalog Route File:**
- Files: `e_office_app_new/backend/src/routes/admin-catalog.ts` (1492 lines)
- Why fragile: 12 different entity CRUD operations in one file. A typo in one handler's error message constant can break another entity's error handling due to shared `handleDbError()`. No tests to catch regressions.
- Safe modification: When adding a new catalog entity, add it at the end of the file. Better yet, extract to a new route file.
- Test coverage: Zero automated tests.

**Authentication Flow:**
- Files: `e_office_app_new/backend/src/lib/auth/jwt.ts`, `e_office_app_new/backend/src/routes/auth.ts`, `e_office_app_new/frontend/src/stores/auth.store.ts`, `e_office_app_new/frontend/src/lib/api.ts`
- Why fragile: Token refresh logic in the Axios interceptor (`api.ts` lines 23-37) retries failed requests but has no guard against infinite retry loops if the refresh endpoint itself returns 401. The `isRefreshing` flag is a local variable, not a ref, which could cause race conditions with concurrent requests.
- Safe modification: Test the full login -> access expired -> refresh -> retry flow manually after any change to auth files.
- Test coverage: Zero automated tests.

**Tree Data Mapping in Frontend:**
- Files: 6 admin pages (listed in Tech Debt section above)
- Why fragile: Each page has its own copy of tree utilities. API response shape changes (e.g., renaming `parent_id` to `parentId`) would require updating all 6 files independently.
- Safe modification: Search all files for `TreeNode` before changing any tree-related API response.
- Test coverage: Zero automated tests.

## Scaling Limits

**PostgreSQL Connection Pool:**
- Current capacity: 20 max connections (configurable via `PG_MAX_CONNECTIONS`)
- Limit: With no caching and every request hitting PG, 20 connections can handle roughly 100-200 concurrent users depending on query complexity.
- Scaling path: Enable Redis caching for reads. Increase pool size. Consider PgBouncer for connection pooling at higher scale.
- Files: `e_office_app_new/backend/src/lib/db/pool.ts`

**Single-Process Backend:**
- Current capacity: One Express process, single-threaded Node.js.
- Limit: CPU-bound operations (bcrypt hashing on login, large JSON serialization) block the event loop.
- Scaling path: Use PM2 cluster mode or deploy multiple instances behind a load balancer. Offload heavy work to BullMQ workers (once implemented).
- Files: `e_office_app_new/backend/src/server.ts`

## Dependencies at Risk

**No Lockfile Hygiene Check:**
- Risk: Both `package.json` and `package-lock.json` exist for backend, but no CI/CD pipeline validates that `npm ci` succeeds. Dependency drift between environments is possible.
- Impact: "Works on my machine" issues during deployment.
- Migration plan: Add CI pipeline with `npm ci` step.

## Missing Critical Features

**No Notification System:**
- Problem: Workers for email, SMS, LGSP, and FCM push are all stubs. The frontend has a notification bell icon with a `TODO: notification drawer` comment.
- Files: `e_office_app_new/workers/src/index.ts`, `e_office_app_new/frontend/src/components/layout/MainLayout.tsx` (line 293)
- Blocks: Users cannot receive alerts about new documents, approvals, or deadlines.

**No Search Functionality:**
- Problem: No full-text search across documents. The current UI only has basic column filters on tables.
- Blocks: Users must manually browse to find documents instead of searching by content or metadata.

**No File Preview:**
- Problem: Documents uploaded to MinIO can only be downloaded. No in-browser preview for PDF or image files.
- Blocks: Users must download every file to view it, slowing workflow.

## Test Coverage Gaps

**Zero Automated Tests:**
- What's not tested: The entire codebase. No test files exist outside `node_modules/`. No test runner is configured (no jest.config, vitest.config, or test scripts in package.json).
- Files: All files under `e_office_app_new/backend/src/` and `e_office_app_new/frontend/src/`
- Risk: Any refactoring (especially the monolithic route files) could introduce regressions with no safety net. Authentication flow changes are particularly dangerous.
- Priority: **High** - Start with:
  1. Auth flow (login, refresh, token verification) - highest business impact
  2. Repository functions (stored procedure calls with correct params)
  3. Admin CRUD operations (create/update/delete with validation)

**No E2E Tests:**
- What's not tested: User flows like login -> navigate -> create document -> upload file -> submit for approval.
- Risk: Integration issues between frontend and backend are only caught manually.
- Priority: **Medium** - Add Playwright or Cypress tests for critical paths after unit tests exist.

---

*Concerns audit: 2026-04-14*
