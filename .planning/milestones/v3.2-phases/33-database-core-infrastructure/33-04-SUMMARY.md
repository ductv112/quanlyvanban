---
phase: 33-database-core-infrastructure
plan: 04
subsystem: backend
tags: [backend, service, lgsp, factory, infrastructure, cache, encryption]

requires:
  - phase: 33-03
    provides: "lgspAgencyConfigRepository.getByUnitId(unitId, env) + decryptSecret() helper"
provides:
  - "Factory getLgspService(unit_id?, environment?) per-unit lookup + cache"
  - "Class LGSPRealService với constructor injection (LgspCredentials) + backward compat env"
  - "Helper createLgspRealService(credentials) cho factory consume"
  - "invalidateLgspServiceCache(unit_id, env?) + clearLgspServiceCache() exports cho Phase 37 admin update"
  - "Backward compat singleton lgspRealService = new LGSPRealService() (no-arg) + routes/lgsp.ts không break"
affects: [phase-34-send-worker, phase-35-receive-cron, phase-36-status-callback-worker, phase-37-admin-ui]

tech-stack:
  added: []
  patterns:
    - "Constructor injection cho credential (thay vì env vars hardcoded) — service test-friendly + multi-tenant"
    - "Inline Map cache + TTL 5 phút (CONTEXT D-02 — chọn Map giảm dep, chưa cần lru-cache)"
    - "Invalidate-on-write strategy (D-02): admin update credential → gọi invalidate(unit_id) ngay → user không chờ 5 phút TTL"
    - "Lazy import './lgsp-real.service.js' trong getLgspServiceForUnit tránh circular dep với getLgspService factory"
    - "Backward compat optional param signature `getLgspService(unitId?, environment?)` — gọi không arg vẫn work với Phase 18 routes/lgsp.ts"

key-files:
  created: []
  modified:
    - "e_office_app_new/backend/src/services/lgsp-real.service.ts (270 dòng, +64 thay đổi: class export + constructor injection + helper + singleton BC)"
    - "e_office_app_new/backend/src/services/lgsp.service.ts (197 dòng, +152 thay đổi: cache Map + invalidate + getLgspServiceForUnit + factory extend)"

key-decisions:
  - "Cache implementation = inline Map (không thêm dep lru-cache) — đủ dùng cho 1 instance + 6 DN (max ~12 entries: 6 unit x 2 env). Khi scale ra cluster mới chuyển Redis pub/sub (defer v3.3+)."
  - "Backward compat priority: singleton lgspRealService GIỮ nguyên export + routes/lgsp.ts KHÔNG sửa (call getLgspService() no-arg vẫn work qua optional param). Phase 18 mock/real flow unchanged."
  - "LGSP_USERNAME/PASSWORD/APPLICATION_CODE vẫn đọc env (KHÔNG add vào LgspCredentials) — 6 DN Lạng Sơn dùng chung 1 LGSP user theo HDSD. Nếu Phase 35 cần per-unit user thì add field optional sau."
  - "Reject placeholder secret 'placeholder_not_configured' rõ ràng (throw error VN) — admin biết phải đi nhập credential thật qua /quan-tri/lgsp-config. Tránh silent fail khi gọi LGSP API với placeholder."
  - "Defensive cache delete khi entry expired (Date.now() - cachedAt >= TTL) — giảm memory leak với entry stale lâu dài."

requirements-completed:
  - LGSP-CRED-03

duration: 18min
completed: 2026-05-20
---

# Phase 33 Plan 04: Service Factory Refactor (Wave 2b) Summary

**LGSPRealService refactor từ singleton env-based sang class với constructor injection + backward compat. Factory `getLgspService()` extended với per-unit lookup (qua repo Phase 33-03) + cache Map 5 phút TTL + invalidate-on-write. Smoke test 17/17 PASS bao trùm backward compat + 4 throw path + cache hit/invalidate/clear lifecycle.**

## Performance

- **Started:** 2026-05-20 (Task 1 start)
- **Completed:** 2026-05-20
- **Duration:** ~18 phút
- **Tasks:** 3
- **Files modified:** 2 (lgsp-real.service.ts + lgsp.service.ts)
- **Files created:** 0 (source); 1 temp smoke test (đã xóa sau verify)

## Accomplishments

### Task 1: Refactor `lgsp-real.service.ts` — constructor injection + BC env (commit 94a6242)

- **Tách `LgspCredentials` interface export** — `{ baseUrl, systemId, secretKey }` (plaintext)
- **Class `LGSPRealService` export PascalCase** (trước private `class LgspRealService`) implements ILgspService
- **Constructor optional `credentials?: LgspCredentials`** — undefined → fallback env (Phase 18 BC), defined → per-unit instance
- **3 getter `endpoint`/`systemId`/`secretKey`** ưu tiên credentials → fallback env
- **Helper `createLgspRealService(credentials): LGSPRealService`** export — factory Phase 33 consume
- **Singleton `lgspRealService = new LGSPRealService()`** GIỮ export (no-arg = env mode) — routes/lgsp.ts không break
- `username` / `password` / `applicationCode` (LGSP login) VẪN đọc env trong `getToken()` — 6 DN dùng chung 1 user (per HDSD)
- File: 270 dòng (baseline 212 + 58 dòng injection logic + docstring + helper + interface)

### Task 2: Extend `lgsp.service.ts` factory với per-unit lookup + cache + invalidate (commit f5423fb)

- **Signature mới `getLgspService(unitId?: number, environment: 'sandbox' | 'prod' = 'prod')`** — 3 modes:
  - `getLgspService(unitId, env)` → per-unit lookup + cache (Phase 33+)
  - `getLgspService(unitId)` → default env='prod' (Phase 33+)
  - `getLgspService()` → backward compat Phase 18 (MOCK_EXTERNAL → mock vs real env)
- **Inline `cache = new Map<string, CacheEntry>`** — key=`${unit_id}:${env}`, TTL 5 phút
- **Helper `getLgspServiceForUnit(unitId, env)`** internal — 7 bước flow:
  1. Check cache hit (chưa expire) → return cached
  2. Cache expired → delete defensive
  3. `lgspAgencyConfigRepository.getByUnitId(unitId, env)` → null → throw "not configured"
  4. `is_active=FALSE` → throw "disabled"
  5. `decryptSecret(secret_key_encrypted)` → catch → throw "decrypt fail (check SIGNING_SECRET_KEY)"
  6. plaintext = 'placeholder_not_configured' hoặc '' → throw "placeholder"
  7. Lazy import + `createLgspRealService({baseUrl, systemId, secretKey})` → cache + return
- **`invalidateLgspServiceCache(unitId, env?)` export** — invalidate-on-write D-02:
  - env defined → xóa 1 key
  - env undefined → xóa cả prod + sandbox cho unit này
- **`clearLgspServiceCache()` export** — clear toàn bộ (test reset / admin "Clear all")
- Lazy import `'./lgsp-real.service.js'` tránh circular dep
- File: 197 dòng (baseline 50 + 147 dòng cache + invalidate + getLgspServiceForUnit + factory extend)

### Task 3: TypeScript strict + smoke test factory + backward compat (no source change)

- **TypeScript strict:** `npx tsc --noEmit` → exit 0, zero error toàn backend
- **Backward compat verified:** `routes/lgsp.ts:138, :170` vẫn dùng `getLgspService()` no-arg, signature `unitId?: number` cho phép gọi không arg → KHÔNG cần sửa routes
- **Smoke test 17/17 PASS** (file temp `_phase33_04_smoke.ts` chạy qua tsx, đã xóa sau verify):
  - [1] Backward compat (MOCK_EXTERNAL=true → mock service) — 3 PASS
  - [2] Per-unit lookup "not configured" — 2 PASS (unit_id=1 chưa seed + unit_id=999999 không tồn tại)
  - [3] Per-unit lookup "is_active=FALSE" — 2 PASS (upsert placeholder + throw "disabled")
  - [4] Per-unit lookup "placeholder secret" — 3 PASS (active + decrypt = "placeholder_not_configured" → throw)
  - [5] Per-unit lookup success — 3 PASS (real cipher + active → LGSPRealService instance)
  - [6] Cache hit — 1 PASS (svc1 === svc2 same reference)
  - [7] invalidate(unit_id) → rebuild — 1 PASS (svc1 !== svc3)
  - [8] invalidate(unit_id, sandbox) → prod KHÔNG bị xóa — 1 PASS (svc4 === svc5)
  - [9] clearAll → tất cả cleared — 1 PASS (svc4 !== svc6)
- **Cleanup:** DELETE rows test (unit_id=1) + clearLgspServiceCache() sau test → DB clean về trạng thái 0 row lgsp_agency_config

## Task Commits

1. **Task 1: LGSPRealService constructor injection** — `94a6242` (refactor)
2. **Task 2: getLgspService factory + cache + invalidate** — `f5423fb` (feat)
3. **Task 3: TS check + smoke test verify** — _(no source commit; verification only — passes captured in SUMMARY)_

**Plan metadata commit:** _(sau khi tạo SUMMARY.md)_

## Files Modified

- **Modified:** `e_office_app_new/backend/src/services/lgsp-real.service.ts` — 270 dòng (+64 từ 212)
  - Add: `LgspCredentials` interface export, class `LGSPRealService` PascalCase export, constructor optional credentials, helper `createLgspRealService(credentials)`, doc strings
  - Keep: getter pattern, fetchJson, getToken/sendDocument/receiveDocuments/syncOrganizations/getDocumentDetail (full Phase 18 behavior), singleton `lgspRealService = new LGSPRealService()` export
- **Modified:** `e_office_app_new/backend/src/services/lgsp.service.ts` — 197 dòng (+152 từ 50)
  - Add: cache `Map<string, CacheEntry>`, `cacheKey()` helper, `invalidateLgspServiceCache()`, `clearLgspServiceCache()`, `getLgspServiceForUnit()` internal, factory extension với optional `unitId` + `environment` params
  - Keep: 3 interfaces (LgspReceivedDoc, LgspSendResult, LgspOrganization, ILgspService), backward compat MOCK_EXTERNAL flag branch

## Decisions Made

### 1. Inline Map cache thay vì lru-cache package

Phase 33 dự kiến max ~12 cache entries (6 DN x 2 env = 12). `Map<string, CacheEntry>` đủ — không cần lru-cache (1 dep nhiều hơn = thêm bundle + maintenance). Khi scale ra cluster (multi-instance), sẽ chuyển sang Redis pub/sub invalidate (defer v3.3+ per CONTEXT D-02).

### 2. Backward compat tuyệt đối (singleton + no-arg factory)

- KHÔNG đổi tên export `lgspRealService` (singleton instance) — `routes/lgsp.ts` line 4 import vẫn work
- KHÔNG đổi signature breaking — optional `unitId?: number` cho phép `getLgspService()` no-arg
- `lgspMockService` không động — Phase 18 mock test path unchanged
- Verify: `grep "getLgspService()" routes/lgsp.ts` → 2 match (line 138, 170) — TypeScript pass = không break

### 3. LGSP login credentials VẪN đọc env (không add vào LgspCredentials)

Per HDSD `docs/Trục EDOC Lạng Sơn - QLVB Doanh nghiệp/HuongDanKetNoiLienThongVB_v2.2.pdf`: `username/password/applicationCode` là login user cấp ở mức "ứng dụng tích hợp" (1 user dùng cho cả 6 DN của 1 hệ thống). `systemId/secretKey` mới là per-organization. → Constructor inject chỉ 3 field per-unit, login info giữ env. Nếu Phase 35 phát hiện cần per-unit user thì add `username?`, `password?`, `applicationCode?` optional vào `LgspCredentials` interface.

### 4. Throw error tiếng Việt với action hint cụ thể

Mỗi throw đều chỉ admin chỗ cần đi sửa:
- "not configured" → `/quan-tri/lgsp-config để cấu hình`
- "disabled" → `Admin có thể bật is_active qua /quan-tri/lgsp-config`
- "decrypt fail" → `Kiểm tra SIGNING_SECRET_KEY trong backend/.env`
- "placeholder" → `Admin cần nhập credential thật qua /quan-tri/lgsp-config`

→ Phase 34/35/36 worker khi gặp error có thể log + email admin với hướng dẫn rõ ràng.

### 5. Reuse `services/signing/crypto.ts` (KHÔNG move ra `lib/crypto.ts`)

CONTEXT D-01 cho phép 2 lựa chọn (reuse import vs move shared). Chọn reuse import trực tiếp `import { decryptSecret } from './signing/crypto.js'` vì:
- Sạch hơn (1 thay đổi ít hơn)
- Crypto helper hiện tại là single-purpose (encrypt/decrypt qua `SIGNING_SECRET_KEY`), tên file `signing/crypto.ts` mô tả đúng nguồn gốc (dùng cho signing module trước, LGSP dùng chung key)
- Khi nào có module thứ 3 cần crypto + có nhu cầu rename → move sau, không vội

## Deviations from Plan

None — plan executed exactly as written. Tasks 1-3 done theo đúng `<action>` của PLAN.md.

## Issues Encountered

- **Dev DB không có seed Plan 33-02 (lgsp_agency_config = 0 row).** Smoke test phải inline seed (upsert 1 row test với unit_id=1) + cleanup ở cuối. Đây là behavior expected — `seed/001_required_data.sql` chỉ apply khi fresh deploy, dev DB current state không reset từ scratch. Tránh edit master seed file → KHÔNG là issue, chỉ note cho Phase 34/35/36 worker khi cần test data.

## Self-Check: PASSED

**Verified files exist:**
- `e_office_app_new/backend/src/services/lgsp-real.service.ts` — 270 dòng (>= 200 required)
- `e_office_app_new/backend/src/services/lgsp.service.ts` — 197 dòng (>= 120 required)

**Verified exports (grep contents):**
- `export class LGSPRealService` — FOUND (lgsp-real.service.ts:90)
- `export function createLgspRealService` — FOUND (lgsp-real.service.ts:260)
- `export const lgspRealService` — FOUND (lgsp-real.service.ts:270)
- `export interface LgspCredentials` — FOUND (lgsp-real.service.ts:84)
- `export function invalidateLgspServiceCache` — FOUND (lgsp.service.ts:73)
- `export function clearLgspServiceCache` — FOUND (lgsp.service.ts:87)
- `async function getLgspServiceForUnit` — FOUND (lgsp.service.ts:107)
- `export async function getLgspService` — FOUND (lgsp.service.ts:181)

**Verified commits exist:**
- `94a6242` — refactor(33-04): LGSPRealService nhan credentials qua constructor + backward compat env — FOUND
- `f5423fb` — feat(33-04): them factory getLgspService(unit_id, env) + cache Map TTL + invalidate — FOUND

**Backward compat verification:**
- `routes/lgsp.ts:138, :170` vẫn dùng `await getLgspService()` no-arg — TS strict pass = signature compatible

**Smoke test result:** 17 PASS / 0 FAIL across 9 test scenarios

## Tech Debt / Caveat

- **`username/password/applicationCode` chung 1 LGSP user** — assumption từ HDSD. Nếu Phase 35 receive cron test phát hiện cần per-unit user (mỗi DN có user riêng), phải extend `LgspCredentials` interface + lookup từ thêm field DB. Hiện chưa có schema column → cần Plan v3.3+ schema migration.
- **Cache không có max-entry limit** — Map sẽ grow theo số unit + env. Hiện max 12 entries (6 DN x 2 env), không lo memory. Khi mở rộng sang model "200+ cơ quan tỉnh" thì cần lru-cache với maxSize=100.
- **Cache không sync giữa multi-instance** — Nếu deploy nhiều pm2 instance (cluster mode), invalidate ở instance A KHÔNG xóa cache ở instance B → instance B sẽ trả service cũ tối đa 5 phút (TTL safety net). Acceptable cho hiện tại (1 pm2 process). Phase v3.3+ chuyển Redis pub/sub.
- **Test file `_phase33_04_smoke.ts` đã xóa** — Khi cần re-run, copy lại từ git history của plan này (commit message `feat(33-04): them factory...`) hoặc viết lại theo schema 9 test scenarios ở Task 3 docs.

## Next Phase Readiness

**Sẵn sàng cho Plan 33-05 (final smoke test E2E + verification toàn phase):**
- Service factory hoàn chỉnh — Phase 35 cron loop có thể call `getLgspService(unit_id, 'prod')` per-DN
- Phase 36 status callback worker có thể call cùng pattern
- Phase 37 admin update credential route có sẵn `invalidateLgspServiceCache(unit_id)` để gọi sau update
- Backward compat verified — Phase 18 routes/lgsp.ts hoạt động nguyên

**Sẵn sàng cho Plan 33-05 verification scope:**
- Verify routes/lgsp.ts khi mount + call có hoạt động (curl test) — KHÔNG break
- Verify factory + cache + invalidate qua repository chain — Plan 33-04 smoke test đã verify
- Verify schema + seed + repo + factory full chain — Plan 33-05 E2E

**Blockers:** None.

---
*Phase: 33-database-core-infrastructure*
*Completed: 2026-05-20*
