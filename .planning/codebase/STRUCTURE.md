# Codebase Structure

**Analysis Date:** 2026-04-14

## Directory Layout

```
e_office_app_new/
├── backend/                    # Express 5 REST API (TypeScript)
│   ├── src/
│   │   ├── config/             # (empty — env vars used directly)
│   │   ├── lib/                # Infrastructure clients and helpers
│   │   │   ├── auth/           # JWT + password utilities
│   │   │   │   ├── jwt.ts      # signAccessToken, signRefreshToken, verifyToken
│   │   │   │   └── password.ts # hashPassword, verifyPassword (bcryptjs)
│   │   │   ├── db/             # PostgreSQL connection
│   │   │   │   ├── pool.ts     # pg.Pool singleton
│   │   │   │   └── query.ts    # callFunction, callFunctionOne, callProcedure, rawQuery, withTransaction
│   │   │   ├── minio/          # MinIO S3-compatible file storage
│   │   │   │   └── client.ts   # uploadFile, getFileUrl, deleteFile
│   │   │   ├── mongodb/        # MongoDB client (stub)
│   │   │   │   └── client.ts
│   │   │   └── redis/          # Redis client (stub)
│   │   │       └── client.ts
│   │   ├── middleware/          # Express middleware
│   │   │   ├── auth.ts         # authenticate, requireRoles
│   │   │   └── upload.ts       # multer memory storage (50MB limit)
│   │   ├── repositories/       # Data access layer (21 repository files)
│   │   │   ├── auth.repository.ts
│   │   │   ├── department.repository.ts
│   │   │   ├── position.repository.ts
│   │   │   ├── staff.repository.ts
│   │   │   ├── role.repository.ts
│   │   │   ├── right.repository.ts
│   │   │   ├── doc-book.repository.ts
│   │   │   ├── doc-type.repository.ts
│   │   │   ├── doc-field.repository.ts
│   │   │   ├── doc-column.repository.ts
│   │   │   ├── organization.repository.ts
│   │   │   ├── signer.repository.ts
│   │   │   ├── work-group.repository.ts
│   │   │   ├── delegation.repository.ts
│   │   │   ├── address.repository.ts
│   │   │   ├── work-calendar.repository.ts
│   │   │   ├── template.repository.ts
│   │   │   ├── config.repository.ts
│   │   │   ├── incoming-doc.repository.ts
│   │   │   ├── drafting-doc.repository.ts
│   │   │   └── outgoing-doc.repository.ts
│   │   ├── routes/             # Express Router modules (7 route files)
│   │   │   ├── health.ts       # GET /api/health
│   │   │   ├── auth.ts         # POST /api/auth/login, /refresh, /logout, GET /me
│   │   │   ├── admin.ts        # /api/quan-tri — departments, positions, staff, roles, rights
│   │   │   ├── admin-catalog.ts# /api/quan-tri — doc books, doc types, fields, signers, groups, etc.
│   │   │   ├── incoming-doc.ts # /api/van-ban-den — incoming document CRUD
│   │   │   ├── drafting-doc.ts # /api/van-ban-du-thao — draft document CRUD
│   │   │   └── outgoing-doc.ts # /api/van-ban-di — outgoing document CRUD
│   │   ├── services/           # Business logic (only auth currently)
│   │   │   └── auth.service.ts # login, refresh, logout, getMe
│   │   └── server.ts           # App entry point — middleware + route mounting
│   ├── package.json
│   ├── tsconfig.json
│   ├── seed_sprint4.js         # Seed data script
│   └── test_sprint4.sh         # Test script
│
├── frontend/                   # Next.js 16 App Router (React 19 + Ant Design 6)
│   ├── src/
│   │   ├── app/                # Next.js App Router pages
│   │   │   ├── layout.tsx      # Root layout (font, AntdProvider)
│   │   │   ├── globals.css     # Global styles (Tailwind 4 + custom CSS)
│   │   │   ├── (auth)/         # Auth route group (no main layout)
│   │   │   │   └── login/
│   │   │   │       └── page.tsx
│   │   │   └── (main)/         # Main route group (sidebar layout)
│   │   │       ├── layout.tsx  # Wraps in MainLayout
│   │   │       ├── dashboard/
│   │   │       │   └── page.tsx
│   │   │       ├── thong-tin-ca-nhan/
│   │   │       │   └── page.tsx
│   │   │       ├── quan-tri/           # Admin modules (17 sub-pages)
│   │   │       │   ├── don-vi/         # Departments/units
│   │   │       │   ├── chuc-vu/        # Positions
│   │   │       │   ├── nguoi-dung/     # Users/staff
│   │   │       │   ├── nhom-quyen/     # Permission groups/roles
│   │   │       │   ├── so-van-ban/     # Document books
│   │   │       │   ├── loai-van-ban/   # Document types
│   │   │       │   ├── linh-vuc/       # Document fields
│   │   │       │   ├── thuoc-tinh-van-ban/ # Document attributes/columns
│   │   │       │   ├── co-quan/        # External organizations
│   │   │       │   ├── nguoi-ky/       # Signers
│   │   │       │   ├── nhom-lam-viec/  # Work groups
│   │   │       │   ├── uy-quyen/       # Delegations
│   │   │       │   ├── dia-ban/        # Addresses (provinces/districts)
│   │   │       │   ├── lich-lam-viec/  # Work calendar
│   │   │       │   ├── mau-thong-bao/  # Notification templates
│   │   │       │   ├── cau-hinh/       # System config
│   │   │       │   └── chuc-nang/      # Functions/features
│   │   │       ├── van-ban-den/        # Incoming documents
│   │   │       │   ├── page.tsx        # List page
│   │   │       │   └── [id]/
│   │   │       │       └── page.tsx    # Detail page
│   │   │       ├── van-ban-du-thao/    # Draft documents
│   │   │       │   ├── page.tsx
│   │   │       │   └── [id]/
│   │   │       │       └── page.tsx
│   │   │       ├── van-ban-di/         # Outgoing documents
│   │   │       │   ├── page.tsx
│   │   │       │   └── [id]/
│   │   │       │       └── page.tsx
│   │   │       └── van-ban-danh-dau/   # Bookmarked documents
│   │   ├── components/
│   │   │   ├── layout/
│   │   │   │   ├── AntdProvider.tsx    # Ant Design ConfigProvider + theme
│   │   │   │   └── MainLayout.tsx      # Sidebar + header + content layout
│   │   │   ├── shared/                 # Shared/reusable components
│   │   │   └── ui/                     # UI primitives
│   │   ├── config/
│   │   │   ├── constants.ts    # APP_NAME, PAGE_SIZE, file extensions, urgency/secret levels
│   │   │   └── theme.ts        # Ant Design theme customization
│   │   ├── hooks/              # Custom React hooks
│   │   ├── lib/
│   │   │   └── api.ts          # Axios instance with interceptors (auth, refresh)
│   │   ├── stores/
│   │   │   └── auth.store.ts   # Zustand auth store (login, logout, fetchMe)
│   │   └── types/              # Frontend-specific TypeScript types
│   ├── public/                 # Static assets
│   ├── package.json
│   ├── tsconfig.json
│   └── next.config.ts
│
├── database/                   # PostgreSQL schema and migrations
│   ├── init/
│   │   └── 01_create_schemas.sql       # Creates schemas: edoc, esto, cont, iso + extensions
│   └── migrations/
│       ├── 001_system_tables.sql       # Staff, departments, positions, roles, rights tables
│       ├── 002_edoc_tables.sql         # Incoming/outgoing/drafting doc tables, attachments
│       ├── 003_auth_stored_procedures.sql
│       ├── 004_rename_auth_sp_convention.sql
│       ├── 005_sprint1_admin_core_sp.sql    # Department, position, staff, role, right SPs
│       ├── 006_sprint1_fix_gaps.sql
│       ├── 007_sprint2_catalog_config.sql   # Doc book, doc type, field, signer, group SPs
│       ├── 008_sprint3_incoming_docs.sql    # Incoming doc CRUD + workflow SPs
│       └── 009_sprint4_drafting_outgoing.sql # Drafting + outgoing doc SPs
│
├── shared/                     # Shared code between frontend/backend
│   └── src/
│       ├── constants/
│       │   └── index.ts        # PAGE_SIZE, file extensions, urgency/secret/status levels
│       └── types/
│           ├── index.ts        # Re-exports api.ts and auth.ts
│           ├── api.ts          # ApiResponse<T>, PaginatedResponse<T>
│           └── auth.ts         # Auth-related shared types
│
├── workers/                    # Background job processing (BullMQ — stub)
│   └── src/
│       ├── jobs/               # Job handler definitions (empty)
│       └── queues/             # Queue configurations (empty)
│
└── docs/                       # Project documentation
    └── quy_uoc_chung.md       # Shared conventions (validation, naming, error messages)
```

## Directory Purposes

**`backend/src/routes/`:**
- Purpose: HTTP endpoint definitions grouped by domain
- Contains: Express Router modules with inline handler functions
- Key files: `admin.ts` (5 admin entities), `admin-catalog.ts` (12 catalog entities), `incoming-doc.ts`, `drafting-doc.ts`, `outgoing-doc.ts`
- Pattern: Each route file imports its repositories, defines `handleDbError()`, and exports a default Router

**`backend/src/repositories/`:**
- Purpose: Data access objects — one file per database entity
- Contains: 21 repository files, each exporting a const object with typed async methods
- Key files: `incoming-doc.repository.ts` (most complex), `department.repository.ts` (tree structure), `auth.repository.ts`
- Pattern: Methods call `callFunction<T>('schema.fn_entity_action', [params])` — never write raw SQL

**`backend/src/lib/`:**
- Purpose: Infrastructure clients and low-level helpers
- Contains: DB pool + query helpers, JWT utilities, password hashing, MinIO client, MongoDB client, Redis client

**`frontend/src/app/(main)/`:**
- Purpose: All authenticated pages wrapped in MainLayout (sidebar + header)
- Contains: Page components organized by Vietnamese URL slugs
- Key pattern: Each `page.tsx` is a self-contained `'use client'` component with its own state, data fetching, table, and Drawer for add/edit

**`frontend/src/app/(main)/quan-tri/`:**
- Purpose: Administration/configuration module pages
- Contains: 17 sub-directories, each with a single `page.tsx`
- Pattern: CRUD pages using Ant Design Table + Drawer (add/edit) + Popconfirm (delete)

**`database/migrations/`:**
- Purpose: Sequential SQL migration files — tables, indexes, and stored procedures
- Contains: 9 migration files numbered by order of execution
- Pattern: `NNN_description.sql` — run manually in order; no migration runner

## Key File Locations

**Entry Points:**
- `backend/src/server.ts`: Backend Express app — middleware setup, route mounting, error handler, server start
- `frontend/src/app/layout.tsx`: Root Next.js layout — font, metadata, AntdProvider wrapper
- `frontend/src/app/(main)/layout.tsx`: Main group layout — wraps children in MainLayout

**Configuration:**
- `backend/package.json`: Backend dependencies and scripts
- `frontend/package.json`: Frontend dependencies and scripts
- `frontend/src/config/theme.ts`: Ant Design theme customization
- `frontend/src/config/constants.ts`: App-wide constants (page size, file limits, urgency levels)
- `.env` files: Environment configuration (existence noted, not read)

**Core Logic:**
- `backend/src/lib/db/query.ts`: Central database abstraction — ALL database calls go through here
- `backend/src/lib/db/pool.ts`: PostgreSQL connection pool singleton
- `backend/src/services/auth.service.ts`: Authentication business logic (login, refresh, logout)
- `backend/src/middleware/auth.ts`: JWT verification + role-based access control

**State & API:**
- `frontend/src/lib/api.ts`: Axios instance with auth interceptor and token refresh
- `frontend/src/stores/auth.store.ts`: Zustand store for user session

**Shared:**
- `shared/src/types/api.ts`: `ApiResponse<T>` and `PaginatedResponse<T>` interfaces
- `shared/src/constants/index.ts`: Business constants (urgency levels, secret levels, document statuses)

## Naming Conventions

**Files:**
- Backend repositories: `kebab-case.repository.ts` (e.g., `incoming-doc.repository.ts`, `doc-book.repository.ts`)
- Backend routes: `kebab-case.ts` (e.g., `admin-catalog.ts`, `incoming-doc.ts`)
- Backend lib: `kebab-case.ts` grouped by domain in subdirectories (e.g., `lib/auth/jwt.ts`)
- Frontend pages: `page.tsx` inside route-segment directories
- Frontend components: `PascalCase.tsx` (e.g., `MainLayout.tsx`, `AntdProvider.tsx`)
- Frontend stores: `kebab-case.store.ts` (e.g., `auth.store.ts`)
- Database migrations: `NNN_description.sql` (e.g., `008_sprint3_incoming_docs.sql`)

**Directories (Frontend Routes — Vietnamese slugs):**
- Admin pages: `/quan-tri/don-vi`, `/quan-tri/chuc-vu`, `/quan-tri/nguoi-dung`, `/quan-tri/nhom-quyen`
- Document pages: `/van-ban-den`, `/van-ban-di`, `/van-ban-du-thao`
- Profile: `/thong-tin-ca-nhan`
- Dashboard: `/dashboard`

**API Routes (match frontend URL slugs):**
- `/api/quan-tri/...` — admin endpoints
- `/api/van-ban-den` — incoming documents
- `/api/van-ban-du-thao` — draft documents
- `/api/van-ban-di` — outgoing documents
- `/api/auth/...` — authentication

**PostgreSQL Functions:**
- Schema-qualified: `public.fn_department_get_tree`, `edoc.fn_incoming_doc_create`
- Pattern: `[schema].fn_[entity]_[action]`
- Actions: `get_tree`, `get_by_id`, `get_list`, `create`, `update`, `delete`, `toggle_lock`, `search`

**TypeScript:**
- Repository interfaces: `PascalCase` with `Row` suffix (e.g., `DepartmentTreeRow`, `IncomingDocListRow`)
- Repository exports: `camelCase` const objects (e.g., `departmentRepository`, `incomingDocRepository`)
- Repository methods: `camelCase` verbs (e.g., `getTree`, `getById`, `create`, `delete`, `toggleLock`)

## Where to Add New Code

**New Backend Module (e.g., "ho-so-cong-viec" / handling docs):**
1. Create repository: `backend/src/repositories/handling-doc.repository.ts`
2. Create route: `backend/src/routes/handling-doc.ts`
3. Register in `backend/src/server.ts`: `app.use('/api/ho-so-cong-viec', authenticate, handlingDocRoutes)`
4. Create migration: `database/migrations/010_sprint5_handling_docs.sql` with stored procedures
5. Follow existing pattern: repository calls `callFunction()`, route uses `handleDbError()`

**New Frontend Page (e.g., admin page for new entity):**
1. Create directory: `frontend/src/app/(main)/quan-tri/[entity-slug]/`
2. Create page: `frontend/src/app/(main)/quan-tri/[entity-slug]/page.tsx`
3. Add menu item in `frontend/src/components/layout/MainLayout.tsx` (menuItems array)
4. Page should be `'use client'` with Ant Design Table + Drawer pattern

**New Frontend Page (e.g., document detail):**
1. Create directory: `frontend/src/app/(main)/[module-slug]/[id]/`
2. Create page: `frontend/src/app/(main)/[module-slug]/[id]/page.tsx`
3. Use `useParams()` to get `id`, fetch via `api.get(`/[api-slug]/${id}`)`

**New Shared Type:**
- Add to `shared/src/types/` and re-export from `shared/src/types/index.ts`

**New Shared Constant:**
- Add to `shared/src/constants/index.ts`
- Mirror in `frontend/src/config/constants.ts` if frontend-only access needed

**New Repository Method:**
1. Add PostgreSQL function in a new migration file
2. Add typed method to the corresponding repository file
3. Call from route handler

**New Middleware:**
- Add to `backend/src/middleware/`
- Register in `backend/src/server.ts` or per-route in route files

## Special Directories

**`database/init/`:**
- Purpose: One-time PostgreSQL initialization (schemas + extensions)
- Generated: No
- Committed: Yes
- Run automatically by Docker PostgreSQL on first startup

**`database/migrations/`:**
- Purpose: Sequential schema + stored procedure changes
- Generated: No
- Committed: Yes
- Run manually in numeric order — no migration runner tool

**`frontend/.next/`:**
- Purpose: Next.js build cache
- Generated: Yes
- Committed: No (should be in .gitignore)

**`workers/`:**
- Purpose: BullMQ background job infrastructure (placeholder for future sprints)
- Generated: No
- Committed: Yes
- Status: Jobs and queues directories are empty stubs

**`shared/`:**
- Purpose: Code shared between frontend, backend, and workers
- Generated: No
- Committed: Yes
- Note: Not a published package — imported directly via relative paths or path aliases

---

*Structure analysis: 2026-04-14*
