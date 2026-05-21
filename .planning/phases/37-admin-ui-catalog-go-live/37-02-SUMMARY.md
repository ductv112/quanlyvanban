---
phase: 37-admin-ui-catalog-go-live
plan: 02
subsystem: backend
tags: [admin, lgsp, test-connection, overview, inter-org-sync, express, postgres, phase-37]

# Dependency graph
requires:
  - phase: 37-admin-ui-catalog-go-live
    plan: 01
    provides: admin-lgsp.ts (9 endpoint) + lgspAgencyConfigRepository.getByIdWithDecryptedSecret + lgspStatusOutboxRepository.resetForRetry + lgspRepository.resetTrackingForRetry + interOrganizationRepository.{listForAdmin,createForAdmin,updateForAdmin,deleteForAdmin,findByCode}
  - phase: 33-credential-store-encrypt
    provides: createLgspRealService(credentials) + getLgspService(unit_id, env) + invalidateLgspServiceCache
  - phase: 34-send-flow-sendedoc
    provides: LGSPRealService.receiveDocuments(fromDate, toDate) chuẩn signature YYYY/MM/DD
  - phase: 35-receive-flow-cron-syncreceivededoclist
    provides: lgsp-real.service.ts receiveDocuments() qua /v1/syncReceivedEdocList header X-SystemId/X-SecretKey
  - phase: 18-lgsp-foundation
    provides: ILgspService.syncOrganizations() qua factory getLgspService — reuse cho inter-org sync endpoint

provides:
  - "3 endpoint admin mới trong /api/admin/* (admin-lgsp.ts): POST /lgsp-agency-config/:id/test, GET /lgsp-overview, POST /inter-organizations/sync"
  - "lgspRepository.getOverviewStats() — aggregate count today (send/receive/outbox) per root unit (6 DN) + interface LgspOverviewRow"
  - "formatLgspDate(d): string helper chuẩn LGSP API YYYY/MM/DD"
  - "Admin có endpoint test connection thật (lightweight read-only KHÔNG side effect), endpoint dashboard overview với totals aggregated, endpoint sync danh sách cơ quan từ LGSP"

affects: [37-03-frontend-admin-config, 37-04-frontend-overview, 37-05-frontend-catalog]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Test connection KHÔNG cache — createLgspRealService() trực tiếp với credential mới lookup (cache invalidate đã handle ở PUT update)"
    - "Endpoint /test trả success=true cả khi LGSP fail — data.ok=false + Vietnamese error message + http_status (UI dễ render kết quả test inline)"
    - "Overview aggregate qua CTE PostgreSQL (root_units + 3 CTE aggregation) + COALESCE 0 cho COUNT NULL khi LEFT JOIN không match"
    - "Inter-org sync reuse Phase 18 ILgspService.syncOrganizations() qua getLgspService factory — KHÔNG duplicate fetch logic"

key-files:
  created: []
  modified:
    - e_office_app_new/backend/src/repositories/lgsp.repository.ts (+ LgspOverviewRow interface + getOverviewStats method)
    - e_office_app_new/backend/src/routes/admin-lgsp.ts (+ formatLgspDate helper + 3 endpoint mới = tổng 12 endpoints)

key-decisions:
  - "Test connection dùng createLgspRealService() trực tiếp (KHÔNG getLgspService cached) — admin có thể test ngay sau khi save credential mới"
  - "Endpoint /test trả success=true + data.ok=false khi LGSP error — request OK chỉ là test failed; tránh confuse với 5xx server error"
  - "http_status=0 khi network/timeout (chưa có HTTP code), http_status=200 khi success — UI render badge theo http_status"
  - "Overview SQL dùng CTE thay vì 4 query Promise.all — single roundtrip + LEFT JOIN tự nhiên cho 6 row baseline"
  - "Overview COUNT FILTER (WHERE...) per status — atomic aggregate KHÔNG cần subquery riêng cho mỗi status"
  - "Inter-org sync lookup 1 DN active đầu tiên (allConfigs.find) thay vì query SQL riêng — dùng cached list result, đơn giản"
  - "Inter-org sync UPSERT theo code: findByCode → có thì updateForAdmin, không có thì createForAdmin — reuse Plan 37-01 admin CRUD methods, KHÔNG thêm method mới"

patterns-established:
  - "Helper inline trong route file khi chỉ dùng 1 lần (formatLgspDate) — KHÔNG tạo lib riêng cho 6 dòng code"
  - "Test endpoint response shape: { success: true, data: { ok, message, http_status, response_summary } } — frontend render Modal inline result"
  - "Overview totals reduce pattern — accumulate qua single pass thay vì .map().reduce() lặp"

requirements-completed: [LGSP-UI-03, LGSP-UI-04, LGSP-UI-06]

# Metrics
duration: ~15 min
completed: 2026-05-21
---

# Phase 37 Plan 02: Backend Test Connection + Dashboard Overview + Inter-Org Sync Summary

**3 endpoint mới (test connection + overview + inter-org sync) extend admin-lgsp.ts → tổng 12 endpoints admin LGSP — Wave 2 backend ready cho Plan 37-03/04/05 frontend pages**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-05-21
- **Completed:** 2026-05-21
- **Tasks:** 2/2
- **Files modified:** 2 (extend)

## Accomplishments

- Extend `lgsp.repository.ts` với `getOverviewStats()` method + `LgspOverviewRow` interface — CTE PostgreSQL aggregate count today (send/receive/outbox) per root unit (6 DN Lạng Sơn)
- Extend `admin-lgsp.ts` với 3 endpoint mới + helper `formatLgspDate(d)`:
  - `POST /lgsp-agency-config/:id/test` — Test connection thật qua `receiveDocuments(now-1d, now)` lightweight read-only
  - `GET /lgsp-overview` — Dashboard summary: 6 units rows + totals aggregated (sent/received/callback today + active count)
  - `POST /inter-organizations/sync` — Batch sync cơ quan từ LGSP qua Phase 18 `syncOrganizations()`, UPSERT vào `inter_organizations` qua reuse `findByCode + create/updateForAdmin` Plan 37-01 methods
- TypeScript strict + production `npm run build` PASS (zero error)
- Total admin LGSP endpoints: 9 (Plan 37-01) + 3 (Plan 37-02) = 12 endpoints sẵn sàng cho 3 page admin UI (Plan 37-03/04/05)

## Task Commits

1. **Task 1: Thêm getOverviewStats vào lgsp.repository.ts** — `4b12f40` (feat)
2. **Task 2: Extend admin-lgsp.ts với 3 endpoint mới** — `c0c8268` (feat)

## Files Created/Modified

- `e_office_app_new/backend/src/repositories/lgsp.repository.ts` — Thêm interface `LgspOverviewRow` (18 fields per unit) + method `getOverviewStats()` query CTE PostgreSQL với 4 CTE:
  - `root_units` — base 6 DN có `lgsp_org_code IS NOT NULL`
  - `send_today` — COUNT lgsp_tracking direction='send' grouped by outgoing_docs.unit_id, with FILTER per status
  - `receive_today` — COUNT incoming_docs WHERE source_type='external_lgsp' grouped by unit_id
  - `outbox_today` — COUNT lgsp_status_outbox JOIN incoming_docs grouped by unit_id, with FILTER per sent_status
  - SELECT main: LEFT JOIN prod_config + sandbox_config + 3 aggregation CTE → trả 1 row per DN với 18 column, ORDER BY lgsp_org_code
- `e_office_app_new/backend/src/routes/admin-lgsp.ts` — Thêm:
  - Import `getLgspService` (factory Phase 33) + `createLgspRealService` (Phase 34 per-instance)
  - Helper `formatLgspDate(d)` — chuẩn LGSP API YYYY/MM/DD
  - Endpoint POST `/lgsp-agency-config/:id/test` — lookup credential decrypted → createLgspRealService → receiveDocuments(yesterday, today) → response standardized
  - Endpoint GET `/lgsp-overview` — `lgspRepository.getOverviewStats()` + reduce totals
  - Endpoint POST `/inter-organizations/sync` — lookup active config → getLgspService → syncOrganizations() → UPSERT loop

## Decisions Made

1. **Test connection dùng `createLgspRealService()` trực tiếp** thay vì `getLgspService()` cached. Lý do: admin có thể edit credential rồi click test ngay → cache đã invalidate ở PUT update, nhưng dùng trực tiếp tránh phụ thuộc thứ tự call. Cũng cho phép test config `is_active=FALSE` (Phase 33 factory throw nếu inactive).

2. **Endpoint /test trả `success=true` cả khi LGSP fail** + `data.ok=false` + Vietnamese error message + `http_status` (200/0). Lý do: phân biệt rõ "request to backend OK" vs "LGSP credential/endpoint error". 5xx server error vẫn handle qua `handleDbError`.

3. **http_status=0 khi network/timeout** (chưa nhận HTTP code từ LGSP), http_status=200 khi success. UI Plan 37-03 render badge theo http_status (green/red/grey).

4. **Overview SQL dùng CTE single query** thay vì 4 query Promise.all. Lý do: 6 row baseline + LEFT JOIN tự nhiên, single roundtrip nhanh hơn parallel queries trên local DB. CTE dễ debug + explain.

5. **Overview COUNT FILTER (WHERE...)** per status — atomic aggregate inline, KHÔNG cần subquery riêng cho mỗi status. PostgreSQL chuẩn.

6. **Inter-org sync lookup 1 DN active đầu tiên** qua `allConfigs.find(c => c.is_active)` thay vì query SQL riêng. Lý do: `allConfigs` đã load — dùng JS find đơn giản hơn. Trade-off chấp nhận: KHÔNG ưu tiên prod over sandbox (sync result giống nhau, danh sách orgs từ LGSP độc lập với env).

7. **Inter-org sync UPSERT theo code** qua `findByCode` (Plan 35-01) → `updateForAdmin` hoặc `createForAdmin` (Plan 37-01). KHÔNG thêm `upsertFromLgsp` method mới — reuse code. Trade-off: 2 DB round-trips per org (find + update/insert) thay vì 1 UPSERT — chấp nhận vì danh sách ~50 orgs, không bottleneck.

## Deviations from Plan

None — plan executed exactly as written.

- Plan skeleton đã chính xác — chỉ adapt nhỏ:
  - Tên alias trong CTE: dùng `ind` (incoming_docs) thay vì `id` (conflict với cột `id` — bài học Phase 5 #6 CLAUDE.md SQL alias conflict)
  - `createLgspRealService` (Phase 34 factory) thay vì `new LGSPRealService(...)` trực tiếp — match Phase 34 pattern + tránh import class
  - `getLgspService(unitId, environment)` đúng signature 2 args (Phase 33)

## Issues Encountered

- **(Minor)** Plan skeleton inter-org sync gợi ý thêm method `upsertFromLgsp` mới + `LGSPRealService.getAgenciesList()` mới — nhưng kiểm tra Phase 18 đã có `ILgspService.syncOrganizations()` factory pattern hoạt động qua `/api/lgspedoc/organizations` (login token flow). Đã reuse hoàn toàn — KHÔNG cần thêm method mới. Nếu sau này Postman collection xác định endpoint chính xác là `/v1/getAgenciesList` (header X-SystemId/X-SecretKey) thay vì `/api/lgspedoc/organizations` (token), thì sửa Phase 18 `lgsp-real.service.ts.syncOrganizations()` 1 chỗ — KHÔNG đụng admin endpoint.

## User Setup Required

None — endpoints sẵn sàng. Frontend Plan 37-03/04/05 sẽ wire vào.

**Smoke test (sau khi backend start + admin login):**

```bash
# Lấy token admin
TOKEN=$(curl -s -X POST http://localhost:4000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"Admin@123"}' | jq -r '.data.access_token')

# 1. Test connection (giả sử config id=1 — dev DB có thể chưa có config)
curl -s -X POST http://localhost:4000/api/admin/lgsp-agency-config/1/test \
  -H "Authorization: Bearer $TOKEN" | jq
# Expected: { success: true, data: { ok: true/false, message: "...", http_status: 200/0, response_summary: {...} | null } }

# 2. Overview (trả empty units array vì dev DB chưa có DN nào có lgsp_org_code)
curl -s http://localhost:4000/api/admin/lgsp-overview \
  -H "Authorization: Bearer $TOKEN" | jq
# Expected: { success: true, data: { units: [], totals: {send_today:0, ...} } }

# 3. Sync (cần ít nhất 1 active config — dev chưa setup → 400)
curl -s -X POST http://localhost:4000/api/admin/inter-organizations/sync \
  -H "Authorization: Bearer $TOKEN" | jq
# Expected: { success: false, message: "Cần ít nhất 1 cấu hình LGSP đang bật..." }
```

## Next Phase Readiness

- **Plan 37-03 (frontend admin config page `/lgsp/cau-hinh`)** unblocked — đủ 6 endpoints:
  - `GET /api/admin/lgsp-agency-config` (Plan 37-01)
  - `PUT /api/admin/lgsp-agency-config/:id` (Plan 37-01)
  - `PATCH /api/admin/lgsp-agency-config/:id/active` (Plan 37-01)
  - `POST /api/admin/lgsp-agency-config/:id/test` (Plan 37-02 — NEW)
- **Plan 37-04 (frontend overview dashboard `/lgsp`)** unblocked — `GET /api/admin/lgsp-overview` (Plan 37-02 — NEW) trả 6 unit rows + totals
- **Plan 37-05 (frontend catalog `/lgsp/co-quan`)** unblocked — đủ 5 endpoints:
  - 4 CRUD Plan 37-01: GET/POST/PUT/DELETE `/inter-organizations`
  - `POST /api/admin/inter-organizations/sync` (Plan 37-02 — NEW) cho button "Sync từ LGSP"
- **Plan 37-06 (frontend retry button)** unblocked từ Plan 37-01

## Self-Check: PASSED

**Files modified verified:**

- FOUND: e_office_app_new/backend/src/repositories/lgsp.repository.ts (+ LgspOverviewRow interface + getOverviewStats method, 123 lines added)
- FOUND: e_office_app_new/backend/src/routes/admin-lgsp.ts (+ formatLgspDate helper + 3 endpoint mới = 12 total endpoints, 182 insertions / 1 deletion)

**Commits verified:**

- FOUND: 4b12f40 (Task 1 — getOverviewStats repository extension)
- FOUND: c0c8268 (Task 2 — 3 admin endpoints in admin-lgsp.ts)

**Acceptance criteria check:**

- ✓ `grep -c "LgspOverviewRow\|getOverviewStats\|send_today_total\|receive_today_total\|outbox_today_pending" lgsp.repository.ts` → 9 (all required strings present)
- ✓ `grep -c "router\.(get|post|put|patch|delete)" admin-lgsp.ts` → exactly 12 (9 Plan 37-01 + 3 Plan 37-02)
- ✓ `/lgsp-agency-config/:id/test`, `/lgsp-overview`, `/inter-organizations/sync` all present
- ✓ `formatLgspDate`, `createLgspRealService` imports present
- ✓ Vietnamese diacritics: "Kết nối LGSP thành công", "Đồng bộ thành công", "Không thể kết nối LGSP", "Không tìm thấy cấu hình LGSP" all present
- ✓ `cd e_office_app_new/backend && npx tsc --noEmit` exit 0
- ✓ `cd e_office_app_new/backend && npm run build` exit 0

---
*Phase: 37-admin-ui-catalog-go-live*
*Completed: 2026-05-21*
