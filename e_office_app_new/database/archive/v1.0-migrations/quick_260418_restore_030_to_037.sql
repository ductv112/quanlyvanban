-- ==== 030_department_subtree_permissions ====
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

-- ==== 031_fix_null_means_all ====
-- ================================================================
-- Migration 031: Fix WHERE logic — NULL = show all (admin)
-- Thay CASE fallback unit_id bằng (IS NULL OR ANY)
-- ================================================================
BEGIN;

-- 1. fn_incoming_doc_count_unread
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_count_unread(
  p_unit_id INT, p_staff_id INT, p_dept_ids INT[] DEFAULT NULL
) RETURNS INT LANGUAGE plpgsql AS $$
DECLARE v_count INT;
BEGIN
  SELECT COUNT(*)::INT INTO v_count
  FROM edoc.incoming_docs d
  LEFT JOIN edoc.user_incoming_docs uid ON uid.incoming_doc_id = d.id AND uid.staff_id = p_staff_id
  WHERE (p_dept_ids IS NULL OR d.department_id = ANY(p_dept_ids))
    AND (uid.is_read IS NULL OR uid.is_read = FALSE);
  RETURN v_count;
END; $$;

-- 2. fn_outgoing_doc_count_unread
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_count_unread(
  p_unit_id INT, p_staff_id INT, p_dept_ids INT[] DEFAULT NULL
) RETURNS INT LANGUAGE plpgsql AS $$
DECLARE v_count INT;
BEGIN
  SELECT COUNT(*)::INT INTO v_count
  FROM edoc.outgoing_docs d
  LEFT JOIN edoc.user_outgoing_docs uo ON uo.outgoing_doc_id = d.id AND uo.staff_id = p_staff_id
  WHERE (p_dept_ids IS NULL OR d.department_id = ANY(p_dept_ids))
    AND (uo.is_read IS NULL OR uo.is_read = FALSE);
  RETURN v_count;
END; $$;

-- 3. fn_drafting_doc_count_unread
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_count_unread(
  p_unit_id INT, p_staff_id INT, p_dept_ids INT[] DEFAULT NULL
) RETURNS INT LANGUAGE plpgsql AS $$
DECLARE v_count INT;
BEGIN
  SELECT COUNT(*)::INT INTO v_count
  FROM edoc.drafting_docs d
  LEFT JOIN edoc.user_drafting_docs ud ON ud.drafting_doc_id = d.id AND ud.staff_id = p_staff_id
  WHERE (p_dept_ids IS NULL OR d.department_id = ANY(p_dept_ids))
    AND (ud.is_read IS NULL OR ud.is_read = FALSE);
  RETURN v_count;
END; $$;

-- 4. fn_handling_doc_count_by_status
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_count_by_status(
  p_unit_id INT, p_staff_id INT, p_dept_ids INT[] DEFAULT NULL
) RETURNS TABLE (filter_type TEXT, count BIGINT) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT 'all'::TEXT,               COUNT(*)::BIGINT FROM edoc.handling_docs WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids))
  UNION ALL
  SELECT 'created_by_me'::TEXT,     COUNT(*)::BIGINT FROM edoc.handling_docs WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids)) AND created_by = p_staff_id
  UNION ALL
  SELECT 'rejected'::TEXT,          COUNT(*)::BIGINT FROM edoc.handling_docs WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids)) AND status = -1 AND created_by = p_staff_id
  UNION ALL
  SELECT 'returned'::TEXT,          COUNT(*)::BIGINT FROM edoc.handling_docs WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids)) AND status = -2
  UNION ALL
  SELECT 'pending_primary'::TEXT,   COUNT(*)::BIGINT
    FROM edoc.handling_docs h
    WHERE (p_dept_ids IS NULL OR h.department_id = ANY(p_dept_ids)) AND h.status = 0
      AND EXISTS (SELECT 1 FROM edoc.staff_handling_docs shd WHERE shd.handling_doc_id = h.id AND shd.staff_id = p_staff_id AND shd.role = 1)
  UNION ALL
  SELECT 'pending_coord'::TEXT,     COUNT(*)::BIGINT
    FROM edoc.handling_docs h
    WHERE (p_dept_ids IS NULL OR h.department_id = ANY(p_dept_ids)) AND h.status IN (0, 1)
      AND EXISTS (SELECT 1 FROM edoc.staff_handling_docs shd WHERE shd.handling_doc_id = h.id AND shd.staff_id = p_staff_id AND shd.role = 2)
  UNION ALL
  SELECT 'submitting'::TEXT,        COUNT(*)::BIGINT FROM edoc.handling_docs WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids)) AND status = 2
  UNION ALL
  SELECT 'in_progress'::TEXT,       COUNT(*)::BIGINT FROM edoc.handling_docs WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids)) AND status = 1
  UNION ALL
  SELECT 'proposed_complete'::TEXT, COUNT(*)::BIGINT FROM edoc.handling_docs WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids)) AND status = 3
  UNION ALL
  SELECT 'completed'::TEXT,         COUNT(*)::BIGINT FROM edoc.handling_docs WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids)) AND status = 4;
END; $$;

-- 5. fn_dashboard_get_stats
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_get_stats(
  p_staff_id INT, p_unit_id INT, p_dept_ids INT[] DEFAULT NULL
) RETURNS TABLE (
  incoming_unread BIGINT, outgoing_pending BIGINT, handling_total BIGINT, handling_overdue BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY SELECT
    (SELECT COUNT(*) FROM edoc.user_incoming_docs uid
     INNER JOIN edoc.incoming_docs ind ON ind.id = uid.incoming_doc_id
     WHERE uid.staff_id = p_staff_id AND uid.is_read = FALSE
       AND (p_dept_ids IS NULL OR ind.department_id = ANY(p_dept_ids))
    ),
    (SELECT COUNT(*) FROM edoc.outgoing_docs
     WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids)) AND approved = FALSE
    ),
    (SELECT COUNT(*) FROM edoc.handling_docs
     WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids))
    ),
    (SELECT COUNT(*) FROM edoc.handling_docs
     WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids))
       AND end_date IS NOT NULL AND end_date < NOW() AND status != 4
    );
END; $$;

-- 6. fn_dashboard_recent_incoming
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_recent_incoming(
  p_unit_id INT, p_limit INT DEFAULT 10, p_dept_ids INT[] DEFAULT NULL
) RETURNS TABLE (
  id BIGINT, doc_code VARCHAR, abstract TEXT, received_date TIMESTAMPTZ, urgency_name VARCHAR, sender_name VARCHAR
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY SELECT d.id,
    COALESCE(NULLIF(d.notation, ''), d.document_code, '')::VARCHAR,
    d.abstract, d.received_date,
    CASE d.urgent_id WHEN 1 THEN 'Thường' WHEN 2 THEN 'Khẩn' WHEN 3 THEN 'Hỏa tốc' ELSE 'Thường' END::VARCHAR,
    COALESCE(d.publish_unit, '')::VARCHAR
  FROM edoc.incoming_docs d
  WHERE (p_dept_ids IS NULL OR d.department_id = ANY(p_dept_ids))
  ORDER BY d.received_date DESC NULLS LAST, d.created_at DESC
  LIMIT COALESCE(p_limit, 10);
END; $$;

-- 7. fn_dashboard_recent_outgoing
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_recent_outgoing(
  p_unit_id INT, p_limit INT DEFAULT 10, p_dept_ids INT[] DEFAULT NULL
) RETURNS TABLE (
  id BIGINT, doc_code VARCHAR, abstract TEXT, sent_date TIMESTAMPTZ, doc_type_name VARCHAR
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY SELECT d.id,
    COALESCE(NULLIF(d.notation, ''), d.document_code, '')::VARCHAR,
    d.abstract, COALESCE(d.publish_date, d.received_date, d.created_at),
    COALESCE(dt.name, '')::VARCHAR
  FROM edoc.outgoing_docs d LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
  WHERE (p_dept_ids IS NULL OR d.department_id = ANY(p_dept_ids))
  ORDER BY COALESCE(d.publish_date, d.received_date, d.created_at) DESC
  LIMIT COALESCE(p_limit, 10);
END; $$;

-- 8. fn_incoming_doc_get_list
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_get_list(INT, INT, INT, INT, INT, SMALLINT, BOOLEAN, BOOLEAN, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, TEXT, INT, INT, INT, INT, INT[]);
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_get_list(
  p_unit_id INT, p_staff_id INT,
  p_doc_book_id INT DEFAULT NULL, p_doc_type_id INT DEFAULT NULL, p_doc_field_id INT DEFAULT NULL,
  p_urgent_id SMALLINT DEFAULT NULL, p_is_read BOOLEAN DEFAULT NULL, p_approved BOOLEAN DEFAULT NULL,
  p_from_date TIMESTAMPTZ DEFAULT NULL, p_to_date TIMESTAMPTZ DEFAULT NULL, p_keyword TEXT DEFAULT NULL,
  p_signer TEXT DEFAULT NULL, p_from_number INT DEFAULT NULL, p_to_number INT DEFAULT NULL,
  p_page INT DEFAULT 1, p_page_size INT DEFAULT 20,
  p_dept_ids INT[] DEFAULT NULL
)
RETURNS TABLE (
  id BIGINT, unit_id INT, received_date TIMESTAMPTZ, number INT, notation VARCHAR,
  document_code VARCHAR, abstract TEXT, publish_unit VARCHAR, publish_date TIMESTAMPTZ,
  signer VARCHAR, sign_date TIMESTAMPTZ, doc_book_id INT, doc_type_id INT, doc_field_id INT,
  secret_id SMALLINT, urgent_id SMALLINT, number_paper INT, number_copies INT,
  expired_date TIMESTAMPTZ, recipients TEXT, sents TEXT,
  approver VARCHAR, approved BOOLEAN, is_handling BOOLEAN, is_received_paper BOOLEAN,
  archive_status BOOLEAN, created_by INT, created_at TIMESTAMPTZ,
  doc_book_name VARCHAR, doc_type_name VARCHAR, doc_type_code VARCHAR, doc_field_name VARCHAR,
  created_by_name VARCHAR, is_read BOOLEAN, read_at TIMESTAMPTZ,
  attachment_count BIGINT, total_count BIGINT
) LANGUAGE plpgsql AS $$
DECLARE v_offset INT; v_keyword TEXT; v_signer TEXT;
BEGIN
  v_offset := (GREATEST(p_page, 1) - 1) * p_page_size;
  v_keyword := NULLIF(TRIM(p_keyword), '');
  v_signer := NULLIF(TRIM(p_signer), '');
  RETURN QUERY
  WITH filtered AS (
    SELECT d.id AS doc_id, d.*,
      db.name AS _doc_book_name, dt.name AS _doc_type_name, dt.code AS _doc_type_code,
      df.name AS _doc_field_name, s.full_name AS _created_by_name,
      uid.is_read AS _is_read, uid.read_at AS _read_at,
      (SELECT COUNT(*) FROM edoc.attachment_incoming_docs a WHERE a.incoming_doc_id = d.id) AS _attachment_count,
      COUNT(*) OVER() AS _total_count
    FROM edoc.incoming_docs d
    LEFT JOIN edoc.doc_books db ON db.id = d.doc_book_id
    LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
    LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id
    LEFT JOIN public.staff s ON s.id = d.created_by
    LEFT JOIN edoc.user_incoming_docs uid ON uid.incoming_doc_id = d.id AND uid.staff_id = p_staff_id
    WHERE (p_dept_ids IS NULL OR d.department_id = ANY(p_dept_ids))
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
      AND (v_keyword IS NULL OR d.abstract ILIKE '%' || v_keyword || '%' OR d.notation ILIKE '%' || v_keyword || '%' OR d.publish_unit ILIKE '%' || v_keyword || '%' OR d.signer ILIKE '%' || v_keyword || '%' OR d.document_code ILIKE '%' || v_keyword || '%')
    ORDER BY d.received_date DESC, d.number DESC LIMIT p_page_size OFFSET v_offset
  )
  SELECT f.doc_id, f.unit_id, f.received_date, f.number, f.notation, f.document_code, f.abstract,
    f.publish_unit, f.publish_date, f.signer, f.sign_date, f.doc_book_id, f.doc_type_id, f.doc_field_id,
    f.secret_id, f.urgent_id, f.number_paper, f.number_copies, f.expired_date, f.recipients, f.sents,
    f.approver, f.approved, f.is_handling, f.is_received_paper, f.archive_status,
    f.created_by, f.created_at, f._doc_book_name, f._doc_type_name, f._doc_type_code, f._doc_field_name,
    f._created_by_name, COALESCE(f._is_read, FALSE), f._read_at, f._attachment_count, f._total_count
  FROM filtered f;
END; $$;

-- 9. fn_outgoing_doc_get_list
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_get_list(
  p_unit_id INT, p_staff_id INT,
  p_doc_book_id INT DEFAULT NULL, p_doc_type_id INT DEFAULT NULL, p_doc_field_id INT DEFAULT NULL,
  p_urgent_id SMALLINT DEFAULT NULL, p_approved BOOLEAN DEFAULT NULL,
  p_from_date TIMESTAMPTZ DEFAULT NULL, p_to_date TIMESTAMPTZ DEFAULT NULL, p_keyword TEXT DEFAULT NULL,
  p_page INT DEFAULT 1, p_page_size INT DEFAULT 20,
  p_dept_ids INT[] DEFAULT NULL
)
RETURNS TABLE (
  id BIGINT, unit_id INT, received_date TIMESTAMPTZ, number INT, sub_number VARCHAR,
  notation VARCHAR, document_code VARCHAR, abstract TEXT,
  drafting_unit_id INT, drafting_user_id INT, publish_unit_id INT,
  publish_date TIMESTAMPTZ, signer VARCHAR, sign_date TIMESTAMPTZ, expired_date TIMESTAMPTZ,
  doc_book_id INT, doc_type_id INT, doc_field_id INT, secret_id SMALLINT, urgent_id SMALLINT,
  number_paper INT, number_copies INT, recipients TEXT,
  approver VARCHAR, approved BOOLEAN, is_handling BOOLEAN, archive_status BOOLEAN,
  created_by INT, created_at TIMESTAMPTZ,
  doc_book_name VARCHAR, doc_type_name VARCHAR, doc_type_code VARCHAR, doc_field_name VARCHAR,
  drafting_unit_name VARCHAR, drafting_user_name VARCHAR, created_by_name VARCHAR,
  is_read BOOLEAN, read_at TIMESTAMPTZ, attachment_count BIGINT, total_count BIGINT
) LANGUAGE plpgsql AS $$
DECLARE v_offset INT; v_keyword TEXT;
BEGIN
  v_offset := (GREATEST(p_page, 1) - 1) * p_page_size;
  v_keyword := NULLIF(TRIM(p_keyword), '');
  RETURN QUERY
  WITH filtered AS (
    SELECT d.id AS doc_id, d.*,
      db.name AS _doc_book_name, dt.name AS _doc_type_name, dt.code AS _doc_type_code,
      df.name AS _doc_field_name, du.name AS _drafting_unit_name, ds.full_name AS _drafting_user_name,
      s.full_name AS _created_by_name, uo.is_read AS _is_read, uo.read_at AS _read_at,
      (SELECT COUNT(*) FROM edoc.attachment_outgoing_docs a WHERE a.outgoing_doc_id = d.id) AS _attachment_count,
      COUNT(*) OVER() AS _total_count
    FROM edoc.outgoing_docs d
    LEFT JOIN edoc.doc_books db ON db.id = d.doc_book_id LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
    LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id LEFT JOIN public.departments du ON du.id = d.drafting_unit_id
    LEFT JOIN public.staff ds ON ds.id = d.drafting_user_id LEFT JOIN public.staff s ON s.id = d.created_by
    LEFT JOIN edoc.user_outgoing_docs uo ON uo.outgoing_doc_id = d.id AND uo.staff_id = p_staff_id
    WHERE (p_dept_ids IS NULL OR d.department_id = ANY(p_dept_ids))
      AND (p_doc_book_id IS NULL OR d.doc_book_id = p_doc_book_id)
      AND (p_doc_type_id IS NULL OR d.doc_type_id = p_doc_type_id)
      AND (p_doc_field_id IS NULL OR d.doc_field_id = p_doc_field_id)
      AND (p_urgent_id IS NULL OR d.urgent_id = p_urgent_id)
      AND (p_approved IS NULL OR d.approved = p_approved)
      AND (p_from_date IS NULL OR d.received_date >= p_from_date)
      AND (p_to_date IS NULL OR d.received_date <= p_to_date)
      AND (v_keyword IS NULL OR d.abstract ILIKE '%' || v_keyword || '%' OR d.notation ILIKE '%' || v_keyword || '%' OR d.signer ILIKE '%' || v_keyword || '%' OR d.recipients ILIKE '%' || v_keyword || '%')
    ORDER BY d.received_date DESC, d.number DESC LIMIT p_page_size OFFSET v_offset
  )
  SELECT f.doc_id, f.unit_id, f.received_date, f.number, f.sub_number, f.notation, f.document_code, f.abstract,
    f.drafting_unit_id, f.drafting_user_id, f.publish_unit_id, f.publish_date, f.signer, f.sign_date, f.expired_date,
    f.doc_book_id, f.doc_type_id, f.doc_field_id, f.secret_id, f.urgent_id, f.number_paper, f.number_copies,
    f.recipients, f.approver, f.approved, f.is_handling, f.archive_status,
    f.created_by, f.created_at, f._doc_book_name, f._doc_type_name, f._doc_type_code, f._doc_field_name,
    f._drafting_unit_name, f._drafting_user_name, f._created_by_name,
    COALESCE(f._is_read, FALSE), f._read_at, f._attachment_count, f._total_count
  FROM filtered f;
END; $$;

-- 10. fn_drafting_doc_get_list
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_get_list(
  p_unit_id INT, p_staff_id INT,
  p_doc_book_id INT DEFAULT NULL, p_doc_type_id INT DEFAULT NULL, p_doc_field_id INT DEFAULT NULL,
  p_urgent_id SMALLINT DEFAULT NULL, p_is_released BOOLEAN DEFAULT NULL, p_approved BOOLEAN DEFAULT NULL,
  p_from_date TIMESTAMPTZ DEFAULT NULL, p_to_date TIMESTAMPTZ DEFAULT NULL, p_keyword TEXT DEFAULT NULL,
  p_page INT DEFAULT 1, p_page_size INT DEFAULT 20,
  p_dept_ids INT[] DEFAULT NULL
)
RETURNS TABLE (
  id BIGINT, unit_id INT, received_date TIMESTAMPTZ, number INT, sub_number VARCHAR,
  notation VARCHAR, document_code VARCHAR, abstract TEXT,
  drafting_unit_id INT, drafting_user_id INT, publish_unit_id INT,
  publish_date TIMESTAMPTZ, signer VARCHAR, sign_date TIMESTAMPTZ,
  doc_book_id INT, doc_type_id INT, doc_field_id INT, secret_id SMALLINT, urgent_id SMALLINT,
  number_paper INT, number_copies INT, expired_date TIMESTAMPTZ, recipients TEXT,
  approver VARCHAR, approved BOOLEAN, is_released BOOLEAN, released_date TIMESTAMPTZ,
  created_by INT, created_at TIMESTAMPTZ,
  doc_book_name VARCHAR, doc_type_name VARCHAR, doc_type_code VARCHAR, doc_field_name VARCHAR,
  drafting_unit_name VARCHAR, drafting_user_name VARCHAR, created_by_name VARCHAR,
  is_read BOOLEAN, read_at TIMESTAMPTZ, attachment_count BIGINT, total_count BIGINT
) LANGUAGE plpgsql AS $$
DECLARE v_offset INT; v_keyword TEXT;
BEGIN
  v_offset := (GREATEST(p_page, 1) - 1) * p_page_size;
  v_keyword := NULLIF(TRIM(p_keyword), '');
  RETURN QUERY
  WITH filtered AS (
    SELECT d.id AS doc_id, d.*,
      db.name AS _doc_book_name, dt.name AS _doc_type_name, dt.code AS _doc_type_code,
      df.name AS _doc_field_name, du.name AS _drafting_unit_name, ds.full_name AS _drafting_user_name,
      s.full_name AS _created_by_name, ud.is_read AS _is_read, ud.read_at AS _read_at,
      (SELECT COUNT(*) FROM edoc.attachment_drafting_docs a WHERE a.drafting_doc_id = d.id) AS _attachment_count,
      COUNT(*) OVER() AS _total_count
    FROM edoc.drafting_docs d
    LEFT JOIN edoc.doc_books db ON db.id = d.doc_book_id LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
    LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id LEFT JOIN public.departments du ON du.id = d.drafting_unit_id
    LEFT JOIN public.staff ds ON ds.id = d.drafting_user_id LEFT JOIN public.staff s ON s.id = d.created_by
    LEFT JOIN edoc.user_drafting_docs ud ON ud.drafting_doc_id = d.id AND ud.staff_id = p_staff_id
    WHERE (p_dept_ids IS NULL OR d.department_id = ANY(p_dept_ids))
      AND (p_doc_book_id IS NULL OR d.doc_book_id = p_doc_book_id)
      AND (p_doc_type_id IS NULL OR d.doc_type_id = p_doc_type_id)
      AND (p_doc_field_id IS NULL OR d.doc_field_id = p_doc_field_id)
      AND (p_urgent_id IS NULL OR d.urgent_id = p_urgent_id)
      AND (p_approved IS NULL OR d.approved = p_approved)
      AND (p_is_released IS NULL OR d.is_released = p_is_released)
      AND (p_from_date IS NULL OR d.received_date >= p_from_date)
      AND (p_to_date IS NULL OR d.received_date <= p_to_date)
      AND (v_keyword IS NULL OR d.abstract ILIKE '%' || v_keyword || '%' OR d.notation ILIKE '%' || v_keyword || '%' OR d.signer ILIKE '%' || v_keyword || '%' OR d.recipients ILIKE '%' || v_keyword || '%')
    ORDER BY d.received_date DESC, d.number DESC LIMIT p_page_size OFFSET v_offset
  )
  SELECT f.doc_id, f.unit_id, f.received_date, f.number, f.sub_number, f.notation, f.document_code, f.abstract,
    f.drafting_unit_id, f.drafting_user_id, f.publish_unit_id, f.publish_date, f.signer, f.sign_date,
    f.doc_book_id, f.doc_type_id, f.doc_field_id, f.secret_id, f.urgent_id, f.number_paper, f.number_copies,
    f.expired_date, f.recipients, f.approver, f.approved, f.is_released, f.released_date,
    f.created_by, f.created_at, f._doc_book_name, f._doc_type_name, f._doc_type_code, f._doc_field_name,
    f._drafting_unit_name, f._drafting_user_name, f._created_by_name,
    COALESCE(f._is_read, FALSE), f._read_at, f._attachment_count, f._total_count
  FROM filtered f;
END; $$;

-- 11. fn_handling_doc_get_list
DROP FUNCTION IF EXISTS edoc.fn_handling_doc_get_list(INT, INT[], INT, INT, TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, INT, INT);
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_get_list(
  p_unit_id INT, p_dept_ids INT[] DEFAULT NULL, p_staff_id INT DEFAULT NULL,
  p_status INT DEFAULT NULL, p_filter_type TEXT DEFAULT NULL, p_keyword TEXT DEFAULT NULL,
  p_from_date TIMESTAMPTZ DEFAULT NULL, p_to_date TIMESTAMPTZ DEFAULT NULL,
  p_page INT DEFAULT 1, p_page_size INT DEFAULT 20
)
RETURNS TABLE (
  id BIGINT, name VARCHAR, start_date TIMESTAMPTZ, end_date TIMESTAMPTZ, status SMALLINT,
  curator_id INT, curator_name TEXT, signer_id INT, signer_name TEXT,
  progress SMALLINT, doc_field_name VARCHAR, doc_type_name VARCHAR, created_at TIMESTAMPTZ, total_count BIGINT
) LANGUAGE plpgsql AS $$
DECLARE v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT h.id, h.name, h.start_date, h.end_date, h.status,
      h.curator AS curator_id, CONCAT(sc.last_name, ' ', sc.first_name) AS curator_name,
      h.signer AS signer_id, CONCAT(ss.last_name, ' ', ss.first_name) AS signer_name,
      h.progress, df.name AS doc_field_name, dt.name AS doc_type_name, h.created_at
    FROM edoc.handling_docs h
    LEFT JOIN public.staff sc ON sc.id = h.curator LEFT JOIN public.staff ss ON ss.id = h.signer
    LEFT JOIN edoc.doc_fields df ON df.id = h.doc_field_id LEFT JOIN edoc.doc_types dt ON dt.id = h.doc_type_id
    WHERE (p_dept_ids IS NULL OR h.department_id = ANY(p_dept_ids))
      AND (p_status IS NULL OR p_status = -99 OR h.status = p_status)
      AND (p_filter_type IS NULL OR p_filter_type = 'all' OR
        (p_filter_type = 'created_by_me' AND h.created_by = p_staff_id) OR
        (p_filter_type = 'rejected' AND h.status = -1 AND h.created_by = p_staff_id) OR
        (p_filter_type = 'returned' AND h.status = -2) OR
        (p_filter_type = 'pending_primary' AND h.status = 0 AND EXISTS (SELECT 1 FROM edoc.staff_handling_docs shd WHERE shd.handling_doc_id = h.id AND shd.staff_id = p_staff_id AND shd.role = 1)) OR
        (p_filter_type = 'pending_coord' AND h.status IN (0, 1) AND EXISTS (SELECT 1 FROM edoc.staff_handling_docs shd WHERE shd.handling_doc_id = h.id AND shd.staff_id = p_staff_id AND shd.role = 2)) OR
        (p_filter_type = 'submitting' AND h.status = 2) OR (p_filter_type = 'in_progress' AND h.status = 1) OR
        (p_filter_type = 'proposed_complete' AND h.status = 3) OR (p_filter_type = 'completed' AND h.status = 4))
      AND (p_keyword IS NULL OR TRIM(p_keyword) = '' OR h.name ILIKE '%' || p_keyword || '%')
      AND (p_from_date IS NULL OR h.start_date >= p_from_date)
      AND (p_to_date IS NULL OR h.start_date <= p_to_date)
  )
  SELECT f.id, f.name, f.start_date, f.end_date, f.status,
    f.curator_id, f.curator_name::TEXT, f.signer_id, f.signer_name::TEXT,
    f.progress, f.doc_field_name, f.doc_type_name, f.created_at,
    COUNT(*) OVER() AS total_count
  FROM filtered f ORDER BY f.created_at DESC LIMIT p_page_size OFFSET v_offset;
END; $$;

DO $$ BEGIN RAISE NOTICE '✅ Migration 031: All SPs fixed — NULL = show all'; END $$;
COMMIT;

-- ==== 032_remove_unit_id_dependency ====
-- ================================================================
-- Migration 032: Remove unit_id dependency
--
-- Goal: Eliminate direct dependency on unit_id by using department_id
--       + helper function fn_get_ancestor_unit() instead.
--
-- Parts:
--   1. Helper function fn_get_ancestor_unit
--   2. Trigger on staff table to auto-compute unit_id
--   3. ALTER TABLE — add department_id to data tables + backfill
--   4. Rewrite 68 stored procedures (Groups A, B, C)
--
-- NOTE: fn_get_department_subtree already exists from migration 030.
--       SPs already updated in 030/031 are NOT rewritten here.
-- ================================================================

BEGIN;

-- ============================================================
-- PART 1: Helper Function — fn_get_ancestor_unit
-- ============================================================

CREATE OR REPLACE FUNCTION public.fn_get_ancestor_unit(p_dept_id INT)
RETURNS INT
LANGUAGE sql STABLE
AS $$
  WITH RECURSIVE ancestors AS (
    SELECT id, parent_id, is_unit
    FROM public.departments
    WHERE id = p_dept_id AND is_deleted = FALSE
    UNION ALL
    SELECT d.id, d.parent_id, d.is_unit
    FROM public.departments d
    JOIN ancestors a ON d.id = a.parent_id
    WHERE d.is_deleted = FALSE
  )
  SELECT COALESCE(
    (SELECT id FROM ancestors WHERE is_unit = TRUE LIMIT 1),
    p_dept_id
  );
$$;

DO $$ BEGIN RAISE NOTICE '032-1: fn_get_ancestor_unit created'; END $$;

-- ============================================================
-- PART 2: Trigger on staff table
-- ============================================================

CREATE OR REPLACE FUNCTION public.fn_staff_auto_unit_id()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.unit_id := public.fn_get_ancestor_unit(NEW.department_id);
  RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS trg_staff_auto_unit_id ON public.staff;
CREATE TRIGGER trg_staff_auto_unit_id
  BEFORE INSERT OR UPDATE OF department_id ON public.staff
  FOR EACH ROW EXECUTE FUNCTION public.fn_staff_auto_unit_id();

DO $$ BEGIN RAISE NOTICE '032-2: trg_staff_auto_unit_id created'; END $$;

-- ============================================================
-- PART 3: ALTER TABLE — Add department_id to data tables
-- ============================================================

-- edoc.notices
ALTER TABLE edoc.notices ADD COLUMN IF NOT EXISTS department_id INT REFERENCES public.departments(id);
CREATE INDEX IF NOT EXISTS idx_notices_department ON edoc.notices(department_id);

-- edoc.inter_incoming_docs
ALTER TABLE edoc.inter_incoming_docs ADD COLUMN IF NOT EXISTS department_id INT REFERENCES public.departments(id);
CREATE INDEX IF NOT EXISTS idx_inter_incoming_department ON edoc.inter_incoming_docs(department_id);

-- edoc.doc_flows
ALTER TABLE edoc.doc_flows ADD COLUMN IF NOT EXISTS department_id INT REFERENCES public.departments(id);
CREATE INDEX IF NOT EXISTS idx_doc_flows_department ON edoc.doc_flows(department_id);

-- edoc.room_schedules
ALTER TABLE edoc.room_schedules ADD COLUMN IF NOT EXISTS department_id INT REFERENCES public.departments(id);
CREATE INDEX IF NOT EXISTS idx_room_schedules_department ON edoc.room_schedules(department_id);

-- public.calendar_events
ALTER TABLE public.calendar_events ADD COLUMN IF NOT EXISTS department_id INT REFERENCES public.departments(id);
CREATE INDEX IF NOT EXISTS idx_calendar_events_department ON public.calendar_events(department_id);

-- esto.warehouses
ALTER TABLE esto.warehouses ADD COLUMN IF NOT EXISTS department_id INT REFERENCES public.departments(id);
CREATE INDEX IF NOT EXISTS idx_warehouses_department ON esto.warehouses(department_id);

-- esto.records
ALTER TABLE esto.records ADD COLUMN IF NOT EXISTS department_id INT REFERENCES public.departments(id);
CREATE INDEX IF NOT EXISTS idx_records_department ON esto.records(department_id);

-- esto.borrow_requests
ALTER TABLE esto.borrow_requests ADD COLUMN IF NOT EXISTS department_id INT REFERENCES public.departments(id);
CREATE INDEX IF NOT EXISTS idx_borrow_requests_department ON esto.borrow_requests(department_id);

-- iso.documents
ALTER TABLE iso.documents ADD COLUMN IF NOT EXISTS department_id INT REFERENCES public.departments(id);
CREATE INDEX IF NOT EXISTS idx_documents_department ON iso.documents(department_id);

DO $$ BEGIN RAISE NOTICE '032-3a: department_id columns + indexes added'; END $$;

-- Backfill from created_by -> staff.department_id where possible
UPDATE edoc.notices n SET department_id = s.department_id
FROM public.staff s WHERE s.id = n.created_by AND n.department_id IS NULL;

UPDATE edoc.inter_incoming_docs d SET department_id = s.department_id
FROM public.staff s WHERE s.id = d.created_by AND d.department_id IS NULL;

UPDATE edoc.doc_flows d SET department_id = s.department_id
FROM public.staff s WHERE s.id = d.created_by AND d.department_id IS NULL;

UPDATE edoc.room_schedules d SET department_id = s.department_id
FROM public.staff s WHERE s.id = d.created_user_id AND d.department_id IS NULL;

UPDATE public.calendar_events d SET department_id = s.department_id
FROM public.staff s WHERE s.id = d.created_by AND d.department_id IS NULL;

UPDATE esto.warehouses d SET department_id = s.department_id
FROM public.staff s WHERE s.id = d.created_user_id AND d.department_id IS NULL;

UPDATE esto.records d SET department_id = s.department_id
FROM public.staff s WHERE s.id = d.created_user_id AND d.department_id IS NULL;

UPDATE esto.borrow_requests d SET department_id = s.department_id
FROM public.staff s WHERE s.id = d.created_user_id AND d.department_id IS NULL;

UPDATE iso.documents d SET department_id = s.department_id
FROM public.staff s WHERE s.id = d.created_user_id AND d.department_id IS NULL;

-- Fallback: department_id = unit_id for tables without created_by or where still NULL
UPDATE edoc.notices SET department_id = unit_id WHERE department_id IS NULL;
UPDATE edoc.inter_incoming_docs SET department_id = unit_id WHERE department_id IS NULL;
UPDATE edoc.doc_flows SET department_id = unit_id WHERE department_id IS NULL;
UPDATE edoc.room_schedules SET department_id = unit_id WHERE department_id IS NULL;
UPDATE public.calendar_events SET department_id = unit_id WHERE department_id IS NULL;
UPDATE esto.warehouses SET department_id = unit_id WHERE department_id IS NULL;
UPDATE esto.records SET department_id = unit_id WHERE department_id IS NULL;
UPDATE esto.borrow_requests SET department_id = unit_id WHERE department_id IS NULL;
UPDATE iso.documents SET department_id = unit_id WHERE department_id IS NULL;

DO $$ BEGIN RAISE NOTICE '032-3b: Backfill department_id complete'; END $$;


-- ############################################################################
-- PART 4: REWRITE STORED PROCEDURES
-- ############################################################################

-- ====================================================================
-- GROUP A: CREATE/UPDATE SPs — add p_department_id, auto-resolve unit_id
-- ====================================================================

-- --------------------------------------------------------------------
-- A.3 public.fn_role_create
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_role_create(
  p_unit_id INT DEFAULT NULL,
  p_name VARCHAR DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_created_by INT DEFAULT NULL,
  p_department_id INT DEFAULT NULL
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE v_id INT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));
  INSERT INTO public.roles (unit_id, name, description, created_by)
  VALUES (v_unit_id, p_name, p_description, p_created_by)
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-A3: fn_role_create rewritten'; END $$;

-- --------------------------------------------------------------------
-- A.4 edoc.fn_doc_book_create
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_doc_book_create(
  p_type_id     SMALLINT,
  p_unit_id     INT DEFAULT NULL,
  p_name        VARCHAR DEFAULT NULL,
  p_is_default  BOOLEAN DEFAULT FALSE,
  p_description TEXT DEFAULT NULL,
  p_created_by  INT DEFAULT NULL,
  p_department_id INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql
AS $$
DECLARE v_id INT; v_exists BOOLEAN; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên sổ văn bản không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF LENGTH(p_name) > 200 THEN
    RETURN QUERY SELECT FALSE, 'Tên sổ văn bản không được vượt quá 200 ký tự'::TEXT, 0;
    RETURN;
  END IF;

  SELECT EXISTS(
    SELECT 1 FROM edoc.doc_books
    WHERE type_id = p_type_id AND unit_id = v_unit_id
      AND LOWER(TRIM(name)) = LOWER(TRIM(p_name))
      AND is_deleted = FALSE
  ) INTO v_exists;

  IF v_exists THEN
    RETURN QUERY SELECT FALSE, 'Tên sổ văn bản đã tồn tại trong đơn vị'::TEXT, 0;
    RETURN;
  END IF;

  IF p_is_default THEN
    UPDATE edoc.doc_books SET is_default = FALSE
    WHERE type_id = p_type_id AND unit_id = v_unit_id AND is_deleted = FALSE;
  END IF;

  INSERT INTO edoc.doc_books (type_id, unit_id, name, is_default, description, created_by)
  VALUES (p_type_id, v_unit_id, TRIM(p_name), COALESCE(p_is_default, FALSE), p_description, p_created_by)
  RETURNING doc_books.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao so van ban thanh cong'::TEXT, v_id;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-A4: fn_doc_book_create rewritten'; END $$;

-- --------------------------------------------------------------------
-- A.5 edoc.fn_doc_book_set_default
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_doc_book_set_default(
  p_id      INT,
  p_type_id SMALLINT,
  p_unit_id INT DEFAULT NULL,
  p_department_id INT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  UPDATE edoc.doc_books SET is_default = FALSE
  WHERE type_id = p_type_id AND unit_id = v_unit_id AND is_deleted = FALSE;

  UPDATE edoc.doc_books SET is_default = TRUE
  WHERE id = p_id AND is_deleted = FALSE;

  RETURN FOUND;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-A5: fn_doc_book_set_default rewritten'; END $$;

-- --------------------------------------------------------------------
-- A.6 edoc.fn_doc_field_create
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_doc_field_create(
  p_unit_id INT DEFAULT NULL,
  p_code    VARCHAR DEFAULT NULL,
  p_name    VARCHAR DEFAULT NULL,
  p_department_id INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql
AS $$
DECLARE v_id INT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF p_code IS NULL OR TRIM(p_code) = '' THEN
    RETURN QUERY SELECT FALSE, 'Mã lĩnh vực không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên lĩnh vực không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF LENGTH(p_code) > 20 THEN
    RETURN QUERY SELECT FALSE, 'Mã lĩnh vực không được vượt quá 20 ký tự'::TEXT, 0;
    RETURN;
  END IF;
  IF LENGTH(p_name) > 200 THEN
    RETURN QUERY SELECT FALSE, 'Tên lĩnh vực không được vượt quá 200 ký tự'::TEXT, 0;
    RETURN;
  END IF;

  IF EXISTS(
    SELECT 1 FROM edoc.doc_fields
    WHERE unit_id = v_unit_id AND LOWER(TRIM(code)) = LOWER(TRIM(p_code))
  ) THEN
    RETURN QUERY SELECT FALSE, 'Mã lĩnh vực đã tồn tại trong đơn vị'::TEXT, 0;
    RETURN;
  END IF;

  INSERT INTO edoc.doc_fields (unit_id, code, name)
  VALUES (v_unit_id, TRIM(p_code), TRIM(p_name))
  RETURNING doc_fields.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao linh vuc thanh cong'::TEXT, v_id;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-A6: fn_doc_field_create rewritten'; END $$;

-- --------------------------------------------------------------------
-- A.7 edoc.fn_sms_template_create
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_sms_template_create(
  p_unit_id     INT DEFAULT NULL,
  p_name        VARCHAR DEFAULT NULL,
  p_content     TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_created_by  INT DEFAULT NULL,
  p_department_id INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql
AS $$
DECLARE v_id INT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên mẫu tin nhắn không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF p_content IS NULL OR TRIM(p_content) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nội dung mẫu tin nhắn không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF LENGTH(p_name) > 200 THEN
    RETURN QUERY SELECT FALSE, 'Tên mẫu tin nhắn không được vượt quá 200 ký tự'::TEXT, 0;
    RETURN;
  END IF;

  INSERT INTO edoc.sms_templates (unit_id, name, content, description, created_by)
  VALUES (v_unit_id, TRIM(p_name), TRIM(p_content), p_description, p_created_by)
  RETURNING sms_templates.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao mau tin nhan thanh cong'::TEXT, v_id;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-A7: fn_sms_template_create rewritten'; END $$;

-- --------------------------------------------------------------------
-- A.8 edoc.fn_email_template_create
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_email_template_create(
  p_unit_id     INT DEFAULT NULL,
  p_name        VARCHAR DEFAULT NULL,
  p_subject     VARCHAR DEFAULT NULL,
  p_content     TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_created_by  INT DEFAULT NULL,
  p_department_id INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql
AS $$
DECLARE v_id INT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên mẫu email không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF p_content IS NULL OR TRIM(p_content) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nội dung mẫu email không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF LENGTH(p_name) > 200 THEN
    RETURN QUERY SELECT FALSE, 'Tên mẫu email không được vượt quá 200 ký tự'::TEXT, 0;
    RETURN;
  END IF;
  IF p_subject IS NOT NULL AND LENGTH(p_subject) > 500 THEN
    RETURN QUERY SELECT FALSE, 'Tiêu đề email không được vượt quá 500 ký tự'::TEXT, 0;
    RETURN;
  END IF;

  INSERT INTO edoc.email_templates (unit_id, name, subject, content, description, created_by)
  VALUES (v_unit_id, TRIM(p_name), TRIM(p_subject), TRIM(p_content), p_description, p_created_by)
  RETURNING email_templates.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao mau email thanh cong'::TEXT, v_id;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-A8: fn_email_template_create rewritten'; END $$;

-- --------------------------------------------------------------------
-- A.9 edoc.fn_organization_upsert — special: unit_id is PK for org
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_organization_upsert(
  p_unit_id          INT DEFAULT NULL,
  p_code             VARCHAR DEFAULT NULL,
  p_name             VARCHAR DEFAULT NULL,
  p_address          TEXT DEFAULT NULL,
  p_phone            VARCHAR DEFAULT NULL,
  p_fax              VARCHAR DEFAULT NULL,
  p_email            VARCHAR DEFAULT NULL,
  p_email_doc        VARCHAR DEFAULT NULL,
  p_secretary        VARCHAR DEFAULT NULL,
  p_chairman_number  VARCHAR DEFAULT NULL,
  p_level            SMALLINT DEFAULT 1,
  p_is_exchange      BOOLEAN DEFAULT FALSE,
  p_updated_by       INT DEFAULT NULL,
  p_department_id    INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF NOT EXISTS(SELECT 1 FROM public.departments WHERE id = v_unit_id AND is_deleted = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Đơn vị không tồn tại'::TEXT;
    RETURN;
  END IF;

  IF p_code IS NOT NULL AND LENGTH(p_code) > 20 THEN
    RETURN QUERY SELECT FALSE, 'Mã cơ quan không được vượt quá 20 ký tự'::TEXT;
    RETURN;
  END IF;
  IF p_email IS NOT NULL AND LENGTH(p_email) > 100 THEN
    RETURN QUERY SELECT FALSE, 'Email không được vượt quá 100 ký tự'::TEXT;
    RETURN;
  END IF;
  IF p_phone IS NOT NULL AND LENGTH(p_phone) > 20 THEN
    RETURN QUERY SELECT FALSE, 'Số điện thoại không được vượt quá 20 ký tự'::TEXT;
    RETURN;
  END IF;

  INSERT INTO edoc.organizations (
    unit_id, code, name, address, phone, fax, email, email_doc,
    secretary, chairman_number, level, is_exchange,
    lgsp_system_id, lgsp_secret_key, updated_by, updated_at
  ) VALUES (
    v_unit_id, p_code, p_name, p_address, p_phone, p_fax, p_email, p_email_doc,
    p_secretary, p_chairman_number, p_level, p_is_exchange,
    NULL, NULL, p_updated_by, NOW()
  )
  ON CONFLICT (unit_id) DO UPDATE SET
    code             = EXCLUDED.code,
    name             = EXCLUDED.name,
    address          = EXCLUDED.address,
    phone            = EXCLUDED.phone,
    fax              = EXCLUDED.fax,
    email            = EXCLUDED.email,
    email_doc        = EXCLUDED.email_doc,
    secretary        = EXCLUDED.secretary,
    chairman_number  = EXCLUDED.chairman_number,
    level            = EXCLUDED.level,
    is_exchange      = EXCLUDED.is_exchange,
    updated_by       = EXCLUDED.updated_by,
    updated_at       = NOW();

  RETURN QUERY SELECT TRUE, 'Cap nhat thong tin co quan thanh cong'::TEXT;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-A9: fn_organization_upsert rewritten'; END $$;

-- --------------------------------------------------------------------
-- A.10 public.fn_config_upsert
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_config_upsert(
  p_unit_id     INT DEFAULT NULL,
  p_key         VARCHAR DEFAULT NULL,
  p_value       TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_department_id INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF p_key IS NULL OR TRIM(p_key) = '' THEN
    RETURN QUERY SELECT FALSE, 'Key cấu hình không được để trống'::TEXT;
    RETURN;
  END IF;
  IF LENGTH(p_key) > 100 THEN
    RETURN QUERY SELECT FALSE, 'Key cấu hình không được vượt quá 100 ký tự'::TEXT;
    RETURN;
  END IF;

  INSERT INTO public.configurations (unit_id, key, value, description)
  VALUES (v_unit_id, TRIM(p_key), p_value, p_description)
  ON CONFLICT (unit_id, key) DO UPDATE SET
    value       = EXCLUDED.value,
    description = COALESCE(EXCLUDED.description, configurations.description);

  RETURN QUERY SELECT TRUE, 'Cap nhat cau hinh thanh cong'::TEXT;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-A10: fn_config_upsert rewritten'; END $$;

-- --------------------------------------------------------------------
-- A.11 edoc.fn_signer_create
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_signer_create(
  p_unit_id       INT DEFAULT NULL,
  p_department_id INT DEFAULT NULL,
  p_staff_id      INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql
AS $$
DECLARE v_id INT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF p_staff_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Vui lòng chọn nhân viên'::TEXT, 0;
    RETURN;
  END IF;

  IF NOT EXISTS(SELECT 1 FROM public.staff s WHERE s.id = p_staff_id AND s.is_deleted = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Nhân viên không tồn tại'::TEXT, 0;
    RETURN;
  END IF;

  IF EXISTS(SELECT 1 FROM edoc.signers WHERE unit_id = v_unit_id AND staff_id = p_staff_id) THEN
    RETURN QUERY SELECT FALSE, 'Nhân viên đã có trong danh sách người ký'::TEXT, 0;
    RETURN;
  END IF;

  INSERT INTO edoc.signers (unit_id, department_id, staff_id)
  VALUES (v_unit_id, p_department_id, p_staff_id)
  RETURNING signers.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Them nguoi ky thanh cong'::TEXT, v_id;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-A11: fn_signer_create rewritten'; END $$;

-- --------------------------------------------------------------------
-- A.12 edoc.fn_work_group_create
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_work_group_create(
  p_unit_id    INT DEFAULT NULL,
  p_name       VARCHAR DEFAULT NULL,
  p_function   TEXT DEFAULT NULL,
  p_sort_order INT DEFAULT 0,
  p_created_by INT DEFAULT NULL,
  p_department_id INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql
AS $$
DECLARE v_id INT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên nhóm không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF LENGTH(p_name) > 200 THEN
    RETURN QUERY SELECT FALSE, 'Tên nhóm không được vượt quá 200 ký tự'::TEXT, 0;
    RETURN;
  END IF;

  IF EXISTS(
    SELECT 1 FROM edoc.work_groups
    WHERE unit_id = v_unit_id AND LOWER(TRIM(name)) = LOWER(TRIM(p_name))
      AND is_deleted = FALSE
  ) THEN
    RETURN QUERY SELECT FALSE, 'Tên nhóm đã tồn tại trong đơn vị'::TEXT, 0;
    RETURN;
  END IF;

  INSERT INTO edoc.work_groups (unit_id, name, function, sort_order, created_by)
  VALUES (v_unit_id, TRIM(p_name), p_function, p_sort_order, p_created_by)
  RETURNING work_groups.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao nhom thanh cong'::TEXT, v_id;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-A12: fn_work_group_create rewritten'; END $$;

-- --------------------------------------------------------------------
-- A.13 edoc.fn_doc_flow_create
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_doc_flow_create(
  p_unit_id       INT DEFAULT NULL,
  p_name          VARCHAR DEFAULT NULL,
  p_version       VARCHAR DEFAULT NULL,
  p_doc_field_id  INT DEFAULT NULL,
  p_created_by    INT DEFAULT NULL,
  p_department_id INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql
AS $$
DECLARE v_id INT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên quy trình không được để trống'::TEXT, 0::INT;
    RETURN;
  END IF;

  IF EXISTS (
    SELECT 1 FROM edoc.doc_flows
    WHERE unit_id = v_unit_id AND name = TRIM(p_name)
      AND (version = p_version OR (version IS NULL AND p_version IS NULL))
  ) THEN
    RETURN QUERY SELECT FALSE, 'Quy trình với tên và phiên bản này đã tồn tại'::TEXT, 0::INT;
    RETURN;
  END IF;

  INSERT INTO edoc.doc_flows (unit_id, name, version, doc_field_id, is_active, created_by, department_id)
  VALUES (v_unit_id, TRIM(p_name), NULLIF(TRIM(COALESCE(p_version, '')), ''), p_doc_field_id, TRUE, p_created_by, p_department_id)
  RETURNING edoc.doc_flows.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tạo quy trình thành công'::TEXT, v_id;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-A13: fn_doc_flow_create rewritten'; END $$;

-- --------------------------------------------------------------------
-- A.14 edoc.fn_handling_doc_create — already has p_department_id, just auto-resolve unit_id
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_create(
  p_unit_id       INT DEFAULT NULL,
  p_department_id INT DEFAULT NULL,
  p_doc_type_id   INT DEFAULT NULL,
  p_doc_field_id  INT DEFAULT NULL,
  p_name          VARCHAR DEFAULT NULL,
  p_comments      TEXT DEFAULT NULL,
  p_start_date    TIMESTAMPTZ DEFAULT NULL,
  p_end_date      TIMESTAMPTZ DEFAULT NULL,
  p_curator_id    INT DEFAULT NULL,
  p_signer_id     INT DEFAULT NULL,
  p_workflow_id   INT DEFAULT NULL,
  p_is_from_doc   BOOLEAN DEFAULT NULL,
  p_parent_id     BIGINT DEFAULT NULL,
  p_created_by    INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE v_id BIGINT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên hồ sơ công việc không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  IF p_start_date IS NOT NULL AND p_end_date IS NOT NULL AND p_end_date < p_start_date THEN
    RETURN QUERY SELECT FALSE, 'Hạn giải quyết phải sau hoặc bằng ngày mở'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.handling_docs (
    unit_id, department_id, doc_type_id, doc_field_id, name, comments,
    start_date, end_date, curator, signer, workflow_id, is_from_doc,
    parent_id, created_by, updated_by
  ) VALUES (
    v_unit_id, p_department_id, p_doc_type_id, p_doc_field_id,
    TRIM(p_name), NULLIF(TRIM(COALESCE(p_comments, '')), ''),
    COALESCE(p_start_date, NOW()), p_end_date, p_curator_id, p_signer_id,
    p_workflow_id, COALESCE(p_is_from_doc, FALSE), p_parent_id,
    p_created_by, p_created_by
  )
  RETURNING edoc.handling_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tạo hồ sơ công việc thành công'::TEXT, v_id;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-A14: fn_handling_doc_create rewritten'; END $$;

-- --------------------------------------------------------------------
-- A.15 edoc.fn_inter_incoming_create
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_inter_incoming_create(
  p_unit_id         INT DEFAULT NULL,
  p_notation        VARCHAR DEFAULT NULL,
  p_document_code   VARCHAR DEFAULT NULL,
  p_abstract        TEXT DEFAULT NULL,
  p_publish_unit    VARCHAR DEFAULT NULL,
  p_publish_date    DATE DEFAULT NULL,
  p_signer          VARCHAR DEFAULT NULL,
  p_sign_date       DATE DEFAULT NULL,
  p_expired_date    DATE DEFAULT NULL,
  p_doc_type_id     INT DEFAULT NULL,
  p_source_system   VARCHAR DEFAULT NULL,
  p_external_doc_id VARCHAR DEFAULT NULL,
  p_created_by      INT DEFAULT NULL,
  p_department_id   INT DEFAULT NULL
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
  v_id BIGINT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF NOT EXISTS (SELECT 1 FROM public.departments WHERE id = v_unit_id) THEN
    RETURN QUERY SELECT FALSE, 'Đơn vị không tồn tại'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.inter_incoming_docs (
    unit_id, department_id, notation, document_code, abstract,
    publish_unit, publish_date, signer, sign_date,
    expired_date, doc_type_id, source_system, external_doc_id,
    created_by, created_at, updated_at
  ) VALUES (
    v_unit_id, p_department_id, p_notation, p_document_code, p_abstract,
    p_publish_unit, p_publish_date, p_signer, p_sign_date,
    p_expired_date, p_doc_type_id, p_source_system, p_external_doc_id,
    p_created_by, NOW(), NOW()
  )
  RETURNING inter_incoming_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tạo văn bản liên thông thành công'::TEXT, v_id;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-A15: fn_inter_incoming_create rewritten'; END $$;

-- --------------------------------------------------------------------
-- A.16 edoc.fn_notice_create
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_notice_create(
  p_unit_id     INT DEFAULT NULL,
  p_title       VARCHAR DEFAULT NULL,
  p_content     TEXT DEFAULT NULL,
  p_notice_type VARCHAR DEFAULT NULL,
  p_created_by  INT DEFAULT NULL,
  p_department_id INT DEFAULT NULL
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
  v_id BIGINT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF p_title IS NULL OR TRIM(p_title) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tiêu đề thông báo không được để trống'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  IF p_content IS NULL OR TRIM(p_content) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nội dung thông báo không được để trống'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.notices (unit_id, department_id, title, content, notice_type, created_by, created_at)
  VALUES (v_unit_id, p_department_id, p_title, p_content, COALESCE(p_notice_type, 'system'), p_created_by, NOW())
  RETURNING notices.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tạo thông báo thành công'::TEXT, v_id;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-A16: fn_notice_create rewritten'; END $$;

-- --------------------------------------------------------------------
-- A.17 public.fn_calendar_event_create
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_calendar_event_create(
  p_title       VARCHAR,
  p_description TEXT,
  p_start_time  TIMESTAMP,
  p_end_time    TIMESTAMP,
  p_all_day     BOOLEAN,
  p_color       VARCHAR,
  p_repeat_type VARCHAR,
  p_scope       VARCHAR,
  p_unit_id     INT,
  p_created_by  INT,
  p_department_id INT DEFAULT NULL
) RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_new_id BIGINT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF p_title IS NULL OR TRIM(p_title) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tiêu đề sự kiện là bắt buộc'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;
  IF p_end_time < p_start_time THEN
    RETURN QUERY SELECT FALSE, 'Thời gian kết thúc phải sau thời gian bắt đầu'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;
  IF p_scope NOT IN ('personal', 'unit', 'leader') THEN
    RETURN QUERY SELECT FALSE, 'Phạm vi sự kiện không hợp lệ'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  INSERT INTO public.calendar_events (
    title, description, start_time, end_time, all_day,
    color, repeat_type, scope, unit_id, department_id, created_by
  ) VALUES (
    TRIM(p_title), p_description,
    p_start_time, p_end_time, COALESCE(p_all_day, FALSE),
    COALESCE(p_color, '#1B3A5C'), COALESCE(p_repeat_type, 'none'),
    p_scope, v_unit_id, p_department_id, p_created_by
  ) RETURNING calendar_events.id INTO v_new_id;

  RETURN QUERY SELECT TRUE, 'Tạo sự kiện thành công'::TEXT, v_new_id;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-A17: fn_calendar_event_create rewritten'; END $$;

-- --------------------------------------------------------------------
-- A.18 public.fn_calendar_event_update
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_calendar_event_update(
  p_id          BIGINT,
  p_title       VARCHAR,
  p_description TEXT,
  p_start_time  TIMESTAMP,
  p_end_time    TIMESTAMP,
  p_all_day     BOOLEAN,
  p_color       VARCHAR,
  p_repeat_type VARCHAR,
  p_scope       VARCHAR,
  p_unit_id     INT,
  p_staff_id    INT,
  p_department_id INT DEFAULT NULL
) RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_event public.calendar_events%ROWTYPE;
  v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  SELECT * INTO v_event FROM public.calendar_events WHERE id = p_id AND is_deleted = FALSE;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy sự kiện'::TEXT;
    RETURN;
  END IF;
  IF v_event.scope = 'personal' AND v_event.created_by != p_staff_id THEN
    RETURN QUERY SELECT FALSE, 'Bạn không có quyền chỉnh sửa sự kiện này'::TEXT;
    RETURN;
  END IF;
  IF p_end_time < p_start_time THEN
    RETURN QUERY SELECT FALSE, 'Thời gian kết thúc phải sau thời gian bắt đầu'::TEXT;
    RETURN;
  END IF;

  UPDATE public.calendar_events SET
    title       = TRIM(p_title),
    description = p_description,
    start_time  = p_start_time,
    end_time    = p_end_time,
    all_day     = COALESCE(p_all_day, FALSE),
    color       = COALESCE(p_color, '#1B3A5C'),
    repeat_type = COALESCE(p_repeat_type, 'none'),
    scope       = p_scope,
    unit_id     = v_unit_id,
    department_id = p_department_id,
    updated_at  = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Cập nhật sự kiện thành công'::TEXT;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-A18: fn_calendar_event_update rewritten'; END $$;

-- --------------------------------------------------------------------
-- A.19 esto.fn_warehouse_create
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION esto.fn_warehouse_create(
  p_unit_id          INT,
  p_type_id          INT,
  p_code             VARCHAR,
  p_name             VARCHAR,
  p_phone_number     VARCHAR,
  p_address          VARCHAR,
  p_status           BOOLEAN,
  p_description      TEXT,
  p_parent_id        INT,
  p_is_unit          BOOLEAN,
  p_warehouse_level  INT,
  p_limit_child      INT,
  p_position         VARCHAR,
  p_created_user_id  INT,
  p_department_id    INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id INT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên kho không được để trống'::TEXT, NULL::INT;
    RETURN;
  END IF;

  INSERT INTO esto.warehouses (
    unit_id, department_id, type_id, code, name, phone_number, address, status,
    description, parent_id, is_unit, warehouse_level, limit_child,
    "position", created_user_id
  ) VALUES (
    v_unit_id, p_department_id, p_type_id, NULLIF(TRIM(p_code),''), p_name, p_phone_number,
    p_address, COALESCE(p_status, true), p_description,
    COALESCE(p_parent_id, 0), COALESCE(p_is_unit, false),
    COALESCE(p_warehouse_level, 0), COALESCE(p_limit_child, 0),
    p_position, p_created_user_id
  ) RETURNING esto.warehouses.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo kho thành công'::TEXT, v_id;
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, 'Mã kho đã tồn tại trong đơn vị'::TEXT, NULL::INT;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-A19: fn_warehouse_create rewritten'; END $$;

-- --------------------------------------------------------------------
-- A.20 esto.fn_fond_create
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION esto.fn_fond_create(
  p_unit_id          INT,
  p_parent_id        INT,
  p_fond_code        VARCHAR,
  p_fond_name        VARCHAR,
  p_fond_history     TEXT,
  p_archives_time    VARCHAR,
  p_paper_total      DECIMAL,
  p_paper_digital    DECIMAL,
  p_keys_group       VARCHAR,
  p_other_type       VARCHAR,
  p_language         VARCHAR,
  p_lookup_tools     VARCHAR,
  p_coppy_number     DECIMAL,
  p_status           INT,
  p_description      TEXT,
  p_version          DECIMAL,
  p_created_user_id  INT,
  p_department_id    INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id INT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF TRIM(COALESCE(p_fond_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên phông không được để trống'::TEXT, NULL::INT;
    RETURN;
  END IF;

  INSERT INTO esto.fonds (
    unit_id, parent_id, fond_code, fond_name, fond_history, archives_time,
    paper_total, paper_digital, keys_group, other_type, language,
    lookup_tools, coppy_number, status, description, version, created_user_id
  ) VALUES (
    v_unit_id, COALESCE(p_parent_id, 0), NULLIF(TRIM(p_fond_code),''),
    p_fond_name, p_fond_history, p_archives_time, p_paper_total, p_paper_digital,
    p_keys_group, p_other_type, p_language, p_lookup_tools, p_coppy_number,
    COALESCE(p_status, 1), p_description, p_version, p_created_user_id
  ) RETURNING esto.fonds.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo phông thành công'::TEXT, v_id;
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, 'Mã phông đã tồn tại trong đơn vị'::TEXT, NULL::INT;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-A20: fn_fond_create rewritten'; END $$;

-- --------------------------------------------------------------------
-- A.21 esto.fn_record_create
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION esto.fn_record_create(
  p_unit_id                 INT,
  p_fond_id                 INT,
  p_warehouse_id            INT,
  p_file_code               VARCHAR,
  p_file_catalog            INT,
  p_file_notation           VARCHAR,
  p_title                   VARCHAR,
  p_maintenance             VARCHAR,
  p_rights                  VARCHAR,
  p_language                VARCHAR,
  p_start_date              DATE,
  p_complete_date           DATE,
  p_total_doc               INT,
  p_description             TEXT,
  p_infor_sign              VARCHAR,
  p_keyword                 VARCHAR,
  p_total_paper             DECIMAL,
  p_page_number             DECIMAL,
  p_format                  INT,
  p_archive_date            DATE,
  p_in_charge_staff_id      INT,
  p_reception_date          DATE,
  p_reception_from          INT,
  p_transfer_staff          VARCHAR,
  p_is_document_original    BOOLEAN,
  p_number_of_copy          INT,
  p_doc_field_id            INT,
  p_created_user_id         INT,
  p_department_id           INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id BIGINT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF TRIM(COALESCE(p_title, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tiêu đề hồ sơ không được để trống'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  INSERT INTO esto.records (
    unit_id, department_id, fond_id, warehouse_id, file_code, file_catalog, file_notation,
    title, maintenance, rights, language, start_date, complete_date, total_doc,
    description, infor_sign, keyword, total_paper, page_number, format,
    archive_date, in_charge_staff_id, reception_date, reception_from,
    transfer_staff, is_document_original, number_of_copy, doc_field_id,
    created_user_id
  ) VALUES (
    v_unit_id, p_department_id, p_fond_id, p_warehouse_id, p_file_code, p_file_catalog, p_file_notation,
    p_title, p_maintenance, p_rights, p_language, p_start_date, p_complete_date, p_total_doc,
    p_description, p_infor_sign, p_keyword, p_total_paper, p_page_number, COALESCE(p_format, 0),
    p_archive_date, p_in_charge_staff_id, p_reception_date, COALESCE(p_reception_from, 0),
    p_transfer_staff, p_is_document_original, p_number_of_copy, p_doc_field_id,
    p_created_user_id
  ) RETURNING esto.records.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo hồ sơ thành công'::TEXT, v_id;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-A21: fn_record_create rewritten'; END $$;

-- --------------------------------------------------------------------
-- A.22 esto.fn_borrow_request_create
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION esto.fn_borrow_request_create(
  p_name             VARCHAR,
  p_unit_id          INT,
  p_emergency        INT,
  p_notice           TEXT,
  p_borrow_date      DATE,
  p_created_user_id  INT,
  p_record_ids       INT[],
  p_department_id    INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id BIGINT; v_record_id INT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên yêu cầu không được để trống'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  INSERT INTO esto.borrow_requests (name, unit_id, department_id, emergency, notice, borrow_date, created_user_id, status)
  VALUES (p_name, v_unit_id, p_department_id, p_emergency, p_notice, p_borrow_date, p_created_user_id, 0)
  RETURNING esto.borrow_requests.id INTO v_id;

  IF p_record_ids IS NOT NULL THEN
    FOREACH v_record_id IN ARRAY p_record_ids LOOP
      INSERT INTO esto.borrow_request_records (borrow_request_id, record_id)
      VALUES (v_id, v_record_id)
      ON CONFLICT (borrow_request_id, record_id) DO NOTHING;
    END LOOP;
  END IF;

  RETURN QUERY SELECT true, 'Tạo yêu cầu mượn thành công'::TEXT, v_id;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-A22: fn_borrow_request_create rewritten'; END $$;

-- --------------------------------------------------------------------
-- A.23 iso.fn_document_create
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION iso.fn_document_create(
  p_unit_id          INT,
  p_category_id      INT,
  p_title            VARCHAR,
  p_description      TEXT,
  p_file_name        VARCHAR,
  p_file_path        VARCHAR,
  p_file_size        BIGINT,
  p_mime_type        VARCHAR,
  p_keyword          VARCHAR,
  p_status           INT,
  p_created_user_id  INT,
  p_department_id    INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id BIGINT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF TRIM(COALESCE(p_title, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tiêu đề tài liệu không được để trống'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  INSERT INTO iso.documents (
    unit_id, department_id, category_id, title, description, file_name, file_path,
    file_size, mime_type, keyword, status, created_user_id
  ) VALUES (
    v_unit_id, p_department_id, p_category_id, p_title, p_description, p_file_name, p_file_path,
    p_file_size, p_mime_type, p_keyword, COALESCE(p_status, 1), p_created_user_id
  ) RETURNING iso.documents.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo tài liệu thành công'::TEXT, v_id;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-A23: fn_document_create rewritten'; END $$;

-- --------------------------------------------------------------------
-- A.24 cont.fn_contract_type_create
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cont.fn_contract_type_create(
  p_unit_id          INT,
  p_parent_id        INT,
  p_code             VARCHAR,
  p_name             VARCHAR,
  p_note             TEXT,
  p_sort_order       INT,
  p_created_user_id  INT,
  p_department_id    INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id INT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên loại hợp đồng không được để trống'::TEXT, NULL::INT;
    RETURN;
  END IF;

  INSERT INTO cont.contract_types (unit_id, parent_id, code, name, note, sort_order, created_user_id)
  VALUES (v_unit_id, COALESCE(p_parent_id, 0), NULLIF(TRIM(p_code),''), p_name, p_note, COALESCE(p_sort_order, 0), p_created_user_id)
  RETURNING cont.contract_types.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo loại hợp đồng thành công'::TEXT, v_id;
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, 'Mã loại hợp đồng đã tồn tại'::TEXT, NULL::INT;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-A24: fn_contract_type_create rewritten'; END $$;

-- --------------------------------------------------------------------
-- A.25 cont.fn_contract_create
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cont.fn_contract_create(
  p_code_index        INT,
  p_contract_type_id  INT,
  p_department_id     INT,
  p_type_of_contract  INT,
  p_contact_id        INT,
  p_contact_name      VARCHAR,
  p_unit_id           INT,
  p_code              VARCHAR,
  p_sign_date         DATE,
  p_input_date        DATE,
  p_receive_date      DATE,
  p_name              VARCHAR,
  p_signer            VARCHAR,
  p_number            INT,
  p_ballot            VARCHAR,
  p_marker            VARCHAR,
  p_curator_name      VARCHAR,
  p_currency          VARCHAR,
  p_transporter       VARCHAR,
  p_staff_id          INT,
  p_note              TEXT,
  p_status            INT,
  p_amount            VARCHAR,
  p_payment_amount    DECIMAL,
  p_created_user_id   INT
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id INT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên hợp đồng không được để trống'::TEXT, NULL::INT;
    RETURN;
  END IF;

  INSERT INTO cont.contracts (
    code_index, contract_type_id, department_id, type_of_contract, contact_id,
    contact_name, unit_id, code, sign_date, input_date, receive_date, name,
    signer, number, ballot, marker, curator_name, currency, transporter,
    staff_id, note, status, amount, payment_amount, created_user_id
  ) VALUES (
    p_code_index, p_contract_type_id, p_department_id, COALESCE(p_type_of_contract, 0),
    p_contact_id, p_contact_name, v_unit_id, p_code, p_sign_date, p_input_date,
    p_receive_date, p_name, p_signer, p_number, p_ballot, p_marker, p_curator_name,
    p_currency, p_transporter, p_staff_id, p_note, COALESCE(p_status, 0),
    p_amount, p_payment_amount, p_created_user_id
  ) RETURNING cont.contracts.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo hợp đồng thành công'::TEXT, v_id;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-A25: fn_contract_create rewritten'; END $$;

-- --------------------------------------------------------------------
-- A.26 edoc.fn_room_create
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_room_create(
  p_unit_id          INT,
  p_name             VARCHAR,
  p_code             VARCHAR,
  p_location         VARCHAR,
  p_note             TEXT,
  p_sort_order       INT,
  p_show_in_calendar BOOLEAN,
  p_created_user_id  INT,
  p_department_id    INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id INT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên phòng họp không được để trống'::TEXT, NULL::INT;
    RETURN;
  END IF;

  INSERT INTO edoc.rooms (unit_id, name, code, location, note, sort_order, show_in_calendar, created_user_id)
  VALUES (v_unit_id, p_name, NULLIF(TRIM(p_code),''), p_location, p_note,
          COALESCE(p_sort_order, 0), COALESCE(p_show_in_calendar, true), p_created_user_id)
  RETURNING edoc.rooms.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo phòng họp thành công'::TEXT, v_id;
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, 'Mã phòng họp đã tồn tại'::TEXT, NULL::INT;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-A26: fn_room_create rewritten'; END $$;

-- --------------------------------------------------------------------
-- A.27 edoc.fn_meeting_type_create
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_meeting_type_create(
  p_unit_id          INT,
  p_name             VARCHAR,
  p_description      TEXT,
  p_sort_order       INT,
  p_created_user_id  INT,
  p_department_id    INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id INT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên loại cuộc họp không được để trống'::TEXT, NULL::INT;
    RETURN;
  END IF;

  INSERT INTO edoc.meeting_types (unit_id, name, description, sort_order, created_user_id)
  VALUES (v_unit_id, p_name, p_description, COALESCE(p_sort_order, 0), p_created_user_id)
  RETURNING edoc.meeting_types.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo loại cuộc họp thành công'::TEXT, v_id;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-A27: fn_meeting_type_create rewritten'; END $$;

-- --------------------------------------------------------------------
-- A.28 edoc.fn_room_schedule_create
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_room_schedule_create(
  p_unit_id          INT,
  p_room_id          INT,
  p_meeting_type_id  INT,
  p_name             VARCHAR,
  p_content          TEXT,
  p_component        VARCHAR,
  p_start_date       DATE,
  p_end_date         DATE,
  p_start_time       VARCHAR,
  p_end_time         VARCHAR,
  p_master_id        INT,
  p_secretary_id     INT,
  p_online_link      VARCHAR,
  p_created_user_id  INT,
  p_department_id    INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id INT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên cuộc họp không được để trống'::TEXT, NULL::INT;
    RETURN;
  END IF;

  IF p_start_date IS NULL THEN
    RETURN QUERY SELECT false, 'Ngày họp không được để trống'::TEXT, NULL::INT;
    RETURN;
  END IF;

  INSERT INTO edoc.room_schedules (
    unit_id, department_id, room_id, meeting_type_id, name, content, component,
    start_date, end_date, start_time, end_time, master_id, secretary_id,
    online_link, created_user_id
  ) VALUES (
    v_unit_id, p_department_id, p_room_id, p_meeting_type_id, p_name, p_content, p_component,
    p_start_date, p_end_date, p_start_time, p_end_time, p_master_id, p_secretary_id,
    p_online_link, p_created_user_id
  ) RETURNING edoc.room_schedules.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo cuộc họp thành công'::TEXT, v_id;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-A28: fn_room_schedule_create rewritten'; END $$;


-- ====================================================================
-- GROUP B: LIST SPs with subtree filter (add p_dept_ids INT[])
-- ====================================================================

-- --------------------------------------------------------------------
-- B.1 public.fn_staff_get_list
-- --------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.fn_staff_get_list(INT, INT, VARCHAR, BOOLEAN, INT, INT);
CREATE OR REPLACE FUNCTION public.fn_staff_get_list(
  p_unit_id INT DEFAULT NULL,
  p_department_id INT DEFAULT NULL,
  p_keyword VARCHAR DEFAULT NULL,
  p_is_locked BOOLEAN DEFAULT NULL,
  p_page INT DEFAULT 1,
  p_page_size INT DEFAULT 20,
  p_dept_ids INT[] DEFAULT NULL
)
RETURNS TABLE (
  id INT, username VARCHAR, full_name VARCHAR, first_name VARCHAR, last_name VARCHAR,
  email VARCHAR, phone VARCHAR, image VARCHAR, gender SMALLINT,
  department_id INT, department_name VARCHAR, unit_id INT, unit_name VARCHAR,
  position_id INT, position_name VARCHAR,
  is_admin BOOLEAN, is_locked BOOLEAN, is_represent_unit BOOLEAN, is_represent_department BOOLEAN,
  last_login_at TIMESTAMPTZ, created_at TIMESTAMPTZ, total_count BIGINT
)
LANGUAGE sql STABLE
AS $$
  SELECT
    s.id, s.username::VARCHAR, s.full_name::VARCHAR, s.first_name::VARCHAR, s.last_name::VARCHAR,
    s.email::VARCHAR, COALESCE(s.phone, s.mobile)::VARCHAR AS phone, s.image::VARCHAR, s.gender,
    s.department_id, d.name::VARCHAR AS department_name,
    s.unit_id, u.name::VARCHAR AS unit_name,
    s.position_id, p.name::VARCHAR AS position_name,
    s.is_admin, s.is_locked, s.is_represent_unit, s.is_represent_department,
    s.last_login_at, s.created_at,
    COUNT(*) OVER() AS total_count
  FROM public.staff s
  LEFT JOIN public.departments d ON d.id = s.department_id
  LEFT JOIN public.departments u ON u.id = s.unit_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  WHERE s.is_deleted = FALSE
    AND (p_dept_ids IS NULL OR s.department_id = ANY(p_dept_ids))
    AND (p_unit_id IS NULL OR s.unit_id = p_unit_id)
    AND (p_department_id IS NULL OR s.department_id = p_department_id)
    AND (p_keyword IS NULL OR s.full_name ILIKE '%' || p_keyword || '%' OR s.username ILIKE '%' || p_keyword || '%' OR s.email ILIKE '%' || p_keyword || '%')
    AND (p_is_locked IS NULL OR s.is_locked = p_is_locked)
  ORDER BY s.last_name, s.first_name
  OFFSET (p_page - 1) * p_page_size LIMIT p_page_size;
$$;

DO $$ BEGIN RAISE NOTICE '032-B1: fn_staff_get_list rewritten'; END $$;

-- --------------------------------------------------------------------
-- B.2 public.fn_directory_get_list
-- --------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.fn_directory_get_list(INT, INT, VARCHAR, INT, INT);
CREATE OR REPLACE FUNCTION public.fn_directory_get_list(
  p_unit_id       INT,
  p_department_id INT,
  p_search        VARCHAR,
  p_page          INT,
  p_page_size     INT,
  p_dept_ids      INT[] DEFAULT NULL
) RETURNS TABLE (
  id              INT,
  full_name       VARCHAR,
  position_name   VARCHAR,
  department_name VARCHAR,
  unit_name       VARCHAR,
  phone           VARCHAR,
  mobile          VARCHAR,
  email           VARCHAR,
  image           VARCHAR,
  total_count     BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
  v_limit  INT := COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  SELECT
    s.id,
    (s.last_name || ' ' || s.first_name)::VARCHAR AS full_name,
    pos.name::VARCHAR AS position_name,
    dep.name::VARCHAR AS department_name,
    unit.name::VARCHAR AS unit_name,
    s.phone,
    s.mobile,
    s.email,
    s.image,
    COUNT(*) OVER() AS total_count
  FROM public.staff s
  LEFT JOIN public.positions pos ON pos.id = s.position_id
  LEFT JOIN public.departments dep ON dep.id = s.department_id
  LEFT JOIN public.departments unit ON unit.id = s.unit_id
  WHERE s.is_locked = FALSE
    AND s.is_deleted = FALSE
    AND (p_dept_ids IS NULL OR s.department_id = ANY(p_dept_ids))
    AND (p_unit_id IS NULL OR s.unit_id = p_unit_id)
    AND (p_department_id IS NULL OR s.department_id = p_department_id)
    AND (
      p_search IS NULL OR TRIM(p_search) = '' OR
      (s.last_name || ' ' || s.first_name) ILIKE '%' || TRIM(p_search) || '%' OR
      s.phone ILIKE '%' || TRIM(p_search) || '%' OR
      s.mobile ILIKE '%' || TRIM(p_search) || '%' OR
      s.email ILIKE '%' || TRIM(p_search) || '%'
    )
  ORDER BY s.last_name ASC, s.first_name ASC
  OFFSET v_offset
  LIMIT v_limit;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-B2: fn_directory_get_list rewritten'; END $$;

-- --------------------------------------------------------------------
-- B.3 edoc.fn_signer_get_list
-- --------------------------------------------------------------------
DROP FUNCTION IF EXISTS edoc.fn_signer_get_list(INT, INT);
CREATE OR REPLACE FUNCTION edoc.fn_signer_get_list(
  p_unit_id       INT,
  p_department_id INT DEFAULT NULL,
  p_dept_ids      INT[] DEFAULT NULL
)
RETURNS TABLE (
  id INT, unit_id INT, department_id INT, staff_id INT,
  staff_name VARCHAR, position_name VARCHAR, department_name VARCHAR,
  sort_order INT
)
LANGUAGE sql STABLE
AS $$
  SELECT sg.id, sg.unit_id, sg.department_id, sg.staff_id,
         s.full_name::VARCHAR AS staff_name,
         p.name::VARCHAR AS position_name,
         d.name::VARCHAR AS department_name,
         sg.sort_order
  FROM edoc.signers sg
    JOIN public.staff s ON s.id = sg.staff_id
    LEFT JOIN public.positions p ON p.id = s.position_id
    LEFT JOIN public.departments d ON d.id = sg.department_id
  WHERE sg.unit_id = p_unit_id
    AND (p_dept_ids IS NULL OR sg.department_id = ANY(p_dept_ids))
    AND (p_department_id IS NULL OR sg.department_id = p_department_id)
  ORDER BY sg.sort_order, s.full_name;
$$;

DO $$ BEGIN RAISE NOTICE '032-B3: fn_signer_get_list rewritten'; END $$;

-- --------------------------------------------------------------------
-- B.4 edoc.fn_work_group_get_list
-- --------------------------------------------------------------------
DROP FUNCTION IF EXISTS edoc.fn_work_group_get_list(INT);
CREATE OR REPLACE FUNCTION edoc.fn_work_group_get_list(
  p_unit_id INT,
  p_dept_ids INT[] DEFAULT NULL
)
RETURNS TABLE (
  id INT, unit_id INT, name VARCHAR, function TEXT,
  sort_order INT, member_count BIGINT,
  created_by INT, created_at TIMESTAMPTZ
)
LANGUAGE sql STABLE
AS $$
  SELECT g.id, g.unit_id, g.name::VARCHAR, g.function,
         g.sort_order,
         (SELECT COUNT(*) FROM edoc.work_group_members m WHERE m.group_id = g.id) AS member_count,
         g.created_by, g.created_at
  FROM edoc.work_groups g
  WHERE g.unit_id = p_unit_id AND g.is_deleted = FALSE
  ORDER BY g.sort_order, g.name;
$$;

DO $$ BEGIN RAISE NOTICE '032-B4: fn_work_group_get_list rewritten'; END $$;

-- --------------------------------------------------------------------
-- B.5 edoc.fn_delegation_get_list
-- --------------------------------------------------------------------
DROP FUNCTION IF EXISTS edoc.fn_delegation_get_list(INT, INT);
CREATE OR REPLACE FUNCTION edoc.fn_delegation_get_list(
  p_unit_id  INT DEFAULT NULL,
  p_staff_id INT DEFAULT NULL,
  p_dept_ids INT[] DEFAULT NULL
)
RETURNS TABLE (
  id INT, from_staff_id INT, from_staff_name VARCHAR,
  to_staff_id INT, to_staff_name VARCHAR,
  start_date DATE, end_date DATE, note TEXT,
  is_revoked BOOLEAN, revoked_at TIMESTAMPTZ, created_at TIMESTAMPTZ
)
LANGUAGE sql STABLE
AS $$
  SELECT dl.id, dl.from_staff_id,
         sf.full_name::VARCHAR AS from_staff_name,
         dl.to_staff_id,
         st.full_name::VARCHAR AS to_staff_name,
         dl.start_date, dl.end_date, dl.note,
         dl.is_revoked, dl.revoked_at, dl.created_at
  FROM edoc.delegations dl
    JOIN public.staff sf ON sf.id = dl.from_staff_id
    JOIN public.staff st ON st.id = dl.to_staff_id
  WHERE (p_dept_ids IS NULL OR sf.department_id = ANY(p_dept_ids))
    AND (p_unit_id IS NULL OR sf.unit_id = p_unit_id)
    AND (p_staff_id IS NULL OR dl.from_staff_id = p_staff_id OR dl.to_staff_id = p_staff_id)
  ORDER BY dl.created_at DESC;
$$;

DO $$ BEGIN RAISE NOTICE '032-B5: fn_delegation_get_list rewritten'; END $$;

-- --------------------------------------------------------------------
-- B.6 edoc.fn_handling_doc_get_for_link
-- --------------------------------------------------------------------
DROP FUNCTION IF EXISTS edoc.fn_handling_doc_get_for_link(INT, TEXT);
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_get_for_link(
  p_unit_id INT,
  p_keyword TEXT DEFAULT NULL,
  p_dept_ids INT[] DEFAULT NULL
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
    AND (p_dept_ids IS NULL OR h.department_id = ANY(p_dept_ids))
    AND h.status < 3
    AND (v_kw IS NULL OR h.name ILIKE '%' || v_kw || '%' OR h.abstract ILIKE '%' || v_kw || '%')
  ORDER BY h.created_at DESC
  LIMIT 50;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-B6: fn_handling_doc_get_for_link rewritten'; END $$;

-- --------------------------------------------------------------------
-- B.7 edoc.fn_handling_doc_kpi
-- --------------------------------------------------------------------
DROP FUNCTION IF EXISTS edoc.fn_handling_doc_kpi(INT, TIMESTAMPTZ, TIMESTAMPTZ);
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_kpi(
  p_unit_id   INT,
  p_from_date TIMESTAMPTZ,
  p_to_date   TIMESTAMPTZ,
  p_dept_ids  INT[] DEFAULT NULL
)
RETURNS TABLE (
  total BIGINT, prev_period BIGINT, current_period BIGINT,
  completed BIGINT, in_progress BIGINT, overdue BIGINT, overdue_percent NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_total BIGINT; v_prev BIGINT; v_current BIGINT;
  v_completed BIGINT; v_in_progress BIGINT; v_overdue BIGINT; v_percent NUMERIC;
BEGIN
  SELECT COUNT(*) INTO v_total FROM edoc.handling_docs
  WHERE unit_id = p_unit_id AND (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids));

  SELECT COUNT(*) INTO v_prev FROM edoc.handling_docs
  WHERE unit_id = p_unit_id AND (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids))
    AND created_at < p_from_date AND status NOT IN (4, -1);

  SELECT COUNT(*) INTO v_current FROM edoc.handling_docs
  WHERE unit_id = p_unit_id AND (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids))
    AND (p_from_date IS NULL OR created_at >= p_from_date)
    AND (p_to_date IS NULL OR created_at <= p_to_date);

  SELECT COUNT(*) INTO v_completed FROM edoc.handling_docs
  WHERE unit_id = p_unit_id AND (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids))
    AND status = 4
    AND (p_from_date IS NULL OR complete_date >= p_from_date)
    AND (p_to_date IS NULL OR complete_date <= p_to_date);

  SELECT COUNT(*) INTO v_in_progress FROM edoc.handling_docs
  WHERE unit_id = p_unit_id AND (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids))
    AND status IN (0, 1, 2, 3)
    AND (p_from_date IS NULL OR created_at >= p_from_date)
    AND (p_to_date IS NULL OR created_at <= p_to_date);

  SELECT COUNT(*) INTO v_overdue FROM edoc.handling_docs
  WHERE unit_id = p_unit_id AND (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids))
    AND end_date < NOW() AND status NOT IN (4, -1)
    AND (p_from_date IS NULL OR created_at >= p_from_date)
    AND (p_to_date IS NULL OR created_at <= p_to_date);

  IF v_current > 0 THEN v_percent := ROUND((v_overdue::NUMERIC / v_current::NUMERIC) * 100, 2);
  ELSE v_percent := 0; END IF;

  RETURN QUERY SELECT v_total, v_prev, v_current, v_completed, v_in_progress, v_overdue, v_percent;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-B7: fn_handling_doc_kpi rewritten'; END $$;

-- --------------------------------------------------------------------
-- B.8 edoc.fn_report_handling_by_unit
-- --------------------------------------------------------------------
DROP FUNCTION IF EXISTS edoc.fn_report_handling_by_unit(INT, TIMESTAMPTZ, TIMESTAMPTZ);
CREATE OR REPLACE FUNCTION edoc.fn_report_handling_by_unit(
  p_unit_id   INT,
  p_from_date TIMESTAMPTZ,
  p_to_date   TIMESTAMPTZ,
  p_dept_ids  INT[] DEFAULT NULL
)
RETURNS TABLE (
  department_id INT, department_name TEXT, total BIGINT,
  completed BIGINT, in_progress BIGINT, overdue BIGINT, completion_rate NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    d.id AS department_id, d.name::TEXT AS department_name,
    COUNT(h.id)::BIGINT AS total,
    COUNT(h.id) FILTER (WHERE h.status = 4)::BIGINT AS completed,
    COUNT(h.id) FILTER (WHERE h.status IN (0,1,2,3))::BIGINT AS in_progress,
    COUNT(h.id) FILTER (WHERE h.end_date < NOW() AND h.status NOT IN (4, -1))::BIGINT AS overdue,
    CASE WHEN COUNT(h.id) > 0
      THEN ROUND(COUNT(h.id) FILTER (WHERE h.status = 4)::NUMERIC / COUNT(h.id)::NUMERIC * 100, 2)
      ELSE 0 END AS completion_rate
  FROM public.departments d
  LEFT JOIN edoc.handling_docs h ON h.department_id = d.id
    AND h.unit_id = p_unit_id
    AND (p_from_date IS NULL OR h.created_at >= p_from_date)
    AND (p_to_date IS NULL OR h.created_at <= p_to_date)
  WHERE (p_dept_ids IS NULL OR d.id = ANY(p_dept_ids))
    AND d.parent_id = p_unit_id AND d.is_unit = FALSE AND d.is_deleted = FALSE
  GROUP BY d.id, d.name
  ORDER BY total DESC, d.name;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-B8: fn_report_handling_by_unit rewritten'; END $$;

-- --------------------------------------------------------------------
-- B.9 edoc.fn_report_handling_by_resolver
-- --------------------------------------------------------------------
DROP FUNCTION IF EXISTS edoc.fn_report_handling_by_resolver(INT, TIMESTAMPTZ, TIMESTAMPTZ);
CREATE OR REPLACE FUNCTION edoc.fn_report_handling_by_resolver(
  p_unit_id   INT, p_from_date TIMESTAMPTZ, p_to_date TIMESTAMPTZ,
  p_dept_ids  INT[] DEFAULT NULL
)
RETURNS TABLE (
  staff_id INT, staff_name TEXT, department_name TEXT,
  total BIGINT, completed BIGINT, in_progress BIGINT, overdue BIGINT, completion_rate NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT s.id AS staff_id, CONCAT(s.last_name, ' ', s.first_name)::TEXT AS staff_name,
    d.name::TEXT AS department_name,
    COUNT(h.id)::BIGINT AS total,
    COUNT(h.id) FILTER (WHERE h.status = 4)::BIGINT AS completed,
    COUNT(h.id) FILTER (WHERE h.status IN (0,1,2,3))::BIGINT AS in_progress,
    COUNT(h.id) FILTER (WHERE h.end_date < NOW() AND h.status NOT IN (4, -1))::BIGINT AS overdue,
    CASE WHEN COUNT(h.id) > 0
      THEN ROUND(COUNT(h.id) FILTER (WHERE h.status = 4)::NUMERIC / COUNT(h.id)::NUMERIC * 100, 2)
      ELSE 0 END AS completion_rate
  FROM public.staff s
  LEFT JOIN public.departments d ON d.id = s.department_id
  LEFT JOIN edoc.handling_docs h ON h.curator = s.id AND h.unit_id = p_unit_id
    AND (p_from_date IS NULL OR h.created_at >= p_from_date) AND (p_to_date IS NULL OR h.created_at <= p_to_date)
  WHERE (p_dept_ids IS NULL OR s.department_id = ANY(p_dept_ids))
    AND s.unit_id = p_unit_id AND s.is_locked = FALSE
  GROUP BY s.id, s.last_name, s.first_name, d.name
  HAVING COUNT(h.id) > 0
  ORDER BY total DESC, s.last_name;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-B9: fn_report_handling_by_resolver rewritten'; END $$;

-- --------------------------------------------------------------------
-- B.10 edoc.fn_report_handling_by_assigner
-- --------------------------------------------------------------------
DROP FUNCTION IF EXISTS edoc.fn_report_handling_by_assigner(INT, TIMESTAMPTZ, TIMESTAMPTZ);
CREATE OR REPLACE FUNCTION edoc.fn_report_handling_by_assigner(
  p_unit_id   INT, p_from_date TIMESTAMPTZ, p_to_date TIMESTAMPTZ,
  p_dept_ids  INT[] DEFAULT NULL
)
RETURNS TABLE (
  staff_id INT, staff_name TEXT, department_name TEXT,
  total BIGINT, completed BIGINT, in_progress BIGINT, overdue BIGINT, completion_rate NUMERIC
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT s.id AS staff_id, CONCAT(s.last_name, ' ', s.first_name)::TEXT AS staff_name,
    d.name::TEXT AS department_name,
    COUNT(h.id)::BIGINT AS total,
    COUNT(h.id) FILTER (WHERE h.status = 4)::BIGINT AS completed,
    COUNT(h.id) FILTER (WHERE h.status IN (0,1,2,3))::BIGINT AS in_progress,
    COUNT(h.id) FILTER (WHERE h.end_date < NOW() AND h.status NOT IN (4, -1))::BIGINT AS overdue,
    CASE WHEN COUNT(h.id) > 0
      THEN ROUND(COUNT(h.id) FILTER (WHERE h.status = 4)::NUMERIC / COUNT(h.id)::NUMERIC * 100, 2)
      ELSE 0 END AS completion_rate
  FROM public.staff s
  LEFT JOIN public.departments d ON d.id = s.department_id
  LEFT JOIN edoc.handling_docs h ON h.created_by = s.id AND h.unit_id = p_unit_id
    AND (p_from_date IS NULL OR h.created_at >= p_from_date) AND (p_to_date IS NULL OR h.created_at <= p_to_date)
  WHERE (p_dept_ids IS NULL OR s.department_id = ANY(p_dept_ids))
    AND s.unit_id = p_unit_id AND s.is_locked = FALSE
  GROUP BY s.id, s.last_name, s.first_name, d.name
  HAVING COUNT(h.id) > 0
  ORDER BY total DESC, s.last_name;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-B10: fn_report_handling_by_assigner rewritten'; END $$;

-- --------------------------------------------------------------------
-- B.11 edoc.fn_inter_incoming_get_list
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_inter_incoming_get_list(
  p_unit_id     INT,
  p_keyword     TEXT,
  p_status      TEXT,
  p_from_date   DATE,
  p_to_date     DATE,
  p_page        INT DEFAULT 1,
  p_page_size   INT DEFAULT 20,
  p_dept_ids    INT[] DEFAULT NULL
)
RETURNS TABLE (
  id BIGINT, unit_id INT, received_date TIMESTAMP, notation VARCHAR,
  document_code VARCHAR, abstract TEXT, publish_unit VARCHAR,
  publish_date DATE, signer VARCHAR, sign_date DATE, expired_date DATE,
  doc_type_id INT, status VARCHAR, source_system VARCHAR,
  external_doc_id VARCHAR, created_by INT, created_at TIMESTAMP,
  updated_at TIMESTAMP, total_count BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT d.id, d.unit_id, d.received_date, d.notation, d.document_code,
      d.abstract, d.publish_unit, d.publish_date, d.signer, d.sign_date,
      d.expired_date, d.doc_type_id, d.status, d.source_system,
      d.external_doc_id, d.created_by, d.created_at, d.updated_at
    FROM edoc.inter_incoming_docs d
    WHERE d.unit_id = p_unit_id
      AND (p_dept_ids IS NULL OR d.department_id = ANY(p_dept_ids))
      AND (p_status IS NULL OR p_status = '' OR d.status = p_status)
      AND (p_from_date IS NULL OR d.received_date::DATE >= p_from_date)
      AND (p_to_date IS NULL OR d.received_date::DATE <= p_to_date)
      AND (p_keyword IS NULL OR TRIM(p_keyword) = ''
        OR d.notation ILIKE '%' || p_keyword || '%'
        OR d.abstract ILIKE '%' || p_keyword || '%'
        OR d.publish_unit ILIKE '%' || p_keyword || '%')
  )
  SELECT f.id, f.unit_id, f.received_date, f.notation, f.document_code,
    f.abstract, f.publish_unit, f.publish_date, f.signer, f.sign_date,
    f.expired_date, f.doc_type_id, f.status, f.source_system,
    f.external_doc_id, f.created_by, f.created_at, f.updated_at,
    COUNT(*) OVER()::BIGINT AS total_count
  FROM filtered f
  ORDER BY f.received_date DESC NULLS LAST
  LIMIT COALESCE(p_page_size, 20) OFFSET v_offset;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-B11: fn_inter_incoming_get_list rewritten'; END $$;

-- --------------------------------------------------------------------
-- B.12 edoc.fn_notice_get_list
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_notice_get_list(
  p_unit_id   INT, p_staff_id INT, p_is_read TEXT,
  p_page INT DEFAULT 1, p_page_size INT DEFAULT 20,
  p_dept_ids INT[] DEFAULT NULL
)
RETURNS TABLE (
  id BIGINT, unit_id INT, title VARCHAR, content TEXT,
  notice_type VARCHAR, created_by INT, created_at TIMESTAMP,
  is_read BOOLEAN, total_count BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT n.id, n.unit_id, n.title, n.content, n.notice_type, n.created_by, n.created_at,
      CASE WHEN nr.id IS NOT NULL THEN TRUE ELSE FALSE END AS is_read
    FROM edoc.notices n
    LEFT JOIN edoc.notice_reads nr ON nr.notice_id = n.id AND nr.staff_id = p_staff_id
    WHERE (p_unit_id IS NULL OR n.unit_id = p_unit_id OR n.unit_id IS NULL)
      AND (p_dept_ids IS NULL OR n.department_id = ANY(p_dept_ids))
      AND (p_is_read IS NULL OR p_is_read = ''
        OR (p_is_read = 'true' AND nr.id IS NOT NULL)
        OR (p_is_read = 'false' AND nr.id IS NULL))
  )
  SELECT f.id, f.unit_id, f.title, f.content, f.notice_type, f.created_by, f.created_at,
    f.is_read, COUNT(*) OVER()::BIGINT AS total_count
  FROM filtered f
  ORDER BY f.created_at DESC
  LIMIT COALESCE(p_page_size, 20) OFFSET v_offset;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-B12: fn_notice_get_list rewritten'; END $$;

-- --------------------------------------------------------------------
-- B.13 edoc.fn_notice_mark_all_read
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_notice_mark_all_read(
  p_staff_id INT, p_unit_id INT,
  p_dept_ids INT[] DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, count BIGINT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_count BIGINT := 0;
BEGIN
  WITH unread_notices AS (
    SELECT n.id FROM edoc.notices n
    WHERE (p_unit_id IS NULL OR n.unit_id = p_unit_id OR n.unit_id IS NULL)
      AND (p_dept_ids IS NULL OR n.department_id = ANY(p_dept_ids))
      AND NOT EXISTS (SELECT 1 FROM edoc.notice_reads nr WHERE nr.notice_id = n.id AND nr.staff_id = p_staff_id)
  ),
  inserted AS (
    INSERT INTO edoc.notice_reads (notice_id, staff_id, read_at)
    SELECT un.id, p_staff_id, NOW() FROM unread_notices un
    ON CONFLICT (notice_id, staff_id) DO NOTHING
    RETURNING 1
  )
  SELECT COUNT(*) INTO v_count FROM inserted;

  RETURN QUERY SELECT TRUE, 'Đánh dấu tất cả đã đọc thành công'::TEXT, v_count;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-B13: fn_notice_mark_all_read rewritten'; END $$;

-- --------------------------------------------------------------------
-- B.14 public.fn_calendar_event_get_list
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_calendar_event_get_list(
  p_scope VARCHAR, p_unit_id INT, p_staff_id INT,
  p_start TIMESTAMP, p_end TIMESTAMP,
  p_dept_ids INT[] DEFAULT NULL
) RETURNS TABLE (
  id BIGINT, title VARCHAR, description TEXT,
  start_time TIMESTAMP, end_time TIMESTAMP, all_day BOOLEAN,
  color VARCHAR, repeat_type VARCHAR, scope VARCHAR,
  unit_id INT, created_by INT, creator_name VARCHAR,
  created_at TIMESTAMP, updated_at TIMESTAMP
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT ce.id, ce.title, ce.description, ce.start_time, ce.end_time,
    ce.all_day, ce.color, ce.repeat_type, ce.scope, ce.unit_id, ce.created_by,
    (s.last_name || ' ' || s.first_name)::VARCHAR AS creator_name,
    ce.created_at, ce.updated_at
  FROM public.calendar_events ce
  LEFT JOIN public.staff s ON s.id = ce.created_by
  WHERE ce.is_deleted = FALSE
    AND ce.scope = p_scope
    AND (p_dept_ids IS NULL OR ce.department_id = ANY(p_dept_ids))
    AND (
      CASE
        WHEN p_scope = 'personal' THEN ce.created_by = p_staff_id
        ELSE ce.unit_id = p_unit_id
      END
    )
    AND ce.start_time >= p_start AND ce.start_time <= p_end
  ORDER BY ce.start_time ASC;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-B14: fn_calendar_event_get_list rewritten'; END $$;

-- --------------------------------------------------------------------
-- B.15 esto.fn_warehouse_get_tree
-- --------------------------------------------------------------------
DROP FUNCTION IF EXISTS esto.fn_warehouse_get_tree(INT);
CREATE OR REPLACE FUNCTION esto.fn_warehouse_get_tree(
  p_unit_id INT,
  p_dept_ids INT[] DEFAULT NULL
)
RETURNS TABLE (
  id INT, unit_id INT, type_id INT, code VARCHAR, name VARCHAR,
  phone_number VARCHAR, address VARCHAR, status BOOLEAN, description TEXT,
  parent_id INT, is_unit BOOLEAN, warehouse_level INT, limit_child INT,
  "position" VARCHAR, created_user_id INT, created_date TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT w.id, w.unit_id, w.type_id, w.code, w.name, w.phone_number, w.address,
    w.status, w.description, w.parent_id, w.is_unit, w.warehouse_level,
    w.limit_child, w."position", w.created_user_id, w.created_date
  FROM esto.warehouses w
  WHERE w.unit_id = p_unit_id AND w.is_deleted = false
    AND (p_dept_ids IS NULL OR w.department_id = ANY(p_dept_ids))
  ORDER BY w.parent_id, w.name;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-B15: fn_warehouse_get_tree rewritten'; END $$;

-- --------------------------------------------------------------------
-- B.16 esto.fn_fond_get_tree
-- --------------------------------------------------------------------
DROP FUNCTION IF EXISTS esto.fn_fond_get_tree(INT);
CREATE OR REPLACE FUNCTION esto.fn_fond_get_tree(
  p_unit_id INT,
  p_dept_ids INT[] DEFAULT NULL
)
RETURNS TABLE (
  id INT, unit_id INT, parent_id INT, fond_code VARCHAR, fond_name VARCHAR,
  fond_history TEXT, archives_time VARCHAR, paper_total DECIMAL,
  paper_digital DECIMAL, keys_group VARCHAR, other_type VARCHAR,
  language VARCHAR, lookup_tools VARCHAR, coppy_number DECIMAL,
  status INT, description TEXT, version DECIMAL, created_date TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT f.id, f.unit_id, f.parent_id, f.fond_code, f.fond_name,
    f.fond_history, f.archives_time, f.paper_total, f.paper_digital,
    f.keys_group, f.other_type, f.language, f.lookup_tools, f.coppy_number,
    f.status, f.description, f.version, f.created_date
  FROM esto.fonds f
  WHERE f.unit_id = p_unit_id
  ORDER BY f.parent_id, f.fond_name;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-B16: fn_fond_get_tree rewritten'; END $$;

-- --------------------------------------------------------------------
-- B.17 esto.fn_record_get_list
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION esto.fn_record_get_list(
  p_unit_id INT, p_fond_id INT, p_warehouse_id INT,
  p_keyword TEXT, p_page INT DEFAULT 1, p_page_size INT DEFAULT 20,
  p_dept_ids INT[] DEFAULT NULL
)
RETURNS TABLE (
  id BIGINT, unit_id INT, fond_id INT, fond_name VARCHAR,
  file_code VARCHAR, file_catalog INT, file_notation VARCHAR,
  title VARCHAR, maintenance VARCHAR, rights VARCHAR, language VARCHAR,
  start_date DATE, complete_date DATE, total_doc INT, description TEXT,
  infor_sign VARCHAR, keyword VARCHAR, total_paper DECIMAL,
  page_number DECIMAL, format INT, archive_date DATE,
  in_charge_staff_id INT, warehouse_id INT, warehouse_name VARCHAR,
  transfer_online_status BOOLEAN, created_date TIMESTAMPTZ, total_count BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT r.id, r.unit_id, r.fond_id, f.fond_name, r.file_code, r.file_catalog,
      r.file_notation, r.title, r.maintenance, r.rights, r.language,
      r.start_date, r.complete_date, r.total_doc, r.description, r.infor_sign,
      r.keyword, r.total_paper, r.page_number, r.format, r.archive_date,
      r.in_charge_staff_id, r.warehouse_id, w.name AS warehouse_name,
      r.transfer_online_status, r.created_date
    FROM esto.records r
    LEFT JOIN esto.fonds f ON f.id = r.fond_id
    LEFT JOIN esto.warehouses w ON w.id = r.warehouse_id
    WHERE r.unit_id = p_unit_id
      AND (p_dept_ids IS NULL OR r.department_id = ANY(p_dept_ids))
      AND (p_fond_id IS NULL OR r.fond_id = p_fond_id)
      AND (p_warehouse_id IS NULL OR r.warehouse_id = p_warehouse_id)
      AND (p_keyword IS NULL OR TRIM(p_keyword) = '' OR
           r.title ILIKE '%' || p_keyword || '%' OR r.file_code ILIKE '%' || p_keyword || '%')
  )
  SELECT flt.*, COUNT(*) OVER() AS total_count
  FROM filtered flt
  ORDER BY flt.created_date DESC
  LIMIT p_page_size OFFSET v_offset;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-B17: fn_record_get_list rewritten'; END $$;

-- --------------------------------------------------------------------
-- B.18 esto.fn_borrow_request_get_list
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION esto.fn_borrow_request_get_list(
  p_unit_id INT, p_status INT, p_keyword TEXT,
  p_page INT DEFAULT 1, p_page_size INT DEFAULT 20,
  p_dept_ids INT[] DEFAULT NULL
)
RETURNS TABLE (
  id BIGINT, name VARCHAR, unit_id INT, emergency INT, notice TEXT,
  borrow_date DATE, status INT, created_user_id INT, creator_name TEXT,
  created_date TIMESTAMPTZ, record_count BIGINT, total_count BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT br.id, br.name, br.unit_id, br.emergency, br.notice, br.borrow_date,
      br.status, br.created_user_id,
      (s.last_name || ' ' || s.first_name)::TEXT AS creator_name,
      br.created_date,
      (SELECT COUNT(*) FROM esto.borrow_request_records brr WHERE brr.borrow_request_id = br.id) AS record_count
    FROM esto.borrow_requests br
    LEFT JOIN public.staff s ON s.id = br.created_user_id
    WHERE br.unit_id = p_unit_id
      AND (p_dept_ids IS NULL OR br.department_id = ANY(p_dept_ids))
      AND (p_status IS NULL OR p_status = -99 OR br.status = p_status)
      AND (p_keyword IS NULL OR TRIM(p_keyword) = '' OR br.name ILIKE '%' || p_keyword || '%')
  )
  SELECT flt.*, COUNT(*) OVER() AS total_count
  FROM filtered flt
  ORDER BY flt.created_date DESC
  LIMIT p_page_size OFFSET v_offset;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-B18: fn_borrow_request_get_list rewritten'; END $$;

-- --------------------------------------------------------------------
-- B.19 iso.fn_document_get_list
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION iso.fn_document_get_list(
  p_unit_id INT, p_category_id INT, p_keyword TEXT,
  p_page INT DEFAULT 1, p_page_size INT DEFAULT 20,
  p_dept_ids INT[] DEFAULT NULL
)
RETURNS TABLE (
  id BIGINT, unit_id INT, category_id INT, category_name VARCHAR,
  title VARCHAR, description TEXT, file_name VARCHAR, file_path VARCHAR,
  file_size BIGINT, mime_type VARCHAR, keyword VARCHAR, status INT,
  created_user_id INT, creator_name TEXT, created_date TIMESTAMPTZ, total_count BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT d.id, d.unit_id, d.category_id, dc.name AS category_name,
      d.title, d.description, d.file_name, d.file_path, d.file_size,
      d.mime_type, d.keyword, d.status, d.created_user_id,
      (s.last_name || ' ' || s.first_name)::TEXT AS creator_name, d.created_date
    FROM iso.documents d
    LEFT JOIN iso.document_categories dc ON dc.id = d.category_id
    LEFT JOIN public.staff s ON s.id = d.created_user_id
    WHERE d.unit_id = p_unit_id AND d.is_deleted = false
      AND (p_dept_ids IS NULL OR d.department_id = ANY(p_dept_ids))
      AND (p_category_id IS NULL OR d.category_id = p_category_id)
      AND (p_keyword IS NULL OR TRIM(p_keyword) = '' OR
           d.title ILIKE '%' || p_keyword || '%' OR d.keyword ILIKE '%' || p_keyword || '%')
  )
  SELECT flt.*, COUNT(*) OVER() AS total_count
  FROM filtered flt
  ORDER BY flt.created_date DESC
  LIMIT p_page_size OFFSET v_offset;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-B19: fn_document_get_list rewritten'; END $$;

-- --------------------------------------------------------------------
-- B.20 cont.fn_contract_get_list
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cont.fn_contract_get_list(
  p_unit_id INT, p_contract_type_id INT, p_status INT,
  p_keyword TEXT, p_page INT DEFAULT 1, p_page_size INT DEFAULT 20,
  p_dept_ids INT[] DEFAULT NULL
)
RETURNS TABLE (
  id INT, code_index INT, contract_type_id INT, type_name VARCHAR,
  unit_id INT, code VARCHAR, name VARCHAR, sign_date DATE,
  signer VARCHAR, contact_name VARCHAR, staff_id INT, status INT,
  amount VARCHAR, payment_amount DECIMAL, created_date TIMESTAMPTZ,
  attachment_count BIGINT, total_count BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT c.id, c.code_index, c.contract_type_id, ct.name AS type_name,
      c.unit_id, c.code, c.name, c.sign_date, c.signer, c.contact_name,
      c.staff_id, c.status, c.amount, c.payment_amount, c.created_date,
      (SELECT COUNT(*) FROM cont.contract_attachments ca WHERE ca.contract_id = c.id) AS attachment_count
    FROM cont.contracts c
    LEFT JOIN cont.contract_types ct ON ct.id = c.contract_type_id
    WHERE c.unit_id = p_unit_id
      AND (p_dept_ids IS NULL OR c.department_id = ANY(p_dept_ids))
      AND (p_contract_type_id IS NULL OR c.contract_type_id = p_contract_type_id)
      AND (p_status IS NULL OR p_status = -99 OR c.status = p_status)
      AND (p_keyword IS NULL OR TRIM(p_keyword) = '' OR
           c.name ILIKE '%' || p_keyword || '%' OR c.code ILIKE '%' || p_keyword || '%' OR
           c.contact_name ILIKE '%' || p_keyword || '%')
  )
  SELECT flt.*, COUNT(*) OVER() AS total_count
  FROM filtered flt
  ORDER BY flt.created_date DESC
  LIMIT p_page_size OFFSET v_offset;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-B20: fn_contract_get_list rewritten'; END $$;

-- --------------------------------------------------------------------
-- B.21 edoc.fn_room_schedule_get_list
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_room_schedule_get_list(
  p_unit_id INT, p_room_id INT, p_status INT,
  p_from_date DATE, p_to_date DATE, p_keyword TEXT,
  p_page INT DEFAULT 1, p_page_size INT DEFAULT 20,
  p_dept_ids INT[] DEFAULT NULL
)
RETURNS TABLE (
  id INT, unit_id INT, room_id INT, room_name VARCHAR,
  meeting_type_id INT, meeting_type_name VARCHAR, name VARCHAR,
  content TEXT, start_date DATE, end_date DATE, start_time VARCHAR,
  end_time VARCHAR, master_id INT, master_name TEXT,
  approved INT, meeting_status INT, online_link VARCHAR,
  created_date TIMESTAMPTZ, staff_count BIGINT, total_count BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT rs.id, rs.unit_id, rs.room_id, r.name AS room_name,
      rs.meeting_type_id, mt.name AS meeting_type_name, rs.name, rs.content,
      rs.start_date, rs.end_date, rs.start_time, rs.end_time, rs.master_id,
      (s.last_name || ' ' || s.first_name)::TEXT AS master_name,
      rs.approved, rs.meeting_status, rs.online_link, rs.created_date,
      (SELECT COUNT(*) FROM edoc.room_schedule_staff rss WHERE rss.room_schedule_id = rs.id) AS staff_count
    FROM edoc.room_schedules rs
    LEFT JOIN edoc.rooms r ON r.id = rs.room_id
    LEFT JOIN edoc.meeting_types mt ON mt.id = rs.meeting_type_id
    LEFT JOIN public.staff s ON s.id = rs.master_id
    WHERE rs.unit_id = p_unit_id
      AND (p_dept_ids IS NULL OR rs.department_id = ANY(p_dept_ids))
      AND (p_room_id IS NULL OR rs.room_id = p_room_id)
      AND (p_status IS NULL OR p_status = -99 OR rs.meeting_status = p_status)
      AND (p_from_date IS NULL OR rs.start_date >= p_from_date)
      AND (p_to_date IS NULL OR rs.start_date <= p_to_date)
      AND (p_keyword IS NULL OR TRIM(p_keyword) = '' OR rs.name ILIKE '%' || p_keyword || '%')
  )
  SELECT flt.*, COUNT(*) OVER() AS total_count
  FROM filtered flt
  ORDER BY flt.start_date DESC, flt.start_time
  LIMIT p_page_size OFFSET v_offset;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-B21: fn_room_schedule_get_list rewritten'; END $$;

-- --------------------------------------------------------------------
-- B.22 edoc.fn_room_schedule_stats
-- --------------------------------------------------------------------
DROP FUNCTION IF EXISTS edoc.fn_room_schedule_stats(INT, INT);
CREATE OR REPLACE FUNCTION edoc.fn_room_schedule_stats(
  p_unit_id INT, p_year INT,
  p_dept_ids INT[] DEFAULT NULL
)
RETURNS TABLE (stat_type TEXT, category_id INT, category_name VARCHAR, month_num INT, count BIGINT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT 'by_month'::TEXT, 0, 'Tất cả'::VARCHAR,
    EXTRACT(MONTH FROM rs.start_date)::INT, COUNT(*)::BIGINT
  FROM edoc.room_schedules rs
  WHERE rs.unit_id = p_unit_id AND EXTRACT(YEAR FROM rs.start_date) = p_year AND rs.is_cancel = 0
    AND (p_dept_ids IS NULL OR rs.department_id = ANY(p_dept_ids))
  GROUP BY EXTRACT(MONTH FROM rs.start_date) ORDER BY month_num;

  RETURN QUERY
  SELECT 'by_room'::TEXT, r.id, r.name, 0, COUNT(*)::BIGINT
  FROM edoc.room_schedules rs
  JOIN edoc.rooms r ON r.id = rs.room_id
  WHERE rs.unit_id = p_unit_id AND EXTRACT(YEAR FROM rs.start_date) = p_year AND rs.is_cancel = 0
    AND (p_dept_ids IS NULL OR rs.department_id = ANY(p_dept_ids))
  GROUP BY r.id, r.name ORDER BY count DESC;

  RETURN QUERY
  SELECT 'by_meeting_type'::TEXT, mt.id, mt.name, 0, COUNT(*)::BIGINT
  FROM edoc.room_schedules rs
  JOIN edoc.meeting_types mt ON mt.id = rs.meeting_type_id
  WHERE rs.unit_id = p_unit_id AND EXTRACT(YEAR FROM rs.start_date) = p_year AND rs.is_cancel = 0
    AND (p_dept_ids IS NULL OR rs.department_id = ANY(p_dept_ids))
  GROUP BY mt.id, mt.name ORDER BY count DESC;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-B22: fn_room_schedule_stats rewritten'; END $$;

-- --------------------------------------------------------------------
-- B.23 edoc.fn_incoming_doc_get_sendable_staff
-- --------------------------------------------------------------------
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_get_sendable_staff(INT);
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_get_sendable_staff(
  p_unit_id INT,
  p_dept_ids INT[] DEFAULT NULL
)
RETURNS TABLE (
  staff_id INT, full_name VARCHAR, position_name VARCHAR,
  department_id INT, department_name VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT s.id, s.full_name, p.name, s.department_id, d.name
  FROM public.staff s
  LEFT JOIN public.positions p ON p.id = s.position_id
  LEFT JOIN public.departments d ON d.id = s.department_id
  WHERE (
    p_dept_ids IS NOT NULL AND s.department_id = ANY(p_dept_ids)
    OR p_dept_ids IS NULL AND s.department_id IN (
      SELECT dep.id FROM public.departments dep
      WHERE dep.id = p_unit_id OR dep.parent_id = p_unit_id
    )
  )
  AND s.is_locked = FALSE AND s.is_deleted = FALSE
  ORDER BY d.sort_order, d.name, s.full_name;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-B23: fn_incoming_doc_get_sendable_staff rewritten'; END $$;


-- ====================================================================
-- GROUP C: LIST SPs with ancestor unit filter (add p_dept_id INT)
-- ====================================================================

-- --------------------------------------------------------------------
-- C.1 public.fn_config_get_list
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_config_get_list(
  p_unit_id INT DEFAULT NULL,
  p_dept_id INT DEFAULT NULL
)
RETURNS TABLE (id INT, unit_id INT, key VARCHAR, value TEXT, description TEXT)
LANGUAGE sql STABLE
AS $$
  SELECT c.id, c.unit_id, c.key::VARCHAR, c.value, c.description
  FROM public.configurations c
  WHERE (
    CASE WHEN p_dept_id IS NOT NULL THEN c.unit_id = public.fn_get_ancestor_unit(p_dept_id)
    ELSE (p_unit_id IS NULL OR c.unit_id = p_unit_id) END
  )
  ORDER BY c.key;
$$;

DO $$ BEGIN RAISE NOTICE '032-C1: fn_config_get_list rewritten'; END $$;

-- --------------------------------------------------------------------
-- C.2 edoc.fn_organization_get
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_organization_get(
  p_unit_id INT DEFAULT NULL,
  p_dept_id INT DEFAULT NULL
)
RETURNS TABLE (
  id INT, unit_id INT, code VARCHAR, name VARCHAR, address TEXT,
  phone VARCHAR, fax VARCHAR, email VARCHAR, email_doc VARCHAR,
  secretary VARCHAR, chairman_number VARCHAR, level SMALLINT,
  is_exchange BOOLEAN, lgsp_system_id VARCHAR, lgsp_secret_key VARCHAR,
  updated_by INT, updated_at TIMESTAMPTZ
)
LANGUAGE sql STABLE
AS $$
  SELECT o.id, o.unit_id, o.code::VARCHAR, o.name::VARCHAR, o.address,
         o.phone::VARCHAR, o.fax::VARCHAR, o.email::VARCHAR, o.email_doc::VARCHAR,
         o.secretary::VARCHAR, o.chairman_number::VARCHAR, o.level,
         o.is_exchange, o.lgsp_system_id::VARCHAR, o.lgsp_secret_key::VARCHAR,
         o.updated_by, o.updated_at
  FROM edoc.organizations o
  WHERE o.unit_id = CASE WHEN p_dept_id IS NOT NULL THEN public.fn_get_ancestor_unit(p_dept_id)
                         ELSE p_unit_id END;
$$;

DO $$ BEGIN RAISE NOTICE '032-C2: fn_organization_get rewritten'; END $$;

-- --------------------------------------------------------------------
-- C.3 edoc.fn_doc_book_get_list
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_doc_book_get_list(
  p_type_id  SMALLINT DEFAULT NULL,
  p_unit_id  INT DEFAULT NULL,
  p_dept_id  INT DEFAULT NULL
)
RETURNS TABLE (
  id INT, unit_id INT, type_id SMALLINT, name VARCHAR,
  description TEXT, sort_order INT, is_default BOOLEAN,
  created_by INT, created_at TIMESTAMPTZ
)
LANGUAGE sql STABLE
AS $$
  SELECT b.id, b.unit_id, b.type_id, b.name::VARCHAR,
         b.description, b.sort_order, b.is_default,
         b.created_by, b.created_at
  FROM edoc.doc_books b
  WHERE b.is_deleted = FALSE
    AND (p_type_id IS NULL OR b.type_id = p_type_id)
    AND (
      CASE WHEN p_dept_id IS NOT NULL THEN b.unit_id = public.fn_get_ancestor_unit(p_dept_id)
      ELSE (p_unit_id IS NULL OR b.unit_id = p_unit_id) END
    )
  ORDER BY b.sort_order, b.name;
$$;

DO $$ BEGIN RAISE NOTICE '032-C3: fn_doc_book_get_list rewritten'; END $$;

-- --------------------------------------------------------------------
-- C.4 edoc.fn_doc_field_get_list
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_doc_field_get_list(
  p_unit_id INT DEFAULT NULL,
  p_keyword VARCHAR DEFAULT NULL,
  p_dept_id INT DEFAULT NULL
)
RETURNS TABLE (
  id INT, unit_id INT, code VARCHAR, name VARCHAR,
  sort_order INT, is_active BOOLEAN, created_at TIMESTAMPTZ
)
LANGUAGE sql STABLE
AS $$
  SELECT f.id, f.unit_id, f.code::VARCHAR, f.name::VARCHAR,
         f.sort_order, f.is_active, f.created_at
  FROM edoc.doc_fields f
  WHERE (
    CASE WHEN p_dept_id IS NOT NULL THEN f.unit_id = public.fn_get_ancestor_unit(p_dept_id)
    ELSE (p_unit_id IS NULL OR f.unit_id = p_unit_id) END
  )
    AND (p_keyword IS NULL OR f.name ILIKE '%' || p_keyword || '%'
         OR f.code ILIKE '%' || p_keyword || '%')
  ORDER BY f.sort_order, f.name;
$$;

DO $$ BEGIN RAISE NOTICE '032-C4: fn_doc_field_get_list rewritten'; END $$;

-- --------------------------------------------------------------------
-- C.5 edoc.fn_sms_template_get_list
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_sms_template_get_list(
  p_unit_id INT DEFAULT NULL,
  p_dept_id INT DEFAULT NULL
)
RETURNS TABLE (
  id INT, unit_id INT, name VARCHAR, content TEXT,
  description TEXT, is_active BOOLEAN,
  created_by INT, created_at TIMESTAMPTZ
)
LANGUAGE sql STABLE
AS $$
  SELECT t.id, t.unit_id, t.name::VARCHAR, t.content,
         t.description, t.is_active, t.created_by, t.created_at
  FROM edoc.sms_templates t
  WHERE t.unit_id = CASE WHEN p_dept_id IS NOT NULL THEN public.fn_get_ancestor_unit(p_dept_id)
                         ELSE p_unit_id END
  ORDER BY t.name;
$$;

DO $$ BEGIN RAISE NOTICE '032-C5: fn_sms_template_get_list rewritten'; END $$;

-- --------------------------------------------------------------------
-- C.6 edoc.fn_email_template_get_list
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_email_template_get_list(
  p_unit_id INT DEFAULT NULL,
  p_dept_id INT DEFAULT NULL
)
RETURNS TABLE (
  id INT, unit_id INT, name VARCHAR, subject VARCHAR,
  content TEXT, description TEXT, is_active BOOLEAN,
  created_by INT, created_at TIMESTAMPTZ
)
LANGUAGE sql STABLE
AS $$
  SELECT t.id, t.unit_id, t.name::VARCHAR, t.subject::VARCHAR,
         t.content, t.description, t.is_active, t.created_by, t.created_at
  FROM edoc.email_templates t
  WHERE t.unit_id = CASE WHEN p_dept_id IS NOT NULL THEN public.fn_get_ancestor_unit(p_dept_id)
                         ELSE p_unit_id END
  ORDER BY t.name;
$$;

DO $$ BEGIN RAISE NOTICE '032-C6: fn_email_template_get_list rewritten'; END $$;

-- --------------------------------------------------------------------
-- C.7 edoc.fn_doc_flow_get_list
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_doc_flow_get_list(
  p_unit_id       INT,
  p_doc_field_id  INT DEFAULT NULL,
  p_is_active     BOOLEAN DEFAULT NULL,
  p_dept_id       INT DEFAULT NULL
)
RETURNS TABLE (
  id INT, name VARCHAR, version VARCHAR, doc_field_id INT,
  doc_field_name VARCHAR, is_active BOOLEAN, step_count BIGINT, created_at TIMESTAMPTZ
)
LANGUAGE plpgsql AS $$
DECLARE v_unit_id INT;
BEGIN
  IF p_dept_id IS NOT NULL THEN v_unit_id := public.fn_get_ancestor_unit(p_dept_id);
  ELSE v_unit_id := p_unit_id; END IF;

  RETURN QUERY
  SELECT f.id, f.name, f.version, f.doc_field_id, df.name AS doc_field_name,
    f.is_active, COUNT(s.id) AS step_count, f.created_at
  FROM edoc.doc_flows f
  LEFT JOIN edoc.doc_fields df ON df.id = f.doc_field_id
  LEFT JOIN edoc.doc_flow_steps s ON s.flow_id = f.id
  WHERE f.unit_id = v_unit_id
    AND (p_doc_field_id IS NULL OR f.doc_field_id = p_doc_field_id)
    AND (p_is_active IS NULL OR f.is_active = p_is_active)
  GROUP BY f.id, f.name, f.version, f.doc_field_id, df.name, f.is_active, f.created_at
  ORDER BY f.name, f.version;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-C7: fn_doc_flow_get_list rewritten'; END $$;

-- --------------------------------------------------------------------
-- C.8 iso.fn_doc_category_get_tree
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION iso.fn_doc_category_get_tree(
  p_unit_id INT,
  p_dept_id INT DEFAULT NULL
)
RETURNS TABLE (
  id INT, parent_id INT, code VARCHAR, name VARCHAR,
  date_process DECIMAL, status INT, description TEXT,
  version DECIMAL, unit_id INT, created_date TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_unit_id INT;
BEGIN
  IF p_dept_id IS NOT NULL THEN v_unit_id := public.fn_get_ancestor_unit(p_dept_id);
  ELSE v_unit_id := p_unit_id; END IF;

  RETURN QUERY
  SELECT dc.id, dc.parent_id, dc.code, dc.name, dc.date_process, dc.status,
    dc.description, dc.version, dc.unit_id, dc.created_date
  FROM iso.document_categories dc
  WHERE (dc.unit_id IS NULL OR dc.unit_id = v_unit_id) AND dc.status = 1
  ORDER BY dc.parent_id, dc.name;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-C8: fn_doc_category_get_tree rewritten'; END $$;

-- --------------------------------------------------------------------
-- C.9 cont.fn_contract_type_get_list
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cont.fn_contract_type_get_list(
  p_unit_id INT,
  p_dept_id INT DEFAULT NULL
)
RETURNS TABLE (
  id INT, unit_id INT, parent_id INT, code VARCHAR, name VARCHAR,
  note TEXT, sort_order INT, created_date TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_unit_id INT;
BEGIN
  IF p_dept_id IS NOT NULL THEN v_unit_id := public.fn_get_ancestor_unit(p_dept_id);
  ELSE v_unit_id := p_unit_id; END IF;

  RETURN QUERY
  SELECT ct.id, ct.unit_id, ct.parent_id, ct.code, ct.name, ct.note,
    ct.sort_order, ct.created_date
  FROM cont.contract_types ct
  WHERE (ct.unit_id IS NULL OR ct.unit_id = v_unit_id)
  ORDER BY ct.sort_order, ct.name;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-C9: fn_contract_type_get_list rewritten'; END $$;

-- --------------------------------------------------------------------
-- C.10 edoc.fn_room_get_list
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_room_get_list(
  p_unit_id INT,
  p_dept_id INT DEFAULT NULL
)
RETURNS TABLE (
  id INT, unit_id INT, name VARCHAR, code VARCHAR,
  location VARCHAR, note TEXT, sort_order INT,
  show_in_calendar BOOLEAN, created_date TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_unit_id INT;
BEGIN
  IF p_dept_id IS NOT NULL THEN v_unit_id := public.fn_get_ancestor_unit(p_dept_id);
  ELSE v_unit_id := p_unit_id; END IF;

  RETURN QUERY
  SELECT r.id, r.unit_id, r.name, r.code, r.location, r.note,
    r.sort_order, r.show_in_calendar, r.created_date
  FROM edoc.rooms r
  WHERE r.unit_id = v_unit_id AND r.is_deleted = false
  ORDER BY r.sort_order, r.name;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-C10: fn_room_get_list rewritten'; END $$;

-- --------------------------------------------------------------------
-- C.11 edoc.fn_meeting_type_get_list
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_meeting_type_get_list(
  p_unit_id INT,
  p_dept_id INT DEFAULT NULL
)
RETURNS TABLE (
  id INT, unit_id INT, name VARCHAR, description TEXT,
  sort_order INT, created_date TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_unit_id INT;
BEGIN
  IF p_dept_id IS NOT NULL THEN v_unit_id := public.fn_get_ancestor_unit(p_dept_id);
  ELSE v_unit_id := p_unit_id; END IF;

  RETURN QUERY
  SELECT mt.id, mt.unit_id, mt.name, mt.description, mt.sort_order, mt.created_date
  FROM edoc.meeting_types mt
  WHERE mt.unit_id = v_unit_id AND mt.is_deleted = false
  ORDER BY mt.sort_order, mt.name;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-C11: fn_meeting_type_get_list rewritten'; END $$;

-- --------------------------------------------------------------------
-- C.12 esto.fn_get_fonds_list
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION esto.fn_get_fonds_list(
  p_unit_id INT DEFAULT NULL,
  p_dept_id INT DEFAULT NULL
)
RETURNS TABLE (id INT, name VARCHAR, code VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE v_unit_id INT;
BEGIN
  IF p_dept_id IS NOT NULL THEN v_unit_id := public.fn_get_ancestor_unit(p_dept_id);
  ELSE v_unit_id := p_unit_id; END IF;

  RETURN QUERY SELECT f.id, f.fond_name, f.fond_code FROM esto.fonds f
  WHERE (v_unit_id IS NULL OR f.unit_id = v_unit_id)
  ORDER BY f.fond_name;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-C12: fn_get_fonds_list rewritten'; END $$;

-- --------------------------------------------------------------------
-- C.13 esto.fn_get_warehouses_list
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION esto.fn_get_warehouses_list(
  p_unit_id INT DEFAULT NULL,
  p_dept_id INT DEFAULT NULL
)
RETURNS TABLE (id INT, name VARCHAR, code VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE v_unit_id INT;
BEGIN
  IF p_dept_id IS NOT NULL THEN v_unit_id := public.fn_get_ancestor_unit(p_dept_id);
  ELSE v_unit_id := p_unit_id; END IF;

  RETURN QUERY SELECT w.id, w.name, w.code FROM esto.warehouses w
  WHERE (v_unit_id IS NULL OR w.unit_id = v_unit_id)
  ORDER BY w.name;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-C13: fn_get_warehouses_list rewritten'; END $$;

-- --------------------------------------------------------------------
-- C.14 public.fn_department_get_tree
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_department_get_tree(
  p_unit_id INT DEFAULT NULL,
  p_dept_id INT DEFAULT NULL
)
RETURNS TABLE (
  id INT, parent_id INT, code VARCHAR, name VARCHAR, name_en VARCHAR,
  short_name VARCHAR, abb_name VARCHAR, is_unit BOOLEAN, level INT,
  sort_order INT, phone VARCHAR, fax VARCHAR, email VARCHAR, address TEXT,
  allow_doc_book BOOLEAN, is_locked BOOLEAN, staff_count BIGINT
)
LANGUAGE sql STABLE
AS $$
  SELECT
    d.id, d.parent_id, d.code::VARCHAR, d.name::VARCHAR, d.name_en::VARCHAR,
    d.short_name::VARCHAR, d.abb_name::VARCHAR, d.is_unit, d.level,
    d.sort_order, d.phone::VARCHAR, d.fax::VARCHAR, d.email::VARCHAR, d.address,
    d.allow_doc_book, d.is_locked,
    (SELECT COUNT(*) FROM public.staff s WHERE s.department_id = d.id AND s.is_deleted = FALSE) AS staff_count
  FROM public.departments d
  WHERE d.is_deleted = FALSE
    AND (
      CASE WHEN p_dept_id IS NOT NULL THEN
        d.id = public.fn_get_ancestor_unit(p_dept_id) OR d.parent_id = public.fn_get_ancestor_unit(p_dept_id)
        OR d.parent_id IN (SELECT dd.id FROM public.departments dd WHERE dd.parent_id = public.fn_get_ancestor_unit(p_dept_id) AND dd.is_deleted = FALSE)
      ELSE
        (p_unit_id IS NULL OR d.id = p_unit_id OR d.parent_id = p_unit_id
         OR d.parent_id IN (SELECT dd.id FROM public.departments dd WHERE dd.parent_id = p_unit_id AND dd.is_deleted = FALSE))
      END
    )
  ORDER BY d.sort_order, d.name;
$$;

DO $$ BEGIN RAISE NOTICE '032-C14: fn_department_get_tree rewritten'; END $$;

-- --------------------------------------------------------------------
-- C.15 edoc.fn_incoming_doc_get_next_number
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_get_next_number(
  p_doc_book_id INT,
  p_unit_id     INT DEFAULT NULL,
  p_dept_id     INT DEFAULT NULL
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE v_max INT; v_unit_id INT;
BEGIN
  IF p_dept_id IS NOT NULL THEN v_unit_id := public.fn_get_ancestor_unit(p_dept_id);
  ELSE v_unit_id := p_unit_id; END IF;

  SELECT COALESCE(MAX(number), 0) INTO v_max
  FROM edoc.incoming_docs
  WHERE doc_book_id = p_doc_book_id
    AND unit_id = v_unit_id
    AND EXTRACT(YEAR FROM received_date) = EXTRACT(YEAR FROM NOW());
  RETURN v_max + 1;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-C15: fn_incoming_doc_get_next_number rewritten'; END $$;

-- --------------------------------------------------------------------
-- C.16 edoc.fn_outgoing_doc_get_next_number
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_get_next_number(
  p_doc_book_id INT,
  p_unit_id     INT DEFAULT NULL,
  p_dept_id     INT DEFAULT NULL
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE v_max INT; v_unit_id INT;
BEGIN
  IF p_dept_id IS NOT NULL THEN v_unit_id := public.fn_get_ancestor_unit(p_dept_id);
  ELSE v_unit_id := p_unit_id; END IF;

  SELECT COALESCE(MAX(number), 0) INTO v_max
  FROM edoc.outgoing_docs
  WHERE doc_book_id = p_doc_book_id
    AND unit_id = v_unit_id
    AND EXTRACT(YEAR FROM received_date) = EXTRACT(YEAR FROM NOW());
  RETURN v_max + 1;
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-C16: fn_outgoing_doc_get_next_number rewritten'; END $$;

-- --------------------------------------------------------------------
-- C.17 edoc.fn_outgoing_doc_check_number
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_check_number(
  p_unit_id     INT DEFAULT NULL,
  p_doc_book_id INT DEFAULT NULL,
  p_number      INT DEFAULT NULL,
  p_exclude_id  BIGINT DEFAULT NULL,
  p_dept_id     INT DEFAULT NULL
)
RETURNS TABLE (is_exists BOOLEAN)
LANGUAGE plpgsql
AS $$
DECLARE v_unit_id INT;
BEGIN
  IF p_dept_id IS NOT NULL THEN v_unit_id := public.fn_get_ancestor_unit(p_dept_id);
  ELSE v_unit_id := p_unit_id; END IF;

  RETURN QUERY
  SELECT EXISTS (
    SELECT 1 FROM edoc.outgoing_docs
    WHERE unit_id = v_unit_id
      AND doc_book_id = p_doc_book_id
      AND number = p_number
      AND EXTRACT(YEAR FROM received_date) = EXTRACT(YEAR FROM NOW())
      AND (p_exclude_id IS NULL OR id != p_exclude_id)
  );
END;
$$;

DO $$ BEGIN RAISE NOTICE '032-C17: fn_outgoing_doc_check_number rewritten'; END $$;


-- ############################################################################
-- DONE
-- ############################################################################

DO $$ BEGIN
  RAISE NOTICE '================================================================';
  RAISE NOTICE 'Migration 032: Remove unit_id dependency — COMPLETE';
  RAISE NOTICE '  Part 1: fn_get_ancestor_unit helper';
  RAISE NOTICE '  Part 2: trg_staff_auto_unit_id trigger';
  RAISE NOTICE '  Part 3: department_id columns on 9 tables + backfill';
  RAISE NOTICE '  Part 4: 68 stored procedures rewritten';
  RAISE NOTICE '    Group A: 26 CREATE/UPDATE SPs (auto-resolve unit_id)';
  RAISE NOTICE '    Group B: 23 LIST SPs (subtree filter via p_dept_ids)';
  RAISE NOTICE '    Group C: 17 LIST SPs (ancestor unit filter via p_dept_id)';
  RAISE NOTICE '  Skipped: SPs already updated in migration 030/031';
  RAISE NOTICE '================================================================';
END $$;

COMMIT;

-- ==== 033_add_rejection_tracking ====
-- ================================================================
-- Migration 033: Thêm rejection tracking cho VB đến/đi/dự thảo
--
-- Thêm cột: rejected_by INT, rejection_reason TEXT
-- Sửa SP reject để lưu thông tin
-- Sửa SP list để trả thêm rejected_by, rejection_reason
-- ================================================================

BEGIN;

-- ============================================================
-- 1. ALTER TABLE — thêm cột rejection
-- ============================================================

ALTER TABLE edoc.incoming_docs ADD COLUMN IF NOT EXISTS rejected_by INT REFERENCES public.staff(id);
ALTER TABLE edoc.incoming_docs ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

ALTER TABLE edoc.outgoing_docs ADD COLUMN IF NOT EXISTS rejected_by INT REFERENCES public.staff(id);
ALTER TABLE edoc.outgoing_docs ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

ALTER TABLE edoc.drafting_docs ADD COLUMN IF NOT EXISTS rejected_by INT REFERENCES public.staff(id);
ALTER TABLE edoc.drafting_docs ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

DO $$ BEGIN RAISE NOTICE '033-1: rejection columns added to 3 doc tables'; END $$;

-- ============================================================
-- 2. SP: fn_outgoing_doc_reject — lưu rejected_by + reason
-- ============================================================

CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_reject(
  p_id BIGINT, p_staff_id INT, p_reason TEXT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.outgoing_docs WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đi'::TEXT; RETURN;
  END IF;
  UPDATE edoc.outgoing_docs
  SET approved = FALSE, rejected_by = p_staff_id, rejection_reason = NULLIF(TRIM(p_reason), ''),
      updated_by = p_staff_id, updated_at = NOW()
  WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Đã từ chối văn bản đi'::TEXT;
END; $$;

-- ============================================================
-- 3. SP: fn_drafting_doc_reject — lưu rejected_by + reason
-- ============================================================

CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_reject(
  p_id BIGINT, p_staff_id INT, p_reason TEXT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.drafting_docs WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản dự thảo'::TEXT; RETURN;
  END IF;
  UPDATE edoc.drafting_docs
  SET approved = FALSE, rejected_by = p_staff_id, rejection_reason = NULLIF(TRIM(p_reason), ''),
      updated_by = p_staff_id, updated_at = NOW()
  WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Đã từ chối văn bản dự thảo'::TEXT;
END; $$;

-- ============================================================
-- 4. SP: fn_outgoing_doc_approve — clear rejection khi duyệt lại
-- ============================================================

CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_approve(
  p_id BIGINT, p_staff_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_name TEXT;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.outgoing_docs WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đi'::TEXT; RETURN;
  END IF;
  SELECT full_name INTO v_name FROM public.staff WHERE id = p_staff_id;
  UPDATE edoc.outgoing_docs
  SET approved = TRUE, approver = v_name, rejected_by = NULL, rejection_reason = NULL,
      updated_by = p_staff_id, updated_at = NOW()
  WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Duyệt văn bản đi thành công'::TEXT;
END; $$;

-- ============================================================
-- 5. SP: fn_drafting_doc_approve — clear rejection khi duyệt lại
-- ============================================================

CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_approve(
  p_id BIGINT, p_staff_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_name TEXT;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.drafting_docs WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản dự thảo'::TEXT; RETURN;
  END IF;
  SELECT full_name INTO v_name FROM public.staff WHERE id = p_staff_id;
  UPDATE edoc.drafting_docs
  SET approved = TRUE, approver = v_name, rejected_by = NULL, rejection_reason = NULL,
      updated_by = p_staff_id, updated_at = NOW()
  WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Duyệt văn bản dự thảo thành công'::TEXT;
END; $$;

-- ============================================================
-- 6. SP: fn_incoming_doc_approve — clear rejection khi duyệt lại
-- ============================================================

CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_approve(
  p_id BIGINT, p_staff_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_name TEXT;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.incoming_docs WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đến'::TEXT; RETURN;
  END IF;
  SELECT full_name INTO v_name FROM public.staff WHERE id = p_staff_id;
  UPDATE edoc.incoming_docs
  SET approved = TRUE, approver = v_name, rejected_by = NULL, rejection_reason = NULL,
      updated_by = p_staff_id, updated_at = NOW()
  WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Duyệt văn bản đến thành công'::TEXT;
END; $$;

DO $$ BEGIN RAISE NOTICE '033: Migration complete — rejection tracking added'; END $$;

COMMIT;

-- ==== 034_fix_ambiguous_columns ====
-- ================================================================
-- Migration 034: Fix ambiguous column references trong SPs
-- ================================================================

BEGIN;

-- 1. fn_message_get_by_id — is_read ambiguous
CREATE OR REPLACE FUNCTION edoc.fn_message_get_by_id(p_id BIGINT, p_staff_id INT)
RETURNS TABLE(id BIGINT, from_staff_id INT, from_staff_name TEXT, subject VARCHAR, content TEXT, parent_id BIGINT, created_at TIMESTAMP, is_read BOOLEAN, recipient_names TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE edoc.message_recipients mr
  SET is_read = TRUE, read_at = NOW()
  WHERE mr.message_id = p_id AND mr.staff_id = p_staff_id AND mr.is_read = FALSE;

  RETURN QUERY
  SELECT m.id, m.from_staff_id,
    CONCAT(s.last_name, ' ', s.first_name)::TEXT,
    m.subject, m.content, m.parent_id, m.created_at,
    COALESCE(mr.is_read, FALSE),
    (SELECT STRING_AGG(CONCAT(sr.last_name, ' ', sr.first_name), ', ' ORDER BY sr.last_name)
     FROM edoc.message_recipients mr2 JOIN public.staff sr ON sr.id = mr2.staff_id
     WHERE mr2.message_id = m.id)::TEXT
  FROM edoc.messages m
  JOIN public.staff s ON s.id = m.from_staff_id
  LEFT JOIN edoc.message_recipients mr ON mr.message_id = m.id AND mr.staff_id = p_staff_id
  WHERE m.id = p_id
    AND (m.from_staff_id = p_staff_id
      OR EXISTS (SELECT 1 FROM edoc.message_recipients mr3 WHERE mr3.message_id = m.id AND mr3.staff_id = p_staff_id));
END; $$;

-- 2. fn_document_archive_create — id ambiguous (đã fix trước đó nhưng lưu lại)
CREATE OR REPLACE FUNCTION esto.fn_document_archive_create(
  p_doc_type VARCHAR, p_doc_id BIGINT,
  p_fond_id INT DEFAULT NULL, p_warehouse_id INT DEFAULT NULL, p_record_id BIGINT DEFAULT NULL,
  p_file_catalog VARCHAR DEFAULT NULL, p_file_notation VARCHAR DEFAULT NULL,
  p_doc_ordinal INT DEFAULT NULL, p_language VARCHAR DEFAULT 'Tiếng Việt',
  p_autograph TEXT DEFAULT NULL, p_keyword TEXT DEFAULT NULL,
  p_format VARCHAR DEFAULT 'Điện tử', p_confidence_level VARCHAR DEFAULT NULL,
  p_is_original BOOLEAN DEFAULT true, p_archived_by INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql AS $$
DECLARE v_id BIGINT;
BEGIN
  IF p_doc_type NOT IN ('incoming', 'outgoing') THEN
    RETURN QUERY SELECT FALSE, 'Loại văn bản không hợp lệ'::TEXT, 0::BIGINT; RETURN;
  END IF;
  IF p_doc_type = 'incoming' AND NOT EXISTS (SELECT 1 FROM edoc.incoming_docs ind WHERE ind.id = p_doc_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đến'::TEXT, 0::BIGINT; RETURN;
  END IF;
  IF p_doc_type = 'outgoing' AND NOT EXISTS (SELECT 1 FROM edoc.outgoing_docs od WHERE od.id = p_doc_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đi'::TEXT, 0::BIGINT; RETURN;
  END IF;

  INSERT INTO esto.document_archives (
    doc_type, doc_id, fond_id, warehouse_id, record_id,
    file_catalog, file_notation, doc_ordinal, language,
    autograph, keyword, format, confidence_level, is_original, archived_by
  ) VALUES (
    p_doc_type, p_doc_id, p_fond_id, p_warehouse_id, p_record_id,
    NULLIF(TRIM(p_file_catalog), ''), NULLIF(TRIM(p_file_notation), ''), p_doc_ordinal,
    COALESCE(p_language, 'Tiếng Việt'),
    NULLIF(TRIM(p_autograph), ''), NULLIF(TRIM(p_keyword), ''),
    COALESCE(p_format, 'Điện tử'), NULLIF(TRIM(p_confidence_level), ''),
    COALESCE(p_is_original, true), p_archived_by
  )
  ON CONFLICT (doc_type, doc_id) DO UPDATE SET
    fond_id = EXCLUDED.fond_id, warehouse_id = EXCLUDED.warehouse_id,
    record_id = EXCLUDED.record_id, file_catalog = EXCLUDED.file_catalog,
    file_notation = EXCLUDED.file_notation, doc_ordinal = EXCLUDED.doc_ordinal,
    language = EXCLUDED.language, autograph = EXCLUDED.autograph,
    keyword = EXCLUDED.keyword, format = EXCLUDED.format,
    confidence_level = EXCLUDED.confidence_level, is_original = EXCLUDED.is_original,
    archived_by = EXCLUDED.archived_by, archive_date = NOW()
  RETURNING document_archives.id INTO v_id;

  IF p_doc_type = 'incoming' THEN
    UPDATE edoc.incoming_docs SET archive_status = true WHERE edoc.incoming_docs.id = p_doc_id;
  ELSIF p_doc_type = 'outgoing' THEN
    UPDATE edoc.outgoing_docs SET archive_status = true WHERE edoc.outgoing_docs.id = p_doc_id;
  END IF;

  RETURN QUERY SELECT TRUE, 'Chuyển lưu trữ thành công'::TEXT, v_id;
END; $$;

-- 3. fn_message_reply — id ambiguous (WHERE id = p_message_id + RETURNING id)
CREATE OR REPLACE FUNCTION edoc.fn_message_reply(p_message_id BIGINT, p_staff_id INT, p_content TEXT)
RETURNS TABLE(success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_reply_id BIGINT;
  v_original edoc.messages%ROWTYPE;
  v_subject VARCHAR(200);
  v_staff_id INT;
BEGIN
  IF p_content IS NULL OR TRIM(p_content) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nội dung trả lời không được để trống'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  SELECT * INTO v_original FROM edoc.messages m WHERE m.id = p_message_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy tin nhắn gốc'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  v_subject := 'Re: ' || v_original.subject;

  INSERT INTO edoc.messages (from_staff_id, subject, content, parent_id, created_at)
  VALUES (p_staff_id, v_subject, p_content, p_message_id, NOW())
  RETURNING edoc.messages.id INTO v_reply_id;

  INSERT INTO edoc.message_recipients (message_id, staff_id, is_read, is_deleted)
  VALUES (v_reply_id, v_original.from_staff_id, FALSE, FALSE)
  ON CONFLICT (message_id, staff_id) DO NOTHING;

  FOR v_staff_id IN
    SELECT mr.staff_id FROM edoc.message_recipients mr
    WHERE mr.message_id = p_message_id AND mr.staff_id <> p_staff_id
  LOOP
    INSERT INTO edoc.message_recipients (message_id, staff_id, is_read, is_deleted)
    VALUES (v_reply_id, v_staff_id, FALSE, FALSE)
    ON CONFLICT (message_id, staff_id) DO NOTHING;
  END LOOP;

  RETURN QUERY SELECT TRUE, 'Trả lời tin nhắn thành công'::TEXT, v_reply_id;
END; $$;

DO $$ BEGIN RAISE NOTICE '034: Fixed ambiguous columns in fn_message_get_by_id + fn_document_archive_create + fn_message_reply'; END $$;

COMMIT;

-- ==== 035_fix_message_sender_delete ====
-- ================================================================
-- Migration 035: Cho phép người gửi xóa tin nhắn từ hộp gửi đi
-- ================================================================

BEGIN;

ALTER TABLE edoc.messages ADD COLUMN IF NOT EXISTS sender_deleted BOOLEAN DEFAULT FALSE;
ALTER TABLE edoc.messages ADD COLUMN IF NOT EXISTS sender_deleted_at TIMESTAMPTZ;

CREATE OR REPLACE FUNCTION edoc.fn_message_delete(p_id BIGINT, p_staff_id INT)
RETURNS TABLE(success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_is_sender BOOLEAN; v_is_recipient BOOLEAN;
BEGIN
  SELECT EXISTS(SELECT 1 FROM edoc.messages WHERE edoc.messages.id = p_id AND from_staff_id = p_staff_id) INTO v_is_sender;
  SELECT EXISTS(SELECT 1 FROM edoc.message_recipients WHERE message_id = p_id AND staff_id = p_staff_id AND is_deleted = FALSE) INTO v_is_recipient;

  IF NOT v_is_sender AND NOT v_is_recipient THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy tin nhắn hoặc đã bị xóa'::TEXT;
    RETURN;
  END IF;

  IF v_is_sender THEN
    UPDATE edoc.messages SET sender_deleted = TRUE, sender_deleted_at = NOW() WHERE edoc.messages.id = p_id;
  END IF;

  IF v_is_recipient THEN
    UPDATE edoc.message_recipients SET is_deleted = TRUE, deleted_at = NOW()
    WHERE message_id = p_id AND staff_id = p_staff_id;
  END IF;

  RETURN QUERY SELECT TRUE, 'Xóa tin nhắn thành công'::TEXT;
END; $$;

DO $$ BEGIN RAISE NOTICE '035: sender_deleted + fix fn_message_delete'; END $$;
COMMIT;

-- ==== 036_fix_message_sent_trash ====
-- ================================================================
-- Migration 036: Fix sent/trash cho sender_deleted
--
-- - fn_message_get_sent: exclude sender_deleted = TRUE
-- - fn_message_get_trash: UNION sender_deleted messages
-- - fn_message_restore: handle sender restore
-- - fn_message_permanent_delete: handle sender permanent delete
-- ================================================================

BEGIN;

CREATE OR REPLACE FUNCTION edoc.fn_message_get_sent(p_staff_id INT, p_keyword TEXT, p_page INT DEFAULT 1, p_page_size INT DEFAULT 20)
RETURNS TABLE(id BIGINT, subject VARCHAR, content TEXT, parent_id BIGINT, created_at TIMESTAMP, recipient_names TEXT, total_count BIGINT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT m.id, m.subject, m.content, m.parent_id, m.created_at,
      (SELECT STRING_AGG(CONCAT(sr.last_name, ' ', sr.first_name), ', ' ORDER BY sr.last_name)
       FROM edoc.message_recipients mr2 JOIN public.staff sr ON sr.id = mr2.staff_id WHERE mr2.message_id = m.id) AS recipient_names
    FROM edoc.messages m
    WHERE m.from_staff_id = p_staff_id AND m.parent_id IS NULL
      AND COALESCE(m.sender_deleted, FALSE) = FALSE
      AND (p_keyword IS NULL OR TRIM(p_keyword) = '' OR m.subject ILIKE '%' || p_keyword || '%' OR m.content ILIKE '%' || p_keyword || '%')
  )
  SELECT f.id, f.subject, f.content, f.parent_id, f.created_at, f.recipient_names, COUNT(*) OVER()::BIGINT
  FROM filtered f ORDER BY f.created_at DESC LIMIT COALESCE(p_page_size, 20) OFFSET v_offset;
END; $$;

CREATE OR REPLACE FUNCTION edoc.fn_message_get_trash(p_staff_id INT, p_page INT DEFAULT 1, p_page_size INT DEFAULT 20)
RETURNS TABLE(id BIGINT, from_staff_id INT, from_staff_name TEXT, subject VARCHAR, content TEXT, parent_id BIGINT, created_at TIMESTAMP, deleted_at TIMESTAMP, total_count BIGINT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT m.id, m.from_staff_id, CONCAT(s.last_name, ' ', s.first_name) AS from_staff_name,
      m.subject, m.content, m.parent_id, m.created_at, mr.deleted_at::TIMESTAMP
    FROM edoc.messages m
    JOIN edoc.message_recipients mr ON mr.message_id = m.id AND mr.staff_id = p_staff_id
    JOIN public.staff s ON s.id = m.from_staff_id
    WHERE mr.is_deleted = TRUE
    UNION
    SELECT m.id, m.from_staff_id, CONCAT(s.last_name, ' ', s.first_name),
      m.subject, m.content, m.parent_id, m.created_at, m.sender_deleted_at::TIMESTAMP
    FROM edoc.messages m
    JOIN public.staff s ON s.id = m.from_staff_id
    WHERE m.from_staff_id = p_staff_id AND m.sender_deleted = TRUE
  )
  SELECT f.id, f.from_staff_id, f.from_staff_name, f.subject, f.content, f.parent_id, f.created_at, f.deleted_at,
    COUNT(*) OVER()::BIGINT
  FROM filtered f ORDER BY f.deleted_at DESC NULLS LAST LIMIT COALESCE(p_page_size, 20) OFFSET v_offset;
END; $$;

CREATE OR REPLACE FUNCTION edoc.fn_message_restore(p_id BIGINT, p_staff_id INT)
RETURNS TABLE(success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_restored BOOLEAN := FALSE;
BEGIN
  IF EXISTS (SELECT 1 FROM edoc.message_recipients WHERE message_id = p_id AND staff_id = p_staff_id AND is_deleted = TRUE) THEN
    UPDATE edoc.message_recipients SET is_deleted = FALSE, deleted_at = NULL WHERE message_id = p_id AND staff_id = p_staff_id;
    v_restored := TRUE;
  END IF;
  IF EXISTS (SELECT 1 FROM edoc.messages WHERE edoc.messages.id = p_id AND from_staff_id = p_staff_id AND sender_deleted = TRUE) THEN
    UPDATE edoc.messages SET sender_deleted = FALSE, sender_deleted_at = NULL WHERE edoc.messages.id = p_id;
    v_restored := TRUE;
  END IF;
  IF v_restored THEN RETURN QUERY SELECT TRUE, 'Khôi phục tin nhắn thành công'::TEXT;
  ELSE RETURN QUERY SELECT FALSE, 'Không tìm thấy tin nhắn trong thùng rác'::TEXT; END IF;
END; $$;

CREATE OR REPLACE FUNCTION edoc.fn_message_permanent_delete(p_id BIGINT, p_staff_id INT)
RETURNS TABLE(success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_deleted BOOLEAN := FALSE;
BEGIN
  IF EXISTS (SELECT 1 FROM edoc.message_recipients WHERE message_id = p_id AND staff_id = p_staff_id AND is_deleted = TRUE) THEN
    DELETE FROM edoc.message_recipients WHERE message_id = p_id AND staff_id = p_staff_id;
    v_deleted := TRUE;
  END IF;
  IF EXISTS (SELECT 1 FROM edoc.messages WHERE edoc.messages.id = p_id AND from_staff_id = p_staff_id AND sender_deleted = TRUE) THEN
    v_deleted := TRUE;
  END IF;
  IF v_deleted THEN RETURN QUERY SELECT TRUE, 'Đã xóa vĩnh viễn tin nhắn'::TEXT;
  ELSE RETURN QUERY SELECT FALSE, 'Không tìm thấy tin nhắn trong thùng rác'::TEXT; END IF;
END; $$;

DO $$ BEGIN RAISE NOTICE '036: Fixed sent/trash/restore/permanent-delete for sender_deleted'; END $$;
COMMIT;

-- ==== 037_dashboard_v2 ====
-- ================================================================
-- MIGRATION 037: Dashboard V2 — Biểu đồ + Stat cards mở rộng
-- Thêm 8 stored functions cho dashboard nâng cấp
-- ================================================================

-- ==========================================
-- 1. Thống kê mở rộng (stat cards bổ sung)
-- Trả về: drafting_pending, message_unread, notice_unread, today_meetings
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_get_stats_extra(
  p_staff_id INT,
  p_dept_ids INT[] DEFAULT NULL
) RETURNS TABLE (
  drafting_pending BIGINT,
  message_unread   BIGINT,
  notice_unread    BIGINT,
  today_meetings   BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    -- VB dự thảo chờ phát hành (approved nhưng chưa released)
    (
      SELECT COUNT(*)
      FROM edoc.drafting_docs dd
      WHERE dd.approved = TRUE
        AND dd.is_released = FALSE
        AND (p_dept_ids IS NULL OR dd.unit_id = ANY(p_dept_ids))
    ) AS drafting_pending,

    -- Tin nhắn chưa đọc
    (
      SELECT COUNT(*)
      FROM edoc.message_recipients mr
      WHERE mr.staff_id = p_staff_id
        AND mr.is_read = FALSE
        AND mr.is_deleted = FALSE
    ) AS message_unread,

    -- Thông báo chưa đọc
    (
      SELECT COUNT(*)
      FROM edoc.notices n
      WHERE NOT EXISTS (
        SELECT 1 FROM edoc.notice_reads nr
        WHERE nr.notice_id = n.id AND nr.staff_id = p_staff_id
      )
      AND (
        n.unit_id IS NULL
        OR n.unit_id = ANY(COALESCE(p_dept_ids, ARRAY[]::INT[]))
      )
    ) AS notice_unread,

    -- Lịch họp hôm nay
    (
      SELECT COUNT(*)
      FROM edoc.room_schedules rs
      WHERE rs.start_date = CURRENT_DATE
        AND (p_dept_ids IS NULL OR rs.unit_id = ANY(p_dept_ids))
    ) AS today_meetings;
END;
$$;

-- ==========================================
-- 2. VB đến/đi theo tháng (6 tháng gần nhất)
-- Dùng cho biểu đồ cột grouped bar chart
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_doc_by_month(
  p_dept_ids INT[] DEFAULT NULL,
  p_months   INT DEFAULT 6
) RETURNS TABLE (
  month_label  TEXT,
  incoming_count BIGINT,
  outgoing_count BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  WITH months AS (
    SELECT generate_series(
      date_trunc('month', CURRENT_DATE) - ((p_months - 1) || ' months')::interval,
      date_trunc('month', CURRENT_DATE),
      '1 month'::interval
    )::date AS m
  )
  SELECT
    to_char(mo.m, 'MM/YYYY')::TEXT AS month_label,
    COALESCE((
      SELECT COUNT(*)
      FROM edoc.incoming_docs ind
      WHERE date_trunc('month', COALESCE(ind.received_date, ind.created_at)) = mo.m
        AND (p_dept_ids IS NULL OR ind.unit_id = ANY(p_dept_ids))
    ), 0) AS incoming_count,
    COALESCE((
      SELECT COUNT(*)
      FROM edoc.outgoing_docs od
      WHERE date_trunc('month', COALESCE(od.publish_date, od.created_at)) = mo.m
        AND (p_dept_ids IS NULL OR od.unit_id = ANY(p_dept_ids))
    ), 0) AS outgoing_count
  FROM months mo
  ORDER BY mo.m;
END;
$$;

-- ==========================================
-- 3. HSCV theo trạng thái (biểu đồ tròn)
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_task_by_status(
  p_staff_id INT,
  p_dept_ids INT[] DEFAULT NULL
) RETURNS TABLE (
  status_code  SMALLINT,
  status_name  TEXT,
  task_count   BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    hd.status AS status_code,
    CASE hd.status
      WHEN 0 THEN 'Mới'
      WHEN 1 THEN 'Đang xử lý'
      WHEN 2 THEN 'Chờ duyệt'
      WHEN 3 THEN 'Đã duyệt'
      WHEN 4 THEN 'Hoàn thành'
      WHEN -1 THEN 'Từ chối'
      WHEN -2 THEN 'Trả về'
      ELSE 'Khác'
    END::TEXT AS status_name,
    COUNT(*)::BIGINT AS task_count
  FROM edoc.handling_docs hd
  WHERE (p_dept_ids IS NULL OR hd.unit_id = ANY(p_dept_ids))
  GROUP BY hd.status
  ORDER BY hd.status;
END;
$$;

-- ==========================================
-- 4. Top 5 phòng ban có nhiều VB nhất (biểu đồ cột ngang)
-- Đếm tổng VB đến + đi theo phòng ban
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_top_departments(
  p_dept_ids INT[] DEFAULT NULL,
  p_limit    INT DEFAULT 5
) RETURNS TABLE (
  department_id   INT,
  department_name VARCHAR,
  doc_count       BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  WITH dept_incoming AS (
    SELECT ind.department_id AS dept_id, COUNT(*) AS cnt
    FROM edoc.incoming_docs ind
    WHERE ind.department_id IS NOT NULL
      AND (p_dept_ids IS NULL OR ind.unit_id = ANY(p_dept_ids))
    GROUP BY ind.department_id
  ),
  dept_outgoing AS (
    SELECT od.department_id AS dept_id, COUNT(*) AS cnt
    FROM edoc.outgoing_docs od
    WHERE od.department_id IS NOT NULL
      AND (p_dept_ids IS NULL OR od.unit_id = ANY(p_dept_ids))
    GROUP BY od.department_id
  ),
  combined AS (
    SELECT dept_id, SUM(cnt)::BIGINT AS total
    FROM (
      SELECT * FROM dept_incoming
      UNION ALL
      SELECT * FROM dept_outgoing
    ) sub
    GROUP BY dept_id
  )
  SELECT
    c.dept_id AS department_id,
    d.name AS department_name,
    c.total AS doc_count
  FROM combined c
  INNER JOIN public.departments d ON d.id = c.dept_id
  ORDER BY c.total DESC
  LIMIT COALESCE(p_limit, 5);
END;
$$;

-- ==========================================
-- 5. Thông báo mới nhất (widget)
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_recent_notices(
  p_staff_id INT,
  p_dept_ids INT[] DEFAULT NULL,
  p_limit    INT DEFAULT 5
) RETURNS TABLE (
  id          BIGINT,
  title       VARCHAR,
  notice_type VARCHAR,
  created_at  TIMESTAMP,
  is_read     BOOLEAN
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    n.id,
    n.title,
    n.notice_type,
    n.created_at,
    EXISTS (
      SELECT 1 FROM edoc.notice_reads nr
      WHERE nr.notice_id = n.id AND nr.staff_id = p_staff_id
    ) AS is_read
  FROM edoc.notices n
  WHERE (
    n.unit_id IS NULL
    OR n.unit_id = ANY(COALESCE(p_dept_ids, ARRAY[]::INT[]))
  )
  ORDER BY n.created_at DESC
  LIMIT COALESCE(p_limit, 5);
END;
$$;

-- ==========================================
-- 6. Lịch hôm nay (widget mini calendar)
-- Lấy sự kiện hôm nay + 7 ngày tới
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_calendar_today(
  p_staff_id INT,
  p_dept_ids INT[] DEFAULT NULL,
  p_days     INT DEFAULT 7
) RETURNS TABLE (
  id         BIGINT,
  title      VARCHAR,
  start_time TIMESTAMP,
  end_time   TIMESTAMP,
  all_day    BOOLEAN,
  color      VARCHAR,
  scope      VARCHAR
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    ce.id,
    ce.title,
    ce.start_time,
    ce.end_time,
    ce.all_day,
    ce.color,
    ce.scope
  FROM public.calendar_events ce
  WHERE ce.is_deleted = FALSE
    AND ce.start_time < (CURRENT_DATE + p_days * interval '1 day')
    AND ce.end_time >= CURRENT_DATE
    AND (
      (ce.scope = 'personal' AND ce.created_by = p_staff_id)
      OR (ce.scope IN ('unit', 'leader') AND (
        p_dept_ids IS NULL
        OR ce.unit_id = ANY(p_dept_ids)
      ))
    )
  ORDER BY ce.start_time ASC
  LIMIT 10;
END;
$$;

-- ==========================================
-- 7. Tỷ lệ xử lý đúng hạn — KPI admin
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_ontime_rate(
  p_dept_ids INT[] DEFAULT NULL
) RETURNS TABLE (
  total_completed BIGINT,
  ontime_count    BIGINT,
  overdue_count   BIGINT,
  ontime_percent  NUMERIC
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  WITH completed AS (
    SELECT
      hd.id,
      CASE
        WHEN hd.complete_date IS NOT NULL AND hd.end_date IS NOT NULL
             AND hd.complete_date <= hd.end_date THEN TRUE
        ELSE FALSE
      END AS is_ontime
    FROM edoc.handling_docs hd
    WHERE hd.status = 4  -- Hoàn thành
      AND (p_dept_ids IS NULL OR hd.unit_id = ANY(p_dept_ids))
  )
  SELECT
    COUNT(*)::BIGINT AS total_completed,
    COUNT(*) FILTER (WHERE c.is_ontime = TRUE)::BIGINT AS ontime_count,
    COUNT(*) FILTER (WHERE c.is_ontime = FALSE)::BIGINT AS overdue_count,
    CASE
      WHEN COUNT(*) = 0 THEN 0
      ELSE ROUND(COUNT(*) FILTER (WHERE c.is_ontime = TRUE)::NUMERIC / COUNT(*)::NUMERIC * 100, 1)
    END AS ontime_percent
  FROM completed c;
END;
$$;

-- ==========================================
-- 8. VB theo đơn vị/phòng ban (admin) — biểu đồ cột
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_doc_by_department(
  p_dept_ids INT[] DEFAULT NULL
) RETURNS TABLE (
  department_id    INT,
  department_name  VARCHAR,
  incoming_count   BIGINT,
  outgoing_count   BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  WITH depts AS (
    SELECT d.id, d.name
    FROM public.departments d
    WHERE d.is_deleted = FALSE
      AND d.is_unit = FALSE
      AND (p_dept_ids IS NULL OR d.id = ANY(p_dept_ids))
  ),
  inc AS (
    SELECT ind.department_id AS dept_id, COUNT(*) AS cnt
    FROM edoc.incoming_docs ind
    WHERE ind.department_id IS NOT NULL
      AND (p_dept_ids IS NULL OR ind.unit_id = ANY(p_dept_ids))
    GROUP BY ind.department_id
  ),
  outg AS (
    SELECT od.department_id AS dept_id, COUNT(*) AS cnt
    FROM edoc.outgoing_docs od
    WHERE od.department_id IS NOT NULL
      AND (p_dept_ids IS NULL OR od.unit_id = ANY(p_dept_ids))
    GROUP BY od.department_id
  )
  SELECT
    dp.id AS department_id,
    dp.name AS department_name,
    COALESCE(i.cnt, 0) AS incoming_count,
    COALESCE(o.cnt, 0) AS outgoing_count
  FROM depts dp
  LEFT JOIN inc i ON i.dept_id = dp.id
  LEFT JOIN outg o ON o.dept_id = dp.id
  WHERE COALESCE(i.cnt, 0) + COALESCE(o.cnt, 0) > 0
  ORDER BY (COALESCE(i.cnt, 0) + COALESCE(o.cnt, 0)) DESC
  LIMIT 10;
END;
$$;

-- ==========================================
-- Cập nhật fn_dashboard_get_stats: thêm p_dept_ids param
-- (đã được cập nhật trong migration 030, chỉ ghi chú)
-- ==========================================

