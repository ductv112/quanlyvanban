# Deferred Items — 260521-v8t

Out-of-scope issues discovered during execution. NOT fixed (per CLAUDE.md scope boundary rule).

## Pre-existing TS errors (backend) — NOT caused by this plan

`npx tsc --noEmit` in `e_office_app_new/backend` reports 3 errors in unrelated files:

| File | Error | Module missing |
|---|---|---|
| `src/services/lgsp-real.service.ts:14` | TS2307 Cannot find module | `form-data` |
| `src/services/lgsp/edxml-builder.ts:15` | TS2307 Cannot find module | `xmlbuilder2` |
| `src/services/signing/pdf-signer.ts:28` | TS2307 Cannot find module | `@pdf-lib/fontkit` |

**Root cause:** `node_modules` missing 3 transitive deps (likely never installed locally; runtime works because they exist in `package.json`).

**Action:** Run `npm install` in `e_office_app_new/backend` to install the declared deps. NOT done here — outside this plan's scope (preview feature).

These errors exist on `main` BEFORE this plan started. The new files (`office-converter.ts`, `attachment-preview.ts`) compile clean.
