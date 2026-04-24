---
phase: "06"
plan: "03"
subsystem: "signing-notifications-backend"
tags: [digital-signing, notifications, bullmq-workers, mock-services]
dependency_graph:
  requires: ["06-01 (migrations)", "06-02 (LGSP backend + queue client)"]
  provides: ["Signing API endpoints", "Notification API endpoints", "Mock notification workers"]
  affects: ["server.ts route mounts", "error-handler.ts constraint mappings", "workers/index.ts"]
tech_stack:
  added: []
  patterns: ["ISigningService factory pattern with MOCK_EXTERNAL toggle", "BullMQ worker notification_log status updates"]
key_files:
  created:
    - e_office_app_new/backend/src/services/signing.service.ts
    - e_office_app_new/backend/src/services/signing-mock.service.ts
    - e_office_app_new/backend/src/repositories/digital-signature.repository.ts
    - e_office_app_new/backend/src/routes/digital-signature.ts
    - e_office_app_new/backend/src/repositories/notification.repository.ts
    - e_office_app_new/backend/src/routes/notification.ts
  modified:
    - e_office_app_new/backend/src/lib/error-handler.ts
    - e_office_app_new/backend/src/server.ts
    - e_office_app_new/workers/src/index.ts
decisions:
  - "SmartCA uses 2-step flow (initiate -> OTP verify), EsignNEAC uses 1-step immediate sign"
  - "All notification workers update notification_log status via fn_notification_log_update_status SP"
  - "send-test debug endpoint enqueues to all 4 channel-specific queues (fcm, zalo, sms, email)"
metrics:
  duration: "~5 min"
  completed: "2026-04-15"
  tasks_completed: 2
  tasks_total: 2
  files_created: 6
  files_modified: 3
---

# Phase 6 Plan 3: Signing + Notification Backend Summary

Signing service with SmartCA/EsignNEAC mock via ISigningService factory, notification repository + routes + 4 BullMQ workers with mock send logic and notification_log status tracking.

## Task Results

| Task | Name | Commit | Status |
|------|------|--------|--------|
| 1 | Signing service interface/mock + repository + routes | b2cb066 | Done |
| 2 | Notification repository + routes + workers mock + error-handler + server mounts | 5730129 | Done |

## What Was Built

### Task 1: Signing Service + Repository + Routes

**ISigningService interface** (`signing.service.ts`):
- `signSmartCA()` -- 2-step: creates signature record with 'signing' status, returns `requires_otp: true`
- `signEsignNEAC()` -- 1-step: creates signature record, immediately marks 'signed' with mock cert
- `verifyOTP()` -- completes SmartCA flow, updates status to 'signed' with certificate info
- Factory `getSigningService()` returns mock when `MOCK_EXTERNAL=true`

**Mock implementation** (`signing-mock.service.ts`):
- All methods log with `MOCK:` prefix and persist via digitalSignatureRepository
- Mock certificate serials: `MOCK-CERT-{timestamp}`, `MOCK-NEAC-{timestamp}`
- Mock signed file paths: `signed/{uuid}.pdf`

**Repository** (`digital-signature.repository.ts`):
- 4 methods calling exact SP names: `fn_digital_signature_create`, `fn_digital_signature_update_status`, `fn_digital_signature_get_by_doc`, `fn_digital_signature_get_by_id`
- Row interfaces match SP RETURNS TABLE columns exactly

**Routes** (`digital-signature.ts`) -- 5 endpoints:
- `POST /sign/smart-ca` -- initiate SmartCA signing
- `POST /sign/esign-neac` -- immediate EsignNEAC signing
- `POST /sign/verify-otp` -- verify SmartCA OTP
- `GET /doc/:docId/:docType` -- signatures by document
- `GET /:id` -- signature by ID

### Task 2: Notification Repository + Routes + Workers + Integration

**Repository** (`notification.repository.ts`):
- 8 methods for device tokens (upsert, get, delete), notification logs (create, update status, list), preferences (upsert, get)
- All SP names match migration 021 exactly

**Routes** (`notification.ts`) -- 7 endpoints:
- `POST /device-tokens` -- register device token (staffId from JWT)
- `GET /device-tokens` -- list user's tokens
- `DELETE /device-tokens/:id` -- remove token (ownership via staffId)
- `GET /logs` -- notification history with pagination
- `GET /preferences` -- user notification preferences
- `PUT /preferences` -- update channel preference
- `POST /send-test` -- debug: enqueue test to all 4 queues

**Workers updated** (`workers/src/index.ts`):
- `email-send`: MOCK: Email sent with title/body logging + notification_log update
- `sms-send`: MOCK: SMS sent with body logging + notification_log update
- `fcm-push`: MOCK: FCM push sent with title logging + notification_log update
- `zalo-send`: MOCK: Zalo OA message sent + notification_log update
- All workers call `edoc.fn_notification_log_update_status` on success/failure

**Error handler**: Added `uq_lgsp_org_code`, `uq_device_token`, `uq_notif_pref_staff_channel`

**Server mounts**: `/api/ky-so` and `/api/thong-bao-kenh` with authenticate middleware

## Deviations from Plan

None -- plan executed exactly as written.

## Known Stubs

None -- all endpoints and workers have complete mock implementations.

## Self-Check: PASSED

- All 6 created files exist on disk
- Both commit hashes (b2cb066, 5730129) verified in git log
- TypeScript compiles with zero new errors
