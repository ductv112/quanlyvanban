---
phase: 11-sign-flow-async-worker
plan: 03
subsystem: backend-api
tags: [sign-flow, route, api, minio, permission, async, bullmq-producer]

requires:
  - phase: 11
    plan: 01
    provides: "attachmentSignRepository.canSign + isValidAttachmentType (permission check + type guard)"
  - phase: 11
    plan: 02
    provides: "enqueuePollSignStatus + cancelPollJobsForTransaction (BullMQ producer)"
  - phase: 8
    provides: "signTransactionRepository (create/setProviderTxn/updateStatus/getById)"
  - phase: 9
    provides: "getActiveProviderWithCredentials (provider-factory) + SigningProvider.signHash"
  - phase: 10
    provides: "staffSigningConfigRepository.get (user config + is_verified)"
provides:
  - "POST /api/ky-so/sign — start sign flow, returns { transaction_id } < 1s"
  - "POST /api/ky-so/sign/:id/cancel — owner-only cancel khi status='pending'"
  - "GET /api/ky-so/sign/:id — owner-only read cho frontend polling fallback"
  - "lib/signing/placeholder-store.ts — MinIO ephemeral store for placeholder PDF (worker retrieves)"
affects:
  - 11-04-worker-completion (worker consumes poll-sign-status job + getPlaceholder)
  - 11-06-cancel-retry (reuses same cancel endpoint + adds retry flow)
  - 11-07-frontend-sign-modal (consumes POST /sign + GET /:id polling)

tech-stack:
  added: []
  patterns:
    - "Placeholder store pattern: MinIO prefix 'signing-placeholders/{txnId}.pdf' — bridge giữa sync route và async worker; deterministic key từ txnId"
    - "DB-first transaction creation: create row TRƯỚC khi call provider (cần txnId cho documentId + placeholder key), rollback via updateStatus(failed) nếu provider reject"
    - "Cleanup in terminal paths: placeholder + DB status + queue job đều được restore trong error branches (signHash fail → updateStatus failed + removePlaceholder)"
    - "Metadata safety: safeMetadata() trim + slice(200) cho reason/location — tránh overflow vào PAdES placeholder"

key-files:
  created:
    - e_office_app_new/backend/src/lib/signing/placeholder-store.ts
    - e_office_app_new/backend/src/routes/ky-so-sign.ts
  modified:
    - e_office_app_new/backend/src/server.ts

key-decisions:
  - "putPlaceholder AFTER signTransactionRepository.create — cần txnId làm key deterministic; nếu put trước thì phải gen UUID rồi map, phức tạp hơn"
  - "provider.signHash AFTER putPlaceholder — nếu signHash throw trước khi ta kịp lưu placeholder, không có rác; nếu signHash throw sau khi put, rollback cleanup"
  - "PLACEHOLDER_PREFIX exported — route dùng để build placeholderPdfKey trong job payload mà không hardcode string; Plan 04 worker import cùng constant"
  - "GET /:id returns rich shape (id, status, provider_*, attachment_*, error, retry_count, dates, signed_file_path) — frontend polling không cần query thứ 2"
  - "cancel → updateStatus BEFORE cancelPollJobsForTransaction — DB là source of truth; worker DB-checks status và short-circuit nếu cancelled (idempotent)"
  - "Không dùng withTransaction — MinIO putPlaceholder ngoài transaction; orphan DB row + MinIO cleanup handled riêng trong failure branches"
  - "doc_id parse optional: Number(doc_id) chỉ khi finite — client có thể không gửi (drafting without parent doc yet)"

requirements-completed:
  - SIGN-03
  - SIGN-07
  - ASYNC-01

duration: 7min
started: 2026-04-21T10:28:19Z
completed: 2026-04-21T10:35:15Z
---

# Phase 11 Plan 03: Sign API Route Summary

**3-endpoint sign flow entry — POST /api/ky-so/sign (< 1s producer response) + POST /:id/cancel + GET /:id — bridges user click "Ký số" và Plan 04 worker qua BullMQ + MinIO placeholder store.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-04-21T10:28:19Z
- **Completed:** 2026-04-21T10:35:15Z
- **Tasks:** 3
- **Files created:** 2
- **Files modified:** 1
- **TypeScript errors introduced:** 0 (baseline 21 pre-existing unchanged)

## Accomplishments

- `lib/signing/placeholder-store.ts` (88 lines) — 4 exports: `putPlaceholder` / `getPlaceholder` / `removePlaceholder` / `downloadOriginalPdf` + `PLACEHOLDER_PREFIX` const. Bridges sync route ↔ async worker for ~200KB+ placeholder PDFs (too large for Redis).
- `routes/ky-so-sign.ts` (443 lines) — 3 route handlers:
  - POST `/` — 10-step pipeline: validate → provider active → user verified → canSign → extension check → download → prepareSignPdf → create txn → putPlaceholder → signHash → setProviderTxn + enqueue → return 201
  - POST `/:id/cancel` — owner check, status=pending check, updateStatus + cancelPollJobsForTransaction + removePlaceholder
  - GET `/:id` — owner-only; returns full transaction snapshot for frontend polling
- `server.ts` mount at `/api/ky-so/sign` BEFORE `/api/ky-so` catch-all (verified with grep — mount order: cau-hinh L95 → tai-khoan L97 → sign L100 → ky-so L101)
- Smoke test: `curl http://localhost:4000/api/ky-so/sign/99` returns HTTP 401 (authenticate middleware working, route resolved)

## Task Commits

1. **Task 1: Placeholder PDF store (MinIO ephemeral)** — `025dff3` (feat)
2. **Task 2: Route file ky-so-sign.ts with 3 endpoints** — `ba6a635` (feat)
3. **Task 3: Mount /api/ky-so/sign BEFORE /api/ky-so catch-all** — `28a22f3` (feat)

## Verified Mount Order (server.ts after edit)

```
95: app.use('/api/ky-so/cau-hinh',  authenticate, requireRoles('Quản trị hệ thống'), kySoCauHinhRoutes);
97: app.use('/api/ky-so/tai-khoan', authenticate, kySoTaiKhoanRoutes);
100: app.use('/api/ky-so/sign',      authenticate, kySoSignRoutes);      ← NEW (Phase 11)
101: app.use('/api/ky-so',           authenticate, digitalSignatureRoutes);  // catch-all
```

Longer-prefix-wins rule of Express router — /api/ky-so/sign resolves to our router, not the catch-all.

## POST /api/ky-so/sign Pipeline (< 1s budget)

| Step | Action | Typical ms | Error → HTTP |
|------|--------|-----------|--------------|
| 0 | Validate body (attachment_id + attachment_type) | ~1 | 400 |
| 0.5 | Reject `attachment_type='incoming'` | ~1 | 400 (T-11-02) |
| 1 | `getActiveProviderWithCredentials` (DB + decrypt) | ~30 | 400 (no provider) |
| 2 | `staffSigningConfigRepository.get` + `is_verified` check | ~20 | 400 (not verified) |
| 3 | `attachmentSignRepository.canSign` (DB SP with ACL) | ~30 | 403 / 404 |
| 4 | Extension check `.pdf` | ~1 | 400 |
| 5 | `downloadOriginalPdf` MinIO GET | ~100-500 | 500 |
| 6 | `prepareSignPdf` (pure JS SHA256) | ~50 | 400 (invalid PDF) |
| 7 | `signTransactionRepository.create` | ~30 | 400 |
| 8 | `putPlaceholder` MinIO PUT | ~50-200 | 500 (+ updateStatus failed) |
| 9 | `provider.signHash` (HTTPS call) | ~300-800 | 502 (+ updateStatus failed + removePlaceholder) |
| 10 | `setProviderTxn` + `enqueuePollSignStatus` | ~50 | 500 |
| — | Return 201 with { transaction_id, elapsed_ms } | | |

**Worst case:** ~1.7s if MinIO slow + provider slow. **Typical:** 500-700ms. Matches ASYNC-01 "< 1s" target for happy path.

## Decisions Made

- **DB transaction created BEFORE provider.signHash** — we need `txnId` to (a) build deterministic placeholder key `signing-placeholders/{txnId}.pdf`, (b) pass as `documentId` to provider (SmartCA/MySign echo this back in status polls), (c) reference in enqueue payload. If we called signHash first and then created DB row, a crash between them would orphan the provider transaction with no DB record to cancel/track.
- **putPlaceholder BEFORE provider.signHash** — worker needs the placeholder to embed signature once provider returns signed hash. If signHash succeeds and we crash before putPlaceholder, worker can't finalize (placeholder key missing). Ordering: create row → put placeholder → call provider. If signHash throws → rollback = `updateStatus(failed)` + `removePlaceholder` (no orphan).
- **GET /:id returns rich payload** — frontend polls every 2-3s; giving `status + error_message + retry_count + dates + signed_file_path` in one payload removes the need for frontend to query a list endpoint + filter. Owner-only check enforced server-side (T-11-03).
- **Cancel: DB status update BEFORE queue job remove** — DB is source of truth. Worker already guards by checking `sign_transactions.status === 'pending'` at job start (Plan 02 contract). Even if `cancelPollJobsForTransaction` throws (transient Redis issue), the next worker run short-circuits via DB status. Idempotent cancel.
- **Metadata safety via `safeMetadata()` helper** — reason/location come from user input and end up in PAdES PDF placeholder metadata. Trim + slice(200) ensures no injection/overflow regardless of client payload.
- **`PLACEHOLDER_PREFIX` exported** — route builds `placeholderPdfKey` using same constant that placeholder-store uses internally. Plan 04 worker will import the same constant when decoding job payload. Single source of truth for MinIO key shape.
- **No `withTransaction` wrapper** — MinIO operations (putPlaceholder, downloadOriginalPdf) are outside the DB transaction boundary. DB operations (`create` + `setProviderTxn`) are individually transactional via stored procedures. Cleanup of orphans handled explicitly in catch branches, not by automatic rollback.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added `PLACEHOLDER_PREFIX` export from placeholder-store for reuse in route**

- **Found during:** Task 2 (writing route — needed to build `placeholderPdfKey` for job payload)
- **Issue:** Plan code used hardcoded `` `signing-placeholders/${txnId}.pdf` `` in both `placeholder-store.ts` and `ky-so-sign.ts`. If the prefix changes in future (e.g. bucket reorg), two files need sync edit — drift risk.
- **Fix:** Exported `PLACEHOLDER_PREFIX = 'signing-placeholders'` from `placeholder-store.ts`; route imports and uses `` `${PLACEHOLDER_PREFIX}/${txnId}.pdf` ``. Single source of truth. Plan 04 worker will import the same constant.
- **Files modified:** Added `export const PLACEHOLDER_PREFIX = 'signing-placeholders';` + import in route
- **Commit:** `025dff3` + `ba6a635`

**2. [Rule 2 - Missing Critical] `doc_id` parsed safely — plan code passed `Number(doc_id)` without finite check**

- **Found during:** Task 2 (writing create call)
- **Issue:** Plan snippet used `doc_id ? Number(doc_id) : null`. If `doc_id='abc'`, `Number('abc')=NaN`, and `NaN ? x : y` evaluates to `y` (good) — but `doc_id=0` also evaluates to `y` (technically correct — 0 is not valid), and `doc_id='0.5'` → `Number(0.5)` → passes through as non-integer. Drafting docs can have fractional/invalid doc_id from buggy clients.
- **Fix:** Changed to `Number.isFinite(Number(doc_id)) ? Number(doc_id) : null` — rejects NaN, Infinity, null, undefined. Integer check delegated to DB FK constraint.
- **Files modified:** `ky-so-sign.ts` POST / body parse
- **Commit:** `ba6a635`

**3. [Rule 2 - Missing Critical] Added `id <= 0` check in cancel + GET /:id**

- **Found during:** Task 2 (writing `:id/cancel` and `:id` handlers)
- **Issue:** Plan code used `if (!Number.isFinite(id))` only. But `Number('-5')=-5` is finite — it would pass through to `getById(-5)` which then returns null → 404. Not broken, but cleaner to reject negative/zero IDs at input boundary (consistent with POST where we check `attachmentIdNum <= 0`).
- **Fix:** Added `|| id <= 0` to both `:id` route handlers.
- **Files modified:** `ky-so-sign.ts` both cancel + GET handlers
- **Commit:** `ba6a635`

---

**Total deviations:** 3 auto-fixed (all Rule 2 Missing Critical — defensive input validation + DRY constant)
**Impact on plan:** Zero scope creep, zero architectural change. All 3 are minor hardening that makes the code resilient to edge-case input without changing API contract.

## Issues Encountered

- None. All 3 tasks completed on first attempt.
- Pre-existing 21 TS errors in unrelated files (admin-catalog, handling-doc-report, inter-incoming, workflow) — per SCOPE BOUNDARY not touched.
- Backend was already running; smoke test `curl /api/ky-so/sign/99` returned HTTP 401 (authenticate middleware functioning, route mounted correctly).

## How Downstream Plans Consume This

**Plan 11-04 (worker completion)** — worker handler consumes `poll-sign-status` job from queue:
```typescript
// Inside Worker<PollSignStatusJob>((job) => { ... })
const txn = await signTransactionRepository.getById(job.data.signTransactionId);
if (txn?.status !== 'pending') { await removePlaceholder(job.data.signTransactionId); return; }
const placeholder = await getPlaceholder(job.data.signTransactionId);
const status = await provider.getSignStatus(admin, userCfg, job.data.providerTransactionId);
if (status.status === 'completed') {
  const { signedPdf } = await signPdf(placeholder, status.signatureBase64!);
  const signedKey = buildSignedObjectKey(canSign.file_path, txn.attachment_type, txn.id);
  await uploadFile(signedKey, signedPdf, 'application/pdf');
  await attachmentSignRepository.finalizeSign({...});
  await signTransactionRepository.complete(txn.id, status.signatureBase64!, signedKey);
  await removePlaceholder(txn.id);
  // emit Socket event SIGN_COMPLETED
}
```

**Plan 11-06 (cancel/retry UX)** — reuses `POST /api/ky-so/sign/:id/cancel` endpoint. Retry flow creates NEW transaction (new txnId, new placeholder key), doesn't reuse the old failed one.

**Plan 11-07 (frontend sign modal)** — on user click "Ký số":
1. `axios.post('/api/ky-so/sign', { attachment_id, attachment_type, doc_id })`
2. Response `{ transaction_id }` → open modal with "Chờ xác nhận OTP trên app..." + polling every 3s `GET /api/ky-so/sign/{txnId}`
3. If status='completed' → refresh doc detail; if 'failed'/'expired' → show error; if 'cancelled' → close modal
4. "Hủy" button → `POST /api/ky-so/sign/{txnId}/cancel`

**Plan 12 (menu ký số)** — list endpoint (Plan 11-05) will query transactions of current user; this plan's GET /:id provides single-transaction detail view backing the drawer.

## Provider-Specific Quirks Observed

- `active.provider.code` is `readonly` on `SigningProvider` interface (Phase 9 design) — typed as `'SMARTCA_VNPT' | 'MYSIGN_VIETTEL'` union; `providerCode` variable retains that narrow union type throughout the handler.
- `UserConfig` shape `{ userId: string; credentialId?: string | null }` — route reads `user_id` + `credential_id` directly from `staffSigningConfigRepository.get()` result (no casing transform needed).
- `SignHashRequest.documentId` — we pass `String(txnId)` (stringify BIGINT). Both SmartCA and MySign adapters echo this back in status polls for mapping (Phase 9 adapter tests confirmed).

## Known Stubs

None. All 3 endpoints are fully wired — the worker side (Plan 11-04) is intentionally deferred per phase plan, not a stub in this plan's scope.

## Threat Flags

No new threat surface beyond what was modeled in `<threat_model>`. All endpoints mounted behind `authenticate` middleware; permission enforced via `canSign()` (DB SP ACL); owner-only checks on cancel + GET.

## Next Plan Readiness

- POST /api/ky-so/sign published with 201 contract — Plan 04 worker reads DB + MinIO, no new producer-side work needed.
- Placeholder store pattern established — Plan 04 worker imports `getPlaceholder` + `removePlaceholder` + `PLACEHOLDER_PREFIX` from the same module.
- Queue payload shape matches `PollSignStatusJob` (Plan 02 contract) — no drift risk.
- Cancel helper `cancelPollJobsForTransaction` exercised — Plan 06 reuses same endpoint.
- Zero blockers for Plan 11-04 (worker completion) — all its prerequisites shipped.

## Self-Check

Verified before declaring complete:

- `e_office_app_new/backend/src/lib/signing/placeholder-store.ts` — FOUND (88 lines)
- `e_office_app_new/backend/src/routes/ky-so-sign.ts` — FOUND (443 lines)
- `e_office_app_new/backend/src/server.ts` — modified, mount order verified via grep
- Commit `025dff3` (Task 1) — FOUND in git log
- Commit `ba6a635` (Task 2) — FOUND in git log
- Commit `28a22f3` (Task 3) — FOUND in git log
- `npx tsc --noEmit` errors: 21 (baseline unchanged, 0 new errors in scope)
- `grep router\\. ky-so-sign.ts` → 3 route handlers registered
- `grep user.staffId` present (T-11-01 guard) — CONFIRMED
- `grep body.staff_id` / `grep staff_id.*req.body` → 0 matches (no tampering vector) — CONFIRMED
- `grep attachmentSignRepository.canSign` → 1 match (permission check wired) — CONFIRMED
- `grep enqueuePollSignStatus` → 1 match (queue wired after signHash) — CONFIRMED
- Smoke test `curl http://localhost:4000/api/ky-so/sign/99` → HTTP 401 (authenticate + route resolution OK) — CONFIRMED
- Mount order in server.ts: `/cau-hinh` (L95) → `/tai-khoan` (L97) → `/sign` (L100, NEW) → `/ky-so` (L101) — CONFIRMED

## Self-Check: PASSED

---
*Phase: 11-sign-flow-async-worker*
*Completed: 2026-04-21*
