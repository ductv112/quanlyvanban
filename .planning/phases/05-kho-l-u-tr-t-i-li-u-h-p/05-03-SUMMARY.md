---
phase: 05
plan: 03
subsystem: backend/meeting
tags: [meeting, voting, socket.io, repository, routes]
dependency_graph:
  requires: [05-01, 05-02]
  provides: [meeting-api, voting-api, phase5-server-wiring]
  affects: [server.ts, backend/routes, backend/repositories]
tech_stack:
  added: []
  patterns: [repository-pattern, socket.io-realtime, jwt-from-token, multer-upload]
key_files:
  created:
    - e_office_app_new/backend/src/repositories/meeting.repository.ts
    - e_office_app_new/backend/src/routes/meeting.ts
  modified:
    - e_office_app_new/backend/src/server.ts
decisions:
  - "uploadFile signature takes 3 args (path, buffer, contentType) not 4 — fixed to match actual client.ts"
  - "req.params.questionId cast to string to satisfy Express 5 string | string[] type"
  - "Phase 5 routes (archive/document/contract) were already created by 05-02 parallel execution"
metrics:
  duration_minutes: 20
  completed_date: "2026-04-14"
  tasks_completed: 2
  files_changed: 3
---

# Phase 5 Plan 03: Meeting Module API + Phase 5 Server Wiring Summary

**One-liner:** Meeting API with rooms/types/schedules CRUD, staff assignment, realtime voting via Socket.IO, and all Phase 5 routes mounted in server.ts.

## What Was Built

### Task 1: Meeting Repository + Routes
- `meeting.repository.ts` — 25 methods covering all meeting operations:
  - Rooms: `getRoomList`, `createRoom`, `updateRoom`, `deleteRoom`
  - Meeting Types: `getMeetingTypeList`, `createMeetingType`, `updateMeetingType`, `deleteMeetingType`
  - Room Schedules: `getRoomScheduleList`, `getRoomScheduleById`, `createRoomSchedule`, `updateRoomSchedule`, `deleteRoomSchedule`, `approveRoomSchedule`, `rejectRoomSchedule`
  - Staff: `getRoomScheduleStaff`, `assignStaff`, `removeStaff`
  - Voting: `getVoteQuestions`, `createVoteQuestion`, `createVoteAnswer`, `castVote`, `startVoteQuestion`, `stopVoteQuestion`, `getVoteResults`
  - Stats: `getMeetingStats`
- `meeting.ts` routes at `/api/cuoc-hop` — 25+ endpoints:
  - Room endpoints: GET/POST/PUT/DELETE `/phong-hop`
  - Meeting type endpoints: GET/POST/PUT/DELETE `/loai-cuoc-hop`
  - Schedule endpoints: GET list, GET by id, POST, PUT, DELETE, PATCH approve/reject
  - Staff endpoints: GET/POST/DELETE `/:id/thanh-vien`
  - Attachment endpoint: POST `/:id/tai-lieu` (multer + MinIO)
  - Voting endpoints: GET questions, POST question, POST answer, PATCH start/stop, POST vote, GET results
  - Stats: GET `/thong-ke` (mounted BEFORE `/:id` to prevent param shadowing)

### Task 2: Server.ts Phase 5 Wiring
- Added 4 imports: archiveRoutes, documentRoutes, contractRoutes, meetingRoutes
- Mounted 4 routes with authenticate middleware:
  - `/api/kho-luu-tru` → archiveRoutes
  - `/api/tai-lieu` → documentRoutes
  - `/api/hop-dong` → contractRoutes
  - `/api/cuoc-hop` → meetingRoutes

## Security Mitigations Applied

| Threat ID | Mitigation |
|-----------|------------|
| T-05-10 | `staff_id` sourced from JWT `staffId`, never from request body in vote cast endpoint |
| T-05-11 | Vote results filtered via `room_schedule_id` — only emitted to meeting participants |
| T-05-12 | `approved_staff_id` sourced from JWT in approve/reject endpoints |
| T-05-13 | Votes stored with staff_id + timestamp via DB unique constraint |

## Commits

| Task | Commit | Files |
|------|--------|-------|
| Task 1 | aeecd37 | meeting.repository.ts, meeting.ts |
| Task 2 | e123657 | server.ts |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed uploadFile call signature**
- **Found during:** Task 1 (TypeScript compile check)
- **Issue:** Plan's interface comment showed `uploadFile(bucketName, objectName, buffer, contentType)` with 4 args, but actual `client.ts` implements `uploadFile(path, buffer, contentType)` with 3 args (bucket is internal constant)
- **Fix:** Changed call to `uploadFile(objectName, req.file.buffer, req.file.mimetype)`
- **Files modified:** meeting.ts
- **Commit:** aeecd37

**2. [Rule 1 - Bug] Fixed Express 5 req.params type casting**
- **Found during:** Task 1 (TypeScript compile check)
- **Issue:** Express 5 types `req.params[key]` as `string | string[]` — repository methods expect `string` for UUID questionId
- **Fix:** Cast all `req.params.questionId` to `string` with `as string`
- **Files modified:** meeting.ts
- **Commit:** aeecd37

## Known Stubs

None — all repository methods call real stored procedures. Attachment upload uses direct `rawQuery` INSERT since no SP exists for `room_schedule_attachments` inserts (SP not defined in migration 018).

## Threat Flags

None — no new security surface beyond what was planned in the threat model.

## Self-Check: PASSED

- meeting.repository.ts: FOUND
- meeting.ts: FOUND
- server.ts: FOUND
- commit aeecd37 (Task 1): FOUND
- commit e123657 (Task 2): FOUND
