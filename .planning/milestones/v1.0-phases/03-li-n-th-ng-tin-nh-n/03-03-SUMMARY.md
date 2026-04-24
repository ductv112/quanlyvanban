---
phase: 03-li-n-th-ng-tin-nh-n
plan: "03"
subsystem: backend
tags: [messages, notices, socket-io, realtime, api]
dependency_graph:
  requires: ["03-01"]
  provides: ["message-api", "notice-api", "socket-io-server"]
  affects: ["frontend-tin-nhan", "frontend-thong-bao"]
tech_stack:
  added: ["socket.io server integration"]
  patterns: ["JWT socket auth middleware", "personal user rooms", "globalThis socket stub"]
key_files:
  created:
    - e_office_app_new/backend/src/repositories/message.repository.ts
    - e_office_app_new/backend/src/repositories/notice.repository.ts
    - e_office_app_new/backend/src/routes/message.ts
    - e_office_app_new/backend/src/routes/notice.ts
    - e_office_app_new/backend/src/lib/socket.ts
  modified:
    - e_office_app_new/backend/src/server.ts
decisions:
  - "Used verifyToken (not verifyAccessToken) — jwt.ts exports verifyToken only"
  - "Socket emit in message routes via globalThis.__socketModule stub to avoid circular import at TS compile time"
  - "PATCH /mark-all-read mounted before PATCH /:id/read in notice routes to prevent route param shadowing"
  - "createServer(app) + httpServer.listen replaces app.listen so Socket.IO shares the same port"
metrics:
  duration: "~15 minutes"
  completed: "2026-04-14"
  tasks_completed: 3
  files_created: 5
  files_modified: 1
---

# Phase 03 Plan 03: Message & Notice API + Socket.IO Summary

JWT-authenticated Socket.IO server sharing Express port, with 8-endpoint message API and 5-endpoint notice API backed by stored procedures.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Message repository + routes | 67c3d71 | message.repository.ts, routes/message.ts |
| 2 | Notice repository + routes | 0dd0252 | notice.repository.ts, routes/notice.ts |
| 3 | Socket.IO server + server.ts mounts | d41fcec | lib/socket.ts, server.ts |

## What Was Built

### Message API (`/api/tin-nhan`)
- `GET /inbox` — paginated inbox with keyword filter
- `GET /sent` — paginated sent messages
- `GET /trash` — paginated soft-deleted messages
- `GET /unread-count` — badge count
- `GET /:id` — message detail (auto-marks read via SP)
- `POST /` — create message to multiple recipients; validates non-empty `to_staff_ids`, subject max 200, content required
- `POST /:id/reply` — thread reply
- `DELETE /:id` — soft delete

### Notice API (`/api/thong-bao`)
- `GET /` — paginated notices with optional `is_read` filter
- `GET /unread-count` — badge count
- `POST /` — create notice; `created_by` from JWT (T-03-11 mitigation); title max 300, content required
- `PATCH /mark-all-read` — bulk mark read (returns count)
- `PATCH /:id/read` — single mark read

### Socket.IO Server (`lib/socket.ts`)
- Attaches to same HTTP server as Express (no additional port)
- JWT auth middleware: reads token from `handshake.auth.token` or `Authorization: Bearer` header
- Rejects unauthenticated connections with `Authentication error` (T-03-08 mitigation)
- Users join room `user_${staffId}` on connect for targeted delivery
- Exports: `initSocket`, `getIO`, `emitToUser`, `emitToUsers`, `SOCKET_EVENTS`
- `SOCKET_EVENTS`: `new_document`, `new_message`, `new_notification`, `doc_status_changed`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] verifyAccessToken does not exist in jwt.ts**
- **Found during:** Task 3 — plan referenced `verifyAccessToken` but jwt.ts exports only `verifyToken`
- **Fix:** Used `verifyToken` from `./auth/jwt.js` in socket.ts middleware
- **Files modified:** e_office_app_new/backend/src/lib/socket.ts
- **Commit:** d41fcec

**2. [Rule 1 - Bug] Circular import at TS compile time for socket emit in message.ts**
- **Found during:** Task 1 — dynamic `import('../lib/socket.js')` fails TS compile before socket.ts exists
- **Fix:** Registered socket helpers on `globalThis.__socketModule` from initSocket(); message.ts reads via globalThis at runtime, no static import needed
- **Files modified:** e_office_app_new/backend/src/routes/message.ts, e_office_app_new/backend/src/lib/socket.ts
- **Commit:** 67c3d71, d41fcec

## Threat Model Coverage

| Threat ID | Mitigation Applied |
|-----------|-------------------|
| T-03-08 | JWT verification in socket middleware — unauthenticated connections rejected |
| T-03-09 | SP `edoc.fn_message_get_by_id` receives `p_staff_id` param — access control in DB layer |
| T-03-11 | `created_by` sourced from `(req as AuthRequest).user.staffId`, never from request body |

## Known Stubs

None — all endpoints delegate to stored procedures. SP implementations are assumed complete from database migrations in sprint 8.

## Self-Check: PASSED

- `e_office_app_new/backend/src/repositories/message.repository.ts` — FOUND
- `e_office_app_new/backend/src/repositories/notice.repository.ts` — FOUND
- `e_office_app_new/backend/src/routes/message.ts` — FOUND
- `e_office_app_new/backend/src/routes/notice.ts` — FOUND
- `e_office_app_new/backend/src/lib/socket.ts` — FOUND
- Commit 67c3d71 — FOUND
- Commit 0dd0252 — FOUND
- Commit d41fcec — FOUND
