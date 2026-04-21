-- ============================================================================
-- Migration 045: Sign flow attachment helpers (Phase 11, Plan 01)
-- Requirements: SIGN-03, SIGN-08, ASYNC-05
-- Depends on: 040_signing_schema.sql (edoc.sign_transactions + attachment ALTER sign_*)
--
-- Creates:
--   Part 1: ALTER edoc.attachment_handling_docs — thêm is_ca / ca_date / signed_file_path
--   Part 2: edoc.fn_attachment_finalize_sign    — worker call sau khi embed signature + upload MinIO
--   Part 3: edoc.fn_attachment_can_sign         — permission check TRƯỚC khi enqueue sign job
--   Part 4: edoc.fn_sign_transaction_list_by_staff  — list 3 tab (pending/completed/failed)
--   Part 5: edoc.fn_sign_transaction_count_by_staff — badge count cho tab UI
-- ============================================================================

-- ============================================================================
-- Part 1: ALTER edoc.attachment_handling_docs (bổ sung 3 cột ký số)
-- ============================================================================
-- 3 bảng attachment khác (incoming/outgoing/drafting) đã có is_ca/ca_date/signed_file_path
-- từ migration 026 (trong 000_full_schema). attachment_handling_docs tạo sau nên thiếu.
ALTER TABLE edoc.attachment_handling_docs
  ADD COLUMN IF NOT EXISTS is_ca BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS ca_date TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS signed_file_path VARCHAR(1000);

COMMENT ON COLUMN edoc.attachment_handling_docs.is_ca IS 'TRUE sau khi ký số thành công (Phase 11).';
COMMENT ON COLUMN edoc.attachment_handling_docs.ca_date IS 'Thời điểm ký số hoàn tất.';
COMMENT ON COLUMN edoc.attachment_handling_docs.signed_file_path IS 'MinIO path của file đã embed signature (Phase 11).';

DO $$ BEGIN
  RAISE NOTICE 'Migration 045 Part 1: ALTER attachment_handling_docs (+ is_ca/ca_date/signed_file_path) — OK';
END $$;

-- ============================================================================
-- Part 2: edoc.fn_attachment_finalize_sign
-- Worker call SAU KHI embed signature + upload MinIO thành công.
-- Update 1 trong 4 bảng attachment_* theo attachment_type.
-- ============================================================================
CREATE OR REPLACE FUNCTION edoc.fn_attachment_finalize_sign(
  p_attachment_id       BIGINT,
  p_attachment_type     VARCHAR,
  p_signed_file_path    VARCHAR,
  p_sign_provider_code  VARCHAR,
  p_sign_transaction_id BIGINT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql AS $$
DECLARE v_rows INT := 0;
BEGIN
  IF p_attachment_type = 'outgoing' THEN
    UPDATE edoc.attachment_outgoing_docs
      SET is_ca = TRUE,
          ca_date = NOW(),
          signed_file_path = p_signed_file_path,
          sign_provider_code = p_sign_provider_code,
          sign_transaction_id = p_sign_transaction_id
      WHERE id = p_attachment_id;
    GET DIAGNOSTICS v_rows = ROW_COUNT;
  ELSIF p_attachment_type = 'drafting' THEN
    UPDATE edoc.attachment_drafting_docs
      SET is_ca = TRUE,
          ca_date = NOW(),
          signed_file_path = p_signed_file_path,
          sign_provider_code = p_sign_provider_code,
          sign_transaction_id = p_sign_transaction_id
      WHERE id = p_attachment_id;
    GET DIAGNOSTICS v_rows = ROW_COUNT;
  ELSIF p_attachment_type = 'handling' THEN
    UPDATE edoc.attachment_handling_docs
      SET is_ca = TRUE,
          ca_date = NOW(),
          signed_file_path = p_signed_file_path,
          sign_provider_code = p_sign_provider_code,
          sign_transaction_id = p_sign_transaction_id
      WHERE id = p_attachment_id;
    GET DIAGNOSTICS v_rows = ROW_COUNT;
  ELSIF p_attachment_type = 'incoming' THEN
    UPDATE edoc.attachment_incoming_docs
      SET is_ca = TRUE,
          ca_date = NOW(),
          signed_file_path = p_signed_file_path,
          sign_provider_code = p_sign_provider_code,
          sign_transaction_id = p_sign_transaction_id
      WHERE id = p_attachment_id;
    GET DIAGNOSTICS v_rows = ROW_COUNT;
  ELSE
    RETURN QUERY SELECT FALSE, 'Loại file đính kèm không hợp lệ'::TEXT;
    RETURN;
  END IF;

  IF v_rows = 0 THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy file đính kèm'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, 'Ký số thành công'::TEXT;
END;
$$;

COMMENT ON FUNCTION edoc.fn_attachment_finalize_sign IS
  'Phase 11 — finalize attachment sau khi worker ký số + upload MinIO OK. Update is_ca/ca_date/signed_file_path/sign_provider_code/sign_transaction_id cho 1 trong 4 bảng attachment_*.';

-- ============================================================================
-- Part 3: edoc.fn_attachment_can_sign
-- Permission check TRƯỚC khi enqueue sign job. Route layer gọi SP này với
-- staff_id từ JWT, KHÔNG bao giờ từ body (mitigate T-11-01 Tampering).
-- ============================================================================
CREATE OR REPLACE FUNCTION edoc.fn_attachment_can_sign(
  p_attachment_id   BIGINT,
  p_attachment_type VARCHAR,
  p_staff_id        INT
)
RETURNS TABLE (
  can_sign  BOOLEAN,
  reason    TEXT,
  file_path VARCHAR,
  file_name VARCHAR
)
LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_is_ca         BOOLEAN;
  v_file_path     VARCHAR(1000);
  v_file_name     VARCHAR(500);
  v_doc_id        BIGINT;
  v_signer_name   VARCHAR(200);
  v_signer_int    INT;
  v_approver_name VARCHAR(200);
  v_created_by    INT;
  v_staff_name    VARCHAR(100);
  v_is_admin      BOOLEAN;
BEGIN
  -- Lấy staff info (full_name + admin check 1 lần)
  SELECT s.full_name,
         EXISTS (
           SELECT 1
           FROM public.role_of_staff ros
           JOIN public.roles r ON r.id = ros.role_id
           WHERE ros.staff_id = p_staff_id
             AND r.name = 'Quản trị hệ thống'
         ) OR COALESCE(s.is_admin, FALSE)
    INTO v_staff_name, v_is_admin
    FROM public.staff s
    WHERE s.id = p_staff_id;

  IF v_staff_name IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy người dùng'::TEXT,
                         NULL::VARCHAR(1000), NULL::VARCHAR(500);
    RETURN;
  END IF;

  -- Incoming: không được ký (VB đến là input, không phát sinh chữ ký số)
  IF p_attachment_type = 'incoming' THEN
    RETURN QUERY SELECT FALSE, 'Không được ký số văn bản đến'::TEXT,
                         NULL::VARCHAR(1000), NULL::VARCHAR(500);
    RETURN;
  END IF;

  IF p_attachment_type = 'outgoing' THEN
    SELECT att.is_ca, att.file_path, att.file_name, att.outgoing_doc_id
      INTO v_is_ca, v_file_path, v_file_name, v_doc_id
      FROM edoc.attachment_outgoing_docs att
      WHERE att.id = p_attachment_id;

    IF v_file_path IS NULL THEN
      RETURN QUERY SELECT FALSE, 'Không tìm thấy file đính kèm'::TEXT,
                           NULL::VARCHAR(1000), NULL::VARCHAR(500);
      RETURN;
    END IF;
    IF COALESCE(v_is_ca, FALSE) THEN
      RETURN QUERY SELECT FALSE, 'File đã được ký số'::TEXT, v_file_path, v_file_name;
      RETURN;
    END IF;

    SELECT od.signer, od.approver, od.created_by
      INTO v_signer_name, v_approver_name, v_created_by
      FROM edoc.outgoing_docs od
      WHERE od.id = v_doc_id;

    IF v_is_admin
       OR (v_created_by IS NOT NULL AND v_created_by = p_staff_id)
       OR (v_signer_name IS NOT NULL
           AND LOWER(unaccent(v_signer_name)) = LOWER(unaccent(v_staff_name)))
       OR (v_approver_name IS NOT NULL
           AND LOWER(unaccent(v_approver_name)) = LOWER(unaccent(v_staff_name))) THEN
      RETURN QUERY SELECT TRUE, NULL::TEXT, v_file_path, v_file_name;
    ELSE
      RETURN QUERY SELECT FALSE,
                         'Bạn không có quyền ký văn bản này (không phải người tạo/người ký)'::TEXT,
                         v_file_path, v_file_name;
    END IF;
    RETURN;
  END IF;

  IF p_attachment_type = 'drafting' THEN
    SELECT att.is_ca, att.file_path, att.file_name, att.drafting_doc_id
      INTO v_is_ca, v_file_path, v_file_name, v_doc_id
      FROM edoc.attachment_drafting_docs att
      WHERE att.id = p_attachment_id;

    IF v_file_path IS NULL THEN
      RETURN QUERY SELECT FALSE, 'Không tìm thấy file đính kèm'::TEXT,
                           NULL::VARCHAR(1000), NULL::VARCHAR(500);
      RETURN;
    END IF;
    IF COALESCE(v_is_ca, FALSE) THEN
      RETURN QUERY SELECT FALSE, 'File đã được ký số'::TEXT, v_file_path, v_file_name;
      RETURN;
    END IF;

    SELECT dd.signer, dd.approver, dd.created_by
      INTO v_signer_name, v_approver_name, v_created_by
      FROM edoc.drafting_docs dd
      WHERE dd.id = v_doc_id;

    IF v_is_admin
       OR (v_created_by IS NOT NULL AND v_created_by = p_staff_id)
       OR (v_signer_name IS NOT NULL
           AND LOWER(unaccent(v_signer_name)) = LOWER(unaccent(v_staff_name)))
       OR (v_approver_name IS NOT NULL
           AND LOWER(unaccent(v_approver_name)) = LOWER(unaccent(v_staff_name))) THEN
      RETURN QUERY SELECT TRUE, NULL::TEXT, v_file_path, v_file_name;
    ELSE
      RETURN QUERY SELECT FALSE,
                         'Bạn không có quyền ký văn bản này (không phải người tạo/người ký)'::TEXT,
                         v_file_path, v_file_name;
    END IF;
    RETURN;
  END IF;

  IF p_attachment_type = 'handling' THEN
    SELECT att.is_ca, att.file_path, att.file_name, att.handling_doc_id
      INTO v_is_ca, v_file_path, v_file_name, v_doc_id
      FROM edoc.attachment_handling_docs att
      WHERE att.id = p_attachment_id;

    IF v_file_path IS NULL THEN
      RETURN QUERY SELECT FALSE, 'Không tìm thấy file đính kèm'::TEXT,
                           NULL::VARCHAR(1000), NULL::VARCHAR(500);
      RETURN;
    END IF;
    IF COALESCE(v_is_ca, FALSE) THEN
      RETURN QUERY SELECT FALSE, 'File đã được ký số'::TEXT, v_file_path, v_file_name;
      RETURN;
    END IF;

    -- handling_docs.signer là INT FK (KHÔNG phải VARCHAR như outgoing/drafting)
    SELECT hd.signer INTO v_signer_int
      FROM edoc.handling_docs hd
      WHERE hd.id = v_doc_id;

    IF v_is_admin OR (v_signer_int IS NOT NULL AND v_signer_int = p_staff_id) THEN
      RETURN QUERY SELECT TRUE, NULL::TEXT, v_file_path, v_file_name;
    ELSE
      RETURN QUERY SELECT FALSE,
                         'Chỉ người được giao ký HSCV mới ký được'::TEXT,
                         v_file_path, v_file_name;
    END IF;
    RETURN;
  END IF;

  -- Fallback: attachment_type lạ
  RETURN QUERY SELECT FALSE, 'Loại file đính kèm không hợp lệ'::TEXT,
                       NULL::VARCHAR(1000), NULL::VARCHAR(500);
END;
$$;

COMMENT ON FUNCTION edoc.fn_attachment_can_sign IS
  'Phase 11 — permission check cho sign flow. Trả (can_sign, reason, file_path, file_name) để route skip query riêng. staff_id PHẢI từ JWT, không từ body.';

-- ============================================================================
-- Part 4: edoc.fn_sign_transaction_list_by_staff
-- List 3 tab (pending / completed / failed) của 1 staff — dùng cho menu "Ký số"
-- Danh sách ký số (Phase 12 UX-01).
-- ============================================================================
CREATE OR REPLACE FUNCTION edoc.fn_sign_transaction_list_by_staff(
  p_staff_id  INT,
  p_tab       VARCHAR,    -- 'pending' | 'completed' | 'failed'
  p_page      INT,
  p_page_size INT
)
RETURNS TABLE (
  id              BIGINT,
  provider_code   VARCHAR,
  provider_name   VARCHAR,
  attachment_id   BIGINT,
  attachment_type VARCHAR,
  file_name       VARCHAR,
  doc_id          BIGINT,
  doc_type        VARCHAR,
  doc_label       TEXT,
  "status"        VARCHAR,
  error_message   TEXT,
  created_at      TIMESTAMPTZ,
  completed_at    TIMESTAMPTZ,
  total_count     BIGINT
)
LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_offset INT;
  v_page_size INT;
BEGIN
  v_page_size := GREATEST(COALESCE(p_page_size, 20), 1);
  v_offset := GREATEST(COALESCE(p_page, 1) - 1, 0) * v_page_size;

  RETURN QUERY
  SELECT
    st.id,
    st.provider_code,
    spc.provider_name,
    st.attachment_id,
    st.attachment_type,
    COALESCE(
      ao.file_name,
      ad.file_name,
      ah.file_name,
      ai.file_name
    ) AS file_name,
    st.doc_id,
    st.doc_type,
    CASE
      WHEN st.doc_type = 'outgoing_doc' AND od.id IS NOT NULL
        THEN ('VB đi số ' || COALESCE(od.number::TEXT, '?')
              || CASE WHEN od.notation IS NOT NULL THEN '/' || od.notation ELSE '' END)::TEXT
      WHEN st.doc_type = 'drafting_doc' AND dd.id IS NOT NULL
        THEN ('VB dự thảo: ' || COALESCE(LEFT(dd.abstract, 80), dd.document_code, '?'))::TEXT
      WHEN st.doc_type = 'handling_doc' AND hd.id IS NOT NULL
        THEN ('HSCV: ' || COALESCE(LEFT(hd.name, 80), '?'))::TEXT
      WHEN st.doc_type = 'incoming_doc' AND ind.id IS NOT NULL
        THEN ('VB đến số ' || COALESCE(ind.document_code, '?'))::TEXT
      ELSE NULL
    END AS doc_label,
    st."status",
    st.error_message,
    st.created_at,
    st.completed_at,
    COUNT(*) OVER()::BIGINT AS total_count
  FROM edoc.sign_transactions st
  LEFT JOIN public.signing_provider_config spc
    ON spc.provider_code = st.provider_code
  LEFT JOIN edoc.attachment_outgoing_docs ao
    ON st.attachment_type = 'outgoing' AND ao.id = st.attachment_id
  LEFT JOIN edoc.attachment_drafting_docs ad
    ON st.attachment_type = 'drafting' AND ad.id = st.attachment_id
  LEFT JOIN edoc.attachment_handling_docs ah
    ON st.attachment_type = 'handling' AND ah.id = st.attachment_id
  LEFT JOIN edoc.attachment_incoming_docs ai
    ON st.attachment_type = 'incoming' AND ai.id = st.attachment_id
  LEFT JOIN edoc.outgoing_docs od
    ON st.doc_type = 'outgoing_doc' AND od.id = st.doc_id
  LEFT JOIN edoc.drafting_docs dd
    ON st.doc_type = 'drafting_doc' AND dd.id = st.doc_id
  LEFT JOIN edoc.handling_docs hd
    ON st.doc_type = 'handling_doc' AND hd.id = st.doc_id
  LEFT JOIN edoc.incoming_docs ind
    ON st.doc_type = 'incoming_doc' AND ind.id = st.doc_id
  WHERE st.staff_id = p_staff_id
    AND (
      (p_tab = 'pending'   AND st."status" = 'pending')
      OR (p_tab = 'completed' AND st."status" = 'completed')
      OR (p_tab = 'failed'    AND st."status" IN ('failed','expired','cancelled'))
    )
  ORDER BY st.created_at DESC
  LIMIT v_page_size
  OFFSET v_offset;
END;
$$;

COMMENT ON FUNCTION edoc.fn_sign_transaction_list_by_staff IS
  'Phase 11 — list sign_transactions theo staff + tab. Tab valid: pending|completed|failed (failed gộp cả expired+cancelled). Trả thêm doc_label + file_name + provider_name + total_count (window COUNT) để FE render 1 query duy nhất.';

-- ============================================================================
-- Part 5: edoc.fn_sign_transaction_count_by_staff
-- Badge count cho tab UI — trả 3 số gọn (pending/completed/failed).
-- ============================================================================
CREATE OR REPLACE FUNCTION edoc.fn_sign_transaction_count_by_staff(
  p_staff_id INT
)
RETURNS TABLE (
  pending_count   BIGINT,
  completed_count BIGINT,
  failed_count    BIGINT
)
LANGUAGE plpgsql STABLE AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*) FILTER (WHERE st."status" = 'pending')::BIGINT AS pending_count,
    COUNT(*) FILTER (WHERE st."status" = 'completed')::BIGINT AS completed_count,
    COUNT(*) FILTER (WHERE st."status" IN ('failed','expired','cancelled'))::BIGINT AS failed_count
  FROM edoc.sign_transactions st
  WHERE st.staff_id = p_staff_id;
END;
$$;

COMMENT ON FUNCTION edoc.fn_sign_transaction_count_by_staff IS
  'Phase 11 — badge count cho 3 tab. failed_count gộp (failed+expired+cancelled) — khớp tab "failed" của list SP.';

DO $$ BEGIN
  RAISE NOTICE 'Migration 045: 4 SPs (finalize_sign, can_sign, list_by_staff, count_by_staff) + ALTER attachment_handling_docs — OK';
END $$;
