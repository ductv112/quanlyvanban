---
gsd_state_version: 1.0
milestone: v3.0
milestone_name: chuan-hoa-quy-trinh-van-ban
status: planning
stopped_at: Milestone v2.0 archived 2026-04-23
last_updated: "2026-04-23T10:00:00.000Z"
last_activity: 2026-04-23
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md

**Core value:** Luồng văn bản đến → xử lý → văn bản đi phải hoạt động đúng nghiệp vụ cơ quan nhà nước
**Current focus:** Milestone v3.0 — Chuẩn hoá data model + workflow nghiệp vụ văn bản

## Current Position

Milestone: v3.0 (Active)
Phase: 15 (next — Audit & design data model)
Plan: Not started
Status: Milestone v2.0 vừa archive, chờ /gsd-new-milestone hoặc /gsd-discuss-phase 15
Last activity: 2026-04-23

## Performance Metrics

**v1.0 (shipped 2026-04-18):** 7 phases + 3 quick plans, 26 plans, 4 days, 97.8% HDSD coverage
**v2.0 (shipped 2026-04-23):** 8 phases (Phase 8-14 + 11.1), 39 plans, 3 days, 41/41 REQ Pass
**v3.0 (planned):** 6 phases (15-20), focus chuẩn hoá data model 3 bảng văn bản + tách bước Ban hành/Gửi + auto-sinh Incoming nội bộ + real LGSP HTTP client + gộp menu Liên thông

## v3.0 Planned Phases

| Phase | Title | Depends on |
|-------|-------|------------|
| 15 | Audit & design data model | — |
| 16 | Schema rebuild v3.0 | 15 |
| 17 | Tách bước Ban hành/Gửi + Auto-sinh Incoming nội bộ + Approver | 16 |
| 18 | Real LGSP HTTP client + worker polling thật | 16 |
| 19 | UI rewrite 3 màn + gộp menu Liên thông vào VB đến | 17, 18 |
| 20 | Regression + UAT toàn bộ | 15-19 |

## Accumulated Context

### Key Decisions Carried Forward

**v1.0 → v2.0:**
- Stored Procedures PostgreSQL, KHÔNG ORM
- Repository pattern, no service layer (trừ auth)
- Ant Design 6 + custom theme (Deep Navy #1B3A5C)
- JWT auth + refresh rotation
- Department subtree scoping cho phân quyền dữ liệu

**v2.0 → v3.0:**
- Master schema file `database/schema/000_schema_v2.0.sql` → bump v3.0 trong Phase 16
- Reset DB clean cho v3.0 (user approved 2026-04-23) — không cần migration script preserve data
- 2 cấp cấu hình ký số (Admin provider + User cert) giữ nguyên
- Async sign flow BullMQ + Socket.IO giữ nguyên

### Open Decisions for v3.0

- LGSP credentials thực tế chưa có (Lào Cai apiltvb.langson.gov.vn) — Phase 18 implement client + test khi KH cấp credentials
- Gộp inter_incoming_docs vào incoming_docs với source_type ENUM ('internal' / 'external_lgsp' / 'manual') — quyết định trong Phase 15 design
- Approver/Approved 1 cấp boolean (như source .NET cũ), không multi-level — gộp Phase 17

### Reference Docs

- Source code .NET cũ: `d:/ProjectAI/quanlyvanban/docs/source_code_cu/sources/`
  - `OneWin.Data.Object/Base/edoc/{IncomingDoc,OutgoingDoc,DraftingDoc}.cs` — schema reference
  - SP `Prc_DraftingDocReleased`, `Prc_UserOutgoingDocSend` — workflow reference
- v2.0 archive: `.planning/milestones/v2.0-MILESTONE-AUDIT.md`
- LGSP integration guide: `docs/source_code_cu/sources/LGSP-LANGSON-API-GUIDE.md`

## Session Continuity

Last session: 2026-04-23T10:00:00Z
Stopped at: Milestone v2.0 archived, ready to start v3.0
Resume: `/gsd-new-milestone` để chính thức tạo v3.0 → `/gsd-discuss-phase 15`
