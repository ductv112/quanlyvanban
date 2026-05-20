---
phase: 33-database-core-infrastructure
plan: 03
subsystem: backend
tags: [postgres, lgsp, repository, typescript, sps, encryption]

requires:
  - phase: 33-01
    provides: "edoc.lgsp_agency_config + lgsp_status_outbox tables + triggers"
  - phase: 33-02
    provides: "Seed placeholder 9 row (idempotent) + portable name-keyword UPDATE"
provides:
  - "11 SPs Phase 33: 7 cho lgsp_agency_config + 4 cho lgsp_status_outbox"
  - "Repository file lgsp-agency-config.repository.ts (169 lines, 3 Row interfaces, 7 methods)"
  - "Repository file lgsp-status-outbox.repository.ts (93 lines, 1 Row interface, LgspTargetStatus type, 4 methods)"
  - "Encryption boundary contract: repo Buffer-pass-through, service decrypt via crypto.ts"
affects: [phase-33-04-service-factory, phase-35-receive-cron, phase-36-status-callback-worker, phase-37-admin-ui]

tech-stack:
  added: []
  patterns:
    - "Repository mirror pattern (signing-provider-config) — export const object, snake_case Row interfaces match SP RETURNS TABLE exactly"
    - "BYTEA → Buffer in TypeScript (pg driver native), encrypt/decrypt centralized in services/signing/crypto.ts"
    - "BIGINT → string in pg driver default (caller wraps Number() per CLAUDE.md pitfall #9)"
    - "DROP FUNCTION IF EXISTS with exact signature (CLAUDE.md DB Migration warning — KHÔNG dùng LIKE 'fn_%')"
    - "ESM imports with .js extension (project convention)"

key-files:
  created:
    - "e_office_app_new/backend/src/repositories/lgsp-agency-config.repository.ts (169 lines)"
    - "e_office_app_new/backend/src/repositories/lgsp-status-outbox.repository.ts (93 lines)"
  modified:
    - "e_office_app_new/database/schema/000_schema_v3.0.sql (+322 lines, 28476 → 28798)"

key-decisions:
  - "Repo TUYỆT ĐỐI KHÔNG decrypt secret_key_encrypted — chỉ pass Buffer through; service layer caller dùng decryptSecret() từ crypto.ts (security boundary)"
  - "fn_lgsp_agency_config_list KHÔNG trả secret_key_encrypted để tránh leak ciphertext qua HTTP response (admin UI use case)"
  - "fn_lgsp_agency_config_get_by_id và get_by_unit_id TRẢ full (có secret_key_encrypted) — chỉ dùng internal cho service factory + admin edit form (caller responsibility KHÔNG echo lên response)"
  - "setActive KHÔNG atomic single-active (khác signing) — mỗi DN có thể active 2 row đồng thời: prod + sandbox độc lập"
  - "outbox.markError với next_retry_at=NULL → sent_status='error' (final fail); với timestamp → giữ 'pending' để retry (Phase 36 worker tính backoff)"

requirements-completed:
  - LGSP-CRED-01
  - LGSP-CRED-04
  - LGSP-STATUS-01

duration: 12min
completed: 2026-05-20
---

# Phase 33 Plan 03: 11 SPs + 2 Repositories Summary

**11 SPs CRUD (7 cho `lgsp_agency_config` + 4 cho `lgsp_status_outbox`) append vào master schema + 2 file repository TypeScript (`lgsp-agency-config.repository.ts` + `lgsp-status-outbox.repository.ts`) mirror EXACT pattern `signing-provider-config.repository.ts` — TypeScript strict zero error + deep smoke test E2E pass (encrypt/decrypt round-trip + outbox lifecycle)**

## Performance

- **Started:** 2026-05-20T (Task 1 start)
- **Completed:** 2026-05-20
- **Duration:** ~12 phút
- **Tasks:** 4
- **Files modified:** 1 (schema master)
- **Files created:** 2 (2 repository files)

## Accomplishments

### Task 1: Schema append + apply DB
- Append 322 dòng SQL Phase 33 vào `database/schema/000_schema_v3.0.sql` (28476 → 28798)
- 11 SPs Phase 33 created in `edoc` schema:
  - **lgsp_agency_config (7):** `_list`, `_get_by_id`, `_get_by_unit_id`, `_get_all_active`, `_upsert`, `_set_active`, `_update_last_synced`
  - **lgsp_status_outbox (4):** `_insert`, `_get_pending`, `_mark_sent`, `_mark_error`
- Pattern DROP exact signature (11 individual DROPs, KHÔNG dùng `LIKE 'fn_%'`) — tránh wipe out SP khác (CLAUDE.md DB Migration warning)
- Apply schema lần 1: exit 0, 11 CREATE FUNCTION, NOTICE 'Phase 33 SPs ... OK'
- Apply schema lần 2 (idempotent verify): exit 0, ZERO ERROR — re-apply an toàn
- Zero SP overload trên edoc.lgsp_* (verify qua `pg_proc GROUP BY proname HAVING count > 1`)

### Task 2: lgsp-agency-config.repository.ts (169 lines)
- 3 Row interfaces match SP output snake_case:
  - `LgspAgencyConfigListRow` (12 fields, JOIN departments)
  - `LgspAgencyConfigFullRow` (9 fields, có `secret_key_encrypted: Buffer`)
  - `LgspAgencyConfigActiveRow` (7 fields, cho cron loop)
- 7 methods async: `list`, `getById`, `getByUnitId`, `getAllActive`, `upsert`, `setActive`, `updateLastSynced`
- `upsert()` accepts params object với `secretKeyEncrypted: Buffer` (caller PHẢI encrypt trước qua `services/signing/crypto.encryptSecret`)
- Default `environment='prod'` cho `getByUnitId` — service factory Phase 33-04 sẽ override

### Task 3: lgsp-status-outbox.repository.ts (93 lines)
- 1 Row interface `LgspStatusOutboxPendingRow` (7 fields)
- 1 union type `LgspTargetStatus` = 9 mã QĐ 28/2018 (`'01' | '02' | ... | '16'`)
- 4 methods async: `insert`, `getPending(limit=10)`, `markSent`, `markError`
- `markError(nextRetryAt=null)` → final fail (sent_status='error'); `markError(nextRetryAt=timestamp)` → keep 'pending' for retry (Phase 36 worker exponential backoff)

### Task 4: TypeScript strict + E2E smoke test
- `npx tsc --noEmit` → exit 0, zero error
- **Simple smoke test:** list/getByUnitId/getAllActive/getPending — empty results expected (dev DB empty per Plan 33-02)
- **Deep smoke test E2E (13 steps, all PASS):**
  1. `encryptSecret(plaintext)` → 92 bytes Buffer
  2. `upsert({unitId: 999003, environment: 'sandbox', ...})` → success, id=4
  3. `getByUnitId(999003, 'sandbox')` → returns Full Row, Buffer.isBuffer(secret_key_encrypted)=true
  4. `decryptSecret(secret_key_encrypted)` → plaintext match (round-trip verified)
  5. `setActive(4, true)` → success
  6. `getAllActive()` → 1 row (matches)
  7. `getAllActive('sandbox')` → 1 row (filter works)
  8. `getAllActive('prod')` → 0 row (filter works)
  9. `updateLastSynced(999003, 'sandbox', NOW)` → success
  10. `outbox.insert(1, '03', {lgsp_doc_id: 'TEST-LGSP-001'})` → success, id=1
  11. `outbox.getPending()` → 1 row, payload preserved as JSONB
  12. `outbox.markSent(1)` → success
  13. After markSent, no longer in pending (lifecycle works)
- Cleanup verified clean: 0 lgsp_agency_config, 0 lgsp_status_outbox, 0 test dept

## Task Commits

1. **Task 1: Append 11 SPs vào master schema + apply DB + verify** — `574ab01` (feat)
2. **Tasks 2+3+4: 2 repository files + TS check + smoke test (bundled)** — `9d2d94a` (feat)

**Plan metadata:** _(commit cuối sau khi tạo SUMMARY.md)_

## Files Created/Modified

- **Created:** `e_office_app_new/backend/src/repositories/lgsp-agency-config.repository.ts` — 169 lines
- **Created:** `e_office_app_new/backend/src/repositories/lgsp-status-outbox.repository.ts` — 93 lines
- **Modified:** `e_office_app_new/database/schema/000_schema_v3.0.sql` — append 322 dòng cuối (sau Phase 33 schema section): 11 DROP FUNCTION + 11 CREATE FUNCTION + 1 RAISE NOTICE

## Decisions Made

### 1. Security boundary: Repo Buffer pass-through, service decrypt

Mirror chính xác pattern `signing-provider-config.repository.ts`:
- Repo nhận `Buffer` (đã encrypted) làm input cho `upsert`
- Repo trả `secret_key_encrypted: Buffer` raw từ SP cho caller
- Service layer (Phase 33-04 sẽ build) gọi `decryptSecret(buffer)` từ `services/signing/crypto.ts` khi cần plaintext (e.g., gửi lên LGSP API)
- HTTP route NEVER echo `secret_key_encrypted` trong response — admin UI list dùng `fn_lgsp_agency_config_list` (KHÔNG trả secret column)

### 2. Default environment='prod' cho getByUnitId

Phù hợp với production deployment Lạng Sơn (mặc định khách dùng prod). Sandbox chỉ dùng cho test thủ công của admin (qua `/ky-so/lgsp-config` Phase 37 UI sẽ có toggle).

### 3. setActive KHÔNG atomic single-active

Khác `signing_provider_config` (chỉ 1 provider active tại 1 thời điểm). Lý do: mỗi DN có thể bật cả `prod` + `sandbox` đồng thời (để test). Constraint `UNIQUE(unit_id, environment)` đảm bảo 1 row per env per DN, nhưng KHÔNG limit total active.

### 4. markError logic split: retry vs final fail

- `next_retry_at = TIMESTAMPTZ` → SP set `sent_status='pending'` + tăng `retry_count` + lưu `error_message` → Phase 36 worker sẽ retry sau timestamp
- `next_retry_at = NULL` → SP set `sent_status='error'` (giving up) → worker không retry nữa
- Worker (Phase 36) tự tính nextRetryAt theo exponential backoff (1m, 5m, 30m, 2h, 6h), max 5 retry → sau lần 5 truyền NULL

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Initial smoke test import error (pool not in query.js)**
- **Found during:** Task 4 (deep smoke test 1st run)
- **Issue:** `import { pool, rawQuery } from './src/lib/db/query.js'` failed — `pool` exported từ `./pool.js`, không phải `query.js`
- **Fix:** Split imports — `pool` từ `pool.js`, `rawQuery` từ `query.js`
- **Files modified:** Smoke test file (temp, đã xóa)
- **Verification:** Re-run smoke test pass all 13 steps
- **Impact:** Không ảnh hưởng source code production — chỉ test scaffolding

**2. [Rule 3 - Blocking] Initial smoke test setup INSERT used wrong column names**
- **Found during:** Task 4 (deep smoke test 1st run)
- **Issue:** Smoke test attempted to insert into `edoc.incoming_docs` with columns `(doc_number, doc_date, subject, urgent_level, secret_level, received_unit_id, current_status)` — but actual schema uses `(document_code, publish_date, abstract, urgent_id, secret_id, unit_id)` (different naming convention from legacy migration)
- **Fix:** Skip creating test incoming_doc — reuse existing `incoming_docs.id=1` (dev seed có sẵn) for outbox FK target
- **Files modified:** Smoke test file (temp, đã xóa)
- **Verification:** outbox.insert (step 10) → success with reused id=1, full lifecycle works
- **Impact:** Không ảnh hưởng source. Cleanup tránh DELETE incoming_doc gốc (không tạo nên không xóa).

---

**Total deviations:** 2 auto-fixed (cả 2 Rule 3 — tooling issues trong smoke test scaffolding, không ảnh hưởng repo source code).

## Issues Encountered

- BIGINT từ pg driver default trả về string (`id: '4'`, `id: '1'`). Đây là behavior chuẩn (CLAUDE.md pitfall #9) — caller cần wrap `Number()` khi compare. Repo Row interface khai báo `id: number` nhưng runtime là string — caller convert qua `Number(row.id)` trước khi pass cho query/JSX key.
  - **Action item:** Phase 33-04 service factory + Phase 37 admin UI cần lưu ý wrap `Number()` khi consume.

## Self-Check: PASSED

**Verified entities:**
- ✅ `edoc.fn_lgsp_agency_config_list` SP — exists
- ✅ `edoc.fn_lgsp_agency_config_get_by_id` SP — exists
- ✅ `edoc.fn_lgsp_agency_config_get_by_unit_id` SP — exists
- ✅ `edoc.fn_lgsp_agency_config_get_all_active` SP — exists
- ✅ `edoc.fn_lgsp_agency_config_upsert` SP — exists
- ✅ `edoc.fn_lgsp_agency_config_set_active` SP — exists
- ✅ `edoc.fn_lgsp_agency_config_update_last_synced` SP — exists
- ✅ `edoc.fn_lgsp_status_outbox_insert` SP — exists
- ✅ `edoc.fn_lgsp_status_outbox_get_pending` SP — exists
- ✅ `edoc.fn_lgsp_status_outbox_mark_sent` SP — exists
- ✅ `edoc.fn_lgsp_status_outbox_mark_error` SP — exists
- ✅ Repository file `lgsp-agency-config.repository.ts` — exists (169 lines, >= 100 required)
- ✅ Repository file `lgsp-status-outbox.repository.ts` — exists (93 lines, >= 60 required)
- ✅ `export const lgspAgencyConfigRepository` — found
- ✅ `export const lgspStatusOutboxRepository` — found
- ✅ TypeScript strict compile — exit 0, zero error
- ✅ Zero SP overload — verified (count GROUP BY HAVING > 1 = 0)
- ✅ Schema idempotent — apply lần 2 zero ERROR

**Verified commits:**
- ✅ `574ab01` — feat(33-03): append 11 SPs CRUD cho lgsp_agency_config + lgsp_status_outbox — FOUND
- ✅ `9d2d94a` — feat(33-03): them 2 repository LGSP (agency_config + status_outbox) — FOUND

**Smoke test:**
- ✅ Simple smoke (4 calls): list=0, getByUnitId=NULL, getAllActive=0, getPending=0 (correct for empty dev DB)
- ✅ Deep smoke (13 steps with temp data + cleanup): encrypt → upsert → decrypt round-trip → setActive → getAllActive filter → outbox lifecycle ALL PASS

## Tech Debt / Caveat

- **BIGINT string vs number:** Repo Row interfaces declare `id: number` for documentation clarity, but pg driver trả về string. Phase 33-04 service factory + Phase 37 admin UI MUST wrap `Number()` khi consume `.id` field. Pattern đã có sẵn trong codebase (signing-provider-config consumers).
- **Outbox no `getByDocId` / `getHistory`:** Hiện chỉ có `getPending` cho worker. Phase 37 admin UI / Phase 36 detail screen có thể cần thêm `getByDocId(docId)` để show history status callback cho 1 VB. Add khi cần (chưa cần thiết Phase 33).
- **Dev DB empty:** `getAllActive()` return 0 rows trên dev. Phase 33-04 test cần seed test data inline hoặc reuse smoke test pattern.

## Next Phase Readiness

**Sẵn sàng cho Plan 33-04 (Service Factory `getLgspService(unit_id)`):**
- Repository layer hoàn chỉnh — service factory chỉ cần `lgspAgencyConfigRepository.getByUnitId(unitId, env)` + `decryptSecret()` để build LGSPRealService instance
- Boundary contract rõ ràng: Service decrypt + cache LGSPRealService instance per unit_id
- Existing `LGSPRealService` (Phase 18) cần refactor để nhận credentials qua constructor thay vì env vars
- Outbox repo sẵn sàng cho Phase 36 worker (status callback queue)

**Blockers:** None.

---
*Phase: 33-database-core-infrastructure*
*Completed: 2026-05-20*
