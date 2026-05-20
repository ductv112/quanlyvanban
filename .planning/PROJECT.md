# e-Office — Hệ thống Quản lý Văn bản điện tử

## What This Is

Hệ thống quản lý văn bản điện tử (e-Office) dành cho cơ quan nhà nước cấp tỉnh (VD: tỉnh Lào Cai) và doanh nghiệp nhà nước. Cho phép toàn bộ nhân sự quản lý văn bản đến/đi/dự thảo, hồ sơ công việc, lịch họp, ký số, liên thông LGSP — thay thế hệ thống cũ (.NET) bằng công nghệ mới (Next.js + Express + PostgreSQL) với giao diện hiện đại hơn, giữ nguyên nghiệp vụ.

## Core Value

Luồng văn bản đến → xử lý → văn bản đi phải hoạt động đúng nghiệp vụ cơ quan nhà nước — đây là flow cốt lõi mà mọi công chức sử dụng hàng ngày.

## Current Milestone: v3.2 LGSP Production Go-live cho 6 DN Lạng Sơn (Planning)

**Trigger:** Có credential thật từ tỉnh Lạng Sơn (6 SystemId + SecretKey + 3 sandbox) — tài liệu trong [`docs/Trục EDOC Lạng Sơn - QLVB Doanh nghiệp/`](../docs/Trục%20EDOC%20Lạng%20Sơn%20-%20QLVB%20Doanh%20nghiệp/). 6 DN đã đang dùng prod trên `doanhnghiep.vatk.org` (multi-tenant 1 system / 1 DB).

**Goal sơ bộ:** Wire LGSP API thật cho 6 DN gửi/nhận VB qua trục liên thông tỉnh:
- Status callback chain (03 Tiếp nhận / 04 Phân công / 05 Xử lý / 06 Hoàn thành + 02 Từ chối + 13/15/16 Lấy lại)
- Cron `syncReceivedEdocList` loop 6 DN mỗi 5 phút (mỗi DN dùng credential riêng)
- Admin UI cấu hình `lgsp_agency_config` per `unit_id` + environment switch (sandbox/prod)
- Edxml builder + parser (theo spec QĐ 28/2018/QĐ-TTg + LGSP_LANGSON guide)
- Roll-out theo wave: Wave 1 (3 DN có sandbox: H37.DN.001/002/003) → Wave 2 (3 DN còn lại: 004/005/006)
- HDSD full refresh round 2 sau khi LGSP ship (vì HDSD Phase 32 đã drift sau 8 ngày fix bug)

**Kiến trúc cốt lõi (chốt 2026-05-19 sau clarification của user):**
- Multi-tenant single-system: 1 deploy / 1 DB / 6 DN = 6 root unit trong cây `departments`
- `lgsp_agency_config` per `unit_id` (KHÔNG đọc từ `.env`)
- `getLgspService(unit_id)` lookup credential động khi gọi LGSP
- Roll-out không qua deploy wave — chỉ toggle `lgsp_agency_config.is_active=true` per row (config-level)

**Decision point chưa chốt** (sẽ hỏi khi `/gsd-discuss-phase`):
- Khi User DN.001 gửi VB → DN.002 (cả 2 cùng trong 6 DN): qua LGSP / nội bộ thuần / cả 2?

**Next step:** `/gsd-new-milestone` để tạo ROADMAP v3.2 chính thức + REQUIREMENTS + breakdown 4-5 phase.

## Requirements

### Validated (v1.0 — Shipped 2026-04-18)

- ✓ Infrastructure: Docker Compose (PostgreSQL, MongoDB, Redis, MinIO) — Sprint 0
- ✓ Authentication: JWT + refresh token rotation + httpOnly cookie — Sprint 0
- ✓ Main Layout: Sidebar (collapsible, dark navy) + Header + Dashboard — Sprint 0
- ✓ Quản lý Đơn vị/Phòng ban: Tree + CRUD + soft delete — Sprint 1
- ✓ Quản lý Chức vụ: Table + CRUD — Sprint 1
- ✓ Quản lý Người dùng: Tree đơn vị + Table NV + avatar MinIO — Sprint 1
- ✓ Quản lý Nhóm quyền & Phân quyền: Role + Rights tree — Sprint 1
- ✓ Quản lý Chức năng/Menu: Tree + dynamic sidebar — Sprint 1
- ✓ 12 module Danh mục & Cấu hình — Sprint 2
- ✓ Văn bản đến: CRUD + xử lý + chuyển tiếp + đính kèm + lịch sử — Sprint 3
- ✓ Văn bản đi & Văn bản dự thảo: CRUD + luồng dự thảo → trình ký → phát hành — Sprint 4
- ✓ Stabilize Sprint 0-4 — v1.0 Phase 1
- ✓ Hồ sơ công việc (Sprint 5-6) — v1.0 Phase 2
- ✓ Liên thông & Tin nhắn (Sprint 7-8) — v1.0 Phase 3
- ✓ Lịch, Danh bạ & Dashboard (Sprint 9-10) — v1.0 Phase 4
- ✓ Kho lưu trữ, Tài liệu & Họp (Sprint 11-13) — v1.0 Phase 5
- ✓ Tích hợp hệ thống ngoài (Sprint 14-16): LGSP + Ký số MOCK + Trục CP mock — v1.0 Phase 6
- ✓ Polish & Redirect (Sprint 17): HDSD Compliance 97.8% — v1.0 Phase 7

### Validated (v2.0 — Shipped 2026-04-23)

- ✓ SIGN-* (8): Tích hợp ký số thật SmartCA VNPT + MySign Viettel — v2.0 Phase 8-11
- ✓ CFG-* (7): 2 cấp cấu hình Admin + User với test connection — v2.0 Phase 9-10
- ✓ UX-* (13): Menu Ký số 4 tab + Modal robust countdown 3:00 + Root CA banner — v2.0 Phase 12-13
- ✓ ASYNC-* (6): BullMQ worker poll 5s × 3' + Socket.IO SIGN_COMPLETED — v2.0 Phase 11
- ✓ MIG-* (5): Migration `staff.sign_phone` → `staff_signing_config` multi-provider — v2.0 Phase 8
- ✓ DEP-* (2): Deploy scripts Windows-only + Root CA static files — v2.0 Phase 13-14
- ✓ Master schema consolidation (`000_schema_v2.0.sql` idempotent) — v2.0 Phase 11.1

### Validated (v3.0 — Shipped 2026-04-24)

- ✓ DM-* (8): Chuẩn hoá data model — source_type/is_unit_send/unit_send/previous_outgoing_doc_id + outgoing_doc_recipients + inter_organizations — v3.0 Phase 15-16
- ✓ WF-* (5): Tách Ban hành/Gửi + Auto-sinh Incoming nội bộ + Approver 1 cấp — v3.0 Phase 17
- ✓ LGSP-* (5): LGSPRealService OAuth2 + REST `apiltvb.langson.gov.vn` + worker BullMQ thật — v3.0 Phase 18
- ✓ UI-* (8): Form 3 màn đồng bộ + recipient picker + bỏ menu Liên thông + tracking inline — v3.0 Phase 19
- ✓ QA-* (3): Regression 27/27 endpoints + 17 bugs UAT fixed — v3.0 Phase 20

### Validated (v3.1 — Shipped 2026-05-19)

- ✓ INFRA-* (7): Test DB tách dev + 6 user fixture + 3 mock server (SmartCA/MySign/LGSP) + Vitest+Playwright+supertest + Excel sync tool + README onboarding — v3.1 Phase 21
- ✓ EXEC-* (9): Execute 847 TC qua 9 wave (a Auth+Admin / b VB / c HSCV+KS / d-f Boundary / g Permission / h E2E / i Concurrent) — v3.1 Phase 22-30
- ✓ REPORT-* (3): Excel results + bug list 90+ severity classified — v3.1 Phase 22-30 (báo qua `docs/20260519_Tester báo lỗi.xlsx`)
- ✓ Phase 31 fix-gom UI: 164+ commit BUG #1 → #90 + IMP #5 (ký số polish, phân quyền granular, menu, HSCV, setup KH Lạng Sơn)
- ✓ Phase 32 HDSD: 16 file HDSD updated + 6 screenshots + HDSD_full.md (4496 dòng) + HDSD_full.docx (13.3MB, 82 ảnh)
- ✓ Setup 6 KH DN Lạng Sơn dùng prod thật trên `doanhnghiep.vatk.org`

### Active (v3.2 — LGSP Production Go-live, planning 2026-05-19)

Requirements sẽ được define qua `/gsd-new-milestone`. Sơ bộ:

- [ ] LGSP-CRED-*: Bảng `lgsp_agency_config` per `unit_id` + 6 row + cột `lgsp_org_code` trong `departments`
- [ ] LGSP-SEND-*: Builder edXML + sendEdoc với credential dynamic theo sender unit
- [ ] LGSP-RECV-*: Cron syncReceivedEdocList loop 6 DN mỗi 5 phút + parser edXML + INSERT incoming_docs
- [ ] LGSP-STATUS-*: Callback chain status 03/04/05/06 + 02 Từ chối + 13/15/16 Lấy lại
- [ ] LGSP-UI-*: Admin UI cấu hình credential + environment switch (sandbox/prod) + bật lại menu `/lgsp`
- [ ] HDSD-REFRESH-*: Re-audit + re-capture ~80 screenshots + re-merge full.docx sau khi LGSP ship

### Deferred (v3.3+ backlog)

- [ ] Drafting recipients structured + carry-over Outgoing khi Release
- [ ] Trang admin CRUD `inter_organizations` + button "Sync from LGSP"
- [ ] Multi-level approval workflow (Trưởng phòng → Phó GĐ → Giám đốc)
- [ ] Cleanup 2 modal legacy v1.0 (Gửi liên thông + Gửi trục CP)
- [ ] Default expired_date theo config sổ văn bản
- [ ] CI/CD pipeline (chỉ kích hoạt khi có team QA — không có team hiện tại → không cần)
- [ ] Visual regression pixel-diff / a11y / mobile responsive E2E (cùng lý do)

### Out of Scope

- Mobile app native — chỉ responsive web, không build iOS/Android riêng
- Thay đổi nghiệp vụ so với hệ thống cũ — giữ nguyên logic, chỉ cải tiến UX/tech
- Multi-provider song song (1 user dùng SmartCA, 1 user dùng MySign cùng hệ thống) — chốt 1 provider active toàn hệ thống
- Ký batch nhiều file 1 lượt — v2.0 chỉ ký từng file riêng
- FPT CA / EasyCA và các provider khác — chỉ 2 provider SmartCA VNPT + MySign Viettel
- Thay thế ViettelFileSigner.jar / VnptHashSignatures.dll — dùng pure JS `node-signpdf` + `node-forge`

## Context

- **Hệ thống cũ:** .NET MVC, 270+ controllers, 10 areas, đang chạy production trên GitLab. Source code cũ là tài liệu tham chiếu chính cho nghiệp vụ.
- **Bản chất dự án:** Rebuild hệ thống cũ — giữ đúng nghiệp vụ, công nghệ mới, tối ưu hơn, giao diện đẹp hơn.
- **Sprint 0-4 đã implement** nhưng chưa test chi tiết — cần light stabilize trước khi tiếp.
- **Codebase map đã phát hiện vấn đề:** JWT fallback secret, requireRoles() không được áp dụng, Zod installed nhưng chưa dùng, route files monolithic, tree mapping duplicate across 6 admin pages.
- **Đối tượng triển khai:** Cơ quan nhà nước cấp tỉnh, doanh nghiệp nhà nước — yêu cầu ổn định, đúng quy trình hành chính.

## Constraints

- **Deadline**: Demo cuối tuần này (2026-04-18/19) — toàn bộ 17 sprint
- **Tech stack**: Next.js 16 + Express 5 + PostgreSQL 16 (Stored Procedures, KHÔNG ORM) + MongoDB + Redis + MinIO
- **Business logic**: PHẢI đối chiếu source code cũ (.NET) trước khi implement — đọc Controllers, Services, SPs cũ
- **UI/UX**: Ant Design 6 + custom theme (Deep Navy #1B3A5C), Drawer cho add/edit, Popconfirm cho xóa, tiếng Việt có dấu
- **Architecture**: Repository pattern, no service layer (trừ auth), all data access qua Stored Functions

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Stored Procedures, không ORM | Chỉ đạo từ sếp — toàn bộ business logic trong PostgreSQL | ✓ Good (v1.0 validated) |
| Light stabilize trước, deep sau | Deadline gấp demo v1.0 — deep hardening chuyển sang v2.0 | ✓ Good |
| Rebuild giữ nguyên nghiệp vụ cũ | Khách hàng quen flow cũ, chỉ cần tech mới + UI đẹp hơn | ✓ Good (97.8% HDSD coverage) |
| Ant Design 6 + custom theme | Consistent UI, không dùng default — Deep Navy palette | ✓ Good |
| CSS classes, không inline styles | Chống FOUC, maintainability | ✓ Good |
| **v2.0: 1 provider active cho toàn hệ thống** | Đơn giản support/billing, KH chọn 1 nhà cung cấp khi triển khai | ✓ Good (v2.0 shipped) |
| **v2.0: Pure JS PDF signing (`node-signpdf`)** | Không phải cài Java/DotNet runtime; PKCS7 detached format chuẩn chung cho cả 2 provider | ✓ Good (v2.0 shipped, 10 unit tests pass) |
| **v2.0: Async decoupled worker (BullMQ)** | User tắt UI vẫn nhận kết quả ký; resilient với backend restart (Redis persistent) | ✓ Good (v2.0 shipped) |
| **v2.0: Menu Ký số riêng** | Ký số tập trung 1 chỗ, không rải rác trong detail VB | ✓ Good (v2.0 shipped, 4 tab UI) |
| **v2.0: Credentials encrypted pgcrypto** | Tránh leak client_secret nếu backup DB rò rỉ | ✓ Good (v2.0 shipped) |
| **v2.0: Master schema consolidation** | 16 migration files → 1 file idempotent — drop+rebuild dev DB nhanh, zero SP overload | ✓ Good (v2.0 Phase 11.1) |
| **v3.0: Reset DB clean, không migration script preserve data** | v2.0 → v3.0 schema thay đổi sâu (3 bảng core), data dev/test có thể seed lại | — Pending (chốt 2026-04-23) |
| **v3.0: Gộp `inter_incoming_docs` vào `incoming_docs`** | Source .NET cũ dùng `IsUnitSend` flag chứ không tách bảng — gộp đơn giản hoá UI + giảm join | — Pending |
| **v3.0: Bỏ menu Liên thông riêng** | VB liên thông bản chất là VB đến (chỉ khác nguồn), gộp giảm điều hướng + 1 chỗ xử lý | — Pending |
| **v3.0: Tách 2 bước Ban hành / Gửi** | Đúng nghiệp vụ source .NET cũ (`Prc_DraftingDocReleased` vs `Prc_UserOutgoingDocSend`) | — Pending |
| **v3.0: Approver/Approved 1 cấp boolean** | Source cũ chỉ làm 1 cấp duyệt đơn giản, không cần multi-level workflow | — Pending |
| **v3.1: Re-scope 2026-05-06 — Manual execute by Claude** | User clarify không có team QA → bỏ CI/CD framework, đổi sang AI tester thủ công | ✓ Good (v3.1 shipped 847 TC + 90 bug fix trong 15 ngày) |
| **v3.1: Phase 22-30 không dùng GSD plan discipline** | Manual execute không cần multi-wave plan, RESULTS.md đủ trace | ✓ Good (giảm overhead, ship nhanh) |
| **v3.1: Phase 31 fix-gom commit trực tiếp ngoài GSD** | Tester batch + đào tạo KH ép tốc độ | ⚠️ Trade-off: 164 commit không có PLAN/SUMMARY (audit khó) |
| **v3.1: Setup 6 DN Lạng Sơn dùng prod thật** | KH đang dùng thử trên `doanhnghiep.vatk.org` để feedback nghiệp vụ | ✓ Good (kiểm chứng đa-tenant + UAT thật) |
| **v3.2: Multi-tenant single-system kiến trúc** | 6 DN chung 1 deploy / 1 DB / 6 root unit trong departments (không phải 6 deploy riêng) | — Pending (chốt 2026-05-19) |
| **v3.2: `lgsp_agency_config` per `unit_id`** | Mỗi DN có SystemId + SecretKey riêng, lookup động qua getLgspService(unit_id) | — Pending |
| **v3.2: Roll-out wave config-level (không deploy)** | Toggle `is_active=true` per row, không cần restart server, giảm rủi ro 5 DN khác | — Pending |
| **v3.2: HDSD full refresh round 2 sau LGSP ship** | HDSD Phase 32 đã drift 8 ngày, defer refresh để bundle với LGSP content mới | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-05-19 — Milestone v3.1 shipped (847 TC + 90 bug fix + setup 6 DN Lạng Sơn prod + HDSD audit), v3.2 (LGSP Production Go-live) planning*
