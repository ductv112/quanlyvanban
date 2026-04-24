---
phase: 06-t-ch-h-p-h-th-ng-ngo-i
plan: 05
subsystem: database
tags: [postgresql, seed-data, demo, sql, truncate]

requires:
  - phase: 06-01
    provides: migration tables 019-021 (LGSP, digital signatures, notifications)
provides:
  - comprehensive seed_full_demo.sql covering all modules Sprint 0-16
  - linked demo data for testing and demo presentation
affects: [all-modules, demo, testing]

tech-stack:
  added: []
  patterns: [truncate-then-seed, explicit-id-inserts, sequence-reset-pattern]

key-files:
  created:
    - e_office_app_new/database/seed_full_demo.sql
  modified: []

key-decisions:
  - "Used explicit IDs in all INSERT statements for predictable FK references"
  - "Corrected column names vs existing seed_demo.sql (doc_books.type_id not book_type, doc_fields requires unit_id+code)"
  - "10 staff across 10 departments with realistic Vietnamese names and diacritics"
  - "Data linked: incoming_docs -> handling_docs -> outgoing_docs, HSCV -> VB links, meetings -> rooms"

patterns-established:
  - "Seed pattern: BEGIN -> TRUNCATE CASCADE in reverse FK order -> INSERT with explicit IDs -> setval sequences -> COMMIT"
  - "Demo password: Admin@123 with shared bcrypt hash for all demo accounts"

requirements-completed: [LGSP-01, LGSP-02, LGSP-03, LGSP-04, SIGN-01, SIGN-02, SIGN-03, NOTIF-01, NOTIF-02, NOTIF-03, NOTIF-04]

duration: 6min
completed: 2026-04-15
---

# Phase 6 Plan 5: Comprehensive Seed Data Summary

**659-line seed_full_demo.sql: TRUNCATE+seed all 5 schemas (public/edoc/esto/cont/iso) with linked demo data across 30+ tables for Sprint 0-16 modules**

## Performance

- **Duration:** 6 min
- **Started:** 2026-04-14T17:48:54Z
- **Completed:** 2026-04-14T17:54:54Z
- **Tasks:** 1
- **Files created:** 1

## Accomplishments
- Created comprehensive seed script covering ALL modules from Sprint 0 through Sprint 16
- 74 TRUNCATE statements ensure clean slate before seeding
- Linked data across modules: VB den -> HSCV -> VB di, Ho so luu tru -> VB, Cuoc hop -> Phong hop, LGSP tracking -> VB
- 50 sequence resets ensure auto-increment IDs work correctly after explicit inserts
- Verify counts at end of script for quick validation

## Task Commits

1. **Task 1: Create comprehensive seed_full_demo.sql** - `5ac3c00` (feat)

## Files Created/Modified
- `e_office_app_new/database/seed_full_demo.sql` - 659-line comprehensive seed covering: 10 departments, 10 staff, 6 positions, 6 roles, 18 rights, 8 doc types, 5 doc fields, 5 doc books, 7 incoming docs, 4 outgoing docs, 4 drafting docs, 6 HSCV, 3 inter-incoming docs, 8 messages, 6 notices, 8 calendar events, 4 warehouses, 3 fonds, 5 archive records, 2 borrow requests, 5 doc categories, 6 ISO documents, 4 contract types, 4 contracts, 3 rooms, 3 meeting types, 4 room schedules, 7 LGSP organizations, 5 LGSP tracking records, 4 digital signatures, 4 device tokens, 10 notification logs, 24 notification preferences

## Decisions Made
- **Corrected existing seed_demo.sql errors:** The old seed used `book_type` (nonexistent column) for `doc_books.type_id` and omitted required `unit_id`/`code` for `doc_fields`. New seed uses correct column names from migration DDL.
- **Explicit IDs for all tables** to ensure FK references are predictable and linked data is correct.
- **Realistic Vietnamese data** with proper diacritics for all names, addresses, content.
- **Phase 6 tables fully seeded:** LGSP organizations (7 real government entities), LGSP tracking (5 records: 3 send + 2 receive), digital signatures (4 records: 2 signed + 1 pending + 1 drafting), device tokens (4), notification logs (10 across fcm/email/sms/zalo), notification preferences (24 across 6 staff x 4 channels).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected doc_books column names**
- **Found during:** Task 1 (seed creation)
- **Issue:** Plan template used `book_type` and `year` columns which don't exist in `edoc.doc_books` table. Actual column is `type_id` per migration 002.
- **Fix:** Used correct column `type_id` instead of `book_type`, removed nonexistent `year` column.
- **Files modified:** e_office_app_new/database/seed_full_demo.sql
- **Committed in:** 5ac3c00

**2. [Rule 1 - Bug] Added required unit_id and code to doc_fields**
- **Found during:** Task 1 (seed creation)
- **Issue:** Plan template omitted `unit_id` (NOT NULL) and `code` (NOT NULL) columns for `edoc.doc_fields`. Old seed_demo.sql also missed these.
- **Fix:** Added `unit_id` and `code` values to all doc_fields inserts.
- **Files modified:** e_office_app_new/database/seed_full_demo.sql
- **Committed in:** 5ac3c00

---

**Total deviations:** 2 auto-fixed (2 bugs in plan template column names)
**Impact on plan:** Both fixes necessary for SQL correctness. No scope creep.

## Issues Encountered
None

## User Setup Required
None - seed script is ready to run via `docker exec eoffice-postgres psql -U postgres -d qlvb -f /docker-entrypoint-initdb.d/seed_full_demo.sql`

## Next Phase Readiness
- Comprehensive demo data available for all modules
- Login with admin/Admin@123 works with all linked data visible
- All Phase 6 tables (LGSP, digital signatures, notifications) have representative demo data

---
*Phase: 06-t-ch-h-p-h-th-ng-ngo-i*
*Completed: 2026-04-15*
