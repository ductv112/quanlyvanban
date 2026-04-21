# e-Office — Hệ thống Quản lý Văn bản điện tử

## What This Is

Hệ thống quản lý văn bản điện tử (e-Office) dành cho cơ quan nhà nước cấp tỉnh (VD: tỉnh Lào Cai) và doanh nghiệp nhà nước. Cho phép toàn bộ nhân sự quản lý văn bản đến/đi/dự thảo, hồ sơ công việc, lịch họp, ký số, liên thông LGSP — thay thế hệ thống cũ (.NET) bằng công nghệ mới (Next.js + Express + PostgreSQL) với giao diện hiện đại hơn, giữ nguyên nghiệp vụ.

## Core Value

Luồng văn bản đến → xử lý → văn bản đi phải hoạt động đúng nghiệp vụ cơ quan nhà nước — đây là flow cốt lõi mà mọi công chức sử dụng hàng ngày.

## Current Milestone: v2.0 Production features — Tích hợp ký số 2 kênh

**Goal:** Hoàn thiện hệ thống từ demo MVP → sản phẩm triển khai cho khách hàng thật, với khả năng chọn 1 trong 2 nền tảng ký số (SmartCA VNPT hoặc MySign Viettel) và quản lý ký số tập trung qua menu riêng.

**Target features:**
- Menu "Ký số" riêng ở sidebar: Cấu hình hệ thống (Admin) / Tài khoản cá nhân (User) / Danh sách ký số (4 tab: Cần ký / Đang xử lý / Đã ký / Thất bại)
- 2 cấp cấu hình: Admin chọn active provider + credentials hệ thống → User cấu hình user_id (+ chọn cert với MySign)
- Tích hợp thật SmartCA VNPT (`https://gwsca.vnpt.vn/sca/sp769/v1/*`) theo spec source cũ
- Tích hợp thật MySign Viettel (`{url}/vtss/service/ras/v1/*`) theo tài liệu chính hãng
- PDF signing Pure JS: `node-signpdf` + `node-forge` (PKCS7 detached), 1 codebase cho cả 2 provider
- Async decoupled worker (BullMQ poll 5s × max 3 phút) + Socket.IO SIGN_COMPLETED + bell notification offline
- Modal ký robust: disable spam click, countdown 3:00, "Đóng" (giữ transaction) vs "Hủy ký số" (mark cancelled)
- Root CA UX: banner dismissible + link `.cer` + PDF HDSD khi file ký bằng MySign
- Migration `staff.sign_phone` → table mới `staff_signing_config(staff_id, provider_code, config_json)`
- Lưu `sign_provider_code` vào attachments + transactions để đổi provider không mất lịch sử

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

### Active (v2.0)

- [ ] SIGN-*: Tích hợp ký số 2 kênh SmartCA VNPT + MySign Viettel
- [ ] CFG-*: 2 cấp cấu hình (Admin + User) với test connection
- [ ] UX-*: Menu Ký số + modal robust + Root CA banner
- [ ] ASYNC-*: BullMQ worker + Socket.IO decoupled flow
- [ ] MIG-*: Migration schema `staff.sign_phone` → multi-provider

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
| **v2.0: 1 provider active cho toàn hệ thống** | Đơn giản support/billing, KH chọn 1 nhà cung cấp khi triển khai | — Pending |
| **v2.0: Pure JS PDF signing (`node-signpdf`)** | Không phải cài Java/DotNet runtime; PKCS7 detached format chuẩn chung cho cả 2 provider | — Pending |
| **v2.0: Async decoupled worker (BullMQ)** | User tắt UI vẫn nhận kết quả ký; resilient với backend restart (Redis persistent) | — Pending |
| **v2.0: Menu Ký số riêng** | Ký số tập trung 1 chỗ, không rải rác trong detail VB | — Pending |
| **v2.0: Credentials encrypted pgcrypto** | Tránh leak client_secret nếu backup DB rò rỉ | — Pending |

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
*Last updated: 2026-04-21 — Milestone v2.0 started (Tích hợp ký số 2 kênh)*
