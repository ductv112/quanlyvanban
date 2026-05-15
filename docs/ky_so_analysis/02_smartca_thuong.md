# Báo cáo phân tích tích hợp VNPT SmartCA Thường (gói SP769)

**Tài liệu nguồn:** `docs/huong_dan_tich_hop_ky_so_SmartCA_thuong/`
**Phiên bản kịch bản:** v4.1 (03/05/2024) — file `Kich_ban_tich_hop_smartca_v4.1.pdf`
**Ngày phân tích:** 2026-05-15
**Người thực hiện:** Claude (AI assistant)
**Mục tiêu:** Hướng dẫn team triển khai TÍCH HỢP THẬT (không mock) ký số SmartCA Thường vào e-Office (Node.js + Express + Next.js).

---

## 1. SmartCA Thường là gì?

**SmartCA Thường** (còn gọi là "SmartCA cá nhân" hoặc "SmartCA bình thường") là dịch vụ ký số từ xa (remote signing) của VNPT theo chuẩn của Bộ TT&TT (văn bản **769/QĐ-BTTTT**). Đặc trưng:

- **Mô hình hoạt động:** *Remote signing* — chứng thư số nằm trên HSM của VNPT, người dùng cuối **chỉ giữ tài khoản + ứng dụng VNPT SmartCA trên mobile** để xác nhận giao dịch ký.
- **Loại CA:** VNPT-CA (VNPT Smart CA RS) — tổ chức cung cấp dịch vụ tin cậy được Bộ TT&TT cấp phép.
- **Định dạng chữ ký:**
  - **PDF** — PAdES (PKCS#7 detached embedded trong PDF `/Contents`)
  - **Office (docx/xlsx)** — OpenXML signature
  - **XML** — XAdES (XMLDSig)
  - **Hash thuần** — CMS detached (`sign_type: "hash"`)
- **Hiện tại VNPT chỉ hỗ trợ giao dịch ký HASH** (trích kichban v4.1, mục 3.3 trang 11):
  > "Hiện tại SmartCA chỉ hỗ trợ giao dịch ký hash"
  → Bên SP (e-Office) PHẢI tự tính hash của tài liệu (PAdES placeholder hash cho PDF) rồi gửi hash hex lên SmartCA.

- **Khác biệt với SmartCA Tích hợp (SmartCA TH):**

| Tiêu chí | **SmartCA Thường** (mục 3 kichban) | **SmartCA Tích hợp** (mục 4 kichban) |
|---|---|---|
| API path | `/sca/sp769/v1/*` | `/sca/sp769/v2/*` |
| Xác nhận user | **App SmartCA mobile bấm "Đồng ý"** | **OTP/TOTP** truyền vào API (không cần mở app) |
| Số API call ký | 2 (`sign` + `status` polling) | 3 (`sign` → `confirm` với SAD + OTP) |
| Tham số bắt buộc thêm | (không) | `password` (mật khẩu user) + `otp` |
| Use case phù hợp | KH cá nhân, ký thủ công xác nhận từng VB | KH doanh nghiệp, ký hàng loạt tự động |
| **Hệ thống e-Office cần** | **✅ ĐÚNG GÓI NÀY** | (Phase sau nếu KH yêu cầu auto-sign) |

> **Kết luận:** e-Office tỉnh Lào Cai dùng **SmartCA Thường** — cán bộ ký từng văn bản, app mobile bấm xác nhận.

---

## 2. Authentication & Authorization

### 2.1 API endpoint

| Môi trường | Base URL |
|---|---|
| **UAT (sandbox)** | `https://rmgateway.vnptit.vn/sca/sp769` |
| **Production** | `https://gwsca.vnpt.vn/sca/sp769` |

### 2.2 Cơ chế xác thực

**KHÔNG dùng OAuth2 access token** (khác với CSC API cũ `/csc/*` của VNPT — đó là API thế hệ trước). Mỗi request POST gửi body kèm 2 trường:

- `sp_id`: client_id của hệ thống e-Office, do VNPT cấp khi đăng ký 3rd Party
- `sp_password`: client_secret tương ứng (plaintext trong body — KHÔNG hash, KHÔNG bearer)

### 2.3 Loại credential KH cần cấp

#### Phía **3rd Party (e-Office)** — được VNPT cấp 1 LẦN:

| Field | Ví dụ từ sample code | Mô tả |
|---|---|---|
| `sp_id` (client_id) | `4184-637127995547330633.apps.signserviceapi.com` | Định danh ứng dụng e-Office trên VNPT SignService |
| `sp_password` (client_secret) | `NGNhMzdmOGE-OGM2Mi00MTg0` | Mật khẩu ứng dụng — gửi plaintext trong body |

> Để đăng ký, e-Office gửi HSXKD cho VNPT (mục 2.1 kichban):
> 1. Tên hệ thống (vd: "Hệ thống Quản lý văn bản tỉnh Lào Cai")
> 2. Mô tả ứng dụng kết nối
> 3. Email quản trị viên (nhận `client_id` + `client_secret`)

#### Phía **end-user (cán bộ tỉnh)** — đăng ký SmartCA cá nhân với VNPT:

| Thông tin | Mô tả |
|---|---|
| Họ tên | Khớp với chứng minh thư |
| **Số CCCD/CMND/Hộ chiếu/MST** | Chính là `user_id` truyền vào API — **trường định danh chính** |
| Email | Nhận thông báo kích hoạt |
| Số điện thoại | Nhận tin nhắn kích hoạt + cài app SmartCA |

User cài app **VNPT SmartCA** trên điện thoại, kích hoạt qua link email/SMS. Sau đó user là "thuê bao" của CA, có thể ký từ bất kỳ ứng dụng 3rd party nào (e-Office).

### 2.4 Token lifetime

**Không có token** — mỗi API call gửi lại `sp_id`/`sp_password`. Server VNPT validate mỗi lần. Hệ thống e-Office chỉ cần **lưu trữ an toàn** (encrypt) `sp_id`/`sp_password` trong DB hoặc env.

> **Trong e-Office hiện tại**, credential này được lưu trong bảng `edoc.signing_providers` (xem code `e_office_app_new/backend/src/repositories/staff-signing-config.repository.ts`).

---

## 3. API Endpoints chính

### 3.1 `POST /sca/sp769/v1/credentials/get_certificate`

**Mục đích:** Lấy danh sách chứng thư số của 1 thuê bao (1 user có thể có nhiều: SmartCA cá nhân, ESEAL doanh nghiệp...).

**Headers:**
```
Content-Type: application/json
Accept: application/json
```

**Request body:**
```json
{
  "sp_id": "4184-637127995547330633.apps.signserviceapi.com",
  "sp_password": "NGNhMzdmOGE-OGM2Mi00MTg0",
  "user_id": "162952530",
  "serial_number": "",
  "transaction_id": "<UUID-v4>"
}
```

**Tham số:**
| Field | Required | Mô tả |
|---|---|---|
| `sp_id` | ✅ | Client_id của e-Office |
| `sp_password` | ✅ | Client_secret |
| `user_id` | ✅ | Số CCCD/CMND của cán bộ ký |
| `serial_number` | ❌ | Lọc theo serial nếu user có nhiều cert |
| `transaction_id` | ✅ | UUID-v4 do e-Office tạo (để trace) |

**Response (success 200):**
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
        "cert_status": "Đang hoạt động",
        "serial_number": "54010101493c47d39f8a84b30ed55191",
        "cert_subject": "C=VN,ST=HÀ NỘI,...CN=Ngô Quang Đạt test SmartCA,UID=CMND:162952530",
        "cert_valid_from": "2023-07-18T09:12:00Z",
        "cert_valid_to": "2026-07-18T21:12:00Z",
        "cert_data": "MIIFQjCCBCqgAwIBAg...",  // X.509 base64
        "chain_data": {
          "ca_cert": "MIIGNDCCBBygAwI...",
          "root_cert": "MIIG/DCCBOSgAw..."
        },
        "transaction_id": "SP_CA_09940"
      }
    ]
  }
}
```

**Nghiệp vụ:**
- Một thuê bao có thể trả về nhiều `user_certificates` (SMARTCA cá nhân + ESEAL doanh nghiệp). e-Office phải **filter `service_type = "SMARTCA"`** hoặc cho user chọn.
- `cert_data` (base64 X.509 DER) là **bắt buộc** cho bước tính PAdES hash sau đó.
- `serial_number` cần lưu lại để truyền vào bước `/signatures/sign`.

---

### 3.2 `POST /sca/sp769/v1/signatures/sign`

**Mục đích:** Gửi hash (đã tính sẵn) lên VNPT để khởi tạo giao dịch ký số. VNPT push thông báo về app SmartCA mobile của user.

**Request body:**
```json
{
  "sp_id": "4184-637127995547330633.apps.signserviceapi.com",
  "sp_password": "NGNhMzdmOGE-OGM2Mi00MTg0",
  "user_id": "0131930813216",
  "transaction_id": "SP_CA_123456",
  "transaction_desc": "Ký văn bản số 12/QĐ-UBND",
  "serial_number": "52341c3f9dcs2371",
  "time_stamp": "20220316063000Z",
  "sign_files": [
    {
      "file_type": "pdf",
      "data_to_be_signed": "3cab0a7c77da32d278f4e85053176d847064cc84b0f1528aa96438a3edf92060",
      "doc_id": "30c-7401-2562",
      "sign_type": "hash"
    }
  ]
}
```

**Tham số quan trọng:**
| Field | Required | Mô tả |
|---|---|---|
| `transaction_id` | ✅ | UUID e-Office tạo — phải UNIQUE, dùng để query status sau |
| `transaction_desc` | ❌ | Hiển thị trên app mobile của user → quan trọng cho UX, nên truyền số/trích yếu VB |
| `serial_number` | ❌ | Serial cert lấy ở bước 3.1 (bắt buộc nếu user có >1 cert) |
| `sign_files[].data_to_be_signed` | ✅ | **Hash HEX của PDF placeholder** (KHÔNG phải base64). Sample code Java: `Hex.toHexString(Base64.decodeBase64(hashValue))` |
| `sign_files[].doc_id` | ✅ | Định danh tài liệu — hiển thị trên app + dùng để map kết quả khi `sign_files` có nhiều item (ký lô) |
| `sign_files[].file_type` | ✅ | `pdf` / `xml` / `office` / `json` |
| `sign_files[].sign_type` | ✅ | `hash` (hiện chỉ hỗ trợ giá trị này) |
| `time_stamp` | ❌ | `yyyyMMddHHmmssZ` |

**Response (success 200):**
```json
{
  "status_code": 200,
  "message": "sig_wait_for_user_confirm",
  "data": {
    "transaction_id": "SP_CA_123456",
    "tran_code": "acd9be84-60e7-4645-83ab-fb7079b71626"
  }
}
```

- `transaction_id` = chính là cái e-Office gửi lên (echo back).
- `tran_code` = mã giao dịch nội bộ VNPT — KHÔNG cần dùng nếu chỉ polling status.
- Sau response này, e-Office **CHẶN UI lại** chờ user mở app SmartCA, nhập PIN, bấm "Đồng ý".

**Ký theo lô:** add nhiều item vào `sign_files[]` (mỗi item một `doc_id` khác). User chỉ cần xác nhận 1 lần trên app cho cả lô.

---

### 3.3 `POST /sca/sp769/v1/signatures/sign/{tranId}/status`

**Mục đích:** Polling kiểm tra user đã xác nhận trên app chưa, lấy signature_value khi xong.

**URL:** `https://gwsca.vnpt.vn/sca/sp769/v1/signatures/sign/SP_CA_123456/status`

- `{tranId}` = `transaction_id` từ response API 3.2.
- HTTP method: **POST** (không phải GET — kichban v4.1 ghi rõ).
- Request body: `{}` (rỗng) — VNPT không yêu cầu auth body cho endpoint này (sample PHP confirm).

**Response (success — user đã xác nhận):**
```json
{
  "status_code": 200,
  "message": "SUCCESS",
  "data": {
    "transaction_id": "c7eabdae-740e-4845-9bcd-dc495562d0bf",
    "signatures": [
      {
        "doc_id": "30c-7401-2562",
        "signature_value": "A7WttpP9/+8hUpZI/...",  // PKCS#7 detached base64
        "timestamp_signature": null
      }
    ]
  }
}
```

**Response (user CHƯA xác nhận):**
- `message` ≠ `"SUCCESS"` (có thể là `"sig_wait_for_user_confirm"` hoặc rỗng).
- Logic poll trong Java/NetCore sample:
  ```java
  while (count < 24 && !isConfirm) {
      tranInfoRes = getTransInfo769(detail, transID);
      if (!"SUCCESS".equals(tranInfoRes.getMessage())) {
          count++;
          Thread.sleep(10000);  // 10 giây / lần
      } else { isConfirm = true; }
  }
  ```
  → **Tối đa 24 lần × 10s = 4 phút** chờ user xác nhận. Sau đó timeout → user phải tạo giao dịch mới.

**signature_value** = base64 của PKCS#7 detached signature → ghép vào placeholder PDF để hoàn thành PAdES.

---

### 3.4 Webhook (optional) — `POST {SP_callback_url}`

**Mục đích:** Thay vì polling, e-Office có thể đăng ký 1 URL với VNPT để nhận callback push khi user xác nhận xong. (Mục 3.5 kichban v4.1)

**Body VNPT POST đến e-Office:**
```json
{
  "sp_id": "...",
  "status_code": 200,
  "message": "SUCCESS",
  "transaction_id": "SP_CA_123456",
  "signed_files": [
    {
      "doc_id": "30c-7401-2562",
      "signature_value": "...",
      "timestamp_signature": null
    }
  ]
}
```

> **Lưu ý cho production:** Webhook đòi hỏi e-Office expose 1 endpoint HTTPS public — KH triển khai on-premise có thể không thuận tiện. **Khuyến nghị Phase 1 dùng polling** (đơn giản, không cần config firewall), Phase sau nâng cấp webhook.

---

## 4. Signing Flow E2E

```
┌─────────┐                  ┌──────────────┐                  ┌──────────────┐                ┌──────────────┐
│ Cán bộ  │                  │   e-Office   │                  │  VNPT SmartCA │                │ App mobile   │
│ (web)   │                  │ (Express BE) │                  │   Gateway    │                │  của cán bộ  │
└────┬────┘                  └──────┬───────┘                  └──────┬───────┘                └──────┬───────┘
     │                              │                                 │                               │
     │ 1. Chọn VB + bấm "Ký"        │                                 │                               │
     ├─────────────────────────────►│                                 │                               │
     │                              │                                 │                               │
     │                              │ 2. Load PDF, thêm placeholder   │                               │
     │                              │    @signpdf/placeholder-plain   │                               │
     │                              │                                 │                               │
     │                              │ 3. Tính SHA256 byte-range hash  │                               │
     │                              │    → hashHex (64 ký tự)         │                               │
     │                              │                                 │                               │
     │                              │ 4. POST /v1/credentials/        │                               │
     │                              │    get_certificate              │                               │
     │                              ├────────────────────────────────►│                               │
     │                              │◄────────────────────────────────┤                               │
     │                              │   cert_data + serial_number    │                               │
     │                              │                                 │                               │
     │                              │ 5. POST /v1/signatures/sign     │                               │
     │                              │    {data_to_be_signed: hashHex} │                               │
     │                              ├────────────────────────────────►│                               │
     │                              │                                 │ 6. Push notify SmartCA app    │
     │                              │                                 ├──────────────────────────────►│
     │                              │◄────────────────────────────────┤                               │
     │                              │ tran_id + "wait_for_user_confirm"                              │
     │                              │                                 │                               │
     │ 7. UI hiện "Mở app           │                                 │                               │
     │    SmartCA xác nhận"         │                                 │                               │
     │◄─────────────────────────────┤                                 │                               │
     │                              │                                 │ 8. User nhập PIN, bấm "Đồng ý"│
     │                              │                                 │◄──────────────────────────────┤
     │                              │ 9. Polling                      │                               │
     │                              │    POST /v1/signatures/sign/    │                               │
     │                              │       {tranId}/status (mỗi 10s) │                               │
     │                              ├────────────────────────────────►│                               │
     │                              │◄────────────────────────────────┤                               │
     │                              │ signature_value (PKCS7 b64)     │                               │
     │                              │                                 │                               │
     │                              │ 10. signPdf(placeholderPdf,     │                               │
     │                              │       signatureBase64)          │                               │
     │                              │ → PDF đã ký hoàn chỉnh (PAdES)  │                               │
     │                              │                                 │                               │
     │                              │ 11. Upload PDF signed → MinIO   │                               │
     │                              │     Update DB status            │                               │
     │                              │                                 │                               │
     │ 12. UI hiện "Ký thành công"  │                                 │                               │
     │◄─────────────────────────────┤                                 │                               │
```

**Trong e-Office hiện tại**, bước 3-10 đã được implement tại:
- `backend/src/services/signing/pdf-signer.ts` — bước 2, 3, 10 (PAdES hash + sign)
- `backend/src/services/signing/providers/smartca-vnpt.provider.ts` — bước 4, 5, 9 (gọi VNPT API)
- `backend/src/workers/signing-poll.worker.ts` — bước 9 (BullMQ worker poll status)

---

## 5. Code demo phân tích (sample PHP cURL — SP769)

**File:** `Sample.SmartCA-769-PHP.Curl/Sample.SmartCA-769-PHP.Curl/signature_curl.php`

### 5.1 Cấu trúc

```
Sample.SmartCA-769-PHP.Curl/
├── index.php                # Landing page với 1 link "Ký số"
├── signature_curl.php       # Bước 1-3: get cert → calculate hash → sign request
├── get_tranInfo.php         # Bước 4-5: poll status → signExternal (ghép cert vào PDF)
├── base64_file.txt          # PDF mẫu (base64)
└── models/
    └── OAuth2Config.php     # client_id + client_secret + user_id hard-code
```

> **Nhận xét sample này:** Tên file là "OAuth2Config" nhưng KHÔNG có OAuth2 — chỉ là plain credentials. Lý do: VNPT có sample cũ dùng OAuth (`/csc/*` API) và sample mới dùng SP769. File này là **mix**: sign dùng SP769, nhưng tính hash + ghép signature dùng API **`/rest/v2/signature/calculateHash`** và **`/rest/v2/signature/signExternal`** (đây là service helper của VNPT để bên SP **không cần dùng JAR Java**).

### 5.2 Đoạn code quan trọng

**Bước 1 — Lấy certificate (SP769):**
```php
$data_getCertificate = [
    "sp_id"          => $config->client_id,
    "sp_password"    => $config->client_secret,
    "user_id"        => $config->user_id,
    "transaction_id" => getGUID()
];
$msg_getCertificate = api_smartca(
    "https://gwsca.vnpt.vn/sca/sp769/v1/credentials/get_certificate",
    $data_getCertificate
);
$certBase64   = $msg_getCertificate->data->user_certificates[0]->cert_data;
$serialNumber = $msg_getCertificate->data->user_certificates[0]->serial_number;
```

**Bước 2 — Tính hash PAdES qua API VNPT (KHÔNG cần Java JAR):**
```php
$unsignDataBase64 = file_get_contents("base64_file.txt");
$data_calculate_hash = [
    "transaction_id"  => getGUID(),
    "sp_id"           => $config->client_id,
    "sp_password"     => $config->client_secret,
    "signerCert"      => $certBase64,
    "digestAlgorithm" => "sha256",
    "sign_files"      => [[
        "name"        => "test.pdf",
        "pdfContent"  => $unsignDataBase64,  // PDF gốc base64
        "sigOptions"  => [
            "renderMode"     => 4,  // TEXT_WITH_BACKGROUND
            "customImage"    => "iVBORw0KGgo...",  // logo base64
            "fontSize"       => 13,
            "fontColor"      => "#000000",
            "signatureText"  => "Ký bởi: Quỳnh Anh\nThời gian ký: 17/05/2023 09:43:23",
            "signatures"     => [["page" => 1, "rectangle" => "0,581,200,657"]]
        ]
    ]]
];
$msg_calculateHash = api_smartca(
    "https://gwsca.vnpt.vn/rest/v2/signature/calculateHash",
    $data_calculate_hash
);
$hashData    = $msg_calculateHash->hashResps[0]->hash;      // base64 hash
$fileID      = $msg_calculateHash->hashResps[0]->fileID;     // server-side file id
$transIdHash = $msg_calculateHash->tranId;
```

> ⚠️ **QUAN TRỌNG:** Sample PHP này dùng **API service của VNPT** (`/rest/v2/signature/calculateHash`) để tính hash và lưu PDF placeholder trên server VNPT. Hệ thống e-Office hiện tại **TỰ tính hash bằng Node.js** (`@signpdf/placeholder-plain` + `crypto.createHash('sha256')`) → KHÔNG phụ thuộc service phụ này → tốt hơn (giảm latency, ít external dependency).

**Bước 3 — Gửi hash lên SP769 sign:**
```php
$data_signhash = [
    "sp_id"          => $config->client_id,
    "sp_password"    => $config->client_secret,
    "user_id"        => $config->user_id,
    "transaction_id" => getGUID(),
    "sign_files"     => [[
        "data_to_be_signed" => bin2hex(base64_decode($hashData)),  // hash hex
        "doc_id"            => "doc_id",
        "file_type"         => "pdf",
        "sign_type"         => "hash"
    ]],
    "serial_number" => $serialNumber,
];
$msg_signHash = api_smartca(
    "https://gwsca.vnpt.vn/sca/sp769/v1/signatures/sign",
    $data_signhash
);
// → response: { message: "sig_wait_for_user_confirm", data: { transaction_id: "..." }}
```

**Bước 4 — Polling lấy signature:**
```php
$msg = api_get_tranInfo_curl(
    "https://gwsca.vnpt.vn/sca/sp769/v1/signatures/sign/" . $_GET["tranId"] . "/status"
);
$hashSigned = $msg->data->signatures[0]->signature_value;
```

**Bước 5 — Ghép signature vào PDF qua API VNPT (signExternal):**
```php
$data_signExternal = [
    "tranId"     => $_GET["transIDHash"],  // tranId từ bước calculateHash
    "sp_id"      => $config->client_id,
    "sp_password"=> $config->client_secret,
    "signatures" => [[
        "fileID"    => $_GET["fileId"],  // fileID từ bước calculateHash
        "signature" => $hashSigned
    ]]
];
$msg_signExternal = api_service_get_hash(
    "https://gwsca.vnpt.vn/rest/v2/signature/signExternal",
    $data_signExternal
);
echo $msg_signExternal->signResps[0]->signedData;  // PDF đã ký, base64
```

> ⚠️ **Tương tự bước 2** — sample PHP dùng API VNPT để ghép. e-Office hiện tại dùng `@signpdf/signpdf` Node lib làm việc này locally → khuyến nghị giữ pattern Node.

### 5.3 Library/Dependency

**PHP sample:**
- `curl` extension (PHP built-in)
- KHÔNG cần TCPDF/FPDI vì dùng API VNPT để tính hash + ghép signature

**Node.js (e-Office đã có):**
- `@signpdf/signpdf` v3 — wrapper cho PAdES signing
- `@signpdf/utils` — `Signer` base class
- `@signpdf/placeholder-plain` — thêm `/Contents <placeholder>` vào PDF
- `node:crypto` — `createHash('sha256')` tính byte range hash
- `node-fetch` / global `fetch` (Node 18+) — HTTP client gọi VNPT API

> **Hệ thống e-Office hiện tại đã implement đầy đủ** (xem section 9 dưới).

---

## 6. Hash Signature Library (vnpthashsignature JAR)

### 6.1 Phân tích JAR

**File:** `vnpthashsignature-1.0.1.5-jar-with-dependencies-JAVA1.7/vnpthashsignature-1.0.1.5-jar-with-dependencies.jar`

**Cấu trúc package:**
```
com.vnpt.vnptkyso
├── signer/
│   ├── HashSignerFactory.class    # Factory: PDF/OFFICE/XML/CMS signer
│   ├── IHashSginer.class          # Interface chính
│   ├── BaseHashSigner.class
│   ├── DocumentType.class         # Enum: PDF, OFFICE, XML, CMS
│   └── SignatureParameter.class
├── pdf/
│   ├── PdfHashSigner.class        # Class chính: tạo placeholder + ghép signature
│   ├── PdfSignatureView.class     # Vị trí chữ ký (page, rectangle)
│   ├── PdfSignatureComment.class  # Annotation/comment trên PDF
│   ├── DigestAlgorithms.class
│   └── ExternalDigest.class
├── office/                         # OfficeHashSigner cho docx/xlsx
├── xml/                            # XmlHashSigner cho XAdES
├── cms/                            # CmsHashSigner cho CMS detached
└── utils/
    ├── MessageDigestAlgorithm.class  # SHA256, SHA384, SHA512
    ├── X509CertificateInfo.class     # Parse cert subject
    └── Base64.class

Dependencies bundled:
- com.lowagie.text.pdf.*  → OpenPDF (fork của iText 4 LGPL, dùng cho PAdES)
- org.bouncycastle.*       → BouncyCastle (PKCS#7, ASN.1)
```

**Mục đích JAR:**
1. **`PdfHashSigner.getSecondHashAsBase64()`** — Tính PAdES "second hash":
   - Bước 1: Thêm `/ByteRange [0 ... ... ...]` và `/Contents <placeholder 0x00...>` vào PDF
   - Bước 2: Hash SHA256 toàn bộ PDF (trừ placeholder bytes)
   - Trả về base64 hash → gửi lên SmartCA `data_to_be_signed`
2. **`PdfHashSigner.sign(signatureValueBase64)`** — Ghép PKCS#7 signature VNPT trả về vào placeholder → PDF đã ký hoàn chỉnh.
3. **`PdfHashSigner.checkHashSignature(signature)`** — Verify signature có khớp với hash đã ký không (sanity check).

### 6.2 Replicate bằng Node.js?

**ĐÃ LÀM ĐƯỢC** — e-Office hiện tại tại `backend/src/services/signing/pdf-signer.ts` đã thay thế JAR Java bằng:

| Chức năng JAR (Java) | Node.js tương đương |
|---|---|
| `PdfHashSigner.getSecondHashAsBase64()` | `plainAddPlaceholder()` + `crypto.createHash('sha256').update(byteRange).digest('hex')` |
| `PdfHashSigner.sign(signatureBase64)` | `SignPdf.sign(pdfWithPlaceholder, precomputedSigner)` |
| `PdfHashSigner.checkHashSignature()` | (Skip — VNPT đã verify trước khi return) |
| PDF visual signature (logo/text overlay) | `@signpdf/signpdf` không tự render. Cần `pdf-lib` để vẽ rectangle overlay TRƯỚC khi addPlaceholder |
| Office docx/xlsx signing | **KHÔNG có Node lib mature** — phải dựng Java microservice OR dùng `node-java-bridge` |
| XML XAdES signing | `xml-crypto` (Node lib) — chưa implement trong e-Office |

> **Kết luận:** Cho **PDF** (use case chính của e-Office) — Node.js đủ, không cần Java JAR. Cho **docx/xlsx** ký số — nếu KH yêu cầu, phải dựng thêm Java microservice riêng dùng JAR này (Phase sau).

### 6.3 Library Node.js trong e-Office

**package.json (backend) hiện tại:**
- `@signpdf/signpdf` — Pure JS PAdES signer
- `@signpdf/utils` — Signer interface
- `@signpdf/placeholder-plain` — Thêm placeholder vào PDF
- `pdf-lib` — Có sẵn (dùng cho watermark/QR code, không bắt buộc)
- `node-forge` — Có thể dùng để verify X.509 (chưa dùng)

---

## 7. Yêu cầu hạ tầng & môi trường

### 7.1 Network / Firewall

| Yêu cầu | Mô tả |
|---|---|
| **Outbound HTTPS 443** từ backend e-Office | Đến `gwsca.vnpt.vn` (prod) hoặc `rmgateway.vnptit.vn` (UAT) |
| **Whitelist IP** | VNPT **CÓ THỂ** yêu cầu whitelist IP server e-Office. Hỏi VNPT khi đăng ký 3rd Party. KH triển khai trên cloud public IP → phải cung cấp cho VNPT. |
| **Webhook callback (optional)** | Nếu dùng webhook thay polling → cần expose endpoint HTTPS public + IP cố định |
| TLS version | TLS 1.2+ (sample code dùng `SSL_VERIFYPEER => false` → **chỉ test**, production PHẢI verify) |

### 7.2 Sandbox vs Production

| Môi trường | Base URL | Khi nào dùng |
|---|---|---|
| **UAT/Sandbox** | `https://rmgateway.vnptit.vn/sca/sp769` | Test integration, user test (CCCD/serial test do VNPT cấp) |
| **Production** | `https://gwsca.vnpt.vn/sca/sp769` | Go-live, dùng cert thật của cán bộ |

> **Cùng `sp_id`/`sp_password` 2 môi trường KHÔNG dùng chung** — phải xin VNPT cả 2 bộ.

### 7.3 KH cần làm

1. **Đăng ký thuê bao SmartCA** với VNPT cho từng cán bộ (HSXKD, KYC).
2. **Cài app VNPT SmartCA** trên điện thoại Android/iOS.
3. **Kích hoạt tài khoản** qua link email / SMS từ VNPT.
4. **Khai báo `user_id` (CCCD) trong e-Office** — link với tài khoản nội bộ qua bảng `staff_signing_config` (đã có).

---

## 8. Thông tin còn THIẾU cần xin VNPT

| Thông tin | Phục vụ | Status hiện tại |
|---|---|---|
| `sp_id` (client_id) — **UAT** | Test integration | ❓ Cần xin VNPT |
| `sp_password` (client_secret) — **UAT** | Test integration | ❓ Cần xin VNPT |
| `sp_id` — **Production** | Go-live | ❓ Cần xin VNPT (sau khi UAT pass) |
| `sp_password` — **Production** | Go-live | ❓ Cần xin VNPT |
| **Account test sandbox** (số CCCD + app SmartCA đã activate) | Smoke test E2E | ❓ Cần xin VNPT 1-2 account test |
| Mức phí giao dịch | Báo giá KH | ❓ Cần xin VNPT |
| SLA + đường dây hỗ trợ kỹ thuật | Vận hành production | ❓ Cần xin VNPT (cskh@vnpt.vn) |
| URL webhook (nếu dùng) | Cấu hình notification | ❓ Đăng ký với VNPT |
| Whitelist IP yêu cầu? | Network config | ❓ Hỏi VNPT có bắt buộc không |
| **Quy trình tạo user_id bulk** cho cán bộ tỉnh | Onboarding ~500 cán bộ | ❓ Hỏi VNPT có API tạo account hàng loạt hay phải từng người |

### Email liên hệ VNPT

- **Tổng đài KH:** `cskh@vnpt.vn` (theo kichban v4.1)
- **Đăng ký dịch vụ:** Liên hệ VNPT Lào Cai hoặc TTKD (theo NetCore sample: "Liên hệ với TTKD")

---

## 9. Đánh giá độ phức tạp triển khai

### 9.1 Status hiện tại của e-Office

**ĐÃ CÓ (Phase 7-9 đã làm):**
- ✅ `services/signing/providers/smartca-vnpt.provider.ts` — Adapter cho VNPT API SP769
- ✅ `services/signing/pdf-signer.ts` — PAdES placeholder + sign bằng `@signpdf/signpdf`
- ✅ `services/signing/types.ts` — Type definitions
- ✅ `routes/digital-signature.ts` — REST API ký số
- ✅ `routes/ky-so-cau-hinh.ts`, `routes/ky-so-tai-khoan.ts` — Quản lý provider + cấu hình ký
- ✅ `workers/signing-poll.worker.ts` — BullMQ worker polling status
- ✅ `repositories/staff-signing-config.repository.ts` — Lưu user_id (CCCD) của từng cán bộ
- ✅ DB schema: bảng `edoc.signing_providers`, `edoc.signing_jobs`, `edoc.staff_signing_config`
- ✅ Frontend UI: trang ký số (xem `frontend/src/app/(main)/ky-so-cau-hinh/`)

**Mock service hiện có:** `services/signing-mock.service.ts` → dùng cho dev/demo khi chưa có credential VNPT.

### 9.2 Effort cho TÍCH HỢP THẬT (chuyển từ mock → live)

| Hạng mục | Effort | Ghi chú |
|---|---|---|
| Xin credential UAT từ VNPT | 1-2 tuần (chờ VNPT) | Blocker — phụ thuộc TTKD VNPT |
| Cấu hình `.env` + DB seed credential | 0.5 ngày | Update `SIGNING_*_CLIENT_ID/SECRET` vars |
| Switch `signing.service.ts` từ mock → real provider | 0.5 ngày | Đã có code, chỉ disable mock flag |
| Test E2E flow với 1 account VNPT test | 1-2 ngày | Cần app SmartCA mobile thật |
| Fix edge cases (timeout, cert expired, batch sign) | 2-3 ngày | Patterns đã có trong sample |
| Test với PDF tiếng Việt có dấu, nhiều page | 1 ngày | Tránh corrupt khi addPlaceholder |
| Xử lý timeout app user không xác nhận (>4 phút) | 0.5 ngày | UI báo "Hết hạn, ký lại" |
| Webhook (nếu KH yêu cầu thay polling) | 2 ngày | Endpoint + signature verify |
| Đăng ký + test với PROD credential | 2 ngày | Sau khi UAT pass |
| Documentation HDSD cho cán bộ | 1 ngày | Có sẵn template, chỉ chỉnh |
| **TỔNG** | **~10-15 man-days** (excl. wait VNPT) | |

### 9.3 Có cần dựng Java service riêng?

**KHÔNG** — Cho use case PDF (90% nhu cầu e-Office), Node.js đủ:
- PAdES PKCS7 detached: `@signpdf/signpdf` ✅
- Hash SHA256 byte range: `node:crypto` ✅
- Visual signature overlay: `pdf-lib` (nếu cần logo/text) ✅
- X.509 parsing: `node-forge` (nếu cần)

**CÓ THỂ CẦN** Java service nếu:
- KH yêu cầu **ký docx/xlsx native** (không convert PDF) — Node không có lib stable cho OpenXML signing
- KH yêu cầu **ký XML XAdES** với schema phức tạp — dùng JAR `XmlHashSigner` chắc chắn hơn `xml-crypto` Node

### 9.4 Khác biệt SmartCA Thường vs Tích hợp

| Tiêu chí | SmartCA Thường (đã chọn) | SmartCA Tích hợp |
|---|---|---|
| Số API call | 3 (`get_cert` → `sign` → `status`) | 4 (`get_cert` → `sign` v2 → `confirm` v2 + thêm OTP/password) |
| UX cán bộ | Mở app mobile xác nhận | Nhập OTP trên web (không cần app) |
| Cấu trúc credential mỗi user | Chỉ user_id (CCCD) | user_id + password đăng nhập SmartCA + TOTP secret |
| Phù hợp | KH cá nhân, công vụ | DN ký lô tự động (kế toán, hóa đơn) |
| Effort migrate sang | (đã làm) | +3-5 man-days |

### 9.5 Risks & Mitigations

| Risk | Mitigation |
|---|---|
| VNPT chậm cấp credential | Demo bằng mock service trước — code đã tách provider rõ ràng |
| User không cài app SmartCA → ký fail | UI hướng dẫn step-by-step + link tải app |
| Timeout app (>4 phút) | UI status "Hết hạn xác nhận, vui lòng ký lại" — không retry tự động |
| Nhiều user cùng ký 1 lúc → polling worker quá tải | BullMQ đã handle queue (đã có `signing-poll.worker.ts`) |
| PDF có form field / annotation conflict với placeholder | Test trên 5-10 mẫu VB thật từ KH trước go-live |
| Visual signature không hiển thị đúng (font Times New Roman tiếng Việt) | Sử dụng `pdf-lib` overlay text TRƯỚC khi addPlaceholder; embed font hỗ trợ Unicode |
| Cert expired giữa giao dịch | API `get_certificate` đã return `cert_valid_to` — backend check trước khi gọi `/sign` |

---

## Tham chiếu nội bộ

- **Source code hệ thống cũ:** `docs/source_code_cu/sources/OneWin.WebApp/SmartCA_VNPT/Model.cs` (Đã có. Pattern giống NetCore sample.)
- **Code e-Office hiện tại:**
  - `e_office_app_new/backend/src/services/signing/providers/smartca-vnpt.provider.ts`
  - `e_office_app_new/backend/src/services/signing/pdf-signer.ts`
  - `e_office_app_new/backend/src/workers/signing-poll.worker.ts`
  - `e_office_app_new/backend/src/routes/digital-signature.ts`
- **DB schema:** `edoc.signing_providers`, `edoc.signing_jobs`, `edoc.staff_signing_config` (xem `database/schema/000_schema_v3.0.sql`)
- **Frontend:** `e_office_app_new/frontend/src/app/(main)/ky-so-cau-hinh/`, `ky-so-tai-khoan/`

---

**End of report.**
