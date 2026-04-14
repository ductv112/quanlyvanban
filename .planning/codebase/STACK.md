# Technology Stack

**Analysis Date:** 2026-04-14

## Languages

**Primary:**
- TypeScript 5.x & 6.x - Backend (Node.js), frontend (Next.js), and worker processes

**Secondary:**
- SQL (PostgreSQL with PL/pgSQL) - Stored procedures and migrations
- CSS (Tailwind CSS) - Frontend styling

## Runtime

**Environment:**
- Node.js (version not specified in config, inferred from package.json compatibility)
- Development: tsx watch for hot reload
- Production: Compiled JavaScript

**Package Manager:**
- npm (standard package manager)
- Lockfile: Not detected (no package-lock.json, yarn.lock, or pnpm-lock.yaml in repo)

## Frameworks

**Core:**
- Express.js 5.2.1 - Backend REST API server (`/d/ProjectAI/quanlyvanban/e_office_app_new/backend/src/server.ts`)
- Next.js 16.2.3 - Frontend React app with SSR and routing
- React 19.2.4 - UI component library
- React DOM 19.2.4 - DOM rendering

**Testing:**
- Not detected - no test runners configured in package.json (jest, vitest, etc.)

**Build/Dev:**
- TypeScript 5.0 & 6.0.2 - Compilation
- TSX 4.21.0 - TypeScript execution and hot reload
- ESLint 9.x - Code linting
- Tailwind CSS 4.x - Utility-first CSS framework
- PostCSS 4.x - CSS processing pipeline

## Key Dependencies

**Critical:**
- pg 8.20.0 - PostgreSQL client for direct SQL queries (stored procedures)
- mongoose 9.4.1 - MongoDB ODM for logging/audit trails
- ioredis 5.10.1 - Redis client for caching and job queues
- bullmq 5.73.5 - Job queue built on Redis (email, SMS, notifications)
- minio 8.0.7 - S3-compatible object storage for documents

**Security:**
- bcryptjs 3.0.3 - Password hashing
- jose 6.2.2 - JWT token signing and verification (HS256 algorithm)
- helmet 8.1.0 - Express security headers middleware

**HTTP & Communication:**
- axios 1.15.0 - Frontend HTTP client (frontend only)
- express 5.2.1 - Backend HTTP server
- cors 2.8.6 - CORS middleware
- cookie-parser 1.4.7 - Cookie parsing middleware
- socket.io 4.8.3 - Real-time bidirectional communication (backend dependency exists but not actively used)
- socket.io-client 4.8.3 - Frontend WebSocket client (not actively used)

**Data Processing:**
- exceljs 4.4.0 - Excel file generation/parsing (both backend and frontend)
- pdf-lib 1.17.1 - PDF manipulation (both backend and frontend)
- zod 4.3.6 - Runtime schema validation (both backend and frontend)
- multer 2.1.1 - File upload handling middleware
- compression 1.8.1 - Response compression middleware

**Frontend State & Utilities:**
- zustand 5.0.12 - Lightweight state management (auth.store.ts)
- dayjs 1.11.20 - Date manipulation
- numeral 2.0.6 - Number formatting
- Ant Design 6.3.5 - Component UI library
- Ant Design Icons 6.1.1 - Icon set
- Ant Design CSS-in-JS 2.1.2 - Dynamic styling for Ant Design

**Logging:**
- pino 10.3.1 - Structured JSON logging (backend and workers)
- pino-http 11.0.0 - HTTP request/response logging middleware
- pino-pretty 13.1.3 - Dev-time pretty printer for logs

**Utilities:**
- uuid 13.0.0 - UUID generation
- nodemailer 8.0.5 - Email sending (prepared for use, not fully implemented)
- dotenv 17.4.2 - Environment variable loading

## Configuration

**Environment:**
- `.env` file required for backend with postgres, mongodb, redis, minio, and JWT secrets
  - Location: `/d/ProjectAI/quanlyvanban/e_office_app_new/backend/.env`
  - Template: `/d/ProjectAI/quanlyvanban/e_office_app_new/backend/.env.example`
- `.env.local` for frontend configuration
  - Location: `/d/ProjectAI/quanlyvanban/e_office_app_new/frontend/.env.local`
  - Template: `/d/ProjectAI/quanlyvanban/e_office_app_new/frontend/.env.example`

**Build:**
- `tsconfig.json` - Backend TypeScript configuration (`/d/ProjectAI/quanlyvanban/e_office_app_new/backend/tsconfig.json`)
  - Target: ES2022
  - Module: ESNext
  - Strict mode enabled
  - Path aliases: `@/*` points to `src/`, `@shared/*` points to shared types
- `tsconfig.json` - Frontend TypeScript configuration (`/d/ProjectAI/quanlyvanban/e_office_app_new/frontend/tsconfig.json`)
  - Target: ES2017
  - Module: esnext
  - Path aliases: `@/*` points to `./src/`
- `next.config.ts` - Next.js configuration (minimal, no custom middleware)
- `eslint.config.mjs` - ESLint configuration with Next.js rules
- `postcss.config.mjs` - PostCSS with Tailwind CSS plugin

## Platform Requirements

**Development:**
- Node.js 18+ (inferred from modern package versions)
- npm or compatible package manager
- Docker & Docker Compose (for local services: PostgreSQL, MongoDB, Redis, MinIO)

**Production:**
- Node.js 18+ runtime
- Separate PostgreSQL 16 instance
- Separate MongoDB 7 instance
- Separate Redis 7 instance
- Separate MinIO S3-compatible storage

**Docker Services (docker-compose.yml):**
- PostgreSQL 16-alpine - Primary relational database
- MongoDB 7 - Audit and logging
- Redis 7-alpine - Cache and job queue
- MinIO - Document/file storage (S3-compatible)

---

*Stack analysis: 2026-04-14*
