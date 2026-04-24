---
phase: 06-t-ch-h-p-h-th-ng-ngo-i
plan: 02
subsystem: api
tags: [lgsp, bullmq, queue, mock-service, express, workers]

requires:
  - phase: 06-01
    provides: "LGSP tables and stored functions (019_sprint14_lgsp.sql)"
provides:
  - "BullMQ shared queue client for backend job enqueuing"
  - "ILgspService interface with mock implementation"
  - "LGSP repository with 6 SP-backed methods"
  - "6 LGSP API endpoints at /api/lgsp"
  - "lgsp-send and lgsp-receive workers with mock logic"
  - "zalo-send and notification-send worker stubs"
affects: [06-03-signing, 06-04-notifications, 06-05-seed-data]

tech-stack:
  added: [bullmq-queue-client]
  patterns: [service-interface-with-mock, async-job-enqueue, worker-direct-sp-call]

key-files:
  created:
    - e_office_app_new/backend/src/lib/queue/client.ts
    - e_office_app_new/backend/src/services/lgsp.service.ts
    - e_office_app_new/backend/src/services/lgsp-mock.service.ts
    - e_office_app_new/backend/src/repositories/lgsp.repository.ts
    - e_office_app_new/backend/src/routes/lgsp.ts
  modified:
    - e_office_app_new/backend/src/server.ts
    - e_office_app_new/workers/src/index.ts

key-decisions:
  - "getLgspService() is async factory using dynamic import for ESM compatibility"
  - "Workers call SPs directly via pg pool instead of importing repository (separate process)"
  - "Mock service caches LGSP token in Redis with 29-min TTL per Sprint 14.1 spec"
  - "LGSP routes mounted at /api/lgsp with authenticate middleware"

patterns-established:
  - "Service interface pattern: ILgspService + getLgspService() factory with MOCK_EXTERNAL env flag"
  - "Shared BullMQ Queue client: backend/src/lib/queue/client.ts exports named queues"
  - "Worker SP calls: workers use direct pool.query('SELECT * FROM edoc.fn_...') not repository imports"

requirements-completed: [LGSP-01, LGSP-02, LGSP-03, LGSP-04]

duration: 4min
completed: 2026-04-14
---

# Phase 06 Plan 02: LGSP Backend Summary

**LGSP integration backend with BullMQ queue client, mock service interface, 6 API endpoints, and send/receive workers**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-14T17:48:06Z
- **Completed:** 2026-04-14T17:51:39Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Shared BullMQ Queue client with 7 named queues (lgsp-receive, lgsp-send, notification, email, sms, fcm, zalo)
- ILgspService interface with full mock implementation returning realistic Vietnamese org/doc data
- LGSP repository with 6 methods calling exact SP names from migration 019
- 6 API endpoints: send doc, tracking list, tracking by doc, org list, org sync, receive poll
- Workers: lgsp-send updates tracking via SP, lgsp-receive creates tracking records, zalo-send stub added

## Task Commits

Each task was committed atomically:

1. **Task 1: BullMQ queue client + LGSP service interface with mock + repository** - `92d453d` (feat)
2. **Task 2: LGSP routes + worker implementation + server.ts mount** - `3e3949d` (feat)

## Files Created/Modified
- `backend/src/lib/queue/client.ts` - Shared BullMQ Queue instances (7 queues)
- `backend/src/services/lgsp.service.ts` - ILgspService interface + getLgspService() async factory
- `backend/src/services/lgsp-mock.service.ts` - Mock with 8 orgs, 2 docs, Redis-cached token
- `backend/src/repositories/lgsp.repository.ts` - 6 methods matching exact SP names from migration 019
- `backend/src/routes/lgsp.ts` - 6 endpoints (POST /gui-lien-thong, GET /tracking, etc.)
- `backend/src/server.ts` - Added lgsp route import and mount at /api/lgsp
- `workers/src/index.ts` - Added lgsp-send, zalo-send, notification-send workers + pg pool

## Decisions Made
- getLgspService() uses async dynamic import (`await import()`) for ESM module compatibility instead of require()
- Workers create their own pg Pool instance (separate process from backend) and call SPs directly
- Mock LGSP token cached in Redis with 29-minute TTL matching Sprint 14.1 spec
- LGSP routes use body `outgoing_doc_id` instead of URL param for send endpoint (cleaner API design at /api/lgsp mount point)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- TypeScript compilation shows pre-existing module resolution errors (no node_modules in worktree) — all new file errors are the same pattern (missing express/bullmq/pino modules), no actual code logic issues.

## User Setup Required

None - no external service configuration required. MOCK_EXTERNAL=true is the default behavior when LGSP_ENDPOINT is not set.

## Next Phase Readiness
- BullMQ queue client ready for notification system (06-04)
- LGSP service interface ready for real implementation (swap mock by setting LGSP_ENDPOINT + removing MOCK_EXTERNAL)
- Workers infrastructure ready for additional job types

## Self-Check: PASSED

- All 5 created files verified present
- Commits 92d453d and 3e3949d verified in git log
- server.ts contains lgsp import and mount
- workers/src/index.ts contains lgsp-send, lgsp-receive, zalo-send, fn_lgsp_tracking_create, fn_lgsp_tracking_update_status

---
*Phase: 06-t-ch-h-p-h-th-ng-ngo-i*
*Completed: 2026-04-14*
