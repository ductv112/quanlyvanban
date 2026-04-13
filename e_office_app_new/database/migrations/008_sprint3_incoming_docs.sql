-- ================================================================
-- SPRINT 3: VĂN BẢN ĐẾN (Incoming Documents)
-- 20 stored procedures
-- ================================================================

-- ==========================================
-- 3.2 CRUD — Lấy số đến tiếp theo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_get_next_number(
  p_doc_book_id INT,
  p_unit_id     INT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE v_max INT;
BEGIN
  SELECT COALESCE(MAX(number), 0) INTO v_max
  FROM edoc.incoming_docs
  WHERE doc_book_id = p_doc_book_id
    AND unit_id = p_unit_id
    AND EXTRACT(YEAR FROM received_date) = EXTRACT(YEAR FROM NOW());
  RETURN v_max + 1;
END;
$$;

-- ==========================================
-- 3.2 CRUD — Tạo văn bản đến
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_create(
  p_unit_id         INT,
  p_received_date   TIMESTAMPTZ,
  p_number          INT,
  p_notation        VARCHAR,
  p_document_code   VARCHAR,
  p_abstract        TEXT,
  p_publish_unit    VARCHAR,
  p_publish_date    TIMESTAMPTZ,
  p_signer          VARCHAR,
  p_sign_date       TIMESTAMPTZ,
  p_doc_book_id     INT,
  p_doc_type_id     INT,
  p_doc_field_id    INT,
  p_secret_id       SMALLINT DEFAULT 1,
  p_urgent_id       SMALLINT DEFAULT 1,
  p_number_paper    INT DEFAULT 1,
  p_number_copies   INT DEFAULT 1,
  p_expired_date    TIMESTAMPTZ DEFAULT NULL,
  p_recipients      TEXT DEFAULT NULL,
  p_is_received_paper BOOLEAN DEFAULT FALSE,
  p_created_by      INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE v_id BIGINT;
BEGIN
  -- Validate
  IF p_abstract IS NULL OR TRIM(p_abstract) = '' THEN
    RETURN QUERY SELECT FALSE, 'Trích yếu nội dung không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  IF p_doc_book_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Sổ văn bản là bắt buộc'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  -- Auto number nếu không truyền
  IF p_number IS NULL OR p_number = 0 THEN
    p_number := edoc.fn_incoming_doc_get_next_number(p_doc_book_id, p_unit_id);
  END IF;

  INSERT INTO edoc.incoming_docs (
    unit_id, received_date, number, notation, document_code,
    abstract, publish_unit, publish_date, signer, sign_date,
    doc_book_id, doc_type_id, doc_field_id, secret_id, urgent_id,
    number_paper, number_copies, expired_date, recipients,
    is_received_paper, created_by, updated_by
  ) VALUES (
    p_unit_id, COALESCE(p_received_date, NOW()), p_number, NULLIF(TRIM(p_notation), ''), NULLIF(TRIM(p_document_code), ''),
    TRIM(p_abstract), NULLIF(TRIM(p_publish_unit), ''), p_publish_date, NULLIF(TRIM(p_signer), ''), p_sign_date,
    p_doc_book_id, p_doc_type_id, p_doc_field_id, COALESCE(p_secret_id, 1), COALESCE(p_urgent_id, 1),
    COALESCE(p_number_paper, 1), COALESCE(p_number_copies, 1), p_expired_date, NULLIF(TRIM(p_recipients), ''),
    COALESCE(p_is_received_paper, FALSE), p_created_by, p_created_by
  )
  RETURNING edoc.incoming_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tạo văn bản đến thành công'::TEXT, v_id;
END;
$$;

-- ==========================================
-- 3.2 CRUD — Cập nhật văn bản đến
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_update(
  p_id              BIGINT,
  p_received_date   TIMESTAMPTZ,
  p_number          INT,
  p_notation        VARCHAR,
  p_document_code   VARCHAR,
  p_abstract        TEXT,
  p_publish_unit    VARCHAR,
  p_publish_date    TIMESTAMPTZ,
  p_signer          VARCHAR,
  p_sign_date       TIMESTAMPTZ,
  p_doc_book_id     INT,
  p_doc_type_id     INT,
  p_doc_field_id    INT,
  p_secret_id       SMALLINT DEFAULT 1,
  p_urgent_id       SMALLINT DEFAULT 1,
  p_number_paper    INT DEFAULT 1,
  p_number_copies   INT DEFAULT 1,
  p_expired_date    TIMESTAMPTZ DEFAULT NULL,
  p_recipients      TEXT DEFAULT NULL,
  p_is_received_paper BOOLEAN DEFAULT FALSE,
  p_updated_by      INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_approved BOOLEAN;
BEGIN
  -- Check exists & approved
  SELECT approved INTO v_approved FROM edoc.incoming_docs WHERE edoc.incoming_docs.id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đến'::TEXT;
    RETURN;
  END IF;
  IF v_approved = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Không thể sửa văn bản đã được duyệt'::TEXT;
    RETURN;
  END IF;

  -- Validate
  IF p_abstract IS NULL OR TRIM(p_abstract) = '' THEN
    RETURN QUERY SELECT FALSE, 'Trích yếu nội dung không được để trống'::TEXT;
    RETURN;
  END IF;

  IF p_doc_book_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Sổ văn bản là bắt buộc'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.incoming_docs SET
    received_date   = COALESCE(p_received_date, received_date),
    number          = COALESCE(p_number, number),
    notation        = NULLIF(TRIM(p_notation), ''),
    document_code   = NULLIF(TRIM(p_document_code), ''),
    abstract        = TRIM(p_abstract),
    publish_unit    = NULLIF(TRIM(p_publish_unit), ''),
    publish_date    = p_publish_date,
    signer          = NULLIF(TRIM(p_signer), ''),
    sign_date       = p_sign_date,
    doc_book_id     = p_doc_book_id,
    doc_type_id     = p_doc_type_id,
    doc_field_id    = p_doc_field_id,
    secret_id       = COALESCE(p_secret_id, 1),
    urgent_id       = COALESCE(p_urgent_id, 1),
    number_paper    = COALESCE(p_number_paper, 1),
    number_copies   = COALESCE(p_number_copies, 1),
    expired_date    = p_expired_date,
    recipients      = NULLIF(TRIM(p_recipients), ''),
    is_received_paper = COALESCE(p_is_received_paper, FALSE),
    updated_by      = p_updated_by,
    updated_at      = NOW()
  WHERE edoc.incoming_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Cập nhật văn bản đến thành công'::TEXT;
END;
$$;

-- ==========================================
-- 3.2 CRUD — Xóa văn bản đến
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_delete(
  p_id BIGINT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_approved BOOLEAN;
BEGIN
  SELECT approved INTO v_approved FROM edoc.incoming_docs WHERE edoc.incoming_docs.id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đến'::TEXT;
    RETURN;
  END IF;
  IF v_approved = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Không thể xóa văn bản đã được duyệt'::TEXT;
    RETURN;
  END IF;

  -- CASCADE sẽ xóa user_incoming_docs, attachments, leader_notes
  DELETE FROM edoc.incoming_docs WHERE edoc.incoming_docs.id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa văn bản đến thành công'::TEXT;
END;
$$;

-- ==========================================
-- 3.1 Danh sách — Lấy danh sách văn bản đến (phân trang)
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_get_list(
  p_unit_id       INT,
  p_staff_id      INT,
  p_doc_book_id   INT       DEFAULT NULL,
  p_doc_type_id   INT       DEFAULT NULL,
  p_doc_field_id  INT       DEFAULT NULL,
  p_urgent_id     SMALLINT  DEFAULT NULL,
  p_is_read       BOOLEAN   DEFAULT NULL,
  p_approved      BOOLEAN   DEFAULT NULL,
  p_from_date     TIMESTAMPTZ DEFAULT NULL,
  p_to_date       TIMESTAMPTZ DEFAULT NULL,
  p_keyword       TEXT      DEFAULT NULL,
  p_page          INT       DEFAULT 1,
  p_page_size     INT       DEFAULT 20
)
RETURNS TABLE (
  id              BIGINT,
  unit_id         INT,
  received_date   TIMESTAMPTZ,
  number          INT,
  notation        VARCHAR,
  document_code   VARCHAR,
  abstract        TEXT,
  publish_unit    VARCHAR,
  publish_date    TIMESTAMPTZ,
  signer          VARCHAR,
  sign_date       TIMESTAMPTZ,
  doc_book_id     INT,
  doc_type_id     INT,
  doc_field_id    INT,
  secret_id       SMALLINT,
  urgent_id       SMALLINT,
  number_paper    INT,
  number_copies   INT,
  expired_date    TIMESTAMPTZ,
  recipients      TEXT,
  approver        VARCHAR,
  approved        BOOLEAN,
  is_handling     BOOLEAN,
  is_received_paper BOOLEAN,
  archive_status  BOOLEAN,
  created_by      INT,
  created_at      TIMESTAMPTZ,
  -- Joined fields
  doc_book_name   VARCHAR,
  doc_type_name   VARCHAR,
  doc_type_code   VARCHAR,
  doc_field_name  VARCHAR,
  created_by_name VARCHAR,
  -- Read status
  is_read         BOOLEAN,
  read_at         TIMESTAMPTZ,
  -- Attachment count
  attachment_count BIGINT,
  -- Pagination
  total_count     BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_offset INT;
  v_keyword TEXT;
BEGIN
  v_offset := (GREATEST(p_page, 1) - 1) * p_page_size;
  v_keyword := NULLIF(TRIM(p_keyword), '');

  RETURN QUERY
  WITH filtered AS (
    SELECT
      d.id AS doc_id,
      d.*,
      db.name AS _doc_book_name,
      dt.name AS _doc_type_name,
      dt.code AS _doc_type_code,
      df.name AS _doc_field_name,
      s.full_name AS _created_by_name,
      uid.is_read AS _is_read,
      uid.read_at AS _read_at,
      (SELECT COUNT(*) FROM edoc.attachment_incoming_docs a WHERE a.incoming_doc_id = d.id) AS _attachment_count,
      COUNT(*) OVER() AS _total_count
    FROM edoc.incoming_docs d
    LEFT JOIN edoc.doc_books db ON db.id = d.doc_book_id
    LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
    LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id
    LEFT JOIN public.staff s ON s.id = d.created_by
    LEFT JOIN edoc.user_incoming_docs uid ON uid.incoming_doc_id = d.id AND uid.staff_id = p_staff_id
    WHERE d.unit_id = p_unit_id
      AND (p_doc_book_id IS NULL OR d.doc_book_id = p_doc_book_id)
      AND (p_doc_type_id IS NULL OR d.doc_type_id = p_doc_type_id)
      AND (p_doc_field_id IS NULL OR d.doc_field_id = p_doc_field_id)
      AND (p_urgent_id IS NULL OR d.urgent_id = p_urgent_id)
      AND (p_approved IS NULL OR d.approved = p_approved)
      AND (p_from_date IS NULL OR d.received_date >= p_from_date)
      AND (p_to_date IS NULL OR d.received_date <= p_to_date)
      AND (p_is_read IS NULL OR (p_is_read = TRUE AND uid.is_read = TRUE) OR (p_is_read = FALSE AND (uid.is_read IS NULL OR uid.is_read = FALSE)))
      AND (v_keyword IS NULL OR
           d.abstract ILIKE '%' || v_keyword || '%' OR
           d.notation ILIKE '%' || v_keyword || '%' OR
           d.publish_unit ILIKE '%' || v_keyword || '%' OR
           d.signer ILIKE '%' || v_keyword || '%' OR
           d.document_code ILIKE '%' || v_keyword || '%'
      )
    ORDER BY d.received_date DESC, d.number DESC
    LIMIT p_page_size OFFSET v_offset
  )
  SELECT
    f.doc_id,
    f.unit_id,
    f.received_date,
    f.number,
    f.notation,
    f.document_code,
    f.abstract,
    f.publish_unit,
    f.publish_date,
    f.signer,
    f.sign_date,
    f.doc_book_id,
    f.doc_type_id,
    f.doc_field_id,
    f.secret_id,
    f.urgent_id,
    f.number_paper,
    f.number_copies,
    f.expired_date,
    f.recipients,
    f.approver,
    f.approved,
    f.is_handling,
    f.is_received_paper,
    f.archive_status,
    f.created_by,
    f.created_at,
    f._doc_book_name,
    f._doc_type_name,
    f._doc_type_code,
    f._doc_field_name,
    f._created_by_name,
    COALESCE(f._is_read, FALSE),
    f._read_at,
    f._attachment_count,
    f._total_count
  FROM filtered f;
END;
$$;

-- ==========================================
-- 3.1 Danh sách — Đếm chưa đọc
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_count_unread(
  p_unit_id   INT,
  p_staff_id  INT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE v_count INT;
BEGIN
  SELECT COUNT(*)::INT INTO v_count
  FROM edoc.incoming_docs d
  LEFT JOIN edoc.user_incoming_docs uid ON uid.incoming_doc_id = d.id AND uid.staff_id = p_staff_id
  WHERE d.unit_id = p_unit_id
    AND (uid.is_read IS NULL OR uid.is_read = FALSE);
  RETURN v_count;
END;
$$;

-- ==========================================
-- 3.1 Danh sách — Đánh dấu đã đọc
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_mark_read(
  p_doc_id    BIGINT,
  p_staff_id  INT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO edoc.user_incoming_docs (incoming_doc_id, staff_id, is_read, read_at)
  VALUES (p_doc_id, p_staff_id, TRUE, NOW())
  ON CONFLICT (incoming_doc_id, staff_id)
  DO UPDATE SET is_read = TRUE, read_at = COALESCE(edoc.user_incoming_docs.read_at, NOW());
END;
$$;

-- ==========================================
-- 3.1 Danh sách — Đánh dấu đã đọc hàng loạt
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_mark_read_bulk(
  p_doc_ids   BIGINT[],
  p_staff_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO edoc.user_incoming_docs (incoming_doc_id, staff_id, is_read, read_at)
  SELECT unnest(p_doc_ids), p_staff_id, TRUE, NOW()
  ON CONFLICT (incoming_doc_id, staff_id)
  DO UPDATE SET is_read = TRUE, read_at = COALESCE(edoc.user_incoming_docs.read_at, NOW());

  RETURN QUERY SELECT TRUE, 'Đã đánh dấu đọc thành công'::TEXT;
END;
$$;

-- ==========================================
-- 3.3 Chi tiết — Lấy theo ID
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_get_by_id(
  p_id        BIGINT,
  p_staff_id  INT
)
RETURNS TABLE (
  id              BIGINT,
  unit_id         INT,
  received_date   TIMESTAMPTZ,
  number          INT,
  notation        VARCHAR,
  document_code   VARCHAR,
  abstract        TEXT,
  publish_unit    VARCHAR,
  publish_date    TIMESTAMPTZ,
  signer          VARCHAR,
  sign_date       TIMESTAMPTZ,
  doc_book_id     INT,
  doc_type_id     INT,
  doc_field_id    INT,
  secret_id       SMALLINT,
  urgent_id       SMALLINT,
  number_paper    INT,
  number_copies   INT,
  expired_date    TIMESTAMPTZ,
  recipients      TEXT,
  approver        VARCHAR,
  approved        BOOLEAN,
  is_handling     BOOLEAN,
  is_received_paper BOOLEAN,
  archive_status  BOOLEAN,
  created_by      INT,
  created_at      TIMESTAMPTZ,
  updated_by      INT,
  updated_at      TIMESTAMPTZ,
  -- Joined
  doc_book_name   VARCHAR,
  doc_type_name   VARCHAR,
  doc_type_code   VARCHAR,
  doc_field_name  VARCHAR,
  created_by_name VARCHAR,
  is_read         BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
  -- Đánh dấu đã đọc
  PERFORM edoc.fn_incoming_doc_mark_read(p_id, p_staff_id);

  RETURN QUERY
  SELECT
    d.id, d.unit_id, d.received_date, d.number, d.notation, d.document_code,
    d.abstract, d.publish_unit, d.publish_date, d.signer, d.sign_date,
    d.doc_book_id, d.doc_type_id, d.doc_field_id, d.secret_id, d.urgent_id,
    d.number_paper, d.number_copies, d.expired_date, d.recipients,
    d.approver, d.approved, d.is_handling, d.is_received_paper, d.archive_status,
    d.created_by, d.created_at, d.updated_by, d.updated_at,
    db.name, dt.name, dt.code, df.name, s.full_name,
    TRUE  -- đã mark read ở trên
  FROM edoc.incoming_docs d
  LEFT JOIN edoc.doc_books db ON db.id = d.doc_book_id
  LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
  LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id
  LEFT JOIN public.staff s ON s.id = d.created_by
  WHERE d.id = p_id;
END;
$$;

-- ==========================================
-- 3.3 Chi tiết — Danh sách người nhận
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_get_recipients(
  p_doc_id BIGINT
)
RETURNS TABLE (
  id          BIGINT,
  staff_id    INT,
  staff_name  VARCHAR,
  position_name VARCHAR,
  department_name VARCHAR,
  is_read     BOOLEAN,
  read_at     TIMESTAMPTZ,
  created_at  TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    uid.id, uid.staff_id,
    s.full_name,
    p.name AS position_name,
    dep.name AS department_name,
    uid.is_read, uid.read_at, uid.created_at
  FROM edoc.user_incoming_docs uid
  JOIN public.staff s ON s.id = uid.staff_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  LEFT JOIN public.departments dep ON dep.id = s.department_id
  WHERE uid.incoming_doc_id = p_doc_id
  ORDER BY uid.created_at DESC;
END;
$$;

-- ==========================================
-- 3.3 Chi tiết — Lịch sử xử lý (timeline)
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_get_history(
  p_doc_id BIGINT
)
RETURNS TABLE (
  event_type  VARCHAR,
  event_time  TIMESTAMPTZ,
  staff_name  VARCHAR,
  content     TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM (
    -- Tạo VB
    SELECT 'created'::VARCHAR AS evt, d.created_at AS etime, s.full_name AS sname, ('Tạo văn bản đến, số đến: ' || d.number)::TEXT AS econtent
    FROM edoc.incoming_docs d
    JOIN public.staff s ON s.id = d.created_by
    WHERE d.id = p_doc_id

    UNION ALL
    -- Duyệt
    SELECT 'approved'::VARCHAR, d.updated_at, d.approver::VARCHAR, 'Duyệt văn bản'::TEXT
    FROM edoc.incoming_docs d
    WHERE d.id = p_doc_id AND d.approved = TRUE

    UNION ALL
    -- Gửi cho cán bộ
    SELECT 'sent'::VARCHAR, uid.created_at, s.full_name, ('Nhận văn bản')::TEXT
    FROM edoc.user_incoming_docs uid
    JOIN public.staff s ON s.id = uid.staff_id
    WHERE uid.incoming_doc_id = p_doc_id

    UNION ALL
    -- Bút phê
    SELECT 'leader_note'::VARCHAR, ln.created_at, s.full_name, ln.content
    FROM edoc.leader_notes ln
    JOIN public.staff s ON s.id = ln.staff_id
    WHERE ln.incoming_doc_id = p_doc_id
  ) sub
  ORDER BY sub.etime DESC;
END;
$$;

-- ==========================================
-- 3.4 File đính kèm — Danh sách
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_attachment_incoming_get_list(
  p_doc_id BIGINT
)
RETURNS TABLE (
  id            BIGINT,
  file_name     VARCHAR,
  file_path     VARCHAR,
  file_size     BIGINT,
  content_type  VARCHAR,
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
         a.sort_order, a.created_by, a.created_at, s.full_name
  FROM edoc.attachment_incoming_docs a
  LEFT JOIN public.staff s ON s.id = a.created_by
  WHERE a.incoming_doc_id = p_doc_id
  ORDER BY a.sort_order, a.created_at;
END;
$$;

-- ==========================================
-- 3.4 File đính kèm — Tạo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_attachment_incoming_create(
  p_doc_id       BIGINT,
  p_file_name    VARCHAR,
  p_file_path    VARCHAR,
  p_file_size    BIGINT,
  p_content_type VARCHAR,
  p_created_by   INT
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

  INSERT INTO edoc.attachment_incoming_docs (incoming_doc_id, file_name, file_path, file_size, content_type, created_by)
  VALUES (p_doc_id, p_file_name, p_file_path, COALESCE(p_file_size, 0), p_content_type, p_created_by)
  RETURNING edoc.attachment_incoming_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tải lên thành công'::TEXT, v_id;
END;
$$;

-- ==========================================
-- 3.4 File đính kèm — Xóa (trả về file_path để xóa trên MinIO)
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_attachment_incoming_delete(
  p_id BIGINT
)
RETURNS TABLE (success BOOLEAN, message TEXT, file_path VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE v_path VARCHAR;
BEGIN
  SELECT a.file_path INTO v_path FROM edoc.attachment_incoming_docs a WHERE a.id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy file đính kèm'::TEXT, ''::VARCHAR;
    RETURN;
  END IF;

  DELETE FROM edoc.attachment_incoming_docs WHERE edoc.attachment_incoming_docs.id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa file thành công'::TEXT, v_path;
END;
$$;

-- ==========================================
-- 3.5 Gửi / Phân phối — DS cán bộ có thể gửi
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_get_sendable_staff(
  p_unit_id INT
)
RETURNS TABLE (
  staff_id        INT,
  full_name       VARCHAR,
  position_name   VARCHAR,
  department_id   INT,
  department_name VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT s.id, s.full_name, p.name, s.department_id, d.name
  FROM public.staff s
  LEFT JOIN public.positions p ON p.id = s.position_id
  LEFT JOIN public.departments d ON d.id = s.department_id
  WHERE s.department_id IN (
    SELECT dep.id FROM public.departments dep
    WHERE dep.id = p_unit_id OR dep.parent_id = p_unit_id
  )
  AND s.is_locked = FALSE AND s.is_deleted = FALSE
  ORDER BY d.sort_order, d.name, s.full_name;
END;
$$;

-- ==========================================
-- 3.5 Gửi / Phân phối — Gửi VB cho cán bộ
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_send(
  p_doc_id    BIGINT,
  p_staff_ids INT[],
  p_sent_by   INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
  v_approved BOOLEAN;
  v_count INT;
BEGIN
  -- Check approved
  SELECT approved INTO v_approved FROM edoc.incoming_docs WHERE edoc.incoming_docs.id = p_doc_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đến'::TEXT;
    RETURN;
  END IF;
  IF v_approved IS NULL OR v_approved = FALSE THEN
    RETURN QUERY SELECT FALSE, 'Văn bản chưa được duyệt, không thể gửi'::TEXT;
    RETURN;
  END IF;

  IF p_staff_ids IS NULL OR array_length(p_staff_ids, 1) IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Vui lòng chọn ít nhất một người nhận'::TEXT;
    RETURN;
  END IF;

  -- Insert, skip duplicates
  INSERT INTO edoc.user_incoming_docs (incoming_doc_id, staff_id, is_read, created_at)
  SELECT p_doc_id, unnest(p_staff_ids), FALSE, NOW()
  ON CONFLICT (incoming_doc_id, staff_id) DO NOTHING;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN QUERY SELECT TRUE, ('Đã gửi cho ' || v_count || ' người nhận')::TEXT;
END;
$$;

-- ==========================================
-- 3.6 Bút phê — Danh sách
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_leader_note_get_list(
  p_doc_id BIGINT
)
RETURNS TABLE (
  id          BIGINT,
  staff_id    INT,
  staff_name  VARCHAR,
  position_name VARCHAR,
  content     TEXT,
  created_at  TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT ln.id, ln.staff_id, s.full_name, p.name, ln.content, ln.created_at
  FROM edoc.leader_notes ln
  JOIN public.staff s ON s.id = ln.staff_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  WHERE ln.incoming_doc_id = p_doc_id
  ORDER BY ln.created_at DESC;
END;
$$;

-- ==========================================
-- 3.6 Bút phê — Tạo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_leader_note_create(
  p_doc_id    BIGINT,
  p_staff_id  INT,
  p_content   TEXT
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE v_id BIGINT;
BEGIN
  IF p_content IS NULL OR TRIM(p_content) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nội dung bút phê không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.leader_notes (incoming_doc_id, staff_id, content)
  VALUES (p_doc_id, p_staff_id, TRIM(p_content))
  RETURNING edoc.leader_notes.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Thêm bút phê thành công'::TEXT, v_id;
END;
$$;

-- ==========================================
-- 3.6 Bút phê — Xóa
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_leader_note_delete(
  p_id        BIGINT,
  p_staff_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM edoc.leader_notes
  WHERE edoc.leader_notes.id = p_id AND staff_id = p_staff_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy bút phê hoặc bạn không có quyền xóa'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, 'Xóa bút phê thành công'::TEXT;
END;
$$;

-- ==========================================
-- 3.7 Đánh dấu cá nhân — Toggle bookmark
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_staff_note_toggle(
  p_doc_type  VARCHAR,
  p_doc_id    BIGINT,
  p_staff_id  INT,
  p_note      TEXT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, is_bookmarked BOOLEAN)
LANGUAGE plpgsql
AS $$
DECLARE v_exists BOOLEAN;
BEGIN
  SELECT TRUE INTO v_exists
  FROM edoc.staff_notes
  WHERE doc_type = p_doc_type AND doc_id = p_doc_id AND staff_id = p_staff_id;

  IF v_exists THEN
    DELETE FROM edoc.staff_notes
    WHERE doc_type = p_doc_type AND doc_id = p_doc_id AND staff_id = p_staff_id;
    RETURN QUERY SELECT TRUE, 'Đã bỏ đánh dấu'::TEXT, FALSE;
  ELSE
    INSERT INTO edoc.staff_notes (doc_type, doc_id, staff_id, note)
    VALUES (p_doc_type, p_doc_id, p_staff_id, NULLIF(TRIM(p_note), ''));
    RETURN QUERY SELECT TRUE, 'Đã đánh dấu'::TEXT, TRUE;
  END IF;
END;
$$;

-- ==========================================
-- 3.7 Đánh dấu cá nhân — Danh sách VB đánh dấu
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_staff_note_get_list(
  p_staff_id  INT,
  p_doc_type  VARCHAR DEFAULT 'incoming'
)
RETURNS TABLE (
  note_id     BIGINT,
  doc_id      BIGINT,
  note        TEXT,
  created_at  TIMESTAMPTZ,
  -- Doc info
  doc_number      INT,
  doc_notation    VARCHAR,
  doc_abstract    TEXT,
  doc_received_date TIMESTAMPTZ,
  doc_publish_unit  VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT sn.id, sn.doc_id, sn.note, sn.created_at,
         d.number, d.notation, d.abstract, d.received_date, d.publish_unit
  FROM edoc.staff_notes sn
  JOIN edoc.incoming_docs d ON d.id = sn.doc_id
  WHERE sn.staff_id = p_staff_id AND sn.doc_type = p_doc_type
  ORDER BY sn.created_at DESC;
END;
$$;

-- ==========================================
-- 3.8 Duyệt / Hủy duyệt
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_approve(
  p_id        BIGINT,
  p_staff_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_staff_name VARCHAR;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.incoming_docs WHERE edoc.incoming_docs.id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đến'::TEXT;
    RETURN;
  END IF;

  SELECT full_name INTO v_staff_name FROM public.staff WHERE public.staff.id = p_staff_id;

  UPDATE edoc.incoming_docs SET
    approved = TRUE,
    approver = v_staff_name,
    updated_by = p_staff_id,
    updated_at = NOW()
  WHERE edoc.incoming_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Duyệt văn bản thành công'::TEXT;
END;
$$;

CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_unapprove(
  p_id        BIGINT,
  p_staff_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_has_sent BOOLEAN;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.incoming_docs WHERE edoc.incoming_docs.id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đến'::TEXT;
    RETURN;
  END IF;

  -- Không cho hủy duyệt nếu đã gửi
  SELECT EXISTS(SELECT 1 FROM edoc.user_incoming_docs WHERE incoming_doc_id = p_id) INTO v_has_sent;
  IF v_has_sent THEN
    RETURN QUERY SELECT FALSE, 'Không thể hủy duyệt: văn bản đã được gửi cho cán bộ'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.incoming_docs SET
    approved = FALSE,
    approver = NULL,
    updated_by = p_staff_id,
    updated_at = NOW()
  WHERE edoc.incoming_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Hủy duyệt thành công'::TEXT;
END;
$$;

-- ==========================================
-- 3.8 Nhận bản giấy
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_receive_paper(
  p_id        BIGINT,
  p_staff_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE edoc.incoming_docs SET
    is_received_paper = TRUE,
    updated_by = p_staff_id,
    updated_at = NOW()
  WHERE edoc.incoming_docs.id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đến'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, 'Đã xác nhận nhận bản giấy'::TEXT;
END;
$$;
