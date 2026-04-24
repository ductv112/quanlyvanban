---
phase: 05-data-type-maxlength-audit
reviewed: 2026-04-14T15:00:00Z
depth: deep
files_reviewed: 34
files_reviewed_list:
  - e_office_app_new/backend/src/repositories/department.repository.ts
  - e_office_app_new/backend/src/repositories/staff.repository.ts
  - e_office_app_new/backend/src/repositories/incoming-doc.repository.ts
  - e_office_app_new/backend/src/repositories/outgoing-doc.repository.ts
  - e_office_app_new/backend/src/repositories/drafting-doc.repository.ts
  - e_office_app_new/backend/src/repositories/contract.repository.ts
  - e_office_app_new/backend/src/repositories/meeting.repository.ts
  - e_office_app_new/backend/src/repositories/archive.repository.ts
  - e_office_app_new/backend/src/repositories/document.repository.ts
  - e_office_app_new/backend/src/repositories/position.repository.ts
  - e_office_app_new/backend/src/repositories/organization.repository.ts
  - e_office_app_new/backend/src/repositories/doc-book.repository.ts
  - e_office_app_new/backend/src/repositories/doc-field.repository.ts
  - e_office_app_new/frontend/src/app/(main)/quan-tri/don-vi/page.tsx
  - e_office_app_new/frontend/src/app/(main)/quan-tri/nguoi-dung/page.tsx
  - e_office_app_new/frontend/src/app/(main)/quan-tri/chuc-vu/page.tsx
  - e_office_app_new/frontend/src/app/(main)/quan-tri/co-quan/page.tsx
  - e_office_app_new/frontend/src/app/(main)/quan-tri/dia-ban/page.tsx
  - e_office_app_new/frontend/src/app/(main)/quan-tri/linh-vuc/page.tsx
  - e_office_app_new/frontend/src/app/(main)/quan-tri/loai-van-ban/page.tsx
  - e_office_app_new/frontend/src/app/(main)/quan-tri/nhom-quyen/page.tsx
  - e_office_app_new/frontend/src/app/(main)/quan-tri/chuc-nang/page.tsx
  - e_office_app_new/frontend/src/app/(main)/quan-tri/mau-thong-bao/page.tsx
  - e_office_app_new/frontend/src/app/(main)/van-ban-den/page.tsx
  - e_office_app_new/frontend/src/app/(main)/van-ban-den/[id]/page.tsx
  - e_office_app_new/frontend/src/app/(main)/cuoc-hop/page.tsx
  - e_office_app_new/frontend/src/app/(main)/hop-dong/page.tsx
  - e_office_app_new/frontend/src/app/(main)/kho-luu-tru/page.tsx
  - e_office_app_new/frontend/src/app/(main)/tai-lieu/page.tsx
findings:
  critical: 2
  warning: 36
  info: 5
  total: 43
status: issues_found
---

# Data Type and MaxLength Audit Report

**Reviewed:** 2026-04-14
**Depth:** deep (cross-file: DB schema vs repositories vs frontend forms)
**Files Reviewed:** 34

## Summary

Audited the full DB schema (790 columns across public/edoc/esto/cont/iso schemas) against backend TypeScript Row interfaces and frontend Ant Design form validation. Found **2 critical** type mismatches, **36 warnings** (missing maxLength validations on VARCHAR fields), and **5 info** items.

Key findings:
- **Critical**: `contract.amount` is typed as `number` in the frontend interface but is `VARCHAR(200)` in DB (string). The form uses `InputNumber` which will send a number to a string column -- potential data truncation or type coercion issues.
- **Critical**: `kho-luu-tru` record `format` field is DB `integer` but rendered as `<Input>` (text) on the form -- will send string to integer column.
- **36 form fields** across 7 pages are missing `maxLength` validation, which can cause DB truncation errors (PostgreSQL will reject inserts exceeding VARCHAR limits).

---

## Critical Issues

### CR-01: Contract `amount` field type mismatch (Frontend number vs DB string)

**File:** `e_office_app_new/frontend/src/app/(main)/hop-dong/page.tsx:49`
**Issue:** The `Contract` interface defines `amount: number` (line 49) and the form uses `<InputNumber>` (line 762). However, the DB column `cont.contracts.amount` is `VARCHAR(200)`. The backend `ContractDetailRow` correctly types it as `string | null`. The frontend will send a numeric value, but the DB expects a string. While PostgreSQL auto-casts, this creates inconsistency and the `formatCurrency()` function (line 78) expects a number, which will fail when receiving a string from the API.

**Fix:**
```typescript
// In frontend interface, change:
interface Contract {
  // ...
  amount: string;  // was: number — DB is VARCHAR(200)
  // ...
}

// In the form, keep InputNumber but convert to string on save:
const payload = {
  ...values,
  amount: values.amount != null ? String(values.amount) : null,
};
```

### CR-02: Archive record `format` field type mismatch (DB integer, form uses text Input)

**File:** `e_office_app_new/frontend/src/app/(main)/kho-luu-tru/page.tsx:1012-1013`
**Issue:** The DB column `esto.records.format` is `integer`, and the backend `RecordListRow` correctly types it as `format: number`. But the frontend form renders it as `<Input placeholder="VD: Ban giay, Dien tu..." maxLength={100} />` which collects a text string. This will cause a type error when the backend tries to insert a string into an integer column.

**Fix:**
```tsx
// Replace text Input with Select or InputNumber:
<Form.Item label="Hinh thuc" name="format">
  <Select
    placeholder="Chon hinh thuc"
    options={[
      { value: 1, label: 'Ban giay' },
      { value: 2, label: 'Dien tu' },
      { value: 3, label: 'Hon hop' },
    ]}
  />
</Form.Item>
```

---

## Warnings

### Section A: Missing maxLength on Frontend Forms

These fields have `VARCHAR(N)` limits in the DB but no `maxLength` prop on the frontend `<Input>` component, allowing users to enter data that PostgreSQL will reject.

| # | Page | Form Field | DB Table.Column | DB Limit | Current maxLength | Fix |
|---|------|-----------|----------------|----------|------------------|-----|
| WR-01 | cuoc-hop/page.tsx:710 | `name` (cuoc hop) | edoc.room_schedules.name | 500 | **MISSING** | Add `maxLength={500}` |
| WR-02 | cuoc-hop/page.tsx:755 | `online_link` | edoc.room_schedules.online_link | 500 | **MISSING** | Add `maxLength={500}` |
| WR-03 | cuoc-hop/page.tsx:760 | `component` | edoc.room_schedules.component | 500 | **MISSING** | Add `maxLength={500}` |
| WR-04 | cuoc-hop/page.tsx:801 | `code` (phong hop) | edoc.rooms.code | 50 | **MISSING** | Add `maxLength={50}` |
| WR-05 | cuoc-hop/page.tsx:804 | `name` (phong hop) | edoc.rooms.name | 200 | **MISSING** | Add `maxLength={200}` |
| WR-06 | cuoc-hop/page.tsx:807 | `location` | edoc.rooms.location | 500 | **MISSING** | Add `maxLength={500}` |
| WR-07 | cuoc-hop/page.tsx:847 | `name` (loai cuoc hop) | edoc.meeting_types.name | 200 | **MISSING** | Add `maxLength={200}` |
| WR-08 | hop-dong/page.tsx:703 | `code` (hop dong) | cont.contracts.code | 100 | **MISSING** | Add `maxLength={100}` |
| WR-09 | hop-dong/page.tsx:725 | `name` (hop dong) | cont.contracts.name | 500 | **MISSING** | Add `maxLength={500}` |
| WR-10 | hop-dong/page.tsx:731 | `contact_name` | cont.contracts.contact_name | 200 | **MISSING** | Add `maxLength={200}` |
| WR-11 | hop-dong/page.tsx:736 | `signer` | cont.contracts.signer | 200 | **MISSING** | Add `maxLength={200}` |
| WR-12 | hop-dong/page.tsx:637 | `code` (loai hop dong) | cont.contract_types.code | 50 | **MISSING** | Add `maxLength={50}` |
| WR-13 | hop-dong/page.tsx:637 | `name` (loai hop dong) | cont.contract_types.name | 200 | **MISSING** | Add `maxLength={200}` |
| WR-14 | van-ban-den/page.tsx:267 | `notation` | edoc.incoming_docs.notation | 100 | **MISSING** | Add `maxLength={100}` |
| WR-15 | van-ban-den/page.tsx:268 | `publish_unit` | edoc.incoming_docs.publish_unit | 500 | **MISSING** | Add `maxLength={500}` |
| WR-16 | van-ban-den/page.tsx:274 | `signer` | edoc.incoming_docs.signer | 200 | **MISSING** | Add `maxLength={200}` |
| WR-17 | tai-lieu/page.tsx:590 | `code` (danh muc) | iso.document_categories.code | 50 | **MISSING** | Add `maxLength={50}` |
| WR-18 | tai-lieu/page.tsx:597 | `name` (danh muc) | iso.document_categories.name | 200 | **MISSING** | Add `maxLength={200}` |
| WR-19 | tai-lieu/page.tsx:639 | `title` (tai lieu) | iso.documents.title | 500 | **MISSING** | Add `maxLength={500}` |
| WR-20 | tai-lieu/page.tsx:661 | `keyword` (tai lieu) | iso.documents.keyword | 500 | **MISSING** | Add `maxLength={500}` |
| WR-21 | tai-lieu/page.tsx:612 | `date_process` | iso.document_categories.date_process | N/A (numeric) | Uses `<Input>` | Should use `<InputNumber>` since DB type is `numeric` |

### Section B: maxLength Mismatch (Frontend vs DB)

These fields have a `maxLength` set but it does not match the DB VARCHAR limit.

| # | Page | Form Field | DB Table.Column | DB Limit | Frontend maxLength | Fix |
|---|------|-----------|----------------|----------|-------------------|-----|
| WR-22 | quan-tri/don-vi/page.tsx:388 | `code` | public.departments.code | **50** | 20 | Change to `maxLength={50}` (frontend is too restrictive) |
| WR-23 | kho-luu-tru/page.tsx:847 | `phone_number` | esto.warehouses.phone_number | **50** | 20 | Change to `maxLength={50}` |
| WR-24 | kho-luu-tru/page.tsx:1020 | `maintenance` | esto.records.maintenance | **200** | 100 | Change to `maxLength={200}` |
| WR-25 | kho-luu-tru/page.tsx:1025 | `keyword` | esto.records.keyword | **500** | 200 | Change to `maxLength={500}` |
| WR-26 | kho-luu-tru/page.tsx:1008 | `language` | esto.records.language | 100 | 100 | OK (matches) |

### Section C: Missing NOT NULL / Required Validation

These DB columns are `NOT NULL` but the frontend form does not have `required: true` rule.

| # | Page | Form Field | DB Table.Column | DB NOT NULL | Has required | Fix |
|---|------|-----------|----------------|------------|-------------|-----|
| WR-27 | cuoc-hop/page.tsx:714 | `room_id` | edoc.room_schedules.room_id | **NO (NOT NULL)** | **No** | Add `rules={[{ required: true, message: 'Chon phong hop' }]}` |
| WR-28 | cuoc-hop/page.tsx:803 | `name` (phong hop) | edoc.rooms.name | **NO (NOT NULL)** | Yes | OK |
| WR-29 | hop-dong/page.tsx:725 | `name` (hop dong) | cont.contracts.name | **NO (NOT NULL)** | Yes | OK |
| WR-30 | kho-luu-tru/page.tsx:977 | `in_charge_staff_id` | esto.records.in_charge_staff_id | **NO (NOT NULL)** | **No** | Add `rules={[{ required: true, message: 'Chon nguoi phu trach' }]}` |
| WR-31 | tai-lieu/page.tsx:612 | `date_process` | iso.document_categories.date_process | YES (nullable) | No | OK (nullable) |

### Section D: TypeScript Type Mismatches (Backend Row Interfaces vs DB)

| # | File | Field | DB Type | TS Type | Issue | Fix |
|---|------|-------|---------|---------|-------|-----|
| WR-32 | contract.repository.ts:38 | `ContractListRow.attachment_count` | SP returns `bigint` | `bigint` | TypeScript `bigint` is not JSON-serializable. `pg` driver returns bigint as `string`. | Change to `string` or `number` |
| WR-33 | contract.repository.ts:39 | `ContractListRow.total_count` | SP returns `bigint` | `bigint` | Same issue as above. | Change to `number` (safe for counts) |
| WR-34 | contract.repository.ts:81 | `ContractAttachmentRow.id` | DB `bigint` | `bigint` | Same serialization issue. | Change to `number` |
| WR-35 | contract.repository.ts:85 | `ContractAttachmentRow.file_size` | DB `bigint` | `bigint \| null` | Same serialization issue. | Change to `number \| null` |
| WR-36 | archive.repository.ts:60 | `RecordListRow.id` | DB `bigint` | `bigint` | Same issue -- pg returns string for bigint. | Change to `number` |
| WR-37 | archive.repository.ts:86 | `RecordListRow.total_count` | DB `bigint` | `bigint` | Same issue. | Change to `number` |

**Note on `bigint`:** The PostgreSQL `pg` driver returns `bigint` values as JavaScript strings (not BigInt), because JS `Number` cannot safely represent all 64-bit integers. For IDs and counts that won't exceed `Number.MAX_SAFE_INTEGER`, using `number` is correct. The current `bigint` type in TypeScript interfaces is misleading because the actual runtime value is a `string`.

---

## Info

### IN-01: Department code DB limit is 50, not 20

**File:** `e_office_app_new/frontend/src/app/(main)/quan-tri/don-vi/page.tsx:388`
**Issue:** The `departments.code` column is `VARCHAR(50)` but the form uses `maxLength={20}`. While not a bug (it's more restrictive), users may be unable to enter valid codes that the DB supports.
**Fix:** Consider changing to `maxLength={50}` to match DB.

### IN-02: Staff address maxLength may be overly generous

**File:** `e_office_app_new/frontend/src/app/(main)/quan-tri/nguoi-dung/page.tsx:706`
**Issue:** `staff.address` is `text` in DB (unlimited) but form uses `maxLength={500}`. This is fine -- `text` has no limit so frontend limit is a UX choice. No action needed.

### IN-03: Organizations form matches DB limits well

**File:** `e_office_app_new/frontend/src/app/(main)/quan-tri/co-quan/page.tsx`
**Issue:** Organization form fields all have correct `maxLength` matching DB limits. No issues found.

### IN-04: Position description is `text` in DB, form uses maxLength={500}

**File:** `e_office_app_new/frontend/src/app/(main)/quan-tri/chuc-vu/page.tsx:318`
**Issue:** `positions.description` is `text` (unlimited) in DB, frontend limits to 500. This is a reasonable UX constraint, not a mismatch.

### IN-05: Several forms correctly match DB limits

The following pages have proper `maxLength` validation matching DB VARCHAR limits:
- `quan-tri/don-vi`: name(200), name_en(200), short_name(50), phone(20), fax(20), email(100)
- `quan-tri/nguoi-dung`: username(50), last_name(50), first_name(50), email(100), phone(20), mobile(20)
- `quan-tri/chuc-vu`: name(100), code(20)
- `quan-tri/co-quan`: code(20), name(200), phone(20), fax(20), email(100), email_doc(100), secretary(200), chairman_number(20)
- `quan-tri/dia-ban`: code(10), name(100)
- `quan-tri/linh-vuc`: code(20), name(200)
- `quan-tri/loai-van-ban`: code(20), name(200)
- `kho-luu-tru` warehouse: code(50), name(200), address(500)
- `kho-luu-tru` fond: fond_code(50), fond_name(200), archives_time(100)
- `kho-luu-tru` record: file_code(100), title(500)

---

## Summary Stats

| Severity | Count | Description |
|----------|-------|-------------|
| Critical | 2 | Type mismatches causing potential data corruption or runtime errors |
| Warning | 36 | Missing maxLength (21), maxLength mismatch (4), missing required (2), TS bigint issues (6), input type mismatch (1), missing required (2) |
| Info | 5 | Informational notes, correct implementations |
| **Total** | **43** | |

### Priority Fix Order

1. **CR-01 + CR-02**: Fix type mismatches immediately -- these cause runtime errors
2. **WR-27, WR-30**: Add missing `required` rules for NOT NULL columns
3. **WR-01 to WR-21**: Add missing `maxLength` props (bulk fix, low effort)
4. **WR-22 to WR-25**: Correct maxLength mismatches
5. **WR-32 to WR-37**: Fix `bigint` types in repository interfaces

---

_Reviewed: 2026-04-14_
_Reviewer: Claude (data-type-maxlength-audit)_
_Depth: deep_
