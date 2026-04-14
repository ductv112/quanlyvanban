# e-Office — Hệ thống Quản lý Văn bản điện tử

## What This Is

Hệ thống quản lý văn bản điện tử (e-Office) dành cho cơ quan nhà nước cấp tỉnh (VD: tỉnh Lào Cai) và doanh nghiệp nhà nước. Cho phép toàn bộ nhân sự quản lý văn bản đến/đi/dự thảo, hồ sơ công việc, lịch họp, ký số, liên thông LGSP — thay thế hệ thống cũ (.NET) bằng công nghệ mới (Next.js + Express + PostgreSQL) với giao diện hiện đại hơn, giữ nguyên nghiệp vụ.

## Core Value

Luồng văn bản đến → xử lý → văn bản đi phải hoạt động đúng nghiệp vụ cơ quan nhà nước — đây là flow cốt lõi mà mọi công chức sử dụng hàng ngày.

## Requirements

### Validated

- ✓ Infrastructure: Docker Compose (PostgreSQL, MongoDB, Redis, MinIO) — Sprint 0
- ✓ Authentication: JWT + refresh token rotation + httpOnly cookie — Sprint 0
- ✓ Main Layout: Sidebar (collapsible, dark navy) + Header + Dashboard — Sprint 0
- ✓ Quản lý Đơn vị/Phòng ban: Tree + CRUD + soft delete — Sprint 1
- ✓ Quản lý Chức vụ: Table + CRUD — Sprint 1
- ✓ Quản lý Người dùng: Tree đơn vị + Table NV + avatar MinIO — Sprint 1
- ✓ Quản lý Nhóm quyền & Phân quyền: Role + Rights tree — Sprint 1
- ✓ Quản lý Chức năng/Menu: Tree + dynamic sidebar — Sprint 1
- ✓ 12 module Danh mục & Cấu hình: Sổ VB, Loại VB, Lĩnh vực, Địa bàn, Ủy quyền, Nhóm làm việc, Mẫu thông báo, Cấu hình hệ thống — Sprint 2
- ✓ Văn bản đến: CRUD + xử lý + chuyển tiếp + đính kèm + lịch sử — Sprint 3
- ✓ Văn bản đi & Văn bản dự thảo: CRUD + luồng dự thảo → trình ký → phát hành — Sprint 4

### Active

- ✓ Stabilize Sprint 0-4: Shared tree utils + error handler extracted, golden path verified — Phase 1
- [ ] Sprint 5: Hồ sơ công việc — Core (danh sách, CRUD, chi tiết, workflow)
- [ ] Sprint 6: Hồ sơ công việc — Workflow & Báo cáo
- [ ] Sprint 7: Văn bản liên thông & Giao việc từ VB
- [ ] Sprint 8: Tin nhắn nội bộ & Thông báo
- [ ] Sprint 9: Lịch & Danh bạ
- [ ] Sprint 10: Dashboard hoàn thiện
- [ ] Sprint 11: Kho lưu trữ
- [ ] Sprint 12: Tài liệu chung & Hợp đồng
- [ ] Sprint 13: Họp không giấy
- [ ] Sprint 14: Tích hợp — LGSP Liên thông văn bản
- [ ] Sprint 15: Tích hợp — Ký số điện tử
- [ ] Sprint 16: Tích hợp — Thông báo đa kênh
- [ ] Sprint 17: Redirect pages & Polish

### Out of Scope

- Mobile app native — chỉ responsive web, không build iOS/Android riêng
- Deep stabilize (security audit, test coverage, performance tuning) — chuyển sang tuần sau demo
- Thay đổi nghiệp vụ so với hệ thống cũ — giữ nguyên logic, chỉ cải tiến UX/tech

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
| Stored Procedures, không ORM | Chỉ đạo từ sếp — toàn bộ business logic trong PostgreSQL | — Pending |
| Light stabilize trước, deep sau | Deadline gấp — fix visible bugs + refactor shared code, security/test tuần sau | — Pending |
| Rebuild giữ nguyên nghiệp vụ cũ | Khách hàng quen flow cũ, chỉ cần tech mới + UI đẹp hơn | — Pending |
| Ant Design 6 + custom theme | Consistent UI, không dùng default — Deep Navy palette | ✓ Good |
| CSS classes, không inline styles | Chống FOUC, maintainability | ✓ Good |

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
*Last updated: 2026-04-14 after Phase 1 completion*
