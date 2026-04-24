# e-Office — Hệ thống Quản lý Văn bản điện tử

## What This Is

Hệ thống quản lý văn bản điện tử (e-Office) dành cho cơ quan nhà nước cấp tỉnh (VD: tỉnh Lào Cai) và doanh nghiệp nhà nước. Cho phép toàn bộ nhân sự quản lý văn bản đến/đi/dự thảo, hồ sơ công việc, lịch họp, ký số, liên thông LGSP — thay thế hệ thống cũ (.NET) bằng công nghệ mới (Next.js + Express + PostgreSQL) với giao diện hiện đại hơn, giữ nguyên nghiệp vụ.

## Core Value

Luồng văn bản đến → xử lý → văn bản đi phải hoạt động đúng nghiệp vụ cơ quan nhà nước — đây là flow cốt lõi mà mọi công chức sử dụng hàng ngày.

## Current Milestone: v3.0 Chuẩn hoá quy trình văn bản

**Goal:** Chuẩn hoá data model 3 bảng văn bản (incoming/outgoing/drafting) đúng nghiệp vụ source .NET cũ — tách rõ "Cơ quan ban hành" vs "Nơi gửi" vs "Nơi nhận", auto-sinh văn bản đến khi gửi nội bộ, real LGSP HTTP client thay mock, gộp menu Liên thông vào VB đến với source_type filter.

**Target features (6 phases):**
- Phase 15: Audit & design data model — phân tích gap 3 bảng + design schema mới (recipients table, source_type flag, gộp inter_incoming_docs vào incoming_docs)
- Phase 16: Schema rebuild v3.0 — bump master schema → `000_schema_v3.0.sql`, drop bảng inter riêng, reset DB clean
- Phase 17: Tách bước Ban hành/Gửi + Auto-sinh Incoming nội bộ + Approver/Approved 1 cấp
- Phase 18: Real LGSP HTTP client (OAuth2 + REST tới `apiltvb.langson.gov.vn`) + worker BullMQ polling thật
- Phase 19: UI rewrite 3 màn (soạn thảo/đi/đến) + gộp menu Liên thông vào VB đến với badge source_type
- Phase 20: Regression + UAT toàn bộ — verify HSCV, ký số, báo cáo không vỡ

**Quyết định v3.0 (chốt 2026-04-23):**
- Reset DB clean (không cần migration script preserve data cũ)
- Gộp `inter_incoming_docs` vào `incoming_docs` với `source_type ENUM('internal','external_lgsp','manual')`
- Bỏ menu `/van-ban-lien-thong` riêng — gộp vào `/van-ban-den` với filter
- Approver/Approved 1 cấp boolean (như source .NET cũ), không multi-level workflow

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

### Active (v3.0)

- [ ] DM-*: Chuẩn hoá data model 3 bảng văn bản (Phase 15-16)
  - Thêm `is_unit_send`, `unit_send`, `previous_outgoing_doc_id` vào `incoming_docs`
  - Bảng mới `outgoing_doc_recipients` (multi-recipient nội bộ + ngoài)
  - Cờ `source_type ENUM('internal','external_lgsp','manual')` thay bảng `inter_incoming_docs` riêng
- [ ] WF-*: Tách bước Ban hành / Gửi trên outgoing_docs + auto-sinh incoming nội bộ + Approver/Approved 1 cấp (Phase 17)
- [ ] LGSP-*: Real LGSP HTTP client (OAuth2 + REST `apiltvb.langson.gov.vn`) thay mock service + worker BullMQ polling thật (Phase 18)
- [ ] UI-*: Rewrite 3 màn (soạn thảo/đi/đến) đồng bộ field mới + recipient picker + gộp menu Liên thông vào VB đến (Phase 19)
- [ ] QA-*: Regression + UAT 3 luồng chính (nội bộ A→B / gửi LGSP / nhận LGSP) (Phase 20)

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
*Last updated: 2026-04-23 — Milestone v2.0 shipped, v3.0 (Chuẩn hoá quy trình văn bản) started*
