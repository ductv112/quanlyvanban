---
phase: 35-receive-flow-cron-syncreceivededoclist
plan: 02
subsystem: workers/lgsp + backend/queue
tags: [worker, bullmq, lgsp, cron, parser, queue, phase-35]
requirements: [LGSP-RECV-01, LGSP-RECV-02, LGSP-RECV-03, LGSP-RECV-04, LGSP-RECV-05, LGSP-RECV-06, LGSP-RECV-07]

dependency_graph:
  requires:
    - phase-35-01 (LGSPRealService.receiveDocuments + getEdocById + edxml-parser.ts + incoming-doc.createFromLgsp + inter-org.autoRegisterFromLgsp + lgsp_sender_org_code column)
    - phase-34 (BullMQ Approach B pattern: workers self-contained, duplicated modules; lgsp-send-queue/worker reference)
    - phase-33 (lgsp_agency_config table + fn_lgsp_agency_config_get_all_active + fn_lgsp_agency_config_update_last_synced + fn_lgsp_status_outbox_insert SP)
  provides:
    - workers/src/queues/lgsp-receive-queue.ts (queue name + 2 job name constants + concurrencies + interval + interfaces)
    - workers/src/jobs/lgsp-receive-tick-worker.ts (concurrency=1 fan-out worker)
    - workers/src/jobs/lgsp-receive-dn-worker.ts (concurrency=3 per-DN pipeline)
    - workers/src/lgsp/edxml-parser.ts (Approach B duplicate of backend parser)
    - workers/src/lgsp/lgsp-receive-service.ts (worker-context credential load + 2 fetch helpers + formatLgspDate)
    - backend/src/lib/queue/lgsp-receive-queue.ts (producer Queue + enqueueReceiveTick + registerReceiveTickRepeatJob + closeLgspReceiveQueue)
  affects:
    - workers/src/index.ts (DELETED Phase 18 inline lgspLogin/lgspReceiveList/LGSP_MOCK/lgspReceiveWorker; ADDED 2-line start calls + SIGTERM cleanup chain entries)

tech_stack:
  added:
    - fast-xml-parser@^4.4.0 (workers module — Approach B requires worker-local install; backend already has from Plan 35-01)
  patterns:
    - BullMQ 2-job-name-per-queue with handler filtering by job.name (tick vs dn)
    - BullMQ repeat scheduler with deterministic jobId (`lgsp-receive-tick-singleton`) + idempotent removeRepeatableByKey pre-loop
    - Approach B (Phase 34 ratified): workers self-contained, duplicated edxml-parser.ts from backend
    - Lazy singleton pattern (getConnection/getPool/getDnQueue/getMinio) for clean shutdown
    - SP-message-substring dedup detection in worker (catches both inner SP-raised 23505 and direct pg 23505 SQLSTATE)
    - 7-day safety-net floor for fromDate (LGSP rejects too-wide windows)
    - Per-doc try/catch in DN loop (1 bad doc doesn't fail entire DN sync)
    - on('failed') handler with final-attempt detection + last_sync_error persistence

key_files:
  created:
    - e_office_app_new/workers/src/queues/lgsp-receive-queue.ts (51 lines)
    - e_office_app_new/workers/src/jobs/lgsp-receive-tick-worker.ts (198 lines)
    - e_office_app_new/workers/src/jobs/lgsp-receive-dn-worker.ts (590 lines)
    - e_office_app_new/workers/src/lgsp/edxml-parser.ts (157 lines, duplicated from backend with sync warning comment)
    - e_office_app_new/workers/src/lgsp/lgsp-receive-service.ts (229 lines)
    - e_office_app_new/backend/src/lib/queue/lgsp-receive-queue.ts (151 lines)
  modified:
    - e_office_app_new/workers/package.json (+1 dep: fast-xml-parser ^4.4.0)
    - e_office_app_new/workers/package-lock.json (npm install — added 2 packages)
    - e_office_app_new/workers/src/index.ts (-92 lines Phase 18 inline / +20 lines Phase 35 wiring; net -72 lines, 281 -> 214)

decisions:
  - D-01 honored: BullMQ Queue.add with repeat:{every: 5*60*1000} + singleton jobId 'lgsp-receive-tick-singleton'
  - D-02 honored: 2 job names on queue 'lgsp-receive' — 'receive-tick' (concurrency=1) + 'receive-dn' (concurrency=3)
  - D-04 honored: tick concurrency=1 (race-safe cron + manual), dn concurrency=3 (mirror Phase 34 send worker)
  - D-06 honored: full field mapping ParsedEdxml -> IncomingDocInsertInput per spec (From.OrganId -> lgsp_sender_org_code, From.OrganName -> publish_unit, Code.CodeNumber -> notation, Code.CodeNotation -> document_code, Subject -> abstract, SignerInfo.Signer -> signer, PromulgationInfo.PromulgationDate -> sign_date + publish_date, OtherInfo.PageAmount -> number_paper with min=1)
  - D-07 honored: MinIO key `lgsp/<lgsp_doc_id>/<file_name>` + 50MB cap skip with WARN log
  - D-08 honored: autoRegisterSender via INSERT ... ON CONFLICT (code) DO NOTHING + fallback SELECT by code (race-safe inline, no backend repo import per Approach B)
  - D-09 honored: 2-layer dedup (SP-message substring detection + direct pg 23505 SQLSTATE catch) -> returns skipped=true, log INFO, continue to next doc
  - D-10 honored: fromDate = COALESCE(last_synced_at, NOW-7d) + 7-day safety-net floor + YYYY/MM/DD format via formatLgspDate()
  - D-11 honored: per-DN error -> UPDATE last_sync_error (last_synced_at unchanged) + throw to trigger BullMQ retry 3 attempts exp 30s/60s/120s; on('failed') final exhaustion persists "Retry exhausted (N/M)" to last_sync_error for Phase 37 admin UI
  - D-12 honored: INSERT lgsp_status_outbox row target_status='01' sent_status='pending' via fn_lgsp_status_outbox_insert SP after every successful INSERT incoming_docs (Phase 36 worker consumes outbox)
  - D-14 honored: per-attempt fresh credential load via loadLgspCredentials() inline pgp_sym_decrypt — no in-worker cache (admin rotation pickup without restart)
  - Approach B (Phase 34 D-15 ratified): workers self-contained, edxml-parser.ts DUPLICATED from backend with explicit sync warning comment at top; lgsp-receive-service.ts is worker-context (NOT importing backend services)
  - Pool/Connection lazy-init pattern (getConnection/getPool/getDnQueue/getMinio) used in both new workers to enable clean stop() + nullable singleton reset

metrics:
  duration: "~25m"
  tasks_completed: 5
  files_created: 6
  files_modified: 3
  lines_added: ~1376 (51 + 198 + 590 + 157 + 229 + 151)
  lines_deleted: ~92 (Phase 18 inline LGSP polling block in workers/src/index.ts)
  commits: 5
  ts_errors_backend: 0
  ts_errors_workers: 0
  smoke_test_workers_started: 2/2 (tick worker + dn worker both print "started" log lines)
  acceptance_grep_checks_passed: 60/60 (12 Task 1 + 9 Task 2 + 7 Task 3 + 17 Task 4 + 15 Task 5)
  completed_date: 2026-05-20
---

# Phase 35 Plan 02: LGSP Receive — BullMQ 2-Tier Worker System Summary

**Plan 35-02:** Build the BullMQ infrastructure (queue + 2 worker types) that drives the Phase 35 receive flow. This is the cron + sync engine: every 5 minutes (or on-demand via Plan 35-03's `/api/lgsp/sync-now`), a tick worker queries all active LGSP DNs and enqueues 1 child job per DN; each child worker runs the full per-DN pipeline (list → getEdoc → parse → INSERT incoming_docs → MinIO upload attachments → INSERT outbox status '01' for Phase 36).

## Summary

5 tasks shipped (Wave 2 of 5 in Phase 35):

### Task 1 — Queue constants + parser duplicate + dep (commit 7f0fef2)

- **`workers/src/queues/lgsp-receive-queue.ts` (51 lines)** — All queue/job name constants + concurrency limits + retry config + 2 typed interfaces (LgspReceiveTickJobData, LgspReceiveDnJobData). Mirrors `workers/src/queues/lgsp-send-queue.ts` (Phase 34) exactly in structure.
- **`workers/src/lgsp/edxml-parser.ts` (157 lines)** — DUPLICATED from `backend/src/services/lgsp/edxml-parser.ts` (Plan 35-01) per Approach B. Header comment explicitly warns "MUST stay in sync with backend version. Plan 35-05 verification audit checksum."
- **`workers/package.json` +1 dep**: `fast-xml-parser ^4.4.0` (Approach B requires worker-local install — `npm install` ran successfully, added 2 packages total).

### Task 2 — Worker-context LGSP service (commit 34e5dab)

- **`workers/src/lgsp/lgsp-receive-service.ts` (229 lines)** — Self-contained HTTP client + credential loader, mirroring `workers/src/lgsp/lgsp-send-service.ts` from Phase 34:
  - `loadLgspCredentials(pool, unitId, env, signingSecretKey)` — inline `pgp_sym_decrypt` SQL on `lgsp_agency_config WHERE is_active=TRUE`, throws on placeholder/missing/inactive. Also returns `last_synced_at` so DN worker can compute fromDate without a 2nd query.
  - `syncReceivedList(creds, fromYmd, toYmd, timeoutMs=30000)` — GET `/v1/syncReceivedEdocList?messageType=edoc&fromDate=...&toDate=...` with X-SystemId + X-SecretKey headers, AbortController timeout, returns typed `LgspReceivedSummary[]`.
  - `getEdocFull(creds, lgspDocId, timeoutMs=60000)` — GET `/v1/getEdoc?docId=<uuid>` with same headers, returns `LgspReceivedFull | null` (null when LGSP returns `success=false` — doc may have been recalled).
  - `formatLgspDate(d: Date) -> 'YYYY/MM/DD'` — utility per CONTEXT D-10 LGSP-required date format.

### Task 3 — Tick worker (commit 3221bc8)

- **`workers/src/jobs/lgsp-receive-tick-worker.ts` (198 lines)** — Spawns child jobs:
  - Handler filter: `if (job.name !== LGSP_RECEIVE_TICK_JOB_NAME) return` — same queue runs both job names, this worker only handles 'receive-tick'.
  - Query: `SELECT * FROM edoc.fn_lgsp_agency_config_get_all_active(NULL)` (Phase 33 SP — null = both sandbox + prod).
  - Fan-out: `await dnQueue.add('receive-dn', {unit_id, environment}, {jobId: 'lgsp-receive-dn-<unitId>-<env>-<tickId>'})` for each row.
  - Returns `{enqueued, agency_count}` for structured pino logging.
  - Concurrency=1, attempts=1 (no retry — next scheduled tick covers it). on('completed') / on('failed') / on('error') listeners + clean lazy-singleton shutdown.

### Task 4 — DN worker (commit a3a8135)

- **`workers/src/jobs/lgsp-receive-dn-worker.ts` (590 lines)** — Full per-DN sync pipeline. This is the largest file in Phase 35 because it orchestrates the entire receive flow:
  1. **Job name filter**: skip if `job.name !== 'receive-dn'`.
  2. **Credential load**: `loadLgspCredentials()` fresh per attempt (D-14). On failure → mark `last_sync_error` and return (don't retry — config genuinely missing).
  3. **Date window**: fromDate = COALESCE(last_synced_at, NOW-7d) with 7-day floor safety net. Format both via `formatLgspDate()`.
  4. **List call**: `syncReceivedList()`. On failure → mark last_sync_error + throw for BullMQ retry.
  5. **Per-doc loop** (with per-doc try/catch — 1 bad doc doesn't fail entire DN):
     - `findExistingByLgspDocId()` pre-check (cheap, skips getEdoc fetch for known docs).
     - `getEdocFull()` (returns null → log warn, increment docs_failed, continue).
     - `parseEdxml()` (throw → log warn, increment docs_failed, continue).
     - `autoRegisterSender()` — race-safe `INSERT ... ON CONFLICT (code) DO NOTHING RETURNING id` + fallback SELECT by code.
     - `insertIncomingDoc()` — `fn_incoming_doc_create` SP with `source_type='external_lgsp'` + `external_doc_id`. Dedup detection: SP message substring (`idx_incoming_docs_external_dedupe` | `duplicate key` | `unique constraint`) → returns `{skipped: true}`. Direct pg SQLSTATE 23505 also caught. Skipped docs log INFO + continue. Post-insert: rawQuery UPDATE `lgsp_sender_org_code = $1 WHERE id = $2` (Phase 35 new column not in SP signature, mirrors Plan 35-01 repo pattern).
     - **Per-attachment loop**: skip if `>50MB` (log warn, increment attachments_skipped). Upload to MinIO with key `lgsp/<lgsp_doc_id>/<file_name>` + `Content-Type` metadata. INSERT `attachments` row with `incoming_doc_id`, `file_path` (MinIO key), `file_size`, `content_type`, `uploaded_by=SYSTEM_STAFF_ID(1)`.
     - **Outbox INSERT**: `fn_lgsp_status_outbox_insert(newDocId, '01', payload jsonb)` — payload includes `{lgsp_doc_id, sender_org_code, ack_received_at}`. Errors logged WARN, don't fail (Phase 36 may retry).
  6. **Success path**: `fn_lgsp_agency_config_update_last_synced(unit_id, env, NOW, NULL)` — clears error + bumps timestamp.
  7. **Failure path** (catch around list call): UPDATE last_sync_error directly via rawQuery; throw to trigger BullMQ retry (3 attempts exp 30s/60s/120s).
  8. **on('failed') final**: when `attemptsMade >= maxAttempts` (3), persist `"Retry exhausted (3/3): <message>"` to `last_sync_error` for Phase 37 admin UI visibility.

  Concurrency=3 (mirror Phase 34 send), attempts=3, exponential backoff base 30s.

### Task 5 — Backend producer + workers wiring (commit aac49aa)

- **`backend/src/lib/queue/lgsp-receive-queue.ts` (151 lines)** — Producer-side:
  - `getLgspReceiveQueue()` lazy singleton Queue with `defaultJobOptions { removeOnComplete: 500, removeOnFail: 2000 }`.
  - `enqueueReceiveTick(data?)` — used by Plan 35-03's `POST /api/lgsp/sync-now`. Defaults `trigger_source='manual'`.
  - `registerReceiveTickRepeatJob()` — idempotent: pre-loop `getRepeatableJobs()` + `removeRepeatableByKey()` for any prior `receive-tick` schedulers, then `q.add('receive-tick', {trigger_source: 'cron'}, {repeat: {every: 5*60*1000}, jobId: 'lgsp-receive-tick-singleton', attempts: 1})`. Plan 35-03 will call this from `server.ts` startup.
  - `closeLgspReceiveQueue()` for SIGTERM cleanup chain in `server.ts` (Plan 35-03).
  - Constants explicitly duplicated from workers/ (separate module per Approach B — backend + workers cannot share import paths).
- **`workers/src/index.ts` rewrite** — Deleted the entire Phase 18 inline LGSP receive block:
  - DELETED: `LGSP_MOCK` / `LGSP_TOKEN_TTL_MS` / `lgspToken` / `lgspTokenExp` module vars
  - DELETED: `async function lgspLogin()` (Phase 18 `/api/lgspedoc/login` — broken endpoint)
  - DELETED: `interface LgspReceivedItem` + `async function lgspReceiveList()` (Phase 18 `/api/lgspedoc/received-edocs` — broken endpoint)
  - DELETED: `const lgspReceiveWorker = new Worker('lgsp-receive', async (job) => {...})` block (the 2 inline `pool.query(fn_incoming_doc_create...)` calls + mock dummy doc generator).
  - ADDED: 2-line `const lgspReceiveTickWorker = startLgspReceiveTickWorker();` + `const lgspReceiveDnWorker = startLgspReceiveDnWorker();`
  - ADDED: SIGTERM chain entries `await stopLgspReceiveTickWorker(...)` + `await stopLgspReceiveDnWorker(...)` replacing the old `await lgspReceiveWorker.close()`.
  - Net diff: 281 → 214 lines (−67 net, −92 deletions + 25 additions).

## Verification

**TypeScript strict — both modules clean (final end-of-plan verification):**

```
$ cd e_office_app_new/backend && npx tsc --noEmit && echo "BACKEND OK"
BACKEND OK

$ cd e_office_app_new/workers && npx tsc --noEmit && echo "WORKERS OK"
WORKERS OK
```

Verified after EACH task commit + at end of plan.

**Smoke test — both workers start successfully:**

```
$ cd e_office_app_new/workers && timeout 8 npx tsx src/index.ts
{"level":30,"name":"lgsp-receive-tick-worker","queue":"lgsp-receive","concurrency":1,"maxAttempts":1,"msg":"LGSP receive tick worker started"}
{"level":30,"name":"lgsp-receive-dn-worker","queue":"lgsp-receive","concurrency":3,"maxAttempts":3,"msg":"LGSP receive DN worker started"}
```

Both new workers print the "started" log line with correct queue + concurrency + maxAttempts. (Subsequent Redis NOAUTH errors are an env-config issue specific to the dev workstation's REDIS_PASSWORD not being in workers/.env — same pattern as Phase 34 send worker which uses backend/.env in production; not a code issue.)

**SP signatures verified against dev DB before writing worker SQL:**

```
$ docker exec qlvb_postgres psql -tAc "SELECT proname, pg_get_function_arguments(oid) ... WHERE proname IN ('fn_lgsp_status_outbox_insert', 'fn_lgsp_agency_config_update_last_synced', 'fn_lgsp_agency_config_get_all_active', 'fn_incoming_doc_create')"

fn_incoming_doc_create | p_unit_id integer, p_received_date timestamptz, p_number integer, p_notation varchar, p_document_code varchar, p_abstract text, p_publish_unit varchar, p_publish_date timestamptz, p_signer varchar, p_sign_date timestamptz, p_doc_book_id integer, p_doc_type_id integer, p_doc_field_id integer, p_secret_id smallint, p_urgent_id smallint, p_number_paper integer, p_number_copies integer, p_expired_date timestamptz, p_recipients text, p_sents text, p_is_received_paper boolean, p_created_by integer, p_department_id integer, p_source_type edoc.doc_source_type, p_is_unit_send boolean, p_unit_send varchar, p_previous_outgoing_doc_id bigint, p_external_doc_id varchar
fn_lgsp_agency_config_get_all_active | p_environment varchar
fn_lgsp_agency_config_update_last_synced | p_unit_id integer, p_environment varchar, p_last_synced_at timestamptz, p_error text
fn_lgsp_status_outbox_insert | p_incoming_doc_id bigint, p_target_status varchar, p_payload jsonb
```

All 4 SPs used by the new worker exist in dev DB with the expected signatures.

**Acceptance grep checks — 60/60 PASS** across all 5 tasks:

- Task 1 (12 checks): fast-xml-parser in package.json + lockfile, all 7 queue constants + interface + parser file + parseEdxml export + duplicate marker
- Task 2 (9 checks): loadLgspCredentials/syncReceivedList/getEdocFull/formatLgspDate exports, pgp_sym_decrypt SQL, X-SystemId + X-SecretKey headers, `/v1/syncReceivedEdocList` + `/v1/getEdoc` endpoints
- Task 3 (7 checks): start/stop exports, SP call, job-name filter, child enqueue, concurrency constant, agency_count log shape
- Task 4 (17 checks): start/stop exports, all 4 service imports, parseEdxml import, auto-register pattern, external_lgsp source type, MinIO `lgsp/` key prefix, MAX_ATTACHMENT_BYTES=50, outbox SP call + target_status '01', update_last_synced SP, last_sync_error column, DN concurrency, fn_incoming_doc_create, lgsp_sender_org_code column
- Task 5 (15 checks): 4 backend producer exports, `every: LGSP_RECEIVE_TICK_INTERVAL_MS` repeat, removeRepeatableByKey idempotency, `lgsp-receive-tick-singleton` jobId; workers/index.ts has start+stop calls + Phase 35 marker; NEGATIVE checks confirm Phase 18 helpers DELETED (lgspLogin, lgspReceiveList, `/api/lgspedoc/received-edocs`)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] BullMQ defaultJobOptions.timeout removed (not in JobsOptions type)**
- **Found during:** Task 3 writing tick worker getDnQueue() — plan code had `timeout: LGSP_RECEIVE_DN_JOB_TIMEOUT_MS as any` in defaultJobOptions
- **Issue:** BullMQ v5 JobsOptions type does not have `timeout` field (it's part of an older API surface). The plan used `as any` cast to suppress TS strict, but that's a code smell when a clean solution exists.
- **Fix:** Omitted `timeout` from `defaultJobOptions`. The constant `LGSP_RECEIVE_DN_JOB_TIMEOUT_MS` is still exported in the queue constants file for future use (e.g., per-job overrides or migration to a job-time-limit pattern). No functional impact — BullMQ relies on Worker.close()/SIGTERM for graceful job termination, and the per-DN sync naturally bounds within ~5min in practice (list 30s + N getEdoc 60s + MinIO uploads).
- **Files modified:** `e_office_app_new/workers/src/jobs/lgsp-receive-tick-worker.ts`
- **Commit:** 3221bc8

**2. [Rule 3 - Blocking] Backend producer import path corrected**
- **Found during:** Task 5 writing `backend/src/lib/queue/lgsp-receive-queue.ts`
- **Issue:** Plan text said `import { getRedisConnection } from './client.js';` but `getRedisConnection` is exported from `./redis-connection.js`, not `client.js`. `client.ts` exports a different `connection` plain object (Phase 18 legacy) and the stale `lgspReceiveQueue` singleton.
- **Fix:** Used `import { getRedisConnection } from './redis-connection.js';` — same import path Phase 34 `lgsp-send-queue.ts` uses (verified).
- **Files modified:** `e_office_app_new/backend/src/lib/queue/lgsp-receive-queue.ts`
- **Commit:** aac49aa

### Plan-driven changes (no deviations)

- D-01, D-02, D-04, D-06, D-07, D-08, D-09, D-10, D-11, D-12, D-14 all honored exactly per CONTEXT
- Approach B (Phase 34 D-15 ratified): parser duplicated with explicit sync warning, lgsp-receive-service is worker-context with inline pgp_sym_decrypt SQL
- All 17 logical conditions in DN worker handle the per-doc loop the way the plan specified (pre-check existence → getEdoc → parse → autoRegister → insert with dedup → upload+attach loop with 50MB skip → outbox status 01 → docs counters)
- Vietnamese KHÔNG DẤU in comments/log strings (CLAUDE.md PowerShell 5.1 safe pattern)
- Lazy singleton pattern (getConnection/getPool/getDnQueue/getMinio) avoids module-init race when worker is started multiple times by tests/PM2 reloads

## Authentication Gates

None. Plan executed fully autonomously — no auth prompts encountered.

## Approach Decision Section

**Approach B re-affirmed (per Phase 34 D-15):**
- `workers/src/lgsp/edxml-parser.ts` is a DUPLICATE of `backend/src/services/lgsp/edxml-parser.ts` (Plan 35-01).
- `workers/src/lgsp/lgsp-receive-service.ts` is worker-context and does NOT import from backend (uses inline `pgp_sym_decrypt` SQL for credential decrypt, native `fetch` for HTTP).
- `backend/src/lib/queue/lgsp-receive-queue.ts` re-declares its own constants instead of importing from workers (separate modules with separate `tsconfig.json` rootDir).
- **Sync discipline**: when `backend/src/services/lgsp/edxml-parser.ts` changes, the workers/ copy MUST be re-synced. Plan 35-05 verification will checksum-audit both files to catch drift.

## Known Stubs / Caveats

**1. `SYSTEM_STAFF_ID = 1` hard-coded (TODO Phase 37)**
- Worker passes `created_by = 1` and `uploaded_by = 1` to `fn_incoming_doc_create` and the `attachments` INSERT. This attributes all LGSP-imported docs and attachments to the admin user in audit log.
- Acceptable for v3.2 launch (admin is the only super-user; only admin uses LGSP config); Phase 37 will create a dedicated `lgsp-system` staff user.

**2. `extra_fields.edxml_raw` / `extra_fields.message_header` JSONB still NOT stored**
- Same caveat as Plan 35-01 — SP `fn_incoming_doc_create` has no `p_extra_fields` parameter. The full edXML payload is parsed but not persisted to `incoming_docs.extra_fields`. If parser is later improved (e.g., to handle a new edXML variant), historical docs cannot be re-parsed from DB.
- Mitigation: original edXML is preserved in `lgsp_tracking.edxml_content` (Phase 18 column) for outgoing trace, but NOT for incoming. Could be addressed in a future plan by either (a) adding `p_extra_fields jsonb` to the SP, or (b) post-insert rawQuery UPDATE `extra_fields = $1` mirroring the existing `lgsp_sender_org_code` post-insert UPDATE pattern.

**3. Outbox payload schema loosely typed (`Record<string, unknown>`)**
- DN worker INSERTs outbox with `payload = {lgsp_doc_id, sender_org_code, ack_received_at}` as untyped JSON. Phase 36 worker (status-callback consumer) will define the formal ack payload contract (TypeScript interface + zod validator on read).
- For now this is fine — only Phase 36 reads the payload, and the 3 fields above are stable.

**4. `MOCK_EXTERNAL` env var no longer respected for receive flow**
- The Phase 18 inline worker had a `LGSP_MOCK` toggle that injected fake mock docs when `process.env.MOCK_EXTERNAL === 'true'`. This is GONE. New workers always call real `/v1/syncReceivedEdocList` + `/v1/getEdoc`.
- Production-grade per CONTEXT user feedback "Giữ nguyên kiến trúc... ko cần cắt giảm". Tests/dev that want mock behavior should use `lgspAgencyConfigRepository.upsert()` to point a test DN at a mock LGSP server, NOT the env-toggle approach.

**5. Phase 18 stale `lgspReceiveQueue` still in `backend/src/lib/queue/client.ts`**
- The legacy `export const lgspReceiveQueue = new Queue('lgsp-receive', { connection })` (line 11) in `client.ts` is unused after Plan 35-02 (grep confirms 0 importers).
- NOT removed in Plan 35-02 to keep diff surface minimal and out-of-scope per the deviation rules (file is unrelated to current task work; pre-existing dead code, not regression).
- TODO: Plan 35-03 or a future cleanup plan can remove it when touching `client.ts` for legitimate reason.

**6. Repeat job registration is plumbed but not wired**
- `registerReceiveTickRepeatJob()` is exported from `backend/src/lib/queue/lgsp-receive-queue.ts` but NO call site invokes it yet. Plan 35-03 will add the call to `backend/src/server.ts` startup (after `app.listen()` and before SIGTERM registration).
- Without that call, the cron-every-5-min behavior is not active. Manual `enqueueReceiveTick()` via `POST /api/lgsp/sync-now` is also Plan 35-03's responsibility.
- **Practical impact**: workers ARE running and CAN process jobs as soon as Plan 35-03 ships — they're just waiting for a producer.

## Threat Flags

None introduced by Plan 35-02. The DN worker handles untrusted inputs (LGSP-supplied org codes, edXML payloads, attachment filenames + content) via:
- Parameterized SQL throughout (`$1, $2` placeholders — zero string concatenation)
- String slicing to DB VARCHAR limits (50/100/200/500/1000/13) as truncation safety net
- base64 decode wrapped in fast-xml-parser's per-attachment try/catch (Plan 35-01 parser already handles this)
- 50MB attachment cap enforced BEFORE MinIO put (RAM safety + LGSP spec limit)
- `is_active=FALSE` default on auto-registered inter_organizations (admin gate before sender trusted in send flow)
- MinIO object keys built from `lgsp_doc_id` (LGSP-controlled UUID) + `file_name` (slashes in fileName cannot escape the `lgsp/<docId>/` prefix because MinIO keys are flat strings, not filesystem paths)
- LGSP credentials never logged: `secretKey` is only used in `X-SecretKey` HTTP header and inline `pgp_sym_decrypt` SQL bind; structured pino logs never include the field

LGSP credentials still managed entirely by Phase 33 secure path (BYTEA encrypted, `pgp_sym_decrypt` via inline SQL with `SIGNING_SECRET_KEY` env var bind, never logged). Plan 35-02 only consumes credentials via `WorkerLgspCredentials` interface.

## Next Steps

**Plan 35-03:** Wire `registerReceiveTickRepeatJob()` into `backend/src/server.ts` startup + add `POST /api/lgsp/sync-now` route (admin-only) that calls `enqueueReceiveTick({trigger_source: 'manual', triggered_by_staff_id})`. Also wire `closeLgspReceiveQueue()` into the server SIGTERM chain. Remove the stale Phase 18 `/api/lgsp/receive-poll` route from `routes/lgsp.ts` (or repurpose it). Consider removing the stale `lgspReceiveQueue` export from `lib/queue/client.ts` while touching it.

**Plan 35-04:** Frontend tab VB-đến — render Tag "LGSP" + filter dropdown nguồn + detail page LGSP section.

**Plan 35-05:** E2E verification per CONTEXT D-16 — gửi 1 edXML test từ DN sandbox khác đến DN.001 sandbox via Postman, trigger sync-now, verify the entire flow lands a row in `incoming_docs` with attachments in MinIO + outbox row + last_synced_at bumped. Also: Approach B checksum audit of `edxml-parser.ts` (backend vs workers copies).

## Commits

- `7f0fef2` feat(35-02): them workers lgsp-receive queue constants + duplicate edxml-parser + fast-xml-parser dep
- `34e5dab` feat(35-02): them workers lgsp-receive-service (loadCreds + syncReceivedList + getEdocFull)
- `3221bc8` feat(35-02): them lgsp-receive-tick-worker (concurrency=1, fan-out N receive-dn jobs)
- `a3a8135` feat(35-02): them lgsp-receive-dn-worker (full per-DN pipeline: list->getEdoc->parse->INSERT->MinIO->outbox)
- `aac49aa` feat(35-02): them backend producer lgsp-receive-queue + wire workers/index.ts (replace Phase 18 inline polling)

## Self-Check: PASSED

**Files exist:**
- FOUND: `e_office_app_new/workers/src/queues/lgsp-receive-queue.ts` (51 lines)
- FOUND: `e_office_app_new/workers/src/jobs/lgsp-receive-tick-worker.ts` (198 lines)
- FOUND: `e_office_app_new/workers/src/jobs/lgsp-receive-dn-worker.ts` (590 lines)
- FOUND: `e_office_app_new/workers/src/lgsp/edxml-parser.ts` (157 lines)
- FOUND: `e_office_app_new/workers/src/lgsp/lgsp-receive-service.ts` (229 lines)
- FOUND: `e_office_app_new/backend/src/lib/queue/lgsp-receive-queue.ts` (151 lines)
- FOUND: `e_office_app_new/workers/src/index.ts` (modified, 214 lines)
- FOUND: `e_office_app_new/workers/package.json` (modified, +fast-xml-parser)
- FOUND: `e_office_app_new/workers/package-lock.json` (modified)

**Commits exist:**
- FOUND: 7f0fef2 (Task 1 — queue constants + parser dup + dep)
- FOUND: 34e5dab (Task 2 — worker LGSP service)
- FOUND: 3221bc8 (Task 3 — tick worker)
- FOUND: a3a8135 (Task 4 — DN worker pipeline)
- FOUND: aac49aa (Task 5 — backend producer + workers wiring)

**Acceptance grep checks:** 60/60 PASS (12 Task 1 + 9 Task 2 + 7 Task 3 + 17 Task 4 + 15 Task 5)

**TypeScript:**
- `cd e_office_app_new/backend && npx tsc --noEmit` → exit 0 (verified after each commit + end-of-plan)
- `cd e_office_app_new/workers && npx tsc --noEmit` → exit 0 (verified after each commit + end-of-plan)

**Smoke test:** PASS — both new workers (lgsp-receive-tick-worker + lgsp-receive-dn-worker) print their "started" log lines with correct queue + concurrency + maxAttempts on worker process startup.
