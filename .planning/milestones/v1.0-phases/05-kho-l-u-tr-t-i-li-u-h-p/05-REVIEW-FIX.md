---
phase: 05-data-type-maxlength-audit
fixed_at: 2026-04-14T16:30:00Z
review_path: .planning/phases/05-kho-l-u-tr-t-i-li-u-h-p/05-REVIEW.md
iteration: 1
findings_in_scope: 31
fixed: 25
skipped: 6
status: partial
---

# Phase 05: Code Review Fix Report

**Fixed at:** 2026-04-14T16:30:00Z
**Source review:** .planning/phases/05-kho-l-u-tr-t-i-li-u-h-p/05-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 31 (2 Critical + 29 Warning, excluding Info and backend-only bigint fixes)
- Fixed: 25
- Skipped: 6

## Fixed Issues

### CR-01: Contract `amount` field type mismatch

**Files modified:** `e_office_app_new/frontend/src/app/(main)/hop-dong/page.tsx`
**Applied fix:** Changed `amount: number` and `payment_amount: number` to `amount?: string` and `payment_amount?: string` in Contract interface. Replaced `<InputNumber>` with `<Input maxLength={200}>` for both amount fields. Updated `formatCurrency()` to accept `string | number | null | undefined` and parse string amounts safely.

### CR-02: Archive record `format` field type mismatch

**Files modified:** `e_office_app_new/frontend/src/app/(main)/kho-luu-tru/page.tsx`
**Applied fix:** Replaced `<Input placeholder="VD: Ban giay, Dien tu..." maxLength={100} />` with `<Select>` component with integer options (1=Ban giay, 2=Dien tu, 3=Hon hop) matching the DB integer column type.

### WR-01: Missing maxLength on meeting name

**Files modified:** `e_office_app_new/frontend/src/app/(main)/cuoc-hop/page.tsx`
**Applied fix:** Added `maxLength={500}` to meeting name Input.

### WR-02: Missing maxLength on online_link

**Files modified:** `e_office_app_new/frontend/src/app/(main)/cuoc-hop/page.tsx`
**Applied fix:** Added `maxLength={500}` to online_link Input.

### WR-03: Missing maxLength on component

**Files modified:** `e_office_app_new/frontend/src/app/(main)/cuoc-hop/page.tsx`
**Applied fix:** Added `maxLength={500}` to component Input.

### WR-04: Missing maxLength on room code

**Files modified:** `e_office_app_new/frontend/src/app/(main)/cuoc-hop/page.tsx`
**Applied fix:** Added `maxLength={50}` to room code Input.

### WR-05: Missing maxLength on room name

**Files modified:** `e_office_app_new/frontend/src/app/(main)/cuoc-hop/page.tsx`
**Applied fix:** Added `maxLength={200}` to room name Input.

### WR-06: Missing maxLength on room location

**Files modified:** `e_office_app_new/frontend/src/app/(main)/cuoc-hop/page.tsx`
**Applied fix:** Added `maxLength={500}` to room location Input.

### WR-07: Missing maxLength on meeting type name

**Files modified:** `e_office_app_new/frontend/src/app/(main)/cuoc-hop/page.tsx`
**Applied fix:** Added `maxLength={200}` to meeting type name Input.

### WR-08: Missing maxLength on contract code

**Files modified:** `e_office_app_new/frontend/src/app/(main)/hop-dong/page.tsx`
**Applied fix:** Added `maxLength={100}` to contract code Input.

### WR-09: Missing maxLength on contract name

**Files modified:** `e_office_app_new/frontend/src/app/(main)/hop-dong/page.tsx`
**Applied fix:** Added `maxLength={500}` to contract name Input.

### WR-10: Missing maxLength on contact_name

**Files modified:** `e_office_app_new/frontend/src/app/(main)/hop-dong/page.tsx`
**Applied fix:** Added `maxLength={200}` to contact_name Input.

### WR-11: Missing maxLength on signer (contract)

**Files modified:** `e_office_app_new/frontend/src/app/(main)/hop-dong/page.tsx`
**Applied fix:** Added `maxLength={200}` to signer Input.

### WR-12: Missing maxLength on contract type code

**Files modified:** `e_office_app_new/frontend/src/app/(main)/hop-dong/page.tsx`
**Applied fix:** Added `maxLength={50}` to contract type code Input.

### WR-13: Missing maxLength on contract type name

**Files modified:** `e_office_app_new/frontend/src/app/(main)/hop-dong/page.tsx`
**Applied fix:** Added `maxLength={200}` to contract type name Input.

### WR-14: Missing maxLength on notation (van-ban-den)

**Files modified:** `e_office_app_new/frontend/src/app/(main)/van-ban-den/page.tsx`
**Applied fix:** Added `maxLength={100}` to notation Input.

### WR-15: Missing maxLength on publish_unit (van-ban-den)

**Files modified:** `e_office_app_new/frontend/src/app/(main)/van-ban-den/page.tsx`
**Applied fix:** Added `maxLength={500}` to publish_unit Input.

### WR-16: Missing maxLength on signer (van-ban-den)

**Files modified:** `e_office_app_new/frontend/src/app/(main)/van-ban-den/page.tsx`
**Applied fix:** Added `maxLength={200}` to signer Input.

### WR-17: Missing maxLength on category code (tai-lieu)

**Files modified:** `e_office_app_new/frontend/src/app/(main)/tai-lieu/page.tsx`
**Applied fix:** Added `maxLength={50}` to category code Input.

### WR-18: Missing maxLength on category name (tai-lieu)

**Files modified:** `e_office_app_new/frontend/src/app/(main)/tai-lieu/page.tsx`
**Applied fix:** Added `maxLength={200}` to category name Input.

### WR-19: Missing maxLength on document title (tai-lieu)

**Files modified:** `e_office_app_new/frontend/src/app/(main)/tai-lieu/page.tsx`
**Applied fix:** Added `maxLength={500}` to document title Input.

### WR-20: Missing maxLength on keyword (tai-lieu)

**Files modified:** `e_office_app_new/frontend/src/app/(main)/tai-lieu/page.tsx`
**Applied fix:** Added `maxLength={500}` to keyword Input.

### WR-21: date_process uses text Input instead of InputNumber

**Files modified:** `e_office_app_new/frontend/src/app/(main)/tai-lieu/page.tsx`
**Applied fix:** Changed `<Input>` to `<InputNumber min={0}>` for date_process field. Added `InputNumber` to antd imports.

### WR-22: Department code maxLength too restrictive (20 vs DB 50)

**Files modified:** `e_office_app_new/frontend/src/app/(main)/quan-tri/don-vi/page.tsx`
**Applied fix:** Changed `maxLength={20}` to `maxLength={50}` to match DB VARCHAR(50).

### WR-23: Warehouse phone_number maxLength too restrictive (20 vs DB 50)

**Files modified:** `e_office_app_new/frontend/src/app/(main)/kho-luu-tru/page.tsx`
**Applied fix:** Changed `maxLength={20}` to `maxLength={50}` to match DB VARCHAR(50).

### WR-24: Record maintenance maxLength too restrictive (100 vs DB 200)

**Files modified:** `e_office_app_new/frontend/src/app/(main)/kho-luu-tru/page.tsx`
**Applied fix:** Changed `maxLength={100}` to `maxLength={200}` to match DB VARCHAR(200).

### WR-25: Record keyword maxLength too restrictive (200 vs DB 500)

**Files modified:** `e_office_app_new/frontend/src/app/(main)/kho-luu-tru/page.tsx`
**Applied fix:** Changed `maxLength={200}` to `maxLength={500}` to match DB VARCHAR(500).

### WR-27: Missing required rule for room_id

**Files modified:** `e_office_app_new/frontend/src/app/(main)/cuoc-hop/page.tsx`
**Applied fix:** Added `rules={[{ required: true, message: 'Chon phong hop' }]}` to room_id Form.Item.

### WR-30: Missing required rule for in_charge_staff_id

**Files modified:** `e_office_app_new/frontend/src/app/(main)/kho-luu-tru/page.tsx`
**Applied fix:** Added `rules={[{ required: true, message: 'Chon nguoi phu trach' }]}` to in_charge_staff_id Form.Item.

## Skipped Issues

### WR-32: ContractListRow.attachment_count bigint type

**File:** `e_office_app_new/backend/src/repositories/contract.repository.ts:38`
**Reason:** Backend-only TypeScript type fix. Not included in this frontend-focused fix batch. Should be addressed in a backend-focused review.
**Original issue:** TypeScript `bigint` is not JSON-serializable; pg driver returns bigint as string.

### WR-33: ContractListRow.total_count bigint type

**File:** `e_office_app_new/backend/src/repositories/contract.repository.ts:39`
**Reason:** Backend-only TypeScript type fix. Not included in this frontend-focused fix batch.
**Original issue:** Same bigint serialization issue.

### WR-34: ContractAttachmentRow.id bigint type

**File:** `e_office_app_new/backend/src/repositories/contract.repository.ts:81`
**Reason:** Backend-only TypeScript type fix. Not included in this frontend-focused fix batch.
**Original issue:** Same bigint serialization issue.

### WR-35: ContractAttachmentRow.file_size bigint type

**File:** `e_office_app_new/backend/src/repositories/contract.repository.ts:85`
**Reason:** Backend-only TypeScript type fix. Not included in this frontend-focused fix batch.
**Original issue:** Same bigint serialization issue.

### WR-36: RecordListRow.id bigint type

**File:** `e_office_app_new/backend/src/repositories/archive.repository.ts:60`
**Reason:** Backend-only TypeScript type fix. Not included in this frontend-focused fix batch.
**Original issue:** Same bigint serialization issue.

### WR-37: RecordListRow.total_count bigint type

**File:** `e_office_app_new/backend/src/repositories/archive.repository.ts:86`
**Reason:** Backend-only TypeScript type fix. Not included in this frontend-focused fix batch.
**Original issue:** Same bigint serialization issue.

---

_Fixed: 2026-04-14T16:30:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
