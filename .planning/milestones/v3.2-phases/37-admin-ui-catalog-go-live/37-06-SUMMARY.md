---
phase: 37-admin-ui-catalog-go-live
plan: 06
subsystem: frontend
tags: [frontend, integration, hidden-routes, sidebar, retry-button, lgsp, phase-37]

# Dependency graph
requires:
  - phase: 37-admin-ui-catalog-go-live
    plan: 01
    provides: POST /api/admin/lgsp-status-outbox/:id/retry + POST /api/admin/lgsp-tracking/:id/retry (admin only)
  - phase: 37-admin-ui-catalog-go-live
    plan: 03
    provides: page /lgsp/cau-hinh (admin only) cho Sidebar entry mới điều hướng tới
  - phase: 36-status-callback-chain-9-ma-qd-28
    plan: 04
    provides: LgspStatusTimeline component (Timeline + polling 10s) — extend với retry button
  - phase: 34-send-flow-sendedoc
    plan: 04
    provides: useRecipientsPolling hook + badge state machine — extend RecipientStatus + retry button
  - phase: 19-vb-di-noi-bo-lgsp
    provides: GET /api/van-ban-di/:id/noi-nhan raw query đã expose generated_lgsp_tracking_id (KHÔNG cần extend schema)
provides:
  - "Menu LGSP unhide trên sidebar (3 entry: Liên thông LGSP, Cơ quan liên thông, Cấu hình kết nối) — admin only group TÍCH HỢP"
  - "Button 'Gửi lại' inline trong LgspStatusTimeline cho entry sent_status='error' (admin only, gọi outbox retry endpoint)"
  - "Button 'Gửi lại' inline trong page VB đi detail cho recipient external_org lgsp_status='error' (admin only, gọi tracking retry endpoint)"
  - "Frontend RecipientStatus interface mở rộng generated_lgsp_tracking_id (đồng bộ với backend route đã expose)"
  - "Breadcrumb '/lgsp/cau-hinh' = 'Cấu hình kết nối LGSP'"
affects: [37-07-verification-go-live]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Popconfirm wrap Button retry (tránh misclick) + loading state per-row (retryingId / retryingTrackingId useState)"
    - "Admin role guard inline: user.isAdmin || roles.includes('Quản trị hệ thống') — KHÔNG fetch admin endpoint nếu non-admin (tránh 403 console error)"
    - "Refetch ngay + setTimeout 5s sau retry — cho worker pick up + cập nhật trạng thái về success/error"
    - "Toast tiếng Việt có dấu cho cả success + error message"
    - "App.useApp() pattern cho message (lgsp-status-timeline) — fix React 19 context warning"

key-files:
  created:
    - .planning/phases/37-admin-ui-catalog-go-live/37-06-SUMMARY.md
  modified:
    - e_office_app_new/frontend/src/config/hidden-routes.ts (xoá '/lgsp' + '/lgsp/co-quan', giữ '/thong-bao-kenh')
    - e_office_app_new/frontend/src/components/layout/MainLayout.tsx (thêm entry '/lgsp/cau-hinh' admin only + ApiOutlined cho /lgsp + breadcrumb)
    - e_office_app_new/frontend/src/components/lgsp-status-timeline.tsx (thêm Button 'Gửi lại' + handleRetry + Popconfirm + isAdmin gate)
    - e_office_app_new/frontend/src/hooks/use-recipients-polling.ts (thêm generated_lgsp_tracking_id vào RecipientStatus interface)
    - e_office_app_new/frontend/src/app/(main)/van-ban-di/[id]/page.tsx (thêm Button 'Gửi lại' + handleRetryTracking + Popconfirm + isAdmin gate trong noiNhan badge render)

key-decisions:
  - "KHÔNG extend schema/SP/repository/route — backend GET /:id/noi-nhan (Phase 19, line 503 routes/outgoing-doc.ts) đã expose generated_lgsp_tracking_id từ rawQuery JOIN edoc.lgsp_tracking. Chỉ cần thêm field vào RecipientStatus interface frontend."
  - "Đổi icon '/lgsp' từ SwapOutlined → ApiOutlined cho semantic LGSP API integration (đã có sẵn import)"
  - "Popconfirm wrap Button retry — pattern dự án (van-ban-di/[id] đã dùng Popconfirm cho delete) để tránh misclick"
  - "Loading state per-row (retryingId/retryingTrackingId useState number|null) — UX tốt hơn khi user click nhiều entry liên tiếp"
  - "Refetch sau retry: ngay + setTimeout 5s — outbox worker cron 30s nhưng polling 10s tự bắt success/error sau đó, 5s ban đầu chỉ confirm state 'pending'"
  - "isAdmin gate: user.isAdmin || roles.includes('Quản trị hệ thống') — mirror Plan 37-03/04/05 pattern, đồng nhất role check toàn frontend"
  - "Breadcrumb '/lgsp/cau-hinh' = 'Cấu hình kết nối LGSP' (KHÔNG dùng 'Cấu hình' thuần để tránh conflict semantic với /quan-tri/cau-hinh)"
  - "App.useApp() (msg context) cho lgsp-status-timeline thay vì message global static — fix React 19 context warning + ensure ConfigProvider/AntdProvider context"

metrics:
  duration: ~30 minutes
  tasks_completed: 4
  files_modified: 5
  files_created: 1
  commits: 3
  completed: 2026-05-21
---

# Phase 37 Plan 06: Frontend Menu Unhide + Retry Buttons Summary

Frontend integration cuối Phase 37: unhide menu LGSP trên sidebar admin (3 entry), thêm button "Gửi lại" admin only ở 2 nơi (LgspStatusTimeline cho outbox event error + VB đi detail badge cho recipient external_org error), zero schema change vì backend route đã expose `generated_lgsp_tracking_id` từ Phase 19.

## Objective

Hoàn tất luồng UX admin self-service cho rolling out + recovery LGSP per LGSP-UI-07 + LGSP-UI-08. Sau plan này:
- Menu LGSP hiện trên sidebar admin (group "TÍCH HỢP" với 3 entry: Liên thông LGSP, Cơ quan liên thông, Cấu hình kết nối)
- Admin có thể "Gửi lại" cho outbox event error qua UI inline trong Timeline (KHÔNG cần SQL update)
- Admin có thể "Gửi lại" cho tracking error qua UI inline trong VB đi detail badge

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Unhide menu + sidebar entry /lgsp/cau-hinh | 7a1dc0a | hidden-routes.ts, MainLayout.tsx |
| 2 | Retry button Timeline (outbox error) | a6186e3 | lgsp-status-timeline.tsx |
| 3 | Retry button VB đi badge (tracking error) | ac58778 | use-recipients-polling.ts, van-ban-di/[id]/page.tsx |
| 4 | Production build verify (no file changes) | (verified inline) | — |

## Implementation Details

### Task 1 — hidden-routes + MainLayout

**hidden-routes.ts:** Xoá entries `'/lgsp'` + `'/lgsp/co-quan'`. Giữ `'/thong-bao-kenh'`. Thêm comment Phase 37 marker.

**MainLayout.tsx (line 270-277):**
- Đổi icon `/lgsp` từ `SwapOutlined` → `ApiOutlined` (semantic LGSP API)
- Thêm entry mới `/lgsp/cau-hinh` với icon `SettingOutlined` label "Cấu hình kết nối" trong block `if (isAdmin)`
- Thêm breadcrumb `/lgsp/cau-hinh` = "Cấu hình kết nối LGSP"
- Cả 2 icon `ApiOutlined` + `SettingOutlined` đã có sẵn trong import block (không cần thêm)

### Task 2 — LgspStatusTimeline retry button

**lgsp-status-timeline.tsx:**
- Import thêm: `Button`, `App`, `Popconfirm`, `ReloadOutlined`, `useAuthStore`
- `isAdmin` gate: `user.isAdmin || roles.includes('Quản trị hệ thống')`
- `handleRetry(outboxId)`: POST `/admin/lgsp-status-outbox/:id/retry` → toast success → refetch ngay + 5s later
- `retryingId` useState cho loading per-row
- Button render khi `r.sent_status === 'error' && isAdmin`:
  ```tsx
  <Popconfirm title="Gửi lại sự kiện này?" onConfirm={() => handleRetry(r.id)}>
    <Button size="small" type="link" icon={<ReloadOutlined />} loading={retryingId === r.id}>
      Gửi lại
    </Button>
  </Popconfirm>
  ```
- Space wrap row 1 `wrap` để retry button xuống dòng trên màn nhỏ

### Task 3 — VB đi badge retry button

**use-recipients-polling.ts:** Thêm field `generated_lgsp_tracking_id: number | null` vào `RecipientStatus` interface.

**van-ban-di/[id]/page.tsx:**
- Import thêm: `ReloadOutlined`
- `isAdmin` inline + `retryingTrackingId` useState
- `handleRetryTracking(trackingId)`: POST `/admin/lgsp-tracking/:id/retry` → toast + refetchNoiNhan ngay + 5s later
- Render Button "Gửi lại" trong noiNhan map (line ~779) khi `external_org && lgsp_status='error' && generated_lgsp_tracking_id && isAdmin`:
  ```tsx
  <Popconfirm title="Gửi lại văn bản này qua LGSP?" onConfirm={() => handleRetryTracking(r.generated_lgsp_tracking_id as number)}>
    <Button size="small" type="link" icon={<ReloadOutlined />} loading={...}>Gửi lại</Button>
  </Popconfirm>
  ```

### Task 4 — Production build verify

- Backend `npm run build` exit 0 (tsc only)
- Frontend `npm run build` exit 0 — "Compiled successfully in 38.1s", "Generating static pages (52/52)"
- 3 LGSP routes có trong route manifest: `/lgsp`, `/lgsp/cau-hinh`, `/lgsp/co-quan` (all static `○`)

## Deviations from Plan

### Auto-resolved Issues (Rule 3 — fix blocking issues)

**1. [Rule 3 - Avoid unnecessary schema surgery] KHÔNG extend SP `fn_outgoing_doc_get_recipients`**

- **Found during:** Task 3 reading backend route
- **Issue:** Plan dự kiến phải extend schema/SP/repo/route để expose `lgsp_tracking_id` cho retry button.
- **Discovery:** Backend route `GET /:id/noi-nhan` (Phase 19, `e_office_app_new/backend/src/routes/outgoing-doc.ts` line 489-526) đã dùng `rawQuery` SELECT trực tiếp từ `outgoing_doc_recipients` JOIN `edoc.lgsp_tracking` ON `r.generated_lgsp_tracking_id = t.id`. Cột `generated_lgsp_tracking_id` đã có trong response shape (line 503).
- **Fix:** Chỉ thêm field `generated_lgsp_tracking_id` vào `RecipientStatus` interface frontend. KHÔNG modify schema/SP/route/backend repo.
- **Impact:** Tiết kiệm 1 schema apply (skipped 2x apply verify) + zero risk schema break + giảm 3 file change.
- **Files modified vs plan:** 5 file modified thực tế (plan dự kiến 5 nhưng có schema/SP/repo/route) — thay schema work bằng zero-change vì route đã sẵn.
- **Commit:** ac58778

## Auth/Schema Gates

Không có. Plan này không cần SIGNING_SECRET_KEY hoặc DB schema apply.

## Known Stubs

Không có stub mới. Retry buttons hoạt động E2E thật (gọi admin endpoint Phase 37-01 đã verify).

## Verification

### Automated (đã chạy)

- TS check frontend: zero NEW errors (chỉ còn 4 pre-existing per CLAUDE.md verification note: ho-so-cong-viec, van-ban-den/page, van-ban-di/page, van-ban-du-thao/page — đều TreeNode strict TS unrelated)
- TS check backend: PASS exit 0
- Production build backend: PASS exit 0
- Production build frontend: PASS exit 0 ("Compiled successfully in 38.1s")
- 3 LGSP routes trong manifest: `/lgsp` `○`, `/lgsp/cau-hinh` `○`, `/lgsp/co-quan` `○` — all static

### Manual E2E (cho Plan 37-07)

1. Admin login → sidebar group "TÍCH HỢP" hiện 4 entry: Liên thông LGSP, Cơ quan liên thông, **Cấu hình kết nối** (mới), Kênh thông báo
2. Click "Cấu hình kết nối" → `/lgsp/cau-hinh` load OK (Plan 37-03 page)
3. Non-admin user login → sidebar KHÔNG hiện group "TÍCH HỢP" (toàn bộ admin-only)
4. VB đến detail (source=external_lgsp) có entry Timeline sent_status='error' → button "Gửi lại" hiện inline (admin) → Popconfirm → click "Gửi lại" → toast "Đã reset outbox event, worker sẽ gửi lại trong vòng 30 giây" → polling 10s tự refresh
5. VB đi detail có recipient external_org lgsp_status='error' → button "Gửi lại" cạnh badge (admin) → Popconfirm → click → toast "Đã reset tracking, worker sẽ gửi lại trong vài giây" → polling tự refresh

### Acceptance Criteria

- [x] `! grep "^\s*'/lgsp',\s*$" hidden-routes.ts` → empty (PASS)
- [x] `! grep "^\s*'/lgsp/co-quan'" hidden-routes.ts` → empty (PASS)
- [x] `grep "'/thong-bao-kenh'" hidden-routes.ts` → match (PASS)
- [x] `grep "/lgsp/cau-hinh" MainLayout.tsx` → match (PASS)
- [x] `grep "Cấu hình kết nối" MainLayout.tsx` → match (PASS)
- [x] `grep "/admin/lgsp-status-outbox" lgsp-status-timeline.tsx` → match (PASS)
- [x] `grep "Gửi lại" lgsp-status-timeline.tsx` (Vietnamese) → match (PASS)
- [x] `grep "useAuthStore" lgsp-status-timeline.tsx` → match (PASS)
- [x] `grep "ReloadOutlined" lgsp-status-timeline.tsx` → match (PASS)
- [x] `grep "/admin/lgsp-tracking" van-ban-di/[id]/page.tsx` → match (PASS)
- [x] `grep "Gửi lại" van-ban-di/[id]/page.tsx` → match (PASS)
- [x] `grep "handleRetryTracking" van-ban-di/[id]/page.tsx` → match (PASS)
- [x] `grep "generated_lgsp_tracking_id" use-recipients-polling.ts` → match (PASS)
- [x] Backend `npx tsc --noEmit` exit 0 (PASS)
- [x] Frontend `npx tsc --noEmit` zero NEW errors (PASS — 4 pre-existing unrelated)
- [x] Frontend `npm run build` exit 0 ("Compiled successfully in 38.1s")
- [x] Build manifest chứa 3 LGSP routes (PASS)

## Commits

- 7a1dc0a — feat(37-06): unhide menu LGSP + them sidebar entry /lgsp/cau-hinh
- a6186e3 — feat(37-06): them button 'Gui lai' admin only trong LgspStatusTimeline cho entry error
- ac58778 — feat(37-06): them button 'Gui lai' admin only cho recipient external_org error VB di

## Threat Flags

Không có. Plan này tái sử dụng admin endpoint Phase 37-01 đã có `requireRoles('Quản trị hệ thống')`. Không thêm endpoint mới, không thêm trust boundary mới.

## Self-Check: PASSED

Tất cả file claim modified + commit hash verified tồn tại trên disk + git log.
