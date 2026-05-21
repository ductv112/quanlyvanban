---
phase: 34-send-flow-sendedoc
plan: 01
subsystem: backend/lgsp
tags: [backend, service, lgsp, edxml, multipart, error-mapping, phase-34]
requirements: [LGSP-SEND-01, LGSP-SEND-02, LGSP-SEND-04, LGSP-SEND-05]

dependency_graph:
  requires:
    - phase-33 (LGSP factory getLgspService + lgsp_agency_config repo + crypto.decryptSecret)
    - phase-18 (LGSPRealService skeleton + LgspCredentials)
  provides:
    - services/lgsp/error-codes.ts (LGSP_ERROR_CODES + LgspSendError + mapLgspError + isLgspNonRetryableError)
    - services/lgsp/edxml-builder.ts (buildEdxml() + BuildEdxmlInput/Result interfaces)
    - LGSPRealService.sendDocument(Buffer, destOrgCode, docCode) -> /v1/sendEdoc multipart
    - LgspSendResult.errorCode? field (worker classify retry vs no-retry)
  affects:
    - lgsp-mock.service.ts (signature update to match new ILgspService.sendDocument)

tech_stack:
  added:
    - xmlbuilder2@^3.1.1 (type-safe XML envelope build, auto-escape)
    - form-data@^4.0.5 (multipart/form-data Buffer streaming for Node fetch)
  patterns:
    - Custom Error class with code + vietnameseMessage for structured throw
    - Lookup table Record<string, string> for error code mapping
    - Native fetch + AbortController 60s timeout for LGSP send
    - Per-DN credential injection via constructor (Phase 33 backward compat)

key_files:
  created:
    - e_office_app_new/backend/src/services/lgsp/error-codes.ts (82 lines)
    - e_office_app_new/backend/src/services/lgsp/edxml-builder.ts (263 lines)
    - e_office_app_new/backend/src/services/lgsp/ (new directory)
  modified:
    - e_office_app_new/backend/src/services/lgsp.service.ts (interface signature + errorCode field)
    - e_office_app_new/backend/src/services/lgsp-real.service.ts (sendDocument rewrite + imports + SendEdocResponse)
    - e_office_app_new/backend/src/services/lgsp-mock.service.ts (sendDocument signature match)
    - e_office_app_new/backend/package.json (xmlbuilder2 + form-data deps)
    - e_office_app_new/backend/package-lock.json (lockfile update)

decisions:
  - D-05 honored: xmlbuilder2 chosen (vs manual string build) — type-safe + auto XML escape
  - D-07 honored: Buffer + form-data lib (NOT disk write) — memory-only for 6 DN small scale
  - D-08 honored: 9 MessageHeader components per QD 28 (From/To/Code/PromulgationInfo/DocumentType/Subject/SignerInfo/OtherInfo/DocumentId/TraceHeaderList) + Manifest base64 attachments
  - D-09 honored: Optional null fields -> "N/A" string / 0 number / NOW date with pino.warn (UX nhe nhang vi KH chua quen field bat buoc)
  - D-12 honored: 9 LGSP codes mapped (0/10/15/18/19/20/21/22/23) tieng Viet KHONG DAU (log-file + PowerShell safe); frontend Plan 34-04 se hardcode tieng Viet co dau cho UI badge
  - Endpoint fix: /api/lgspedoc/send-edoc (BROKEN Phase 18) -> /v1/sendEdoc (Postman authoritative)
  - Auth fix: login token + OAuth body -> HTTP headers X-SystemId + X-SecretKey (Postman doc API standard)
  - Signature change: sendDocument(string, string) -> (Buffer, string, string) — adds docCode for multipart filename
  - destOrgCode kept as param even though LGSP parses from edXML MessageHeader.To — needed for log + future routing decisions

metrics:
  duration: "27m"
  tasks_completed: 3
  files_modified: 5
  files_created: 2
  lines_added: ~600
  commits: 3
  ts_errors: 0
  smoke_tests_passed: 2/2
  completed_date: 2026-05-20
---

# Phase 34 Plan 01: Fix LGSP sendDocument + edXML Builder + Error Codes

**Plan 34-01:** Fix `LGSPRealService.sendDocument()` Phase 18 BROKEN (wrong endpoint + wrong body shape + wrong auth) bằng cách rewrite theo Postman collection authoritative — multipart/form-data tới `/v1/sendEdoc` với headers `X-SystemId` + `X-SecretKey`. Tạo 2 module mới `services/lgsp/error-codes.ts` (9 mã LGSP → Vietnamese) + `services/lgsp/edxml-builder.ts` (build edXML envelope đúng spec QĐ 28 với MessageHeader 9 thành phần + Manifest attachment base64). Foundation cho Plan 34-02 BullMQ worker consume.

## Summary

3 tasks shipped trong Wave 1 part 1 của Phase 34:

1. **error-codes.ts (NEW, 82 lines)** — `LGSP_ERROR_CODES` lookup table 9 mã (0/10/15/18/19/20/21/22/23) → Vietnamese (không dấu). `LgspSendError extends Error` với fields `code` + `vietnameseMessage` + `rawMessage` cho structured throw. `mapLgspError()` format display string. `isLgspNonRetryableError()` classify retry vs no-retry cho worker D-11.

2. **edxml-builder.ts (NEW, 263 lines) + 2 npm deps** — `buildEdxml(input)` produce edXML envelope đầy đủ theo QĐ 28/2018/QĐ-TTg:
   - 9 thành phần MessageHeader: `<From>`, `<To>`, `<Code>` (CodeNumber + CodeNotation), `<PromulgationInfo>` (Promulgator + PromulgationDate), `<DocumentType>`, `<Subject>`, `<SignerInfo>` (Signer + Position + Competence), `<OtherInfo>` (PageAmount + Appendix), `<DocumentId>` (UUID), `<TraceHeaderList>` (1 entry initial)
   - `<Manifest>` chứa N `<Attachment>` (Content base64 + FileName + FileType)
   - Fallback null fields: `"N/A"` string, `0` number, NOW date — kèm `pino.warn` log để dev biết
   - Trả về `{ buffer, docId, destOrgCode, docCode }` đủ data cho worker call sendDocument
   - `xmlbuilder2@^3.1.1` auto escape XML entities (`& < > " '`)
   - `form-data@^4.0.5` cho multipart streaming sendDocument

3. **LGSPRealService.sendDocument() FIX (lgsp-real.service.ts) + interface update (lgsp.service.ts + lgsp-mock.service.ts)** — Migration từ Phase 18 BROKEN sang Phase 34 CORRECT:

| Aspect | Phase 18 (BROKEN) | Phase 34 (CORRECT) |
|---|---|---|
| Endpoint | `POST /api/lgspedoc/send-edoc` | `POST /v1/sendEdoc` |
| Body | JSON `{ token, edocContent: string, ... }` | multipart/form-data `edocFile` (Buffer) + `messageType=edoc` |
| Auth | Login token trong body | HTTP headers `X-SystemId` + `X-SecretKey` |
| Signature | `(edxmlContent: string, destOrgCode: string)` | `(edxmlBuffer: Buffer, destOrgCode: string, docCode: string)` |
| Result | `{success, lgsp_doc_id, message}` | `{success, lgsp_doc_id, message, errorCode?}` |
| Network/timeout | Generic Error throw | `LgspSendError` throw (no code = retryable) |
| LGSP 4xx | Mixed in result | Non-throw return (worker no-retry per D-11) |
| Timeout | 30s | 60s (big attachments) |

Mock service `lgsp-mock.service.ts` cũng update sendDocument signature để match `ILgspService` interface mới — không break dev/test workflow với `MOCK_EXTERNAL=true`.

## Verification

**TypeScript strict:** PASS (zero error sau `npx tsc --noEmit`)

**Smoke test 1 — buildEdxml():**
```
docId: ab535a99-cb2a-404f-8fe8-a762bf4010cc
docCode: 123/UBND-VP
destOrgCode: H37.DN.002
bytes: 1141
xml_head: <?xml version="1.0" encoding="UTF-8"?><EdXMLEnvelope xmlns="http://www.go.vn/eDoc"><MessageHeader><From><OrganId>H37.DN.001</OrganId><OrganName>Cty CP Huu nghi Xuan Cuong</OrganName></From><To><OrganId>H37.DN.002</OrganI...
```
✓ Valid UUID DocumentId
✓ Envelope namespace `http://www.go.vn/eDoc` correct
✓ MessageHeader/From/To structure đúng
✓ pino log "Built edXML envelope" với docId/docCode/destOrgCode/bytes

**Smoke test 2 — error-codes:**
```
15: Sai SystemId hoac SecretKey (Code 15)
null: fallback msg
999: unknown raw (Code 999)
isNon 18: true
isNon 0: false
isNon null: false
LgspSendError.code: 15
LgspSendError.vietnameseMessage: Sai SystemId hoac SecretKey
LgspSendError instanceof Error: true
```
✓ 9 codes mapped đúng
✓ Fallback message khi code unknown
✓ Classify retry/no-retry chuẩn
✓ Custom Error class working (instanceof check)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Critical] Update mock service sendDocument signature**
- **Found during:** Task 3 (after updating ILgspService interface)
- **Issue:** `lgsp-mock.service.ts` implements `ILgspService` — đổi signature interface mà không sửa mock sẽ break TypeScript compile (mock không thoả interface contract).
- **Fix:** Update `lgsp-mock.service.ts:sendDocument()` từ `(string, string)` → `(Buffer, string, string)` + return `errorCode: '0'` cho success. Log thêm `bytes: edxmlBuffer.length` để dev biết payload size khi test với MOCK_EXTERNAL=true.
- **Files modified:** `e_office_app_new/backend/src/services/lgsp-mock.service.ts`
- **Commit:** f08288c (included in Task 3 commit since same interface change)

**2. [Rule 1 - Bug] SendEdocResponse `data.docId` should be optional + nullable**
- **Found during:** Task 3 (interface review)
- **Issue:** Original `SendEdocResponse` declared `data: { docId: string }` required. Postman shows error response có thể trả `data: { docId: null, ... }` hoặc omit `docId` entirely khi error chưa kịp tạo doc.
- **Fix:** Change `data?: { docId?: string | null; status?: string; errorCode?: string; errorDesc?: string }` — all fields optional, docId nullable.
- **Files modified:** `e_office_app_new/backend/src/services/lgsp-real.service.ts` line 36-46
- **Commit:** f08288c

### Plan-driven changes (no deviations)

- ✓ 9 LGSP error codes mapped exactly per CONTEXT D-12 table
- ✓ buildEdxml() produces 9 MessageHeader components exactly per CONTEXT D-08
- ✓ Fallback strategy null → "N/A" / 0 / NOW exactly per CONTEXT D-09
- ✓ Endpoint + headers + body shape exactly per Postman collection authoritative
- ✓ Vietnamese KHÔNG DẤU trong error messages (CLAUDE.md PowerShell 5.1 safe pattern)
- ✓ Phase 33 factory `getLgspService(unit_id, env)` NOT modified (reuse as-is)

## Authentication Gates

None. Plan executed fully autonomously — no auth prompts encountered.

## Known Stubs / Caveats

**1. `attachments[].contentBase64` is caller responsibility**
   - Builder không tải file từ MinIO — caller (Plan 34-02 worker) load buffer qua `minioClient.getObject()` rồi base64 encode trước khi gọi `buildEdxml()`.
   - Lý do: separate concerns (builder pure function, worker handle I/O).
   - Plan 34-02 sẽ implement attachment loading helper.

**2. `docId` UUID là PLACEHOLDER**
   - Builder generate `crypto.randomUUID()` cho `DocumentId` field.
   - Worker (Plan 34-02) update `lgsp_tracking.lgsp_doc_id` bằng UUID này NHƯNG sẽ overwrite bằng `docId` thật LGSP trả về sau `sendDocument()` success.
   - Lý do: Spec QĐ 28 yêu cầu MessageHeader có DocumentId, nhưng LGSP server cũng generate docId riêng (authoritative).

**3. `Competence` hardcode "Truc tiep"**
   - Builder hardcode `<Competence>Truc tiep</Competence>` cho SignerInfo.
   - Schema `outgoing_docs` chưa có column lưu competence — defer Phase 35+ nếu KH yêu cầu các loại khác (VD: "Thay mat", "Ky thay").
   - Phase 33 KH Lạng Sơn chỉ dùng "Trực tiếp" cho 6 DN.

**4. LGSP login flow `getToken()` KHÔNG dùng cho sendDocument**
   - sendDocument dùng HTTP headers thuần, không gọi `getToken()`.
   - `getToken()` chỉ còn dùng cho `receiveDocuments()` (Phase 35) và `syncOrganizations()` (Phase 37 admin sync).
   - Phase 35-37 sẽ review xem có cần update các method này theo Postman authoritative không.

## Threat Flags

None introduced by Plan 34-01. Existing threat surface (LGSP secret credentials) was already mitigated Phase 33 via:
- `secret_key_encrypted BYTEA` (pgp_sym_encrypt) in DB
- `crypto.decryptSecret()` only in service factory at instantiation time
- HTTPS endpoint enforce (baseUrl validation in repo)
- Cache invalidate on credential update (Phase 33 D-02)

Plan 34-01 secrets only pass through memory in `LgspCredentials` object — no logging of `secretKey` value, only `'OK' / 'EMPTY'` status string trong error messages.

## Next Steps

Plan 34-02: BullMQ worker module `lgsp-send-worker.ts` + queue `lgsp-send-queue.ts` consume:
- Input: `{ recipient_id, outgoing_doc_id, tracking_id, sender_unit_id, environment }`
- Steps: getLgspService(sender_unit_id, env) → load outgoing_doc + attachments from DB + MinIO → buildEdxml() → sendDocument(buffer, destOrgCode, docCode) → update lgsp_tracking status + lgsp_doc_id
- Retry policy: 5 attempts exponential 30s/60s/120s/240s/480s (CONTEXT D-10)
- Classify: throw → retry, return success/error → no-retry (CONTEXT D-11 + isLgspNonRetryableError helper)

## Commits

- `6931632` feat(34-01): them LGSP error codes map + LgspSendError class
- `2be33ee` feat(34-01): them edxml-builder + 2 deps (xmlbuilder2 + form-data)
- `f08288c` fix(34-01): LGSPRealService.sendDocument() dung /v1/sendEdoc multipart + headers

## Self-Check: PASSED

**Files exist:**
- ✓ FOUND: `e_office_app_new/backend/src/services/lgsp/error-codes.ts` (82 lines)
- ✓ FOUND: `e_office_app_new/backend/src/services/lgsp/edxml-builder.ts` (263 lines)
- ✓ FOUND: `e_office_app_new/backend/src/services/lgsp-real.service.ts` (modified)
- ✓ FOUND: `e_office_app_new/backend/src/services/lgsp.service.ts` (modified)
- ✓ FOUND: `e_office_app_new/backend/src/services/lgsp-mock.service.ts` (modified)
- ✓ FOUND: `e_office_app_new/backend/package.json` (xmlbuilder2 + form-data added)

**Commits exist:**
- ✓ FOUND: 6931632 (Task 1 error-codes)
- ✓ FOUND: 2be33ee (Task 2 edxml-builder + deps)
- ✓ FOUND: f08288c (Task 3 sendDocument fix)

**Acceptance grep checks:**
- ✓ `form.append('edocFile'` present in lgsp-real.service.ts
- ✓ `form.append('messageType'` present
- ✓ `'X-SystemId':` + `'X-SecretKey':` headers present
- ✓ `/v1/sendEdoc` fetch URL present (NOT `/api/lgspedoc/send-edoc`)
- ✓ `import FormData from 'form-data'` present
- ✓ `LgspSendError` imported + thrown 4x
- ✓ `errorCode?: string` in LgspSendResult interface
- ✓ Signature `(edxmlBuffer: Buffer, destOrgCode: string, docCode: string)` in interface + impl + mock

**TypeScript:** `npx tsc --noEmit` exit 0 (zero errors)

**Smoke tests:** 2/2 PASS (builder produces valid XML, error mapper returns correct Vietnamese)
