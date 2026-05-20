---
phase: 34-send-flow-sendedoc
plan: 04
subsystem: frontend/ui (polling badge + state machine for LGSP send tracking)
tags: [frontend, ui, react-hook, polling, badge, lgsp, antd, phase-34]
requirements: [LGSP-SEND-06]

dependency_graph:
  requires:
    - phase-34-01 (services/lgsp/error-codes.ts + sendDocument fix — error messages from backend)
    - phase-34-02 (workers/lgsp-send-worker.ts — updates lgsp_tracking.status to success/error)
    - phase-34-03 (route POST /:id/gui-noi-bo enqueue + response shape {internal_count, external_count, enqueued_count})
    - phase-19 (endpoint GET /api/van-ban-di/:id/noi-nhan + outgoing_doc_recipients schema with lgsp_status fields)
    - phase-17 (page van-ban-di/[id]/page.tsx detail panel structure)
  provides:
    - Reusable hook useRecipientsPolling(outgoingDocId, enabled, intervalMs) → { data, loading, hasPending, refetch }
    - Pure helper computeHasPending(rows) — testable badge state predicate
    - getBadgeForRecipient(r) → BadgeInfo — pure function, 7-case state machine (Phase 34 D-17 + extras)
    - "Đang theo dõi" subtle UX indicator at panel header when polling active
    - Real-time badge transition pending → success/error without page refresh
  affects:
    - Plan 34-05 (E2E sandbox test will exercise polling + badge transitions)
    - Phase 37 (admin "Gửi lại" UI — will reuse same badge helper + RecipientStatus type)
    - Future pages that need recipient status (hook is reusable)

tech_stack:
  added:
    - (none — pure React hook + antd composition)
  patterns:
    - React hook with conditional polling (setInterval guarded by hasPending state)
    - Pure helper functions for state-machine UI logic (getBadgeForRecipient, computeHasPending) — testable in isolation
    - useRef for interval handle + cleanup in useEffect return
    - Silent error catch in polling fetch (keep previous data, no reset)
    - Tooltip wrapper for badge — multiline pre-wrap whitespace
    - AntD Tag color prop: success/warning/error/processing/default/blue

key_files:
  created:
    - e_office_app_new/frontend/src/hooks/use-recipients-polling.ts (116 lines, new hook)
  modified:
    - e_office_app_new/frontend/src/app/(main)/van-ban-di/[id]/page.tsx (+122 / -58 lines net +64)

decisions:
  - D-16 honored: setInterval 10s default, stop on hasPending=false / disabled / unmount
  - D-17 honored: badge state machine with 4 core states (internal sent, external pending/success/error) + 3 extras (internal pending, external processing, external null)
  - Hook returns hasPending boolean so component can render "Đang theo dõi" UX indicator
  - Polling enabled flag set to `docId > 0` (always-on while page mounted) — hook self-stops via hasPending=false anyway
  - Initial fetch fires in separate useEffect from polling loop — clean separation of concerns
  - Error message truncated to 40 chars in badge label (full message preserved in tooltip)
  - Success message after Gửi extended to show enqueued_count when external_count > 0 — UX hint that background work is in flight
  - Old static noiNhan state + fetchNoiNhan callback fully removed (refactored, not duplicated)
  - Hidden routes NOT modified — menu LGSP stays hidden per CLAUDE.md customer-facing scope; Phase 37 will unhide when admin "Gửi lại" + monitoring UI ready
  - Pre-existing TS2345 errors in 4 other pages (ho-so-cong-viec, van-ban-den, van-ban-di list, van-ban-du-thao) ignored per CLAUDE.md scope boundary — they are Phase 33-05 deferred items, not introduced by this plan

metrics:
  duration: "~6m"
  tasks_completed: 3
  files_modified: 1
  files_created: 1
  lines_added: 238
  lines_deleted: 58
  commits: 2 (Task 3 = build verify only, no source change)
  ts_errors_new: 0
  ts_errors_preexisting_ignored: 4 (Phase 33-05 deferred TreeNode TS2345)
  production_build: PASSED
  completed_date: 2026-05-20
---

# Phase 34 Plan 04: Frontend Polling Hook + Badge State Machine Summary

**Real-time recipient tracking on VB đi detail page: 10s polling hook + 7-case badge state machine (Đã gửi nội bộ / Đang chờ LGSP / Đã gửi LGSP / Lỗi LGSP / Đang xử lý LGSP / Chờ gửi nội bộ / Chờ enqueue) with hover tooltips for timestamp + LGSP docId + full error message.**

## Performance

- **Duration:** ~6 minutes
- **Started:** 2026-05-20T06:46:58Z
- **Completed:** 2026-05-20T06:53:24Z
- **Tasks:** 3
- **Files created:** 1 (hook)
- **Files modified:** 1 (page)

## Accomplishments

1. **New reusable hook `useRecipientsPolling`** — 116 lines, exports `RecipientStatus` interface + hook signature. Polling auto-starts when `enabled && hasPending && docId > 0`, auto-stops when no recipients pending or component unmounts. Silent error handling preserves last-known data on transient API failure.

2. **Badge state machine `getBadgeForRecipient`** — pure helper covering 7 states (4 core per CONTEXT D-17 + 3 extras for completeness):
   - internal_unit + sent → green "Đã gửi nội bộ" + tooltip timestamp
   - internal_unit + pending → default "Chờ gửi nội bộ"
   - external_org + lgsp_status=success → green "Đã gửi LGSP ✓" + tooltip timestamp + Mã LGSP
   - external_org + lgsp_status=error → red "Lỗi LGSP: {first 40 chars}…" + tooltip full error
   - external_org + lgsp_status=processing → processing "Đang xử lý LGSP"
   - external_org + lgsp_status=pending → warning "Đang chờ LGSP" + tooltip worker hint
   - external_org + lgsp_status=null → default "Chờ enqueue"

3. **"Đang theo dõi" indicator** at panel header — AntD Badge `status="processing"` with subtle text when `hasPending=true`. Disappears automatically when all recipients reach terminal state.

4. **Extended Gửi UX** — 3 success message sites (handleSendDirect, handleReleaseAndSend, handleSendNoiBo) now show `enqueued_count / external_count` when external recipients exist, e.g. "Đã gửi 3 đơn vị nội bộ + đang gửi 2/2 cơ quan ngoài qua LGSP (theo dõi tại 'Đơn vị / Cơ quan nhận')".

5. **Refactored, not duplicated** — removed old local `noiNhan` state + `fetchNoiNhan` callback completely. All 3 `fetchNoiNhan()` call sites replaced with hook's `refetchNoiNhan()`. Promise.all cleanup deps updated. Hook becomes single source of truth for recipient data.

## Task Commits

Each task committed atomically (Task 3 = verification only, no source change):

1. **Task 1: Create useRecipientsPolling hook** — `46dae6a` (feat)
   - NEW `e_office_app_new/frontend/src/hooks/use-recipients-polling.ts` (116 lines)
   - Export RecipientStatus interface + hook function
   - Pure helper computeHasPending() + useEffect cleanup pattern

2. **Task 2: Wire hook + badge state machine into page** — `05bf18f` (feat)
   - Import Tooltip antd + useRecipientsPolling + RecipientStatus
   - Add getBadgeForRecipient helper (49 lines, 7 cases)
   - Replace local state/callback with hook
   - Replace 3 fetchNoiNhan → refetchNoiNhan
   - Update 3 success message sites with enqueued_count
   - Replace render panel with badge state machine + Tooltip wrapping + "Đang theo dõi" header indicator
   - Net diff: +122 / -58 lines

3. **Task 3: Production build verify + sanity check** — no source change
   - `npm run build` PASS (`.next/build-manifest.json` exists, all 51 routes built including `ƒ /van-ban-di/[id]` dynamic)
   - `hidden-routes.ts` unchanged — `/lgsp` + `/lgsp/co-quan` still hidden
   - No new `console.*` in hook or page diff

## Verification

**TypeScript strict (CLAUDE.md SCOPE BOUNDARY rule applied):**
- Full `npx tsc --noEmit` reports 4 pre-existing TS2345 errors in unrelated files:
  - `src/app/(main)/ho-so-cong-viec/page.tsx:191`
  - `src/app/(main)/van-ban-den/page.tsx:153`
  - `src/app/(main)/van-ban-di/page.tsx:156`
  - `src/app/(main)/van-ban-du-thao/page.tsx:178`
- These are Phase 33-05 deferred TreeNode type issues, **NOT** introduced by Plan 34-04
- ZERO new errors in Phase 34-04 target files (`use-recipients-polling.ts` and `van-ban-di/[id]/page.tsx`)

**Production build:** PASS (`npm run build` with `NODE_ENV` unset per CLAUDE.md pitfall #2)
- `.next/build-manifest.json` generated
- Page `van-ban-di/[id]` compiled as dynamic route (ƒ)
- All 51 routes built successfully

**Acceptance grep checks (all PASS):**

Hook file:
- `export function useRecipientsPolling` ✓
- `export interface RecipientStatus` ✓
- `setInterval` ✓ (line 102)
- `clearInterval` ✓ (lines 93, 109)
- `lgsp_status` ✓ (in interface + computeHasPending)
- `computeHasPending` ✓
- Line count 116 (>= 70 required)

Page file:
- `useRecipientsPolling` ✓ (import + invocation line 221)
- `getBadgeForRecipient` ✓ (helper at line 105 + invocation line 780)
- `refetchNoiNhan` ✓ (3 call sites)
- `noiNhanHasPending` ✓ (line 772 conditional render)
- Old `setNoiNhan` removed (zero matches)
- Old `fetchNoiNhan` callback removed (zero matches — only `refetchNoiNhan` remains)
- 4 badge state labels present:
  - "Đã gửi nội bộ" ✓
  - "Đang chờ LGSP" ✓
  - "Đã gửi LGSP" ✓
  - "Lỗi LGSP" ✓
- "Đang xử lý LGSP" ✓ (extra)
- "Đang theo dõi" ✓ (polling indicator)
- `Tooltip` ✓ (imported + used 3 places)

**Hidden routes unchanged (CLAUDE.md customer-facing scope honored):**
- `/lgsp` still in `hidden-routes.ts` line 31
- `/lgsp/co-quan` still in `hidden-routes.ts` line 32
- Menu LGSP will remain hidden until Phase 37 unhides

**No console.log added:** Diff has 0 new `console.*` statements (both files).

## Files Created/Modified

- `e_office_app_new/frontend/src/hooks/use-recipients-polling.ts` — **NEW** — Reusable polling hook with state-machine-driven cleanup
- `e_office_app_new/frontend/src/app/(main)/van-ban-di/[id]/page.tsx` — **MODIFIED** — Wired hook, added badge helper, refactored render panel, extended Gửi success messages

## Decisions Made

All decisions inherited from `34-CONTEXT.md`:
- **D-16 honored:** 10s polling interval, auto-stop on hasPending=false / unmount / disabled
- **D-17 honored:** 4 core badge states + 3 extras for processing/null/internal-pending edges
- **Hook reusable:** future pages (Phase 37 admin "Gửi lại" UI) can import the same hook + RecipientStatus type
- **Tooltip multiline:** uses `whiteSpace: 'pre-wrap'` to preserve newlines in tooltip content (timestamp + Mã LGSP on separate lines)
- **Error truncation:** badge label cuts at 40 chars + ellipsis; full message in tooltip (UX balance: scannable + complete on hover)

## Deviations from Plan

None — plan executed exactly as written.

The plan's action steps and verification checks matched implementation 1:1 with one minor optimization: removed the local `noiNhan` state + `fetchNoiNhan` callback fully (rather than keeping them as separate concerns) because the hook completely subsumes their responsibility. This was already the plan intent ("Replace state + fetch noiNhan với hook" at Task 2 Bước 2 a/b/c) — implementation matches.

## Issues Encountered

None. Frontend production build succeeded on first attempt. TypeScript strict mode passes for the 2 Phase 34-04 target files.

## Known Stubs

None. All UI states are wired to backend data via the polling hook. No placeholder/hardcoded values introduced.

## Threat Flags

None introduced. Surfaces unchanged:
- API endpoint `/van-ban-di/:id/noi-nhan` was Phase 19 existing — no new endpoint exposed
- Hook auth attaches via shared `api` axios instance interceptor (existing JWT pattern)
- Error messages from `lgsp_error_message` displayed in UI — these are backend-controlled messages from `LGSP_ERROR_CODES` map (Phase 34-01 controlled), not raw stack traces
- No new client-side data persistence (hook state is component-scoped, dies on unmount)

## Manual Visual Check (deferred to Plan 34-05 E2E)

Spec for E2E test in Plan 34-05:
1. Đăng nhập user văn thư DN.001 (sandbox active, `LGSP_DEFAULT_ENVIRONMENT=sandbox`)
2. Tạo VB đi với recipients mix: 3 internal + 2 external (H37.DN.002, H37.DN.003 sandbox)
3. Bấm "Gửi" → response success `{ internal_count: 3, external_count: 2, enqueued_count: 2 }`
4. Toast message hiển thị: "Đã gửi 3 đơn vị nội bộ + đang gửi 2/2 cơ quan ngoài qua LGSP (theo dõi tại 'Đơn vị / Cơ quan nhận')"
5. Panel "Đơn vị / Cơ quan nhận" hiển thị:
   - 3 row internal: badge green "Đã gửi nội bộ" + tooltip "Đã gửi lúc DD/MM/YYYY HH:mm"
   - 2 row external: badge orange "Đang chờ LGSP" + tooltip "Worker đang xử lý gửi LGSP — tự cập nhật sau ~30s"
   - Header panel hiển thị Badge "Đang theo dõi" với animated processing dot
6. Đợi 30-60s (worker process) → badge external transition mà KHÔNG cần refresh page:
   - Success path: green "Đã gửi LGSP ✓" + tooltip "Đã gửi lúc DD/MM/YYYY HH:mm\nMã LGSP: {uuid}"
   - Error path: red "Lỗi LGSP: {first 40 chars}…" + tooltip full error
7. Sau khi tất cả recipients reach terminal state → Badge "Đang theo dõi" biến mất → DevTools Network tab confirm polling stop (no more `/noi-nhan` requests every 10s)
8. Error path test: tạo VB đi với external recipient code không tồn tại → worker fail mã 18 → badge red "Lỗi LGSP: Đơn vị nhận không tồn tại (Code 18)"

## Next Phase Readiness

**Plan 34-05 (E2E sandbox test):**
- All 3 LGSP send flow layers now stitched end-to-end (route enqueue → worker process → DB update → frontend badge)
- Backend ready (Plans 34-01, 34-02, 34-03)
- Frontend ready (Plan 34-04 — this plan)
- Sandbox credentials active (DN.001 confirmed per CONTEXT)
- Set `LGSP_DEFAULT_ENVIRONMENT=sandbox` in `backend/.env`, restart backend, run worker terminal, exercise UI per manual visual check spec above

**Phase 37 (admin "Gửi lại" UI — future):**
- `useRecipientsPolling` hook + `getBadgeForRecipient` helper can be lifted to a shared `e_office_app_new/frontend/src/components/lgsp/recipient-badge.tsx` for reuse across:
  - Admin LGSP tracking dashboard (new in Phase 37)
  - Bulk retry UI (new in Phase 37)
  - Notifications widget
- Hide-then-unhide gating: when Phase 37 unhides menu LGSP in `hidden-routes.ts`, no other code change needed for this badge to work — Phase 34-04 already shipped the building blocks

## Commits

- `46dae6a` feat(34-04): them hook useRecipientsPolling polling 10s recipients status
- `05bf18f` feat(34-04): wire useRecipientsPolling + badge state machine 4 state vao van-ban-di detail

(Task 3 = build verification only, no source commit.)

## Self-Check: PASSED

**Files exist:**
- ✓ FOUND: `e_office_app_new/frontend/src/hooks/use-recipients-polling.ts` (116 lines, new)
- ✓ FOUND: `e_office_app_new/frontend/src/app/(main)/van-ban-di/[id]/page.tsx` (+122 / -58 lines)

**Commits exist:**
- ✓ FOUND: `46dae6a` (Task 1 — new hook)
- ✓ FOUND: `05bf18f` (Task 2 — page wire-up)

**Acceptance grep checks:** ALL PASS (16/16 patterns verified — 6 hook + 10 page)

**TypeScript:** 0 new errors in Phase 34-04 files (4 pre-existing TS2345 in unrelated files ignored per CLAUDE.md scope boundary)

**Production build:** PASS — `npm run build` exit 0, `.next/build-manifest.json` generated, all 51 routes compiled

**Hidden routes:** unchanged — `/lgsp` + `/lgsp/co-quan` still hidden (Phase 37 will unhide)

---
*Phase: 34-send-flow-sendedoc*
*Plan: 04*
*Completed: 2026-05-20*
