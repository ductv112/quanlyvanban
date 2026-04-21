---
phase: 10-user-config-page
plan: 02
subsystem: frontend
tags: [signing, user-config, frontend, antd, sidebar, wave-2, ui, cfg-05, cfg-06]

# Dependency graph
requires:
  - phase: 10-01
    provides: 4 user-level endpoints /api/ky-so/tai-khoan* (GET/POST/certificates/verify)
  - phase: 09-03
    provides: Sidebar group KÝ SỐ (admin-only) pattern + SafetyCertificateOutlined icon import
provides:
  - User config page /ky-so/tai-khoan với form dynamic theo provider active (SmartCA 1 field / MySign 2 field + Tải CTS)
  - Sidebar submenu "Tài khoản ký số cá nhân" visible cho MỌI user
  - Verify flow với badge "Đã xác thực" + cert subject/serial display
affects:
  - Phase 10 Plan 03 (Remove tab chữ ký số cũ) — consume URL mới làm Alert pointer target
  - Phase 11 (Sign flow) — user cần is_verified=true trước khi ký thật

# Tech tracking
tech-stack:
  added: []  # Zero new deps — reuse AntD 6 Form/Alert/Tag + api axios instance
  patterns:
    - "Form-mount guard pattern: setFieldsValue chỉ chạy khi Form đã render (active + config đều tồn tại) + setTimeout(0) defer tới sau render — tránh AntD warning 'useForm not connected to any Form element'"
    - "Group sidebar split pattern: push group header unconditionally cho mọi user, nhưng submenu bên trong admin-only wrap trong if (isAdmin) — group visible cho mọi user vì có ≥1 submenu visible"
    - "Provider-UX metadata map: PROVIDER_UX Record keyed by provider_code cho label/tooltip/placeholder dynamic — 1 component render cả 2 provider qua data-driven UI"
    - "Dynamic form with needsCertList flag: MySign bật Select credential_id + button 'Tải CTS'; SmartCA ẩn → 1 field form simpler"
    - "Soft-failure verify pattern: response 200 {verified: false} hiển thị warning toast + refetch config để show last_error; KHÔNG throw error"
    - "Label-over-action pattern: 'Xác thực tài khoản ký số' thay cho 'Kiểm tra kết nối' — mô tả chính xác action gọi API fetch user cert thay vì test TCP connection"

key-files:
  created:
    - e_office_app_new/frontend/src/app/(main)/ky-so/tai-khoan/page.tsx
    - .planning/phases/10-user-config-page/10-02-SUMMARY.md
  modified:
    - e_office_app_new/frontend/src/components/layout/MainLayout.tsx

key-decisions:
  - "AntD 6 API compliance: Alert dùng title/description thay vì message/description (message đã deprecated)"
  - "Form-mount guard via setTimeout(0): tránh warning 'useForm not connected to any Form element' khi Form unmount trong empty-state (active=null) mà setFieldsValue gọi sau fetch"
  - "Label 'Xác thực tài khoản ký số' thay vì 'Kiểm tra kết nối': action thực chất là verify mã định danh qua API provider (fetch cert list + match credential_id), không phải test TCP/HTTPS connection đơn thuần — tên mới mô tả chính xác kết quả (badge 'Đã xác thực')"
  - "Group sidebar KÝ SỐ visible cho mọi user (không chỉ admin): trước đây toàn bộ group wrapped trong if (isAdmin). Phase 10 plan 02 restructure — push group header unconditionally, chỉ wrap submenu 'Cấu hình hệ thống' trong if (isAdmin). Submenu 'Tài khoản cá nhân' hiển thị cho mọi user."
  - "fetchConfig gọi lại sau verify dù verified=true/false: giúp UI sync lại last_verified_at + last_error persist từ backend (BE lưu snapshot sau verify thành công)"
  - "Skeleton skeleton active paragraph={{rows: 6}} cho user=null guard: consistent loading state với các trang khác (KHÔNG Spin full-page theo CLAUDE.md)"
  - "POST /certificates KHÔNG gọi staffId từ store: user_id lấy trực tiếp từ Form input (user có thể test với user_id khác trước khi commit save)"

patterns-established:
  - "Pattern: Dynamic form theo provider_code active — metadata map + conditional rendering; scale tốt khi thêm provider thứ 3 (chỉ add entry vào PROVIDER_UX map)"
  - "Pattern: setBackendFieldError tiếng Việt cho CRUD user — map backend message → inline field error; fallback toast cho error không map được"
  - "Pattern: Soft-failure HTTP 200 parse — response.data.verified === false hiển thị warning không phải error, consistent với Plan 10-01 backend semantic"

requirements-completed: [CFG-05, CFG-06]

# Metrics
duration: ~45min (including 2 checkpoint-driven fixes)
completed: 2026-04-21
---

# Phase 10 Plan 2: User Signing Config Page Summary

**Trang `/ky-so/tai-khoan` với form dynamic theo provider active (SmartCA VNPT: 1 field; MySign Viettel: 2 field + button "Tải danh sách CTS") + sidebar submenu "Tài khoản ký số cá nhân" visible cho MỌI user (restructure group KÝ SỐ từ admin-only sang visible-for-all). Human verification PASSED (approved bởi user sau 2 round fix): round 1 tạo page + sidebar, round 2 fix AntD warning `useForm not connected` + rename label button từ "Kiểm tra kết nối" → "Xác thực tài khoản ký số". 656 lines production TSX + 2-line sidebar restructure. Zero new TypeScript errors.**

## Performance

- **Duration:** ~45min across 3 phases:
  - Task 1+2 implementation: ~25min (2026-04-21T09:08Z → ~09:30Z)
  - Human verification round 1: user tested UI, reported 2 issues (useForm warning + label wording)
  - Round 2 fixes: ~15min (39afbd2 + e936c13)
  - Final approval: 2026-04-21 evening
- **Tasks:** 3 (page + sidebar + human-verify checkpoint)
- **Files created:** 1 (page.tsx — 656 lines)
- **Files modified:** 1 (MainLayout.tsx — 6-line restructure: group push moved outside if-admin, add new submenu push)
- **Post-checkpoint fixes:** 2 commits (useForm warning guard, label rename)

## Accomplishments

### Task 1 — User config page (`/ky-so/tai-khoan/page.tsx`)

- **656-line production TSX** tại `e_office_app_new/frontend/src/app/(main)/ky-so/tai-khoan/page.tsx`:
  - Client component (`'use client'`) với complete TypeScript types matching Plan 10-01 API shape (GetResponse, CertificatesResponse, VerifyResponse, UserConfig, ClientCert, ActiveProvider)
  - **PROVIDER_UX metadata map** (Record<ProviderCode, {userIdLabel, userIdTooltip, userIdPlaceholder, needsCertList}>) cho data-driven form rendering
  - **4 state slices**: loading, active/config/activeMessage (từ GET), certificates/loadingCerts (MySign flow), saving/verifying (action loading)
  - **fetchConfig callback** (useCallback, deps [form, message]): load active provider + user config → auto-populate form qua setTimeout(0) setFieldsValue khi cả active + config tồn tại
  - **onLoadCertificates** (MySign only): gọi POST /certificates → populate Select options. Validate user_id non-empty trước gọi → inline error
  - **onSave**: POST / với user_id + optional credential_id. Map backend error message → inline field error qua setBackendFieldError pattern (credential message contains "chứng thư số" → credential_id field)
  - **onVerify**: POST /verify → parse data.verified flag: `true` = success + re-fetch; `false` = warning + re-fetch (để lấy last_error persist); network fail = error toast
  - **3 UI states rendered**:
    1. `loading === true` → Skeleton active paragraph rows=5
    2. `active === null` → Alert warning "Hệ thống chưa kích hoạt provider ký số" + button Làm mới
    3. `active != null` → Card 1 (Provider info Alert) + Card 2 (Form với badge verified + action buttons)
  - **Badge verified state**: `config.is_verified === true` → Tag success "Đã xác thực" + Tooltip(certificate_subject); false → Tag warning "Chưa xác thực"
  - **Cert info display**: khi verified → Descriptions bordered (Chủ thể chứng thư + Số serial) monospace styling
  - **Action buttons**: "Lưu cấu hình" (primary, SaveOutlined) + "Xác thực tài khoản ký số" (CheckCircleOutlined, disabled nếu `!config`, Tooltip giải thích action)

### Task 2 — Sidebar restructure (`MainLayout.tsx`)

- **Group KÝ SỐ hiển thị cho mọi user** (trước đây wrapped trong `if (isAdmin)`):
  - Line 279: `items.push({ key: 'grp-kyso', type: 'group', label: 'KÝ SỐ' })` — unconditional push
  - Line 281-287: `if (isAdmin) { items.push({ key: '/ky-so/cau-hinh', ... }) }` — submenu admin-only giữ nguyên guard
  - Line 288-293: `items.push({ key: '/ky-so/tai-khoan', icon: SafetyCertificateOutlined, label: 'Tài khoản ký số cá nhân' })` — unconditional push, visible cho mọi user
- **breadcrumbMap entry mới** (line 382): `'/ky-so/tai-khoan': 'Tài khoản ký số cá nhân'`
- **User verification confirmed**:
  - Login user thường → thấy group "KÝ SỐ" + CHỈ submenu "Tài khoản ký số cá nhân"
  - Login admin → thấy CẢ 2 submenu "Cấu hình ký số hệ thống" + "Tài khoản ký số cá nhân"

### Task 3 — Human verification PASSED (approved)

User chạy thực tế với real backend + frontend dev server, xác nhận:

- **Empty state** khi `is_active=false` cho cả 2 provider: Alert vàng đúng như spec + button Làm mới hoạt động
- **Form SmartCA VNPT**: 1 field `Mã định danh SmartCA`, không có button Tải CTS, không có Select credential → UI đơn giản
- **Form MySign Viettel**: 2 field + button "Tải danh sách chứng thư" load options cho Select credential_id
- **Save flow**: POST → toast success "Lưu cấu hình thành công. Vui lòng bấm 'Xác thực tài khoản ký số' để kiểm tra." + badge chuyển "Chưa xác thực" (vàng)
- **Verify flow**: POST → (với dev credentials mock) trả verified=false → toast warning; nếu có credentials thật → badge xanh "Đã xác thực" + Descriptions cert subject/serial
- **Sidebar restructure đúng** cho 2 role user/admin như kịch bản

**2 issues user flag trong verification round 1 → Claude fix trong round 2:**

### Post-checkpoint fixes

**Fix 1 (commit 39afbd2):** Guard form.setFieldsValue khi Form chưa mount
- **Issue**: React DevTools warn "useForm is not connected to any Form element" khi `active === null` (Form component không render, nhưng fetchConfig vẫn gọi setFieldsValue)
- **Fix**: Bỏ `form.resetFields()` trong else branch; chỉ gọi `setFieldsValue` khi `nextActive && nextConfig` đều tồn tại. Wrap trong `setTimeout(0)` defer tới sau render tiếp theo để Form kịp mount.
- **File**: `e_office_app_new/frontend/src/app/(main)/ky-so/tai-khoan/page.tsx` line 208-219
- **Impact**: Warning disappear, form state sync đúng khi active=null → form mount.

**Fix 2 (commit e936c13):** Rename button label "Kiểm tra kết nối" → "Xác thực tài khoản ký số"
- **Issue**: User feedback: "Kiểm tra kết nối" gây hiểu nhầm — giống chức năng Admin test TCP connection trong `/ky-so/cau-hinh`. Thực tế action gọi API provider fetch user certificate để verify mã định danh user, không test connection đơn thuần.
- **Fix**: Đổi label button (line 646) + toast success message (line 304) để consistent.
- **File**: `e_office_app_new/frontend/src/app/(main)/ky-so/tai-khoan/page.tsx` — 5 lines changed
- **Impact**: Vocabulary clear hơn, phân biệt với admin test connection. Badge "Đã xác thực" phù hợp với action "Xác thực".

## Task Commits

Each task committed atomically on main branch:

1. **Task 1: Tạo trang /ky-so/tai-khoan page.tsx** — `4905a38` (feat)
2. **Task 2: Thêm submenu sidebar + breadcrumb cho /ky-so/tai-khoan** — `e9124c1` (feat)
3. **Human verification** — checkpoint (no commit)
4. **Post-checkpoint fix 1: useForm warning guard** — `39afbd2` (fix)
5. **Post-checkpoint fix 2: label rename** — `e936c13` (fix)

**Plan metadata commit:** _pending_ (docs: complete plan — next)

## Files Created

- `e_office_app_new/frontend/src/app/(main)/ky-so/tai-khoan/page.tsx` — **created** (656 lines production TSX)
  - Complete React functional component with 4 API integrations
  - TypeScript-strict — all external API response shapes typed (GetResponse/CertificatesResponse/VerifyResponse)
  - CSS classes: `.page-header`, `.page-title`, `.page-description`, `.page-card` (from globals.css)

## Files Modified

- `e_office_app_new/frontend/src/components/layout/MainLayout.tsx` — **modified** (+6 lines net)
  - Line 278-286: restructure group KÝ SỐ push (unconditional group + conditional submenu admin)
  - Line 288-293: add unconditional submenu "Tài khoản ký số cá nhân"
  - Line 382: add breadcrumbMap entry `/ky-so/tai-khoan`

## Decisions Made

- **Form-mount guard qua setTimeout(0)**: AntD 6 `Form.useForm()` phải connect với mounted Form element. Khi `active=null`, Form component không render (empty state rendering Alert only). fetchConfig gọi setFieldsValue sẽ throw warning. Fix bằng: (1) chỉ setFieldsValue khi active + config đều tồn tại, (2) defer qua setTimeout(0) để Form kịp mount sau state update.
- **Label "Xác thực tài khoản ký số"**: phân biệt ngữ nghĩa với admin's "Kiểm tra kết nối" trong `/ky-so/cau-hinh`. Admin test TCP/HTTPS + credentials; user verify mã định danh qua fetch cert. "Xác thực" mapping 1:1 với badge "Đã xác thực" — UX consistent.
- **Group sidebar restructure**: KHÔNG tạo group KÝ SỐ thứ 2 cho user. Solution: push group header unconditionally, submenu bên trong tự guard. Scale tốt — nếu thêm submenu "Danh sách ký số" (Phase 12 UX-01) cho mọi user, chỉ cần push thêm, không đụng logic group.
- **Skeleton active paragraph rows=6 cho user=null guard**: consistent với các trang khác (HSCV list, VB đi list). KHÔNG dùng Spin full-page theo CLAUDE.md convention.
- **POST /certificates user_id lấy từ Form input**: user có thể test với user_id khác trước khi commit save (flow UX: nhập user_id mới → bấm "Tải CTS" → xem có cert nào → chọn → bấm Lưu → bấm Xác thực). KHÔNG lấy từ auth store vì có thể user đổi user_id.
- **needsCertList flag trong PROVIDER_UX**: thay vì `providerCode === 'MYSIGN_VIETTEL'` check inline, flag này semantic hơn. Nếu tương lai SmartCA thêm multi-cert support → chỉ toggle flag.
- **Re-fetch sau verify dù verified=true/false**: để UI sync lại `last_verified_at` + `last_error` persist từ backend. User thấy ngay kết quả verify không cần refresh page.

## Deviations from Plan

### Auto-fixed Issues

**None during initial execution** — Task 1 + Task 2 execute khớp 100% spec.

### Post-checkpoint fixes (user-flagged, not auto)

Both issues user phát hiện trong human verification round 1:

**Fix 1 — [User Feedback] useForm warning**
- **Found during:** Checkpoint verification (user mở DevTools console)
- **Issue:** Warning "useForm is not connected to any Form element" khi active=null
- **Fix:** Guard setFieldsValue + defer setTimeout(0)
- **Commit:** 39afbd2

**Fix 2 — [User Feedback] Label ambiguous**
- **Found during:** Checkpoint verification (user test flow, feedback label trùng với admin)
- **Issue:** "Kiểm tra kết nối" gây confusion với admin's test connection
- **Fix:** Rename thành "Xác thực tài khoản ký số"
- **Commit:** e936c13

Cả 2 đều là feedback từ user trong human verification — không phải auto-deviation executor tự phát hiện.

### Intentional Enhancements (beyond plan text)

- **setTimeout(0) wrap setFieldsValue**: plan không specify — added để tránh race condition giữa state setter và Form mount.
- **Explicit `CertificatesResponse` / `VerifyResponse` / `GetResponse` named interfaces**: plan inline type trong api.get generic parameter; refactor thành named types để reuse giữa state setter và error handler typing.
- **Tooltip trên button "Xác thực tài khoản ký số"** giải thích action: "Gọi API provider để xác thực mã định danh và lấy thông tin chứng thư số" — user hover biết rõ action trước khi click.
- **`style={{ margin: 0 }}` trên Tag verify badge**: AntD 6 Tag default có margin-right, trong Space layout cần reset để align đẹp với title.

---

**Total deviations:** 0 auto-fixes (during execution), 2 user-flagged post-checkpoint fixes, 4 intentional enhancements.
**Impact on plan:** Zero functional deviation from plan spec. 2 fixes là polish UX layer (warning elimination + label clarity), không thay đổi API contract hay data flow.

## Verification Results

### Task 1 (page.tsx)
- File exists: `ls e_office_app_new/frontend/src/app/\(main\)/ky-so/tai-khoan/page.tsx` → 656 lines
- API calls: `grep -c "api\.(get|post)" page.tsx` → ≥4 (1 GET + 3 POST as required)
- Client directive: `grep "'use client'" page.tsx` → 1 line
- Provider codes: `grep "SMARTCA_VNPT\|MYSIGN_VIETTEL" page.tsx` → ≥2 lines (types + metadata map)
- TypeScript: `npx tsc --noEmit` → 0 new errors in tai-khoan/ file
- All text tiếng Việt có dấu ✓

### Task 2 (MainLayout.tsx)
- Menu item entry: `grep -n "'/ky-so/tai-khoan'" MainLayout.tsx` → 2 lines (menu + breadcrumb)
- Label line: `grep -n "Tài khoản ký số cá nhân" MainLayout.tsx` → 2 lines
- Group push NOT inside `if (isAdmin)` → verified line 278-279 unconditional
- TypeScript: `npx tsc --noEmit` → 0 new errors

### Task 3 (Human verification)
- User approved: "approved" (after round 2 fixes)
- Both UI states (active=null / active có) render đúng
- Sidebar phân biệt theo role verified
- Form SmartCA 1 field / MySign 2 field + Tải CTS button verified
- Save + Verify flow work end-to-end (verify thành công với mock provider data)

### Post-checkpoint fix verification
- Commit 39afbd2: `grep -n "setTimeout(() =>" page.tsx` → 1 line at setFieldsValue wrap
- Commit e936c13: `grep -n "Xác thực tài khoản ký số" page.tsx` → 2 lines (button label + toast)
- Warning useForm not-connected: resolved (no DevTools warn)

## Issues Encountered

- **AntD 6 Form.useForm warning** (resolved): Form khi unmount (active=null) vẫn nhận setFieldsValue call từ fetchConfig. Root cause: fetchConfig không guard theo active existence. Fix pattern applicable cho các trang khác có conditional Form render.
- **Label ambiguity "Kiểm tra kết nối"** (resolved): User perception vs spec language clash — plan dùng "Kiểm tra" (test) nhưng UX context khác action (xác thực). Lesson: khi action gọi API business (fetch cert + match credential), label nên mô tả kết quả (verify), không phải protocol (test connection).

## User Setup Required

- **None.** Frontend dev server auto-reload picked up 4 commits. User có thể test ngay bằng login bằng tài khoản thường (không admin).
- **Khi triển khai production**: Admin PHẢI activate 1 provider qua `/ky-so/cau-hinh` (Phase 9-03) trước khi user dùng được trang `/ky-so/tai-khoan`. Nếu chưa activate → user thấy empty state warning.

## Next Phase Readiness

- **Ready for Phase 10 Plan 03 (Remove tab Chữ ký số cũ trong `/thong-tin-ca-nhan`)**:
  - URL mới `/ky-so/tai-khoan` đã live và có sidebar entry — làm Alert pointer target chính xác
  - User có flow thay thế tab cũ → có thể safely remove mà không mất functionality
- **Ready for Phase 11 (Sign flow + async worker)**:
  - `staff_signing_config.is_verified = true` là precondition cho ký thật — flow verify UI đã hoạt động
  - Phase 11 backend có thể guard "user chưa verify → 400 bắt vào /ky-so/tai-khoan verify trước"

## Self-Check: PASSED

Verified (2026-04-21):
- File `e_office_app_new/frontend/src/app/(main)/ky-so/tai-khoan/page.tsx` exists (656 lines)
- File `e_office_app_new/frontend/src/components/layout/MainLayout.tsx` modified (restructured group KÝ SỐ + new submenu + breadcrumb entry)
- Commit `4905a38` exists: `feat(10-02): add user signing config page /ky-so/tai-khoan`
- Commit `e9124c1` exists: `feat(10-02): add sidebar submenu 'Tài khoản ký số cá nhân' cho mọi user`
- Commit `39afbd2` exists: `fix(10-02): guard form.setFieldsValue khi Form chưa mount (useForm warning)`
- Commit `e936c13` exists: `fix(10-02): đổi label 'Kiểm tra kết nối' → 'Xác thực tài khoản ký số'`
- Human verification approved by user
- `grep -c "api\.(get|post)" page.tsx` ≥ 4 (4 endpoint integrations)
- `grep -n "grp-kyso" MainLayout.tsx` NOT inside `if (isAdmin)` block
- `grep -n "Xác thực tài khoản ký số" page.tsx` = 2 (button label + toast message consistent)
- TypeScript: 0 new errors baseline preserved

---
*Phase: 10-user-config-page*
*Completed: 2026-04-21*
