# Architecture

**Analysis Date:** 2026-04-14

## Pattern Overview

**Overall:** Repository Pattern with PostgreSQL Stored Procedures (no ORM)

**Key Characteristics:**
- Two-tier backend: Express routes call repositories directly (no service layer for most modules; auth is the exception with `auth.service.ts`)
- All data access goes through PostgreSQL stored functions/procedures -- no raw SQL in application code (except the query helpers and one `rawQuery` usage in handling-doc route)
- Frontend is a Next.js App Router SPA that talks to the backend via REST API (axios)
- State management via Zustand store (auth only); page-level state is local React state
- File storage via MinIO (S3-compatible object storage)
- JWT-based authentication with access/refresh token rotation
- Real-time notifications via Socket.IO (WebSocket)

## Layers

**Frontend -- Next.js App Router (React 19 + Ant Design 6):**
- Purpose: Client-side SPA with server-side layout rendering
- Location: `e_office_app_new/frontend/src/`
- Contains: Pages (App Router), components, stores, hooks, lib utilities
- Depends on: Backend REST API via axios, Socket.IO for real-time events
- Used by: End users (browser)

**Backend -- Express 5 REST API:**
- Purpose: HTTP API layer -- receives requests, validates, calls repositories, returns JSON
- Location: `e_office_app_new/backend/src/`
- Contains: Routes (16 files), middleware, repositories (28 files), services, lib (DB/auth/MinIO/MongoDB/Redis/Socket clients)
- Depends on: PostgreSQL (via pg pool), MinIO, Socket.IO
- Used by: Frontend

**Database -- PostgreSQL with Stored Functions:**
- Purpose: All business logic and data validation lives in stored procedures/functions
- Location: `e_office_app_new/database/`
- Contains: Schema creation scripts, 15 migration SQL files with stored procedures, 1 seed file
- Depends on: PostgreSQL extensions (uuid-ossp, pgcrypto, unaccent, pg_trgm)
- Used by: Backend repositories via `callFunction()` / `callFunctionOne()`

**Shared -- Constants and Types:**
- Purpose: Shared TypeScript types and constants used by both frontend and backend
- Location: `e_office_app_new/shared/src/`
- Contains: API response types, auth types, business constants (urgent levels, secret levels, doc statuses, handling doc statuses)
- Used by: Frontend and backend

**Workers -- Background Jobs (stub):**
- Purpose: BullMQ-based background job processing
- Location: `e_office_app_new/workers/src/`
- Contains: Empty job/queue directories (placeholder)
- Depends on: Redis (via ioredis), BullMQ
- Status: Not implemented; `bullmq` and `ioredis` are listed in package.json but unused

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

**Real-Time Notification Flow (Socket.IO):**

1. Backend `server.ts` creates HTTP server and calls `initSocket(httpServer)` (`backend/src/lib/socket.ts`)
2. Socket.IO authenticates connections via JWT (from `handshake.auth.token` or Authorization header)
3. Each connected user joins a personal room `user_{staffId}`
4. Route handlers emit events via `emitToUser(staffId, event, data)` or `emitToUsers(staffIds, event, data)`
5. Frontend `MainLayout.tsx` calls `initSocket(token)` (`frontend/src/lib/socket.ts`) and listens for events
6. Events: `new_document`, `new_message`, `new_notification`, `doc_status_changed`

**State Management:**

- Zustand store at `frontend/src/stores/auth.store.ts` holds user session state
- Each page component manages its own local state (Ant Design table pagination, form state, etc.)
- No global data cache -- pages fetch data on mount via `useEffect` + `api.get()`
- Notification unread count managed as local state in `MainLayout.tsx`, updated via Socket.IO events

## Key Abstractions

**Repository Pattern:**
- Purpose: Encapsulate all database calls behind typed interfaces
- Examples: `backend/src/repositories/department.repository.ts`, `backend/src/repositories/incoming-doc.repository.ts`, `backend/src/repositories/handling-doc.repository.ts`, `backend/src/repositories/workflow.repository.ts`
- Pattern: Each repository exports a const object with async methods. Methods call `callFunction<T>()` or `callFunctionOne<T>()` with the PostgreSQL function name and parameters.
- Total: 28 repository files

**Query Helpers (`backend/src/lib/db/query.ts`):**
- `callFunction<T>(name, params)` -- calls a PostgreSQL function, returns array of rows
- `callFunctionOne<T>(name, params)` -- calls a function, returns first row or null
- `callProcedure(name, params)` -- calls a PostgreSQL procedure (void)
- `rawQuery<T>(sql, params)` -- escape hatch for ad-hoc SQL
- `withTransaction<T>(callback)` -- wraps callback in BEGIN/COMMIT/ROLLBACK

**Centralized Error Handler (`backend/src/lib/error-handler.ts`):**
- Purpose: Maps PostgreSQL constraint violation errors to Vietnamese user messages
- Shared across ALL route files via `import { handleDbError }`
- Maps error codes: 23505 (unique) -> Vietnamese constraint message, 23503 (FK) -> "dang duoc tham chieu", 23502 (not null) -> column name
- Contains a `messageMap` record mapping constraint names to messages

**Route Modules:**
- Purpose: Group related endpoints into Express Router instances
- Total: 16 route files in `backend/src/routes/`
- Pattern: Each file creates a Router, imports its repository + `handleDbError`, defines route handlers inline, and exports default router

**PostgreSQL Stored Functions:**
- Naming convention: `[schema].fn_[entity]_[action]` (e.g., `edoc.fn_incoming_doc_create`, `public.fn_department_get_tree`)
- `public` schema: system entities (departments, staff, roles, positions, rights)
- `edoc` schema: document entities (incoming docs, outgoing docs, drafting docs, handling docs, workflows, messages, notices, calendars)
- Functions handle validation and return structured results (e.g., `TABLE(success BOOLEAN, message TEXT, id BIGINT)`)

**Database Schemas:**
- `public` -- System tables: staff, departments, positions, roles, rights, login logs
- `edoc` -- Document tables: incoming_docs, outgoing_docs, drafting_docs, handling_docs, workflows, messages, notices, calendar_events, attachments
- `esto` -- Archive/storage (planned, not yet implemented)
- `cont` -- Contracts (planned, not yet implemented)
- `iso` -- ISO documents (planned, not yet implemented)

## Entry Points

**Backend Server:**
- Location: `e_office_app_new/backend/src/server.ts`
- Triggers: `npm run dev` (tsx watch) or `npm start` (compiled JS)
- Responsibilities: Initializes Express app, registers middleware (helmet, cors, compression, cookie-parser, pino-http), mounts 16 route modules, initializes Socket.IO, starts HTTP server on port 4000

**Frontend App:**
- Location: `e_office_app_new/frontend/src/app/layout.tsx` (root layout)
- Triggers: `npm run dev` (Next.js dev server on port 3000)
- Responsibilities: Renders root HTML with Inter font (Latin + Vietnamese subsets), wraps children in `AntdProvider`

**Main Layout:**
- Location: `e_office_app_new/frontend/src/app/(main)/layout.tsx`
- Triggers: Any authenticated route under `(main)` group
- Responsibilities: Wraps pages in `MainLayout` component (sidebar navigation + header + notification bell + Socket.IO connection)

**Auth Layout:**
- Location: `e_office_app_new/frontend/src/app/(auth)/layout.tsx`
- Triggers: `/login` route
- Responsibilities: Login page outside main layout

**Database Init:**
- Location: `e_office_app_new/database/init/01_create_schemas.sql`
- Triggers: First PostgreSQL container startup
- Responsibilities: Creates schemas (edoc, esto, cont, iso) and enables extensions

**Database Migrations:**
- Location: `e_office_app_new/database/migrations/001_system_tables.sql` through `015_sprint10_dashboard_stats.sql`
- Triggers: Manual execution (no migration runner)
- Responsibilities: Create tables, indexes, stored procedures per sprint

**Database Seed:**
- Location: `e_office_app_new/database/seed_demo.sql`
- Triggers: Manual execution
- Responsibilities: Inserts demo data for development/testing

## Route Map (Backend API)

**Unauthenticated:**
- `GET /api/health` -- `backend/src/routes/health.ts`
- `POST /api/auth/login` -- `backend/src/routes/auth.ts`
- `POST /api/auth/refresh` -- `backend/src/routes/auth.ts`

**Authenticated (all require `authenticate` middleware):**
- `POST /api/auth/logout`, `GET /api/auth/me` -- `backend/src/routes/auth.ts`
- `/api/quan-tri/don-vi|chuc-vu|nguoi-dung|nhom-quyen|chuc-nang` -- `backend/src/routes/admin.ts`
- `/api/quan-tri/so-van-ban|loai-van-ban|linh-vuc|thuoc-tinh|co-quan|nguoi-ky|nhom-lam-viec|uy-quyen|dia-ban|lich-lam-viec|mau-thong-bao|cau-hinh` -- `backend/src/routes/admin-catalog.ts`
- `/api/quan-tri/quy-trinh` -- `backend/src/routes/workflow.ts` (workflow designer CRUD + steps)
- `/api/van-ban-den` -- `backend/src/routes/incoming-doc.ts` (incoming documents CRUD + attachments)
- `/api/van-ban-du-thao` -- `backend/src/routes/drafting-doc.ts` (draft documents CRUD)
- `/api/van-ban-di` -- `backend/src/routes/outgoing-doc.ts` (outgoing documents CRUD)
- `/api/van-ban-lien-thong` -- `backend/src/routes/inter-incoming.ts` (inter-organizational incoming docs)
- `/api/ho-so-cong-viec/thong-ke` -- `backend/src/routes/handling-doc-report.ts` (HSCV KPI + reports)
- `/api/ho-so-cong-viec` -- `backend/src/routes/handling-doc.ts` (handling docs CRUD + assignments + links)
- `/api/tin-nhan` -- `backend/src/routes/message.ts` (inbox, sent, compose, read/delete)
- `/api/thong-bao` -- `backend/src/routes/notice.ts` (notifications list, unread count, mark read)
- `/api/lich` -- `backend/src/routes/calendar.ts` (calendar events CRUD, scope: personal/unit/leader)
- `/api/danh-ba` -- `backend/src/routes/directory.ts` (staff phone directory)
- `/api/dashboard` -- `backend/src/routes/dashboard.ts` (stats KPI, recent incoming/outgoing, upcoming tasks)

## Error Handling

**Strategy:** Centralized PostgreSQL error mapping + stored procedure result validation

**Patterns:**
- `backend/src/lib/error-handler.ts` exports `handleDbError()` -- maps PostgreSQL error codes (23505, 23503, 23502) to Vietnamese messages. ALL route files use this shared function.
- Stored procedures return structured results with `success BOOLEAN, message TEXT` for business validation -- route handlers check `result?.success` before returning 200
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
- Route handlers perform basic field presence checks before calling repository (e.g., empty string checks)
- `zod` is listed as dependency but not currently used for request validation
- Frontend uses Ant Design Form validation rules

**Authentication:**
- JWT via `jose` library (HS256)
- Access token: configurable expiry (default 15min), stored in localStorage
- Refresh token: configurable expiry (default 7d), stored as httpOnly cookie + hash in DB
- Token rotation on refresh (old token revoked, new token issued)
- Middleware: `authenticate` (verify token), `requireRoles(...roles)` (RBAC)
- Socket.IO connections also authenticated via JWT
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

**Real-Time Events:**
- Socket.IO server initialized in `backend/src/lib/socket.ts`
- JWT-authenticated WebSocket connections
- User-targeted events via personal rooms (`user_{staffId}`)
- Events: `new_document`, `new_message`, `new_notification`, `doc_status_changed`
- Frontend client at `frontend/src/lib/socket.ts`

---

*Architecture analysis: 2026-04-14*
