-- ============================================================================
-- Migration 022: Doc Module Fixes — Schema Changes + SP Updates
-- Ngay: 2026-04-16
-- Muc dich: Hoan thien 5 module VB den/di/du thao/lien thong/danh dau
-- ============================================================================

BEGIN;

-- ============================================================================
-- BATCH 1: SCHEMA CHANGES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1.1 incoming_docs — Them cot "Noi gui" va "Ngay nhan ban giay"
-- ----------------------------------------------------------------------------
ALTER TABLE edoc.incoming_docs ADD COLUMN IF NOT EXISTS sents TEXT;
COMMENT ON COLUMN edoc.incoming_docs.sents IS 'Noi gui van ban (source cu: Sents)';

ALTER TABLE edoc.incoming_docs ADD COLUMN IF NOT EXISTS received_paper_date TIMESTAMPTZ;
COMMENT ON COLUMN edoc.incoming_docs.received_paper_date IS 'Ngay nhan ban giay (chi co khi is_received_paper=true)';

-- ----------------------------------------------------------------------------
-- 1.2 leader_notes — Mo rong cho VB di + VB du thao
-- Hien tai chi co incoming_doc_id NOT NULL — can nullable + them 2 cot moi
-- ----------------------------------------------------------------------------
ALTER TABLE edoc.leader_notes ALTER COLUMN incoming_doc_id DROP NOT NULL;

ALTER TABLE edoc.leader_notes ADD COLUMN IF NOT EXISTS outgoing_doc_id BIGINT
  REFERENCES edoc.outgoing_docs(id) ON DELETE CASCADE;

ALTER TABLE edoc.leader_notes ADD COLUMN IF NOT EXISTS drafting_doc_id BIGINT
  REFERENCES edoc.drafting_docs(id) ON DELETE CASCADE;

-- Constraint: dung 1 trong 3 doc_id duoc co gia tri (XOR)
-- Drop truoc neu ton tai (cho phep chay lai)
ALTER TABLE edoc.leader_notes DROP CONSTRAINT IF EXISTS chk_leader_note_doc_type;
ALTER TABLE edoc.leader_notes ADD CONSTRAINT chk_leader_note_doc_type
  CHECK (
    (incoming_doc_id IS NOT NULL)::int +
    (outgoing_doc_id IS NOT NULL)::int +
    (drafting_doc_id IS NOT NULL)::int = 1
  );

-- Index cho cac cot moi
CREATE INDEX IF NOT EXISTS idx_leader_notes_outgoing ON edoc.leader_notes(outgoing_doc_id)
  WHERE outgoing_doc_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_leader_notes_drafting ON edoc.leader_notes(drafting_doc_id)
  WHERE drafting_doc_id IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 1.3 staff_notes — Them is_important (danh dau quan trong)
-- ----------------------------------------------------------------------------
ALTER TABLE edoc.staff_notes ADD COLUMN IF NOT EXISTS is_important BOOLEAN DEFAULT false;
COMMENT ON COLUMN edoc.staff_notes.is_important IS 'Danh dau quan trong (source cu: IsImportant)';

-- ----------------------------------------------------------------------------
-- 1.4 drafting_docs — Them reject_reason (ly do tu choi)
-- ----------------------------------------------------------------------------
ALTER TABLE edoc.drafting_docs ADD COLUMN IF NOT EXISTS reject_reason TEXT;
COMMENT ON COLUMN edoc.drafting_docs.reject_reason IS 'Ly do tu choi (ghi boi nguoi tu choi)';

-- ----------------------------------------------------------------------------
-- 1.5 Attachment tables — Them description cho 3 bang
-- Source cu co FileDescription, moi thieu
-- ----------------------------------------------------------------------------
ALTER TABLE edoc.attachment_incoming_docs ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE edoc.attachment_outgoing_docs ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE edoc.attachment_drafting_docs ADD COLUMN IF NOT EXISTS description TEXT;

COMMENT ON COLUMN edoc.attachment_incoming_docs.description IS 'Mo ta file dinh kem';
COMMENT ON COLUMN edoc.attachment_outgoing_docs.description IS 'Mo ta file dinh kem';
COMMENT ON COLUMN edoc.attachment_drafting_docs.description IS 'Mo ta file dinh kem';

-- ----------------------------------------------------------------------------
-- 1.6 user_outgoing_docs + user_drafting_docs — Them tracking columns
-- Source cu co: UserSend, ExpiredDate — moi thieu
-- ----------------------------------------------------------------------------
ALTER TABLE edoc.user_outgoing_docs ADD COLUMN IF NOT EXISTS sent_by INTEGER
  REFERENCES staff(id);
ALTER TABLE edoc.user_outgoing_docs ADD COLUMN IF NOT EXISTS expired_date TIMESTAMPTZ;

COMMENT ON COLUMN edoc.user_outgoing_docs.sent_by IS 'Nguoi gui (staff_id)';
COMMENT ON COLUMN edoc.user_outgoing_docs.expired_date IS 'Han xu ly per-person';

ALTER TABLE edoc.user_drafting_docs ADD COLUMN IF NOT EXISTS sent_by INTEGER
  REFERENCES staff(id);
ALTER TABLE edoc.user_drafting_docs ADD COLUMN IF NOT EXISTS expired_date TIMESTAMPTZ;

COMMENT ON COLUMN edoc.user_drafting_docs.sent_by IS 'Nguoi gui (staff_id)';
COMMENT ON COLUMN edoc.user_drafting_docs.expired_date IS 'Han xu ly per-person';

-- ----------------------------------------------------------------------------
-- 1.7 inter_incoming_docs — Them truong LGSP + thong tin bo sung
-- Source cu co nhieu truong: OrganID, FromOrganID, Priority, PageAmount...
-- ----------------------------------------------------------------------------
ALTER TABLE edoc.inter_incoming_docs ADD COLUMN IF NOT EXISTS organ_id VARCHAR(100);
COMMENT ON COLUMN edoc.inter_incoming_docs.organ_id IS 'Ma don vi gui (LGSP OrganID)';

ALTER TABLE edoc.inter_incoming_docs ADD COLUMN IF NOT EXISTS from_organ_id VARCHAR(100);
COMMENT ON COLUMN edoc.inter_incoming_docs.from_organ_id IS 'Ma don vi nhan (LGSP FromOrganID)';

ALTER TABLE edoc.inter_incoming_docs ADD COLUMN IF NOT EXISTS number_paper INTEGER DEFAULT 1;
ALTER TABLE edoc.inter_incoming_docs ADD COLUMN IF NOT EXISTS number_copies INTEGER DEFAULT 1;
ALTER TABLE edoc.inter_incoming_docs ADD COLUMN IF NOT EXISTS secret_id SMALLINT DEFAULT 1;
ALTER TABLE edoc.inter_incoming_docs ADD COLUMN IF NOT EXISTS urgent_id SMALLINT DEFAULT 1;
ALTER TABLE edoc.inter_incoming_docs ADD COLUMN IF NOT EXISTS recipients TEXT;

ALTER TABLE edoc.inter_incoming_docs ADD COLUMN IF NOT EXISTS doc_field_id INTEGER
  REFERENCES edoc.doc_fields(id);

-- Index cho LGSP lookup
CREATE INDEX IF NOT EXISTS idx_inter_incoming_organ ON edoc.inter_incoming_docs(organ_id)
  WHERE organ_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_inter_incoming_external ON edoc.inter_incoming_docs(external_doc_id)
  WHERE external_doc_id IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 1.8 Tao bang attachment_inter_incoming_docs
-- Source cu co AttachmentInterIncomingDoc — moi thieu hoan toan
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS edoc.attachment_inter_incoming_docs (
  id            BIGSERIAL PRIMARY KEY,
  inter_incoming_doc_id BIGINT NOT NULL
    REFERENCES edoc.inter_incoming_docs(id) ON DELETE CASCADE,
  file_name     VARCHAR(500) NOT NULL,
  file_path     VARCHAR(1000) NOT NULL,
  file_size     BIGINT DEFAULT 0,
  content_type  VARCHAR(100),
  description   TEXT,
  sort_order    INTEGER DEFAULT 0,
  created_by    INTEGER REFERENCES staff(id),
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_attach_inter_incoming_doc
  ON edoc.attachment_inter_incoming_docs(inter_incoming_doc_id);

COMMENT ON TABLE edoc.attachment_inter_incoming_docs
  IS 'File dinh kem VB lien thong (tu LGSP hoac upload thu cong)';

-- ============================================================================
-- Ket thuc Batch 1
-- ============================================================================

DO $$ BEGIN
  RAISE NOTICE '✅ Migration 022 — Batch 1: Schema changes applied';
  RAISE NOTICE '   incoming_docs: +sents, +received_paper_date';
  RAISE NOTICE '   leader_notes: +outgoing_doc_id, +drafting_doc_id (nullable incoming_doc_id)';
  RAISE NOTICE '   staff_notes: +is_important';
  RAISE NOTICE '   drafting_docs: +reject_reason';
  RAISE NOTICE '   attachment_*_docs: +description (3 tables)';
  RAISE NOTICE '   user_outgoing/drafting_docs: +sent_by, +expired_date';
  RAISE NOTICE '   inter_incoming_docs: +organ_id, +from_organ_id, +number_paper, +number_copies, +secret_id, +urgent_id, +recipients, +doc_field_id';
  RAISE NOTICE '   NEW TABLE: attachment_inter_incoming_docs';
END $$;

COMMIT;

-- ============================================================================
-- BATCH 2: STORED PROCEDURE UPDATES
-- ============================================================================

BEGIN;

-- ============================================================================
-- DROP functions có RETURNS TABLE thay đổi (CREATE OR REPLACE không cho đổi)
-- ============================================================================
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_get_by_id(BIGINT, INT);
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_create(INT, TIMESTAMPTZ, INT, VARCHAR, VARCHAR, TEXT, VARCHAR, TIMESTAMPTZ, VARCHAR, TIMESTAMPTZ, INT, INT, INT, SMALLINT, SMALLINT, INT, INT, TIMESTAMPTZ, TEXT, BOOLEAN, INT);
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_update(BIGINT, TIMESTAMPTZ, INT, VARCHAR, VARCHAR, TEXT, VARCHAR, TIMESTAMPTZ, VARCHAR, TIMESTAMPTZ, INT, INT, INT, SMALLINT, SMALLINT, INT, INT, TIMESTAMPTZ, TEXT, BOOLEAN, INT);
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_receive_paper(BIGINT, INT);
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_get_list(INT, INT, INT, INT, INT, SMALLINT, BOOLEAN, BOOLEAN, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, INT, INT);
DROP FUNCTION IF EXISTS edoc.fn_outgoing_doc_get_by_id(BIGINT, INT);
DROP FUNCTION IF EXISTS edoc.fn_outgoing_doc_retract(BIGINT, INT);
DROP FUNCTION IF EXISTS edoc.fn_outgoing_doc_send(BIGINT, INT[], INT);
DROP FUNCTION IF EXISTS edoc.fn_drafting_doc_get_by_id(BIGINT, INT);
DROP FUNCTION IF EXISTS edoc.fn_drafting_doc_reject(BIGINT, INT, TEXT);
DROP FUNCTION IF EXISTS edoc.fn_drafting_doc_retract(BIGINT, INT);
DROP FUNCTION IF EXISTS edoc.fn_drafting_doc_send(BIGINT, INT[], INT);
DROP FUNCTION IF EXISTS edoc.fn_inter_incoming_get_by_id(BIGINT);
DROP FUNCTION IF EXISTS edoc.fn_inter_incoming_get_list(INT, TEXT, TEXT, DATE, DATE, INT, INT);
DROP FUNCTION IF EXISTS edoc.fn_staff_note_toggle(VARCHAR, BIGINT, INT, TEXT);
DROP FUNCTION IF EXISTS edoc.fn_staff_note_get_list(INT, VARCHAR);

-- ############################################################################
-- VĂN BẢN ĐẾN — SP Updates
-- ############################################################################

-- ----------------------------------------------------------------------------
-- 2.1 fn_incoming_doc_get_by_id — Thêm: is_inter_doc, inter_doc_id, sents, received_paper_date
-- BUG CŨ: thiếu is_inter_doc → nút "Nhận bàn giao" không hiển thị
-- ----------------------------------------------------------------------------
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
  sents           TEXT,                  -- MỚI
  approver        VARCHAR,
  approved        BOOLEAN,
  is_handling     BOOLEAN,
  is_received_paper BOOLEAN,
  received_paper_date TIMESTAMPTZ,       -- MỚI
  archive_status  BOOLEAN,
  is_inter_doc    BOOLEAN,               -- MỚI (đã có trong bảng, thiếu trong SP cũ)
  inter_doc_id    INT,                   -- MỚI
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
    d.sents,                                    -- MỚI
    d.approver, d.approved, d.is_handling, d.is_received_paper,
    d.received_paper_date,                      -- MỚI
    d.archive_status,
    d.is_inter_doc,                             -- MỚI
    d.inter_doc_id,                             -- MỚI
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

-- ----------------------------------------------------------------------------
-- 2.2 fn_incoming_doc_create — Thêm p_sents
-- ----------------------------------------------------------------------------
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
  p_sents           TEXT DEFAULT NULL,           -- MỚI
  p_is_received_paper BOOLEAN DEFAULT FALSE,
  p_created_by      INT DEFAULT NULL
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

  INSERT INTO edoc.incoming_docs (
    unit_id, received_date, number, notation, document_code,
    abstract, publish_unit, publish_date, signer, sign_date,
    doc_book_id, doc_type_id, doc_field_id, secret_id, urgent_id,
    number_paper, number_copies, expired_date, recipients, sents,
    is_received_paper, created_by, updated_by
  ) VALUES (
    p_unit_id, COALESCE(p_received_date, NOW()), p_number, NULLIF(TRIM(p_notation), ''), NULLIF(TRIM(p_document_code), ''),
    TRIM(p_abstract), NULLIF(TRIM(p_publish_unit), ''), p_publish_date, NULLIF(TRIM(p_signer), ''), p_sign_date,
    p_doc_book_id, p_doc_type_id, p_doc_field_id, COALESCE(p_secret_id, 1), COALESCE(p_urgent_id, 1),
    COALESCE(p_number_paper, 1), COALESCE(p_number_copies, 1), p_expired_date, NULLIF(TRIM(p_recipients), ''),
    NULLIF(TRIM(p_sents), ''),
    COALESCE(p_is_received_paper, FALSE), p_created_by, p_created_by
  )
  RETURNING edoc.incoming_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tạo văn bản đến thành công'::TEXT, v_id;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2.2 fn_incoming_doc_update — Thêm p_sents
-- ----------------------------------------------------------------------------
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
  p_sents           TEXT DEFAULT NULL,           -- MỚI
  p_is_received_paper BOOLEAN DEFAULT FALSE,
  p_updated_by      INT DEFAULT NULL
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
    sents           = NULLIF(TRIM(p_sents), ''),       -- MỚI
    is_received_paper = COALESCE(p_is_received_paper, FALSE),
    updated_by      = p_updated_by,
    updated_at      = NOW()
  WHERE edoc.incoming_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Cập nhật văn bản đến thành công'::TEXT;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2.3 fn_incoming_doc_receive_paper — Thêm p_received_paper_date
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_receive_paper(
  p_id                  BIGINT,
  p_staff_id            INT,
  p_received_paper_date TIMESTAMPTZ DEFAULT NULL    -- MỚI
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE edoc.incoming_docs SET
    is_received_paper = TRUE,
    received_paper_date = COALESCE(p_received_paper_date, NOW()),  -- MỚI
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

-- ----------------------------------------------------------------------------
-- 2.4 fn_incoming_doc_get_list — Thêm filter: signer, from_number, to_number
--     Thêm output: sents
-- ----------------------------------------------------------------------------
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
  p_signer        TEXT      DEFAULT NULL,          -- MỚI
  p_from_number   INT       DEFAULT NULL,          -- MỚI
  p_to_number     INT       DEFAULT NULL,          -- MỚI
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
  sents           TEXT,                            -- MỚI
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
    WHERE d.unit_id = p_unit_id
      AND (p_doc_book_id IS NULL OR d.doc_book_id = p_doc_book_id)
      AND (p_doc_type_id IS NULL OR d.doc_type_id = p_doc_type_id)
      AND (p_doc_field_id IS NULL OR d.doc_field_id = p_doc_field_id)
      AND (p_urgent_id IS NULL OR d.urgent_id = p_urgent_id)
      AND (p_approved IS NULL OR d.approved = p_approved)
      AND (p_from_date IS NULL OR d.received_date >= p_from_date)
      AND (p_to_date IS NULL OR d.received_date <= p_to_date)
      AND (p_is_read IS NULL OR (p_is_read = TRUE AND uid.is_read = TRUE) OR (p_is_read = FALSE AND (uid.is_read IS NULL OR uid.is_read = FALSE)))
      AND (v_signer IS NULL OR d.signer ILIKE '%' || v_signer || '%')                  -- MỚI
      AND (p_from_number IS NULL OR d.number >= p_from_number)                          -- MỚI
      AND (p_to_number IS NULL OR d.number <= p_to_number)                              -- MỚI
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
    f.sents,                            -- MỚI
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


-- ############################################################################
-- VĂN BẢN ĐI — SP Updates
-- ############################################################################

-- ----------------------------------------------------------------------------
-- 2.7 fn_outgoing_doc_get_by_id — Thêm JOIN publish_unit_name
-- BUG CŨ: hiển thị "Đơn vị #N" thay vì tên
-- ----------------------------------------------------------------------------
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
  publish_unit_name  VARCHAR,              -- MỚI
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
    du.name, ds.full_name,
    pu.name,                                       -- MỚI: publish_unit_name
    s.full_name,
    TRUE
  FROM edoc.outgoing_docs d
  LEFT JOIN edoc.doc_books db ON db.id = d.doc_book_id
  LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
  LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id
  LEFT JOIN public.departments du ON du.id = d.drafting_unit_id
  LEFT JOIN public.staff ds ON ds.id = d.drafting_user_id
  LEFT JOIN public.departments pu ON pu.id = d.publish_unit_id    -- MỚI
  LEFT JOIN public.staff s ON s.id = d.created_by
  WHERE d.id = p_id;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2.8 fn_outgoing_doc_retract — Per-person retract
-- Nếu p_staff_ids = NULL → thu hồi tất cả (behavior cũ)
-- Nếu p_staff_ids có giá trị → chỉ thu hồi người cụ thể
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_retract(
  p_id        BIGINT,
  p_staff_id  INT,
  p_staff_ids INT[] DEFAULT NULL        -- MỚI: NULL = thu hồi tất cả
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_deleted_count INT;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.outgoing_docs WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đi'::TEXT; RETURN;
  END IF;

  IF p_staff_ids IS NULL THEN
    -- Thu hồi tất cả (trừ người thu hồi)
    DELETE FROM edoc.user_outgoing_docs WHERE outgoing_doc_id = p_id AND staff_id != p_staff_id;
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    -- Reset approved khi thu hồi toàn bộ
    UPDATE edoc.outgoing_docs SET approved = FALSE, updated_by = p_staff_id, updated_at = NOW() WHERE id = p_id;
  ELSE
    -- Thu hồi từng người cụ thể
    DELETE FROM edoc.user_outgoing_docs WHERE outgoing_doc_id = p_id AND staff_id = ANY(p_staff_ids);
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    UPDATE edoc.outgoing_docs SET updated_by = p_staff_id, updated_at = NOW() WHERE id = p_id;
  END IF;

  RETURN QUERY SELECT TRUE, ('Thu hồi thành công — đã xóa ' || v_deleted_count || ' người nhận')::TEXT;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2.9 fn_outgoing_doc_send — Thêm sent_by, expired_date
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_send(
  p_doc_id       BIGINT,
  p_staff_ids    INT[],
  p_sent_by      INT,
  p_expired_date TIMESTAMPTZ DEFAULT NULL        -- MỚI: hạn xử lý per-person
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

  INSERT INTO edoc.user_outgoing_docs (outgoing_doc_id, staff_id, sent_by, expired_date, is_read, created_at)
  SELECT p_doc_id, unnest(p_staff_ids), p_sent_by, p_expired_date, FALSE, NOW()
  ON CONFLICT (outgoing_doc_id, staff_id) DO NOTHING;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN QUERY SELECT TRUE, ('Đã gửi cho ' || v_count || ' người nhận')::TEXT;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2.10 fn_outgoing_doc_check_number — MỚI: Kiểm tra trùng số
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_check_number(
  p_unit_id     INT,
  p_doc_book_id INT,
  p_number      INT,
  p_exclude_id  BIGINT DEFAULT NULL
)
RETURNS TABLE (is_exists BOOLEAN)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT EXISTS (
    SELECT 1 FROM edoc.outgoing_docs
    WHERE unit_id = p_unit_id
      AND doc_book_id = p_doc_book_id
      AND number = p_number
      AND EXTRACT(YEAR FROM received_date) = EXTRACT(YEAR FROM NOW())
      AND (p_exclude_id IS NULL OR id != p_exclude_id)
  );
END;
$$;

-- ----------------------------------------------------------------------------
-- 2.12 Leader notes cho VB đi — Danh sách
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_leader_note_get_by_outgoing_doc(
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
  WHERE ln.outgoing_doc_id = p_doc_id
  ORDER BY ln.created_at DESC;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2.12 Leader notes cho VB đi — Tạo
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_leader_note_create_outgoing(
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
    RETURN QUERY SELECT FALSE, 'Nội dung ý kiến không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.leader_notes (outgoing_doc_id, staff_id, content)
  VALUES (p_doc_id, p_staff_id, TRIM(p_content))
  RETURNING edoc.leader_notes.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Thêm ý kiến thành công'::TEXT, v_id;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2.12 Leader notes cho VB đi — Xóa
-- Dùng chung fn_leader_note_delete đã có (check staff_id)
-- ----------------------------------------------------------------------------

-- ############################################################################
-- VĂN BẢN DỰ THẢO — SP Updates
-- ############################################################################

-- ----------------------------------------------------------------------------
-- 2.13 fn_drafting_doc_get_by_id — Thêm JOIN publish_unit_name + reject_reason
-- BUG CŨ: hiển thị "#ID" thay vì tên đơn vị
-- ----------------------------------------------------------------------------
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
  reject_reason   TEXT,                    -- MỚI
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
  publish_unit_name  VARCHAR,              -- MỚI
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
    d.reject_reason,                                -- MỚI
    d.created_by, d.created_at, d.updated_by, d.updated_at,
    db.name, dt.name, dt.code, df.name,
    du.name, ds.full_name,
    pu.name,                                        -- MỚI: publish_unit_name
    s.full_name,
    TRUE
  FROM edoc.drafting_docs d
  LEFT JOIN edoc.doc_books db ON db.id = d.doc_book_id
  LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
  LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id
  LEFT JOIN public.departments du ON du.id = d.drafting_unit_id
  LEFT JOIN public.staff ds ON ds.id = d.drafting_user_id
  LEFT JOIN public.departments pu ON pu.id = d.publish_unit_id    -- MỚI
  LEFT JOIN public.staff s ON s.id = d.created_by
  WHERE d.id = p_id;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2.14 fn_drafting_doc_reject — Lưu reason vào reject_reason
-- BUG CŨ: p_reason bị bỏ qua hoàn toàn
-- ----------------------------------------------------------------------------
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
    reject_reason = NULLIF(TRIM(p_reason), ''),    -- MỚI: lưu lý do
    updated_by = p_staff_id,
    updated_at = NOW()
  WHERE edoc.drafting_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Đã từ chối văn bản dự thảo'::TEXT;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2.15 fn_drafting_doc_retract — Per-person retract
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_retract(
  p_id        BIGINT,
  p_staff_id  INT,
  p_staff_ids INT[] DEFAULT NULL        -- MỚI: NULL = thu hồi tất cả
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_is_released BOOLEAN;
  v_deleted_count INT;
BEGIN
  SELECT d.is_released INTO v_is_released
  FROM edoc.drafting_docs d WHERE d.id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản dự thảo'::TEXT; RETURN;
  END IF;

  IF v_is_released THEN
    RETURN QUERY SELECT FALSE, 'Không thể thu hồi — văn bản đã phát hành'::TEXT; RETURN;
  END IF;

  IF p_staff_ids IS NULL THEN
    DELETE FROM edoc.user_drafting_docs WHERE drafting_doc_id = p_id;
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    UPDATE edoc.drafting_docs SET approved = FALSE, updated_by = p_staff_id, updated_at = NOW() WHERE id = p_id;
  ELSE
    DELETE FROM edoc.user_drafting_docs WHERE drafting_doc_id = p_id AND staff_id = ANY(p_staff_ids);
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    UPDATE edoc.drafting_docs SET updated_by = p_staff_id, updated_at = NOW() WHERE id = p_id;
  END IF;

  RETURN QUERY SELECT TRUE, ('Thu hồi thành công — đã xóa ' || v_deleted_count || ' người nhận')::TEXT;
END;
$$;

-- ----------------------------------------------------------------------------
-- Leader notes cho VB dự thảo — Danh sách
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_leader_note_get_by_drafting_doc(
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
  WHERE ln.drafting_doc_id = p_doc_id
  ORDER BY ln.created_at DESC;
END;
$$;

-- Leader notes cho VB dự thảo — Tạo
CREATE OR REPLACE FUNCTION edoc.fn_leader_note_create_drafting(
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
    RETURN QUERY SELECT FALSE, 'Nội dung ý kiến không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.leader_notes (drafting_doc_id, staff_id, content)
  VALUES (p_doc_id, p_staff_id, TRIM(p_content))
  RETURNING edoc.leader_notes.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Thêm ý kiến thành công'::TEXT, v_id;
END;
$$;

-- ----------------------------------------------------------------------------
-- fn_drafting_doc_send — Thêm sent_by, expired_date
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_send(
  p_doc_id       BIGINT,
  p_staff_ids    INT[],
  p_sent_by      INT,
  p_expired_date TIMESTAMPTZ DEFAULT NULL        -- MỚI
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

  INSERT INTO edoc.user_drafting_docs (drafting_doc_id, staff_id, sent_by, expired_date, is_read, created_at)
  SELECT p_doc_id, unnest(p_staff_ids), p_sent_by, p_expired_date, FALSE, NOW()
  ON CONFLICT (drafting_doc_id, staff_id) DO NOTHING;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN QUERY SELECT TRUE, ('Đã gửi cho ' || v_count || ' người nhận')::TEXT;
END;
$$;


-- ############################################################################
-- VĂN BẢN LIÊN THÔNG — SP Updates
-- ############################################################################

-- ----------------------------------------------------------------------------
-- 2.16 fn_inter_incoming_get_by_id — Thêm JOINs cho doc_type_name, doc_field_name, created_by_name
--      + các cột mới từ Batch 1
-- BUG CŨ: không JOIN gì, frontend hiển thị "—" hết
-- ----------------------------------------------------------------------------
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
  doc_field_id    INT,                   -- MỚI
  secret_id       SMALLINT,              -- MỚI
  urgent_id       SMALLINT,              -- MỚI
  number_paper    INT,                   -- MỚI
  number_copies   INT,                   -- MỚI
  recipients      TEXT,                  -- MỚI
  status          VARCHAR,
  source_system   VARCHAR,
  external_doc_id VARCHAR,
  organ_id        VARCHAR,               -- MỚI
  from_organ_id   VARCHAR,               -- MỚI
  created_by      INT,
  created_at      TIMESTAMP,
  updated_at      TIMESTAMP,
  -- Joined fields
  doc_type_name   VARCHAR,               -- MỚI
  doc_field_name  VARCHAR,               -- MỚI
  created_by_name VARCHAR                -- MỚI
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    d.id, d.unit_id, d.received_date, d.notation, d.document_code,
    d.abstract, d.publish_unit, d.publish_date, d.signer, d.sign_date,
    d.expired_date, d.doc_type_id,
    d.doc_field_id,                                -- MỚI
    d.secret_id,                                   -- MỚI
    d.urgent_id,                                   -- MỚI
    d.number_paper,                                -- MỚI
    d.number_copies,                               -- MỚI
    d.recipients,                                  -- MỚI
    d.status, d.source_system, d.external_doc_id,
    d.organ_id,                                    -- MỚI
    d.from_organ_id,                               -- MỚI
    d.created_by, d.created_at, d.updated_at,
    dt.name,                                       -- MỚI: doc_type_name
    df.name,                                       -- MỚI: doc_field_name
    s.full_name                                    -- MỚI: created_by_name
  FROM edoc.inter_incoming_docs d
  LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id        -- MỚI
  LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id      -- MỚI
  LEFT JOIN public.staff s ON s.id = d.created_by             -- MỚI
  WHERE d.id = p_id;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2.17 fn_inter_incoming_get_list — Thêm p_doc_type_id + joined fields
-- BUG CŨ: frontend gửi doc_type_id nhưng SP không nhận
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_inter_incoming_get_list(
  p_unit_id      INT,
  p_keyword      TEXT,
  p_status       TEXT,
  p_from_date    DATE,
  p_to_date      DATE,
  p_doc_type_id  INT DEFAULT NULL,              -- MỚI
  p_page         INT DEFAULT 1,
  p_page_size    INT DEFAULT 20
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
  -- Joined
  doc_type_name   VARCHAR,                       -- MỚI
  created_by_name VARCHAR,                       -- MỚI
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
      d.id, d.unit_id, d.received_date, d.notation, d.document_code,
      d.abstract, d.publish_unit, d.publish_date, d.signer, d.sign_date,
      d.expired_date, d.doc_type_id, d.status, d.source_system, d.external_doc_id,
      d.created_by, d.created_at, d.updated_at,
      dt.name AS _doc_type_name,                  -- MỚI
      s.full_name AS _created_by_name             -- MỚI
    FROM edoc.inter_incoming_docs d
    LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id       -- MỚI
    LEFT JOIN public.staff s ON s.id = d.created_by            -- MỚI
    WHERE
      d.unit_id = p_unit_id
      AND (p_status IS NULL OR p_status = '' OR d.status = p_status)
      AND (p_doc_type_id IS NULL OR d.doc_type_id = p_doc_type_id)  -- MỚI
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
    f.id, f.unit_id, f.received_date, f.notation, f.document_code,
    f.abstract, f.publish_unit, f.publish_date, f.signer, f.sign_date,
    f.expired_date, f.doc_type_id, f.status, f.source_system, f.external_doc_id,
    f.created_by, f.created_at, f.updated_at,
    f._doc_type_name,                              -- MỚI
    f._created_by_name,                            -- MỚI
    COUNT(*) OVER()::BIGINT AS total_count
  FROM filtered f
  ORDER BY f.received_date DESC NULLS LAST
  LIMIT COALESCE(p_page_size, 20)
  OFFSET v_offset;
END;
$$;


-- ############################################################################
-- BOOKMARK — SP Updates
-- ############################################################################

-- ----------------------------------------------------------------------------
-- 2.18 fn_staff_note_toggle — Thêm p_is_important
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_staff_note_toggle(
  p_doc_type      VARCHAR,
  p_doc_id        BIGINT,
  p_staff_id      INT,
  p_note          TEXT DEFAULT NULL,
  p_is_important  BOOLEAN DEFAULT FALSE          -- MỚI
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
    INSERT INTO edoc.staff_notes (doc_type, doc_id, staff_id, note, is_important)
    VALUES (p_doc_type, p_doc_id, p_staff_id, NULLIF(TRIM(p_note), ''), COALESCE(p_is_important, FALSE));
    RETURN QUERY SELECT TRUE, 'Đã đánh dấu'::TEXT, TRUE;
  END IF;
END;
$$;

-- ----------------------------------------------------------------------------
-- fn_staff_note_update_important — MỚI: Toggle is_important mà không xóa bookmark
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_staff_note_update_important(
  p_doc_type      VARCHAR,
  p_doc_id        BIGINT,
  p_staff_id      INT,
  p_is_important  BOOLEAN
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE edoc.staff_notes SET
    is_important = p_is_important
  WHERE doc_type = p_doc_type AND doc_id = p_doc_id AND staff_id = p_staff_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy đánh dấu'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT TRUE,
    CASE WHEN p_is_important THEN 'Đã đánh dấu quan trọng'::TEXT
    ELSE 'Đã bỏ đánh dấu quan trọng'::TEXT END;
END;
$$;

-- ----------------------------------------------------------------------------
-- fn_staff_note_get_list — Thêm is_important vào output
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_staff_note_get_list(
  p_staff_id  INT,
  p_doc_type  VARCHAR DEFAULT 'incoming'
)
RETURNS TABLE (
  note_id     BIGINT,
  doc_id      BIGINT,
  note        TEXT,
  is_important BOOLEAN,                          -- MỚI
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
    SELECT sn.id, sn.doc_id, sn.note, sn.is_important, sn.created_at,
           d.number, d.notation, d.abstract, d.received_date, d.publish_unit
    FROM edoc.staff_notes sn
    JOIN edoc.incoming_docs d ON d.id = sn.doc_id
    WHERE sn.staff_id = p_staff_id AND sn.doc_type = 'incoming'
    ORDER BY sn.is_important DESC, sn.created_at DESC;

  ELSIF p_doc_type = 'outgoing' THEN
    RETURN QUERY
    SELECT sn.id, sn.doc_id, sn.note, sn.is_important, sn.created_at,
           d.number, d.notation, d.abstract, d.received_date,
           COALESCE(du.name, '')::VARCHAR
    FROM edoc.staff_notes sn
    JOIN edoc.outgoing_docs d ON d.id = sn.doc_id
    LEFT JOIN public.departments du ON du.id = d.drafting_unit_id
    WHERE sn.staff_id = p_staff_id AND sn.doc_type = 'outgoing'
    ORDER BY sn.is_important DESC, sn.created_at DESC;

  ELSIF p_doc_type = 'drafting' THEN
    RETURN QUERY
    SELECT sn.id, sn.doc_id, sn.note, sn.is_important, sn.created_at,
           d.number, d.notation, d.abstract, d.received_date,
           COALESCE(du.name, '')::VARCHAR
    FROM edoc.staff_notes sn
    JOIN edoc.drafting_docs d ON d.id = sn.doc_id
    LEFT JOIN public.departments du ON du.id = d.drafting_unit_id
    WHERE sn.staff_id = p_staff_id AND sn.doc_type = 'drafting'
    ORDER BY sn.is_important DESC, sn.created_at DESC;
  END IF;
END;
$$;


-- ============================================================================
-- Kết thúc Batch 2
-- ============================================================================

DO $$ BEGIN
  RAISE NOTICE '✅ Migration 022 — Batch 2: SP updates applied';
  RAISE NOTICE '   VB đến: fn_incoming_doc_get_by_id (+is_inter_doc, sents, received_paper_date)';
  RAISE NOTICE '   VB đến: fn_incoming_doc_create/update (+sents)';
  RAISE NOTICE '   VB đến: fn_incoming_doc_receive_paper (+received_paper_date)';
  RAISE NOTICE '   VB đến: fn_incoming_doc_get_list (+signer, from/to number filters, +sents)';
  RAISE NOTICE '   VB đi:  fn_outgoing_doc_get_by_id (+publish_unit_name)';
  RAISE NOTICE '   VB đi:  fn_outgoing_doc_retract (per-person)';
  RAISE NOTICE '   VB đi:  fn_outgoing_doc_send (+sent_by, expired_date)';
  RAISE NOTICE '   VB đi:  fn_outgoing_doc_check_number (MỚI)';
  RAISE NOTICE '   VB đi:  fn_leader_note_get/create_outgoing (MỚI)';
  RAISE NOTICE '   Dự thảo: fn_drafting_doc_get_by_id (+publish_unit_name, reject_reason)';
  RAISE NOTICE '   Dự thảo: fn_drafting_doc_reject (lưu reason)';
  RAISE NOTICE '   Dự thảo: fn_drafting_doc_retract (per-person)';
  RAISE NOTICE '   Dự thảo: fn_leader_note_get/create_drafting (MỚI)';
  RAISE NOTICE '   Dự thảo: fn_drafting_doc_send (+sent_by, expired_date)';
  RAISE NOTICE '   Liên thông: fn_inter_incoming_get_by_id (+JOINs, +new columns)';
  RAISE NOTICE '   Liên thông: fn_inter_incoming_get_list (+doc_type_id, +JOINs)';
  RAISE NOTICE '   Bookmark: fn_staff_note_toggle (+is_important)';
  RAISE NOTICE '   Bookmark: fn_staff_note_update_important (MỚI)';
  RAISE NOTICE '   Bookmark: fn_staff_note_get_list (+is_important)';
END $$;

COMMIT;
