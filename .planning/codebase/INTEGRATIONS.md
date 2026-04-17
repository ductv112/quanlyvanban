# External Integrations

**Analysis Date:** 2026-04-14

## APIs & External Services

**Email Delivery:**
- Nodemailer - Email sending service
  - SDK/Client: `nodemailer` ^8.0.5
  - Status: Worker stub exists, NOT implemented (TODO in `e_office_app_new/workers/src/index.ts` line 22)
  - Queue: BullMQ job `email-send`

**SMS Gateway:**
- Not implemented
  - Worker stub exists at `e_office_app_new/workers/src/index.ts` line 30
  - Queue: BullMQ job `sms-send`

**Firebase Cloud Messaging (FCM):**
- Mobile push notifications
  - Status: Worker stub exists, NOT implemented (`e_office_app_new/workers/src/index.ts` line 49)
  - Queue: BullMQ job `fcm-push`
  - No Firebase SDK installed

**LGSP Integration (Lien thong):**
- Vietnamese government document exchange system (Truc lien thong van ban)
  - Status: Worker stub exists, NOT implemented (`e_office_app_new/workers/src/index.ts` line 39)
  - Queue: BullMQ job `lgsp-receive`
  - Purpose: Polling for new documents from LGSP service
  - Frontend module exists: `e_office_app_new/frontend/src/app/(main)/van-ban-lien-thong/`
  - Backend routes exist: `e_office_app_new/backend/src/routes/inter-incoming.ts`
  - Repository exists: `e_office_app_new/backend/src/repositories/inter-incoming.repository.ts`

## Real-Time Communication

**Socket.IO (WebSocket):**
- Actively used for real-time notifications and messaging
- Backend: `e_office_app_new/backend/src/lib/socket.ts`
  - Server initialization with JWT authentication middleware
  - Per-user rooms: `user_{staffId}`
  - Events: `new_document`, `new_message`, `new_notification`, `doc_status_changed`
  - Helper functions: `emitToUser()`, `emitToUsers()`
  - Used in: `e_office_app_new/backend/src/routes/message.ts` (message send triggers socket emit)
- Frontend: `e_office_app_new/frontend/src/lib/socket.ts`
  - Client initialization with auth token
  - Auto-reconnect with 3-second delay
  - Connected in: `e_office_app_new/frontend/src/components/layout/MainLayout.tsx`

## Data Storage

**PostgreSQL 16 (Primary Database):**
- Docker image: `postgres:16-alpine`
- Default database: `qlvb_dev`
- Connection pool: `e_office_app_new/backend/src/lib/db/pool.ts`
  - Max connections: 20 (configurable via `PG_MAX_CONNECTIONS`)
  - Idle timeout: 30 seconds
  - Connection timeout: 5 seconds
- Client: `pg` ^8.20.0 (native driver, NO ORM)
- All business logic in PL/pgSQL stored procedures
- Env vars: `PG_HOST`, `PG_PORT`, `PG_DATABASE`, `PG_USER`, `PG_PASSWORD`, `PG_MAX_CONNECTIONS`
- Init scripts: `e_office_app_new/database/init/01_create_schemas.sql`
- Migrations: `e_office_app_new/database/migrations/001_system_tables.sql` through `015_sprint10_dashboard_stats.sql`
- Seed data: `e_office_app_new/database/seed_demo.sql`

**MongoDB 7 (Audit & Logging):**
- Docker image: `mongo:7`
- Database: `qlvb_logs`
- Client: `mongoose` ^9.4.1
- Connection: `e_office_app_new/backend/src/lib/mongodb/client.ts`
- Env var: `MONGODB_URI`
- Purpose: Login audit trails and structured logging

**MinIO (S3-Compatible File Storage):**
- Docker image: `minio/minio:latest`
- Client: `minio` ^8.0.7
- Configuration: `e_office_app_new/backend/src/lib/minio/client.ts`
- Default bucket: `documents` (configurable via `MINIO_BUCKET`)
- Functions:
  - `uploadFile(path, buffer, contentType)` - Store documents
  - `getFileUrl(path, expirySeconds)` - Presigned URLs (default 1-hour expiry)
  - `deleteFile(path)` - Remove documents
  - `ensureBucket()` - Auto-create bucket if missing
- Env vars: `MINIO_ENDPOINT`, `MINIO_PORT`, `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`, `MINIO_USE_SSL`, `MINIO_BUCKET`
- Web Console: Port 9001

**Redis 7 (Cache + Job Queue):**
- Docker image: `redis:7-alpine`
- Client: `ioredis` ^5.10.1
- Configuration: `e_office_app_new/backend/src/lib/redis/client.ts`
- Memory limit: 256MB with `allkeys-lru` eviction policy
- Dual purpose:
  1. **Caching:** Generic `cached<T>(key, fetcher, ttlSeconds)` helper with 1-hour default TTL
  2. **Job Queue:** BullMQ backend (requires `maxRetriesPerRequest: null`)
- Cache invalidation: `invalidateCache(pattern)` using Redis KEYS + DEL
- Env vars: `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD`

## Authentication & Identity

**Custom JWT-Based Authentication:**
- Implementation: `e_office_app_new/backend/src/lib/auth/jwt.ts`
- Algorithm: HS256 (HMAC with SHA-256) via `jose` ^6.2.2
- Secret: `JWT_SECRET` env var (fallback: `'fallback-secret'`)
- Access Token: Configurable expiry via `JWT_ACCESS_EXPIRES` (default: 15m)
- Refresh Token: Configurable expiry via `JWT_REFRESH_EXPIRES` (default: 7d)
- Token Payload (`TokenPayload` interface):
  - `staffId: number`
  - `unitId: number`
  - `departmentId: number`
  - `username: string`
  - `roles: string[]`
- Password Hashing: `bcryptjs` ^3.0.3

**Login Flow:**
1. Frontend posts username/password to `/api/auth/login`
2. Backend validates against PostgreSQL stored procedure
3. Returns `{ accessToken, user }` object
4. Frontend stores accessToken in `localStorage`
5. Auth service: `e_office_app_new/backend/src/services/auth.service.ts`
6. Auth repository: `e_office_app_new/backend/src/repositories/auth.repository.ts`

**Frontend Token Management:** (`e_office_app_new/frontend/src/lib/api.ts`)
- Axios request interceptor: Attaches `Authorization: Bearer {token}` from localStorage
- Axios response interceptor: On 401, attempts refresh via `POST /api/auth/refresh`
- On refresh failure: Clears localStorage, redirects to `/login`
- Auth state: Zustand store at `e_office_app_new/frontend/src/stores/auth.store.ts`

**Auth Middleware:** (`e_office_app_new/backend/src/middleware/auth.ts`)
- Applied to all routes except `/api/health` and `/api/auth`

## Error Handling (Database Layer)

**PostgreSQL Error Mapping:** (`e_office_app_new/backend/src/lib/error-handler.ts`)
- Unique violation (23505): Maps constraint names to Vietnamese messages
- Foreign key violation (23503): Generic reference error message
- Not null violation (23502): Column-specific required field message
- Default: Hides raw errors in production

## Monitoring & Observability

**Error Tracking:**
- None - no Sentry, Datadog, or similar service

**Logging:**
- Structured JSON logging via Pino
  - Backend: `pino` with `pino-http` middleware on all requests
  - Workers: `pino` with environment-based verbosity
  - Dev mode: `pino-pretty` for human-readable output
  - Production: Raw JSON to stdout
- Login audit: Logged to PostgreSQL via `authRepository.logLogin()`

## CI/CD & Deployment

**Hosting:**
- Docker Compose for local/dev infrastructure (`e_office_app_new/docker-compose.yml`)
- No production deployment configuration detected

**CI Pipeline:**
- Not configured - no GitHub Actions, GitLab CI, or Jenkins files

## Environment Configuration

**Required env vars (Backend) - template at `e_office_app_new/backend/.env.example`:**

| Variable | Default | Purpose |
|----------|---------|---------|
| `PORT` | 4000 | Backend server port |
| `NODE_ENV` | development | Environment mode |
| `CORS_ORIGIN` | http://localhost:3000 | Allowed CORS origin |
| `PG_HOST` | localhost | PostgreSQL host |
| `PG_PORT` | 5432 | PostgreSQL port |
| `PG_DATABASE` | qlvb_dev | PostgreSQL database name |
| `PG_USER` | qlvb_admin | PostgreSQL user |
| `PG_PASSWORD` | (required) | PostgreSQL password |
| `PG_MAX_CONNECTIONS` | 20 | Connection pool size |
| `MONGODB_URI` | (required) | MongoDB connection string |
| `REDIS_HOST` | localhost | Redis host |
| `REDIS_PORT` | 6379 | Redis port |
| `REDIS_PASSWORD` | (required) | Redis password |
| `MINIO_ENDPOINT` | localhost | MinIO endpoint |
| `MINIO_PORT` | 9000 | MinIO API port |
| `MINIO_ACCESS_KEY` | (required) | MinIO access key |
| `MINIO_SECRET_KEY` | (required) | MinIO secret key |
| `MINIO_USE_SSL` | false | Enable SSL for MinIO |
| `MINIO_BUCKET` | documents | Default storage bucket |
| `JWT_SECRET` | fallback-secret | JWT signing secret |
| `JWT_ACCESS_EXPIRES` | 15m | Access token TTL |
| `JWT_REFRESH_EXPIRES` | 7d | Refresh token TTL |

**Required env vars (Frontend):**

| Variable | Default | Purpose |
|----------|---------|---------|
| `NEXT_PUBLIC_APP_NAME` | Quan ly Van ban | Application display name |
| `NEXT_PUBLIC_APP_URL` | http://localhost:3000 | Frontend base URL |
| `NEXT_PUBLIC_API_URL` | http://localhost:4000/api | Backend API base URL |

**Secrets location:**
- Backend: `.env` file (not committed; `.env.example` provided)
- Frontend: `.env.local` file (not committed)

## Background Jobs & Queue System

**Framework:** BullMQ ^5.73.5 on Redis
- Worker process: `e_office_app_new/workers/` (separate Node.js process)
- Run: `npm run dev` (tsx watch) or `npm start` (compiled)
- Graceful shutdown on SIGTERM

**Job Types (all have TODO stubs):**

| Queue Name | Purpose | Status |
|------------|---------|--------|
| `email-send` | Email delivery via nodemailer | Stub only |
| `sms-send` | SMS delivery via gateway | Stub only |
| `fcm-push` | Firebase push notifications | Stub only |
| `lgsp-receive` | LGSP document polling | Stub only |

## Webhooks & Callbacks

**Incoming:**
- None detected

**Outgoing:**
- Email notifications (stub, not implemented)
- SMS notifications (stub, not implemented)
- Push notifications via FCM (stub, not implemented)
- LGSP document polling (stub, not implemented)

## API Route Map

All backend routes are mounted in `e_office_app_new/backend/src/server.ts`:

| Route Prefix | Auth | Route File | Purpose |
|-------------|------|------------|---------|
| `/api/health` | No | `routes/health.ts` | Health check |
| `/api/auth` | No | `routes/auth.ts` | Login, refresh, logout |
| `/api/quan-tri` | Yes | `routes/admin.ts` | Admin: departments, positions, roles, staff |
| `/api/quan-tri` | Yes | `routes/admin-catalog.ts` | Admin: doc books, doc types, fields, signers, etc. |
| `/api/quan-tri/quy-trinh` | Yes | `routes/workflow.ts` | Workflow designer |
| `/api/van-ban-den` | Yes | `routes/incoming-doc.ts` | Incoming documents (van ban den) |
| `/api/van-ban-du-thao` | Yes | `routes/drafting-doc.ts` | Draft documents (van ban du thao) |
| `/api/van-ban-di` | Yes | `routes/outgoing-doc.ts` | Outgoing documents (van ban di) |
| `/api/van-ban-lien-thong` | Yes | `routes/inter-incoming.ts` | Inter-agency documents (lien thong) |
| `/api/ho-so-cong-viec/thong-ke` | Yes | `routes/handling-doc-report.ts` | Work file reports/statistics |
| `/api/ho-so-cong-viec` | Yes | `routes/handling-doc.ts` | Work files (ho so cong viec) |
| `/api/tin-nhan` | Yes | `routes/message.ts` | Internal messaging |
| `/api/thong-bao` | Yes | `routes/notice.ts` | System notices |
| `/api/lich` | Yes | `routes/calendar.ts` | Calendar/scheduling |
| `/api/danh-ba` | Yes | `routes/directory.ts` | Staff directory |
| `/api/dashboard` | Yes | `routes/dashboard.ts` | Dashboard statistics |

---

*Integration audit: 2026-04-14*
