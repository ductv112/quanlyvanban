# Architecture

**Analysis Date:** 2026-04-14

## Pattern Overview

**Overall:** Repository Pattern with PostgreSQL Stored Procedures (no ORM)

**Key Characteristics:**
- Two-tier backend: Express routes call repositories directly (no service layer for most modules; auth is the exception with `auth.service.ts`)
- All data access goes through PostgreSQL stored functions/procedures — no raw SQL in application code (except the query helpers)
- Frontend is a Next.js App Router SPA that talks to the backend via REST API (axios)
- State management via Zustand stores on the frontend
- File storage via MinIO (S3-compatible object storage)
- JWT-based authentication with access/refresh token rotation

## Layers

**Frontend — Next.js App Router (React 19 + Ant Design 6):**
- Purpose: Client-side SPA with server-side layout rendering
- Location: `e_office_app_new/frontend/src/`
- Contains: Pages (App Router), components, stores, hooks, lib utilities
- Depends on: Backend REST API via axios
- Used by: End users (browser)

**Backend — Express 5 REST API:**
- Purpose: HTTP API layer — receives requests, validates, calls repositories, returns JSON
- Location: `e_office_app_new/backend/src/`
- Contains: Routes, middleware, repositories, services, lib (DB/auth/MinIO/Redis/MongoDB clients)
- Depends on: PostgreSQL (via pg pool), MinIO, MongoDB, Redis
- Used by: Frontend

**Database — PostgreSQL with Stored Functions:**
- Purpose: All business logic and data validation lives in stored procedures/functions
- Location: `e_office_app_new/database/`
- Contains: Schema creation scripts, migration SQL files with stored procedures
- Depends on: PostgreSQL extensions (uuid-ossp, pgcrypto, unaccent, pg_trgm)
- Used by: Backend repositories via `callFunction()` / `callFunctionOne()`

**Shared — Constants and Types:**
- Purpose: Shared TypeScript types and constants used by both frontend and backend
- Location: `e_office_app_new/shared/src/`
- Contains: API response types, auth types, business constants (urgent levels, secret levels, doc statuses)
- Used by: Frontend and backend

**Workers — Background Jobs (stub):**
- Purpose: BullMQ-based background job processing
- Location: `e_office_app_new/workers/src/`
- Contains: Job definitions and queue configurations (currently empty/stub)
- Depends on: Redis (via ioredis), BullMQ

## Data Flow

**Typical CRUD Request (e.g., create incoming document):**

1. Frontend page calls `api.post('/van-ban-den', payload)` using the axios instance at `frontend/src/lib/api.ts`
2. Axios interceptor attaches `Authorization: Bearer <accessToken>` from localStorage
3. Express receives request at `backend/src/routes/incoming-doc.ts`
4. `authenticate` middleware (`backend/src/middleware/auth.ts`) verifies JWT via `jose` library
5. Route handler extracts `staffId`/`unitId` from `(req as AuthRequest).user`
6. Route handler calls repository method: `incomingDocRepository.create(...)`
7. Repository calls `callFunction('edoc.fn_incoming_doc_create', [params...])` from `backend/src/lib/db/query.ts`
8. `query.ts` builds `SELECT * FROM edoc.fn_incoming_doc_create($1, $2, ...)` and executes via `pg.Pool`
9. PostgreSQL stored function performs validation, inserts data, returns result
10. Route handler returns `{ success: true, data: ... }` JSON response

**Authentication Flow:**

1. Frontend calls `useAuthStore().login(username, password)` which posts to `/api/auth/login`
2. `auth.service.ts` verifies credentials via `authRepository.findByUsername()`
3. Service generates access token (15min) + refresh token (7d) via `jose` library (`backend/src/lib/auth/jwt.ts`)
4. Refresh token hash stored in DB; raw refresh token set as httpOnly cookie
5. Access token returned in response body, stored in `localStorage` by frontend
6. On 401, axios interceptor auto-refreshes via `POST /api/auth/refresh` (token rotation)

**File Upload Flow:**

1. Frontend sends multipart form data
2. `multer` middleware (`backend/src/middleware/upload.ts`) stores file in memory buffer
3. Route handler uploads buffer to MinIO via `uploadFile()` (`backend/src/lib/minio/client.ts`)
4. MinIO object path stored in PostgreSQL
5. File download returns presigned URL from MinIO via `getFileUrl()`

**State Management:**

- Zustand store at `frontend/src/stores/auth.store.ts` holds user session state
- Each page component manages its own local state (Ant Design table pagination, form state, etc.)
- No global data cache — pages fetch data on mount via `useEffect` + `api.get()`

## Key Abstractions

**Repository Pattern:**
- Purpose: Encapsulate all database calls behind typed interfaces
- Examples: `backend/src/repositories/department.repository.ts`, `backend/src/repositories/incoming-doc.repository.ts`, `backend/src/repositories/auth.repository.ts`
- Pattern: Each repository exports a const object with async methods. Methods call `callFunction<T>()` or `callFunctionOne<T>()` with the PostgreSQL function name and parameters.

**Query Helpers (`backend/src/lib/db/query.ts`):**
- `callFunction<T>(name, params)` — calls a PostgreSQL function, returns array of rows
- `callFunctionOne<T>(name, params)` — calls a function, returns first row or null
- `callProcedure(name, params)` — calls a PostgreSQL procedure (void)
- `rawQuery<T>(sql, params)` — escape hatch for ad-hoc SQL
- `withTransaction<T>(callback)` — wraps callback in BEGIN/COMMIT/ROLLBACK

**Route Modules:**
- Purpose: Group related endpoints into Express Router instances
- Examples: `backend/src/routes/admin.ts` (departments, positions, staff, roles, rights), `backend/src/routes/admin-catalog.ts` (doc books, doc types, fields, signers, work groups, delegations, addresses, calendars, templates, config), `backend/src/routes/incoming-doc.ts`
- Pattern: Each file creates a Router, defines route handlers inline (no controller classes), and exports default router

**PostgreSQL Stored Functions:**
- Naming convention: `[schema].fn_[entity]_[action]` (e.g., `edoc.fn_incoming_doc_create`, `public.fn_department_get_tree`)
- `public` schema: system entities (departments, staff, roles, positions, rights)
- `edoc` schema: document entities (incoming docs, outgoing docs, drafts)
- Functions handle validation and return structured results (e.g., `TABLE(success BOOLEAN, message TEXT, id BIGINT)`)

**Database Schemas:**
- `public` — System tables: staff, departments, positions, roles, rights, login logs
- `edoc` — Document tables: incoming_docs, outgoing_docs, drafting_docs, attachments
- `esto` — Archive/storage (planned)
- `cont` — Contracts (planned)
- `iso` — ISO documents (planned)

## Entry Points

**Backend Server:**
- Location: `e_office_app_new/backend/src/server.ts`
- Triggers: `npm run dev` (tsx watch) or `npm start` (compiled JS)
- Responsibilities: Initializes Express app, registers middleware (helmet, cors, compression, cookie-parser, pino-http), mounts route modules, starts HTTP server on port 4000

**Frontend App:**
- Location: `e_office_app_new/frontend/src/app/layout.tsx` (root layout)
- Triggers: `npm run dev` (Next.js dev server on port 3000)
- Responsibilities: Renders root HTML with Plus Jakarta Sans font, wraps children in `AntdProvider`

**Main Layout:**
- Location: `e_office_app_new/frontend/src/app/(main)/layout.tsx`
- Triggers: Any authenticated route under `(main)` group
- Responsibilities: Wraps pages in `MainLayout` component (sidebar navigation + header)

**Auth Layout:**
- Location: `e_office_app_new/frontend/src/app/(auth)/login/`
- Triggers: `/login` route
- Responsibilities: Login page outside main layout

**Database Init:**
- Location: `e_office_app_new/database/init/01_create_schemas.sql`
- Triggers: First PostgreSQL container startup
- Responsibilities: Creates schemas (edoc, esto, cont, iso) and enables extensions

**Database Migrations:**
- Location: `e_office_app_new/database/migrations/001_system_tables.sql` through `009_sprint4_drafting_outgoing.sql`
- Triggers: Manual execution (no migration runner)
- Responsibilities: Create tables, indexes, stored procedures per sprint

## Error Handling

**Strategy:** PostgreSQL constraint errors mapped to Vietnamese user messages in route handlers

**Patterns:**
- Each route file defines a `handleDbError()` function that maps PostgreSQL error codes (23505=unique, 23503=FK, 23502=not null) to Vietnamese messages
- Stored procedures return structured results with `success BOOLEAN, message TEXT` for business validation
- Auth errors use custom `AuthError` class with `statusCode` property (`backend/src/services/auth.service.ts`)
- Global Express error handler in `server.ts` catches unhandled errors; hides raw messages in production
- Frontend axios interceptor handles 401 (auto-refresh) and redirects to `/login` on failure

## Cross-Cutting Concerns

**Logging:**
- Backend uses `pino` + `pino-http` for structured JSON logging
- Dev mode uses `pino-pretty` for readable console output
- Configured in `backend/src/server.ts`

**Validation:**
- Primary validation in PostgreSQL stored procedures (server-side, authoritative)
- `zod` is listed as dependency but validation is mostly done in stored procedures
- Frontend uses Ant Design Form validation rules

**Authentication:**
- JWT via `jose` library (HS256)
- Access token: 15min expiry, stored in localStorage
- Refresh token: 7d expiry, stored as httpOnly cookie + hash in DB
- Token rotation on refresh (old token revoked, new token issued)
- Middleware: `authenticate` (verify token), `requireRoles(...roles)` (RBAC)
- Defined in `backend/src/middleware/auth.ts` and `backend/src/lib/auth/jwt.ts`

**Authorization:**
- Role-based via `requireRoles()` middleware
- Token payload includes `roles: string[]`, `staffId`, `unitId`, `departmentId`
- Staff-unit scoping: queries filter by `unitId` from JWT to enforce multi-tenancy

**File Storage:**
- MinIO client at `backend/src/lib/minio/client.ts`
- Upload via `multer` memory storage (`backend/src/middleware/upload.ts`, 50MB limit)
- Files stored with UUID-based paths in MinIO bucket `documents`
- Download via presigned URLs (1 hour expiry)

---

*Architecture analysis: 2026-04-14*
