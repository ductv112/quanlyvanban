---
phase: 06-t-ch-h-p-h-th-ng-ngo-i
plan: 04
subsystem: ui
tags: [react, antd, lgsp, digital-signature, notification, frontend]

# Dependency graph
requires:
  - phase: 06-02
    provides: LGSP backend routes and repository
  - phase: 06-03
    provides: Signing and notification backend routes and repositories
provides:
  - LGSP tracking list page with direction/status filters
  - LGSP organization sync page with search and sync button
  - SigningModal component (SmartCA 2-step OTP + EsignNEAC 1-step)
  - Notification channel preferences page with Switch toggles
  - Notification logs table with channel/status filters
  - Sidebar navigation updated with Tich hop group
affects: [06-05, van-ban-di, van-ban-du-thao]

# Tech tracking
tech-stack:
  added: []
  patterns: [signing-modal-3-step-flow, channel-preference-switch-toggle]

key-files:
  created:
    - e_office_app_new/frontend/src/app/(main)/lgsp/page.tsx
    - e_office_app_new/frontend/src/app/(main)/lgsp/co-quan/page.tsx
    - e_office_app_new/frontend/src/components/signing/SigningModal.tsx
    - e_office_app_new/frontend/src/app/(main)/thong-bao-kenh/page.tsx
  modified:
    - e_office_app_new/frontend/src/components/layout/MainLayout.tsx

key-decisions:
  - "SigningModal uses 3-step flow (choose -> verify -> result) matching SmartCA 2-step and EsignNEAC 1-step"
  - "Notification preferences use Switch toggle per channel with immediate API save"
  - "Sidebar groups LGSP and notification under Tich hop parent menu"

patterns-established:
  - "SigningModal: reusable modal accepting docId/docType/filePath props for integration into VB di and VB du thao"
  - "Channel preference toggle: immediate PUT on Switch change with optimistic UI update"

requirements-completed: [LGSP-03, LGSP-04, SIGN-03, NOTIF-01, NOTIF-02, NOTIF-03, NOTIF-04]

# Metrics
duration: 4min
completed: 2026-04-15
---

# Phase 6 Plan 4: Frontend Pages for LGSP, Signing, and Notifications Summary

**LGSP tracking/org pages, SigningModal with SmartCA+EsignNEAC flows, notification preferences with channel toggles, sidebar navigation updated**

## What Was Built

### Task 1: LGSP Tracking + Organization Pages + SigningModal

1. **LGSP Tracking Page** (`/lgsp/page.tsx`): Table listing LGSP tracking records with filters for direction (send/receive) and status (pending/processing/success/error). Field names match `LgspTrackingRow` exactly: `direction`, `dest_org_name`, `lgsp_doc_id`, `status`, `sent_at`, `received_at`, `created_at`. API: `GET /api/lgsp/tracking`.

2. **LGSP Organizations Page** (`/lgsp/co-quan/page.tsx`): Table listing LGSP-connected organizations with search. Sync button triggers `POST /api/lgsp/organizations/sync` and shows synced count. Field names match `LgspOrgRow`: `org_code`, `org_name`, `address`, `email`, `phone`, `is_active`, `synced_at`.

3. **SigningModal Component** (`/components/signing/SigningModal.tsx`): Reusable modal with 3-step flow:
   - Step 1 (Choose): Radio group for SmartCA/EsignNEAC/USB Token (disabled)
   - Step 2 (Verify): OTP input for SmartCA, CA provider select for EsignNEAC
   - Step 3 (Result): Success/error display with certificate info
   - Existing signatures table below modal content
   - APIs: `POST /api/ky-so/sign/smart-ca`, `POST /api/ky-so/sign/esign-neac`, `POST /api/ky-so/sign/verify-otp`, `GET /api/ky-so/doc/:docId/:docType`

### Task 2: Notification Preferences + Sidebar Update

4. **Notification Channel Page** (`/thong-bao-kenh/page.tsx`): Two cards:
   - Channel preferences: 4 channels (FCM, Zalo, SMS, Email) with Switch toggles. API: `GET /api/thong-bao-kenh/preferences`, `PUT /api/thong-bao-kenh/preferences`.
   - Notification logs: Table with channel/status filters. API: `GET /api/thong-bao-kenh/logs`.

5. **MainLayout Sidebar**: Added "Tich hop" group with 3 items: Lien thong van ban (`/lgsp`), Co quan lien thong (`/lgsp/co-quan`), Cau hinh thong bao (`/thong-bao-kenh`). Added breadcrumb entries.

## Deviations from Plan

None - plan executed exactly as written.

## Commits

| # | Hash | Message |
|---|------|---------|
| 1 | 64a8ff6 | feat(06-04): LGSP tracking page, org sync page, and SigningModal component |
| 2 | 5cfd140 | feat(06-04): notification preferences page and sidebar navigation update |

## Self-Check: PASSED

All 4 created files verified on disk. Both commits (64a8ff6, 5cfd140) confirmed in git log.
