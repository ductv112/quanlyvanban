-- ================================================================
-- MIGRATION 017: Sprint 12 — Tài liệu chung (iso) & Hợp đồng (cont)
-- Schema: iso, cont
-- Tables: iso.document_categories, iso.documents,
--         cont.contract_types, cont.contracts, cont.contract_attachments
-- Functions: ~18 stored functions
-- ================================================================

-- ==========================================
-- 1. BẢNG DANH MỤC TÀI LIỆU (document_categories)
-- ==========================================
CREATE TABLE IF NOT EXISTS iso.document_categories (
  id                SERIAL PRIMARY KEY,
  parent_id         INT DEFAULT 0,
  code              VARCHAR(50),
  name              VARCHAR(200) NOT NULL,
  date_process      DECIMAL,
  status            INT DEFAULT 1,
  description       TEXT,
  version           DECIMAL,
  unit_id           INT,
  created_user_id   INT NOT NULL,
  created_date      TIMESTAMPTZ DEFAULT NOW(),
  modified_user_id  INT,
  modified_date     TIMESTAMPTZ
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_doc_categories_code ON iso.document_categories(unit_id, code)
  WHERE code IS NOT NULL;

COMMENT ON TABLE iso.document_categories IS 'Danh mục tài liệu ISO — cây phân cấp, ánh xạ từ EstoCategory.cs';

-- ==========================================
-- 2. BẢNG TÀI LIỆU CHUNG (documents)
-- ==========================================
CREATE TABLE IF NOT EXISTS iso.documents (
  id                BIGSERIAL PRIMARY KEY,
  unit_id           INT NOT NULL,
  category_id       INT REFERENCES iso.document_categories(id),
  title             VARCHAR(500) NOT NULL,
  description       TEXT,
  file_name         VARCHAR(500),
  file_path         VARCHAR(1000),
  file_size         BIGINT,
  mime_type         VARCHAR(200),
  keyword           VARCHAR(500),
  status            INT DEFAULT 1,
  -- 1=Đang hoạt động, 0=Không hoạt động
  created_user_id   INT NOT NULL,
  created_date      TIMESTAMPTZ DEFAULT NOW(),
  modified_user_id  INT,
  modified_date     TIMESTAMPTZ,
  is_deleted        BOOLEAN DEFAULT false
);

CREATE INDEX IF NOT EXISTS idx_documents_unit_id ON iso.documents(unit_id);
CREATE INDEX IF NOT EXISTS idx_documents_category_id ON iso.documents(category_id);

COMMENT ON TABLE iso.documents IS 'Tài liệu chung — tài liệu ISO, nội bộ, pháp quy';

-- ==========================================
-- 3. BẢNG LOẠI HỢP ĐỒNG (contract_types)
-- ==========================================
CREATE TABLE IF NOT EXISTS cont.contract_types (
  id                SERIAL PRIMARY KEY,
  unit_id           INT,
  parent_id         INT DEFAULT 0,
  code              VARCHAR(50),
  name              VARCHAR(200) NOT NULL,
  note              TEXT,
  sort_order        INT DEFAULT 0,
  created_user_id   INT NOT NULL,
  created_date      TIMESTAMPTZ DEFAULT NOW(),
  modified_user_id  INT,
  modified_date     TIMESTAMPTZ
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_contract_types_code ON cont.contract_types(unit_id, code)
  WHERE code IS NOT NULL;

COMMENT ON TABLE cont.contract_types IS 'Loại hợp đồng — ánh xạ từ ContractType.cs';

-- ==========================================
-- 4. BẢNG HỢP ĐỒNG (contracts)
-- ==========================================
CREATE TABLE IF NOT EXISTS cont.contracts (
  id                  SERIAL PRIMARY KEY,
  code_index          INT,
  contract_type_id    INT REFERENCES cont.contract_types(id),
  department_id       INT,
  type_of_contract    INT DEFAULT 0,
  contact_id          INT,
  contact_name        VARCHAR(200),
  unit_id             INT NOT NULL,
  code                VARCHAR(100),
  sign_date           DATE,
  input_date          DATE,
  receive_date        DATE,
  name                VARCHAR(500) NOT NULL,
  signer              VARCHAR(200),
  number              INT,
  ballot              VARCHAR(200),
  marker              VARCHAR(200),
  curator_name        VARCHAR(200),
  currency            VARCHAR(50),
  transporter         VARCHAR(200),
  staff_id            INT,
  note                TEXT,
  status              INT DEFAULT 0,
  -- 0=Mới, 1=Đang thực hiện, 2=Hoàn thành, -1=Hủy
  amount              VARCHAR(200),
  payment_amount      DECIMAL,
  created_user_id     INT NOT NULL,
  created_date        TIMESTAMPTZ DEFAULT NOW(),
  modified_user_id    INT,
  modified_date       TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_contracts_unit_id ON cont.contracts(unit_id);
CREATE INDEX IF NOT EXISTS idx_contracts_contract_type_id ON cont.contracts(contract_type_id);

COMMENT ON TABLE cont.contracts IS 'Hợp đồng — ánh xạ từ Contract.cs';

-- ==========================================
-- 5. BẢNG ĐÍNH KÈM HỢP ĐỒNG (contract_attachments)
-- ==========================================
CREATE TABLE IF NOT EXISTS cont.contract_attachments (
  id                BIGSERIAL PRIMARY KEY,
  contract_id       INT NOT NULL REFERENCES cont.contracts(id) ON DELETE CASCADE,
  file_name         VARCHAR(500) NOT NULL,
  file_path         VARCHAR(1000) NOT NULL,
  file_size         BIGINT,
  mime_type         VARCHAR(200),
  created_user_id   INT NOT NULL,
  created_date      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE cont.contract_attachments IS 'Đính kèm hợp đồng — ánh xạ từ AttachmentOfContract.cs';

-- ==========================================
-- STORED FUNCTIONS — DOCUMENT CATEGORIES
-- ==========================================

-- 1. Lấy cây danh mục tài liệu
CREATE OR REPLACE FUNCTION iso.fn_doc_category_get_tree(
  p_unit_id INT
)
RETURNS TABLE (
  id                INT,
  parent_id         INT,
  code              VARCHAR,
  name              VARCHAR,
  date_process      DECIMAL,
  status            INT,
  description       TEXT,
  version           DECIMAL,
  unit_id           INT,
  created_date      TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    dc.id,
    dc.parent_id,
    dc.code,
    dc.name,
    dc.date_process,
    dc.status,
    dc.description,
    dc.version,
    dc.unit_id,
    dc.created_date
  FROM iso.document_categories dc
  WHERE (dc.unit_id IS NULL OR dc.unit_id = p_unit_id)
    AND dc.status = 1
  ORDER BY dc.parent_id, dc.name;
END;
$$;

-- 2. Tạo danh mục tài liệu
CREATE OR REPLACE FUNCTION iso.fn_doc_category_create(
  p_parent_id        INT,
  p_code             VARCHAR,
  p_name             VARCHAR,
  p_date_process     DECIMAL,
  p_description      TEXT,
  p_version          DECIMAL,
  p_unit_id          INT,
  p_created_user_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id INT;
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên danh mục không được để trống'::TEXT, NULL::INT;
    RETURN;
  END IF;

  INSERT INTO iso.document_categories (
    parent_id, code, name, date_process, description, version, unit_id, created_user_id
  ) VALUES (
    COALESCE(p_parent_id, 0), NULLIF(TRIM(p_code),''), p_name,
    p_date_process, p_description, p_version, p_unit_id, p_created_user_id
  ) RETURNING iso.document_categories.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo danh mục thành công'::TEXT, v_id;
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, 'Mã danh mục đã tồn tại'::TEXT, NULL::INT;
END;
$$;

-- 3. Cập nhật danh mục tài liệu
CREATE OR REPLACE FUNCTION iso.fn_doc_category_update(
  p_id               INT,
  p_parent_id        INT,
  p_code             VARCHAR,
  p_name             VARCHAR,
  p_date_process     DECIMAL,
  p_status           INT,
  p_description      TEXT,
  p_version          DECIMAL,
  p_modified_user_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên danh mục không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE iso.document_categories SET
    parent_id        = COALESCE(p_parent_id, 0),
    code             = NULLIF(TRIM(p_code),''),
    name             = p_name,
    date_process     = p_date_process,
    status           = COALESCE(p_status, 1),
    description      = p_description,
    version          = p_version,
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy danh mục'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cập nhật thành công'::TEXT;
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, 'Mã danh mục đã tồn tại'::TEXT;
END;
$$;

-- 4. Xóa danh mục (kiểm tra danh mục con + tài liệu)
CREATE OR REPLACE FUNCTION iso.fn_doc_category_delete(
  p_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM iso.document_categories WHERE parent_id = p_id;
  IF v_count > 0 THEN
    RETURN QUERY SELECT false, 'Danh mục đang có danh mục con, không thể xóa'::TEXT;
    RETURN;
  END IF;

  SELECT COUNT(*) INTO v_count FROM iso.documents WHERE category_id = p_id AND is_deleted = false;
  IF v_count > 0 THEN
    RETURN QUERY SELECT false, 'Danh mục đang có tài liệu, không thể xóa'::TEXT;
    RETURN;
  END IF;

  UPDATE iso.document_categories SET status = 0 WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy danh mục'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Xóa danh mục thành công'::TEXT;
END;
$$;

-- ==========================================
-- STORED FUNCTIONS — DOCUMENTS
-- ==========================================

-- 5. Danh sách tài liệu (phân trang)
CREATE OR REPLACE FUNCTION iso.fn_document_get_list(
  p_unit_id     INT,
  p_category_id INT,
  p_keyword     TEXT,
  p_page        INT DEFAULT 1,
  p_page_size   INT DEFAULT 20
)
RETURNS TABLE (
  id              BIGINT,
  unit_id         INT,
  category_id     INT,
  category_name   VARCHAR,
  title           VARCHAR,
  description     TEXT,
  file_name       VARCHAR,
  file_path       VARCHAR,
  file_size       BIGINT,
  mime_type       VARCHAR,
  keyword         VARCHAR,
  status          INT,
  created_user_id INT,
  creator_name    TEXT,
  created_date    TIMESTAMPTZ,
  total_count     BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT
      d.id,
      d.unit_id,
      d.category_id,
      dc.name AS category_name,
      d.title,
      d.description,
      d.file_name,
      d.file_path,
      d.file_size,
      d.mime_type,
      d.keyword,
      d.status,
      d.created_user_id,
      (s.last_name || ' ' || s.first_name)::TEXT AS creator_name,
      d.created_date
    FROM iso.documents d
    LEFT JOIN iso.document_categories dc ON dc.id = d.category_id
    LEFT JOIN public.staff s ON s.id = d.created_user_id
    WHERE d.unit_id = p_unit_id
      AND d.is_deleted = false
      AND (p_category_id IS NULL OR d.category_id = p_category_id)
      AND (p_keyword IS NULL OR TRIM(p_keyword) = '' OR
           d.title ILIKE '%' || p_keyword || '%' OR
           d.keyword ILIKE '%' || p_keyword || '%')
  )
  SELECT
    flt.*,
    COUNT(*) OVER() AS total_count
  FROM filtered flt
  ORDER BY flt.created_date DESC
  LIMIT p_page_size OFFSET v_offset;
END;
$$;

-- 6. Chi tiết tài liệu
CREATE OR REPLACE FUNCTION iso.fn_document_get_by_id(
  p_id BIGINT
)
RETURNS TABLE (
  id              BIGINT,
  unit_id         INT,
  category_id     INT,
  category_name   VARCHAR,
  title           VARCHAR,
  description     TEXT,
  file_name       VARCHAR,
  file_path       VARCHAR,
  file_size       BIGINT,
  mime_type       VARCHAR,
  keyword         VARCHAR,
  status          INT,
  created_user_id INT,
  creator_name    TEXT,
  created_date    TIMESTAMPTZ,
  modified_user_id INT,
  modified_date   TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    d.id, d.unit_id, d.category_id, dc.name AS category_name,
    d.title, d.description, d.file_name, d.file_path, d.file_size,
    d.mime_type, d.keyword, d.status, d.created_user_id,
    (s.last_name || ' ' || s.first_name)::TEXT AS creator_name,
    d.created_date, d.modified_user_id, d.modified_date
  FROM iso.documents d
  LEFT JOIN iso.document_categories dc ON dc.id = d.category_id
  LEFT JOIN public.staff s ON s.id = d.created_user_id
  WHERE d.id = p_id AND d.is_deleted = false;
END;
$$;

-- 7. Tạo tài liệu
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
  p_created_user_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id BIGINT;
BEGIN
  IF TRIM(COALESCE(p_title, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tiêu đề tài liệu không được để trống'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  INSERT INTO iso.documents (
    unit_id, category_id, title, description, file_name, file_path,
    file_size, mime_type, keyword, status, created_user_id
  ) VALUES (
    p_unit_id, p_category_id, p_title, p_description, p_file_name, p_file_path,
    p_file_size, p_mime_type, p_keyword, COALESCE(p_status, 1), p_created_user_id
  ) RETURNING iso.documents.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo tài liệu thành công'::TEXT, v_id;
END;
$$;

-- 8. Cập nhật tài liệu
CREATE OR REPLACE FUNCTION iso.fn_document_update(
  p_id               BIGINT,
  p_category_id      INT,
  p_title            VARCHAR,
  p_description      TEXT,
  p_file_name        VARCHAR,
  p_file_path        VARCHAR,
  p_file_size        BIGINT,
  p_mime_type        VARCHAR,
  p_keyword          VARCHAR,
  p_status           INT,
  p_modified_user_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TRIM(COALESCE(p_title, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tiêu đề tài liệu không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE iso.documents SET
    category_id      = p_category_id,
    title            = p_title,
    description      = p_description,
    file_name        = COALESCE(p_file_name, file_name),
    file_path        = COALESCE(p_file_path, file_path),
    file_size        = COALESCE(p_file_size, file_size),
    mime_type        = COALESCE(p_mime_type, mime_type),
    keyword          = p_keyword,
    status           = COALESCE(p_status, status),
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id AND is_deleted = false;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy tài liệu'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cập nhật thành công'::TEXT;
END;
$$;

-- 9. Xóa tài liệu (soft delete)
CREATE OR REPLACE FUNCTION iso.fn_document_delete(
  p_id BIGINT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE iso.documents SET is_deleted = true WHERE id = p_id AND is_deleted = false;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy tài liệu'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Xóa tài liệu thành công'::TEXT;
END;
$$;

-- ==========================================
-- STORED FUNCTIONS — CONTRACT TYPES
-- ==========================================

-- 10. Danh sách loại hợp đồng
CREATE OR REPLACE FUNCTION cont.fn_contract_type_get_list(
  p_unit_id INT
)
RETURNS TABLE (
  id                INT,
  unit_id           INT,
  parent_id         INT,
  code              VARCHAR,
  name              VARCHAR,
  note              TEXT,
  sort_order        INT,
  created_date      TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    ct.id, ct.unit_id, ct.parent_id, ct.code, ct.name, ct.note,
    ct.sort_order, ct.created_date
  FROM cont.contract_types ct
  WHERE (ct.unit_id IS NULL OR ct.unit_id = p_unit_id)
  ORDER BY ct.sort_order, ct.name;
END;
$$;

-- 11. Tạo loại hợp đồng
CREATE OR REPLACE FUNCTION cont.fn_contract_type_create(
  p_unit_id          INT,
  p_parent_id        INT,
  p_code             VARCHAR,
  p_name             VARCHAR,
  p_note             TEXT,
  p_sort_order       INT,
  p_created_user_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id INT;
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên loại hợp đồng không được để trống'::TEXT, NULL::INT;
    RETURN;
  END IF;

  INSERT INTO cont.contract_types (unit_id, parent_id, code, name, note, sort_order, created_user_id)
  VALUES (p_unit_id, COALESCE(p_parent_id, 0), NULLIF(TRIM(p_code),''), p_name, p_note, COALESCE(p_sort_order, 0), p_created_user_id)
  RETURNING cont.contract_types.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo loại hợp đồng thành công'::TEXT, v_id;
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, 'Mã loại hợp đồng đã tồn tại'::TEXT, NULL::INT;
END;
$$;

-- 12. Cập nhật loại hợp đồng
CREATE OR REPLACE FUNCTION cont.fn_contract_type_update(
  p_id               INT,
  p_parent_id        INT,
  p_code             VARCHAR,
  p_name             VARCHAR,
  p_note             TEXT,
  p_sort_order       INT,
  p_modified_user_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên loại hợp đồng không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE cont.contract_types SET
    parent_id        = COALESCE(p_parent_id, 0),
    code             = NULLIF(TRIM(p_code),''),
    name             = p_name,
    note             = p_note,
    sort_order       = COALESCE(p_sort_order, 0),
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy loại hợp đồng'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cập nhật thành công'::TEXT;
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, 'Mã loại hợp đồng đã tồn tại'::TEXT;
END;
$$;

-- 13. Xóa loại hợp đồng
CREATE OR REPLACE FUNCTION cont.fn_contract_type_delete(
  p_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM cont.contracts WHERE contract_type_id = p_id;
  IF v_count > 0 THEN
    RETURN QUERY SELECT false, 'Loại hợp đồng đang được sử dụng, không thể xóa'::TEXT;
    RETURN;
  END IF;

  DELETE FROM cont.contract_types WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy loại hợp đồng'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Xóa loại hợp đồng thành công'::TEXT;
END;
$$;

-- ==========================================
-- STORED FUNCTIONS — CONTRACTS
-- ==========================================

-- 14. Danh sách hợp đồng (phân trang)
CREATE OR REPLACE FUNCTION cont.fn_contract_get_list(
  p_unit_id          INT,
  p_contract_type_id INT,
  p_status           INT,
  p_keyword          TEXT,
  p_page             INT DEFAULT 1,
  p_page_size        INT DEFAULT 20
)
RETURNS TABLE (
  id                INT,
  code_index        INT,
  contract_type_id  INT,
  type_name         VARCHAR,
  unit_id           INT,
  code              VARCHAR,
  name              VARCHAR,
  sign_date         DATE,
  signer            VARCHAR,
  contact_name      VARCHAR,
  staff_id          INT,
  status            INT,
  amount            VARCHAR,
  payment_amount    DECIMAL,
  created_date      TIMESTAMPTZ,
  attachment_count  BIGINT,
  total_count       BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT
      c.id,
      c.code_index,
      c.contract_type_id,
      ct.name AS type_name,
      c.unit_id,
      c.code,
      c.name,
      c.sign_date,
      c.signer,
      c.contact_name,
      c.staff_id,
      c.status,
      c.amount,
      c.payment_amount,
      c.created_date,
      (SELECT COUNT(*) FROM cont.contract_attachments ca WHERE ca.contract_id = c.id) AS attachment_count
    FROM cont.contracts c
    LEFT JOIN cont.contract_types ct ON ct.id = c.contract_type_id
    WHERE c.unit_id = p_unit_id
      AND (p_contract_type_id IS NULL OR c.contract_type_id = p_contract_type_id)
      AND (p_status IS NULL OR p_status = -99 OR c.status = p_status)
      AND (p_keyword IS NULL OR TRIM(p_keyword) = '' OR
           c.name ILIKE '%' || p_keyword || '%' OR
           c.code ILIKE '%' || p_keyword || '%' OR
           c.contact_name ILIKE '%' || p_keyword || '%')
  )
  SELECT
    flt.*,
    COUNT(*) OVER() AS total_count
  FROM filtered flt
  ORDER BY flt.created_date DESC
  LIMIT p_page_size OFFSET v_offset;
END;
$$;

-- 15. Chi tiết hợp đồng
CREATE OR REPLACE FUNCTION cont.fn_contract_get_by_id(
  p_id INT
)
RETURNS TABLE (
  id                INT,
  code_index        INT,
  contract_type_id  INT,
  type_name         VARCHAR,
  department_id     INT,
  type_of_contract  INT,
  contact_id        INT,
  contact_name      VARCHAR,
  unit_id           INT,
  code              VARCHAR,
  sign_date         DATE,
  input_date        DATE,
  receive_date      DATE,
  name              VARCHAR,
  signer            VARCHAR,
  number            INT,
  ballot            VARCHAR,
  marker            VARCHAR,
  curator_name      VARCHAR,
  currency          VARCHAR,
  transporter       VARCHAR,
  staff_id          INT,
  note              TEXT,
  status            INT,
  amount            VARCHAR,
  payment_amount    DECIMAL,
  created_user_id   INT,
  created_date      TIMESTAMPTZ,
  modified_user_id  INT,
  modified_date     TIMESTAMPTZ,
  attachment_count  BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id, c.code_index, c.contract_type_id, ct.name AS type_name,
    c.department_id, c.type_of_contract, c.contact_id, c.contact_name,
    c.unit_id, c.code, c.sign_date, c.input_date, c.receive_date,
    c.name, c.signer, c.number, c.ballot, c.marker, c.curator_name,
    c.currency, c.transporter, c.staff_id, c.note, c.status,
    c.amount, c.payment_amount, c.created_user_id, c.created_date,
    c.modified_user_id, c.modified_date,
    (SELECT COUNT(*) FROM cont.contract_attachments ca WHERE ca.contract_id = c.id) AS attachment_count
  FROM cont.contracts c
  LEFT JOIN cont.contract_types ct ON ct.id = c.contract_type_id
  WHERE c.id = p_id;
END;
$$;

-- 16. Tạo hợp đồng
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
  v_id INT;
BEGIN
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
    p_contact_id, p_contact_name, p_unit_id, p_code, p_sign_date, p_input_date,
    p_receive_date, p_name, p_signer, p_number, p_ballot, p_marker, p_curator_name,
    p_currency, p_transporter, p_staff_id, p_note, COALESCE(p_status, 0),
    p_amount, p_payment_amount, p_created_user_id
  ) RETURNING cont.contracts.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo hợp đồng thành công'::TEXT, v_id;
END;
$$;

-- 17. Cập nhật hợp đồng
CREATE OR REPLACE FUNCTION cont.fn_contract_update(
  p_id                INT,
  p_code_index        INT,
  p_contract_type_id  INT,
  p_department_id     INT,
  p_type_of_contract  INT,
  p_contact_id        INT,
  p_contact_name      VARCHAR,
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
  p_modified_user_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên hợp đồng không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE cont.contracts SET
    code_index        = p_code_index,
    contract_type_id  = p_contract_type_id,
    department_id     = p_department_id,
    type_of_contract  = COALESCE(p_type_of_contract, 0),
    contact_id        = p_contact_id,
    contact_name      = p_contact_name,
    code              = p_code,
    sign_date         = p_sign_date,
    input_date        = p_input_date,
    receive_date      = p_receive_date,
    name              = p_name,
    signer            = p_signer,
    number            = p_number,
    ballot            = p_ballot,
    marker            = p_marker,
    curator_name      = p_curator_name,
    currency          = p_currency,
    transporter       = p_transporter,
    staff_id          = p_staff_id,
    note              = p_note,
    status            = COALESCE(p_status, status),
    amount            = p_amount,
    payment_amount    = p_payment_amount,
    modified_user_id  = p_modified_user_id,
    modified_date     = NOW()
  WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy hợp đồng'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cập nhật thành công'::TEXT;
END;
$$;

-- 18. Xóa hợp đồng (chỉ khi status=0)
CREATE OR REPLACE FUNCTION cont.fn_contract_delete(
  p_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_status INT;
BEGIN
  SELECT status INTO v_status FROM cont.contracts WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy hợp đồng'::TEXT;
    RETURN;
  END IF;

  IF v_status <> 0 THEN
    RETURN QUERY SELECT false, 'Chỉ có thể xóa hợp đồng ở trạng thái Mới'::TEXT;
    RETURN;
  END IF;

  DELETE FROM cont.contracts WHERE id = p_id;

  RETURN QUERY SELECT true, 'Xóa hợp đồng thành công'::TEXT;
END;
$$;

-- 19. Lấy danh sách đính kèm hợp đồng
CREATE OR REPLACE FUNCTION cont.fn_contract_get_attachments(
  p_contract_id INT
)
RETURNS TABLE (
  id              BIGINT,
  contract_id     INT,
  file_name       VARCHAR,
  file_path       VARCHAR,
  file_size       BIGINT,
  mime_type       VARCHAR,
  created_user_id INT,
  created_date    TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    ca.id, ca.contract_id, ca.file_name, ca.file_path,
    ca.file_size, ca.mime_type, ca.created_user_id, ca.created_date
  FROM cont.contract_attachments ca
  WHERE ca.contract_id = p_contract_id
  ORDER BY ca.created_date DESC;
END;
$$;

-- ==========================================
-- Thông báo hoàn thành
-- ==========================================
DO $$
BEGIN
  RAISE NOTICE '✅ Migration 017: Sprint 12 Documents & Contracts';
  RAISE NOTICE '   Tables: iso.document_categories, iso.documents, cont.contract_types, cont.contracts, cont.contract_attachments';
  RAISE NOTICE '   Functions: 19 stored functions (doc_category x4, document x5, contract_type x4, contract x5, attachment x1)';
END $$;
