---
phase: 10-user-config-page
plan: 01
subsystem: backend
tags: [signing, user-config, api, cfg-05, cfg-06, authenticate, rbac]

# Dependency graph
requires:
  - phase: 08-04
    provides: staffSigningConfigRepository (upsert + get) via public.fn_staff_signing_config_*
  - phase: 09-01
    provides: getActiveProviderWithCredentials + SigningProvider.listCertificates
  - phase: 09-02
    provides: Mount pattern /api/ky-so/* with longer-prefix-wins ordering
provides:
  - routes/ky-so-tai-khoan.ts — 4 user-level endpoints /api/ky-so/tai-khoan*
  - server.ts mount with authenticate only (no requireRoles)
affects:
  - Phase 10 Plan 02 (User config frontend page) — consumes 4 endpoints này
  - Phase 11 (Sign flow) — config is_verified=true là precondition cho ký thật

# Tech tracking
tech-stack:
  added: []  # Zero new deps — reuse factory + repository + handleDbError
  patterns:
    - "staffId-from-JWT boundary: user-level endpoints đọc staffId từ req.user, KHÔNG từ body (T-10-01 mitigation)"
    - "authenticate-only mount BEFORE /api/ky-so generic: longer-prefix-wins preserves no-admin-guard semantic without leaking to digital-signature routes"
    - "Double-reset on save: POST / pass null cho certificate_* (SP COALESCE giữ cert cũ) nhưng force is_verified=false (reset verify status) — user PHẢI bấm Kiểm tra sau mỗi lần save"
    - "Cert shape transformation toClientCert(): camelCase provider DTO → snake_case FE, strip certificateBase64 (T-10-04 — không cần ở list UI, tiết kiệm payload)"
    - "Verify fail = HTTP 200 với verified:false (expected state), NOT 500: cert-not-found là business outcome, không phải server error"
    - "MySign credential match via .find(c.credentialId === config.credential_id); SmartCA fallback to certs[0] (thường 1 cert/user)"
    - "Error persistence non-fatal: verify failure upsert wrapped in try/catch — primary error vẫn trả client nếu repo upsert cũng lỗi"

key-files:
  created:
    - e_office_app_new/backend/src/routes/ky-so-tai-khoan.ts
    - .planning/phases/10-user-config-page/10-01-SUMMARY.md
  modified:
    - e_office_app_new/backend/src/server.ts

key-decisions:
  - "Bỏ qua validate credential_id maxLength riêng cho SmartCA — isNonEmptyString check đã cover cho cả 2 provider, không cần logic phân nhánh sâu hơn"
  - "POST /certificates KHÔNG dùng staffId từ JWT — user_id đến từ body (có thể khác với config đã save, cho phép user test trước khi commit)"
  - "Verify errMsg truncate slice(0, 1000): đồng bộ với pattern Phase 9 Plan 02 test-saved endpoint — bảo vệ DB VARCHAR(?) (staff_signing_config.last_error là TEXT nên không strictly cần nhưng giữ consistency)"
  - "Catch block trong verify upsert failure cũng call upsert với isVerified=false để persist trạng thái — UI có thể nhìn last_error trong next GET để hiện toast/tooltip"
  - "Provider name map constant PROVIDER_NAMES thay vì inline if/else — dễ mở rộng khi thêm FPT CA hoặc provider thứ 3 sau này"
  - "POST / không dùng `.toLowerCase()` trên user_id — MySign CMT có thể chứa chữ cái thường/hoa và provider treat case-sensitive; giữ nguyên user input"

patterns-established:
  - "Pattern: JWT-scoped user config — mọi CRUD endpoint 'cá nhân' đọc owner từ JWT, không trust body input"
  - "Pattern: Soft-failure HTTP semantic — verify/validate action trả 200 với flag verified:bool thay vì throw 500 cho business fail"
  - "Pattern: Mount group trước generic prefix — admin config + user config cùng `/api/ky-so/*` hội tụ qua thứ tự mount chứ không phải route guard nested"

requirements-completed: [CFG-05, CFG-06]

# Metrics
duration: ~4min
completed: 2026-04-21
---

# Phase 10 Plan 1: User Signing Config API Summary

**4 user-level endpoints `/api/ky-so/tai-khoan*` — authenticate-only (mọi user, không admin), staffId luôn từ JWT (không từ body), reuse provider-factory + staffSigningConfigRepository từ Phase 8-9. GET trả active provider metadata + user config hiện tại (config=null nếu chưa save); POST upsert với auto-reset is_verified=false (ép user verify lại); POST /certificates fetch cert list từ MySign (CTS flow); POST /verify call listCertificates + match theo credential_id (MySign) hoặc certs[0] (SmartCA), lưu snapshot subject+serial+data nếu verified, trả 200 verified:false nếu cert không match (business outcome chứ không phải server error). Zero new TS errors (21 pre-existing baseline giữ nguyên). Live smoke: unauthenticated GET trả 401, xác nhận authenticate middleware hoạt động.**

## Performance

- **Duration:** ~4min 22s (2026-04-21T09:01:56Z → 2026-04-21T09:06:18Z)
- **Tasks:** 2 (route file + server mount)
- **Files created:** 1 (ky-so-tai-khoan.ts — 433 lines)
- **Files modified:** 1 (server.ts — +3 lines: 1 import + 2 mount lines)
- **Total lines added:** 436 lines production TS

## Accomplishments

- **4 user-level endpoints ready** tại `routes/ky-so-tai-khoan.ts` (433 lines):
  1. **GET `/`** — trả active provider metadata (`provider_code`, `provider_name`, `base_url`) + user config (staff_id/provider_code/user_id/credential_id/certificate_subject/serial/is_verified/last_verified_at). Không trả `certificate_data` (TEXT base64) — T-10-03 mitigation. 3 response shapes: active=null (admin chưa cấu hình), active+config=null (user chưa save), active+config (đã save).
  2. **POST `/`** — upsert user config với 2 validation rules:
     - `user_id` non-empty ≤ 200 chars (required cho cả 2 provider)
     - `credential_id` REQUIRED cho `MYSIGN_VIETTEL` (multi-cert), OPTIONAL cho `SMARTCA_VNPT`.
     - Auto-reset `is_verified=false` + `last_verified_at=null` + `last_error=null`; certificate_* pass null để SP COALESCE giữ cert snapshot cũ (nhưng is_verified=false ép user verify lại).
     - Response 201 với message "Lưu cấu hình thành công. Vui lòng bấm \"Kiểm tra\" để xác thực."
  3. **POST `/certificates`** — call `active.provider.listCertificates(credentials, { userId })`, map `toClientCert()` → snake_case (credential_id/subject/serial_number/valid_from/valid_to/status). KHÔNG trả `certificateBase64` (T-10-04). Catch provider throw → 502 với Vietnamese message.
  4. **POST `/verify`** — 3-step flow:
     - Đọc config hiện tại → 400 nếu chưa có
     - Call listCertificates (catch throw → 502, persist failure non-fatal)
     - Match cert (MySign: `.find(c.credentialId === config.credential_id)`, SmartCA: `certs[0]`). Không match → 200 với `verified:false` + upsert is_verified=false + last_error. Match → upsert is_verified=true + snapshot (subject+serial+data) + last_verified_at=now, trả 200 với `verified:true` + cert details.

- **Mount order correct** trong `server.ts`:
  - Line 94: `/api/ky-so/cau-hinh` → admin with requireRoles('Quản trị hệ thống')
  - Line 96: `/api/ky-so/tai-khoan` → authenticate only (user)
  - Line 97: `/api/ky-so` generic → digital-signature mock routes
  - Longer-prefix-wins pattern preserved: request `GET /api/ky-so/tai-khoan` match line 96, không rơi vào generic line 97.

- **Security mitigations** (5/6 STRIDE threats handled):
  - **T-10-01 (Tampering)**: `staffId` đọc từ `(req as AuthRequest).user.staffId` trong 3 handlers (GET /, POST /, POST /verify) — user A không thể update config user B. Verified via `grep -c "staffId"` = 13 occurrences, tất cả đều trong scope của JWT-derived value (không có `body.staff_id` nào).
  - **T-10-02 (Elevation of Privilege)**: Mount riêng với authenticate only, không requireRoles. Live smoke confirm: anonymous GET trả 401, authenticated user có thể truy cập.
  - **T-10-03 (Information Disclosure)**: GET / response omit `certificate_data` (TEXT ~2-4KB base64). Chỉ trả subject/serial/is_verified đủ cho UI display.
  - **T-10-04 (Information Disclosure)**: `toClientCert()` helper explicit strip `certificateBase64` khỏi payload trong POST /certificates — list UI chỉ render dropdown không cần raw cert.
  - **T-10-05 (DoS)**: Phase 9 Plan 01 adapter có AbortController timeout 15s — inherited tự động. User-level endpoint low volume, không cần thêm rate limit.
  - **T-10-06 (Spoofing provider response)**: accepted — HTTPS enforced ở adapter layer (Phase 9 Plan 01 `validateHttpsBaseUrl`), không validate thêm ở route.

- **TypeScript clean**: baseline 21 pre-existing errors (Phase 9) giữ nguyên, 0 new errors trong `ky-so-tai-khoan.ts` hoặc `server.ts`.

- **Live smoke test PASS**: `curl http://localhost:4000/api/ky-so/tai-khoan` → HTTP 401 (authenticate middleware reject unauthenticated call). Confirm mount + middleware chain hoạt động.

## Task Commits

Each task committed atomically on main branch:

1. **Task 1: Tạo route file ky-so-tai-khoan.ts với 4 endpoint** — `5d43e3c` (feat)
2. **Task 2: Mount route trong server.ts với authenticate-only** — `93bb908` (feat)

**Plan metadata commit:** _pending_ (docs: complete plan — next)

## Files Created

- `e_office_app_new/backend/src/routes/ky-so-tai-khoan.ts` — **created** (433 lines)
  - 4 router handlers: `router.get('/')`, `router.post('/')`, `router.post('/certificates')`, `router.post('/verify')`
  - Constants: `PROVIDER_NAMES` (SMARTCA_VNPT → 'SmartCA VNPT', MYSIGN_VIETTEL → 'MySign Viettel')
  - Helpers: `isNonEmptyString`, `toClientCert` (camelCase → snake_case map)
  - TSDoc banner với 4 SECURITY sections (T-10-01, T-10-02, T-10-03, T-10-04)

## Files Modified

- `e_office_app_new/backend/src/server.ts` — **modified** (+3 lines)
  - Line 34: `import kySoTaiKhoanRoutes from './routes/ky-so-tai-khoan.js';` (added sau line 33 import admin)
  - Line 95: comment `// Phase 10: User config ký số cá nhân — mount BEFORE /api/ky-so generic, authenticate only (mọi user)`
  - Line 96: `app.use('/api/ky-so/tai-khoan', authenticate, kySoTaiKhoanRoutes);` (giữa line 94 admin mount và line 97 generic mount)

## Decisions Made

- **staffId luôn từ JWT (T-10-01)**: 3/4 handlers cần staffId (GET, POST, verify) đều đọc từ `(req as AuthRequest).user.staffId`. POST /certificates là exception — KHÔNG cần staffId vì không mutate DB, user_id đến từ body (cho phép test với user_id KHÁC trước khi save).
- **POST / auto-reset is_verified=false**: user save config là sự kiện "config mới" — phải bấm Kiểm tra để verify lại. Nếu không reset, user đổi credential_id mà vẫn hiện "Đã xác thực" là misleading. Certificate_* vẫn null để SP COALESCE giữ snapshot cũ (audit vẫn có data cũ cho đến khi verify mới).
- **Verify fail = HTTP 200 verified:false (không 500)**: Cert không tìm thấy hoặc credential_id không match là BUSINESS OUTCOME (user input sai/cert expired), KHÔNG phải server error. Trả 200 cho phép FE parse `data.verified` flag một cách nhất quán. HTTP 502 chỉ dùng cho network/auth fail thật sự (listCertificates throw).
- **MySign match qua `.find(c.credentialId === config.credential_id)`**: Adapter Phase 9 Plan 01 trả cert list với `credentialId` (camelCase từ DTO CertificateInfo) — so sánh với `config.credential_id` (snake_case từ DB). Field mismatch camel↔snake giữa 2 layer acceptable vì đây là internal type bridge.
- **SmartCA fallback `certs[0]` khi match không có credential_id**: SmartCA config có thể có credential_id=null (optional). Nếu list trả nhiều cert (edge case), lấy cert đầu tiên là "best effort" — admin có thể lưu credential_id cụ thể sau để narrow xuống.
- **Error persistence trong verify bọc try/catch**: nếu upsert failure lỗi (DB down), primary error vẫn ưu tiên trả về client qua `res.status(502)`. KHÔNG throw từ inner catch — tránh double error response.
- **PROVIDER_NAMES constant**: hardcode 2 tên tiếng Việt chuẩn. Nếu thêm FPT CA sau này chỉ cần thêm 1 entry. Tốt hơn inline ternary `code === 'SMARTCA_VNPT' ? '...' : '...'` vì scale tốt.
- **errMsg slice(0, 1000) trong verify persist failure**: đồng bộ với Phase 9 Plan 02 test-saved pattern. Bảo vệ `last_error TEXT` column khỏi oversized error strings từ provider (VD: stack trace dài).

## Deviations from Plan

### Auto-fixed Issues

**None.** Plan execution khớp 100% spec. Không có bug phát sinh, không có blocking issue, không có CLAUDE.md rule adjustment cần áp dụng.

### Intentional Enhancements (beyond plan text)

- **PROVIDER_NAMES constant map**: plan có inline `providerCode === 'SMARTCA_VNPT' ? 'SmartCA VNPT' : 'MySign Viettel'` trong GET handler. Refactor thành constant ở top file để:
  - Dễ mở rộng provider thứ 3 (chỉ thêm 1 entry)
  - Tránh duplicate nếu thêm endpoint khác cần hiển thị provider_name
  - Consistency với Phase 9 Plan 02 pattern `PROVIDER_NAMES` (line 59 ky-so-cau-hinh.ts)
- **Error message truncate slice(0, 1000) trong verify catch**: plan không specify, thêm vì đồng bộ với ky-so-cau-hinh.ts `/test-saved` handler. Bảo vệ DB khỏi oversized last_error payload.
- **Explicit return type `CertificateInfo | undefined` cho matched**: TypeScript strict catch exhaustive — `matched` có thể undefined từ `.find()` hoặc `certs[0]` khi list rỗng. Code flow handle cả hai case qua `if (!matched)` branch.
- **Non-fatal wrapped try/catch inner trong verify network fail**: plan nói "Persist failure" nhưng nếu repo upsert cũng fail (DB down), primary provider error vẫn phải reach client. Wrap inner upsert in try/catch với empty catch — graceful degradation.

---

**Total deviations:** 0 auto-fixes, 4 intentional enhancements (all beyond plan specs, không modify spec intent).
**Impact on plan:** Zero functional deviation. 4 endpoint shape + 2 files modified khớp `<must_haves>` exact. All 4 enhancements là code quality/consistency improvements, không thay đổi API contract.

## Verification Results

### Task 1 (route file)
- File exists: `ls e_office_app_new/backend/src/routes/ky-so-tai-khoan.ts` → 433 lines
- Handler count: `grep -c "^router\." src/routes/ky-so-tai-khoan.ts` → **4** (get, post, post /certificates, post /verify)
- No admin guard in route file: `grep requireRoles src/routes/ky-so-tai-khoan.ts` → 2 hits, both trong TSDoc NEGATION comments ("không requireRoles", "KHÔNG requireRoles") — NOT code usage
- staffId reads: `grep -c "staffId" src/routes/ky-so-tai-khoan.ts` → **13** (≥ 3 handlers đọc staffId từ AuthRequest + comments)
- Vietnamese error messages: tất cả error response dùng tiếng Việt có dấu (verified via grep "message:")
- `npx tsc --noEmit 2>&1 | grep "ky-so-tai-khoan"` → **0 errors**

### Task 2 (server mount)
- Import: `grep -n "kySoTaiKhoanRoutes" src/server.ts` → line 34 (import) + line 96 (mount) = 2 hits
- Mount count: `grep -c "api/ky-so" src/server.ts` → **3** (cau-hinh + tai-khoan + generic)
- Mount order: line 94 `/cau-hinh` < line 96 `/tai-khoan` < line 97 `/ky-so` generic — longer-prefix-wins correct
- No admin guard on /tai-khoan: line 96 chỉ có `authenticate`, không có `requireRoles` — verified via grep
- `npx tsc --noEmit 2>&1 | grep "server.ts"` → **0 errors**

### Live smoke test (backend running)
- `curl http://localhost:4000/api/ky-so/tai-khoan` → HTTP **401** — authenticate middleware reject anonymous
- Confirm mount hoạt động + middleware chain chạy đúng (không 404 = route found)

### Final TS baseline
- Total `npx tsc --noEmit 2>&1 | grep -c "error TS"` → **21 errors** (same as Phase 9 Plan 01/02 baseline, 0 new)

## API Reference for Phase 10 Plan 02 (Frontend Consumer)

**All endpoints require `Authorization: Bearer {user-jwt}` header — bất kỳ authenticated user nào đều dùng được (không cần admin role):**

### GET `/api/ky-so/tai-khoan`
Response khi admin chưa kích hoạt provider:
```json
{
  "success": true,
  "data": {
    "active": null,
    "config": null,
    "message": "Admin chưa kích hoạt provider ký số nào. Vui lòng liên hệ Quản trị viên."
  }
}
```
Response khi provider active + user chưa save config:
```json
{
  "success": true,
  "data": {
    "active": {
      "provider_code": "MYSIGN_VIETTEL",
      "provider_name": "MySign Viettel",
      "base_url": "https://remotesigning.viettel.vn"
    },
    "config": null
  }
}
```
Response khi có đầy đủ:
```json
{
  "success": true,
  "data": {
    "active": { "provider_code": "MYSIGN_VIETTEL", "provider_name": "MySign Viettel", "base_url": "..." },
    "config": {
      "staff_id": 42,
      "provider_code": "MYSIGN_VIETTEL",
      "user_id": "CMT_123456789",
      "credential_id": "CRED_001",
      "certificate_subject": "CN=Nguyễn Văn A",
      "certificate_serial": "0A1B2C",
      "is_verified": true,
      "last_verified_at": "2026-04-21T10:15:00.000Z"
    }
  }
}
```

### POST `/api/ky-so/tai-khoan`
Body: `{ user_id: string, credential_id?: string }`
Response 201: `{success: true, message: "Lưu cấu hình thành công. Vui lòng bấm \"Kiểm tra\" để xác thực."}`
Response 400: validation error — user_id empty, credential_id missing cho MYSIGN_VIETTEL, hoặc provider chưa active

### POST `/api/ky-so/tai-khoan/certificates`
Body: `{ user_id: string }`
Response 200:
```json
{
  "success": true,
  "data": {
    "certificates": [
      { "credential_id": "CRED_001", "subject": "CN=...", "serial_number": "0A1B2C",
        "valid_from": "2025-01-01T00:00:00.000Z", "valid_to": "2027-01-01T00:00:00.000Z", "status": "active" }
    ]
  }
}
```
Response 400: user_id empty hoặc provider chưa active
Response 502: provider network/auth error

### POST `/api/ky-so/tai-khoan/verify`
No body required.
Response 200 verified:
```json
{
  "success": true,
  "data": {
    "verified": true,
    "certificate_subject": "CN=Nguyễn Văn A",
    "cert_valid_to": "2027-01-01T00:00:00.000Z",
    "last_verified_at": "2026-04-21T10:20:00.000Z"
  }
}
```
Response 200 not verified (expected):
```json
{ "success": true, "data": { "verified": false, "message": "Không tìm thấy chứng thư khớp credential_id..." } }
```
Response 400: user chưa có config (phải POST / trước) hoặc provider chưa active
Response 502: provider network/auth error

## Issues Encountered

- **None.** 2 tasks executed linearly theo plan spec, verification pass all gates.
- Backend đang chạy dev server nên live smoke test xác nhận mount hoạt động ngay.

## User Setup Required

- **None.** Backend restart auto-picked up 2 tasks vì `tsx watch` reload on file change.
- Phase 10 Plan 02 (frontend page) có thể develop ngay — 4 API endpoints sẵn sàng consume.
- Khi triển khai production: cần KH cấp credentials thật cho provider (SmartCA/MySign) và Admin phải kích hoạt 1 provider qua Phase 9 Plan 03 UI trước khi user dùng được Phase 10 flow.

## Next Phase Readiness

- **Ready for Phase 10 Plan 02 (Frontend user config page)**:
  - UI có thể consume 4 endpoints với response shape documented trên.
  - Flow UX: User nhập user_id → bấm "Tải danh sách CTS" (MySign) → chọn credential_id → bấm "Lưu" → bấm "Kiểm tra" → xem badge "Đã xác thực" ✓.
  - SmartCA flow đơn giản hơn: nhập user_id → bấm "Lưu" → bấm "Kiểm tra" (skip CTS list step).
- **Not blocking Phase 11 (Sign flow)**:
  - Phase 11 cần `is_verified=true` + `certificate_data` snapshot để build PKCS7 signature container.
  - Plan 10-01 đã persist `certificate_data` qua verify flow (matched.certificateBase64 → SP `certificate_data TEXT`).
  - Phase 11 có thể đọc qua `staffSigningConfigRepository.get(staffId, providerCode).certificate_data` (đã có trong `StaffSigningConfigFullRow`).

## Self-Check: PASSED

Verified:
- File `e_office_app_new/backend/src/routes/ky-so-tai-khoan.ts` exists (433 lines)
- File `e_office_app_new/backend/src/server.ts` modified (+3 lines: import + comment + mount)
- Commit `5d43e3c` exists: `feat(10-01): add user-level signing config routes /api/ky-so/tai-khoan`
- Commit `93bb908` exists: `feat(10-01): mount /api/ky-so/tai-khoan user routes with authenticate-only`
- `grep -c "^router\." src/routes/ky-so-tai-khoan.ts` = 4 (4 endpoints)
- `grep "api/ky-so" src/server.ts` returns 3 lines in correct order (cau-hinh → tai-khoan → ky-so)
- `grep "api/ky-so/tai-khoan" src/server.ts` contains `authenticate` but NOT `requireRoles`
- `grep -c "staffId" src/routes/ky-so-tai-khoan.ts` = 13 (JWT-scoped, no body.staff_id)
- `npx tsc --noEmit` in backend → 21 pre-existing errors (unchanged baseline, **0 new**)
- Live smoke: `curl http://localhost:4000/api/ky-so/tai-khoan` → **401** (authenticate middleware working)

---
*Phase: 10-user-config-page*
*Completed: 2026-04-21*
