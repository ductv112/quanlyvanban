# Requirements

**Milestone:** v2.0 Production features — Tích hợp ký số 2 kênh
**Created:** 2026-04-21
**Status:** Active
**Previous milestone (v1.0):** See `MILESTONES.md` — 100% shipped 2026-04-18 (92 test cases, 97.8% HDSD coverage)

---

## v2.0 Requirements

### SIGN — Signing Integration (8 requirements)

- [ ] **SIGN-01:** Admin có thể cấu hình SmartCA VNPT làm provider active với credentials hệ thống (`base_url`, `client_id`, `client_secret`)
- [ ] **SIGN-02:** Admin có thể cấu hình MySign Viettel làm provider active với credentials hệ thống (`base_url`, `client_id`, `client_secret`, `profile_id`)
- [ ] **SIGN-03:** User (người có quyền ký: lãnh đạo, cán bộ được giao) có thể ký file PDF đính kèm trên VB đi / VB dự thảo / HSCV trình ký bằng provider active
- [ ] **SIGN-04:** Hệ thống compute SHA256 hash PDF (PAdES byte range) và gọi API sign của provider active, nhận PKCS7 detached signature, embed vào PDF placeholder bằng `node-signpdf`
- [ ] **SIGN-05:** Hệ thống poll status transaction từ provider mỗi 5s, tối đa 3 phút (36 lần), để nhận kết quả ký sau khi user xác nhận OTP trên app mobile
- [ ] **SIGN-06:** User có thể ký lại file sau khi transaction fail/expire — tạo transaction mới, record cũ giữ cho audit
- [ ] **SIGN-07:** User có thể hủy transaction đang pending (status → cancelled) từ UI
- [ ] **SIGN-08:** Hệ thống lưu `sign_provider_code` vào attachment sau ký thành công — đảm bảo khi Admin switch provider sau này, lịch sử ký file cũ vẫn hiển thị đúng provider

### CFG — Configuration (7 requirements)

- [ ] **CFG-01:** Hệ thống enforce "single active provider" — chỉ 1 row `signing_provider_config` có `is_active = true` tại 1 thời điểm (partial unique index)
- [ ] **CFG-02:** Admin có thể switch provider mà không mất config user cũ — table `staff_signing_config(staff_id, provider_code)` composite PK cho phép giữ config đa provider
- [ ] **CFG-03:** Admin bấm "Test connection" khi lưu config → hệ thống gọi provider login/get_certificate test → chỉ lưu nếu response OK
- [ ] **CFG-04:** Credentials admin (`client_secret`) được encrypt bằng pgcrypto `pgp_sym_encrypt` trước khi lưu DB; decrypt khi đọc
- [ ] **CFG-05:** User có thể cấu hình tài khoản ký số cá nhân theo provider active:
  - SmartCA VNPT: chỉ input `user_id` (số ĐT/mã định danh)
  - MySign Viettel: input `user_id` + button "Tải danh sách CTS" → fetch list cert → Select `credential_id`
- [ ] **CFG-06:** User có thể bấm "Kiểm tra" để verify config cá nhân — hệ thống thử fetch certificate từ provider, update `is_verified = true` + `last_verified_at`
- [ ] **CFG-07:** Admin có thể xem trang dashboard provider active + stats (số user đã cấu hình, số user verified, số giao dịch ký tháng)

### UX — User Experience (13 requirements)

- [ ] **UX-01:** Sidebar có menu "Ký số" riêng (icon SafetyCertificate) với 3 submenu:
  - Cấu hình ký số hệ thống (Admin only) — `/ky-so/cau-hinh`
  - Tài khoản ký số cá nhân (Mọi user) — `/ky-so/tai-khoan`
  - Danh sách ký số (Mọi user) — `/ky-so/danh-sach`
- [ ] **UX-02:** Trang `/ky-so/danh-sach` có 4 tab với badge count: "Cần ký" / "Đang xử lý" / "Đã ký" / "Thất bại"
- [ ] **UX-03:** Tab "Cần ký" liệt kê documents có `signer_id = currentUser`:
  - `outgoing_docs` chưa ký
  - `drafting_docs` chưa ký
  - `handling_docs` status IN (2, 3) chưa ký
  - Button "Ký số" trên mỗi dòng mở modal ký trực tiếp (KHÔNG phải vào detail)
- [ ] **UX-04:** Tab "Đang xử lý" liệt kê `sign_transactions` WHERE `staff_id = me AND status = 'pending'` — button "Hủy" gọi cancel
- [ ] **UX-05:** Tab "Đã ký" liệt kê `sign_transactions` WHERE `status = 'completed'` với cột Provider + thời gian ký — button "Xem file" (download + banner Root CA nếu MySign)
- [ ] **UX-06:** Tab "Thất bại" liệt kê `status IN ('failed', 'expired', 'cancelled')` với `error_message` — button "Ký lại" tạo transaction mới
- [ ] **UX-07:** Modal ký số có button "Thực hiện ký" disable + spinner `<LoadingOutlined />` ngay khi click, không cho user spam
- [ ] **UX-08:** Modal ký số có `maskClosable: false`, button "Đóng" (giữ transaction chạy ngầm) vs "Hủy ký số" (mark cancelled)
- [ ] **UX-09:** Modal ký số hiển thị countdown 3:00 → 0:00 và text "Vui lòng xác nhận OTP trên ứng dụng [SmartCA/MySign] mobile"
- [ ] **UX-10:** Bell notification hiện toast + badge khi nhận Socket event `SIGN_COMPLETED` / `SIGN_FAILED` — user offline khi nhận cũng thấy notification trong bell dropdown
- [ ] **UX-11:** Khi user download file ký bằng MySign Viettel, hệ thống hiện banner dismissible với link tải Root CA `.cer` + HDSD PDF. LocalStorage lưu `dismiss_root_ca_banner = true` để không hiện lại
- [ ] **UX-12:** Trang chi tiết VB (`/van-ban-di/[id]`, `/van-ban-du-thao/[id]`, `/ho-so-cong-viec/[id]`) vẫn giữ button "Ký số" trên file đính kèm — đường dẫn thứ 2 vào flow ký, mở cùng modal
- [ ] **UX-13:** Tab "Chữ ký số" cũ trong `/thong-tin-ca-nhan` bị remove — migrate user sang `/ky-so/tai-khoan` (menu độc lập)

### ASYNC — Async Worker (6 requirements)

- [ ] **ASYNC-01:** POST `/ky-so/sign` trả `{ transaction_id }` ngay lập tức (< 1s), background worker xử lý polling status
- [ ] **ASYNC-02:** BullMQ worker poll `provider.getStatus(provider_txn_id)` mỗi 5s, re-queue với delay, tối đa 36 lần retry (3 phút tổng)
- [ ] **ASYNC-03:** User đóng browser / tắt modal giữa chừng → worker vẫn chạy → kết quả ký vẫn lưu vào DB + MinIO
- [ ] **ASYNC-04:** Backend restart giữa chừng → BullMQ job persistent trong Redis → job tự resume sau backend start lại
- [ ] **ASYNC-05:** Khi ký thành công → worker: (1) embed signature PKCS7 vào PDF, (2) upload file signed MinIO key mới, (3) update `attachments.is_ca=true`, (4) Socket.IO emit `SIGN_COMPLETED`, (5) tạo notification bell
- [ ] **ASYNC-06:** Khi ký thất bại/hết hạn → worker: (1) update `sign_transactions.status`, (2) Socket.IO emit `SIGN_FAILED` với `error_message`, (3) tạo notification bell

### MIG — Schema Migration (5 requirements)

- [ ] **MIG-01:** Schema migration tạo 3 bảng mới: `signing_provider_config` (admin cấp 1), `staff_signing_config` (user cấp 2), `sign_transactions` (audit log)
- [ ] **MIG-02:** Alter `attachments` thêm 2 cột: `sign_provider_code VARCHAR(20)` (nullable), `sign_transaction_id BIGINT` (nullable, FK)
- [ ] **MIG-03:** Migrate data `staff.sign_phone` existing sang `staff_signing_config` với `provider_code='SMARTCA_VNPT'` — clean schema, bảo toàn config cũ
- [ ] **MIG-04:** Drop column `staff.sign_phone` sau verify migration (hoặc mark deprecated với DEFAULT NULL + trigger warn)
- [ ] **MIG-05:** Breaking change: backend endpoint `/ky-so/mock/sign` → `/ky-so/sign` (dùng provider thật); cập nhật 3 frontend VB detail pages (`van-ban-di/[id]`, `van-ban-du-thao/[id]`, `ho-so-cong-viec/[id]`)

### DEP — Deployment & Docs (3 requirements)

- [ ] **DEP-01:** Deploy scripts (`deploy/*.sh`, `deploy/*.ps1`) cập nhật seed `signing_provider_config` mặc định disabled (cần admin config sau khi deploy)
- [ ] **DEP-02:** Copy Root CA Viettel `.cer` + HDSD PDF vào `frontend/public/root-ca/` từ `docs/huong_dan_tich_hop_ky_so_MySign_Viettel/` (build time)
- [ ] **DEP-03:** HDSD triển khai (`deploy/README.md`) thêm section "Cấu hình ký số sau deploy" hướng dẫn Admin: test connection, distribute Root CA cho end user máy

**Total: 42 requirements across 6 categories**

---

## Future Requirements (v2.1+)

- **FPT CA / EasyCA / các provider khác:** Architecture strategy pattern đã support — add provider mới chỉ cần implement interface + register
- **Multi-provider song song:** Nếu KH yêu cầu sau này (VD: lãnh đạo cấp cao dùng SmartCA, nhân viên dùng MySign) — schema `staff_signing_config` đã sẵn, chỉ cần bỏ constraint single-active
- **Ký batch nhiều file 1 lượt:** UI + worker hỗ trợ batch sign — scope v2.1+
- **Timestamping server (TSA):** Thêm TSA signature vào PKCS7 để chứng minh thời gian ký không bị sửa
- **Long-term validation (LTV):** Embed CRL/OCSP vào PDF signature — hợp pháp lâu dài 10+ năm
- **Remote signature verify API:** Endpoint độc lập verify chữ ký 1 PDF upload từ ngoài hệ thống

## Out of Scope (v2.0)

- **Mobile app native** — chỉ responsive web, KH dùng browser (không cần build app iOS/Android để confirm OTP — user confirm trên app SmartCA/MySign của VNPT/Viettel đã có)
- **Client-side Root CA installer** — hệ thống chỉ hiển thị banner + link, KHÔNG tự cài Root CA lên máy user (việc của IT triển khai, không phải code)
- **Backend Java/DotNet runtime** — quyết định dùng pure JS `node-signpdf` + `node-forge`, KHÔNG spawn `java -jar ViettelFileSigner.jar` hoặc Mono cho .NET DLL
- **Replacement of VNPT SmartCA / MySign với SDK của bên khác** — chỉ dùng 2 provider này theo yêu cầu, không mix với CKCA chính phủ hoặc khác
- **Ký file Word/Excel/XML** — v2.0 chỉ ký PDF (file đính kèm upload sẵn dạng PDF hoặc convert sang PDF)
- **Chữ ký số cho văn bản điện tử XML** (chuẩn quốc gia khác) — scope riêng, cần engineering khác

## Traceability

Filled by `/gsd-roadmapper` khi tạo ROADMAP.md. Mỗi REQ-ID map tới đúng 1 phase.

| Category | Count | Phase mapping |
|----------|-------|---------------|
| SIGN-*   | 8 | TBD |
| CFG-*    | 7 | TBD |
| UX-*     | 13 | TBD |
| ASYNC-*  | 6 | TBD |
| MIG-*    | 5 | TBD |
| DEP-*    | 3 | TBD |

---

*Updated 2026-04-21 — v1.0 requirements moved to MILESTONES.md as Validated, v2.0 scope defined*
