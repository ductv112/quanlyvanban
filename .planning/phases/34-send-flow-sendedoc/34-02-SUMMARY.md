---
phase: 34-send-flow-sendedoc
plan: 02
subsystem: workers/lgsp + backend/queue
tags: [worker, bullmq, lgsp, queue, retry, phase-34]
requirements: [LGSP-SEND-04]

dependency_graph:
  requires:
    - phase-33 (lgsp_agency_config table + pgp_sym_decrypt + departments.lgsp_org_code)
    - phase-34-01 (edxml-builder + error-codes + LGSPRealService.sendDocument /v1/sendEdoc)
    - phase-17 (outgoing_doc_recipients + lgsp_tracking + SP fn_outgoing_doc_send_to_recipients)
    - phase-18 (BullMQ Queue infra — redis-connection helper)
  provides:
    - workers/src/queues/lgsp-send-queue.ts (queue/job name constants + LgspSendJobData interface)
    - workers/src/jobs/lgsp-send-worker.ts (BullMQ Worker handler + startLgspSendWorker/stopLgspSendWorker)
    - workers/src/lgsp/edxml-builder.ts (duplicated for workers self-containment)
    - workers/src/lgsp/error-codes.ts (duplicated for workers self-containment)
    - workers/src/lgsp/lgsp-send-service.ts (NEW — loadLgspCredentials + sendDocument for worker context)
    - backend/src/lib/queue/lgsp-send-queue.ts (producer-side Queue + enqueueLgspSendJob helper)
  affects:
    - workers/src/index.ts (REPLACED Phase 18 inline lgspSendWorker + DELETED lgspSendEdoc helper)
    - backend/src/server.ts (added closeLgspSendQueue to SIGTERM handler chain)
    - workers/tsconfig.json (NEW — standard workers-only config, rootDir default ./src)
    - workers/package.json (added xmlbuilder2 + form-data + minio + pino-pretty deps)

tech_stack:
  added:
    - xmlbuilder2@^3.1.1 (workers — duplicated edxml-builder dep)
    - form-data@^4.0.5 (workers — multipart for sendEdoc)
    - minio@^8.0.7 (workers — attachment fetch base64)
    - pino-pretty@^13.1.3 (workers — dev log formatting)
  patterns:
    - BullMQ Worker + on('failed') listener for retry-exhausted handling (CONTEXT D-13)
    - Per-attempt credential fresh-load (NO worker cache; D-14 rotation pickup)
    - Inline pg pgp_sym_decrypt for credential decryption in worker (avoid Node crypto layer)
    - Self-contained worker module (no backend imports — Approach B)
    - Job dedupe via deterministic jobId (lgsp-send-{tracking_id})

key_files:
  created:
    - e_office_app_new/workers/tsconfig.json (24 lines)
    - e_office_app_new/workers/src/queues/lgsp-send-queue.ts (57 lines)
    - e_office_app_new/workers/src/jobs/lgsp-send-worker.ts (581 lines)
    - e_office_app_new/workers/src/lgsp/edxml-builder.ts (201 lines, duplicated)
    - e_office_app_new/workers/src/lgsp/error-codes.ts (63 lines, duplicated)
    - e_office_app_new/workers/src/lgsp/lgsp-send-service.ts (216 lines, NEW worker-specific)
    - e_office_app_new/backend/src/lib/queue/lgsp-send-queue.ts (125 lines)
  modified:
    - e_office_app_new/workers/package.json (+4 deps)
    - e_office_app_new/workers/package-lock.json (lockfile)
    - e_office_app_new/workers/src/index.ts (replace inline LGSP worker + delete lgspSendEdoc helper)
    - e_office_app_new/backend/src/server.ts (SIGTERM cleanup chain)

decisions:
  - D-04 honored: Worker concurrency=3
  - D-10 honored: attempts=5, exponential backoff delay=30s -> 30/60/120/240/480s
  - D-11 honored: 4xx LGSP errorCode -> no-throw (UPDATE tracking error, BullMQ skip retry)
                  Network/5xx -> throw (BullMQ retry per backoff)
  - D-13 honored: worker.on('failed') with attemptsMade>=maxAttempts mark tracking 'Retry exhausted: <last>'
  - D-14 honored: getLgspService factory cache pattern duplicated as fresh-load-per-attempt
                  (worker DOES NOT cache credential; reads fresh from DB each attempt)
  - D-15 honored: Worker runs in workers/ module (terminal #3 dev, PM2 prod)
  - Job dedupe: jobId=lgsp-send-{tracking_id} (BullMQ skip duplicate enqueue)
  - APPROACH B chosen: Worker self-contained (duplicate LGSP modules into workers/src/lgsp/)
    instead of Approach A (import from backend). Approach A failed with cascading rootDir errors
    from transitive backend deps (redis client, jose, doc-book repo, etc).
    Trade-off documented: 3 files must stay in sync (edxml-builder + error-codes + LgspSendError class)
    Plan 34-05 will audit checksum pre-deploy.
  - Worker uses inline pg `pgp_sym_decrypt` for credential decryption (no Node crypto import)
    — SQL: pgp_sym_decrypt(secret_key_encrypted, $signing_secret_key)::text
  - Pino logger always include {recipient_id, outgoing_doc_id, tracking_id, sender_unit_id, environment}

metrics:
  duration: "~50m"
  tasks_completed: 3
  files_created: 7
  files_modified: 4
  lines_added: ~1370
  commits: 3
  ts_errors: 0
  smoke_tests_passed: 1/1
  completed_date: 2026-05-20
---

# Phase 34 Plan 02: LGSP Send Worker (BullMQ) + Backend Producer Queue Summary

**Plan 34-02:** Hoàn tất worker infra để Plan 34-03 enqueue job từ route, Plan 34-05 E2E test. Replace Phase 18 inline `lgspSendWorker` (job shape `{tracking_id, dest_org_code, edxml_content}`) bằng worker mới chấp nhận shape `LgspSendJobData` (IDs only, per-recipient granularity per CONTEXT D-02). Worker tự load doc + attachments + credential fresh per attempt qua per-unit `lgsp_agency_config` lookup (D-14). Retry 5 attempts exponential backoff 30s/60s/120s/240s/480s (D-10). 4xx LGSP no-retry, network/5xx retry (D-11). Exhausted -> mark tracking 'Retry exhausted: ...' (D-13). Backend tạo producer-side Queue helper `enqueueLgspSendJob()` để route Plan 34-03 enqueue sau khi SP commit.

## Summary

3 tasks shipped trong Wave 1 part 2 của Phase 34:

1. **Task 1 — workers/tsconfig + 3 deps + queue file (commit f5a004e):**
   - Created `workers/tsconfig.json` (workers-only standard, rootDir default ./src)
   - Added deps: `xmlbuilder2@^3.1.1`, `form-data@^4.0.5`, `minio@^8.0.7`, `pino-pretty@^13.1.3`
   - `npm install` clean (134 packages, 0 critical vulns)
   - Created `workers/src/queues/lgsp-send-queue.ts` (57 lines): 6 constants (`LGSP_SEND_QUEUE_NAME='lgsp-send'`, `LGSP_SEND_JOB_NAME='send-edoc-recipient'`, `CONCURRENCY=3`, `MAX_ATTEMPTS=5`, `BACKOFF_DELAY=30_000`, `JOB_TIMEOUT=90_000`) + `LgspSendJobData` interface (5 fields)

2. **Task 2 — Worker handler 581 lines + 3 worker-local LGSP modules (commit 0eb1852):**

   **Decision: APPROACH B (self-contained worker, duplicate modules into `workers/src/lgsp/`)** — Approach A initially attempted (extend `workers/tsconfig.json` include glob to import from `../backend/src/services/lgsp/`), but failed with cascading `rootDir` errors. Backend code imports transitively pulled in:
   - `services/lgsp-mock.service.ts` → `lib/redis/client.ts` (Redis client, KHÔNG cần worker)
   - `services/lgsp.service.ts` → `repositories/lgsp-agency-config.repository.ts` → `repositories/doc-book.repository.ts` → `lib/db/query.ts` → `lib/db/pool.ts`
   - `services/signing/crypto.ts` → jose library

   TypeScript refused these because they sit outside workers' `rootDir` even when included. Rather than further loosening rootDir (which would create a fragile setup with backend types in workers' build), reverted to clean workers-only tsconfig + duplicated 3 modules.

   **Files created:**
   - `workers/src/lgsp/error-codes.ts` (63 lines) — duplicated `LGSP_ERROR_CODES` (9 mã), `LgspSendError` class, `mapLgspError`, `isLgspNonRetryableError`
   - `workers/src/lgsp/edxml-builder.ts` (201 lines) — duplicated `buildEdxml(input)` + interfaces. Uses `xmlbuilder2`, `crypto.randomUUID`, `pino`.
   - `workers/src/lgsp/lgsp-send-service.ts` (216 lines, NEW worker-specific) — `loadLgspCredentials(pool, unitId, env, signingSecretKey)` lookup + inline `pgp_sym_decrypt` qua pg + `sendDocument(credentials, buffer, destOrgCode, docCode)` multipart `/v1/sendEdoc`. Replaces backend's per-unit factory + LGSPRealService class (worker doesn't need cache layer since per-attempt fresh load is required by D-14 anyway).
   - `workers/src/jobs/lgsp-send-worker.ts` (581 lines) — full handler:
     - Module-level singletons: `connection` (IORedis), `pool` (pg Pool max=5), `minioClient`
     - SQL helpers: `loadOutgoingDoc`, `loadRecipient`, `loadSender`, `loadDocTypeName`, `loadAttachments`, `loadAttachmentBuffer`, `updateTrackingStatus`
     - `handleSendJob(data)`: load doc/recipient/sender → defensive validation (return early + mark error for missing data) → load attachments base64 (skip-on-error per D-06, warn >5MB) → `buildEdxml()` → `loadLgspCredentials()` → `lgspSend()` → classify result + error per D-11
     - `startLgspSendWorker()` exports Worker with `concurrency: 3` + `on('completed')`, `on('failed')` (D-13 exhausted tracking error), `on('error')` listeners
     - `stopLgspSendWorker(worker)` graceful close: worker.close() + pool.end() + connection.disconnect()

3. **Task 3 — Wire workers/index.ts + backend producer + SIGTERM (commit 6a6e218):**

   **`workers/src/index.ts`:**
   - Added import `{ startLgspSendWorker, stopLgspSendWorker }` from `./jobs/lgsp-send-worker.js`
   - **DELETED** old `lgspSendWorker` inline block (35 lines, Phase 18 BROKEN job shape + endpoint)
   - **DELETED** `lgspSendEdoc()` helper (only used by old worker; uses BROKEN `/api/lgspedoc/send-edoc` endpoint)
   - Replaced with single-line invocation `const lgspSendWorker = startLgspSendWorker();`
   - Updated SIGTERM: `await stopLgspSendWorker(lgspSendWorker);` instead of `await lgspSendWorker.close();`
   - Updated startup log: `"lgsp-send (Phase 34)"`
   - **KEPT** `lgspLogin()` + `lgspReceiveList()` + `lgspReceiveWorker` (used by Phase 35 receive flow, will be refactored separately)

   **`backend/src/lib/queue/lgsp-send-queue.ts` (NEW, 125 lines):**
   - Lazy singleton `Queue<LgspSendJobData>` via `getLgspSendQueue()` (reuse `getRedisConnection()` shared)
   - `defaultJobOptions`: `attempts=5, backoff: { type: 'exponential', delay: 30000 }, removeOnComplete: {count:1000}, removeOnFail: {count:5000}`
   - `enqueueLgspSendJob(data)`: deterministic `jobId='lgsp-send-{tracking_id}'` for BullMQ dedupe
   - `closeLgspSendQueue()`: graceful close
   - Constants duplicated from workers' queue file (NOT shared — 2 module rieng)

   **`backend/src/server.ts`:**
   - Added import `closeLgspSendQueue`
   - Wired into shutdown chain: `try { await closeLgspSendQueue(); } catch (err) { ... }`

## Verification

**TypeScript strict:** PASS both modules
- `cd backend && npx tsc --noEmit` → exit 0
- `cd workers && npx tsc --noEmit` → exit 0

**Acceptance grep checks (all PASS):**
- `workers/src/queues/lgsp-send-queue.ts`: 6 constants + LgspSendJobData interface ✓
- `workers/src/jobs/lgsp-send-worker.ts` 581 lines (>= 250 target):
  - `startLgspSendWorker` exports x1 ✓
  - `stopLgspSendWorker` exports x1 ✓
  - `concurrency: LGSP_SEND_CONCURRENCY` x2 ✓
  - `buildEdxml(` x2 ✓
  - `loadLgspCredentials` x3 ✓ (replaces `getLgspService` per Approach B)
  - `isLgspNonRetryableError` x3 ✓
  - `fn_lgsp_tracking_update_status` x2 ✓
  - `worker.on('failed'` x2 ✓
  - `minioClient.getObject` x1 ✓
  - `"Retry exhausted"` x2 ✓
- `workers/src/index.ts`: `startLgspSendWorker` x2, `stopLgspSendWorker` x2, old shape `{tracking_id, dest_org_code, edxml_content}` REMOVED ✓
- `backend/src/lib/queue/lgsp-send-queue.ts` 125 lines (>= 60 target):
  - `export async function enqueueLgspSendJob` x1 ✓
  - `export function getLgspSendQueue` x1 ✓
  - `export interface LgspSendJobData` x1 ✓
  - `attempts: LGSP_SEND_MAX_ATTEMPTS` x2 ✓
  - `type: 'exponential'` x1 ✓
  - `closeLgspSendQueue` x1 ✓

**Smoke test — Worker startup:** PASS
```
[INFO] (lgsp-send-worker): LGSP send worker started
    queue: "lgsp-send"
    concurrency: 3
    maxAttempts: 5
[INFO]: Workers started: email-send, sms-send, lgsp-receive, lgsp-send (Phase 34), fcm-push, zalo-send, notification-send
```

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocker] Approach A (backend imports) abandoned due to rootDir cascade**
- **Found during:** Task 2 — initial worker handler with backend imports via `../../../backend/src/services/lgsp/...`
- **Issue:** Even with workers `tsconfig.json include` extended to backend file paths, tsc raised `error TS6059: File '...' is not under 'rootDir'`. Backend transitive imports cascaded to many more files (Redis client, jose, doc-book repository, etc.) that workers shouldn't need.
- **Fix:** Reverted `workers/tsconfig.json` to clean workers-only config (`include: ["src/**/*"]`). Duplicated `edxml-builder.ts` + `error-codes.ts` into `workers/src/lgsp/` (Approach B per Plan fallback). Created NEW worker-specific `lgsp-send-service.ts` (replaces backend's factory + LGSPRealService class) that uses inline `pgp_sym_decrypt` via worker's pg Pool instead of importing `crypto.decryptSecret` (which uses jose internally).
- **Files affected:** `workers/tsconfig.json` reverted, `workers/src/lgsp/{edxml-builder,error-codes,lgsp-send-service}.ts` created, worker imports updated
- **Trade-off documented:** 2 file backend pairs MUST stay in sync when edited. Plan 34-05 will audit checksum pre-deploy. Single source of truth lost but: (a) isolated build, (b) clean tsconfig, (c) workers don't depend on backend code paths

**2. [Rule 2 - Critical] Backend SIGTERM cleanup added for LGSP send queue**
- **Found during:** Task 3
- **Issue:** Plan said "if SIGTERM exists, add closeLgspSendQueue()". Backend already has `shutdown()` handler with `closeSigningQueue()` call — so consistent pattern requires `closeLgspSendQueue()` to be in same chain.
- **Fix:** Added import + call in SIGTERM chain after `closeSigningQueue` and before `closeRedisConnection`.
- **Files modified:** `backend/src/server.ts`

### Plan-driven changes (no deviations)

- ✓ Worker concurrency=3 exactly per CONTEXT D-04
- ✓ Retry attempts=5 + exponential backoff delay=30000ms exactly per D-10
- ✓ Per-attempt credential fresh-load (no in-worker cache) per D-14
- ✓ Job data shape exactly per CONTEXT specifics (5 fields: recipient_id, outgoing_doc_id, tracking_id, sender_unit_id, environment)
- ✓ Queue name 'lgsp-send', job name 'send-edoc-recipient'
- ✓ Vietnamese KHÔNG DẤU in logs/error messages (PowerShell 5.1 safe)
- ✓ Old worker REMOVED from workers/index.ts (verified by grep absence)
- ✓ `lgspReceiveWorker` + `lgspLogin` + `lgspReceiveList` KEPT (used by Phase 35 receive flow)

## Authentication Gates

None. Plan executed fully autonomously — Redis password loaded via env vars during smoke test (CLAUDE.md no auth prompts needed; dev defaults match docker-compose.yml + backend/.env).

## Known Stubs / Caveats

**1. Duplicated 2 files between backend + workers (Approach B trade-off)**
- `backend/src/services/lgsp/edxml-builder.ts` ←→ `workers/src/lgsp/edxml-builder.ts`
- `backend/src/services/lgsp/error-codes.ts` ←→ `workers/src/lgsp/error-codes.ts`
- ANY change in backend MUST be mirrored to workers. Plan 34-05 will add checksum audit script pre-deploy.

**2. Worker-specific `lgsp-send-service.ts` differs from backend `lgsp.service.ts` + `lgsp-real.service.ts`**
- Worker: `loadLgspCredentials(pool, unitId, env, signingSecretKey)` — pg pgp_sym_decrypt inline
- Backend: `getLgspService(unitId, env)` — repo + crypto.decryptSecret + cache
- INTENTIONAL divergence: worker is per-attempt fresh-load (D-14), backend has cache for HTTP request frequency. Keep them in sync semantically (error messages, validation logic).

**3. NO automated test for retry classification path**
- 4xx no-retry behavior + on('failed') retry-exhausted only verified by code review.
- Plan 34-05 E2E test will exercise real LGSP sandbox responses to verify classification correct.

**4. Attachment >5MB inline base64 — RAM theo dõi**
- Worker keeps full attachment buffer in memory + base64 encode in 1 chunk.
- 6 DN Lạng Sơn scale: attachments thường <5MB nên acceptable. Nếu KH gửi VB attach 50MB nhiều file → defer streaming refactor v3.3+.

## Threat Flags

None introduced by Plan 34-02. Existing surface (LGSP credential decryption) already mitigated Phase 33. Worker uses identical pgp_sym_decrypt + SIGNING_SECRET_KEY pattern as backend service factory — secret only in memory, never logged (only `'OK' / 'EMPTY'` status string in error messages).

## Next Steps

Plan 34-03: Wire `enqueueLgspSendJob()` trong route `POST /api/outgoing-doc/:id/gui-noi-bo`:
- Sau khi SP `fn_outgoing_doc_send_to_recipients` commit thành công + trả về `{internal_count, external_count}`
- Query `outgoing_doc_recipients` WHERE `outgoing_doc_id=X AND recipient_type='external_org'` để lấy danh sách (`recipient_id`, `generated_lgsp_tracking_id`)
- Resolve `environment` từ `lgsp_agency_config` per `sender_unit_id` (prefer 'prod' nếu active, else 'sandbox')
- For each external recipient: `enqueueLgspSendJob({ recipient_id, outgoing_doc_id, tracking_id, sender_unit_id, environment })`
- Response include `external_count` để frontend biết số job background đang chờ

Plan 34-04: Frontend polling badge state machine + recipients-status endpoint verify
Plan 34-05: E2E test với DN.001 sandbox + roundtrip verification

## Commits

- `f5a004e` feat(34-02): workers tsconfig + LGSP send queue constants + 3 deps
- `0eb1852` feat(34-02): LGSP send worker handler (BullMQ consumer, Approach B self-contained)
- `6a6e218` feat(34-02): wire LGSP send worker + backend producer queue + SIGTERM cleanup

## Self-Check: PASSED

**Files exist:**
- ✓ FOUND: `e_office_app_new/workers/tsconfig.json`
- ✓ FOUND: `e_office_app_new/workers/src/queues/lgsp-send-queue.ts` (57 lines)
- ✓ FOUND: `e_office_app_new/workers/src/jobs/lgsp-send-worker.ts` (581 lines)
- ✓ FOUND: `e_office_app_new/workers/src/lgsp/edxml-builder.ts` (201 lines)
- ✓ FOUND: `e_office_app_new/workers/src/lgsp/error-codes.ts` (63 lines)
- ✓ FOUND: `e_office_app_new/workers/src/lgsp/lgsp-send-service.ts` (216 lines)
- ✓ FOUND: `e_office_app_new/backend/src/lib/queue/lgsp-send-queue.ts` (125 lines)
- ✓ MODIFIED: `e_office_app_new/workers/src/index.ts` (LGSP send worker replaced, lgspSendEdoc deleted)
- ✓ MODIFIED: `e_office_app_new/workers/package.json` (4 deps added)
- ✓ MODIFIED: `e_office_app_new/backend/src/server.ts` (closeLgspSendQueue wired)

**Commits exist:**
- ✓ FOUND: f5a004e (Task 1)
- ✓ FOUND: 0eb1852 (Task 2)
- ✓ FOUND: 6a6e218 (Task 3)

**TypeScript:** Both `backend` + `workers` `npx tsc --noEmit` exit 0

**Smoke test:** PASS — "LGSP send worker started" log {queue, concurrency: 3, maxAttempts: 5}

**Acceptance:** All grep patterns from Plan verification passed (10/10 worker + 6/6 backend)
