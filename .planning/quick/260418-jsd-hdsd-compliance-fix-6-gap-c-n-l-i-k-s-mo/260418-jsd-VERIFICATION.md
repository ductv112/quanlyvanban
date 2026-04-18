---
phase: quick-260418-jsd
verified: 2026-04-18T15:30:00Z
status: human_needed
score: 32/32 must-haves verified
overrides_applied: 0
---

# Quick Task Verification Report — JSD HDSD Compliance (6 Gaps + Test Catalog)

**Task Goal:** Fix 6 gap HDSD (TC-011, 045, 046, 066, 067, 068) + regen test catalog từ 90.2% → 97.8% coverage
**Verified:** 2026-04-18T15:30:00Z
**Status:** human_needed — Automated checks passed 100% (32/32). Awaiting human UAT on UI flows.
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (grouped by Gap)

| #   | Gap | Truth                                                                                                                                 | Status     | Evidence                                                                                             |
| --- | --- | ------------------------------------------------------------------------------------------------------------------------------------- | ---------- | ---------------------------------------------------------------------------------------------------- |
| 1   | A   | SP `fn_attachment_outgoing_get_list` + `fn_attachment_drafting_get_list` trả 12 field (9 cũ + 3 mới is_ca/ca_date/signed_file_path)   | ✓ VERIFIED | DB `\df` 2 SP có đầy đủ 12 cột; smoke test `SELECT * FROM fn_attachment_outgoing_get_list(1)` chạy OK |
| 2   | A   | Backend AttachmentRow interface có 3 field mới optional                                                                               | ✓ VERIFIED | `incoming-doc.repository.ts:82-85` có `is_ca?`, `ca_date?`, `signed_file_path?` (reused bởi outgoing + drafting repos) |
| 3   | A   | Frontend VB đi `[id]/page.tsx` có nút "Ký số" + Modal OTP (Input.OTP length=6)                                                        | ✓ VERIFIED | `van-ban-di/[id]/page.tsx:487` button "Ký số", `:700` `Input.OTP length={6}`, `:274` POST `/ky-so/mock/sign` |
| 4   | A   | Frontend VB dự thảo `[id]/page.tsx` có nút "Ký số" + Modal OTP                                                                        | ✓ VERIFIED | `van-ban-du-thao/[id]/page.tsx:404` button, `:561` `Input.OTP length={6}`, `:179` POST `/ky-so/mock/sign` |
| 5   | B   | `edoc.lgsp_tracking.channel VARCHAR(20) DEFAULT 'lgsp' CHECK IN ('lgsp','cp')`                                                        | ✓ VERIFIED | DB `\d edoc.lgsp_tracking` show cột `channel` + CHECK constraint match                                |
| 6   | B   | SP `fn_lgsp_tracking_create` DROP/CREATE với param `p_channel` cuối cùng                                                              | ✓ VERIFIED | DB `\df` show 8 params trong đúng thứ tự kết thúc bằng `p_channel character varying DEFAULT 'lgsp'`   |
| 7   | B   | Backend route `POST /van-ban-di/:id/gui-truc-cp` tồn tại                                                                              | ✓ VERIFIED | `outgoing-doc.ts:734` handler; call repo `sendCp()`                                                   |
| 8   | B   | Frontend VB đi có button "Gửi trục CP" + Modal 5+ bộ/ngành                                                                            | ✓ VERIFIED | `van-ban-di/[id]/page.tsx:352` button (green), `:664` Modal "Gửi trục Chính phủ" with checkboxes      |
| 9   | B   | Call site `sendLgsp()` truyền `'lgsp'` ở param cuối (backward-compat)                                                                 | ✓ VERIFIED | `outgoing-doc.repository.ts:284` `[...,'lgsp']`; `sendCp()` `:291` `[...,'cp']`                       |
| 10  | C   | Backend 2 endpoint `GET /van-ban-di/:id/luu-tru/phong` + `/kho` (mirror pattern VB đến)                                               | ✓ VERIFIED | `outgoing-doc.ts:765-782` 2 routes dùng `resolveAncestorUnit` + `incomingDocRepository.getFonds/getWarehouses` |
| 11  | C   | Frontend VB đi có Drawer "Chuyển lưu trữ" size=640 + button + fetch dropdowns                                                         | ✓ VERIFIED | `van-ban-di/[id]/page.tsx:353` button, `:633-658` Drawer với 11 fields (mirror VB đến pattern) + defaults language='Tiếng Việt', format='Điện tử', is_original=true |
| 12  | D   | `edoc.handling_docs` có 3 cột cancel_reason/cancelled_at/cancelled_by                                                                 | ✓ VERIFIED | DB `\d edoc.handling_docs` show 3 cột thêm đúng type TEXT/TIMESTAMPTZ/INT                             |
| 13  | D   | SP `fn_handling_doc_cancel(p_id BIGINT, p_user_id INT, p_reason TEXT)`                                                                | ✓ VERIFIED | DB `\df` signature match; returns TABLE(success BOOLEAN, message TEXT)                                |
| 14  | D   | SP `fn_handling_doc_get_by_id` trả 33 field cũ + 3 cancel_* (tổng 36)                                                                 | ✓ VERIFIED | DB `\df` show 36 fields trong RETURNS TABLE, trailing cancel_reason/cancelled_at/cancelled_by          |
| 15  | D   | Backend route `POST /ho-so-cong-viec/:id/huy` với validation reason required                                                          | ✓ VERIFIED | `handling-doc.ts:693` handler; `reason` required (400 if empty)                                       |
| 16  | D   | Frontend HSCV detail button "Hủy HSCV" + Modal reason                                                                                 | ✓ VERIFIED | `ho-so-cong-viec/[id]/page.tsx:300` toolbar btn danger, `:786` handleCancel, `:1932` Modal.onOk handler |
| 17  | D   | Card "Đã hủy" hiển thị khi status=-3                                                                                                  | ✓ VERIFIED | `ho-so-cong-viec/[id]/page.tsx:1332-1338` conditional render with cancel_reason/cancelled_at/cancelled_by |
| 18  | E   | Endpoint `GET /api/ho-so-cong-viec/nhan-vien-cung-don-vi` middleware chỉ authenticate (KHÔNG requireRoles)                            | ✓ VERIFIED | `handling-doc.ts:18` route (TRƯỚC /:id routes); `server.ts:71` mount chỉ `authenticate`              |
| 19  | E   | `edoc.opinion_handling_docs` có 4 cột forward_*                                                                                       | ✓ VERIFIED | DB `\d` show forwarded_to_staff_id INT, forwarded_at TIMESTAMPTZ, forward_note TEXT, parent_opinion_id BIGINT REFERENCES self ON DELETE SET NULL |
| 20  | E   | SP `fn_opinion_forward(p_opinion_id BIGINT, p_from_staff_id INT, p_to_staff_id INT, p_note TEXT)`                                    | ✓ VERIFIED | DB `\df` signature match                                                                              |
| 21  | E   | SP `fn_opinion_get_list` giữ 6 field cũ + 5 forward_* (param vẫn `p_doc_id BIGINT`, staff_name TEXT)                                 | ✓ VERIFIED | DB `\df` show 11 fields; smoke test `SELECT * FROM fn_opinion_get_list(1)` trả row với cả forward fields |
| 22  | E   | Frontend opinion-item có nút "Chuyển tiếp" + Modal staff picker + thread indent                                                       | ✓ VERIFIED | `ho-so-cong-viec/[id]/page.tsx:1598` "Chuyển tiếp" button, `:1895` Modal "Chuyển tiếp ý kiến", `:1565` indent style with parent_opinion_id, `:1586` icon "↪" với forwarded_to_name |
| 23  | E   | Backend route `POST /:id/y-kien/:opinionId/chuyen-tiep`                                                                               | ✓ VERIFIED | `handling-doc.ts:622` handler                                                                         |
| 24  | F   | Table `edoc.handling_doc_history` tồn tại với 8 cột đúng signature                                                                    | ✓ VERIFIED | DB `\d` show id BIGSERIAL, handling_doc_id BIGINT, action_type VARCHAR(50), from_staff_id/to_staff_id INT, note TEXT, created_by INT, created_at TIMESTAMPTZ DEFAULT NOW() |
| 25  | F   | SP `fn_handling_doc_transfer(p_id BIGINT, p_from_staff_id INT, p_to_staff_id INT, p_note TEXT, p_by INT)`                            | ✓ VERIFIED | DB `\df` signature match                                                                              |
| 26  | F   | SP `fn_handling_doc_history_list(p_id BIGINT)` JOIN staff lấy name                                                                    | ✓ VERIFIED | DB `\df` show 11 fields bao gồm from_staff_name TEXT, to_staff_name TEXT, created_by_name TEXT        |
| 27  | F   | Backend route `POST /:id/chuyen-tiep` + `GET /:id/lich-su`                                                                            | ✓ VERIFIED | `handling-doc.ts:652, 678` 2 handlers                                                                 |
| 28  | F   | Frontend button "Chuyển tiếp HSCV" (curator_id/isAdmin) + Modal + tab Lịch sử                                                         | ✓ VERIFIED | `ho-so-cong-viec/[id]/page.tsx:239` transferBtn, `:1826` Modal "Chuyển tiếp hồ sơ công việc", `:1879` tab history với action_type render |
| 29  | 7   | `docs/test_theo_hdsd_cu.md` update 7 TCs (TC-011/045/046/066/067/068/070) status ✅                                                   | ✓ VERIFIED | Grep all 7 TCs có "✅ Pass" với note đúng Gap A-F + TC-070 dashboard gộp                              |
| 30  | 7   | TC-079 giữ "❌ Missing" với note "Defer Phase 2"                                                                                      | ✓ VERIFIED | `test_theo_hdsd_cu.md:106` "❌ Missing" + "Defer Phase 2 — cần schema permission model mới"          |
| 31  | 7   | `docs/test_theo_hdsd_cu.xlsx` tồn tại với modified time khớp .md                                                                      | ✓ VERIFIED | `ls -la` show cả 2 file mtime Apr 18 15:23, xlsx 16124 bytes                                          |
| 32  | 7   | Stats: ✅ 90, 🚫 1, ❌ 1 = 92 total (97.8%)                                                                                            | ✓ VERIFIED | Header lines `:17-22` show exact counts; grep TC-lines confirm 90 ✅, 1 🚫 (TC-069), 1 ❌ (TC-079)    |

**Score:** 32/32 truths verified

### Required Artifacts

| Artifact                                                                           | Expected                             | Status     | Details                                                     |
| ---------------------------------------------------------------------------------- | ------------------------------------ | ---------- | ----------------------------------------------------------- |
| `database/migrations/quick_260418_jsd_sign_otp.sql`                                | DROP/CREATE 2 SP attachment          | ✓ VERIFIED | File tồn tại + DB SP có 12 fields + `LEFT JOIN public.staff` |
| `database/migrations/quick_260418_jsd_truc_cp.sql`                                 | ALTER lgsp_tracking + DROP/CREATE SP | ✓ VERIFIED | DB col `channel` + SP signature match                        |
| `database/migrations/quick_260418_jsd_hscv_cancel.sql`                             | ALTER + CREATE 2 SP                  | ✓ VERIFIED | 3 cols + fn_handling_doc_cancel + fn_handling_doc_get_by_id 36 fields |
| `database/migrations/quick_260418_jsd_opinion_forward.sql`                         | ALTER 4 cols + CREATE 2 SP           | ✓ VERIFIED | DB match fully                                               |
| `database/migrations/quick_260418_jsd_hscv_transfer.sql`                           | CREATE table + 2 SP                  | ✓ VERIFIED | Table + FKs + 2 SP all present                               |
| `backend/src/repositories/outgoing-doc.repository.ts`                              | sendCp + sendLgsp với 8 params       | ✓ VERIFIED | Lines 283-293 both methods correct                           |
| `backend/src/repositories/drafting-doc.repository.ts`                              | Import AttachmentRow mới             | ✓ VERIFIED | Imports từ incoming-doc.repository with 3 new optional fields |
| `backend/src/repositories/handling-doc.repository.ts`                              | cancel, forwardOpinion, transfer, listStaffSameUnit, getHistory | ✓ VERIFIED | All 5 methods (lines 386, 398, 405, 425, 431)                |
| `backend/src/routes/outgoing-doc.ts`                                               | gui-truc-cp + luu-tru/phong + /kho + chuyen-luu-tru | ✓ VERIFIED | 4 endpoints mounted correctly                                |
| `backend/src/routes/handling-doc.ts`                                               | nhan-vien-cung-don-vi (top) + 4 new routes | ✓ VERIFIED | Mount order correct; `/nhan-vien-cung-don-vi` at line 18 TRƯỚC `/:id` |
| `frontend/src/app/(main)/van-ban-di/[id]/page.tsx`                                 | Ký số + Trục CP + Chuyển lưu trữ     | ✓ VERIFIED | 3 features all wired, modals + drawer                        |
| `frontend/src/app/(main)/van-ban-du-thao/[id]/page.tsx`                            | Ký số OTP                            | ✓ VERIFIED | Button + Modal + API call present                            |
| `frontend/src/app/(main)/ho-so-cong-viec/[id]/page.tsx`                            | Hủy + Chuyển tiếp ý kiến + Chuyển tiếp HSCV + Lịch sử | ✓ VERIFIED | All 4 features wired with Modal + history tab |
| `docs/test_theo_hdsd_cu.md`                                                        | Regen với 7 TCs update              | ✓ VERIFIED | Stats 90✅/1🚫/1❌; 7 TCs status match                       |
| `docs/test_theo_hdsd_cu.xlsx`                                                      | Regen khớp .md                       | ✓ VERIFIED | File present, modified 15:23                                 |

### Key Link Verification

| From                                                         | To                                                                | Via            | Status    | Details                                                                                       |
| ------------------------------------------------------------ | ----------------------------------------------------------------- | -------------- | --------- | --------------------------------------------------------------------------------------------- |
| FE van-ban-di + van-ban-du-thao `[id]/page.tsx`              | `/api/ky-so/mock/sign`                                            | axios POST     | ✓ WIRED   | `{attachment_id, attachment_type}` body; handler reloads detail/attachments                   |
| SP `fn_attachment_{outgoing,drafting}_get_list`              | `attachment_*_docs.is_ca, ca_date, signed_file_path` + JOIN staff | SELECT bổ sung | ✓ WIRED   | DB `pg_get_functiondef` body confirm JOIN + 3 new cols                                        |
| FE van-ban-di `[id]/page.tsx`                                | `/api/van-ban-di/:id/gui-truc-cp`                                 | axios POST     | ✓ WIRED   | Line 252 axios call; Line 734 backend handler                                                 |
| BE `routes/outgoing-doc.ts` sendCp                           | `fn_lgsp_tracking_create(..., 'cp')`                              | callFunctionOne | ✓ WIRED   | `outgoing-doc.repository.ts:291` last param `'cp'`                                            |
| FE van-ban-di `[id]/page.tsx` Drawer                         | `/chuyen-luu-tru` + `/luu-tru/phong` + `/luu-tru/kho`             | axios GET+POST | ✓ WIRED   | Line 232 POST; backend `/luu-tru/phong` L765, `/kho` L774, `/chuyen-luu-tru` L790            |
| FE ho-so-cong-viec `[id]/page.tsx`                           | `/api/ho-so-cong-viec/:id/huy`                                    | axios POST     | ✓ WIRED   | `handleCancel` L786 → POST → fetch reload                                                     |
| SP `fn_handling_doc_cancel`                                  | UPDATE status=-3 + 3 cancel cols                                  | UPDATE         | ✓ WIRED   | Frontend render cancel card when status=-3                                                    |
| FE opinion-item                                              | `/api/ho-so-cong-viec/:id/y-kien/:opinionId/chuyen-tiep`          | axios POST     | ✓ WIRED   | Modal → POST → reload opinions (line ~720-734)                                                |
| FE Modal staff picker                                        | `/api/ho-so-cong-viec/nhan-vien-cung-don-vi`                      | axios GET      | ✓ WIRED   | Line 698 `api.get('/ho-so-cong-viec/nhan-vien-cung-don-vi')` — NO admin check                 |
| SP `fn_opinion_forward`                                      | INSERT row với parent_opinion_id                                  | INSERT         | ✓ WIRED   | DB smoke: SP accepts 4 params + returns id                                                    |
| FE ho-so-cong-viec `[id]/page.tsx`                           | `/api/ho-so-cong-viec/:id/chuyen-tiep` + `/lich-su`               | axios POST/GET | ✓ WIRED   | BE routes L652, L678 both exist + handlers complete                                           |
| SP `fn_handling_doc_transfer`                                | UPDATE curator + INSERT history                                   | UPDATE+INSERT  | ✓ WIRED   | handling_doc_history table FK cascade + SP body calls both ops                                |

### Data-Flow Trace (Level 4)

| Artifact                                              | Data Variable          | Source                                            | Produces Real Data | Status      |
| ----------------------------------------------------- | ---------------------- | ------------------------------------------------- | ------------------ | ----------- |
| `attachmentsTable` (van-ban-di detail)                | `attachments[]`        | `GET /van-ban-di/:id/attachments` (SP 12 fields)  | Yes                | ✓ FLOWING   |
| Opinion list with forward threading                   | `opinions[]`           | `fn_opinion_get_list` (SP 11 fields incl forward) | Yes (smoke row tested) | ✓ FLOWING |
| History tab HSCV                                      | `history[]`            | `fn_handling_doc_history_list` (empty OK in test DB) | SP ready; empty if no transfers yet | ✓ FLOWING |
| Cancel card status=-3                                 | `detail.cancel_reason` | `fn_handling_doc_get_by_id` (36 fields)           | Yes (real UPDATE)  | ✓ FLOWING   |
| Trục CP modal                                         | `org list (hardcode)`  | Hardcoded 5+ bộ/ngành in FE                       | Yes (static OK)    | ✓ FLOWING   |
| Chuyển lưu trữ dropdowns                              | `fondOptions, warehouseOptions` | `/luu-tru/phong`+`/kho` → `incomingDocRepository.getFonds/getWarehouses` | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior                                   | Command                                                                      | Result                           | Status |
| ------------------------------------------ | ---------------------------------------------------------------------------- | -------------------------------- | ------ |
| SP fn_attachment_outgoing_get_list runs    | `psql -c "SELECT * FROM edoc.fn_attachment_outgoing_get_list(1) LIMIT 1"`    | 12 columns returned (0 rows OK)  | ✓ PASS |
| SP fn_opinion_get_list runs with forward   | `psql -c "SELECT * FROM edoc.fn_opinion_get_list(1) LIMIT 1"`                | 11 columns + 1 row returned      | ✓ PASS |
| SP fn_handling_doc_history_list runs       | `psql -c "SELECT * FROM edoc.fn_handling_doc_history_list(1) LIMIT 1"`       | 11 columns (empty set OK)        | ✓ PASS |
| SP fn_attachment_mock_sign exists          | `SELECT EXISTS FROM pg_proc WHERE proname='fn_attachment_mock_sign'`        | t                                | ✓ PASS |
| Migration files all present                | `ls database/migrations/quick_260418_jsd_*.sql`                              | 5 files                          | ✓ PASS |

### Anti-Patterns Found

| File                                         | Line | Pattern                                                           | Severity | Impact                                                  |
| -------------------------------------------- | ---- | ----------------------------------------------------------------- | -------- | ------------------------------------------------------- |
| `backend/src/routes/outgoing-doc.ts`         | 733  | `TODO Phase 2: tích hợp trục CP thực — hiện chỉ mock log tracking` | ℹ️ Info  | Intentional mock per plan (HDSD-II.3.8), không phải stub |
| `docs/test_theo_hdsd_cu.md`                  | 38   | Note: "TODO tích hợp VNPT SmartCA SDK thực ở Phase 2"             | ℹ️ Info  | Intentional Phase 2 deferred — SmartCA SDK integration  |
| `docs/test_theo_hdsd_cu.md`                  | 72   | Note: "TODO tích hợp thực Phase 2"                                | ℹ️ Info  | Trục CP mock intentional                                |

**No blocker anti-patterns found.** All TODOs are intentional Phase 2 placeholders aligned with HDSD plan.

### Human Verification Required

Automated checks cover: DB schema, SP signatures, repository imports, API route wiring, FE component existence, state wiring. These do NOT exercise UX flow. Please verify manually:

#### 1. Ký số OTP flow VB đi (TC-011)

**Test:** Login VB đi detail của VB có attachment → bấm "Ký số" trên 1 file
**Expected:** Modal OTP mở với label "Nhập mã OTP (6 chữ số) gửi tới số ĐT SmartCA 84xxx\*\*\*xxx"; nhập 6 digits bất kỳ → bấm "Xác nhận ký" → success message → attachment reload với Tag "Đã ký số"
**Why human:** UX (visual modal, OTP input interaction, tag rerender) không verify được bằng grep

#### 2. Ký số OTP flow VB dự thảo (TC-011)

**Test:** Login VB dự thảo detail → bấm "Ký số" → nhập OTP
**Expected:** Same as #1
**Why human:** UX (Modal + OTP + tag) — real-time

#### 3. Gửi trục CP (TC-045)

**Test:** VB đi approved=true → bấm "Gửi trục CP" (button xanh lá) → Modal "Gửi trục Chính phủ" mở
**Expected:** Checkbox list hardcode 5+ bộ/ngành (Văn phòng CP, Bộ Nội vụ, Bộ Tài chính, Bộ Tư pháp, Bộ GDĐT); chọn ít nhất 1 → bấm "Gửi" → success → DB row `lgsp_tracking` mới với `channel='cp'`
**Why human:** Visual modal layout, checkbox interaction, DB row inspection post-action

#### 4. Chuyển lưu trữ VB đi (TC-046)

**Test:** VB đi (approved=true, !archive_status) → bấm "Chuyển lưu trữ" → Drawer size=640 mở
**Expected:** Dropdown Kho + Phông load data; fields ordinal/language (default 'Tiếng Việt')/format (default 'Điện tử')/autograph/keyword/confidence_level/is_original (default true); Save thành công → Tag "Đã lưu trữ"
**Why human:** Visual + dropdown population + default values

#### 5. Hủy HSCV (TC-066)

**Test:** HSCV status=-1 hoặc -2 (bị từ chối / khôi phục) → bấm "Hủy HSCV" (đỏ) → Modal nhập lý do
**Expected:** Reason required (không bỏ trống); Confirm → status=-3; card "Đã hủy" hiển thị với reason + cancelled_at + cancelled_by name
**Why human:** Conditional render + status transition

#### 6. Chuyển tiếp ý kiến HSCV (TC-067)

**Test:** HSCV đang xử lý, tab "Ý kiến xử lý", hover row opinion → bấm icon "Chuyển tiếp"
**Expected:** Modal Select staff (load từ `/nhan-vien-cung-don-vi`) + TextArea note; submit → reload → child opinion hiện indent 24px + icon "↪" + label "Chuyển tiếp cho {name}"
**Why human:** Thread indentation + icon visual + staff picker UI

#### 7. Chuyển tiếp HSCV ownership (TC-068)

**Test:** HSCV status 0-3, user === curator (hoặc admin) → bấm "Chuyển tiếp HSCV" toolbar
**Expected:** Modal chọn staff cùng đơn vị + note → confirm → curator update → tab "Lịch sử" hiện row transfer với from→to
**Why human:** Permission check (curator OR admin) + history tab render

#### 8. Backward-compat LGSP gửi liên thông (không regression)

**Test:** VB đi approved=true → bấm "Gửi liên thông" (nút cũ, xanh dương) → chọn đơn vị
**Expected:** Gửi thành công → DB row `lgsp_tracking` có `channel='lgsp'` (default, không phải 'cp')
**Why human:** Ensure old flow still works (backward-compat truth)

### Gaps Summary

**Không có gap nào.** Tất cả 32 must-haves đã VERIFIED ở cấp DB/repo/route/page. Data flow từ SP → repo → route → FE đều wired đúng.

6 gap HDSD (Gap A/B/C/D/E/F) + Task 7 regen catalog đều đạt:

- **DB layer:** 5 migration SQL chạy thành công vào DB; 7 SPs tạo mới hoặc DROP/CREATE đúng signature; 4 tables/columns added with FK constraints + CHECK constraints.
- **Backend layer:** 10 routes mới (gui-truc-cp, luu-tru/phong, luu-tru/kho, chuyen-luu-tru, /:id/huy, /nhan-vien-cung-don-vi, /:id/y-kien/:opinionId/chuyen-tiep, /:id/chuyen-tiep, /:id/lich-su); 6 repository methods mới (sendCp, cancel, forwardOpinion, listStaffSameUnit, transfer, getHistory).
- **Frontend layer:** 3 pages update (van-ban-di/[id], van-ban-du-thao/[id], ho-so-cong-viec/[id]); 7 Modals mới (Ký số OTP ×2, Trục CP, Hủy, Chuyển tiếp ý kiến, Chuyển tiếp HSCV); 1 Drawer mới (Chuyển lưu trữ VB đi); 1 tab mới (Lịch sử HSCV).
- **Critical rules compliance:** All BIGSERIAL tables dùng `p_id BIGINT` params; staff picker endpoint mount TRƯỚC `/:id/...`; Modal vẫn dùng `width`, Drawer đổi sang `size={640}`; reserved words không bị hit (channel/action_type không reserved).
- **Backward-compat:** `sendLgsp()` truyền 'lgsp' ở param cuối để không break LGSP hiện có (verified repo line 284).
- **Test catalog:** 7 TCs update đúng, TC-079 giữ ❌ với note Phase 2 defer; stats 90✅/1🚫/1❌ = 97.8% khớp target.

Automated verification cho thấy tất cả artifact tồn tại, có substance, được wire đúng, và data flow chạy được. Tuy nhiên UX flow (Modal interaction, thread indentation visual, status transition feedback) cần human UAT trước demo 2026-04-18/19. Không có pre-existing TS errors nào mới phát sinh từ các thay đổi này.

---

_Verified: 2026-04-18T15:30:00Z_
_Verifier: Claude (gsd-verifier)_
