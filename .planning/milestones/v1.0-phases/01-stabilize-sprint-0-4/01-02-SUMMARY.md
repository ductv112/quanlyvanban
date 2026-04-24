---
phase: 01-stabilize-sprint-0-4
plan: 02
subsystem: backend/error-handling
tags: [refactor, error-handler, shared-lib, typescript, postgresql]
dependency_graph:
  requires: []
  provides: [shared-error-handler]
  affects: [routes/admin, routes/admin-catalog, routes/incoming-doc, routes/drafting-doc, routes/outgoing-doc]
tech_stack:
  added: []
  patterns: [shared-lib extraction, ESM .js imports, PostgreSQL constraint mapping]
key_files:
  created:
    - e_office_app_new/backend/src/lib/error-handler.ts
  modified:
    - e_office_app_new/backend/src/routes/admin.ts
    - e_office_app_new/backend/src/routes/admin-catalog.ts
    - e_office_app_new/backend/src/routes/incoming-doc.ts
    - e_office_app_new/backend/src/routes/drafting-doc.ts
    - e_office_app_new/backend/src/routes/outgoing-doc.ts
decisions:
  - Merged both admin.ts and admin-catalog.ts constraint maps into single shared file — no split by domain
  - Kept buildTree function in admin.ts (not extracted) — out of scope for this plan
key_decisions:
  - Merged constraint map: single messageMap covers all domains (admin + catalog + doc routes)
  - ESM .js extension on all internal imports per project convention
metrics:
  duration: ~8 minutes
  completed_date: "2026-04-14"
  tasks_completed: 2
  files_changed: 6
---

# Phase 1 Plan 02: Shared Error Handler Extraction Summary

**One-liner:** Extracted duplicated handleDbError into shared `lib/error-handler.ts` with merged PostgreSQL constraint map covering all 5 route files, upgrading VB đến/đi/dự thảo from raw error.message to Vietnamese user messages.

## What Was Built

A single shared `handleDbError` function in `backend/src/lib/error-handler.ts` that:
- Maps PostgreSQL unique violation (23505) to Vietnamese messages for 13 known constraints
- Maps FK violation (23503) to a generic Vietnamese message
- Maps not-null violation (23502) to a field-specific Vietnamese message
- Hides raw `error.message` in production (NODE_ENV guard — T-02-01 mitigation)

All 5 route files now import from the shared location. The 3 document route files (incoming-doc, drafting-doc, outgoing-doc) had a simplified bug version (`error.message` only, no constraint mapping, always 500) — these are now upgraded to full constraint handling.

## Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create shared error-handler.ts | a549cc9 | `src/lib/error-handler.ts` (created) |
| 2 | Replace inline handleDbError in 5 route files | ca3e7fb | 5 route files updated |

## Verification Results

- `npx tsc --noEmit` — exit 0 (clean build)
- `grep -rn "^function handleDbError" routes/` — 0 matches (no inline definitions remain)
- `grep -rn "error-handler" routes/` — 5 matches (one per route file)
- `grep -n "export function handleDbError" lib/error-handler.ts` — 1 match

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None — no new network endpoints, auth paths, or schema changes introduced. The `isDev` guard for T-02-01 was already in the admin.ts implementation and was preserved in the shared version.

## Self-Check: PASSED

- `e_office_app_new/backend/src/lib/error-handler.ts` — FOUND
- Commit `a549cc9` — FOUND
- Commit `ca3e7fb` — FOUND
- TypeScript build clean — VERIFIED
- 0 inline handleDbError definitions in routes — VERIFIED
- 5 route files with shared import — VERIFIED
