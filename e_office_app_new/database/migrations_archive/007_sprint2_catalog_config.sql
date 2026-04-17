-- ============================================
-- MIGRATION 007: Sprint 2 — Danh muc & Cau hinh
-- Sub-modules: 2.1–2.12
--   DocBook, DocType, DocField, DocColumn,
--   Organization, Signer, WorkGroup, Delegation,
--   Province/District/Commune, WorkCalendar,
--   SMS/Email Template, Configuration
-- ============================================

-- ══════════════════════════════════════════════
-- SCHEMA ALTERATIONS (existing tables)
-- ══════════════════════════════════════════════

-- 2.2 DocType: add parent_id for tree structure
ALTER TABLE edoc.doc_types
  ADD COLUMN IF NOT EXISTS parent_id INT REFERENCES edoc.doc_types(id);

-- ══════════════════════════════════════════════
-- NEW TABLES
-- ══════════════════════════════════════════════

-- 2.4 edoc.doc_columns (Thuoc tinh van ban)
CREATE TABLE IF NOT EXISTS edoc.doc_columns (
  id            SERIAL PRIMARY KEY,
  type_id       SMALLINT NOT NULL,                -- 1=den, 2=di, 3=du thao
  column_name   VARCHAR(100) NOT NULL,
  label         VARCHAR(200) NOT NULL,
  is_mandatory  BOOLEAN DEFAULT FALSE,
  is_show_all   BOOLEAN DEFAULT TRUE,
  sort_order    INT DEFAULT 0,
  description   TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(type_id, column_name)
);

COMMENT ON TABLE edoc.doc_columns IS 'Thuoc tinh van ban theo loai (den/di/du thao)';

-- 2.5 edoc.organizations (Thong tin co quan)
CREATE TABLE IF NOT EXISTS edoc.organizations (
  id                SERIAL PRIMARY KEY,
  unit_id           INT NOT NULL REFERENCES public.departments(id) UNIQUE,
  code              VARCHAR(20),
  name              VARCHAR(200),
  address           TEXT,
  phone             VARCHAR(20),
  fax               VARCHAR(20),
  email             VARCHAR(100),
  email_doc         VARCHAR(100),
  secretary         VARCHAR(200),
  chairman_number   VARCHAR(20),
  level             SMALLINT DEFAULT 1,
  is_exchange       BOOLEAN DEFAULT FALSE,
  lgsp_system_id    VARCHAR(50),
  lgsp_secret_key   VARCHAR(100),
  updated_by        INT,
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE edoc.organizations IS 'Thong tin co quan - 1 ban ghi / don vi';

-- 2.6 edoc.signers (Nguoi ky van ban)
CREATE TABLE IF NOT EXISTS edoc.signers (
  id              SERIAL PRIMARY KEY,
  unit_id         INT NOT NULL REFERENCES public.departments(id),
  department_id   INT REFERENCES public.departments(id),
  staff_id        INT NOT NULL REFERENCES public.staff(id),
  sort_order      INT DEFAULT 0,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(unit_id, staff_id)
);

COMMENT ON TABLE edoc.signers IS 'Danh sach nguoi ky van ban theo don vi';

-- 2.7 edoc.work_groups + edoc.work_group_members
CREATE TABLE IF NOT EXISTS edoc.work_groups (
  id          SERIAL PRIMARY KEY,
  unit_id     INT NOT NULL REFERENCES public.departments(id),
  name        VARCHAR(200) NOT NULL,
  function    TEXT,
  sort_order  INT DEFAULT 0,
  is_deleted  BOOLEAN DEFAULT FALSE,
  created_by  INT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE edoc.work_groups IS 'Nhom xu ly cong viec';

CREATE TABLE IF NOT EXISTS edoc.work_group_members (
  id          SERIAL PRIMARY KEY,
  group_id    INT NOT NULL REFERENCES edoc.work_groups(id) ON DELETE CASCADE,
  staff_id    INT NOT NULL REFERENCES public.staff(id),
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(group_id, staff_id)
);

COMMENT ON TABLE edoc.work_group_members IS 'Thanh vien nhom xu ly';

-- 2.8 edoc.delegations (Uy quyen)
CREATE TABLE IF NOT EXISTS edoc.delegations (
  id              SERIAL PRIMARY KEY,
  from_staff_id   INT NOT NULL REFERENCES public.staff(id),
  to_staff_id     INT NOT NULL REFERENCES public.staff(id),
  start_date      DATE NOT NULL,
  end_date        DATE NOT NULL,
  note            TEXT,
  is_revoked      BOOLEAN DEFAULT FALSE,
  revoked_at      TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE edoc.delegations IS 'Uy quyen xu ly van ban';

CREATE INDEX IF NOT EXISTS idx_delegations_from ON edoc.delegations(from_staff_id) WHERE is_revoked = FALSE;
CREATE INDEX IF NOT EXISTS idx_delegations_to   ON edoc.delegations(to_staff_id)   WHERE is_revoked = FALSE;

-- 2.10 public.work_calendar (Lich lam viec — ngay nghi)
CREATE TABLE IF NOT EXISTS public.work_calendar (
  id          SERIAL PRIMARY KEY,
  date        DATE NOT NULL UNIQUE,
  description VARCHAR(200),
  is_holiday  BOOLEAN DEFAULT TRUE,
  created_by  INT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.work_calendar IS 'Lich ngay nghi / ngay le';

-- 2.11 edoc.sms_templates
CREATE TABLE IF NOT EXISTS edoc.sms_templates (
  id          SERIAL PRIMARY KEY,
  unit_id     INT NOT NULL REFERENCES public.departments(id),
  name        VARCHAR(200) NOT NULL,
  content     TEXT NOT NULL,
  description TEXT,
  is_active   BOOLEAN DEFAULT TRUE,
  created_by  INT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE edoc.sms_templates IS 'Mau tin nhan SMS';

-- 2.11 edoc.email_templates
CREATE TABLE IF NOT EXISTS edoc.email_templates (
  id          SERIAL PRIMARY KEY,
  unit_id     INT NOT NULL REFERENCES public.departments(id),
  name        VARCHAR(200) NOT NULL,
  subject     VARCHAR(500),
  content     TEXT NOT NULL,
  description TEXT,
  is_active   BOOLEAN DEFAULT TRUE,
  created_by  INT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE edoc.email_templates IS 'Mau email thong bao (HTML)';

-- ══════════════════════════════════════════════
-- SEED DATA: doc_columns
-- ══════════════════════════════════════════════

-- type_id = 1 (VB den)
INSERT INTO edoc.doc_columns (type_id, column_name, label, is_mandatory, sort_order) VALUES
  (1, 'received_date',  'Ngay den',          TRUE,   1),
  (1, 'number',         'So den',            TRUE,   2),
  (1, 'notation',       'So ky hieu',        FALSE,  3),
  (1, 'abstract',       'Trich yeu',         TRUE,   4),
  (1, 'publish_unit',   'Co quan ban hanh',  FALSE,  5),
  (1, 'signer',         'Nguoi ky',          FALSE,  6),
  (1, 'doc_type_id',    'Loai van ban',      FALSE,  7),
  (1, 'doc_field_id',   'Linh vuc',          FALSE,  8),
  (1, 'urgent_id',      'Do khan',           FALSE,  9),
  (1, 'secret_id',      'Do mat',            FALSE, 10),
  (1, 'expired_date',   'Han xu ly',         FALSE, 11),
  (1, 'doc_book_id',    'So van ban',        FALSE, 12)
ON CONFLICT DO NOTHING;

-- type_id = 2 (VB di)
INSERT INTO edoc.doc_columns (type_id, column_name, label, is_mandatory, sort_order) VALUES
  (2, 'received_date',  'Ngay phat hanh',    TRUE,   1),
  (2, 'number',         'So phat hanh',      TRUE,   2),
  (2, 'notation',       'So ky hieu',        TRUE,   3),
  (2, 'abstract',       'Trich yeu',         TRUE,   4),
  (2, 'publish_unit',   'Don vi soan thao',  FALSE,  5),
  (2, 'signer',         'Nguoi ky',          FALSE,  6),
  (2, 'doc_type_id',    'Loai van ban',      FALSE,  7),
  (2, 'doc_field_id',   'Linh vuc',          FALSE,  8),
  (2, 'urgent_id',      'Do khan',           FALSE,  9),
  (2, 'secret_id',      'Do mat',            FALSE, 10),
  (2, 'recipients',     'Noi nhan',          FALSE, 11),
  (2, 'doc_book_id',    'So van ban',        FALSE, 12)
ON CONFLICT DO NOTHING;

-- type_id = 3 (Du thao)
INSERT INTO edoc.doc_columns (type_id, column_name, label, is_mandatory, sort_order) VALUES
  (3, 'received_date',  'Ngay tao',          TRUE,   1),
  (3, 'notation',       'So ky hieu',        FALSE,  2),
  (3, 'abstract',       'Trich yeu',         TRUE,   3),
  (3, 'publish_unit',   'Don vi soan thao',  FALSE,  4),
  (3, 'signer',         'Nguoi ky',          FALSE,  5),
  (3, 'doc_type_id',    'Loai van ban',      FALSE,  6),
  (3, 'doc_field_id',   'Linh vuc',          FALSE,  7),
  (3, 'urgent_id',      'Do khan',           FALSE,  8),
  (3, 'secret_id',      'Do mat',            FALSE,  9),
  (3, 'doc_book_id',    'So van ban',        FALSE, 10)
ON CONFLICT DO NOTHING;


-- ══════════════════════════════════════════════════════════════════════
-- STORED PROCEDURES
-- ══════════════════════════════════════════════════════════════════════


-- ══════════════════════════════════════════════
-- 2.1 DOC BOOK (So van ban)
-- ══════════════════════════════════════════════

-- 2.1.1 Danh sach so van ban
CREATE OR REPLACE FUNCTION edoc.fn_doc_book_get_list(
  p_type_id  SMALLINT DEFAULT NULL,
  p_unit_id  INT DEFAULT NULL
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
    AND (p_unit_id IS NULL OR b.unit_id = p_unit_id)
  ORDER BY b.sort_order, b.name;
$$;

-- 2.1.2 Chi tiet
CREATE OR REPLACE FUNCTION edoc.fn_doc_book_get_by_id(p_id INT)
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
  WHERE b.id = p_id AND b.is_deleted = FALSE;
$$;

-- 2.1.3 Tao moi
CREATE OR REPLACE FUNCTION edoc.fn_doc_book_create(
  p_type_id     SMALLINT,
  p_unit_id     INT,
  p_name        VARCHAR,
  p_is_default  BOOLEAN DEFAULT FALSE,
  p_description TEXT DEFAULT NULL,
  p_created_by  INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql
AS $$
DECLARE v_id INT; v_exists BOOLEAN;
BEGIN
  -- Validate
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên sổ văn bản không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF LENGTH(p_name) > 200 THEN
    RETURN QUERY SELECT FALSE, 'Tên sổ văn bản không được vượt quá 200 ký tự'::TEXT, 0;
    RETURN;
  END IF;

  -- Check unique name per type + unit
  SELECT EXISTS(
    SELECT 1 FROM edoc.doc_books
    WHERE type_id = p_type_id AND unit_id = p_unit_id
      AND LOWER(TRIM(name)) = LOWER(TRIM(p_name))
      AND is_deleted = FALSE
  ) INTO v_exists;

  IF v_exists THEN
    RETURN QUERY SELECT FALSE, 'Tên sổ văn bản đã tồn tại trong đơn vị'::TEXT, 0;
    RETURN;
  END IF;

  -- If setting as default, unset others
  IF p_is_default THEN
    UPDATE edoc.doc_books SET is_default = FALSE
    WHERE type_id = p_type_id AND unit_id = p_unit_id AND is_deleted = FALSE;
  END IF;

  INSERT INTO edoc.doc_books (type_id, unit_id, name, is_default, description, created_by)
  VALUES (p_type_id, p_unit_id, TRIM(p_name), COALESCE(p_is_default, FALSE), p_description, p_created_by)
  RETURNING doc_books.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao so van ban thanh cong'::TEXT, v_id;
END;
$$;

-- 2.1.4 Cap nhat
CREATE OR REPLACE FUNCTION edoc.fn_doc_book_update(
  p_id          INT,
  p_name        VARCHAR,
  p_is_default  BOOLEAN DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_sort_order  INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_rec edoc.doc_books%ROWTYPE;
BEGIN
  SELECT * INTO v_rec FROM edoc.doc_books WHERE id = p_id AND is_deleted = FALSE;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy sổ văn bản'::TEXT;
    RETURN;
  END IF;

  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên sổ văn bản không được để trống'::TEXT;
    RETURN;
  END IF;
  IF LENGTH(p_name) > 200 THEN
    RETURN QUERY SELECT FALSE, 'Tên sổ văn bản không được vượt quá 200 ký tự'::TEXT;
    RETURN;
  END IF;

  -- Check unique name (exclude self)
  IF EXISTS(
    SELECT 1 FROM edoc.doc_books
    WHERE type_id = v_rec.type_id AND unit_id = v_rec.unit_id
      AND LOWER(TRIM(name)) = LOWER(TRIM(p_name))
      AND id <> p_id AND is_deleted = FALSE
  ) THEN
    RETURN QUERY SELECT FALSE, 'Tên sổ văn bản đã tồn tại trong đơn vị'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.doc_books SET
    name        = TRIM(p_name),
    is_default  = COALESCE(p_is_default, is_default),
    description = COALESCE(p_description, description),
    sort_order  = COALESCE(p_sort_order, sort_order)
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Cap nhat thanh cong'::TEXT;
END;
$$;

-- 2.1.5 Xoa (soft delete)
CREATE OR REPLACE FUNCTION edoc.fn_doc_book_delete(p_id INT)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.doc_books WHERE id = p_id AND is_deleted = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy sổ văn bản'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.doc_books SET is_deleted = TRUE WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xoa so van ban thanh cong'::TEXT;
END;
$$;

-- 2.1.6 Dat mac dinh
CREATE OR REPLACE FUNCTION edoc.fn_doc_book_set_default(
  p_id      INT,
  p_type_id SMALLINT,
  p_unit_id INT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
  -- Unset all defaults for this type + unit
  UPDATE edoc.doc_books SET is_default = FALSE
  WHERE type_id = p_type_id AND unit_id = p_unit_id AND is_deleted = FALSE;

  -- Set the selected one
  UPDATE edoc.doc_books SET is_default = TRUE
  WHERE id = p_id AND is_deleted = FALSE;

  RETURN FOUND;
END;
$$;


-- ══════════════════════════════════════════════
-- 2.2 DOC TYPE (Loai van ban) — tree
-- ══════════════════════════════════════════════

-- 2.2.1 Cay loai van ban
CREATE OR REPLACE FUNCTION edoc.fn_doc_type_get_tree(p_type_id SMALLINT DEFAULT NULL)
RETURNS TABLE (
  id INT, type_id SMALLINT, parent_id INT, code VARCHAR, name VARCHAR,
  description TEXT, sort_order INT, notation_type SMALLINT,
  is_default BOOLEAN, created_at TIMESTAMPTZ
)
LANGUAGE sql STABLE
AS $$
  SELECT t.id, t.type_id, t.parent_id, t.code::VARCHAR, t.name::VARCHAR,
         t.description, t.sort_order, t.notation_type,
         t.is_default, t.created_at
  FROM edoc.doc_types t
  WHERE t.is_deleted = FALSE
    AND (p_type_id IS NULL OR t.type_id = p_type_id)
  ORDER BY t.sort_order, t.name;
$$;

-- 2.2.2 Chi tiet
CREATE OR REPLACE FUNCTION edoc.fn_doc_type_get_by_id(p_id INT)
RETURNS TABLE (
  id INT, type_id SMALLINT, parent_id INT, code VARCHAR, name VARCHAR,
  description TEXT, sort_order INT, notation_type SMALLINT,
  is_default BOOLEAN, created_at TIMESTAMPTZ
)
LANGUAGE sql STABLE
AS $$
  SELECT t.id, t.type_id, t.parent_id, t.code::VARCHAR, t.name::VARCHAR,
         t.description, t.sort_order, t.notation_type,
         t.is_default, t.created_at
  FROM edoc.doc_types t
  WHERE t.id = p_id AND t.is_deleted = FALSE;
$$;

-- 2.2.3 Tao moi
CREATE OR REPLACE FUNCTION edoc.fn_doc_type_create(
  p_type_id       SMALLINT,
  p_parent_id     INT DEFAULT NULL,
  p_name          VARCHAR DEFAULT NULL,
  p_code          VARCHAR DEFAULT NULL,
  p_notation_type SMALLINT DEFAULT 0,
  p_sort_order    INT DEFAULT 0,
  p_created_by    INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql
AS $$
DECLARE v_id INT;
BEGIN
  -- Validate required
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên loại văn bản không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF p_code IS NULL OR TRIM(p_code) = '' THEN
    RETURN QUERY SELECT FALSE, 'Mã loại văn bản không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF LENGTH(p_code) > 20 THEN
    RETURN QUERY SELECT FALSE, 'Mã loại văn bản không được vượt quá 20 ký tự'::TEXT, 0;
    RETURN;
  END IF;
  IF LENGTH(p_name) > 200 THEN
    RETURN QUERY SELECT FALSE, 'Tên loại văn bản không được vượt quá 200 ký tự'::TEXT, 0;
    RETURN;
  END IF;

  -- Check unique code
  IF EXISTS(
    SELECT 1 FROM edoc.doc_types
    WHERE LOWER(TRIM(code)) = LOWER(TRIM(p_code)) AND is_deleted = FALSE
  ) THEN
    RETURN QUERY SELECT FALSE, 'Mã loại văn bản đã tồn tại'::TEXT, 0;
    RETURN;
  END IF;

  -- Check parent exists
  IF p_parent_id IS NOT NULL THEN
    IF NOT EXISTS(SELECT 1 FROM edoc.doc_types dt WHERE dt.id = p_parent_id AND dt.is_deleted = FALSE) THEN
      RETURN QUERY SELECT FALSE, 'Loại văn bản cha không tồn tại'::TEXT, 0;
      RETURN;
    END IF;
  END IF;

  INSERT INTO edoc.doc_types (type_id, parent_id, code, name, notation_type, sort_order, created_by)
  VALUES (p_type_id, p_parent_id, TRIM(p_code), TRIM(p_name), p_notation_type, p_sort_order, p_created_by)
  RETURNING doc_types.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao loai van ban thanh cong'::TEXT, v_id;
END;
$$;

-- 2.2.4 Cap nhat
CREATE OR REPLACE FUNCTION edoc.fn_doc_type_update(
  p_id            INT,
  p_parent_id     INT DEFAULT NULL,
  p_name          VARCHAR DEFAULT NULL,
  p_code          VARCHAR DEFAULT NULL,
  p_notation_type SMALLINT DEFAULT NULL,
  p_sort_order    INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.doc_types WHERE id = p_id AND is_deleted = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy loại văn bản'::TEXT;
    RETURN;
  END IF;

  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên loại văn bản không được để trống'::TEXT;
    RETURN;
  END IF;
  IF p_code IS NULL OR TRIM(p_code) = '' THEN
    RETURN QUERY SELECT FALSE, 'Mã loại văn bản không được để trống'::TEXT;
    RETURN;
  END IF;
  IF LENGTH(p_code) > 20 THEN
    RETURN QUERY SELECT FALSE, 'Mã loại văn bản không được vượt quá 20 ký tự'::TEXT;
    RETURN;
  END IF;

  -- Check unique code (exclude self)
  IF EXISTS(
    SELECT 1 FROM edoc.doc_types
    WHERE LOWER(TRIM(code)) = LOWER(TRIM(p_code))
      AND id <> p_id AND is_deleted = FALSE
  ) THEN
    RETURN QUERY SELECT FALSE, 'Mã loại văn bản đã tồn tại'::TEXT;
    RETURN;
  END IF;

  -- Prevent self-referencing
  IF p_parent_id = p_id THEN
    RETURN QUERY SELECT FALSE, 'Không thể chọn chính mình làm cha'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.doc_types SET
    parent_id     = p_parent_id,
    name          = TRIM(p_name),
    code          = TRIM(p_code),
    notation_type = COALESCE(p_notation_type, notation_type),
    sort_order    = COALESCE(p_sort_order, sort_order)
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Cap nhat thanh cong'::TEXT;
END;
$$;

-- 2.2.5 Xoa (soft delete, check children)
CREATE OR REPLACE FUNCTION edoc.fn_doc_type_delete(p_id INT)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_child_count INT;
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.doc_types WHERE id = p_id AND is_deleted = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy loại văn bản'::TEXT;
    RETURN;
  END IF;

  SELECT COUNT(*) INTO v_child_count
  FROM edoc.doc_types WHERE parent_id = p_id AND is_deleted = FALSE;

  IF v_child_count > 0 THEN
    RETURN QUERY SELECT FALSE, ('Không thể xóa: còn '|| v_child_count ||' loại văn bản con')::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.doc_types SET is_deleted = TRUE WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xoa loai van ban thanh cong'::TEXT;
END;
$$;


-- ══════════════════════════════════════════════
-- 2.3 DOC FIELD (Linh vuc van ban)
-- ══════════════════════════════════════════════

-- 2.3.1 Danh sach
CREATE OR REPLACE FUNCTION edoc.fn_doc_field_get_list(
  p_unit_id INT DEFAULT NULL,
  p_keyword VARCHAR DEFAULT NULL
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
  WHERE (p_unit_id IS NULL OR f.unit_id = p_unit_id)
    AND (p_keyword IS NULL OR f.name ILIKE '%' || p_keyword || '%'
         OR f.code ILIKE '%' || p_keyword || '%')
  ORDER BY f.sort_order, f.name;
$$;

-- 2.3.2 Chi tiet
CREATE OR REPLACE FUNCTION edoc.fn_doc_field_get_by_id(p_id INT)
RETURNS TABLE (
  id INT, unit_id INT, code VARCHAR, name VARCHAR,
  sort_order INT, is_active BOOLEAN, created_at TIMESTAMPTZ
)
LANGUAGE sql STABLE
AS $$
  SELECT f.id, f.unit_id, f.code::VARCHAR, f.name::VARCHAR,
         f.sort_order, f.is_active, f.created_at
  FROM edoc.doc_fields f WHERE f.id = p_id;
$$;

-- 2.3.3 Tao moi
CREATE OR REPLACE FUNCTION edoc.fn_doc_field_create(
  p_unit_id INT,
  p_code    VARCHAR,
  p_name    VARCHAR
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql
AS $$
DECLARE v_id INT;
BEGIN
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

  -- Check unique code per unit
  IF EXISTS(
    SELECT 1 FROM edoc.doc_fields
    WHERE unit_id = p_unit_id AND LOWER(TRIM(code)) = LOWER(TRIM(p_code))
  ) THEN
    RETURN QUERY SELECT FALSE, 'Mã lĩnh vực đã tồn tại trong đơn vị'::TEXT, 0;
    RETURN;
  END IF;

  INSERT INTO edoc.doc_fields (unit_id, code, name)
  VALUES (p_unit_id, TRIM(p_code), TRIM(p_name))
  RETURNING doc_fields.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao linh vuc thanh cong'::TEXT, v_id;
END;
$$;

-- 2.3.4 Cap nhat
CREATE OR REPLACE FUNCTION edoc.fn_doc_field_update(
  p_id        INT,
  p_code      VARCHAR DEFAULT NULL,
  p_name      VARCHAR DEFAULT NULL,
  p_sort_order INT DEFAULT NULL,
  p_is_active BOOLEAN DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_unit_id INT;
BEGIN
  SELECT unit_id INTO v_unit_id FROM edoc.doc_fields WHERE id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy lĩnh vực'::TEXT;
    RETURN;
  END IF;

  IF p_code IS NULL OR TRIM(p_code) = '' THEN
    RETURN QUERY SELECT FALSE, 'Mã lĩnh vực không được để trống'::TEXT;
    RETURN;
  END IF;
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên lĩnh vực không được để trống'::TEXT;
    RETURN;
  END IF;
  IF LENGTH(p_code) > 20 THEN
    RETURN QUERY SELECT FALSE, 'Mã lĩnh vực không được vượt quá 20 ký tự'::TEXT;
    RETURN;
  END IF;

  -- Check unique code (exclude self)
  IF EXISTS(
    SELECT 1 FROM edoc.doc_fields
    WHERE unit_id = v_unit_id AND LOWER(TRIM(code)) = LOWER(TRIM(p_code))
      AND id <> p_id
  ) THEN
    RETURN QUERY SELECT FALSE, 'Mã lĩnh vực đã tồn tại trong đơn vị'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.doc_fields SET
    code       = TRIM(p_code),
    name       = TRIM(p_name),
    sort_order = COALESCE(p_sort_order, sort_order),
    is_active  = COALESCE(p_is_active, is_active)
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Cap nhat thanh cong'::TEXT;
END;
$$;

-- 2.3.5 Xoa
CREATE OR REPLACE FUNCTION edoc.fn_doc_field_delete(p_id INT)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.doc_fields WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy lĩnh vực'::TEXT;
    RETURN;
  END IF;

  DELETE FROM edoc.doc_fields WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xoa linh vuc thanh cong'::TEXT;
END;
$$;


-- ══════════════════════════════════════════════
-- 2.4 DOC COLUMN (Thuoc tinh van ban)
-- ══════════════════════════════════════════════

-- 2.4.1 Danh sach theo type
CREATE OR REPLACE FUNCTION edoc.fn_doc_column_get_list(p_type_id SMALLINT)
RETURNS TABLE (
  id INT, type_id SMALLINT, column_name VARCHAR, label VARCHAR,
  is_mandatory BOOLEAN, is_show_all BOOLEAN, sort_order INT,
  description TEXT
)
LANGUAGE sql STABLE
AS $$
  SELECT c.id, c.type_id, c.column_name::VARCHAR, c.label::VARCHAR,
         c.is_mandatory, c.is_show_all, c.sort_order, c.description
  FROM edoc.doc_columns c
  WHERE c.type_id = p_type_id
  ORDER BY c.sort_order;
$$;

-- 2.4.2 Cap nhat
CREATE OR REPLACE FUNCTION edoc.fn_doc_column_update(
  p_id           INT,
  p_label        VARCHAR DEFAULT NULL,
  p_is_mandatory BOOLEAN DEFAULT NULL,
  p_is_show_all  BOOLEAN DEFAULT NULL,
  p_sort_order   INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.doc_columns WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy thuộc tính'::TEXT;
    RETURN;
  END IF;

  IF p_label IS NOT NULL AND LENGTH(p_label) > 200 THEN
    RETURN QUERY SELECT FALSE, 'Nhãn hiển thị không được vượt quá 200 ký tự'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.doc_columns SET
    label        = COALESCE(NULLIF(TRIM(p_label), ''), label),
    is_mandatory = COALESCE(p_is_mandatory, is_mandatory),
    is_show_all  = COALESCE(p_is_show_all, is_show_all),
    sort_order   = COALESCE(p_sort_order, sort_order)
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Cap nhat thanh cong'::TEXT;
END;
$$;

-- 2.4.3 Toggle hien thi
CREATE OR REPLACE FUNCTION edoc.fn_doc_column_toggle_visibility(p_id INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE edoc.doc_columns SET is_show_all = NOT is_show_all WHERE id = p_id;
  RETURN FOUND;
END;
$$;


-- ══════════════════════════════════════════════
-- 2.5 ORGANIZATION (Thong tin co quan)
-- ══════════════════════════════════════════════

-- 2.5.1 Lay thong tin co quan
CREATE OR REPLACE FUNCTION edoc.fn_organization_get(p_unit_id INT)
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
  WHERE o.unit_id = p_unit_id;
$$;

-- 2.5.2 Upsert thong tin co quan
CREATE OR REPLACE FUNCTION edoc.fn_organization_upsert(
  p_unit_id          INT,
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
  p_updated_by       INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  -- Validate FK
  IF NOT EXISTS(SELECT 1 FROM public.departments WHERE id = p_unit_id AND is_deleted = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Đơn vị không tồn tại'::TEXT;
    RETURN;
  END IF;

  -- Validate lengths
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
    p_unit_id, p_code, p_name, p_address, p_phone, p_fax, p_email, p_email_doc,
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


-- ══════════════════════════════════════════════
-- 2.6 SIGNER (Nguoi ky van ban)
-- ══════════════════════════════════════════════

-- 2.6.1 Danh sach
CREATE OR REPLACE FUNCTION edoc.fn_signer_get_list(
  p_unit_id       INT,
  p_department_id INT DEFAULT NULL
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
    AND (p_department_id IS NULL OR sg.department_id = p_department_id)
  ORDER BY sg.sort_order, s.full_name;
$$;

-- 2.6.2 Them nguoi ky
CREATE OR REPLACE FUNCTION edoc.fn_signer_create(
  p_unit_id       INT,
  p_department_id INT DEFAULT NULL,
  p_staff_id      INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql
AS $$
DECLARE v_id INT;
BEGIN
  IF p_staff_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Vui lòng chọn nhân viên'::TEXT, 0;
    RETURN;
  END IF;

  -- Check staff exists
  IF NOT EXISTS(SELECT 1 FROM public.staff s WHERE s.id = p_staff_id AND s.is_deleted = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Nhân viên không tồn tại'::TEXT, 0;
    RETURN;
  END IF;

  -- Check unique
  IF EXISTS(SELECT 1 FROM edoc.signers WHERE unit_id = p_unit_id AND staff_id = p_staff_id) THEN
    RETURN QUERY SELECT FALSE, 'Nhân viên đã có trong danh sách người ký'::TEXT, 0;
    RETURN;
  END IF;

  INSERT INTO edoc.signers (unit_id, department_id, staff_id)
  VALUES (p_unit_id, p_department_id, p_staff_id)
  RETURNING signers.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Them nguoi ky thanh cong'::TEXT, v_id;
END;
$$;

-- 2.6.3 Xoa nguoi ky
CREATE OR REPLACE FUNCTION edoc.fn_signer_delete(p_id INT)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.signers WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy người ký'::TEXT;
    RETURN;
  END IF;

  DELETE FROM edoc.signers WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xoa nguoi ky thanh cong'::TEXT;
END;
$$;


-- ══════════════════════════════════════════════
-- 2.7 WORK GROUP (Nhom xu ly)
-- ══════════════════════════════════════════════

-- 2.7.1 Danh sach nhom
CREATE OR REPLACE FUNCTION edoc.fn_work_group_get_list(p_unit_id INT)
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

-- 2.7.2 Chi tiet
CREATE OR REPLACE FUNCTION edoc.fn_work_group_get_by_id(p_id INT)
RETURNS TABLE (
  id INT, unit_id INT, name VARCHAR, function TEXT,
  sort_order INT, created_by INT, created_at TIMESTAMPTZ
)
LANGUAGE sql STABLE
AS $$
  SELECT g.id, g.unit_id, g.name::VARCHAR, g.function,
         g.sort_order, g.created_by, g.created_at
  FROM edoc.work_groups g
  WHERE g.id = p_id AND g.is_deleted = FALSE;
$$;

-- 2.7.3 Tao nhom
CREATE OR REPLACE FUNCTION edoc.fn_work_group_create(
  p_unit_id    INT,
  p_name       VARCHAR,
  p_function   TEXT DEFAULT NULL,
  p_sort_order INT DEFAULT 0,
  p_created_by INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql
AS $$
DECLARE v_id INT;
BEGIN
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên nhóm không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF LENGTH(p_name) > 200 THEN
    RETURN QUERY SELECT FALSE, 'Tên nhóm không được vượt quá 200 ký tự'::TEXT, 0;
    RETURN;
  END IF;

  -- Check unique name per unit
  IF EXISTS(
    SELECT 1 FROM edoc.work_groups
    WHERE unit_id = p_unit_id AND LOWER(TRIM(name)) = LOWER(TRIM(p_name))
      AND is_deleted = FALSE
  ) THEN
    RETURN QUERY SELECT FALSE, 'Tên nhóm đã tồn tại trong đơn vị'::TEXT, 0;
    RETURN;
  END IF;

  INSERT INTO edoc.work_groups (unit_id, name, function, sort_order, created_by)
  VALUES (p_unit_id, TRIM(p_name), p_function, p_sort_order, p_created_by)
  RETURNING work_groups.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao nhom thanh cong'::TEXT, v_id;
END;
$$;

-- 2.7.4 Cap nhat nhom
CREATE OR REPLACE FUNCTION edoc.fn_work_group_update(
  p_id         INT,
  p_name       VARCHAR DEFAULT NULL,
  p_function   TEXT DEFAULT NULL,
  p_sort_order INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_unit_id INT;
BEGIN
  SELECT unit_id INTO v_unit_id FROM edoc.work_groups WHERE id = p_id AND is_deleted = FALSE;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy nhóm'::TEXT;
    RETURN;
  END IF;

  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên nhóm không được để trống'::TEXT;
    RETURN;
  END IF;
  IF LENGTH(p_name) > 200 THEN
    RETURN QUERY SELECT FALSE, 'Tên nhóm không được vượt quá 200 ký tự'::TEXT;
    RETURN;
  END IF;

  -- Check unique name (exclude self)
  IF EXISTS(
    SELECT 1 FROM edoc.work_groups
    WHERE unit_id = v_unit_id AND LOWER(TRIM(name)) = LOWER(TRIM(p_name))
      AND id <> p_id AND is_deleted = FALSE
  ) THEN
    RETURN QUERY SELECT FALSE, 'Tên nhóm đã tồn tại trong đơn vị'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.work_groups SET
    name       = TRIM(p_name),
    function   = COALESCE(p_function, function),
    sort_order = COALESCE(p_sort_order, sort_order)
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Cap nhat nhom thanh cong'::TEXT;
END;
$$;

-- 2.7.5 Xoa nhom (soft delete)
CREATE OR REPLACE FUNCTION edoc.fn_work_group_delete(p_id INT)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.work_groups WHERE id = p_id AND is_deleted = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy nhóm'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.work_groups SET is_deleted = TRUE WHERE id = p_id;
  -- Also remove members
  DELETE FROM edoc.work_group_members WHERE group_id = p_id;

  RETURN QUERY SELECT TRUE, 'Xoa nhom thanh cong'::TEXT;
END;
$$;

-- 2.7.6 Danh sach thanh vien
CREATE OR REPLACE FUNCTION edoc.fn_work_group_get_members(p_group_id INT)
RETURNS TABLE (
  id INT, group_id INT, staff_id INT,
  staff_name VARCHAR, position_name VARCHAR, department_name VARCHAR,
  created_at TIMESTAMPTZ
)
LANGUAGE sql STABLE
AS $$
  SELECT m.id, m.group_id, m.staff_id,
         s.full_name::VARCHAR AS staff_name,
         p.name::VARCHAR AS position_name,
         d.name::VARCHAR AS department_name,
         m.created_at
  FROM edoc.work_group_members m
    JOIN public.staff s ON s.id = m.staff_id
    LEFT JOIN public.positions p ON p.id = s.position_id
    LEFT JOIN public.departments d ON d.id = s.department_id
  WHERE m.group_id = p_group_id
  ORDER BY s.full_name;
$$;

-- 2.7.7 Gan thanh vien (xoa cu, them moi)
CREATE OR REPLACE FUNCTION edoc.fn_work_group_assign_members(
  p_group_id  INT,
  p_staff_ids INT[]
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.work_groups WHERE id = p_group_id AND is_deleted = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy nhóm'::TEXT;
    RETURN;
  END IF;

  -- Delete old members
  DELETE FROM edoc.work_group_members WHERE group_id = p_group_id;

  -- Insert new members
  IF p_staff_ids IS NOT NULL AND array_length(p_staff_ids, 1) > 0 THEN
    INSERT INTO edoc.work_group_members (group_id, staff_id)
    SELECT p_group_id, unnest(p_staff_ids)
    ON CONFLICT (group_id, staff_id) DO NOTHING;
  END IF;

  RETURN QUERY SELECT TRUE, 'Cap nhat thanh vien thanh cong'::TEXT;
END;
$$;


-- ══════════════════════════════════════════════
-- 2.8 DELEGATION (Uy quyen)
-- ══════════════════════════════════════════════

-- 2.8.1 Danh sach uy quyen
CREATE OR REPLACE FUNCTION edoc.fn_delegation_get_list(
  p_unit_id  INT DEFAULT NULL,
  p_staff_id INT DEFAULT NULL
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
  WHERE (p_unit_id IS NULL OR sf.unit_id = p_unit_id)
    AND (p_staff_id IS NULL OR dl.from_staff_id = p_staff_id OR dl.to_staff_id = p_staff_id)
  ORDER BY dl.created_at DESC;
$$;

-- 2.8.2 Tao uy quyen
CREATE OR REPLACE FUNCTION edoc.fn_delegation_create(
  p_from_staff_id INT,
  p_to_staff_id   INT,
  p_start_date    DATE,
  p_end_date      DATE,
  p_note          TEXT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql
AS $$
DECLARE v_id INT;
BEGIN
  IF p_from_staff_id IS NULL OR p_to_staff_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Vui lòng chọn người ủy quyền và người nhận ủy quyền'::TEXT, 0;
    RETURN;
  END IF;
  IF p_from_staff_id = p_to_staff_id THEN
    RETURN QUERY SELECT FALSE, 'Không thể ủy quyền cho chính mình'::TEXT, 0;
    RETURN;
  END IF;
  IF p_start_date IS NULL OR p_end_date IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Ngày bắt đầu và ngày kết thúc không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF p_end_date < p_start_date THEN
    RETURN QUERY SELECT FALSE, 'Ngày kết thúc phải lớn hơn hoặc bằng ngày bắt đầu'::TEXT, 0;
    RETURN;
  END IF;

  -- Check staff exists
  IF NOT EXISTS(SELECT 1 FROM public.staff s WHERE s.id = p_from_staff_id AND s.is_deleted = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Người ủy quyền không tồn tại'::TEXT, 0;
    RETURN;
  END IF;
  IF NOT EXISTS(SELECT 1 FROM public.staff s WHERE s.id = p_to_staff_id AND s.is_deleted = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Người nhận ủy quyền không tồn tại'::TEXT, 0;
    RETURN;
  END IF;

  -- Check overlap: same from_staff, active, date range overlaps
  IF EXISTS(
    SELECT 1 FROM edoc.delegations d
    WHERE d.from_staff_id = p_from_staff_id
      AND d.is_revoked = FALSE
      AND d.start_date <= p_end_date
      AND d.end_date >= p_start_date
  ) THEN
    RETURN QUERY SELECT FALSE, 'Đã tồn tại ủy quyền trong khoảng thời gian này'::TEXT, 0;
    RETURN;
  END IF;

  INSERT INTO edoc.delegations (from_staff_id, to_staff_id, start_date, end_date, note)
  VALUES (p_from_staff_id, p_to_staff_id, p_start_date, p_end_date, p_note)
  RETURNING edoc.delegations.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao uy quyen thanh cong'::TEXT, v_id;
END;
$$;

-- 2.8.3 Thu hoi uy quyen
CREATE OR REPLACE FUNCTION edoc.fn_delegation_revoke(p_id INT)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.delegations WHERE id = p_id AND is_revoked = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy ủy quyền hoặc đã thu hồi'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.delegations SET is_revoked = TRUE, revoked_at = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Thu hoi uy quyen thanh cong'::TEXT;
END;
$$;


-- ══════════════════════════════════════════════
-- 2.9 PROVINCE / DISTRICT / COMMUNE (Dia ban hanh chinh)
-- ══════════════════════════════════════════════

-- === Province ===

CREATE OR REPLACE FUNCTION public.fn_province_get_list(p_keyword VARCHAR DEFAULT NULL)
RETURNS TABLE (id INT, name VARCHAR, code VARCHAR, is_active BOOLEAN)
LANGUAGE sql STABLE
AS $$
  SELECT p.id, p.name::VARCHAR, p.code::VARCHAR, p.is_active
  FROM public.provinces p
  WHERE (p_keyword IS NULL OR p.name ILIKE '%' || p_keyword || '%'
         OR p.code ILIKE '%' || p_keyword || '%')
  ORDER BY p.name;
$$;

CREATE OR REPLACE FUNCTION public.fn_province_create(
  p_name VARCHAR,
  p_code VARCHAR DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql
AS $$
DECLARE v_id INT;
BEGIN
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên tỉnh/thành không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF p_code IS NOT NULL AND LENGTH(p_code) > 10 THEN
    RETURN QUERY SELECT FALSE, 'Mã tỉnh/thành không được vượt quá 10 ký tự'::TEXT, 0;
    RETURN;
  END IF;

  -- Check unique code
  IF p_code IS NOT NULL AND EXISTS(
    SELECT 1 FROM public.provinces WHERE LOWER(TRIM(code)) = LOWER(TRIM(p_code))
  ) THEN
    RETURN QUERY SELECT FALSE, 'Mã tỉnh/thành đã tồn tại'::TEXT, 0;
    RETURN;
  END IF;

  INSERT INTO public.provinces (name, code)
  VALUES (TRIM(p_name), TRIM(p_code))
  RETURNING provinces.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao tinh/thanh thanh cong'::TEXT, v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_province_update(
  p_id        INT,
  p_name      VARCHAR,
  p_code      VARCHAR DEFAULT NULL,
  p_is_active BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM public.provinces WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy tỉnh/thành'::TEXT;
    RETURN;
  END IF;
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên tỉnh/thành không được để trống'::TEXT;
    RETURN;
  END IF;

  -- Check unique code (exclude self)
  IF p_code IS NOT NULL AND EXISTS(
    SELECT 1 FROM public.provinces
    WHERE LOWER(TRIM(code)) = LOWER(TRIM(p_code)) AND id <> p_id
  ) THEN
    RETURN QUERY SELECT FALSE, 'Mã tỉnh/thành đã tồn tại'::TEXT;
    RETURN;
  END IF;

  UPDATE public.provinces SET name = TRIM(p_name), code = TRIM(p_code), is_active = p_is_active WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Cap nhat thanh cong'::TEXT;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_province_delete(p_id INT)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_district_count INT;
BEGIN
  IF NOT EXISTS(SELECT 1 FROM public.provinces WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy tỉnh/thành'::TEXT;
    RETURN;
  END IF;

  SELECT COUNT(*) INTO v_district_count FROM public.districts WHERE province_id = p_id;
  IF v_district_count > 0 THEN
    RETURN QUERY SELECT FALSE, ('Không thể xóa: còn '|| v_district_count ||' quận/huyện thuộc tỉnh/thành này')::TEXT;
    RETURN;
  END IF;

  DELETE FROM public.provinces WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xoa tinh/thanh thanh cong'::TEXT;
END;
$$;

-- === District ===

CREATE OR REPLACE FUNCTION public.fn_district_get_list(
  p_province_id INT DEFAULT NULL,
  p_keyword     VARCHAR DEFAULT NULL
)
RETURNS TABLE (id INT, province_id INT, name VARCHAR, code VARCHAR, is_active BOOLEAN)
LANGUAGE sql STABLE
AS $$
  SELECT d.id, d.province_id, d.name::VARCHAR, d.code::VARCHAR, d.is_active
  FROM public.districts d
  WHERE (p_province_id IS NULL OR d.province_id = p_province_id)
    AND (p_keyword IS NULL OR d.name ILIKE '%' || p_keyword || '%'
         OR d.code ILIKE '%' || p_keyword || '%')
  ORDER BY d.name;
$$;

CREATE OR REPLACE FUNCTION public.fn_district_create(
  p_province_id INT,
  p_name        VARCHAR,
  p_code        VARCHAR DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql
AS $$
DECLARE v_id INT;
BEGIN
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên quận/huyện không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF NOT EXISTS(SELECT 1 FROM public.provinces pv WHERE pv.id = p_province_id) THEN
    RETURN QUERY SELECT FALSE, 'Tỉnh/thành không tồn tại'::TEXT, 0;
    RETURN;
  END IF;
  IF p_code IS NOT NULL AND LENGTH(p_code) > 10 THEN
    RETURN QUERY SELECT FALSE, 'Mã quận/huyện không được vượt quá 10 ký tự'::TEXT, 0;
    RETURN;
  END IF;

  -- Check unique code within province
  IF p_code IS NOT NULL AND EXISTS(
    SELECT 1 FROM public.districts
    WHERE province_id = p_province_id AND LOWER(TRIM(code)) = LOWER(TRIM(p_code))
  ) THEN
    RETURN QUERY SELECT FALSE, 'Mã quận/huyện đã tồn tại trong tỉnh/thành'::TEXT, 0;
    RETURN;
  END IF;

  INSERT INTO public.districts (province_id, name, code)
  VALUES (p_province_id, TRIM(p_name), TRIM(p_code))
  RETURNING districts.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao quan/huyen thanh cong'::TEXT, v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_district_update(
  p_id        INT,
  p_name      VARCHAR,
  p_code      VARCHAR DEFAULT NULL,
  p_is_active BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_province_id INT;
BEGIN
  SELECT province_id INTO v_province_id FROM public.districts WHERE id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy quận/huyện'::TEXT;
    RETURN;
  END IF;
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên quận/huyện không được để trống'::TEXT;
    RETURN;
  END IF;

  -- Check unique code (exclude self)
  IF p_code IS NOT NULL AND EXISTS(
    SELECT 1 FROM public.districts
    WHERE province_id = v_province_id AND LOWER(TRIM(code)) = LOWER(TRIM(p_code))
      AND id <> p_id
  ) THEN
    RETURN QUERY SELECT FALSE, 'Mã quận/huyện đã tồn tại trong tỉnh/thành'::TEXT;
    RETURN;
  END IF;

  UPDATE public.districts SET name = TRIM(p_name), code = TRIM(p_code), is_active = p_is_active WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Cap nhat thanh cong'::TEXT;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_district_delete(p_id INT)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_commune_count INT;
BEGIN
  IF NOT EXISTS(SELECT 1 FROM public.districts WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy quận/huyện'::TEXT;
    RETURN;
  END IF;

  SELECT COUNT(*) INTO v_commune_count FROM public.communes WHERE district_id = p_id;
  IF v_commune_count > 0 THEN
    RETURN QUERY SELECT FALSE, ('Không thể xóa: còn '|| v_commune_count ||' phường/xã thuộc quận/huyện này')::TEXT;
    RETURN;
  END IF;

  DELETE FROM public.districts WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xoa quan/huyen thanh cong'::TEXT;
END;
$$;

-- === Commune ===

CREATE OR REPLACE FUNCTION public.fn_commune_get_list(
  p_district_id INT DEFAULT NULL,
  p_keyword     VARCHAR DEFAULT NULL
)
RETURNS TABLE (id INT, district_id INT, name VARCHAR, code VARCHAR, is_active BOOLEAN)
LANGUAGE sql STABLE
AS $$
  SELECT c.id, c.district_id, c.name::VARCHAR, c.code::VARCHAR, c.is_active
  FROM public.communes c
  WHERE (p_district_id IS NULL OR c.district_id = p_district_id)
    AND (p_keyword IS NULL OR c.name ILIKE '%' || p_keyword || '%'
         OR c.code ILIKE '%' || p_keyword || '%')
  ORDER BY c.name;
$$;

CREATE OR REPLACE FUNCTION public.fn_commune_create(
  p_district_id INT,
  p_name        VARCHAR,
  p_code        VARCHAR DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql
AS $$
DECLARE v_id INT;
BEGIN
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên phường/xã không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF NOT EXISTS(SELECT 1 FROM public.districts ds WHERE ds.id = p_district_id) THEN
    RETURN QUERY SELECT FALSE, 'Quận/huyện không tồn tại'::TEXT, 0;
    RETURN;
  END IF;
  IF p_code IS NOT NULL AND LENGTH(p_code) > 10 THEN
    RETURN QUERY SELECT FALSE, 'Mã phường/xã không được vượt quá 10 ký tự'::TEXT, 0;
    RETURN;
  END IF;

  -- Check unique code within district
  IF p_code IS NOT NULL AND EXISTS(
    SELECT 1 FROM public.communes
    WHERE district_id = p_district_id AND LOWER(TRIM(code)) = LOWER(TRIM(p_code))
  ) THEN
    RETURN QUERY SELECT FALSE, 'Mã phường/xã đã tồn tại trong quận/huyện'::TEXT, 0;
    RETURN;
  END IF;

  INSERT INTO public.communes (district_id, name, code)
  VALUES (p_district_id, TRIM(p_name), TRIM(p_code))
  RETURNING communes.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao phuong/xa thanh cong'::TEXT, v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_commune_update(
  p_id        INT,
  p_name      VARCHAR,
  p_code      VARCHAR DEFAULT NULL,
  p_is_active BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_district_id INT;
BEGIN
  SELECT district_id INTO v_district_id FROM public.communes WHERE id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy phường/xã'::TEXT;
    RETURN;
  END IF;
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên phường/xã không được để trống'::TEXT;
    RETURN;
  END IF;

  -- Check unique code (exclude self)
  IF p_code IS NOT NULL AND EXISTS(
    SELECT 1 FROM public.communes
    WHERE district_id = v_district_id AND LOWER(TRIM(code)) = LOWER(TRIM(p_code))
      AND id <> p_id
  ) THEN
    RETURN QUERY SELECT FALSE, 'Mã phường/xã đã tồn tại trong quận/huyện'::TEXT;
    RETURN;
  END IF;

  UPDATE public.communes SET name = TRIM(p_name), code = TRIM(p_code), is_active = p_is_active WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Cap nhat thanh cong'::TEXT;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_commune_delete(p_id INT)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM public.communes WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy phường/xã'::TEXT;
    RETURN;
  END IF;

  DELETE FROM public.communes WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xoa phuong/xa thanh cong'::TEXT;
END;
$$;


-- ══════════════════════════════════════════════
-- 2.10 WORK CALENDAR (Lich ngay nghi)
-- ══════════════════════════════════════════════

-- 2.10.1 Lay lich theo nam
CREATE OR REPLACE FUNCTION public.fn_work_calendar_get(p_year INT)
RETURNS TABLE (
  id INT, date DATE, description VARCHAR, is_holiday BOOLEAN,
  created_by INT, created_at TIMESTAMPTZ
)
LANGUAGE sql STABLE
AS $$
  SELECT wc.id, wc.date, wc.description::VARCHAR, wc.is_holiday,
         wc.created_by, wc.created_at
  FROM public.work_calendar wc
  WHERE EXTRACT(YEAR FROM wc.date) = p_year
  ORDER BY wc.date;
$$;

-- 2.10.2 Upsert ngay nghi
CREATE OR REPLACE FUNCTION public.fn_work_calendar_set_holiday(
  p_date        DATE,
  p_description VARCHAR DEFAULT NULL,
  p_created_by  INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF p_date IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Ngày không được để trống'::TEXT;
    RETURN;
  END IF;
  IF p_description IS NOT NULL AND LENGTH(p_description) > 200 THEN
    RETURN QUERY SELECT FALSE, 'Mô tả không được vượt quá 200 ký tự'::TEXT;
    RETURN;
  END IF;

  INSERT INTO public.work_calendar (date, description, is_holiday, created_by)
  VALUES (p_date, p_description, TRUE, p_created_by)
  ON CONFLICT (date) DO UPDATE SET
    description = EXCLUDED.description,
    is_holiday  = TRUE,
    created_by  = EXCLUDED.created_by;

  RETURN QUERY SELECT TRUE, 'Cap nhat lich thanh cong'::TEXT;
END;
$$;

-- 2.10.3 Xoa ngay nghi
CREATE OR REPLACE FUNCTION public.fn_work_calendar_remove_holiday(p_date DATE)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM public.work_calendar WHERE date = p_date) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy ngày nghỉ'::TEXT;
    RETURN;
  END IF;

  DELETE FROM public.work_calendar WHERE date = p_date;
  RETURN QUERY SELECT TRUE, 'Xoa ngay nghi thanh cong'::TEXT;
END;
$$;


-- ══════════════════════════════════════════════
-- 2.11 SMS / EMAIL TEMPLATES
-- ══════════════════════════════════════════════

-- === SMS Template ===

CREATE OR REPLACE FUNCTION edoc.fn_sms_template_get_list(p_unit_id INT)
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
  WHERE t.unit_id = p_unit_id
  ORDER BY t.name;
$$;

CREATE OR REPLACE FUNCTION edoc.fn_sms_template_create(
  p_unit_id     INT,
  p_name        VARCHAR,
  p_content     TEXT,
  p_description TEXT DEFAULT NULL,
  p_created_by  INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql
AS $$
DECLARE v_id INT;
BEGIN
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
  VALUES (p_unit_id, TRIM(p_name), TRIM(p_content), p_description, p_created_by)
  RETURNING sms_templates.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao mau tin nhan thanh cong'::TEXT, v_id;
END;
$$;

CREATE OR REPLACE FUNCTION edoc.fn_sms_template_update(
  p_id          INT,
  p_name        VARCHAR DEFAULT NULL,
  p_content     TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_is_active   BOOLEAN DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.sms_templates WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy mẫu tin nhắn'::TEXT;
    RETURN;
  END IF;
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên mẫu tin nhắn không được để trống'::TEXT;
    RETURN;
  END IF;
  IF p_content IS NULL OR TRIM(p_content) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nội dung mẫu tin nhắn không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.sms_templates SET
    name        = TRIM(p_name),
    content     = TRIM(p_content),
    description = COALESCE(p_description, description),
    is_active   = COALESCE(p_is_active, is_active)
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Cap nhat mau tin nhan thanh cong'::TEXT;
END;
$$;

CREATE OR REPLACE FUNCTION edoc.fn_sms_template_delete(p_id INT)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.sms_templates WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy mẫu tin nhắn'::TEXT;
    RETURN;
  END IF;

  DELETE FROM edoc.sms_templates WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xoa mau tin nhan thanh cong'::TEXT;
END;
$$;

-- === Email Template ===

CREATE OR REPLACE FUNCTION edoc.fn_email_template_get_list(p_unit_id INT)
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
  WHERE t.unit_id = p_unit_id
  ORDER BY t.name;
$$;

CREATE OR REPLACE FUNCTION edoc.fn_email_template_create(
  p_unit_id     INT,
  p_name        VARCHAR,
  p_subject     VARCHAR DEFAULT NULL,
  p_content     TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_created_by  INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql
AS $$
DECLARE v_id INT;
BEGIN
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
  VALUES (p_unit_id, TRIM(p_name), TRIM(p_subject), TRIM(p_content), p_description, p_created_by)
  RETURNING email_templates.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao mau email thanh cong'::TEXT, v_id;
END;
$$;

CREATE OR REPLACE FUNCTION edoc.fn_email_template_update(
  p_id          INT,
  p_name        VARCHAR DEFAULT NULL,
  p_subject     VARCHAR DEFAULT NULL,
  p_content     TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_is_active   BOOLEAN DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.email_templates WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy mẫu email'::TEXT;
    RETURN;
  END IF;
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên mẫu email không được để trống'::TEXT;
    RETURN;
  END IF;
  IF p_content IS NULL OR TRIM(p_content) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nội dung mẫu email không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.email_templates SET
    name        = TRIM(p_name),
    subject     = COALESCE(TRIM(p_subject), subject),
    content     = TRIM(p_content),
    description = COALESCE(p_description, description),
    is_active   = COALESCE(p_is_active, is_active)
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Cap nhat mau email thanh cong'::TEXT;
END;
$$;

CREATE OR REPLACE FUNCTION edoc.fn_email_template_delete(p_id INT)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.email_templates WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy mẫu email'::TEXT;
    RETURN;
  END IF;

  DELETE FROM edoc.email_templates WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xoa mau email thanh cong'::TEXT;
END;
$$;


-- ══════════════════════════════════════════════
-- 2.12 CONFIGURATION (Cau hinh he thong)
-- ══════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.fn_config_get_list(p_unit_id INT DEFAULT NULL)
RETURNS TABLE (id INT, unit_id INT, key VARCHAR, value TEXT, description TEXT)
LANGUAGE sql STABLE
AS $$
  SELECT c.id, c.unit_id, c.key::VARCHAR, c.value, c.description
  FROM public.configurations c
  WHERE (p_unit_id IS NULL OR c.unit_id = p_unit_id)
  ORDER BY c.key;
$$;

CREATE OR REPLACE FUNCTION public.fn_config_upsert(
  p_unit_id     INT,
  p_key         VARCHAR,
  p_value       TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF p_key IS NULL OR TRIM(p_key) = '' THEN
    RETURN QUERY SELECT FALSE, 'Key cấu hình không được để trống'::TEXT;
    RETURN;
  END IF;
  IF LENGTH(p_key) > 100 THEN
    RETURN QUERY SELECT FALSE, 'Key cấu hình không được vượt quá 100 ký tự'::TEXT;
    RETURN;
  END IF;

  INSERT INTO public.configurations (unit_id, key, value, description)
  VALUES (p_unit_id, TRIM(p_key), p_value, p_description)
  ON CONFLICT (unit_id, key) DO UPDATE SET
    value       = EXCLUDED.value,
    description = COALESCE(EXCLUDED.description, configurations.description);

  RETURN QUERY SELECT TRUE, 'Cap nhat cau hinh thanh cong'::TEXT;
END;
$$;


-- ══════════════════════════════════════════════
-- END OF MIGRATION 007
-- ══════════════════════════════════════════════
