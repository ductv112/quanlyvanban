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

-- ============================================================================
-- STORED FUNCTIONS — signing_provider_config (5 functions)
-- ============================================================================

-- GET LIST — trả mọi provider (Admin xem tất cả, KHÔNG trả client_secret)
CREATE OR REPLACE FUNCTION public.fn_signing_provider_config_list()
RETURNS TABLE (
  id BIGINT,
  provider_code VARCHAR,
  provider_name VARCHAR,
  base_url VARCHAR,
  client_id VARCHAR,
  profile_id VARCHAR,
  extra_config JSONB,
  is_active BOOLEAN,
  last_tested_at TIMESTAMPTZ,
  test_result TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql STABLE AS $$
BEGIN
  RETURN QUERY
    SELECT c.id, c.provider_code, c.provider_name, c.base_url, c.client_id,
           c.profile_id, c.extra_config, c.is_active, c.last_tested_at, c.test_result,
           c.created_at, c.updated_at
    FROM public.signing_provider_config c
    ORDER BY c.is_active DESC, c.provider_code ASC;
END;
$$;

-- GET BY CODE (full — có client_secret BYTEA cho backend decrypt phía Node)
CREATE OR REPLACE FUNCTION public.fn_signing_provider_config_get_by_code(
  p_provider_code VARCHAR
)
RETURNS TABLE (
  id BIGINT,
  provider_code VARCHAR,
  provider_name VARCHAR,
  base_url VARCHAR,
  client_id VARCHAR,
  client_secret BYTEA,
  profile_id VARCHAR,
  extra_config JSONB,
  is_active BOOLEAN,
  last_tested_at TIMESTAMPTZ,
  test_result TEXT
)
LANGUAGE plpgsql STABLE AS $$
BEGIN
  RETURN QUERY
    SELECT c.id, c.provider_code, c.provider_name, c.base_url, c.client_id,
           c.client_secret, c.profile_id, c.extra_config, c.is_active,
           c.last_tested_at, c.test_result
    FROM public.signing_provider_config c
    WHERE c.provider_code = p_provider_code;
END;
$$;

-- GET ACTIVE — lấy provider đang active duy nhất
CREATE OR REPLACE FUNCTION public.fn_signing_provider_config_get_active()
RETURNS TABLE (
  id BIGINT,
  provider_code VARCHAR,
  provider_name VARCHAR,
  base_url VARCHAR,
  client_id VARCHAR,
  client_secret BYTEA,
  profile_id VARCHAR,
  extra_config JSONB
)
LANGUAGE plpgsql STABLE AS $$
BEGIN
  RETURN QUERY
    SELECT c.id, c.provider_code, c.provider_name, c.base_url, c.client_id,
           c.client_secret, c.profile_id, c.extra_config
    FROM public.signing_provider_config c
    WHERE c.is_active = TRUE
    LIMIT 1;
END;
$$;

-- UPSERT (insert nếu chưa có, update nếu có) — cập nhật toàn bộ fields (trừ is_active)
-- Note: client_secret_bytea đã encrypted từ Node-side bằng pgp_sym_encrypt
CREATE OR REPLACE FUNCTION public.fn_signing_provider_config_upsert(
  p_provider_code     VARCHAR,
  p_provider_name     VARCHAR,
  p_base_url          VARCHAR,
  p_client_id         VARCHAR,
  p_client_secret     BYTEA,
  p_profile_id        VARCHAR,
  p_extra_config      JSONB,
  p_last_tested_at    TIMESTAMPTZ,
  p_test_result       TEXT,
  p_updated_by        INT
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql AS $$
DECLARE v_id BIGINT;
BEGIN
  INSERT INTO public.signing_provider_config (
    provider_code, provider_name, base_url, client_id, client_secret,
    profile_id, extra_config, last_tested_at, test_result, created_by, updated_by
  )
  VALUES (
    p_provider_code, p_provider_name, p_base_url, p_client_id, p_client_secret,
    p_profile_id, COALESCE(p_extra_config, '{}'::jsonb), p_last_tested_at, p_test_result, p_updated_by, p_updated_by
  )
  ON CONFLICT (provider_code) DO UPDATE SET
    provider_name   = EXCLUDED.provider_name,
    base_url        = EXCLUDED.base_url,
    client_id       = EXCLUDED.client_id,
    client_secret   = EXCLUDED.client_secret,
    profile_id      = EXCLUDED.profile_id,
    extra_config    = EXCLUDED.extra_config,
    last_tested_at  = EXCLUDED.last_tested_at,
    test_result     = EXCLUDED.test_result,
    updated_by      = EXCLUDED.updated_by,
    updated_at      = NOW()
  RETURNING public.signing_provider_config.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Lưu cấu hình provider thành công'::TEXT, v_id;
END;
$$;

-- SET ACTIVE — atomic swap: deactivate tất cả provider, activate provider được chọn
CREATE OR REPLACE FUNCTION public.fn_signing_provider_config_set_active(
  p_provider_code VARCHAR,
  p_updated_by    INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql AS $$
DECLARE v_exists BOOLEAN;
BEGIN
  SELECT EXISTS(SELECT 1 FROM public.signing_provider_config WHERE provider_code = p_provider_code)
    INTO v_exists;
  IF NOT v_exists THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy provider'::TEXT; RETURN;
  END IF;

  -- Deactivate all (respects partial unique index)
  UPDATE public.signing_provider_config
    SET is_active = FALSE, updated_at = NOW(), updated_by = p_updated_by
    WHERE is_active = TRUE;

  -- Activate chosen
  UPDATE public.signing_provider_config
    SET is_active = TRUE, updated_at = NOW(), updated_by = p_updated_by
    WHERE provider_code = p_provider_code;

  RETURN QUERY SELECT TRUE, 'Kích hoạt provider thành công'::TEXT;
END;
$$;

-- ============================================================================
-- STORED FUNCTIONS — staff_signing_config (4 functions)
-- ============================================================================

-- GET LIST BY STAFF
CREATE OR REPLACE FUNCTION public.fn_staff_signing_config_list_by_staff(
  p_staff_id INT
)
RETURNS TABLE (
  staff_id INT,
  provider_code VARCHAR,
  user_id VARCHAR,
  credential_id VARCHAR,
  certificate_subject VARCHAR,
  certificate_serial VARCHAR,
  is_verified BOOLEAN,
  last_verified_at TIMESTAMPTZ,
  last_error TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql STABLE AS $$
BEGIN
  RETURN QUERY
    SELECT c.staff_id, c.provider_code, c.user_id, c.credential_id,
           c.certificate_subject, c.certificate_serial, c.is_verified,
           c.last_verified_at, c.last_error, c.created_at, c.updated_at
    FROM public.staff_signing_config c
    WHERE c.staff_id = p_staff_id
    ORDER BY c.provider_code;
END;
$$;

-- GET BY STAFF + PROVIDER (cho sign flow)
CREATE OR REPLACE FUNCTION public.fn_staff_signing_config_get(
  p_staff_id      INT,
  p_provider_code VARCHAR
)
RETURNS TABLE (
  staff_id INT,
  provider_code VARCHAR,
  user_id VARCHAR,
  credential_id VARCHAR,
  certificate_data TEXT,
  certificate_subject VARCHAR,
  certificate_serial VARCHAR,
  is_verified BOOLEAN,
  last_verified_at TIMESTAMPTZ
)
LANGUAGE plpgsql STABLE AS $$
BEGIN
  RETURN QUERY
    SELECT c.staff_id, c.provider_code, c.user_id, c.credential_id,
           c.certificate_data, c.certificate_subject, c.certificate_serial,
           c.is_verified, c.last_verified_at
    FROM public.staff_signing_config c
    WHERE c.staff_id = p_staff_id AND c.provider_code = p_provider_code;
END;
$$;

-- UPSERT user config
CREATE OR REPLACE FUNCTION public.fn_staff_signing_config_upsert(
  p_staff_id            INT,
  p_provider_code       VARCHAR,
  p_user_id             VARCHAR,
  p_credential_id       VARCHAR,
  p_certificate_data    TEXT,
  p_certificate_subject VARCHAR,
  p_certificate_serial  VARCHAR,
  p_is_verified         BOOLEAN,
  p_last_verified_at    TIMESTAMPTZ,
  p_last_error          TEXT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO public.staff_signing_config (
    staff_id, provider_code, user_id, credential_id, certificate_data,
    certificate_subject, certificate_serial, is_verified, last_verified_at, last_error
  )
  VALUES (
    p_staff_id, p_provider_code, p_user_id, p_credential_id, p_certificate_data,
    p_certificate_subject, p_certificate_serial, COALESCE(p_is_verified, FALSE),
    p_last_verified_at, p_last_error
  )
  ON CONFLICT (staff_id, provider_code) DO UPDATE SET
    user_id             = EXCLUDED.user_id,
    credential_id       = EXCLUDED.credential_id,
    certificate_data    = COALESCE(EXCLUDED.certificate_data, public.staff_signing_config.certificate_data),
    certificate_subject = COALESCE(EXCLUDED.certificate_subject, public.staff_signing_config.certificate_subject),
    certificate_serial  = COALESCE(EXCLUDED.certificate_serial, public.staff_signing_config.certificate_serial),
    is_verified         = EXCLUDED.is_verified,
    last_verified_at    = EXCLUDED.last_verified_at,
    last_error          = EXCLUDED.last_error,
    updated_at          = NOW();

  RETURN QUERY SELECT TRUE, 'Lưu cấu hình ký số cá nhân thành công'::TEXT;
END;
$$;

-- DELETE config (khi user muốn xóa cấu hình)
CREATE OR REPLACE FUNCTION public.fn_staff_signing_config_delete(
  p_staff_id      INT,
  p_provider_code VARCHAR
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM public.staff_signing_config
    WHERE staff_id = p_staff_id AND provider_code = p_provider_code;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy cấu hình'::TEXT; RETURN;
  END IF;
  RETURN QUERY SELECT TRUE, 'Xóa cấu hình thành công'::TEXT;
END;
$$;

-- ============================================================================
-- STORED FUNCTIONS — sign_transactions (6 functions)
-- ============================================================================

-- CREATE transaction (status='pending', expires_at = now + 3 phút)
CREATE OR REPLACE FUNCTION edoc.fn_sign_transaction_create(
  p_staff_id         INT,
  p_provider_code    VARCHAR,
  p_attachment_id    BIGINT,
  p_attachment_type  VARCHAR,
  p_doc_id           BIGINT,
  p_doc_type         VARCHAR,
  p_file_hash_sha256 VARCHAR
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql AS $$
DECLARE v_id BIGINT;
BEGIN
  IF p_attachment_type NOT IN ('incoming','outgoing','drafting','handling') THEN
    RETURN QUERY SELECT FALSE, 'Loại file đính kèm không hợp lệ'::TEXT, 0::BIGINT; RETURN;
  END IF;

  INSERT INTO edoc.sign_transactions (
    staff_id, provider_code, attachment_id, attachment_type, doc_id, doc_type,
    file_hash_sha256, "status", expires_at
  )
  VALUES (
    p_staff_id, p_provider_code, p_attachment_id, p_attachment_type, p_doc_id, p_doc_type,
    p_file_hash_sha256, 'pending', NOW() + INTERVAL '3 minutes'
  )
  RETURNING edoc.sign_transactions.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tạo giao dịch ký số thành công'::TEXT, v_id;
END;
$$;

-- SET provider_txn_id (sau khi call provider API thành công)
CREATE OR REPLACE FUNCTION edoc.fn_sign_transaction_set_provider_txn(
  p_id              BIGINT,
  p_provider_txn_id VARCHAR
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE edoc.sign_transactions
    SET provider_txn_id = p_provider_txn_id, started_at = NOW()
    WHERE id = p_id AND "status" = 'pending';
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy giao dịch pending'::TEXT; RETURN;
  END IF;
  RETURN QUERY SELECT TRUE, 'Cập nhật provider_txn_id thành công'::TEXT;
END;
$$;

-- COMPLETE transaction (signature_base64 + signed_file_path)
CREATE OR REPLACE FUNCTION edoc.fn_sign_transaction_complete(
  p_id               BIGINT,
  p_signature_base64 TEXT,
  p_signed_file_path VARCHAR
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE edoc.sign_transactions
    SET "status" = 'completed',
        signature_base64 = p_signature_base64,
        signed_file_path = p_signed_file_path,
        completed_at = NOW()
    WHERE id = p_id AND "status" = 'pending';
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy giao dịch pending'::TEXT; RETURN;
  END IF;
  RETURN QUERY SELECT TRUE, 'Hoàn tất giao dịch ký số'::TEXT;
END;
$$;

-- FAIL / EXPIRE / CANCEL (gộp 1 SP, tham số p_status)
CREATE OR REPLACE FUNCTION edoc.fn_sign_transaction_update_status(
  p_id            BIGINT,
  p_status        VARCHAR,     -- 'failed' | 'expired' | 'cancelled'
  p_error_message TEXT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql AS $$
BEGIN
  IF p_status NOT IN ('failed','expired','cancelled') THEN
    RETURN QUERY SELECT FALSE, 'Trạng thái không hợp lệ'::TEXT; RETURN;
  END IF;
  UPDATE edoc.sign_transactions
    SET "status" = p_status,
        error_message = p_error_message,
        completed_at = NOW()
    WHERE id = p_id AND "status" = 'pending';
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy giao dịch pending'::TEXT; RETURN;
  END IF;
  RETURN QUERY SELECT TRUE, 'Cập nhật trạng thái thành công'::TEXT;
END;
$$;

-- INCREMENT retry_count (worker mỗi lần poll failed retry)
-- Note: RETURNS TABLE dùng column name khác table column để tránh PL/pgSQL ambiguity
-- DROP IF EXISTS để tránh "cannot change return type of existing function" khi migrate lại
DROP FUNCTION IF EXISTS edoc.fn_sign_transaction_increment_retry(BIGINT);
CREATE OR REPLACE FUNCTION edoc.fn_sign_transaction_increment_retry(
  p_id BIGINT
)
RETURNS TABLE (success BOOLEAN, new_retry_count INT)
LANGUAGE plpgsql AS $$
DECLARE v_count INT;
BEGIN
  UPDATE edoc.sign_transactions AS t
    SET retry_count = t.retry_count + 1
    WHERE t.id = p_id AND t."status" = 'pending'
    RETURNING t.retry_count INTO v_count;
  IF v_count IS NULL THEN
    RETURN QUERY SELECT FALSE, 0; RETURN;
  END IF;
  RETURN QUERY SELECT TRUE, v_count;
END;
$$;

-- GET BY ID (worker đọc full context của transaction)
CREATE OR REPLACE FUNCTION edoc.fn_sign_transaction_get_by_id(
  p_id BIGINT
)
RETURNS TABLE (
  id BIGINT,
  staff_id INT,
  provider_code VARCHAR,
  provider_txn_id VARCHAR,
  attachment_id BIGINT,
  attachment_type VARCHAR,
  doc_id BIGINT,
  doc_type VARCHAR,
  file_hash_sha256 VARCHAR,
  signature_base64 TEXT,
  signed_file_path VARCHAR,
  "status" VARCHAR,
  error_message TEXT,
  retry_count INT,
  created_at TIMESTAMPTZ,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ
)
LANGUAGE plpgsql STABLE AS $$
BEGIN
  RETURN QUERY
    SELECT t.id, t.staff_id, t.provider_code, t.provider_txn_id,
           t.attachment_id, t.attachment_type, t.doc_id, t.doc_type,
           t.file_hash_sha256, t.signature_base64, t.signed_file_path,
           t."status", t.error_message, t.retry_count,
           t.created_at, t.started_at, t.completed_at, t.expires_at
    FROM edoc.sign_transactions t
    WHERE t.id = p_id;
END;
$$;

DO $$ BEGIN
  RAISE NOTICE 'Migration 040 Part 2: 15 stored functions (provider_config + staff_config + sign_transactions) — OK';
END $$;
