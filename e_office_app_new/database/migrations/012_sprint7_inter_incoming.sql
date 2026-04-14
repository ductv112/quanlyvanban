-- ================================================================
-- MIGRATION 012: Sprint 7 — Văn bản liên thông & Giao việc từ VB
-- Tables: edoc.inter_incoming_docs
-- Functions: 7 stored functions
-- ================================================================

-- ==========================================
-- 1. BẢNG VĂN BẢN LIÊN THÔNG (inter_incoming_docs)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.inter_incoming_docs (
  id                BIGSERIAL PRIMARY KEY,
  unit_id           INT NOT NULL REFERENCES public.departments(id),
  received_date     TIMESTAMP DEFAULT NOW(),
  notation          VARCHAR(100),
  document_code     VARCHAR(100),
  abstract          TEXT,
  publish_unit      VARCHAR(300),
  publish_date      DATE,
  signer            VARCHAR(200),
  sign_date         DATE,
  expired_date      DATE,
  doc_type_id       INT REFERENCES edoc.doc_types(id),
  status            VARCHAR(50) DEFAULT 'pending',
  source_system     VARCHAR(100),
  external_doc_id   VARCHAR(200),
  created_by        INT REFERENCES public.staff(id),
  created_at        TIMESTAMP DEFAULT NOW(),
  updated_at        TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_inter_incoming_unit_id ON edoc.inter_incoming_docs(unit_id);
CREATE INDEX IF NOT EXISTS idx_inter_incoming_received_date ON edoc.inter_incoming_docs(received_date DESC);
CREATE INDEX IF NOT EXISTS idx_inter_incoming_status ON edoc.inter_incoming_docs(status);

COMMENT ON TABLE edoc.inter_incoming_docs IS 'Văn bản đến liên thông — nhận từ hệ thống LGSP bên ngoài';

-- ==========================================
-- 2. FN: DANH SÁCH VB LIÊN THÔNG
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_inter_incoming_get_list(
  p_unit_id     INT,
  p_keyword     TEXT,
  p_status      TEXT,
  p_from_date   DATE,
  p_to_date     DATE,
  p_page        INT DEFAULT 1,
  p_page_size   INT DEFAULT 20
)
RETURNS TABLE (
  id              BIGINT,
  unit_id         INT,
  received_date   TIMESTAMP,
  notation        VARCHAR,
  document_code   VARCHAR,
  abstract        TEXT,
  publish_unit    VARCHAR,
  publish_date    DATE,
  signer          VARCHAR,
  sign_date       DATE,
  expired_date    DATE,
  doc_type_id     INT,
  status          VARCHAR,
  source_system   VARCHAR,
  external_doc_id VARCHAR,
  created_by      INT,
  created_at      TIMESTAMP,
  updated_at      TIMESTAMP,
  total_count     BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT
      d.id,
      d.unit_id,
      d.received_date,
      d.notation,
      d.document_code,
      d.abstract,
      d.publish_unit,
      d.publish_date,
      d.signer,
      d.sign_date,
      d.expired_date,
      d.doc_type_id,
      d.status,
      d.source_system,
      d.external_doc_id,
      d.created_by,
      d.created_at,
      d.updated_at
    FROM edoc.inter_incoming_docs d
    WHERE
      d.unit_id = p_unit_id
      AND (p_status IS NULL OR p_status = '' OR d.status = p_status)
      AND (p_from_date IS NULL OR d.received_date::DATE >= p_from_date)
      AND (p_to_date IS NULL OR d.received_date::DATE <= p_to_date)
      AND (
        p_keyword IS NULL OR TRIM(p_keyword) = ''
        OR d.notation ILIKE '%' || p_keyword || '%'
        OR d.abstract ILIKE '%' || p_keyword || '%'
        OR d.publish_unit ILIKE '%' || p_keyword || '%'
      )
  )
  SELECT
    f.id,
    f.unit_id,
    f.received_date,
    f.notation,
    f.document_code,
    f.abstract,
    f.publish_unit,
    f.publish_date,
    f.signer,
    f.sign_date,
    f.expired_date,
    f.doc_type_id,
    f.status,
    f.source_system,
    f.external_doc_id,
    f.created_by,
    f.created_at,
    f.updated_at,
    COUNT(*) OVER()::BIGINT AS total_count
  FROM filtered f
  ORDER BY f.received_date DESC NULLS LAST
  LIMIT COALESCE(p_page_size, 20)
  OFFSET v_offset;
END;
$$;

-- ==========================================
-- 3. FN: CHI TIẾT VB LIÊN THÔNG
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_inter_incoming_get_by_id(
  p_id  BIGINT
)
RETURNS TABLE (
  id              BIGINT,
  unit_id         INT,
  received_date   TIMESTAMP,
  notation        VARCHAR,
  document_code   VARCHAR,
  abstract        TEXT,
  publish_unit    VARCHAR,
  publish_date    DATE,
  signer          VARCHAR,
  sign_date       DATE,
  expired_date    DATE,
  doc_type_id     INT,
  status          VARCHAR,
  source_system   VARCHAR,
  external_doc_id VARCHAR,
  created_by      INT,
  created_at      TIMESTAMP,
  updated_at      TIMESTAMP
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    d.id,
    d.unit_id,
    d.received_date,
    d.notation,
    d.document_code,
    d.abstract,
    d.publish_unit,
    d.publish_date,
    d.signer,
    d.sign_date,
    d.expired_date,
    d.doc_type_id,
    d.status,
    d.source_system,
    d.external_doc_id,
    d.created_by,
    d.created_at,
    d.updated_at
  FROM edoc.inter_incoming_docs d
  WHERE d.id = p_id;
END;
$$;

-- ==========================================
-- 4. FN: TẠO VB LIÊN THÔNG
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_inter_incoming_create(
  p_unit_id         INT,
  p_notation        VARCHAR,
  p_document_code   VARCHAR,
  p_abstract        TEXT,
  p_publish_unit    VARCHAR,
  p_publish_date    DATE,
  p_signer          VARCHAR,
  p_sign_date       DATE,
  p_expired_date    DATE,
  p_doc_type_id     INT,
  p_source_system   VARCHAR,
  p_external_doc_id VARCHAR,
  p_created_by      INT
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT,
  id      BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_id BIGINT;
BEGIN
  -- Kiểm tra đơn vị tồn tại
  IF NOT EXISTS (SELECT 1 FROM public.departments WHERE id = p_unit_id) THEN
    RETURN QUERY SELECT FALSE, 'Đơn vị không tồn tại'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.inter_incoming_docs (
    unit_id, notation, document_code, abstract,
    publish_unit, publish_date, signer, sign_date,
    expired_date, doc_type_id, source_system, external_doc_id,
    created_by, created_at, updated_at
  ) VALUES (
    p_unit_id, p_notation, p_document_code, p_abstract,
    p_publish_unit, p_publish_date, p_signer, p_sign_date,
    p_expired_date, p_doc_type_id, p_source_system, p_external_doc_id,
    p_created_by, NOW(), NOW()
  )
  RETURNING inter_incoming_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tạo văn bản liên thông thành công'::TEXT, v_id;
END;
$$;

-- ==========================================
-- 5. FN: TẠO HSCV TỪ VĂN BẢN ĐẾN (giao việc)
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_create_from_doc(
  p_doc_id        BIGINT,
  p_doc_type      VARCHAR,
  p_name          TEXT,
  p_start_date    DATE,
  p_end_date      DATE,
  p_curator_ids   INT[],
  p_note          TEXT,
  p_created_by    INT
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT,
  id      BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_id      BIGINT;
  v_unit_id INT;
  v_curator_id INT;
BEGIN
  -- Lấy unit_id từ văn bản gốc
  IF p_doc_type = 'incoming' THEN
    SELECT unit_id INTO v_unit_id FROM edoc.incoming_docs WHERE id = p_doc_id;
  ELSIF p_doc_type = 'outgoing' THEN
    SELECT unit_id INTO v_unit_id FROM edoc.outgoing_docs WHERE id = p_doc_id;
  ELSIF p_doc_type = 'drafting' THEN
    SELECT unit_id INTO v_unit_id FROM edoc.drafting_docs WHERE id = p_doc_id;
  END IF;

  IF v_unit_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản nguồn'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  -- Lấy người phụ trách đầu tiên (primary curator)
  IF p_curator_ids IS NOT NULL AND array_length(p_curator_ids, 1) > 0 THEN
    v_curator_id := p_curator_ids[1];
  END IF;

  -- Tạo hồ sơ công việc
  INSERT INTO edoc.handling_docs (
    unit_id, name, comments, start_date, end_date,
    curator, status, is_from_doc, created_by, created_at, updated_at
  ) VALUES (
    v_unit_id, p_name, p_note, p_start_date, p_end_date,
    v_curator_id, 0, TRUE, p_created_by, NOW(), NOW()
  )
  RETURNING handling_docs.id INTO v_id;

  -- Liên kết văn bản với HSCV
  INSERT INTO edoc.handling_doc_links (handling_doc_id, doc_type, doc_id)
  VALUES (v_id, p_doc_type, p_doc_id)
  ON CONFLICT DO NOTHING;

  -- Thêm các người phụ trách vào staff_handling_docs
  IF p_curator_ids IS NOT NULL THEN
    FOR v_curator_id IN SELECT unnest(p_curator_ids) LOOP
      INSERT INTO edoc.staff_handling_docs (handling_doc_id, staff_id, role, assigned_at)
      VALUES (v_id, v_curator_id, 1, NOW())
      ON CONFLICT DO NOTHING;
    END LOOP;
  END IF;

  RETURN QUERY SELECT TRUE, 'Tạo hồ sơ công việc thành công'::TEXT, v_id;
END;
$$;

-- ==========================================
-- 6. FN: NHẬN BÀN GIAO VĂN BẢN ĐẾN
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_handover(
  p_doc_id    BIGINT,
  p_staff_id  INT
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_count INT;
BEGIN
  -- Kiểm tra văn bản tồn tại
  SELECT COUNT(*) INTO v_count FROM edoc.incoming_docs WHERE id = p_doc_id;
  IF v_count = 0 THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản'::TEXT;
    RETURN;
  END IF;

  -- Đánh dấu nhân viên đã nhận bàn giao (ghi nhận user nhận VB)
  INSERT INTO edoc.user_incoming_docs (incoming_doc_id, staff_id, is_read, read_at)
  VALUES (p_doc_id, p_staff_id, TRUE, NOW())
  ON CONFLICT (incoming_doc_id, staff_id)
  DO UPDATE SET is_read = TRUE, read_at = NOW();

  RETURN QUERY SELECT TRUE, 'Nhận bàn giao thành công'::TEXT;
END;
$$;

-- ==========================================
-- 7. FN: CHUYỂN LẠI / TRẢ VĂN BẢN ĐẾN
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_return(
  p_doc_id      BIGINT,
  p_returned_by INT,
  p_reason      TEXT
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_count INT;
BEGIN
  -- Kiểm tra lý do không được rỗng
  IF p_reason IS NULL OR TRIM(p_reason) = '' THEN
    RETURN QUERY SELECT FALSE, 'Lý do chuyển lại không được để trống'::TEXT;
    RETURN;
  END IF;

  -- Kiểm tra văn bản tồn tại
  SELECT COUNT(*) INTO v_count FROM edoc.incoming_docs WHERE id = p_doc_id;
  IF v_count = 0 THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản'::TEXT;
    RETURN;
  END IF;

  -- Ghi nhận bút phê lý do chuyển lại
  INSERT INTO edoc.leader_notes (incoming_doc_id, staff_id, content, created_at)
  VALUES (p_doc_id, p_returned_by, '[Chuyển lại] ' || TRIM(p_reason), NOW());

  -- Cập nhật trạng thái văn bản về chờ xử lý
  UPDATE edoc.incoming_docs
  SET
    approved = FALSE,
    updated_by = p_returned_by,
    updated_at = NOW()
  WHERE id = p_doc_id;

  RETURN QUERY SELECT TRUE, 'Chuyển lại văn bản thành công'::TEXT;
END;
$$;

-- ==========================================
-- 8. FN: HỦY DUYỆT VĂN BẢN ĐẾN
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_cancel_approve(
  p_doc_id        BIGINT,
  p_cancelled_by  INT
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_approved BOOLEAN;
BEGIN
  -- Kiểm tra văn bản tồn tại và đã được duyệt
  SELECT approved INTO v_approved FROM edoc.incoming_docs WHERE id = p_doc_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản'::TEXT;
    RETURN;
  END IF;

  IF NOT COALESCE(v_approved, FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Văn bản chưa được duyệt, không thể hủy duyệt'::TEXT;
    RETURN;
  END IF;

  -- Hủy duyệt
  UPDATE edoc.incoming_docs
  SET
    approved = FALSE,
    updated_by = p_cancelled_by,
    updated_at = NOW()
  WHERE id = p_doc_id;

  RETURN QUERY SELECT TRUE, 'Hủy duyệt văn bản thành công'::TEXT;
END;
$$;
