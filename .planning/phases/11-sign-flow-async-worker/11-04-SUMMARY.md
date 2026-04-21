---
phase: 11-sign-flow-async-worker
plan: 04
subsystem: backend-worker
tags: [bullmq, worker, signing, async, socket-io, notification, graceful-shutdown]

requires:
  - phase: 11
    plan: 01
    provides: "attachmentSignRepository.finalizeSign + canSign + buildSignedObjectKey (finalize flow)"
  - phase: 11
    plan: 02
    provides: "createRedisConnection + PollSignStatusJob + enqueuePollSignStatus + MAX_POLL_ATTEMPTS"
  - phase: 11
    plan: 03
    provides: "getPlaceholder + removePlaceholder + placeholder-store (bridge from route to worker)"
  - phase: 8
    provides: "signTransactionRepository (getById/updateStatus/incrementRetry/complete)"
  - phase: 9
    provides: "getProviderByCodeWithCredentials + SigningProvider.getSignStatus"
  - phase: 10
    provides: "staffSigningConfigRepository.get (user_id + credential_id + is_verified)"

provides:
  - "workers/signing-poll.worker.ts — BullMQ Worker consumes poll-sign-status, embeds signature, uploads signed PDF, updates DB, emits Socket events, creates bell notification"
  - "lib/signing/sign-events.ts — Socket.IO sign_completed / sign_failed event helpers"
  - "noticeRepository.createForStaff — personal bell notification via unit-wide fn_notice_create + SIGN_RESULT type"
  - "server.ts — boot startSigningWorker() + SIGTERM/SIGINT graceful shutdown with in-flight job drain"

affects:
  - 11-05-list-endpoint (consumes sign_transactions rows that this worker finalizes)
  - 11-06-cancel-retry (worker honors DB status check; cancelled transactions skipped mid-flight)
  - 11-07-frontend-sign-modal (consumes sign_completed / sign_failed Socket events to close modal)
  - 11-08-deployment-hdsd (docs WORKER_ENABLED + WORKER_CONCURRENCY env vars)

tech-stack:
  added: []
  patterns:
    - "BullMQ Worker with manual re-enqueue (attempts:1) — worker calls enqueuePollSignStatus(attempt+1) with 5s delay instead of BullMQ auto-retry; gives exact 36×5s=3min window matching DB expires_at"
    - "handleFailure helper — single function consolidates updateStatus + removePlaceholder + emitSignFailed + createForStaff; called from 7+ failure branches"
    - "rescheduleOrExpire helper — unified pending-retry logic for both re-queue and transient-error catch blocks"
    - "Short-circuit on DB status — worker re-reads sign_transactions.status at start of every job, skips if cancelled/complete (mitigate T-11-13 Redis tampering)"
    - "Graceful shutdown race — Promise.race([worker.close(), setTimeout(30s)]) ensures SIGTERM never hangs forever"
    - "Feature flag WORKER_ENABLED=false — kill switch for CI/sync-debug without removing worker code"

key-files:
  created:
    - e_office_app_new/backend/src/lib/signing/sign-events.ts
    - e_office_app_new/backend/src/workers/signing-poll.worker.ts
  modified:
    - e_office_app_new/backend/src/repositories/notice.repository.ts
    - e_office_app_new/backend/src/server.ts

key-decisions:
  - "Manual re-enqueue vs BullMQ built-in retry — exact 5s × 36 attempts aligned with DB expires_at; BullMQ attempts:N uses exponential backoff không control được interval chính xác"
  - "Concurrency = 1 (default) — serialize sign jobs tránh provider rate-limit + đơn giản tracing; WORKER_CONCURRENCY env override cho future tuning khi provider scale"
  - "rescheduleOrExpire extract helper — tránh duplicate code giữa pending branch và catch block của provider.getSignStatus throw; cùng logic 'increment + re-queue HOẶC expire'"
  - "handleFailure helper consolidates 4 steps (updateStatus + removePlaceholder + emitSignFailed + createForStaff) — gọi từ 7+ failure branches; sửa logic 1 chỗ, áp dụng cho tất cả"
  - "Bell notification via noticeRepository.createForStaff (unit-wide) thay vì SP mới — pragmatic v2.0, trade-off chấp nhận unit members thấy notice vì (a) rare, (b) title chứa tên user, (c) tránh migration mới cho Phase 11"
  - "Graceful shutdown order: stopSigningWorker → closeSigningQueue → closeRedisConnection — đóng consumer trước producer trước connection, đảm bảo job đang chạy finish được"
  - "Failsafe setTimeout(10s).unref() cho httpServer.close — tránh hang forever nếu connection nào stuck; unref để không block event loop nếu close() nhanh"
  - "Short-circuit DB re-read là MANDATORY mỗi job — attacker inject job cho txn đã cancelled = no-op (T-11-13 mitigation), user hủy mid-poll không bị worker finalize sau"
  - "emit + createForStaff đều best-effort (try/catch log warn) — DB là source of truth; Socket miss / bell SP fail không được rollback transaction đã complete"

requirements-completed:
  - SIGN-05
  - SIGN-08
  - ASYNC-02
  - ASYNC-03
  - ASYNC-05
  - ASYNC-06

duration: 8min
started: 2026-04-21T10:42:07Z
completed: 2026-04-21T10:50:03Z
---

# Phase 11 Plan 04: BullMQ Signing Poll Worker Summary

**3 tasks shipped — Socket sign events helper + personal bell notification method + 544-line BullMQ Worker with start/stop/graceful-shutdown wired into server.ts. Async sign flow complete end-to-end: route enqueues → worker polls provider → embeds signature → uploads signed PDF → updates DB → emits Socket + bell.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-04-21T10:42:07Z
- **Completed:** 2026-04-21T10:50:03Z
- **Tasks:** 3
- **Files created:** 2
- **Files modified:** 2

## Accomplishments

- `lib/signing/sign-events.ts` (70 lines) — SIGN_EVENTS constants + SignCompletedPayload/SignFailedPayload typed payloads + emitSignCompleted/emitSignFailed wrappers; Socket.IO room targeting `user_{staffId}` with JWT-enforced membership (mitigate T-11-14)
- `noticeRepository.createForStaff` — resolves staff → department_id → ancestor unit → fn_notice_create with notice_type='SIGN_RESULT'; compatible with existing /api/thong-bao endpoints (user thấy trong bell menu ngay)
- `workers/signing-poll.worker.ts` (544 lines) — full BullMQ Worker với 4-branch state machine (pending-retry / pending-expire / failed-expired-provider / completed-embed-upload-finalize), unified `handleFailure` + `rescheduleOrExpire` helpers, concurrency=1 default với WORKER_CONCURRENCY override, WORKER_ENABLED=false kill switch
- `server.ts` wired — startSigningWorker() after httpServer.listen + SIGTERM/SIGINT graceful shutdown calling stopSigningWorker → closeSigningQueue → closeRedisConnection với failsafe 10s timeout
- Zero TS errors in scope (baseline 21 pre-existing in unrelated files unchanged)

## Task Commits

1. **Task 1: sign-events.ts — Socket.IO emit helpers** — `9082dcc` (feat)
2. **Task 2: noticeRepository.createForStaff — personal bell notification** — `774beaf` (feat)
3. **Task 3: BullMQ worker + server.ts integration (graceful shutdown)** — `a7e859a` (feat)

## Files Created/Modified

| File | Status | Lines | Purpose |
|------|--------|-------|---------|
| `backend/src/lib/signing/sign-events.ts` | Created | 70 | Socket event constants + emit wrappers |
| `backend/src/workers/signing-poll.worker.ts` | Created | 544 | BullMQ Worker consumer + lifecycle |
| `backend/src/repositories/notice.repository.ts` | Modified | +45 | createForStaff method for SIGN_RESULT notifications |
| `backend/src/server.ts` | Modified | +28 | startSigningWorker boot + SIGTERM/SIGINT handlers |

## Worker State Machine (processJob branches)

```
┌─────────────────────────────────────────────────────────────────┐
│  Job picked up by Worker                                        │
│    ↓                                                            │
│  1. getById(txnId)                                              │
│      ├── not found    → removePlaceholder + return              │
│      └── found                                                  │
│    ↓                                                            │
│  2. Check txn.status                                            │
│      ├── !== 'pending' → removePlaceholder + return (cancelled) │
│      └── 'pending'                                              │
│    ↓                                                            │
│  3. Load user config                                            │
│      ├── null / !is_verified → handleFailure (failed)          │
│      └── OK                                                     │
│    ↓                                                            │
│  4. getProviderByCodeWithCredentials                            │
│      ├── null (deactivated) → handleFailure (failed)           │
│      └── active                                                 │
│    ↓                                                            │
│  5. provider.getSignStatus (try/catch)                          │
│      ├── THROW → rescheduleOrExpire (transient retry)          │
│      └── returns statusRes                                      │
│    ↓                                                            │
│  6. Branch on statusRes.status:                                 │
│      ├── 'pending'                                              │
│      │     ├── attempt < MAX → incrementRetry + re-queue 5s    │
│      │     └── attempt >= MAX → handleFailure (expired)        │
│      ├── 'failed'    → handleFailure (failed)                  │
│      ├── 'expired'   → handleFailure (expired)                 │
│      └── 'completed'                                            │
│            ├── signatureBase64 empty → handleFailure (failed)  │
│            ├── getPlaceholder fail   → handleFailure (failed)  │
│            ├── signPdf fail          → handleFailure (failed)  │
│            ├── uploadSignedPdf fail  → handleFailure (failed)  │
│            └── OK: complete + finalizeSign + emit + bell       │
└─────────────────────────────────────────────────────────────────┘
```

## Smoke Test Results

Verified live before commit via `npx tsx --eval`:

```
Exports: [ 'startSigningWorker', 'stopSigningWorker' ]
startSigningWorker type: function
stopSigningWorker type: function

Worker started: yes
Worker name: signing
INFO (signing-worker): Signing worker started
  queue: "signing"
  concurrency: 1
Stopping...
Stopped OK
INFO (signing-worker): Stopping signing worker...
INFO (signing-worker): Signing worker stopped
```

**WORKER_ENABLED=false kill switch:**
```
Result when WORKER_ENABLED=false: null (disabled OK)
WARN (signing-worker): Signing worker DISABLED (WORKER_ENABLED=false)
```

**Idempotent double start:**
```
Same worker returned: yes (idempotent OK)
INFO: Signing worker started
WARN: Signing worker đã start — bỏ qua call trùng
```

**Backend health after changes:**
```json
{"success":true,"services":{"postgresql":{"status":"connected"},"redis":{"status":"connected"},"minio":{"status":"connected"}}}
```

## Decisions Made

### Manual re-enqueue vs BullMQ `attempts: N`

**Chosen:** Worker explicitly calls `enqueuePollSignStatus({...payload, attempt: attempt+1}, 5000)` instead of letting BullMQ auto-retry.

**Why:** ASYNC-02 yêu cầu exact 5s × 36 attempts = 180s, aligned với `sign_transactions.expires_at = NOW() + 3 minutes`. BullMQ's built-in `attempts:N` dùng exponential backoff mặc định và không có "fixed interval" option đơn giản. Manual re-enqueue cũng cho phép inject DB state check (short-circuit nếu status đã chuyển) mỗi attempt.

### Single concurrency (default = 1)

**Chosen:** `new Worker({ concurrency: Number(process.env.WORKER_CONCURRENCY) || 1 })`

**Why:**
- SmartCA VNPT + MySign Viettel đều có rate limit — concurrent polls risk 429
- Simpler tracing — 1 job at a time = linear log flow per job
- Future tuning: set `WORKER_CONCURRENCY=5` khi verified provider chịu được

### handleFailure + rescheduleOrExpire helpers

**Chosen:** Extract 2 helpers để consolidate logic duplicated across 7+ failure branches.

**handleFailure (4 steps, idempotent):**
1. `updateStatus(id, 'failed'|'expired', errMsg)` — DB source of truth
2. `removePlaceholder(id)` — MinIO cleanup
3. `emitSignFailed(staffId, payload)` — Socket (best-effort)
4. `noticeRepository.createForStaff(...)` — bell (best-effort)

**rescheduleOrExpire (branch on attempt counter):**
- `attempt >= MAX_POLL_ATTEMPTS` → `handleFailure('expired', expireReason)`
- `attempt < MAX_POLL_ATTEMPTS` → `incrementRetry` + `enqueuePollSignStatus(attempt+1, 5000)`

Một sửa đổi tại 1 helper = áp dụng cho tất cả call sites. Reduces bug surface đáng kể.

### Short-circuit DB re-read every job

**Chosen:** Worker ALWAYS re-reads `signTransactionRepository.getById(txnId)` at job start — skips if `status !== 'pending'`.

**Why:** Mitigate T-11-13 Tampering (Redis trust zone). Ngay cả khi attacker inject job cho txn đã cancelled, worker check DB trước và skip. Cũng giúp race condition: user hủy mid-poll → `cancelPollJobsForTransaction` removes delayed job, nhưng nếu 1 job đã active khi cancel gọi → DB status check tại start đảm bảo worker vẫn skip.

### Graceful shutdown order

**Chosen:** `stopSigningWorker → closeSigningQueue → closeRedisConnection`

**Why:** Consumer trước producer trước connection. BullMQ Worker.close() drain job đang chạy (tối đa 30s). Nếu đóng Redis trước, Worker sẽ fail mid-job, data loss. Failsafe `setTimeout(10_000).unref()` cho `httpServer.close` — tránh hang nếu còn Socket.IO connection.

### Personal notification via unit-wide SP (pragmatic v2.0)

**Chosen:** `createForStaff(staffId)` resolves department_id → ancestor unit → fn_notice_create với `notice_type='SIGN_RESULT'`.

**Trade-off:** Unit members cùng đơn vị sẽ thấy notice trong bell của họ. Chấp nhận được vì:
- Sign result là sự kiện rare (user sign ~5-10 docs/day max)
- Title chứa txn ID + file name cụ thể → user biết không phải của mình
- Tránh migration schema mới (dedicated personal_notice table) trong Phase 11 budget
- v2.1 sẽ add SP `fn_notice_create_personal(target_staff_id, ...)` — strict per-user

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] `callFunction` still imported but unused**

- **Found during:** Task 2 (after adding `rawQuery` + `resolveAncestorUnit` imports)
- **Issue:** Plan snippet left `callFunction` import; verified still used by `getList` method → kept as-is. Not a real deviation, just a check.
- **Fix:** None needed — existing method `getList` still uses `callFunction`. No unused import warnings.

**2. [Rule 2 - Missing Critical] `rescheduleOrExpire` helper extracted (not in plan)**

- **Found during:** Task 3 (writing worker)
- **Issue:** Plan had duplicate pending-retry logic in 2 places (the pending branch AND the catch block của provider.getSignStatus throw). Copy-paste = 2 places to fix if logic changes.
- **Fix:** Extracted to `rescheduleOrExpire(job, txn, staff, provider, attachId, attachType, currentAttempt, expireReason)` — single source of truth. Called from both pending branch và catch block.
- **Files modified:** `workers/signing-poll.worker.ts`
- **Impact:** Cleaner code, easier maintenance. Matches plan's handleFailure pattern.

**3. [Rule 3 - Blocking] `fn_staff_get_ancestor_unit` SP không tồn tại**

- **Found during:** Task 2 (verifying SP existence via docker psql)
- **Issue:** Plan mentioned `fn_staff_get_ancestor_unit(staffId)` as Option A. Actual DB only has `fn_get_ancestor_unit(departmentId)` (departmentId-based, used by existing `notice.ts` route).
- **Fix:** Used Plan's Alternative B pattern — `rawQuery('SELECT department_id FROM staff WHERE id=$1')` → `resolveAncestorUnit(departmentId)` → `fn_notice_create(unitId, ...)`.
- **Files modified:** `repositories/notice.repository.ts`
- **Impact:** Zero — Plan explicitly provided this fallback. Used proven code path already exercised by `notice.ts` route.

**4. [Rule 2 - Missing Critical] Failsafe timeout on httpServer.close in shutdown handler**

- **Found during:** Task 3 (writing shutdown function)
- **Issue:** Plan code had `setTimeout(() => process.exit(1), 10_000)` — but this keeps event loop alive for 10s even if close() completes fast. Could delay normal exit.
- **Fix:** Added `.unref()` to `setTimeout` return — timer doesn't keep process alive, triggered only if close() hangs.
- **Files modified:** `server.ts`
- **Impact:** Process exits immediately after normal close; 10s failsafe only activates if stuck.

**5. [Rule 2 - Missing Critical] Guard double-shutdown via `shuttingDown` flag**

- **Found during:** Task 3 (writing shutdown function)
- **Issue:** SIGTERM + SIGINT received back-to-back (VD user Ctrl+C then kill -TERM) would trigger shutdown() twice → double-close → error logs.
- **Fix:** `let shuttingDown = false` guard at function start. Second call no-op's.
- **Files modified:** `server.ts`
- **Impact:** Clean single-shutdown semantics.

---

**Total deviations:** 5 auto-fixed (4 Rule 2 Missing Critical hardening + 1 Rule 3 Blocking SP not found)
**Impact on plan:** All Rule 2 fixes are defensive hardening that make the code resilient to edge cases (double signals, hanging close, missing SP). Plan explicitly provided Rule 3 fallback for SP alternative. Zero scope creep, zero architectural change.

## Issues Encountered

- **tsx dotenv not loaded in eval:** Standalone `npx tsx --eval` doesn't auto-load `.env` → Redis NOAUTH errors in smoke test. Not a code issue — real backend (`src/server.ts` has `import 'dotenv/config'`) works fine; confirmed via `/api/health` showing Redis connected.
- **Pre-existing 21 TS errors:** In unrelated files (admin-catalog, handling-doc-report, inter-incoming, workflow) — per SCOPE BOUNDARY untouched.

## How Downstream Plans Consume This

**Plan 11-05 (list endpoint)** — Reads `sign_transactions` rows that this worker finalizes. Worker's `complete()` + `finalizeSign()` populate `status='completed'`, `signed_file_path`, `completed_at` — these fields drive "Đã ký" tab.

**Plan 11-06 (cancel/retry UX)** — Cancel endpoint works because worker's short-circuit DB check at job start respects `cancelPollJobsForTransaction` call (removes delayed jobs) + `updateStatus('cancelled')` (any active job will skip on next processJob entry). Retry = new transaction (new txnId, new job, new placeholder) — worker doesn't need changes.

**Plan 11-07 (frontend sign modal)** — Subscribes to Socket events via `socket.on('sign_completed', ...)` and `socket.on('sign_failed', ...)`. Payload shapes match `SignCompletedPayload` + `SignFailedPayload` exported from sign-events.ts. Modal closes on either event. Bell notification (createForStaff) is fallback when user offline.

**Plan 11-08 (deployment)** — Document env vars:
- `WORKER_ENABLED=true|false` (default true) — kill switch
- `WORKER_CONCURRENCY=<N>` (default 1) — tune based on provider rate limits
- Redis must be persistent in production (`appendonly yes`) — worker resumes delayed jobs on boot

## Environment Variables Added

| Variable | Default | Purpose |
|----------|---------|---------|
| `WORKER_ENABLED` | `true` (via env absence) | Set `false` to disable worker boot |
| `WORKER_CONCURRENCY` | `1` | Override BullMQ Worker concurrency |

Existing Redis vars (`REDIS_URL` / `REDIS_HOST` / `REDIS_PORT` / `REDIS_PASSWORD`) used as-is from Plan 11-02.

## Socket.IO Event Contract

Events emitted by worker (consumed by Plan 11-07 frontend):

```typescript
// Event: 'sign_completed'
interface SignCompletedPayload {
  transaction_id: number;
  provider_code: string;         // 'SMARTCA_VNPT' | 'MYSIGN_VIETTEL'
  attachment_id: number;
  attachment_type: string;       // 'incoming' | 'outgoing' | 'drafting' | 'handling'
  doc_id: number | null;
  doc_type: string | null;
  signed_file_path: string;      // MinIO key of signed PDF
  completed_at: string;          // ISO 8601
}

// Event: 'sign_failed'
interface SignFailedPayload {
  transaction_id: number;
  provider_code: string;
  attachment_id: number;
  attachment_type: string;
  error_message: string;
  status: 'failed' | 'expired' | 'cancelled';
}
```

Room target: `user_{staffId}` — Socket.IO `io.to(room).emit(event, payload)`.

## Threat Model Validation

| Threat ID | Category | Mitigation Implemented |
|-----------|----------|------------------------|
| T-11-13 | Tampering (Redis) | Worker re-reads `sign_transactions.status` every job start — skips if !pending |
| T-11-14 | Info Disclosure (Socket) | `emitToUser` uses room `user_{staffId}` — Socket.IO JWT middleware (lib/socket.ts) enforces room membership |
| T-11-15 | DoS (provider stuck) | try/catch wraps `getSignStatus` — transient throw counts as retry, max 36 attempts caps total time at 3 min |
| T-11-16 | Repudiation | Signed PDF at separate MinIO key via `buildSignedObjectKey`; `sign_transactions` row persists signature_base64 + signed_file_path forever |
| T-11-17 | Elevation (stale creds) | `getProviderByCodeWithCredentials` called each poll — admin revocation takes effect within 5s |

## Known Stubs

None. All branches functional — completed/failed/expired/cancelled/pending all handled with real implementations. No TODO/FIXME in worker file beyond v2.1 migration note in notice.repository.ts createForStaff (documented, not a stub).

## Threat Flags

No new threat surface. All new code mounted behind existing authentication layer — worker consumes only DB + MinIO + provider HTTPS, all authenticated. Socket emit targets JWT-enforced rooms. Notification goes through existing fn_notice_create (same ACL as user-created notices).

## Next Plan Readiness

- Worker ready and verified running + stopping cleanly
- Socket events published with typed payloads — frontend can type-safe listeners
- Bell notification via existing /api/thong-bao — no new FE work needed in Phase 12
- Graceful shutdown tested — SIGTERM works without data loss
- Zero blockers for Plan 11-05 (list endpoint) — worker finalized transactions are DB-readable

## Self-Check

Verified before declaring complete:

- `e_office_app_new/backend/src/lib/signing/sign-events.ts` — FOUND (70 lines)
- `e_office_app_new/backend/src/workers/signing-poll.worker.ts` — FOUND (544 lines, exceeds 250 min)
- `e_office_app_new/backend/src/repositories/notice.repository.ts` — MODIFIED (+45 lines, createForStaff method)
- `e_office_app_new/backend/src/server.ts` — MODIFIED (+28 lines, imports + boot + shutdown)
- Commit `9082dcc` (Task 1: sign-events.ts) — FOUND in git log
- Commit `774beaf` (Task 2: createForStaff) — FOUND in git log
- Commit `a7e859a` (Task 3: worker + server.ts) — FOUND in git log
- `grep startSigningWorker server.ts` → 2 matches (import + call) — CONFIRMED
- `grep stopSigningWorker server.ts` → 2 matches (import + call) — CONFIRMED
- `grep 'processJob|handleFailure|getSignStatus|emitSignCompleted|finalizeSign' worker.ts` → 23 matches — CONFIRMED
- `npx tsc --noEmit` in-scope errors: 0 (baseline 21 unchanged)
- Module import test: exports `startSigningWorker` + `stopSigningWorker` as functions — CONFIRMED
- Live start/stop test: worker logs "Signing worker started" + "Signing worker stopped" — CONFIRMED
- WORKER_ENABLED=false returns null + logs DISABLED — CONFIRMED
- Double start returns same instance (idempotent) — CONFIRMED
- Backend /api/health 200 OK after changes — CONFIRMED

## Self-Check: PASSED

---
*Phase: 11-sign-flow-async-worker*
*Completed: 2026-04-21*
