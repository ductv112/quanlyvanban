---
phase: 11-sign-flow-async-worker
plan: 07
subsystem: ui
tags: [frontend, migration, replace-mock, detail-page, sign-flow, useSigning, ant-design]

requires:
  - phase: 11-06
    provides: useSigning hook + SignModal component + renderSignModal
provides:
  - VB đi detail page (outgoing) migrated sang real async sign flow (useSigning hook)
  - VB dự thảo detail page (drafting) migrated sang real async sign flow (useSigning hook)
affects: [11-08, 11-09]

tech-stack:
  added: []
  patterns:
    - "Detail page migration pattern: remove local sign state → import useSigning → replace button onClick với openSign({ attachment, attachmentType, docId, signReason, signLocation, onSuccess }) → render {renderSignModal()} at JSX end"
    - "attachmentType discriminator per-page: 'outgoing' cho VB đi, 'drafting' cho VB dự thảo — dùng cho backend Plan 11-03 canSign ACL routing"
    - "signReason/signLocation metadata embed vào PDF placeholder: '<loại VB> số <number>/<notation>' + 'drafting_unit_name || Lào Cai'"

key-files:
  created: []
  modified:
    - e_office_app_new/frontend/src/app/(main)/van-ban-di/[id]/page.tsx
    - e_office_app_new/frontend/src/app/(main)/van-ban-du-thao/[id]/page.tsx

key-decisions:
  - "Không xóa maskPhone helper dù không còn dùng — plan explicitly marks removal optional; giữ để tránh scope creep"
  - "Giữ import Input từ antd dù Input.OTP không còn dùng — Input vẫn được dùng ở các Modal/form khác trong cùng file"
  - "Không touch pre-existing bug TS17001 (duplicate forceRender attribute trên Drawer Giao việc line 580-581 VB đi) — out of scope, introduced ở commit a54be0f từ trước"
  - "Checkpoint human-verify auto-approved vì workflow.auto_advance=true — verification steps documented trong SUMMARY để user test sau"

patterns-established:
  - "Breaking change migration pattern: POST /ky-so/mock/sign (synchronous OTP mock) → POST /ky-so/sign (async transaction via useSigning hook). Old endpoint giữ trong backend cho backward compat nhưng không còn consumer nào trong FE."
  - "Detail page integrating hook-based modals: single line import + single line hook call + single line render — tối thiểu surface thay đổi trên consumer side (KHÔNG phải tự quản transaction state)"

requirements-completed: [MIG-05]

duration: ~4min
completed: 2026-04-21
---

# Phase 11 Plan 07: Migrate VB đi + VB dự thảo Detail Pages Summary

**Pure migration plan — remove mock OTP sign flow khỏi 2 detail pages và wire up useSigning hook + SignModal (Plan 11-06). Breaking change /ky-so/mock/sign → /ky-so/sign hoàn tất cho 2 trên 3 detail pages (HSCV pending Plan 11-09).**

## Performance

- **Duration:** ~4 phút
- **Started:** 2026-04-21T11:15:26Z
- **Completed:** 2026-04-21T11:19:25Z
- **Tasks:** 3 (2 code + 1 checkpoint)
- **Files modified:** 2
- **Lines changed:** -108 / +26 (net -82 — dead code removal win)

## Accomplishments

- **VB đi detail page** (`/van-ban-di/[id]`) — removed 4 state hooks (otpOpen, otpValue, signing, targetAttachment) + 29-line handleSignOtp handler + 18-line OTP Modal block. Thay bằng 1 import + 1 hook call + 1 `{renderSignModal()}`. Button "Ký số" giờ opens SignModal qua openSign({ ..., attachmentType: 'outgoing', ... }).
- **VB dự thảo detail page** (`/van-ban-du-thao/[id]`) — same pattern với `attachmentType: 'drafting'`. Logic identical đến VB đi, chỉ khác discriminator + signReason prefix.
- **is_ca badge rendering unchanged** — `{att.is_ca ? <Tag>Đã ký số</Tag> : <Button>Ký số</Button>}` logic giữ nguyên, zero regression khi file đã ký.
- **signReason/signLocation metadata propagation** — mỗi page gửi context phù hợp cho PDF placeholder signature: "Phê duyệt VB đi số N/notation" hoặc "Phê duyệt VB dự thảo số N/notation", location fallback "Lào Cai" nếu drafting_unit_name null.

## Task Commits

1. **Task 1: Migrate VB đi detail** — `bd7023f` (refactor)
2. **Task 2: Migrate VB dự thảo detail** — `bce6d15` (refactor)
3. **Task 3: Checkpoint human-verify** — auto-approved (no commit, workflow.auto_advance=true)

## Grep Verification (after migration)

```bash
# VB đi detail — mock references: ZERO matches
$ grep -n "ky-so/mock\|otpOpen\|handleSignOtp\|targetAttachment\|setOtpValue\|setOtpOpen\|otpValue" \
    e_office_app_new/frontend/src/app/\(main\)/van-ban-di/\[id\]/page.tsx
# (no output)

# VB đi detail — useSigning references: PRESENT
$ grep -n "useSigning\|renderSignModal\|openSign" \
    e_office_app_new/frontend/src/app/\(main\)/van-ban-di/\[id\]/page.tsx
22:import { useSigning } from '@/hooks/use-signing';
127:  // Ký số — sử dụng useSigning hook (Plan 11-06, thay thế mock OTP Plan 1)
128:  const { openSign, renderSignModal } = useSigning();
454:                        <Button ... onClick={() => openSign({
659:      {/* Sign modal từ useSigning hook ... */}
660:      {renderSignModal()}

# VB dự thảo detail — mock references: ZERO matches
# VB dự thảo detail — useSigning + attachmentType='drafting': PRESENT
$ grep -n "attachmentType: 'drafting'" \
    e_office_app_new/frontend/src/app/\(main\)/van-ban-du-thao/\[id\]/page.tsx
373:                          attachmentType: 'drafting',
```

## TypeScript Status

- **VB đi detail** (`page.tsx`): 1 error REMAINING — TS17001 duplicate `forceRender` attribute on Drawer Giao việc (line 581). **PRE-EXISTING** (commit `a54be0f` "fix: thêm forceRender cho tất cả Drawer có Form"), NOT introduced by Plan 11-07. Out of scope per SCOPE BOUNDARY rule (`deferred-items.md` trackable).
- **VB dự thảo detail** (`page.tsx`): 0 errors from this migration. Clean.

## Checkpoint Auto-Approval (human-verify)

`workflow.auto_advance=true` configured — checkpoint auto-approved per GSD protocol. Human verification (E2E flow testing) **deferred to user** since this requires:
- Backend running with signing worker
- Admin-configured provider (MySign Viettel hoặc SmartCA mock)
- User với verified `/ky-so/tai-khoan` badge
- Test PDF attachment

**Verification steps user can run when provider credentials available:**

### Test path 1 — VB đi success
1. Navigate to `/van-ban-di/[id]` với PDF attachment
2. Click "Ký số" button on attachment row
3. Expect: Modal opens < 1.5s, shows "Đang chờ xác nhận OTP" + provider name
4. On mobile (SmartCA/MySign), confirm OTP
5. Expect within 5-30s: Modal flips to "Ký số thành công" + attachment list refreshes với "Đã ký số" tag

### Test path 2 — VB đi cancel
1. Open modal như path 1, click "Hủy ký số" button
2. Expect: Modal shows "Đã hủy giao dịch"
3. DB check: `SELECT status FROM edoc.sign_transactions ORDER BY id DESC LIMIT 1;` → 'cancelled'

### Test path 3 — VB dự thảo
Same as path 1 trên `/van-ban-du-thao/[id]`

### Test path 4 — close browser mid-flow
1. Start sign, see "Đang chờ xác nhận OTP"
2. Close browser tab
3. Confirm OTP on mobile
4. Re-login to web
5. Expect: Bell icon shows "Ký số thành công" notification (Phase 11-04 noticeRepository.createForStaff)

### If no real provider
Just verify:
- Modal opens với valid transaction_id
- POST /api/ky-so/sign returns 201 < 1500ms
- GET /api/ky-so/sign/:id returns status 'pending'
- Cancel works (DB status → 'cancelled')

## Files Modified

### `e_office_app_new/frontend/src/app/(main)/van-ban-di/[id]/page.tsx`

**Removed (81 lines total):**
- Line 22: new import `useSigning from '@/hooks/use-signing'` (ADD, +1)
- Lines 127-130: 4 state hooks (otpOpen, otpValue, signing, targetAttachment) — REMOVE 4 lines
- Lines 264-292: handleSignOtp function — REMOVE 29 lines
- Lines 486-488: button onClick handler (inline setState) — REMOVE 1 complex line
- Lines 684-701: OTP Modal JSX block — REMOVE 18 lines

**Added (13 lines total):**
- Import line (+1)
- `const { openSign, renderSignModal } = useSigning();` (+2 lines incl comment)
- openSign({ ... }) args inline on button (+7 lines)
- `{renderSignModal()}` + comment (+2 lines)

**Net change:** -54 / +13 lines

### `e_office_app_new/frontend/src/app/(main)/van-ban-du-thao/[id]/page.tsx`

Same pattern — net -54 / +13 lines. Only difference: `attachmentType: 'drafting'` thay vì 'outgoing'.

## Decisions Made

- **Không xóa maskPhone helper** — dead code sau migration (previously used trong OTP Modal). Plan 07 action explicitly marked removal optional (`"maskPhone helper (still used by other places... actually verify grep — if no longer used, optionally remove but not required)"`). Giữ để tránh scope creep.
- **Pre-existing TS17001 duplicate forceRender** — NOT touched. Bug tồn tại từ commit a54be0f ("fix: thêm forceRender cho tất cả Drawer có Form — fix useForm warning"). Out of scope per SCOPE BOUNDARY rule. Should be fixed in separate ticket/phase.
- **Auto-approved human-verify checkpoint** — workflow.auto_advance=true. Logged verification steps trong SUMMARY để user test sau khi provider credentials available.
- **attachmentType discriminator per-page** — 'outgoing' cho VB đi, 'drafting' cho VB dự thảo. Backend Plan 11-03 canSign() dùng discriminator này để route ACL check (fn_outgoing_doc_can_sign vs fn_drafting_doc_can_sign).

## Deviations from Plan

None — plan executed exactly as written. Both tasks followed step-by-step instructions. Pre-existing TS17001 duplicate `forceRender` is NOT my change (git blame confirms commit a54be0f).

## Issues Encountered

- **Pre-existing TS17001** trong VB đi page.tsx line 581 — duplicate `forceRender` attribute trên Drawer Giao việc. Git blame: commit `a54be0f`. Out of scope Plan 11-07. Logged as deferred item for future cleanup phase.
- **maskPhone helper orphaned** — technically dead code sau migration (no more callers). Plan explicitly marks removal as optional. Kept untouched.

## Breaking Change Status (MIG-05)

| Component | Old (before Plan 07) | New (after Plan 07) |
|-----------|----------------------|---------------------|
| VB đi detail (`/van-ban-di/[id]`) | POST `/ky-so/mock/sign` (synchronous mock OTP) | POST `/ky-so/sign` + GET/:id polling + Socket.IO fast-path (via useSigning) |
| VB dự thảo detail (`/van-ban-du-thao/[id]`) | POST `/ky-so/mock/sign` (synchronous mock OTP) | POST `/ky-so/sign` (via useSigning) |
| HSCV handling detail | POST `/ky-so/mock/sign` | **Pending Plan 11-09** |
| Backend endpoint `/ky-so/mock/sign` | ACTIVE (used by FE) | ACTIVE (no FE consumer, backward compat only) |

MIG-05 requirement **2/3 migrated** — HSCV remaining. After Plan 11-09, `/ky-so/mock/sign` can be safely deleted trong Phase 13 cleanup.

## Next Phase Readiness

- **Plan 11-08** (VB dự thảo was in scope Plan 11-07 — COMPLETED HERE together với VB đi)
- **Plan 11-09** (HSCV/handling-doc detail page migration với `attachmentType: 'handling'`) — mirror pattern, use same openSign() signature
- **Phase 13 cleanup candidates** (out of scope):
  - Remove `maskPhone` helper from 2 detail pages (dead code)
  - Fix TS17001 duplicate `forceRender` trên Drawer Giao việc (line 580-581 VB đi)
  - Delete backend `/ky-so/mock/sign` endpoint sau khi Plan 11-09 xong
- **User verification** — khi có provider credentials, chạy 5 test paths documented trong SUMMARY section "Checkpoint Auto-Approval"

## Self-Check: PASSED

- `e_office_app_new/frontend/src/app/(main)/van-ban-di/[id]/page.tsx` — FOUND (modified)
- `e_office_app_new/frontend/src/app/(main)/van-ban-du-thao/[id]/page.tsx` — FOUND (modified)
- Commit `bd7023f` (Task 1 VB đi migration) — FOUND
- Commit `bce6d15` (Task 2 VB dự thảo migration) — FOUND
- Grep mock references in both files — ZERO matches (verified)
- Grep useSigning/renderSignModal in both files — PRESENT (verified)
- TypeScript: 0 new errors introduced by Plan 11-07 (1 pre-existing TS17001 in VB đi file, from commit a54be0f — documented as out-of-scope)

---
*Phase: 11-sign-flow-async-worker*
*Completed: 2026-04-21*
