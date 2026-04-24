---
phase: 13-modal-ky-so-robust-root-ca-ux
plan: 02
subsystem: frontend-bell-notification
tags: [frontend, bell, antd6, socket, notifications, toast, header]

requires:
  - phase: 13
    plan: 01
    provides: "GET /api/notifications + unread-count + mark-read + read-all endpoints + snake_case response shape (PersonalNotification)"
  - phase: 11
    plan: 04
    provides: "Worker emit SIGN_COMPLETED/SIGN_FAILED socket events vào room user_{staffId}"
  - phase: 11
    plan: 06
    provides: "SOCKET_EVENTS constants + getSocket() singleton + signing/types.ts SignCompletedEvent/SignFailedEvent payload shapes"

provides:
  - "lib/api-notifications.ts — 4 typed async clients (listNotifications, unreadCount, markRead, markAllRead) + PersonalNotification domain type"
  - "components/notifications/BellNotification.tsx — self-contained bell component: BellOutlined + Badge + Dropdown + socket listener + toast + stale-while-revalidate"
  - "MainLayout.tsx — bell migrated từ /api/thong-bao (unit-wide notice) sang /api/notifications (personal notifications); sidebar menu '/thong-bao' badge giữ coexist với /api/thong-bao endpoint"

affects:
  - 13-04-root-ca-banner-files (bell metadata.provider_code === 'MYSIGN_VIETTEL' có thể dùng sau để trigger banner — không trực tiếp consume trong Plan 13-04)
  - 13-05-e2e-uat-checkpoint (verify bell dropdown render + toast realtime + offline-safe flow với 2 accounts)

tech-stack:
  added: []
  patterns:
    - "Self-contained bell component — manage state + socket + API nội bộ, parent (MainLayout) chỉ mount 1 tag; pattern tách concern cho bell-level logic không rò rỉ layout"
    - "Stale-while-revalidate dropdown (D-12) — render cached items ngay khi click + fetch mới background; UX không chặn khi có network latency"
    - "Optimistic mark-read UI update — click item → setItems + setUnread ngay + markRead() async; user không chờ round-trip"
    - "Toast qua App.useApp().notification (AntD 6) — success/error với title+description 3s, khác message (chỉ 1 dòng cho form action)"
    - "Reuse global CSS classes — .notif-bell-overlay + .notif-item + .notif-item.unread từ globals.css (đã tồn tại từ Phase 3 bell cũ); zero duplicate CSS"
    - "dayjs relativeTime vi locale — extend plugin + setLocale ở top component module; 'vài giây trước' / '5 phút trước' thay full datetime"
    - "Socket useEffect with open dep — re-subscribe khi dropdown open đổi để refresh logic đọc đúng state (không stale closure)"

key-files:
  created:
    - e_office_app_new/frontend/src/lib/api-notifications.ts
    - e_office_app_new/frontend/src/components/notifications/BellNotification.tsx
  modified:
    - e_office_app_new/frontend/src/components/layout/MainLayout.tsx

key-decisions:
  - "Reuse CSS classes từ globals.css — .notif-bell-overlay + .notif-item + .notif-item.unread đã có từ Phase 3 bell implementation; BellNotification chỉ thêm inline style cho layout flex/gap bên trong item (không override class). Giảm duplicate CSS + giữ theme consistency."
  - "Socket staff_id filter defense-in-depth — SignCompletedEvent/SignFailedEvent payload từ Phase 11 KHÔNG có staff_id field (BE emit vào room user_{staffId} đã scope). FE include currentStaffId trong useEffect deps để re-subscribe khi user switch — KHÔNG filter by payload.staff_id (vì payload không có). Trust room-scoping từ BE."
  - "Giữ coexist 2 bell channel FE-side — sidebar menu '/thong-bao' badge vẫn fetch /api/thong-bao/unread-count (cho notifications unit-wide legacy từ Phase 3); header bell chuyển qua /api/notifications (personal sign events Phase 13). User không confused vì 2 entry point khác nhau, badge count đếm khác nhau logically."
  - "Cleanup unused imports — sau khi xoá bellDropdownContent block, các import Badge + Button + Typography + useCallback không còn dùng trong MainLayout; tsc không error (noUnusedLocals disable) nhưng clean-up để reduce bundle + dễ đọc."
  - "Optimistic UI update on mark-read — setItems + setUnread gọi TRƯỚC markRead(id); nếu BE fail (rare), giữ UI optimistic (user đã rời dropdown, sẽ thấy lại unread ở lần fetch tới). Trade-off: UX nhanh > eventual consistency rare-fail."
  - "Toast message copy theo status — sign_failed có 3 sub-status (failed / expired / cancelled) map thành 3 title khác: 'Ký số thất bại', 'Ký số hết hạn', 'Đã hủy ký số'. Khác với sign_completed chỉ 1 copy 'Ký số thành công'. User nhìn toast biết chính xác điều gì xảy ra."
  - "Path /notifications (không /api/notifications) trong api-notifications.ts — axios instance baseURL='/api' đã có, dùng /notifications tránh double-prefix. Khớp convention 12-02 (/ky-so/...) và 13-01 naming."

requirements-completed:
  - UX-10 (frontend portion — BE đã hoàn thành Plan 13-01)

duration: 8min
started: 2026-04-23T06:38:40Z
completed: 2026-04-23T06:46:48Z
---

# Phase 13 Plan 02: Bell Notification Frontend Summary

**3 tasks shipped — Frontend bell notification UI hoàn tất UX-10: self-contained BellNotification component tiêu thụ /api/notifications (Plan 13-01 BE), migrate bell icon MainLayout từ legacy /api/thong-bao unit-wide sang personal bell cho sign events. Badge count realtime qua Socket, dropdown stale-while-revalidate, dayjs Vietnamese locale, toast 3s khi SIGN_COMPLETED/SIGN_FAILED.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-04-23T06:38:40Z
- **Completed:** 2026-04-23T06:46:48Z
- **Tasks:** 3
- **Files created:** 2
- **Files modified:** 1
- **Build:** PASS (58s compile, 0 error)

## Accomplishments

- `lib/api-notifications.ts` (104 lines, created) — 4 typed async functions (listNotifications, unreadCount, markRead, markAllRead) + 4 response interfaces + 1 domain type (PersonalNotification); snake_case matching BE Plan 13-01 contract; path `/notifications/...` với axios baseURL='/api'
- `components/notifications/BellNotification.tsx` (326 lines, created) — self-contained bell: BellOutlined + Badge count + Dropdown 10 items với status icon (✓ xanh / ✗ đỏ / bell mặc định) + title + message ellipsis + dayjs.fromNow() vi locale; socket listeners SIGN_COMPLETED/SIGN_FAILED → toast 3s + increment badge + refresh dropdown if open; optimistic mark-read on click + navigate; stale-while-revalidate fetch on dropdown open
- `components/layout/MainLayout.tsx` — import + mount `<BellNotification />` thay inline Dropdown bell block (xoá 70-line bellDropdownContent + NotifItem interface + 2 bell handlers + notifItems/bellOpen state); giữ notifUnreadCount + fetchCounts cho sidebar menu '/thong-bao' badge (coexist legacy); cleanup 4 unused imports (useCallback, Badge, Button, Typography)
- Net change: +7 insertions / -134 deletions — replace legacy logic với import + 1-tag component
- TypeScript check PASS (zero new errors trong 3 files scope; baseline errors pre-existing trong khác files không liên quan)
- Frontend build PASS 58s compile

## Task Commits

1. **Task 1: Add bell notification API client wrappers** — `93beb29` (feat)
2. **Task 2: Add BellNotification self-contained component** — `63196fa` (feat)
3. **Task 3: Replace inline bell block với <BellNotification /> trong MainLayout** — `692db86` (feat)

## Files Created/Modified

| File | Status | Lines | Purpose |
|------|--------|-------|---------|
| `e_office_app_new/frontend/src/lib/api-notifications.ts` | Created | 104 | API client wrappers + domain types |
| `e_office_app_new/frontend/src/components/notifications/BellNotification.tsx` | Created | 326 | Self-contained bell component (state + socket + API + toast + dropdown) |
| `e_office_app_new/frontend/src/components/layout/MainLayout.tsx` | Modified (+7/-134) | 735 | Import + mount BellNotification, remove legacy bell logic |

## API Client Contract (consumed từ BE Plan 13-01)

```typescript
listNotifications(page=1, pageSize=10) → ListResponse {
  success, data: PersonalNotification[], pagination: { total, page, pageSize }
}

unreadCount() → number  // extracts data.data.count

markRead(id) → void  // PATCH /notifications/:id/read; 404 cho not-found or IDOR

markAllRead() → { updated_count: number }  // PATCH /notifications/read-all

PersonalNotification {
  id, type, title, message, link, metadata, is_read, created_at, read_at
}
```

## Component Integration Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  Mount on every page (via MainLayout header)                    │
│    ↓                                                            │
│  useEffect: fetchUnreadCount() → setUnread(N)                   │
│    ↓                                                            │
│  Render: <Dropdown> <Badge count={N}> <BellOutlined /> </...>   │
│    ↓                                                            │
│  User click bell:                                               │
│    → setOpen(true) → refreshList()                              │
│    → listNotifications() → setItems + refresh unread            │
│    → Render 10 items với status icon + title + fromNow()        │
│    ↓                                                            │
│  User click item:                                               │
│    → setOpen(false) + optimistic setItems/setUnread             │
│    → markRead(id) async                                         │
│    → router.push(item.link)                                     │
│    ↓                                                            │
│  User click 'Đánh dấu đã đọc tất cả':                           │
│    → markAllRead() → setItems/setUnread 0                       │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  Socket event (from Phase 11 worker emit):                      │
│    SIGN_COMPLETED payload → notification.success 3s             │
│      + setUnread(+1)                                            │
│      + if open, listNotifications() refresh                     │
│    SIGN_FAILED payload (status: failed/expired/cancelled) →     │
│      notification.error với title theo status 3s                │
│      + setUnread(+1)                                            │
│      + if open, listNotifications() refresh                     │
└─────────────────────────────────────────────────────────────────┘
```

## Verification Results

### Success Criteria Grep

```bash
grep -l "BellOutlined" frontend/src/components/layout/MainLayout.tsx  → MATCH
grep -l "BellNotification" frontend/src/components/notifications/BellNotification.tsx  → MATCH
grep -c "/notifications" frontend/src/lib/api-notifications.ts  → 13 (4 endpoint calls + 9 doc/comment)
grep -cE "staff_id === |staffId ===|currentStaffId" BellNotification.tsx  → 4 (useAuthStore usage + deps)
```

### Bell legacy removed from MainLayout

```bash
grep -nE "bellDropdownContent|handleBellOpenChange|handleBellMarkAllRead|setNotifItems|notifItems|bellOpen|NotifItem" MainLayout.tsx
# (empty — all removed)
```

### BellNotification mount in MainLayout

```bash
grep -nE "BellNotification|<BellNotification" MainLayout.tsx
# 51: import BellNotification from '@/components/notifications/BellNotification';
# 447: // Header bell icon đã migrate sang <BellNotification /> consume /api/notifications riêng.
# 710: <BellNotification />
```

### Frontend Build

```
✓ Compiled successfully in 58s
54 static pages + 8 dynamic routes generated
```

### TypeScript Check

Zero new errors trong 3 files scope. Pre-existing baseline errors trong files khác (ho-so-cong-viec, lich/ca-nhan, van-ban-den/[id]...) không liên quan Plan 13-02.

## Threat Model Validation

| Threat ID | Category | Mitigation Implemented | Status |
|-----------|----------|------------------------|--------|
| T-13-08 | Info Disclosure — Socket leak notification của user khác | BE Plan 11-04 emit vào room `user_{staffId}`, FE chỉ nhận event của mình. FE defense-in-depth: useAuthStore currentStaffId trong deps useEffect để re-subscribe khi user switch login | ✓ Mitigated (BE enforcement) |
| T-13-09 | Spoofing — Fake Socket event trong dev console | Accepted — attacker có thể `socket.emit('sign_completed', ...)` từ console để trigger toast + badge++; chỉ cosmetic không destructive; BE verify qua worker emit path | ✓ Accepted (low risk) |
| T-13-10 | Info Disclosure — Notification message chứa PII | BE Plan 13-01 chỉ đưa txn_id + attachment_id + provider_code vào message/metadata; không chứa PII user | ✓ Mitigated (BE payload shape) |
| T-13-11 | DoS — User spam click mark-all-read | Accepted — BE mark-all-read idempotent (0 row affected nếu đã hết unread); rate limit helmet default đủ; SP O(N) với N≤100 | ✓ Accepted (BE idempotent) |
| T-13-12 | Tampering — Click item gọi markRead với id không thuộc user | BE Plan 13-01 SP owner check (WHERE id=$1 AND staff_id=$2); FE chỉ gửi id hiển thị từ list API đã filter theo staff_id — không có UX nào cho phép user nhập id tùy ý | ✓ Mitigated (BE SP check) |

## Decisions Made

### Reuse CSS Classes từ globals.css

**Chosen:** Dùng class `.notif-bell-overlay` (container dropdown) + `.notif-item` + `.notif-item.unread` đã tồn tại trong `src/app/globals.css` (dòng 787-811) từ Phase 3 bell cũ.

**Why:**
- Zero duplicate CSS — responsive rules (mobile breakpoint line 894) + hover/unread states đều đã có
- Consistent theme — cùng màu accent #0891B2 + background #F0F7FF cho unread
- BellNotification inline style CHỈ cho flex/gap inside item body (icon + title + meta column) — không override class
- Nếu sau này design đổi, update 1 chỗ trong globals.css apply tất cả bell UI

### Socket staff_id filter via useAuthStore

**Chosen:** Include `currentStaffId = useAuthStore((s) => s.user?.staffId)` trong useEffect deps thay vì filter `payload.staff_id`.

**Why:**
- `SignCompletedEvent` / `SignFailedEvent` payload từ Phase 11 KHÔNG có `staff_id` field (BE room-scoping đủ tin, payload shape không include redundant data)
- Defense-in-depth: re-subscribe listener khi user switch login (logout → login user khác) — đảm bảo listener bind đúng socket của current user
- Nếu sau này payload thêm `staff_id`, có thể filter trong callback dễ dàng — infrastructure sẵn sàng

### Coexist 2 Bell Channels FE

**Chosen:** Header bell → `/api/notifications` (Phase 13 personal). Sidebar menu `/thong-bao` badge → `/api/thong-bao/unread-count` (Phase 3 legacy unit-wide).

**Why:**
- 2 entry points logically different:
  - Header bell: notifications cá nhân quan trọng realtime (sign events, sau có thể thêm VB assign, HSCV deadline...)
  - Sidebar menu + `/thong-bao` page: notice unit-wide (công văn chung, thông báo cả cơ quan)
- Badge count khác nhau user không confused vì context khác nhau
- FE Plan 13-02 chỉ scope bell header, không touch `/thong-bao` page (backwards-compat Phase 3)
- Cost coexist: 2 endpoint call mỗi mount MainLayout — rate thấp, 1 call cho mỗi; zero impact performance

### Toast Copy per sign_failed Sub-status

**Chosen:** 3 title khác cho `sign_failed`:
- `status === 'expired'` → "Ký số hết hạn"
- `status === 'cancelled'` → "Đã hủy ký số"
- Default (`status === 'failed'`) → "Ký số thất bại"

**Why:**
- User nhìn toast biết chính xác điều gì xảy ra — "hết hạn" vs "thất bại" có ý nghĩa khác (expired: không xác nhận OTP trong 3 phút; failed: provider reject); cancelled: user chủ động hủy trên modal
- Map 1:1 với BE emitSignFailed payload status — không cần lookup table riêng
- Copy Vietnamese có dấu (diacritics mandatory per CLAUDE.md)

## Deviations from Plan

None — plan thực hiện chính xác 3 tasks đúng spec D-08 → D-12. Pattern cleanup unused imports là discretionary cleanup trong Task 3 Step 4 plan cho phép.

## Issues Encountered

- **Pre-existing TypeScript baseline errors** trong các files khác (không liên quan Plan 13-02) — scope boundary: không auto-fix (Rule scope: chỉ fix issues DO thay đổi của task này gây ra). Documented trong Self-Check.
- **Read-before-edit hook reminders** — hook nhắc re-read MainLayout.tsx trước mỗi Edit; đã read full file ở đầu session, các edit đều tiếp nhận thành công (hook là reminder, không block).

## How Downstream Plans Consume This

### Plan 13-04 (Root CA banner files)

**Not directly consumed** — Root CA banner trong `/ky-so/danh-sach` page trigger qua localStorage flag khi user click download signed PDF của MYSIGN_VIETTEL, không phụ thuộc bell component. Nhưng metadata bell notification có `provider_code` → nếu sau này muốn, banner có thể consume notification history để show auto.

### Plan 13-05 (E2E + UAT checkpoint)

**Verify:**
- Login admin → thấy Badge count=2 (2 notifications seed từ Plan 13-01 Task 3)
- Click bell → dropdown mở, 2 items render với status icon ✓/✗ + title tiếng Việt + "vài giây trước"
- Click item → navigate `/ky-so/danh-sach?tab=completed|failed` + badge giảm 1
- Click "Đánh dấu đã đọc tất cả" → badge=0
- Socket realtime: trigger ký số → DB insert row + socket emit → toast success/error 3s xuất hiện top-right + badge++
- Offline user: tắt tab trước khi provider complete → login lại → badge vẫn >0 (DB source of truth)
- IDOR test: 2 accounts A + B — user A không thấy notification của user B trong bell dropdown

## Environment Variables Added

None.

## Known Stubs

None — tất cả functionality wired end-to-end với BE Plan 13-01 endpoints. Không có placeholder UI hay mock data trong FE.

## Self-Check

Verified before declaring complete:

- `e_office_app_new/frontend/src/lib/api-notifications.ts` — FOUND (104 lines, created)
- `e_office_app_new/frontend/src/components/notifications/BellNotification.tsx` — FOUND (326 lines, created)
- `e_office_app_new/frontend/src/components/layout/MainLayout.tsx` — MODIFIED (735 lines, +7/-134)
- Commit `93beb29` (Task 1) — FOUND in git log
- Commit `63196fa` (Task 2) — FOUND in git log
- Commit `692db86` (Task 3) — FOUND in git log
- `grep "BellOutlined" MainLayout.tsx` — MATCH
- `grep "BellNotification" BellNotification.tsx` — MATCH
- `grep "/notifications" api-notifications.ts` — 13 matches (4 API calls)
- `grep "currentStaffId|staffId" BellNotification.tsx` — 4 matches (useAuthStore integration)
- Bell legacy handlers removed (bellDropdownContent, handleBellOpenChange, handleBellMarkAllRead, notifItems, bellOpen, NotifItem) — zero match in MainLayout.tsx
- Frontend build — PASS (58s compile, zero error, 54 static + 8 dynamic routes generated)
- TypeScript check for 3 scope files — zero new errors (pre-existing baseline in other files)

## Self-Check: PASSED

---
*Phase: 13-modal-ky-so-robust-root-ca-ux*
*Completed: 2026-04-23*
