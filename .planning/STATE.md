---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
stopped_at: Completed 09-01-PLAN.md (Phase 9 Plan 1 — provider adapters + factory ready for Plan 02 API routes)
last_updated: "2026-04-21T07:31:23.234Z"
last_activity: 2026-04-21
progress:
  total_phases: 9
  completed_phases: 8
  total_plans: 40
  completed_plans: 38
  percent: 95
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-21 — Milestone v2.0 started)

**Core value:** Luồng văn bản đến → xử lý → văn bản đi phải hoạt động đúng nghiệp vụ cơ quan nhà nước
**Current focus:** Phase 9 — Admin config API + provider adapters (SmartCA VNPT + MySign Viettel)

## Current Position

Phase: 9
Plan: 1/3 (09-01 complete — provider adapters)
Status: In progress — Plan 02 (Admin config API) next
Last activity: 2026-04-21

Progress: [██████████] 95% (38/40 plans complete)

## Performance Metrics

**Velocity (v1.0 baseline):**

- Total plans completed (v1.0): 26
- v1.0 duration: 4 days (2026-04-14 → 2026-04-18)
- v1.0 achievement: 7 phases + 3 quick plans, 97.8% HDSD coverage (92 test cases)

**v2.0 tracking:** Reset — metrics populated as plans complete

**v2.0 planned phases (Phase 8-14):**

| Phase | Title | REQ count | Dependency |
|-------|-------|-----------|------------|
| 8 | Schema foundation + PDF signing layer | 5 | — (v1.0 shipped) |
| 9 | Admin config + provider adapters | 7 | Phase 8 |
| 10 | User config page + migrate tab | 3 | Phase 9 |
| 11 | Sign flow + async worker (core) | 12 | Phase 10 |
| 12 | Menu Ký số + Danh sách 4 tab UI | 7 | Phase 11 |
| 13 | Modal ký số robust + Root CA UX | 6 | Phase 12 |
| 14 | Deployment + HDSD + verification | 2 | Phase 13 |

**Total: 42 REQ-IDs (100% coverage, no orphans)**
| Phase 08 P01 | 25min | 2 tasks | 1 files |
| Phase 08 P02 | 10min | 1 tasks | 1 files |
| Phase 08 P03 | 12min | 2 tasks | 3 files |
| Phase 08 P04 | 5min | 2 tasks | 5 files |
| Phase 09 P01 | 10min | 3 tasks | 6 files |

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

**Roadmap decisions (2026-04-21):**

- Phase granularity: coarse (7 phases cho 42 REQs — trung bình 6 REQs/phase)
- Phase 8 = foundation (schema + generic PDF layer) không có UI → giúp downstream không block bởi UI changes
- Phase 11 là phase lớn nhất (12 REQs) nhưng coherent: toàn bộ core sign flow + async worker phải ship cùng lúc để user test được end-to-end
- Phase 14 tách riêng deployment để ensure HDSD + seed scripts không bị quên cuối milestone
- [Phase 08]: BYTEA client_secret forces Node-side pgp_sym_encrypt at boundary (plaintext column rejected)
- [Phase 08]: Partial unique index on is_active=TRUE gives database-level single-active provider guarantee (vs trigger)
- [Phase 08]: attachment_type enum includes handling (4 values) to match plan's ALTER of attachment_handling_docs
- [Phase 08]: [Phase 08-02]: Data migration DO block pattern — info_schema guard + EXECUTE dynamic SQL + ON CONFLICT DO NOTHING + target>=source verify + RAISE EXCEPTION rollback — re-runnable forever
- [Phase 08]: [Phase 08-02]: Keep sign_ca + sign_image in staff table — out of scope MIG-04; sign_ca for UI cert subject display, sign_image for PDF stamp
- [Phase 08]: PrecomputedSigner pattern — extend @signpdf/utils.Signer to embed external provider signatures without local key access
- [Phase 08]: pdf-lib requires useObjectStreams:false for compatibility with @signpdf/placeholder-plain (classic xref only)
- [Phase 08]: Use Node builtin test runner (node:test via tsx) for signing unit tests — no jest/vitest dependency added
- [Phase 08]: [Phase 08-04]: SIGNING_SECRET_KEY fail-fast validation (throw on unset/<16 chars) — no weak default to avoid accidental production ship
- [Phase 08]: [Phase 08-04]: Wave 2 rule caught SP drift — pg_get_function_result() revealed fn_sign_transaction_increment_retry returns new_retry_count (plan had stale retry_count). Repository interface fixed before runtime bug.
- [Phase 09]: [Phase 09-01]: Node fetch thay vì axios — backend package.json không có axios (frontend-only), Node 18+ fetch + AbortController đủ cho JSON POST timeout
- [Phase 09]: [Phase 09-01]: HttpClient interface + DI factory — tests inject mock qua create*Provider(httpClient?), production dùng singleton với default fetch wrapper
- [Phase 09]: [Phase 09-01]: Stateless MySign adapter (no token cache) — fresh login every call prevents race in Phase 11 multi-concurrency BullMQ worker
- [Phase 09]: [Phase 09-01]: SmartCA getSignStatus là POST (không GET) — Model.cs Query() helper hardcode POST, plan draft sai method

### Pending Todos

- `/gsd-plan-phase 8` — lên kế hoạch chi tiết Phase 8 (schema foundation + PDF signing layer)
- Chuẩn bị docs reference cho Phase 9: đối chiếu code cũ `OneWin.WebApp/SmartCA_VNPT/Model.cs` (3 endpoints VNPT) và postman collection MySign Viettel (4 endpoints)

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

Last session: 2026-04-21T07:31:23.220Z
Stopped at: Completed 09-01-PLAN.md (Phase 9 Plan 1 — provider adapters + factory ready for Plan 02 API routes)
Resume: `/gsd-plan-phase 8`
