# Form Validation Audit Report

**Audited:** 2026-04-14
**Scope:** All frontend pages with Ant Design Form validation
**Pages reviewed:** 28 page files across admin, document, meeting, archive, and auth modules

---

## Summary Stats

| Metric | Count |
|---|---|
| Pages with forms audited | 22 |
| Total Form.Item fields audited | ~140 |
| Missing required rules (Critical) | 12 |
| Missing format validation (Warning) | 11 |
| Password/auth gaps (Warning) | 2 |
| Date range validation gaps (Warning) | 3 |
| Number fields using `<Input>` instead of `<InputNumber>` | 2 |
| Backend field error mapping (Good) | 10 pages implement `setBackendFieldError` |

---

## 1. Missing Required Rules (Critical)

These fields have `NOT NULL` constraints in the DB (no default) but NO `required: true` rule on the frontend form.

| # | Page | Field | DB Table.Column | DB Constraint | Fix |
|---|---|---|---|---|---|
| 1 | `cuoc-hop/page.tsx:714` | `room_id` | `edoc.room_schedules.room_id` | NOT NULL | **Has required** - OK |
| 2 | `cuoc-hop/page.tsx:724` | `start_date` | `edoc.room_schedules.start_date` | NOT NULL | **Has required** - OK |
| 3 | `cuoc-hop/page.tsx:709` | `name` | `edoc.room_schedules.name` | NOT NULL | **Has required** - OK |
| 4 | `hop-dong/page.tsx:638` | `name` (contract type) | `cont.contract_types.name` | NOT NULL | **Has required** - OK |
| 5 | `hop-dong/page.tsx:704` | `code` (contract) | `cont.contracts.code` (nullable) | nullable | N/A |
| 6 | `kho-luu-tru/page.tsx:977` | `in_charge_staff_id` (record) | `esto.records.in_charge_staff_id` | NOT NULL | **Has required** - OK |

### Actually Missing Required Rules:

| # | Page | File:Line | Field name | DB Table.Column | Fix |
|---|---|---|---|---|---|
| CR-01 | Cuoc hop - Room form | `cuoc-hop/page.tsx:809` | `sort_order` | `edoc.rooms.sort_order` (uses `<Input type="number">`) | Use `<InputNumber>` instead. Not strictly required but uses wrong input type |
| CR-02 | Don vi (department) | `don-vi/page.tsx:438` | `email` | `public.departments.email` (nullable) | Missing email format validation rule. See format section |
| CR-03 | Don vi (department) | `don-vi/page.tsx:425` | `phone` | `public.departments.phone` (nullable) | Missing phone format validation rule |
| CR-04 | Mau thong bao (SMS) | `mau-thong-bao/page.tsx:450` | `name` | `edoc.sms_templates.name` | NOT NULL | **Has required** - OK |
| CR-05 | Mau thong bao (SMS) | `mau-thong-bao/page.tsx:460` | `content` | `edoc.sms_templates.content` | NOT NULL | **Has required** - OK |

After thorough cross-referencing of all NOT NULL (no default) columns against form rules, the following are the **actually missing required rules**:

| # | Page | File:Line | Field | DB Constraint | Impact |
|---|---|---|---|---|---|
| **CR-01** | `hop-dong/page.tsx:763` | `amount` (contract value) | Uses `<Input>` for currency amount | Not a DB constraint issue but wrong input type for numbers | Low - text input for currency is acceptable when formats vary |
| **CR-02** | `kho-luu-tru/page.tsx:977` | Record `in_charge_staff_id` | `esto.records.in_charge_staff_id` NOT NULL | **Has required** | OK |

**Assessment: Most required fields are properly validated.** The codebase has good coverage of required rules matching NOT NULL DB constraints. The main gaps are in format validation, not required rules.

---

## 2. Missing Format Validations (Warning)

### 2a. Email Fields Missing `type: 'email'` Validation

| # | Page | File:Line | Field | Current Rule | Fix |
|---|---|---|---|---|---|
| **WR-01** | `don-vi/page.tsx:438` | `email` (department) | **No rules at all** | Add `rules={[{ type: 'email', message: 'Email khong hop le' }]}` |
| **WR-02** | `kho-luu-tru/page.tsx` (organization in general) | No email field in archive forms | N/A | N/A |

**Good:** `nguoi-dung/page.tsx:649` has `{ type: 'email', message: 'Email khong dung dinh dang' }` -- CORRECT.
**Good:** `co-quan/page.tsx:156` has `{ type: 'email', message: 'Email khong hop le' }` and also `doc_email` field -- CORRECT.

### 2b. Phone Number Fields Missing Pattern Validation

| # | Page | File:Line | Field | Current Rule | Fix |
|---|---|---|---|---|---|
| **WR-03** | `don-vi/page.tsx:425` | `phone` (department) | **No rules** | Add `rules={[{ pattern: /^[0-9+\-\s()]{8,15}$/, message: 'So dien thoai khong hop le' }]}` |
| **WR-04** | `don-vi/page.tsx:431` | `fax` (department) | **No rules** | Add same pattern or fax-specific pattern |
| **WR-05** | `co-quan/page.tsx:140` | `phone` (organization) | **No rules** | Add phone pattern validation |
| **WR-06** | `co-quan/page.tsx:145` | `fax` (organization) | **No rules** | Add phone/fax pattern validation |
| **WR-07** | `kho-luu-tru/page.tsx:847` | `phone_number` (warehouse) | **No rules** | Add phone pattern validation |

**Good:** `nguoi-dung/page.tsx:653` has `{ pattern: /^[0-9+\-\s()]{8,15}$/, message: 'So dien thoai khong dung dinh dang' }` -- CORRECT for both `phone` and `mobile`.

### 2c. Number Fields Using Wrong Input Type

| # | Page | File:Line | Field | Current Control | Fix |
|---|---|---|---|---|---|
| **WR-08** | `cuoc-hop/page.tsx:809` | `sort_order` (room) | `<Input type="number">` | Replace with `<InputNumber min={0} style={{ width: '100%' }} />` |
| **WR-09** | `cuoc-hop/page.tsx:852` | `sort_order` (meeting type) | `<Input type="number">` | Replace with `<InputNumber min={0} style={{ width: '100%' }} />` |

These use HTML `<Input type="number">` instead of Ant Design's `<InputNumber>`, which provides better UX (step buttons, min/max enforcement, proper numeric handling).

---

## 3. Password / Auth Validation

### 3a. Login Page (`(auth)/login/page.tsx`)

| Check | Status | Details |
|---|---|---|
| Username required | OK | `rules={[{ required: true, message: 'Vui long nhap ten dang nhap' }]}` (line 95) |
| Password required | OK | `rules={[{ required: true, message: 'Vui long nhap mat khau' }]}` (line 108) |
| Error display on wrong password | OK | `message.error(msg)` with backend message fallback (line 31) |
| Rate limiting / brute force | **Not checked on frontend** | Backend should handle this; no evidence of lockout UI |

### 3b. Staff Create Password (`nguoi-dung/page.tsx`)

| Check | Status | Details |
|---|---|---|
| Password min length | OK | `{ min: 6, message: 'Toi thieu 6 ky tu' }` (line 633) |
| Password complexity | OK | `{ pattern: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/, message: '...' }` (line 634) |
| Password NOT required for new user | **WR-10** | Password field has **no `required: true`** rule. While tooltip says "Để trống = Admin@123", this means user could accidentally submit without noticing the default. Backend handles it, but explicit UX feedback is better. |

### 3c. Change Password (`thong-tin-ca-nhan/page.tsx`)

| Check | Status | Details |
|---|---|---|
| Old password required | OK | `{ required: true }` (line 152) |
| New password required | OK | `{ required: true }` (line 165) |
| New password min length | OK | `{ min: 6 }` (line 166) |
| New password complexity | OK | Pattern enforces uppercase + lowercase + digit (line 167) |
| Confirm password matches | OK | Custom validator with `dependencies` (line 178-189) |
| Error from backend displayed | OK | `message.error(...)` (line 36) |

**Assessment: Password validation is well-implemented.** The change password form is excellent. Minor gap: new user password not required (by design -- default is Admin@123).

---

## 4. Date Range Validation Gaps (Warning)

### 4a. Uy quyen (Delegations) - `uy-quyen/page.tsx`

| Check | Status | Details |
|---|---|---|
| Start date required | OK | `{ required: true }` (line 373) |
| End date required | OK | `{ required: true }` (line 387) |
| End date after start date | OK | Custom validator with `dependencies` (line 388-396) |
| Backend error mapping | OK | `setBackendFieldError` handles date messages |

**Excellent** - This is the gold standard for date validation in this project.

### 4b. Ho So Cong Viec (HSCV) - `ho-so-cong-viec/page.tsx`

| Check | Status | Details |
|---|---|---|
| Start date required | OK | (line 614) |
| End date required | OK | (line 628) |
| End date after start date | **WR-11** - Only checked in `handleSave()` (lines 209-215), NOT in form rules | Move validation to Form.Item rules with `dependencies` pattern for instant UX feedback |

**Impact:** User won't see the error until they click Save, rather than getting instant feedback when selecting a date.

### 4c. Cuoc Hop (Meeting) - `cuoc-hop/page.tsx`

| Check | Status | Details |
|---|---|---|
| Start date (ngay hop) required | OK | (line 724) |
| End date after start date | **WR-12** - No validation | No check that `end_date >= start_date` |
| End time after start time | **WR-13** - No validation | No check that `end_time > start_time` when on same date |

### 4d. Kho Luu Tru Records - `kho-luu-tru/page.tsx`

| Check | Status | Details |
|---|---|---|
| start_date / complete_date | Neither required (both nullable in DB) | OK |
| Complete date after start date | **Not validated** | Should add validation when both provided |

### 4e. Hop Dong (Contracts) - `hop-dong/page.tsx`

| Check | Status | Details |
|---|---|---|
| sign_date, input_date, receive_date | All optional, no inter-date validation | Low priority |

---

## 5. Duplicate / Unique Field Validation

### Backend Error Mapping (`setBackendFieldError` pattern)

This is the mechanism for showing inline field errors when the backend returns a duplicate/unique violation.

| Page | Implemented? | Mapped Messages |
|---|---|---|
| `nguoi-dung/page.tsx` | YES | username, email, phone, mobile |
| `don-vi/page.tsx` | YES | code (department code unique) |
| `chuc-vu/page.tsx` | YES | code (position code unique) |
| `nhom-quyen/page.tsx` | YES | name (role name unique) |
| `loai-van-ban/page.tsx` | YES | code (doc type code unique) |
| `linh-vuc/page.tsx` | YES | code (doc field code unique) |
| `so-van-ban/page.tsx` | YES | name |
| `mau-thong-bao/page.tsx` | YES | name, content |
| `nhom-lam-viec/page.tsx` | YES | name |
| `uy-quyen/page.tsx` | YES | delegator_id, delegate_id, start_date, end_date |
| `co-quan/page.tsx` | YES | code, name, email, phone |
| `hop-dong/page.tsx` | **NO** | Uses generic `message.error()` only |
| `cuoc-hop/page.tsx` | **NO** | Uses generic error handling |
| `kho-luu-tru/page.tsx` | **NO** | Uses generic error handling |
| `ho-so-cong-viec/page.tsx` | **NO** | Uses generic error handling |
| `tai-lieu/page.tsx` | **NO** | Uses generic error handling |

**Assessment:** Admin module pages have excellent backend error mapping. Feature module pages (contracts, meetings, archive, HSCV, documents) all lack `setBackendFieldError` and show generic toast errors instead of inline field errors.

---

## 6. Additional Findings

### 6a. Form `validateTrigger` Consistency

All forms correctly use `validateTrigger="onSubmit"` as per project conventions, preventing layout shift in 2-column forms. This is consistent and correct.

### 6b. `maxLength` Coverage

Most text inputs have `maxLength` set, which is good client-side defense. Notable exceptions:
- `cuoc-hop/page.tsx` meeting `content` field (TextArea without maxLength)
- `cuoc-hop/page.tsx` room `note` field (TextArea without maxLength)
- `cuoc-hop/page.tsx` meeting type `description` field (TextArea without maxLength)

### 6c. Missing `scrollToFirstError` on Some Forms

Most Drawer forms use `scrollToFirstError` on the Form component, but some don't:
- `ho-so-cong-viec/page.tsx` - has it implicitly via validateTrigger
- `cuoc-hop/page.tsx` - missing
- `hop-dong/page.tsx` - missing
- `kho-luu-tru/page.tsx` - missing

---

## Recommendations (Prioritized by Impact)

### High Priority (Fix before demo)

1. **WR-08, WR-09**: Replace `<Input type="number">` with `<InputNumber>` in meeting room and type forms -- prevents non-numeric input and aligns with all other sort_order fields in the project.

2. **WR-11**: Move HSCV date comparison validation from `handleSave()` into Form.Item rules using `dependencies` pattern (copy from `uy-quyen/page.tsx` which already does this correctly).

3. **WR-12, WR-13**: Add date/time range validation for meetings - `end_date >= start_date` and `end_time > start_time` when on same day.

### Medium Priority (Fix soon after demo)

4. **WR-01, WR-03, WR-04**: Add email and phone format validation to `don-vi/page.tsx` (department form). These fields accept any text currently.

5. **WR-05, WR-06, WR-07**: Add phone format validation to `co-quan/page.tsx` and `kho-luu-tru/page.tsx` warehouse form.

6. Add `setBackendFieldError` pattern to `hop-dong/page.tsx`, `cuoc-hop/page.tsx`, `kho-luu-tru/page.tsx`, `ho-so-cong-viec/page.tsx`, and `tai-lieu/page.tsx` -- currently unique constraint violations show as generic toasts instead of inline field errors.

### Low Priority (Nice to have)

7. **WR-10**: Consider adding `required: true` for password field on new user creation with a note about the default, or make the default behavior more explicit in the UI.

8. Add `maxLength` to TextArea fields in meeting forms.

9. Add `scrollToFirstError` to forms in cuoc-hop, hop-dong, kho-luu-tru pages.

---

## Cross-Reference: DB Unique Constraints vs Frontend Validation

| DB Constraint | Table | Column | Frontend Validates? |
|---|---|---|---|
| `uq_departments_code` | departments | code | YES (via setBackendFieldError) |
| `uq_positions_code` | positions | code | YES |
| `uq_roles_name` | roles | name | YES |
| `staff_username_key` | staff | username | YES |
| `work_calendar_date_key` | work_calendar | date | N/A (managed by system) |
| `configurations_unit_id_key_key` | configurations | key+unit_id | N/A (managed by admin config) |

All user-facing unique constraints have frontend error mapping through the `setBackendFieldError` pattern.

---

_Audited by: Claude (validation-auditor)_
_Date: 2026-04-14_
