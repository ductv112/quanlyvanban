# External Integrations

**Analysis Date:** 2026-04-14

## APIs & External Services

**Email Delivery:**
- Nodemailer - Email sending service
  - SDK/Client: `nodemailer` 8.0.5
  - Status: Prepared but NOT fully implemented
  - Worker: `/d/ProjectAI/quanlyvanban/e_office_app_new/workers/src/index.ts` (TODO: implement nodemailer send)
  - Queue: BullMQ job `email-send`

**SMS Gateway:**
- Not implemented
  - Worker: `/d/ProjectAI/quanlyvanban/e_office_app_new/workers/src/index.ts` (TODO: implement SMS gateway)
  - Queue: BullMQ job `sms-send`

**Firebase Cloud Messaging (FCM):**
- Mobile push notifications
  - Status: Planned but NOT implemented
  - Worker: `/d/ProjectAI/quanlyvanban/e_office_app_new/workers/src/index.ts` (TODO: implement Firebase FCM)
  - Queue: BullMQ job `fcm-push`

**LGSP Integration:**
- Vietnamese government document exchange system
  - Status: Planned but NOT implemented
  - Worker: `/d/ProjectAI/quanlyvanban/e_office_app_new/workers/src/index.ts` (TODO: implement LGSP API polling)
  - Queue: BullMQ job `lgsp-receive`
  - Purpose: Polling for new documents from LGSP service

## Data Storage

**Databases:**
- PostgreSQL 16
  - Host: `PG_HOST` (default: localhost:5432)
  - Database: `qlvb_dev`
  - Credentials: `PG_USER` / `PG_PASSWORD`
  - Client: `pg` 8.20.0 (native driver, no ORM)
  - Connection Pool: max 20 connections, 30s idle timeout
  - Location: Pool configured at `/d/ProjectAI/quanlyvanban/e_office_app_new/backend/src/lib/db/pool.ts`
  - Migrations: `/d/ProjectAI/quanlyvanban/e_office_app_new/database/migrations/`
  - Init Scripts: `/d/ProjectAI/quanlyvanban/e_office_app_new/database/init/`
  - Stored Procedures: All business logic in PL/pgSQL SPs (no ORM usage per requirement)

- MongoDB 7
  - Purpose: Logging and audit trails
  - URI: `MONGODB_URI`
  - Database: `qlvb_logs`
  - Client: `mongoose` 9.4.1 (ODM for schema definition)
  - Connection: `/d/ProjectAI/quanlyvanban/e_office_app_new/backend/src/lib/mongodb/client.ts`

**File Storage:**
- MinIO (S3-compatible)
  - Endpoint: `MINIO_ENDPOINT` (default: localhost:9000)
  - Port: `MINIO_PORT` (default: 9000)
  - Bucket: `MINIO_BUCKET` (default: `documents`)
  - Credentials: `MINIO_ACCESS_KEY` / `MINIO_SECRET_KEY`
  - Client: `minio` 8.0.7
  - Location: `/d/ProjectAI/quanlyvanban/e_office_app_new/backend/src/lib/minio/client.ts`
  - Functions:
    - `uploadFile()` - Store documents
    - `getFileUrl()` - Presigned URLs (1-hour expiry by default)
    - `deleteFile()` - Remove documents
  - Web Console: Accessible on `MINIO_PORT + 1` (e.g., 9001 for localhost)

**Caching:**
- Redis 7
  - Host: `REDIS_HOST` (default: localhost:6379)
  - Port: `REDIS_PORT` (default: 6379)
  - Password: `REDIS_PASSWORD` (required)
  - Client: `ioredis` 5.10.1
  - Configuration: `/d/ProjectAI/quanlyvanban/e_office_app_new/backend/src/lib/redis/client.ts`
  - Cached Helper: `cached<T>(key, fetcher, ttlSeconds)`
  - Cache Invalidation: `invalidateCache(pattern)`
  - Job Queue Backend: For BullMQ workers
  - Memory Limit: 256MB with LRU eviction policy

## Authentication & Identity

**Auth Provider:**
- Custom JWT-based authentication
  - Implementation: `/d/ProjectAI/quanlyvanban/e_office_app_new/backend/src/lib/auth/jwt.ts`
  - Algorithm: HS256 (HMAC with SHA-256)
  - Secret: `JWT_SECRET` (environment variable, fallback: 'fallback-secret')
  - Access Token: Expires in `JWT_ACCESS_EXPIRES` (default: 15m)
  - Refresh Token: Expires in `JWT_REFRESH_EXPIRES` (default: 7d)
  - Token Payload: Includes staffId, unitId, departmentId, username, roles array
  - Password Hashing: bcryptjs 3.0.3 with hash/verify functions
  - Token Verification: `/d/ProjectAI/quanlyvanban/e_office_app_new/backend/src/lib/auth/password.ts`

**Login Flow:**
- Username/password validation against PostgreSQL
- Returns accessToken + refreshToken + user profile object
- Tokens stored in localStorage (frontend) and cookies (httpOnly refresh token planned)
- Service: `/d/ProjectAI/quanlyvanban/e_office_app_new/backend/src/services/auth.service.ts`

**Frontend Token Management:**
- Axios interceptor: Attaches `Authorization: Bearer {accessToken}` to all requests
- Auto-refresh: On 401 response, calls `/api/auth/refresh` endpoint
- Fallback: Redirects to `/login` if refresh fails
- Location: `/d/ProjectAI/quanlyvanban/e_office_app_new/frontend/src/lib/api.ts`

## Monitoring & Observability

**Error Tracking:**
- None detected - only console error logging

**Logs:**
- Structured JSON logging via Pino
  - Backend: `pino` with `pino-http` middleware
  - Workers: `pino` with environment-based verbosity
  - Dev mode: `pino-pretty` for readable output
  - Production mode: Raw JSON to stdout
  - Login Audit: Logged to PostgreSQL via `authRepository.logLogin()`
  - Middleware: `/d/ProjectAI/quanlyvanban/e_office_app_new/backend/src/server.ts` (line 22-25)

## CI/CD & Deployment

**Hosting:**
- Docker Compose (local/dev environment)
- Not specified for production (likely manual deployment or CI/CD pipeline not in scope)

**CI Pipeline:**
- Not detected - no GitHub Actions, GitLab CI, or Jenkins config files

## Environment Configuration

**Required env vars (Backend):**

```
# Server
PORT=4000
NODE_ENV=development|production
CORS_ORIGIN=http://localhost:3000

# PostgreSQL
PG_HOST=localhost
PG_PORT=5432
PG_DATABASE=qlvb_dev
PG_USER=qlvb_admin
PG_PASSWORD=your_pg_password
PG_MAX_CONNECTIONS=20

# MongoDB
MONGODB_URI=mongodb://user:pass@host:27017/dbname?authSource=admin

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password

# MinIO
MINIO_ENDPOINT=localhost
MINIO_PORT=9000
MINIO_ACCESS_KEY=qlvb_admin
MINIO_SECRET_KEY=your_minio_password
MINIO_USE_SSL=false
MINIO_BUCKET=documents

# JWT
JWT_SECRET=change-this-to-random-in-production
JWT_ACCESS_EXPIRES=15m
JWT_REFRESH_EXPIRES=7d
```

**Required env vars (Frontend):**

```
NEXT_PUBLIC_APP_NAME=Quản lý Văn bản
NEXT_PUBLIC_APP_URL=http://localhost:3000
NEXT_PUBLIC_API_URL=http://localhost:4000/api
```

**Secrets location:**
- Backend: `.env` file (not committed, example provided in `.env.example`)
- Frontend: `.env.local` file (not committed, example provided in `.env.example`)

## Webhooks & Callbacks

**Incoming:**
- None detected in current implementation

**Outgoing:**
- Email notifications (prepared, not implemented)
- SMS notifications (prepared, not implemented)
- Push notifications via FCM (prepared, not implemented)
- LGSP document polling (prepared, not implemented)

## Background Jobs & Queue System

**Job Queue Framework:**
- BullMQ 5.73.5 - Queue management built on Redis
- Connection: Redis with maxRetriesPerRequest: null (for BullMQ compatibility)

**Job Types:**
- `email-send` - Email delivery via nodemailer (TODO)
- `sms-send` - SMS delivery (TODO)
- `fcm-push` - Firebase push notifications (TODO)
- `lgsp-receive` - LGSP document polling (TODO)

**Worker Process:**
- Location: `/d/ProjectAI/quanlyvanban/e_office_app_new/workers/`
- Package: `qlvb-workers` with separate entry point
- Run: `npm run dev` (tsx watch) or `npm start` (compiled Node.js)
- Graceful shutdown: Closes all workers on SIGTERM

---

*Integration audit: 2026-04-14*
