-- ============================================================================
-- Migration 040: Signing schema foundation (Phase 8, Plan 01)
-- Requirements: MIG-01, MIG-02
-- Depends on: 000_full_schema.sql (pgcrypto extension, staff table, edoc schema)
--
-- Creates:
--   1. public.signing_provider_config   (Admin cấp 1)
--   2. public.staff_signing_config      (User cấp 2)
--   3. edoc.sign_transactions           (Audit log)
--   + ALTER 4 attachment tables (incoming/outgoing/drafting/handling)
--   + 15 stored functions CRUD
-- ============================================================================

-- Đảm bảo pgcrypto (idempotent — migration 000 đã tạo nhưng safe guard)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- 1. public.signing_provider_config — Admin cấp 1 (provider + credentials hệ thống)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.signing_provider_config (
  id              BIGSERIAL PRIMARY KEY,
  provider_code   VARCHAR(20) NOT NULL,               -- 'SMARTCA_VNPT' | 'MYSIGN_VIETTEL'
  provider_name   VARCHAR(100) NOT NULL,              -- Hiển thị UI: 'SmartCA VNPT', 'MySign Viettel'
  base_url        VARCHAR(500) NOT NULL,              -- https://gwsca.vnpt.vn/sca/sp769/v1
  client_id       VARCHAR(200) NOT NULL,
  client_secret   BYTEA NOT NULL,                     -- Encrypted bằng pgp_sym_encrypt (plaintext không bao giờ lưu)
  profile_id      VARCHAR(200),                       -- MySign only, SmartCA nullable
  extra_config    JSONB DEFAULT '{}'::jsonb,          -- Extension point cho config riêng mỗi provider
  is_active       BOOLEAN NOT NULL DEFAULT FALSE,
  last_tested_at  TIMESTAMPTZ,                        -- Lần cuối test connection OK
  test_result     TEXT,                               -- 'OK' | error message
  created_by      INT REFERENCES public.staff(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_by      INT REFERENCES public.staff(id),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_signing_provider_config_code UNIQUE (provider_code),
  CONSTRAINT chk_provider_code CHECK (provider_code IN ('SMARTCA_VNPT', 'MYSIGN_VIETTEL'))
);

-- Partial unique index: chỉ 1 provider active tại 1 thời điểm
CREATE UNIQUE INDEX IF NOT EXISTS uq_signing_provider_config_active
  ON public.signing_provider_config (is_active)
  WHERE is_active = TRUE;

COMMENT ON TABLE public.signing_provider_config IS 'Cấu hình provider ký số cấp hệ thống (Admin). Partial unique index đảm bảo single-active.';
COMMENT ON COLUMN public.signing_provider_config.client_secret IS 'Encrypted bằng pgp_sym_encrypt(plaintext, key). Key từ env SIGNING_SECRET_KEY.';

-- ============================================================================
-- 2. public.staff_signing_config — User cấp 2 (user_id + certificate của mỗi user/provider)
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.staff_signing_config (
  staff_id            INT NOT NULL REFERENCES public.staff(id) ON DELETE CASCADE,
  provider_code       VARCHAR(20) NOT NULL,         -- Match signing_provider_config.provider_code
  user_id             VARCHAR(200) NOT NULL,        -- SĐT hoặc mã định danh user trên provider
  credential_id       VARCHAR(200),                 -- MySign only — ID certificate chọn từ list
  certificate_data    TEXT,                         -- Base64 cert (lấy về khi verify)
  certificate_subject VARCHAR(500),                 -- Extracted từ cert, hiển thị UI
  certificate_serial  VARCHAR(200),
  is_verified         BOOLEAN NOT NULL DEFAULT FALSE,
  last_verified_at    TIMESTAMPTZ,
  last_error          TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT pk_staff_signing_config PRIMARY KEY (staff_id, provider_code),
  CONSTRAINT chk_staff_signing_provider_code CHECK (provider_code IN ('SMARTCA_VNPT', 'MYSIGN_VIETTEL'))
);

CREATE INDEX IF NOT EXISTS idx_staff_signing_config_staff
  ON public.staff_signing_config (staff_id);

COMMENT ON TABLE public.staff_signing_config IS 'Cấu hình ký số cá nhân per user per provider (composite PK — user có thể có config cho cả 2 provider song song).';

-- ============================================================================
-- 3. edoc.sign_transactions — Audit log mọi giao dịch ký (pending/completed/failed/cancelled/expired)
-- ============================================================================
CREATE TABLE IF NOT EXISTS edoc.sign_transactions (
  id                  BIGSERIAL PRIMARY KEY,
  staff_id            INT NOT NULL REFERENCES public.staff(id),
  provider_code       VARCHAR(20) NOT NULL,        -- Snapshot provider lúc tạo transaction
  provider_txn_id     VARCHAR(200),                -- ID trên phía provider (trả về sau khi tạo sign request)

  -- Liên kết tới attachment đang ký (1 trong 4 loại)
  attachment_id       BIGINT NOT NULL,
  attachment_type     VARCHAR(20) NOT NULL,        -- 'incoming' | 'outgoing' | 'drafting' | 'handling'
  doc_id              BIGINT,                      -- outgoing_doc_id / drafting_doc_id / handling_doc_id / incoming_doc_id
  doc_type            VARCHAR(20),                 -- 'outgoing_doc' | 'drafting_doc' | 'handling_doc' | 'incoming_doc'

  -- Dữ liệu ký
  file_hash_sha256    VARCHAR(64),                 -- SHA256 hex của PDF byte-range (PAdES)
  signature_base64    TEXT,                        -- PKCS7 detached signature (provider trả về)
  signed_file_path    VARCHAR(1000),               -- MinIO path của file đã embed signature

  -- Trạng thái
  "status"            VARCHAR(20) NOT NULL DEFAULT 'pending',  -- quote vì status là từ khóa reserved
  error_message       TEXT,
  retry_count         INT NOT NULL DEFAULT 0,

  -- Timestamps
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  started_at          TIMESTAMPTZ,
  completed_at        TIMESTAMPTZ,
  expires_at          TIMESTAMPTZ,                 -- created_at + 3 phút (poll timeout)

  CONSTRAINT chk_sign_transaction_status CHECK ("status" IN ('pending','completed','failed','cancelled','expired')),
  CONSTRAINT chk_sign_transaction_attachment_type CHECK (attachment_type IN ('incoming','outgoing','drafting','handling')),
  CONSTRAINT chk_sign_transaction_provider_code CHECK (provider_code IN ('SMARTCA_VNPT','MYSIGN_VIETTEL'))
);

CREATE INDEX IF NOT EXISTS idx_sign_transactions_staff_status
  ON edoc.sign_transactions (staff_id, "status");
CREATE INDEX IF NOT EXISTS idx_sign_transactions_provider_txn
  ON edoc.sign_transactions (provider_code, provider_txn_id)
  WHERE provider_txn_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_sign_transactions_attachment
  ON edoc.sign_transactions (attachment_type, attachment_id);
CREATE INDEX IF NOT EXISTS idx_sign_transactions_pending
  ON edoc.sign_transactions ("status", created_at)
  WHERE "status" = 'pending';

COMMENT ON TABLE edoc.sign_transactions IS 'Audit log ký số — mọi lần ký tạo 1 record (pending → completed/failed/cancelled/expired).';
COMMENT ON COLUMN edoc.sign_transactions."status" IS 'pending → completed/failed/cancelled/expired. Ký lại = tạo transaction MỚI (giữ record cũ).';

-- ============================================================================
-- 4. ALTER 4 bảng attachment: thêm sign_provider_code + sign_transaction_id
-- ============================================================================
ALTER TABLE edoc.attachment_incoming_docs
  ADD COLUMN IF NOT EXISTS sign_provider_code VARCHAR(20),
  ADD COLUMN IF NOT EXISTS sign_transaction_id BIGINT REFERENCES edoc.sign_transactions(id) ON DELETE SET NULL;

ALTER TABLE edoc.attachment_outgoing_docs
  ADD COLUMN IF NOT EXISTS sign_provider_code VARCHAR(20),
  ADD COLUMN IF NOT EXISTS sign_transaction_id BIGINT REFERENCES edoc.sign_transactions(id) ON DELETE SET NULL;

ALTER TABLE edoc.attachment_drafting_docs
  ADD COLUMN IF NOT EXISTS sign_provider_code VARCHAR(20),
  ADD COLUMN IF NOT EXISTS sign_transaction_id BIGINT REFERENCES edoc.sign_transactions(id) ON DELETE SET NULL;

-- attachment_handling_docs (HSCV trình ký)
ALTER TABLE edoc.attachment_handling_docs
  ADD COLUMN IF NOT EXISTS sign_provider_code VARCHAR(20),
  ADD COLUMN IF NOT EXISTS sign_transaction_id BIGINT REFERENCES edoc.sign_transactions(id) ON DELETE SET NULL;

COMMENT ON COLUMN edoc.attachment_outgoing_docs.sign_provider_code IS 'Provider đã dùng để ký (snapshot, không đổi khi admin switch provider).';

DO $$ BEGIN
  RAISE NOTICE 'Migration 040 Part 1: Schema (3 bảng mới + ALTER 4 attachment tables) — OK';
END $$;
