# Roadmap: e-Office — Quản lý Văn bản điện tử

> **Xem thêm:** Chi tiết 17 sprints (SP, API, UI) tại `e_office_app_new/ROADMAP.md`

## Overview

Rebuild hệ thống quản lý văn bản điện tử (.NET cũ) thành stack mới (Next.js + Express + PostgreSQL).

## Milestones

- ✅ **v1.0 MVP** — Phases 1-7 (shipped 2026-04-18) — `.planning/milestones/v1.0-phases/`
- ✅ **v2.0 Tích hợp ký số 2 kênh** — Phases 8-14 + 11.1 (shipped 2026-04-23) — `.planning/milestones/v2.0-ROADMAP.md`
- 🚧 **v3.0 Chuẩn hoá quy trình văn bản** — Phases 15-20 (planned)

## Phases

### v3.0 (Active — Milestone: Chuẩn hoá data model + workflow nghiệp vụ văn bản)

- [ ] **Phase 15: Audit & design data model** — Phân tích gap 3 bảng văn bản (incoming/outgoing/drafting), design schema mới với recipients table + source_type flag + gộp inter_incoming_docs vào incoming_docs
- [ ] **Phase 16: Schema rebuild v3.0** — Bump master schema → `000_schema_v3.0.sql`. Drop bảng inter_incoming_docs riêng, gộp vào incoming_docs với source_type ENUM. Thêm bảng outgoing_doc_recipients. Thêm is_released cho drafting_docs. Reset DB clean.
- [ ] **Phase 17: Tách bước Ban hành/Gửi + Auto-sinh Incoming nội bộ** — Outgoing có 2 action: Ban hành (cấp số, IsReleased=true) và Gửi. Khi gửi recipient nội bộ → SP tự INSERT incoming_docs với source_type='internal'. Bao gồm Approver/Approved (1 cấp như source cũ).
- [ ] **Phase 18: Real LGSP HTTP client + worker polling thật** — Thay lgsp-mock.service.ts bằng real OAuth2 + REST client tới apiltvb.langson.gov.vn. Worker BullMQ polling thật, nhận VB từ LGSP → INSERT incoming_docs với source_type='external_lgsp'.
- [ ] **Phase 19: UI rewrite 3 màn + gộp menu Liên thông vào VB đến** — Bỏ route /van-ban-lien-thong + menu sidebar "Liên thông". Workflow recall (thu hồi LGSP, chuyển lại, hoàn thành) chuyển vào /van-ban-den với badge/filter source_type. Form 3 màn đồng bộ field mới + recipient picker phân loại nội bộ/ngoài.
- [ ] **Phase 20: Regression + UAT toàn bộ** — Verify HSCV, ký số, báo cáo, dashboard không vỡ. UAT 3 luồng chính: nội bộ A→B, gửi LGSP outgoing, nhận LGSP incoming.

<details>
<summary>✅ v1.0 MVP (Phases 1-7) — SHIPPED 2026-04-18</summary>

- [x] **Phase 1: Stabilize Sprint 0-4** — Fix visible bugs, refactor shared patterns, golden path mượt
- [x] **Phase 2: Hồ sơ công việc** — HSCV CRUD, 6-tab detail, workflow designer, KPI, 3 reports, Excel export
- [x] **Phase 3: Liên thông & Tin nhắn** — VB liên thông (tiếp nhận/từ chối/thu hồi), tin nhắn nội bộ
- [x] **Phase 4: Lịch, Danh bạ & Dashboard** — Lịch 3 loại, danh bạ, dashboard charts + feeds
- [x] **Phase 5: Kho lưu trữ, Tài liệu & Họp** — Kho/Phông + mượn/trả, tài liệu, họp không giấy
- [x] **Phase 6: Tích hợp hệ thống ngoài** — LGSP mock, ký số mock (SmartCA OTP), Trục CP mock
- [x] **Phase 7: Polish & Redirect** — HDSD compliance 97.8%, sidebar dynamic, redirect đối tác

Detail: `.planning/milestones/v1.0-phases/`
</details>

<details>
<summary>✅ v2.0 Tích hợp ký số 2 kênh (Phases 8-14 + 11.1) — SHIPPED 2026-04-23</summary>

- [x] **Phase 8: Schema foundation + PDF signing layer** — 3 bảng + migration `staff.sign_phone` + PDF pure JS
- [x] **Phase 9: Admin config + provider adapters** — SmartCA + MySign adapters, trang Admin với test connection
- [x] **Phase 10: User config page** — `/ky-so/tai-khoan` form dynamic theo provider + verify
- [x] **Phase 11: Sign flow + async worker** — BullMQ poll 5s × 3', Socket.IO SIGN_COMPLETED, ký lại/hủy
- [x] **Phase 11.1: DB Consolidation & Seed Strategy** — Master schema idempotent + tách seed required/demo
- [x] **Phase 12: Menu Ký số + Danh sách 4 tab UI** — `/ky-so/danh-sach` 4 tab dynamic
- [x] **Phase 13: Modal ký số robust + Root CA UX** — Countdown 3:00, banner Root CA Viettel
- [x] **Phase 14: Deployment + HDSD + verification** — Deploy scripts Windows, REQUIREMENTS audit 41 REQ

Detail: `.planning/milestones/v2.0-phases/`, audit: `.planning/milestones/v2.0-MILESTONE-AUDIT.md`
</details>

## Progress

| Phase range | Milestone | Plans | Status | Completed |
|-------------|-----------|-------|--------|-----------|
| 1-7 | v1.0 | 26/26 | Complete | 2026-04-14 → 2026-04-18 |
| 8-14 + 11.1 | v2.0 | 39/39 | Complete | 2026-04-21 → 2026-04-23 |
| 15-20 | v3.0 | 0/? | Not started | — |
