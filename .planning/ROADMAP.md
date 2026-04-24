# Roadmap: e-Office — Quản lý Văn bản điện tử

> **Xem thêm:** Chi tiết 17 sprints (SP, API, UI) tại `e_office_app_new/ROADMAP.md`

## Overview

Rebuild hệ thống quản lý văn bản điện tử (.NET cũ) thành stack mới (Next.js + Express + PostgreSQL).

## Milestones

- ✅ **v1.0 MVP** — Phases 1-7 (shipped 2026-04-18) — `.planning/milestones/v1.0-phases/`
- ✅ **v2.0 Tích hợp ký số 2 kênh** — Phases 8-14 + 11.1 (shipped 2026-04-23) — `.planning/milestones/v2.0-ROADMAP.md`
- ✅ **v3.0 Chuẩn hoá quy trình văn bản** — Phases 15-20 (shipped 2026-04-24) — `.planning/milestones/v3.0-ROADMAP.md`
- 📋 **v3.1+** — Defer items (drafting recipients structured, admin CRUD inter_orgs, multi-level approval...)

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1-7) — SHIPPED 2026-04-18</summary>

- [x] Phase 1-7. Detail: `.planning/milestones/v1.0-phases/`
</details>

<details>
<summary>✅ v2.0 Tích hợp ký số 2 kênh (Phases 8-14 + 11.1) — SHIPPED 2026-04-23</summary>

- [x] Phase 8-14 + 11.1. Detail: `.planning/milestones/v2.0-phases/`
</details>

<details>
<summary>✅ v3.0 Chuẩn hoá quy trình văn bản (Phases 15-20) — SHIPPED 2026-04-24</summary>

- [x] **Phase 15: Audit & design data model** — DESIGN.md user-approved
- [x] **Phase 16: Schema rebuild v3.0** — Master schema v3.0 idempotent (~27K lines)
- [x] **Phase 17: Tách Ban hành/Gửi + Auto-sinh Incoming nội bộ + Approver** — 5 SPs + 4 routes + UI buttons
- [x] **Phase 18: Real LGSP HTTP client + worker BullMQ thật** — `LGSPRealService` OAuth2 + REST `apiltvb.langson.gov.vn`
- [x] **Phase 19: UI rewrite + bỏ menu Liên thông** — Tracking inline VB đi
- [x] **Phase 20: Regression + UAT + audit đối xứng** — 27/27 endpoints PASS, 17 bugs UAT fixed

Detail: `.planning/milestones/v3.0-phases/`, audit: `.planning/milestones/v3.0-MILESTONE-AUDIT.md`
</details>

## Progress

| Phase range | Milestone | Status | Completed |
|-------------|-----------|--------|-----------|
| 1-7 | v1.0 | Complete | 2026-04-14 → 2026-04-18 |
| 8-14 + 11.1 | v2.0 | Complete | 2026-04-21 → 2026-04-23 |
| 15-20 | v3.0 | Complete | 2026-04-23 → 2026-04-24 |
| TBD | v3.1+ | Planning | — |
