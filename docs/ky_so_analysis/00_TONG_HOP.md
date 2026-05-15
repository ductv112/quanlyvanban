# Tổng hợp đánh giá tích hợp ký số THẬT — e-Office

> **Ngày:** 2026-05-15
> **Phạm vi:** Đánh giá khả thi tích hợp THẬT 3 dịch vụ ký số (MySign Viettel, SmartCA Thường, SmartCA Tích hợp) vào e-Office, đối chiếu với code hiện tại.

## 1. So sánh 3 phương án ký số

| Tiêu chí | **SmartCA Thường (VNPT)** | **SmartCA Tích hợp (VNPT)** | **MySign Viettel (Viettel-CA)** |
|---|---|---|---|
| **Mô hình xác nhận user** | Mở app SmartCA mobile, bấm "Đồng ý" mỗi lần ký | Backend tự sinh TOTP từ secret user đã ủy quyền → ký không cần app | Mở app Mysign mobile, vân tay/Face ID |
| **API path** | `/sca/sp769/v1/*` | `/sca/sp769/v2/*` + `/rest/v2/*` (hashing) | `/vtss/service/ras/v1/*` + `/vtss/service/*` |
| **Số API call ký 1 file** | 3 (get_cert → sign → poll status) | 4 (get_cert → calculateHash → sign → confirm → signExternal) hoặc 5 nếu dùng flow VNPT helper | 3 (login → certInfo → signHash → status) |
| **Auth backend** | sp_id + sp_password (body, mọi request) | sp_id + sp_password (body) | client_id + client_secret + profile_id → access_token Bearer per-user, TTL 3600s |
| **Auth end-user** | user_id (CCCD) — đẩy notif app | user_id + **password user** + **TOTP secret** (lưu trên backend) | user_id Mysign |
| **Trả kết quả** | Async (polling 10s × 24, hoặc webhook) | Sync 2 bước (sign → confirm) | Async (sync mode 0, polling mode 1/2, hoặc webhook mode 3) |
| **Bảo mật** | Cao (user physical confirm) | Trung bình (password + TOTP secret nằm trên server e-Office) | Cao (user physical confirm) |
| **PDF hash compute** | Local Node.js (`@signpdf/signpdf`) — đã code | Local OR qua VNPT `rest/v2/calculateHash` | Local Node.js — đã code |
| **Lib Java/.NET bắt buộc?** | KHÔNG | KHÔNG (nếu dùng flow VNPT helper) | KHÔNG |
| **Effort thêm cho TÍCH HỢP THẬT (từ trạng thái hiện tại)** | **10-15 MD** | **11-17 MD** (chưa có provider trong code, làm mới) | **17-23 MD** (provider có nhưng chưa verify endpoint chính xác + spike PDF byte-range) |
| **Phù hợp e-Office** | ✅ Đúng nhất — cán bộ ký từng VB, user confirm trên mobile | ⚠️ Chỉ nên dùng cho ký tự động/batch (kế toán, hóa đơn) — rủi ro bảo mật cao nếu cán bộ ký công vụ | ✅ Phù hợp nếu KH dùng CA Viettel |
| **Trạng thái code hiện tại** | ✅ Provider adapter SMARTCA_VNPT đã code | ❌ CHƯA có provider SMARTCA_TH (cần làm mới) | ✅ Provider adapter MYSIGN_VIETTEL đã code |

### Khác biệt cốt lõi 3 phương án (1 câu)

- **SmartCA Thường:** "Cán bộ mở app VNPT SmartCA xác nhận từng văn bản" (an toàn nhất, mặc định cho e-Office).
- **SmartCA Tích hợp:** "Backend tự ký không cần app — đổi lại phải giữ password + TOTP secret của user" (chỉ dùng cho automation, KHÔNG khuyến nghị cho ký công vụ).
- **MySign Viettel:** "Cán bộ mở app Mysign xác nhận vân tay" (giống SmartCA Thường về UX, khác CA cung cấp).

---

## 2. Trạng thái code hiện tại

### Đã sẵn sàng (READY)
- ✅ **Schema DB** đầy đủ: `edoc.sign_transactions`, `public.signing_provider_config`, `public.staff_signing_config` + 7 stored functions
- ✅ **Provider seed:** 2 record sẵn (SMARTCA_VNPT, MYSIGN_VIETTEL) — `is_active=false`, chờ admin nhập credential
- ✅ **Backend adapter:** `smartca-vnpt.provider.ts`, `mysign-viettel.provider.ts` — KHÔNG mock, gọi API thật
- ✅ **PDF signer Node.js:** `pdf-signer.ts` dùng `@signpdf/signpdf` — placeholder + hash + sign — KHÔNG cần Java JAR
- ✅ **Worker poll BullMQ:** `signing-poll.worker.ts` — 5s/lần, max 3 phút, embed signature + upload MinIO + emit Socket.IO
- ✅ **Frontend admin config:** `/ky-so/cau-hinh` — chọn provider, test connection, kích hoạt
- ✅ **Frontend user config:** `/ky-so/tai-khoan` — input user_id, verify cert
- ✅ **Frontend SignModal:** countdown 3:00, status realtime, cancel, download
- ✅ **Encryption:** `pgp_sym_encrypt` cho client_secret với `SIGNING_SECRET_KEY` env
- ✅ **Provider config CRUD** đầy đủ

### CHƯA xong / Cần làm
- ❌ **CHƯA verify** endpoint paths + response schema trong adapter code có khớp tài liệu mới nhất (PDF v3/v4 của VNPT/Viettel) — code adapter viết dựa code legacy, cần đối chiếu lại
- ❌ **CHƯA spike** ký 1 file PDF thật E2E sandbox → verify Adobe Reader nhận diện signature
- ❌ **CHƯA có credential sandbox** từ nhà cung cấp (cả VNPT lẫn Viettel)
- ❌ **CHƯA có provider SMARTCA_TH** (nếu KH cần) — phải làm mới: TOTP generator, encrypt password, 2-step API
- ❌ **Frontend chưa wire** `listCertificates()` dropdown đầy đủ trong user config page
- ❌ **Frontend user KHÔNG chọn provider** khi ký — hệ thống chỉ dùng provider active duy nhất
- ❌ **Legacy MOCK routes** vẫn còn: `/api/ky-so/sign/smart-ca`, `/sign/esign-neac`, `/mock/sign`, `/mock/verify` — cần gỡ/disable trước demo
- ❌ **Visual signature** (logo + text overlay) — chưa có UI cho user chọn vị trí/style
- ❌ **Test E2E** với PDF tiếng Việt có dấu, multi-page, nhiều người ký

### Files hiện tại để biết
- `e_office_app_new/backend/src/services/signing/providers/smartca-vnpt.provider.ts`
- `e_office_app_new/backend/src/services/signing/providers/mysign-viettel.provider.ts`
- `e_office_app_new/backend/src/services/signing/pdf-signer.ts`
- `e_office_app_new/backend/src/workers/signing-poll.worker.ts`
- `e_office_app_new/backend/src/routes/ky-so-sign.ts` (Phase 11 REAL)
- `e_office_app_new/backend/src/routes/digital-signature.ts` (v1.0 MOCK — gỡ)

---

## 3. Thông tin cần xin nhà cung cấp (CRITICAL — blocker)

### Từ VNPT (SmartCA Thường + Tích hợp)
1. **`sp_id` + `sp_password` UAT** (sandbox) — bắt buộc để bắt đầu
2. **`sp_id` + `sp_password` Production** — go-live (sau khi UAT pass)
3. **1-2 account test sandbox**: CCCD + cert active + app SmartCA đã activate
4. **Nếu dùng Tích hợp:** Thêm `password user` + **TOTP secret** cho account test
5. **Whitelist IP** server e-Office (UAT + Prod) — VNPT có yêu cầu không
6. **Confirm endpoint production cho `rest/v2/*`** — sample chỉ ghi sandbox
7. **Mức phí giao dịch** + quota
8. **SLA + email kỹ thuật** (mặc định `cskh@vnpt.vn`)
9. **Đầu mối:** Liên hệ VNPT Lào Cai hoặc TTKD theo địa bàn

### Từ Viettel-CA (MySign)
1. **`client_id` + `client_secret` + `profile_id` sandbox** (UAT)
2. **URL sandbox** — tài liệu CHỈ ghi production `remotesigning.viettel.vn`, cần hỏi URL UAT riêng
3. **`client_id` + `client_secret` Production** — go-live
4. **1-2 account demo** có CTS Viettel-CA active + app Mysign đã activate
5. **Hỗ trợ webhook async=3 không?** Hoặc dùng polling
6. **Rate limit + quota + pricing**
7. **Sample PDF đã ký bằng MySign** để verify chữ ký giống chuẩn
8. **Whitelist IP** outbound
9. **Đầu mối:** Viettel-CA / Viettel Lào Cai

### Từ Khách hàng (UBND/cán bộ)
1. **Quyết định provider:** SmartCA hay MySign? (CA nào KH đã/đang dùng?)
2. **Quy trình onboarding** cán bộ ký số (~ ? người) — KH có dữ liệu CCCD chưa
3. **Server triển khai có IP public cố định không** (cho whitelist + webhook)
4. **PDF mẫu thực tế** (5-10 văn bản tỉnh) để test placeholder + visual signature

---

## 4. Quyết định kiến trúc cần chốt

### QĐ #1: Chọn provider chính
- **Option A:** Chỉ SmartCA Thường (VNPT) — khớp code hiện tại nhất, an toàn nhất
- **Option B:** Chỉ MySign Viettel — nếu KH đã dùng Viettel-CA
- **Option C:** Cả 2 (admin chọn active 1 trong 2) — code đã sẵn sàng, chỉ cần verify endpoint
- **Option D:** Cả 3 (thêm SmartCA Tích hợp) — phải code thêm provider mới, **không khuyến nghị** trừ khi KH có nhu cầu auto-sign batch

### QĐ #2: PDF hash strategy
- **Option A (đã code):** Pure Node.js local — `@signpdf/signpdf` tự compute hash byte-range. **Rủi ro:** sai 1 byte → signature invalid trên Adobe.
- **Option B:** Gọi VNPT helper `/rest/v2/signature/calculateHash` + `/signExternal` — VNPT xử lý PDF, không cần lib local. Trade-off: phụ thuộc API VNPT, latency cao hơn, upload file lên VNPT.
- **Option C:** Dựng Java/.NET signing service standalone (microservice). Phức tạp deploy.

→ **Khuyến nghị:** Bắt đầu với Option A (đã code). Spike 2-3 ngày verify Adobe Reader. Nếu fail → fallback Option B.

### QĐ #3: Cách user xác thực
- **SmartCA Thường:** Polling 10s × 24 lần (4 phút) — đơn giản, không cần expose public webhook.
- **Webhook async=3:** Hiệu năng tốt hơn, nhưng cần e-Office expose endpoint HTTPS public — vấn đề firewall on-prem.

→ **Khuyến nghị:** Phase 1 polling. Phase sau webhook nếu KH yêu cầu.

### QĐ #4: Visual signature
- Logo + text "Ký bởi: <Tên>, Thời gian: <ngày giờ>" trên PDF — KH có yêu cầu vị trí cố định, format cụ thể không
- UI cho user chọn vị trí (page, x, y) bằng drag-and-drop — có làm không hay hardcode

---

## 5. Roadmap triển khai THẬT (giả định: chỉ SmartCA Thường, code hiện tại)

| Phase | Việc | Effort | Blocker |
|---|---|---|---|
| **P0 — Pre-work** (làm song song chờ VNPT) | Đối chiếu endpoint adapter code với tài liệu v4.1 mới nhất, fix lệch (nếu có). Gỡ legacy MOCK routes. Bổ sung wire `listCertificates()` UI | 2-3 MD | Không |
| **P1 — Setup sandbox** | Nhận credential UAT VNPT, set `.env`, seed DB | 0.5 MD | **Chờ VNPT cấp credential UAT** (~1-2 tuần) |
| **P2 — Spike kỹ thuật** | Ký thử 1 PDF test → verify Adobe Reader xanh tick "Signature valid". Test placeholder không corrupt PDF tiếng Việt. | 2-3 MD | P1 |
| **P3 — Integration test** | Test E2E: chọn VB → ký → poll status → mở app SmartCA test confirm → embed signature → download PDF đã ký. Test edge: timeout, user reject, cert expired. | 3-4 MD | P2 |
| **P4 — Visual signature** | Logo + text overlay đúng yêu cầu KH. Font Times New Roman tiếng Việt có dấu. | 1-2 MD | KH duyệt format |
| **P5 — Onboarding KH** | KH cấp danh sách cán bộ + CCCD, đăng ký SmartCA với VNPT, cài app, kích hoạt. Bulk import vào `staff_signing_config`. | 1 MD code + nhiều ngày chờ VNPT/KH | KH triển khai |
| **P6 — Production switch** | Nhận credential prod, swap `.env`, smoke test với 1 cán bộ thật. | 1 MD | **Chờ VNPT cấp credential Prod + KH ký hợp đồng** |
| **P7 — Documentation** | HDSD cho cán bộ (text + video), HDSD admin cấu hình. | 1-2 MD | Không |
| **TỔNG** | | **11-16 MD công code** | Chủ yếu chờ VNPT + KH |

**Critical path:** Chờ credential VNPT (~1-2 tuần, không control được) + KH onboard cán bộ vào hệ thống VNPT. Mọi thứ code đã sẵn sàng, chỉ cần verify + test.

---

## 6. Rủi ro chính khi triển khai

| # | Rủi ro | Mitigation |
|---|---|---|
| 1 | **Sai byte-range PDF** → signature invalid trên Adobe Reader | Spike 2-3 ngày đầu phase. Test trên Adobe Reader + Foxit thật. Có Option B fallback (VNPT helper). |
| 2 | **Chờ VNPT/Viettel cấp credential** (1-2 tuần) | Chủ động liên hệ ngay khi user OK. Trong thời gian chờ → làm P0 (cleanup mock, đối chiếu endpoint). |
| 3 | **Cán bộ không biết dùng app SmartCA / Mysign** | Video tutorial + slide đào tạo. Khi user mở app lần đầu phải có TKKD VNPT support. |
| 4 | **Timeout 4 phút user không confirm** | UI báo "Hết hạn xác nhận, vui lòng ký lại" — KHÔNG auto-retry. |
| 5 | **Cert user hết hạn giữa giao dịch** | Cron daily check `cert_valid_to`, cảnh báo 30 ngày trước. |
| 6 | **Multi-signer 1 PDF** (lãnh đạo + văn thư đóng dấu) | Test với `multiSignatures=true`, ký nối tiếp không invalidate signature cũ. |
| 7 | **PDF có form field/annotation** conflict với placeholder | Test 5-10 PDF mẫu KH cung cấp. |
| 8 | **Visual signature font tiếng Việt không hiển thị đúng** | Embed font Unicode (Times New Roman, Arial) — dùng `pdf-lib` overlay TRƯỚC khi addPlaceholder. |
| 9 | **Webhook firewall on-prem** (nếu chọn async=3) | Phase 1 dùng polling, không cần webhook. |
| 10 | **Race TOTP** (chỉ Tích hợp) — OTP regen giây 29-30 | Retry 1 lần với OTP mới. |

---

## 7. Effort tổng & ưu tiên

- **Effort code thuần (không chờ):** 11-16 MD (~3 tuần 1 dev fulltime) cho SmartCA Thường
- **Thêm MySign Viettel:** +5-7 MD (provider đã có code, chỉ verify endpoint + test)
- **Thêm SmartCA Tích hợp:** +11-17 MD (provider mới, TOTP generator, encrypt password user)
- **Tổng cả 3 provider:** ~25-35 MD (~5-7 tuần)

**Ưu tiên đề xuất:**
1. **HÔM NAY:** Liên hệ VNPT/Viettel xin credential UAT (song song với code) + hỏi KH chọn provider nào
2. **TUẦN NÀY:** Đối chiếu adapter code với tài liệu mới nhất (P0). Gỡ MOCK legacy. Spike POC nếu đã có credential.
3. **TUẦN SAU:** Integration test + UAT với account VNPT test.
4. **2-3 TUẦN SAU:** Visual signature + onboard cán bộ + production switch.

---

## 8. Files tham khảo

- `01_mysign_viettel.md` — Phân tích chi tiết MySign Viettel (API, code demo, 23 MD plan)
- `02_smartca_thuong.md` — Phân tích chi tiết SmartCA Thường VNPT (API, code demo PHP, 15 MD plan)
- `03_smartca_tichhop.md` — Phân tích chi tiết SmartCA Tích hợp VNPT (OAuth-style, TOTP, 17 MD plan)
- `04_current_state.md` — Map toàn bộ code/schema/UI/env ký số hiện tại trong e-Office
