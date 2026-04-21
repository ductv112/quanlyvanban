---
phase: 11-sign-flow-async-worker
plan: 08
subsystem: ui
tags: [frontend, hscv, detail-page, sign-flow, useSigning, ant-design, migration-complete]

requires:
  - phase: 11-06
    provides: useSigning hook + SignModal + renderSignModal (stable API)
  - phase: 11-01
    provides: attachments.is_ca / ca_date / signed_file_path columns
provides:
  - HSCV detail page (`/ho-so-cong-viec/[id]`) — nút Ký số + integration với SignModal
  - Hoàn tất migration MIG-05 (3/3 detail pages đã wire lên async sign flow)
  - attachmentType='handling' lần đầu tiên được sử dụng trong FE (Plan 11-06 đã khai báo type, Plan 11-08 là consumer đầu tiên)
affects: [12, 13]

tech-stack:
  added: []
  patterns:
    - "HSCV sign gate: canSignHandling = detail.signer_id === user.staffId && status ∈ {2,3}"
    - "PDF-only check via file_name.toLowerCase().endsWith('.pdf') — đồng nhất với gate ở backend fn_attachment_can_sign"
    - "UX gating pattern: client-side boolean chỉ để ẩn nút — backend ACL (Plan 11-01 SP) mới là authoritative"
    - "Placement pattern: hook call + flag derivation sau toolbarButtons, modal render ở cuối JSX tree — nhất quán với VB đi/VB dự thảo"

key-files:
  created: []
  modified:
    - e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/[id]/page.tsx

key-decisions:
  - "Giữ icon phong cách VB đi: SafetyOutlined cho nút Ký số (màu xanh #059669), CheckCircleOutlined cho Tag Đã ký số — consistent UX xuyên suốt 3 detail pages"
  - "canSignHandling dùng [2,3].includes(status) (Chờ trình ký / Đã trình ký) — plan spec; status=0 (Mới) + 1 (Đang xử lý) không được ký vì HSCV chưa sẵn sàng nghiệp vụ"
  - "Extend Attachment interface inline (is_ca/ca_date/signed_file_path) — không cần shared type vì mỗi detail page có Attachment riêng từ Plan 10"
  - "signLocation fallback: detail.unit_name || 'Lào Cai' — VB đi dùng drafting_unit_name, HSCV không có field tương đương nên dùng unit_name (đơn vị sở hữu HSCV)"
  - "Checkpoint human-verify auto-approved (workflow.auto_advance=true) — verification steps chi tiết documented bên dưới cho user test khi có provider credentials"
  - "Không touch pre-existing TS2322 (Modal size={800} line 2104) — git blame commit 99214219 từ 2026-04-14, không phải do Plan 11-08, ngoài scope"

patterns-established:
  - "Phase 11 migration pattern 3/3 complete — mỗi detail page chỉ cần: 1 import + 1 hook call + 1 flag derivation + 1 button + 1 renderSignModal(). Tổng ~50 dòng thay đổi tối thiểu"
  - "attachmentType discriminator coverage: 'outgoing' (VB đi) | 'drafting' (VB dự thảo) | 'handling' (HSCV). 'incoming' chưa có consumer — VB đến không ký nghiệp vụ"

requirements-completed: [MIG-05, SIGN-03]

duration: ~3min
completed: 2026-04-21
---

# Phase 11 Plan 08: HSCV Detail Page — Ký số Button Integration Summary

**Hoàn tất Phase 11 migration: HSCV detail page là detail page cuối cùng được wire vào async sign flow (SignModal + useSigning). 3/3 detail pages giờ đã dùng flow thật — kết thúc MIG-05.**

## Performance

- **Duration:** ~3 phút
- **Started:** 2026-04-21T11:22:38Z
- **Completed:** 2026-04-21T11:26:02Z
- **Tasks:** 2 (1 code + 1 checkpoint auto-approved)
- **Files modified:** 1
- **Lines changed:** +53 (insertions, no deletions — first-time integration)

## Accomplishments

- **HSCV detail page** (`/ho-so-cong-viec/[id]`) — lần đầu tiên có nút Ký số. Trước đây HSCV KHÔNG có mock OTP sign flow (khác VB đi/VB dự thảo) — Plan 11-08 là **first-time functionality**, không phải migration.
- **Visibility gate** hoạt động:
  - `canSignHandling = user là signer của HSCV + status ∈ {2,3}` — UI chỉ hiện cho người có quyền
  - `!att.is_ca` — file chưa ký mới hiện nút, file đã ký hiện Tag "Đã ký số"
  - `file_name.toLowerCase().endsWith('.pdf')` — chỉ PDF mới ký được
- **useSigning integration** đồng nhất với VB đi/VB dự thảo — reuse exact pattern, zero divergence
- **Badge "Đã ký số"** render với CheckCircleOutlined + Tag success khi `att.is_ca=true` — giống VB đi (line 452 trong VB đi page.tsx)
- **onSuccess refresh**: sau khi ký xong, hook fire `fetchAttachments()` → file list reload → nút Ký số biến mất, Tag Đã ký số xuất hiện

## Task Commits

1. **Task 1: Thêm nút Ký số + useSigning integration** — `74532af` (feat)
2. **Task 2: Checkpoint human-verify** — auto-approved (workflow.auto_advance=true, no commit)

## Variable Names Used (plan asked to document exact names)

Xác định bằng grep trước khi viết code để tránh field mismatch:

| Plan spec | Actual (in file) | Reason |
|-----------|------------------|--------|
| `docDetail` | `detail` | Existing var name trong HSCV page là `detail`, không phải `docDetail`. |
| `user?.staffId ?? user?.staff_id` | `user?.staffId` | Verified at line 1844 existing usage — chỉ có `staffId` (camelCase), không có `staff_id` fallback. Đơn giản hóa expression. |
| `docDetail.status` | `detail.status` | Match tên biến thực tế. |
| `docDetail.signer_id` | `detail.signer_id` | Field từ HscvDetail interface line 62. |
| `docDetail.name` | `detail.name` | Dùng cho `signReason: 'Phê duyệt HSCV: ${detail.name}'`. |

## Grep Verification (sau task)

```bash
# useSigning references — expect ≥ 3
$ grep -c "useSigning\|renderSignModal\|openSign" \
    e_office_app_new/frontend/src/app/\(main\)/ho-so-cong-viec/\[id\]/page.tsx
5   # ✓ PASS

# attachmentType='handling' — expect present
$ grep -n "attachmentType: 'handling'" \
    e_office_app_new/frontend/src/app/\(main\)/ho-so-cong-viec/\[id\]/page.tsx
1705:                          attachmentType: 'handling',   # ✓ PASS

# canSignHandling gate — expect present
$ grep -n "canSignHandling\|signer_id" \
    e_office_app_new/frontend/src/app/\(main\)/ho-so-cong-viec/\[id\]/page.tsx
62:  signer_id: number | null;
888:      signer_id: detail.signer_id,
1280:  const canSignHandling = Boolean(
1283:    detail.signer_id === user.staffId &&
1695:                  {canSignHandling &&
# ✓ PASS — gate present + signer_id comparison present
```

## TypeScript Status

- **Plan 11-08 changes**: 0 new TS errors introduced. Clean.
- **Pre-existing errors in HSCV page**: 1 error remaining — line 2104 `size={800}` trên Modal (Modal dùng `width` không phải `size` ở AntD 6). Git blame: commit `99214219` từ 2026-04-14, predates Phase 11. **Out of scope** per SCOPE BOUNDARY rule. Logged as deferred item for future cleanup phase (ghi chú: dùng `width={800}` thay vì `size={800}`).

## Checkpoint Auto-Approval (human-verify)

`workflow.auto_advance=true` — checkpoint auto-approved per GSD protocol. **Human verification deferred to user** — test paths documented chi tiết cho user thực hiện khi có provider credentials + HSCV test data sẵn sàng.

### Test Path 1 — Nút visibility (core UX logic)

1. **Login as HSCV signer** (user là `signer_id` của HSCV `X`). Navigate to `/ho-so-cong-viec/X` → tab "File đính kèm".
2. **Expected:**
   - File PDF có `is_ca=false` → **CÓ** nút Ký số (màu xanh #059669) + icon lá chắn
   - File PDF có `is_ca=true` → **HIỆN Tag** "Đã ký số" (màu xanh success) + icon check, KHÔNG có nút Ký số
   - File .docx/.xlsx/.png/... → **KHÔNG CÓ** nút Ký số (không phải PDF)
3. **Login as non-signer** (user khác). Navigate to cùng HSCV.
4. **Expected:** **KHÔNG CÓ** nút Ký số cho bất kỳ file nào (vì `signer_id !== user.staffId`).

### Test Path 2 — Status gate

1. HSCV có `status=0` (Mới tạo) — user là signer. Mở tab File đính kèm.
2. **Expected:** **KHÔNG CÓ** nút Ký số (vì status không thuộc [2,3]).
3. Cập nhật status lên `2` (Chờ trình ký) qua HSCV workflow. Refresh.
4. **Expected:** Nút Ký số **XUẤT HIỆN**.

### Test Path 3 — Sign flow end-to-end (cần provider thật hoặc mock worker)

1. Click nút Ký số trên file PDF.
2. **Expected:** SignModal mở < 1.5s, hiển thị:
   - `File: <file_name>`
   - `Nhà cung cấp: <SmartCA VNPT / MySign Viettel>` (tùy provider được admin config)
   - `Trạng thái: Đang chờ xác nhận OTP`
   - Alert "Mở ứng dụng trên điện thoại và xác nhận"
3. Trên mobile, confirm OTP (hoặc đợi mock worker callback).
4. **Expected trong 5-30s:** Modal đổi sang:
   - `Trạng thái: Đã ký` (Tag success)
   - Alert "Ký số thành công"
   - Auto-close sau ~1.2s
5. **Expected ngay sau khi modal đóng:** List file đính kèm refresh → file vừa ký:
   - KHÔNG còn nút Ký số
   - XUẤT HIỆN Tag "Đã ký số" (xanh)

### Test Path 4 — Cancel mid-flow

1. Click Ký số → modal opens, status=pending.
2. Click nút "Hủy ký số".
3. **Expected:** Modal đổi status=cancelled, message.info "Đã hủy giao dịch ký số".
4. **DB check:**
   ```sql
   SELECT id, status, attachment_type FROM edoc.sign_transactions
   WHERE attachment_type='handling' ORDER BY id DESC LIMIT 1;
   ```
   Expected: `status='cancelled'`, `attachment_type='handling'`.

### Test Path 5 — Close modal nền (async notification)

1. Start sign → modal shows pending.
2. Click "Đóng (chạy nền)" → modal unmount, txn vẫn chạy.
3. Confirm OTP trên mobile.
4. **Expected:** Bell icon (top-right) xuất hiện notification "Ký số thành công" (từ Plan 11-04 noticeRepository.createForStaff).
5. Navigate về HSCV page → tab đính kèm → file đã có Tag "Đã ký số" (dù user không đứng ở modal khi worker xong).

### Test Path 6 — Backend ACL enforcement (security check)

1. User KHÔNG phải signer — mở DevTools Network tab.
2. Manually craft POST request: `POST /api/ky-so/sign` với body `{ attachment_id: <HSCV attachment id>, attachment_type: 'handling', doc_id: <id> }`.
3. **Expected:** Backend trả 403 từ `fn_attachment_can_sign()` — **UI gate chỉ là UX, backend mới authoritative**. Mitigate T-11-25.

### Fallback (không có provider credentials)

Chỉ verify các path 1, 2, 4 — KHÔNG cần thực hiện path 3/5 khi không có provider thật. Hoặc dùng mock worker (backend env `SIGNING_MOCK_ENABLED=true` nếu có — hỏi admin).

## MIG-05 Status — HOÀN TẤT

| Detail Page | Before (Plan ≤ 1) | After Phase 11 |
|-------------|-------------------|----------------|
| VB đi `/van-ban-di/[id]` | Mock POST `/ky-so/mock/sign` (sync OTP) | ✅ Plan 11-07 — `/ky-so/sign` async |
| VB dự thảo `/van-ban-du-thao/[id]` | Mock POST `/ky-so/mock/sign` | ✅ Plan 11-07 — `/ky-so/sign` async |
| HSCV `/ho-so-cong-viec/[id]` | KHÔNG có nút Ký số (no mock) | ✅ Plan 11-08 — `/ky-so/sign` async (first-time) |
| Backend endpoint `/ky-so/mock/sign` | ACTIVE | ACTIVE (no FE consumer — backward compat) |

**MIG-05 2/3 → 3/3 → DONE.** Backend `/ky-so/mock/sign` có thể xóa trong Phase 13 cleanup (đã ghi nhận trong Plan 11-07 SUMMARY).

## Files Modified

### `e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/[id]/page.tsx`

**Changes (+53 lines, 0 deletions):**

1. **Line 37** — import `useSigning` hook (+1 line)
2. **Line 31** — add 3 icons (`SafetyOutlined`, `SafetyCertificateOutlined`, `CheckCircleOutlined`) vào existing `@ant-design/icons` import (+1 line)
3. **Lines 158-163** — mở rộng `Attachment` interface với 3 optional fields: `is_ca`, `ca_date`, `signed_file_path` (+3 lines)
4. **Lines 325-326** — `const { openSign, renderSignModal } = useSigning();` + comment (+3 lines)
5. **Lines 1280-1287** — derive `canSignHandling` boolean (+8 lines)
6. **Lines 1694-1723** — inject Ký số button + Đã ký số Tag vào `<Space>` attachment row (+30 lines)
7. **Lines 2209-2210** — `{renderSignModal()}` + comment ở cuối JSX (+3 lines)

**Net change:** +53 lines / 0 deletions. Không touch logic download/delete/upload — giữ nguyên pattern existing.

## Decisions Made

- **Không redesign attachment card** — chỉ inject button vào `<Space>` hiện có (giữ consistency với plan spec "DO NOT restructure attachment rendering").
- **Icon style match VB đi** — `SafetyOutlined` cho button + `CheckCircleOutlined` cho Tag Đã ký (giống VB đi line 452). **KHÔNG dùng `SafetyCertificateOutlined` cho button** dù plan gợi ý — dùng `SafetyOutlined` để 3 pages đồng nhất. `SafetyCertificateOutlined` được import nhưng có thể dùng trong future (ví dụ icon trên header khi status="signed").
- **`signLocation: detail.unit_name || 'Lào Cai'`** — HSCV không có `drafting_unit_name` như VB đi. Dùng `unit_name` (đơn vị sở hữu) làm fallback, mặc định "Lào Cai" để metadata PDF không null.
- **`signReason: 'Phê duyệt HSCV: ${detail.name}'`** — khác VB đi dùng số/notation; HSCV không có notation mà chỉ có `name` (tên hồ sơ), nên dùng name.
- **Status gate [2,3]** — chính xác như plan spec. Status=0 (Mới) + 1 (Đang xử lý) KHÔNG cho ký vì HSCV chưa ready; status=4 (Hoàn thành) + 5 (Tạm dừng) + -1/-2/-3 (từ chối/trả về/đã hủy) cũng không cho ký vì terminal states.
- **Auto-approved human-verify** — `workflow.auto_advance=true`. Test paths 1-6 documented chi tiết cho user test sau.

## Deviations from Plan

None substantive — plan executed gần như exactly as written. Chỉ có minor adaptations:

1. **Icon choice**: Plan gợi ý `SafetyCertificateOutlined` cho button nhưng dùng `SafetyOutlined` để match VB đi pattern (cùng UX xuyên suốt). Cả 2 icons đều import sẵn nên dễ đổi sau nếu cần.
2. **Variable name `detail` không phải `docDetail`**: Adapt theo code hiện có. Plan đã advise grep trước để confirm — đã làm.
3. **`user?.staffId` (không fallback `staff_id`)**: Grep xác nhận HSCV page chỉ dùng `staffId` (camelCase), không có `staff_id`. Đơn giản hóa expression bỏ fallback.

## Issues Encountered

- **Pre-existing TS2322 line 2104** (Modal `size={800}` — should be `width={800}`) — git blame `99214219` 2026-04-14, predates Phase 11. Out of scope. Deferred cleanup.
- **Không issue nào do Plan 11-08**. TypeScript 0 new errors.

## Phase 11 Completion Summary

Plan 11-08 là plan CUỐI CÙNG của Phase 11. Sau plan này:

- **8/8 plans** trong Phase 11 hoàn tất
- **MIG-05 DONE** — 3/3 detail pages migrated
- **SIGN-03 DONE** — shared SignModal + useSigning hook có consumer cả 3 detail pages
- **Phase 13 backlog** (deferred):
  - Xóa backend `/ky-so/mock/sign` endpoint (zero consumer)
  - Fix pre-existing TS2322 ở HSCV page line 2104 (`size={800}` → `width={800}`)
  - Fix pre-existing TS17001 ở VB đi page line 580-581 (duplicate `forceRender`)
  - UX polish: countdown timer 3:00 trong SignModal, Root CA banner cho MYSIGN_VIETTEL

## User Setup Required (cho production)

Không có setup mới cho Plan 11-08 — tất cả dependencies đã sẵn từ Phase 11 earlier plans:

- Plan 11-01 DB migration (attachments.is_ca columns) — DONE
- Plan 11-02 provider adapters — DONE
- Plan 11-03 REST endpoints POST /ky-so/sign + GET/:id + cancel — DONE
- Plan 11-04 Socket.IO emit — DONE
- Plan 11-05 worker polling — DONE
- Plan 11-06 SignModal + useSigning hook — DONE
- Plan 11-07 VB đi + VB dự thảo migration — DONE
- Plan 11-08 HSCV integration — THIS PLAN (DONE)

## Next Phase Readiness

- **Phase 12** hoặc tiếp theo: UX polish cho signing (countdown timer, provider branding, retry flow)
- **Phase 13 cleanup**: xóa `/ky-so/mock/sign`, fix 2 pre-existing TS errors
- **Deferred item**: integration test end-to-end sign flow (cần provider test credentials) — khi có credentials, chạy 6 test paths trên SUMMARY

## Self-Check: PASSED

- `e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/[id]/page.tsx` — FOUND (modified)
- Commit `74532af` (Task 1) — FOUND (verified via `git log`)
- Grep `useSigning\|renderSignModal\|openSign` — 5 matches (≥3 required) ✓
- Grep `attachmentType: 'handling'` — 1 match ✓
- Grep `canSignHandling` — 2 matches (1 declaration + 1 usage) ✓
- Grep `signer_id` — multiple matches including `detail.signer_id === user.staffId` gate ✓
- TypeScript: 0 new errors introduced by Plan 11-08 (1 pre-existing TS2322, documented out-of-scope)

---
*Phase: 11-sign-flow-async-worker — COMPLETE (8/8 plans)*
*Completed: 2026-04-21*
