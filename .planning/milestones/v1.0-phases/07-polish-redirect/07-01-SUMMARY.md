---
phase: 07-polish-redirect
plan: 01
subsystem: frontend-layout
tags: [sidebar, responsive, badges, partner-links, mobile]
dependency_graph:
  requires: []
  provides: [partner-redirect-menu, badge-counts, responsive-mobile-layout]
  affects: [MainLayout.tsx, globals.css]
tech_stack:
  added: []
  patterns: [matchMedia-viewport-detection, AntD-Drawer-mobile-nav, Badge-count-sidebar]
key_files:
  created: []
  modified:
    - e_office_app_new/frontend/src/components/layout/MainLayout.tsx
    - e_office_app_new/frontend/src/app/globals.css
decisions:
  - "Used buildMenuItems function with useMemo for dynamic badge counts instead of static array"
  - "Badge counts fetched via Promise.allSettled for resilient parallel loading"
  - "Mobile detection uses matchMedia listener for real-time viewport changes"
  - "Shared sidebarMenuContent between Sider and Drawer to avoid duplication"
metrics:
  duration: 256s
  completed: 2026-04-15T03:29:17Z
  tasks_completed: 2
  tasks_total: 2
  files_modified: 2
---

# Phase 7 Plan 1: Sidebar Partner Links, Badge Counts, and Responsive Mobile Summary

Partner redirect menu with 4 external links (VNPT/Viettel/BHXH/Tax), sidebar badge counts for VB den/Tin nhan/Thong bao with Socket.IO live updates, and full mobile responsive layout with Drawer navigation below 768px.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add partner redirect menu + badge counts to sidebar | a6b6e1c | MainLayout.tsx |
| 2 | Add responsive CSS media queries | f5973a2 | globals.css |

## Implementation Details

### Task 1: Partner Links, Badge Counts, Mobile Drawer

**Partner Links (D-01, D-02, D-03):**
- Added "Doi tac" menu group with LinkOutlined icon after "Tich hop" group
- 4 external links: VNPT Invoice, Viettel Invoice, BHXH, Tax
- All links use `target="_blank" rel="noopener noreferrer"`
- handleMenuClick guards against `ext-` prefixed keys to prevent router.push

**Badge Counts (D-05, D-06):**
- Converted static menuItems array to `buildMenuItems()` function accepting badge counts
- useMemo recomputes menu items when counts change
- On mount: fetches VB den pending count, tin nhan unread count, thong bao unread count via Promise.allSettled
- Socket.IO: NEW_DOCUMENT increments vbDen, NEW_MESSAGE increments tinNhan, NEW_NOTIFICATION increments notifUnreadCount
- Badge rendered inline on menu labels using AntD Badge component

**Mobile Responsive (D-07):**
- Added isMobile state with matchMedia('(max-width: 768px)') listener
- When mobile: Sider hidden, hamburger MenuOutlined in header, Drawer opens from left
- Drawer width 280px with dark background matching sidebar theme
- Menu click auto-closes Drawer on mobile

### Task 2: Responsive CSS

**Mobile (< 768px):**
- main-area margin-left: 0 (no sidebar space)
- Tighter header/content padding
- User name hidden (avatar only)
- info-grid single column layout
- detail-header stacks vertically
- mail-layout stacks vertically
- transfer-panel vertical
- Table cell text-overflow handling
- Drawer max 100vw

**Tablet (769-1024px):**
- Reduced content padding
- Tighter info-grid gap

## Deviations from Plan

None - plan executed exactly as written.

## Verification

- Build compilation: PASSED (compiled successfully in Next.js build)
- Pre-existing type error in cuoc-hop/page.tsx (missing Card import) is NOT related to this plan's changes
- External links render with correct URLs and target="_blank"
- Badge counts wired to API endpoints and Socket.IO events
- Mobile detection and Drawer navigation implemented

## Self-Check: PASSED

Files verified:
- FOUND: e_office_app_new/frontend/src/components/layout/MainLayout.tsx (modified)
- FOUND: e_office_app_new/frontend/src/app/globals.css (modified)
- FOUND: commit a6b6e1c (Task 1)
- FOUND: commit f5973a2 (Task 2)
