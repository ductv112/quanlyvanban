# Báo cáo phân tích — Code ký số hiện tại trong e-Office

> **Mục đích:** Cung cấp bản đồ chính xác về phần code ký số đã triển khai để đối chiếu với 3 tài liệu nhà cung cấp (MySign Viettel, SmartCA Thường, SmartCA Tích hợp), từ đó đánh giá gap khi triển khai THẬT.
>
> **Phạm vi:** Backend (`e_office_app_new/backend/src/`), Frontend (`e_office_app_new/frontend/src/`), Database (`e_office_app_new/database/`).

---

## 1. Module/file backend liên quan ký số

### Routes (API Endpoints)
| File | Mô tả |
|---|---|
| `backend/src/routes/ky-so-sign.ts` | Endpoint async sign flow chính (Phase 11): POST `/api/ky-so/sign` (khởi tạo ký), GET `/:id` (status), POST `/:id/cancel`, GET `/:id/download` |
| `backend/src/routes/ky-so-cau-hinh.ts` | Admin cấu hình provider: list, test connection, cập nhật config, kích hoạt provider (SmartCA + MySign) |
| `backend/src/routes/ky-so-tai-khoan.ts` | User config cá nhân: GET/POST config, POST `/certificates` (tải danh sách cert), POST `/verify` |
| `backend/src/routes/ky-so-danh-sach.ts` | Danh sách ký: GET `/counts` (badge), GET `/` (4 tab need_sign/pending/completed/failed) |
| `backend/src/routes/digital-signature.ts` | **Legacy v1.0** — preview, sign/smart-ca, sign/esign-neac, verify-otp, mock endpoints |

### Repositories
| File | Mô tả |
|---|---|
| `backend/src/repositories/sign-transaction.repository.ts` | CRUD sign_transactions: create, getById, getActive, updateStatus, setProviderTxn, countByStaff |
| `backend/src/repositories/signing-provider-config.repository.ts` | Provider config: list, getActive, getByCode, upsert, setActive |
| `backend/src/repositories/staff-signing-config.repository.ts` | User config theo (staff_id, provider_code) |
| `backend/src/repositories/attachment-sign.repository.ts` | canSign() (ACL), needListByStaff, listByStaff, countByStaff, needCountByStaff |
| `backend/src/repositories/digital-signature.repository.ts` | Legacy v1.0 signatures |
| `backend/src/repositories/signer.repository.ts` | Người ký (legacy) |

### Services
| File | Mô tả |
|---|---|
| `backend/src/services/signing.service.ts` | Factory `getSigningService()` → MOCK hoặc REAL. **REAL chưa implement, throw error** |
| `backend/src/services/signing-mock.service.ts` | MOCK signSmartCA / verifyOTP / signEsignNEAC (hardcoded success) |
| `backend/src/services/signing/pdf-signer.ts` | Pure JS PDF ký: `addSignaturePlaceholder`, `computePdfHash`, `signPdf` dùng `@signpdf/signpdf` + PrecomputedSigner |
| `backend/src/services/signing/crypto.ts` | encryptSecret/decryptSecret cho client_secret (dùng SIGNING_SECRET_KEY env) |
| `backend/src/services/signing/providers/provider.interface.ts` | Interface `SigningProvider`: testConnection, listCertificates, signHash, getSignStatus |
| `backend/src/services/signing/providers/smartca-vnpt.provider.ts` | SmartCA VNPT adapter: POST `/sca/sp769/v1/credentials/get_certificate`, `.../signatures/sign`, `.../status` |
| `backend/src/services/signing/providers/mysign-viettel.provider.ts` | MySign Viettel adapter: POST `/vtss/service/ras/v1/login`, `.../certificates/info`, `.../signHash`, `.../requests/status` |
| `backend/src/services/signing/providers/provider-factory.ts` | Dispatcher: getProviderByCode (pure), getActiveProviderWithCredentials (fetch + decrypt), getProviderByCodeWithCredentials |
| `backend/src/services/signing/providers/http-client.ts` | HTTP client abstraction (fetch, injectable cho test) |

### Libraries
| File | Mô tả |
|---|---|
| `backend/src/lib/signing/sign-helpers.ts` | isValidAttachmentType, buildSignedObjectKey, PLACEHOLDER_PREFIX |
| `backend/src/lib/signing/sign-events.ts` | Socket.IO events: emitSignCompleted, emitSignFailed → user room |
| `backend/src/lib/queue/signing-queue.ts` | BullMQ: enqueuePollSignStatus, cancelPollJobsForTransaction |
| `backend/src/lib/signing/placeholder-store.ts` | MinIO placeholder management: downloadOriginalPdf, putPlaceholder, getPlaceholder, removePlaceholder |

### Workers
| File | Mô tả |
|---|---|
| `backend/src/workers/signing-poll.worker.ts` | BullMQ Worker `poll-sign-status`: gọi `provider.getSignStatus()`, nếu completed → embed signature + upload MinIO + emit Socket + bell notification |

---

## 2. Route/API backend ký số

| Method | Endpoint | Service/Repo | Mô tả |
|---|---|---|---|
| POST | `/api/ky-so/sign` | signTransactionRepository, getActiveProviderWithCredentials, attachmentSignRepository | Khởi tạo: hash PDF → tạo transaction → `provider.signHash()` → enqueue poll. Trả 201 + transaction_id + provider_code |
| GET | `/api/ky-so/sign/:id` | signTransactionRepository | Status transaction (owner-only) — FE polling |
| POST | `/api/ky-so/sign/:id/cancel` | signTransactionRepository | Hủy pending — mark cancelled, cleanup placeholder |
| GET | `/api/ky-so/sign/:id/download` | signTransactionRepository | Tải file đã ký (owner-or-admin, chỉ completed) — stream qua backend proxy |
| GET | `/api/ky-so/danh-sach` | attachmentSignRepository | 4 tab phân trang |
| GET | `/api/ky-so/danh-sach/counts` | attachmentSignRepository | Badge counts |
| GET | `/api/ky-so/cau-hinh` | signingProviderConfigRepository, fn_signing_stats | List 2 providers + stats + has_secret (KHÔNG trả plaintext) |
| POST | `/api/ky-so/cau-hinh/test-connection` | getProviderByCode | Test credentials không persist |
| POST | `/api/ky-so/cau-hinh/:id/test-saved` | signingProviderConfigRepository, getProviderByCode | Test credentials đã lưu + persist result |
| PUT | `/api/ky-so/cau-hinh/:id` | signingProviderConfigRepository, encryptSecret | Update config: base_url, client_id, secret (re-encrypt) |
| PATCH | `/api/ky-so/cau-hinh/:id/active` | signingProviderConfigRepository | Kích hoạt (auto-deactivate others). Guard: chỉ cho phép nếu test_result='OK' |
| POST | `/api/ky-so/cau-hinh` | — | **DISABLED** (405) — 2 provider cố định |
| DELETE | `/api/ky-so/cau-hinh/:id` | — | **DISABLED** (405) |
| GET | `/api/ky-so/tai-khoan` | staffSigningConfigRepository, getActiveProviderWithCredentials | Active provider metadata + user config (no cert_data) |
| POST | `/api/ky-so/tai-khoan` | staffSigningConfigRepository | Upsert config — reset is_verified=false |
| POST | `/api/ky-so/tai-khoan/certificates` | getActiveProviderWithCredentials | Fetch cert list (read-only, không persist) |
| POST | `/api/ky-so/tai-khoan/verify` | staffSigningConfigRepository, getActiveProviderWithCredentials | Verify: listCertificates → match → persist + is_verified=true |
| GET | `/api/ky-so/preview` | — | Presigned preview (legacy) |
| POST | `/api/ky-so/sign/smart-ca` | getSigningService | **Legacy MOCK** |
| POST | `/api/ky-so/sign/esign-neac` | getSigningService | **Legacy MOCK** |
| POST | `/api/ky-so/sign/verify-otp` | getSigningService | **Legacy MOCK** |
| POST | `/api/ky-so/mock/sign` | fn_attachment_mock_sign | **Dev-only MOCK** |
| POST | `/api/ky-so/mock/verify` | fn_attachment_mock_verify | **Dev-only MOCK** |

---

## 3. Database schema ký số

### Tables chính

**`edoc.sign_transactions`** (Phase 11 async sign flow)
- `id BIGINT` (PK)
- `staff_id INT`
- `provider_code VARCHAR(20)` — `SMARTCA_VNPT` | `MYSIGN_VIETTEL` (CHECK)
- `provider_txn_id VARCHAR(200)`
- `attachment_id BIGINT`
- `attachment_type VARCHAR(20)` — incoming|outgoing|drafting|handling
- `doc_id BIGINT`, `doc_type VARCHAR(20)`
- `file_hash_sha256 VARCHAR(64)`
- `signature_base64 TEXT` (PKCS7)
- `signed_file_path VARCHAR(1000)`
- `status VARCHAR(20)` — pending|completed|failed|cancelled|expired
- `error_message TEXT`
- `retry_count INT` (max 36 = 3 phút / 5s)
- `created_at, started_at, completed_at, expires_at`

**`public.signing_provider_config`** (Admin config)
- `id BIGINT`
- `provider_code VARCHAR(20)` UNIQUE
- `provider_name VARCHAR(100)`
- `base_url VARCHAR(500)`
- `client_id VARCHAR(200)`
- `client_secret BYTEA` — pgp_sym_encrypt(plaintext, SIGNING_SECRET_KEY)
- `profile_id VARCHAR(200)` — chỉ MySign
- `extra_config JSONB` (rỗng `{}`)
- `is_active BOOLEAN` (chỉ 1 active)
- `last_tested_at, test_result TEXT`
- `created_at, updated_at`

**`public.staff_signing_config`** (User config)
- Composite key (staff_id, provider_code)
- `user_id VARCHAR(200)` — số điện thoại/CCCD/CMT_xxx
- `credential_id VARCHAR(200)` — bắt buộc MySign, optional SmartCA
- `certificate_data TEXT` — DER base64 snapshot
- `certificate_subject VARCHAR(500)`, `certificate_serial VARCHAR(200)`
- `is_verified BOOLEAN`, `last_verified_at`, `last_error TEXT`

**`edoc.digital_signatures`** (Legacy v1.0)
- doc_id, doc_type, staff_id, sign_method (smart_ca|esign_neac|usb_token), certificate_*, signed_file_path, sign_status

### Stored Functions chính
- `edoc.fn_sign_transaction_create(staff_id, provider_code, attachment_id, attachment_type, doc_id, doc_type, file_hash_sha256)` → return id + success
- `edoc.fn_sign_transaction_list_by_staff(staff_id, tab, page, page_size)` — 4 tab filter
- `edoc.fn_sign_need_list_by_staff(staff_id, page, page_size)` — ACL check + filter
- `public.fn_signing_stats(provider_code)` — total_users, verified_users, monthly_*
- `edoc.fn_attachment_can_sign(attachment_id, attachment_type, staff_id)` — RETURN can_sign, reason, file_path, file_name
- `edoc.fn_attachment_finalize_sign(attachment_id, attachment_type, signed_file_path, sign_provider_code, sign_transaction_id)` — UPDATE attachment_*_docs
- `edoc.fn_attachment_mock_sign / fn_attachment_mock_verify` — Legacy mock

---

## 4. Frontend pages/components ký số

### Pages (Next.js App Router)
| File | Mô tả |
|---|---|
| `frontend/src/app/(main)/ky-so/cau-hinh/page.tsx` | **Admin** — list 2 provider, show/hide secret, test connection, update base_url/client_id/secret, kích hoạt |
| `frontend/src/app/(main)/ky-so/tai-khoan/page.tsx` | **User** — input user_id, (MySign) select certificate, verify, show cert subject |
| `frontend/src/app/(main)/ky-so/danh-sach/page.tsx` | **User** — 4 tab phân trang, badge counts sidebar |

### Components
- `frontend/src/components/signing/SignModal.tsx` — Shared modal: countdown 3:00, status tag, poll + Socket.IO listen, cancel, download khi completed, auto-close 1.2s. Màu countdown: xanh >60s, vàng 30-60s, đỏ <30s
- `frontend/src/components/signing/SigningModal.tsx` — (cần verify thêm)

### Hooks
- `frontend/src/hooks/use-signing.tsx` — `openSign()`, `closeSign()`, `renderSignModal()`. Spam-click guard, onSuccess fire once, auto-close 1.2s

### Types
- `frontend/src/lib/signing/types.ts` — `AttachmentType`, `TxnStatus`, `ProviderCode`, `SignPayload`, `SignResponseData`, `TxnStatusData`, `SignCompletedEvent`, `SignFailedEvent`

### UI gap
- ❌ User **KHÔNG** chọn provider khi ký — hệ thống dùng provider active duy nhất
- ❌ Danh sách ký KHÔNG hiển thị provider name/code
- ⚠️ User account page chưa wire `listCertificates()` dropdown đầy đủ

---

## 5. Provider config & seed data

**`database/seed/001_required_data.sql`:**
```sql
-- SmartCA VNPT
INSERT INTO public.signing_provider_config
  (provider_code, provider_name, base_url, client_id, client_secret,
   profile_id, extra_config, is_active, created_by, updated_by)
VALUES (
  'SMARTCA_VNPT',
  'SmartCA VNPT',
  'https://gwsca.vnpt.vn',
  '',                              -- EMPTY (admin nhập)
  pgp_sym_encrypt('', v_key),      -- EMPTY
  NULL, '{}',
  FALSE,                           -- INACTIVE
  1, 1
) ON CONFLICT DO NOTHING;

-- MySign Viettel
INSERT INTO public.signing_provider_config
VALUES (
  'MYSIGN_VIETTEL',
  'MySign Viettel',
  '',                                              -- EMPTY base_url
  '',                                              -- EMPTY client_id
  pgp_sym_encrypt('placeholder_not_configured', v_key),  -- SENTINEL
  '', '{}',
  FALSE,                                           -- INACTIVE
  1, 1
) ON CONFLICT DO NOTHING;
```

---

## 6. MOCK vs REAL

### MOCK (giả lập, KHÔNG gọi API thật)
1. **`backend/src/services/signing-mock.service.ts`** (lines 20-140)
   - `signSmartCA()` → hardcoded success, signature record status='signing'
   - `verifyOTP()` → mock cert_serial=`MOCK-CERT-${Date.now()}`, cert_subject='CN=Nguyen Van A, O=UBND tinh Lao Cai'
   - `signEsignNEAC()` → 1-step, mark signed mock cert

2. **`backend/src/services/signing.service.ts`** (lines 42-48)
   ```ts
   export async function getSigningService(): Promise<ISigningService> {
     if (process.env.MOCK_EXTERNAL === 'true') {
       const mod = await import('./signing-mock.service.js');
       return mod.signingMockService;
     }
     throw new Error('Real signing service not implemented yet — set MOCK_EXTERNAL=true');
   }
   ```
   → Legacy route `/api/ky-so/sign/smart-ca` + `/esign-neac` **KHÔNG dùng được** ngoài MOCK mode.

3. **`backend/src/routes/digital-signature.ts`** (lines 155-187) — `/mock/sign`, `/mock/verify` dùng SP fake sign

### REAL (gọi provider API thật)
1. **`backend/src/routes/ky-so-sign.ts`** (lines 103-347) — Phase 11, **THẬT**
2. **`backend/src/workers/signing-poll.worker.ts`** (lines 104-300+) — Worker poll **THẬT**
3. **Provider adapters** — smartca-vnpt + mysign-viettel **THẬT**, gọi REAL API

**Kết luận:** Phase 11 routes (`/api/ky-so/sign`, `/cau-hinh`, `/tai-khoan`) đã code REAL adapter. Legacy v1.0 routes vẫn MOCK.

---

## 7. ENV Variables

```bash
# Encryption key cho provider credentials (32+ ký tự)
SIGNING_SECRET_KEY=qlvb-signing-dev-key-change-production-2026

# Worker
WORKER_ENABLED=true
WORKER_CONCURRENCY=1

# Redis (BullMQ)
REDIS_URL=redis://localhost:6379

# MinIO
MINIO_BUCKET=documents
MINIO_ENDPOINT=minio:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin

# Legacy (chỉ ảnh hưởng route /api/ky-so/sign/smart-ca)
MOCK_EXTERNAL=true
```

---

## 8. Tóm tắt trạng thái

| Hạng mục | Trạng thái |
|---|---|
| Schema database (sign_transactions, signing_provider_config, staff_signing_config) | ✅ READY |
| Stored functions (fn_sign_transaction_*, fn_attachment_can_sign, fn_attachment_finalize_sign, fn_signing_stats) | ✅ READY |
| Provider adapters (SmartCA VNPT, MySign Viettel) — interface + class skeleton | ✅ CODED |
| Routes Phase 11 (`/api/ky-so/sign`, `/cau-hinh`, `/tai-khoan`, `/danh-sach`) | ✅ REAL (không mock) |
| BullMQ worker poll status + embed signature + upload MinIO | ✅ CODED |
| Frontend admin config UI | ✅ READY |
| Frontend user account UI | ⚠️ Cert dropdown wiring incomplete |
| Frontend SignModal (countdown + Socket.IO) | ✅ READY |
| Encrypt/decrypt client_secret (pgp_sym_encrypt + SIGNING_SECRET_KEY) | ✅ READY |
| **Tích hợp THẬT với SmartCA VNPT** | ❌ Cần credentials + verify endpoint paths + verify response schema |
| **Tích hợp THẬT với MySign Viettel** | ❌ Cần credentials + verify endpoint paths + verify response schema |
| **Test E2E ký file PDF thật** | ❌ Chưa làm |
| Legacy routes `/sign/smart-ca`, `/esign-neac` | ⚠️ MOCK only — nên gỡ hoặc redirect sang Phase 11 |

**Outstanding cần xử lý khi triển khai thật:**
1. Lấy credentials sandbox + production từ VNPT + Viettel
2. Đối chiếu endpoint paths trong code adapter với tài liệu mới nhất (có thể path/field đã đổi)
3. Verify response schema (signature_base64 format, status enum)
4. Test PDF embed signature (PAdES placeholder vs LTV)
5. Cài Root CA Viettel vào trust store nếu cần verify cert chain
6. Xóa hoặc disable legacy mock routes trước khi demo cho khách
7. Wire user select provider khi ký (hiện chỉ dùng active provider)
