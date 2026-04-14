-- ================================================================
-- SPRINT 4: VĂN BẢN DỰ THẢO & VĂN BẢN ĐI
-- ~30 stored procedures
-- ================================================================

-- ==========================================
-- 0. ALTER TABLES — Thêm cột còn thiếu
-- ==========================================
-- drafting_docs cần thêm: approver, expired_date
ALTER TABLE edoc.drafting_docs ADD COLUMN IF NOT EXISTS approver VARCHAR(200);
ALTER TABLE edoc.drafting_docs ADD COLUMN IF NOT EXISTS expired_date TIMESTAMPTZ;
ALTER TABLE edoc.drafting_docs ADD COLUMN IF NOT EXISTS document_code VARCHAR(100);

-- outgoing_docs cần thêm: approver
ALTER TABLE edoc.outgoing_docs ADD COLUMN IF NOT EXISTS approver VARCHAR(200);

-- Index cho drafting
CREATE INDEX IF NOT EXISTS idx_drafting_docs_unit ON edoc.drafting_docs(unit_id, received_date DESC);
CREATE INDEX IF NOT EXISTS idx_drafting_docs_search ON edoc.drafting_docs USING gin(abstract gin_trgm_ops);

-- Index cho user tracking
CREATE INDEX IF NOT EXISTS idx_user_outgoing_docs_staff ON edoc.user_outgoing_docs(staff_id, is_read);
CREATE INDEX IF NOT EXISTS idx_user_drafting_docs_staff ON edoc.user_drafting_docs(staff_id, is_read);


-- ================================================================
-- PHẦN A: VĂN BẢN DỰ THẢO (DRAFTING DOCS)
-- ================================================================

-- ==========================================
-- A.1 Lấy số tiếp theo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_get_next_number(
  p_doc_book_id INT,
  p_unit_id     INT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE v_max INT;
BEGIN
  SELECT COALESCE(MAX(number), 0) INTO v_max
  FROM edoc.drafting_docs
  WHERE doc_book_id = p_doc_book_id
    AND unit_id = p_unit_id
    AND EXTRACT(YEAR FROM received_date) = EXTRACT(YEAR FROM NOW());
  RETURN v_max + 1;
END;
$$;

-- ==========================================
-- A.2 Tạo văn bản dự thảo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_create(
  p_unit_id           INT,
  p_received_date     TIMESTAMPTZ,
  p_number            INT,
  p_sub_number        VARCHAR,
  p_notation          VARCHAR,
  p_document_code     VARCHAR,
  p_abstract          TEXT,
  p_drafting_unit_id  INT        DEFAULT NULL,
  p_drafting_user_id  INT        DEFAULT NULL,
  p_publish_unit_id   INT        DEFAULT NULL,
  p_publish_date      TIMESTAMPTZ DEFAULT NULL,
  p_signer            VARCHAR    DEFAULT NULL,
  p_sign_date         TIMESTAMPTZ DEFAULT NULL,
  p_doc_book_id       INT        DEFAULT NULL,
  p_doc_type_id       INT        DEFAULT NULL,
  p_doc_field_id      INT        DEFAULT NULL,
  p_secret_id         SMALLINT   DEFAULT 1,
  p_urgent_id         SMALLINT   DEFAULT 1,
  p_number_paper      INT        DEFAULT 1,
  p_number_copies     INT        DEFAULT 1,
  p_expired_date      TIMESTAMPTZ DEFAULT NULL,
  p_recipients        TEXT       DEFAULT NULL,
  p_created_by        INT        DEFAULT NULL
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
    p_number := edoc.fn_drafting_doc_get_next_number(p_doc_book_id, p_unit_id);
  END IF;

  INSERT INTO edoc.drafting_docs (
    unit_id, received_date, number, sub_number, notation, document_code,
    abstract, drafting_unit_id, drafting_user_id, publish_unit_id, publish_date,
    signer, sign_date, doc_book_id, doc_type_id, doc_field_id,
    secret_id, urgent_id, number_paper, number_copies, expired_date,
    recipients, created_by, updated_by
  ) VALUES (
    p_unit_id, COALESCE(p_received_date, NOW()), p_number,
    NULLIF(TRIM(p_sub_number), ''), NULLIF(TRIM(p_notation), ''), NULLIF(TRIM(p_document_code), ''),
    TRIM(p_abstract), p_drafting_unit_id, p_drafting_user_id, p_publish_unit_id, p_publish_date,
    NULLIF(TRIM(p_signer), ''), p_sign_date, p_doc_book_id, p_doc_type_id, p_doc_field_id,
    COALESCE(p_secret_id, 1), COALESCE(p_urgent_id, 1),
    COALESCE(p_number_paper, 1), COALESCE(p_number_copies, 1), p_expired_date,
    NULLIF(TRIM(p_recipients), ''), p_created_by, p_created_by
  )
  RETURNING edoc.drafting_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tạo văn bản dự thảo thành công'::TEXT, v_id;
END;
$$;

-- ==========================================
-- A.3 Cập nhật văn bản dự thảo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_update(
  p_id                BIGINT,
  p_received_date     TIMESTAMPTZ,
  p_number            INT,
  p_sub_number        VARCHAR,
  p_notation          VARCHAR,
  p_document_code     VARCHAR,
  p_abstract          TEXT,
  p_drafting_unit_id  INT        DEFAULT NULL,
  p_drafting_user_id  INT        DEFAULT NULL,
  p_publish_unit_id   INT        DEFAULT NULL,
  p_publish_date      TIMESTAMPTZ DEFAULT NULL,
  p_signer            VARCHAR    DEFAULT NULL,
  p_sign_date         TIMESTAMPTZ DEFAULT NULL,
  p_doc_book_id       INT        DEFAULT NULL,
  p_doc_type_id       INT        DEFAULT NULL,
  p_doc_field_id      INT        DEFAULT NULL,
  p_secret_id         SMALLINT   DEFAULT 1,
  p_urgent_id         SMALLINT   DEFAULT 1,
  p_number_paper      INT        DEFAULT 1,
  p_number_copies     INT        DEFAULT 1,
  p_expired_date      TIMESTAMPTZ DEFAULT NULL,
  p_recipients        TEXT       DEFAULT NULL,
  p_updated_by        INT        DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
  v_approved BOOLEAN;
  v_released BOOLEAN;
BEGIN
  SELECT approved, is_released INTO v_approved, v_released
  FROM edoc.drafting_docs WHERE edoc.drafting_docs.id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản dự thảo'::TEXT;
    RETURN;
  END IF;
  IF v_approved = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Không thể sửa văn bản đã được duyệt'::TEXT;
    RETURN;
  END IF;
  IF v_released = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Không thể sửa văn bản đã phát hành'::TEXT;
    RETURN;
  END IF;

  IF p_abstract IS NULL OR TRIM(p_abstract) = '' THEN
    RETURN QUERY SELECT FALSE, 'Trích yếu nội dung không được để trống'::TEXT;
    RETURN;
  END IF;
  IF p_doc_book_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Sổ văn bản là bắt buộc'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.drafting_docs SET
    received_date     = COALESCE(p_received_date, received_date),
    number            = COALESCE(p_number, number),
    sub_number        = NULLIF(TRIM(p_sub_number), ''),
    notation          = NULLIF(TRIM(p_notation), ''),
    document_code     = NULLIF(TRIM(p_document_code), ''),
    abstract          = TRIM(p_abstract),
    drafting_unit_id  = p_drafting_unit_id,
    drafting_user_id  = p_drafting_user_id,
    publish_unit_id   = p_publish_unit_id,
    publish_date      = p_publish_date,
    signer            = NULLIF(TRIM(p_signer), ''),
    sign_date         = p_sign_date,
    doc_book_id       = p_doc_book_id,
    doc_type_id       = p_doc_type_id,
    doc_field_id      = p_doc_field_id,
    secret_id         = COALESCE(p_secret_id, 1),
    urgent_id         = COALESCE(p_urgent_id, 1),
    number_paper      = COALESCE(p_number_paper, 1),
    number_copies     = COALESCE(p_number_copies, 1),
    expired_date      = p_expired_date,
    recipients        = NULLIF(TRIM(p_recipients), ''),
    updated_by        = p_updated_by,
    updated_at        = NOW()
  WHERE edoc.drafting_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Cập nhật văn bản dự thảo thành công'::TEXT;
END;
$$;

-- ==========================================
-- A.4 Xóa văn bản dự thảo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_delete(
  p_id BIGINT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
  v_approved BOOLEAN;
  v_released BOOLEAN;
BEGIN
  SELECT approved, is_released INTO v_approved, v_released
  FROM edoc.drafting_docs WHERE edoc.drafting_docs.id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản dự thảo'::TEXT;
    RETURN;
  END IF;
  IF v_approved = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Không thể xóa văn bản đã được duyệt'::TEXT;
    RETURN;
  END IF;
  IF v_released = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Không thể xóa văn bản đã phát hành'::TEXT;
    RETURN;
  END IF;

  DELETE FROM edoc.drafting_docs WHERE edoc.drafting_docs.id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa văn bản dự thảo thành công'::TEXT;
END;
$$;

-- ==========================================
-- A.5 Danh sách văn bản dự thảo (phân trang)
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_get_list(
  p_unit_id       INT,
  p_staff_id      INT,
  p_doc_book_id   INT       DEFAULT NULL,
  p_doc_type_id   INT       DEFAULT NULL,
  p_doc_field_id  INT       DEFAULT NULL,
  p_urgent_id     SMALLINT  DEFAULT NULL,
  p_is_released   BOOLEAN   DEFAULT NULL,
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
  sub_number      VARCHAR,
  notation        VARCHAR,
  document_code   VARCHAR,
  abstract        TEXT,
  drafting_unit_id  INT,
  drafting_user_id  INT,
  publish_unit_id   INT,
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
  is_released     BOOLEAN,
  released_date   TIMESTAMPTZ,
  created_by      INT,
  created_at      TIMESTAMPTZ,
  -- Joined
  doc_book_name   VARCHAR,
  doc_type_name   VARCHAR,
  doc_type_code   VARCHAR,
  doc_field_name  VARCHAR,
  drafting_unit_name VARCHAR,
  drafting_user_name VARCHAR,
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
      du.name AS _drafting_unit_name,
      ds.full_name AS _drafting_user_name,
      s.full_name AS _created_by_name,
      ud.is_read AS _is_read,
      ud.read_at AS _read_at,
      (SELECT COUNT(*) FROM edoc.attachment_drafting_docs a WHERE a.drafting_doc_id = d.id) AS _attachment_count,
      COUNT(*) OVER() AS _total_count
    FROM edoc.drafting_docs d
    LEFT JOIN edoc.doc_books db ON db.id = d.doc_book_id
    LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
    LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id
    LEFT JOIN public.departments du ON du.id = d.drafting_unit_id
    LEFT JOIN public.staff ds ON ds.id = d.drafting_user_id
    LEFT JOIN public.staff s ON s.id = d.created_by
    LEFT JOIN edoc.user_drafting_docs ud ON ud.drafting_doc_id = d.id AND ud.staff_id = p_staff_id
    WHERE d.unit_id = p_unit_id
      AND (p_doc_book_id IS NULL OR d.doc_book_id = p_doc_book_id)
      AND (p_doc_type_id IS NULL OR d.doc_type_id = p_doc_type_id)
      AND (p_doc_field_id IS NULL OR d.doc_field_id = p_doc_field_id)
      AND (p_urgent_id IS NULL OR d.urgent_id = p_urgent_id)
      AND (p_approved IS NULL OR d.approved = p_approved)
      AND (p_is_released IS NULL OR d.is_released = p_is_released)
      AND (p_from_date IS NULL OR d.received_date >= p_from_date)
      AND (p_to_date IS NULL OR d.received_date <= p_to_date)
      AND (v_keyword IS NULL OR
           d.abstract ILIKE '%' || v_keyword || '%' OR
           d.notation ILIKE '%' || v_keyword || '%' OR
           d.signer ILIKE '%' || v_keyword || '%' OR
           d.recipients ILIKE '%' || v_keyword || '%'
      )
    ORDER BY d.received_date DESC, d.number DESC
    LIMIT p_page_size OFFSET v_offset
  )
  SELECT
    f.doc_id, f.unit_id, f.received_date, f.number, f.sub_number,
    f.notation, f.document_code, f.abstract,
    f.drafting_unit_id, f.drafting_user_id, f.publish_unit_id, f.publish_date,
    f.signer, f.sign_date, f.doc_book_id, f.doc_type_id, f.doc_field_id,
    f.secret_id, f.urgent_id, f.number_paper, f.number_copies,
    f.expired_date, f.recipients, f.approver, f.approved,
    f.is_released, f.released_date, f.created_by, f.created_at,
    f._doc_book_name, f._doc_type_name, f._doc_type_code, f._doc_field_name,
    f._drafting_unit_name, f._drafting_user_name, f._created_by_name,
    COALESCE(f._is_read, FALSE), f._read_at,
    f._attachment_count, f._total_count
  FROM filtered f;
END;
$$;

-- ==========================================
-- A.6 Chi tiết văn bản dự thảo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_get_by_id(
  p_id        BIGINT,
  p_staff_id  INT
)
RETURNS TABLE (
  id              BIGINT,
  unit_id         INT,
  received_date   TIMESTAMPTZ,
  number          INT,
  sub_number      VARCHAR,
  notation        VARCHAR,
  document_code   VARCHAR,
  abstract        TEXT,
  drafting_unit_id  INT,
  drafting_user_id  INT,
  publish_unit_id   INT,
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
  is_released     BOOLEAN,
  released_date   TIMESTAMPTZ,
  created_by      INT,
  created_at      TIMESTAMPTZ,
  updated_by      INT,
  updated_at      TIMESTAMPTZ,
  -- Joined
  doc_book_name   VARCHAR,
  doc_type_name   VARCHAR,
  doc_type_code   VARCHAR,
  doc_field_name  VARCHAR,
  drafting_unit_name VARCHAR,
  drafting_user_name VARCHAR,
  created_by_name VARCHAR,
  is_read         BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
  -- Đánh dấu đã đọc
  INSERT INTO edoc.user_drafting_docs (drafting_doc_id, staff_id, is_read, read_at)
  VALUES (p_id, p_staff_id, TRUE, NOW())
  ON CONFLICT (drafting_doc_id, staff_id)
  DO UPDATE SET is_read = TRUE, read_at = COALESCE(edoc.user_drafting_docs.read_at, NOW());

  RETURN QUERY
  SELECT
    d.id, d.unit_id, d.received_date, d.number, d.sub_number,
    d.notation, d.document_code, d.abstract,
    d.drafting_unit_id, d.drafting_user_id, d.publish_unit_id, d.publish_date,
    d.signer, d.sign_date, d.doc_book_id, d.doc_type_id, d.doc_field_id,
    d.secret_id, d.urgent_id, d.number_paper, d.number_copies,
    d.expired_date, d.recipients, d.approver, d.approved,
    d.is_released, d.released_date,
    d.created_by, d.created_at, d.updated_by, d.updated_at,
    db.name, dt.name, dt.code, df.name,
    du.name, ds.full_name, s.full_name,
    TRUE  -- đã mark read ở trên
  FROM edoc.drafting_docs d
  LEFT JOIN edoc.doc_books db ON db.id = d.doc_book_id
  LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
  LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id
  LEFT JOIN public.departments du ON du.id = d.drafting_unit_id
  LEFT JOIN public.staff ds ON ds.id = d.drafting_user_id
  LEFT JOIN public.staff s ON s.id = d.created_by
  WHERE d.id = p_id;
END;
$$;

-- ==========================================
-- A.7 Đếm chưa đọc — dự thảo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_count_unread(
  p_unit_id   INT,
  p_staff_id  INT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE v_count INT;
BEGIN
  SELECT COUNT(*)::INT INTO v_count
  FROM edoc.drafting_docs d
  LEFT JOIN edoc.user_drafting_docs ud ON ud.drafting_doc_id = d.id AND ud.staff_id = p_staff_id
  WHERE d.unit_id = p_unit_id
    AND (ud.is_read IS NULL OR ud.is_read = FALSE);
  RETURN v_count;
END;
$$;

-- ==========================================
-- A.8 Đánh dấu đã đọc hàng loạt — dự thảo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_mark_read_bulk(
  p_doc_ids   BIGINT[],
  p_staff_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO edoc.user_drafting_docs (drafting_doc_id, staff_id, is_read, read_at)
  SELECT unnest(p_doc_ids), p_staff_id, TRUE, NOW()
  ON CONFLICT (drafting_doc_id, staff_id)
  DO UPDATE SET is_read = TRUE, read_at = COALESCE(edoc.user_drafting_docs.read_at, NOW());

  RETURN QUERY SELECT TRUE, 'Đã đánh dấu đọc thành công'::TEXT;
END;
$$;

-- ==========================================
-- A.9 Duyệt văn bản dự thảo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_approve(
  p_id        BIGINT,
  p_staff_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_staff_name VARCHAR;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.drafting_docs WHERE edoc.drafting_docs.id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản dự thảo'::TEXT;
    RETURN;
  END IF;

  IF (SELECT is_released FROM edoc.drafting_docs WHERE edoc.drafting_docs.id = p_id) = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Văn bản đã phát hành, không cần duyệt'::TEXT;
    RETURN;
  END IF;

  SELECT full_name INTO v_staff_name FROM public.staff WHERE public.staff.id = p_staff_id;

  UPDATE edoc.drafting_docs SET
    approved = TRUE,
    approver = v_staff_name,
    updated_by = p_staff_id,
    updated_at = NOW()
  WHERE edoc.drafting_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Duyệt văn bản dự thảo thành công'::TEXT;
END;
$$;

-- ==========================================
-- A.10 Hủy duyệt văn bản dự thảo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_unapprove(
  p_id        BIGINT,
  p_staff_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.drafting_docs WHERE edoc.drafting_docs.id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản dự thảo'::TEXT;
    RETURN;
  END IF;

  IF (SELECT is_released FROM edoc.drafting_docs WHERE edoc.drafting_docs.id = p_id) = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Không thể hủy duyệt: văn bản đã phát hành'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.drafting_docs SET
    approved = FALSE,
    approver = NULL,
    updated_by = p_staff_id,
    updated_at = NOW()
  WHERE edoc.drafting_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Hủy duyệt thành công'::TEXT;
END;
$$;

-- ==========================================
-- A.11 Từ chối văn bản dự thảo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_reject(
  p_id        BIGINT,
  p_staff_id  INT,
  p_reason    TEXT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_staff_name VARCHAR;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.drafting_docs WHERE edoc.drafting_docs.id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản dự thảo'::TEXT;
    RETURN;
  END IF;

  IF (SELECT is_released FROM edoc.drafting_docs WHERE edoc.drafting_docs.id = p_id) = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Không thể từ chối: văn bản đã phát hành'::TEXT;
    RETURN;
  END IF;

  SELECT full_name INTO v_staff_name FROM public.staff WHERE public.staff.id = p_staff_id;

  UPDATE edoc.drafting_docs SET
    approved = FALSE,
    approver = NULL,
    updated_by = p_staff_id,
    updated_at = NOW()
  WHERE edoc.drafting_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Đã từ chối văn bản dự thảo'::TEXT;
END;
$$;

-- ==========================================
-- A.12 Phát hành dự thảo → Tạo VB đi
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_release(
  p_id          BIGINT,
  p_released_by INT
)
RETURNS TABLE (success BOOLEAN, message TEXT, outgoing_doc_id BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE
  v_draft   edoc.drafting_docs%ROWTYPE;
  v_out_id  BIGINT;
BEGIN
  SELECT * INTO v_draft FROM edoc.drafting_docs WHERE edoc.drafting_docs.id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản dự thảo'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  IF v_draft.approved IS NULL OR v_draft.approved = FALSE THEN
    RETURN QUERY SELECT FALSE, 'Văn bản chưa được duyệt, không thể phát hành'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  IF v_draft.is_released = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Văn bản đã được phát hành trước đó'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  -- Tạo VB đi từ dự thảo
  INSERT INTO edoc.outgoing_docs (
    unit_id, received_date, number, sub_number, notation, document_code,
    abstract, drafting_unit_id, drafting_user_id, publish_unit_id, publish_date,
    signer, sign_date, expired_date,
    number_paper, number_copies, secret_id, urgent_id,
    recipients, doc_book_id, doc_type_id, doc_field_id,
    approved, approver, created_by, updated_by
  ) VALUES (
    v_draft.unit_id, v_draft.received_date, v_draft.number, v_draft.sub_number,
    v_draft.notation, v_draft.document_code, v_draft.abstract,
    v_draft.drafting_unit_id, v_draft.drafting_user_id, v_draft.publish_unit_id, v_draft.publish_date,
    v_draft.signer, v_draft.sign_date, v_draft.expired_date,
    v_draft.number_paper, v_draft.number_copies, v_draft.secret_id, v_draft.urgent_id,
    v_draft.recipients, v_draft.doc_book_id, v_draft.doc_type_id, v_draft.doc_field_id,
    TRUE, v_draft.approver, p_released_by, p_released_by
  )
  RETURNING edoc.outgoing_docs.id INTO v_out_id;

  -- Copy đính kèm từ dự thảo sang VB đi
  INSERT INTO edoc.attachment_outgoing_docs (outgoing_doc_id, file_name, file_path, file_size, content_type, sort_order, created_by)
  SELECT v_out_id, file_name, file_path, file_size, content_type, sort_order, created_by
  FROM edoc.attachment_drafting_docs
  WHERE drafting_doc_id = p_id;

  -- Đánh dấu dự thảo đã phát hành
  UPDATE edoc.drafting_docs SET
    is_released = TRUE,
    released_date = NOW(),
    updated_by = p_released_by,
    updated_at = NOW()
  WHERE edoc.drafting_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Phát hành thành công, đã tạo văn bản đi'::TEXT, v_out_id;
END;
$$;

-- ==========================================
-- A.13 File đính kèm dự thảo — Danh sách
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_attachment_drafting_get_list(
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
  FROM edoc.attachment_drafting_docs a
  LEFT JOIN public.staff s ON s.id = a.created_by
  WHERE a.drafting_doc_id = p_doc_id
  ORDER BY a.sort_order, a.created_at;
END;
$$;

-- ==========================================
-- A.14 File đính kèm dự thảo — Tạo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_attachment_drafting_create(
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

  INSERT INTO edoc.attachment_drafting_docs (drafting_doc_id, file_name, file_path, file_size, content_type, created_by)
  VALUES (p_doc_id, p_file_name, p_file_path, COALESCE(p_file_size, 0), p_content_type, p_created_by)
  RETURNING edoc.attachment_drafting_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tải lên thành công'::TEXT, v_id;
END;
$$;

-- ==========================================
-- A.15 File đính kèm dự thảo — Xóa
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_attachment_drafting_delete(
  p_id BIGINT
)
RETURNS TABLE (success BOOLEAN, message TEXT, file_path VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE v_path VARCHAR;
BEGIN
  SELECT a.file_path INTO v_path FROM edoc.attachment_drafting_docs a WHERE a.id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy file đính kèm'::TEXT, ''::VARCHAR;
    RETURN;
  END IF;

  DELETE FROM edoc.attachment_drafting_docs WHERE edoc.attachment_drafting_docs.id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa file thành công'::TEXT, v_path;
END;
$$;

-- ==========================================
-- A.16 Lịch sử xử lý dự thảo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_get_history(
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
    -- Tạo
    SELECT 'created'::VARCHAR AS evt, d.created_at AS etime, s.full_name AS sname,
           ('Tạo văn bản dự thảo, số: ' || d.number)::TEXT AS econtent
    FROM edoc.drafting_docs d
    JOIN public.staff s ON s.id = d.created_by
    WHERE d.id = p_doc_id

    UNION ALL
    -- Duyệt
    SELECT 'approved'::VARCHAR, d.updated_at, d.approver::VARCHAR, 'Duyệt văn bản dự thảo'::TEXT
    FROM edoc.drafting_docs d
    WHERE d.id = p_doc_id AND d.approved = TRUE

    UNION ALL
    -- Phát hành
    SELECT 'released'::VARCHAR, d.released_date, s.full_name, 'Phát hành thành văn bản đi'::TEXT
    FROM edoc.drafting_docs d
    JOIN public.staff s ON s.id = d.updated_by
    WHERE d.id = p_doc_id AND d.is_released = TRUE

    UNION ALL
    -- Gửi
    SELECT 'sent'::VARCHAR, ud.created_at, s.full_name, 'Nhận văn bản'::TEXT
    FROM edoc.user_drafting_docs ud
    JOIN public.staff s ON s.id = ud.staff_id
    WHERE ud.drafting_doc_id = p_doc_id
  ) sub
  ORDER BY sub.etime DESC;
END;
$$;

-- ==========================================
-- A.17 Gửi VB dự thảo cho cán bộ
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_send(
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
  SELECT approved INTO v_approved FROM edoc.drafting_docs WHERE edoc.drafting_docs.id = p_doc_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản dự thảo'::TEXT;
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

  INSERT INTO edoc.user_drafting_docs (drafting_doc_id, staff_id, is_read, created_at)
  SELECT p_doc_id, unnest(p_staff_ids), FALSE, NOW()
  ON CONFLICT (drafting_doc_id, staff_id) DO NOTHING;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN QUERY SELECT TRUE, ('Đã gửi cho ' || v_count || ' người nhận')::TEXT;
END;
$$;

-- ==========================================
-- A.18 Danh sách người nhận dự thảo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_get_recipients(
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
    ud.id, ud.staff_id,
    s.full_name,
    p.name AS position_name,
    dep.name AS department_name,
    ud.is_read, ud.read_at, ud.created_at
  FROM edoc.user_drafting_docs ud
  JOIN public.staff s ON s.id = ud.staff_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  LEFT JOIN public.departments dep ON dep.id = s.department_id
  WHERE ud.drafting_doc_id = p_doc_id
  ORDER BY ud.created_at DESC;
END;
$$;


-- ================================================================
-- PHẦN B: VĂN BẢN ĐI (OUTGOING DOCS)
-- ================================================================

-- ==========================================
-- B.1 Lấy số tiếp theo — VB đi
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_get_next_number(
  p_doc_book_id INT,
  p_unit_id     INT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE v_max INT;
BEGIN
  SELECT COALESCE(MAX(number), 0) INTO v_max
  FROM edoc.outgoing_docs
  WHERE doc_book_id = p_doc_book_id
    AND unit_id = p_unit_id
    AND EXTRACT(YEAR FROM received_date) = EXTRACT(YEAR FROM NOW());
  RETURN v_max + 1;
END;
$$;

-- ==========================================
-- B.2 Tạo VB đi
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_create(
  p_unit_id           INT,
  p_received_date     TIMESTAMPTZ,
  p_number            INT,
  p_sub_number        VARCHAR,
  p_notation          VARCHAR,
  p_document_code     VARCHAR,
  p_abstract          TEXT,
  p_drafting_unit_id  INT        DEFAULT NULL,
  p_drafting_user_id  INT        DEFAULT NULL,
  p_publish_unit_id   INT        DEFAULT NULL,
  p_publish_date      TIMESTAMPTZ DEFAULT NULL,
  p_signer            VARCHAR    DEFAULT NULL,
  p_sign_date         TIMESTAMPTZ DEFAULT NULL,
  p_doc_book_id       INT        DEFAULT NULL,
  p_doc_type_id       INT        DEFAULT NULL,
  p_doc_field_id      INT        DEFAULT NULL,
  p_secret_id         SMALLINT   DEFAULT 1,
  p_urgent_id         SMALLINT   DEFAULT 1,
  p_number_paper      INT        DEFAULT 1,
  p_number_copies     INT        DEFAULT 1,
  p_expired_date      TIMESTAMPTZ DEFAULT NULL,
  p_recipients        TEXT       DEFAULT NULL,
  p_created_by        INT        DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE v_id BIGINT;
BEGIN
  IF p_abstract IS NULL OR TRIM(p_abstract) = '' THEN
    RETURN QUERY SELECT FALSE, 'Trích yếu nội dung không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  IF p_doc_book_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Sổ văn bản là bắt buộc'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  IF p_number IS NULL OR p_number = 0 THEN
    p_number := edoc.fn_outgoing_doc_get_next_number(p_doc_book_id, p_unit_id);
  END IF;

  INSERT INTO edoc.outgoing_docs (
    unit_id, received_date, number, sub_number, notation, document_code,
    abstract, drafting_unit_id, drafting_user_id, publish_unit_id, publish_date,
    signer, sign_date, expired_date,
    number_paper, number_copies, secret_id, urgent_id,
    recipients, doc_book_id, doc_type_id, doc_field_id,
    created_by, updated_by
  ) VALUES (
    p_unit_id, COALESCE(p_received_date, NOW()), p_number,
    NULLIF(TRIM(p_sub_number), ''), NULLIF(TRIM(p_notation), ''), NULLIF(TRIM(p_document_code), ''),
    TRIM(p_abstract), p_drafting_unit_id, p_drafting_user_id, p_publish_unit_id, p_publish_date,
    NULLIF(TRIM(p_signer), ''), p_sign_date, p_expired_date,
    COALESCE(p_number_paper, 1), COALESCE(p_number_copies, 1),
    COALESCE(p_secret_id, 1), COALESCE(p_urgent_id, 1),
    NULLIF(TRIM(p_recipients), ''), p_doc_book_id, p_doc_type_id, p_doc_field_id,
    p_created_by, p_created_by
  )
  RETURNING edoc.outgoing_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tạo văn bản đi thành công'::TEXT, v_id;
END;
$$;

-- ==========================================
-- B.3 Cập nhật VB đi
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_update(
  p_id                BIGINT,
  p_received_date     TIMESTAMPTZ,
  p_number            INT,
  p_sub_number        VARCHAR,
  p_notation          VARCHAR,
  p_document_code     VARCHAR,
  p_abstract          TEXT,
  p_drafting_unit_id  INT        DEFAULT NULL,
  p_drafting_user_id  INT        DEFAULT NULL,
  p_publish_unit_id   INT        DEFAULT NULL,
  p_publish_date      TIMESTAMPTZ DEFAULT NULL,
  p_signer            VARCHAR    DEFAULT NULL,
  p_sign_date         TIMESTAMPTZ DEFAULT NULL,
  p_doc_book_id       INT        DEFAULT NULL,
  p_doc_type_id       INT        DEFAULT NULL,
  p_doc_field_id      INT        DEFAULT NULL,
  p_secret_id         SMALLINT   DEFAULT 1,
  p_urgent_id         SMALLINT   DEFAULT 1,
  p_number_paper      INT        DEFAULT 1,
  p_number_copies     INT        DEFAULT 1,
  p_expired_date      TIMESTAMPTZ DEFAULT NULL,
  p_recipients        TEXT       DEFAULT NULL,
  p_updated_by        INT        DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_approved BOOLEAN;
BEGIN
  SELECT approved INTO v_approved FROM edoc.outgoing_docs WHERE edoc.outgoing_docs.id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đi'::TEXT;
    RETURN;
  END IF;
  IF v_approved = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Không thể sửa văn bản đã được duyệt'::TEXT;
    RETURN;
  END IF;

  IF p_abstract IS NULL OR TRIM(p_abstract) = '' THEN
    RETURN QUERY SELECT FALSE, 'Trích yếu nội dung không được để trống'::TEXT;
    RETURN;
  END IF;
  IF p_doc_book_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Sổ văn bản là bắt buộc'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.outgoing_docs SET
    received_date     = COALESCE(p_received_date, received_date),
    number            = COALESCE(p_number, number),
    sub_number        = NULLIF(TRIM(p_sub_number), ''),
    notation          = NULLIF(TRIM(p_notation), ''),
    document_code     = NULLIF(TRIM(p_document_code), ''),
    abstract          = TRIM(p_abstract),
    drafting_unit_id  = p_drafting_unit_id,
    drafting_user_id  = p_drafting_user_id,
    publish_unit_id   = p_publish_unit_id,
    publish_date      = p_publish_date,
    signer            = NULLIF(TRIM(p_signer), ''),
    sign_date         = p_sign_date,
    doc_book_id       = p_doc_book_id,
    doc_type_id       = p_doc_type_id,
    doc_field_id      = p_doc_field_id,
    secret_id         = COALESCE(p_secret_id, 1),
    urgent_id         = COALESCE(p_urgent_id, 1),
    number_paper      = COALESCE(p_number_paper, 1),
    number_copies     = COALESCE(p_number_copies, 1),
    expired_date      = p_expired_date,
    recipients        = NULLIF(TRIM(p_recipients), ''),
    updated_by        = p_updated_by,
    updated_at        = NOW()
  WHERE edoc.outgoing_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Cập nhật văn bản đi thành công'::TEXT;
END;
$$;

-- ==========================================
-- B.4 Xóa VB đi
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_delete(
  p_id BIGINT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_approved BOOLEAN;
BEGIN
  SELECT approved INTO v_approved FROM edoc.outgoing_docs WHERE edoc.outgoing_docs.id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đi'::TEXT;
    RETURN;
  END IF;
  IF v_approved = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Không thể xóa văn bản đã được duyệt'::TEXT;
    RETURN;
  END IF;

  DELETE FROM edoc.outgoing_docs WHERE edoc.outgoing_docs.id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa văn bản đi thành công'::TEXT;
END;
$$;

-- ==========================================
-- B.5 Danh sách VB đi (phân trang)
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_get_list(
  p_unit_id       INT,
  p_staff_id      INT,
  p_doc_book_id   INT       DEFAULT NULL,
  p_doc_type_id   INT       DEFAULT NULL,
  p_doc_field_id  INT       DEFAULT NULL,
  p_urgent_id     SMALLINT  DEFAULT NULL,
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
  sub_number      VARCHAR,
  notation        VARCHAR,
  document_code   VARCHAR,
  abstract        TEXT,
  drafting_unit_id  INT,
  drafting_user_id  INT,
  publish_unit_id   INT,
  publish_date    TIMESTAMPTZ,
  signer          VARCHAR,
  sign_date       TIMESTAMPTZ,
  expired_date    TIMESTAMPTZ,
  doc_book_id     INT,
  doc_type_id     INT,
  doc_field_id    INT,
  secret_id       SMALLINT,
  urgent_id       SMALLINT,
  number_paper    INT,
  number_copies   INT,
  recipients      TEXT,
  approver        VARCHAR,
  approved        BOOLEAN,
  is_handling     BOOLEAN,
  archive_status  BOOLEAN,
  created_by      INT,
  created_at      TIMESTAMPTZ,
  -- Joined
  doc_book_name   VARCHAR,
  doc_type_name   VARCHAR,
  doc_type_code   VARCHAR,
  doc_field_name  VARCHAR,
  drafting_unit_name VARCHAR,
  drafting_user_name VARCHAR,
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
      du.name AS _drafting_unit_name,
      ds.full_name AS _drafting_user_name,
      s.full_name AS _created_by_name,
      uo.is_read AS _is_read,
      uo.read_at AS _read_at,
      (SELECT COUNT(*) FROM edoc.attachment_outgoing_docs a WHERE a.outgoing_doc_id = d.id) AS _attachment_count,
      COUNT(*) OVER() AS _total_count
    FROM edoc.outgoing_docs d
    LEFT JOIN edoc.doc_books db ON db.id = d.doc_book_id
    LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
    LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id
    LEFT JOIN public.departments du ON du.id = d.drafting_unit_id
    LEFT JOIN public.staff ds ON ds.id = d.drafting_user_id
    LEFT JOIN public.staff s ON s.id = d.created_by
    LEFT JOIN edoc.user_outgoing_docs uo ON uo.outgoing_doc_id = d.id AND uo.staff_id = p_staff_id
    WHERE d.unit_id = p_unit_id
      AND (p_doc_book_id IS NULL OR d.doc_book_id = p_doc_book_id)
      AND (p_doc_type_id IS NULL OR d.doc_type_id = p_doc_type_id)
      AND (p_doc_field_id IS NULL OR d.doc_field_id = p_doc_field_id)
      AND (p_urgent_id IS NULL OR d.urgent_id = p_urgent_id)
      AND (p_approved IS NULL OR d.approved = p_approved)
      AND (p_from_date IS NULL OR d.received_date >= p_from_date)
      AND (p_to_date IS NULL OR d.received_date <= p_to_date)
      AND (v_keyword IS NULL OR
           d.abstract ILIKE '%' || v_keyword || '%' OR
           d.notation ILIKE '%' || v_keyword || '%' OR
           d.signer ILIKE '%' || v_keyword || '%' OR
           d.recipients ILIKE '%' || v_keyword || '%'
      )
    ORDER BY d.received_date DESC, d.number DESC
    LIMIT p_page_size OFFSET v_offset
  )
  SELECT
    f.doc_id, f.unit_id, f.received_date, f.number, f.sub_number,
    f.notation, f.document_code, f.abstract,
    f.drafting_unit_id, f.drafting_user_id, f.publish_unit_id, f.publish_date,
    f.signer, f.sign_date, f.expired_date,
    f.doc_book_id, f.doc_type_id, f.doc_field_id,
    f.secret_id, f.urgent_id, f.number_paper, f.number_copies,
    f.recipients, f.approver, f.approved,
    f.is_handling, f.archive_status, f.created_by, f.created_at,
    f._doc_book_name, f._doc_type_name, f._doc_type_code, f._doc_field_name,
    f._drafting_unit_name, f._drafting_user_name, f._created_by_name,
    COALESCE(f._is_read, FALSE), f._read_at,
    f._attachment_count, f._total_count
  FROM filtered f;
END;
$$;

-- ==========================================
-- B.6 Chi tiết VB đi
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_get_by_id(
  p_id        BIGINT,
  p_staff_id  INT
)
RETURNS TABLE (
  id              BIGINT,
  unit_id         INT,
  received_date   TIMESTAMPTZ,
  number          INT,
  sub_number      VARCHAR,
  notation        VARCHAR,
  document_code   VARCHAR,
  abstract        TEXT,
  drafting_unit_id  INT,
  drafting_user_id  INT,
  publish_unit_id   INT,
  publish_date    TIMESTAMPTZ,
  signer          VARCHAR,
  sign_date       TIMESTAMPTZ,
  expired_date    TIMESTAMPTZ,
  doc_book_id     INT,
  doc_type_id     INT,
  doc_field_id    INT,
  secret_id       SMALLINT,
  urgent_id       SMALLINT,
  number_paper    INT,
  number_copies   INT,
  recipients      TEXT,
  approver        VARCHAR,
  approved        BOOLEAN,
  is_handling     BOOLEAN,
  archive_status  BOOLEAN,
  is_inter_doc    BOOLEAN,
  is_digital_signed SMALLINT,
  created_by      INT,
  created_at      TIMESTAMPTZ,
  updated_by      INT,
  updated_at      TIMESTAMPTZ,
  -- Joined
  doc_book_name   VARCHAR,
  doc_type_name   VARCHAR,
  doc_type_code   VARCHAR,
  doc_field_name  VARCHAR,
  drafting_unit_name VARCHAR,
  drafting_user_name VARCHAR,
  created_by_name VARCHAR,
  is_read         BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
  -- Đánh dấu đã đọc
  INSERT INTO edoc.user_outgoing_docs (outgoing_doc_id, staff_id, is_read, read_at)
  VALUES (p_id, p_staff_id, TRUE, NOW())
  ON CONFLICT (outgoing_doc_id, staff_id)
  DO UPDATE SET is_read = TRUE, read_at = COALESCE(edoc.user_outgoing_docs.read_at, NOW());

  RETURN QUERY
  SELECT
    d.id, d.unit_id, d.received_date, d.number, d.sub_number,
    d.notation, d.document_code, d.abstract,
    d.drafting_unit_id, d.drafting_user_id, d.publish_unit_id, d.publish_date,
    d.signer, d.sign_date, d.expired_date,
    d.doc_book_id, d.doc_type_id, d.doc_field_id,
    d.secret_id, d.urgent_id, d.number_paper, d.number_copies,
    d.recipients, d.approver, d.approved,
    d.is_handling, d.archive_status, d.is_inter_doc, d.is_digital_signed,
    d.created_by, d.created_at, d.updated_by, d.updated_at,
    db.name, dt.name, dt.code, df.name,
    du.name, ds.full_name, s.full_name,
    TRUE
  FROM edoc.outgoing_docs d
  LEFT JOIN edoc.doc_books db ON db.id = d.doc_book_id
  LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
  LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id
  LEFT JOIN public.departments du ON du.id = d.drafting_unit_id
  LEFT JOIN public.staff ds ON ds.id = d.drafting_user_id
  LEFT JOIN public.staff s ON s.id = d.created_by
  WHERE d.id = p_id;
END;
$$;

-- ==========================================
-- B.7 Đếm chưa đọc — VB đi
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_count_unread(
  p_unit_id   INT,
  p_staff_id  INT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE v_count INT;
BEGIN
  SELECT COUNT(*)::INT INTO v_count
  FROM edoc.outgoing_docs d
  LEFT JOIN edoc.user_outgoing_docs uo ON uo.outgoing_doc_id = d.id AND uo.staff_id = p_staff_id
  WHERE d.unit_id = p_unit_id
    AND (uo.is_read IS NULL OR uo.is_read = FALSE);
  RETURN v_count;
END;
$$;

-- ==========================================
-- B.8 Đánh dấu đã đọc hàng loạt — VB đi
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_mark_read_bulk(
  p_doc_ids   BIGINT[],
  p_staff_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO edoc.user_outgoing_docs (outgoing_doc_id, staff_id, is_read, read_at)
  SELECT unnest(p_doc_ids), p_staff_id, TRUE, NOW()
  ON CONFLICT (outgoing_doc_id, staff_id)
  DO UPDATE SET is_read = TRUE, read_at = COALESCE(edoc.user_outgoing_docs.read_at, NOW());

  RETURN QUERY SELECT TRUE, 'Đã đánh dấu đọc thành công'::TEXT;
END;
$$;

-- ==========================================
-- B.9 Duyệt VB đi
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_approve(
  p_id        BIGINT,
  p_staff_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_staff_name VARCHAR;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.outgoing_docs WHERE edoc.outgoing_docs.id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đi'::TEXT;
    RETURN;
  END IF;

  SELECT full_name INTO v_staff_name FROM public.staff WHERE public.staff.id = p_staff_id;

  UPDATE edoc.outgoing_docs SET
    approved = TRUE,
    approver = v_staff_name,
    updated_by = p_staff_id,
    updated_at = NOW()
  WHERE edoc.outgoing_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Duyệt văn bản đi thành công'::TEXT;
END;
$$;

-- ==========================================
-- B.10 Hủy duyệt VB đi
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_unapprove(
  p_id        BIGINT,
  p_staff_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_has_sent BOOLEAN;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.outgoing_docs WHERE edoc.outgoing_docs.id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đi'::TEXT;
    RETURN;
  END IF;

  SELECT EXISTS(SELECT 1 FROM edoc.user_outgoing_docs WHERE outgoing_doc_id = p_id) INTO v_has_sent;
  IF v_has_sent THEN
    RETURN QUERY SELECT FALSE, 'Không thể hủy duyệt: văn bản đã được gửi cho cán bộ'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.outgoing_docs SET
    approved = FALSE,
    approver = NULL,
    updated_by = p_staff_id,
    updated_at = NOW()
  WHERE edoc.outgoing_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Hủy duyệt thành công'::TEXT;
END;
$$;

-- ==========================================
-- B.11 Gửi VB đi cho cán bộ
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_send(
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
  SELECT approved INTO v_approved FROM edoc.outgoing_docs WHERE edoc.outgoing_docs.id = p_doc_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đi'::TEXT;
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

  INSERT INTO edoc.user_outgoing_docs (outgoing_doc_id, staff_id, is_read, created_at)
  SELECT p_doc_id, unnest(p_staff_ids), FALSE, NOW()
  ON CONFLICT (outgoing_doc_id, staff_id) DO NOTHING;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN QUERY SELECT TRUE, ('Đã gửi cho ' || v_count || ' người nhận')::TEXT;
END;
$$;

-- ==========================================
-- B.12 Danh sách người nhận VB đi
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_get_recipients(
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
    uo.id, uo.staff_id,
    s.full_name,
    p.name AS position_name,
    dep.name AS department_name,
    uo.is_read, uo.read_at, uo.created_at
  FROM edoc.user_outgoing_docs uo
  JOIN public.staff s ON s.id = uo.staff_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  LEFT JOIN public.departments dep ON dep.id = s.department_id
  WHERE uo.outgoing_doc_id = p_doc_id
  ORDER BY uo.created_at DESC;
END;
$$;

-- ==========================================
-- B.13 File đính kèm VB đi — Danh sách
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_attachment_outgoing_get_list(
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
  FROM edoc.attachment_outgoing_docs a
  LEFT JOIN public.staff s ON s.id = a.created_by
  WHERE a.outgoing_doc_id = p_doc_id
  ORDER BY a.sort_order, a.created_at;
END;
$$;

-- ==========================================
-- B.14 File đính kèm VB đi — Tạo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_attachment_outgoing_create(
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

  INSERT INTO edoc.attachment_outgoing_docs (outgoing_doc_id, file_name, file_path, file_size, content_type, created_by)
  VALUES (p_doc_id, p_file_name, p_file_path, COALESCE(p_file_size, 0), p_content_type, p_created_by)
  RETURNING edoc.attachment_outgoing_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tải lên thành công'::TEXT, v_id;
END;
$$;

-- ==========================================
-- B.15 File đính kèm VB đi — Xóa
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_attachment_outgoing_delete(
  p_id BIGINT
)
RETURNS TABLE (success BOOLEAN, message TEXT, file_path VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE v_path VARCHAR;
BEGIN
  SELECT a.file_path INTO v_path FROM edoc.attachment_outgoing_docs a WHERE a.id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy file đính kèm'::TEXT, ''::VARCHAR;
    RETURN;
  END IF;

  DELETE FROM edoc.attachment_outgoing_docs WHERE edoc.attachment_outgoing_docs.id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa file thành công'::TEXT, v_path;
END;
$$;

-- ==========================================
-- B.16 Lịch sử xử lý VB đi
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_get_history(
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
    -- Tạo
    SELECT 'created'::VARCHAR AS evt, d.created_at AS etime, s.full_name AS sname,
           ('Tạo văn bản đi, số: ' || d.number)::TEXT AS econtent
    FROM edoc.outgoing_docs d
    JOIN public.staff s ON s.id = d.created_by
    WHERE d.id = p_doc_id

    UNION ALL
    -- Duyệt
    SELECT 'approved'::VARCHAR, d.updated_at, d.approver::VARCHAR, 'Duyệt văn bản đi'::TEXT
    FROM edoc.outgoing_docs d
    WHERE d.id = p_doc_id AND d.approved = TRUE

    UNION ALL
    -- Gửi
    SELECT 'sent'::VARCHAR, uo.created_at, s.full_name, 'Nhận văn bản'::TEXT
    FROM edoc.user_outgoing_docs uo
    JOIN public.staff s ON s.id = uo.staff_id
    WHERE uo.outgoing_doc_id = p_doc_id
  ) sub
  ORDER BY sub.etime DESC;
END;
$$;


-- ================================================================
-- PHẦN C: HÀM DÙNG CHUNG — Bookmark cho outgoing/drafting
-- ================================================================

-- Cập nhật fn_staff_note_get_list để hỗ trợ outgoing + drafting
CREATE OR REPLACE FUNCTION edoc.fn_staff_note_get_list(
  p_staff_id  INT,
  p_doc_type  VARCHAR DEFAULT 'incoming'
)
RETURNS TABLE (
  note_id     BIGINT,
  doc_id      BIGINT,
  note        TEXT,
  created_at  TIMESTAMPTZ,
  doc_number      INT,
  doc_notation    VARCHAR,
  doc_abstract    TEXT,
  doc_received_date TIMESTAMPTZ,
  doc_publish_unit  VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
  IF p_doc_type = 'incoming' THEN
    RETURN QUERY
    SELECT sn.id, sn.doc_id, sn.note, sn.created_at,
           d.number, d.notation, d.abstract, d.received_date, d.publish_unit
    FROM edoc.staff_notes sn
    JOIN edoc.incoming_docs d ON d.id = sn.doc_id
    WHERE sn.staff_id = p_staff_id AND sn.doc_type = 'incoming'
    ORDER BY sn.created_at DESC;

  ELSIF p_doc_type = 'outgoing' THEN
    RETURN QUERY
    SELECT sn.id, sn.doc_id, sn.note, sn.created_at,
           d.number, d.notation, d.abstract, d.received_date,
           COALESCE(du.name, '')::VARCHAR
    FROM edoc.staff_notes sn
    JOIN edoc.outgoing_docs d ON d.id = sn.doc_id
    LEFT JOIN public.departments du ON du.id = d.drafting_unit_id
    WHERE sn.staff_id = p_staff_id AND sn.doc_type = 'outgoing'
    ORDER BY sn.created_at DESC;

  ELSIF p_doc_type = 'drafting' THEN
    RETURN QUERY
    SELECT sn.id, sn.doc_id, sn.note, sn.created_at,
           d.number, d.notation, d.abstract, d.received_date,
           COALESCE(du.name, '')::VARCHAR
    FROM edoc.staff_notes sn
    JOIN edoc.drafting_docs d ON d.id = sn.doc_id
    LEFT JOIN public.departments du ON du.id = d.drafting_unit_id
    WHERE sn.staff_id = p_staff_id AND sn.doc_type = 'drafting'
    ORDER BY sn.created_at DESC;
  END IF;
END;
$$;
