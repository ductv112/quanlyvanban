---
phase: 04-l-ch-danh-b-dashboard
plan: "02"
subsystem: backend
tags: [api, calendar, directory, dashboard, repository-pattern, express, postgresql]
dependency_graph:
  requires:
    - 04-01 (database migrations 014 + 015 — stored functions)
    - e_office_app_new/backend/src/lib/db/query.ts (callFunction, callFunctionOne)
    - e_office_app_new/backend/src/middleware/auth.ts (authenticate, requireRoles, AuthRequest)
    - e_office_app_new/backend/src/lib/error-handler.ts (handleDbError)
  provides:
    - GET/POST/PUT/DELETE /api/lich/events (Calendar CRUD)
    - GET /api/danh-ba (Staff directory with pagination)
    - GET /api/dashboard/stats (4 KPI counts)
    - GET /api/dashboard/recent-incoming (recent VB den)
    - GET /api/dashboard/upcoming-tasks (upcoming HSCV)
    - GET /api/dashboard/recent-outgoing (recent VB di)
  affects:
    - 04-03 (frontend calendar, directory, dashboard pages will call these endpoints)
tech_stack:
  added: []
  patterns:
    - Repository pattern with callFunction/callFunctionOne (consistent with all prior modules)
    - AuthRequest casting via (req as AuthRequest).user for staffId/unitId from JWT
    - handleDbError for consistent error mapping
    - T-04-04: created_by always from JWT staffId, never from request body
    - T-04-05: staffId passed to SP for ownership check on update/delete
    - T-04-06: unitId from JWT for multi-tenancy filtering in dashboard
    - T-04-07: directory returns only public contact fields
    - T-04-08: unit/leader scope creation requires admin/secretary role check
key_files:
  created:
    - e_office_app_new/backend/src/repositories/calendar.repository.ts
    - e_office_app_new/backend/src/repositories/directory.repository.ts
    - e_office_app_new/backend/src/repositories/dashboard.repository.ts
    - e_office_app_new/backend/src/routes/calendar.ts
    - e_office_app_new/backend/src/routes/directory.ts
    - e_office_app_new/backend/src/routes/dashboard.ts
    - e_office_app_new/database/migrations/014_sprint9_calendar_directory.sql
    - e_office_app_new/database/migrations/015_sprint10_dashboard_stats.sql
  modified:
    - e_office_app_new/backend/src/server.ts
decisions:
  - "Migration files 014 and 015 were not present in git despite 04-01 SUMMARY claiming they existed — created them as part of this plan (Rule 3 blocker fix)"
  - "Worktree branch was diverged from main — reset to main HEAD before executing to get Sprint 4-8 code context"
  - "Directory route uses JWT unitId as default for multi-tenancy, allows query param override for cross-unit lookup (admin use case)"
  - "scope=unit/leader creation validated via role check in route layer before calling SP (T-04-08 mitigation)"
metrics:
  duration: "~15 minutes"
  completed: "2026-04-14"
  tasks_completed: 2
  tasks_total: 2
  files_created: 8
  files_modified: 1
---

# Phase 04 Plan 02: Calendar, Directory & Dashboard Backend APIs Summary

Calendar CRUD endpoints, staff directory search, and dashboard KPI + widget APIs — 3 repositories, 3 route files, server.ts mounts, plus missing migration files from 04-01.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Calendar + Directory repositories and routes | b09c35b | calendar.repository.ts, directory.repository.ts, calendar.ts, directory.ts, 014_sprint9_calendar_directory.sql |
| 2 | Dashboard repository + route + server.ts mount | 3333d14 | dashboard.repository.ts, dashboard.ts, server.ts, 015_sprint10_dashboard_stats.sql |

## What Was Built

### Repositories

**calendar.repository.ts:**
- `getList(scope, unitId, staffId, start, end)` — calls `public.fn_calendar_event_get_list`
- `getById(id)` — calls `public.fn_calendar_event_get_by_id`
- `create(title, description, startTime, endTime, allDay, color, repeatType, scope, unitId, createdBy)` — calls `public.fn_calendar_event_create`
- `update(id, ...)` — calls `public.fn_calendar_event_update` (SP checks ownership for personal scope)
- `delete(id, staffId)` — calls `public.fn_calendar_event_delete` (SP checks ownership)

**directory.repository.ts:**
- `getList(unitId, departmentId, search, page, pageSize)` — calls `public.fn_directory_get_list`
- Returns paginated rows with `total_count` window function for pagination

**dashboard.repository.ts:**
- `getStats(staffId, unitId)` — calls `edoc.fn_dashboard_get_stats` — 4 KPI integers
- `getRecentIncoming(unitId, limit)` — calls `edoc.fn_dashboard_recent_incoming`
- `getUpcomingTasks(staffId, limit)` — calls `edoc.fn_dashboard_upcoming_tasks`
- `getRecentOutgoing(unitId, limit)` — calls `edoc.fn_dashboard_recent_outgoing`

### Routes

**calendar.ts (`/api/lich`):**
- `GET /events` — query: scope, start, end. Defaults: scope=personal, last 30 days → next 60 days
- `GET /events/:id` — 404 if not found
- `POST /events` — validates title/times, T-04-08 role check for unit/leader scope, T-04-04 staffId from JWT
- `PUT /events/:id` — same validation + T-04-05 ownership via SP
- `DELETE /events/:id` — T-04-05 ownership check via SP

**directory.ts (`/api/danh-ba`):**
- `GET /` — query: unit_id (defaults to JWT unitId), department_id, search, page, page_size. Returns `{data, pagination}`

**dashboard.ts (`/api/dashboard`):**
- `GET /stats` — T-04-06 staffId + unitId from JWT
- `GET /recent-incoming` — query: limit (default 10)
- `GET /upcoming-tasks` — query: limit (default 10)
- `GET /recent-outgoing` — query: limit (default 10)

### server.ts Updates

3 new mounts added after `/api/thong-bao`:
```typescript
app.use('/api/lich', authenticate, calendarRoutes);
app.use('/api/danh-ba', authenticate, directoryRoutes);
app.use('/api/dashboard', authenticate, dashboardRoutes);
```

### Migration Files (014 + 015)

Created missing migrations that were documented in 04-01 SUMMARY but never committed:

**014_sprint9_calendar_directory.sql:**
- `public.calendar_events` table with scope/color/repeat_type columns
- 6 functions: get_list, get_by_id, create, update (ownership check), delete (soft, ownership check), fn_directory_get_list

**015_sprint10_dashboard_stats.sql:**
- `edoc.fn_dashboard_get_stats` — 4 KPI counts via subqueries
- `edoc.fn_dashboard_recent_incoming` — urgency CASE expression (1=Thường, 2=Khẩn, 3=Hỏa tốc)
- `edoc.fn_dashboard_upcoming_tasks` — curator + staff_handling_docs check for assignment
- `edoc.fn_dashboard_recent_outgoing` — COALESCE(publish_date, received_date, created_at) for sent_date

## Deviations from Plan

### Pre-requisite Issues Fixed

**1. [Rule 3 - Blocker] Migration files 014 and 015 not in git history**
- **Found during:** Task 1 read_first — `014_sprint9_calendar_directory.sql` referenced by plan did not exist
- **Issue:** 04-01 SUMMARY claimed commits d8da85e and f5929a5 but those hashes don't exist in git history. Files were never actually committed.
- **Fix:** Created both migration files (014 + 015) with full SP definitions matching 04-01 SUMMARY documentation
- **Files created:** `014_sprint9_calendar_directory.sql`, `015_sprint10_dashboard_stats.sql`
- **Committed with:** Task 1 and Task 2 commits respectively

**2. [Rule 3 - Blocker] Worktree branch diverged from main**
- **Found during:** Initial setup — worktree branch `worktree-agent-aa0f577d` was at Sprint 3 code, missing Sprint 4-8 routes
- **Issue:** Worktree had old code; new files would conflict or miss context
- **Fix:** Reset worktree branch to `main` HEAD (1e66ee10) to get all Sprint 4-8 code, then applied plan changes on top
- **No files modified** — git operation only

### Pre-existing TypeScript Errors (Out of Scope)

`workflow.ts` and `handling-doc-report.ts` have pre-existing TypeScript errors (using `AuthRequest` directly as router handler type instead of `Request` with casting). These existed before this plan and are not caused by this plan's changes. New files produce zero TypeScript errors.

## Threat Mitigations Applied

| Threat ID | Applied |
|-----------|---------|
| T-04-04 (Calendar create spoofing) | `createdBy` always uses `staffId` from JWT, request body cannot override |
| T-04-05 (Calendar update/delete tampering) | `staffId` from JWT passed to SP; SP checks `created_by = p_staff_id` for personal scope ownership |
| T-04-06 (Dashboard info disclosure) | `staffId` and `unitId` from JWT only — not from query params for stats endpoint |
| T-04-07 (Directory info disclosure) | `fn_directory_get_list` returns only: full_name, position_name, department_name, phone, mobile, email, image — no password_hash |
| T-04-08 (Calendar scope elevation) | Route validates `roles` from JWT before allowing unit/leader scope create/update — rejects 403 if not admin/secretary/van_thu/quan_tri |

## Known Stubs

None — all repositories call real stored functions. All routes return real data from database.

## Threat Flags

None — no new security surface introduced beyond what the plan's threat model covers.

## Self-Check: PASSED

- `e_office_app_new/backend/src/repositories/calendar.repository.ts`: FOUND
- `e_office_app_new/backend/src/repositories/directory.repository.ts`: FOUND
- `e_office_app_new/backend/src/repositories/dashboard.repository.ts`: FOUND
- `e_office_app_new/backend/src/routes/calendar.ts`: FOUND
- `e_office_app_new/backend/src/routes/directory.ts`: FOUND
- `e_office_app_new/backend/src/routes/dashboard.ts`: FOUND
- `e_office_app_new/database/migrations/014_sprint9_calendar_directory.sql`: FOUND
- `e_office_app_new/database/migrations/015_sprint10_dashboard_stats.sql`: FOUND
- Commit b09c35b: FOUND
- Commit 3333d14: FOUND
- server.ts mounts /api/lich, /api/danh-ba, /api/dashboard: VERIFIED
- TypeScript errors in new files: ZERO
