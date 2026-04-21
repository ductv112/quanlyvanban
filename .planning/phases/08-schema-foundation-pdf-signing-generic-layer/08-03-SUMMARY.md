---
phase: 08-schema-foundation-pdf-signing-generic-layer
plan: 03
subsystem: backend
tags: [signing, pdf-lib, pkcs7, pades, node-signpdf, node-forge, pure-js, unit-test]

# Dependency graph
requires:
  - phase: 08-01
    provides: edoc.sign_transactions table (stores file_hash_sha256 + signature_base64)
provides:
  - backend/src/services/signing/pdf-signer.ts — generic PDF signing API (4 exports)
  - backend/src/services/signing/types.ts — shared types (SignatureMetadata, PdfHashResult, PdfSignResult, PlaceholderOptions)
  - backend/src/services/signing/pdf-signer.test.ts — 10 unit tests via node:test runner
  - PrecomputedSigner pattern — bridges @signpdf/utils.Signer contract with pre-fetched external signatures
affects: [08-04, Phase 9 (provider adapters SmartCA/MySign), Phase 11 (sign flow + async worker)]

# Tech tracking
tech-stack:
  added:
    - "@signpdf/signpdf@3.3.0 — embed PKCS7 detached into PDF placeholder"
    - "@signpdf/placeholder-plain@3.3.0 — classic /ByteRange placeholder injection"
    - "@signpdf/signer-p12@3.3.0 — optional p12 signer (reserved for test fixtures)"
    - "node-forge@1.4.0 — PKCS7 structure building + self-signed cert for tests"
    - "@types/node-forge@1.3.14 (dev) — TS types"
  patterns:
    - "PrecomputedSigner extends @signpdf/utils.Signer — returns pre-fetched signature Buffer without local cert access"
    - "extractByteRange() with fallback — supports both filled ByteRange and unfilled placeholder (compute from /Contents position)"
    - "Node built-in test runner (node:test) via tsx — no jest/vitest dependency needed"
    - "Error messages in Vietnamese throughout signing layer (consistent with project convention)"

key-files:
  created:
    - e_office_app_new/backend/src/services/signing/types.ts
    - e_office_app_new/backend/src/services/signing/pdf-signer.ts
    - e_office_app_new/backend/src/services/signing/pdf-signer.test.ts
  modified:
    - e_office_app_new/backend/package.json (5 new deps)
    - e_office_app_new/backend/package-lock.json (auto)

key-decisions:
  - "Pre-computed signature strategy — Signer subclass returns signature from provider, doesn't compute locally (matches SmartCA/MySign flow where private key never leaves HSM/CA)"
  - "pdf-lib `useObjectStreams: false` required for test PDFs — @signpdf/placeholder-plain only reads classic xref tables, not cross-reference streams"
  - "Fallback ByteRange parser — computes from /Contents < position when plainAddPlaceholder leaves placeholder markers (`/ByteRange [0 /* 0 /*]`) unfilled; primary path matches numeric ByteRange after SignPdf.sign fills it"
  - "Node built-in test runner (`node --test` via tsx) — avoids adding jest/vitest (~20MB dep) for 10 unit tests"
  - "Error messages tiếng Việt only — signature layer stays consistent with rest of backend (Vietnamese UX per project rules)"

patterns-established:
  - "Pattern: PDF signing bridge — generic layer receives hash, delegates to provider, receives PKCS7 base64, embeds via Signer subclass. Adapter layer (Phase 9) only needs to implement the provider call, not the PKCS7/PDF plumbing."
  - "Pattern: Custom Signer extending @signpdf/utils.Signer for non-local-key scenarios (remote CA, HSM, provider gateway)"
  - "Pattern: PAdES byte range fallback parser — robust against placeholder-vs-filled state ambiguity"

requirements-completed: [SIGN-04]

# Metrics
duration: ~12min
completed: 2026-04-21
---

# Phase 8 Plan 3: PDF Signing Generic Layer Summary

**Pure-JS PDF signing layer for PKCS7 detached signatures (PAdES) — 4 exports (`addSignaturePlaceholder`, `computePdfHash`, `prepareSignPdf`, `signPdf`) shared by SmartCA VNPT and MySign Viettel adapter layers in Phase 9+. 10 unit tests pass via `tsx --test` using self-signed mock PKCS7 (node-forge).**

## Performance

- **Duration:** ~12 min (695s — npm install + implementation + 1 Rule 3 blocking fix + tests passing + commits)
- **Started:** 2026-04-21T06:33:58Z
- **Completed:** 2026-04-21T06:45:33Z
- **Tasks:** 2
- **Files modified:** 3 created + 2 modified (package.json, package-lock.json)

## Accomplishments

- Generic PDF signing layer (238 lines `pdf-signer.ts` + 65 lines `types.ts`) complete — ready for Phase 9 adapter layer
- 5 packages installed at production-stable versions (@signpdf/* v3.3.0, node-forge v1.4.0)
- Unit test suite: 10 tests across 4 describe blocks, all passing via Node's built-in test runner — no new test framework dependency added
- Self-signed PKCS7 signature generation helper (`createMockPkcs7Signature`) usable by downstream adapter tests without real provider credentials
- Zero TypeScript errors in `services/signing/` (verified against existing tech debt in other route files — no new errors introduced)

## Task Commits

1. **Task 1: Install packages + types.ts** — `fc7115d` (feat)
2. **Task 2: Implement pdf-signer.ts + unit tests** — `9d14ca5` (feat)

**Plan metadata:** _pending this commit_ (docs: complete plan)

## Files Created/Modified

- `e_office_app_new/backend/src/services/signing/types.ts` — **created** (65 lines)
  - 4 exported interfaces: `SignatureMetadata`, `PdfHashResult`, `PdfSignResult`, `PlaceholderOptions`
- `e_office_app_new/backend/src/services/signing/pdf-signer.ts` — **created** (238 lines)
  - `PrecomputedSigner` class (internal) — bridges `@signpdf/utils.Signer` with external signature
  - `extractByteRange()` (internal) — parses `/ByteRange` with dual-mode fallback
  - `addSignaturePlaceholder(pdf, options)` — PAdES placeholder injection via plainAddPlaceholder
  - `computePdfHash(placeholderPdf)` — SHA256 of byte range (PAdES)
  - `prepareSignPdf(pdf, options)` — convenience combining the two above
  - `signPdf(placeholderPdf, signatureBase64)` — embed PKCS7 into `/Contents`
- `e_office_app_new/backend/src/services/signing/pdf-signer.test.ts` — **created** (186 lines, 10 tests)
- `e_office_app_new/backend/package.json` — **modified** (5 deps added)
- `e_office_app_new/backend/package-lock.json` — **modified** (auto by npm)

## Decisions Made

- **Pre-computed signature strategy via PrecomputedSigner subclass**: `@signpdf/signpdf@3.3.0` expects a `Signer` instance with `async sign(pdfBuffer, signingTime)` that computes a PKCS7 signature locally. For our use case (signature already obtained from SmartCA VNPT / MySign Viettel remotely), a custom subclass stores the pre-fetched Buffer in its constructor and returns it directly from `sign()`. This keeps the public API symmetric (`signPdf(placeholderPdf, signatureBase64)`) while satisfying @signpdf's internal `instanceof Signer` check.
- **`useObjectStreams: false` for test PDFs**: pdf-lib v1.17 defaults to writing cross-reference streams. `@signpdf/placeholder-plain`'s `readPdf.js` hard-fails with `"Expected xref at NaN but found other content."` because it only reads classic `trailer\n...xref...startxref\n%%EOF` blocks. Fix applied in `createSamplePdf()` test helper.
- **Fallback ByteRange parser in `extractByteRange()`**: `plainAddPlaceholder` outputs `/ByteRange [0 /* 0 /*]` (unfilled placeholder with asterisks). `SignPdf.sign` later replaces with numeric values `[0 100 200 300]`. The parser tries numeric match first; on miss, computes byte range from `/Contents <` marker position and PDF total length. This makes `computePdfHash` work against both states.
- **Node's built-in test runner (`node:test`) over jest/vitest**: 10 simple unit tests don't justify adding a testing framework (20+ MB dep tree). `tsx --test` runs TypeScript tests directly with zero config. Pattern scales to other future backend services.
- **Vietnamese-only error messages**: Consistent with the backend's `handleDbError` pattern and project rule "ALL UI text MUST be in Vietnamese with diacritics" — error messages bubbled up through signing service surface in response JSON eventually.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 — Bug] Fixed outdated `SignPdf.sign()` API signature in plan pseudocode**
- **Found during:** Task 2 (reading actual `@signpdf/signpdf@3.3.0` type definitions)
- **Issue:** Plan's `<interfaces>` section showed `signer.sign(pdfWithPlaceholder, signatureBuffer)` — this was the v1.x/v2.x API. In v3.3.0, `SignPdf.sign(pdfBuffer, signer: Signer, signingTime?: Date)` requires a `Signer` instance argument (with internal `async sign(pdf, time): Promise<Buffer>`), not a raw signature buffer.
- **Fix:** Created `PrecomputedSigner extends @signpdf/utils.Signer` that stores the provider's signature in its constructor and returns it from its `sign()` method. Verified the final signed PDF contains the signature bytes (not zero-filled placeholder).
- **Files modified:** `e_office_app_new/backend/src/services/signing/pdf-signer.ts`
- **Verification:** Test "embed mock PKCS7 signature thành công" — checks `/Contents <hex>` is not all zeros after signing. PASS.
- **Committed in:** Task 2 (`9d14ca5`)

**2. [Rule 3 — Blocking] pdf-lib output incompatible with @signpdf/placeholder-plain**
- **Found during:** Task 2 first test run (6 tests failing with same error)
- **Issue:** pdf-lib v1.17.1 defaults to `useObjectStreams: true` when saving, producing a PDF with cross-reference streams (modern format, objstm 7.5.8 per PDF spec). `@signpdf/placeholder-plain@3.3.0`'s `readPdf.js` only parses classic xref tables (PDF spec 7.5.5 trailer). It throws `"Expected xref at NaN but found other content."` → wrapped by our code as `"Không thể thêm signature placeholder vào PDF: Expected xref at NaN..."`.
- **Fix:** Changed test helper to `doc.save({ useObjectStreams: false })`. Documented the requirement in the helper's JSDoc so Phase 11 worker knows to apply it when reading attachments from MinIO (most PDFs from office tools already use classic xref, but pdf-lib-generated PDFs do not by default).
- **Files modified:** `e_office_app_new/backend/src/services/signing/pdf-signer.test.ts`
- **Verification:** Re-ran full test suite → 10/10 pass.
- **Committed in:** Task 2 (`9d14ca5`)

**3. [Rule 1 — Bug] node-forge authenticatedAttributes type mismatch in test**
- **Found during:** Task 2 (tsc check after writing test file)
- **Issue:** `@types/node-forge@1.3.14` declares `authenticatedAttributes: Array<{ type: string; value?: string }>`. At runtime, node-forge accepts a `Date` for the `signingTime` attribute value. TypeScript rejected `value: new Date()` with `TS2322: Type 'Date' is not assignable to type 'string'`.
- **Fix:** Cast `value: new Date() as any` with ESLint disable comment and explanatory JSDoc. Alternative would be to fork node-forge types, but that's disproportionate for a test helper.
- **Files modified:** `e_office_app_new/backend/src/services/signing/pdf-signer.test.ts`
- **Verification:** `npx tsc --noEmit` — zero errors in `services/signing/`.
- **Committed in:** Task 2 (`9d14ca5`)

---

**Total deviations:** 3 auto-fixed (2 Rule 1 bugs, 1 Rule 3 blocking)
**Impact on plan:** None of the deviations changed the public API shape documented in the plan's `<must_haves>`. They changed (a) internal plumbing to match the current `@signpdf/signpdf` v3 API contract, (b) test data generation to satisfy the placeholder library's parser expectations, and (c) a TypeScript-runtime mismatch in a 3rd-party dep. Spirit of plan preserved: `signPdf(buffer, base64)` signature is exactly as specified.

## Pre-existing Tech Debt (Out of Scope)

During `tsc --noEmit` for Task 1 verification, 21 pre-existing TypeScript errors surfaced in unrelated files:
- `routes/workflow.ts` (11 errors — Express 5 route handler type resolution with TypeScript 6)
- `routes/admin-catalog.ts` (3 errors — `number | null` vs `number`)
- `routes/handling-doc-report.ts` (4 errors — same Express 5 pattern as workflow.ts)
- `routes/inter-incoming.ts` (1 error — unknown property `docTypeId` in repository search filter)
- `scripts/fix-staff-ids.ts` (2 errors — no longer tracked)

These errors **existed before this plan** (verified via `git stash` test before starting work). They are pre-existing tech debt accumulated from v1.0 Sprint 0-17. Logged to future-phase cleanup backlog, NOT fixed here (scope boundary: only fix issues caused by this plan's changes).

Logged to: `deferred-items.md` — _not created for this plan_ since items belong to broader v1.0 backlog cleanup (Phase 14 Deployment may address Express 5 type compatibility globally).

## API Reference for Phase 9+

Downstream consumers (adapter layer for SmartCA/MySign, sign flow in Phase 11):

```typescript
import {
  prepareSignPdf,
  signPdf,
  type PdfHashResult,
  type PdfSignResult,
} from '@/services/signing/pdf-signer.js';  // backend ESM alias

// Phase 11 flow:
//   1) User clicks "Sign" → backend loads PDF from MinIO
const pdfBuffer: Buffer = await minioClient.getObject(bucket, objectKey);

//   2) Prepare PDF + hash (server-side, synchronous)
const prep: PdfHashResult = prepareSignPdf(pdfBuffer, {
  reason: 'Phê duyệt văn bản đi',
  name:   'Nguyễn Văn A',
  location: 'Lào Cai',
});
//   prep.hash           — send to provider
//   prep.placeholderPdf — keep in memory or Redis for step 4
//   prep.byteRange      — debug/audit

//   3) Adapter calls provider with hash (Phase 9 responsibility)
//      Provider returns PKCS7 detached base64 (SmartCA VNPT + MySign Viettel both use this format)
const signatureBase64: string = await smartCAAdapter.sign(prep.hash, providerConfig);

//   4) Embed signature back into PDF (this layer)
const result: PdfSignResult = await signPdf(prep.placeholderPdf, signatureBase64);
//   result.signedPdf  — upload to MinIO as attachment_*.signed_file_path
//   result.finalHash  — persist to edoc.sign_transactions.final_file_hash for audit

await minioClient.putObject(bucket, `signed/${objectKey}`, result.signedPdf);
```

## Issues Encountered

- **MSYS bash PATH rewriting**: Not a blocker for this plan (all `npx` commands worked), but same pattern observed in Plan 08-02. If a future task needs `docker exec ... -f /path`, wrap with `sh -c "..."`.
- **pdf-lib cross-reference streams vs plain xref**: Not obvious from either lib's README. Documented in test helper JSDoc + this Summary. Phase 11 worker must ensure source PDFs have classic xref (most office tools produce classic; pdf-lib output does not by default).

## User Setup Required

None. All 5 new deps install from npm registry. No env vars added in this plan (provider credentials come in Phase 9 for Admin config).

## Next Phase Readiness

- **Ready for Plan 08-04 (integration smoke test)**: Generic signing API is exercised by 10 unit tests. 08-04 will add integration smoke test proving end-to-end chain (DB transaction create → hash compute → mock signature → embed → verify).
- **Ready for Phase 9 (Admin provider config + adapter layers)**: Adapter implementations only need to focus on the provider HTTP contract (SmartCA 3 endpoints, MySign 4 endpoints). PDF/PKCS7 plumbing is solved.
- **Phase 11 worker dependency note**: BullMQ sign worker will call this module's `prepareSignPdf` + `signPdf` — it must also handle PDF-lib output from upstream draft generation, or enforce input-PDF source is classic-xref. Add detection + reject with user-friendly message when source PDF uses object streams.

## Self-Check: PASSED

Verified:
- File `e_office_app_new/backend/src/services/signing/types.ts` exists (65 lines, 4 exported interfaces)
- File `e_office_app_new/backend/src/services/signing/pdf-signer.ts` exists (238 lines >= 120 required, all 4 exports present)
- File `e_office_app_new/backend/src/services/signing/pdf-signer.test.ts` exists (186 lines, 10 tests in 4 describe blocks)
- `package.json` contains: @signpdf/signpdf@^3.2.4, @signpdf/placeholder-plain@^3.2.4, @signpdf/signer-p12@^3.2.4, node-forge@^1.3.1
- `package.json` devDependencies contain: @types/node-forge@^1.3.11
- `npm ls` confirms installed versions: @signpdf/* @3.3.0, node-forge @1.4.0, @types/node-forge @1.3.14
- Commit `fc7115d` exists in git log: `feat(08-03): add @signpdf/* + node-forge deps + signing types`
- Commit `9d14ca5` exists in git log: `feat(08-03): implement generic PDF signer (addPlaceholder + hash + signPdf)`
- `npx tsx --test src/services/signing/pdf-signer.test.ts` → 10 pass, 0 fail, 0 cancelled
- Zero TS errors in `services/signing/` (pre-existing errors in routes/ are out of scope, verified pre-existing via git stash test)
- All 4 exports present: `addSignaturePlaceholder`, `computePdfHash`, `prepareSignPdf`, `signPdf`
- All 2 required imports present: `import { SignPdf } from '@signpdf/signpdf'`, `import { plainAddPlaceholder } from '@signpdf/placeholder-plain'`

---
*Phase: 08-schema-foundation-pdf-signing-generic-layer*
*Completed: 2026-04-21*
