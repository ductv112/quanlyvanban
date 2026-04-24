# Milestones

## v3.0 — Chuẩn hoá quy trình văn bản (2026-04-23 → 2026-04-24)

**Status:** ✓ Shipped

**Goal:** Chuẩn hoá data model 3 bảng văn bản (incoming/outgoing/drafting) đúng nghiệp vụ source .NET cũ — tách "Cơ quan ban hành" vs "Nơi gửi" vs "Nơi nhận", auto-sinh văn bản đến khi gửi nội bộ, real LGSP HTTP client thay mock, gộp menu Liên thông vào VB đến.

**Delivered:**

| # | Phase | Scope |
|---|-------|-------|
| 15 | Audit & design data model | DESIGN.md user-approved (12 sections, ERD mermaid, 25 decisions) |
| 16 | Schema rebuild v3.0 | Master `000_schema_v3.0.sql` (~27K lines, idempotent), DROP `inter_incoming_docs`, ADD `outgoing_doc_recipients` + `inter_organizations` |
| 17 | Tách Ban hành/Gửi + Auto-sinh Incoming nội bộ + Approver | 5 SPs mới (release/send_to_recipients/recipients_create/approve/unapprove) + 4 routes + UI 2 buttons |
| 18 | Real LGSP HTTP client + worker BullMQ | `LGSPRealService` OAuth2 + REST `apiltvb.langson.gov.vn`, token cache 29', worker switch mock/real |
| 19 | Bỏ menu Liên thông + tracking inline | Remove route + menu sidebar, section "Đơn vị/Cơ quan nhận" inline VB đi với LGSP tracking status |
| 20 | Regression + UAT + audit đối xứng | 27/27 endpoints PASS, 17 bugs UAT fixed (sub_number, document_code, label uniformity, permission VB đến) |

**Metrics:**

- 6 phases shipped, 23 commits chính
- 29/29 REQ-IDs Pass (DM×8, WF×5, LGSP×5, UI×8, QA×3)
- 17 bugs UAT user phát hiện + fix incremental
- Reset DB clean (user approved, không migrate data v2.0)

**Key decisions carried forward:**

- Master schema bump `000_schema_v2.0.sql` → `000_schema_v3.0.sql`
- 3 bảng VB không đối xứng 100% (incoming = nhận từ ngoài, outgoing/drafting = mình ban hành) — đúng bản chất
- VB đến chỉ sửa được khi `source_type='manual'` (internal/LGSP block)
- 2 step Ban hành (cấp số) + Gửi (đẩy recipients) — đúng nghiệp vụ source cũ
- Drafting recipients giữ text-only (defer structured v3.1)
- Trang admin `inter_organizations` defer (auto-sync LGSP khi có credentials)

**Tech debt (defer v3.1):**

- Drafting recipients structured + carry-over Outgoing
- Trang admin CRUD inter_organizations + button Sync from LGSP
- Multi-level approval workflow
- Cleanup 2 modal legacy LGSP/CP code v1.0
- Default expired_date theo config sổ văn bản

**Archive:**

- Roadmap: `.planning/milestones/v3.0-ROADMAP.md`
- Requirements: `.planning/milestones/v3.0-REQUIREMENTS.md`
- Audit: `.planning/milestones/v3.0-MILESTONE-AUDIT.md`
- Phases: `.planning/milestones/v3.0-phases/` (4 phase directories: 15, 16, 17, 20 — Phase 18+19 work commit thẳng vào codebase, không có phase folder riêng)

---

## v1.0 — MVP Demo (2026-04-14 → 2026-04-18)

**Status:** ✓ Shipped

**Goal:** Demo cuối tuần cho KH — toàn bộ 17 sprint rebuild hệ thống .NET cũ bằng Next.js + Express + PostgreSQL.

**Delivered:**

| # | Phase | Scope |
|---|-------|-------|
| 1 | Stabilize Sprint 0-4 | Shared tree utils + error handler extracted, golden path verified |
| 2 | Hồ sơ công việc | CRUD, 6-tab detail, workflow designer, KPI, 3 reports, Excel export |
| 3 | Liên thông & Tin nhắn | VB liên thông (tiếp nhận/từ chối/thu hồi), tin nhắn nội bộ |
| 4 | Lịch, Danh bạ & Dashboard | Lịch cá nhân/cơ quan/lãnh đạo, danh bạ, dashboard v2 với charts + feeds |
| 5 | Kho lưu trữ, Tài liệu & Họp | Kho lưu trữ + mượn/trả, tài liệu, cuộc họp không giấy |
| 6 | Tích hợp hệ thống ngoài | LGSP, Ký số mock (SmartCA OTP + VB đi/dự thảo), Trục CP mock |
| 7 | Polish & Redirect | HDSD compliance 97.8% (92 test cases), UI polish, đối tác external links |

**Metrics:**

- 7 phases + 3 quick plans hoàn thành (26 plans executed)
- 92 test cases UAT (90 pass / 1 hidden / 1 missing) — coverage 97.8%
- Estimate đã gửi KH: ~321 MD = 642M VND

**Key decisions carried forward:**

- Stored Procedures PostgreSQL, KHÔNG ORM
- Repository pattern, no service layer (trừ auth)
- Ant Design 6 + custom theme (Deep Navy #1B3A5C)
- Next.js 16 + Express 5 + PostgreSQL 16 + MongoDB + Redis + MinIO
- JWT auth + refresh rotation
- Department subtree scoping cho phân quyền dữ liệu

**Archive:** `.planning/milestones/v1.0-phases/` (7 phase directories)

---

## v2.0 — Tích hợp ký số 2 kênh (2026-04-21 → 2026-04-23)

**Status:** ✓ Shipped

**Goal:** Hoàn thiện từ demo MVP → sản phẩm triển khai cho khách hàng thật, với khả năng chọn 1 trong 2 nền tảng ký số (SmartCA VNPT hoặc MySign Viettel) và quản lý ký số tập trung qua menu riêng.

**Delivered:**

| # | Phase | Scope |
|---|-------|-------|
| 8 | Schema foundation + PDF signing layer | 3 bảng + migration `staff.sign_phone` + PDF signing pure JS (node-signpdf + node-forge) |
| 9 | Admin config + provider adapters | SmartCA VNPT + MySign Viettel adapters, trang Admin cấu hình hệ thống với test connection |
| 10 | User config page | Trang `/ky-so/tai-khoan` form dynamic theo provider + verify, remove tab cũ trong `/thong-tin-ca-nhan` |
| 11 | Sign flow + async worker | API `/ky-so/sign` real, BullMQ worker poll 5s × 3 phút, Socket.IO `SIGN_COMPLETED`, ký lại/hủy |
| 11.1 | DB Consolidation & Seed Strategy | Consolidate 16 migrations → 1 master schema idempotent + tách seed required/demo |
| 12 | Menu Ký số + Danh sách 4 tab UI | Sidebar menu mới, trang `/ky-so/danh-sach` 4 tab dynamic (Cần ký / Đang xử lý / Đã ký / Thất bại) |
| 13 | Modal ký số robust + Root CA UX | Modal countdown 3:00, disable spam, banner Root CA Viettel + link `.cer` + HDSD PDF |
| 14 | Deployment + HDSD + verification | Deploy scripts Windows-only, seed provider config disabled, REQUIREMENTS audit 41 REQs |

**Metrics:**

- 8 phases (Phase 8-14 + 11.1), 39 plans executed
- 41/41 REQ-IDs Pass (SIGN×8, CFG×7, UX×13, ASYNC×6, MIG×5, DEP×2)
- DEP-03 deferred sang v2.1 (HDSD cấu hình ký số sau deploy với KH thật)

**Key decisions carried forward:**

- Master schema file `database/schema/000_schema_v2.0.sql` (20,168 dòng, idempotent)
- 2 cấp cấu hình ký số: Admin (provider + credentials) + User (user_id + certificate)
- Async sign: BullMQ worker poll provider mỗi 5s × tối đa 3 phút, Socket.IO push notification
- PDF PKCS7 detached signature pure JS (node-signpdf + node-forge)
- Personal bell notification persist trong PostgreSQL `notifications` table

**Tech debt (deferred):**

- Real LGSP HTTP client chưa implement — mock service đang chạy → v3.0
- DEP-03 HDSD cấu hình ký số → v2.1 khi có credentials KH thật

**Archive:**

- Roadmap: `.planning/milestones/v2.0-ROADMAP.md`
- Requirements: `.planning/milestones/v2.0-REQUIREMENTS.md`
- Audit: `.planning/milestones/v2.0-MILESTONE-AUDIT.md`
- Phases: `.planning/milestones/v2.0-phases/` (8 phase directories)
