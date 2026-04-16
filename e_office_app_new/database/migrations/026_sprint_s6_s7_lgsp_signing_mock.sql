-- ============================================================================
-- Migration 026: S6 (LGSP mock) + S7 (Ký số mock)
-- Giả lập — khi có SDK/API thật chỉ cần swap implementation
-- ============================================================================

BEGIN;

-- ============================================================================
-- S6: LGSP CONFIG TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS edoc.lgsp_config (
  id                  SERIAL PRIMARY KEY,
  unit_id             INT REFERENCES departments(id),
  endpoint_url        VARCHAR(500) NOT NULL DEFAULT 'https://lgsp.laocai.gov.vn/api',
  org_code            VARCHAR(100) NOT NULL,
  username            VARCHAR(100),
  password_encrypted  VARCHAR(200),
  polling_interval_sec INT DEFAULT 300,
  is_active           BOOLEAN DEFAULT true,
  last_sync_at        TIMESTAMPTZ,
  created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- SP: Mock nhận VB từ LGSP (giả lập tạo inter_incoming_doc)
CREATE OR REPLACE FUNCTION edoc.fn_lgsp_mock_receive(
  p_unit_id       INT,
  p_notation      VARCHAR,
  p_abstract      TEXT,
  p_publish_unit  VARCHAR,
  p_signer        VARCHAR,
  p_doc_type_id   INT DEFAULT NULL,
  p_created_by    INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql AS $$
DECLARE v_id BIGINT;
BEGIN
  INSERT INTO edoc.inter_incoming_docs (
    unit_id, notation, abstract, publish_unit, signer,
    doc_type_id, source_system, status, created_by
  ) VALUES (
    p_unit_id, p_notation, p_abstract, p_publish_unit, p_signer,
    p_doc_type_id, 'LGSP_MOCK', 'pending', p_created_by
  )
  RETURNING inter_incoming_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, ('[MOCK] Đã nhận VB liên thông #' || v_id)::TEXT, v_id;
END;
$$;

-- SP: Mock gửi VB đi qua LGSP (giả lập thành công)
CREATE OR REPLACE FUNCTION edoc.fn_lgsp_mock_send(
  p_doc_id        BIGINT,
  p_doc_type      VARCHAR,  -- 'incoming' | 'outgoing'
  p_dest_org_code VARCHAR,
  p_dest_org_name VARCHAR,
  p_sent_by       INT
)
RETURNS TABLE (success BOOLEAN, message TEXT, tracking_id BIGINT)
LANGUAGE plpgsql AS $$
DECLARE v_id BIGINT;
BEGIN
  INSERT INTO edoc.lgsp_tracking (
    outgoing_doc_id, incoming_doc_id, direction, dest_org_code, dest_org_name,
    status, sent_at, created_by
  ) VALUES (
    CASE WHEN p_doc_type = 'outgoing' THEN p_doc_id ELSE NULL END,
    CASE WHEN p_doc_type = 'incoming' THEN p_doc_id ELSE NULL END,
    'send', p_dest_org_code, p_dest_org_name,
    'success', NOW(), p_sent_by  -- Mock: luôn success
  )
  RETURNING edoc.lgsp_tracking.id INTO v_id;

  RETURN QUERY SELECT TRUE, ('[MOCK] Gửi liên thông thành công → ' || p_dest_org_name)::TEXT, v_id;
END;
$$;

-- ============================================================================
-- S7: KÝ SỐ — Thêm cột cho 3 bảng attachment
-- ============================================================================

ALTER TABLE edoc.attachment_incoming_docs ADD COLUMN IF NOT EXISTS is_ca BOOLEAN DEFAULT false;
ALTER TABLE edoc.attachment_incoming_docs ADD COLUMN IF NOT EXISTS ca_date TIMESTAMPTZ;
ALTER TABLE edoc.attachment_incoming_docs ADD COLUMN IF NOT EXISTS signed_file_path VARCHAR(1000);

ALTER TABLE edoc.attachment_outgoing_docs ADD COLUMN IF NOT EXISTS is_ca BOOLEAN DEFAULT false;
ALTER TABLE edoc.attachment_outgoing_docs ADD COLUMN IF NOT EXISTS ca_date TIMESTAMPTZ;
ALTER TABLE edoc.attachment_outgoing_docs ADD COLUMN IF NOT EXISTS signed_file_path VARCHAR(1000);

ALTER TABLE edoc.attachment_drafting_docs ADD COLUMN IF NOT EXISTS is_ca BOOLEAN DEFAULT false;
ALTER TABLE edoc.attachment_drafting_docs ADD COLUMN IF NOT EXISTS ca_date TIMESTAMPTZ;
ALTER TABLE edoc.attachment_drafting_docs ADD COLUMN IF NOT EXISTS signed_file_path VARCHAR(1000);

-- SP: Mock ký số (cập nhật attachment — giả lập ký thành công)
CREATE OR REPLACE FUNCTION edoc.fn_attachment_mock_sign(
  p_attachment_id   BIGINT,
  p_attachment_type VARCHAR,  -- 'incoming' | 'outgoing' | 'drafting'
  p_signed_by       INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql AS $$
BEGIN
  IF p_attachment_type = 'incoming' THEN
    UPDATE edoc.attachment_incoming_docs SET is_ca = true, ca_date = NOW(), signed_file_path = file_path WHERE id = p_attachment_id;
  ELSIF p_attachment_type = 'outgoing' THEN
    UPDATE edoc.attachment_outgoing_docs SET is_ca = true, ca_date = NOW(), signed_file_path = file_path WHERE id = p_attachment_id;
  ELSIF p_attachment_type = 'drafting' THEN
    UPDATE edoc.attachment_drafting_docs SET is_ca = true, ca_date = NOW(), signed_file_path = file_path WHERE id = p_attachment_id;
  ELSE
    RETURN QUERY SELECT FALSE, 'Loại không hợp lệ'::TEXT; RETURN;
  END IF;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy file đính kèm'::TEXT; RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, '[MOCK] Ký số thành công'::TEXT;
END;
$$;

-- SP: Xác thực chữ ký (mock — luôn trả valid)
CREATE OR REPLACE FUNCTION edoc.fn_attachment_mock_verify(
  p_attachment_id   BIGINT,
  p_attachment_type VARCHAR
)
RETURNS TABLE (is_valid BOOLEAN, signer_name VARCHAR, sign_date TIMESTAMPTZ, message TEXT)
LANGUAGE plpgsql AS $$
DECLARE v_ca BOOLEAN; v_date TIMESTAMPTZ;
BEGIN
  IF p_attachment_type = 'incoming' THEN
    SELECT is_ca, ca_date INTO v_ca, v_date FROM edoc.attachment_incoming_docs WHERE id = p_attachment_id;
  ELSIF p_attachment_type = 'outgoing' THEN
    SELECT is_ca, ca_date INTO v_ca, v_date FROM edoc.attachment_outgoing_docs WHERE id = p_attachment_id;
  ELSIF p_attachment_type = 'drafting' THEN
    SELECT is_ca, ca_date INTO v_ca, v_date FROM edoc.attachment_drafting_docs WHERE id = p_attachment_id;
  END IF;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, ''::VARCHAR, NULL::TIMESTAMPTZ, 'Không tìm thấy file'::TEXT; RETURN;
  END IF;

  IF COALESCE(v_ca, false) THEN
    RETURN QUERY SELECT TRUE, '[MOCK] Người ký hợp lệ'::VARCHAR, v_date, 'Chữ ký số hợp lệ (MOCK)'::TEXT;
  ELSE
    RETURN QUERY SELECT FALSE, ''::VARCHAR, NULL::TIMESTAMPTZ, 'File chưa được ký số'::TEXT;
  END IF;
END;
$$;

DO $$ BEGIN
  RAISE NOTICE '✅ Migration 026: S6 + S7 (LGSP mock + Ký số mock)';
  RAISE NOTICE '   S6: lgsp_config table, fn_lgsp_mock_receive, fn_lgsp_mock_send';
  RAISE NOTICE '   S7: attachment +is_ca/ca_date/signed_file_path, fn_attachment_mock_sign/verify';
END $$;

COMMIT;
