# Technology Stack

**Analysis Date:** 2026-04-14

## Languages

**Primary:**
- TypeScript 6.0.2 - Backend (`e_office_app_new/backend/`) and workers (`e_office_app_new/workers/`)
- TypeScript 5.x - Frontend (`e_office_app_new/frontend/`)

**Secondary:**
- SQL (PostgreSQL PL/pgSQL) - All stored procedures and migrations (`e_office_app_new/database/`)
- CSS (Tailwind CSS 4.x) - Frontend styling

## Runtime

**Environment:**
- Node.js 18+ (inferred from ES2022 target and modern package versions)
- Development: `tsx watch` for hot reload (backend and workers)
- Development: `next dev` for frontend hot reload
- Production: Compiled JavaScript via `tsc` (backend/workers), `next build` (frontend)

**Package Manager:**
- npm (standard)
- Lockfiles: Present for both backend (`e_office_app_new/backend/package-lock.json`) and frontend (`e_office_app_new/frontend/package-lock.json`)

## Frameworks

**Core:**
- Express.js ^5.2.1 - Backend REST API server (`e_office_app_new/backend/src/server.ts`)
- Next.js 16.2.3 - Frontend React app with App Router (`e_office_app_new/frontend/src/app/`)
- React 19.2.4 / React DOM 19.2.4 - UI rendering

**UI Library:**
- Ant Design (antd) ^6.3.5 - Primary component library
- Ant Design Icons ^6.1.1 - Icon set
- Ant Design CSS-in-JS ^2.1.2 - Dynamic styling engine

**Visualization & Layout:**
- @ant-design/charts ^2.6.7 - Charts for dashboard and reports (`e_office_app_new/frontend/src/app/(main)/dashboard/page.tsx`, `e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/bao-cao/page.tsx`)
- @xyflow/react ^12.10.2 - Workflow designer with nodes/edges (`e_office_app_new/frontend/src/app/(main)/quan-tri/quy-trinh/[id]/thiet-ke/page.tsx`)
- react-grid-layout ^2.2.3 - Draggable grid for dashboard layout

**Testing:**
- Not configured - no test runners (jest, vitest, etc.) in any package.json

**Build/Dev:**
- TypeScript 5.x / 6.0.2 - Compilation
- TSX ^4.21.0 - TypeScript execution without compilation step (dev mode)
- ESLint ^9 with eslint-config-next 16.2.3 - Code linting (frontend only)
- Tailwind CSS ^4 with @tailwindcss/postcss ^4 - Utility-first CSS
- PostCSS - CSS processing pipeline (`e_office_app_new/frontend/postcss.config.mjs`)

## Key Dependencies

**Critical (Backend):**
- pg ^8.20.0 - PostgreSQL client; all DB access via stored procedures (no ORM)
- mongoose ^9.4.1 - MongoDB ODM for audit/logging connection
- ioredis ^5.10.1 - Redis client for caching and BullMQ backend
- bullmq ^5.73.5 - Job queue for background workers (email, SMS, FCM, LGSP)
- minio ^8.0.7 - S3-compatible object storage for document files
- socket.io ^4.8.3 - Real-time WebSocket server (actively used for messages/notifications)

**Security (Backend):**
- bcryptjs ^3.0.3 - Password hashing
- jose ^6.2.2 - JWT token signing/verification (HS256)
- helmet ^8.1.0 - Express security headers
- cors ^2.8.6 - CORS middleware
- cookie-parser ^1.4.7 - Cookie parsing

**HTTP & Middleware (Backend):**
- compression ^1.8.1 - Response gzip compression
- multer ^2.1.1 - Multipart file upload handling
- dotenv ^17.4.2 - Environment variable loading

**Data Processing (Backend):**
- exceljs ^4.4.0 - Excel file generation/parsing
- pdf-lib ^1.17.1 - PDF manipulation
- zod ^4.3.6 - Runtime schema validation

**Logging (Backend):**
- pino ^10.3.1 - Structured JSON logging
- pino-http ^11.0.0 - HTTP request/response logging middleware
- pino-pretty ^13.1.3 - Dev-time pretty printer (devDependency)

**Frontend State & Utilities:**
- zustand ^5.0.12 - Lightweight state management (`e_office_app_new/frontend/src/stores/auth.store.ts`)
- axios ^1.15.0 - HTTP client with interceptors (`e_office_app_new/frontend/src/lib/api.ts`)
- socket.io-client ^4.8.3 - WebSocket client (`e_office_app_new/frontend/src/lib/socket.ts`)
- dayjs ^1.11.20 - Date manipulation and formatting
- numeral ^2.0.6 - Number formatting
- zod ^4.3.6 - Shared validation schemas

**Frontend (backend-like deps - likely copy-paste, used for shared types only):**
- pg, mongoose, ioredis, bullmq, minio, nodemailer, pino, bcryptjs, jose - Present in frontend `package.json` but should only be used server-side or for type imports

**Utilities (Backend):**
- uuid ^13.0.0 - UUID generation
- nodemailer ^8.0.5 - Email sending (prepared, workers have TODO stubs)

## Configuration

**Environment:**
- Backend `.env` file required - template at `e_office_app_new/backend/.env.example`
- Frontend `.env.local` file required - for `NEXT_PUBLIC_*` variables
- Workers share same env vars as backend (Redis, PG connections)

**TypeScript (Backend):** `e_office_app_new/backend/tsconfig.json`
- Target: ES2022
- Module: ESNext
- moduleResolution: bundler
- Strict mode: enabled
- Path aliases: `@/*` -> `src/*`, `@shared/*` -> `../../shared/src/*`
- Output: `dist/`

**TypeScript (Frontend):** `e_office_app_new/frontend/tsconfig.json`
- Target: ES2017
- Module: esnext
- moduleResolution: bundler
- Strict mode: enabled
- Path aliases: `@/*` -> `./src/*`
- Next.js plugin enabled

**Next.js:** `e_office_app_new/frontend/next.config.ts` (minimal config)
**ESLint:** `e_office_app_new/frontend/eslint.config.mjs` (Next.js preset)
**PostCSS:** `e_office_app_new/frontend/postcss.config.mjs` (Tailwind CSS plugin)

## Project Structure (Packages)

The project is a **monorepo-style** layout with 4 packages (no workspace manager):

| Package | Location | Purpose |
|---------|----------|---------|
| qlvb-backend | `e_office_app_new/backend/` | Express REST API server |
| frontend | `e_office_app_new/frontend/` | Next.js web application |
| qlvb-workers | `e_office_app_new/workers/` | BullMQ background job processors |
| shared | `e_office_app_new/shared/` | Shared types and constants |

Each package has its own `package.json` and `node_modules`. No npm/yarn/pnpm workspaces configured.

## Platform Requirements

**Development:**
- Node.js 18+ runtime
- npm package manager
- Docker & Docker Compose for infrastructure services (`e_office_app_new/docker-compose.yml`)

**Docker Compose Services:** (`e_office_app_new/docker-compose.yml`)
- PostgreSQL 16-alpine on port 5432 - Primary relational database
- MongoDB 7 on port 27017 - Audit and logging
- Redis 7-alpine on port 6379 - Cache and job queue (256MB, LRU eviction)
- MinIO latest on ports 9000 (API) / 9001 (Console) - Document file storage

**Production:**
- Node.js 18+ for backend, workers
- Next.js SSR or static export for frontend
- Managed PostgreSQL, MongoDB, Redis, S3-compatible storage

---

*Stack analysis: 2026-04-14*
