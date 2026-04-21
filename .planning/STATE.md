---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: Production features — Tích hợp ký số 2 kênh
status: defining_requirements
stopped_at: Milestone v2.0 initialized
last_updated: "2026-04-21T04:00:00.000Z"
last_activity: 2026-04-21 - Milestone v2.0 started — Tích hợp ký số SmartCA VNPT + MySign Viettel
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-21 — Milestone v2.0 started)

**Core value:** Luồng văn bản đến → xử lý → văn bản đi phải hoạt động đúng nghiệp vụ cơ quan nhà nước
**Current focus:** Milestone v2.0 — Tích hợp ký số 2 kênh (SmartCA VNPT + MySign Viettel)

## Current Position

Phase: Not started (defining requirements)
Plan: —
Status: Defining requirements
Last activity: 2026-04-21 — Milestone v2.0 started

Progress: [░░░░░░░░░░] 0%

## Performance Metrics

**Velocity (v1.0 baseline):**

- Total plans completed (v1.0): 26
- v1.0 duration: 4 days (2026-04-14 → 2026-04-18)
- v1.0 achievement: 7 phases + 3 quick plans, 97.8% HDSD coverage (92 test cases)

**v2.0 tracking:** Reset — metrics populated as plans complete

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.

**Key v2.0 decisions (2026-04-21):**

- 1 provider active cho toàn hệ thống (không multi song song) — đơn giản support/billing
- Pure JS PDF signing với `node-signpdf` + `node-forge` — không cần Java/DotNet runtime
- Async decoupled worker (BullMQ poll 5s × max 3 phút) — user tắt UI vẫn ký OK
- Menu "Ký số" riêng ở sidebar với 3 submenu — tập trung quản lý ký số
- 2 cấp cấu hình: Admin (provider + credentials) → User (user_id + cert)
- Test connection bắt buộc khi Admin lưu config
- Lưu `sign_provider_code` vào attachments + transactions để đổi provider không mất lịch sử
- Migration `staff.sign_phone` → table mới `staff_signing_config` (multi-provider schema)
- Root CA Viettel: KHÔNG code trong hệ thống, chỉ show banner link + HDSD PDF + `.cer` file
- Ký lại sau fail: tạo transaction MỚI (giữ record cũ cho audit), không reset record cũ

### Pending Todos

- Waiting for REQUIREMENTS.md generation
- Waiting for ROADMAP.md generation
- Waiting for `/gsd-plan-phase` on first v2.0 phase

### Blockers/Concerns

- **SmartCA VNPT credentials thực tế**: client_id/secret trong source cũ (`Web.config`) có thể đã hết hạn hoặc cho dev env. Cần KH cấp credentials production khi triển khai.
- **MySign Viettel credentials**: chưa có — cần KH đăng ký với Viettel để lấy `client_id`, `client_secret`, `profile_id`.
- **Không test được ký thật** trong môi trường dev (không có số ĐT thật đăng ký SmartCA / không có app MySign). User đã confirm chấp nhận: code đầy đủ, test khi triển khai production.

### Reference Docs (v2.0)

- `docs/huong_dan_tich_hop_ky_so_MySign_Viettel/Tai lieu tich hop dich vu Mysign API+SDK v1.9.pdf` — MySign API spec
- `docs/huong_dan_tich_hop_ky_so_MySign_Viettel/Viettel Mysign Gateway.postman_collection.json` — 4 API endpoints
- `docs/huong_dan_tich_hop_ky_so_MySign_Viettel/HUONG DAN CAI DAT CTS ROOT CA VIETTEL Mysign.pdf` — HDSD cài Root CA (cho end user)
- `docs/source_code_cu/sources/OneWin.WebApp/SmartCA_VNPT/Model.cs` — VNPT SmartCA reference implementation (3 endpoints, credentials trong Web.config)

### v1.0 Quick Tasks (archive reference)

v1.0 hoàn thành với 3 quick tasks (HDSD Compliance sprint cuối):

| # | Description | Commit |
|---|-------------|--------|
| 260418-gs7 | Phase 1 — ẩn các module chưa có trong HDSD cũ | 8afd6d7 |
| 260418-hlj | HDSD Compliance P0+P1 — SmartCA UI + thu hồi VB liên thông + HSCV mở lại/lấy số | f189464 |
| 260418-jsd | HDSD Compliance — fix 6 gap (ký số mock OTP + trục CP mock + ...) | 26caf2b |

## Session Continuity

Last session: 2026-04-21T04:00:00.000Z
Stopped at: Milestone v2.0 initialized — ready to define REQUIREMENTS.md
Resume: `/gsd-plan-phase [N]` sau khi ROADMAP.md được tạo
