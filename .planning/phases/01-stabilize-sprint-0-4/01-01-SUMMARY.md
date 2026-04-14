---
phase: 01-stabilize-sprint-0-4
plan: 01
subsystem: frontend/admin
tags: [refactor, tree-utils, shared-types, deduplication]
requirements: [STAB-02]

dependency_graph:
  requires: []
  provides:
    - e_office_app_new/frontend/src/types/tree.ts (TreeNode type)
    - e_office_app_new/frontend/src/lib/tree-utils.ts (filterTree, flattenTreeForSelect)
  affects:
    - e_office_app_new/frontend/src/app/(main)/quan-tri/don-vi/page.tsx
    - e_office_app_new/frontend/src/app/(main)/quan-tri/nguoi-dung/page.tsx
    - e_office_app_new/frontend/src/app/(main)/quan-tri/nguoi-ky/page.tsx
    - e_office_app_new/frontend/src/app/(main)/quan-tri/chuc-nang/page.tsx

tech_stack:
  added: []
  patterns:
    - Pure function extraction from React hooks (useCallback → module-level function)
    - Shared TypeScript types in /src/types/
    - Shared utility functions in /src/lib/

key_files:
  created:
    - e_office_app_new/frontend/src/types/tree.ts
    - e_office_app_new/frontend/src/lib/tree-utils.ts
  modified:
    - e_office_app_new/frontend/src/app/(main)/quan-tri/don-vi/page.tsx
    - e_office_app_new/frontend/src/app/(main)/quan-tri/nguoi-dung/page.tsx
    - e_office_app_new/frontend/src/app/(main)/quan-tri/nguoi-ky/page.tsx
    - e_office_app_new/frontend/src/app/(main)/quan-tri/chuc-nang/page.tsx

decisions:
  - Extracted filterTree and flattenTreeForSelect as pure module-level functions (not hooks) so callers use useMemo at call site
  - filterTree handles empty keyword with early return (returns nodes unchanged when keyword is blank/whitespace)
  - TreeNode uses index signature [key: string]: any to allow page-specific fields (is_unit, data, etc.)

metrics:
  duration: ~5 minutes
  completed: 2026-04-14T05:02:00Z
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 4
---

# Phase 1 Plan 01: Extract Shared Tree Utilities Summary

**One-liner:** Extracted filterTree + flattenTreeForSelect + TreeNode into shared files, eliminating 4 duplicate inline copies across admin pages.

## What Was Done

Refactored duplicated tree utility code from 4 admin pages into shared modules:

- **`src/types/tree.ts`** — Single `TreeNode` interface with index signature for page-specific fields
- **`src/lib/tree-utils.ts`** — `filterTree` and `flattenTreeForSelect` as pure functions with Vietnamese JSDoc

Then updated all 4 pages to import from the shared location, removing the inline definitions.

## Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create shared TreeNode type and tree utility functions | f4fee0b | src/types/tree.ts, src/lib/tree-utils.ts |
| 2 | Update 4 admin pages to import from shared tree utils | b670897 | don-vi, nguoi-dung, nguoi-ky, chuc-nang pages |

## Verification Results

1. `npx tsc --noEmit` — exit code 0 (no TypeScript errors)
2. `grep -rn "interface TreeNode|const filterTree = useCallback|const flattenTreeForSelect = useCallback" src/app/` — 0 matches
3. `grep -rn "from '@/lib/tree-utils'" src/app/` — exactly 4 matches (one per page)

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — no placeholder or stub values introduced.

## Threat Flags

None — this is a pure internal refactor. No new network endpoints, auth paths, file access patterns, or schema changes introduced.

## Self-Check: PASSED

- `e_office_app_new/frontend/src/types/tree.ts` — FOUND
- `e_office_app_new/frontend/src/lib/tree-utils.ts` — FOUND
- Commit f4fee0b — FOUND
- Commit b670897 — FOUND
