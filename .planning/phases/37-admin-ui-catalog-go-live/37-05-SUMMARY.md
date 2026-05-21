---
phase: 37-admin-ui-catalog-go-live
plan: 05
subsystem: frontend
tags: [frontend, ui, admin, lgsp, overview, dashboard, polling, phase-37]

# Dependency graph
requires:
  - phase: 37-admin-ui-catalog-go-live
    plan: 02
    provides: GET /api/admin/lgsp-overview (units + totals aggregated CTE) + LgspOverviewRow interface
  - phase: 35-receive-flow-cron-syncreceivededoclist
    plan: 03
    provides: POST /api/lgsp/sync-now (admin only, 202 Accepted, enqueueReceiveTick trigger_source='manual')
  - phase: 18-lgsp-foundation
    provides: GET /api/lgsp/tracking (all authenticated users — Phase 18 endpoint reused)
provides:
  - "REWRITE page /lgsp tu Phase 18 tracking list stub thanh full Dashboard overview"
  - "4 stat cards tong quan today (gui/nhan/outbox pending/outbox error) — wire totals tu /admin/lgsp-overview"
  - "6 DN cards grid (1 per root unit co lgsp_org_code) voi env badges + last_synced_at + count today + Alert error inline"
  - "Button 'Dong bo ngay' admin only -> POST /lgsp/sync-now -> setTimeout 8s refresh"
  - "Polling 30s tu refresh overview + tracking background (KHONG cleanup race condition)"
  - "Admin role guard inline cho 4 stat cards + 6 DN cards + button Dong bo (non-admin van xem tracking history)"
affects: [37-06-frontend-menu-unhide-retry]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Polling 30s setInterval trong useEffect voi cleanup clearInterval — single endpoint /admin/lgsp-overview lightweight"
    - "Admin role check inline via useAuthStore (user.isAdmin || roles.includes('Quan tri he thong')) — conditional render 3 section + button"
    - "Non-admin transparent visibility: vẫn xem tracking history + Alert info giai thich, KHONG fetch admin endpoint (tranh 403 console error)"
    - "Tolerant field name mapping QUA strict TS interface — backend Plan 37-02 da xac dinh exact shape (send_today_total etc)"
    - "Sync button UX: trigger -> toast -> setTimeout 8s refresh (cho cron pick up + worker complete)"
    - "Empty/Loading state per section: 6 DN cards Skeleton riêng (KHONG block toan page), Empty khi units[]=[]"

key-files:
  created:
    - .planning/phases/37-admin-ui-catalog-go-live/37-05-SUMMARY.md
  modified:
    - e_office_app_new/frontend/src/app/(main)/lgsp/page.tsx (REWRITE 206 -> 577 lines)

key-decisions:
  - "Admin role guard inline (mirror Plan 37-03/04 pattern) thay vi redirect - non-admin van xem tracking history + Alert info, transparent UX"
  - "Polling 30s setInterval thay vi WebSocket - endpoint /admin/lgsp-overview lightweight CTE single roundtrip, OK refresh background"
  - "Sync button setTimeout 8s thay vi immediate refresh - cho receive-tick job enqueue + N receive-dn child jobs co thoi gian pick up"
  - "Non-admin KHONG fetch /admin/lgsp-overview (skip if !isAdmin) — tranh 403 console error + giam tai backend"
  - "Tracking history giu Phase 18 endpoint reuse (GET /lgsp/tracking khong admin gate) - non-admin van xem duoc transparency"
  - "Stat cards Vietnamese diacritics: 'VB gửi hôm nay/VB nhận hôm nay/Callback chờ xử lý/Callback lỗi' (match plan acceptance)"
  - "fromNow KHONG dung — dayjs.format('DD/MM HH:mm') de tranh phai import relativeTime plugin"

patterns-established:
  - "Dashboard overview page pattern: header + Alert conditional + stat cards Row + section cards Row + tracking Table - reusable cho ky-so dashboard, audit dashboard..."
  - "Polling lightweight: single endpoint setInterval 30s + cleanup clearInterval - tot hon useSWR cho dashboard real-time low-frequency update"

requirements-completed: [LGSP-UI-04]

# Metrics
duration: ~10 min
completed: 2026-05-21
---

# Phase 37 Plan 05: Frontend Overview Dashboard /lgsp Summary

**REWRITE page /lgsp (206 -> 577 lines) — Phase 18 tracking list stub -> full Dashboard overview LGSP: 4 stat cards tổng quan today + 6 DN cards với env badges + last_synced_at + count today + button "Đồng bộ ngay" admin only + tracking history Table giữ Phase 18 — wire 3 endpoint (1 admin overview + 1 sync-now + 1 tracking).**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-05-21
- **Completed:** 2026-05-21
- **Tasks:** 2/2 (Task 2 verification-only, no commit)
- **Files modified:** 1 (REWRITE)

## Accomplishments

- **REWRITE** `e_office_app_new/frontend/src/app/(main)/lgsp/page.tsx` (Phase 18 206 dòng → Phase 37 577 dòng):
  - Admin role guard inline (`useAuthStore` — check `user?.isAdmin || roles.includes('Quản trị hệ thống')`)
  - Header: title "Liên thông LGSP" với icon `ApiOutlined` + Space buttons (Làm mới luôn + "Đồng bộ ngay" admin only)
  - Alert info cho non-admin user: "Chế độ xem cho người dùng thường. Một số chức năng chỉ dành cho Quản trị hệ thống."
  - Alert warning admin khi `totals.active_count === 0`: hướng dẫn truy cập `/lgsp/cau-hinh` để bật kết nối
  - **4 stat cards (admin only)** với icon + giá trị + label tiếng Việt:
    - VB gửi hôm nay (icon SendOutlined blue) + suffix Tag "X lỗi" nếu `send_error > 0`
    - VB nhận hôm nay (icon InboxOutlined green)
    - Callback chờ xử lý (icon ClockCircleOutlined warning #D97706)
    - Callback lỗi (icon ExclamationCircleOutlined error #DC2626, valueStyle conditional red khi > 0)
  - **6 DN cards (admin only)** Row gutter[16,16] responsive xs={24} sm={12} lg={8}:
    - Title: BankOutlined + unit_name, extra: Tag blue lgsp_org_code
    - Env badges Space: Sandbox (orange khi active, default khi tắt) + Production (red khi active, default khi tắt) — Tooltip giải thích last_sync_error hoặc state
    - Last synced: dayjs format DD/MM HH:mm (KHÔNG fromNow để tránh dayjs plugin) hoặc "Chưa đồng bộ"
    - Row 3 col counts: Gửi today blue, Nhận today green, Outbox warning conditional background `#fff7e6` nếu pending > 0
    - Alert error inline nếu `send_today_error > 0`
  - Loading state: 6 Skeleton cards riêng (KHÔNG block toàn page)
  - Empty state: Empty "Chưa có DN nào được cấu hình LGSP"
  - **Tracking history (all authenticated users)** Card title "Lịch sử liên thông gần đây (10 bản ghi mới nhất)":
    - Table 5 column: Hướng (Tag blue Gửi đi / green Nhận về với icon), Cơ quan (ellipsis), Mã LGSP, Trạng thái (Tag color + Tooltip error_message), Thời gian (dayjs DD/MM HH:mm)
    - Skeleton loading, Empty fallback
- **3 endpoint integration:**
  - `GET /admin/lgsp-overview` (Plan 37-02) — load 6 units + totals on mount + polling 30s + sau sync 8s (admin only, skip silent nếu non-admin)
  - `POST /lgsp/sync-now` (Phase 35-03, admin only) — 202 Accepted, setTimeout 8s refresh
  - `GET /lgsp/tracking?page=1&pageSize=10` (Phase 18, all users) — recent tracking history
- **Polling 30s** setInterval trong useEffect riêng với cleanup clearInterval — chỉ 1 endpoint admin overview + 1 tracking, lightweight OK
- **TypeScript strict:** 0 NEW error trong `lgsp/page.tsx` (xác minh `npx tsc --noEmit 2>&1 | grep lgsp/page.tsx | wc -l` = 0)
- **Production build frontend:** PASS (`Compiled successfully in 36.5s`, route `/lgsp` compiled static `○`)

## Task Commits

1. **Task 1: REWRITE page.tsx /lgsp Dashboard overview** — `cca35a8` (feat) — 483 insertions / 112 deletions, file final 577 lines
2. **Task 2: Production build verify** — verification only, no commit (build PASS exit 0)

## Files Created/Modified

- `e_office_app_new/frontend/src/app/(main)/lgsp/page.tsx` **(REWRITE)** — 206 → 577 dòng. Phase 18 tracking list `/lgsp/tracking` table chỉ → Phase 37 full Dashboard overview với 3 endpoint integration + 4 stat cards + 6 DN cards + admin guard + polling 30s + tracking history giữ pattern Phase 18.

## Decisions Made

1. **Admin role guard inline (mirror Plan 37-03/04 pattern)** thay vì redirect — non-admin user vẫn xem được tracking history (Phase 18 endpoint không admin gate) + Alert info giải thích các chức năng admin only. Transparent visibility tốt hơn redirect đột ngột. Code đơn giản hơn (KHÔNG cần wrap layout/route).

2. **Polling 30s setInterval thay vì WebSocket** — endpoint `/admin/lgsp-overview` là CTE single PostgreSQL roundtrip lightweight. WebSocket overkill cho dashboard refresh low-frequency. Trade-off: lag tối đa 30s — admin ok với refresh tự động background, có thể click "Làm mới" để immediate.

3. **Sync button setTimeout 8s thay vì immediate refresh** — `/lgsp/sync-now` enqueue receive-tick job (returns 202 ngay), worker mới spawn N receive-dn child jobs (1 per active DN). Refresh ngay sẽ thấy data cũ. 8s = đủ thời gian cho 1-2 DN sandbox sync round-trip.

4. **Non-admin KHÔNG fetch `/admin/lgsp-overview` (skip if !isAdmin)** — tránh 403 console error spam (polling 30s × 2 lần/phút = 4 lần 403 mỗi 2 phút). Giảm tải backend cho non-admin users.

5. **Tracking history giữ Phase 18 endpoint reuse** — `GET /lgsp/tracking` không admin gate (legacy Phase 18). Non-admin user xem được history giúp transparency biết hệ thống có hoạt động LGSP — không leak data nhạy cảm (tracking row chỉ có direction + status + dest_org_code/name + lgsp_doc_id).

6. **Stat cards Vietnamese diacritics: 'VB gửi hôm nay/VB nhận hôm nay/Callback chờ xử lý/Callback lỗi'** — match plan acceptance criteria. Ngắn gọn + súc tích.

7. **fromNow KHÔNG dùng — dayjs.format('DD/MM HH:mm')** — tránh import `dayjs/plugin/relativeTime` + `dayjs.extend(relativeTime)` setup. Plan skeleton có 1 chỗ dùng fromNow → đã chỉnh sang format. Người dùng cần thông tin tuyệt đối (HH:mm) cho dashboard admin hơn là relative ("5 phút trước").

## Deviations from Plan

**None — plan executed exactly as written.**

Plan skeleton trong PLAN.md đã có full implementation (~487 dòng skeleton + comments) với 1 chỗ note `fromNow → format`. File final 577 dòng vì:
- JSX formatting với line break đẹp hơn (mỗi `<Tag>`, `<Tooltip>` trên dòng riêng)
- Comments inline cho main sections (// ── 4 Stat cards, // ── 6 DN cards, etc.)
- Header comment block chi tiết hơn (mô tả layout + endpoint + non-admin behavior)
- Type SyncNowResponse explicit (interface riêng cho api.post<>)
- Admin guard logic: thêm Alert info cho non-admin user (UX improvement KHÔNG có trong skeleton — Rule 2 auto-add critical: feedback cho non-admin user biết tại sao thiếu section)

## Issues Encountered

- **(None)** — backend endpoints (Plan 37-02 + Phase 35-03 + Phase 18) đã đầy đủ + tested. Pattern AntD 6 đã ổn định từ Plan 37-03 (/cau-hinh) + 37-04 (/co-quan). Implementation thẳng theo skeleton plan với 2 minor UX improvements (Alert info non-admin + comments).

## Acceptance Criteria — All PASS

| Check | Result |
|---|---|
| File length ≥ 280 lines | ✓ 577 lines |
| Grep `Liên thông LGSP\|Đồng bộ ngay\|Trạng thái 6 doanh nghiệp` | ✓ 7 matches (cả 3 substring present) |
| Grep `/admin/lgsp-overview` | ✓ matched (in fetchOverview + Alert link) |
| Grep `/lgsp/sync-now` | ✓ matched (in handleSyncNow + comment) |
| Grep `/lgsp/tracking` | ✓ matched (Phase 18 reuse trong fetchTracking) |
| Grep `POLL_INTERVAL_MS\|setInterval` | ✓ 3 matches |
| Grep `VB gửi hôm nay\|VB nhận hôm nay\|Callback chờ xử lý\|Callback lỗi` | ✓ 4 matches (all 4 stat labels) |
| Grep `fromNow` (must be 0) | ✓ 0 matches (đúng — dùng format thay vì fromNow) |
| `npx tsc --noEmit \| grep lgsp/page.tsx \| wc -l` | ✓ 0 NEW errors |
| `npm run build` exit 0 | ✓ PASS + `Compiled successfully in 36.5s` + route `/lgsp` compiled `○` static |

## User Setup Required

None — page sẵn sàng (vẫn ẩn trong sidebar bởi `hidden-routes.ts` — Plan 37-06 sẽ unhide menu `/lgsp` + `/lgsp/co-quan`).

Manual visual test (defer Plan 37-07 E2E full):
1. Backend running dev + admin login
2. Tạm xóa `/lgsp` khỏi `hidden-routes.ts` Set (hoặc gõ URL trực tiếp `http://localhost:3000/lgsp`)
3. Verify header với button "Đồng bộ ngay" hiện (admin role)
4. Verify 4 stat cards load (totals từ DB)
5. Verify 6 DN cards với env badges (sandbox orange / production red khi active, default khi tắt), last_synced_at, counts today
6. Click "Đồng bộ ngay" → toast "Đã xếp hàng đồng bộ LGSP — worker sẽ chạy trong giây lát" → đợi 8s → cards refresh
7. Mở Network tab → verify polling 30s tự gọi `/admin/lgsp-overview` + `/lgsp/tracking` background
8. Non-admin login → vẫn vào được `/lgsp` → KHÔNG thấy button "Đồng bộ ngay" + 4 stat cards + 6 DN cards → vẫn thấy tracking history + Alert info giải thích

## Next Phase Readiness

- **Plan 37-06 (frontend menu unhide + retry button)** unblocked — page `/lgsp` đã hoàn thiện. Plan 37-06 sẽ:
  - Xóa `/lgsp` + `/lgsp/co-quan` khỏi `hidden-routes.ts` Set
  - Thêm sidebar entry `/lgsp/cau-hinh` admin only trong MainLayout.tsx
  - Wire retry button vào Phase 36-04 Timeline (outbox retry) + Phase 34-04 badge (tracking retry)
- **Plan 37-07 (E2E verification + SHIP-READINESS)** sẵn sàng nhận page `/lgsp` để test toàn flow

## Known Stubs

None — page là production-ready, KHÔNG có placeholder/TODO/mock data. Tất cả data flow từ backend real endpoints (Plan 37-02 `/admin/lgsp-overview` + Phase 35-03 `/lgsp/sync-now` + Phase 18 `/lgsp/tracking`).

## Threat Flags

None — admin endpoint `/admin/lgsp-overview` mount tại `/api/admin/*` đã wrap `authenticate + requireRoles('Quản trị hệ thống')` (Plan 37-01 mount line 136 server.ts). Non-admin KHÔNG fetch endpoint (skip if !isAdmin). Sync endpoint `/lgsp/sync-now` đã có `requireRoles('Quản trị hệ thống')` middleware (Phase 35-03). Tracking endpoint `/lgsp/tracking` không admin gate là design choice (transparent visibility — non-admin có thể xem history liên thông, không leak data nhạy cảm). Không có surface mới tại trust boundary.

## Self-Check: PASSED

**Files created/modified verified:**
- FOUND: e_office_app_new/frontend/src/app/(main)/lgsp/page.tsx (577 lines)
- FOUND: .planning/phases/37-admin-ui-catalog-go-live/37-05-SUMMARY.md (this file)

**Commits verified:**
- FOUND: cca35a8 (Task 1 — REWRITE page.tsx Dashboard overview)

**Acceptance criteria check:** All 10 criteria PASS (see table above)

---
*Phase: 37-admin-ui-catalog-go-live*
*Completed: 2026-05-21*
