# Phase 1: Stabilize Sprint 0-4 - Context

**Gathered:** 2026-04-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix visible bugs, refactor duplicated shared patterns, and ensure the golden path (VB đến → xử lý → VB đi) works end-to-end across Sprint 0-4 features. This is a light stabilization — security audit, test coverage, and deep refactoring are deferred to next week.

</domain>

<decisions>
## Implementation Decisions

### Refactor Scope
- **D-01:** Light refactoring only — extract duplicated code into shared utilities, fix visible bugs. Do NOT refactor route file structure (admin-catalog.ts 1492 lines stays as-is for now).
- **D-02:** Do NOT add Zod validation, service layer, or architectural changes — those are Deep Stabilize scope.

### Bug Prioritization
- **D-03:** Golden path first — manually test main user flows (login → navigate → VB đến CRUD → VB đi CRUD → admin modules). Fix any blockers found.
- **D-04:** UI bugs visible to demo audience take priority over backend-only issues.

### Shared Patterns Strategy
- **D-05:** Extract tree utilities (buildTree, filterTree, flattenTreeForSelect, TreeNode type) from 6 admin pages into `e_office_app_new/frontend/src/lib/tree-utils.ts` and `e_office_app_new/frontend/src/types/tree.ts`.
- **D-06:** Extract `handleDbError()` from admin.ts and admin-catalog.ts into `e_office_app_new/backend/src/lib/error-handler.ts`. All route files import from shared.
- **D-07:** Standardize API response format across all routes if inconsistencies found.

### Testing Approach
- **D-08:** No new tests during this phase. Testing is deferred to Deep Stabilize (v2 requirement DEEP-02).
- **D-09:** Manual verification of golden path is sufficient for demo readiness.

### Claude's Discretion
- Specific bug fixes and their implementation approach
- Order of refactoring tasks (tree utils first vs error handler first)
- Whether to fix cosmetic UI issues found during golden path testing

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Codebase Analysis
- `.planning/codebase/CONCERNS.md` — Full list of tech debt, security issues, and known bugs
- `.planning/codebase/CONVENTIONS.md` — Code style, naming patterns, error handling conventions
- `.planning/codebase/ARCHITECTURE.md` — System layers, data flow, repository pattern
- `.planning/codebase/STRUCTURE.md` — Directory layout, key file locations

### Sprint Details (implementation specs)
- `e_office_app_new/ROADMAP.md` §Sprint 0-4 — Detailed SP, API, UI specs for all implemented modules

### Project Conventions
- `e_office_app_new/docs/quy_uoc_chung.md` — maxLength, validation rules, error messages, naming, security conventions

### Source Code Reference (old system)
- `docs/source_code_cu/sources/OneWin.WebApp/` — .NET MVC controllers and views for business logic reference
- `docs/source_code_cu/sources/OneWin.Data.Services/` — Service layer with business logic
- `docs/source_code_cu/sources/OneWin.Data.Repositories/` — Data access patterns

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Tree utilities (buildTree, filterTree, flattenTreeForSelect) exist in 6 pages — need extraction, not creation
- handleDbError() exists in 2 route files — need extraction, not creation
- API interceptor with auto-refresh already working in `frontend/src/lib/api.ts`
- Auth store (Zustand) working in `frontend/src/stores/auth.store.ts`

### Established Patterns
- Repository pattern: routes → repositories → PostgreSQL stored functions
- Frontend: `'use client'` pages with Ant Design components + Zustand stores
- CSS: Tailwind CSS + globals.css with custom classes (CSS-first, no inline styles per project convention)
- Drawer for add/edit (720px), Popconfirm for delete, Card tabs for detail views

### Integration Points
- All admin pages import tree utilities inline — refactored utils will be imported from shared location
- handleDbError called in route catch blocks — refactored handler imported from lib/
- MainLayout.tsx renders sidebar + header — check for any layout bugs here

</code_context>

<specifics>
## Specific Ideas

- MUST reference source code cũ (docs/source_code_cu/) to verify business logic correctness when fixing bugs
- Tiếng Việt có dấu in all UI text — verify during golden path testing
- Dashboard should show placeholder data correctly (4 KPI cards + 2 content cards)

</specifics>

<deferred>
## Deferred Ideas

### Deep Stabilize (next week)
- JWT secret fallback vulnerability fix
- requireRoles() middleware enforcement on routes
- Zod validation schemas
- Rate limiting
- Test coverage
- Route file splitting (admin-catalog.ts 1492 lines)
- Shared package consumption (frontend/backend → @shared/types)
- Redis caching for catalog data

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-stabilize-sprint-0-4*
*Context gathered: 2026-04-14*
