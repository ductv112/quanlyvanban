---
phase: 36-status-callback-chain-9-ma-qd-28
plan: 01
subsystem: schema+backend
tags: [lgsp, status-callback, qd28, schema, dedup, service-interface, repository]
requirements:
  - LGSP-STATUS-08   # Schema-ready for sender-side mã 13/15/16 (active wiring DEFERRED Phase 37)
  - LGSP-STATUS-09   # Worker retry mechanism — schema (UNIQUE) + repo + service contract foundation
dependency_graph:
  requires:
    - 33-05  # edoc.lgsp_status_outbox baseline (table + 4 SPs + indexes)
    - 34-01  # LgspSendError + mapLgspError + isLgspNonRetryableError (services/lgsp/error-codes.ts)
    - 35-01  # LGSPRealService pattern (sendDocument + receiveDocuments + getEdocById fetch shape)
  provides:
    - "UNIQUE constraint uq_lgsp_status_outbox_doc_status (incoming_doc_id, target_status) — race-safe dedup phia DB"
    - "ILgspService.updateStatus(docId, status) → Promise<LgspSendResult> — contract cho worker Plan 36-02"
    - "LGSPRealService.updateStatus() POST /v1/updateStatus JSON body + X-SystemId/X-SecretKey headers"
    - "lgspMockService.updateStatus() mirror — mock luôn return success (dev test)"
    - "lgspStatusOutboxRepository.insertEvent({incoming_doc_id, target_status, payload}) → DbResultWithId | null (catch 23505)"
    - "lgspStatusOutboxRepository.getDocStatusHistory(docId) → LgspStatusOutboxHistoryRow[] (chronological)"
  affects:
    - "Plan 36-02 (worker) — sẽ consume ILgspService.updateStatus contract + insertEvent dedup"
    - "Plan 36-03 (route hooks) — sẽ gọi lgspStatusOutboxRepository.insertEvent() từ 6 route handlers"
    - "Plan 36-04 (UI Timeline) — sẽ render lgspStatusOutboxRepository.getDocStatusHistory()"
tech-stack:
  added: []
  patterns:
    - "DB idempotent DO block ALTER TABLE ... ADD CONSTRAINT catch 4 SQLSTATE (CLAUDE.md §DB Migration)"
    - "Repository try/catch SQLSTATE 23505 → null silent dedup (mirror Plan 35-01 pattern)"
    - "Service fetch native + 30s AbortController timeout + LgspSendError throw (mirror Phase 34/35)"
key-files:
  created: []
  modified:
    - e_office_app_new/database/schema/000_schema_v3.0.sql
    - e_office_app_new/backend/src/services/lgsp.service.ts
    - e_office_app_new/backend/src/services/lgsp-real.service.ts
    - e_office_app_new/backend/src/services/lgsp-mock.service.ts
    - e_office_app_new/backend/src/repositories/lgsp-status-outbox.repository.ts
decisions:
  - "D-04 honored: UNIQUE (incoming_doc_id, target_status) thay vì SELECT-then-INSERT — race-safe + nhanh hơn"
  - "D-08 honored: POST /v1/updateStatus JSON body {docId, status} + X-SystemId/X-SecretKey (Postman authoritative 06.updateStatus)"
  - "D-13 honored: schema APPEND idempotent DO block catch 4 SQLSTATE — apply lần 2 zero error"
  - "Reuse LgspSendResult shape thay vì tạo type mới — update + send response shape tương đồng (success/message/errorCode)"
  - "Status value default = mã số QĐ 28 ('02'..'06') không phải keyword 'done' — chuẩn QĐ 28/2018/QĐ-TTg. Worker Plan 36-05 verify nếu LGSP reject (errorCode 22) → flag switch keyword map"
  - "Mock service KHÔNG bỏ qua — phải mirror signature để satisfy ILgspService interface contract khi MOCK_EXTERNAL=true"
metrics:
  duration: "~25 min"
  ts_errors_backend: 0
  schema_apply_2x_zero_error: true
  dedup_test_passed: true
  acceptance_grep_checks_passed: 13
  commits: 3
  files_modified: 5
  sp_count_baseline: 361
  completed: 2026-05-21
---

# Phase 36 Plan 36-01: Schema UNIQUE + LGSPRealService.updateStatus + ILgspService Interface + Repo Extensions Summary

**One-liner:** Wave 1 foundation cho Status Callback Chain — APPEND UNIQUE constraint dedup vào outbox table, thêm `updateStatus(docId, status)` contract vào ILgspService + 2 service impl (real + mock), extend `lgspStatusOutboxRepository` với `insertEvent` (catch SQLSTATE 23505 silent) + `getDocStatusHistory` (chronological cho UI Timeline).

## What was built

### Task 1: Schema UNIQUE constraint (commit `5355eed`)

APPEND vào cuối `e_office_app_new/database/schema/000_schema_v3.0.sql`:

```sql
DO $$
BEGIN
  BEGIN
    ALTER TABLE edoc.lgsp_status_outbox
      ADD CONSTRAINT uq_lgsp_status_outbox_doc_status
      UNIQUE (incoming_doc_id, target_status);
  EXCEPTION
    WHEN duplicate_object THEN NULL;
    WHEN duplicate_table THEN NULL;
    WHEN invalid_table_definition THEN NULL;
    WHEN duplicate_column THEN NULL;
  END;
END $$;
```

- Idempotent — apply lần 2 catch `duplicate_object` → NULL → zero error
- Dedup test: 2 lần `INSERT (incoming_doc_id=1, target_status='03')` → lần 2 SQLSTATE 23505 PASS
- SP count baseline: 361 (KHÔNG drop SP nào)

### Task 2: LGSPRealService.updateStatus + ILgspService interface (commit `7a27210`)

**`lgsp.service.ts` ILgspService** — added method signature:
```typescript
updateStatus(docId: string, status: string): Promise<LgspSendResult>;
```
Reuse `LgspSendResult` (success/lgsp_doc_id/message/errorCode?) — shape giống send.

**`lgsp-real.service.ts` LGSPRealService.updateStatus()** — NEW method (Phase 18 không có):
- `POST {baseUrl}/v1/updateStatus` JSON body `{ docId, status }`
- Headers: `Content-Type: application/json`, `X-SystemId`, `X-SecretKey`, `Accept: application/json`
- 30s AbortController timeout
- Response parse 2 variants: success → return `{success:true, ..., errorCode:'0'}`; failure → return `{success:false, ..., errorCode: data.errorCode}` (NO throw — worker mark error)
- Throw `LgspSendError` cho network/timeout/non-JSON (BullMQ retry)
- Reuse `mapLgspError(errorCode, rawMessage)` từ Phase 34 error-codes.ts

**`lgsp-mock.service.ts` lgspMockService.updateStatus()** — mirror signature, luôn return success (mock dev test).

### Task 3: Repository extensions (commit `3dcd1c3`)

**`lgsp-status-outbox.repository.ts`** — extended, KHÔNG sửa 4 method Phase 33 baseline:

New exports:
- `interface LgspStatusOutboxHistoryRow` — row cho UI Timeline (Plan 36-04)
- `interface InsertEventParams` — named params {incoming_doc_id, target_status, payload}

New methods:
- `insertEvent(params)` — wrap `fn_lgsp_status_outbox_insert` SP, try/catch SQLSTATE 23505 → return `null` silent (caller NOOP), re-throw other SQLSTATE
- `getDocStatusHistory(docId)` — `rawQuery` SELECT 7 cột ORDER BY created_at ASC (chronological)

New import: `rawQuery` từ `lib/db/query.js`.

## Decisions made (honored from CONTEXT)

- **D-04 (idempotency):** UNIQUE constraint thay vì SELECT-then-INSERT — race-safe (atomic at DB level), nhanh hơn, dedup chống user spam action 2 lần
- **D-08 (API spec):** POST `/v1/updateStatus` JSON body {docId, status} + X-SystemId/X-SecretKey headers — Postman authoritative 06.updateStatus (verified trong file Postman collection)
- **D-13 (schema strategy):** APPEND idempotent vào master schema, DO block catch 4 SQLSTATE, KHÔNG tạo migration rời (CLAUDE.md §DB Migration Strategy)

## Deviations from Plan

**Auto-added missing functionality (Rule 2):**

1. **[Rule 2 - Interface Contract] Thêm `updateStatus` vào `lgsp-mock.service.ts`**
   - **Found during:** Task 2 TS check
   - **Issue:** Khi thêm `updateStatus(docId, status)` vào `ILgspService` interface mà KHÔNG thêm vào `lgspMockService` const object → TS error "Type ... missing 'updateStatus'"
   - **Fix:** Thêm mock `updateStatus` mirror signature, luôn return success (dev test khi `MOCK_EXTERNAL=true`)
   - **Files modified:** `e_office_app_new/backend/src/services/lgsp-mock.service.ts`
   - **Commit:** `7a27210` (bundled với Task 2 vì cùng concern interface contract)

**Plan deviation:** Plan acceptance criteria của Task 2 chỉ list 2 file (lgsp.service.ts + lgsp-real.service.ts), không liệt kê lgsp-mock.service.ts. Nhưng vì plan add method REQUIRED vào interface, mock service implementing same interface PHẢI satisfy → bắt buộc thêm. Documented as deviation per `<deviation_handling>` ("mock service phải mirror signature mới").

**No other deviations:** Plan executed exactly as written cho Task 1 (schema) và Task 3 (repo extensions).

## Auth gates encountered

None — local Docker postgres available, no LGSP credentials needed cho Wave 1 (chỉ TS check + schema apply + dedup test).

## Verification results

### Schema (Task 1)
- `grep -q "uq_lgsp_status_outbox_doc_status" e_office_app_new/database/schema/000_schema_v3.0.sql` → exit 0
- `grep -q "Phase 36 Plan 36-01" e_office_app_new/database/schema/000_schema_v3.0.sql` → exit 0
- `grep -q "UNIQUE (incoming_doc_id, target_status)" e_office_app_new/database/schema/000_schema_v3.0.sql` → exit 0
- psql constraint query → returns `uq_lgsp_status_outbox_doc_status`
- Apply schema **lần 2 zero error** (NOTICE "Phase 36 schema: ... -- OK" xuất hiện cả 2 lần, no ERROR)
- SP count baseline: **361** (>= 361 ✓ KHÔNG drop SP nào)
- Dedup test: INSERT 2x cùng key → lần 2 ERROR `duplicate key value violates unique constraint "uq_lgsp_status_outbox_doc_status"` ✓

### LGSPRealService (Task 2)
- `grep -q "/v1/updateStatus"` → exit 0
- `grep -c "X-SystemId"` = **10** (>= 4 ✓ — sendDocument + receiveDocuments + getEdocById + updateStatus đều use)
- `grep -q "JSON.stringify({ docId, status })"` → exit 0
- `grep -q "throw new LgspSendError"` in updateStatus → exit 0
- `grep -q "mapLgspError(errorCode, rawMessage)"` → exit 0
- NEGATIVE: `grep -q "/api/lgspedoc/update-status"` → exit 1 ✓ (broken Phase 18 endpoint KHÔNG có)
- `grep -q "updateStatus(docId: string, status: string)"` in lgsp.service.ts → exit 0

### Repository (Task 3)
- `grep -q "async insertEvent(params: InsertEventParams)"` → exit 0
- `grep -q "async getDocStatusHistory(incomingDocId: number)"` → exit 0
- `grep -q "sqlState === '23505'"` → exit 0
- `grep -q "ORDER BY created_at ASC"` → exit 0
- `grep -q "export interface LgspStatusOutboxHistoryRow"` → exit 0
- `grep -q "export interface InsertEventParams"` → exit 0
- `grep -q "import { callFunction, callFunctionOne, rawQuery } from"` → exit 0
- 4 Phase 33 methods unchanged: count = **5** (insert + getPending + markSent + markError + insertEvent) ✓

### TypeScript
- `cd e_office_app_new/backend && npx tsc --noEmit` → exit 0 ✓ (both after Task 2 and Task 3)

## Next steps (downstream Wave 2+)

- **Plan 36-02 (worker infra):**
  - Consume `lgspStatusOutboxRepository.getPending()` (Phase 33) + `markSuccess`/`markError`
  - Consume `(svc as ILgspService).updateStatus(payload.lgsp_doc_id, target_status)` qua factory `getLgspService(unit_id, env)`
  - Reuse `isLgspNonRetryableError(err.code)` từ Phase 34 — classify retry vs no-retry
- **Plan 36-03 (route hooks):**
  - Consume `lgspStatusOutboxRepository.insertEvent({incoming_doc_id, target_status, payload})` từ 6 route handlers
  - Pattern: SP success commit → check `doc.source_type === 'external_lgsp'` → `await insertEvent(...)` → swallow log warn (KHÔNG fail user action)
  - UNIQUE constraint Phase 36-01 sẽ chặn double-fire khi user spam action — return null silent
- **Plan 36-04 (UI Timeline):**
  - Consume `lgspStatusOutboxRepository.getDocStatusHistory(docId)` qua endpoint mới `GET /api/van-ban-den/:id/lgsp-status-history`
  - Render AntD `<Timeline>` với badge per `sent_status` (pending/success/error)
- **Plan 36-05 (verification):**
  - E2E test sequence trên DN.001 sandbox: trigger 4 actions → verify outbox + LGSP /v1/updateStatus thực tế
  - Nếu LGSP reject mã số (errorCode 22 — "Format edXML khong dung chuan QD 28"), flag switch sang keyword map (`'02'→'reject'`, `'03'→'received'`, `'04'→'assigned'`, `'05'→'processing'`, `'06'→'done'`)

## Self-Check: PASSED

Verified all artifacts exist + commits exist:

**Files modified (5):**
- `e_office_app_new/database/schema/000_schema_v3.0.sql` — FOUND (29053 lines)
- `e_office_app_new/backend/src/services/lgsp.service.ts` — FOUND
- `e_office_app_new/backend/src/services/lgsp-real.service.ts` — FOUND
- `e_office_app_new/backend/src/services/lgsp-mock.service.ts` — FOUND
- `e_office_app_new/backend/src/repositories/lgsp-status-outbox.repository.ts` — FOUND

**Commits (3):**
- `5355eed` — FOUND (`feat(36-01): them UNIQUE (incoming_doc_id, target_status) cho lgsp_status_outbox dedup`)
- `7a27210` — FOUND (`feat(36-01): fix LGSPRealService.updateStatus per /v1/updateStatus + JSON body + headers`)
- `3dcd1c3` — FOUND (`feat(36-01): extend lgsp-status-outbox repo voi insertEvent (23505 dedup) + getDocStatusHistory`)
