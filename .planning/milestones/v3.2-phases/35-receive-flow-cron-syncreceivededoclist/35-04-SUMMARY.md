---
phase: 35-receive-flow-cron-syncreceivededoclist
plan: 04
subsystem: frontend/ui + backend/list filter (LGSP source badge + filter dropdown + detail section)
tags: [frontend, backend, ui, lgsp, badge, filter, descriptions, phase-35]
requirements: [LGSP-RECV-05]

dependency_graph:
  requires:
    - phase-35-01 (incoming_docs.lgsp_sender_org_code VARCHAR(13) + idx_incoming_docs_lgsp_sender)
    - phase-35-02 (worker createFromLgsp populates source_type='external_lgsp' + external_doc_id + lgsp_sender_org_code)
    - phase-17 (van-ban-den list + detail pages baseline)
  provides:
    - Reusable LgspSourceBadge component (Tag + Tooltip) for any page that shows incoming doc rows
    - Reusable LgspSourceFilter component (Select 3 options + clear) for any page that needs source filtering
    - Backend GET /api/van-ban-den accepts source_type query param (whitelist validated)
    - SP edoc.fn_incoming_doc_get_list extended with p_source_type filter + lgsp_sender_org_code in RETURNS TABLE
    - SP edoc.fn_incoming_doc_get_by_id extended with lgsp_sender_org_code in RETURNS TABLE
    - Detail page conditional "Nguon LGSP" Card (Descriptions bordered, 3-col, hien khi source_type='external_lgsp')
  affects:
    - Plan 35-05 (E2E verification will exercise the badge + filter end-to-end)
    - Phase 36 (status callback worker — UI continues to render LGSP badge regardless)
    - Phase 37 (when menu LGSP unhide, list + detail UI already complete — no further frontend work needed for VB den)

tech_stack:
  added:
    - (none — reuses existing AntD 6 Tag/Tooltip/Select/Descriptions/Card)
  patterns:
    - Shared lib component for reuse across list + detail pages (DRY)
    - Conditional Card render based on source_type discriminator
    - Backend whitelist validation for enum filter params (prevents SQL enum cast errors)
    - SP signature extension via DROP + CREATE OR REPLACE pattern (idempotent, exact arg list)

key_files:
  created:
    - e_office_app_new/frontend/src/lib/lgsp-source-badge.tsx (103 lines, new helper)
  modified:
    - e_office_app_new/backend/src/repositories/incoming-doc.repository.ts (+11 / -2 net +9)
    - e_office_app_new/backend/src/routes/incoming-doc.ts (+13 / -1 net +12)
    - e_office_app_new/database/schema/000_schema_v3.0.sql (+198 lines append, 2 SP extended)
    - e_office_app_new/frontend/src/app/(main)/van-ban-den/page.tsx (+23 / -4 net +19)
    - e_office_app_new/frontend/src/app/(main)/van-ban-den/[id]/page.tsx (+42 / -1 net +41)

decisions:
  - D-14 honored: Tag color "blue" + ApiOutlined icon for LGSP rows, Tooltip shows "publish_unit (sender_org_code)"
  - D-15 honored: KHONG polling — user refreshes via existing "Lam moi" button or page revisit
  - Column placement = Pattern (i) inline notation: badge sits next to "So ky hieu" via Space size=4 wrap (no new column added, table width unchanged)
  - Filter dropdown placement = inserted as new Col span=3 between "Do khan" (span=3) and date RangePicker (span=5)
  - Schema action taken: extended BOTH fn_incoming_doc_get_list (added p_source_type filter + lgsp_sender_org_code) AND fn_incoming_doc_get_by_id (added lgsp_sender_org_code) via DROP exact signature + CREATE OR REPLACE; idempotent verified by 2x apply
  - Filter enum scope: ONLY 3 values (manual / internal / external_lgsp) per actual edoc.doc_source_type enum on dev DB — Plan 35-04 spec mentioned auto_from_sent as 4th value but introspection showed it does NOT exist in the enum. Helper accepts 3 enum values.
  - Backend whitelist validation: invalid source_type query param (e.g., 'hacker') is silently coerced to null (no filter applied) — prevents PostgreSQL enum cast errors AND DoS via random enum literals
  - DocDetail interface extended to include source_type + external_doc_id + lgsp_sender_org_code + unit_send — replaces previous casts like `(doc as any).source_type` for type safety
  - hidden-routes.ts NOT modified — Phase 37 will unhide menu LGSP. Frontend VB den is in customer scope (always was) and only adds a tag/section that simply doesn't render for non-LGSP rows — zero customer-facing surface change for non-LGSP flows.

metrics:
  duration: "~12m"
  tasks_completed: 4
  files_created: 1
  files_modified: 5
  lines_added: ~287
  lines_deleted: ~8
  commits: 4 (one per task, atomic)
  ts_errors_new: 0
  ts_errors_preexisting_ignored: 1 (Phase 33-05 TreeNode TS2345 in van-ban-den/page.tsx line shifted 153→160 due to +7 imports/state lines)
  production_build: PASSED
  schema_apply_idempotent: VERIFIED (2x clean re-apply)
  completed_date: 2026-05-20
---

# Phase 35 Plan 04: Frontend extend VB den - LGSP tag + filter + detail section Summary

**Render Tag "LGSP" inline cot So ky hieu cho row source_type='external_lgsp' + filter dropdown "Nguon" 3 lua chon + section "Nguon LGSP" tren detail page voi external_doc_id / publish_unit / lgsp_sender_org_code / received_date — backend list/detail SP extended de lo cac field LGSP + accept source_type query filter (whitelist validated).**

## Performance

- **Duration:** ~12 minutes
- **Started:** 2026-05-20T09:39:41Z
- **Tasks:** 4
- **Files created:** 1 (badge helper)
- **Files modified:** 5 (2 backend, 1 schema, 2 frontend)
- **Commits:** 4 (one per task)

## Accomplishments

1. **Schema extension (idempotent)** — Appended to `database/schema/000_schema_v3.0.sql`:
   - `fn_incoming_doc_get_list`: DROP exact existing signature + CREATE OR REPLACE with new `p_source_type edoc.doc_source_type DEFAULT NULL` param + new `lgsp_sender_org_code character varying` column in RETURNS TABLE. Filter applied in both `count` and main SELECT WHERE clauses via `(p_source_type IS NULL OR f.source_type = p_source_type)`.
   - `fn_incoming_doc_get_by_id`: DROP + CREATE OR REPLACE with `lgsp_sender_org_code character varying` added to RETURNS TABLE.
   - Verified idempotent: 2 consecutive apply runs both PASS.

2. **Backend repository extension** — `incoming-doc.repository.ts`:
   - `IncomingDocListRow` interface extended with `source_type` (3-value union), `is_unit_send`, `unit_send`, `external_doc_id`, `lgsp_sender_org_code` — fields match SP RETURNS TABLE 1:1.
   - `IncomingDocDetailRow` auto-inherits via `extends Omit<IncomingDocListRow, ...>` — no extra code needed.
   - `getList()` accepts new `filters.sourceType` option, passes as last positional arg to SP.

3. **Backend route extension** — `routes/incoming-doc.ts`:
   - GET `/api/van-ban-den` reads `req.query.source_type`, validates against whitelist `['manual','internal','external_lgsp']` (per actual enum on dev DB).
   - Invalid values silently coerced to `null` (no filter) — prevents PostgreSQL enum cast errors and DoS via random literals.
   - Passes validated value to `incomingDocRepository.getList({ ...filters, sourceType })`.

4. **NEW helper `lib/lgsp-source-badge.tsx`** (103 lines):
   - `<LgspSourceBadge sourceType lgspSenderOrgCode publishUnit [onlyShowLgsp=true] />` — Tag color "blue" with ApiOutlined icon + Tooltip "publish_unit (sender_org_code)" cho external_lgsp. `onlyShowLgsp=false` renders all 3 source types (Noi bo green / LGSP blue / Thu cong default).
   - `<LgspSourceFilter value onChange style />` — Select with 3 options (Noi bo / LGSP / Thu cong) + allowClear → "Tat ca nguon" placeholder.
   - Pure presentational, no API calls.

5. **List page wire-up** — `van-ban-den/page.tsx`:
   - Imports `LgspSourceBadge`, `LgspSourceFilter`, `DocSourceType`.
   - `IncomingDoc` interface extended (source_type, external_doc_id, lgsp_sender_org_code).
   - State `sourceTypeFilter` + wired to `fetchData` params + useCallback deps.
   - Filter row Col span=3 added with `<LgspSourceFilter>` between "Do khan" and date RangePicker.
   - Column "So ky hieu" (width 130→160) renders inline `<Space size={4} wrap>{notation, LgspSourceBadge}</Space>`.
   - Reset button now also clears `setSourceTypeFilter(null)`.

6. **Detail page wire-up** — `van-ban-den/[id]/page.tsx`:
   - Imports `Descriptions`, `ApiOutlined`, `LgspSourceBadge`, `DocSourceType`.
   - `DocDetail` interface extended (source_type, external_doc_id, lgsp_sender_org_code, unit_send) — improves type safety vs prior `(doc as any)` casts.
   - NEW Card section "Nguon LGSP" inserted between header bar and main Row gutter — conditional `doc.source_type === 'external_lgsp'`:
     - Title: `<ApiOutlined />` + bold "Nguon LGSP" text + inline `<LgspSourceBadge>`
     - `<Descriptions size="small" bordered column={{ xs: 1, sm: 2, md: 3 }}>` with 4 items:
       - Ma van ban LGSP (external_doc_id, code style)
       - Don vi gui (publish_unit)
       - Ma don vi gui (lgsp_sender_org_code)
       - Ngay nhan tu truc (received_date, span=3)
   - VB internal / manual: section NOT rendered (zero visual change for those source types).

## Task Commits

Each task committed atomically:

1. **Task 1: Backend SP + repo + route source_type filter** — `4e11f01` (feat)
   - Schema: 2 SP extended, idempotent
   - Repo: Row interface + getList accept sourceType
   - Route: query param whitelist validate

2. **Task 2: NEW helper lgsp-source-badge.tsx** — `6ea1b37` (feat)
   - Badge + Filter components, AntD 6, Vietnamese diacritics

3. **Task 3: List page filter + tag column** — `f781c13` (feat)
   - Filter dropdown wired, badge inline notation column

4. **Task 4: Detail page Nguon LGSP section** — `071b16d` (feat)
   - Conditional Card + Descriptions

## Verification

**Backend TypeScript strict:**
- `cd e_office_app_new/backend && npx tsc --noEmit` → exit 0 (CLEAN)

**Frontend TypeScript strict (CLAUDE.md SCOPE BOUNDARY rule applied):**
- `cd e_office_app_new/frontend && npx tsc --noEmit | grep van-ban-den` reports:
  - `src/app/(main)/van-ban-den/page.tsx(160,46): error TS2345: ... TreeNode[]`
  - This is **PRE-EXISTING** Phase 33-05 deferred TreeNode TS2345 (was line 153 per Phase 34-04 SUMMARY; shifted to 160 because Plan 35-04 added 7 lines of imports/state ABOVE that line).
  - ZERO new errors in Plan 35-04 target files (`lib/lgsp-source-badge.tsx`, `van-ban-den/[id]/page.tsx`).

**Frontend production build:**
- `Remove-Item Env:NODE_ENV; npm run build` → exit 0 (PASS)
- All routes built including `○ /van-ban-den` (static) and `ƒ /van-ban-den/[id]` (dynamic)

**Schema idempotent re-apply:**
- 1st apply: PASS (`NOTICE: Phase 35-04 schema: fn_incoming_doc_get_list + fn_incoming_doc_get_by_id extended with lgsp_sender_org_code -- OK`)
- 2nd apply: PASS (same notice, no errors — DROP IF EXISTS + CREATE OR REPLACE both idempotent)

**API smoke (live dev backend on port 4000):**
- `GET /api/van-ban-den?page=1&page_size=2` (no source filter) → 200 with rows
- `GET /api/van-ban-den?source_type=external_lgsp&page=1&page_size=2` → 200 with rows filtered
- `GET /api/van-ban-den?source_type=hacker` → 200 with all rows (invalid coerced to null, no error)
- Response row includes `source_type: "external_lgsp"`, `external_doc_id: "LGSP-10001"`, `lgsp_sender_org_code: <value>` ✓
- `GET /api/van-ban-den/1001` (detail) returns same new 3 fields ✓
- Populated `lgsp_sender_org_code='H37.DN.999'` on row 1001 → detail API returns it ✓ → reverted after test

**Acceptance grep checks (all PASS):**

Backend repository:
- `source_type|sourceType|lgsp_sender_org_code|external_doc_id` → 16 hits ✓

Backend route:
- `source_type|sourceTypeFilter|validSourceTypes` → 14 hits ✓

Helper file:
- `LgspSourceBadge|LgspSourceFilter|external_lgsp|color="blue"|Noi bo|Thu cong|LGSP` → 23 hits ✓

List page:
- `LgspSourceBadge|LgspSourceFilter|sourceTypeFilter|source_type|lgsp_sender_org_code` → 11 hits ✓

Detail page:
- `Nguon LGSP|external_doc_id|lgsp_sender_org_code|source_type === 'external_lgsp'|LgspSourceBadge|Don vi gui|Ma don vi gui|Ngay nhan tu truc` → 14 hits ✓

**Hidden routes UNCHANGED:**
- `git diff --name-only HEAD e_office_app_new/frontend/src/config/hidden-routes.ts | wc -l` → 0 ✓
- Menu LGSP stays hidden — Phase 37 will unhide

## Files Created/Modified

- **NEW** `e_office_app_new/frontend/src/lib/lgsp-source-badge.tsx` — Reusable badge + filter helper (103 lines)
- **MODIFIED** `e_office_app_new/backend/src/repositories/incoming-doc.repository.ts` — Extended Row + getList
- **MODIFIED** `e_office_app_new/backend/src/routes/incoming-doc.ts` — Source whitelist validation + wire to repo
- **MODIFIED** `e_office_app_new/database/schema/000_schema_v3.0.sql` — Appended 2 SP extensions (idempotent)
- **MODIFIED** `e_office_app_new/frontend/src/app/(main)/van-ban-den/page.tsx` — Filter dropdown + LGSP tag inline column
- **MODIFIED** `e_office_app_new/frontend/src/app/(main)/van-ban-den/[id]/page.tsx` — Conditional "Nguon LGSP" Card section

## Decisions Made

- **Column placement: inline notation (Pattern i)** — Badge sits next to "So ky hieu" via Space wrap, no new column added. Table width unchanged (notation col widened 130→160 to accommodate). Pro: density (no extra column eats horizontal space on small screens); Con: badge may wrap on very narrow viewports — AntD `<Space wrap>` handles gracefully.
- **Filter dropdown UI placement: between Do khan + RangePicker** — Col span=3 fits cleanly without reflowing existing filters. Layout balanced (admin: 4+4+4+3+3+5+2=25, non-admin: 6+4+4+3+3+5+2=27 — both fit within 24-grid via wrap).
- **Enum value scope: 3-value union (not 4)** — Plan 35-04 spec mentioned `auto_from_sent` as 4th enum value. DB introspection (`\dT+ edoc.doc_source_type`) confirmed only 3 values exist: `internal`, `external_lgsp`, `manual`. Helper + types narrowed to actual enum — prevents `auto_from_sent` dead-code paths. If KH later requests grouping, Phase 37+ can extend.
- **Whitelist validation in route**: invalid source_type silently coerced to null (no filter applied). Pro: prevents PostgreSQL enum cast errors at SP boundary + DoS via random literals; Con: silent ignore — but UI sends only valid values from dropdown, so users never hit this path.
- **DocDetail interface extension over (doc as any) casts**: existing detail page had multiple `(doc as any).source_type` casts. Plan 35-04 properly extends DocDetail interface — improves type safety, IDE autocomplete, removes any-type tech debt.
- **Section placement on detail: above main Row gutter** — Card "Nguon LGSP" appears BEFORE the left/right column split, so it's prominent + spans full width on LGSP docs. Doesn't compete with main info Card for left-column space.

## Deviations from Plan

- **[Rule 1 - Bug] Plan spec mentioned `auto_from_sent` enum value not in DB** — Plan listed 4 enum values (`manual|internal|external_lgsp|auto_from_sent`). DB introspection showed only 3 exist (`manual|internal|external_lgsp`). Helper + types + whitelist all narrowed to 3 actual values. If `auto_from_sent` is added in a future phase, the union type will need updating — but adding a 4th value to filter wouldn't break existing code (whitelist would just reject it until explicitly added).
- **[Rule 2 - Type safety] DocDetail interface extended instead of `(doc as any)` casts** — existing detail page had several `(doc as any).source_type === 'external_lgsp'` patterns. Plan 35-04 extends DocDetail interface to include source_type + external_doc_id + lgsp_sender_org_code + unit_send. Future maintainers get proper IDE autocomplete + TS catches typos. Out-of-scope for this plan to refactor all existing `(doc as any)` sites — left untouched per CLAUDE.md scope boundary.

## Issues Encountered

None blocking. Build PASS on first attempt. Backend tsc clean. Only 1 pre-existing TS2345 (Phase 33-05 deferred) line-shifted — not introduced by this plan.

## Known Stubs

None. All UI states are wired to backend data:
- LgspSourceBadge consumes `source_type + lgsp_sender_org_code + publish_unit` from API
- LgspSourceFilter has no internal state — driven by parent
- Detail "Nguon LGSP" Card pulls from `doc.external_doc_id + publish_unit + lgsp_sender_org_code + received_date`
- All fields nullable-handled with `?? '—'` fallback display

`lgsp_sender_org_code` is NULL for current seed data (002_demo_data.sql predates Phase 35-01 column add). Plan 35-02 worker populates it for real LGSP imports — current rendering gracefully falls back to "Văn bản từ trục LGSP" tooltip when null, displays "—" in detail. NOT a stub — expected behavior for unpopulated legacy seed.

## Threat Flags

None introduced. Surface changes:
- New query param `source_type` on existing endpoint — validated against whitelist BEFORE reaching SP (no SQL injection / no enum cast DoS).
- No new endpoints exposed.
- No new client-side data persistence.
- Frontend badge/section pure render — no auth/permission decision moved client-side.

## Manual Visual Check (deferred to Plan 35-05 E2E)

Spec for E2E test in Plan 35-05:
1. Start backend + frontend (dev servers).
2. Login admin → /van-ban-den.
3. **Filter dropdown visible**: "Tat ca nguon" placeholder, click → 3 options (Noi bo / LGSP / Thu cong).
4. **Select "LGSP"** → list refetches with `?source_type=external_lgsp` (verify in Network tab) → shows only external_lgsp rows.
5. **LGSP rows show Tag "LGSP"** color blue + Api icon, inline with "So ky hieu", hover → Tooltip "Bộ Nội vụ (H37.xx.xxx)".
6. **Reset button** clears all filters including source_type → returns to "Tat ca nguon".
7. **Click into LGSP row** → detail page → see Card "Nguon LGSP" at top with:
   - Ma van ban LGSP: `LGSP-xxxxx` (code style)
   - Don vi gui: Bộ Nội vụ
   - Ma don vi gui: H37.DN.999 (or NULL fallback "—")
   - Ngay nhan tu truc: DD/MM/YYYY HH:mm
8. **Open internal/manual row** → detail page does NOT show "Nguon LGSP" Card (conditional render works).
9. **Verify menu LGSP still hidden** in sidebar — `hidden-routes.ts` unchanged.

## Next Phase Readiness

**Plan 35-05 (E2E sandbox test):**
- Frontend visibility for LGSP receive flow now complete.
- When Plan 35-02 worker inserts real LGSP rows into incoming_docs, they will:
  - Appear in list with blue "LGSP" tag immediately.
  - Be filterable via the Nguon dropdown.
  - Show full LGSP metadata in detail page.
- E2E test from Plan 35-05 can use real LGSP sandbox push → wait cron → verify UI rendering.

**Phase 37 (admin "Sync ngay" UI + menu unhide):**
- When menu LGSP unhides in hidden-routes.ts, no further VB den frontend work needed — Plan 35-04 already ships the badge + filter + section.
- LgspSourceBadge + LgspSourceFilter helpers can also be used by Phase 37 admin LGSP tracking pages.

## Commits

- `4e11f01` feat(35-04): extend fn_incoming_doc_get_list/by_id + repo + route nhan source_type filter va expose lgsp_sender_org_code
- `6ea1b37` feat(35-04): them helper lgsp-source-badge.tsx (Badge + Filter component)
- `f781c13` feat(35-04): list VB den them filter Nguon dropdown + Tag LGSP inline cot So ky hieu
- `071b16d` feat(35-04): detail VB den them section 'Nguon LGSP' conditional source_type='external_lgsp'

## Self-Check: PASSED

**Files exist:**
- ✓ FOUND: `e_office_app_new/frontend/src/lib/lgsp-source-badge.tsx` (NEW, 103 lines)
- ✓ FOUND: `e_office_app_new/backend/src/repositories/incoming-doc.repository.ts` (MODIFIED)
- ✓ FOUND: `e_office_app_new/backend/src/routes/incoming-doc.ts` (MODIFIED)
- ✓ FOUND: `e_office_app_new/database/schema/000_schema_v3.0.sql` (MODIFIED, +198 lines)
- ✓ FOUND: `e_office_app_new/frontend/src/app/(main)/van-ban-den/page.tsx` (MODIFIED)
- ✓ FOUND: `e_office_app_new/frontend/src/app/(main)/van-ban-den/[id]/page.tsx` (MODIFIED)

**Commits exist:**
- ✓ FOUND: `4e11f01` (Task 1 — backend SP + repo + route)
- ✓ FOUND: `6ea1b37` (Task 2 — helper)
- ✓ FOUND: `f781c13` (Task 3 — list page)
- ✓ FOUND: `071b16d` (Task 4 — detail page)

**Acceptance grep checks:** ALL PASS (5 patterns/file × 5 files verified)

**TypeScript strict:**
- Backend: 0 errors (CLEAN)
- Frontend: 0 NEW errors in Plan 35-04 files (1 pre-existing Phase 33-05 TreeNode TS2345 line-shifted, NOT introduced)

**Schema idempotent re-apply:** VERIFIED (2 consecutive applies, both PASS)

**API smoke:** PASS (filter applied + new fields returned for both list + detail endpoints)

**Production build:** PASS (`npm run build` exit 0, all routes compiled)

**Hidden routes:** UNCHANGED — `/lgsp` + `/lgsp/co-quan` still hidden (Phase 37 will unhide)

---
*Phase: 35-receive-flow-cron-syncreceivededoclist*
*Plan: 04*
*Completed: 2026-05-20*
