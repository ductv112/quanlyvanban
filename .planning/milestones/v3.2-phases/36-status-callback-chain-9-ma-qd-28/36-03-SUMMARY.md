---
phase: 36-status-callback-chain-9-ma-qd-28
plan: 03
subsystem: backend/route + backend/server
tags: [lgsp, status-callback, qd28, route-hook, outbox, server-startup, sigterm]
requirements:
  - LGSP-STATUS-02   # Auto fire mã 03 (Tiếp nhận) khi mark-read
  - LGSP-STATUS-03   # Auto fire mã 04 (Phân công) khi giao-viec
  - LGSP-STATUS-04   # Auto fire mã 05 (Đang xử lý) khi but-phe + them-vao-hscv
  - LGSP-STATUS-05   # Auto fire mã 06 (Hoàn thành) khi chuyen-luu-tru + handling-doc complete
  - LGSP-STATUS-06   # Refactor chuyen-lai LGSP doc → fire mã 02 (Từ chối tiếp nhận) — backend hook only; SP rename + label refactor defer Phase 37
dependency_graph:
  requires:
    - 36-01  # lgspStatusOutboxRepository.insertEvent + getDocStatusHistory + LgspTargetStatus type
    - 36-02  # registerStatusTickRepeatJob + closeLgspStatusQueue producer queue
    - 35-04  # incoming_docs columns source_type/external_doc_id/lgsp_sender_org_code exposed
  provides:
    - "6 incoming-doc routes wired auto fire outbox (mark-read 03 / giao-viec 04 / but-phe 05x2 / them-vao-hscv 05 / chuyen-luu-tru 06 / chuyen-lai 02)"
    - "1 handling-doc route wired (PATCH /:id/trang-thai action='complete' → outbox 06 cho moi VB cha LGSP gan HSCV)"
    - "1 new endpoint GET /api/van-ban-den/:id/lgsp-status-history (chronological history cho UI Timeline Plan 36-04)"
    - "server.ts startup non-blocking registerStatusTickRepeatJob (mirror Phase 35-03 receive cron pattern)"
    - "server.ts SIGTERM chain extend closeLgspStatusQueue truoc closeRedisConnection (Phase 36)"
  affects:
    - "Plan 36-04 (UI Timeline) — frontend se consume GET /lgsp-status-history endpoint"
    - "Plan 36-05 (E2E verification) — verify outbox INSERTED dung sau moi action + worker pickup 30s"
tech-stack:
  added: []
  patterns:
    - "Helper fireLgspStatusOutbox: guard source_type='external_lgsp' + try/catch + req.log.warn KHONG fail user action (D-03 best-effort)"
    - "loadDocAndPerms extend SELECT them 3 cot LGSP -- hook payload build truc tiep, KHONG can extra getById call"
    - "Schema adaptation: handling_doc_links (doc_type='incoming', doc_id) thay vi handling_doc_documents -- verified qua psql"
    - "Non-blocking startup hook .then/.catch (mirror Phase 35-03) -- failure KHONG crash server"
    - "SIGTERM order: send -> receive -> status -> redis (Phase 36 status BEFORE redis cleanup)"
key-files:
  created: []
  modified:
    - e_office_app_new/backend/src/routes/incoming-doc.ts
    - e_office_app_new/backend/src/routes/handling-doc.ts
    - e_office_app_new/backend/src/server.ts
decisions:
  - "D-01 honored: action -> ma mapping dung spec (03/04/05/05/06/02 + handling complete 06)"
  - "D-02 honored: guard source_type='external_lgsp' tap trung trong helper fireLgspStatusOutbox -- KHONG fire cho doc noi bo"
  - "D-03 honored: hook trong success path (sau SP commit, truoc res.json), try/catch + log warn KHONG fail user action"
  - "D-15 honored: server.ts startup registerStatusTickRepeatJob non-blocking + SIGTERM closeLgspStatusQueue (mirror Phase 35-03 exact pattern)"
  - "Extend loadDocAndPerms thay vi add separate getById per hook -- tiet kiem 1 round-trip DB per route, payload build truc tiep tu loaded.doc"
  - "Schema adaptation handling_doc_links: plan goc tham chieu handling_doc_documents nhung verify qua psql -> table thuc te la handling_doc_links voi doc_type='incoming' + doc_id. Query adapted accordingly."
metrics:
  duration: "~12 min"
  ts_errors_backend: 0
  build_pass: true
  smoke_test_backend_health: "HTTP 200 (backend running, hot reload OK)"
  acceptance_grep_checks_passed: 11
  commits: 3
  files_modified: 3
  completed: 2026-05-21
---

# Phase 36 Plan 36-03: Route Hooks + Server Startup Wiring Summary

**One-liner:** Wave 2 producer side — wire 7 route hooks (6 incoming-doc + 1 handling-doc) auto-fire `lgsp_status_outbox` row sau khi SP commit thanh cong neu doc `source_type='external_lgsp'` (5 ma QD 28: 02/03/04/05/06), them 1 GET endpoint `/lgsp-status-history` cho UI Timeline, va wire server.ts startup register 30s status cron + SIGTERM cleanup chain extend.

## What was built

### Task 1: 6 incoming-doc.ts route hooks + GET history endpoint (commit `6cc6318`)

**File modified:** `e_office_app_new/backend/src/routes/incoming-doc.ts`

**Import them:** `import { lgspStatusOutboxRepository, type LgspTargetStatus } from '../repositories/lgsp-status-outbox.repository.js'`.

**Helper `loadDocAndPerms` extend SELECT:** Plan goc khong de cap nhung tat ca route dung helper nay deu can `source_type`/`external_doc_id`/`lgsp_sender_org_code` cho hook payload. Extend SELECT 3 cot them -- tiet kiem 1 round-trip DB per hook call (alternative la goi `incomingDocRepository.getById()` rieng).

**Helper `fireLgspStatusOutbox(doc, targetStatus, req, extra?)`:**
- Guard `if (doc.source_type !== 'external_lgsp') return` (D-02)
- Call `lgspStatusOutboxRepository.insertEvent({incoming_doc_id, target_status, payload: {lgsp_doc_id, sender_org_code, ...extra}})`
- 3 log paths: dedup skip (result===null), SP success=false (warn), success (info with outboxId)
- try/catch outer: log warn + return (KHONG throw -- D-03 best-effort)

**6 routes wired:**

| Route | Mã | Pattern |
|---|---|---|
| PATCH `/danh-dau-da-doc` | 03 | Batch query LGSP docs tu `doc_ids` array (1 SELECT WHERE id = ANY + source_type filter) → loop fire 03 per doc. Best-effort wrap batch -- 1 doc fail KHONG dragon bulk mark-read |
| POST `/:id/giao-viec` | 04 | Reuse `loaded.doc` (loadDocAndPerms da load) + payload `{hscv_id, curator_ids}` |
| POST `/:id/but-phe` (combo path) | 05 | Inline query LGSP cot (route khong dung loadDocAndPerms) + payload `{leader_note_id}` |
| POST `/:id/but-phe` (standalone path) | 05 | Inline query LGSP cot + payload `{leader_note_id}` |
| POST `/:id/them-vao-hscv` | 05 | Reuse `loaded.doc` + payload `{handling_doc_id}` -- UNIQUE NOOP neu da co 05 tu but-phe |
| POST `/:id/chuyen-luu-tru` | 06 | Reuse `loaded.doc` + payload `{archive_id}` |
| POST `/:id/chuyen-lai` | 02 | Reuse `loaded.doc` + payload `{reason}` -- backend ready, SP rename + UI label refactor defer Phase 37 |

**NEW endpoint:** `GET /:id/lgsp-status-history`
- Permission check qua `loadDocAndPerms()` (giong Phase 35-04 pattern) → 404 neu khong xem duoc
- `lgspStatusOutboxRepository.getDocStatusHistory(docId)` tra ve chronological ASC
- Response: `{ success: true, data: HistoryRow[] }`

**Grep verification:**
- `fireLgspStatusOutbox` count = 10 (1 helper def + 9 sites: 1 batch loop + 5 inline calls per Plan + 3 doc fields)
- All 5 mã ('02','03','04','05','06') present in route file
- `source_type !== 'external_lgsp'` guard present in helper
- New endpoint route registered with `loadDocAndPerms` permission gate

### Task 2: handling-doc.ts complete hook (commit `b4079ba`)

**File modified:** `e_office_app_new/backend/src/routes/handling-doc.ts`

**Schema verification (psql):** Plan goc tham chieu `edoc.handling_doc_documents` voi cot `incoming_doc_id` -- nhung verify qua `\d edoc.handling_doc*` cho thay table thuc te la `edoc.handling_doc_links` voi cot `doc_type` VARCHAR(20) + `doc_id` BIGINT (polymorphic link). Query adapted: filter `WHERE hdl.doc_type = 'incoming' AND d.source_type = 'external_lgsp'`.

**Helper `fireHscvCompleteOutbox(handlingDocId, req)`:**
- Query JOIN `handling_doc_links` ↔ `incoming_docs` filter `source_type='external_lgsp'`
- Loop fire outbox 06 per VB cha LGSP voi payload `{lgsp_doc_id, sender_org_code, handling_doc_id, trigger: 'hscv_complete'}`
- 2-level try/catch: outer cho query fail, inner cho per-doc INSERT fail → log warn each, NEVER throw

**Wire vao PATCH `/:id/trang-thai`:** Sau `if (!result.success)` check pass, them `if (action === 'complete') { await fireHscvCompleteOutbox(id, req); }` truoc `res.json`.

**Best-effort:** Hook fail KHONG fail HSCV complete -- user van thay HSCV done, chi LGSP callback ko gui (worker se KHONG retry vi khong co outbox row tao thanh cong).

### Task 3: server.ts startup + SIGTERM (commit `57c43b2`)

**File modified:** `e_office_app_new/backend/src/server.ts`

**Import them:** `registerStatusTickRepeatJob` + `closeLgspStatusQueue` tu `./lib/queue/lgsp-status-queue.js`.

**Startup hook (sau Phase 35 `registerReceiveTickRepeatJob`):**
```typescript
registerStatusTickRepeatJob()
  .then(() => { /* success log inside helper */ })
  .catch((err) => logger.error({ err }, 'Failed to register LGSP status tick repeat job (...)'));
```
Non-blocking pattern mirror exact Phase 35-03. Failure (Redis chua ready) KHONG crash server -- outbox events accumulate, worker pickup khi Redis san sang.

**SIGTERM chain extend:** Them `try { await closeLgspStatusQueue(); } catch (...)` truoc `closeRedisConnection`. Thu tu shutdown: signing → lgsp-send → lgsp-receive → **lgsp-status (NEW)** → redis. Status close TRUOC redis vi queue can ket noi Redis de drain in-flight.

## Decisions made (honored from CONTEXT)

- **D-01 (mapping):** 03 cho mark-read, 04 cho giao-viec, 05 cho but-phe + them-vao-hscv, 06 cho chuyen-luu-tru + handling complete, 02 cho chuyen-lai. Bang map nay duoc test bang 7 hook call sites trong commit history.
- **D-02 (guard):** Helper `fireLgspStatusOutbox` co line dau tien `if (doc.source_type !== 'external_lgsp') return` -- tap trung guard tai 1 cho duy nhat. handling-doc helper guard trong SQL `WHERE d.source_type = 'external_lgsp'`.
- **D-03 (best-effort):** Tat ca hook call wrap try/catch ngoai (helper level) + log warn + KHONG throw → user action vẫn return 200/201 du outbox fail. Test bang `grep -B5 fireLgspStatusOutbox` cho thay tat ca call nam trong success path (sau SP commit), khong nam trong catch block.
- **D-15 (server wiring):** Mirror Phase 35-03 pattern exact -- non-blocking startup + SIGTERM extend. SIGTERM order document trong code (status TRUOC redis).

## Deviations from Plan

**Auto-fixed Issues:**

1. **[Rule 3 - Schema adaptation] handling_doc_links thay vi handling_doc_documents**
   - **Found during:** Task 2 schema verification step (`<read_first>` step 3 trong plan)
   - **Issue:** Plan tham chieu `edoc.handling_doc_documents` voi cot `incoming_doc_id` nhung verify qua `docker exec qlvb_postgres psql ... "\d edoc.handling_doc*"` cho thay 3 table thuc te: `handling_doc_history`, `handling_doc_links`, `handling_docs`. KHONG co `handling_doc_documents`.
   - **Fix:** Adapt query → use `edoc.handling_doc_links` voi `WHERE hdl.doc_type = 'incoming' AND ... JOIN edoc.incoming_docs d ON d.id = hdl.doc_id`. Plan deviation handling block explicit cover case nay: "Nếu Schema dùng tên cột khác... adapt query".
   - **Files modified:** `e_office_app_new/backend/src/routes/handling-doc.ts`
   - **Commit:** `b4079ba`

2. **[Rule 2 - Critical addition] Extend `loadDocAndPerms` SELECT them 3 cot LGSP**
   - **Found during:** Task 1 implementation, 5/6 routes dung helper nay
   - **Issue:** Plan `<action>` skeleton dung `loaded.doc as any` cast vi helper goc chi SELECT `{id, unit_id, created_by}`. Nhung cast `as any` lam mat type safety + 5 route call site can field LGSP. Alternative la goi `incomingDocRepository.getById()` rieng per hook → +1 round-trip per request.
   - **Fix:** Extend `loadDocAndPerms` SELECT them `source_type, external_doc_id, lgsp_sender_org_code` + interface row type. Hook payload build truc tiep tu `loaded.doc` voi proper TypeScript types, ZERO `as any` cast trong call sites.
   - **Files modified:** `e_office_app_new/backend/src/routes/incoming-doc.ts`
   - **Commit:** `6cc6318` (bundle voi Task 1)

3. **[Rule 2 - Critical addition] But-phe standalone path them hook (plan chi mention bundled)**
   - **Found during:** Task 1 implementation, doc plan `<action>` Phan C item 3 noi "Path 2 (line ~809 không staff_ids): tương tự trước res.status(201).json"
   - **Issue:** Standalone but-phe path KHONG dung loadDocAndPerms → can inline query LGSP cot, plan skeleton chi outline brief "tương tự".
   - **Fix:** Inline query LGSP cot pattern (same as combo path), fire 05 voi payload `{leader_note_id}`. 2 success path → 2 hook call site.
   - **Files modified:** `e_office_app_new/backend/src/routes/incoming-doc.ts`
   - **Commit:** `6cc6318`

**No other deviations:** Task 3 (server.ts) executed exactly as plan skeleton — non-blocking startup mirror Phase 35-03 + SIGTERM order extend.

## Auth gates encountered

**None plan-blocking** — local Docker postgres + backend hot reload available, smoke test `curl /api/health` returned HTTP 200. Khong can LGSP credential cho Wave 2 (route hooks INSERT outbox row, worker Plan 36-02 moi POST /v1/updateStatus -- Plan 36-05 verification se E2E test credential).

## Verification results

### TypeScript clean
- `cd e_office_app_new/backend && npx tsc --noEmit` → exit 0 ✓ (after each task)
- `cd e_office_app_new/backend && npm run build` → exit 0 ✓ (production build pass — CLAUDE.md pitfall #4)

### Acceptance grep checks (11/11 PASS)

**Task 1 (7):**
- `grep -c "fireLgspStatusOutbox" incoming-doc.ts` = 10 (>= 7 -- helper def + 9 call sites)
- All 5 ma present: `fireLgspStatusOutbox(... '02')` line 1210, `'03'` line 284, `'04'` line 1154, `'05'` lines 914/941/1256, `'06'` line 1354
- `import { lgspStatusOutboxRepository, type LgspTargetStatus }` exit 0
- `async function fireLgspStatusOutbox` exit 0
- `source_type !== 'external_lgsp'` exit 0 (guard)
- `router.get('/:id/lgsp-status-history'` exit 0
- `getDocStatusHistory` exit 0

**Task 2 (3):**
- `lgspStatusOutboxRepository` exit 0 (import + insertEvent call)
- `async function fireHscvCompleteOutbox` exit 0
- `target_status: '06'` exit 0
- `source_type = 'external_lgsp'` exit 0 (SQL guard)
- `fireHscvCompleteOutbox(id, req)` exit 0
- `if (action === 'complete')` adjacent to hook call exit 0

**Task 3 (4):**
- `registerStatusTickRepeatJob` count = 2 (import + call)
- `closeLgspStatusQueue` count = 2 (import + SIGTERM)
- `from './lib/queue/lgsp-status-queue.js'` exit 0
- SIGTERM order verified: send (234) → receive (235) → status (236) → redis (237)

### Smoke test
- `curl -s -o /dev/null -w "HTTP %{http_code}" http://localhost:4000/api/health` → `HTTP 200` ✓
- Backend hot reload (tsx watch) picked up TS changes — no popup error in console

## Next steps (downstream)

- **Plan 36-04 (UI Timeline frontend):**
  - Frontend `app/(main)/van-ban-den/[id]/page.tsx` extend Phase 35-04 detail thêm conditional section "Lịch sử trạng thái LGSP" khi `source_type='external_lgsp'`.
  - Call `GET /api/van-ban-den/:id/lgsp-status-history` qua axios.
  - Render AntD `<Timeline mode="left">` với map `target_status → label` (02='Từ chối tiếp nhận', 03='Tiếp nhận', 04='Phân công', 05='Đang xử lý', 06='Hoàn thành'), badge per `sent_status` (pending orange spin / success green check / error red exclamation + tooltip error_message).

- **Plan 36-05 (E2E verification):**
  - DN.001 sandbox active + tao 1 doc source_type='external_lgsp' (qua Phase 35 receive flow hoac manual INSERT).
  - Trigger sequence: PATCH danh-dau-da-doc → wait 30s tick → verify outbox 03 sent_status='success'. Tuong tu cho 04/05/06.
  - Dedup test: PATCH danh-dau-da-doc lan 2 → grep log "dedup skip (UNIQUE chan)" + outbox van chi co 1 row 03.
  - Error path: tam UPDATE credential sai → giao-viec → outbox 04 enqueued → worker fail 5x → sent_status='error' + 'Retry exhausted'. RESTORE credential.
  - UI verify: detail page hien thi Timeline 4-5 entries voi badge.

## Self-Check: PASSED

**Files modified (3):**
- `e_office_app_new/backend/src/routes/incoming-doc.ts` — FOUND (1373 dong sau extend)
- `e_office_app_new/backend/src/routes/handling-doc.ts` — FOUND (helper + hook wired)
- `e_office_app_new/backend/src/server.ts` — FOUND (import + startup + SIGTERM)

**Commits (3):**
- `6cc6318` — FOUND (`feat(36-03): hook 6 incoming-doc routes outbox + them GET /lgsp-status-history endpoint`)
- `b4079ba` — FOUND (`feat(36-03): hook handling-doc complete action -> fire outbox 06 cho VB cha LGSP`)
- `57c43b2` — FOUND (`feat(36-03): wire registerStatusTickRepeatJob startup + closeLgspStatusQueue SIGTERM chain`)
