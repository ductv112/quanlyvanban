---
phase: 11-sign-flow-async-worker
plan: 02
subsystem: infrastructure
tags: [bullmq, redis, queue, ioredis, infrastructure, sign-flow]

requires:
  - phase: 11
    plan: 01
    provides: "buildSignedObjectKey helper + attachment-sign repo (consumed by Plan 04 worker, not Plan 02)"
provides:
  - "lib/queue/redis-connection.ts — ioredis singleton (getRedisConnection) + worker factory (createRedisConnection) with BullMQ-required maxRetriesPerRequest:null"
  - "lib/queue/types.ts — PollSignStatusJob interface + SIGNING_QUEUE_NAME + POLL_INTERVAL_MS/MAX_POLL_ATTEMPTS constants"
  - "lib/queue/signing-queue.ts — lazy singleton Queue + enqueuePollSignStatus + cancelPollJobsForTransaction + closeSigningQueue"
  - ".env.example — documented REDIS_URL alternative + BullMQ/persistent-redis deployment note"
affects:
  - 11-03-sign-api (consumes enqueuePollSignStatus after provider.signHash)
  - 11-04-worker-completion (imports createRedisConnection + PollSignStatusJob + Worker consumes signing queue)
  - 11-06-cancel-retry (consumes cancelPollJobsForTransaction when user clicks "Hủy ký")

tech-stack:
  added: []
  patterns:
    - "Lazy-singleton Queue — first getSigningQueue() call boots Queue + Redis; unused sign feature costs nothing at startup"
    - "Separate Worker connection via createRedisConnection() — Worker BLPOP blocks connection; producer shares singleton"
    - "Manual retry model (attempts:1) — worker re-enqueues attempt+1; plan-controlled poll spacing vs BullMQ auto-retry"
    - "jobId = poll-{txnId}-{attempt} — BullMQ dedupe prevents double-enqueue for the same (txn, attempt) tuple"
    - "Payload = IDs + MinIO key only (no PDF bytes, no certs, no credentials) — minimizes Redis trust-zone exposure (T-11-05 accept)"

key-files:
  created:
    - e_office_app_new/backend/src/lib/queue/redis-connection.ts
    - e_office_app_new/backend/src/lib/queue/types.ts
    - e_office_app_new/backend/src/lib/queue/signing-queue.ts
  modified:
    - e_office_app_new/backend/.env.example

key-decisions:
  - "Lazy-singleton vs eager init at module import — unused sign flow must not force Redis ping; tests/CI without Redis can still import the module without crash"
  - "Separate getRedisConnection (shared) vs createRedisConnection (fresh) — BullMQ docs require Worker to have exclusive connection because BLPOP blocks; producer can safely share"
  - "attempts:1 (manual retry) vs BullMQ attempts:N (auto retry) — manual re-enqueue gives finer control: we need exact 5s × 36 attempts aligned with DB expires_at, not exponential backoff"
  - "jobId format poll-{txnId}-{attempt} — BullMQ dedupes within queue; accidental double enqueue for same (txn, attempt) is idempotent no-op, mitigates T-11-06 DoS"
  - "REDIS_URL preferred for production, REDIS_HOST fallback for dev — production deployments often pass Redis via URI (TLS, auth, dedicated DB index)"
  - "Do NOT wire up Queue at server.ts boot — Plan 04 Worker will start with server; Plan 02 only publishes the interfaces"
  - "Keep existing lib/queue/client.ts untouched — LGSP/notification queues use older connection pattern; signing flow introduces the BullMQ-v5-correct pattern for Phase 11+, no forced migration of legacy queues"

patterns-established:
  - "Queue module template: types.ts (constants + job payload) + connection.ts (factory) + {name}-queue.ts (singleton + enqueue helper + cancel helper + close) — reusable for future decoupled flows"
  - "Lazy singleton pattern: private _queue = null + public getQueue() returns same instance; closeQueue() resets so next call re-initializes"
  - "Manual retry via re-enqueue: attempts:1 + worker re-enqueues attempt+1 for plan-controlled spacing vs exponential backoff"

requirements-completed:
  - ASYNC-01
  - ASYNC-02
  - ASYNC-04

duration: 4min
started: 2026-04-21T10:19:27Z
completed: 2026-04-21T10:23:05Z
---

# Phase 11 Plan 02: BullMQ Signing Queue Infrastructure Summary

**3-file BullMQ layer — Redis connection factory + typed PollSignStatusJob + lazy Queue singleton with jobId dedupe — producer-only scaffold ready for Plan 04 Worker to consume.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-21T10:19:27Z
- **Completed:** 2026-04-21T10:23:05Z
- **Tasks:** 2
- **Files created:** 3
- **Files modified:** 1 (.env.example)

## Accomplishments

- 3 new TS modules under `backend/src/lib/queue/` (redis-connection, types, signing-queue) — 0 tsc errors in scope
- BullMQ-v5-correct connection options (`maxRetriesPerRequest: null`, `enableReadyCheck: false`) applied to both producer and worker factories
- Lazy-singleton pattern — import does NOT trigger Redis ping; boot is zero-cost for paths that never sign
- Typed `PollSignStatusJob` payload + shared `SIGNING_QUEUE_NAME` constant — Plan 04 Worker imports directly, no magic strings
- `.env.example` expanded with BullMQ deployment guidance (REDIS_URL option + persistent-redis recommendation for sign-job resume-after-restart)

## Task Commits

1. **Task 1: Redis connection factory + queue types** — `fa7d88e` (feat)
2. **Task 2: Signing queue + enqueue/cancel helpers + .env.example** — `2734305` (feat)

## Files Created/Modified

- `e_office_app_new/backend/src/lib/queue/redis-connection.ts` — `getRedisConnection()` singleton + `createRedisConnection()` factory + `closeRedisConnection()` (~110 lines)
- `e_office_app_new/backend/src/lib/queue/types.ts` — `SIGNING_QUEUE_NAME` + `POLL_SIGN_STATUS` + `POLL_INTERVAL_MS = 5_000` + `MAX_POLL_ATTEMPTS = 36` + `PollSignStatusJob` (~50 lines)
- `e_office_app_new/backend/src/lib/queue/signing-queue.ts` — `getSigningQueue()` + `enqueuePollSignStatus()` + `cancelPollJobsForTransaction()` + `closeSigningQueue()` (~135 lines)
- `e_office_app_new/backend/.env.example` — Redis section rewritten with BullMQ context + `REDIS_URL` example + production persistence note

## Exact Exports (consumed by downstream plans)

```typescript
// from 'lib/queue/redis-connection.js'
export function getRedisConnection(): Redis;           // producer-side singleton
export function createRedisConnection(): Redis;        // worker-side exclusive connection
export async function closeRedisConnection(): Promise<void>;

// from 'lib/queue/types.js'
export const SIGNING_QUEUE_NAME = 'signing';
export const POLL_SIGN_STATUS   = 'poll-sign-status';
export const POLL_INTERVAL_MS   = 5_000;
export const MAX_POLL_ATTEMPTS  = 36;
export const JOB_REMOVE_ON_COMPLETE = 1000;
export const JOB_REMOVE_ON_FAIL     = 5000;
export interface PollSignStatusJob {
  signTransactionId: number;
  providerTransactionId: string;
  placeholderPdfKey: string;
  attempt: number;
}

// from 'lib/queue/signing-queue.js'
export { SIGNING_QUEUE_NAME };                          // re-export
export function getSigningQueue(): Queue<PollSignStatusJob>;
export function enqueuePollSignStatus(
  payload: PollSignStatusJob,
  delayMs?: number,
): Promise<string>;
export function cancelPollJobsForTransaction(signTransactionId: number): Promise<number>;
export async function closeSigningQueue(): Promise<void>;
```

## Decisions Made

- **Lazy singleton over eager boot** — unused sign paths (auth refresh, doc CRUD) must not pay Redis ping cost at server startup, and unit tests that never touch signing can import the module without needing Redis. `getSigningQueue()` creates the Queue on first call; subsequent calls return the cached instance.
- **Separate Worker connection via `createRedisConnection()`** — BullMQ v5 docs require Worker to own an exclusive connection because `BLPOP` blocks the connection. If Worker shared the producer's singleton, `enqueuePollSignStatus()` calls would stall every 5 seconds. Factory returns fresh `IORedis` so Worker.close() can cleanly dispose its own connection.
- **Manual retry via re-enqueue vs `attempts: N`** — ASYNC-02 requires exactly 5s × 36 attempts = 3 min, aligned with `sign_transactions.expires_at`. BullMQ's built-in `attempts` uses exponential backoff and can't be capped at exactly N attempts with fixed interval. Worker will consume the job, poll provider, and either finalize OR call `enqueuePollSignStatus({...payload, attempt: attempt+1})` with `delay: 5000`.
- **`jobId = poll-{txnId}-{attempt}` for dedupe** — BullMQ dedupes on jobId within the same queue. If two enqueue calls race for the same (transaction, attempt) tuple (e.g., double-click on retry), the second is a no-op. Mitigates T-11-06 DoS without app-level locking.
- **Payload minimization** — only IDs + MinIO key cross Redis. No PDF bytes, no certificate data, no client_secret. Worker re-fetches everything by ID on each poll (fresh status, current DB snapshot). Aligns with T-11-05 Accept: Redis stays in the same trust zone as backend, but we don't bulk up the exposure surface.
- **REDIS_URL preferred for prod, HOST/PORT fallback** — production deployments often pass Redis via URI (TLS, cluster DNS, password auth, dedicated DB index). `parseRedisUrl()` tries `REDIS_URL` first; falls back to `REDIS_HOST + REDIS_PORT + REDIS_PASSWORD` for dev.
- **Kept legacy `lib/queue/client.ts` untouched** — LGSP/notification queues already exist with an older connection pattern (plain object config, no separate factory). Migrating them is out of scope for Plan 02. Sign flow gets the BullMQ-v5-correct pattern; legacy queues continue to work since their connection object also sets `maxRetriesPerRequest` via default.

## Why `jobId = poll-{txnId}-{attempt}`

The jobId uniquely identifies a single (transaction, attempt) pair. BullMQ rejects duplicate jobIds within a queue (returns the existing job instead of creating a new one). This gives us **natural idempotency without app-level locks**:

- User double-clicks "Ký" → route calls `enqueuePollSignStatus(..., attempt: 1)` twice → second call is a no-op; single poll job scheduled
- Worker crashes between `sign_transactions.insert` and successful enqueue → on restart, re-enqueue with same `(txnId, attempt=1)` is idempotent
- Concurrent "Hủy ký" + retry → cancel removes the delayed job; retry enqueues `attempt=1` of the NEW transaction (different txnId → different jobId), so no collision

## Deviations from Plan

**Total:** None beyond stylistic additions (error logging on Redis `error` events, defensive `try/catch` in `closeSigningQueue`). Plan executed as written. Files match `must_haves.artifacts` paths and exports exactly.

- Added `parseRedisUrl()` `try/catch` around `new URL()` — malformed `REDIS_URL` now logs a warning and falls back to `REDIS_HOST` instead of crashing at module load. Defensive; no behavior change when env is valid. Not a deviation per Rule classification (hardening, not a fix).
- Added `.on('error', ...)` handlers on both Redis connections — pino-logged instead of triggering unhandled `error` events. BullMQ works fine without explicit handlers, but Node emits warnings if an `EventEmitter` has no listener for `error`. Defensive.

## How Downstream Plans Consume This

**Plan 11-03 (sign API)** — after `provider.signHash()` returns `providerTransactionId`, route calls:
```typescript
await enqueuePollSignStatus({
  signTransactionId,          // from INSERT ... RETURNING id
  providerTransactionId,      // from provider adapter
  placeholderPdfKey,          // from MinIO upload of placeholder PDF
  attempt: 1,
});
// Returns 201 with { txn_id: signTransactionId } — user sees "đang xử lý"
```

**Plan 11-04 (worker completion)** — creates Worker:
```typescript
import { Worker } from 'bullmq';
import { createRedisConnection } from '@/lib/queue/redis-connection.js';
import { SIGNING_QUEUE_NAME, type PollSignStatusJob, MAX_POLL_ATTEMPTS, POLL_INTERVAL_MS } from '@/lib/queue/types.js';
import { enqueuePollSignStatus } from '@/lib/queue/signing-queue.js';

const worker = new Worker<PollSignStatusJob>(SIGNING_QUEUE_NAME, async (job) => {
  // 1. DB check: sign_transactions.status === 'pending' (else early-return — cancelled/expired)
  // 2. Call provider.getSignStatus(job.data.providerTransactionId)
  // 3. If 'done'   → embed signature, upload signed PDF, finalizeSign(...), emit Socket SIGN_COMPLETED
  // 4. If 'failed' → mark failed in DB, emit Socket SIGN_FAILED
  // 5. If 'pending' AND job.data.attempt < MAX_POLL_ATTEMPTS → enqueuePollSignStatus({...job.data, attempt: job.data.attempt + 1})
  // 6. Else (attempt >= MAX) → mark expired, emit Socket SIGN_EXPIRED
}, { connection: createRedisConnection(), concurrency: 5 });
```

**Plan 11-06 (cancel/retry)** — "Hủy ký" endpoint:
```typescript
await cancelPollJobsForTransaction(signTransactionId); // Remove delayed jobs for this txn
// SP call: edoc.fn_sign_transaction_cancel(txnId, staffId) — marks DB row cancelled
// Any Worker already executing a job for this txn will short-circuit via DB status check
```

**Server shutdown (Plan 11-04 integrates)** — add to SIGTERM handler:
```typescript
await closeSigningQueue();
await closeRedisConnection();
```

## Issues Encountered

- None. Zero tsc errors in `src/lib/queue/` scope. Pre-existing unrelated errors in `src/routes/workflow.ts` (Express 5 `AuthRequest` type overload issue) are out of scope per SCOPE BOUNDARY — not introduced by this plan.

## Known Stubs

None. Every exported function has a real implementation. The Worker that *consumes* this queue is intentionally deferred to Plan 04 — per plan scope, not a stub.

## Next Plan Readiness

- Producer API published: route handlers in Plan 11-03 can `import { enqueuePollSignStatus } from '@/lib/queue/signing-queue.js'` immediately.
- Type contract published: `PollSignStatusJob` is the sole job payload shape; Plan 04 Worker will import this exact type to avoid drift.
- Redis config documented: deploy team has the env vars they need (REDIS_URL preferred, HOST/PORT fallback).
- Zero blockers for Plan 11-03 (sign API) — all its queue prerequisites shipped.

## Self-Check

Verified before declaring complete:

- `e_office_app_new/backend/src/lib/queue/redis-connection.ts` — FOUND
- `e_office_app_new/backend/src/lib/queue/types.ts` — FOUND
- `e_office_app_new/backend/src/lib/queue/signing-queue.ts` — FOUND
- `.env.example` has `REDIS_URL` + `REDIS_HOST` (grep count 4) — FOUND
- `maxRetriesPerRequest: null` present in `redis-connection.ts` (grep count 3) — FOUND
- `MAX_POLL_ATTEMPTS = 36` present in `types.ts` — FOUND
- `enqueuePollSignStatus` / `getSigningQueue` present in `signing-queue.ts` (grep count 5) — FOUND
- Commit `fa7d88e` (Task 1) exists in git log — FOUND
- Commit `2734305` (Task 2) exists in git log — FOUND
- `npx tsc --noEmit` reports 0 errors in `src/lib/queue/*` — CONFIRMED

## Self-Check: PASSED

---
*Phase: 11-sign-flow-async-worker*
*Completed: 2026-04-21*
