---
phase: 09-admin-config-provider-adapters
plan: 01
subsystem: backend
tags: [signing, provider-adapter, strategy-pattern, smartca, mysign, http-client, wave-2, tdd]

# Dependency graph
requires:
  - phase: 08-04
    provides: signingProviderConfigRepository + decryptSecret() consumed by factory
  - phase: 08-03
    provides: services/signing/ directory structure
provides:
  - services/signing/providers/provider.interface.ts — SigningProvider contract + 7 DTOs
  - services/signing/providers/http-client.ts — HttpClient abstraction wrapping Node fetch
  - services/signing/providers/smartca-vnpt.provider.ts — SmartCA VNPT adapter (3 VNPT endpoints)
  - services/signing/providers/mysign-viettel.provider.ts — MySign Viettel adapter (4 MySign endpoints)
  - services/signing/providers/provider-factory.ts — getProviderByCode + getActiveProviderWithCredentials
  - services/signing/providers/provider.test.ts — 26 unit tests with mock HttpClient
affects:
  - Phase 9 Plan 02 (Admin config API — consumes getProviderByCodeWithCredentials + testConnection)
  - Phase 10 (User config page — consumes provider.listCertificates)
  - Phase 11 (Sign flow + worker — consumes getActiveProviderWithCredentials + signHash + getSignStatus)

# Tech tracking
tech-stack:
  added: []  # Zero new deps — Node fetch is built-in
  patterns:
    - "Strategy pattern: SigningProvider interface + 2 concrete implementations + pure dispatcher factory"
    - "Factory dependency injection: create*Provider(httpClient?) allows test to inject mock, production uses singleton"
    - "Stateless adapters: no token caching — fresh login every call prevents race condition in Phase 11 BullMQ worker"
    - "HTTPS-only baseUrl validation (with localhost exception for dev) — MITM prevention at adapter entry point"
    - "Secret scrubbing in error messages: client_secret/access_token redacted before surfacing to HTTP caller"
    - "Switch + default throw for provider dispatch — prevents code injection via tampered DB provider_code"
    - "URL path verification in tests: grep sca/sp769/v1 = 7 hits (3 endpoints × some duplicated), vtss/service = 8 hits (4 endpoints)"
    - "Body key casing verified: MySign signHash uses credentialID (chữ D hoa) — case-sensitive match with postman"

key-files:
  created:
    - e_office_app_new/backend/src/services/signing/providers/provider.interface.ts
    - e_office_app_new/backend/src/services/signing/providers/http-client.ts
    - e_office_app_new/backend/src/services/signing/providers/smartca-vnpt.provider.ts
    - e_office_app_new/backend/src/services/signing/providers/mysign-viettel.provider.ts
    - e_office_app_new/backend/src/services/signing/providers/provider-factory.ts
    - e_office_app_new/backend/src/services/signing/providers/provider.test.ts
  modified: []

key-decisions:
  - "Node fetch thay vì axios: backend/package.json không có axios (chỉ frontend). Node 18+ có fetch native đủ cho JSON POST + AbortController timeout. Không thêm dependency mới chỉ để 2 adapter dùng."
  - "HTTP client abstraction qua interface HttpClient: tests inject mock, production dùng createDefaultHttpClient() wrap fetch. Pattern này chuẩn hơn mocking global fetch."
  - "Không cache access_token của MySign: mỗi call login tươi. Lý do: Phase 11 BullMQ worker chạy multi-concurrency → token cache shared memory dễ race. Production optimization (Redis cache + TTL=expires_in) deferred sau khi benchmark."
  - "testConnection trả success=true cho 'user not found' errors: user_id test là fake, provider báo 'not found' là hợp lệ (credentials OK). Chỉ success=false khi lỗi client_id/secret/unauthorized."
  - "POST cho SmartCA getSignStatus (không phải GET): plan draft ghi GET, nhưng Model.cs _getStatus() gọi qua Query() chỉ POST. Kiểm chứng lại source cũ (line 1053-1063) để tránh sai."
  - "HTTPS-only validate với localhost exception: dev có thể chạy mock server http://localhost cho test, nhưng production bắt buộc HTTPS. Throw 'baseUrl phải là HTTPS' với error message tiếng Việt."
  - "Switch statement cho dispatcher (không dynamic import): threat T-09-03 — nếu dùng dynamic import theo provider_code từ DB, attacker có thể inject path '../evil.js'. Switch + default throw là safe."
  - "credentialID (chữ D hoa) trong MySign signHash body: postman collection literal là credentialID, không phải credential_id. Test assert key này để tránh mismatch lúc runtime."

patterns-established:
  - "Pattern: Strategy pattern cho external provider integrations (2+ providers cùng shape API nhưng URL/body khác)"
  - "Pattern: Factory DI với optional httpClient — test inject mock, production dùng singleton (tránh build mới mỗi call)"
  - "Pattern: Validate input tại adapter entry (HTTPS check) — không tin DB/request body"
  - "Pattern: Secret scrubbing trong error path — redact() helper replace plaintext với *** trước khi throw"

requirements-completed: [SIGN-01, SIGN-02, CFG-03]

# Metrics
duration: ~10min
completed: 2026-04-21
---

# Phase 9 Plan 1: Provider Adapters Summary

**Strategy-pattern `SigningProvider` interface + 2 concrete adapters (SmartCA VNPT, MySign Viettel) + factory reading DB + decrypting secrets — all unit-tested với 26 mock-based tests. Phase 9 Plan 02 có thể call `getActiveProvider().testConnection()` để Admin test connection (CFG-03); Phase 11 worker có thể poll `provider.getSignStatus(txnId)` (SIGN-05). Zero axios dependency — Node fetch native đã đủ.**

## Performance

- **Duration:** ~10 min (~551s — read context + 3 tasks + verification + SUMMARY)
- **Started:** 2026-04-21T07:18:51Z
- **Completed:** 2026-04-21T07:28:03Z
- **Tasks:** 3
- **Files created:** 6 (4 source + 1 http-client helper + 1 test file)
- **Files modified:** 0
- **Total lines added:** 1505 lines (1012 production TS + 493 test)

## Accomplishments

- **Strategy pattern interface ready**: `SigningProvider` với 4 async methods (testConnection, listCertificates, signHash, getSignStatus) + 7 typed DTOs. Phase 9/10/11 call sites không cần biết provider cụ thể.
- **2 adapters production-ready**:
  - **SmartCA VNPT**: 3 endpoints theo Model.cs (`credentials/get_certificate`, `signatures/sign`, `signatures/sign/{txn}/status`). Body keys `sp_id`/`sp_password`/`user_id`/`sign_files`/`serial_number` khớp literal với source cũ.
  - **MySign Viettel**: 4 endpoints theo postman (`ras/v1/login`, `certificates/info`, `signHash`, `requests/status`). Body signHash dùng `credentialID` (chữ D hoa), `hashAlgo='2.16.840.1.101.3.4.2.1'` (SHA-256 OID), `signAlgo='1.2.840.113549.1.1.1'` (RSA OID), `async=1`.
- **Factory dispatcher**: `getProviderByCode(code)` pure switch (không gọi DB) + `getActiveProviderWithCredentials()` đọc DB + decrypt. Pure dispatcher tách biệt vì Admin test-connection có thể cần test credentials chưa lưu DB.
- **HttpClient abstraction**: minimal interface wrap Node fetch — tests inject mock qua factory, production dùng default. Không cần axios (không có sẵn trong backend/package.json).
- **Security mitigations** (5/6 STRIDE threats handled):
  - T-09-01 (VNPT secret leak): redact() helper scrub `sp_password` trong error path
  - T-09-02 (MySign secret/token leak): redact() scrub `client_secret` + `access_token`; stateless — no token cache
  - T-09-03 (DB tampering): switch + default throw, không dynamic import
  - T-09-04 (MITM): `validateHttpsBaseUrl()` throw với http:// (trừ localhost)
  - T-09-05 (DoS): `AbortController` timeout 15s cho mọi request
- **Zero new TypeScript errors**: 21 pre-existing errors trong routes/*.ts không đổi (same baseline as Phase 8).
- **26 unit tests pass** — toàn bộ mock-based, không hit provider thật.

## Task Commits

Each task committed atomically:

1. **Task 1: SigningProvider interface + test scaffold** — `051337b` (feat)
2. **Task 2: SmartCA VNPT + MySign Viettel adapters + HttpClient** — `9734930` (feat)
3. **Task 3: Provider factory + dispatcher tests** — `030dfe7` (feat)

**Plan metadata commit:** _pending_ (docs: complete plan)

## Files Created

- `e_office_app_new/backend/src/services/signing/providers/provider.interface.ts` — **created** (182 lines)
  - `ProviderCode` union literal
  - 7 DTOs: `TestConnectionResult`, `CertificateInfo`, `SignHashRequest`, `SignHashResult`, `GetStatusResult`, `AdminCredentials`, `UserConfig`
  - `SigningProvider` interface với readonly code + 4 async methods
  - TSDoc mapping mỗi method → REQ-ID consumer (CFG-03, CFG-05, SIGN-03, SIGN-05)
- `e_office_app_new/backend/src/services/signing/providers/http-client.ts` — **created** (105 lines)
  - `HttpClient` interface với `post<T>(url, body, headers?)`
  - `createDefaultHttpClient(timeoutMs=15000)` wrap Node fetch + AbortController
  - `validateHttpsBaseUrl(url)` throw nếu http:// (trừ localhost/127.0.0.1/::1)
- `e_office_app_new/backend/src/services/signing/providers/smartca-vnpt.provider.ts` — **created** (289 lines)
  - Factory `createSmartCaVnptProvider(httpClient?)` + singleton `smartcaVnptProvider`
  - 4 methods: testConnection, listCertificates, signHash, getSignStatus
  - Helper `joinUrl`, `scrubSecret`, VNPT response interfaces (`VnptGetCertResponse`, `VnptSignResponse`, `VnptStatusResponse`)
- `e_office_app_new/backend/src/services/signing/providers/mysign-viettel.provider.ts` — **created** (328 lines)
  - Factory `createMysignViettelProvider(httpClient?)` + singleton `mysignViettelProvider`
  - Private `login()` helper (stateless, no cache)
  - 4 methods: testConnection, listCertificates, signHash, getSignStatus
  - Helper `joinUrl`, `redact`, MySign response interfaces (`ViettelLoginResponse`, `ViettelCertListResponse`, `ViettelSignHashResponse`, `ViettelStatusResponse`)
- `e_office_app_new/backend/src/services/signing/providers/provider-factory.ts` — **created** (108 lines)
  - `getProviderByCode(code)` — pure dispatcher switch
  - `getActiveProviderWithCredentials()` — DB-backed + decrypt
  - `getProviderByCodeWithCredentials(code)` — DB-backed specific code
  - `ProviderWithCredentials` interface exported
- `e_office_app_new/backend/src/services/signing/providers/provider.test.ts` — **created** (493 lines)
  - 4 describe blocks: interface shape (8 tests) + SmartCA (8 tests) + MySign (7 tests) + factory (3 tests)
  - `makeMockClient(responses)` helper — inject vào factory, record calls

## Decisions Made

- **Node fetch over axios**: `backend/package.json` không có `axios` (chỉ frontend có). Node 18+ cung cấp `fetch` + `AbortController` đủ cho JSON POST timeout. Không thêm dependency mới chỉ cho 2 adapter. Tradeoff: mất interceptor convenience của axios, nhưng adapter logic đủ đơn giản để không cần.
- **HttpClient abstraction layer**: interface `HttpClient` cho phép tests inject mock — cleaner hơn stub global `fetch`. Production dùng `createDefaultHttpClient()` wrap fetch. Pattern này dễ swap sang axios/got sau nếu cần retry logic.
- **Stateless token (không cache MySign access_token)**: mỗi call login tươi. Lý do: Phase 11 BullMQ worker chạy multi-concurrency — shared-memory cache dễ race. Tradeoff: extra login latency (~50-200ms) mỗi call vs correctness. Production optimization (Redis cache với TTL=expires_in) sẽ làm sau benchmark thực tế.
- **testConnection semantic: 'user not found' = success**: khi test, user_id là `'test_connection'` (fake). Provider trả message "not found" / "user not exist" nghĩa là credentials đúng, chỉ user_id giả không tồn tại — đó là CFG-05 concern (User config), không phải CFG-03 (Admin). Return `{success: true, message: 'Kết nối OK (credentials hợp lệ)'}`.
- **POST cho SmartCA getSignStatus (plan draft ghi GET)**: kiểm chứng Model.cs line 1053-1063 — `_getStatus()` gọi `Query(new Object{}, uri)` và `Query` chỉ POST method. Plan draft sai, adapter implement đúng theo source cũ. Body empty `{}`.
- **Switch dispatcher (không dynamic import)**: threat T-09-03 Tampering — nếu DB `provider_code` bị sửa thành path traversal (VD: `'../../../evil.js'`), dynamic import sẽ load file nguy hiểm. Switch + default throw an toàn.
- **credentialID chữ D hoa**: postman collection literal `"credentialID"`, không phải `credential_id` (snake_case như các field khác). Có thể do MySign team inconsistent naming. Adapter + test assert key này để tránh bug runtime.
- **HTTPS validate với localhost whitelist**: dev mock server có thể là `http://localhost:9005` (theo postman example history). Production phải HTTPS. Whitelist localhost/127.0.0.1/::1 — threat T-09-04 Spoofing.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 — Missing Critical Dependency] Plan assumed axios, backend không có axios**
- **Found during:** Task 2 — đọc `backend/package.json`
- **Issue:** Plan `<context>` line 204 nói "e_office_app_new/backend/package.json (confirm axios 1.15.0 available)" nhưng thực tế backend package.json CHỈ có axios trong frontend (CLAUDE.md line 52: "axios 1.15.0 - Frontend HTTP client (frontend only)"). Dùng axios sẽ cần thêm dependency mới.
- **Fix:** Tạo `http-client.ts` với interface HttpClient + `createDefaultHttpClient()` wrap Node `fetch` (built-in từ Node 18+). Tests inject mock qua interface, production dùng fetch. Zero new npm package.
- **Files modified:** `http-client.ts` (CREATED — ngoài plan spec), cả 2 adapter import từ đây thay vì axios
- **Verification:** `npm list axios` trong backend → not found (xác nhận không có). Tests pass.
- **Committed in:** Task 2 (`9734930`)

**2. [Rule 1 — Plan draft có endpoint method sai] SmartCA getSignStatus: POST không phải GET**
- **Found during:** Task 2 — đọc Model.cs line 1053-1063
- **Issue:** Plan `<reference_endpoints>` ghi `GET {base_url}/sca/sp769/v1/signatures/sign/{transaction_id}/status`. Model.cs `_getStatus()` gọi `Query(new Object{}, uri)` và `Query()` method hardcode `Method.POST` (line 1024: `new RestRequest(Method.POST)`). Thực tế provider expect POST với empty body `{}`.
- **Fix:** Adapter `getSignStatus` dùng `http.post(url, {})` — empty body. Test assert URL đúng có `/status` suffix.
- **Files modified:** `smartca-vnpt.provider.ts` line ~225
- **Verification:** Test `getSignStatus URL có /status suffix + POST method + empty body` pass.
- **Committed in:** Task 2 (`9734930`)

### Intentional Enhancements (beyond plan text)

- **Thêm redact() helper trong mysign-viettel.provider.ts**: scrub `client_secret` + `access_token` trong error message trước khi throw. Plan chỉ yêu cầu "không log" nhưng error.message cũng có thể leak nếu fetch throw với URL/body. Proactive mitigation T-09-02.
- **Thêm test "reject http:// baseUrl"**: verify threat T-09-04 active tại runtime. Plan không yêu cầu cụ thể nhưng threat model có disposition `mitigate`.
- **Thêm test "signHash reject khi thiếu credentialId"**: MySign bắt buộc credentialId, nếu thiếu sẽ lỗi runtime khó debug. Throw sớm với message rõ ràng.
- **CRLF strip trong MySign signatureBase64**: postman response có `\r\n\r\n` newlines giữa base64 string. Adapter `.replace(/\s+/g, '')` để Phase 11 worker dùng được trực tiếp.

---

**Total deviations:** 1 Rule 2 critical (http-client abstraction thay axios), 1 Rule 1 bug (plan method sai), 4 intentional enhancements.
**Impact on plan:** Public API shape của `SigningProvider` + 4 methods + factory khớp `<must_haves>` exactly. Fix Rule 2 (http-client) prevent runtime failure "Cannot find module 'axios'". Fix Rule 1 (POST vs GET) prevent 404/405 error khi poll status thật.

## Verification Results

### Task 1 (Interface + scaffold)
- `provider.interface.ts` exports `SigningProvider` + `ProviderCode` + 6 DTOs — confirmed via grep
- `npx tsc --noEmit` — 21 pre-existing errors (same baseline), 0 new in `services/signing/providers/`
- `npx tsx --test` → 8/8 scaffold tests pass

### Task 2 (Adapters + tests)
- Both adapter files exist with factory + singleton exports
- All 4 methods implemented in each adapter
- URL paths verified: `grep -c "sca/sp769/v1" smartca-vnpt.provider.ts` = **7** (3 endpoints, some duplicated trong code + TSDoc)
- `grep -c "vtss/service" mysign-viettel.provider.ts` = **8** (4 endpoints)
- `grep -n "credentialID" mysign-viettel.provider.ts` confirms chữ D hoa trong body literal
- `npx tsx --test` → 23/23 tests pass (8 interface + 8 SmartCA + 7 MySign)
- `npx tsc --noEmit` — 0 new errors

### Task 3 (Factory + dispatcher tests)
- `provider-factory.ts` exports 3 functions (`getProviderByCode`, `getActiveProviderWithCredentials`, `getProviderByCodeWithCredentials`)
- Switch handles both codes + default throw with Vietnamese message
- `npx tsx --test` → **26/26 tests pass** (9 interface + 8 SmartCA + 7 MySign + 3 factory)
- `npx tsc --noEmit` — **0 new errors** (21 pre-existing unchanged)

### Final smoke checks
- No `console.log` in any providers/*.ts file — confirmed via `grep -rn "console.log" src/services/signing/providers/` returns empty
- Test output excerpt:
  ```
  # tests 26
  # suites 4
  # pass 26
  # fail 0
  # duration_ms 1249.47
  ```

## API Reference for Phase 9+

**Admin test-connection route (Phase 9 Plan 02):**
```typescript
import { getProviderByCode } from '@/services/signing/providers/provider-factory.js';

// POST /api/quan-tri/cau-hinh-ky-so/test-connection
const provider = getProviderByCode(req.body.provider_code);  // 'SMARTCA_VNPT' or 'MYSIGN_VIETTEL'
const result = await provider.testConnection({
  baseUrl: req.body.base_url,
  clientId: req.body.client_id,
  clientSecretPlaintext: req.body.client_secret,  // Admin vừa nhập (plaintext)
  profileId: req.body.profile_id ?? null,
});
// { success, message, certificateSubject? } — UI hiển thị badge xanh/đỏ
```

**User listCertificates (Phase 10):**
```typescript
import { getActiveProviderWithCredentials } from '@/services/signing/providers/provider-factory.js';
import { staffSigningConfigRepository } from '@/repositories/staff-signing-config.repository.js';

const active = await getActiveProviderWithCredentials();
if (!active) throw new Error('Chưa cấu hình provider ký số');

const staffConfig = await staffSigningConfigRepository.get(req.user.staffId, active.provider.code);
const certs = await active.provider.listCertificates(active.credentials, {
  userId: staffConfig.user_id,
});
// [{ credentialId, subject, serialNumber, validFrom, validTo, certificateBase64, status }, ...]
```

**Sign flow worker (Phase 11):**
```typescript
import { getActiveProviderWithCredentials } from '@/services/signing/providers/provider-factory.js';
import { computePdfHash, signPdf } from '@/services/signing/pdf-signer.js';

const active = await getActiveProviderWithCredentials();
const { hash } = computePdfHash(placeholderPdf);

// 1. Gửi hash → nhận providerTransactionId
const { providerTransactionId } = await active.provider.signHash(
  active.credentials,
  { userId, credentialId },
  { hashHex: hash, documentName: 'QD-123.pdf', documentId: signTxnId.toString() },
);

// 2. BullMQ worker poll mỗi 5s, max 36 lần (3 phút)
for (let i = 0; i < 36; i++) {
  const status = await active.provider.getSignStatus(active.credentials, { userId }, providerTransactionId);
  if (status.status === 'completed') {
    const signed = await signPdf(placeholderPdf, status.signatureBase64!);
    // upload signed.signedPdf to MinIO, update sign_transactions.complete()
    break;
  }
  if (status.status === 'failed' || status.status === 'expired') {
    // update sign_transactions.updateStatus(txnId, status.status, status.errorMessage)
    break;
  }
  await sleep(5000);
}
```

## Issues Encountered

- **None critical.** 2 plan deviations caught early (axios absence + POST vs GET status endpoint), both fixed during Task 2 implementation before commit.
- Plan `<reference_endpoints>` line 121 said GET for SmartCA status, but Model.cs `Query()` helper is POST-only. Always verify source code over plan spec text.
- Plan `<context>` assumed axios available backend — false (only frontend). Checked `package.json` before implementing to catch.

## User Setup Required

- **None.** All changes are in-code + tests. No env var, no DB migration, no container restart.
- Existing `SIGNING_SECRET_KEY` (set for Phase 8) is still required — factory's `getActiveProviderWithCredentials()` calls `decryptSecret()` which reads this env.

## Next Phase Readiness

- **Ready for Phase 9 Plan 02 (Admin config API)**:
  - POST `/quan-tri/cau-hinh-ky-so/test-connection` → `getProviderByCode(code).testConnection(admin)` with body credentials
  - GET `/quan-tri/cau-hinh-ky-so/active` → `signingProviderConfigRepository.getActive()` + `maskSecret()` for response
  - POST `/quan-tri/cau-hinh-ky-so` upsert → `encryptSecret(plaintext)` before `signingProviderConfigRepository.upsert()`
- **Ready for Phase 10 (User config page)**:
  - `getActiveProviderWithCredentials()` + `staffSigningConfigRepository.get()` → call `provider.listCertificates()` to fetch certs for user
  - User selects credentialId → save via `staffSigningConfigRepository.upsert()`
- **Ready for Phase 11 (Sign flow + worker)**:
  - Worker pattern documented above — combining factory + pdf-signer (from Plan 08-03) + sign_transactions repository (from Plan 08-04)
  - Timeout 15s per HTTP call (threat T-09-05 mitigated) — worker's 3-minute total poll window is 15s × 12 polls OK

## Self-Check: PASSED

Verified:
- File `e_office_app_new/backend/src/services/signing/providers/provider.interface.ts` exists (182 lines)
- File `e_office_app_new/backend/src/services/signing/providers/http-client.ts` exists (105 lines)
- File `e_office_app_new/backend/src/services/signing/providers/smartca-vnpt.provider.ts` exists (289 lines)
- File `e_office_app_new/backend/src/services/signing/providers/mysign-viettel.provider.ts` exists (328 lines)
- File `e_office_app_new/backend/src/services/signing/providers/provider-factory.ts` exists (108 lines)
- File `e_office_app_new/backend/src/services/signing/providers/provider.test.ts` exists (493 lines)
- Commit `051337b` exists: `feat(09-01): add SigningProvider interface + type exports + test scaffold`
- Commit `9734930` exists: `feat(09-01): implement SmartCA VNPT + MySign Viettel adapters + HTTP client`
- Commit `030dfe7` exists: `feat(09-01): add provider-factory with DB-backed + pure dispatcher`
- `grep -c "sca/sp769/v1" smartca-vnpt.provider.ts` = 7 (matches 3 endpoints literal)
- `grep -c "vtss/service" mysign-viettel.provider.ts` = 8 (matches 4 endpoints literal)
- `grep -n "credentialID" mysign-viettel.provider.ts` confirms chữ D hoa
- No `console.log` in providers/ (grep empty)
- `npx tsc --noEmit` in backend → 21 pre-existing errors (unchanged baseline, 0 new in providers/)
- `SIGNING_SECRET_KEY=... npx tsx --test provider.test.ts` → **26 pass, 0 fail, 4 suites**

---
*Phase: 09-admin-config-provider-adapters*
*Completed: 2026-04-21*
