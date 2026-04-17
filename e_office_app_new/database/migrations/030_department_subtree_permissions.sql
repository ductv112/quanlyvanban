-- ================================================================
-- Migration 030: Phân quyền dữ liệu theo cây phòng ban
--
-- Mục tiêu: User tại department X → thấy VB của X + con cháu X
--           Admin → thấy tất cả, có bộ lọc
--
-- Approach: Thêm p_dept_ids INT[] vào các SP list/count
--           Fallback về unit_id nếu p_dept_ids IS NULL (backwards-compatible)
-- ================================================================

BEGIN;

-- ============================================================
-- 1. HELPER: Lấy subtree department IDs (recursive)
-- ============================================================
CREATE OR REPLACE FUNCTION public.fn_get_department_subtree(p_dept_id INT)
RETURNS INT[]
LANGUAGE sql STABLE
AS $$
  WITH RECURSIVE tree AS (
    SELECT id FROM public.departments WHERE id = p_dept_id AND is_deleted = FALSE
    UNION ALL
    SELECT d.id FROM public.departments d
    JOIN tree t ON d.parent_id = t.id
    WHERE d.is_deleted = FALSE
  )
  SELECT COALESCE(ARRAY(SELECT id FROM tree), ARRAY[p_dept_id]);
$$;

DO $$ BEGIN RAISE NOTICE '✅ 030-1: fn_get_department_subtree created'; END $$;

-- ============================================================
-- 2. ALTER TABLE: Thêm department_id vào 3 bảng VB
-- ============================================================
ALTER TABLE edoc.incoming_docs ADD COLUMN IF NOT EXISTS department_id INT REFERENCES public.departments(id);
ALTER TABLE edoc.outgoing_docs ADD COLUMN IF NOT EXISTS department_id INT REFERENCES public.departments(id);
ALTER TABLE edoc.drafting_docs ADD COLUMN IF NOT EXISTS department_id INT REFERENCES public.departments(id);

CREATE INDEX IF NOT EXISTS idx_incoming_docs_department ON edoc.incoming_docs(department_id);
CREATE INDEX IF NOT EXISTS idx_outgoing_docs_department ON edoc.outgoing_docs(department_id);
CREATE INDEX IF NOT EXISTS idx_drafting_docs_department ON edoc.drafting_docs(department_id);

DO $$ BEGIN RAISE NOTICE '✅ 030-2: department_id columns + indexes added'; END $$;

-- ============================================================
-- 3. BACKFILL: department_id từ created_by → staff.department_id
-- ============================================================
UPDATE edoc.incoming_docs d SET department_id = s.department_id
FROM public.staff s WHERE s.id = d.created_by AND d.department_id IS NULL;

UPDATE edoc.outgoing_docs d SET department_id = s.department_id
FROM public.staff s WHERE s.id = d.created_by AND d.department_id IS NULL;

UPDATE edoc.drafting_docs d SET department_id = s.department_id
FROM public.staff s WHERE s.id = d.created_by AND d.department_id IS NULL;

-- Fallback: dùng unit_id nếu vẫn NULL
UPDATE edoc.incoming_docs SET department_id = unit_id WHERE department_id IS NULL;
UPDATE edoc.outgoing_docs SET department_id = unit_id WHERE department_id IS NULL;
UPDATE edoc.drafting_docs SET department_id = unit_id WHERE department_id IS NULL;

DO $$ BEGIN RAISE NOTICE '✅ 030-3: Backfill department_id complete'; END $$;

-- ============================================================
-- 4. SP: fn_incoming_doc_get_list — thêm p_dept_ids
-- (Bản LATEST đã có p_signer, p_from_number, p_to_number)
-- ============================================================
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_get_list(INT, INT, INT, INT, INT, SMALLINT, BOOLEAN, BOOLEAN, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, TEXT, INT, INT, INT, INT);
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
  p_signer        TEXT      DEFAULT NULL,
  p_from_number   INT       DEFAULT NULL,
  p_to_number     INT       DEFAULT NULL,
  p_page          INT       DEFAULT 1,
  p_page_size     INT       DEFAULT 20,
  p_dept_ids      INT[]     DEFAULT NULL          -- NEW: department subtree filter
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
  sents           TEXT,
  approver        VARCHAR,
  approved        BOOLEAN,
  is_handling     BOOLEAN,
  is_received_paper BOOLEAN,
  archive_status  BOOLEAN,
  created_by      INT,
  created_at      TIMESTAMPTZ,
  doc_book_name   VARCHAR,
  doc_type_name   VARCHAR,
  doc_type_code   VARCHAR,
  doc_field_name  VARCHAR,
  created_by_name VARCHAR,
  is_read         BOOLEAN,
  read_at         TIMESTAMPTZ,
  attachment_count BIGINT,
  total_count     BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_offset INT;
  v_keyword TEXT;
  v_signer TEXT;
BEGIN
  v_offset := (GREATEST(p_page, 1) - 1) * p_page_size;
  v_keyword := NULLIF(TRIM(p_keyword), '');
  v_signer := NULLIF(TRIM(p_signer), '');

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
    WHERE
      CASE
        WHEN p_dept_ids IS NOT NULL THEN d.department_id = ANY(p_dept_ids)
        ELSE d.unit_id = p_unit_id
      END
      AND (p_doc_book_id IS NULL OR d.doc_book_id = p_doc_book_id)
      AND (p_doc_type_id IS NULL OR d.doc_type_id = p_doc_type_id)
      AND (p_doc_field_id IS NULL OR d.doc_field_id = p_doc_field_id)
      AND (p_urgent_id IS NULL OR d.urgent_id = p_urgent_id)
      AND (p_approved IS NULL OR d.approved = p_approved)
      AND (p_from_date IS NULL OR d.received_date >= p_from_date)
      AND (p_to_date IS NULL OR d.received_date <= p_to_date)
      AND (p_is_read IS NULL OR (p_is_read = TRUE AND uid.is_read = TRUE) OR (p_is_read = FALSE AND (uid.is_read IS NULL OR uid.is_read = FALSE)))
      AND (v_signer IS NULL OR d.signer ILIKE '%' || v_signer || '%')
      AND (p_from_number IS NULL OR d.number >= p_from_number)
      AND (p_to_number IS NULL OR d.number <= p_to_number)
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
    f.sents,
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

DO $$ BEGIN RAISE NOTICE '✅ 030-4: fn_incoming_doc_get_list updated'; END $$;

-- ============================================================
-- 5. SP: fn_incoming_doc_count_unread — thêm p_dept_ids
-- ============================================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_count_unread(
  p_unit_id   INT,
  p_staff_id  INT,
  p_dept_ids  INT[] DEFAULT NULL
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE v_count INT;
BEGIN
  SELECT COUNT(*)::INT INTO v_count
  FROM edoc.incoming_docs d
  LEFT JOIN edoc.user_incoming_docs uid ON uid.incoming_doc_id = d.id AND uid.staff_id = p_staff_id
  WHERE
    CASE
      WHEN p_dept_ids IS NOT NULL THEN d.department_id = ANY(p_dept_ids)
      ELSE d.unit_id = p_unit_id
    END
    AND (uid.is_read IS NULL OR uid.is_read = FALSE);
  RETURN v_count;
END;
$$;

DO $$ BEGIN RAISE NOTICE '✅ 030-5: fn_incoming_doc_count_unread updated'; END $$;

-- ============================================================
-- 6. SP: fn_incoming_doc_create — thêm p_department_id
-- ============================================================
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
  p_created_by      INT DEFAULT NULL,
  p_department_id   INT DEFAULT NULL              -- NEW
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
    p_number := edoc.fn_incoming_doc_get_next_number(p_doc_book_id, p_unit_id);
  END IF;

  -- Resolve department_id from created_by if not provided
  IF p_department_id IS NULL AND p_created_by IS NOT NULL THEN
    SELECT s.department_id INTO p_department_id FROM public.staff s WHERE s.id = p_created_by;
  END IF;

  INSERT INTO edoc.incoming_docs (
    unit_id, department_id, received_date, number, notation, document_code,
    abstract, publish_unit, publish_date, signer, sign_date,
    doc_book_id, doc_type_id, doc_field_id, secret_id, urgent_id,
    number_paper, number_copies, expired_date, recipients,
    is_received_paper, created_by, updated_by
  ) VALUES (
    p_unit_id, COALESCE(p_department_id, p_unit_id), COALESCE(p_received_date, NOW()), p_number,
    NULLIF(TRIM(p_notation), ''), NULLIF(TRIM(p_document_code), ''),
    TRIM(p_abstract), NULLIF(TRIM(p_publish_unit), ''), p_publish_date,
    NULLIF(TRIM(p_signer), ''), p_sign_date,
    p_doc_book_id, p_doc_type_id, p_doc_field_id, COALESCE(p_secret_id, 1), COALESCE(p_urgent_id, 1),
    COALESCE(p_number_paper, 1), COALESCE(p_number_copies, 1), p_expired_date,
    NULLIF(TRIM(p_recipients), ''),
    COALESCE(p_is_received_paper, FALSE), p_created_by, p_created_by
  )
  RETURNING edoc.incoming_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tạo văn bản đến thành công'::TEXT, v_id;
END;
$$;

DO $$ BEGIN RAISE NOTICE '✅ 030-6: fn_incoming_doc_create updated'; END $$;

-- ============================================================
-- 7. SP: fn_outgoing_doc_get_list — thêm p_dept_ids
-- ============================================================
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
  p_page_size     INT       DEFAULT 20,
  p_dept_ids      INT[]     DEFAULT NULL          -- NEW
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
  doc_book_name   VARCHAR,
  doc_type_name   VARCHAR,
  doc_type_code   VARCHAR,
  doc_field_name  VARCHAR,
  drafting_unit_name VARCHAR,
  drafting_user_name VARCHAR,
  created_by_name VARCHAR,
  is_read         BOOLEAN,
  read_at         TIMESTAMPTZ,
  attachment_count BIGINT,
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
    WHERE
      CASE
        WHEN p_dept_ids IS NOT NULL THEN d.department_id = ANY(p_dept_ids)
        ELSE d.unit_id = p_unit_id
      END
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
    f.drafting_unit_id, f.drafting_user_id, f.publish_unit_id,
    f.publish_date, f.signer, f.sign_date, f.expired_date,
    f.doc_book_id, f.doc_type_id, f.doc_field_id,
    f.secret_id, f.urgent_id, f.number_paper, f.number_copies,
    f.recipients, f.approver, f.approved, f.is_handling, f.archive_status,
    f.created_by, f.created_at,
    f._doc_book_name, f._doc_type_name, f._doc_type_code, f._doc_field_name,
    f._drafting_unit_name, f._drafting_user_name, f._created_by_name,
    COALESCE(f._is_read, FALSE), f._read_at,
    f._attachment_count, f._total_count
  FROM filtered f;
END;
$$;

DO $$ BEGIN RAISE NOTICE '✅ 030-7: fn_outgoing_doc_get_list updated'; END $$;

-- ============================================================
-- 8. SP: fn_outgoing_doc_count_unread — thêm p_dept_ids
-- ============================================================
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_count_unread(
  p_unit_id   INT,
  p_staff_id  INT,
  p_dept_ids  INT[] DEFAULT NULL
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE v_count INT;
BEGIN
  SELECT COUNT(*)::INT INTO v_count
  FROM edoc.outgoing_docs d
  LEFT JOIN edoc.user_outgoing_docs uo ON uo.outgoing_doc_id = d.id AND uo.staff_id = p_staff_id
  WHERE
    CASE
      WHEN p_dept_ids IS NOT NULL THEN d.department_id = ANY(p_dept_ids)
      ELSE d.unit_id = p_unit_id
    END
    AND (uo.is_read IS NULL OR uo.is_read = FALSE);
  RETURN v_count;
END;
$$;

DO $$ BEGIN RAISE NOTICE '✅ 030-8: fn_outgoing_doc_count_unread updated'; END $$;

-- ============================================================
-- 9. SP: fn_outgoing_doc_create — thêm p_department_id
-- ============================================================
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
  p_created_by        INT        DEFAULT NULL,
  p_department_id     INT        DEFAULT NULL     -- NEW
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

  -- Resolve department_id from created_by if not provided
  IF p_department_id IS NULL AND p_created_by IS NOT NULL THEN
    SELECT s.department_id INTO p_department_id FROM public.staff s WHERE s.id = p_created_by;
  END IF;

  INSERT INTO edoc.outgoing_docs (
    unit_id, department_id, received_date, number, sub_number, notation, document_code,
    abstract, drafting_unit_id, drafting_user_id, publish_unit_id, publish_date,
    signer, sign_date, expired_date,
    number_paper, number_copies, secret_id, urgent_id,
    recipients, doc_book_id, doc_type_id, doc_field_id,
    created_by, updated_by
  ) VALUES (
    p_unit_id, COALESCE(p_department_id, p_unit_id), COALESCE(p_received_date, NOW()), p_number,
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

DO $$ BEGIN RAISE NOTICE '✅ 030-9: fn_outgoing_doc_create updated'; END $$;

-- ============================================================
-- 10. SP: fn_drafting_doc_get_list — thêm p_dept_ids
-- ============================================================
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
  p_page_size     INT       DEFAULT 20,
  p_dept_ids      INT[]     DEFAULT NULL          -- NEW
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
  doc_book_name   VARCHAR,
  doc_type_name   VARCHAR,
  doc_type_code   VARCHAR,
  doc_field_name  VARCHAR,
  drafting_unit_name VARCHAR,
  drafting_user_name VARCHAR,
  created_by_name VARCHAR,
  is_read         BOOLEAN,
  read_at         TIMESTAMPTZ,
  attachment_count BIGINT,
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
    WHERE
      CASE
        WHEN p_dept_ids IS NOT NULL THEN d.department_id = ANY(p_dept_ids)
        ELSE d.unit_id = p_unit_id
      END
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
    f.drafting_unit_id, f.drafting_user_id, f.publish_unit_id,
    f.publish_date, f.signer, f.sign_date,
    f.doc_book_id, f.doc_type_id, f.doc_field_id,
    f.secret_id, f.urgent_id, f.number_paper, f.number_copies,
    f.expired_date, f.recipients, f.approver, f.approved,
    f.is_released, f.released_date,
    f.created_by, f.created_at,
    f._doc_book_name, f._doc_type_name, f._doc_type_code, f._doc_field_name,
    f._drafting_unit_name, f._drafting_user_name, f._created_by_name,
    COALESCE(f._is_read, FALSE), f._read_at,
    f._attachment_count, f._total_count
  FROM filtered f;
END;
$$;

DO $$ BEGIN RAISE NOTICE '✅ 030-10: fn_drafting_doc_get_list updated'; END $$;

-- ============================================================
-- 11. SP: fn_drafting_doc_count_unread — thêm p_dept_ids
-- ============================================================
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_count_unread(
  p_unit_id   INT,
  p_staff_id  INT,
  p_dept_ids  INT[] DEFAULT NULL
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE v_count INT;
BEGIN
  SELECT COUNT(*)::INT INTO v_count
  FROM edoc.drafting_docs d
  LEFT JOIN edoc.user_drafting_docs ud ON ud.drafting_doc_id = d.id AND ud.staff_id = p_staff_id
  WHERE
    CASE
      WHEN p_dept_ids IS NOT NULL THEN d.department_id = ANY(p_dept_ids)
      ELSE d.unit_id = p_unit_id
    END
    AND (ud.is_read IS NULL OR ud.is_read = FALSE);
  RETURN v_count;
END;
$$;

DO $$ BEGIN RAISE NOTICE '✅ 030-11: fn_drafting_doc_count_unread updated'; END $$;

-- ============================================================
-- 12. SP: fn_drafting_doc_create — thêm p_department_id
-- ============================================================
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
  p_created_by        INT        DEFAULT NULL,
  p_department_id     INT        DEFAULT NULL     -- NEW
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
    p_number := edoc.fn_drafting_doc_get_next_number(p_doc_book_id, p_unit_id);
  END IF;

  -- Resolve department_id from created_by if not provided
  IF p_department_id IS NULL AND p_created_by IS NOT NULL THEN
    SELECT s.department_id INTO p_department_id FROM public.staff s WHERE s.id = p_created_by;
  END IF;

  INSERT INTO edoc.drafting_docs (
    unit_id, department_id, received_date, number, sub_number, notation, document_code,
    abstract, drafting_unit_id, drafting_user_id, publish_unit_id, publish_date,
    signer, sign_date, doc_book_id, doc_type_id, doc_field_id,
    secret_id, urgent_id, number_paper, number_copies, expired_date,
    recipients, created_by, updated_by
  ) VALUES (
    p_unit_id, COALESCE(p_department_id, p_unit_id), COALESCE(p_received_date, NOW()), p_number,
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

DO $$ BEGIN RAISE NOTICE '✅ 030-12: fn_drafting_doc_create updated'; END $$;

-- ============================================================
-- 13. SP: fn_handling_doc_get_list — đổi sang subtree
-- (Đã có p_department_id, đổi thành p_dept_ids)
-- ============================================================
DROP FUNCTION IF EXISTS edoc.fn_handling_doc_get_list(INT, INT, INT, INT, TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, INT, INT);
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_get_list(
  p_unit_id       INT,
  p_dept_ids      INT[]     DEFAULT NULL,         -- CHANGED from p_department_id INT
  p_staff_id      INT       DEFAULT NULL,
  p_status        INT       DEFAULT NULL,
  p_filter_type   TEXT      DEFAULT NULL,
  p_keyword       TEXT      DEFAULT NULL,
  p_from_date     TIMESTAMPTZ DEFAULT NULL,
  p_to_date       TIMESTAMPTZ DEFAULT NULL,
  p_page          INT DEFAULT 1,
  p_page_size     INT DEFAULT 20
)
RETURNS TABLE (
  id              BIGINT,
  name            VARCHAR,
  start_date      TIMESTAMPTZ,
  end_date        TIMESTAMPTZ,
  status          SMALLINT,
  curator_id      INT,
  curator_name    TEXT,
  signer_id       INT,
  signer_name     TEXT,
  progress        SMALLINT,
  doc_field_name  VARCHAR,
  doc_type_name   VARCHAR,
  created_at      TIMESTAMPTZ,
  total_count     BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT
      h.id,
      h.name,
      h.start_date,
      h.end_date,
      h.status,
      h.curator       AS curator_id,
      CONCAT(sc.last_name, ' ', sc.first_name) AS curator_name,
      h.signer        AS signer_id,
      CONCAT(ss.last_name, ' ', ss.first_name) AS signer_name,
      h.progress,
      df.name         AS doc_field_name,
      dt.name         AS doc_type_name,
      h.created_at
    FROM edoc.handling_docs h
    LEFT JOIN public.staff sc ON sc.id = h.curator
    LEFT JOIN public.staff ss ON ss.id = h.signer
    LEFT JOIN edoc.doc_fields df ON df.id = h.doc_field_id
    LEFT JOIN edoc.doc_types dt ON dt.id = h.doc_type_id
    WHERE
      CASE
        WHEN p_dept_ids IS NOT NULL THEN h.department_id = ANY(p_dept_ids)
        ELSE h.unit_id = p_unit_id
      END
      AND (p_status IS NULL OR p_status = -99 OR h.status = p_status)
      AND (
        p_filter_type IS NULL OR p_filter_type = 'all' OR
        (p_filter_type = 'created_by_me'    AND h.created_by = p_staff_id) OR
        (p_filter_type = 'rejected'         AND h.status = -1 AND h.created_by = p_staff_id) OR
        (p_filter_type = 'returned'         AND h.status = -2) OR
        (p_filter_type = 'pending_primary'  AND h.status = 0 AND EXISTS (
          SELECT 1 FROM edoc.staff_handling_docs shd WHERE shd.handling_doc_id = h.id AND shd.staff_id = p_staff_id AND shd.role = 1
        )) OR
        (p_filter_type = 'pending_coord'    AND h.status IN (0, 1) AND EXISTS (
          SELECT 1 FROM edoc.staff_handling_docs shd WHERE shd.handling_doc_id = h.id AND shd.staff_id = p_staff_id AND shd.role = 2
        )) OR
        (p_filter_type = 'submitting'       AND h.status = 2) OR
        (p_filter_type = 'in_progress'      AND h.status = 1) OR
        (p_filter_type = 'proposed_complete' AND h.status = 3) OR
        (p_filter_type = 'completed'        AND h.status = 4)
      )
      AND (p_keyword IS NULL OR TRIM(p_keyword) = '' OR h.name ILIKE '%' || p_keyword || '%')
      AND (p_from_date IS NULL OR h.start_date >= p_from_date)
      AND (p_to_date IS NULL OR h.start_date <= p_to_date)
  )
  SELECT
    f.id, f.name, f.start_date, f.end_date, f.status,
    f.curator_id, f.curator_name::TEXT, f.signer_id, f.signer_name::TEXT,
    f.progress, f.doc_field_name, f.doc_type_name, f.created_at,
    COUNT(*) OVER() AS total_count
  FROM filtered f
  ORDER BY f.created_at DESC
  LIMIT p_page_size OFFSET v_offset;
END;
$$;

DO $$ BEGIN RAISE NOTICE '✅ 030-13: fn_handling_doc_get_list updated'; END $$;

-- ============================================================
-- 14. SP: fn_handling_doc_count_by_status — thêm p_dept_ids
-- ============================================================
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_count_by_status(
  p_unit_id   INT,
  p_staff_id  INT,
  p_dept_ids  INT[] DEFAULT NULL
)
RETURNS TABLE (filter_type TEXT, count BIGINT)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 'all'::TEXT,               COUNT(*)::BIGINT FROM edoc.handling_docs WHERE (CASE WHEN p_dept_ids IS NOT NULL THEN department_id = ANY(p_dept_ids) ELSE unit_id = p_unit_id END)
  UNION ALL
  SELECT 'created_by_me'::TEXT,     COUNT(*)::BIGINT FROM edoc.handling_docs WHERE (CASE WHEN p_dept_ids IS NOT NULL THEN department_id = ANY(p_dept_ids) ELSE unit_id = p_unit_id END) AND created_by = p_staff_id
  UNION ALL
  SELECT 'rejected'::TEXT,          COUNT(*)::BIGINT FROM edoc.handling_docs WHERE (CASE WHEN p_dept_ids IS NOT NULL THEN department_id = ANY(p_dept_ids) ELSE unit_id = p_unit_id END) AND status = -1 AND created_by = p_staff_id
  UNION ALL
  SELECT 'returned'::TEXT,          COUNT(*)::BIGINT FROM edoc.handling_docs WHERE (CASE WHEN p_dept_ids IS NOT NULL THEN department_id = ANY(p_dept_ids) ELSE unit_id = p_unit_id END) AND status = -2
  UNION ALL
  SELECT 'pending_primary'::TEXT,   COUNT(*)::BIGINT
    FROM edoc.handling_docs h
    WHERE (CASE WHEN p_dept_ids IS NOT NULL THEN h.department_id = ANY(p_dept_ids) ELSE h.unit_id = p_unit_id END) AND h.status = 0
      AND EXISTS (SELECT 1 FROM edoc.staff_handling_docs shd WHERE shd.handling_doc_id = h.id AND shd.staff_id = p_staff_id AND shd.role = 1)
  UNION ALL
  SELECT 'pending_coord'::TEXT,     COUNT(*)::BIGINT
    FROM edoc.handling_docs h
    WHERE (CASE WHEN p_dept_ids IS NOT NULL THEN h.department_id = ANY(p_dept_ids) ELSE h.unit_id = p_unit_id END) AND h.status IN (0, 1)
      AND EXISTS (SELECT 1 FROM edoc.staff_handling_docs shd WHERE shd.handling_doc_id = h.id AND shd.staff_id = p_staff_id AND shd.role = 2)
  UNION ALL
  SELECT 'submitting'::TEXT,        COUNT(*)::BIGINT FROM edoc.handling_docs WHERE (CASE WHEN p_dept_ids IS NOT NULL THEN department_id = ANY(p_dept_ids) ELSE unit_id = p_unit_id END) AND status = 2
  UNION ALL
  SELECT 'in_progress'::TEXT,       COUNT(*)::BIGINT FROM edoc.handling_docs WHERE (CASE WHEN p_dept_ids IS NOT NULL THEN department_id = ANY(p_dept_ids) ELSE unit_id = p_unit_id END) AND status = 1
  UNION ALL
  SELECT 'proposed_complete'::TEXT, COUNT(*)::BIGINT FROM edoc.handling_docs WHERE (CASE WHEN p_dept_ids IS NOT NULL THEN department_id = ANY(p_dept_ids) ELSE unit_id = p_unit_id END) AND status = 3
  UNION ALL
  SELECT 'completed'::TEXT,         COUNT(*)::BIGINT FROM edoc.handling_docs WHERE (CASE WHEN p_dept_ids IS NOT NULL THEN department_id = ANY(p_dept_ids) ELSE unit_id = p_unit_id END) AND status = 4;
END;
$$;

DO $$ BEGIN RAISE NOTICE '✅ 030-14: fn_handling_doc_count_by_status updated'; END $$;

-- ============================================================
-- 15. SP: fn_dashboard_get_stats — thêm p_dept_ids
-- ============================================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_get_stats(
  p_staff_id INT,
  p_unit_id  INT,
  p_dept_ids INT[] DEFAULT NULL
) RETURNS TABLE (
  incoming_unread  BIGINT,
  outgoing_pending BIGINT,
  handling_total   BIGINT,
  handling_overdue BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    (
      SELECT COUNT(*)
      FROM edoc.user_incoming_docs uid
      INNER JOIN edoc.incoming_docs ind ON ind.id = uid.incoming_doc_id
      WHERE uid.staff_id = p_staff_id
        AND uid.is_read = FALSE
        AND (CASE WHEN p_dept_ids IS NOT NULL THEN ind.department_id = ANY(p_dept_ids) ELSE ind.unit_id = p_unit_id END)
    ) AS incoming_unread,

    (
      SELECT COUNT(*)
      FROM edoc.outgoing_docs
      WHERE (CASE WHEN p_dept_ids IS NOT NULL THEN department_id = ANY(p_dept_ids) ELSE unit_id = p_unit_id END)
        AND approved = FALSE
    ) AS outgoing_pending,

    (
      SELECT COUNT(*)
      FROM edoc.handling_docs
      WHERE (CASE WHEN p_dept_ids IS NOT NULL THEN department_id = ANY(p_dept_ids) ELSE unit_id = p_unit_id END)
    ) AS handling_total,

    (
      SELECT COUNT(*)
      FROM edoc.handling_docs
      WHERE (CASE WHEN p_dept_ids IS NOT NULL THEN department_id = ANY(p_dept_ids) ELSE unit_id = p_unit_id END)
        AND end_date IS NOT NULL
        AND end_date < NOW()
        AND status != 4
    ) AS handling_overdue;
END;
$$;

DO $$ BEGIN RAISE NOTICE '✅ 030-15: fn_dashboard_get_stats updated'; END $$;

-- ============================================================
-- 16. SP: fn_dashboard_recent_incoming — thêm p_dept_ids
-- ============================================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_recent_incoming(
  p_unit_id INT,
  p_limit   INT DEFAULT 10,
  p_dept_ids INT[] DEFAULT NULL
) RETURNS TABLE (
  id            BIGINT,
  doc_code      VARCHAR,
  abstract      TEXT,
  received_date TIMESTAMPTZ,
  urgency_name  VARCHAR,
  sender_name   VARCHAR
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    d.id,
    COALESCE(NULLIF(d.notation, ''), d.document_code, '')::VARCHAR AS doc_code,
    d.abstract,
    d.received_date,
    CASE d.urgent_id
      WHEN 1 THEN 'Thường'
      WHEN 2 THEN 'Khẩn'
      WHEN 3 THEN 'Hỏa tốc'
      ELSE 'Thường'
    END::VARCHAR AS urgency_name,
    COALESCE(d.publish_unit, '')::VARCHAR AS sender_name
  FROM edoc.incoming_docs d
  WHERE
    CASE
      WHEN p_dept_ids IS NOT NULL THEN d.department_id = ANY(p_dept_ids)
      ELSE d.unit_id = p_unit_id
    END
  ORDER BY d.received_date DESC NULLS LAST, d.created_at DESC
  LIMIT COALESCE(p_limit, 10);
END;
$$;

DO $$ BEGIN RAISE NOTICE '✅ 030-16: fn_dashboard_recent_incoming updated'; END $$;

-- ============================================================
-- 17. SP: fn_dashboard_recent_outgoing — thêm p_dept_ids
-- ============================================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_recent_outgoing(
  p_unit_id INT,
  p_limit   INT DEFAULT 10,
  p_dept_ids INT[] DEFAULT NULL
) RETURNS TABLE (
  id            BIGINT,
  doc_code      VARCHAR,
  abstract      TEXT,
  sent_date     TIMESTAMPTZ,
  doc_type_name VARCHAR
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    d.id,
    COALESCE(NULLIF(d.notation, ''), d.document_code, '')::VARCHAR AS doc_code,
    d.abstract,
    COALESCE(d.publish_date, d.received_date, d.created_at) AS sent_date,
    COALESCE(dt.name, '')::VARCHAR AS doc_type_name
  FROM edoc.outgoing_docs d
  LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
  WHERE
    CASE
      WHEN p_dept_ids IS NOT NULL THEN d.department_id = ANY(p_dept_ids)
      ELSE d.unit_id = p_unit_id
    END
  ORDER BY COALESCE(d.publish_date, d.received_date, d.created_at) DESC
  LIMIT COALESCE(p_limit, 10);
END;
$$;

DO $$ BEGIN RAISE NOTICE '✅ 030-17: fn_dashboard_recent_outgoing updated'; END $$;

-- ============================================================
-- DONE
-- ============================================================
DO $$ BEGIN RAISE NOTICE '========================================'; END $$;
DO $$ BEGIN RAISE NOTICE '✅ Migration 030 COMPLETE'; END $$;
DO $$ BEGIN RAISE NOTICE '  - fn_get_department_subtree helper'; END $$;
DO $$ BEGIN RAISE NOTICE '  - department_id added to 3 doc tables'; END $$;
DO $$ BEGIN RAISE NOTICE '  - 14 SPs updated with p_dept_ids'; END $$;
DO $$ BEGIN RAISE NOTICE '========================================'; END $$;

COMMIT;
