# Codebase Structure

**Analysis Date:** 2026-04-14 (refreshed after Phase 4 completion)

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
│   │   │   ├── mongodb/        # MongoDB client (stub — unused)
│   │   │   │   └── client.ts
│   │   │   ├── redis/          # Redis client (stub — unused except health check)
│   │   │   │   └── client.ts
│   │   │   ├── error-handler.ts # Shared handleDbError — PG constraint → Vietnamese messages
│   │   │   └── socket.ts       # Socket.IO server initialization (initSocket)
│   │   ├── middleware/          # Express middleware
│   │   │   ├── auth.ts         # authenticate, requireRoles
│   │   │   └── upload.ts       # multer memory storage (50MB limit)
│   │   ├── repositories/       # Data access layer (30 repository files)
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
│   │   │   ├── outgoing-doc.repository.ts
│   │   │   ├── handling-doc.repository.ts        # Phase 2 — Hồ sơ công việc
│   │   │   ├── handling-doc-report.repository.ts # Phase 2 — KPI/reports
│   │   │   ├── workflow.repository.ts            # Phase 2 — Quy trình
│   │   │   ├── inter-incoming.repository.ts      # Phase 3 — VB liên thông
│   │   │   ├── message.repository.ts             # Phase 3 — Tin nhắn
│   │   │   ├── notice.repository.ts              # Phase 3 — Thông báo
│   │   │   ├── calendar.repository.ts            # Phase 4 — Lịch
│   │   │   ├── directory.repository.ts           # Phase 4 — Danh bạ
│   │   │   └── dashboard.repository.ts           # Phase 4 — Dashboard
│   │   ├── routes/             # Express Router modules (16 route files)
│   │   │   ├── health.ts       # GET /api/health (59 lines)
│   │   │   ├── auth.ts         # /api/auth — login, refresh, logout, /me (116 lines)
│   │   │   ├── admin.ts        # /api/quan-tri — departments, positions, staff, roles, rights (853 lines)
│   │   │   ├── admin-catalog.ts# /api/quan-tri — 12 catalog entities (1447 lines)
│   │   │   ├── incoming-doc.ts # /api/van-ban-den — incoming doc CRUD + actions (600 lines)
│   │   │   ├── drafting-doc.ts # /api/van-ban-du-thao — draft doc CRUD (461 lines)
│   │   │   ├── outgoing-doc.ts # /api/van-ban-di — outgoing doc CRUD (415 lines)
│   │   │   ├── handling-doc.ts # /api/ho-so-cong-viec — HSCV CRUD (543 lines)
│   │   │   ├── handling-doc-report.ts # /api/ho-so-cong-viec/thong-ke (69 lines)
│   │   │   ├── workflow.ts     # /api/quan-tri/quy-trinh — workflow designer (325 lines)
│   │   │   ├── inter-incoming.ts # /api/van-ban-lien-thong (57 lines)
│   │   │   ├── message.ts      # /api/tin-nhan — messages (234 lines)
│   │   │   ├── notice.ts       # /api/thong-bao — notifications (129 lines)
│   │   │   ├── calendar.ts     # /api/lich — calendar events (185 lines)
│   │   │   ├── directory.ts    # /api/danh-ba — directory/contacts (48 lines)
│   │   │   └── dashboard.ts    # /api/dashboard — KPI stats (93 lines)
│   │   ├── services/           # Business logic (only auth currently)
│   │   │   └── auth.service.ts # login, refresh, logout, getMe
│   │   └── server.ts           # App entry point — middleware + route mounting + Socket.IO
│   ├── package.json
│   ├── tsconfig.json
│   ├── seed_sprint5.js         # Seed data for HSCV testing
│   └── test_sprint3.sh         # Manual curl test script (Sprint 3)
│
├── frontend/                   # Next.js 16 App Router (React 19 + Ant Design 6)
│   ├── src/
│   │   ├── app/                # Next.js App Router pages
│   │   │   ├── layout.tsx      # Root layout (font, AntdProvider)
│   │   │   ├── globals.css     # Global styles (Tailwind 4 + custom CSS, 620+ lines)
│   │   │   ├── page.tsx        # Root redirect
│   │   │   ├── (auth)/         # Auth route group (no main layout)
│   │   │   │   └── login/
│   │   │   │       └── page.tsx
│   │   │   └── (main)/         # Main route group (sidebar layout) — 40 pages
│   │   │       ├── layout.tsx  # Wraps in MainLayout
│   │   │       ├── dashboard/page.tsx              # Dashboard KPI (541 lines)
│   │   │       ├── thong-tin-ca-nhan/page.tsx       # User profile
│   │   │       ├── quan-tri/                        # Admin modules (19 sub-pages)
│   │   │       │   ├── don-vi/page.tsx              # Departments (460 lines)
│   │   │       │   ├── chuc-vu/page.tsx             # Positions
│   │   │       │   ├── nguoi-dung/page.tsx          # Users/staff (785 lines)
│   │   │       │   ├── nhom-quyen/page.tsx          # Permission groups (375 lines)
│   │   │       │   ├── chuc-nang/page.tsx           # Functions
│   │   │       │   ├── so-van-ban/page.tsx          # Document books
│   │   │       │   ├── loai-van-ban/page.tsx        # Document types
│   │   │       │   ├── linh-vuc/page.tsx            # Document fields
│   │   │       │   ├── thuoc-tinh-van-ban/page.tsx  # Document attributes
│   │   │       │   ├── co-quan/page.tsx             # External orgs
│   │   │       │   ├── nguoi-ky/page.tsx            # Signers
│   │   │       │   ├── nhom-lam-viec/page.tsx       # Work groups (508 lines)
│   │   │       │   ├── uy-quyen/page.tsx            # Delegations (412 lines)
│   │   │       │   ├── dia-ban/page.tsx             # Addresses (430 lines)
│   │   │       │   ├── lich-lam-viec/page.tsx       # Work calendar
│   │   │       │   ├── mau-thong-bao/page.tsx       # Templates (484 lines)
│   │   │       │   ├── cau-hinh/page.tsx            # Config
│   │   │       │   ├── quy-trinh/page.tsx           # Workflow list (356 lines)
│   │   │       │   └── quy-trinh/[id]/thiet-ke/page.tsx # ReactFlow designer (786 lines)
│   │   │       ├── van-ban-den/                     # Incoming documents
│   │   │       │   ├── page.tsx                     # List
│   │   │       │   └── [id]/page.tsx                # Detail (662 lines)
│   │   │       ├── van-ban-du-thao/                 # Draft documents
│   │   │       │   ├── page.tsx                     # List (644 lines)
│   │   │       │   └── [id]/page.tsx                # Detail (435 lines)
│   │   │       ├── van-ban-di/                      # Outgoing documents
│   │   │       │   ├── page.tsx                     # List (441 lines)
│   │   │       │   └── [id]/page.tsx                # Detail (374 lines)
│   │   │       ├── van-ban-lien-thong/              # Inter-org documents
│   │   │       │   ├── page.tsx                     # List (250 lines)
│   │   │       │   └── [id]/page.tsx                # Detail (331 lines)
│   │   │       ├── ho-so-cong-viec/                 # HSCV (Handling docs)
│   │   │       │   ├── page.tsx                     # List (713 lines)
│   │   │       │   ├── [id]/page.tsx                # Detail (1670 lines — LARGEST)
│   │   │       │   └── bao-cao/page.tsx             # KPI reports (619 lines)
│   │   │       ├── van-ban-danh-dau/page.tsx         # Bookmarked docs
│   │   │       ├── tin-nhan/page.tsx                 # Messages 3-panel (516 lines)
│   │   │       ├── thong-bao/page.tsx                # Notifications (310 lines)
│   │   │       ├── lich/                             # Calendar
│   │   │       │   ├── ca-nhan/page.tsx             # Personal (395 lines)
│   │   │       │   ├── co-quan/page.tsx             # Organization (403 lines)
│   │   │       │   └── lanh-dao/page.tsx            # Leadership (342 lines)
│   │   │       └── danh-ba/page.tsx                  # Directory/contacts (238 lines)
│   │   ├── components/
│   │   │   └── layout/
│   │   │       ├── AntdProvider.tsx    # Ant Design ConfigProvider + theme
│   │   │       └── MainLayout.tsx      # Sidebar + header + content layout
│   │   ├── config/
│   │   │   ├── constants.ts    # APP_NAME, PAGE_SIZE, file extensions, urgency/secret levels
│   │   │   └── theme.ts        # Ant Design theme customization (Inter font)
│   │   ├── hooks/              # Custom React hooks (empty)
│   │   ├── lib/
│   │   │   ├── api.ts          # Axios instance with interceptors (auth, refresh)
│   │   │   ├── socket.ts       # Socket.IO client instance
│   │   │   └── tree-utils.ts   # Shared buildTree, filterTree, flattenTreeForSelect
│   │   ├── stores/
│   │   │   └── auth.store.ts   # Zustand auth store (login, logout, fetchMe)
│   │   └── types/
│   │       └── tree.ts         # TreeNode interface
│   ├── public/                 # Static assets
│   ├── package.json
│   ├── tsconfig.json
│   └── next.config.ts
│
├── database/                   # PostgreSQL schema and migrations
│   ├── init/
│   │   └── 01_create_schemas.sql       # Creates schemas: edoc, esto, cont, iso + extensions
│   ├── migrations/                     # 15 migration files
│   │   ├── 001_system_tables.sql       # Staff, departments, positions, roles, rights tables
│   │   ├── 002_edoc_tables.sql         # Incoming/outgoing/drafting doc tables, attachments
│   │   ├── 003_auth_stored_procedures.sql
│   │   ├── 004_rename_auth_sp_convention.sql
│   │   ├── 005_sprint1_admin_core_sp.sql    # Department, position, staff, role, right SPs
│   │   ├── 006_sprint1_fix_gaps.sql
│   │   ├── 007_sprint2_catalog_config.sql   # Doc book, doc type, field, signer, group SPs
│   │   ├── 008_sprint3_incoming_docs.sql    # Incoming doc CRUD + workflow SPs
│   │   ├── 009_sprint4_drafting_outgoing.sql # Drafting + outgoing doc SPs
│   │   ├── 010_sprint5_handling_doc_sps.sql  # HSCV stored procedures (23 functions)
│   │   ├── 011_sprint6_workflow_tables_sps.sql # Workflow tables + 17 SPs
│   │   ├── 012_sprint7_inter_incoming.sql    # VB liên thông + incoming doc action SPs
│   │   ├── 013_sprint8_messages_notices.sql  # Messages + Notices tables + 13 SPs
│   │   ├── 014_sprint9_calendar_directory.sql # Calendar + directory SPs
│   │   └── 015_sprint10_dashboard_stats.sql   # Dashboard statistics SPs
│   └── seed_demo.sql                   # Demo seed data
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

## Summary Counts

| Area | Count | Notes |
|------|-------|-------|
| Backend repositories | 30 | One per entity |
| Backend routes | 16 | Mounted in server.ts |
| Database migrations | 15 | Sprint 1 through 10 |
| Frontend pages (main) | 40 | Under `(main)/` group |
| Frontend pages (auth) | 1 | Login page |
| Frontend components | 2 | AntdProvider, MainLayout |
| Frontend libs | 3 | api.ts, socket.ts, tree-utils.ts |
| Shared types | 3 | api.ts, auth.ts, index.ts |

## Key File Locations

**Entry Points:**
- `backend/src/server.ts`: Backend Express app — middleware, route mounting, Socket.IO init, error handler
- `frontend/src/app/layout.tsx`: Root Next.js layout — font, metadata, AntdProvider wrapper
- `frontend/src/app/(main)/layout.tsx`: Main group layout — wraps children in MainLayout

**Shared Utilities (new in Phase 1):**
- `backend/src/lib/error-handler.ts`: Centralized handleDbError — PG constraint → Vietnamese messages
- `backend/src/lib/socket.ts`: Socket.IO server init with auth and room management
- `frontend/src/lib/tree-utils.ts`: buildTree, filterTree, flattenTreeForSelect
- `frontend/src/types/tree.ts`: TreeNode interface

**Configuration:**
- `backend/package.json`: Backend dependencies and scripts
- `frontend/package.json`: Frontend dependencies and scripts
- `frontend/src/config/theme.ts`: Ant Design theme (Inter font, navy palette)
- `frontend/src/config/constants.ts`: App-wide constants

**Core Logic:**
- `backend/src/lib/db/query.ts`: Central database abstraction — ALL DB calls go through here
- `backend/src/lib/db/pool.ts`: PostgreSQL connection pool singleton
- `backend/src/services/auth.service.ts`: Authentication business logic
- `backend/src/middleware/auth.ts`: JWT verification + role-based access control

**State & API:**
- `frontend/src/lib/api.ts`: Axios instance with auth interceptor and token refresh
- `frontend/src/stores/auth.store.ts`: Zustand store for user session
- `frontend/src/lib/socket.ts`: Socket.IO client singleton

## Largest Files (by line count)

| File | Lines | Module |
|------|-------|--------|
| ho-so-cong-viec/[id]/page.tsx | 1670 | HSCV detail (6 tabs) |
| admin-catalog.ts (route) | 1447 | 12 catalog entities |
| admin.ts (route) | 853 | 5 admin entities |
| nguoi-dung/page.tsx | 785 | User management |
| quy-trinh/[id]/thiet-ke/page.tsx | 786 | ReactFlow workflow designer |
| ho-so-cong-viec/page.tsx | 713 | HSCV list |
| van-ban-den/[id]/page.tsx | 662 | Incoming doc detail |
| van-ban-du-thao/page.tsx | 644 | Draft doc list |
| globals.css | 620+ | All custom CSS |
| ho-so-cong-viec/bao-cao/page.tsx | 619 | KPI reports |

## API Route Mounting (from server.ts)

```
/api/health                    → health.ts
/api/auth                      → auth.ts
/api/quan-tri                  → admin.ts + admin-catalog.ts
/api/van-ban-den               → incoming-doc.ts
/api/van-ban-du-thao           → drafting-doc.ts
/api/van-ban-lien-thong        → inter-incoming.ts
/api/van-ban-di                → outgoing-doc.ts
/api/ho-so-cong-viec/thong-ke  → handling-doc-report.ts (mounted BEFORE /:id)
/api/ho-so-cong-viec           → handling-doc.ts
/api/quan-tri/quy-trinh        → workflow.ts
/api/tin-nhan                  → message.ts
/api/thong-bao                 → notice.ts
/api/lich                      → calendar.ts
/api/danh-ba                   → directory.ts
/api/dashboard                 → dashboard.ts
```

## Where to Add New Code

**New Backend Module:**
1. Create repository: `backend/src/repositories/{module}.repository.ts`
2. Create route: `backend/src/routes/{module}.ts`
3. Register in `backend/src/server.ts`: `app.use('/api/{slug}', authenticate, routes)`
4. Create migration: `database/migrations/0NN_{description}.sql`
5. Use shared `handleDbError` from `lib/error-handler.ts`

**New Frontend Page:**
1. Create directory: `frontend/src/app/(main)/{slug}/`
2. Create page: `frontend/src/app/(main)/{slug}/page.tsx`
3. Add menu item in `MainLayout.tsx` menuItems array
4. For detail pages: `{slug}/[id]/page.tsx`

---

*Structure analysis: 2026-04-14 (refreshed)*
