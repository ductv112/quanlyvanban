# Phân tích kỹ thuật — VNPT SmartCA gói TÍCH HỢP (SmartCA TH / OAuth)

> **Phạm vi:** Tài liệu này phân tích gói "SmartCA Tích hợp" (SmartCA TH) — gói dành cho 3rd Party tích hợp ký số tập trung qua OAuth-style credentials + TOTP, **KHÁC** với gói "SmartCA Thường" (yêu cầu user xác nhận trên app mobile mỗi lần ký).
>
> **Nguồn dữ liệu:**
> - `docs/huong_dan_tich_hop_ky_so_SmartCA_tich_hop/Tài liệu tích hợp SmartCATH v3.0.pdf` (qua bản extract text tại `_kichban_smartca.txt`)
> - `docs/huong_dan_tich_hop_ky_so_SmartCA_tich_hop/HUONG DAN TICH HOP_VNPT SmartCA goi Tich hop_oauth_v3.4.5.pdf`
> - Source code mẫu: PHP cURL, .NET Core (net5.0), .NET Framework 4.5.2, Java
> - `SignHashService/` (.NET Framework Web app, dùng VnptHashSignatures.dll)
>
> **Lưu ý quan trọng về thuật ngữ:** Tài liệu VNPT dùng cụm "OAuth" rất lỏng. Sau khi đọc kỹ tất cả 4 sample code + spec, **gói Tích hợp KHÔNG dùng OAuth2 chuẩn (authorize/token/refresh)**. Thay vào đó, nó dùng mô hình "SP credentials + user credentials + TOTP" — gần giống Basic Auth + 2FA. Mỗi request gửi trực tiếp `sp_id` + `sp_password` + `user_id` + `password` + `otp` trong JSON body. Không có endpoint `/oauth/token`, không có Bearer access_token, không có authorization code flow.

---

## 1. SmartCA Tích hợp là gì

### 1.1. Định nghĩa (trích nguyên văn tài liệu mục 4)

> "SmartCATH là 1 loại tài khoản của SmartCA, loại tài khoản này đầy đủ các tính năng của SmartCA bình thường, có thể gọi tất cả các luồng API của mục 3 và có thêm 1 tính năng nữa đấy là **có thể ký mà không cần xác nhận trên APP điện thoại** nếu như người dùng cung cấp các thông tin cần thiết để thực hiện luồng ký tự động này."

### 1.2. Phân biệt với SmartCA Thường

| Điểm | SmartCA Thường (gói thường) | SmartCA Tích hợp (TH) |
|---|---|---|
| **Endpoint sign** | `/sca/sp769/v1/signatures/sign` | `/sca/sp769/v2/signatures/sign` |
| **Xác nhận user** | User PHẢI bấm "Đồng ý" trên app VNPT SmartCA mobile mỗi lần ký | KHÔNG cần bấm trên mobile, miễn là 3rd party có TOTP secret |
| **Yếu tố xác thực** | sp_id + sp_password + user_id (CA push notif tới app, user confirm) | sp_id + sp_password + **user_id + user_password + OTP (TOTP)** |
| **Trả về kết quả** | Async (webhook `/sign/{tranId}/status` hoặc CA push webhook) | Sync 2 bước (sign → trả `sad` → confirm → trả `signature_value`) |
| **Phù hợp** | Cá nhân ký tài liệu cá nhân (cần user mở app confirm) | Doanh nghiệp ký hàng loạt, ký tự động (e-Office, ERP, hóa đơn điện tử) |
| **Bảo mật** | Cao hơn (yêu cầu thiết bị physical) | Trung bình (TOTP secret nằm trong server 3rd party — phải bảo mật) |

### 1.3. Mô hình "OAuth" thực tế

**KHÔNG có OAuth2 chuẩn**. Hệ thống dùng:

- **SP credentials (3rd party app):** `client_id` (đặt tên là `sp_id` trong API) + `client_secret` (`sp_password`) — VNPT cấp cho doanh nghiệp một lần.
- **User credentials (end-user):** `user_id` (CCCD/CMND/MST) + `password` (mật khẩu SmartCA) — user tự đăng ký SmartCA.
- **TOTP secret:** Chuỗi base64 (mỗi user một secret riêng, VD: `"QTQ4RTAxN0JGMTE3MzcyMEIwNDlEREVCNTJBMDA2NjU="`) — user "ủy quyền" cho 3rd party bằng cách cung cấp TOTP secret để 3rd party tự sinh OTP HMAC-SHA1, 30s/lần, 6 digits.

**Audience / Scope:** Không có. Mỗi request mang đầy đủ credentials.
**Redirect URI / PKCE:** Không áp dụng.
**Token lifetime:** Không có access token. Mỗi giao dịch ký có 2 token tạm:
- `tran_code`: định danh giao dịch trên CA.
- `sad` (Signature Activation Data) — JWT trả về từ API `/sign`, `expired_in: 299` giây — dùng làm input cho `/confirm` để hoàn tất ký. Đây là cái gần "access token" nhất, nhưng chỉ dùng trong 1 giao dịch duy nhất.

---

## 2. "OAuth" Authentication chi tiết

> Vì gói Tích hợp KHÔNG có endpoint `/oauth/token` riêng, mục này mô tả cơ chế authentication thực tế.

### 2.1. Không có Authorize / Token endpoint

- Không có `/authorize` (không có authorization code flow).
- Không có `/token` (không cần lấy access_token trước khi gọi API).
- Không có refresh_token, không có scope, không có redirect_uri.

### 2.2. Credentials phân lớp

**Lớp 1 — SP (App level):**
```
sp_id     = "4185-637127995547330633.apps.signserviceapi.com"   // do VNPT cấp
sp_password = "NGNhMzdmOGE-OGM2Mi00MTg0"                         // do VNPT cấp
```
Định danh ứng dụng e-Office. Set 1 lần trong config backend.

**Lớp 2 — End-user (Subscriber level):**
```
user_id       = "871097"            // CCCD hoặc mã số thuế thuê bao SmartCA
password      = "123456a@A"          // password đăng nhập SmartCA của user
serial_number = "54010101..."        // serial cert của user, lấy từ get_certificate
TOTP_secret   = "QTQ4RTAxN0JGMTE3MzcyMEIwNDlEREVCNTJBMDA2NjU="  // base64 — KHÔNG QUA SHARING NÀO, user nhập vào e-Office (UI quản lý cá nhân)
```
Mỗi nhân sự cần ký số trong e-Office phải có 1 set thông tin user-level riêng. **Mật khẩu user và TOTP secret là dữ liệu nhạy cảm — phải mã hóa khi lưu DB (KHÔNG plaintext).**

### 2.3. TOTP — sinh OTP HMAC-SHA1 mỗi 30s

PHP code (file `OTPService.php`):
```php
const keyRegeneration = 30;       // 30s per regen
const otpLength       = 6;        // 6 digits

public static function get_timestamp() {
    return floor(time() / self::keyRegeneration);
}

public static function oath_hotp($key, $counter) {
    $bin_counter = pack('N*', 0) . pack('N*', $counter);    // 64-bit int
    $hash = hash_hmac('sha1', $bin_counter, $key, true);
    return str_pad(self::oath_truncate($hash), 6, '0', STR_PAD_LEFT);
}
```

Java code (`OTPService.java`) dùng lib `com.eatthepath.otp.TimeBasedOneTimePasswordGenerator`, thuật toán `HmacSHA1`, period 30s, 6 digits.

.NET code dùng `OtpNet.Totp` package — mặc định cũng HMAC-SHA1 + 30s + 6 digits.

**Trong Node.js:** dùng package `otplib` hoặc `speakeasy`:
```ts
import { authenticator } from 'otplib';
authenticator.options = { step: 30, digits: 6, algorithm: 'sha1' };
const otp = authenticator.generate(totpSecretBase64);  // Lưu ý: secret phải decode base64
```

### 2.4. Sample HTTP

**KHÔNG có "Authorization: Bearer xxx" header.** Tất cả qua body:

```bash
POST https://rmgateway.vnptit.vn/sca/sp769/v2/signatures/sign
Content-Type: application/json
Accept: application/json

{
  "sp_id": "4185-637127995547330633.apps.signserviceapi.com",
  "sp_password": "NGNhMzdmOGE-OGM2Mi00MTg0",
  "user_id": "871097",
  "password": "123456a@A",
  "otp": "249560",
  "transaction_id": "<UUID do SP sinh>",
  "serial_number": "54010101aad15185e5d334900b526deb",
  "sign_files": [ ... ]
}
```

---

## 3. Signing API Endpoints (chi tiết)

### 3.1. Base URLs (mục 4.1 + 3.1)

| Env | URL |
|---|---|
| **UAT / Sandbox** | `https://rmgateway.vnptit.vn/sca/sp769` |
| **Production** | `https://gwsca.vnpt.vn/sca/sp769` |

Tất cả API: `POST` + `Content-Type: application/json` + `Accept: application/json`.

### 3.2. API #1 — `v1/credentials/get_certificate`

**Mục đích:** Lấy danh sách chứng thư số của user (cần để biết serial + cert_data PEM để tính hash PAdES).

**Request body:**
```json
{
  "sp_id": "4185-637127995547330633.apps.signserviceapi.com",
  "sp_password": "NGNhMzdmOGE-OGM2Mi00MTg0",
  "user_id": "871097",
  "serial_number": "",          // optional — để rỗng lấy tất cả cert của user
  "transaction_id": "<UUID>"
}
```

**Response body (thành công):**
```json
{
  "status_code": 200,
  "message": "Success",
  "data": {
    "user_certificates": [
      {
        "service_type": "SMARTCA",
        "service_name": "SMARTCA PERSONAL PRO",
        "cert_id": "fcfffddf-2bed-4dda-8276-d00b4c3df6c9",
        "cert_status": "đang hoạt động",
        "serial_number": "54010101493c47d39f8a84b30ed55191",
        "cert_subject": "C=VN,ST=Hà Nội,L=Quận,CN=Ngô Quang Đạt test SmartCA,UID=CMND:162952530",
        "cert_valid_from": "2023-07-18T09:12:00Z",
        "cert_valid_to":   "2026-07-18T21:12:00Z",
        "cert_data": "MIIFQjCCBCqgAwIBAg...",      // PEM base64 (không có header BEGIN/END)
        "chain_data": {
          "ca_cert":   "MIIGNDCCBBygAwI...",
          "root_cert": "MIIG/DCCBOSgAw..."
        },
        "transaction_id": "SP_CA_09940"
      }
    ]
  }
}
```

**Lưu ý:** 1 user có thể có nhiều cert (SMARTCA cá nhân + ESEAL doanh nghiệp). UI e-Office cần cho user chọn cert nào để ký, hoặc dùng `service_type=SMARTCA` cho cá nhân.

### 3.3. API #2 — `rest/v2/signature/calculateHash` (chỉ trong sample PHP)

> **CẢNH BÁO QUAN TRỌNG:** Đây là API **PHỤ TRỢ** ngoài `sp769` path, host khác phần endpoint chuẩn. Chỉ thấy trong sample PHP (`signature_curl.php` dòng 107):
> ```
> https://rmgateway.vnptit.vn/rest/v2/signature/calculateHash
> ```
> Sample .NET Core và Java **KHÔNG dùng API này** — họ tính hash PAdES **local** bằng thư viện `VnptHashSignatures.dll` (cho .NET) hoặc `vnpthashsignature-1.0.1.5-jar-with-dependencies-JAVA1.7.jar` (cho Java).

**Mục đích (khi dùng):** Backend không có lib PDF/PAdES local → upload PDF base64 lên VNPT, VNPT tính hash trả về.

**Request body (PHP sample):**
```json
{
  "transaction_id": "<UUID>",
  "sp_id": "...",
  "sp_password": "...",
  "signerCert": "<base64 cert từ get_certificate>",
  "digestAlgorithm": "sha256",
  "sign_files": [
    {
      "storage_file_name": "",
      "name": "test.pdf",
      "pdfContent": "<base64 toàn bộ file PDF>",
      "sigOptions": {
        "renderMode": 4,         // 0:TextOnly, 1:TEXT_WITH_LOGO_LEFT, 2:LOGO_ONLY, 3:TEXT_WITH_LOGO_TOP, 4:TEXT_WITH_BACKGROUND
        "customImage": "<base64 PNG logo>",
        "fontSize": 13,
        "fontColor": "#000000",
        "signatureText": "Ký bởi: Nguyễn Văn A\nThời gian ký: 17/05/2023 09:43:23",
        "signatures": [
          { "page": 1, "rectangle": "0,581,200,657" }
        ]
      }
    }
  ]
}
```

**Response:**
```json
{
  "tranId": "<UUID giao dịch hash>",
  "hashResps": [
    {
      "code": "sigSuccess",
      "hash": "<base64 second-hash>",
      "fileID": "<UUID file>"
    }
  ]
}
```

**Cặp đôi với API:** `rest/v2/signature/signExternal` (mục 3.6 dưới đây) — sau khi có signature value, gọi để VNPT ghép vào PDF trả file đã ký.

### 3.4. API #3 — `v2/signatures/sign` (CORE)

**Mục đích:** Submit hash lên CA, CA validate + tạo giao dịch ký, trả `sad` (Signature Activation Data).

**Request body (mục 4.3):**
```json
{
  "sp_id": "4185-637127995547330633.apps.signserviceapi.com",
  "sp_password": "NGNhMzdmOGE-OGM2Mi00MTg0",
  "user_id": "871097",
  "password": "123456a@A",            // password đăng nhập SmartCA của user
  "otp": "249560",                     // OTP TOTP 6 digits hiện tại
  "transaction_id": "<UUID do SP sinh>",
  "serial_number": "54010101aad15185e5d334900b526deb",
  "sign_files": [
    {
      "data_to_be_signed": "17001dcce9fe19e30cba5219f86ad05fd6c802338078521af634dab92eef96d7",
      // HEX (LOWER CASE) của hash bytes. Lưu ý: PHP/.NET/Java đều convert
      // base64(hash) → hex(bytes) trước khi gửi
      "doc_id": "30c-7401-2562",       // ID tài liệu — SP tự đặt, để track
      "file_type": "pdf",              // pdf / xml / word / cms
      "sign_type": "hash"              // Hiện CA chỉ hỗ trợ "hash"
    }
    // có thể thêm nhiều item → ký batch
  ]
}
```

**Response (thành công, mục 4.3):**
```json
{
  "status_code": 200,
  "message": "sig_wait_for_user_confirm",
  "data": {
    "transaction_id": "67975bcc-5ee7-4a24-ab29-dd9f3c8fe32a",
    "tran_code": "b40d5ec4-513c-420a-b4e8-cc413eac308c",
    "sad": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9...",
    "expired_in": 299                  // SAD valid 299s
  }
}
```

> **Quan trọng:** Message `"sig_wait_for_user_confirm"` nghe có vẻ như chờ user confirm, NHƯNG với gói TH thì không cần — gọi tiếp `confirm` ngay.

### 3.5. API #4 — `v2/signatures/confirm` (FINALIZE)

**Mục đích:** Hoàn tất giao dịch ký, CA trả về `signature_value` (chữ ký số PKCS#1 base64).

**Request body (mục 4.4):**
```json
{
  "sp_id":   "4185-637127995547330633.apps.signserviceapi.com",
  "sp_password": "NGNhMzdmOGE-OGM2Mi00MTg0",
  "user_id": "871097",
  "password": "123456a@A",
  "transaction_id": "67975bcc-5ee7-4a24-ab29-dd9f3c8fe32a",  // từ response /sign
  "sad": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9..."           // từ response /sign
}
```

**Response (thành công):**
```json
{
  "status_code": 200,
  "message": "Success",
  "data": {
    "transaction_id": "a71bf8ad-71ad-4823-b586-33c8698b768e",
    "expired_in": 299,
    "signatures": [
      {
        "doc_id": "30c-7401-2562",
        "signature_value": "ZLebEc4JFwgCT2l13feWFH6...",   // base64 PKCS#1
        "timestamp_signature": null
      }
    ]
  }
}
```

### 3.6. API #5 — `rest/v2/signature/signExternal` (chỉ trong sample PHP)

**Mục đích:** Nếu dùng API `calculateHash` (mục 3.3) thì gọi tiếp `signExternal` để VNPT ghép signature vào PDF, trả file đã ký.

**Request body:**
```json
{
  "tranId": "<từ response calculateHash>",
  "sp_id": "...",
  "sp_password": "...",
  "signatures": [
    {
      "fileID": "<từ response calculateHash>",
      "signature": "<signature_value từ /confirm>"
    }
  ]
}
```

**Response:**
```json
{
  "signResps": [
    { "signedData": "<base64 PDF đã ký hoàn chỉnh>" }
  ]
}
```

### 3.7. API polling (chỉ cho gói Thường)

`POST /v1/signatures/sign/{tranId}/status` — **chỉ áp dụng cho gói Thường** (mục 3.4 trong doc). Gói Tích hợp KHÔNG cần polling vì flow đã sync qua `/sign` → `/confirm`.

### 3.8. Webhook (chỉ cho gói Thường)

Mục 3.5 trong doc — CA gọi webhook về SP khi user xác nhận xong. **Không áp dụng cho gói TH.**

### 3.9. Mã lỗi (mục 3.1)

| HTTP | Mã | Ý nghĩa |
|---|---|---|
| 200 | SUCCESS | Thành công |
| 400 | BAD_REQUEST | Sai format |
| 401 | SP_CREDENTIAL_INVALID | sp_id/sp_password sai hoặc user không đúng |
| 403 | CREDENTIAL_STATUS_INVALID | Cert hết hạn / bị khóa |
| 500 | SERVER_INTERNAL_ERROR | Lỗi server, xem `message` |

---

## 4. Signing flow E2E

### 4.1. Flow CHUẨN — Tính hash LOCAL (như Java/.NET sample)

```
┌───────────────────────────────────────────────────────────────────────────┐
│ e-Office Backend (Node.js) — KHÔNG dùng API calculateHash/signExternal    │
└───────────────────────────────────────────────────────────────────────────┘
[1] User upload PDF + chọn vị trí ký (page, rectangle), reason, image
   ↓
[2] Backend: gọi POST /v1/credentials/get_certificate
   → response: cert_data (base64 PEM), serial_number
   ↓
[3] Backend: TÍNH HASH PAdES LOCAL
   - Chèn signature placeholder (rectangle, page) vào PDF
   - Tính "second hash" = SHA-256(SignedAttributes) theo chuẩn PAdES (CAdES B-T)
   - Cần lib: pdf-lib + node-forge / pdfsigner / @signpdf/signpdf
   - Hash kết quả: 32 bytes → convert HEX lower-case (KHÔNG base64)
   ↓
[4] Backend: tự sinh TOTP từ user.totp_secret
   - otplib: HMAC-SHA1, 30s, 6 digits
   ↓
[5] Backend: POST /sca/sp769/v2/signatures/sign
   body: { sp_id, sp_password, user_id, password, otp, transaction_id, serial_number,
           sign_files: [{ data_to_be_signed: HEX_HASH, doc_id, file_type: "pdf", sign_type: "hash" }] }
   → response: { transaction_id, sad, expired_in: 299 }
   ↓
[6] Backend: POST /sca/sp769/v2/signatures/confirm
   body: { sp_id, sp_password, user_id, password, transaction_id, sad }
   → response: { signatures: [{ doc_id, signature_value: <base64 PKCS#1> }] }
   ↓
[7] Backend: GHÉP signature_value VÀO PDF LOCAL
   - Decode base64 → bytes
   - Ghi vào placeholder đã chèn ở bước 3
   - Tạo file PDF cuối cùng, lưu vào MinIO
   ↓
[8] Frontend tải file đã ký
```

**Đặc điểm:** 4 lần gọi API VNPT, 100% xử lý PDF local, không gửi file gốc lên VNPT.

### 4.2. Flow ALTERNATIVE — Dùng API calculateHash/signExternal (PHP sample)

Phù hợp khi backend KHÔNG có thư viện PAdES local mạnh:

```
[1-2] giống flow 4.1
[3] Backend: POST /rest/v2/signature/calculateHash
   body: { signerCert, digestAlgorithm: "sha256", sign_files: [{ pdfContent: <base64 cả file>, sigOptions }] }
   → response: { tranId, hashResps: [{ hash: base64, fileID }] }
[4] Convert hash base64 → hex → giống flow 4.1 bước 5
[5-6] /sign → /confirm như flow 4.1
[7] Backend: POST /rest/v2/signature/signExternal
   body: { tranId, sp_id, sp_password, signatures: [{ fileID, signature: <signature_value> }] }
   → response: { signResps: [{ signedData: <base64 file PDF đã ký> }] }
[8] Backend decode base64 → save MinIO → trả Frontend
```

**Đặc điểm:** 6 lần gọi API VNPT, upload toàn bộ PDF lên VNPT 1 lần. **Phù hợp Node.js vì không cần lib PAdES local phức tạp.** Trade-off: phụ thuộc VNPT cho hashing + finalization.

### 4.3. Batch sign

Cả 2 flow đều hỗ trợ batch — chỉ cần push nhiều item vào array `sign_files`:

```json
"sign_files": [
  { "doc_id": "30c-7401-2562", "data_to_be_signed": "abc...", "file_type": "pdf", "sign_type": "hash" },
  { "doc_id": "29a-7749-1325", "data_to_be_signed": "def...", "file_type": "xml", "sign_type": "hash" }
]
```

CA xử lý đồng thời, response `signatures[]` mapping theo `doc_id`.

### 4.4. Có cần PAdES placeholder không?

**CÓ — bắt buộc.** Đây là chuẩn ETSI EN 319 142 cho chữ ký PDF:
1. Chèn `/Sig` field rỗng (placeholder ByteRange + Contents zero-padded) vào PDF
2. Tính hash trên ByteRange (toàn bộ PDF trừ Contents)
3. Hash đi ký
4. Sau khi có signature → ghi vào Contents placeholder (KHÔNG thay đổi byte offset)

**Trong Node.js, lib khuyên dùng:**
- [`@signpdf/signpdf`](https://www.npmjs.com/package/@signpdf/signpdf) + `@signpdf/signer-p12` — nhưng cần custom signer plugin để gọi VNPT thay vì ký local
- [`node-signpdf`](https://www.npmjs.com/package/node-signpdf) — đã cũ
- Hoặc: dùng API `calculateHash` + `signExternal` của VNPT (flow 4.2) → bypass toàn bộ phức tạp PAdES local

---

## 5. SignHashService — Có phải Service standalone?

### 5.1. Phân tích folder `SignHashService/`

Cấu trúc folder cho thấy đây là **ASP.NET MVC Web Application (.NET Framework 4.5.2)**, KHÔNG phải console tool. Bằng chứng:
- `Web.config`, `Global.asax`, `Views/`, `Areas/HelpPage/` (ASP.NET Web API help page)
- `bin/SignHashWeb.dll`, `bin/VnptHashSignatures.dll`, `bin/itextsharp.dll`
- `Controllers/` folder rỗng (không có file `.cs` source code) — **chỉ có binary DLL**

### 5.2. Kết luận về SignHashService

Đây là một **HTTP service wrapper** do VNPT compile sẵn, expose REST API trên IIS để:
1. Nhận PDF + sigOptions từ client
2. Dùng `VnptHashSignatures.dll` + `itextsharp.dll` tính hash PAdES local
3. Trả hash về client
4. Sau khi client lấy signature từ VNPT → POST lại lên service để ghép vào PDF

**Service này CHÍNH LÀ implementation backend của API `rest/v2/signature/calculateHash` và `signExternal`** (mục 3.3 và 3.6). VNPT cung cấp source/binary này như một **option self-host** cho khách hàng muốn tự deploy thay vì gọi sang `rmgateway.vnptit.vn/rest/v2/...`.

### 5.3. Có cần dùng SignHashService không?

**KHÔNG bắt buộc** với e-Office. Có 3 lựa chọn:

| Lựa chọn | Mô tả | Phù hợp |
|---|---|---|
| **A — Node.js tự ký PAdES local** | Dùng `@signpdf/signpdf` + custom signer gọi VNPT `/sign` + `/confirm` | Khi team đủ skill PAdES, muốn tự chủ |
| **B — Gọi sang `rmgateway.vnptit.vn/rest/v2/...`** | Dùng API public của VNPT (calculateHash + signExternal) — không cần deploy gì thêm | **KHUYẾN NGHỊ** — dễ nhất cho Node.js |
| **C — Self-host SignHashService trên IIS** | Deploy .NET service VNPT cung cấp, Node.js gọi qua HTTP | Khi VNPT public API quá tải / latency cao / yêu cầu offline hashing |

**Khuyến nghị cho e-Office:** Bắt đầu với **lựa chọn B**, đo performance, nếu cần thì migrate sang A hoặc C.

### 5.4. Nếu chọn C — deploy SignHashService

- Cần Windows Server + IIS + .NET Framework 4.5.2
- Copy folder `SignHashService/SignHashService/` lên server
- Config IIS site trỏ vào folder, app pool .NET CLR v4.0
- Service expose API trên port 80/443 — Node.js gọi qua HTTP
- Sample C# code/Java/PHP đều dùng pattern này

---

## 6. Code demo PHP cURL — phân tích từng đoạn

**File:** `PHP_Example_SmartCATH_Curl/Sample.SmartCATH-PHP.Curl/signature_curl.php`

### 6.1. Cấu trúc

```
signature_curl.php          # main flow 5 bước
models/OAuth2Config.php      # SP credentials (sp_id, sp_password, user_id, password)
models/OTPService.php        # TOTP generator HMAC-SHA1
base64_file.txt              # PDF gốc base64
```

### 6.2. Đoạn key — OAuth Config (không phải OAuth thật)

```php
class OAuth2Config {
    public $client_id     = '4185-637127995547330633.apps.signserviceapi.com';
    public $client_secret = 'NGNhMzdmOGE-OGM2Mi00MTg0';
    public $user_id       = "871097";
    public $user_password = "123456a@A";
}
```

### 6.3. Đoạn key — Helper gọi VNPT API

```php
function api_smartca_tichhop($link, $data) {
    $curl = curl_init();
    curl_setopt_array($curl, [
        CURLOPT_URL => $link,
        CURLOPT_HTTPHEADER => ['Accept: application/json', 'Content-Type: application/json'],
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_SSL_VERIFYPEER => false,    // ← chỉ dev! prod phải true
        CURLOPT_CUSTOMREQUEST => 'POST',
        CURLOPT_POSTFIELDS => json_encode($data)
    ]);
    $response = curl_exec($curl);
    return json_decode($response);
}
```

### 6.4. Đoạn key — Bước 1: get_certificate

```php
$data_getCertificate = [
    "sp_id" => $config->client_id,
    "sp_password" => $config->client_secret,
    "user_id" => $config->user_id,
    "transaction_id" => getGUID()
];
$msg = api_smartca_tichhop(
    "https://rmgateway.vnptit.vn/sca/sp769/v2/credentials/get_certificate",
    $data_getCertificate
);
$certBase64 = $msg->data->user_certificates[0]->cert_data;
$serialNumber = $msg->data->user_certificates[0]->serial_number;
```

> **Lưu ý:** PHP sample dùng `v2/credentials/get_certificate` trong khi doc + Java + .NET dùng `v1/credentials/get_certificate`. Cả 2 đều hoạt động. Khuyến nghị dùng `v1` (theo doc chính thức).

### 6.5. Đoạn key — Bước 2: calculateHash (PAdES qua VNPT)

```php
$unsignDataBase64 = file_get_contents("base64_file.txt");

$data_calculate_hash = [
    "transaction_id" => getGUID(),
    "sp_id" => $config->client_id,
    "sp_password" => $config->client_secret,
    "signerCert" => $certBase64,
    "digestAlgorithm" => "sha256",
    "sign_files" => [[
        "name" => "test.pdf",
        "pdfContent" => $unsignDataBase64,
        "sigOptions" => [
            "renderMode" => 4,
            "customImage" => "<base64 PNG>",
            "fontSize" => 13,
            "fontColor" => "#000000",
            "signatureText" => "Ký bởi: Quỳnh Anh test ca\nThời gian ký: 17/05/2023 09:43:23",
            "signatures" => [["page" => 1, "rectangle" => "0,581,200,657"]]
        ]
    ]]
];
$msg_calculateHash = api_smartca_tichhop(
    "https://rmgateway.vnptit.vn/rest/v2/signature/calculateHash",
    $data_calculate_hash
);
$hashData = $msg_calculateHash->hashResps[0]->hash;      // base64
$fileID   = $msg_calculateHash->hashResps[0]->fileID;
$transIdHash = $msg_calculateHash->tranId;
```

### 6.6. Đoạn key — Bước 3: signHash (CORE — /v2/sign)

```php
$totp = "QTQ4RTAxN0JGMTE3MzcyMEIwNDlEREVCNTJBMDA2NjU=";  // TOTP secret base64
$TimeStamp = TOTP::get_timestamp();
$secretkey = base64_decode($totp);
$otp       = TOTP::oath_hotp($secretkey, $TimeStamp);

$data_signhash = [
    "sp_id"          => $config->client_id,
    "sp_password"    => $config->client_secret,
    "user_id"        => $config->user_id,
    "password"       => $config->user_password,
    "otp"            => $otp,
    "transaction_id" => getGUID(),
    "sign_files"     => [[
        "data_to_be_signed" => bin2hex(base64_decode($hashData)),  // base64 → bytes → HEX
        "doc_id"   => "doc_id",
        "file_type"=> "pdf",
        "sign_type"=> "hash"
    ]],
    "serial_number" => $serialNumber
];
$msg_signHash = api_smartca_tichhop(
    "https://rmgateway.vnptit.vn/sca/sp769/v2/signatures/sign",
    $data_signhash
);
$sad             = $msg_signHash->data->sad;
$transIdSignHash = $msg_signHash->data->transaction_id;
```

### 6.7. Đoạn key — Bước 4: confirm

```php
$data_confirm = [
    "sp_id" => $config->client_id,
    "sp_password" => $config->client_secret,
    "user_id" => $config->user_id,
    "password" => $config->user_password,
    "transaction_id" => $transIdSignHash,
    "sad" => $sad
];
$msg_confirm = api_smartca_tichhop(
    "https://rmgateway.vnptit.vn/sca/sp769/v2/signatures/confirm",
    $data_confirm
);
$signatureValue = $msg_confirm->data->signatures[0]->signature_value;
```

### 6.8. Đoạn key — Bước 5: signExternal (ghép signature vào PDF)

```php
$data_signExternal = [
    "tranId" => $transIdHash,
    "sp_id" => $config->client_id,
    "sp_password" => $config->client_secret,
    "signatures" => [[
        "fileID" => $fileID,
        "signature" => $signatureValue
    ]]
];
$msg_signExternal = api_smartca_tichhop(
    "https://rmgateway.vnptit.vn/rest/v2/signature/signExternal",
    $data_signExternal
);
echo $msg_signExternal->signResps[0]->signedData;   // base64 PDF đã ký
```

### 6.9. Tóm tắt 5 bước

| Bước | Endpoint | Input quan trọng | Output quan trọng |
|---|---|---|---|
| 1 | `/sca/sp769/v1/credentials/get_certificate` | user_id | cert_data, serial_number |
| 2 | `/rest/v2/signature/calculateHash` | pdfContent (base64), signerCert, sigOptions | hash (base64), fileID, tranId |
| 3 | `/sca/sp769/v2/signatures/sign` | data_to_be_signed (HEX), serial_number, otp | sad, transaction_id |
| 4 | `/sca/sp769/v2/signatures/confirm` | sad, transaction_id | signature_value (base64 PKCS#1) |
| 5 | `/rest/v2/signature/signExternal` | tranId, fileID, signature | signedData (base64 PDF) |

---

## 7. Hạ tầng & môi trường

### 7.1. URLs

| Env | Base URL gateway | Base URL hashing (rest/v2) |
|---|---|---|
| UAT/Sandbox | `https://rmgateway.vnptit.vn/sca/sp769` | `https://rmgateway.vnptit.vn/rest/v2` |
| Production | `https://gwsca.vnpt.vn/sca/sp769` | `https://gwsca.vnpt.vn/rest/v2` (cần verify với VNPT) |

### 7.2. Whitelist IP

**Yêu cầu — cần xác nhận lại với VNPT khi onboarding.** Theo kinh nghiệm:
- UAT: thường không whitelist (free for testing)
- Production: VNPT thường yêu cầu submit IP server outbound → whitelist 2 chiều (in/out)

### 7.3. HTTPS / mTLS

- HTTPS bắt buộc (TLS 1.2 trở lên — sample .NET set `SecurityProtocolType.Tls12`)
- **KHÔNG mTLS** — sample `CURLOPT_SSL_VERIFYPEER => false` + `NoopHostnameVerifier` của Java cho thấy không có client cert ràng buộc. Production nên bật verify peer.

### 7.4. Certificate

- **Server-side cert (TLS):** VNPT cung cấp, không cần config bên client (trừ khi pin cert).
- **End-user signing cert:** Của user (SmartCA personal cert), KHÔNG store trong e-Office — chỉ store `serial_number` để truyền vào API. Cert PEM lấy động qua `get_certificate` mỗi lần ký (hoặc cache 5-10 phút).

---

## 8. Thông tin còn THIẾU — cần xin VNPT

| # | Item | Mục đích | Ai cung cấp |
|---|---|---|---|
| 1 | **sp_id (client_id) sandbox** | Định danh app e-Office UAT | VNPT — qua email đăng ký doanh nghiệp |
| 2 | **sp_password (client_secret) sandbox** | Auth app e-Office | VNPT |
| 3 | **sp_id + sp_password Production** | Khi go-live | VNPT — sau hợp đồng |
| 4 | **Sample test user account** | 1 user_id + password + cert thật để test UAT | VNPT cấp tài khoản demo (có thể yêu cầu nhiều user để test phân quyền nhân sự) |
| 5 | **TOTP secret cho test account** | Sinh OTP test ký tự động | VNPT — gửi cùng test account |
| 6 | **URL sandbox confirm** | Verify base URL UAT đúng | Đã có: `https://rmgateway.vnptit.vn/sca/sp769` |
| 7 | **URL production** | Cần confirm endpoint production | Doc nói: `https://gwsca.vnpt.vn/sca/sp769` — verify |
| 8 | **Production có whitelist IP không?** | Mở firewall outbound | VNPT — quy trình onboarding |
| 9 | **Quota giới hạn ký** | Throttle, billing | VNPT — phụ thuộc hợp đồng |
| 10 | **SLA + hỗ trợ** | Liên hệ khi lỗi | VNPT (cskh@vnpt.vn / tài liệu nói) |
| 11 | **Self-host SignHashService có được hỗ trợ không?** | Quyết định kiến trúc | VNPT — option B/C trong mục 5 |
| 12 | **Quy trình kích hoạt TOTP cho user mới** | Onboarding nhân sự e-Office | VNPT — UI khi user setup TOTP |
| 13 | **Cert có chain root được phép cache không?** | Performance | VNPT |
| 14 | **Có timestamp authority (TSA) đi kèm?** | Nếu cần chữ ký PAdES-T (long-term validation) | VNPT — `pdfSigner.setTsaClient(...)` có trong sample Java |

---

## 9. Đánh giá độ phức tạp triển khai

### 9.1. Effort estimate

| Phase | Việc | Effort (man-day) |
|---|---|---|
| **9.1.1 Setup + Auth wrapper** | OTP generator (otplib), `get_certificate` call, error mapping, env config (sp_id, sp_password, base URLs UAT/Prod) | **1-2 ngày** |
| **9.1.2 PAdES strategy** | Quyết định flow A (local) vs B (VNPT calculateHash) vs C (self-host SignHashService). Khuyến nghị B. POC happy-path 1 file PDF. | **2-3 ngày** |
| **9.1.3 Tích hợp vào e-Office** | UI: trang user nhập user_id + password + TOTP secret (mã hóa lưu DB). Endpoint backend `POST /api/ky-so/smartca-th/sign`. Flow: get_cert → calculateHash → sign → confirm → signExternal → save MinIO → update `outgoing_docs.signed_status`. | **3-4 ngày** |
| **9.1.4 Batch + queue** | BullMQ job cho ký hàng loạt (nhiều VB cùng lúc). Status tracking. | **1-2 ngày** |
| **9.1.5 Error handling + retry** | TOTP race condition (OTP regen mỗi 30s — retry với OTP mới), SAD expired, network error. | **1-2 ngày** |
| **9.1.6 Audit + log** | MongoDB audit (mỗi lần ký: user, file_id, transaction_id, signature_value hash, timestamp). | **1 ngày** |
| **9.1.7 Test + UAT** | Test với user thật, verify signature trong Adobe Reader (panel "Signature Properties"), test edge cases. | **2-3 ngày** |
| **TỔNG** | | **11-17 man-days (~3 tuần 1 dev fulltime)** |

### 9.2. Khả năng Node.js làm 100%

**CÓ — với flow B (gọi VNPT calculateHash/signExternal):**
- HTTP client: axios
- TOTP: otplib
- Crypto: built-in `crypto` module (không cần)
- PDF: KHÔNG cần thư viện PAdES local — VNPT lo phần này
- Lưu file: MinIO client (đã có sẵn trong e-Office)

**Không cần Java/.NET service đi kèm** trừ khi chọn flow C (self-host SignHashService).

**Nếu chọn flow A (PAdES local Node.js):**
- Cần `@signpdf/signpdf` + `@signpdf/utils` + custom signer plugin gọi VNPT
- Khó hơn 1 bậc — nhưng tự chủ hơn, không phụ thuộc rest/v2 API của VNPT
- Effort +3-5 ngày vs flow B

### 9.3. Rủi ro chính

| # | Rủi ro | Mitigation |
|---|---|---|
| 1 | **TOTP race** — OTP regen mỗi 30s, request lỡ giây 29→30 fail | Retry 1 lần với OTP mới khi gặp lỗi `INVALID_OTP` |
| 2 | **SAD expired (299s)** — nếu xử lý confirm chậm | Gọi confirm ngay sau sign, không delay >5 phút |
| 3 | **Lưu trữ TOTP secret + user password** — nếu DB leak → toàn bộ user bị ký mạo danh | Mã hóa AES-256 với key trong env var + KMS rotation. Cân nhắc dùng HSM cho prod. |
| 4 | **Cert PEM hết hạn** — 1 năm (ESEAL) hoặc 3 năm (SMARTCA) | Check `cert_valid_to` trước ký, cảnh báo user 30 ngày trước hết hạn |
| 5 | **VNPT downtime** — `rmgateway.vnptit.vn` lỗi → toàn bộ ký dừng | Queue tasks với retry exponential backoff, dashboard monitor health endpoint |
| 6 | **API rest/v2 không stable** — không có trong doc chính | Confirm với VNPT trước. Nếu API này sẽ deprecated → chuyển sang flow A local |
| 7 | **Doc bản v3.0 thiếu mục v2/get_certificate** (PHP dùng `v2`, doc dùng `v1`) | Test cả 2, mặc định `v1` |
| 8 | **Batch sign timeout** — ký 100 VB cùng lúc | BullMQ chia nhỏ, mỗi job ký 1-10 VB, không gửi 1 request 100 file |
| 9 | **`CURLOPT_SSL_VERIFYPEER => false` của PHP sample** | KHÔNG copy lên production — bật verify peer, dùng CA trust store mặc định |
| 10 | **Signature verify failure** — sai byte offset PAdES → file ký không mở được trong Adobe | Test với Adobe Reader/Foxit thực sự, dùng `pdfsig` của poppler để verify CLI |

### 9.4. Khuyến nghị final

1. **Bắt đầu với flow B** (calculateHash + signExternal qua `rest/v2`) — đơn giản, không cần PAdES local.
2. **Đề xuất với VNPT** xác nhận `rest/v2/signature/...` là endpoint chính thức + có URL production tương ứng.
3. **UI quản lý TOTP** cho user e-Office: trang `/ky-so/cau-hinh-smartca-th` — user nhập user_id + password + TOTP secret (link QR code do VNPT SmartCA app sinh). Backend mã hóa AES + lưu vào `staff_signing_config` table.
4. **Tạo provider mới** trong bảng `signing_providers` (schema đã có từ Phase 11.1) — type = `SMARTCA_TH`, distinguishable với `SMARTCA` thường và `VIETTEL_CA`.
5. **Tách routes:** `/api/ky-so/smartca-th/*` riêng với `/api/ky-so/smartca/*` (gói thường) — không trộn logic xác nhận mobile vs xác nhận TOTP.
6. **Reuse middleware upload + MinIO** — không cần build mới.
7. **Audit** mỗi giao dịch ký vào MongoDB `signing_audit` collection: `{ user_id, transaction_id, provider: "SMARTCA_TH", file_id, signature_hash, signed_at, sad_expired_at }`.

---

## Phụ lục A — So sánh nhanh code mẫu

| Sample | Hash strategy | Strength |
|---|---|---|
| **PHP cURL** | Flow B (calculateHash + signExternal qua VNPT) | Đơn giản nhất, ít code, không cần lib PDF — **MODEL CHO NODE.JS** |
| **.NET Core (net5.0)** | Flow A (local PAdES với `VnptHashSignatures.dll`) | Mạnh, tự chủ — nhưng phụ thuộc lib VNPT chỉ có .NET |
| **.NET Framework 4.5.2** | Flow A | Giống .NET Core, dùng cho legacy IIS |
| **Java** | Flow A (`com.vnpt.vnptkyso.*` package — lib VNPT only-Java) | Tương tự .NET |

→ Vì lib `VnptHashSignatures` của VNPT chỉ có .NET và Java, **Node.js không thể clone flow A trực tiếp** — phải hoặc dùng `@signpdf/signpdf` (effort cao), hoặc dùng flow B (khuyến nghị).

## Phụ lục B — Test credentials trong code mẫu (CHỈ DEV — KHÔNG ĐƯỢC DÙNG PROD)

```
sp_id      = "4185-637127995547330633.apps.signserviceapi.com"
sp_password= "NGNhMzdmOGE-OGM2Mi00MTg0"
user_id    = "871097"
password   = "123456a@A"
TOTP_secret= "QTQ4RTAxN0JGMTE3MzcyMEIwNDlEREVCNTJBMDA2NjU="
serial_no  = "54010101..."  (lấy động qua get_certificate)
```

(Tương đương trong PHP/.NET/Java sample — VNPT dùng chung 1 tài khoản demo cho mọi sample. Khi onboarding sẽ được cấp riêng cho e-Office.)
