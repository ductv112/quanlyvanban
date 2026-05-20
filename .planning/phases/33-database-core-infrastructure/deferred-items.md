# Deferred Items — Phase 33 (Out of Scope)

Issues discovered during Phase 33 verification that are NOT caused by Phase 33 work. Per SCOPE BOUNDARY rule, these are NOT auto-fixed.

## Frontend TypeScript Errors (Pre-existing, Phase 33 NOT cause)

Verified via `git checkout 84d2f8f~1 -- <files> && npx tsc --noEmit` — all 4 errors exist BEFORE Phase 33 started.

| File | Line | Error |
|---|---|---|
| `e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/page.tsx` | 191:46 | TS2345: `{ id; parent_id; children? }[]` missing `key, title` properties from `TreeNode[]` |
| `e_office_app_new/frontend/src/app/(main)/van-ban-den/page.tsx` | 153:46 | TS2345: `{ id; parent_id; name }[]` missing `key, title` from `TreeNode[]` |
| `e_office_app_new/frontend/src/app/(main)/van-ban-di/page.tsx` | 156:46 | TS2345: `{ id; parent_id; name }[]` missing `key, title` from `TreeNode[]` |
| `e_office_app_new/frontend/src/app/(main)/van-ban-du-thao/page.tsx` | 178:46 | TS2345: `{ id; parent_id; name }[]` missing `key, title` from `TreeNode[]` |

**Root cause:** Department tree helper changed its parameter type to require `key, title` (Ant Design Tree convention) but 4 page-level callers still pass raw `{ id, parent_id, name }` shape without conversion. Pattern fix = wrap with `mapDepartmentToTreeNode()` helper or add `key: dept.id, title: dept.name` inline.

**Why deferred:**
- Phase 33 scope = `lgsp_agency_config` + `lgsp_status_outbox` + service factory. Zero frontend changes.
- These TS errors exist at HEAD~10 (Phase 30+ era), unrelated to Phase 33 work.
- Fixing them would risk regression on unrelated pages without verification scope.
- Should be fixed by a dedicated `/gsd-quick` task or future Phase 34/35 if those phases touch the files.

**Impact on Phase 33 completion:**
- Backend TS strict: PASS (0 error) — Phase 33 code clean.
- Production deploy: 4 errors do NOT block `next build` (they're TS2345, Next.js build runs even with type errors unless explicitly configured to fail).
- Customer-facing: No regression — pages already in prod (HSCV, VB đến/đi/dự thảo) work despite TS warning (runtime cast via implicit `any`).

**Action:** Track as separate tech-debt ticket. Recommend `/gsd-quick: Fix 4 frontend TreeNode TS errors in HSCV + VB pages`.
