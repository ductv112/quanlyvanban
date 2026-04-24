---
phase: 04-l-ch-danh-b-dashboard
plan: "01"
subsystem: database
tags: [migration, calendar, directory, dashboard, stored-procedures, postgresql]
dependency_graph:
  requires:
    - 001_system_tables.sql (public.staff, public.departments, public.positions)
    - 002_edoc_tables.sql (edoc.incoming_docs, edoc.outgoing_docs, edoc.handling_docs, edoc.user_incoming_docs, edoc.staff_handling_docs, edoc.doc_types)
  provides:
    - public.calendar_events table
    - public.fn_calendar_event_get_list
    - public.fn_calendar_event_get_by_id
    - public.fn_calendar_event_create
    - public.fn_calendar_event_update
    - public.fn_calendar_event_delete
    - public.fn_directory_get_list
    - edoc.fn_dashboard_get_stats
    - edoc.fn_dashboard_recent_incoming
    - edoc.fn_dashboard_upcoming_tasks
    - edoc.fn_dashboard_recent_outgoing
  affects:
    - 04-02 (backend calendar + directory routes will call these functions)
    - 04-03 (backend dashboard routes will call these functions)
tech_stack:
  added: []
  patterns:
    - Stored function SECURITY DEFINER pattern (consistent with 013)
    - Soft delete via is_deleted = TRUE (consistent with messages pattern)
    - Ownership check before update/delete for personal scope events
    - Multi-tenancy via p_unit_id filter on all dashboard functions
    - Pagination via OFFSET/LIMIT with COUNT(*) OVER() for total_count
key_files:
  created:
    - e_office_app_new/database/migrations/014_sprint9_calendar_directory.sql
    - e_office_app_new/database/migrations/015_sprint10_dashboard_stats.sql
  modified: []
decisions:
  - "incoming_unread counts via user_incoming_docs join (not direct is_read column on incoming_docs which doesn't exist) — consistent with Sprint 3 design"
  - "outgoing_pending uses approved=FALSE (existing column) as proxy for pending state"
  - "handling_overdue uses end_date column (not deadline — that column doesn't exist in schema)"
  - "fn_dashboard_upcoming_tasks includes curator + staff_handling_docs lookup for comprehensive assignment check"
  - "urgency_name computed via CASE on urgent_id (1=Thường, 2=Khẩn, 3=Hỏa tốc) — no separate urgency table"
metrics:
  duration: "~8 minutes"
  completed: "2026-04-14"
  tasks_completed: 2
  tasks_total: 2
  files_created: 2
  files_modified: 0
---

# Phase 04 Plan 01: Sprint 9-10 Database Migrations Summary

Calendar events table + directory SP for Sprint 9, dashboard KPI stats for Sprint 10 — using real edoc schema column names discovered from 002_edoc_tables.sql.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Sprint 9 migration — Calendar events table + Directory SP | d8da85e | e_office_app_new/database/migrations/014_sprint9_calendar_directory.sql |
| 2 | Sprint 10 migration — Dashboard statistics stored functions | f5929a5 | e_office_app_new/database/migrations/015_sprint10_dashboard_stats.sql |

## What Was Built

### 014_sprint9_calendar_directory.sql

**Table `public.calendar_events`:**
- Columns: id, title, description, start_time, end_time, all_day, color (`#1B3A5C` default), repeat_type (none/daily/weekly/monthly), scope (personal/unit/leader), unit_id, created_by, created_at, updated_at, is_deleted
- Indexes: `(scope, unit_id, start_time)` for scope-based queries, `(created_by, start_time)` for personal calendar

**6 stored functions:**
- `fn_calendar_event_get_list` — filter by scope + date range, JOIN staff for creator_name. For personal: `created_by = p_staff_id`, for unit/leader: `unit_id = p_unit_id`
- `fn_calendar_event_get_by_id` — single event with creator info and audit timestamps
- `fn_calendar_event_create` — validate title/times (end >= start), INSERT with defaults
- `fn_calendar_event_update` — ownership check (`created_by = p_staff_id`) for personal scope before UPDATE
- `fn_calendar_event_delete` — soft delete (is_deleted=TRUE), ownership check for personal scope
- `fn_directory_get_list` — paginated staff with position/department/unit JOINs, ILIKE search on full_name/phone/mobile/email, excludes locked/deleted staff. Returns total_count via window function.

### 015_sprint10_dashboard_stats.sql

**4 stored functions:**
- `fn_dashboard_get_stats(p_staff_id, p_unit_id)` — 4 KPI integers:
  - `incoming_unread`: COUNT via `user_incoming_docs` (is_read=FALSE) for this staff
  - `outgoing_pending`: COUNT outgoing_docs WHERE approved=FALSE
  - `handling_total`: COUNT all handling_docs for unit
  - `handling_overdue`: COUNT handling_docs WHERE end_date < NOW() AND status NOT IN (4=Hoàn thành)
- `fn_dashboard_recent_incoming(p_unit_id, p_limit)` — latest VB đến with urgency label derived from urgent_id (1=Thường, 2=Khẩn, 3=Hỏa tốc), sender from publish_unit
- `fn_dashboard_upcoming_tasks(p_staff_id, p_limit)` — HSCV nearing deadline for staff (curator OR in staff_handling_docs), status NOT IN (4), end_date >= NOW(), ORDER BY end_date ASC
- `fn_dashboard_recent_outgoing(p_unit_id, p_limit)` — latest VB đi with doc_type name JOIN, sent_date from COALESCE(publish_date, received_date, created_at)

## Deviations from Plan

### Schema Adaptations (Rule 1 — accurate column mapping)

**1. [Rule 1 - Schema] incoming_unread uses user_incoming_docs instead of incoming_docs.is_read**
- **Found during:** Task 2 read_first
- **Issue:** `incoming_docs` table has no `is_read` column. The read-tracking is in `edoc.user_incoming_docs` (per Sprint 3 design)
- **Fix:** `fn_dashboard_get_stats` JOINs `user_incoming_docs` on `staff_id + is_read=FALSE` instead of checking incoming_docs directly
- **Files modified:** 015_sprint10_dashboard_stats.sql

**2. [Rule 1 - Schema] handling_docs uses end_date, not deadline column**
- **Found during:** Task 2 read_first
- **Issue:** Plan mentioned `deadline` column but `handling_docs` uses `end_date` for the deadline
- **Fix:** All queries use `end_date` column for deadline-based filtering
- **Files modified:** 015_sprint10_dashboard_stats.sql

**3. [Rule 1 - Schema] outgoing_pending uses approved=FALSE (no status-based pending state)**
- **Found during:** Task 2 read_first
- **Issue:** outgoing_docs has `approved BOOLEAN` but no multi-status enum column for pending/draft
- **Fix:** `approved = FALSE` used as the pending proxy for outgoing_pending KPI
- **Files modified:** 015_sprint10_dashboard_stats.sql

## Threat Mitigations Applied

| Threat ID | Applied |
|-----------|---------|
| T-04-01 (Calendar ownership) | `fn_calendar_event_update` and `fn_calendar_event_delete` check `created_by = p_staff_id` for personal scope before modifying |
| T-04-02 (Directory info disclosure) | `fn_directory_get_list` selects only public contact info (full_name, phone, mobile, email, image) — never includes password_hash or sensitive fields |
| T-04-03 (Calendar scope elevation) | Backend routes (future plan) must validate admin role for unit/leader scope creation; the SP itself does not enforce this at DB level |

## Known Stubs

None — all stored functions query real tables with real column names verified against schema.

## Self-Check: PASSED

- `014_sprint9_calendar_directory.sql` exists: FOUND
- `015_sprint10_dashboard_stats.sql` exists: FOUND
- Commit d8da85e: FOUND
- Commit f5929a5: FOUND
- `fn_calendar_event` count in 014: 5 occurrences
- `fn_dashboard` count in 015: 4 occurrences
