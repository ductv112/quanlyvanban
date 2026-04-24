---
phase: 01-stabilize-sprint-0-4
plan: 03
subsystem: frontend/golden-path
tags: [bugfix, verification, golden-path, sprint4, van-ban-den, van-ban-di, van-ban-du-thao]
requirements: [STAB-01, STAB-03]

dependency_graph:
  requires:
    - e_office_app_new/frontend/src/types/tree.ts (Plan 01)
    - e_office_app_new/frontend/src/lib/tree-utils.ts (Plan 01)
    - e_office_app_new/backend/src/lib/error-handler.ts (Plan 02)
  provides:
    - e_office_app_new/frontend/src/app/(main)/van-ban-di/page.tsx (Outgoing doc list)
    - e_office_app_new/frontend/src/app/(main)/van-ban-du-thao/page.tsx (Draft doc list)
    - e_office_app_new/backend/src/repositories/drafting-doc.repository.ts
    - e_office_app_new/backend/src/repositories/outgoing-doc.repository.ts
    - e_office_app_new/database/migrations/009_sprint4_drafting_outgoing.sql
  affects:
    - e_office_app_new/frontend/src/app/(main)/van-ban-den/page.tsx (verified clean)
    - e_office_app_new/frontend/src/components/layout/MainLayout.tsx (verified clean)

tech_stack:
  added: []
  patterns:
    - Golden path verification — TypeScript build + backslash path scan + Vietnamese text audit
    - Sprint 4 files committed — van-ban-di, van-ban-du-thao pages + backend repositories

key_files:
  created:
    - e_office_app_new/frontend/src/app/(main)/van-ban-di/page.tsx
    - e_office_app_new/frontend/src/app/(main)/van-ban-di/[id]/page.tsx
    - e_office_app_new/frontend/src/app/(main)/van-ban-du-thao/page.tsx
    - e_office_app_new/frontend/src/app/(main)/van-ban-du-thao/[id]/page.tsx
    - e_office_app_new/backend/src/repositories/drafting-doc.repository.ts
    - e_office_app_new/backend/src/repositories/outgoing-doc.repository.ts
    - e_office_app_new/database/migrations/009_sprint4_drafting_outgoing.sql
  modified:
    - e_office_app_new/frontend/src/app/(main)/van-ban-den/page.tsx (verified)
    - e_office_app_new/frontend/src/app/(main)/van-ban-den/[id]/page.tsx (verified)
    - e_office_app_new/backend/src/server.ts (verified route registrations)
    - e_office_app_new/frontend/src/components/layout/MainLayout.tsx (verified)

decisions:
  - Backslash path bug in van-ban-den was already fixed before this plan ran — no code change needed
  - MainLayout notification bell is already a safe no-op onClick — no crash risk
  - Committed Sprint 4 untracked files as part of golden path stabilization
  - Auto-approved human-verify checkpoint (auto mode active)

metrics:
  duration: ~10 minutes
  completed_date: "2026-04-14"
  tasks_completed: 2
  tasks_total: 2
  files_created: 7
  files_modified: 4
---

# Phase 1 Plan 03: Golden Path Verification Summary

**One-liner:** Verified golden path is bug-free (no backslash paths, clean TS builds, proper Vietnamese diacritics) and committed Sprint 4 document management pages — van-ban-di and van-ban-du-thao — closing the demo readiness gap.

## What Was Done

Executed golden path verification and bug-fixing for Sprint 0-4 stabilization:

**Task 1 — Bug verification and Sprint 4 file commit:**
- Scanned `van-ban-den/page.tsx`, `van-ban-di/page.tsx`, `van-ban-du-thao/page.tsx` for backslash API paths — none found. The critical bug (`\van-ban-den\danh-dau-da-doc`) mentioned in the plan was already corrected in the Sprint 4 implementation before this plan ran.
- Verified `MainLayout.tsx` notification bell: `onClick={() => {/* TODO: notification drawer */}}` — proper no-op lambda, no undefined reference, no runtime crash.
- Verified all Vietnamese user-visible text uses proper diacritics across all three document pages.
- Ran `npx tsc --noEmit` in both frontend and backend — both exit 0 (clean builds).
- Committed Sprint 4 untracked files that were part of the implementation: van-ban-di page, van-ban-du-thao page, backend repositories (drafting-doc.repository.ts, outgoing-doc.repository.ts), and database migration 009_sprint4_drafting_outgoing.sql.
- Confirmed `backend/src/server.ts` has correct route registrations for all three document modules.

**Task 2 — Checkpoint (auto-approved):**
- Golden path code verified clean — auto-approved in auto mode.

## Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Verify golden path, commit sprint 4 files | 82f4689 | 7 created, 4 verified |
| 2 | Checkpoint human-verify | n/a | Auto-approved |

## Verification Results

1. `grep -rn "\\van-ban\|\\api\|\\quan-tri" frontend/src/` — 0 matches (no backslash paths)
2. `npx tsc --noEmit` frontend — exit 0 (clean)
3. `npx tsc --noEmit` backend — exit 0 (clean)
4. MainLayout.tsx notification bell — `onClick={() => {}}` style no-op, no undefined references
5. Vietnamese text audit — all labels in van-ban-den, van-ban-di, van-ban-du-thao use proper diacritics

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Sprint 4 pages were untracked, needed to be committed**
- **Found during:** Task 1 — git status showed van-ban-di/ and van-ban-du-thao/ as untracked new directories
- **Issue:** Sprint 4 implementation files were written but never committed, blocking golden path validation
- **Fix:** Staged and committed all Sprint 4 implementation artifacts (7 new files)
- **Files modified:** van-ban-di/page.tsx, van-ban-di/[id]/page.tsx, van-ban-du-thao/page.tsx, van-ban-du-thao/[id]/page.tsx, drafting-doc.repository.ts, outgoing-doc.repository.ts, 009_sprint4_drafting_outgoing.sql
- **Commit:** 82f4689

### Pre-fixed Issues

**2. Backslash path bug (already fixed):** The plan's Fix 1 (`\van-ban-den\danh-dau-da-doc` → `/van-ban-den/danh-dau-da-doc`) was already correctly written in the Sprint 4 implementation. No code change was needed here — the current code already uses forward slashes.

## Known Stubs

None — all pages are wired to real backend API endpoints. The notification bell is intentionally a no-op placeholder (not a stub for data rendering).

## Threat Flags

None — no new network endpoints beyond what Sprint 4 planned. The van-ban-di and van-ban-du-thao routes are registered under `authenticate` middleware (same pattern as van-ban-den).

## Self-Check: PASSED

- `e_office_app_new/frontend/src/app/(main)/van-ban-di/page.tsx` — FOUND
- `e_office_app_new/frontend/src/app/(main)/van-ban-du-thao/page.tsx` — FOUND
- `e_office_app_new/backend/src/repositories/drafting-doc.repository.ts` — FOUND
- `e_office_app_new/backend/src/repositories/outgoing-doc.repository.ts` — FOUND
- `e_office_app_new/database/migrations/009_sprint4_drafting_outgoing.sql` — FOUND
- Commit 82f4689 — FOUND
- Frontend TypeScript — CLEAN (exit 0)
- Backend TypeScript — CLEAN (exit 0)
- Backslash path scan — 0 matches (clean)
