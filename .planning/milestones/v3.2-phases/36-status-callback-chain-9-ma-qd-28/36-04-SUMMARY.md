---
phase: 36-status-callback-chain-9-ma-qd-28
plan: 04
subsystem: frontend
tags: [lgsp, status-callback, qd28, timeline, polling, ui-detail, antd-v6]
requirements:
  - LGSP-STATUS-10           # UI tag trang thai LGSP (01..16) mau phan biet + tooltip Vietnamese
  - LGSP-STATUS-07 (partial) # "Chuyen lai" -> "Tu choi tiep nhan" label helper -- backend rename + button refactor defer Phase 37
dependency_graph:
  requires:
    - 36-01  # lgspStatusOutboxRepository.getDocStatusHistory + LgspTargetStatus type (backend)
    - 36-03  # GET /api/van-ban-den/:id/lgsp-status-history endpoint
    - 35-04  # Detail page DocDetail co source_type/external_doc_id/lgsp_sender_org_code + "Nguon LGSP" Card pattern
  provides:
    - "Helper module lgsp-status-labels.ts (9 ma -> tieng Viet + AntD color + tooltip description) -- reusable cho Phase 37"
    - "Component LgspStatusTimeline (AntD v6 Timeline items prop + polling 10s pending event)"
    - "Detail VB den page extension: section 'Lich su trang thai LGSP' conditional render khi source_type='external_lgsp'"
  affects:
    - "Plan 36-05 (E2E verification) -- frontend UI visual check Timeline render dung 4-5 entries voi badge sau khi action sequence"
    - "Phase 37 admin UI lgsp-config + van-ban-di sender-side -- reuse helper module + Timeline component"
tech-stack:
  added: []
  patterns:
    - "AntD v6 Timeline items prop functional API (NOT deprecated Timeline.Item children syntax)"
    - "Polling 10s chi khi co >=1 row pending (saves bandwidth -- auto-stop khi tat ca da success/error)"
    - "BIGINT id pg driver tra string -> Number() wrap per CLAUDE.md pitfall #9"
    - "Conditional render mirror Phase 35-04 'Nguon LGSP' pattern -- INSERT them Card thu 2 ngay sau, KHONG modify Card cu"
    - "4 render states: loading (Skeleton) / error (Text danger) / empty (Empty.PRESENTED_IMAGE_SIMPLE) / data (Timeline)"
    - "Helper module data-only constants (KHONG JSX) -- component dung helper data + tu render Tag"
key-files:
  created:
    - e_office_app_new/frontend/src/lib/lgsp-status-labels.ts
    - e_office_app_new/frontend/src/components/lgsp-status-timeline.tsx
  modified:
    - e_office_app_new/frontend/src/app/(main)/van-ban-den/[id]/page.tsx
decisions:
  - "D-14 honored: helper map 9 ma -> Vietnamese label theo CONTEXT spec exact (01='Da gui', 02='Tu choi tiep nhan', 03='Da tiep nhan', 04='Phan cong', 05='Dang xu ly', 06='Hoan thanh', 13/15/16='Lay lai/Dong y/Tu choi lay lai')"
  - "D-14 color mapping honored: 01=blue, 02=red, 03=gold, 04=orange, 05=processing (animated blue), 06=green, 13=default (gray), 15=green, 16=red"
  - "AntD v6 Timeline items prop (NOT deprecated Timeline.Item JSX children) -- mirror Phase 36-04 plan skeleton + AGENTS.md note 've Next.js/AntD breaking changes'"
  - "Polling 10s khi co pending -- mirror Phase 34-04 pattern, useEffect cleanup with clearInterval. Auto-stop khi no pending -- saves bandwidth"
  - "Conditional render duy nhat khi source_type='external_lgsp' -- ngay sau Phase 35-04 Nguon LGSP card, KHONG nested vi 2 concerns rieng (info vs history)"
  - "Tach 2 file (helper + component) -- helper reusable cho Phase 37 admin/van-ban-di sender-side (13/15/16) ma KHONG can rewrite map 9 ma"
  - "LGSP-STATUS-07 partial: label 'Tu choi tiep nhan' (ma 02) co trong helper -- backend SP rename + button 'Chuyen lai LGSP' text refactor defer Phase 37 per CONTEXT scope"
metrics:
  duration: "~10 min"
  ts_errors_frontend: "0 NEW (4 pre-existing TS2345 Phase 33-05 in ho-so-cong-viec/van-ban-den/van-ban-di/van-ban-du-thao pages -- acceptable per project constraints)"
  build_pass: true
  acceptance_grep_checks_passed: 8
  commits: 3
  files_created: 2
  files_modified: 1
  lines_added: 284
  completed: 2026-05-21
---

# Phase 36 Plan 36-04: Frontend Timeline UI Lich Su Trang Thai LGSP Summary

**One-liner:** Wave 2 frontend consumer — them helper `lgsp-status-labels.ts` (9 ma QD 28 -> tieng Viet + AntD color + tooltip), component `LgspStatusTimeline` (AntD v6 Timeline items prop + polling 10s khi co pending), wire vao detail VB den page conditional render khi `source_type='external_lgsp'` ngay sau Phase 35-04 "Nguon LGSP" card.

## What was built

### Task 1: NEW helper lgsp-status-labels.ts (commit `b546680`)

**File created:** `e_office_app_new/frontend/src/lib/lgsp-status-labels.ts` (85 dong)

**5 const exports + 1 type:**

| Export | Purpose |
|---|---|
| `type LgspTargetStatus` | Union 9 ma: `'01' \| '02' \| '03' \| '04' \| '05' \| '06' \| '13' \| '15' \| '16'` |
| `LGSP_STATUS_LABELS` | Map 9 ma -> tieng Viet co dau ('Da gui', 'Tu choi tiep nhan', ...) |
| `LGSP_STATUS_COLORS` | Map ma -> AntD Tag color token per D-14 (01=blue, 06=green, 02/16=red, 03=gold, 04=orange, 05=processing, 13=default, 15=green) |
| `LGSP_STATUS_DESCRIPTIONS` | Map ma -> tooltip Vietnamese day du (vi du 03='Van thu don vi nhan da tiep nhan VB vao he thong') |
| `SENT_STATUS_COLORS` | Map sent_status -> Tag color (pending=orange, success=green, error=red) |
| `SENT_STATUS_LABELS` | Map sent_status -> tieng Viet ('Dang cho gui', 'Da gui', 'Loi') |

**Pattern:** Data-only constants module (KHONG JSX). Component dung data tu helper de render `<Tag>` -- mirror `lgsp-source-badge.tsx` (Phase 35-04) split helper structure. Reusable cho Phase 37 admin UI + van-ban-di sender-side (13/15/16) ma KHONG can rewrite map.

### Task 2: NEW component LgspStatusTimeline (commit `fc40657`)

**File created:** `e_office_app_new/frontend/src/components/lgsp-status-timeline.tsx` (193 dong)

**Props:** `{ incomingDocId: number }`

**Export shape:**
- `interface LgspStatusHistoryRow` (matches Plan 36-03 GET endpoint shape)
- `function LgspStatusTimeline({ incomingDocId }: Props): React.ReactElement`

**Data flow:**
1. **Initial fetch** trong `useEffect`: `api.get('/van-ban-den/${id}/lgsp-status-history')` -> normalize BIGINT id via `Number()` -> setRows.
2. **Polling 10s** trong useEffect riêng: chi start `setInterval` khi `rows.some(r => r.sent_status === 'pending')`. Auto-stop khi tat ca da success/error (cleanup `clearInterval` trong return).

**Render states (4):**
- Loading: `<Skeleton active paragraph={{ rows: 3 }} />`
- Error: `<Text type="danger">Loi: {error}</Text>`
- Empty: `<Empty description="Chua co su kien trang thai LGSP nao cho van ban nay" image={Empty.PRESENTED_IMAGE_SIMPLE} />`
- Data: `<Timeline mode="left" items={items} />` (AntD v6 items prop functional API)

**Per-row Timeline item:**
- **Dot color/icon** uu tien sent_status: pending=Spin small (orange), success=CheckCircle (green #52c41a), error=CloseCircle (red #ff4d4f)
- **Label** (left side): `dayjs(created_at).format('DD/MM HH:mm')` gray 12px
- **Children** (right side): vertical Space
  - Row 1: Tooltip(description) > Tag(color, `{ma} — {label}`) + Tag(sent_color, sent_label) + Tag(retry x/5) khi error
  - Row 2 (success): "Da day len truc luc {sent_at HH:mm:ss}"
  - Row 2 (error): Tooltip(full error_message) > Text danger ellipsis 600px

### Task 3: Wire vao detail page (commit `46e56a3`)

**File modified:** `e_office_app_new/frontend/src/app/(main)/van-ban-den/[id]/page.tsx`

**2 changes:**

1. **Import** (line 23, ngay sau LgspSourceBadge import):
   ```typescript
   import { LgspStatusTimeline } from '@/components/lgsp-status-timeline';
   ```

2. **Insert Card section MOI** (line 589-592, sau Phase 35-04 Nguon LGSP card close `)}` line 587, truoc `<Row gutter={16}>`):
   ```tsx
   {/* ====== Phase 36 Plan 36-04: Lich su trang thai LGSP — chi hien khi source_type='external_lgsp' ====== */}
   {doc.source_type === 'external_lgsp' && (
     <LgspStatusTimeline incomingDocId={Number(doc.id)} />
   )}
   ```

**KHONG sua Phase 35-04 Nguon LGSP card. KHONG thay doi conditional Phase 35-04.** 2 Card rieng biet vi 2 concerns (Nguon = static info luc receive, Lich su = dynamic outbox events qua time).

## Decisions made (honored from CONTEXT)

- **D-14 UI Timeline pattern honored:** Helper `lgsp-status-labels.ts` exports map 9 ma -> tieng Viet exact theo CONTEXT spec. AntD `<Timeline>` component voi 3 sent_status badge (pending orange spin / success green check / error red exclamation + tooltip error_message).
- **D-14 color mapping honored:** 01=blue (initial), 06=green (final success), 02/16=red (negative), 03=gold/04=orange/05=processing (in-progress), 13=default gray, 15=green.
- **AntD v6 items prop:** Plan skeleton + AGENTS.md note ('This is NOT the Next.js you know' / breaking changes) -- ratified items prop over deprecated `<Timeline.Item>` JSX children.
- **Polling pattern:** Mirror Phase 34-04 hook pattern -- useEffect cleanup with clearInterval. Auto-stop khi no pending -- saves bandwidth (most docs sau khi worker xu ly xong se khong con pending nua).
- **2-file split (helper + component) honored** per plan -- reusable cho Phase 37 admin/sender-side ma KHONG can rewrite map 9 ma.

## Deviations from Plan

**None.** Tat ca 3 task execute exactly per plan skeleton:
- Task 1 file content match skeleton 100% (5 const + 1 type)
- Task 2 component skeleton match 100% (4 render states + polling 10s + items prop + BIGINT Number() wrap)
- Task 3 wire INSERT ngay sau Phase 35-04 Nguon LGSP card -- KHONG modify card cu, conditional duy nhat

**No auto-fixes needed:**
- Endpoint path `/van-ban-den/:id/lgsp-status-history` verify dung qua Plan 36-03 SUMMARY (`router.get('/:id/lgsp-status-history'` mounted at `/api/van-ban-den/*` per server.ts)
- AntD imports da co `Timeline` san trong page.tsx line 5 -- KHONG remove (page van dung Timeline o section khac), chi add LgspStatusTimeline component import rieng
- Pre-existing 4 TS2345 errors trong tree-utils consumers (ho-so-cong-viec/van-ban-den/van-ban-di/van-ban-du-thao list pages) Phase 33-05 -- acceptable per project constraints, KHONG fix vi out-of-scope task

## Auth gates encountered

**None plan-blocking** -- frontend build self-contained, KHONG can backend running. Plan 36-05 E2E verification se test runtime fetch endpoint + worker pickup.

## Verification results

### TypeScript clean
- `cd e_office_app_new/frontend && npx tsc --noEmit` -> 0 NEW errors (4 pre-existing TS2345 Phase 33-05 acceptable per project constraints)

### Production build
- `cd e_office_app_new/frontend && Remove-Item Env:NODE_ENV; npm run build` -> exit 0
- All routes prerendered/dynamic correctly: `/van-ban-den` (static) + `/van-ban-den/[id]` (dynamic ƒ) -- xac nhan LgspStatusTimeline duoc bundle vao page.

### Acceptance grep checks (8/8 PASS)

**Task 1 helper (4):**
- `export const LGSP_STATUS_LABELS` present
- `Đã tiếp nhận` Vietnamese diacritics present (mã 03)
- `'06': 'Hoàn thành'` present
- `export const LGSP_STATUS_COLORS|DESCRIPTIONS|SENT_STATUS_COLORS` all present

**Task 2 component (5):**
- `export function LgspStatusTimeline` present
- `import { Timeline, Tag, Tooltip, ...` present
- `/lgsp-status-history` endpoint path present
- `POLL_INTERVAL_MS = 10_000` present
- `<Timeline mode="left" items={items} />` present (v6 items prop)
- `Lịch sử trạng thái LGSP` Vietnamese present

**Task 3 wire (2):**
- `import { LgspStatusTimeline } from '@/components/lgsp-status-timeline'` present (line 23)
- `<LgspStatusTimeline incomingDocId={Number(doc.id)} />` present (line 592, INSIDE conditional `source_type === 'external_lgsp'`)

## Threat Flags

None. Per CONTEXT threat model T-36-10/T-36-11:
- `error_message` Vietnamese-mapped Phase 34 `mapLgspError()`, truncated 1000 chars at DB INSERT -- accept disposition.
- React auto-escapes `{value}` interpolation, payload NOT rendered (only id/target_status/sent_status/timestamps/error_message). XSS mitigated.

## Next steps (downstream)

- **Plan 36-05 E2E verification:**
  - DN.001 sandbox active + tao 1 incoming_doc `source_type='external_lgsp'` (qua Phase 35 receive flow hoac manual INSERT)
  - Trigger sequence: PATCH `/danh-dau-da-doc` -> wait 30s tick -> open detail UI -> verify section "Lich su trang thai LGSP" render Timeline 1 entry (03, blue dot pending -> green dot success sau 10s polling refresh)
  - Tiep tuc giao-viec (04) + but-phe (05) + chuyen-luu-tru (06) -- verify Timeline grow 4 entries chronological
  - Error path: tam UPDATE credential sai -> giao-viec -> outbox 04 enqueued -> worker fail 5x -> UI hien red dot + Tag "Loi (retry 5/5)" + tooltip error_message
  - Visual verify: color mapping dung (06 green, 02/16 red, 05 processing animated blue), tooltip description Vietnamese day du khi hover
  - Dedup test: PATCH danh-dau-da-doc lan 2 -> Timeline van chi co 1 row 03 (UNIQUE chan)

## Self-Check: PASSED

**Files created (2):**
- `e_office_app_new/frontend/src/lib/lgsp-status-labels.ts` -- FOUND (85 dong, 5 const + 1 type)
- `e_office_app_new/frontend/src/components/lgsp-status-timeline.tsx` -- FOUND (193 dong)

**Files modified (1):**
- `e_office_app_new/frontend/src/app/(main)/van-ban-den/[id]/page.tsx` -- FOUND (1097 dong sau add 6 dong import + Card section)

**Commits (3):**
- `b546680` -- FOUND (`feat(36-04): them helper lgsp-status-labels.ts (9 ma QD 28 labels + colors + descriptions)`)
- `fc40657` -- FOUND (`feat(36-04): them component LgspStatusTimeline (AntD Timeline items + polling 10s pending)`)
- `46e56a3` -- FOUND (`feat(36-04): wire LgspStatusTimeline vao VB den detail page (conditional external_lgsp)`)
