# Milestones

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

**Quick plans trong v1.0 (không đếm vào phase):**
- `260418-gs7` — Ẩn các module Phase 2 chưa có trong HDSD cũ
- `260418-hlj` — HDSD Compliance P0+P1: SmartCA UI, thu hồi VB liên thông, HSCV mở lại/lấy số
- `260418-jsd` — HDSD Compliance fix 6 gap: ký số OTP mock, chuyển tiếp HSCV, trục CP mock

**Metrics:**
- **7 phases + 3 quick plans** hoàn thành
- **26 plans executed** với atomic commits
- **92 test cases UAT** (90 pass / 1 hidden / 1 missing) — coverage 97.8%
- **6+ modules ẩn Phase 2** (Tin nhắn, Lịch, Danh bạ, Kho lưu trữ, LGSP, v.v.) để demo focus đúng HDSD cũ

**Key decisions carried forward:**
- Stored Procedures PostgreSQL, KHÔNG ORM
- Repository pattern, no service layer (trừ auth)
- Ant Design 6 + custom theme (Deep Navy #1B3A5C)
- Next.js 16 + Express 5 + PostgreSQL 16 + MongoDB + Redis + MinIO
- JWT auth + refresh rotation
- Department subtree scoping cho phân quyền dữ liệu

**Estimate đã gửi KH:** ~321 MD = 642M VND (file `docs/Function list & Estimate.xlsx`, gitignored)

---

## v2.0 — Production features (2026-04-21 → in progress)

**Status:** 🟡 Đang triển khai

**Goal:** Hoàn thiện từ demo MVP → sản phẩm triển khai cho khách hàng thật, với khả năng chọn 1 trong 2 nền tảng ký số (SmartCA VNPT hoặc MySign Viettel) và quản lý ký số tập trung qua menu riêng.

**In-flight features:**
- Menu "Ký số" riêng ở sidebar với 3 submenu (Cấu hình hệ thống / Tài khoản cá nhân / Danh sách ký số với 4 tab)
- Tích hợp thật SmartCA VNPT (`https://gwsca.vnpt.vn/sca/sp769/v1/*`) + MySign Viettel (`/vtss/service/ras/v1/*`)
- PDF signing Pure JS dùng `node-signpdf` + `node-forge` (PKCS7 detached)
- Async decoupled worker (BullMQ) + Socket.IO push SIGN_COMPLETED
- Modal ký robust với countdown 3 phút, disable spam click
- Root CA UX banner khi file ký bằng MySign
- 2 cấp cấu hình: Admin (provider active + credentials hệ thống) + User (user_id + certificate)
- Migration schema `staff.sign_phone` → `staff_signing_config` multi-provider

**Estimate:** Separate (continuation scope, not re-estimated per user decision)
