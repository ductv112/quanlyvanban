-- ============================================================================
-- Migration 023: Doc Module Extras
-- 1. SP lấy danh sách HSCV để link VB vào
-- 2. SP lấy số chưa phát hành VB đi
-- 3. SP giao việc từ VB đi (đã có fn_handling_doc_create_from_doc hỗ trợ 'outgoing')
-- 4. SP gửi liên thông LGSP từ VB đến/đi
-- 5. SP CRUD file đính kèm VB liên thông
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. HSCV — Lấy danh sách HSCV sẵn có để link VB
-- ============================================================================

CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_get_for_link(
  p_unit_id INT,
  p_keyword TEXT DEFAULT NULL
)
RETURNS TABLE (
  id          BIGINT,
  name        VARCHAR,
  abstract    TEXT,
  status      SMALLINT,
  start_date  TIMESTAMPTZ,
  end_date    TIMESTAMPTZ,
  curator_name VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE v_kw TEXT := NULLIF(TRIM(p_keyword), '');
BEGIN
  RETURN QUERY
  SELECT h.id, h.name::VARCHAR, h.abstract, h.status, h.start_date, h.end_date,
         s.full_name
  FROM edoc.handling_docs h
  LEFT JOIN public.staff s ON s.id = h.curator
  WHERE h.unit_id = p_unit_id
    AND h.status < 3  -- chưa hoàn thành (0=mới, 1=đang xử lý, 2=trình duyệt)
    AND (v_kw IS NULL OR h.name ILIKE '%' || v_kw || '%' OR h.abstract ILIKE '%' || v_kw || '%')
  ORDER BY h.created_at DESC
  LIMIT 50;
END;
$$;

-- ============================================================================
-- 2. VB ĐI — Lấy danh sách số chưa phát hành (cấp số rồi nhưng chưa có VB)
-- Source cũ: Prc_OutgoingDocGetNumberNotUse
-- Logic: tìm gaps trong dãy số đã cấp trong năm
-- ============================================================================

CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_get_unused_numbers(
  p_unit_id     INT,
  p_doc_book_id INT
)
RETURNS TABLE (
  unused_number INT
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_max INT;
BEGIN
  -- Lấy số lớn nhất đã cấp trong năm
  SELECT COALESCE(MAX(number), 0) INTO v_max
  FROM edoc.outgoing_docs
  WHERE unit_id = p_unit_id
    AND doc_book_id = p_doc_book_id
    AND EXTRACT(YEAR FROM received_date) = EXTRACT(YEAR FROM NOW());

  -- Trả về các số bị bỏ qua (gaps)
  RETURN QUERY
  SELECT g.n::INT AS unused_number
  FROM generate_series(1, v_max) AS g(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM edoc.outgoing_docs o
    WHERE o.unit_id = p_unit_id
      AND o.doc_book_id = p_doc_book_id
      AND o.number = g.n
      AND EXTRACT(YEAR FROM o.received_date) = EXTRACT(YEAR FROM NOW())
  )
  ORDER BY g.n;
END;
$$;

-- ============================================================================
-- 4. LGSP — Gửi liên thông từ VB đến (tạo tracking record)
-- Mở rộng fn_lgsp_tracking_create để hỗ trợ incoming_doc_id
-- ============================================================================

DROP FUNCTION IF EXISTS edoc.fn_lgsp_tracking_create(BIGINT, VARCHAR, VARCHAR, VARCHAR, TEXT, INT);

CREATE OR REPLACE FUNCTION edoc.fn_lgsp_tracking_create(
  p_outgoing_doc_id BIGINT DEFAULT NULL,
  p_incoming_doc_id BIGINT DEFAULT NULL,        -- MỚI
  p_direction       VARCHAR DEFAULT 'send',
  p_dest_org_code   VARCHAR DEFAULT NULL,
  p_dest_org_name   VARCHAR DEFAULT NULL,
  p_edxml_content   TEXT DEFAULT NULL,
  p_created_by      INT DEFAULT NULL
)
RETURNS TABLE (
  success   BOOLEAN,
  message   TEXT,
  id        BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
  v_id BIGINT;
BEGIN
  INSERT INTO edoc.lgsp_tracking (
    outgoing_doc_id, incoming_doc_id, direction, dest_org_code, dest_org_name,
    edxml_content, status, created_by
  )
  VALUES (
    p_outgoing_doc_id, p_incoming_doc_id, p_direction, p_dest_org_code, p_dest_org_name,
    p_edxml_content, 'pending', p_created_by
  )
  RETURNING edoc.lgsp_tracking.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo tracking liên thông thành công'::TEXT, v_id;
END;
$$;

-- ============================================================================
-- 5. FILE ĐÍNH KÈM VB LIÊN THÔNG — CRUD SPs
-- Bảng edoc.attachment_inter_incoming_docs đã tạo ở migration 022
-- ============================================================================

-- 5a. Danh sách
CREATE OR REPLACE FUNCTION edoc.fn_attachment_inter_incoming_get_list(
  p_doc_id BIGINT
)
RETURNS TABLE (
  id            BIGINT,
  file_name     VARCHAR,
  file_path     VARCHAR,
  file_size     BIGINT,
  content_type  VARCHAR,
  description   TEXT,
  sort_order    INT,
  created_by    INT,
  created_at    TIMESTAMPTZ,
  created_by_name VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT a.id, a.file_name, a.file_path, a.file_size, a.content_type,
         a.description, a.sort_order, a.created_by, a.created_at, s.full_name
  FROM edoc.attachment_inter_incoming_docs a
  LEFT JOIN public.staff s ON s.id = a.created_by
  WHERE a.inter_incoming_doc_id = p_doc_id
  ORDER BY a.sort_order, a.created_at;
END;
$$;

-- 5b. Tạo
CREATE OR REPLACE FUNCTION edoc.fn_attachment_inter_incoming_create(
  p_doc_id       BIGINT,
  p_file_name    VARCHAR,
  p_file_path    VARCHAR,
  p_file_size    BIGINT,
  p_content_type VARCHAR,
  p_description  TEXT DEFAULT NULL,
  p_created_by   INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE v_id BIGINT;
BEGIN
  IF p_file_name IS NULL OR TRIM(p_file_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên file không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.attachment_inter_incoming_docs (
    inter_incoming_doc_id, file_name, file_path, file_size, content_type, description, created_by
  )
  VALUES (p_doc_id, p_file_name, p_file_path, COALESCE(p_file_size, 0), p_content_type, NULLIF(TRIM(p_description), ''), p_created_by)
  RETURNING edoc.attachment_inter_incoming_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tải lên thành công'::TEXT, v_id;
END;
$$;

-- 5c. Xóa
CREATE OR REPLACE FUNCTION edoc.fn_attachment_inter_incoming_delete(
  p_id BIGINT
)
RETURNS TABLE (success BOOLEAN, message TEXT, file_path VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE v_path VARCHAR;
BEGIN
  SELECT a.file_path INTO v_path FROM edoc.attachment_inter_incoming_docs a WHERE a.id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy file đính kèm'::TEXT, ''::VARCHAR;
    RETURN;
  END IF;

  DELETE FROM edoc.attachment_inter_incoming_docs WHERE edoc.attachment_inter_incoming_docs.id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa file thành công'::TEXT, v_path;
END;
$$;

-- ============================================================================
DO $$ BEGIN
  RAISE NOTICE '✅ Migration 023: Doc Module Extras';
  RAISE NOTICE '   fn_handling_doc_get_for_link (HSCV sẵn có để link)';
  RAISE NOTICE '   fn_outgoing_doc_get_unused_numbers (số chưa phát hành)';
  RAISE NOTICE '   fn_lgsp_tracking_create (mở rộng cho incoming_doc_id)';
  RAISE NOTICE '   fn_attachment_inter_incoming_* (CRUD 3 SPs)';
END $$;

COMMIT;
