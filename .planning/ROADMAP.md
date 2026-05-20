# Roadmap: e-Office — Quản lý Văn bản điện tử

> **Xem thêm:** Chi tiết 17 sprints (SP, API, UI) tại `e_office_app_new/ROADMAP.md`

## Overview

Rebuild hệ thống quản lý văn bản điện tử (.NET cũ) thành stack mới (Next.js + Express + PostgreSQL).

## Milestones

- ✅ **v1.0 MVP** — Phases 1-7 (shipped 2026-04-18) — `.planning/milestones/v1.0-phases/`
- ✅ **v2.0 Tích hợp ký số 2 kênh** — Phases 8-14 + 11.1 (shipped 2026-04-23) — `.planning/milestones/v2.0-ROADMAP.md`
- ✅ **v3.0 Chuẩn hoá quy trình văn bản** — Phases 15-20 (shipped 2026-04-24) — `.planning/milestones/v3.0-ROADMAP.md`
- ✅ **v3.1 Manual Test Execution + Bug Fix** — Phases 21-32 (shipped 2026-05-19) — `.planning/milestones/v3.1-ROADMAP.md`
- 📋 **v3.2 LGSP Production Go-live cho 6 DN Lạng Sơn** — Phases 33+ (planning) — chờ `/gsd-new-milestone`

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

### 📋 v3.2 LGSP Production Go-live (Planning)

**Trigger:** Có credential thật từ tỉnh Lạng Sơn (6 SystemId + SecretKey + 3 sandbox) — tài liệu trong `docs/Trục EDOC Lạng Sơn - QLVB Doanh nghiệp/`.

**Goal sơ bộ:** Wire status callback chain (03/04/05/06 + 02 Từ chối + 13/15/16 Lấy lại) + cron `syncReceivedEdocList` + admin UI cấu hình `lgsp_agency_config` per-unit + roll-out theo wave (Wave 1: 3 DN có sandbox → Wave 2: 3 DN còn lại) + HDSD full refresh round 2 sau khi LGSP ship.

**Kiến trúc cốt lõi:** Multi-tenant single-system (1 deploy / 1 DB / 6 DN = 6 root unit trong cây `departments`). `lgsp_agency_config` per `unit_id` + `getLgspService(unit_id)` lookup credential động.

**Next step:** Chạy `/gsd-new-milestone` để discuss scope + tạo ROADMAP v3.2 chính thức.

## Progress

| Phase range | Milestone | Status | Completed |
|-------------|-----------|--------|-----------|
| 1-7 | v1.0 | Complete | 2026-04-14 → 2026-04-18 |
| 8-14 + 11.1 | v2.0 | Complete | 2026-04-21 → 2026-04-23 |
| 15-20 | v3.0 | Complete | 2026-04-23 → 2026-04-24 |
| 21-32 | v3.1 | Complete | 2026-05-05 → 2026-05-19 |
| 33+ | v3.2 | Planning | — |
