# Hướng dẫn test E2E ký số THẬT — SmartCA Tích hợp (DEV)

> **Mục đích:** Verify code Node.js ký PDF đúng chuẩn PAdES end-to-end với credential demo có sẵn trong tài liệu VNPT. Sau khi pass → khẳng định pipeline (provider adapter + worker poll + embed signature + visual overlay) hoạt động đúng → áp pattern same cho SmartCA Thường + MySign Viettel khi có credential thật.
>
> **Yêu cầu:** Docker compose + Node 18+ chạy local. KHÔNG cần app mobile (SmartCA Tích hợp dùng TOTP backend tự sinh).

## 1. Prerequisites — Reset DB + restart backend

### 1.1. Đảm bảo có file `.env`

```powershell
cd e_office_app_new\backend
# Nếu chưa có .env → copy từ template
if (-not (Test-Path .env)) { Copy-Item .env.example .env }
```

Verify file `e_office_app_new/backend/.env` có 3 dòng (mới thêm ở commit `995514d`):

```bash
SMARTCA_TH_USER_ID=871097
SMARTCA_TH_USER_PASSWORD=123456a@A
SMARTCA_TH_TOTP_SECRET=QTQ4RTAxN0JGMTE3MzcyMEIwNDlEREVCNTJBMDA2NjU=
```

Nếu chưa có → copy 3 dòng này từ `.env.example` vào.

### 1.2. Reset DB (drop + apply schema mới + seed)

```powershell
.\deploy\reset-db-windows.ps1
```

Script này drop schema cũ + apply `000_schema_v3.0.sql` mới (đã có CHECK constraint accept SMARTCA_VNPT_TH) + apply `001_required_data.sql` (đã seed record SmartCA TH).

Verify record SmartCA TH đã được seed:
```powershell
docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "SELECT provider_code, provider_name, base_url, is_active FROM public.signing_provider_config ORDER BY provider_code;"
```

Expected output: 3 rows (SMARTCA_VNPT, MYSIGN_VIETTEL, SMARTCA_VNPT_TH), tất cả `is_active=FALSE`.

### 1.3. Restart backend + frontend

Mở 2 terminal:

```powershell
# Terminal 1 — backend
cd e_office_app_new\backend
npm run dev
```

```powershell
# Terminal 2 — frontend
cd e_office_app_new\frontend
npm run dev
```

Mở browser: http://localhost:3000 → login `admin` / `Admin@123`.

---

## 2. Step 1 — Admin cấu hình provider SmartCA TH

1. Vào menu **Quản trị → Cấu hình ký số** (URL: `/ky-so/cau-hinh`)
2. Tìm dòng "SmartCA VNPT Tích hợp (DEV TEST)" trong danh sách 3 provider
3. Bấm "Chỉnh sửa" / "Sửa" → form mở
4. Nhập:
   - **Base URL:** `https://rmgateway.vnptit.vn` (sandbox của VNPT)
   - **Client ID (sp_id):** `4185-637127995547330633.apps.signserviceapi.com`
   - **Client Secret (sp_password):** `NGNhMzdmOGE-OGM2Mi00MTg0`
   - **Profile ID:** để rỗng
5. Bấm "Lưu"
6. Bấm "Kiểm tra kết nối" (Test Connection)
   - ✅ Nếu success → "Kết nối SmartCA VNPT Tích hợp thành công" → đi tiếp
   - ❌ Nếu fail → kiểm tra log backend (`pino-pretty` output), thường là sai endpoint hoặc credential VNPT đã đổi
7. Bấm "Kích hoạt" (Activate) → row chuyển sang xanh "Đang hoạt động"
   - Các provider khác (SmartCA Thường, MySign) tự deactivate

---

## 3. Step 2 — User cấu hình tài khoản ký số

1. Vào menu **Cá nhân → Tài khoản ký số cá nhân** (URL: `/ky-so/tai-khoan`)
2. Form hiện ra với "Provider đang hoạt động: SmartCA VNPT Tích hợp (DEV TEST)"
3. Nhập **Mã định danh:** `871065` hoặc `871097` (account demo của VNPT — kiểm tra hộp văn bản placeholder)
4. Bấm "Lưu cấu hình" → success
5. Bấm "Xác thực tài khoản ký số" → backend gọi `listCertificates()` với user_id vừa nhập
   - ✅ Nếu success → badge xanh "Đã xác thực" + hiển thị Chủ thể chứng thư (subject DN)
   - ❌ Nếu fail → có thể user_id `871097` không có cert active trong sandbox → thử CCCD khác (xem `02_smartca_thuong.md` mục 8 — account `162952530` cũng có)

---

## 4. Step 3 — Ký thử 1 PDF E2E

### Setup quyền

Verify tài khoản đang login có role `Ban Lãnh đạo` hoặc `Quản trị hệ thống`. Mặc định `admin` có quyền.

### Tạo file PDF test (nếu chưa có)

- Upload 1 file PDF nhỏ (vd: `test-1page.pdf`) vào hệ thống qua menu "Văn bản đi → Thêm mới → upload đính kèm"
- Hoặc dùng file VB đi có sẵn

### Ký

1. Vào trang chi tiết 1 VB đi
2. Trong phần "Đính kèm" → tìm nút "Ký số" cạnh file PDF → click
3. **SignModal** mở:
   - Countdown 3:00 hiển thị
   - Status tag "Đang chờ provider..." (pending)
4. Backend flow:
   - Download PDF từ MinIO
   - Add visual signature overlay (góc dưới-phải page cuối, hiển thị tên ký + ngày giờ)
   - Add PAdES placeholder
   - Compute SHA-256 hash byte range
   - Call provider `signHash()` → adapter TH gọi `/v2/signatures/sign` + `/v2/signatures/confirm` → cache signature_value
   - Enqueue BullMQ poll job (5s delay)
   - Trả `transaction_id` cho frontend
5. Sau ~5s:
   - Worker poll → adapter TH lookup cache → trả signature → embed PDF → upload MinIO → emit Socket.IO event
   - SignModal nhận event → status xanh "Ký thành công" → nút "Tải xuống"

### Verify Adobe Reader

1. Click "Tải xuống" → file `*-signed.pdf` lưu về máy
2. Mở bằng **Adobe Reader** (KHÔNG dùng Chrome PDF viewer — không support signature panel)
3. Kiểm tra:
   - ✅ Panel "Signatures" bên trái có "Signed by Ngo Quang Dat test SmartCA" (hoặc tên user demo)
   - ✅ Tab "Signature Properties" → "Validity Summary": "Signature is VALID" hoặc "valid with warnings" (warnings về Root CA chưa trust — bình thường vì Adobe chưa có Vietnam Root CA mặc định)
   - ✅ Visual overlay góc dưới-phải page cuối: rectangle navy + text "KY SO DIEN TU" / "Nguoi ky: ..." / "Thoi gian: ..."

---

## 5. Troubleshoot — các lỗi thường gặp

| Lỗi | Nguyên nhân | Fix |
|---|---|---|
| Test Connection fail "401 SP_CREDENTIAL_INVALID" | `sp_id` / `sp_password` sai | Copy lại từ section 2 |
| Test Connection fail timeout | Server không access được `rmgateway.vnptit.vn` (firewall/proxy) | Check kết nối mạng |
| Verify cert fail "user not exist" | User demo `871097` không có cert active | Thử user `162952530` |
| Ký fail "Phải xác thực OTP" | TOTP secret sai/clock skew | Check NTP đồng bộ với VNPT, đảm bảo `SMARTCA_TH_TOTP_SECRET` chính xác |
| Adobe Reader báo "Signature INVALID" | Hash byte-range sai, embed signature lệch | Check log worker, dump `signature_base64` từ DB → verify base64 → so với raw bytes |
| Visual overlay không hiện | `signerName` không được pass (cert chưa verify hoặc CN parse fail) | Verify `userConfig.certificate_subject` trong DB, regex `/CN=([^,]+)/` |
| Worker stuck pending mãi | Adapter cache miss (signHash → confirm xong nhưng cache bị restart) | Backend restart sẽ clear in-memory cache. Ký lại từ đầu. |

---

## 6. Cleanup sau khi test xong

### Disable provider TH (KHÔNG bật trên production)

```sql
-- Set is_active=FALSE để chỉ test trong dev
UPDATE public.signing_provider_config
   SET is_active = FALSE, client_id = '', client_secret = pgp_sym_encrypt('', current_setting('app.signing_secret_key'))
 WHERE provider_code = 'SMARTCA_VNPT_TH';
```

### Hoặc xóa hẳn provider TH (nếu KH không bao giờ dùng)

```sql
DELETE FROM public.staff_signing_config WHERE provider_code = 'SMARTCA_VNPT_TH';
DELETE FROM edoc.sign_transactions WHERE provider_code = 'SMARTCA_VNPT_TH';
DELETE FROM public.signing_provider_config WHERE provider_code = 'SMARTCA_VNPT_TH';
```

Sau đó remove 3 dòng env vars `SMARTCA_TH_*` khỏi `.env` (giữ trong `.env.example` để document).

---

## 7. Acceptance criteria — pass = code Node.js đúng chuẩn

- [x] Backend boot OK với env vars mới, không lỗi schema
- [x] DB có 3 provider rows (SmartCA Thường, MySign, SmartCA TH)
- [x] Admin Test Connection SmartCA TH → success
- [x] User verify cert → badge "Đã xác thực" + hiển thị Chủ thể chứng thư
- [x] Ký 1 PDF → SignModal complete trong ~10s → download
- [x] Adobe Reader: Signature panel xanh tick "Signature is VALID"
- [x] Visual overlay góc dưới-phải page cuối hiển thị đúng tên + ngày

Khi tất cả tick → code Node.js đã verify đúng chuẩn PAdES. Sau đó:
- Áp dụng pattern same cho SmartCA Thường (đã code sẵn — chỉ cần KH cung cấp credential + dùng app SmartCA mobile)
- Áp dụng cho MySign Viettel (đã code sẵn — chỉ cần Viettel cấp credential + KH dùng app Mysign)
- Disable provider TH trên production trước khi demo cho KH

---

## 8. Files liên quan (commits hôm nay)

| Commit | Mô tả |
|---|---|
| `88f9771` | P0: cleanup mock signing service + legacy routes |
| `3ec3a70` | P1: fix adapter SmartCA + MySign khớp tài liệu chính thức (status_code 0→200, transaction_id UUID, document_name base64, status codes mapping) |
| `995514d` | A1: schema + seed + env cho provider SMARTCA_VNPT_TH |
| `f396603` | A2+A3: provider TH adapter (v2 + TOTP) + factory + worker dispatch |
| `4344c35` | B1+B2+B3: visual signature overlay + UI polish (PROVIDER_UX + PROVIDER_LABEL) |
