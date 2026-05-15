# Phân tích tích hợp ký số MySign Viettel cho e-Office

**Nguồn tài liệu:** `docs/huong_dan_tich_hop_ky_so_MySign_Viettel/`
**Phiên bản tài liệu phân tích:** Mysign Integration Document v1.8/v1.9 (2025-02), Postman collection.
**Mục tiêu:** Tích hợp THẬT (production) — không mock.

---

## 1. MySign Viettel là gì

**MySign** (còn gọi là Cloud-CA / Viettel RS — Remote Signing) là dịch vụ ký số từ xa của Viettel-CA. Đặc điểm:

- **Mô hình:** Server-to-server **hash signing** (KHÔNG gửi cả file lên Viettel). Backend e-Office tự tạo PDF placeholder + tự compute hash (SHA-256, base64) → gửi hash lên Viettel → Viettel yêu cầu user xác thực trên app Mysign / app tích hợp SDK → trả về **chữ ký số (PKCS#7 / CMS)** dạng base64 → backend e-Office tự attach signature vào PDF.
- **Mã hoá ký:** RSA (OID `1.2.840.113549.1.1.1`). Hash: SHA-256 (OID `2.16.840.1.101.3.4.2.1`) — tài liệu nói "Only SHA256 hash converted to base64 is accepted". (Demo code .NET có hỗ trợ SHA-1 nhưng spec mới buộc SHA-256.)
- **Loại CA:** Viettel-CA Remote Signing (RS), chain: User cert → Viettel-CA → Vietnam National Root CA (Ministry of Information and Communications).
- **Loại chữ ký:** Theo demo code .NET → tạo **PKCS#7 detached (CMS)** trong PDF (PdfName `ADBE_PKCS7_DETACHED`). Có hỗ trợ **PAdES (CAdES detached)** nếu bật `CryptoStandard.CADES`. Có thể bật **timestamp (TSA)** nhưng demo để `useTSA = false`.
- **Có 2 mode xác thực user:**
  1. **App Mysign** của Viettel (KH tải sẵn) — không cần Mobile SDK ở phía e-Office.
  2. **Mobile SDK CloudCA Lite** — nhúng vào app mobile của e-Office (Android `.aar` + iOS framework). Hiện e-Office **không có app mobile** → đề xuất dùng mode 1 (App Mysign).
- **3 mode signing flow (server-side):**
  - **Sync** (`async=0`): API `signHash` block chờ user confirm trên app rồi trả signature ngay. Có timeout (mặc định ~120s).
  - **Async polling** (`async=1` hoặc `async=2`): API trả `transactionId` ngay → backend tự poll `/requests/status`.
  - **Async webhook** (`async=3`): Viettel **callback** ngược về backend e-Office khi user confirm xong (cần expose public HTTPS endpoint).

---

## 2. Authentication & Authorization

### 2.1. Credentials Viettel cấp cho e-Office

| Tên | Mô tả | Lưu ở đâu |
|---|---|---|
| `client_id` | ID app tích hợp e-Office (≤50 ký tự). VD demo: `Test_Demo_Mysign` | `.env` backend (encrypt) |
| `client_secret` | Secret app tích hợp. VD demo: `860c5746f30d705ef9b16e0adbd7b5f6d8c4a4ee` | `.env` backend (encrypt — đã có sẵn `pgp_sym_encrypt` cho provider table) |
| `profile_id` | RAS Profile ID. VD demo: `adss:ras:profile:001` | `.env` backend |

### 2.2. Credentials user KH (từng người ký)

| Tên | Mô tả | Lưu ở đâu |
|---|---|---|
| `user_id` | Username Mysign của user (VD: `CMT_0123456789` hoặc `MST_0100109106-998`) | DB `staff.mysign_user_id` (column mới) |
| `credential_id` | ID chứng thư số hoạt động của user (VD: `0123456787-178_2434498_20220913174927`) | DB cache; gọi `/certificates/info` để refresh |

### 2.3. Flow lấy access_token (server-to-server)

**Endpoint:** `POST https://remotesigning.viettel.vn/vtss/service/ras/v1/login`

**Request:**
```json
{
  "client_id": "Test_Demo_Mysign",
  "client_secret": "860c...4ee",
  "profile_id": "adss:ras:profile:001",
  "user_id": "CMT_0123456789"
}
```

**Response 200:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiJ9...j3NAnYL2...",
  "refresh_token": "",
  "token_type": "Bearer",
  "expires_in": "3600"
}
```

- **Lifetime:** 3600s (1 giờ). `refresh_token` của API server-side **luôn rỗng** → khi hết hạn phải gọi lại `/login`.
- **Auth header cho các API tiếp theo:** `Authorization: Bearer <access_token>`.
- **Lưu ý quan trọng:** access_token này **gắn với user_id** (per-user token). Mỗi user signer cần 1 token riêng. Nên cache trong Redis với key `mysign:token:<user_id>` TTL 50 phút (để tự refresh trước khi hết hạn).

### 2.4. Authen errors thường gặp

- `58007` Client ID does not exist → check `.env`
- `58008` User ID does not exist → user chưa được Viettel kích hoạt
- `59033` user ID or password is invalid (401) → sai credential
- `86024` Client secret is invalid → sai `client_secret`
- `86002` TLS client certificate is revoked → nếu Viettel bắt mTLS

---

## 3. API Endpoints chính (server-to-server)

**Base URL production:** `https://remotesigning.viettel.vn`
**Common headers:** `Content-Type: application/json`, `Accept: application/json`, `Authorization: Bearer <token>` (trừ `/login`).

### 3.1. Login — Lấy access_token

| Field | Value |
|---|---|
| **Endpoint** | `POST /vtss/service/ras/v1/login` |
| **Request** | `{client_id, client_secret, profile_id, user_id}` |
| **Response** | `{access_token, refresh_token, token_type, expires_in}` |

### 3.2. CertificateInfo — Lấy danh sách CTS user

| Field | Value |
|---|---|
| **Endpoint** | `POST /vtss/service/certificates/info` |
| **Request** | `{client_id, client_secret, profile_id, user_id, certificates: "chain", certInfo: true, authInfo: true}` |

**Response 200 (array, 1 element/CTS):**
```json
[{
  "description": "Go>Sign mobile based implicit credential authorization",
  "key": {"status": "enabled", "algo": ["1.2.840.113549.1.1.1"], "len": "2048", "curve": null},
  "cert": {
    "status": "valid",
    "certificates": [
      "MIIEXjCCA0agA... (user cert base64)",
      "MIIEPDCCA... (Viettel-CA cert base64)",
      "MIID1z... (Root CA cert base64)"
    ],
    "issuerDN": "CN=Viettel-CA,O=Viettel Group,L=Hà Nội,C=VN",
    "serialNumber": "111681...85",
    "subjectDN": "UID=CMND:0123456789,CN=KH TEST,L=BẮC KẠN,C=VN",
    "validFrom": "20221017043150+0000",
    "validTo": "20230117043150+0000"
  },
  "authMode": "implicit",
  "multisign": "2147483647",
  "credential_id": "0123456789_2482540_20221017114147",
  "scal": "2"
}]
```

**Field quan trọng để extract & lưu DB:**
- `credential_id` — định danh CTS (dùng cho `signHash`)
- `cert.certificates[]` — array 3 cert base64 (user → Viettel-CA → Root) → dùng để build certificate chain khi đính kèm signature vào PDF
- `cert.subjectDN` — thông tin chủ thể (tên người ký) để hiển thị trên signature appearance
- `cert.validFrom`, `cert.validTo` — kiểm hạn (cảnh báo user trước 30 ngày hết hạn)

### 3.3. SignHash — Gửi hash để ký

| Field | Value |
|---|---|
| **Endpoint** | `POST /vtss/service/signHash` |
| **Header** | `Authorization: Bearer <access_token>` |

**Request body:**
```json
{
  "client_id": "Test_Demo_Mysign",
  "client_secret": "860c...4ee",
  "credentialID": "0123456789_2482540_20221017114147",
  "numSignatures": 1,
  "description": "VkIgMTIzLTIwMjUtVUJORA==",
  "documents": [{
    "document_id": "vb_outgoing_123",
    "document_name": "VkItMTIzLTIwMjUucGRm"
  }],
  "hash": ["sTOgwOm+474gFj0q0x1iSNspKqbcse4IeiqlDg/HWuI="],
  "hashAlgo": "2.16.840.1.101.3.4.2.1",
  "signAlgo": "1.2.840.113549.1.1.1",
  "async": 1
}
```

**Lưu ý FORMAT quan trọng (đã được nhấn mạnh trong tài liệu):**
- `document_name` và `description` **PHẢI base64-encode** của chuỗi UTF-8 (đoạn raw chỉ chấp nhận `[a-zA-Z0-9_\- ]`, KHÔNG dấu tiếng Việt).
- Base64 length < 100 ký tự.
- `hash` là array base64 SHA-256 hash của data cần ký (sau khi PDF đã được "pre-close" bằng PdfStamper).
- `numSignatures` = số lượng signature sẽ tạo (PHẢI = `hash[].length` = `documents[].length`).

**Response — `async=0` (sync):**
```json
{"signatures": ["KeTob5gl26S2tmXjqN...MRGtoew=="]}
```

**Response — `async=1` hoặc `async=2` (poll):**
```json
{"transactionId": "de67f948-0498-4919-af28-dff54a6a4e77"}
```

**Response — `async=3` (webhook):** giống `async=1` + Viettel sẽ callback về URL e-Office sau khi user confirm.

### 3.4. Get signing request status (poll cho async=1,2)

| Field | Value |
|---|---|
| **Endpoint** | `POST /vtss/service/requests/status` |
| **Request** | `{"transactionId": "de67f948-..."}` |
| **Header** | `Authorization: Bearer <access_token>` |

**Response 200:**
```json
{"signatures": ["KeTob5gl26S...MRGtoew=="], "status": "1"}
```

**Status codes của response:**

| Status | Mô tả |
|---|---|
| `1` | Success — có `signatures[]` |
| `4000` | Waiting for user confirmation (poll tiếp) |
| `6000` | User đã confirm, system đang ký (poll tiếp) |
| `4001` | Timeout — user không confirm trong thời gian quy định |
| `4002` | User reject |
| `4004` | Signing failed |
| `4005` | Tài khoản hết lượt ký / hết tiền |
| `13004` | CTS hết hạn hoặc bị thu hồi |
| `50000` | Lỗi nội bộ Viettel |

**Pattern poll khuyến nghị:** mỗi 2s, max 60 lần (~2 phút). Sau đó gọi `signHash` lại hoặc báo timeout.

### 3.5. Webhook callback (async=3) — 2 API e-Office PHẢI expose

#### 3.5.1. API Auth (Viettel gọi để lấy token call API kết quả)

**Backend e-Office expose:** `GET https://<e-office-public-url>/api/mysign/webhook/auth`

Viettel sẽ gửi:
```json
{
  "grant_type": "client_credentials",
  "client_id": "simple_callback_code",
  "client_secret": "205640fd6ea8c7d80bb91c630b52d286d21ee511"
}
```

Backend trả:
```json
{
  "status_code": "00",
  "message": "Thành công",
  "data": {
    "access_token": "Ex2YH...0Z",
    "expires_in": "3600000",
    "consented_on": "1735035122"
  }
}
```

> **Lưu ý:** `client_id` + `client_secret` ở đây do **e-Office** tự định nghĩa và cấp **cho Viettel** (chiều ngược lại). Phải lưu cặp này ở `.env` để verify khi Viettel gọi callback.

#### 3.5.2. API nhận kết quả ký

**Backend e-Office expose:** `GET https://<e-office-public-url>/api/mysign/webhook/result`
(URL này e-Office cung cấp cho Viettel khi setup tích hợp.)

Viettel gọi với `Authorization: Bearer <access_token từ 3.5.1>` + body:
```json
{
  "meta_data": {
    "request_id": "VIETTEL_6fa0d53c-..._1735543766152",
    "transaction_id": "6fa0d53c-e225-45bd-8a78-95246c9bb590",
    "description": "Ký thành công",
    "status": "1"
  },
  "data": {
    "action_timestamp": 1735543766,
    "signature_timestamp": 1735543766,
    "results": [{
      "document_id": "vb_outgoing_123",
      "signature": "dQA1ZLHK...lmsIy69nLiTICO4Q=="
    }]
  }
}
```

Backend trả:
```json
{"status_code": "00", "message": "Thành công"}
```

---

## 4. Signing flow E2E (e-Office → MySign → e-Office)

### 4.1. Flow chính (chọn async=1 polling — đơn giản nhất, không cần expose public webhook)

```
[Frontend e-Office]                [Backend e-Office]              [Viettel MySign]            [User Mobile]
       |                                  |                              |                          |
   1. Click "Ký số" văn bản đi          |                              |                          |
       | -- POST /api/ky-so/start ----> |                              |                          |
       |                                  |                              |                          |
       |                              2. Load PDF từ MinIO                |                          |
       |                              3. Get/refresh Mysign token (Redis cache 50min)               |
       |                                  | -- POST /vtss/.../login --> |                          |
       |                                  | <----- {access_token} -----  |                          |
       |                                  |                              |                          |
       |                              4. Get CTS info (cache 1h)         |                          |
       |                                  | -- POST .../certificates/info -> |                       |
       |                                  | <-- {credential_id, cert chain} -|                       |
       |                                  |                              |                          |
       |                              5. PdfStamper.CreateSignature + PreClose       |                |
       |                                  | (tự compute SHA-256 hash của byte range PDF placeholder)  |
       |                                  |                              |                          |
       |                              6. SignHash async=1                |                          |
       |                                  | -- POST .../signHash --->   |                          |
       |                                  | <----- {transactionId} ----  |                          |
       |                                  |                              | -- Push notification --> |
       | <-- {transactionId} ---------    |                              |                          |
       |                                  |                              |                          |
   7. UI hiển thị "Đang chờ xác thực... (mở app Mysign trên điện thoại)"                            |
       |                                  |                              |                       8. User mở Mysign app, xem yêu cầu, xác thực bằng vân tay
       |                                  |                              | <-- Auth OK ---------    |
       |                                  |                              | (server-side compute signature) |
       |                                  |                              |                          |
   9. Frontend poll status mỗi 2s    |                              |                          |
       | -- GET /api/ky-so/status/<tid> ->|                              |                          |
       |                                  | -- POST .../requests/status->|                          |
       |                                  | <-- {status:"1", signatures}-|                          |
       |                                  |                              |                          |
       |                              10. Attach signature vào PDF (sgn.SetExternalDigest + sap.Close + stamper.Close) |
       |                              11. Upload PDF đã ký vào MinIO     |                          |
       |                              12. Update DB: outgoing_doc.signed=true, append history       |
       | <-- {status:done, file_id} -----  |                              |                          |
       |                                  |                              |                          |
   13. UI hiển thị "Ký thành công", cho phép download VB đã ký           |                          |
```

### 4.2. Flow PDF/XML khác nhau

| Mode | Hash computation | Signature attachment |
|---|---|---|
| **PDF (PAdES-B/CMS)** | iText PdfStamper.CreateSignature + sap.PreClose + DigestAlgorithms.Digest(SHA-256) trên byte-range | sgn.SetExternalDigest(extSig) + GetEncodedPKCS7 + sap.Close |
| **XML (XAdES)** | Canonicalize XML node cần ký + SHA-256 hash → ký → wrap thành XMLDSig | Insert `<Signature>` block vào XML |
| **Office (Word/Excel)** | Không hỗ trợ trực tiếp — phải convert PDF trước hoặc dùng OOXML detached signature (phức tạp) |

**Đề xuất phase 1:** Chỉ hỗ trợ **PDF**. XML là phase 2 nếu KH cần ký file XML LGSP (hiện đã ẩn).

---

## 5. Code demo phân tích

### 5.1. Cấu trúc demo

| Folder | Ngôn ngữ | Mô tả |
|---|---|---|
| `Code demo ky Mysign/DEMO_CLOUD_CA_DOTNET/` | C# .NET Framework 4.5 (WinForms) | Demo ký PDF — **quan trọng nhất** |
| `Code demo ky Mysign/DEMO_CLOUD_CA_JAVA/` | Java (NetBeans, có ant build) | Demo ký PDF — tham khảo chéo |
| `Code demo ký Mysign - XML/DEMO_CLOUD_CA_DOTNET_XML_Gateway/` | C# | Demo ký XML |
| `Code demo ký Mysign - XML/Portable/` | C# | XML signer portable |
| `ViettelFileSigner-v2.7/` | C# desktop tool | Tool desktop độc lập — KHÔNG dùng cho integration |
| `SDK Mobile-...zip` | Android `.aar` + iOS `.framework` | Chỉ dùng nếu nhúng SDK vào app mobile e-Office (KHÔNG cần phase 1) |

### 5.2. Dependency .NET demo (PDF signing)

```
- iTextSharp 5.x (PDF manipulation — sign, hash, stamp)
- BouncyCastle (X509 cert parsing, PKCS7 signing)
- Newtonsoft.Json (HTTP API call)
- log4net (logging)
- ViettelFileSigner.dll (wrapper helper của Viettel — encapsulate PdfSignerSynchronous, SignPdfFile, HashFilePDF)
```

### 5.3. Đoạn code core flow (trích từ `Form1.cs` lines 316-360)

```csharp
// 1. Tạo PDF placeholder + compute hash
SignPdfFile pdfSig = new SignPdfFile();
string base64Hash = HashFilePDF.GetHashTypeRectangleText(
    pdfSig, pathFile, certChain, HashFilePDF.HASH_ALGORITHM_SHA_256);
byte[] hash = Convert.FromBase64String(base64Hash);

// 2. Gọi SignHash API Viettel
String[] hashList = new String[] { base64Hash };
String data = app + " - " + desc;                                    // raw "MyApp - Ky VB 123"
var dataBytes = Encoding.UTF8.GetBytes(data);
String dataDisplay = Convert.ToBase64String(dataBytes);              // base64 → hiển thị trên app Mysign
String[] signatureList = MobileCA.signHash(
    hashList, id, dataDisplay, clientId, clientSecret,
    credentialID, wsdlUrl, token);                                   // returns base64 signatures

if (signatureList == null || signatureList.Length == 0) {
    log("Ký không thành công"); return false;
}
var signature = signatureList[0];

// 3. Attach signature vào PDF
TimestampConfig timestampConfig = new TimestampConfig { UseTimestamp = false };
if (!pdfSig.insertSignature(signature, signedFile, timestampConfig,
                            HashFilePDF.HASH_ALGORITHM_SHA_256)) {
    log("Insert signature into file fail."); return false;
}
log("Ký thành công");
```

### 5.4. Core hash computation (từ `PdfSignerSynchronous.cs` lines 222-281)

```csharp
public byte[] GetHashFile(PdfSignatureAppearance sapInput, ICollection<X509Certificate> chain, ...) {
    sap.Certificate = certa[0];
    PdfSignature dic = new PdfSignature(PdfName.ADOBE_PPKLITE,
        sigtype == CryptoStandard.CADES
            ? PdfName.ETSI_CADES_DETACHED
            : PdfName.ADBE_PKCS7_DETACHED);   // PAdES vs CMS
    dic.Reason = sap.Reason;
    dic.Location = sap.Location;
    dic.Date = new PdfDate(sap.SignDate);
    sap.CryptoDictionary = dic;

    Dictionary<PdfName, int> exc = new Dictionary<PdfName, int>();
    exc[PdfName.CONTENTS] = estimatedSize * 2 + 2;   // reserve space cho signature
    sap.PreClose(exc);

    String hashAlgorithm = "SHA1";                    // demo dùng SHA1, phải đổi SHA256
    sgn = new PdfPKCS7(null, chain, hashAlgorithm, false);
    Stream data = sap.GetRangeStream();                // byte-range PDF cần hash
    hash = DigestAlgorithms.Digest(data, hashAlgorithm);
    cal = DateTime.Now;
    byte[] sh = sgn.getAuthenticatedAttributeBytes(hash, cal, ocsp, crlBytes, sigtype);
    return sh;   // <-- đây là cái sẽ gửi lên Viettel (base64 hoá)
}
```

### 5.5. **Khác biệt quan trọng giữa demo và Node.js production**

Demo .NET dùng **iTextSharp 5.x** để compute hash byte-range của PDF. Để port sang Node.js, **2 lựa chọn:**

**Option A — Pure Node.js:**
- Library: `pdf-lib` (đã có trong project) **KHÔNG hỗ trợ detached signature placeholder** trực tiếp.
- Library: `@signpdf/signpdf` + `@signpdf/placeholder-plain` + `@signpdf/signer-p12` — hỗ trợ tốt nhưng cần custom signer wrapper để delegate hash → Viettel.
- Library: `node-signpdf` (deprecated nhưng vẫn dùng được).
- **Khó nhất:** PDF byte-range hash phải đúng tuyệt đối (1 byte sai → signature invalid). Cần test kỹ với Adobe Reader.

**Option B — Standalone Java/.NET signing service (microservice):**
- Tạo 1 service riêng (Spring Boot Java hoặc .NET) wrap demo code của Viettel → expose HTTP endpoint `POST /sign-pdf` → Node.js backend gọi qua HTTP.
- **Ưu:** Code chuẩn của Viettel, ít rủi ro hash sai.
- **Nhược:** Thêm 1 dịch vụ phải deploy + maintain.

→ **Khuyến nghị:** Option A (Node.js + `@signpdf/signpdf`) — đỡ phức tạp deploy, có nhiều ví dụ open-source ký hash từ xa. Spike 1-2 ngày để verify signature valid trên Adobe Reader trước.

---

## 6. Yêu cầu hạ tầng & môi trường

### 6.1. Server-side (backend e-Office)

| Yêu cầu | Chi tiết |
|---|---|
| **Outbound IP whitelist** | KHÔNG yêu cầu trong tài liệu, nhưng nên hỏi Viettel: có cần whitelist IP server e-Office gọi đến `remotesigning.viettel.vn` không? |
| **Production URL** | `https://remotesigning.viettel.vn` (port 443) |
| **Sandbox URL** | **KHÔNG có trong tài liệu** — phải hỏi Viettel cấp môi trường test riêng |
| **Public HTTPS endpoint (chỉ nếu dùng async=3 webhook)** | e-Office cần có domain public + cert HTTPS valid (Let's Encrypt OK), expose 2 endpoint `/api/mysign/webhook/auth` + `/api/mysign/webhook/result` |
| **Root CA Viettel cần cài trên server?** | **KHÔNG bắt buộc** ở phía server (chỉ cần verify HTTPS chuẩn). Tài liệu `HUONG DAN CAI DAT CTS ROOT CA VIETTEL Mysign.pdf` chỉ dành cho **PC của user cuối** để Adobe Reader nhận diện chữ ký là valid (cài Vietnam National Root CA + Viettel-CA RS vào Windows Trust Store) |
| **OS support** | Cross-platform (Node.js Express trên Linux/Docker là OK) |

### 6.2. Phía khách hàng (end-user)

| Yêu cầu | Chi tiết |
|---|---|
| **Cert type** | Viettel RS (Remote Signing) — KH mua từ Viettel-CA. Không phải hard token, không phải soft cert local. |
| **Authentication app** | **App Mysign** của Viettel (tải Play Store / App Store) — hoặc app mobile e-Office tích hợp SDK CloudCA Lite (phase 2) |
| **Mỗi KH cần** | 1 tài khoản Mysign + 1 chứng thư số RS active + smartphone biometric (vân tay/Face ID) |
| **Cài Root CA trên PC** | Optional — để Adobe Reader xanh tick "Signature valid" khi mở PDF đã ký. Hướng dẫn trong `HUONG DAN CAI DAT CTS ROOT CA VIETTEL Mysign.pdf` (cài Vietnam National Root CA vào Trusted Root + Viettel-CA RS vào Intermediate). |

---

## 7. Thông tin còn THIẾU cần xin nhà cung cấp Viettel

| # | Item | Mức độ |
|---|---|---|
| 1 | **URL sandbox riêng** để test (không thấy trong tài liệu — chỉ có production URL `remotesigning.viettel.vn`) | **BẮT BUỘC** |
| 2 | **Sandbox credentials:** `client_id` + `client_secret` + `profile_id` dùng cho môi trường test | **BẮT BUỘC** |
| 3 | **Sandbox user accounts** để demo: ít nhất 2 user_id có CTS active để test multi-signer | **BẮT BUỘC** |
| 4 | **Demo App Mysign** linked vào sandbox để xác thực OTP (Play Store/App Store) — link cài, hướng dẫn enroll | **BẮT BUỘC** |
| 5 | **Production credentials** (sẽ cấp khi go-live) | Sau khi UAT |
| 6 | **Có support webhook async=3 hay không?** Hỏi rõ + cách config callback URL ở phía Viettel | **QUAN TRỌNG** |
| 7 | **Rate limit** API (calls/min, calls/day) — không thấy trong tài liệu | Nên hỏi |
| 8 | **Pricing** mỗi lần ký (số lượt/account/tháng) — để tính cost cho KH | Cho commercial |
| 9 | **Whitelist IP** outbound từ server e-Office (nếu có) | Cho production |
| 10 | **SLA + support contact** khi production có sự cố | Cho commercial |
| 11 | **Có hỗ trợ ký PAdES-LT/LTA (long-term archive với CRL/OCSP embedded)?** | Nếu KH cần |
| 12 | **TSA endpoint Viettel** (nếu muốn timestamp) | Optional |
| 13 | **Sample PDF đã ký bằng MySign** để verify chữ ký trên Adobe Reader của chúng ta tạo ra giống chuẩn | **QUAN TRỌNG** |

---

## 8. Đánh giá độ phức tạp triển khai

### 8.1. Effort estimate (giả định Option A — pure Node.js)

| Module | Effort | Ghi chú |
|---|---|---|
| **Backend — MySign API client (login, certInfo, signHash, status)** | 2 MD | Straightforward HTTP wrapper |
| **Backend — Token cache (Redis) + refresh logic** | 1 MD | TTL 50 phút |
| **Backend — PDF placeholder + hash compute (`@signpdf/signpdf`)** | 3-5 MD | **Rủi ro cao** — phải test kỹ |
| **Backend — Attach signature vào PDF + verify Adobe Reader** | 2-3 MD | |
| **Backend — Poll job (BullMQ) hoặc webhook endpoint** | 1-2 MD | |
| **Backend — Provider config CRUD (đã có sẵn `pgp_sym_encrypt`)** | 0.5 MD | Lưu `client_id`/`client_secret`/`profile_id` |
| **Backend — Staff field `mysign_user_id`, `mysign_credential_id`** | 0.5 MD | |
| **Frontend — UI chọn vị trí chữ ký (page, x, y) — Drawer** | 2 MD | |
| **Frontend — UI "Đang chờ xác thực trên App Mysign" + poll status** | 1 MD | |
| **Frontend — Hiển thị file PDF đã ký + download** | 0.5 MD | (đã có sẵn) |
| **DB migration: staff fields + signing_log table** | 0.5 MD | |
| **Integration test với sandbox Viettel** | 2-3 MD | |
| **UAT với KH (test trên app Mysign thật)** | 1-2 MD | |
| **TỔNG (lạc quan)** | **17-23 MD** (~3-4 tuần 1 dev fulltime) |

### 8.2. Rủi ro chính

1. **Hash byte-range PDF sai 1 byte** → signature invalid trên Adobe Reader → mất rất nhiều thời gian debug. **Mitigation:** spike 1-2 ngày đầu phase để verify với sandbox + Adobe Reader thật trước khi tiếp tục.
2. **Sandbox Viettel chưa được cấp** → phải chờ ~1 tuần liên hệ. **Mitigation:** chủ động liên hệ Viettel-CA hỗ trợ ngay khi bắt đầu phase.
3. **`document_name` / `description` chỉ chấp nhận `[a-zA-Z0-9_\- ]` raw, base64 < 100 ký tự** → không thể hiển thị tiếng Việt có dấu trên app Mysign cho user. **Mitigation:** dùng số văn bản + ID thay vì tên (VD: `VB-123-2025`).
4. **CTS user hết hạn không kiểm soát được** → SignHash fail với code `13004`. **Mitigation:** cron job daily check CertInfo, cảnh báo user trước 30 ngày hết hạn.
5. **Async=3 webhook cần expose public** → vấn đề firewall trong môi trường on-prem KH. **Mitigation:** dùng async=1 polling cho phase 1, async=3 cho phase 2 nếu cần performance.
6. **Multi-signer 1 PDF** (lãnh đạo ký, văn thư đóng dấu) — phải bật `multiSignatures=true` khi tạo PdfStamper. **Mitigation:** test kỹ.
7. **App Mysign UX khó cho user lớn tuổi** — phải có hướng dẫn rõ ràng. **Mitigation:** video tutorial + section trong slide đào tạo.

### 8.3. Có cần signing service standalone không?

**Khuyến nghị: KHÔNG cần signing service riêng nếu chọn Option A.**

Node.js có thư viện đủ tốt (`@signpdf/signpdf` + `node-forge`) để:
- Tạo PDF placeholder
- Compute SHA-256 byte-range hash
- Send hash to Viettel
- Insert signature blob

**CHỈ cần** signing service Java/.NET standalone nếu:
- Spike Node.js fail (signature không valid trên Adobe Reader sau 2-3 ngày)
- KH yêu cầu chuẩn PAdES-LTA với CRL/OCSP embedded (Node lib chưa hoàn thiện cho LTA)
- Multi-tenancy heavy concurrent signing (Java performance tốt hơn cho heavy PDF ops)

→ **Plan:** Bắt đầu với Node.js. Nếu sau 3 ngày spike vẫn fail Adobe Reader verify → fallback sang microservice Java/.NET (1 tuần thêm).

---

## 9. Phụ lục — Kế hoạch tích hợp thực tế cho e-Office

### 9.1. Module cần thêm/sửa

```
e_office_app_new/
├── backend/src/
│   ├── lib/
│   │   └── signing/
│   │       ├── mysign-client.ts          (NEW — wrap login/certInfo/signHash/status)
│   │       ├── pdf-signer.ts             (NEW — wrap @signpdf + Viettel hash flow)
│   │       └── token-cache.ts            (NEW — Redis cache 50min)
│   ├── routes/
│   │   └── ky-so.ts                      (NEW or extend — start, status, webhook endpoints)
│   ├── repositories/
│   │   ├── signing-provider.repository.ts (đã có — extend MySign)
│   │   └── signing-log.repository.ts     (NEW)
│   └── workers/
│       └── mysign-poll.worker.ts         (NEW — BullMQ poll job nếu dùng async=1)
├── frontend/src/
│   └── app/(main)/van-ban-di/[id]/
│       ├── KySoMysignDrawer.tsx          (NEW — UI chọn cert + vị trí + status)
│       └── ...
└── database/schema/
    └── 000_schema_v3.0.sql               (extend: staff.mysign_user_id, signing_logs table)
```

### 9.2. .env additions

```bash
# MySign Viettel
MYSIGN_BASE_URL=https://remotesigning.viettel.vn
MYSIGN_CLIENT_ID=<từ Viettel>
MYSIGN_CLIENT_SECRET=<từ Viettel — encrypt qua pgp_sym_encrypt>
MYSIGN_PROFILE_ID=adss:ras:profile:001
MYSIGN_DEFAULT_ASYNC_MODE=1          # 1=poll, 3=webhook
MYSIGN_POLL_INTERVAL_MS=2000
MYSIGN_POLL_MAX_RETRIES=60

# Webhook (chỉ khi MYSIGN_DEFAULT_ASYNC_MODE=3)
MYSIGN_WEBHOOK_CLIENT_ID=<e-Office tự tạo>
MYSIGN_WEBHOOK_CLIENT_SECRET=<e-Office tự tạo>
```

### 9.3. DB schema cần thêm

```sql
-- Staff bổ sung 2 field MySign
ALTER TABLE public.staff
  ADD COLUMN IF NOT EXISTS mysign_user_id VARCHAR(50),
  ADD COLUMN IF NOT EXISTS mysign_credential_id VARCHAR(100),
  ADD COLUMN IF NOT EXISTS mysign_cert_valid_to TIMESTAMP;

-- Signing log
CREATE TABLE IF NOT EXISTS edoc.signing_logs (
  id BIGSERIAL PRIMARY KEY,
  doc_type VARCHAR(20) NOT NULL,           -- 'outgoing' | 'incoming' | 'draft'
  doc_id BIGINT NOT NULL,
  attachment_id BIGINT,
  signer_staff_id BIGINT NOT NULL REFERENCES public.staff(id),
  provider VARCHAR(20) NOT NULL,           -- 'mysign' | 'smartca' | 'viettel-ca'
  mysign_transaction_id VARCHAR(100),
  mysign_credential_id VARCHAR(100),
  status VARCHAR(20) NOT NULL,             -- 'pending' | 'waiting' | 'success' | 'failed' | 'rejected' | 'timeout'
  error_code VARCHAR(20),
  error_message TEXT,
  signed_file_path VARCHAR(500),
  hash_base64 TEXT,
  signature_base64 TEXT,
  signed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_signing_logs_transaction ON edoc.signing_logs(mysign_transaction_id);
CREATE INDEX IF NOT EXISTS idx_signing_logs_doc ON edoc.signing_logs(doc_type, doc_id);
```

---

**Kết luận:** Tài liệu Viettel khá đầy đủ để integrate. Bottleneck chính là **sandbox Viettel** + **hash byte-range PDF chuẩn**. Đề xuất triển khai theo phase: (1) Spike PDF hash 2-3 ngày → (2) Backend API wrap 1 tuần → (3) Frontend UI + poll 4 ngày → (4) Integration test + UAT với KH 1 tuần. Tổng ~3-4 tuần 1 dev fulltime.
