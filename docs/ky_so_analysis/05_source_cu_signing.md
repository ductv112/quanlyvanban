# Phân tích ký số trong source code cũ (OneWin .NET)

> **Nguồn:** `docs/source_code_cu/sources/OneWin.WebApp/`
> **Mục đích:** Hiểu pattern ký số hệ thống cũ để đối chiếu với code Node.js mới.

## 1. Cấu hình `Web.config`

Toàn bộ key liên quan ký số:
```xml
<add key="smartca.client_id"     value="4d00-638392811079166938.apps.smartcaapi.com" />
<add key="smartca.client_secret" value="ZjA4MjE4NDg-MjU3Mi00ZDAw" />
<add key="smartca.sign_domain"   value="https://gwsca.vnpt.vn" />
```

**KHÔNG có** config nào cho MySign Viettel, USB Token, VGCA bổ sung.

## 2. Provider đang tích hợp

### a) SmartCA VNPT (chính, đang chạy)
- File: `OneWin.WebApp/SmartCA_VNPT/Model.cs` (~1000 dòng)
- Endpoint: `https://gwsca.vnpt.vn/sca/sp769/v1/*` (KHỚP với "SmartCA Thường" trong tài liệu mới)
- Method:
  - `_getAccountCert(uid)` → POST `/sca/sp769/v1/credentials/get_certificate`
  - `_sign(uid, dataHash, serialNumber)` → POST `/sca/sp769/v1/signatures/sign` (sign_type="hash")
  - `signSmartCAPDF(pdfBytes, ...)` — orchestrator: get_cert → hash PDF → sign → embed signature
- Dependency: `VnptHashSignatures.Pdf` + `VnptHashSignatures.Common` + `VnptHashSignatures.Interface` (DLL proprietary VNPT, internal dùng iTextSharp 5.5 + BouncyCastle)
- HTTP client: `RestSharp 104.0` + force TLS 1.2

### b) VGCA / MPKI (legacy, ~90% commented out)
- File: `OneWin.WebApp/Areas/Apis/Controllers/SignPDFController.cs`
- Cert AP: `/App_Templates/3108937_VGCA_Application_Provider_certificate.p12` (password `123456` hardcoded)
- Credentials AP: `APID=https://mpki.ca.gov.vn/binhphuoc`, `APPWD=GhAC4PZR`
- Mô hình: MSSP (Mobile Signature Service Provider) — client gọi AP → AP call MSSP
- **Trạng thái: KHÔNG hoạt động (đã comment hầu hết)**

### c) EsignNEAC (chỉ stub)
- Folder `EsignNEAC/` định nghĩa enum CA: `MISA_CA, BKAV_CA, VNPT_CA, VIETTEL_CA, FPT_CA, CA2`
- **KHÔNG có implementation code** — chỉ data structure
- `VgcaController` empty placeholder

### d) MySign Viettel
- **KHÔNG có** trong source cũ
- Hệ thống tỉnh Lào Cai trước đây chỉ dùng SmartCA VNPT

## 3. Controllers & Views

| Path | Loại | Chức năng |
|---|---|---|
| `Areas/Document/Controllers/SignerController.cs` | MVC | View `SetSigner.cshtml` — admin set người ký |
| `Areas/Document/Controllers/VgcaController.cs` | MVC | View `Vgca/Index.cshtml` (empty UI) |
| `Areas/Apis/Controllers/SignPDFController.cs` | API | PDF sign/verify (iText7 + BC) — phần lớn comment |
| `Areas/ApiService/Controllers/edoc/SignerController.cs` | API | CRUD signer DB |
| `Areas/ApiService/Controllers/edoc/VgcaController.cs` | API | Empty placeholder |

## 4. Flow ký số SmartCA (server-side)

```csharp
// 1. Lấy chứng thư của user
var userCert = _getAccountCert(uid, "/sca/sp769/v1/credentials/get_certificate");

// 2. Hash PDF LOCAL trên backend (KHÔNG gửi cả file)
IHashSigner signer = HashSignerFactory.GenerateSigner(pdfBytes, certBase64, null, PDF);
signer.SetHashAlgorithm(MessageDigestAlgorithm.SHA256);
((PdfHashSigner)signer).AddSignatureView(new PdfSignatureView { Rectangle, Page });

// 3. Gửi HASH (không phải file) lên VNPT
DataSign result = _sign(uid, "/sca/sp769/v1/signatures/sign", dataHash, serialNumber);
// Response: { transaction_id, tran_code, signatures[] }

// 4. Embed signature_value vào PDF placeholder
signer.Sign(signatureValueBase64);  // → PDF đã ký hoàn chỉnh
```

**Chính xác giống flow E2E mô tả trong [02_smartca_thuong.md](02_smartca_thuong.md) section 4.**

## 5. Library bắt buộc

**Source cũ phụ thuộc `VnptHashSignatures.dll`** — proprietary VNPT, **chỉ có cho .NET và Java**, KHÔNG có version Node.js.

→ Hệ thống Node.js mới đã thay bằng `@signpdf/signpdf` + `node:crypto` (xem [02_smartca_thuong.md section 6.2](02_smartca_thuong.md)).

## 6. Pitfalls source cũ cần tránh

1. **Hardcode credential trong Web.config** — không encrypt
2. **Password VGCA hardcode** trong code (`123456`, `GhAC4PZR`)
3. **Cert P12 commit vào repo** (`3108937_VGCA_Application_Provider_certificate.p12`)
4. **VGCA code không xóa** dù không dùng → noise
5. **Không có log audit** ký số (không track ai ký gì khi nào)
6. **Không có rate limit** / abuse protection
7. **Trộn 2 endpoint VNPT** (`smartcaapi.com` và `signserviceapi.com`) — confusing

## 7. Kết luận

- **Source cũ chỉ tích hợp 1 provider: SmartCA VNPT (Thường)** — endpoint `/sca/sp769/v1/*`
- **Flow:** Server-side hash signing — KHỚP với pattern `smartca-vnpt.provider.ts` mới đang code
- **Endpoint:** Cùng version `/sca/sp769/v1/*` — code mới KHÔNG cần đổi
- **Credential prod:** `4d00-...smartcaapi.com` (domain khác `signserviceapi.com` của tài liệu sample) → có thể là credential **thế hệ trước** (SmartCA gen 1?) hoặc **credential thật KH cũ** — KHÔNG nên reuse cho test
- **Không học được gì mới về integration** — code mới đã chuẩn pattern hơn (encrypt secret, BullMQ worker, Socket.IO realtime, audit trail)
