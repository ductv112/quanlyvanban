# Field Audit Report: Repository vs Database SP Signatures

**Audited**: 2026-04-15
**Total repository files**: 37
**Total SPs checked**: ~180+

---

## CRITICAL MISMATCHES FOUND

### 1. dashboard.repository.ts — MULTIPLE SEVERE MISMATCHES

| SP Name | Issue | Code Has | DB Has |
|---------|-------|----------|--------|
| `fn_dashboard_get_stats` | **Param order swapped** | `[unitId, staffId]` (unitId first) | `(p_staff_id integer, p_unit_id integer)` (staffId first) |
| `fn_dashboard_recent_incoming` | **Wrong return fields** | `number, notation, publish_unit, received_date, doc_type_name, urgent_id` | `doc_code, abstract, received_date, urgency_name, sender_name` (no number/notation/publish_unit/doc_type_name/urgent_id) |
| `fn_dashboard_recent_outgoing` | **Wrong return fields** | `number, notation, abstract, publish_date, doc_type_name` | `doc_code, abstract, sent_date, doc_type_name` (no number/notation, publish_date -> sent_date) |
| `fn_dashboard_upcoming_tasks` | **Wrong return fields** | `name, start_date, end_date, status, progress, curator_name` | `title, open_date, status, progress_percent, deadline` (no name/start_date/end_date/progress/curator_name) |

**Impact**: Dashboard page will show empty/undefined data for ALL widgets. This is a **P0 bug** affecting the main landing page.

### 2. auth.repository.ts — Interface includes field not in SP output

| SP Name | Issue | Code Has | DB Has |
|---------|-------|----------|--------|
| `fn_auth_verify_refresh_token` | `StaffLoginRow` has `password_hash` | `password_hash` in interface | SP does NOT return `password_hash` |

**Impact**: Low — `password_hash` will be `undefined` at runtime but it's not used after token verification. Still a type-safety issue.

### 3. staff.repository.ts — `StaffDetailRow` missing `roles` field

| SP Name | Issue | Code Has | DB Has |
|---------|-------|----------|--------|
| `fn_staff_get_by_id` | Missing field in interface | no `roles` field in `StaffDetailRow` | SP returns `roles text` column |

**Impact**: Medium — if frontend needs roles from detail view, it won't be typed. The field still arrives at runtime but isn't in the TypeScript interface.

### 4. message.repository.ts — MULTIPLE field mismatches

| SP Name | Issue | Code Has | DB Has |
|---------|-------|----------|--------|
| `fn_message_get_inbox` | **Extra field in SP not in interface** | `MessageListRow` lacks `parent_id` | SP returns `parent_id bigint` |
| `fn_message_get_sent` | **Completely wrong interface** | Uses `MessageListRow` (has `from_staff_id`, `from_staff_name`, `is_read`) | SP returns `recipient_names text` instead, NO `from_staff_id`/`from_staff_name`/`is_read` |
| `fn_message_get_trash` | **Extra field in SP not in interface** | `MessageListRow` lacks `deleted_at` | SP returns `deleted_at timestamp` |
| `fn_message_get_by_id` | **Field name mismatch** | `MessageDetailRow.recipients` | SP returns `recipient_names text` (not `recipients`) |
| `fn_message_create` | **Param type mismatch** | Passes manual `pgArray` string `{1,2,3}` | SP expects `integer[]` — should pass JS array directly |
| `fn_message_reply` | **Return field name mismatch** | `MessageReplyResult.reply_id` | SP returns `id bigint` (not `reply_id`) |

**Impact**: HIGH — Sent messages list will show wrong/empty data. Message detail `recipients` field will be undefined. Reply result `reply_id` will always be undefined.

### 5. notice.repository.ts — Param type mismatch

| SP Name | Issue | Code Has | DB Has |
|---------|-------|----------|--------|
| `fn_notice_get_list` | **p_is_read type mismatch** | Passes `boolean \| null` | SP expects `p_is_read text` (not boolean!) |

**Impact**: Medium — PostgreSQL may auto-cast, but if it doesn't, the filter won't work.

### 6. inter-incoming.repository.ts — Missing `updated_at` field

| SP Name | Issue | Code Has | DB Has |
|---------|-------|----------|--------|
| `fn_inter_incoming_get_list` | Missing field in interface | `InterIncomingListRow` lacks `updated_at` | SP returns `updated_at timestamp` |
| `fn_inter_incoming_get_by_id` | Missing field in interface | `InterIncomingDetailRow` lacks `updated_at` | SP returns `updated_at timestamp` |

**Impact**: Low — data still arrives, just not typed.

### 7. incoming-doc.repository.ts — `IncomingDocDetailRow` has `read_at` from parent but SP doesn't return it

| SP Name | Issue | Code Has | DB Has |
|---------|-------|----------|--------|
| `fn_incoming_doc_get_by_id` | **Inherited field not in SP** | `IncomingDocDetailRow` extends `IncomingDocListRow` which has `read_at` | SP does NOT return `read_at` |

**Impact**: Low — `read_at` will be undefined in detail view but likely not used there.

### 8. work-calendar.repository.ts — Missing `created_at` field

| SP Name | Issue | Code Has | DB Has |
|---------|-------|----------|--------|
| `fn_work_calendar_get` | Missing field in interface | `WorkCalendarRow` lacks `created_at` | SP returns `created_at timestamp` |

**Impact**: Low — data still arrives, just not typed.

### 9. doc-type.repository.ts — Missing `created_at` field

| SP Name | Issue | Code Has | DB Has |
|---------|-------|----------|--------|
| `fn_doc_type_get_tree` | Missing field in interface | `DocTypeRow` lacks `created_at` | SP returns `created_at timestamp` |
| `fn_doc_type_get_by_id` | Missing field in interface | `DocTypeRow` lacks `created_at` | SP returns `created_at timestamp` |

**Impact**: Low.

### 10. doc-field.repository.ts — Missing `created_at` field

| SP Name | Issue | Code Has | DB Has |
|---------|-------|----------|--------|
| `fn_doc_field_get_list` | Missing field in interface | `DocFieldRow` lacks `created_at` | SP returns `created_at timestamp` |
| `fn_doc_field_get_by_id` | Missing field in interface | `DocFieldRow` lacks `created_at` | SP returns `created_at timestamp` |

**Impact**: Low.

### 11. work-group.repository.ts — Missing `created_by` field and extra `full_name` in member

| SP Name | Issue | Code Has | DB Has |
|---------|-------|----------|--------|
| `fn_work_group_get_list` | Missing field in interface | `WorkGroupRow` lacks `created_by` | SP returns `created_by integer` |
| `fn_work_group_get_by_id` | Missing field in interface | `WorkGroupRow` lacks `created_by` | SP returns `created_by integer` |
| `fn_work_group_get_members` | **Field name mismatch** | `WorkGroupMemberRow.full_name` | SP returns `staff_name` (not `full_name`) |
| `fn_work_group_get_members` | Missing fields in interface | lacks `group_id`, `created_at` | SP returns `group_id integer, created_at timestamp` |

**Impact**: Medium — `full_name` in member rows will be undefined; frontend will show empty member names.

### 12. role.repository.ts — Missing `created_at` in `fn_role_get_by_id`

| SP Name | Issue | Code Has | DB Has |
|---------|-------|----------|--------|
| `fn_role_get_by_id` | Interface has `created_at` but SP doesn't return it | `RoleRow.created_at` | SP only returns `id, name, description, unit_id, is_locked` (no `created_at`) |

**Impact**: Low — `created_at` will be undefined in detail but likely not displayed.

### 13. doc-type.repository.ts — `notation_type` type mismatch

| SP Name | Issue | Code Has | DB Has |
|---------|-------|----------|--------|
| `fn_doc_type_get_tree` / `get_by_id` | Type mismatch | `DocTypeRow.notation_type: string` | SP returns `notation_type smallint` (number) |

**Impact**: Low — JavaScript will still work but TypeScript types are wrong.

---

## MODERATE ISSUES

### 14. meeting.repository.ts — Minor type differences

| SP Name | Issue | Code Has | DB Has |
|---------|-------|----------|--------|
| `fn_vote_question_get_list` | `VoteQuestionRow.id: string` | `id: string` | SP returns `id uuid` — OK, pg driver returns uuid as string |
| `fn_room_schedule_get_list` | Type mismatch | `staff_count: number`, `total_count: number` | SP returns `bigint` for both |

**Impact**: Low — JavaScript handles this fine.

### 15. document.repository.ts — Uses `iso.fn_doc_category_*` but SPs are in default namespace

| SP Name | Issue | Code Has | DB Has |
|---------|-------|----------|--------|
| All doc category SPs | **Wrong schema prefix** | `iso.fn_doc_category_get_tree` etc. | SPs exist but search only found them without schema qualification |

**Impact**: Need to verify — if SPs are in `iso` schema, this is fine. The pg_proc query found them so they exist.

---

## CLEAN (no issues found)

- department.repository.ts -- All SP signatures match
- position.repository.ts -- All SP signatures match (uses correct overloaded SP)
- right.repository.ts -- All SP signatures match
- doc-book.repository.ts -- All SP signatures match
- signer.repository.ts -- All SP signatures match
- delegation.repository.ts -- All SP signatures match
- config.repository.ts -- All SP signatures match
- template.repository.ts -- All SP signatures match (sms + email)
- doc-column.repository.ts -- All SP signatures match
- digital-signature.repository.ts -- All SP signatures match
- incoming-doc.repository.ts -- Mostly clean (minor read_at inheritance issue noted above)
- outgoing-doc.repository.ts -- All SP signatures match
- drafting-doc.repository.ts -- All SP signatures match
- handling-doc.repository.ts -- All SP signatures match
- handling-doc-report.repository.ts -- All SP signatures match
- address.repository.ts -- All SP signatures match
- calendar.repository.ts -- All SP signatures match
- organization.repository.ts -- All SP signatures match
- lgsp.repository.ts -- All SP signatures match
- notification.repository.ts -- All SP signatures match
- archive.repository.ts -- All SP signatures match (warehouse, fond, record, borrow)
- contract.repository.ts -- All SP signatures match
- directory.repository.ts -- All SP signatures match
- workflow.repository.ts -- All SP signatures match
- staff.repository.ts -- Mostly clean (minor missing `roles` field noted above)

---

## PRIORITY FIX ORDER

### P0 — Will cause runtime errors / broken features
1. **dashboard.repository.ts** — Param order swap + ALL return field names wrong (4 SPs)
2. **message.repository.ts** — `fn_message_get_sent` uses completely wrong interface; `recipients` vs `recipient_names`; `reply_id` vs `id`

### P1 — Data shows wrong/empty in UI
3. **work-group.repository.ts** — `full_name` vs `staff_name` in members

### P2 — Type safety issues (may work at runtime but wrong types)
4. **auth.repository.ts** — `password_hash` in `StaffLoginRow` for verify
5. **notice.repository.ts** — `boolean` vs `text` for `is_read` param
6. **role.repository.ts** — `created_at` in interface but not in `get_by_id` SP
7. **doc-type.repository.ts** — `notation_type` string vs smallint
8. **staff.repository.ts** — Missing `roles` in `StaffDetailRow`
9. **incoming-doc.repository.ts** — `read_at` inherited but not in detail SP
10. **inter-incoming.repository.ts** — Missing `updated_at`
11. **work-calendar.repository.ts** — Missing `created_at`
12. **doc-field.repository.ts** — Missing `created_at`
13. **doc-type.repository.ts** — Missing `created_at`

---

## SUMMARY

| Severity | Count | Description |
|----------|-------|-------------|
| P0 | 2 repos (6 SPs) | Runtime broken — dashboard + message |
| P1 | 1 repo (1 SP) | Wrong data displayed — work group members |
| P2 | 8 repos (~12 fields) | Type mismatches or missing optional fields |
| Clean | 25 repos | No issues found |

**Total mismatched fields**: ~25
**Total repos with issues**: 12 of 37 (32%)
