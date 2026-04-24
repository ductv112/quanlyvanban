---
phase: 06-t-ch-h-p-h-th-ng-ngo-i
plan: 01
subsystem: database
tags: [postgresql, lgsp, digital-signing, notifications, stored-functions, migrations]

requires:
  - phase: 05
    provides: "Existing edoc schema tables (outgoing_docs, incoming_docs) for FK references"
provides:
  - "edoc.lgsp_organizations and edoc.lgsp_tracking tables for LGSP integration"
  - "edoc.digital_signatures table for digital signing"
  - "edoc.device_tokens, edoc.notification_logs, edoc.notification_preferences tables for notifications"
  - "18 stored functions for LGSP, signing, and notification CRUD operations"
affects: [06-02, 06-03, 06-04, 06-05]

tech-stack:
  added: []
  patterns: [UPSERT on unique constraints, CHECK constraints for enums, parameterized stored functions]

key-files:
  created:
    - e_office_app_new/database/migrations/019_sprint14_lgsp.sql
    - e_office_app_new/database/migrations/020_sprint15_digital_signing.sql
    - e_office_app_new/database/migrations/021_sprint16_notifications.sql
  modified: []

key-decisions:
  - "Used INT for staff_id FK (matches public.staff.id INTEGER type), BIGINT for doc FKs"
  - "Used full_name from staff table instead of concatenating last_name + first_name"
  - "UPSERT pattern for lgsp_org_sync, device_token_upsert, notification_pref_upsert"

patterns-established:
  - "LGSP tracking uses direction column (send/receive) with nullable outgoing_doc_id and incoming_doc_id"
  - "Digital signatures use doc_type discriminator (outgoing/drafting) instead of separate tables"
  - "Notification preferences use UNIQUE(staff_id, channel) for upsert pattern"

requirements-completed: [LGSP-01, LGSP-02, LGSP-03, LGSP-04, SIGN-01, SIGN-02, SIGN-03, NOTIF-01, NOTIF-02, NOTIF-03, NOTIF-04]

duration: 3min
completed: 2026-04-15
---

# Phase 6 Plan 01: Database Migrations for LGSP, Digital Signing, and Notifications

**3 migration files creating 6 tables and 18 stored functions for Sprint 14/15/16 external integrations — LGSP tracking, digital signatures, and multi-channel notifications**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-15T00:00:30Z
- **Completed:** 2026-04-15T00:03:35Z
- **Tasks:** 3/3
- **Files created:** 3

## Accomplishments

### Task 1: Migration 019 — Sprint 14 LGSP (d1c3a55)
- Created `edoc.lgsp_organizations` table with UPSERT on org_code
- Created `edoc.lgsp_tracking` table with FK to outgoing_docs, incoming_docs, staff
- 6 stored functions: org_sync, org_get_list, tracking_create, tracking_update_status, tracking_get_list, tracking_get_by_doc
- Indexes on status, direction, outgoing_doc_id

### Task 2: Migration 020 — Sprint 15 Digital Signing (26ff0ea)
- Created `edoc.digital_signatures` table with CHECK constraints for doc_type, sign_method, sign_status
- 4 stored functions: signature_create, signature_update_status, signature_get_by_doc (with staff JOIN), signature_get_by_id
- Indexes on (doc_id, doc_type), staff_id, sign_status

### Task 3: Migration 021 — Sprint 16 Notifications (c7578b0)
- Created `edoc.device_tokens` with UNIQUE device_token
- Created `edoc.notification_logs` with indexes on staff_id, channel, send_status, created_at
- Created `edoc.notification_preferences` with UNIQUE(staff_id, channel)
- 8 stored functions: device_token CRUD, notification_log CRUD, notification_pref CRUD

## Verification

All 3 migrations executed successfully in PostgreSQL (qlvb_dev database):
- 6 tables confirmed: lgsp_organizations, lgsp_tracking, digital_signatures, device_tokens, notification_logs, notification_preferences
- 18 stored functions confirmed via information_schema.routines query

## Deviations from Plan

None - plan executed exactly as written.

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | d1c3a55 | Migration 019 — LGSP tables + 6 SPs |
| 2 | 26ff0ea | Migration 020 — Digital signing table + 4 SPs |
| 3 | c7578b0 | Migration 021 — Notification tables + 8 SPs |

## Self-Check: PASSED

All 4 files found. All 3 commits verified.
