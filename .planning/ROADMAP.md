# Roadmap: e-Office — Quản lý Văn bản điện tử

> **Xem thêm:** Chi tiết 17 sprints (SP, API, UI) tại `e_office_app_new/ROADMAP.md`

## Overview

Rebuild hệ thống quản lý văn bản điện tử (.NET cũ) thành stack mới (Next.js + Express + PostgreSQL).

## Milestones

- ✅ **v1.0 MVP** — Phases 1-7 (shipped 2026-04-18) — `.planning/milestones/v1.0-phases/`
- ✅ **v2.0 Tích hợp ký số 2 kênh** — Phases 8-14 + 11.1 (shipped 2026-04-23) — `.planning/milestones/v2.0-ROADMAP.md`
- ✅ **v3.0 Chuẩn hoá quy trình văn bản** — Phases 15-20 (shipped 2026-04-24) — `.planning/milestones/v3.0-ROADMAP.md`
- ✅ **v3.1 Manual Test Execution + Bug Fix** — Phases 21-32 (shipped 2026-05-19) — `.planning/milestones/v3.1-ROADMAP.md`
- ✅ **v3.2 LGSP Production Go-live cho 6 DN Lạng Sơn** — Phases 33-37 (shipped 2026-05-21) — `.planning/milestones/v3.2-ROADMAP.md`

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

<details>
<summary>✅ v3.1 Manual Test Execution + Bug Fix (Phases 21-32) — SHIPPED 2026-05-19</summary>

- [x] **Phase 21: Automation Foundation (INFRA)** — Test DB tách dev, 6 user fixture, 3 mock server, Vitest+Playwright+supertest, Excel sync tool
- [x] **Phase 22-30: Execute 847 TC qua 9 wave** — Manual test execution, RESULTS file mỗi wave, bug logged (90+ BUG fixed)
- [x] **Phase 31: Fix-gom UI** — 164+ commit bug fix ký số / phân quyền / menu / HSCV / setup KH Lạng Sơn
- [x] **Phase 32: HDSD audit + update** — 16 HDSD updated, 6 screenshots re-captured, HDSD_full.md (4496 dòng) + HDSD_full.docx (13.3MB, 82 ảnh)

Detail: `.planning/milestones/v3.1-phases/`, archive: `.planning/milestones/v3.1-ROADMAP.md`, helpers: `.planning/milestones/v3.1-helpers/`
</details>

<details>
<summary>✅ v3.2 LGSP Production Go-live cho 6 DN Lạng Sơn (Phases 33-37) — SHIPPED 2026-05-21</summary>

- [x] **Phase 33: Database + Core Infrastructure** — Schema `lgsp_agency_config` per-unit + `lgsp_org_code` + outbox + `getLgspService()` lookup + 11 SPs + 9 row seed (5 plans)
- [x] **Phase 34: Send Flow (sendEdoc)** — Fix `/v1/sendEdoc` multipart + edXML builder QĐ 28 + BullMQ worker concurrency=3 retry 5x + 9-code error map + UI badge polling 10s (5 plans)
- [x] **Phase 35: Receive Flow (cron)** — BullMQ tick 5min + fast-xml-parser + dedup UNIQUE + MinIO attachments + outbox '01' + UI tag LGSP + filter Nguồn (5 plans)
- [x] **Phase 36: Status Callback Chain (9 mã QĐ 28)** — UNIQUE constraint dedup + 6 route hooks (mark-read/giao-viec/but-phe/them-vao-hscv/chuyen-luu-tru/chuyen-lai) + worker poll 30s + Timeline UI (5 plans)
- [x] **Phase 37: Admin UI + Catalog + Go-live** — 3 page admin (`/lgsp`, `/lgsp/co-quan`, `/lgsp/cau-hinh`) + 12 admin endpoints + retry buttons + unhide menu + roll-out doc (7 plans)

**Total:** 27 plans, ~80 commits, 36/36 REQ-IDs covered, PASS với tech debt v3.3+ tracked.

Detail: `.planning/milestones/v3.2-ROADMAP.md`, audit: `.planning/milestones/v3.2-MILESTONE-AUDIT.md`, ship: `.planning/v3.2-SHIP-READINESS.md`
</details>

## Progress

| Phase range | Milestone | Status | Completed |
|-------------|-----------|--------|-----------|
| 1-7 | v1.0 | Complete | 2026-04-14 → 2026-04-18 |
| 8-14 + 11.1 | v2.0 | Complete | 2026-04-21 → 2026-04-23 |
| 15-20 | v3.0 | Complete | 2026-04-23 → 2026-04-24 |
| 21-32 | v3.1 | Complete | 2026-05-05 → 2026-05-19 |
| 33-37 | v3.2 | Complete | 2026-05-20 → 2026-05-21 |
