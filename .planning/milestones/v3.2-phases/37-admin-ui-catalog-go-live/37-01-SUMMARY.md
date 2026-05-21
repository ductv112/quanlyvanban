---
phase: 37-admin-ui-catalog-go-live
plan: 01
subsystem: backend
tags: [admin, lgsp, retry, crud, express, postgres, encrypt, requireRoles, phase-37]

# Dependency graph
requires:
  - phase: 33-credential-store-encrypt
    provides: lgspAgencyConfigRepository.{list,getById,upsert,setActive} + encryptSecret/decryptSecret + invalidateLgspServiceCache
  - phase: 34-send-flow-sendedoc
    provides: enqueueLgspSendJob + LgspSendJobData shape (recipient_id/outgoing_doc_id/tracking_id/sender_unit_id/environment)
  - phase: 35-receive-flow-cron-syncreceivededoclist
    provides: interOrganizationRepository.{autoRegisterFromLgsp,findByCode} + Phase 35-03 requireRoles('Quản trị hệ thống') verified pattern
  - phase: 36-status-callback-chain-9-ma-qd-28
    provides: lgspStatusOutboxRepository.{insert,getPending,markSent,markError,insertEvent,getDocStatusHistory} + outbox table sent_status='error' rows
provides:
  - "9 endpoint admin namespace `/api/admin/lgsp-*` + `/api/admin/inter-organizations` (router file admin-lgsp.ts)"
  - "Admin có khả năng cấu hình LGSP credential từ UI (list mask secret + update encrypt + toggle active per row)"
  - "Admin có khả năng retry outbox event lỗi (Phase 36) + retry tracking send lỗi (Phase 34) qua HTTP endpoint"
  - "Admin có khả năng CRUD catalog inter_organizations (list/create/update/delete) — Phase 35 auto-register Phase 37 verify/edit"
  - "Repository pattern: 7 method mới + 3 interface mới reuse được cho Plan 37-02 (test connection + overview endpoint)"
affects: [37-02-backend-test-connection-overview, 37-03-frontend-admin-config, 37-04-frontend-overview, 37-05-frontend-catalog, 37-06-frontend-retry-button]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Admin namespace `/api/admin/*` + requireRoles('Quản trị hệ thống') wrap tại server.ts (Phase 35-03 verified — KHÔNG dùng literal 'admin')"
    - "Repository method admin-only: list mask secret + update encrypt lazy + reset+re-enqueue pattern cho retry"
    - "Type-safe partial update qua `Partial<InterOrgCreateFields>` + dynamic SET clause builder"

key-files:
  created:
    - e_office_app_new/backend/src/routes/admin-lgsp.ts (302 dòng — 9 endpoint)
  modified:
    - e_office_app_new/backend/src/repositories/lgsp-agency-config.repository.ts (+ getByIdWithDecryptedSecret)
    - e_office_app_new/backend/src/repositories/lgsp-status-outbox.repository.ts (+ resetForRetry)
    - e_office_app_new/backend/src/repositories/lgsp.repository.ts (+ getTrackingForRetry, resetTrackingForRetry, LgspTrackingFullRow)
    - e_office_app_new/backend/src/repositories/inter-organization.repository.ts (+ 4 method, 2 interface)
    - e_office_app_new/backend/src/server.ts (import + mount + requireRoles import)

key-decisions:
  - "Tách file `admin-lgsp.ts` riêng thay vì extend `lgsp.ts` (file lgsp.ts đã to + scope khác — admin vs user actions)"
  - "Encrypt secret_key tại route layer (lazy import encryptSecret) — repo `upsert` nhận sẵn Buffer (giữ contract Phase 33)"
  - "JOIN qua `outgoing_doc_recipients.generated_lgsp_tracking_id` (Phase 34 wiring) thay vì match qua dest_org_code → robust hơn"
  - "Resolve environment cho tracking retry: prefer 'prod' nếu có 2 row active (ORDER BY environment='prod' DESC NULLS LAST)"
  - "secret_key_masked = '***' add explicit trong response (SP `list` đã KHÔNG trả secret_key_encrypted) — UI rõ ràng"

patterns-established:
  - "Admin endpoint role guard: chỉ tại mount site server.ts, KHÔNG lặp lại trong từng handler"
  - "Repository delete với FK catch 23503 → message rõ ràng 'cơ quan đang được tham chiếu (văn bản đến/đi)'"
  - "Dynamic SET clause cho partial update: array push + param counter — type-safe + idempotent (sets.length===0 guard)"
  - "Retry endpoint pattern: get full payload → reset state → re-enqueue job với đầy đủ data (recipient_id, outgoing_doc_id, tracking_id, sender_unit_id, environment)"

requirements-completed: [LGSP-UI-01, LGSP-UI-05]

# Metrics
duration: ~18 min
completed: 2026-05-21
---

# Phase 37 Plan 01: Backend Admin Endpoints + Repository Extensions Summary

**9 endpoint admin LGSP (`/api/admin/*`) + 4 repository extends (7 method mới + 3 interface mới) — Wave 1 foundation cho Phase 37 frontend pages**

## Performance

- **Duration:** ~18 min
- **Started:** 2026-05-21
- **Completed:** 2026-05-21
- **Tasks:** 3/3
- **Files modified:** 5 (1 NEW + 4 extend)

## Accomplishments

- 4 repository extend với 7 method admin-only + 3 interface mới (LgspTrackingFullRow, InterOrgFullRow, InterOrgCreateFields)
- NEW `routes/admin-lgsp.ts` với 9 endpoint REST: 3 cho lgsp_agency_config (list/update/active), 2 cho retry (outbox/tracking), 4 cho inter_organizations CRUD
- Mount tại server.ts dưới `/api/admin` namespace với `requireRoles('Quản trị hệ thống')` guard — non-admin user nhận 403 Forbidden
- TS strict backend exit 0 + production `npm run build` PASS

## Task Commits

1. **Task 1: Extend 4 repository với admin methods** — `95d93de` (feat)
2. **Task 2: Tạo NEW routes/admin-lgsp.ts với 9 endpoints** — `ee7bb3d` (feat)
3. **Task 3: Mount admin-lgsp router vào server.ts với role guard** — `a9958da` (feat)

## Files Created/Modified

- `e_office_app_new/backend/src/routes/admin-lgsp.ts` **(NEW)** — Router với 9 endpoint admin, mount relative (server.ts prefix /api/admin)
- `e_office_app_new/backend/src/repositories/lgsp-agency-config.repository.ts` — Thêm `getByIdWithDecryptedSecret(id)` lazy decrypt secret
- `e_office_app_new/backend/src/repositories/lgsp-status-outbox.repository.ts` — Thêm `resetForRetry(id)` UPDATE sent_status='pending' + retry_count=0 + next_retry_at=NOW WHERE sent_status='error'
- `e_office_app_new/backend/src/repositories/lgsp.repository.ts` — Thêm `getTrackingForRetry(id)` (JOIN outgoing_doc_recipients + lgsp_agency_config) + `resetTrackingForRetry(id)` + interface `LgspTrackingFullRow`. Import `rawQuery` thêm vào.
- `e_office_app_new/backend/src/repositories/inter-organization.repository.ts` — Thêm 4 method admin CRUD (`listForAdmin`, `createForAdmin`, `updateForAdmin`, `deleteForAdmin`) + 2 interface (`InterOrgFullRow`, `InterOrgCreateFields`)
- `e_office_app_new/backend/src/server.ts` — Import `adminLgspRoutes` + import thêm `requireRoles` + mount `app.use('/api/admin', authenticate, requireRoles('Quản trị hệ thống'), adminLgspRoutes)` ngay sau `/api/lgsp` mount

## Decisions Made

1. **Tách file `admin-lgsp.ts` riêng thay vì extend `lgsp.ts`** — file lgsp.ts đã to (Phase 18+34+35 cộng dồn); admin endpoints có scope khác (role guard, mutation-heavy) → file riêng dễ maintain. Plan 37-02 sẽ extend cùng file này (test connection + overview).
2. **Encrypt secret tại route layer (lazy import `encryptSecret`)** — `lgspAgencyConfigRepository.upsert` đã nhận `secretKeyEncrypted: Buffer` (contract Phase 33). Route layer encrypt từ plaintext rồi pass Buffer → giữ separation of concerns.
3. **JOIN qua `outgoing_doc_recipients.generated_lgsp_tracking_id`** — Phase 34 wiring đã set FK direct từ recipient → tracking. Match qua đây robust hơn match qua dest_org_code (recipients có thể có nhiều org cùng code do auto-register Phase 35).
4. **Resolve environment retry: prefer 'prod'** — nếu unit có 2 row active (prod + sandbox cùng lúc) → ưu tiên prod để retry. Edge case rare nhưng deterministic.
5. **`secret_key_masked: '***'` explicit trong response** — SP `fn_lgsp_agency_config_list` KHÔNG trả `secret_key_encrypted` (intentional Phase 33), nhưng UI cần field `secret_key_masked` để hiển thị "***" trong column. Route map ngay tại response thay vì sửa SP.
6. **Verify columns inter_organizations tồn tại** — `\d edoc.inter_organizations` confirm `address VARCHAR(500)`, `email VARCHAR(200)`, `phone VARCHAR(50)` đã có (Phase 18 schema) → KHÔNG cần ALTER TABLE.

## Deviations from Plan

None — plan executed exactly as written.

- Plan đã skeleton hoá toàn bộ method bodies, route handlers, mount pattern. Implementation chỉ cần adapt:
  - `JOIN outgoing_doc_recipients` đúng FK `generated_lgsp_tracking_id` (Phase 34) thay vì match qua `recipient_type='external_org' AND recipient_org_code=t.dest_org_code` như skeleton gợi ý — skeleton sai vì `outgoing_doc_recipients` KHÔNG có cột `recipient_org_code` (chỉ có `recipient_org_id` FK tới `inter_organizations.id`). Đã verify bằng `\d edoc.outgoing_doc_recipients`.
  - Skeleton dùng `if (!result.rowCount > 0)` mà rawQuery return T[] (no rowCount), nên check `result.length === 0` thay thế — giữ idiomatic.

## Issues Encountered

- **(Minor)** Skeleton plan mô tả `outgoing_doc_recipients.recipient_org_code` không tồn tại — verify bằng `\d edoc.outgoing_doc_recipients` thấy schema thật dùng `recipient_org_id BIGINT FK` (không có code column). Đã dùng `generated_lgsp_tracking_id` FK direct (Phase 34 wiring) — cleaner approach.
- **(Minor)** PostgreSQL ORDER BY với expression `(ac.environment = 'prod') DESC NULLS LAST` — valid syntax, return NULL khi không có config → row vẫn match nhưng `environment IS NULL` check sau LIMIT 1 → return null từ method. Đúng intent.

## User Setup Required

None — endpoints sẵn sàng. Phase 37 frontend pages (Plan 37-03/04/05) sẽ wire vào.

Smoke test thủ công (sau khi backend start):

```bash
# Non-admin → 403
curl -s -X GET http://localhost:4000/api/admin/lgsp-agency-config -H "Authorization: Bearer <non_admin_token>"
# Expected: {"success":false,"message":"Forbidden — insufficient permissions"}

# Admin → 200 + 12 row
curl -s -X GET http://localhost:4000/api/admin/lgsp-agency-config -H "Authorization: Bearer <admin_token>"
# Expected: {"success":true,"data":[{"id":1,...,"secret_key_masked":"***"}, ...]}

# Inter-organizations list
curl -s "http://localhost:4000/api/admin/inter-organizations?page=1&pageSize=20" -H "Authorization: Bearer <admin_token>"
```

## Next Phase Readiness

- **Plan 37-02 (backend test-connection + overview)** unblocked — extend cùng file `admin-lgsp.ts` với 2 endpoint mới (`POST /lgsp-agency-config/:id/test`, `GET /lgsp-overview`). Reuse `getByIdWithDecryptedSecret` method đã có.
- **Plan 37-03 (frontend admin config page)** unblocked — gọi `GET /api/admin/lgsp-agency-config` + `PUT /api/admin/lgsp-agency-config/:id` + `PATCH .../active`.
- **Plan 37-04 (frontend overview dashboard)** unblocked (cần thêm overview endpoint Plan 37-02 trước).
- **Plan 37-05 (frontend catalog `/lgsp/co-quan`)** unblocked — gọi 4 endpoint CRUD inter-organizations.
- **Plan 37-06 (frontend retry button)** unblocked — gọi 2 retry endpoint outbox/tracking.

## Self-Check: PASSED

**Files created/modified verified:**
- FOUND: e_office_app_new/backend/src/routes/admin-lgsp.ts (302 lines)
- FOUND: e_office_app_new/backend/src/repositories/lgsp-agency-config.repository.ts (+ getByIdWithDecryptedSecret)
- FOUND: e_office_app_new/backend/src/repositories/lgsp-status-outbox.repository.ts (+ resetForRetry)
- FOUND: e_office_app_new/backend/src/repositories/lgsp.repository.ts (+ getTrackingForRetry, resetTrackingForRetry, LgspTrackingFullRow)
- FOUND: e_office_app_new/backend/src/repositories/inter-organization.repository.ts (+ 4 method, 2 interface)
- FOUND: e_office_app_new/backend/src/server.ts (+ import adminLgspRoutes, requireRoles, + mount line)

**Commits verified:**
- FOUND: 95d93de (Task 1 — repo extends)
- FOUND: ee7bb3d (Task 2 — admin-lgsp.ts)
- FOUND: a9958da (Task 3 — server.ts mount)

**Acceptance criteria check:**
- ✓ `router.(get|post|put|patch|delete)` count in admin-lgsp.ts = 9 (verified via grep — 9 matches)
- ✓ `/lgsp-agency-config`, `/lgsp-status-outbox/:id/retry`, `/lgsp-tracking/:id/retry`, `/inter-organizations` all present
- ✓ `enqueueLgspSendJob`, `invalidateLgspServiceCache`, `encryptSecret` imports present
- ✓ Vietnamese diacritics: "Đã cập nhật", "Đã bật", "Đã tắt", "Mã cơ quan", "Tên cơ quan" all present
- ✓ `cd e_office_app_new/backend && npx tsc --noEmit` exit 0
- ✓ `cd e_office_app_new/backend && npm run build` exit 0

---
*Phase: 37-admin-ui-catalog-go-live*
*Completed: 2026-05-21*
