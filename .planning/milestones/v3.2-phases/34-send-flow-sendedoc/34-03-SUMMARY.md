---
phase: 34-send-flow-sendedoc
plan: 03
subsystem: backend/route + repository (LGSP send enqueue wire)
tags: [backend, route, enqueue, lgsp, bullmq, phase-34]
requirements: [LGSP-SEND-03, LGSP-SEND-04]

dependency_graph:
  requires:
    - phase-34-01 (services/lgsp/error-codes.ts + edxml-builder.ts + sendDocument fix)
    - phase-34-02 (backend/lib/queue/lgsp-send-queue.ts + workers/jobs/lgsp-send-worker.ts)
    - phase-17 (SP fn_outgoing_doc_send_to_recipients + outgoing_doc_recipients.generated_lgsp_tracking_id)
  provides:
    - outgoingDocRepository.getExternalRecipientsForSend(docId) → list { recipient_id, tracking_id } external pending
    - Route POST /api/van-ban-di/:id/gui-noi-bo extended → enqueue 1 BullMQ job per external recipient after SP commit
    - Response shape: { internal_count, external_count, enqueued_count, [enqueue_errors] }
  affects:
    - Frontend Plan 34-04 sẽ dùng `enqueued_count` để quyết định polling badge state
    - Worker Plan 34-02 sẽ consume jobs enqueue từ route này (Plan 34-05 E2E test)

tech_stack:
  added:
    - (none — pure wire-up using existing producer queue from Plan 34-02)
  patterns:
    - rawQuery helper for cross-cutting ad-hoc SELECT (BIGINT → Number wrap)
    - Per-recipient try/catch (1 enqueue fail không drag batch)
    - Outer try/catch resolve+enqueue chain (Redis down → log + return success, tracking pending intact)
    - pino structured logger `route-outgoing-doc-lgsp`
    - Environment via env var LGSP_DEFAULT_ENVIRONMENT (default 'prod', override 'sandbox' for dev/test)

key_files:
  created: []
  modified:
    - e_office_app_new/backend/src/repositories/outgoing-doc.repository.ts (added rawQuery import + getExternalRecipientsForSend method, +34 lines)
    - e_office_app_new/backend/src/routes/outgoing-doc.ts (added enqueueLgspSendJob + pino imports, extended POST /:id/gui-noi-bo with enqueue logic, +65 lines)

decisions:
  - D-01 honored: Async — route enqueue after SP commit success, return 200 ngay với external_count + enqueued_count
  - D-02 honored: Job granularity per recipient (1 doc N external = N jobs), per-recipient try/catch
  - D-03 honored: Enqueue **after** DB commit success (await sendToRecipients trả success → THEN loop enqueue)
  - D-14 honored: Environment passed via jobData (resolved ở producer side, not worker — worker dùng env trong loadLgspCredentials)
  - Sender unit resolution: dùng `resolveAncestorUnit(departmentId)` (helper đã có từ Phase 19+), KHÔNG tạo helper mới
  - Failure mode: enqueue fail (Redis down hoặc resolveAncestorUnit fail) → log error pino + return success (tracking rows đã pending, admin Phase 37 retry sau)
  - Response shape: thêm `enqueued_count` + optional `enqueue_errors` để Frontend Plan 34-04 hiển thị status

metrics:
  duration: "~5m"
  tasks_completed: 3
  files_modified: 2
  files_created: 0
  lines_added: ~99
  commits: 2 (Task 3 smoke-only — no source change)
  ts_errors: 0
  smoke_tests_passed: 3/3
  completed_date: 2026-05-20
---

# Phase 34 Plan 03: Wire LGSP Send Enqueue trong Route /:id/gui-noi-bo

**Plan 34-03:** Hoàn tất producer-side wire để worker Phase 34-02 consume job thật từ user action. Route `POST /api/van-ban-di/:id/gui-noi-bo` sau khi SP `fn_outgoing_doc_send_to_recipients` commit success → query danh sách external recipients vừa được SP tạo `lgsp_tracking` pending → enqueue 1 BullMQ job per recipient qua `enqueueLgspSendJob()` (Plan 34-02 producer helper). Repository thêm method `getExternalRecipientsForSend(docId)` để route dùng.

## Summary

3 tasks shipped trong Wave 2 của Phase 34:

1. **Task 1 — Repository method `getExternalRecipientsForSend(docId)` (commit 6f8ccf7):**
   - Added `rawQuery` to existing `callFunction, callFunctionOne` import (`outgoing-doc.repository.ts` line 1)
   - New method (line 240-263) queries `edoc.outgoing_doc_recipients`:
     - `WHERE outgoing_doc_id = $1 AND recipient_type = 'external_org' AND generated_lgsp_tracking_id IS NOT NULL AND sent_status = 'pending'`
     - Returns `Array<{ recipient_id: number; tracking_id: number }>`
     - Wrap `Number()` cast for BIGINT (CLAUDE.md pitfall #9 — pg driver returns BIGINT as string)
   - Internal recipients skip (SP sets `sent_status='sent'` for those — already handled)

2. **Task 2 — Route POST /:id/gui-noi-bo extended (commit 2ac0890):**
   - Added imports: `enqueueLgspSendJob` from `../lib/queue/lgsp-send-queue.js`, `pino`
   - Added module-level `lgspLogger = pino({ name: 'route-outgoing-doc-lgsp' })`
   - Route handler (line 718-806) extended:
     - Call SP via `sendToRecipients()` — unchanged
     - **NEW:** If `external_count > 0`:
       - Resolve `senderUnitId = await resolveAncestorUnit(departmentId)` (existing helper từ Phase 19+)
       - Resolve `environment: 'sandbox' | 'prod'` — default `'prod'`, override via `process.env.LGSP_DEFAULT_ENVIRONMENT === 'sandbox'`
       - Loop `recipients = await outgoingDocRepository.getExternalRecipientsForSend(docId)`:
         - Per-recipient `try { await enqueueLgspSendJob({...}) } catch { enqueueErrors++; log }`
       - Outer try/catch wraps resolve+enqueue chain — Redis down → log + continue to return success
     - Response: `{ message, internal_count, external_count, enqueued_count, [enqueue_errors] }`

3. **Task 3 — Integration smoke test (NO source change):**
   - Backend `npx tsc --noEmit`: exit 0
   - Backend `npm run build`: exit 0
   - Dist artifacts present: `dist/routes/outgoing-doc.js`, `dist/lib/queue/lgsp-send-queue.js`, `dist/repositories/outgoing-doc.repository.js`
   - Dynamic import smoke test:
     ```
     enqueueLgspSendJob: function
     getLgspSendQueue: function
     LGSP_SEND_QUEUE_NAME: lgsp-send
     LGSP_SEND_JOB_NAME: send-edoc-recipient
     LGSP_SEND_MAX_ATTEMPTS: 5
     getExternalRecipientsForSend: function
     sendToRecipients: function
     ```
   - Backend health endpoint `GET /api/health` → 200 OK với services connected (postgresql, redis, minio)

## Verification

**TypeScript strict:** PASS — `cd e_office_app_new/backend && npx tsc --noEmit` exit 0

**Build:** PASS — `npm run build` produces all 3 affected dist files

**Acceptance grep checks:**
- `outgoing-doc.repository.ts`:
  - `import { callFunction, callFunctionOne, rawQuery }` ✓
  - `async getExternalRecipientsForSend(` ✓
  - `recipient_type = 'external_org'` ✓
  - `generated_lgsp_tracking_id IS NOT NULL` ✓
  - `sent_status = 'pending'` ✓
  - `Number(r.recipient_id)`, `Number(r.tracking_id)` ✓ (BIGINT cast)
- `outgoing-doc.ts` route:
  - `import { enqueueLgspSendJob }` ✓
  - `const lgspLogger = pino(...)` ✓
  - `await enqueueLgspSendJob({` ✓
  - `recipient_id: r.recipient_id` ✓
  - `tracking_id: r.tracking_id` ✓
  - `sender_unit_id: senderUnitId` ✓
  - `environment` (in job data + log) ✓
  - `getExternalRecipientsForSend` ✓
  - `enqueued_count: enqueuedCount` ✓
  - `resolveAncestorUnit(departmentId)` ✓ (existing helper reused)

**Dynamic import smoke (Node ESM):**
```
enqueueLgspSendJob: function          ← Plan 34-02 producer reachable
getLgspSendQueue: function            ← Plan 34-02 lazy singleton reachable
LGSP_SEND_QUEUE_NAME: lgsp-send       ← constant match
LGSP_SEND_JOB_NAME: send-edoc-recipient
LGSP_SEND_MAX_ATTEMPTS: 5             ← matches worker config
getExternalRecipientsForSend: function ← NEW method exposed
sendToRecipients: function            ← unchanged, still present
```

**Backend smoke start (with existing dev process running on :4000):**
```
GET http://localhost:4000/api/health → 200
Body: { success: true, services: { postgresql: connected, redis: connected, minio: connected, ... } }
```
TSX watch auto-reloaded our modified files (no manual restart needed in dev mode).

## Deviations from Plan

### Auto-fixed Issues

None. Plan executed exactly as written.

### Plan-driven changes (no deviations)

- ✓ Task 1: `rawQuery` import added (file đã không có sẵn) — plan đã anticipate trong action steps
- ✓ Task 2: `resolveAncestorUnit(departmentId)` reused (đã có ở line 12 import); KHÔNG cần tạo helper inline recursive query mới như fallback trong plan
- ✓ Per-recipient + outer try/catch pattern exactly per CONTEXT D-02 spirit
- ✓ Environment default 'prod' + LGSP_DEFAULT_ENVIRONMENT override exactly per plan
- ✓ Vietnamese KHÔNG dấu trong pino log messages (CLAUDE.md PowerShell 5.1 safe pattern)
- ✓ BIGINT → Number wrap (CLAUDE.md pitfall #9)
- ✓ SP `fn_outgoing_doc_send_to_recipients` NOT modified (CONTEXT canonical_refs honored)

## Authentication Gates

None. Plan executed fully autonomously. Backend started with existing dev process (port 4000 conflict warning ignored — running instance with tsx watch auto-reloaded our changes).

## Known Stubs / Caveats

**1. Sender unit resolution depends on `resolveAncestorUnit(departmentId)` helper semantics**
- Helper looks up `public.fn_get_ancestor_unit(p_department_id)` SP. For 6 DN Lạng Sơn architecture (top-level departments ARE root units per CONTEXT and project memory), this should return the user's root unit_id correctly. Verify in Plan 34-05 E2E that for văn thư DN.001 user → returns 1 (DN.001 root unit id).
- If helper returns wrong unit (e.g., sub-department instead of root), worker `loadLgspCredentials` will fail lookup → tracking marked error. Plan 34-05 sandbox test will catch this.

**2. Per-DN environment resolution simplified to env var default**
- Plan original D-14 noted "resolve environment from lgsp_agency_config.is_active per (unit, env)". This plan simplifies to env var (`LGSP_DEFAULT_ENVIRONMENT`) because:
  - Dev/test: all 6 DN use sandbox (set env var once, all enqueue go sandbox)
  - Prod: all 6 DN use prod (default 'prod', env var unset)
  - If KH wants mixed (e.g., DN.001 sandbox + DN.002 prod simultaneously) → defer Phase 35+ refactor to query `lgsp_agency_config` per `senderUnitId`
- Worker `loadLgspCredentials(pool, unitId, env, signingSecretKey)` accepts env arg → if config row missing for that env, lookup throws → worker marks tracking error (D-11 no-retry classification handled in worker Plan 34-02)

**3. Outer try/catch swallows resolveAncestorUnit errors silently**
- If `resolveAncestorUnit()` fails (e.g., department deleted, DB connection issue), the chain fails and external_count > 0 jobs are NOT enqueued — but tracking rows remain pending forever (no retry path until Phase 37 admin "Gửi lại").
- Acceptable for Phase 34 scope (rare edge case for 6 DN small scale). Phase 37 admin retry will cover.

**4. No HTTP integration test for enqueue path**
- Triggering full request needs: auth token + setup user văn thư + create VB with external recipient + bấm Gửi. Defer to Plan 34-05 E2E test với DN.001 sandbox.
- Smoke test verifies static reachability (export + TS + build + health) only.

## Threat Flags

None introduced by Plan 34-03. Existing surfaces unchanged:
- Route auth: `loadDocAndPerms` + `perms.canSend` permission check (Phase 17 existing pattern)
- SP commit before enqueue (D-03) — tracking rows transactionally consistent
- Job data IDs only (no sensitive payload) — worker reloads doc + decrypts credential per attempt
- LGSP credential never logged (only `recipient_id`, `tracking_id`, `sender_unit_id`, `environment` in pino logs)

## Next Steps

**Plan 34-04 (Frontend polling badge):**
- Page VB đi chi tiết extend recipients panel with 4-state badge (CONTEXT D-17)
- Hook `useRecipientsPolling(outgoingDocId, enabled)` polling `GET /api/outgoing-doc/:id/recipients-status` every 10s when `enqueued_count > 0`
- Stop polling when all recipients reach terminal state (sent/error)

**Plan 34-05 (E2E sandbox test):**
- DN.001 sandbox active, set `LGSP_DEFAULT_ENVIRONMENT=sandbox` in `.env`
- Văn thư DN.001 tạo VB đi với 3 internal + 2 external (H37.DN.002 + H37.DN.003 sandbox)
- Bấm Gửi → response `{ internal_count: 3, external_count: 2, enqueued_count: 2 }`
- Wait worker (~30-60s) → SELECT lgsp_tracking → 2 rows status='success' + lgsp_doc_id populated
- UI badge: 3 green "Đã gửi nội bộ" + 2 green "Đã gửi LGSP ✓"

## Commits

- `6f8ccf7` feat(34-03): them outgoing-doc repo method getExternalRecipientsForSend
- `2ac0890` feat(34-03): extend POST /:id/gui-noi-bo enqueue LGSP send jobs sau SP commit

(Task 3 = smoke test, no source change committed.)

## Self-Check: PASSED

**Files modified exist:**
- ✓ FOUND: `e_office_app_new/backend/src/repositories/outgoing-doc.repository.ts` (+34 lines, rawQuery import + new method)
- ✓ FOUND: `e_office_app_new/backend/src/routes/outgoing-doc.ts` (+65 lines, imports + extended handler)

**Commits exist:**
- ✓ FOUND: 6f8ccf7 (Task 1 — repo method)
- ✓ FOUND: 2ac0890 (Task 2 — route extend)

**Acceptance grep checks:** ALL PASS (12/12 patterns verified)

**TypeScript:** `cd e_office_app_new/backend && npx tsc --noEmit` exit 0 (zero errors)

**Build:** `npm run build` exit 0, all 3 dist files generated

**Export reachability:** Dynamic import test PASS — 7/7 symbols reachable (enqueueLgspSendJob, getLgspSendQueue, 3 constants, getExternalRecipientsForSend, sendToRecipients)

**Backend health smoke:** `GET /api/health` → 200 (postgresql + redis + minio all connected)
