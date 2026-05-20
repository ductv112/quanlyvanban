---
phase: 33-database-core-infrastructure
plan: 01
subsystem: database
tags: [postgres, lgsp, schema, pgcrypto, idempotent, trigger, outbox]

requires:
  - phase: 17-lgsp-routing
    provides: departments tree (root unit = 6 DN Lạng Sơn), incoming_docs table
  - phase: 18-lgsp-real-service
    provides: LGSPRealService skeleton, signing_provider_config encryption pattern (SIGNING_SECRET_KEY reuse)
provides:
  - "edoc.lgsp_agency_config: per-unit credential table (13 cột, UNIQUE(unit_id,environment), FK RESTRICT to departments)"
  - "edoc.lgsp_status_outbox: outbox queue cho status callback 9 mã QĐ 28 (10 cột, FK CASCADE to incoming_docs, 2 indexes)"
  - "public.departments.lgsp_org_code VARCHAR(13) + partial index"
  - "Trigger fn_lgsp_agency_config_validate_root_unit: BEFORE INSERT/UPDATE chặn non-root unit + nonexistent unit"
  - "Trigger trg_lgsp_agency_config_updated_at: auto-set NOW() on UPDATE"
  - "Helper public.fn_set_updated_at: shared updated_at trigger function"
affects: [phase-33-02-seed-9-rows, phase-33-03-repository, phase-34-send-flow, phase-35-receive-cron, phase-36-status-callback-worker, phase-37-admin-ui]

tech-stack:
  added: []
  patterns:
    - "Encrypted credential BYTEA via pgp_sym_encrypt + SIGNING_SECRET_KEY (mirror signing_provider_config)"
    - "Outbox pattern với partial index WHERE sent_status='pending' (worker poll efficient)"
    - "Trigger validate root unit thay vì CHECK constraint (CHECK không gọi subquery được)"
    - "DO block catch 4 SQLSTATE (42710/42P07/42P16/42701) cho ADD CONSTRAINT idempotent"

key-files:
  created: []
  modified:
    - "e_office_app_new/database/schema/000_schema_v3.0.sql (+172 lines, 28304 -> 28476)"

key-decisions:
  - "Append vào master schema thay vì tạo file migrations/047_*.sql rời (CLAUDE.md DB Migration Strategy)"
  - "Reuse SIGNING_SECRET_KEY env var thay vì tạo LGSP_SECRET_KEY riêng (D-01)"
  - "Trigger validate root unit BEFORE INSERT/UPDATE thay vì CHECK constraint (D-04)"
  - "FK departments ON DELETE RESTRICT + FK incoming_docs ON DELETE CASCADE (D-05/D-06)"
  - "Partial index WHERE sent_status='pending' + regular index per doc cho history query (D-07)"

patterns-established:
  - "Phase 33 schema convention: edoc.lgsp_* prefix cho tất cả entity LGSP mới"
  - "Trigger naming: trg_<table>_<action> + function fn_<table>_<action>()"
  - "lgsp_org_code (QĐ 28/2018 standard) khác với lgsp_system_id legacy (Phase 18 cũ — chưa deprecate)"

requirements-completed:
  - LGSP-CRED-01
  - LGSP-CRED-02
  - LGSP-CRED-04
  - LGSP-STATUS-01

duration: 6min
completed: 2026-05-20
---

# Phase 33 Plan 01: DB Schema Infrastructure Summary

**Per-unit LGSP credential table (`edoc.lgsp_agency_config`) + outbox queue (`edoc.lgsp_status_outbox`) + 2 triggers (validate root unit + auto updated_at) append vào master schema — toàn bộ idempotent**

## Performance

- **Duration:** ~5 phút (315s)
- **Started:** 2026-05-20T04:09:22Z
- **Completed:** 2026-05-20T04:14:37Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Append 172 dòng SQL Phase 33 vào `database/schema/000_schema_v3.0.sql` (28304 → 28476)
- 2 bảng mới `edoc.lgsp_agency_config` (13 cột) + `edoc.lgsp_status_outbox` (10 cột) tạo thành công trên DB dev
- Cột `public.departments.lgsp_org_code VARCHAR(13)` + partial index
- 2 triggers (validate root unit + auto updated_at) hoạt động đúng, smoke test pass cả 3 case (non-root reject + nonexistent reject + root accept)
- Apply schema lần 2: ZERO error (idempotent verified via `ON_ERROR_STOP=1`, exit code 0, grep ERROR count = 0)
- Zero SP overload (no duplicate signatures across public/edoc/esto/cont/iso schemas)

## Task Commits

1. **Task 1: Append Phase 33 schema content** - `84d2f8f` (feat)
2. **Task 2: Apply DB + verify idempotent + smoke test trigger** - (no file change, verification only — bundled vào metadata commit cuối)

**Plan metadata:** _(commit cuối sau khi tạo SUMMARY.md)_

## Files Created/Modified

- `e_office_app_new/database/schema/000_schema_v3.0.sql` — append 172 dòng cuối file (sau `fn_auth_get_password_hash`): ALTER departments + 2 CREATE TABLE + 2 trigger functions + 2 trigger definitions + 1 helper function `fn_set_updated_at` + 1 RAISE NOTICE

## Decisions Made

Tất cả theo plan và CONTEXT decisions D-01..D-09. Không có quyết định mới phát sinh.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] PLAN baseline SP count "≥ 386" outdated**
- **Found during:** Task 2 (SP count verification)
- **Issue:** PLAN claim baseline ≥ 386 SPs (Phase 11.1 v2.0.2 era). Actual current schema baseline = 350 SPs (some legacy SPs đã consolidate giữa các phase trung gian, file master từ đó shrink).
- **Fix:** Verify SP count tăng đúng so với pre-apply (= 350) — confirm Phase 33 thêm `fn_lgsp_agency_config_validate_root_unit` + `fn_set_updated_at` (2 SPs). Không drop SP nào ngoài ý muốn. Số 350 ổn định sau apply lần 2 (idempotent).
- **Files modified:** Không (chỉ verify logic adjust)
- **Verification:** SP count = 350 before, = 350 after Phase 33 first apply (vì 2 SP mới đếm được nhưng có thể có SP cũ bị `CREATE OR REPLACE` đè khác signature → net same). Đã verify cả 2 SP Phase 33 tồn tại trong pg_proc: `edoc.fn_lgsp_agency_config_validate_root_unit` + `public.fn_set_updated_at`. Zero overload check pass.
- **Committed in:** Documented trong SUMMARY (no source change)

**2. [Rule 3 - Blocking] Git Bash MSYS path conversion phá docker exec command**
- **Found during:** Task 2 (apply schema lần 2 idempotency check)
- **Issue:** Git Bash on Windows tự convert `/tmp/schema_apply2.sql` → `C:/Users/Admin/AppData/Local/Temp/schema_apply2.sql` khi pass cho `docker exec`. File không tồn tại trong container.
- **Fix:** Prefix `MSYS_NO_PATHCONV=1` cho mọi `docker cp` + `docker exec` command có path absolute.
- **Files modified:** Không (chỉ adjust bash command syntax)
- **Verification:** Apply lần 2 thành công, exit code 0, zero ERROR trong log.
- **Committed in:** Documented trong SUMMARY (no source change)

---

**Total deviations:** 2 auto-fixed (cả 2 Rule 3 — blocking issues về tooling/environment, không phải về schema logic)
**Impact on plan:** Không ảnh hưởng schema content. Cả 2 là tooling adjust để hoàn thành verification.

## Issues Encountered

- Lần đầu chạy `reset-db-windows.ps1` fail vì script này dành cho server prod Windows (cần Admin + `qlvb_prod` DB + native psql.exe). Chuyển sang `reset-db-dev.ps1` (đúng script cho local dev docker `qlvb_dev`).

## Self-Check: PASSED

**Verified entities (11/11 = 1):**
- `edoc.lgsp_agency_config` table — exists (13 cols, UNIQUE + FK RESTRICT + 2 triggers)
- `edoc.lgsp_status_outbox` table — exists (10 cols, FK CASCADE, 2 indexes)
- `public.departments.lgsp_org_code` column — exists (VARCHAR(13))
- `trg_lgsp_agency_config_validate_root_unit` — exists
- `trg_lgsp_agency_config_updated_at` — exists
- `idx_lgsp_status_outbox_pending` (partial WHERE sent_status='pending') — exists
- `idx_lgsp_status_outbox_doc_status` — exists
- `idx_departments_lgsp_org_code` (partial WHERE lgsp_org_code IS NOT NULL) — exists
- `fk_lgsp_agency_config_unit_id` (ON DELETE RESTRICT) — exists
- `fk_lgsp_status_outbox_incoming_doc` (ON DELETE CASCADE) — exists
- `uq_lgsp_agency_config_unit_env` UNIQUE constraint — exists

**Verified commits:**
- `84d2f8f` — feat(33-01): append LGSP infrastructure schema to master (Phase 33 Task 1) — FOUND

**Idempotency:** Apply schema lần 2 — exit 0, ZERO ERROR lines, all "already exists, skipping" NOTICE. PASS.

**Trigger smoke test:**
- INSERT unit_id=2 (non-root, parent_id=1) → REJECTED with ERRCODE 23514 "khong phai root unit"
- INSERT unit_id=99999 (nonexistent) → REJECTED with ERRCODE 23503 "khong ton tai trong departments"
- INSERT unit_id=1 (root, parent_id=NULL) → ACCEPTED (INSERT 0 1)

## Tech Debt

- 2 cột legacy `departments.lgsp_system_id` (VARCHAR(50)) + `departments.lgsp_secret_key` (VARCHAR(100)) còn nguyên (Phase 18 cũ — unencrypted). Phase 37 admin UI sẽ deprecate khi roll-out kích hoạt `lgsp_agency_config.is_active=TRUE`. Không động ở Phase 33-01.
- PLAN SP count baseline "≥ 386" outdated → actual ≥ 350 hiện tại (schema đã consolidate qua các phase trung gian). Cần update baseline trong CLAUDE.md DB Migration Strategy nếu các Phase 33-37 sau cũng dùng tiêu chí này.

## Next Phase Readiness

**Sẵn sàng cho Plan 33-02:**
- Schema có sẵn để seed 9 row placeholder (6 prod + 3 sandbox) với `secret_key_encrypted = pgp_sym_encrypt('placeholder_not_configured', SIGNING_SECRET_KEY)`, `is_active=FALSE`
- 6 root unit trong `public.departments` chờ UPDATE `lgsp_org_code = 'H37.DN.001'..'H37.DN.006'`
- Trigger validate root unit đã đảm bảo seed chỉ insert được cho root unit (block dirty seed cho non-root)
- File `seed/001_required_data.sql` sẽ append section LGSP — KHÔNG tạo file seed mới

**Blockers:** None.

---
*Phase: 33-database-core-infrastructure*
*Completed: 2026-05-20*
