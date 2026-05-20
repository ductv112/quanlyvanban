---
phase: 35-receive-flow-cron-syncreceivededoclist
plan: 01
subsystem: backend/lgsp
tags: [backend, schema, lgsp, edxml, parser, repository, phase-35]
requirements: [LGSP-RECV-02, LGSP-RECV-03, LGSP-RECV-04, LGSP-RECV-05, LGSP-RECV-06]

dependency_graph:
  requires:
    - phase-33 (LGSP factory getLgspService + lgsp_agency_config repo + crypto.decryptSecret)
    - phase-34 (LGSPRealService sendDocument fix pattern + edxml-builder)
    - phase-18 (LGSPRealService skeleton + ILgspService interface baseline)
  provides:
    - schema/000_schema_v3.0.sql: ADD COLUMN edoc.incoming_docs.lgsp_sender_org_code VARCHAR(13) + partial index
    - services/lgsp/edxml-parser.ts (parseEdxml + ParsedEdxml/EdxmlMessageHeader/ParsedEdxmlAttachment types)
    - LGSPRealService.receiveDocuments(fromYmd, toYmd) -> /v1/syncReceivedEdocList with X-SystemId/X-SecretKey
    - LGSPRealService.getEdocById(docId) -> /v1/getEdoc with X-SystemId/X-SecretKey
    - ILgspService interface signatures updated + 3 new export types (Summary/Full/FullAttachment)
    - incomingDocRepository.createFromLgsp() + createLgspAttachment() + types
    - interOrganizationRepository.autoRegisterFromLgsp() + findByCode()
  affects:
    - lgsp-mock.service.ts (signature update to match new ILgspService 2-arg receiveDocuments + getEdocById)
    - routes/lgsp.ts:/receive-poll (updated for new 2-arg signature + getEdocById call -- will be replaced by Plan 35-03)

tech_stack:
  added:
    - fast-xml-parser@^4.4.0 (~50KB type-safe XML parser, no transitive deps, paired with xmlbuilder2 from Phase 34)
  patterns:
    - Pure function parseEdxml(xml) -> typed ParsedEdxml (separate from worker I/O)
    - removeNSPrefix config to handle namespace-prefixed edXML envelopes
    - isArray hint forces [Attachment, Path] always-array even single-element
    - SP-message-substring dedup detection (catches inner 23505 raised by SP's WHEN OTHERS)
    - Post-insert rawQuery UPDATE for column not in SP signature (lgsp_sender_org_code)
    - INSERT ... ON CONFLICT (code) DO NOTHING + SELECT-by-code race-safe auto-register

key_files:
  created:
    - e_office_app_new/backend/src/services/lgsp/edxml-parser.ts (153 lines)
    - e_office_app_new/backend/src/repositories/inter-organization.repository.ts (77 lines)
  modified:
    - e_office_app_new/database/schema/000_schema_v3.0.sql (+22 lines, Phase 35 section appended at end)
    - e_office_app_new/backend/package.json (+1 dep: fast-xml-parser)
    - e_office_app_new/backend/package-lock.json (lockfile update)
    - e_office_app_new/backend/src/services/lgsp-real.service.ts (445 lines, +~80 lines for receiveDocuments rewrite + new getEdocById, -~22 lines old getDocumentDetail removed)
    - e_office_app_new/backend/src/services/lgsp.service.ts (268 lines, +~50 lines for 3 new types + updated interface)
    - e_office_app_new/backend/src/services/lgsp-mock.service.ts (124 lines, mock data shape rewrite + new getEdocById)
    - e_office_app_new/backend/src/repositories/incoming-doc.repository.ts (560 lines, +~125 lines for createFromLgsp + createLgspAttachment + 2 types)
    - e_office_app_new/backend/src/routes/lgsp.ts (Rule 3 auto-fix: /receive-poll updated for new 2-arg signature)

decisions:
  - D-05 honored: fast-xml-parser ^4.4.0 added (~50KB, no transitive deps)
  - D-06 honored: field mapping per spec — From.OrganId -> lgsp_sender_org_code, From.OrganName -> publish_unit, Code.CodeNumber -> notation, Code.CodeNotation -> document_code, Subject -> abstract, SignerInfo.Signer -> signer, PromulgationInfo.PromulgationDate -> sign_date + publish_date
  - D-08 honored: interOrganizationRepository.autoRegisterFromLgsp() with is_active=FALSE default + ON CONFLICT DO NOTHING (race-safe)
  - D-09 honored: createFromLgsp() catches dedup via SP message substring (idx_incoming_docs_external_dedupe / duplicate key / unique constraint) -> returns { skipped: true } NO throw
  - D-13 honored: schema append idempotent ADD COLUMN IF NOT EXISTS lgsp_sender_org_code VARCHAR(13) + CREATE INDEX IF NOT EXISTS partial WHERE NOT NULL
  - Postman authoritative: /v1/syncReceivedEdocList + /v1/getEdoc with X-SystemId/X-SecretKey headers (Phase 18 broken /api/lgspedoc/* endpoints fully removed from receive path)
  - YYYY/MM/DD format for fromDate/toDate query params (NOT YYYY-MM-DD) per LGSP spec
  - 60s timeout for getEdocById (vs 30s for syncReceivedEdocList) — attachments can be large
  - Buffer.from(base64) for attachment content (returns Buffer, not string)
  - removeNSPrefix=true to handle <e:EdXMLEnvelope xmlns:e="http://www.go.vn/eDoc"> namespace prefix
  - LgspReceivedDoc legacy type kept @deprecated for backward-compat with old code paths

metrics:
  duration: "~12m"
  tasks_completed: 3
  files_modified: 7
  files_created: 2
  lines_added: ~480
  commits: 3
  ts_errors: 0
  smoke_tests_passed: 18/18 (4 cases, 18 assertions)
  schema_reapply_zero_error: true
  sp_count: 361 (baseline preserved)
  completed_date: 2026-05-20
---

# Phase 35 Plan 01: LGSP Receive — Schema + Parser + Service Fix + Repos Summary

**Plan 35-01:** Foundation for Phase 35 receive flow. Append idempotent schema (`lgsp_sender_org_code` column + partial index), add `fast-xml-parser` dep, fix Phase 18 broken `LGSPRealService.receiveDocuments()` to use real `/v1/syncReceivedEdocList` + add new `getEdocById()` per Postman authoritative (mirror Phase 34 sendDocument fix pattern), create `services/lgsp/edxml-parser.ts` module, extend `incoming-doc.repository.ts` with `createFromLgsp()` + dedup catch, create `inter-organization.repository.ts` with `autoRegisterFromLgsp()` per CONTEXT D-08.

## Summary

3 tasks shipped in Wave 1 (Plan 35-01 of 5):

### Task 1 — Schema + dep (commit ebd3835)

- Appended Phase 35 section at END of `database/schema/000_schema_v3.0.sql`:
  ```sql
  ALTER TABLE edoc.incoming_docs
    ADD COLUMN IF NOT EXISTS lgsp_sender_org_code VARCHAR(13) NULL;
  CREATE INDEX IF NOT EXISTS idx_incoming_docs_lgsp_sender
    ON edoc.incoming_docs(lgsp_sender_org_code)
    WHERE lgsp_sender_org_code IS NOT NULL;
  ```
- Added `fast-xml-parser ^4.4.0` to `backend/package.json` (~50KB, no transitive deps; paired with `xmlbuilder2` from Phase 34 for symmetric send/receive XML handling).
- Applied schema to dev DB twice: first apply OK, second apply (idempotent verify) zero error.
- Verified after second apply: column + index exist; SP count = 361 (matches baseline, no regression).

### Task 2 — LGSPRealService receive fix + edxml-parser (commit 459f98d)

Migration from Phase 18 BROKEN to Phase 35 CORRECT (mirror Phase 34 sendDocument fix):

| Aspect | Phase 18 (BROKEN) | Phase 35 (CORRECT) |
|---|---|---|
| receiveDocuments URL | `GET /api/lgspedoc/received-edocs?token=...&systemId=...&secretKey=...` | `GET /v1/syncReceivedEdocList?messageType=edoc&fromDate=...&toDate=...` |
| receiveDocuments auth | Login token + creds in query string | HTTP headers `X-SystemId` + `X-SecretKey` |
| receiveDocuments signature | `()` (hardcoded last-7-days) | `(fromDateYmd: string, toDateYmd: string)` (caller computes window) |
| Date format | `YYYY-MM-DD` (ISO slice) | `YYYY/MM/DD` (LGSP spec) |
| Detail fetch | Private `getDocumentDetail(token, docId)` called inside loop | Public `getEdocById(docId)` separate method, caller controls when to fetch |
| getEdoc URL | `GET /api/lgspedoc/get-edoc?token=...&docId=...` (private, removed) | `GET /v1/getEdoc?docId=<uuid>` (public, new) |
| getEdoc timeout | 30s | 60s (attachments may be large) |
| Return shape | `LgspReceivedDoc[]` (mixed list + detail fields) | `LgspReceivedDocSummary[]` from list, `LgspReceivedDocFull | null` from detail |
| Error handling | Silent catch + return null | `throw` on credential missing (worker classifies retry) |

Created `services/lgsp/edxml-parser.ts` (153 lines):
- `parseEdxml(xml: string): ParsedEdxml` pure function (no I/O — separate from worker)
- 3 exported types: `ParsedEdxml`, `EdxmlMessageHeader`, `ParsedEdxmlAttachment`
- Parser config: `removeNSPrefix=true` (handles `<e:EdXMLEnvelope>` namespace), `isArray=[Attachment, Path]` (forces always-array even single element), `parseTagValue=false` (keeps `123` as string not number)
- Supports both `<EdXML>` and `<EdXMLEnvelope>` root elements
- Attachment content decoded from base64 to `Buffer` for direct MinIO upload by worker
- Throws on malformed XML / missing root / missing MessageHeader (caller decides retry vs skip)
- Skips incomplete attachments (no filename or no content) with `pino.warn` log

Updated `lgsp.service.ts` interface:
- `receiveDocuments(): Promise<LgspReceivedDoc[]>` → `receiveDocuments(fromYmd, toYmd): Promise<LgspReceivedDocSummary[]>`
- NEW `getEdocById(docId): Promise<LgspReceivedDocFull | null>`
- 3 new exported types: `LgspReceivedDocSummary`, `LgspReceivedDocFull`, `LgspReceivedDocFullAttachment`
- Kept `LgspReceivedDoc` as `@deprecated` for backward-compat with any external imports

Updated `lgsp-mock.service.ts`:
- New `MOCK_DOC_SUMMARIES` shape matching `LgspReceivedDocSummary`
- New `buildMockEdxml()` helper producing valid edXML envelope for `getEdocById` mock response
- `receiveDocuments(fromYmd, toYmd)` accepts new 2 args (ignores in mock, logs them)
- NEW `getEdocById(docId)` returns mock `LgspReceivedDocFull` with parseable `edxml` string

### Task 3 — Repositories: createFromLgsp + autoRegisterFromLgsp (commit 9866e99)

Extended `incoming-doc.repository.ts`:
- `createFromLgsp(input: CreateFromLgspInput): Promise<CreateFromLgspResult>` — calls existing SP `edoc.fn_incoming_doc_create` (28 positional args) with `source_type='external_lgsp'` + `external_doc_id` (UNIQUE dedup via `idx_incoming_docs_external_dedupe`)
- Dedup detection: SP message substring check (`'idx_incoming_docs_external_dedupe'` | `'duplicate key'` | `'unique constraint'`) → returns `{ skipped: true }` NO throw (CONTEXT D-09)
- Post-insert: `rawQuery UPDATE edoc.incoming_docs SET lgsp_sender_org_code = $1 WHERE id = $2` (Phase 35 new column not in SP signature)
- `createLgspAttachment(params)` — delegates to existing SP `edoc.fn_attachment_incoming_create` (verified at `schema/000_schema_v3.0.sql:722`)
- 2 new exported types: `CreateFromLgspInput`, `CreateFromLgspResult`
- String slicing to DB VARCHAR limits (50/100/200/500/1000/13) as safety net

Created `inter-organization.repository.ts` (77 lines):
- `interOrganizationRepository` const object
- `autoRegisterFromLgsp(code, name) → { id, created }` — `INSERT ... ON CONFLICT (code) DO NOTHING RETURNING id` then `SELECT id by code` if conflict (race-safe — handles 2 concurrent cron ticks landing on same sender)
- `is_active=FALSE` default per CONTEXT D-08 (admin verifies later via Phase 37 UI)
- `findByCode(code) → InterOrgRow | null`
- All string params truncated to `code≤100` / `name≤500` (matches DB VARCHAR limits)

## Verification

**TypeScript strict:** `cd e_office_app_new/backend && npx tsc --noEmit` exits 0 (zero errors). Verified after each task commit AND final end-of-plan.

**Schema idempotency:** Applied master schema to dev DB **3 times** (Task 1 first + second + final verification). Each apply exits 0, zero `ERROR`/`FATAL` lines printed. Second/third applies show `NOTICE: column "lgsp_sender_org_code" already exists, skipping` + `NOTICE: relation "idx_incoming_docs_lgsp_sender" already exists, skipping` (correct idempotent behavior).

**Column + index exist in DB:**
```
$ docker exec qlvb_postgres psql -tAc "SELECT 1 FROM information_schema.columns WHERE table_schema='edoc' AND table_name='incoming_docs' AND column_name='lgsp_sender_org_code'"
1

$ docker exec qlvb_postgres psql -tAc "SELECT indexname FROM pg_indexes WHERE schemaname='edoc' AND indexname='idx_incoming_docs_lgsp_sender'"
idx_incoming_docs_lgsp_sender
```

**SP count baseline preserved:**
```
$ docker exec qlvb_postgres psql -tAc "SELECT count(*) FROM pg_proc WHERE pronamespace IN ('public'::regnamespace,'edoc'::regnamespace) AND proname LIKE 'fn_%'"
361
```
(Phase 33 baseline = 361. Plan 35-01 did not add or remove any SP — only schema column + indexes.)

**Smoke test for edxml-parser: 18/18 PASS (4 test cases):**

```
--- Test 1 (happy path + 1 attachment, base64 "hello" = "aGVsbG8=") ---
PASS: T1.from.organId === H37.DN.002
PASS: T1.code.codeNumber === "123"
PASS: T1.documentId === uuid-1
PASS: T1.attachments.length === 1
PASS: T1.attachments[0].fileName === a.pdf
PASS: T1.attachments[0].content is Buffer
PASS: T1.attachments[0].content decodes to "hello"
PASS: T1.raw === input
PASS: T1.signerInfo.position === GD
PASS: T1.otherInfo.pageAmount === 2

--- Test 2 (no Manifest, no attachments) ---
PASS: T2.attachments.length === 0
PASS: T2.documentId === uuid-2
PASS: T2.signerInfo.position undefined
PASS: T2.otherInfo.pageAmount undefined

--- Test 3 (malformed XML) ---
  threw as expected: parseEdxml: invalid XML -- Cannot read properties of undefined (reading 'tagName')
PASS: T3 throws on malformed

--- Test 4 (namespace-prefixed root: <e:EdXMLEnvelope xmlns:e="http://www.go.vn/eDoc">) ---
PASS: T4.documentId === uuid-3
PASS: T4.from.organId === X
PASS: T4.attachments.length === 0

=== SUMMARY: 18 PASS, 0 FAIL ===
```

Smoke test file `_smoke_edxml_parser.mjs` deleted after run (temp verification artifact only).

**Acceptance grep checks: all 28 PASS** (12 for Task 2, 13 for Task 3, 3 for Task 1):

Task 1 — schema + dep:
- `grep -q "ADD COLUMN IF NOT EXISTS lgsp_sender_org_code" 000_schema_v3.0.sql` PASS
- `grep -q "idx_incoming_docs_lgsp_sender" 000_schema_v3.0.sql` PASS
- `grep -q '"fast-xml-parser"' backend/package.json` PASS

Task 2 — service fix + parser (12 checks):
- `/v1/syncReceivedEdocList` (2 hits) PASS
- `/v1/getEdoc` (2 hits) PASS
- `X-SystemId` (8 hits — receive + getEdocById + sendDocument from Phase 34) PASS
- `/api/lgspedoc/received-edocs` (0 hits — broken endpoint REMOVED) PASS
- `/api/lgspedoc/get-edoc` (0 hits — broken endpoint REMOVED) PASS
- `export function parseEdxml` (1 hit in edxml-parser.ts) PASS
- `export interface ParsedEdxml` (2 hits — ParsedEdxml + ParsedEdxmlAttachment) PASS
- `import { XMLParser } from 'fast-xml-parser'` (1 hit) PASS
- `removeNSPrefix` (2 hits — config + comment) PASS
- `isArray.*Attachment` (2 hits) PASS
- `getEdocById` (2 hits in lgsp.service.ts interface + jsdoc) PASS
- `LgspReceivedDocFull` (5 hits in lgsp.service.ts: type def + interface return + jsdoc + import) PASS

Task 3 — repositories (13 checks):
- `async createFromLgsp` (1 hit) PASS
- `CreateFromLgspInput` (2 hits — type def + method param) PASS
- `CreateFromLgspResult` (2 hits — type def + method return) PASS
- `skipped: true` (1 hit — dedup return path) PASS
- `idx_incoming_docs_external_dedupe|duplicate key` (4 hits combined) PASS
- `external_lgsp` (2 hits — SP arg + comment) PASS
- `lgsp_sender_org_code` (5 hits — UPDATE + comment + input field) PASS
- `fn_incoming_doc_create` (3 hits — SP call + 2 comments) PASS
- `async createLgspAttachment` (1 hit) PASS
- `export const interOrganizationRepository` (1 hit) PASS
- `async autoRegisterFromLgsp` (1 hit) PASS
- `ON CONFLICT (code) DO NOTHING` (2 hits — SQL + jsdoc) PASS
- `is_active.*FALSE` (2 hits — INSERT default + jsdoc) PASS

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] routes/lgsp.ts /receive-poll updated for new 2-arg signature**
- **Found during:** Task 2 (after updating ILgspService interface)
- **Issue:** `routes/lgsp.ts:171` calls `service.receiveDocuments()` with 0 args + reads old shape fields (`sender_org_code`, `sender_org_name`, `edxml_content`). TS strict refused to compile after I narrowed the interface signature.
- **Fix:** Updated `/receive-poll` route to:
  - Compute 7-day window + format `YYYY/MM/DD` via local `formatYmd()` helper
  - Call `service.receiveDocuments(fromYmd, toYmd)` with 2 args → `LgspReceivedDocSummary[]`
  - Loop summaries + call `service.getEdocById(summary.lgsp_doc_id)` for each to fetch full payload
  - Read fields from `LgspReceivedDocFull` (`full.sender_org_code`, `full.sender_org_name`, `full.edxml`)
  - Added comment noting this route will be replaced by `POST /api/lgsp/sync-now` in Plan 35-03
- **Files modified:** `e_office_app_new/backend/src/routes/lgsp.ts`
- **Commit:** 459f98d (included in Task 2 commit since same interface change)

### Plan-driven changes (no deviations)

- D-05/D-06/D-08/D-09/D-13 honored exactly per CONTEXT
- Schema append uses idempotent `ADD COLUMN IF NOT EXISTS` + `CREATE INDEX IF NOT EXISTS`
- Vietnamese KHÔNG DẤU in comments/log strings (CLAUDE.md PowerShell 5.1 safe pattern)
- `fn_attachment_incoming_create` SP verified to exist at schema line 722 → repo uses SP path (not inline rawQuery fallback)
- `getToken()` left unchanged (still used by `syncOrganizations` admin API) — added clarifying comment

## Authentication Gates

None. Plan executed fully autonomously — no auth prompts encountered.

## Known Stubs / Caveats

**1. `created_by` will be hardcoded to system staff_id (Plan 35-02 worker)**
- Plan 35-02 worker will pass `created_by: 1` (admin) when calling `createFromLgsp()` because no dedicated `lgsp-system` user exists yet.
- TODO Phase 37: create dedicated `lgsp-system` staff user; admin UI sets it via config.
- Until then, audit log will attribute LGSP-received docs to the admin user — acceptable for v3.2 launch since admin is the only super-user.

**2. `extra_fields.edxml_raw` + `extra_fields.message_header` JSONB columns NOT stored yet**
- `CreateFromLgspInput.edxml_raw` is accepted by the method signature but the SP `fn_incoming_doc_create` has no `p_extra_fields` parameter. Currently the raw edXML is dropped (only `lgsp_sender_org_code` denormalized column is persisted).
- TODO: Plan 35-02 OR Plan 35-03 should either (a) add a `p_extra_fields jsonb` arg to the SP, or (b) UPDATE `extra_fields` column directly via `rawQuery` after insert (mirror the existing `lgsp_sender_org_code` UPDATE pattern).
- For now this means: dev cannot re-parse the original edXML if the parser is later improved. Mitigation: full edXML is also stored in `lgsp_tracking.edxml_content` (Phase 18 column) for any incoming doc that has a tracking row.

**3. `doc_type_id` always passed as the value from worker (no auto-lookup yet)**
- Plan 35-02 worker is responsible for the `doc_types.name = MessageHeader.DocumentType` lookup. If no match, worker passes `null` and admin assigns later from VB-đến edit form.
- This is per CONTEXT D-06 design (avoid silent miscategorization).

**4. `routes/lgsp.ts:/receive-poll` will be replaced by Plan 35-03**
- Current `/receive-poll` route is auto-fix-patched to compile but is NOT the production entry point. Plan 35-03 will add `POST /api/lgsp/sync-now` which enqueues the BullMQ tick job (mirroring Phase 34 send queue pattern).
- `/receive-poll` will likely be removed or repurposed at that time.

## SP Existence Check (per Plan request)

`edoc.fn_attachment_create_for_incoming` (Plan asked which path to take): **NOT FOUND** in schema. Instead, the existing SP `edoc.fn_attachment_incoming_create` (same purpose, different name — verified at `database/schema/000_schema_v3.0.sql:722`) is used by `createLgspAttachment()`. This is the same SP already used by `incomingDocRepository.createAttachment()` (line 255) for manual attachment uploads, so behavior is symmetric with the existing manual flow.

Signature confirmed: `edoc.fn_attachment_incoming_create(p_doc_id bigint, p_file_name varchar, p_file_path varchar, p_file_size bigint, p_content_type varchar, p_created_by integer) RETURNS TABLE(success boolean, message text, id bigint)`.

## Threat Flags

None introduced by Plan 35-01. The new code paths handle untrusted inputs (LGSP-supplied sender org code, edXML content, filenames) by:
- String slicing to DB VARCHAR limits (truncation safety net against oversized injection attempts)
- `parameterized $1/$2` SQL via `rawQuery` (no concatenation — SQL injection safe)
- base64 decode wrapped in try/catch (malformed payload skipped, not crashed)
- XML parsing throws on malformed input (caller decides retry vs skip — does not corrupt DB)
- `is_active=FALSE` default on auto-registered inter_organizations (admin gate before sender trusted)

LGSP credentials still managed entirely by Phase 33 secure path (BYTEA encrypted, `crypto.decryptSecret`, never logged). Plan 35-01 only consumes credentials via `LgspCredentials` object — no new exposure.

## Next Steps

**Plan 35-02:** BullMQ worker module `lgsp-receive-worker.ts` + queue `lgsp-receive-queue.ts` consume:
- Reads `lgspAgencyConfigRepository.getAllActive()` to get list of DNs to poll
- For each DN: `getLgspService(unit_id, env)` → `receiveDocuments(fromYmd, toYmd)` → loop summaries
- For each new summary: `getEdocById(docId)` → `parseEdxml(full.edxml)` → upload attachments to MinIO → `interOrganizationRepository.autoRegisterFromLgsp(code, name)` → `incomingDocRepository.createFromLgsp(input)` → loop attachments + `createLgspAttachment()`
- Update `lgsp_agency_config.last_synced_at` + `last_sync_error` per CONTEXT D-10/D-11
- INSERT `lgsp_status_outbox` row `target_status='01'` for Phase 36 to consume

**Plan 35-03:** Backend route `POST /api/lgsp/sync-now` + cron tick registration on server boot.

**Plan 35-04:** Frontend tab VB-đến — render Tag "LGSP" + filter dropdown nguồn + detail page LGSP section.

**Plan 35-05:** E2E verification per CONTEXT D-16.

## Commits

- `ebd3835` feat(35-01): them lgsp_sender_org_code column + fast-xml-parser dep
- `459f98d` feat(35-01): fix LGSPRealService receive + getEdocById + edxml-parser
- `9866e99` feat(35-01): incoming-doc.createFromLgsp + inter-organization auto-register

## Self-Check: PASSED

**Files exist:**
- FOUND: `e_office_app_new/backend/src/services/lgsp/edxml-parser.ts` (153 lines)
- FOUND: `e_office_app_new/backend/src/repositories/inter-organization.repository.ts` (77 lines)
- FOUND: `e_office_app_new/backend/src/services/lgsp-real.service.ts` (modified, 445 lines)
- FOUND: `e_office_app_new/backend/src/services/lgsp.service.ts` (modified, 268 lines)
- FOUND: `e_office_app_new/backend/src/services/lgsp-mock.service.ts` (modified, 124 lines)
- FOUND: `e_office_app_new/backend/src/repositories/incoming-doc.repository.ts` (modified, 560 lines)
- FOUND: `e_office_app_new/backend/src/routes/lgsp.ts` (Rule 3 auto-fix, 221 lines)
- FOUND: `e_office_app_new/backend/package.json` (fast-xml-parser added)
- FOUND: `e_office_app_new/database/schema/000_schema_v3.0.sql` (Phase 35 section appended)

**Commits exist:**
- FOUND: ebd3835 (Task 1 schema + dep)
- FOUND: 459f98d (Task 2 service + parser)
- FOUND: 9866e99 (Task 3 repos)

**Acceptance grep checks:** 28/28 PASS (3 Task 1 + 12 Task 2 + 13 Task 3)

**TypeScript:** `npx tsc --noEmit` exit 0 (zero errors) — verified end-of-plan

**Smoke tests:** 18/18 PASS (parser produces correct output for happy path / no-attachment / namespace-prefixed; throws on malformed)

**Schema idempotency:** PASS (3-time re-apply zero ERROR/FATAL; column + index exist in DB; SP count = 361 baseline preserved)
