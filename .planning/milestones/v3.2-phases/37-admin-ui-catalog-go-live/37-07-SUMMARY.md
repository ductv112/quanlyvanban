---
phase: 37-admin-ui-catalog-go-live
plan: 07
subsystem: docs
tags: [verification, documentation, go-live, milestone-v3.2, ship-readiness, phase-37]

# Dependency graph
requires:
  - phase: 37-admin-ui-catalog-go-live
    plan: 01
    provides: 12 admin endpoint /api/admin/lgsp-* + /api/admin/inter-organizations + admin namespace mount với requireRoles('Quản trị hệ thống')
  - phase: 37-admin-ui-catalog-go-live
    plan: 06
    provides: Menu LGSP unhide + retry buttons admin only (Timeline + VB đi badge)
  - phase: 33-database-core-infrastructure
    plan: 05
    provides: VERIFICATION-REPORT.md template (Phase 33 final)
  - phase: 34-send-flow-sendedoc
    plan: 05
    provides: 34-05-VERIFICATION-REPORT.md template + credential rotation caveat baseline
  - phase: 35-receive-flow-cron-syncreceivededoclist
    plan: 05
    provides: 35-05-VERIFICATION-REPORT.md template + worker race caveat
  - phase: 36-status-callback-chain-9-ma-qd-28
    plan: 05
    provides: 36-05-VERIFICATION-REPORT.md template + 9 mã QĐ 28 callback chain verified
provides:
  - "Section 'Kich hoat LGSP v3.2 (post-deploy)' tail file deploy/MANUAL_UPDATE_PROD.md với 7 step (A-E + Wave plan table) — Vietnamese KHÔNG dấu cho PS 5.1 safety"
  - "Phase 37 final VERIFICATION-REPORT.md với matrix TS/build/schema/smoke + 8/8 LGSP-UI REQ pass"
  - "Milestone v3.2 SHIP-READINESS.md aggregate 5 phase 33-37 verification + 36 REQ-IDs status (35 Done + 1 Partial)"
  - "Tag candidate v3.2.0 ready post-merge to main"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Documentation pattern: VERIFICATION-REPORT.md style (mirror Phase 34-05/35-05/36-05) — header Status PASS/PARTIAL/FAIL + Executive Summary + Test Matrix sections + Decision Coverage + REQ Coverage + Caveats + Self-Check PASSED"
    - "Milestone SHIP-READINESS aggregate: Phases Summary table + per-category REQ status table + Tech Stack additions + Known Caveats + Roll-out Plan + Performance Metrics + Final Commit Suggestion + Ship Checklist"
    - "Production rollout doc append pattern: tail MANUAL_UPDATE_PROD.md với separator '---' + section '## Kich hoat ...' + Vietnamese KHÔNG dấu (PS 5.1 UTF-8 safe per CLAUDE.md pitfall #1)"
    - "Auto-approve checkpoint mode mirror Phase 34-05/35-05/36-05 chain (user delegated 'Chạy liên hoàn' v3.2)"

key-files:
  created:
    - deploy/MANUAL_UPDATE_PROD.md (APPEND section, không phải file mới)
    - .planning/phases/37-admin-ui-catalog-go-live/37-07-VERIFICATION-REPORT.md
    - .planning/v3.2-SHIP-READINESS.md
    - .planning/phases/37-admin-ui-catalog-go-live/37-07-SUMMARY.md
  modified:
    - deploy/MANUAL_UPDATE_PROD.md (APPEND tail — 95 dòng mới)

key-decisions:
  - "Vietnamese KHÔNG dấu section MANUAL_UPDATE_PROD per CLAUDE.md pitfall #1 (PS 5.1 default UTF-8 no BOM mis-decode → tiếng Việt corrupt). Section trước (Bước 0-4) giữ nguyên có dấu vì đã có sẵn. Chỉ section mới append KHÔNG dấu."
  - "VERIFICATION-REPORT.md mirror style Phase 34-05/35-05/36-05 — auto-approve mode + Test Matrix 6 sub-section (TS/Build/Schema/Smoke/Frontend/Acceptance) + Decision Coverage D-01..D-16 + REQ Coverage LGSP-UI-01..08"
  - "SHIP-READINESS.md aggregate 5 phase 33-37 (KHÔNG phải plan-level) — tiếng Việt CÓ dấu (markdown render normal, không phải PS script)"
  - "Smoke test backend endpoint 8/8 thay vì 7 (plan ghi 7 + non-admin gate) — thêm endpoint #6 (inter-organizations/sync) để verify guard message + #8 (no-token 401) để cover full auth gate matrix 3/3"
  - "Auth gate verification dùng admin/Admin@123 + nguyenvana/Admin@123 — mirror Phase 35-03 pattern (Vietnamese role string 'Quản trị hệ thống' KHÔNG phải literal 'admin')"
  - "LGSP-STATUS-08 marked Partial trong SHIP-READINESS vì sender retract UI defer v3.3+ (schema CHECK constraint Phase 33 ready cho future). KHÔNG block v3.2 ship — không có use case immediate"
  - "Tag candidate v3.2.0 chứ KHÔNG v3.2.X (X = patch level) vì milestone v3.2 = clean release, không có pre-shipped patch"
  - "Backend prod build start qua `node dist/server.js` để verify production artifact thực sự work (không phải dev mode tsx watch) — tăng confidence cho deploy"

patterns-established:
  - "Final plan phase pattern (mirror 34-05/35-05/36-05): 3 task = doc append + verification report + milestone aggregate (nếu là final phase của milestone)"
  - "MANUAL_UPDATE_PROD.md append pattern: tách section mới với '---' separator + Vietnamese KHÔNG dấu + reference admin UI rõ ràng cho self-service"

metrics:
  duration: ~25 minutes
  tasks_completed: 3
  files_modified: 1 (MANUAL_UPDATE_PROD.md)
  files_created: 3 (VERIFICATION-REPORT.md + SHIP-READINESS.md + this SUMMARY.md)
  commits: 3 (Task 1 644ae21 + Task 2 03dc55b + Task 3 3df97d7)
  completed: 2026-05-21
---

# Phase 37 Plan 07: Final Verification + Milestone v3.2 Wrap-up Summary

Final plan Phase 37 + milestone v3.2 closure. Append production rollout doc + write Phase 37 final verification report + aggregate 5 phase 33-37 thành ship-readiness report. Zero source code change.

## Objective

Đóng milestone v3.2 với reproducible doc cho admin KH tự rollout LGSP + ship-readiness report đảm bảo nothing missed. Ouput:
1. APPEND section "Kich hoat LGSP v3.2 (post-deploy)" tail file `deploy/MANUAL_UPDATE_PROD.md` (Vietnamese KHÔNG dấu PS 5.1 safe)
2. NEW `.planning/phases/37-admin-ui-catalog-go-live/37-07-VERIFICATION-REPORT.md` — Phase 37 final verification PASS với caveat
3. NEW `.planning/v3.2-SHIP-READINESS.md` — milestone v3.2 aggregate 5 phase 33-37 + 36 REQ-IDs status + caveats + roll-out plan reference

## Tasks Completed

### Task 1: APPEND section "Kich hoat LGSP v3.2" vào MANUAL_UPDATE_PROD.md

- File: `deploy/MANUAL_UPDATE_PROD.md` (APPEND tail — 95 dòng mới)
- Format: 5 step (A-E) + Wave plan table + SIGNING_SECRET_KEY guard
- Bước A: Admin login + truy cập menu LGSP
- Bước B: Wave 1 sandbox 3 DN.001/002/003 (test connection → toggle is_active)
- Bước C: Wave 2 production rollout TỪNG DN MỘT (24h verify mỗi DN)
- Bước D: Setup catalog cơ quan ngoài (Sync từ trục)
- Bước E: Monitoring + Recovery (dashboard + retry button + force sync)
- Bonus: Check encrypt key warning (SIGNING_SECRET_KEY persistence)
- Vietnamese KHÔNG dấu toàn section (PS 5.1 UTF-8 safety per CLAUDE.md pitfall #1)
- Commit: `644ae21`

### Task 2: Final verification suite Phase 37 + write VERIFICATION-REPORT.md

- File: `.planning/phases/37-admin-ui-catalog-go-live/37-07-VERIFICATION-REPORT.md`
- Status: **PASS với caveat** (mirror Phase 34-05/35-05/36-05 pattern)
- Test Matrix:
  - **TS strict 3 modules:** backend 0 / workers 0 / frontend 4 pre-existing TS2345 (UNCHANGED baseline)
  - **Production build 3 modules:** backend + workers + frontend ALL exit 0
  - **Schema 3x idempotent:** zero ERROR/FATAL; SP count = 361 baseline preserved; 0 SP overloads
  - **Admin endpoints smoke 8/8:** 3 read 200 + 2 retry 400-shape Vietnamese + 1 sync 400-shape + 1 non-admin 403 + 1 no-token 401
  - **Frontend LGSP routes built 3/3:** `/lgsp` + `/lgsp/cau-hinh` + `/lgsp/co-quan` static prerendered
  - **Acceptance grep 10/10:** menu unhide + sidebar entry + breadcrumb + retry button hooks
  - **D-01..D-16 coverage:** 16/16
  - **LGSP-UI-01..08 REQ:** 8/8 PASS
- Caveats documented: credential rotation (Phase 34-05/35-05/36-05 same) + inter-organizations parent_id tree select defer + bulk retry defer + mã 13/15/16 defer
- Self-Check: PASSED
- Commit: `03dc55b`

### Task 3: v3.2 SHIP-READINESS milestone report

- File: `.planning/v3.2-SHIP-READINESS.md`
- Status: **READY TO SHIP** (tag candidate v3.2.0)
- Aggregate 5 phase 33-37:
  - Phase 33 Database + Core Infrastructure (6 REQ done)
  - Phase 34 Send Flow sendEdoc (6 REQ done)
  - Phase 35 Receive Flow cron syncReceivedEdocList (7 REQ done)
  - Phase 36 Status Callback Chain 9 mã QĐ 28 (9 REQ done + 1 partial LGSP-STATUS-08)
  - Phase 37 Admin UI + Catalog + Go-live (8 REQ done)
- 36 REQ-IDs status: **35/36 Done + 1/36 Partial** (LGSP-STATUS-08 sender retract defer v3.3+)
- 10 Known Caveats documented (credential rotation, race condition, defer items)
- Roll-out Plan reference `deploy/MANUAL_UPDATE_PROD.md § "Kich hoat LGSP v3.2 (post-deploy)"`
- Ship Checklist 11/11 PASS
- 12 v3.3+ candidates listed (sender retract, queue split, DLQ, audit, HDSD refresh, etc.)
- Commit: `3df97d7`

## Verification Result

| Check | Status | Evidence |
|---|---|---|
| `grep "Kich hoat LGSP v3.2" deploy/MANUAL_UPDATE_PROD.md` | PASS | 1 hit |
| `grep "Wave 1|Wave 2|Sandbox|Production|SIGNING_SECRET_KEY|/lgsp/cau-hinh|Cau hinh ket noi" deploy/MANUAL_UPDATE_PROD.md` | PASS | 13 hits |
| VERIFICATION-REPORT.md exists + has "PASS" | PASS | 46 PASS occurrences |
| SHIP-READINESS.md exists + 5 phase rows | PASS | 5 phases in summary table |
| SHIP-READINESS.md categories | PASS | 5 LGSP categories (CRED/SEND/RECV/STATUS/UI) |
| SHIP-READINESS.md "READY TO SHIP" | PASS | 3 occurrences |
| SHIP-READINESS.md "Kich hoat LGSP v3.2" reference | PASS | 3 occurrences |
| SHIP-READINESS.md caveats count | PASS | 10 numbered caveats |
| TS backend/workers/frontend | PASS | 0/0/4-pre-existing-unchanged |
| Production build backend/workers/frontend | PASS | 0/0/0 exit |
| Schema 3x idempotent | PASS | 0 ERROR/FATAL |
| Backend smoke 8 admin endpoints | PASS | 8/8 expected shape |
| Auth gates 3/3 | PASS | admin 200, non-admin 403, no-token 401 |

## Deviations from Plan

**None** — Plan executed exactly as written.

Minor adjustment: Smoke test #6 included `/inter-organizations/sync` (KHÔNG có trong plan task list nhưng có trong plan endpoint matrix) + added explicit #8 no-token 401 test to cover full auth gate matrix. KHÔNG ảnh hưởng plan acceptance criteria.

## Known Stubs

None.

## Architecture Decisions Captured

- Auto-approve checkpoint mode mirror Phase 34-05/35-05/36-05 chain (user delegated "Chạy liên hoàn" v3.2)
- Vietnamese KHÔNG dấu cho section mới trong PowerShell-touched file (MANUAL_UPDATE_PROD.md)
- VERIFICATION-REPORT.md style match phase predecessors (mirror Phase 34-05/35-05/36-05 template)
- SHIP-READINESS.md = milestone-level (NOT plan-level), aggregate 5 phase verification

## Next Steps

- Auto-advance to next phase OR user reviews + tag v3.2.0 release
- Roll-out per `deploy/MANUAL_UPDATE_PROD.md § "Kich hoat LGSP v3.2 (post-deploy)"`:
  - Wave 1 sandbox 3 DN (Day 1-2)
  - Wave 2 prod 6 DN từ từ (Day 3-10)
- Monitoring + recovery via admin UI `/lgsp` dashboard + retry buttons

## Self-Check: PASSED

**Files exist:**
- FOUND: `deploy/MANUAL_UPDATE_PROD.md` (modified — section appended)
- FOUND: `.planning/phases/37-admin-ui-catalog-go-live/37-07-VERIFICATION-REPORT.md`
- FOUND: `.planning/phases/37-admin-ui-catalog-go-live/37-07-SUMMARY.md` (this file)
- FOUND: `.planning/v3.2-SHIP-READINESS.md`

**Commits exist (3/3):**
- FOUND: `644ae21` — docs(37-07): append Kich hoat LGSP v3.2 rollout section
- FOUND: `03dc55b` — test(37-07): final verification report Phase 37 PASS
- FOUND: `3df97d7` — docs(37-07): v3.2 SHIP-READINESS milestone report

**Acceptance criteria all met:**
- Task 1: `grep "Kich hoat LGSP v3.2"` = 1 hit; 13 hits for Wave 1/2/Sandbox/Production/SIGNING_SECRET_KEY/lgsp/cau-hinh
- Task 2: VERIFICATION-REPORT.md exists with 46 PASS occurrences; 8/8 REQ verified
- Task 3: SHIP-READINESS.md exists with 5 phase rows + 5 LGSP categories + "READY TO SHIP" + 10 caveats

---

*Plan: 07*
*Phase: 37-admin-ui-catalog-go-live*
*Completed: 2026-05-21*
*Auto-approved per delegation mode (user "Chạy liên hoàn" v3.2)*
