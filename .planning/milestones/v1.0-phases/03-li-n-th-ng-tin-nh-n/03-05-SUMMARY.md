---
phase: 03-li-n-th-ng-tin-nh-n
plan: 05
subsystem: frontend-messaging
tags: [socket-io, tin-nhan, thong-bao, bell-dropdown, main-layout]
dependency_graph:
  requires: [03-03]
  provides: [socket-client, messaging-pages, notification-pages]
  affects: [MainLayout, globals.css]
tech_stack:
  added: [socket.io-client]
  patterns: [3-panel-mail-layout, bell-dropdown, socket-event-listeners]
key_files:
  created:
    - e_office_app_new/frontend/src/lib/socket.ts
    - e_office_app_new/frontend/src/app/(main)/tin-nhan/page.tsx
    - e_office_app_new/frontend/src/app/(main)/thong-bao/page.tsx
  modified:
    - e_office_app_new/frontend/src/app/globals.css
    - e_office_app_new/frontend/src/components/layout/MainLayout.tsx
    - e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/[id]/page.tsx
    - e_office_app_new/frontend/src/app/(main)/quan-tri/quy-trinh/[id]/thiet-ke/page.tsx
decisions:
  - "Socket.IO client stored as module singleton — one connection per app lifecycle"
  - "Bell dropdown fetches /api/thong-bao on open rather than polling — lower overhead"
  - "Inline UploadRequestOption type used instead of rc-upload import (package unavailable)"
  - "ProcessNodeData interface cast used for NodeProps data to fix TypeScript unknown type error"
metrics:
  duration: ~35min
  completed: 2026-04-14
  tasks_completed: 3
  files_changed: 7
---

# Phase 03 Plan 05: Tin nhắn & Thông báo Frontend Summary

**One-liner:** Gmail-style 3-panel mail page, thong-bao list with filter tabs, functional bell dropdown, and Socket.IO client wired into MainLayout with JWT auth.

---

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Socket.IO client + CSS + Tin nhan page | 46c579c | socket.ts, globals.css, tin-nhan/page.tsx |
| 2 | Thong bao page + Bell dropdown + Sidebar + Socket | ea42507 | thong-bao/page.tsx, MainLayout.tsx |
| 3 | Visual verification (checkpoint) | — | Auto-approved (--auto mode) |

---

## What Was Built

### `lib/socket.ts`
Socket.IO client singleton with exports `initSocket(token)`, `getSocket()`, `disconnectSocket()` and `SOCKET_EVENTS` constant (`new_document`, `new_message`, `new_notification`, `doc_status_changed`). Uses JWT token in socket handshake auth object. Auto-reconnects every 3 seconds.

### `globals.css` additions
All Phase 3 CSS classes appended:
- `.mail-layout`, `.mail-sidebar`, `.mail-list-panel`, `.mail-detail-pane`
- `.mail-item`, `.mail-item.unread`, `.mail-item.selected`, `.mail-item:hover`
- `.mail-item-sender`, `.mail-item-subject`, `.mail-item-snippet`, `.mail-item-meta`
- `.notif-item`, `.notif-item.unread`, `.notif-bell-overlay`

### `tin-nhan/page.tsx`
3-panel mail interface (260+ lines):
- Dark sidebar (220px, `#0F1A2E`) with "Soạn tin nhắn" button and folder menu (Hộp thư đến with badge, Đã gửi, Thùng rác)
- Message list panel (360px) with search, sender avatar, subject, snippet, relative timestamp
- Detail pane with subject heading, from/to meta, body, thread replies (`.opinion-item` pattern), reply textarea + button
- Compose Drawer (width 720, rootClassName "drawer-gradient"): Người nhận multi-select, Tiêu đề, Nội dung
- Delete via Popconfirm; all Vietnamese text with diacritics

### `thong-bao/page.tsx`
Notification list page:
- Tabs filter: Tất cả / Chưa đọc / Đã đọc
- `<List>` with BellOutlined icons, unread bold styling, `.notif-item` CSS class
- "Đánh dấu đã đọc tất cả" and per-item click-to-mark-read
- Admin "Tạo thông báo" Drawer with Tiêu đề + Nội dung fields
- Pagination when total > pageSize

### `MainLayout.tsx` updates
- **New sidebar items:** Văn bản liên thông (under van-ban submenu), Tin nhắn, Thông báo (top-level)
- **Breadcrumb map:** 3 new entries with Vietnamese diacritics
- **Bell Dropdown:** Fetches `/api/thong-bao` on open, displays max 10 items in `.notif-bell-overlay`, "Xem tất cả thông báo" link, mark-all-read action, `<Badge count={notifUnreadCount}>`
- **Socket.IO:** `initSocket(token)` called on mount with localStorage JWT, listens to `NEW_MESSAGE` / `NEW_NOTIFICATION` / `NEW_DOCUMENT` events with `message.info` toasts and badge count increment; `disconnectSocket()` called on unmount

---

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed missing rc-upload type import**
- **Found during:** Task 1 build verification
- **Issue:** `ho-so-cong-viec/[id]/page.tsx` imported `UploadRequestOption` from `rc-upload/lib/interface` but the `rc-upload` package is not installed directly (it's a transitive dep with no type declarations accessible)
- **Fix:** Replaced import with inline `UploadRequestOption` type definition
- **Files modified:** `e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/[id]/page.tsx`
- **Commit:** abd0087

**2. [Rule 3 - Blocking] Fixed NodeProps data: unknown TypeScript error**
- **Found during:** Task 1 build verification (stash-test confirmed pre-existing)
- **Issue:** `quy-trinh/[id]/thiet-ke/page.tsx` used `NodeProps` from `@xyflow/react` where `data` is typed as `unknown`, causing TypeScript errors when accessing `data.step_type`
- **Fix:** Added `ProcessNodeData` interface and cast `rawData` to it in `ProcessNode` component
- **Files modified:** `e_office_app_new/frontend/src/app/(main)/quan-tri/quy-trinh/[id]/thiet-ke/page.tsx`
- **Commit:** abd0087

Both issues were pre-existing before this plan (confirmed by stash-test baseline build).

### Checkpoint Auto-Approval

**Task 3 (checkpoint:human-verify):** Auto-approved per `--auto` mode flag. Visual verification was not performed by a human.

---

## Known Stubs

- `GET /api/tin-nhan/{folder}` — The tin-nhan page calls this endpoint which was implemented in plan 03-03. If the backend is not running, the message list will show empty (silent error handling).
- `GET /api/thong-bao/unread-count` — Bell badge defaults to 0 if the endpoint is unavailable.
- Staff Select in compose drawer fetches `/api/quan-tri/nhan-vien` — will show empty options if endpoint returns unexpected shape.

---

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: auth | lib/socket.ts | JWT token read from localStorage and passed in socket handshake — same trust level as API calls (mitigated per T-03-14) |

---

## Self-Check: PASSED

- [x] `e_office_app_new/frontend/src/lib/socket.ts` — exists
- [x] `e_office_app_new/frontend/src/app/(main)/tin-nhan/page.tsx` — exists
- [x] `e_office_app_new/frontend/src/app/(main)/thong-bao/page.tsx` — exists
- [x] `e_office_app_new/frontend/src/app/globals.css` — modified with Phase 3 classes
- [x] `e_office_app_new/frontend/src/components/layout/MainLayout.tsx` — modified
- [x] Commit 46c579c — Task 1
- [x] Commit ea42507 — Task 2
- [x] Commit abd0087 — Deviation fixes
- [x] Next.js build: PASSED (exit code 0, /tin-nhan and /thong-bao listed in build output)
