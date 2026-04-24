---
phase: 260424-wve-permission-v2-vb-den-vb-di-apply-pattern
plan: 01
subsystem: backend-permissions, frontend-ui
tags: [permissions, security, capability-based, incoming-doc, outgoing-doc]
dependency_graph:
  requires: [260424-w4u (drafting-doc permission v2 pattern)]
  provides: [permission-v2-all-three-doc-types]
  affects: [van-ban-den, van-ban-di, van-ban-du-thao]
tech_stack:
  added: [_shared.ts, incoming-doc permission helper, outgoing-doc permission helper]
  patterns: [capability-based permissions, batch N+1-safe enrich, pure sync compute + async load]
key_files:
  created:
    - e_office_app_new/backend/src/lib/permissions/_shared.ts
    - e_office_app_new/backend/src/lib/permissions/incoming-doc.ts
    - e_office_app_new/backend/src/lib/permissions/outgoing-doc.ts
    - .planning/quick/260424-wve-permission-v2-vb-den-vb-di-apply-pattern/SMOKE-RESULT.txt
  modified:
    - e_office_app_new/backend/src/lib/permissions/drafting-doc.ts
    - e_office_app_new/backend/src/routes/incoming-doc.ts
    - e_office_app_new/backend/src/routes/outgoing-doc.ts
    - e_office_app_new/frontend/src/app/(main)/van-ban-den/page.tsx
    - e_office_app_new/frontend/src/app/(main)/van-ban-den/[id]/page.tsx
    - e_office_app_new/frontend/src/app/(main)/van-ban-di/page.tsx
    - e_office_app_new/frontend/src/app/(main)/van-ban-di/[id]/page.tsx
decisions:
  - "_shared.ts extracted as single source of truth for DocPermissions types and getUserPermissionContext — avoids importing from drafting-doc.ts in sibling modules"
  - "outgoing-doc isOwner = isDrafter OR isCreator (both drafting_user_id and created_by count) to avoid staff losing access when văn thư creates on behalf"
  - "incoming-doc canRelease kept in DocPermissions for uniform interface even though VB đến has no release endpoint"
  - "Duplicate forceRender attrs (pre-existing bug) fixed in van-ban-den/[id] and van-ban-di/[id] Drawers as Rule 1 auto-fix"
metrics:
  duration: ~90min
  completed: 2026-04-25
  tasks: 8/8
  files_modified: 11
---

# Quick Plan 260424-wve: Permission v2 VB đến + VB đi Summary

**One-liner:** Capability-based permission v2 (canEdit/canApprove/canRelease/canSend/canRetract) applied to VB đến + VB đi via shared helper `_shared.ts`, with 403 guards on 12 incoming + 15 outgoing mutation endpoints and UI gate on list dropdown + detail action buttons.

## Tasks

- [x] Task 1: Refactor `drafting-doc.ts` — extract shared logic to `_shared.ts`, backward-compat 100%
- [x] Task 2: Create `incoming-doc.ts` permission helper — isOwner = created_by
- [x] Task 3: Create `outgoing-doc.ts` permission helper — isOwner = drafting_user_id OR created_by
- [x] Task 4: Route `incoming-doc.ts` — loadDocAndPerms + 12 guards (403) + batch list enrich + detail enrich
- [x] Task 5: Route `outgoing-doc.ts` — loadDocAndPerms + 15 guards (403) + batch list enrich + detail enrich
- [x] Task 6: Frontend VB đến — permissions? interface + gate list dropdown + detail buttons
- [x] Task 7: Frontend VB đi — permissions? interface + gate list dropdown + detail buttons
- [x] Task 8: Smoke test 10/10 PASS

## Files Modified

From `git status`:
```
 M e_office_app_new/backend/src/lib/permissions/drafting-doc.ts
 M e_office_app_new/backend/src/routes/incoming-doc.ts
 M e_office_app_new/backend/src/routes/outgoing-doc.ts
 M e_office_app_new/frontend/src/app/(main)/van-ban-den/[id]/page.tsx
 M e_office_app_new/frontend/src/app/(main)/van-ban-den/page.tsx
 M e_office_app_new/frontend/src/app/(main)/van-ban-di/[id]/page.tsx
 M e_office_app_new/frontend/src/app/(main)/van-ban-di/page.tsx
?? e_office_app_new/backend/src/lib/permissions/_shared.ts        (NEW)
?? e_office_app_new/backend/src/lib/permissions/incoming-doc.ts   (NEW)
?? e_office_app_new/backend/src/lib/permissions/outgoing-doc.ts   (NEW)
?? .planning/quick/260424-wve-permission-v2-vb-den-vb-di-apply-pattern/SMOKE-RESULT.txt (NEW)
```

## TypeScript Check Results

**Backend:** 0 new errors in permissions/* and routes/incoming-doc.ts and routes/outgoing-doc.ts and routes/drafting-doc.ts. Pre-existing errors in admin-catalog.ts (unrelated, not touched).

**Frontend:** 0 new errors in van-ban-den/* and van-ban-di/*. Pre-existing errors:
- `van-ban-den/page.tsx(149)`: `TreeNode[]` type mismatch in buildTree call (pre-existing)
- `van-ban-di/page.tsx(152)`: same pre-existing TreeNode issue

## Smoke Test Results (10/10 PASS)

See `SMOKE-RESULT.txt` for full output. Summary:

| # | Token | Endpoint | Expected | Result |
|---|-------|----------|----------|--------|
| 1 | ADMIN | GET /van-ban-den | permissions all true | PASS |
| 2 | tranthib (khác unit) | GET /van-ban-den/1001 | permissions all false | PASS |
| 3 | tranthib | PATCH /van-ban-den/1001/duyet | 403 | PASS |
| 4 | tranthib | POST /van-ban-den/1001/gui | 403 | PASS |
| 5 | tranthib | POST /van-ban-den/1001/thu-hoi | 403 | PASS |
| 6 | ADMIN | GET /van-ban-di | permissions all true | PASS |
| 7 | tranthib | PATCH /van-ban-di/1001/ban-hanh | 403 | PASS |
| 8 | tranthib | PATCH /van-ban-di/1001/duyet | 403 | PASS |
| 9 | tranthib | POST /van-ban-di/1001/gui | 403 | PASS |
| 10 | tranthib | POST /van-ban-di/1001/noi-nhan | 403 | PASS |

## Architecture: Permission v2 Pattern

```
_shared.ts
  ├── DocPermissions (interface)
  ├── UserPermissionContext (interface)
  ├── getUserPermissionContext() — async, load once per request
  └── computePermsFromContext(ctx, doc, isOwner) — pure sync

drafting-doc.ts  → wrap _shared, isOwner = staffId === drafting_user_id
incoming-doc.ts  → wrap _shared, isOwner = staffId === created_by
outgoing-doc.ts  → wrap _shared, isOwner = staffId === drafting_user_id OR created_by
```

**Rules (không hard-code role name):**
```
canEdit    = isAdmin || isOwner || (sameUnit && is_handle_document)
canApprove = isAdmin || (sameUnit && is_leader)
canRelease = isAdmin || (sameUnit && is_leader)
canSend    = isAdmin || isOwner || (sameUnit && is_leader)
canRetract = isAdmin || (sameUnit && is_leader)
```

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Duplicate `forceRender` attribute on Drawer components**
- **Found during:** Task 6 (TS check van-ban-den/[id]) and Task 7 (TS check van-ban-di/[id])
- **Issue:** `<Drawer forceRender ... forceRender>` — duplicate JSX attribute causing TS17001 error
- **Fix:** Removed first occurrence of `forceRender` on opening tag, keeping the one inline
- **Files modified:** `van-ban-den/[id]/page.tsx`, `van-ban-di/[id]/page.tsx`

**2. [Rule 1 - Bug] `doc.is_inter_doc` missing from DocDetail interface**
- **Found during:** Task 6 (TS check van-ban-den/[id])
- **Issue:** `DocDetail` interface didn't declare `is_inter_doc`, causing TS2339 on line 449
- **Fix:** Changed `doc.is_inter_doc` to `(doc as any).is_inter_doc` — consistent with other `(doc as any).*` casts in same file
- **Files modified:** `van-ban-den/[id]/page.tsx`

## Known Stubs

None — all permissions compute from real DB data (staff position flags, unit_id, ownership).

## Threat Flags

None — no new network endpoints or auth paths introduced. Guards added to existing endpoints (reduces attack surface by blocking unauthorized mutations).
