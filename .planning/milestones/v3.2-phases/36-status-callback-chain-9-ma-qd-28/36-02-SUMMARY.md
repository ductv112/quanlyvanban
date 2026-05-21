---
phase: 36-status-callback-chain-9-ma-qd-28
plan: 02
subsystem: workers/lgsp + backend/queue
tags: [lgsp, status-callback, qd28, bullmq, worker, queue, retry, exponential-backoff]
requirements:
  - LGSP-STATUS-09   # Worker poll + exponential backoff (5 retry: 30s/60s/120s/240s/480s) + per-event jobs
dependency_graph:
  requires:
    - 33-05  # edoc.lgsp_status_outbox table + Phase 33 SPs (get_pending, mark_sent, mark_error)
    - 34-01  # workers/src/lgsp/error-codes.ts (LgspSendError + isLgspNonRetryableError)
    - 34-02  # Approach B duplicate workers pattern + lgsp-send 2-worker pattern
    - 35-02  # Phase 35 tick + dn closest analog 2-worker pattern (mirror exact)
    - 36-01  # ILgspService.updateStatus contract + LGSPRealService.updateStatus (consumed indirectly via worker-local lgsp-status-service)
  provides:
    - "workers/src/queues/lgsp-status-queue.ts — 9 constants + 2 job data interfaces"
    - "workers/src/lgsp/lgsp-status-service.ts — resolveDocOwner + loadLgspCredentials + updateStatus (worker-local, Approach B)"
    - "workers/src/jobs/lgsp-status-tick-worker.ts — concurrency=1, attempts=1, fan-out N status-event jobs FIFO"
    - "workers/src/jobs/lgsp-status-event-worker.ts — concurrency=5, attempts=5 exp 30s, 4xx no-retry, on(failed) markError"
    - "backend/src/lib/queue/lgsp-status-queue.ts — producer Queue + 4 exports (get/enqueue/register/close)"
    - "workers/src/index.ts — start 2 status workers + extend SIGTERM cleanup"
  affects:
    - "Plan 36-03 (route hooks + server wiring) — sẽ gọi registerStatusTickRepeatJob() từ server.ts startup + closeLgspStatusQueue() từ SIGTERM"
    - "Plan 36-04 (UI Timeline) — không phụ thuộc trực tiếp, nhưng worker là backend cho status history hiển thị thật"
    - "Plan 36-05 (E2E verification) — sẽ verify tick chạy 30s cadence + event POST /v1/updateStatus thực tế"
tech-stack:
  added: []  # No new deps — reuse BullMQ + ioredis + pg + pino từ Phase 34/35
  patterns:
    - "BullMQ Queue + 2 Worker same-queue filter by job.name (mirror Phase 35-02 tick+dn pattern)"
    - "Lazy singleton (connection + pool + eventQueue) lazy-init trong worker file cho clean stop()"
    - "Approach B duplicate (workers/ self-contained — KHÔNG import backend, inline pgp_sym_decrypt SQL + native fetch)"
    - "Per-attempt fresh credential load (D-14 — admin rotation pickup without worker restart)"
    - "Deterministic jobId 'lgsp-status-event-{outbox_id}' chặn duplicate enqueue khi tick overlap"
    - "Idempotent registerStatusTickRepeatJob (removeRepeatableByKey + add) safe restart"
key-files:
  created:
    - e_office_app_new/workers/src/queues/lgsp-status-queue.ts
    - e_office_app_new/workers/src/lgsp/lgsp-status-service.ts
    - e_office_app_new/workers/src/jobs/lgsp-status-tick-worker.ts
    - e_office_app_new/workers/src/jobs/lgsp-status-event-worker.ts
    - e_office_app_new/backend/src/lib/queue/lgsp-status-queue.ts
  modified:
    - e_office_app_new/workers/src/index.ts
decisions:
  - "D-05 honored: BullMQ repeat 30s cadence với singleton jobId 'lgsp-status-tick-singleton'"
  - "D-06 honored: per-event granularity (1 outbox row = 1 status-event job) — retry độc lập"
  - "D-07 honored: tick concurrency=1, event concurrency=5 (payload nhỏ, fast RPC)"
  - "D-09 honored: 5 attempts exponential 30s base → 30s/60s/120s/240s/480s mirror Phase 34"
  - "D-10 honored: reuse isLgspNonRetryableError() (Phase 34 error-codes.ts) — 4xx LGSP code (10/15/18-23) mark error no-retry, network/5xx throw cho BullMQ retry"
  - "D-11 honored: on('failed') listener — attemptsMade >= max → markOutboxError 'Retry exhausted (n/max): <reason>'"
  - "D-12 honored: FIFO best-effort theo created_at LIMIT 100 — tick handler enqueue child theo SP fn_lgsp_status_outbox_get_pending(100)"
  - "D-14 honored: per-attempt fresh resolveDocOwner + loadLgspCredentials trong event handler (KHÔNG cache in worker)"
  - "D-15 honored: 6 files theo spec — 4 new workers + 1 new backend producer + 1 modify workers/index.ts"
  - "Approach B ratified (Phase 34-02 → Phase 35-02 → Phase 36-02): workers self-contained, duplicate error-codes.ts từ backend, KHÔNG import qua rootDir"
metrics:
  duration: "~6.4 min (384s)"
  ts_errors_backend: 0
  ts_errors_workers: 0
  smoke_test_workers_started: "2/2 (both 'LGSP status tick worker started' + 'LGSP status event worker started' log lines present in stdout)"
  smoke_test_redis_auth: "preexisting NOAUTH error (Redis password mismatch — affects ALL Phase 34/35/36 workers identically — NOT caused by 36-02, out of scope per CLAUDE.md scope boundary rule)"
  acceptance_grep_checks_passed: 35  # 5 Task 1 + 8 Task 2 + 8 Task 3 + 7 Task 4 + 7 Task 5
  approach_b_audit_passed: true  # grep verified zero backend imports in 4 workers/ files
  commits: 5
  files_created: 5
  files_modified: 1
  completed: 2026-05-21
---

# Phase 36 Plan 36-02: BullMQ Worker Infrastructure cho Status Callback Chain Summary

**One-liner:** Wave 1 worker layer cho status callback chain — 2-worker BullMQ system trên queue `'lgsp-status'` (tick concurrency=1 repeat 30s fan-out + event concurrency=5 retry 5x exp 30s POST /v1/updateStatus), worker-local LGSP service (Approach B duplicate per Phase 34/35 ratified), backend producer queue expose 4 helper cho Plan 36-03 server.ts wiring. 6 files (5 new + 1 modify workers/index.ts). TS clean both modules. Smoke test 2/2 workers boot OK.

## What was built

### Task 1: `workers/src/queues/lgsp-status-queue.ts` (commit `25ce8e0`)

55-dòng module mirror exact Phase 35-02 `lgsp-receive-queue.ts`:

- 9 constants: `LGSP_STATUS_QUEUE_NAME='lgsp-status'`, `LGSP_STATUS_TICK_JOB_NAME='status-tick'`, `LGSP_STATUS_EVENT_JOB_NAME='status-event'`, tick concurrency=1 attempts=1, event concurrency=5 attempts=5 backoff 30_000, tick interval 30_000ms, singleton jobId `'lgsp-status-tick-singleton'`, event timeout 60s, batch size 100.
- 2 interfaces: `LgspStatusTickJobData { trigger_source?, triggered_by_staff_id? }`, `LgspStatusEventJobData { outbox_id, incoming_doc_id, unit_id, target_status, payload }`.

### Task 2: `workers/src/lgsp/lgsp-status-service.ts` (commit `a263a45`)

175-dòng worker-local HTTP client mirror `lgsp-receive-service.ts`:

- **`resolveDocOwner(pool, incomingDocId)`** — JOIN incoming_docs + lgsp_agency_config (prefer prod env), return `{unit_id, environment}` hoặc null.
- **`loadLgspCredentials(pool, unitId, env, signingKey)`** — inline `pgp_sym_decrypt(secret_key_encrypted, $3)` SELECT, throw nếu not found/inactive/placeholder. Fresh per-call (D-14 rotation pickup).
- **`updateStatus(credentials, docId, status, timeoutMs=30000)`** — `POST {baseUrl}/v1/updateStatus` JSON body `{docId, status}` + headers `Content-Type: application/json, X-SystemId, X-SecretKey, Accept: application/json`, 30s AbortController, parse JSON success → return `LgspUpdateStatusResult{success, message, errorCode}`. Throw `LgspSendError` cho network/timeout/non-JSON (BullMQ retry).

Reuse `LgspSendError` + `mapLgspError` từ `./error-codes.js` (Phase 34 duplicate). Approach B — KHÔNG import backend.

### Task 3: `workers/src/jobs/lgsp-status-tick-worker.ts` (commit `d40a821`)

211-dòng tick worker mirror `lgsp-receive-tick-worker.ts`:

- Lazy singletons: `getConnection()`, `getPool()`, `getEventQueue()` cho clean `stop()`.
- Handler: filter `if (job.name !== LGSP_STATUS_TICK_JOB_NAME) return` (same queue, different name).
- Query Phase 33 SP `SELECT * FROM edoc.fn_lgsp_status_outbox_get_pending($1)` với LIMIT 100 (D-12 FIFO).
- Batch JOIN `SELECT id, unit_id FROM edoc.incoming_docs WHERE id = ANY($1::bigint[])` để lookup `unit_id` cho event job data.
- Enqueue child `status-event` với deterministic `jobId = 'lgsp-status-event-{outbox_id}'` chặn duplicate khi tick overlap.
- `startLgspStatusTickWorker()` + `stopLgspStatusTickWorker(worker)` exports.

### Task 4: `workers/src/jobs/lgsp-status-event-worker.ts` (commit `bb0db3d`)

276-dòng event worker pattern closer to `lgsp-send-worker.ts`:

- Lazy `getConnection()` + `getPool()`.
- `markOutboxSuccess(id)` → `SELECT * FROM edoc.fn_lgsp_status_outbox_mark_sent($1, NULL)`.
- `markOutboxError(id, msg)` → `SELECT * FROM edoc.fn_lgsp_status_outbox_mark_error($1, $2, NULL)` (next_retry_at=NULL → final state, BullMQ retry mechanism độc lập).
- Handler:
  1. Re-resolve owner per-attempt (D-14) — owner missing → markError no-retry.
  2. Load credentials fresh per-attempt (D-14) — load fail → markError no-retry (admin chưa cấu hình).
  3. Extract `payload.lgsp_doc_id` (string) — missing → markError no-retry.
  4. Call `updateStatus(credentials, lgspDocId, targetStatus)`:
     - `success=true` → markSent + log success
     - `success=false` + `isLgspNonRetryableError(errorCode)` → markError no-retry (D-10 — 4xx LGSP codes 10/15/18-23)
     - `success=false` + unknown errorCode → throw `LgspSendError` → BullMQ retry
     - Catch `LgspSendError` với `isLgspNonRetryableError(err.code)` → markError no-retry
     - Catch other → log + throw → BullMQ retry
- `on('failed')` D-11: `attemptsMade >= LGSP_STATUS_EVENT_MAX_ATTEMPTS` → `markOutboxError(outboxId, 'Retry exhausted (n/max): <reason>')`. KHÔNG mark khi còn retry pending.

### Task 5: `backend/src/lib/queue/lgsp-status-queue.ts` + `workers/src/index.ts` (commit `c3fc4ca`)

**Backend producer (`lgsp-status-queue.ts`, 142 dòng)** mirror `lgsp-receive-queue.ts`:

- 8 constants (duplicated từ workers — Approach B separate module).
- 2 interfaces (mirror workers interfaces).
- Lazy `getLgspStatusQueue()` singleton với `defaultJobOptions: { removeOnComplete: 500, removeOnFail: 2000 }`.
- `enqueueStatusTick(data?)` — manual trigger (Phase 37 admin optional), trigger_source default `'manual'`.
- `registerStatusTickRepeatJob()` — idempotent: `getRepeatableJobs() → removeRepeatableByKey(r.key)` for each existing tick repeat → `add('status-tick', {trigger_source:'cron'}, { repeat: { every: 30_000 }, jobId: 'lgsp-status-tick-singleton' })`.
- `closeLgspStatusQueue()` — SIGTERM helper.

**Workers/index.ts modify (4 edit points):**

1. Import block thêm `startLgspStatusTickWorker/stopLgspStatusTickWorker` + `startLgspStatusEventWorker/stopLgspStatusEventWorker`.
2. Sau Phase 35 receive workers thêm comment block + `const lgspStatusTickWorker = startLgspStatusTickWorker(); const lgspStatusEventWorker = startLgspStatusEventWorker();`.
3. Startup log line update: thêm `'lgsp-status (Phase 36: tick + event)'`.
4. SIGTERM extend: thêm `stopLgspStatusTickWorker(lgspStatusTickWorker)` + `stopLgspStatusEventWorker(lgspStatusEventWorker)` trước Phase 34 lgsp-send stop.

## Decisions made (honored from CONTEXT)

- **D-05 (mechanism):** BullMQ `Queue.add` với `repeat: { every: 30_000 }` + singleton jobId 'lgsp-status-tick-singleton' — idempotent registration cho restart safety.
- **D-06 (granularity):** Per-event job (1 outbox row = 1 'status-event' job) — retry độc lập, FIFO best-effort.
- **D-07 (concurrency):** Tick=1 (race-safe, attempt=1 vì next 30s tick covers), Event=5 (payload ~200 bytes, fast RPC, không spam LGSP).
- **D-09 (retry):** 5 attempts exponential 30s base → 30s/60s/120s/240s/480s mirror Phase 34 send worker.
- **D-10 (classify):** Reuse `isLgspNonRetryableError(errorCode)` từ `workers/src/lgsp/error-codes.ts` Phase 34 duplicate — 9 LGSP errorCode (0/10/15/18/19/20/21/22/23) trong map → no-retry; unknown/network/5xx → retry.
- **D-11 (exhaust):** `on('failed')` listener khi `attemptsMade >= 5` → `markOutboxError(outboxId, 'Retry exhausted (5/5): <reason>')` với `next_retry_at=NULL` (final state).
- **D-12 (ordering):** FIFO best-effort theo `created_at` LIMIT 100 — Phase 33 SP đã có ORDER BY trong partial index.
- **D-14 (rotation):** Per-attempt fresh `resolveDocOwner` + `loadLgspCredentials` — admin bật/tắt credential giữa luồng được pickup ngay attempt sau.
- **D-15 (hosting):** Workers/ module — 4 new files trong `workers/src/{queues,lgsp,jobs}/lgsp-status-*` + 1 backend producer + modify workers/src/index.ts.
- **Approach B (Phase 34-02 ratified):** Workers self-contained — KHÔNG import từ backend (rootDir cascade fail). Duplicate `error-codes.ts` đã có sẵn từ Phase 34. `lgsp-status-service.ts` inline `pgp_sym_decrypt` SQL + native fetch (KHÔNG import `LGSPRealService` từ backend).

## Deviations from Plan

**None — plan executed exactly as written.**

Tất cả 5 task implement đúng skeleton trong plan (`<action>` blocks). TypeScript clean cả backend + workers ngay sau mỗi task, không cần Rule 1/2/3 auto-fix.

Minor — TS type narrowing trên `result as any`:

- Plan skeleton (Task 3 + Task 4) dùng `(result as any)?.enqueued` cho on('completed') handler — refactor thành `result as { enqueued?: number } | undefined` (Task 3) và `result as { status?: string; outbox_id?: number } | undefined` (Task 4) cho TS strict-friendly. Không thay đổi runtime behavior — chỉ avoid `any` type cast (best practice).

## Auth gates encountered

**None plan-blocking** — local Docker postgres available, không cần LGSP credential cho Wave 1 (chỉ TS check + worker boot smoke test). Plan 36-05 verification sẽ E2E POST `/v1/updateStatus` thực tế với DN.001 sandbox credential.

**Pre-existing Redis NOAUTH error trong smoke test** — Workers boot OK + tất cả 4 worker log "started" line (Phase 34 send + Phase 35 receive tick/dn + Phase 36 status tick/event đều print). Sau đó BullMQ Worker `info` command bị Redis reject NOAUTH (REDIS_PASSWORD chưa set trong workers env). Đây là pre-existing config gap KHÔNG do Plan 36-02 gây ra — same error tồn tại trong Phase 35-02 boot identical pattern. Khi Plan 36-03 wire vào backend server.ts startup + production runtime, REDIS_PASSWORD trong `.env` sẽ resolve. Out of scope per CLAUDE.md scope boundary rule (only auto-fix issues DIRECTLY caused by current task's changes).

## Verification results

### TypeScript clean
- `cd e_office_app_new/backend && npx tsc --noEmit` → exit 0 ✓
- `cd e_office_app_new/workers && npx tsc --noEmit` → exit 0 ✓

### Acceptance grep checks
- **Task 1 (5 greps):** LGSP_STATUS_QUEUE_NAME, LGSP_STATUS_TICK_INTERVAL_MS=30*1000, LGSP_STATUS_EVENT_CONCURRENCY=5, LGSP_STATUS_EVENT_MAX_ATTEMPTS=5, LgspStatusEventJobData — all exit 0 ✓
- **Task 2 (8 greps):** updateStatus, resolveDocOwner, loadLgspCredentials, /v1/updateStatus, X-SystemId, pgp_sym_decrypt + 2 implicit (X-SecretKey, JSON.stringify) — all exit 0 ✓
- **Task 3 (8 greps):** startLgspStatusTickWorker, stopLgspStatusTickWorker, fn_lgsp_status_outbox_get_pending, LGSP_STATUS_TICK_CONCURRENCY, concurrency: LGSP_STATUS_TICK_CONCURRENCY, job.name !== LGSP_STATUS_TICK_JOB_NAME, lgsp-status-event- (deterministic jobId), LGSP_STATUS_TICK_BATCH_SIZE — all exit 0 ✓
- **Task 4 (7 greps):** startLgspStatusEventWorker, stopLgspStatusEventWorker, concurrency: LGSP_STATUS_EVENT_CONCURRENCY, isLgspNonRetryableError, Retry exhausted, fn_lgsp_status_outbox_mark_sent, fn_lgsp_status_outbox_mark_error — all exit 0 ✓
- **Task 5 (7 greps):** registerStatusTickRepeatJob, enqueueStatusTick, closeLgspStatusQueue, startLgspStatusTickWorker (in index.ts), startLgspStatusEventWorker (in index.ts), stopLgspStatusTickWorker (in index.ts), stopLgspStatusEventWorker (in index.ts), 'lgsp-status (Phase 36' (in index.ts startup log) — all exit 0 ✓

### Smoke test workers boot (8s timeout)
```
{"level":30,"name":"lgsp-receive-tick-worker","msg":"LGSP receive tick worker started"}
{"level":30,"name":"lgsp-receive-dn-worker","msg":"LGSP receive DN worker started"}
{"level":30,"name":"lgsp-status-tick-worker","queue":"lgsp-status","concurrency":1,"maxAttempts":1,"msg":"LGSP status tick worker started"}
{"level":30,"name":"lgsp-status-event-worker","queue":"lgsp-status","concurrency":5,"maxAttempts":5,"msg":"LGSP status event worker started"}
```

**Both Phase 36 workers print "started" log line trước Redis NOAUTH error.** SUCCESS criterion met.

### Approach B audit (workers self-contained)
```bash
grep -l "from '../../../backend\|from '../../backend" \
  e_office_app_new/workers/src/jobs/lgsp-status-tick-worker.ts \
  e_office_app_new/workers/src/jobs/lgsp-status-event-worker.ts \
  e_office_app_new/workers/src/lgsp/lgsp-status-service.ts \
  e_office_app_new/workers/src/queues/lgsp-status-queue.ts
# → empty result (zero backend imports) ✓
```

### SP signatures verified (Phase 33 baseline)
```
fn_lgsp_status_outbox_get_pending(p_limit integer DEFAULT 10)
fn_lgsp_status_outbox_mark_error(p_id bigint, p_error_message text, p_next_retry_at timestamp with time zone)
fn_lgsp_status_outbox_mark_sent(p_id bigint, p_sent_at timestamp with time zone DEFAULT now())
```
All 3 SPs invoked correctly từ worker handlers ✓.

## Next steps (downstream Wave 2+)

- **Plan 36-03 (route hooks + server.ts wiring):**
  - Import + gọi `registerStatusTickRepeatJob()` từ `backend/src/server.ts` startup (sau register Phase 35 receive tick cron).
  - SIGTERM extend `closeLgspStatusQueue()` (sau Phase 35 closeLgspReceiveQueue).
  - Wire 6 route handlers (5 incoming-doc + 1 handling-doc) gọi `lgspStatusOutboxRepository.insertEvent({incoming_doc_id, target_status, payload})` sau SP success nếu `doc.source_type === 'external_lgsp'`.
- **Plan 36-04 (UI Timeline):**
  - Backend endpoint mới `GET /api/van-ban-den/:id/lgsp-status-history` consume `lgspStatusOutboxRepository.getDocStatusHistory()` (Phase 36-01).
  - Frontend extend Phase 35-04 detail page thêm conditional section `<Timeline>` render history.
- **Plan 36-05 (E2E verification):**
  - DN.001 sandbox active → trigger sequence (mark-read → giao-viec → but-phe → chuyen-luu-tru) → verify outbox row INSERTED → wait ≤30s tick → verify `sent_status='success'`.
  - Dedup test (UNIQUE constraint Phase 36-01).
  - Error path test (tạm UPDATE credential sai → retry exhaust → markError 'Retry exhausted').
  - UI verify section "Lịch sử trạng thái LGSP" hiển thị Timeline 4 entries với badge per sent_status.

## Self-Check: PASSED

**Files created (5):**
- `e_office_app_new/workers/src/queues/lgsp-status-queue.ts` — FOUND
- `e_office_app_new/workers/src/lgsp/lgsp-status-service.ts` — FOUND
- `e_office_app_new/workers/src/jobs/lgsp-status-tick-worker.ts` — FOUND
- `e_office_app_new/workers/src/jobs/lgsp-status-event-worker.ts` — FOUND
- `e_office_app_new/backend/src/lib/queue/lgsp-status-queue.ts` — FOUND

**Files modified (1):**
- `e_office_app_new/workers/src/index.ts` — FOUND

**Commits (5):**
- `25ce8e0` — FOUND (`feat(36-02): them workers lgsp-status queue constants + job data interfaces`)
- `a263a45` — FOUND (`feat(36-02): them workers lgsp-status-service (resolveDocOwner + loadCreds + POST /v1/updateStatus)`)
- `d40a821` — FOUND (`feat(36-02): them lgsp-status-tick-worker (concurrency=1, fan-out N status-event jobs)`)
- `bb0db3d` — FOUND (`feat(36-02): them lgsp-status-event-worker (concurrency=5, retry 5x exp, 4xx no-retry, on(failed) mark exhaust)`)
- `c3fc4ca` — FOUND (`feat(36-02): wire backend producer lgsp-status-queue + workers/index.ts lgsp-status tick + event workers`)
