---
phase: 09-admin-config-provider-adapters
plan: 02
subsystem: backend
tags: [signing, api, admin, encryption, stats, stored-procedure, rbac]

# Dependency graph
requires:
  - phase: 08-04
    provides: signingProviderConfigRepository + encryptSecret + maskSecret
  - phase: 09-01
    provides: getProviderByCode dispatcher + SigningProvider interface
provides:
  - database/migrations/042_signing_stats_sp.sql — fn_signing_stats per provider
  - routes/ky-so-cau-hinh.ts — 6 Admin endpoints /api/ky-so/cau-hinh*
  - server.ts mount with requireRoles('Quản trị hệ thống')
affects:
  - Phase 9 Plan 03 (Admin config frontend page) — consumes 6 endpoints này
  - Phase 10+ (sign flow) — không dùng trực tiếp, nhưng là foundation cho Admin UI

# Tech tracking
tech-stack:
  added: []  # Zero new deps — reuse Phase 8/9-01 primitives
  patterns:
    - "Plaintext-in, BYTEA-out boundary: body.client_secret → encryptSecret() → repo receives Buffer — plaintext never persists"
    - "Response masking: client_secret_masked: '***' literal, never send ciphertext Buffer or plaintext back"
    - "Longer-prefix-wins mount order: /api/ky-so/cau-hinh mounted BEFORE /api/ky-so to route correctly"
    - "Skeleton-row GET pattern: always return 2 providers (even never-configured) so UI renders both SmartCA + MySign rows"
    - "Test-connection via pure dispatcher: getProviderByCode(code) takes credentials from body, no DB lookup — Admin can test NEW credentials before save"
    - "PUT re-encrypt guard: body.client_secret omitted/empty → reuse existing Buffer, only encrypt when user provides new secret"
    - "Whitelist validation before dispatch (T-09-11 Spoofing): validateProviderCode(body.provider_code) is ProviderCode type-guard prevents invalid inputs hitting provider-factory switch"

key-files:
  created:
    - e_office_app_new/database/migrations/042_signing_stats_sp.sql
    - e_office_app_new/backend/src/routes/ky-so-cau-hinh.ts
    - .planning/phases/09-admin-config-provider-adapters/09-02-SUMMARY.md
  modified:
    - e_office_app_new/backend/src/server.ts

key-decisions:
  - "Migration 042 (not 041 as plan draft said) — 041 đã được dùng bởi migrate_sign_phone trong Phase 8. Rule 3 auto-fix: không thể đè migration hiện có."
  - "GET / trả array 2 rows always (skeleton cho provider chưa cấu hình) — UI chỉ cần render 1 vòng lặp, không phân biệt 'đã có config' vs 'chưa có'. Cleaner hơn client-side merge."
  - "Stats tính in-parallel bằng Promise.all cho 2 provider code — tránh 2 round-trip SQL sequential."
  - "PUT dùng provider_code + id matching thay vì getById riêng — existing repository chỉ có getByCode, không muốn extend repository cho 1 route. Check existing.id === id đủ bảo đảm consistency."
  - "DELETE guard is_active trước khi DELETE — database cũng có partial unique index nhưng app-level guard trả message tiếng Việt rõ ràng (409 Conflict)."
  - "test-connection trả 200 cho cả success=true/false (distinguish bằng data.test_result: 'OK'|'FAILED') — 400/502 chỉ dùng cho invalid input / network error, keep response shape consistent với FE expectation."
  - "Longer-prefix mount BEFORE generic: '/api/ky-so/cau-hinh' trước '/api/ky-so' — Express matches in registration order. Confirmed in existing pattern (line 70-72 thong-ke trước ho-so-cong-viec)."

patterns-established:
  - "Pattern: Secret boundary routes — encrypt at controller, mask in response, reuse on update-without-secret"
  - "Pattern: Skeleton GET for admin config tables — return whitelisted keys even when no DB row exists"
  - "Pattern: Parallel stats fetch via Promise.all for per-entity aggregates"

requirements-completed: [SIGN-01, SIGN-02, CFG-01, CFG-02, CFG-03, CFG-04, CFG-07]

# Metrics
duration: ~4min
completed: 2026-04-21
---

# Phase 9 Plan 2: Admin Config API Summary

**6 Admin-only endpoints `/api/ky-so/cau-hinh*` + `fn_signing_stats` SP — wrap Plan 01 providers với encrypt/decrypt boundary (plaintext body → BYTEA DB → '***' response). Admin UI consumer: GET liệt kê 2 provider với stats, POST/PUT lưu credentials đã encrypt, POST /test-connection thử credentials chưa lưu qua pure dispatcher, PATCH /active auto-deactivate provider khác, DELETE block nếu active. Mount order `/cau-hinh` BEFORE generic `/api/ky-so` đảm bảo role guard Admin-only không leak ra mock sign endpoints cũ. Zero new TS errors (21 pre-existing unchanged baseline).**

## Performance

- **Duration:** ~4 min (2026-04-21T07:33:24Z → 2026-04-21T07:37:28Z)
- **Tasks:** 3 (migration + route + mount)
- **Files created:** 2 (1 SQL migration + 1 route TS)
- **Files modified:** 1 (server.ts +3 lines)
- **Total lines added:** 553 lines (75 SQL + 475 TS route + 3 server mount)

## Accomplishments

- **`public.fn_signing_stats(p_provider_code VARCHAR)` SP**: trả 5 stats (total_users, verified_users, monthly_transactions, monthly_completed, monthly_failed) per provider code. STABLE + CREATE OR REPLACE + idempotent + NULL-safe + reserved-word `"status"` quoted. Applied vào live DB, smoke test pass cho SMARTCA_VNPT / MYSIGN_VIETTEL / NULL (all 0s).

- **6 endpoints Admin-only** tại `routes/ky-so-cau-hinh.ts`:
  1. **GET `/`** — list 2 providers (luôn 2 rows, skeleton cho chưa configured) + stats parallel + mask secret. Trả `active_code` top-level cho UI hiển thị badge.
  2. **POST `/test-connection`** — dispatch `getProviderByCode(body.provider_code).testConnection(...)` với credentials từ body (không lookup DB). Trả `{test_result: 'OK'|'FAILED', message, certificate_subject}`. Network error → 502 với Vietnamese message.
  3. **POST `/`** — validate + `encryptSecret(body.client_secret)` → `repository.upsert(...)`. Optional `set_active: true` → call `setActive` sau upsert. Trả 201 + id.
  4. **PUT `/:id`** — lookup existing qua getByCode + id match. Re-encrypt chỉ khi `body.client_secret` được cung cấp (≥ 8 chars), ngược lại reuse `existing.client_secret` Buffer. Giữ `last_tested_at`/`test_result` cũ (credential mới chưa test).
  5. **PATCH `/:id/active`** — rawQuery lookup `provider_code` từ id → `setActive(code, staffId)`. SP tự động deactivate provider khác (partial unique index bảo vệ).
  6. **DELETE `/:id`** — rawQuery check `is_active` → 409 với message tiếng Việt nếu đang active, ngược lại DELETE + 200.

- **Security mitigations** (5/6 STRIDE threats handled):
  - T-09-07 (Information Disclosure): Grep audit confirm response JSON chỉ chứa `client_secret_masked: '***'`, không có `client_secret:` literal trong response construction.
  - T-09-08 (Elevation of Privilege): server.ts mount với `requireRoles('Quản trị hệ thống')` — middleware chain reject non-admin 403 trước khi route handler chạy.
  - T-09-09 (Tampering): id param cast `Number(req.params.id)` + finiteness check + existing row lookup trước khi mutation.
  - T-09-10 (DoS): Phase 9 Plan 01 adapter có AbortController timeout 15s — acceptable cho Admin-only low-volume endpoint.
  - T-09-11 (Spoofing): `validateProviderCode()` whitelist check trước khi gọi `getProviderByCode()` — double-defense với factory switch default.

- **Mount ordering verified**: `/api/ky-so/cau-hinh` (line 93) BEFORE `/api/ky-so` (line 94) — Express registration-order matching bảo đảm admin requireRoles không leak ra digital-signature mock routes.

- **TypeScript clean**: `npx tsc --noEmit` → 21 pre-existing errors (same baseline as Plan 09-01), 0 new errors in ky-so-cau-hinh.ts hoặc server.ts.

## Task Commits

Each task committed atomically on main branch:

1. **Task 1: Migration 042 — fn_signing_stats SP** — `8319779` (feat)
2. **Task 2: Route ky-so-cau-hinh.ts với 6 endpoints** — `9223770` (feat)
3. **Task 3: Mount route trong server.ts với requireRoles** — `1575898` (feat)

**Plan metadata commit:** _pending_ (docs: complete plan — next)

## Files Created

- `e_office_app_new/database/migrations/042_signing_stats_sp.sql` — **created** (75 lines)
  - `public.fn_signing_stats(p_provider_code VARCHAR(30))` RETURNS TABLE(5 INT columns)
  - LANGUAGE plpgsql STABLE + CREATE OR REPLACE
  - COMMENT ON FUNCTION — CFG-07 reference
  - Reserved-word `"status"` quoted in WHERE clauses (per CLAUDE.md checklist #4)

- `e_office_app_new/backend/src/routes/ky-so-cau-hinh.ts` — **created** (475 lines)
  - 6 router handlers (grep confirmed: `router.get/post/post/put/patch/delete`)
  - Constants: `VALID_CODES`, `PROVIDER_NAMES`, `EMPTY_STATS`
  - Helpers: `getStatsForProvider`, `validateProviderCode` (type guard), `validateBaseUrl`, `isNonEmptyString`
  - TSDoc + SECURITY comment banner tại top

## Files Modified

- `e_office_app_new/backend/src/server.ts` — **modified** (+3 lines)
  - Line 33: `import kySoCauHinhRoutes from './routes/ky-so-cau-hinh.js';`
  - Line 92-93: comment + `app.use('/api/ky-so/cau-hinh', authenticate, requireRoles('Quản trị hệ thống'), kySoCauHinhRoutes);`
  - Line 94: existing `/api/ky-so` generic mount (unchanged, now second in chain)

## Decisions Made

- **Migration number 042 thay vì 041**: Plan draft ghi 041 nhưng file 041_migrate_sign_phone.sql đã tồn tại từ Phase 8. Rule 3 auto-fix (blocker — không thể đè). Documented trong migration header comment.
- **Skeleton rows trong GET /**: trả 2 rows luôn (VALID_CODES) dù provider chưa configured — UI chỉ render 1 loop không phân biệt "đã config" vs "chưa config". Cleaner client code, không phải tự build 2 row giả bên FE.
- **Parallel stats với Promise.all**: 2 provider stats fetch song song thay vì sequential — 1 round-trip thay vì 2.
- **PUT không tạo repository.getById**: reuse existing `getByCode(body.provider_code)` + check `existing.id === id` — tránh extend repository cho 1 use-case. Tradeoff: body phải có provider_code (FE always có), acceptable.
- **DELETE guard app-level (is_active check)**: DB partial unique index bảo vệ insert/update 2 active cùng lúc, nhưng DELETE không bị block bởi DB. App-level check → message tiếng Việt rõ ràng "Không thể xóa provider đang được kích hoạt" cho UX.
- **test-connection luôn trả HTTP 200 cho provider response**: distinguish success/fail qua `data.test_result: 'OK'|'FAILED'`. HTTP 400 chỉ cho invalid input (bad provider_code, missing fields); HTTP 502 chỉ cho network/timeout. Frontend dễ handle một shape thống nhất.
- **Longer-prefix mount order**: `/api/ky-so/cau-hinh` BEFORE `/api/ky-so` — đã có tiền lệ trong codebase (line 71-72: `/api/ho-so-cong-viec/thong-ke` BEFORE `/api/ho-so-cong-viec`). Express match in registration order, longer path wins nhờ register trước.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 — Blocker] Migration number 041 đã được sử dụng**
- **Found during:** Task 1 — `ls database/migrations/` cho thấy `041_migrate_sign_phone.sql` đã tồn tại (Phase 8 MIG-03/04).
- **Issue:** Plan spec ghi `041_signing_stats_sp.sql` nhưng không thể đè migration đang chạy production. Conflict với naming uniqueness convention.
- **Fix:** Đặt migration là **042_signing_stats_sp.sql** — document trong header comment với giải thích rõ ràng.
- **Files modified:** `042_signing_stats_sp.sql` (new path — khác plan spec), plan frontmatter `files_modified` không match thực tế (acceptable — Rule 3 auto-fix).
- **Verification:** Migration applied to DB successfully, smoke test pass, idempotent on second run.
- **Committed in:** Task 1 (`8319779`)

**Total deviations:** 1 Rule 3 (blocker auto-fix) — migration number.
**Impact on plan:** Zero functional impact. SP name + signature + return shape 100% match plan spec. Only path differs (042 instead of 041).

### Intentional Enhancements (beyond plan text)

- **Skeleton rows trong GET /**: plan nói "If provider has never been configured, still include in response" nhưng không chi tiết schema. Implement trả full row với `id: null, has_secret: false, client_secret_masked: null, base_url: null, ...` + stats vẫn compute (returns 0s). UI có thể render form "Chưa cấu hình" trực tiếp.
- **POST `/` với set_active optional**: plan nói "If set_active === true → call setActive". Implement phân biệt 2 paths:
  - set_active=true + activate success → 201 với message "Lưu cấu hình thành công"
  - set_active=true + activate fail → vẫn 201 (config đã lưu) nhưng message warning "Lưu cấu hình thành công. Kích hoạt thất bại: {reason}"
  - Tránh rollback config khi chỉ activate fail, user có thể retry activate sau.
- **DELETE double-check trước khi xóa**: plan nói "Lookup by id. If is_active === true → 409". Implement ngoài check is_active còn check row exists (404 trước 409) — tránh user tưởng lầm record không tồn tại là "active".
- **PUT `/:id` giữ `last_tested_at` + `test_result` cũ**: plan không specify. Khi user update credentials mà không test lại, giữ lịch sử test cũ (reset về null sẽ gây UI nhầm "provider chưa từng test"). User vẫn phải test lại để cập nhật status.

## Verification Results

### Task 1 (Migration 042)
- File exists at `database/migrations/042_signing_stats_sp.sql` (75 lines)
- Applied to DB: `docker exec -i qlvb_postgres psql < 042_signing_stats_sp.sql` → `CREATE FUNCTION / COMMENT`
- Smoke test: `SELECT * FROM public.fn_signing_stats('SMARTCA_VNPT')` → 5 cols, all 0 (empty tables)
- Smoke test: `SELECT * FROM public.fn_signing_stats('MYSIGN_VIETTEL')` → 5 cols, all 0
- Smoke test: `SELECT * FROM public.fn_signing_stats(NULL)` → 5 cols, all 0 (no crash)
- Idempotency test: run migration 2nd time → `CREATE FUNCTION / COMMENT` (no error, OR REPLACE semantics)

### Task 2 (Route file)
- File exists at `backend/src/routes/ky-so-cau-hinh.ts` (475 lines)
- `grep "router\\." src/routes/ky-so-cau-hinh.ts` — **6 matches** (get, post /test-connection, post /, put /:id, patch /:id/active, delete /:id)
- Secret audit: `grep "client_secret"` → 14 matches, all safe (comment + validation + encryptSecret + clientSecretPlaintext to provider + existing.client_secret reuse + masked response)
- `npx tsc --noEmit | grep "ky-so-cau-hinh"` → 0 errors
- All Vietnamese error messages (checked bằng grep "message: '" — every construction có Vietnamese text)

### Task 3 (Server mount)
- `grep -n "kySoCauHinhRoutes\|api/ky-so/cau-hinh\|api/ky-so'" server.ts` confirms:
  - Line 33: `import kySoCauHinhRoutes from './routes/ky-so-cau-hinh.js';`
  - Line 93: `app.use('/api/ky-so/cau-hinh', authenticate, requireRoles('Quản trị hệ thống'), kySoCauHinhRoutes);`
  - Line 94: `app.use('/api/ky-so', authenticate, digitalSignatureRoutes);`
- Mount order: longer-prefix FIRST → admin requireRoles guard doesn't leak to digital-signature routes
- `npx tsc --noEmit | grep "server\\.ts"` → 0 errors
- Total tsc error count: 21 (same pre-existing baseline as Plan 09-01)

### Live smoke test
- Backend dev server không chạy tại thời điểm execute (curl health check trả 000). Fallback verification qua tsc + mount grep đầy đủ.
- Live curl test sẽ thực hiện bởi Plan 03 khi backend được start cho frontend development.

## API Reference for Phase 9 Plan 03 (Frontend Consumer)

**All endpoints require `Authorization: Bearer {admin-jwt}` header + role `'Quản trị hệ thống'`:**

### GET `/api/ky-so/cau-hinh`
Response:
```json
{
  "success": true,
  "data": {
    "providers": [
      {
        "id": 1,
        "provider_code": "SMARTCA_VNPT",
        "provider_name": "SmartCA VNPT",
        "base_url": "https://gwsca.vnpt.vn",
        "client_id": "sp_xxx",
        "profile_id": null,
        "extra_config": {},
        "is_active": true,
        "last_tested_at": "2026-04-21T...",
        "test_result": "OK",
        "created_at": "...",
        "updated_at": "...",
        "has_secret": true,
        "client_secret_masked": "***",
        "stats": { "total_users": 10, "verified_users": 8, "monthly_transactions": 25, "monthly_completed": 22, "monthly_failed": 3 }
      },
      {
        "id": null,
        "provider_code": "MYSIGN_VIETTEL",
        "provider_name": "MySign Viettel",
        "base_url": null,
        "client_id": null,
        "profile_id": null,
        "extra_config": {},
        "is_active": false,
        "last_tested_at": null,
        "test_result": null,
        "created_at": null,
        "updated_at": null,
        "has_secret": false,
        "client_secret_masked": null,
        "stats": { "total_users": 0, "verified_users": 0, "monthly_transactions": 0, "monthly_completed": 0, "monthly_failed": 0 }
      }
    ],
    "active_code": "SMARTCA_VNPT"
  }
}
```

### POST `/api/ky-so/cau-hinh/test-connection`
Body: `{provider_code, base_url, client_id, client_secret, profile_id?}`
Response 200: `{success: true, data: {test_result: "OK"|"FAILED", message, certificate_subject}}`
Response 400: invalid input — provider_code not whitelisted, base_url not HTTPS, missing fields
Response 502: network/timeout error

### POST `/api/ky-so/cau-hinh`
Body: `{provider_code, provider_name, base_url, client_id, client_secret (min 8 chars), profile_id?, extra_config?, set_active?}`
Response 201: `{success: true, message, data: {id}}`
Response 400: validation error (unique violation handled via 409 in handleDbError)

### PUT `/api/ky-so/cau-hinh/:id`
Body: same as POST but `client_secret` optional (omit/empty = keep existing cipher)
Response 200: `{success: true, message: "Cập nhật thành công"}`
Response 404: id không khớp với provider_code trong body

### PATCH `/api/ky-so/cau-hinh/:id/active`
No body required.
Response 200: `{success: true, message: "Kích hoạt provider thành công"}`
Response 404: id không tồn tại

### DELETE `/api/ky-so/cau-hinh/:id`
Response 200: `{success: true, message: "Xóa thành công"}`
Response 409: `{success: false, message: "Không thể xóa provider đang được kích hoạt..."}` — user phải activate provider khác trước
Response 404: id không tồn tại

## Issues Encountered

- **Migration 041 conflict** (resolved Rule 3): Plan draft sai số migration. Fix: dùng 042, documented trong header.
- **None critical.** 3 tasks executed linearly theo plan spec, verification pass all gates.

## User Setup Required

- **None.** Migration 042 đã applied vào dev DB. Route mount registered. Restart backend dev server khi muốn test live endpoints (`npm run dev` trong `backend/`).
- Existing env `SIGNING_SECRET_KEY` (Phase 8) vẫn cần thiết — `encryptSecret()` trong POST/PUT sẽ throw nếu unset.

## Next Phase Readiness

- **Ready for Phase 9 Plan 03 (Admin config frontend page)**:
  - UI có thể consume 6 endpoints với response shape documented trên.
  - Skeleton row pattern cho phép FE render 2 provider cards ngay cả khi DB trống.
  - Mask '***' + placeholder "Nhập để thay đổi" cho secret field — user không thấy plaintext đã lưu.
  - test-connection endpoint hỗ trợ test TRƯỚC khi save (credentials từ form, không cần DB lookup).
- **Not blocking Phase 10/11**: provider-factory vẫn dùng `getActiveProviderWithCredentials()` từ Plan 09-01. Admin config chỉ là UI để set up DB rows; runtime flow không đổi.

## Self-Check: PASSED

Verified:
- File `e_office_app_new/database/migrations/042_signing_stats_sp.sql` exists (75 lines)
- File `e_office_app_new/backend/src/routes/ky-so-cau-hinh.ts` exists (475 lines)
- File `e_office_app_new/backend/src/server.ts` modified (+3 lines: import + mount with requireRoles)
- Commit `8319779` exists: `feat(09-02): add fn_signing_stats SP for Admin config page (CFG-07)`
- Commit `9223770` exists: `feat(09-02): add 6 Admin endpoints /api/ky-so/cau-hinh* (CFG-01..04, CFG-07)`
- Commit `1575898` exists: `feat(09-02): mount /api/ky-so/cau-hinh admin routes with requireRoles guard`
- `grep -c "router\\." src/routes/ky-so-cau-hinh.ts` = 6 (matches 6 endpoints)
- `grep "api/ky-so" src/server.ts` returns 2 lines, `/cau-hinh` line FIRST (line 93 before line 94)
- `grep "requireRoles" src/server.ts | grep "cau-hinh"` confirms admin guard applied
- Migration smoke test in DB: 3 calls (SMARTCA_VNPT, MYSIGN_VIETTEL, NULL) all return 5 cols 0s, no error
- Idempotency: migration re-run → `CREATE FUNCTION / COMMENT` (no error)
- `npx tsc --noEmit` in backend → 21 pre-existing errors (unchanged baseline, **0 new** in ky-so-cau-hinh.ts hoặc server.ts)

---
*Phase: 09-admin-config-provider-adapters*
*Completed: 2026-04-21*
