<!-- GSD:project-start source:PROJECT.md -->
## Project

**e-Office — Hệ thống Quản lý Văn bản điện tử**

Hệ thống quản lý văn bản điện tử (e-Office) dành cho cơ quan nhà nước cấp tỉnh (VD: tỉnh Lào Cai) và doanh nghiệp nhà nước. Cho phép toàn bộ nhân sự quản lý văn bản đến/đi/dự thảo, hồ sơ công việc, lịch họp, ký số, liên thông LGSP — thay thế hệ thống cũ (.NET) bằng công nghệ mới (Next.js + Express + PostgreSQL) với giao diện hiện đại hơn, giữ nguyên nghiệp vụ.

**Core Value:** Luồng văn bản đến → xử lý → văn bản đi phải hoạt động đúng nghiệp vụ cơ quan nhà nước — đây là flow cốt lõi mà mọi công chức sử dụng hàng ngày.

### Constraints

- **Deadline**: Demo cuối tuần này (2026-04-18/19) — toàn bộ 17 sprint
- **Tech stack**: Next.js 16 + Express 5 + PostgreSQL 16 (Stored Procedures, KHÔNG ORM) + MongoDB + Redis + MinIO
- **Business logic**: PHẢI đối chiếu source code cũ (.NET) trước khi implement — đọc Controllers, Services, SPs cũ
- **UI/UX**: Ant Design 6 + custom theme (Deep Navy #1B3A5C), Drawer cho add/edit, Popconfirm cho xóa, tiếng Việt có dấu
- **Architecture**: Repository pattern, no service layer (trừ auth), all data access qua Stored Functions
<!-- GSD:project-end -->

<!-- GSD:stack-start source:codebase/STACK.md -->
## Technology Stack

## Languages
- TypeScript 5.x & 6.x - Backend (Node.js), frontend (Next.js), and worker processes
- SQL (PostgreSQL with PL/pgSQL) - Stored procedures and migrations
- CSS (Tailwind CSS) - Frontend styling
## Runtime
- Node.js (version not specified in config, inferred from package.json compatibility)
- Development: tsx watch for hot reload
- Production: Compiled JavaScript
- npm (standard package manager)
- Lockfile: Not detected (no package-lock.json, yarn.lock, or pnpm-lock.yaml in repo)
## Frameworks
- Express.js 5.2.1 - Backend REST API server (`/d/ProjectAI/quanlyvanban/e_office_app_new/backend/src/server.ts`)
- Next.js 16.2.3 - Frontend React app with SSR and routing
- React 19.2.4 - UI component library
- React DOM 19.2.4 - DOM rendering
- Not detected - no test runners configured in package.json (jest, vitest, etc.)
- TypeScript 5.0 & 6.0.2 - Compilation
- TSX 4.21.0 - TypeScript execution and hot reload
- ESLint 9.x - Code linting
- Tailwind CSS 4.x - Utility-first CSS framework
- PostCSS 4.x - CSS processing pipeline
## Key Dependencies
- pg 8.20.0 - PostgreSQL client for direct SQL queries (stored procedures)
- mongoose 9.4.1 - MongoDB ODM for logging/audit trails
- ioredis 5.10.1 - Redis client for caching and job queues
- bullmq 5.73.5 - Job queue built on Redis (email, SMS, notifications)
- minio 8.0.7 - S3-compatible object storage for documents
- bcryptjs 3.0.3 - Password hashing
- jose 6.2.2 - JWT token signing and verification (HS256 algorithm)
- helmet 8.1.0 - Express security headers middleware
- axios 1.15.0 - Frontend HTTP client (frontend only)
- express 5.2.1 - Backend HTTP server
- cors 2.8.6 - CORS middleware
- cookie-parser 1.4.7 - Cookie parsing middleware
- socket.io 4.8.3 - Real-time bidirectional communication (backend dependency exists but not actively used)
- socket.io-client 4.8.3 - Frontend WebSocket client (not actively used)
- exceljs 4.4.0 - Excel file generation/parsing (both backend and frontend)
- pdf-lib 1.17.1 - PDF manipulation (both backend and frontend)
- zod 4.3.6 - Runtime schema validation (both backend and frontend)
- multer 2.1.1 - File upload handling middleware
- compression 1.8.1 - Response compression middleware
- zustand 5.0.12 - Lightweight state management (auth.store.ts)
- dayjs 1.11.20 - Date manipulation
- numeral 2.0.6 - Number formatting
- Ant Design 6.3.5 - Component UI library
- Ant Design Icons 6.1.1 - Icon set
- Ant Design CSS-in-JS 2.1.2 - Dynamic styling for Ant Design
- pino 10.3.1 - Structured JSON logging (backend and workers)
- pino-http 11.0.0 - HTTP request/response logging middleware
- pino-pretty 13.1.3 - Dev-time pretty printer for logs
- uuid 13.0.0 - UUID generation
- nodemailer 8.0.5 - Email sending (prepared for use, not fully implemented)
- dotenv 17.4.2 - Environment variable loading
## Configuration
- `.env` file required for backend with postgres, mongodb, redis, minio, and JWT secrets
- `.env.local` for frontend configuration
- `tsconfig.json` - Backend TypeScript configuration (`/d/ProjectAI/quanlyvanban/e_office_app_new/backend/tsconfig.json`)
- `tsconfig.json` - Frontend TypeScript configuration (`/d/ProjectAI/quanlyvanban/e_office_app_new/frontend/tsconfig.json`)
- `next.config.ts` - Next.js configuration (minimal, no custom middleware)
- `eslint.config.mjs` - ESLint configuration with Next.js rules
- `postcss.config.mjs` - PostCSS with Tailwind CSS plugin
## Platform Requirements
- Node.js 18+ (inferred from modern package versions)
- npm or compatible package manager
- Docker & Docker Compose (for local services: PostgreSQL, MongoDB, Redis, MinIO)
- Node.js 18+ runtime
- Separate PostgreSQL 16 instance
- Separate MongoDB 7 instance
- Separate Redis 7 instance
- Separate MinIO S3-compatible storage
- PostgreSQL 16-alpine - Primary relational database
- MongoDB 7 - Audit and logging
- Redis 7-alpine - Cache and job queue
- MinIO - Document/file storage (S3-compatible)
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

## Naming Patterns
- Use **kebab-case** with suffix: `{module}.repository.ts`, `{module}.service.ts`, `{module}.ts` (routes)
- Examples: `department.repository.ts`, `auth.service.ts`, `admin-catalog.ts`, `incoming-doc.ts`
- Location pattern: `backend/src/routes/`, `backend/src/repositories/`, `backend/src/services/`
- Page files: `page.tsx` (Next.js App Router convention)
- Layout/Provider components: **PascalCase** — `MainLayout.tsx`, `AntdProvider.tsx`
- Stores: `{name}.store.ts` — e.g., `auth.store.ts`
- Hooks: `use-{name}.ts` (not yet created, but convention documented)
- Config: `theme.ts`, `constants.ts`
- Use **camelCase** for all functions and variables: `handleDbError`, `fetchTree`, `staffId`
- Repository methods: `getTree`, `getById`, `create`, `update`, `delete`, `toggleLock`, `getList`
- Use **PascalCase** with descriptive suffixes: `DepartmentTreeRow`, `DepartmentDetailRow`, `IncomingDocListRow`
- Row suffix for DB result types: `*Row`
- Frontend state interfaces: `AuthState`, `UserInfo`
- Request extension: `AuthRequest extends Request`
- Tables: **snake_case**, plural — `departments`, `incoming_docs`
- Columns: **snake_case** — `first_name`, `created_at`, `is_locked`
- Stored procedures: `{schema}.fn_{module}_{action}` — `public.fn_department_get_tree`, `edoc.fn_incoming_doc_create`
- Constraints: `uq_{table}_{column}` (unique), `fk_{table}_{ref}` (foreign key), `idx_{table}_{column}` (index)
- Prefix: `/api/`
- Resource paths: **kebab-case Vietnamese** — `/quan-tri/don-vi`, `/van-ban-den`, `/so-van-ban`
- CRUD: `GET /resource`, `POST /resource`, `PUT /resource/:id`, `DELETE /resource/:id`
- Actions: `PATCH /resource/:id/lock`, `PATCH /resource/:id/reset-password`
- Use **snake_case** matching DB column names: `parent_id`, `is_unit`, `doc_book_id`
## Code Style
- No Prettier config detected. Rely on editor defaults and ESLint.
- Indentation: 2 spaces (observed throughout)
- Semicolons: required (TypeScript strict)
- Quotes: single quotes for strings
- Frontend: ESLint with `eslint-config-next/core-web-vitals` and `eslint-config-next/typescript`
- Backend: No ESLint configured. TypeScript strict mode serves as the primary check.
- Both backend and frontend use `"strict": true` in `tsconfig.json`
- Backend: `e_office_app_new/backend/tsconfig.json` — target ES2022, ESM modules
- Frontend: `e_office_app_new/frontend/tsconfig.json` — target ES2017, Next.js plugin
## Import Organization
- Frontend: `@/*` maps to `./src/*` — use as `import { api } from '@/lib/api'`
- Backend: `@/*` maps to `./src/*` and `@shared/*` maps to `../../shared/src/*`
- ALWAYS use `.js` extension in imports (ESM requirement): `import { pool } from './pool.js'`
## Error Handling
### Backend: `handleDbError` Pattern
### Backend: Auth Error Pattern
### Backend: Route Handler Pattern
### Frontend: Error Display
### Global Error Handler
## API Response Format
- `200` — GET, PUT, PATCH, DELETE success
- `201` — POST create success
- `400` — Validation failure
- `401` — Unauthorized (missing/expired token)
- `403` — Forbidden (insufficient permissions)
- `404` — Not found
- `409` — Conflict (unique violation)
- `500` — Server error
## Database Access Pattern
- ALWAYS use parameterized queries (`$1, $2`) — never string concatenation
- Repository exports a plain object (not a class)
- Each repository defines its own row interfaces
- Stored procedure naming: `{schema}.fn_{module}_{action}`
## Frontend Component Patterns
### Page Structure
### Drawer (Add/Edit)
- Size: `size={720}` (standard for forms — AntD 6 dùng `size` thay vì `width`)
- Use `rootClassName="drawer-gradient"` for gradient header
- Title: dynamic based on `editingRecord` — "Them moi" vs "Chinh sua"
- Footer: Save + Cancel buttons in drawer `extra`
- Form uses `validateTrigger="onSubmit"` to prevent layout issues in 2-column forms
### Table Actions
- Use `Dropdown` with `MoreOutlined` icon button, NOT multiple icon buttons
- Divider before dangerous actions (delete)
- Delete uses `Modal.confirm` with `danger: true`
- Lock/Unlock is a toggle action via `PATCH`
### Notifications
- Success: `message.success('Them thanh cong')` — via `App.useApp()`
- Error: `message.error(...)` — only for system errors not mappable to fields
- Never use `alert()` or `notification` popup
### Loading States
- Table: `loading` prop on `<Table>`
- Tree/Page sections: `<Skeleton active paragraph={{ rows: N }} />`
- Never use `<Spin />` full-page
### State Management
- **Zustand** for global state (auth only so far): `e_office_app_new/frontend/src/stores/auth.store.ts`
- **Local state** (`useState`) for page-level data (lists, forms, drawers)
- **Axios** via shared instance: `e_office_app_new/frontend/src/lib/api.ts`
- Token stored in `localStorage`, auto-attached via Axios interceptor
- 401 response triggers automatic refresh token flow
## CSS Approach
- Layout/structural styles MUST use CSS classes in `e_office_app_new/frontend/src/app/globals.css`
- Dynamic/data-driven styles MAY use inline `style={{}}`
- Shared CSS classes: `.main-layout`, `.main-sider`, `.main-header`, `.main-content`, `.page-header`, `.page-title`, `.page-card`, `.drawer-gradient`, `.stat-card`, `.info-grid`, `.detail-header`, `.filter-row`, `.empty-center`
- Ant Design theme customization in `e_office_app_new/frontend/src/config/theme.ts`
- TailwindCSS v4 is installed but primarily used via `@import "tailwindcss"` base — most styling is through Ant Design + custom CSS classes
- Primary: `#1B3A5C` (deep navy)
- Accent: `#0891B2` (teal)
- Success: `#059669`
- Warning: `#D97706`
- Error: `#DC2626`
- Background: `#F0F2F5`
- Sidebar: `#0F1A2E`
## Language
- **ALL UI text MUST be in Vietnamese with diacritics** (co dau)
- Labels, messages, placeholders, tooltips, tags — everything in Vietnamese
- API error messages are also in Vietnamese
- Constants file uses Vietnamese labels: `e_office_app_new/frontend/src/config/constants.ts`
## Git Conventions
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

## Pattern Overview
- Two-tier backend: Express routes call repositories directly (no service layer for most modules; auth is the exception with `auth.service.ts`)
- All data access goes through PostgreSQL stored functions/procedures — no raw SQL in application code (except the query helpers)
- Frontend is a Next.js App Router SPA that talks to the backend via REST API (axios)
- State management via Zustand stores on the frontend
- File storage via MinIO (S3-compatible object storage)
- JWT-based authentication with access/refresh token rotation
## Layers
- Purpose: Client-side SPA with server-side layout rendering
- Location: `e_office_app_new/frontend/src/`
- Contains: Pages (App Router), components, stores, hooks, lib utilities
- Depends on: Backend REST API via axios
- Used by: End users (browser)
- Purpose: HTTP API layer — receives requests, validates, calls repositories, returns JSON
- Location: `e_office_app_new/backend/src/`
- Contains: Routes, middleware, repositories, services, lib (DB/auth/MinIO/Redis/MongoDB clients)
- Depends on: PostgreSQL (via pg pool), MinIO, MongoDB, Redis
- Used by: Frontend
- Purpose: All business logic and data validation lives in stored procedures/functions
- Location: `e_office_app_new/database/`
- Contains: Schema creation scripts, migration SQL files with stored procedures
- Depends on: PostgreSQL extensions (uuid-ossp, pgcrypto, unaccent, pg_trgm)
- Used by: Backend repositories via `callFunction()` / `callFunctionOne()`
- Purpose: Shared TypeScript types and constants used by both frontend and backend
- Location: `e_office_app_new/shared/src/`
- Contains: API response types, auth types, business constants (urgent levels, secret levels, doc statuses)
- Used by: Frontend and backend
- Purpose: BullMQ-based background job processing
- Location: `e_office_app_new/workers/src/`
- Contains: Job definitions and queue configurations (currently empty/stub)
- Depends on: Redis (via ioredis), BullMQ
## Data Flow
- Zustand store at `frontend/src/stores/auth.store.ts` holds user session state
- Each page component manages its own local state (Ant Design table pagination, form state, etc.)
- No global data cache — pages fetch data on mount via `useEffect` + `api.get()`
## Key Abstractions
- Purpose: Encapsulate all database calls behind typed interfaces
- Examples: `backend/src/repositories/department.repository.ts`, `backend/src/repositories/incoming-doc.repository.ts`, `backend/src/repositories/auth.repository.ts`
- Pattern: Each repository exports a const object with async methods. Methods call `callFunction<T>()` or `callFunctionOne<T>()` with the PostgreSQL function name and parameters.
- `callFunction<T>(name, params)` — calls a PostgreSQL function, returns array of rows
- `callFunctionOne<T>(name, params)` — calls a function, returns first row or null
- `callProcedure(name, params)` — calls a PostgreSQL procedure (void)
- `rawQuery<T>(sql, params)` — escape hatch for ad-hoc SQL
- `withTransaction<T>(callback)` — wraps callback in BEGIN/COMMIT/ROLLBACK
- Purpose: Group related endpoints into Express Router instances
- Examples: `backend/src/routes/admin.ts` (departments, positions, staff, roles, rights), `backend/src/routes/admin-catalog.ts` (doc books, doc types, fields, signers, work groups, delegations, addresses, calendars, templates, config), `backend/src/routes/incoming-doc.ts`
- Pattern: Each file creates a Router, defines route handlers inline (no controller classes), and exports default router
- Naming convention: `[schema].fn_[entity]_[action]` (e.g., `edoc.fn_incoming_doc_create`, `public.fn_department_get_tree`)
- `public` schema: system entities (departments, staff, roles, positions, rights)
- `edoc` schema: document entities (incoming docs, outgoing docs, drafts)
- Functions handle validation and return structured results (e.g., `TABLE(success BOOLEAN, message TEXT, id BIGINT)`)
- `public` — System tables: staff, departments, positions, roles, rights, login logs
- `edoc` — Document tables: incoming_docs, outgoing_docs, drafting_docs, attachments
- `esto` — Archive/storage (planned)
- `cont` — Contracts (planned)
- `iso` — ISO documents (planned)
## Entry Points
- Location: `e_office_app_new/backend/src/server.ts`
- Triggers: `npm run dev` (tsx watch) or `npm start` (compiled JS)
- Responsibilities: Initializes Express app, registers middleware (helmet, cors, compression, cookie-parser, pino-http), mounts route modules, starts HTTP server on port 4000
- Location: `e_office_app_new/frontend/src/app/layout.tsx` (root layout)
- Triggers: `npm run dev` (Next.js dev server on port 3000)
- Responsibilities: Renders root HTML with Plus Jakarta Sans font, wraps children in `AntdProvider`
- Location: `e_office_app_new/frontend/src/app/(main)/layout.tsx`
- Triggers: Any authenticated route under `(main)` group
- Responsibilities: Wraps pages in `MainLayout` component (sidebar navigation + header)
- Location: `e_office_app_new/frontend/src/app/(auth)/login/`
- Triggers: `/login` route
- Responsibilities: Login page outside main layout
- Location: `e_office_app_new/database/init/01_create_schemas.sql`
- Triggers: First PostgreSQL container startup
- Responsibilities: Creates schemas (edoc, esto, cont, iso) and enables extensions
- Location: `e_office_app_new/database/migrations/001_system_tables.sql` through `009_sprint4_drafting_outgoing.sql`
- Triggers: Manual execution (no migration runner)
- Responsibilities: Create tables, indexes, stored procedures per sprint
## Error Handling
- Each route file defines a `handleDbError()` function that maps PostgreSQL error codes (23505=unique, 23503=FK, 23502=not null) to Vietnamese messages
- Stored procedures return structured results with `success BOOLEAN, message TEXT` for business validation
- Auth errors use custom `AuthError` class with `statusCode` property (`backend/src/services/auth.service.ts`)
- Global Express error handler in `server.ts` catches unhandled errors; hides raw messages in production
- Frontend axios interceptor handles 401 (auto-refresh) and redirects to `/login` on failure
## Cross-Cutting Concerns
- Backend uses `pino` + `pino-http` for structured JSON logging
- Dev mode uses `pino-pretty` for readable console output
- Configured in `backend/src/server.ts`
- Primary validation in PostgreSQL stored procedures (server-side, authoritative)
- `zod` is listed as dependency but validation is mostly done in stored procedures
- Frontend uses Ant Design Form validation rules
- JWT via `jose` library (HS256)
- Access token: 15min expiry, stored in localStorage
- Refresh token: 7d expiry, stored as httpOnly cookie + hash in DB
- Token rotation on refresh (old token revoked, new token issued)
- Middleware: `authenticate` (verify token), `requireRoles(...roles)` (RBAC)
- Defined in `backend/src/middleware/auth.ts` and `backend/src/lib/auth/jwt.ts`
- Role-based via `requireRoles()` middleware
- Token payload includes `roles: string[]`, `staffId`, `unitId`, `departmentId`
- Staff-unit scoping: queries filter by `unitId` from JWT to enforce multi-tenancy
- MinIO client at `backend/src/lib/minio/client.ts`
- Upload via `multer` memory storage (`backend/src/middleware/upload.ts`, 50MB limit)
- Files stored with UUID-based paths in MinIO bucket `documents`
- Download via presigned URLs (1 hour expiry)
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, or `.github/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

## Phase Execution Rules (Bài học từ Phase 4-5)

### Quy trình thực thi bắt buộc

**Wave 1 (DB migrations):**
- Tạo migration → **chạy vào DB ngay** → verify SP hoạt động (test trực tiếp bằng psql trong docker)
- Kiểm tra reserved words (`position`, `offset`, `limit`, `order`...) phải quote bằng `""`
- Kiểm tra cột tham chiếu tồn tại thực sự trong bảng (không giả định `is_deleted` có sẵn)

**Wave 2 (Backend repos + routes) — TUẦN TỰ:**
- Agent backend **PHẢI query DB** (`\d table_name`) để lấy tên cột thật trước khi viết Row interface
- Không "tưởng tượng" cột — chỉ dùng cột có trong bảng
- SP trả về đúng tên cột DB (snake_case), KHÔNG alias/rename

**Wave 3 (Frontend pages) — TUẦN TỰ:**
- Agent frontend **PHẢI đọc file repository** đã tạo ở Wave 2 để lấy đúng tên field
- Không tự đặt tên field — copy từ Row interface
- Kiểm tra API endpoint paths khớp với routes backend

**Integration check sau MỖI wave**, không chỉ cuối phase.

### Khi nào được chạy song song?
- Các module **hoàn toàn độc lập** (không share file, không share bảng, không gọi nhau)
- Khi nghi ngờ → chạy tuần tự

### Commit
- KHÔNG tự động commit. Chỉ commit khi user yêu cầu rõ ràng.

### Bài học cụ thể
- Phase 5: 15 bugs do parallel agents (missing routes, `file_url` vs `file_path`, `created_at` vs `created_date`, `is_deleted` không tồn tại, reserved word `position`)
- Sprint 4: Tên trường không thống nhất giữa SP ↔ repository ↔ frontend

### Checklist lỗi thường gặp — PHẢI kiểm tra khi viết code

#### 1. Field name mismatch (SP ↔ Repository ↔ Frontend)
- SP trả `created_date` nhưng frontend dùng `created_at` → **luôn dùng đúng tên SP trả về**
- SP trả `file_path` nhưng frontend dùng `file_url` → **copy tên từ SP output**
- SP trả `staff_name` nhưng frontend dùng `full_name` → **đọc SP RETURNS TABLE trước khi đặt tên interface**
- Frontend định nghĩa field SP không trả về (`secretary_name`, `department_name`, `doc_type_name`) → **chỉ khai báo field có trong SP output**

#### 2. API route path sai
- Frontend gọi `/danh-muc/linh-vuc` nhưng backend mount ở `/quan-tri/linh-vuc` → **đọc server.ts để biết đúng path**
- Frontend gọi `/quan-tri/nhan-vien` nhưng route tên `/quan-tri/nguoi-dung` → **search trong routes/ thay vì đoán**
- Frontend gọi `/nguoi-dung/list` nhưng route dùng `/:id` → `list` bị catch bởi param → **tránh path trùng với route param**

#### 3. Query param naming
- Frontend gửi `page_size` (snake_case) nhưng backend đọc `pageSize` (camelCase) → **kiểm tra req.query trong route handler**
- Pagination response: thống nhất `{ pagination: { total, page, pageSize } }` hoặc `{ total, page, pageSize }` — KHÔNG mix

#### 4. PostgreSQL reserved words
- Các từ PHẢI quote bằng `""` trong RETURNS TABLE và SELECT: `position`, `offset`, `limit`, `order`, `user`, `type`, `comment`, `key`, `value`, `name`
- Nếu SP tạo thành công nhưng runtime lỗi "does not exist" → check reserved word trong RETURNS TABLE

#### 5. Cột không tồn tại trong bảng
- Không giả định `is_deleted` có sẵn — nhiều bảng (incoming_docs, outgoing_docs, handling_docs) KHÔNG có soft delete
- **PHẢI chạy `\d schema.table_name`** trong docker để verify cột tồn tại trước khi viết SP

#### 6. SQL alias conflict
- Không dùng alias trùng tên cột: `JOIN incoming_docs id` → `id.is_deleted` conflict với cột `id` → **dùng alias rõ ràng: `ind`, `od`, `hd`**

#### 7. Ant Design 6 deprecated APIs
- `Drawer`: dùng `size={720}` thay vì `width={720}`
- `List` component: deprecated → dùng `.map()` + `Pagination` riêng
- Kiểm tra AntD 6 migration guide khi dùng component

#### 8. Data type mismatch (DB type ↔ TypeScript type)
- DB `VARCHAR` → TS `string` (KHÔNG dùng `number`)
- DB `INTEGER/SMALLINT` → TS `number` (KHÔNG dùng `string`)
- DB `BIGINT` → TS `number` (OK cho IDs thông thường, `string` nếu giá trị rất lớn)
- DB `BOOLEAN` → TS `boolean` (KHÔNG dùng `number`)
- DB `NUMERIC/DECIMAL` → TS `number` (KHÔNG dùng `string`)
- DB `TIMESTAMP/DATE` → TS `string` (pg driver trả ISO string, KHÔNG dùng `Date`)
- Đặc biệt: nếu DB là `VARCHAR` (VD: `amount VARCHAR(200)`) thì frontend KHÔNG được dùng `<InputNumber>` — phải dùng `<Input>`

#### 9. maxLength validation trên form
- Mỗi `<Input>` trong form **PHẢI có `maxLength={N}`** khớp với DB `VARCHAR(N)`
- Mỗi `<Input.TextArea>` dùng `maxLength={N}` với `showCount`
- Bảng tham chiếu nhanh:
  - `code`: thường `VARCHAR(20-100)` → `maxLength={50}` hoặc theo DB
  - `name`: thường `VARCHAR(200-500)` → `maxLength={200}` hoặc theo DB
  - `phone`: `VARCHAR(50)` → `maxLength={50}`
  - `address`: `VARCHAR(500)` → `maxLength={500}`
  - `email`: `VARCHAR(200)` → `maxLength={200}`
- **PHẢI query `\d schema.table_name`** để lấy chính xác limit, KHÔNG đoán

#### 10. NOT NULL → required validation
- DB column `NOT NULL` (không có DEFAULT) → Form.Item phải có `rules={[{ required: true, message: '...' }]}`
- Đặc biệt: `<Select>` cho FK columns (room_id, staff_id, department_id) cũng cần `required` rule

#### 11. Format validation trên form
- **Email**: `rules={[{ type: 'email', message: 'Email không hợp lệ' }]}` — áp dụng cho tất cả field email
- **Số điện thoại/fax**: `rules={[{ pattern: /^[0-9+\-\s()]*$/, message: 'Số điện thoại không hợp lệ' }]}`
- **Số (sort_order, number...)**: dùng `<InputNumber>` thay vì `<Input type="number">`
- **Tiền/số lượng**: nếu DB là `VARCHAR` → dùng `<Input>`, nếu DB là `INTEGER/NUMERIC` → dùng `<InputNumber>`

#### 12. Date range validation
- Khi form có cặp `start_date` / `end_date`: **PHẢI validate end_date >= start_date** bằng Form rules
- Dùng pattern `dependencies` + `validator`:
  ```tsx
  <Form.Item name="end_date" dependencies={['start_date']} rules={[{
    validator: (_, value) => {
      const start = form.getFieldValue('start_date');
      if (start && value && dayjs(value).isBefore(dayjs(start)))
        return Promise.reject('Ngày kết thúc phải sau ngày bắt đầu');
      return Promise.resolve();
    }
  }]}>
  ```
- **KHÔNG validate ngày trong handleSave()** — phải dùng Form rules để user thấy lỗi inline

#### 13. setBackendFieldError cho unique constraint
- Mỗi page có form CRUD **PHẢI có `setBackendFieldError`** để map lỗi unique violation thành inline field error
- Đọc `error-handler.ts` để biết Vietnamese message cho mỗi constraint
- Pattern:
  ```tsx
  const setBackendFieldError = (msg: string): boolean => {
    const map: Record<string, string> = { 'Mã ... đã tồn tại': 'code' };
    const field = map[msg];
    if (field) { form.setFields([{ name: field, errors: [msg] }]); return true; }
    return false;
  };
  // Trong catch: if (!setBackendFieldError(msg)) message.error(msg);
  ```

#### 14. Password validation
- Đổi mật khẩu: yêu cầu mật khẩu cũ + mật khẩu mới (min 6 ký tự, có chữ hoa + số) + xác nhận mật khẩu mới
- Xác nhận mật khẩu: dùng `dependencies={['new_password']}` + validator so sánh
- Đăng nhập sai: hiển thị `message.error()` với thông báo từ backend



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
