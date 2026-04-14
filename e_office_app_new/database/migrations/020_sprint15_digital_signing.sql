-- ================================================================
-- MIGRATION 020: Sprint 15 — Ky so dien tu (Digital Signing)
-- Schema: edoc
-- Tables: edoc.digital_signatures
-- Functions: 4 stored functions
-- ================================================================

-- ==========================================
-- 1. BANG CHU KY SO (digital_signatures)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.digital_signatures (
  id                  BIGSERIAL PRIMARY KEY,
  doc_id              BIGINT NOT NULL,
  doc_type            VARCHAR(20) NOT NULL CHECK(doc_type IN ('outgoing', 'drafting')),
  staff_id            INT NOT NULL REFERENCES public.staff(id),
  sign_method         VARCHAR(30) NOT NULL CHECK(sign_method IN ('smart_ca', 'esign_neac', 'usb_token')),
  certificate_serial  VARCHAR(200),
  certificate_subject VARCHAR(500),
  certificate_issuer  VARCHAR(500),
  signed_file_path    VARCHAR(1000),
  original_file_path  VARCHAR(1000),
  sign_status         VARCHAR(20) NOT NULL DEFAULT 'pending'
                      CHECK(sign_status IN ('pending', 'signing', 'signed', 'error', 'rejected')),
  error_message       TEXT,
  signed_at           TIMESTAMPTZ,
  created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_digsig_doc ON edoc.digital_signatures(doc_id, doc_type);
CREATE INDEX IF NOT EXISTS idx_digsig_staff ON edoc.digital_signatures(staff_id);
CREATE INDEX IF NOT EXISTS idx_digsig_status ON edoc.digital_signatures(sign_status);

COMMENT ON TABLE edoc.digital_signatures IS 'Chu ky so tren van ban — luu thong tin ky SmartCA, EsignNEAC, USB Token';

-- ==========================================
-- 2. FN: TAO YEU CAU KY SO
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_digital_signature_create(
  p_doc_id             BIGINT,
  p_doc_type           VARCHAR,
  p_staff_id           INT,
  p_sign_method        VARCHAR,
  p_original_file_path VARCHAR DEFAULT NULL
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT,
  id      BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
  v_id BIGINT;
BEGIN
  -- Validate doc_type
  IF p_doc_type NOT IN ('outgoing', 'drafting') THEN
    RETURN QUERY SELECT false, 'Loai van ban khong hop le'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  -- Validate sign_method
  IF p_sign_method NOT IN ('smart_ca', 'esign_neac', 'usb_token') THEN
    RETURN QUERY SELECT false, 'Phuong thuc ky khong hop le'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.digital_signatures (
    doc_id, doc_type, staff_id, sign_method, original_file_path
  )
  VALUES (
    p_doc_id, p_doc_type, p_staff_id, p_sign_method, p_original_file_path
  )
  RETURNING edoc.digital_signatures.id INTO v_id;

  RETURN QUERY SELECT true, 'Tao yeu cau ky so thanh cong'::TEXT, v_id;
END;
$$;

-- ==========================================
-- 3. FN: CAP NHAT TRANG THAI KY SO
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_digital_signature_update_status(
  p_id                  BIGINT,
  p_sign_status         VARCHAR,
  p_certificate_serial  VARCHAR DEFAULT NULL,
  p_certificate_subject VARCHAR DEFAULT NULL,
  p_certificate_issuer  VARCHAR DEFAULT NULL,
  p_signed_file_path    VARCHAR DEFAULT NULL,
  p_error_message       TEXT DEFAULT NULL
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT
)
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE edoc.digital_signatures
  SET sign_status         = p_sign_status,
      certificate_serial  = COALESCE(p_certificate_serial, certificate_serial),
      certificate_subject = COALESCE(p_certificate_subject, certificate_subject),
      certificate_issuer  = COALESCE(p_certificate_issuer, certificate_issuer),
      signed_file_path    = COALESCE(p_signed_file_path, signed_file_path),
      error_message       = p_error_message,
      signed_at           = CASE WHEN p_sign_status = 'signed' THEN NOW() ELSE signed_at END
  WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Khong tim thay ban ghi ky so'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cap nhat trang thai ky so thanh cong'::TEXT;
END;
$$;

-- ==========================================
-- 4. FN: LAY CHU KY SO THEO VAN BAN
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_digital_signature_get_by_doc(
  p_doc_id   BIGINT,
  p_doc_type VARCHAR
)
RETURNS TABLE (
  id                  BIGINT,
  doc_id              BIGINT,
  doc_type            VARCHAR,
  staff_id            INT,
  staff_name          VARCHAR,
  sign_method         VARCHAR,
  certificate_serial  VARCHAR,
  certificate_subject VARCHAR,
  certificate_issuer  VARCHAR,
  signed_file_path    VARCHAR,
  original_file_path  VARCHAR,
  sign_status         VARCHAR,
  error_message       TEXT,
  signed_at           TIMESTAMPTZ,
  created_at          TIMESTAMPTZ
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    ds.id,
    ds.doc_id,
    ds.doc_type,
    ds.staff_id,
    s.full_name::VARCHAR AS staff_name,
    ds.sign_method,
    ds.certificate_serial,
    ds.certificate_subject,
    ds.certificate_issuer,
    ds.signed_file_path,
    ds.original_file_path,
    ds.sign_status,
    ds.error_message,
    ds.signed_at,
    ds.created_at
  FROM edoc.digital_signatures ds
  JOIN public.staff s ON s.id = ds.staff_id
  WHERE ds.doc_id = p_doc_id
    AND ds.doc_type = p_doc_type
  ORDER BY ds.created_at DESC;
END;
$$;

-- ==========================================
-- 5. FN: LAY CHU KY SO THEO ID
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_digital_signature_get_by_id(
  p_id BIGINT
)
RETURNS TABLE (
  id                  BIGINT,
  doc_id              BIGINT,
  doc_type            VARCHAR,
  staff_id            INT,
  staff_name          VARCHAR,
  sign_method         VARCHAR,
  certificate_serial  VARCHAR,
  certificate_subject VARCHAR,
  certificate_issuer  VARCHAR,
  signed_file_path    VARCHAR,
  original_file_path  VARCHAR,
  sign_status         VARCHAR,
  error_message       TEXT,
  signed_at           TIMESTAMPTZ,
  created_at          TIMESTAMPTZ
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    ds.id,
    ds.doc_id,
    ds.doc_type,
    ds.staff_id,
    s.full_name::VARCHAR AS staff_name,
    ds.sign_method,
    ds.certificate_serial,
    ds.certificate_subject,
    ds.certificate_issuer,
    ds.signed_file_path,
    ds.original_file_path,
    ds.sign_status,
    ds.error_message,
    ds.signed_at,
    ds.created_at
  FROM edoc.digital_signatures ds
  JOIN public.staff s ON s.id = ds.staff_id
  WHERE ds.id = p_id;
END;
$$;
