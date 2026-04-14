-- ================================================================
-- MIGRATION 016: Sprint 11 — Kho lưu trữ (Archive/Storage)
-- Schema: esto
-- Tables: esto.warehouses, esto.fonds, esto.records,
--         esto.borrow_requests, esto.borrow_request_records
-- Functions: ~20 stored functions for warehouse/fond/record/borrow
-- ================================================================

-- ==========================================
-- 1. BẢNG KHO LƯU TRỮ (warehouses)
-- ==========================================
CREATE TABLE IF NOT EXISTS esto.warehouses (
  id                SERIAL PRIMARY KEY,
  unit_id           INT NOT NULL REFERENCES public.departments(id),
  type_id           INT,
  code              VARCHAR(50),
  name              VARCHAR(200) NOT NULL,
  phone_number      VARCHAR(50),
  address           VARCHAR(500),
  status            BOOLEAN DEFAULT true,
  description       TEXT,
  parent_id         INT DEFAULT 0,
  is_unit           BOOLEAN DEFAULT false,
  warehouse_level   INT DEFAULT 0,
  limit_child       INT DEFAULT 0,
  position          VARCHAR(200),
  is_deleted        BOOLEAN DEFAULT false,
  created_user_id   INT NOT NULL,
  created_date      TIMESTAMPTZ DEFAULT NOW(),
  modified_user_id  INT,
  modified_date     TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_warehouses_unit_id ON esto.warehouses(unit_id);
CREATE INDEX IF NOT EXISTS idx_warehouses_parent_id ON esto.warehouses(parent_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_warehouses_code ON esto.warehouses(unit_id, code) WHERE code IS NOT NULL AND is_deleted = false;

COMMENT ON TABLE esto.warehouses IS 'Kho lưu trữ — cấu trúc cây (parent_id), ánh xạ từ Warehouse.cs';

-- ==========================================
-- 2. BẢNG PHÔNG LƯU TRỮ (fonds)
-- ==========================================
CREATE TABLE IF NOT EXISTS esto.fonds (
  id                SERIAL PRIMARY KEY,
  unit_id           INT NOT NULL,
  parent_id         INT DEFAULT 0,
  fond_code         VARCHAR(50),
  fond_name         VARCHAR(200) NOT NULL,
  fond_history      TEXT,
  archives_time     VARCHAR(100),
  paper_total       DECIMAL,
  paper_digital     DECIMAL,
  keys_group        VARCHAR(200),
  other_type        VARCHAR(200),
  language          VARCHAR(100),
  lookup_tools      VARCHAR(200),
  coppy_number      DECIMAL,
  status            INT DEFAULT 1,
  description       TEXT,
  version           DECIMAL,
  created_user_id   INT NOT NULL,
  created_date      TIMESTAMPTZ DEFAULT NOW(),
  modified_user_id  INT,
  modified_date     TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_fonds_unit_id ON esto.fonds(unit_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_fonds_code ON esto.fonds(unit_id, fond_code) WHERE fond_code IS NOT NULL;

COMMENT ON TABLE esto.fonds IS 'Phông lưu trữ — ánh xạ từ Fond.cs';

-- ==========================================
-- 3. BẢNG HỒ SƠ LƯU TRỮ (records)
-- ==========================================
CREATE TABLE IF NOT EXISTS esto.records (
  id                        BIGSERIAL PRIMARY KEY,
  unit_id                   INT NOT NULL,
  fond_id                   INT NOT NULL REFERENCES esto.fonds(id),
  file_code                 VARCHAR(100),
  file_catalog              INT,
  file_notation             VARCHAR(200),
  title                     VARCHAR(500) NOT NULL,
  maintenance               VARCHAR(200),
  rights                    VARCHAR(200),
  language                  VARCHAR(100),
  start_date                DATE,
  complete_date             DATE,
  total_doc                 INT,
  description               TEXT,
  infor_sign                VARCHAR(200),
  keyword                   VARCHAR(500),
  total_paper               DECIMAL,
  page_number               DECIMAL,
  format                    INT DEFAULT 0,
  archive_date              DATE,
  reception_archive_id      INT,
  in_charge_staff_id        INT NOT NULL,
  parent_id                 INT DEFAULT 0,
  warehouse_id              INT NOT NULL REFERENCES esto.warehouses(id),
  reception_date            DATE,
  reception_from            INT DEFAULT 0,
  transfer_staff            VARCHAR(200),
  is_document_original      BOOLEAN,
  number_of_copy            INT,
  doc_field_id              INT,
  transfer_online_status    BOOLEAN DEFAULT false,
  created_user_id           INT,
  created_date              TIMESTAMPTZ DEFAULT NOW(),
  modified_user_id          INT,
  modified_date             TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_records_unit_id ON esto.records(unit_id);
CREATE INDEX IF NOT EXISTS idx_records_fond_id ON esto.records(fond_id);
CREATE INDEX IF NOT EXISTS idx_records_warehouse_id ON esto.records(warehouse_id);

COMMENT ON TABLE esto.records IS 'Hồ sơ lưu trữ — ánh xạ từ Record.cs';

-- ==========================================
-- 4. BẢNG YÊU CẦU MƯỢN/TRẢ (borrow_requests)
-- ==========================================
CREATE TABLE IF NOT EXISTS esto.borrow_requests (
  id                BIGSERIAL PRIMARY KEY,
  name              VARCHAR(200) NOT NULL,
  unit_id           INT NOT NULL,
  emergency         INT,
  notice            TEXT,
  borrow_date       DATE,
  status            INT DEFAULT 0,
  -- 0=Mới, 1=Đã duyệt, 2=Đã mượn, 3=Đã trả, -1=Từ chối
  created_user_id   INT NOT NULL,
  created_date      TIMESTAMPTZ DEFAULT NOW(),
  modified_user_id  INT,
  modified_date     TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_borrow_requests_unit_id ON esto.borrow_requests(unit_id);
CREATE INDEX IF NOT EXISTS idx_borrow_requests_status ON esto.borrow_requests(status);

COMMENT ON TABLE esto.borrow_requests IS 'Yêu cầu mượn/trả hồ sơ lưu trữ — ánh xạ từ BorrowRequest.cs';

-- ==========================================
-- 5. BẢNG LIÊN KẾT MƯỢN-HỒ SƠ (borrow_request_records)
-- ==========================================
CREATE TABLE IF NOT EXISTS esto.borrow_request_records (
  id                  BIGSERIAL PRIMARY KEY,
  borrow_request_id   BIGINT NOT NULL REFERENCES esto.borrow_requests(id) ON DELETE CASCADE,
  record_id           BIGINT NOT NULL REFERENCES esto.records(id),
  return_date         DATE,
  actual_return_date  DATE,
  UNIQUE(borrow_request_id, record_id)
);

COMMENT ON TABLE esto.borrow_request_records IS 'Chi tiết hồ sơ trong yêu cầu mượn/trả';

-- ==========================================
-- STORED FUNCTIONS — WAREHOUSE (KHO)
-- ==========================================

-- 1. Lấy cây kho
CREATE OR REPLACE FUNCTION esto.fn_warehouse_get_tree(
  p_unit_id INT
)
RETURNS TABLE (
  id                INT,
  unit_id           INT,
  type_id           INT,
  code              VARCHAR,
  name              VARCHAR,
  phone_number      VARCHAR,
  address           VARCHAR,
  status            BOOLEAN,
  description       TEXT,
  parent_id         INT,
  is_unit           BOOLEAN,
  warehouse_level   INT,
  limit_child       INT,
  "position"        VARCHAR,
  created_user_id   INT,
  created_date      TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    w.id,
    w.unit_id,
    w.type_id,
    w.code,
    w.name,
    w.phone_number,
    w.address,
    w.status,
    w.description,
    w.parent_id,
    w.is_unit,
    w.warehouse_level,
    w.limit_child,
    w."position",
    w.created_user_id,
    w.created_date
  FROM esto.warehouses w
  WHERE w.unit_id = p_unit_id
    AND w.is_deleted = false
  ORDER BY w.parent_id, w.name;
END;
$$;

-- 2. Lấy 1 kho theo id
CREATE OR REPLACE FUNCTION esto.fn_warehouse_get_by_id(
  p_id INT
)
RETURNS TABLE (
  id                INT,
  unit_id           INT,
  type_id           INT,
  code              VARCHAR,
  name              VARCHAR,
  phone_number      VARCHAR,
  address           VARCHAR,
  status            BOOLEAN,
  description       TEXT,
  parent_id         INT,
  is_unit           BOOLEAN,
  warehouse_level   INT,
  limit_child       INT,
  "position"        VARCHAR,
  created_user_id   INT,
  created_date      TIMESTAMPTZ,
  modified_user_id  INT,
  modified_date     TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    w.id,
    w.unit_id,
    w.type_id,
    w.code,
    w.name,
    w.phone_number,
    w.address,
    w.status,
    w.description,
    w.parent_id,
    w.is_unit,
    w.warehouse_level,
    w.limit_child,
    w."position",
    w.created_user_id,
    w.created_date,
    w.modified_user_id,
    w.modified_date
  FROM esto.warehouses w
  WHERE w.id = p_id AND w.is_deleted = false;
END;
$$;

-- 3. Tạo kho
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
  p_created_user_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id INT;
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên kho không được để trống'::TEXT, NULL::INT;
    RETURN;
  END IF;

  INSERT INTO esto.warehouses (
    unit_id, type_id, code, name, phone_number, address, status,
    description, parent_id, is_unit, warehouse_level, limit_child,
    "position", created_user_id
  ) VALUES (
    p_unit_id, p_type_id, NULLIF(TRIM(p_code),''), p_name, p_phone_number,
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

-- 4. Cập nhật kho
CREATE OR REPLACE FUNCTION esto.fn_warehouse_update(
  p_id               INT,
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
  p_modified_user_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên kho không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE esto.warehouses SET
    type_id          = p_type_id,
    code             = NULLIF(TRIM(p_code),''),
    name             = p_name,
    phone_number     = p_phone_number,
    address          = p_address,
    status           = COALESCE(p_status, true),
    description      = p_description,
    parent_id        = COALESCE(p_parent_id, 0),
    is_unit          = COALESCE(p_is_unit, false),
    warehouse_level  = COALESCE(p_warehouse_level, 0),
    limit_child      = COALESCE(p_limit_child, 0),
    "position"       = p_position,
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id AND is_deleted = false;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy kho'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cập nhật thành công'::TEXT;
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, 'Mã kho đã tồn tại trong đơn vị'::TEXT;
END;
$$;

-- 5. Xóa kho (soft delete, kiểm tra hồ sơ con)
CREATE OR REPLACE FUNCTION esto.fn_warehouse_delete(
  p_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM esto.records WHERE warehouse_id = p_id;
  IF v_count > 0 THEN
    RETURN QUERY SELECT false, 'Kho đang có hồ sơ, không thể xóa'::TEXT;
    RETURN;
  END IF;

  SELECT COUNT(*) INTO v_count FROM esto.warehouses WHERE parent_id = p_id AND is_deleted = false;
  IF v_count > 0 THEN
    RETURN QUERY SELECT false, 'Kho đang có kho con, không thể xóa'::TEXT;
    RETURN;
  END IF;

  UPDATE esto.warehouses SET is_deleted = true WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy kho'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Xóa kho thành công'::TEXT;
END;
$$;

-- ==========================================
-- STORED FUNCTIONS — FOND (PHÔNG)
-- ==========================================

-- 6. Lấy cây phông
CREATE OR REPLACE FUNCTION esto.fn_fond_get_tree(
  p_unit_id INT
)
RETURNS TABLE (
  id                INT,
  unit_id           INT,
  parent_id         INT,
  fond_code         VARCHAR,
  fond_name         VARCHAR,
  fond_history      TEXT,
  archives_time     VARCHAR,
  paper_total       DECIMAL,
  paper_digital     DECIMAL,
  keys_group        VARCHAR,
  other_type        VARCHAR,
  language          VARCHAR,
  lookup_tools      VARCHAR,
  coppy_number      DECIMAL,
  status            INT,
  description       TEXT,
  version           DECIMAL,
  created_date      TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    f.id,
    f.unit_id,
    f.parent_id,
    f.fond_code,
    f.fond_name,
    f.fond_history,
    f.archives_time,
    f.paper_total,
    f.paper_digital,
    f.keys_group,
    f.other_type,
    f.language,
    f.lookup_tools,
    f.coppy_number,
    f.status,
    f.description,
    f.version,
    f.created_date
  FROM esto.fonds f
  WHERE f.unit_id = p_unit_id
  ORDER BY f.parent_id, f.fond_name;
END;
$$;

-- 7. Lấy 1 phông theo id
CREATE OR REPLACE FUNCTION esto.fn_fond_get_by_id(
  p_id INT
)
RETURNS TABLE (
  id                INT,
  unit_id           INT,
  parent_id         INT,
  fond_code         VARCHAR,
  fond_name         VARCHAR,
  fond_history      TEXT,
  archives_time     VARCHAR,
  paper_total       DECIMAL,
  paper_digital     DECIMAL,
  keys_group        VARCHAR,
  other_type        VARCHAR,
  language          VARCHAR,
  lookup_tools      VARCHAR,
  coppy_number      DECIMAL,
  status            INT,
  description       TEXT,
  version           DECIMAL,
  created_date      TIMESTAMPTZ,
  modified_user_id  INT,
  modified_date     TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    f.id, f.unit_id, f.parent_id, f.fond_code, f.fond_name,
    f.fond_history, f.archives_time, f.paper_total, f.paper_digital,
    f.keys_group, f.other_type, f.language, f.lookup_tools,
    f.coppy_number, f.status, f.description, f.version,
    f.created_date, f.modified_user_id, f.modified_date
  FROM esto.fonds f
  WHERE f.id = p_id;
END;
$$;

-- 8. Tạo phông
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
  p_created_user_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id INT;
BEGIN
  IF TRIM(COALESCE(p_fond_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên phông không được để trống'::TEXT, NULL::INT;
    RETURN;
  END IF;

  INSERT INTO esto.fonds (
    unit_id, parent_id, fond_code, fond_name, fond_history, archives_time,
    paper_total, paper_digital, keys_group, other_type, language,
    lookup_tools, coppy_number, status, description, version, created_user_id
  ) VALUES (
    p_unit_id, COALESCE(p_parent_id, 0), NULLIF(TRIM(p_fond_code),''),
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

-- 9. Cập nhật phông
CREATE OR REPLACE FUNCTION esto.fn_fond_update(
  p_id               INT,
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
  p_modified_user_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TRIM(COALESCE(p_fond_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên phông không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE esto.fonds SET
    parent_id        = COALESCE(p_parent_id, 0),
    fond_code        = NULLIF(TRIM(p_fond_code),''),
    fond_name        = p_fond_name,
    fond_history     = p_fond_history,
    archives_time    = p_archives_time,
    paper_total      = p_paper_total,
    paper_digital    = p_paper_digital,
    keys_group       = p_keys_group,
    other_type       = p_other_type,
    language         = p_language,
    lookup_tools     = p_lookup_tools,
    coppy_number     = p_coppy_number,
    status           = COALESCE(p_status, 1),
    description      = p_description,
    version          = p_version,
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy phông'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cập nhật thành công'::TEXT;
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, 'Mã phông đã tồn tại trong đơn vị'::TEXT;
END;
$$;

-- 10. Xóa phông
CREATE OR REPLACE FUNCTION esto.fn_fond_delete(
  p_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM esto.records WHERE fond_id = p_id;
  IF v_count > 0 THEN
    RETURN QUERY SELECT false, 'Phông đang có hồ sơ, không thể xóa'::TEXT;
    RETURN;
  END IF;

  SELECT COUNT(*) INTO v_count FROM esto.fonds WHERE parent_id = p_id;
  IF v_count > 0 THEN
    RETURN QUERY SELECT false, 'Phông đang có phông con, không thể xóa'::TEXT;
    RETURN;
  END IF;

  DELETE FROM esto.fonds WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy phông'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Xóa phông thành công'::TEXT;
END;
$$;

-- ==========================================
-- STORED FUNCTIONS — RECORD (HỒ SƠ LƯU TRỮ)
-- ==========================================

-- 11. Danh sách hồ sơ (phân trang)
CREATE OR REPLACE FUNCTION esto.fn_record_get_list(
  p_unit_id      INT,
  p_fond_id      INT,
  p_warehouse_id INT,
  p_keyword      TEXT,
  p_page         INT DEFAULT 1,
  p_page_size    INT DEFAULT 20
)
RETURNS TABLE (
  id                      BIGINT,
  unit_id                 INT,
  fond_id                 INT,
  fond_name               VARCHAR,
  file_code               VARCHAR,
  file_catalog            INT,
  file_notation           VARCHAR,
  title                   VARCHAR,
  maintenance             VARCHAR,
  rights                  VARCHAR,
  language                VARCHAR,
  start_date              DATE,
  complete_date           DATE,
  total_doc               INT,
  description             TEXT,
  infor_sign              VARCHAR,
  keyword                 VARCHAR,
  total_paper             DECIMAL,
  page_number             DECIMAL,
  format                  INT,
  archive_date            DATE,
  in_charge_staff_id      INT,
  warehouse_id            INT,
  warehouse_name          VARCHAR,
  transfer_online_status  BOOLEAN,
  created_date            TIMESTAMPTZ,
  total_count             BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT
      r.id,
      r.unit_id,
      r.fond_id,
      f.fond_name,
      r.file_code,
      r.file_catalog,
      r.file_notation,
      r.title,
      r.maintenance,
      r.rights,
      r.language,
      r.start_date,
      r.complete_date,
      r.total_doc,
      r.description,
      r.infor_sign,
      r.keyword,
      r.total_paper,
      r.page_number,
      r.format,
      r.archive_date,
      r.in_charge_staff_id,
      r.warehouse_id,
      w.name AS warehouse_name,
      r.transfer_online_status,
      r.created_date
    FROM esto.records r
    LEFT JOIN esto.fonds f ON f.id = r.fond_id
    LEFT JOIN esto.warehouses w ON w.id = r.warehouse_id
    WHERE r.unit_id = p_unit_id
      AND (p_fond_id IS NULL OR r.fond_id = p_fond_id)
      AND (p_warehouse_id IS NULL OR r.warehouse_id = p_warehouse_id)
      AND (p_keyword IS NULL OR TRIM(p_keyword) = '' OR
           r.title ILIKE '%' || p_keyword || '%' OR
           r.file_code ILIKE '%' || p_keyword || '%')
  )
  SELECT
    flt.*,
    COUNT(*) OVER() AS total_count
  FROM filtered flt
  ORDER BY flt.created_date DESC
  LIMIT p_page_size OFFSET v_offset;
END;
$$;

-- 12. Chi tiết 1 hồ sơ
CREATE OR REPLACE FUNCTION esto.fn_record_get_by_id(
  p_id BIGINT
)
RETURNS TABLE (
  id                      BIGINT,
  unit_id                 INT,
  fond_id                 INT,
  fond_name               VARCHAR,
  file_code               VARCHAR,
  file_catalog            INT,
  file_notation           VARCHAR,
  title                   VARCHAR,
  maintenance             VARCHAR,
  rights                  VARCHAR,
  language                VARCHAR,
  start_date              DATE,
  complete_date           DATE,
  total_doc               INT,
  description             TEXT,
  infor_sign              VARCHAR,
  keyword                 VARCHAR,
  total_paper             DECIMAL,
  page_number             DECIMAL,
  format                  INT,
  archive_date            DATE,
  reception_archive_id    INT,
  in_charge_staff_id      INT,
  parent_id               INT,
  warehouse_id            INT,
  warehouse_name          VARCHAR,
  reception_date          DATE,
  reception_from          INT,
  transfer_staff          VARCHAR,
  is_document_original    BOOLEAN,
  number_of_copy          INT,
  doc_field_id            INT,
  transfer_online_status  BOOLEAN,
  created_user_id         INT,
  created_date            TIMESTAMPTZ,
  modified_user_id        INT,
  modified_date           TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    r.id,
    r.unit_id,
    r.fond_id,
    f.fond_name,
    r.file_code,
    r.file_catalog,
    r.file_notation,
    r.title,
    r.maintenance,
    r.rights,
    r.language,
    r.start_date,
    r.complete_date,
    r.total_doc,
    r.description,
    r.infor_sign,
    r.keyword,
    r.total_paper,
    r.page_number,
    r.format,
    r.archive_date,
    r.reception_archive_id,
    r.in_charge_staff_id,
    r.parent_id,
    r.warehouse_id,
    w.name AS warehouse_name,
    r.reception_date,
    r.reception_from,
    r.transfer_staff,
    r.is_document_original,
    r.number_of_copy,
    r.doc_field_id,
    r.transfer_online_status,
    r.created_user_id,
    r.created_date,
    r.modified_user_id,
    r.modified_date
  FROM esto.records r
  LEFT JOIN esto.fonds f ON f.id = r.fond_id
  LEFT JOIN esto.warehouses w ON w.id = r.warehouse_id
  WHERE r.id = p_id;
END;
$$;

-- 13. Tạo hồ sơ
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
  p_created_user_id         INT
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id BIGINT;
BEGIN
  IF TRIM(COALESCE(p_title, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tiêu đề hồ sơ không được để trống'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  INSERT INTO esto.records (
    unit_id, fond_id, warehouse_id, file_code, file_catalog, file_notation,
    title, maintenance, rights, language, start_date, complete_date, total_doc,
    description, infor_sign, keyword, total_paper, page_number, format,
    archive_date, in_charge_staff_id, reception_date, reception_from,
    transfer_staff, is_document_original, number_of_copy, doc_field_id,
    created_user_id
  ) VALUES (
    p_unit_id, p_fond_id, p_warehouse_id, p_file_code, p_file_catalog, p_file_notation,
    p_title, p_maintenance, p_rights, p_language, p_start_date, p_complete_date, p_total_doc,
    p_description, p_infor_sign, p_keyword, p_total_paper, p_page_number, COALESCE(p_format, 0),
    p_archive_date, p_in_charge_staff_id, p_reception_date, COALESCE(p_reception_from, 0),
    p_transfer_staff, p_is_document_original, p_number_of_copy, p_doc_field_id,
    p_created_user_id
  ) RETURNING esto.records.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo hồ sơ thành công'::TEXT, v_id;
END;
$$;

-- 14. Cập nhật hồ sơ
CREATE OR REPLACE FUNCTION esto.fn_record_update(
  p_id                      BIGINT,
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
  p_modified_user_id        INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TRIM(COALESCE(p_title, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tiêu đề hồ sơ không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE esto.records SET
    fond_id               = p_fond_id,
    warehouse_id          = p_warehouse_id,
    file_code             = p_file_code,
    file_catalog          = p_file_catalog,
    file_notation         = p_file_notation,
    title                 = p_title,
    maintenance           = p_maintenance,
    rights                = p_rights,
    language              = p_language,
    start_date            = p_start_date,
    complete_date         = p_complete_date,
    total_doc             = p_total_doc,
    description           = p_description,
    infor_sign            = p_infor_sign,
    keyword               = p_keyword,
    total_paper           = p_total_paper,
    page_number           = p_page_number,
    format                = COALESCE(p_format, 0),
    archive_date          = p_archive_date,
    in_charge_staff_id    = p_in_charge_staff_id,
    reception_date        = p_reception_date,
    reception_from        = COALESCE(p_reception_from, 0),
    transfer_staff        = p_transfer_staff,
    is_document_original  = p_is_document_original,
    number_of_copy        = p_number_of_copy,
    doc_field_id          = p_doc_field_id,
    modified_user_id      = p_modified_user_id,
    modified_date         = NOW()
  WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy hồ sơ'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cập nhật thành công'::TEXT;
END;
$$;

-- 15. Xóa hồ sơ (kiểm tra yêu cầu mượn)
CREATE OR REPLACE FUNCTION esto.fn_record_delete(
  p_id BIGINT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM esto.borrow_request_records WHERE record_id = p_id;
  IF v_count > 0 THEN
    RETURN QUERY SELECT false, 'Hồ sơ đang có yêu cầu mượn, không thể xóa'::TEXT;
    RETURN;
  END IF;

  DELETE FROM esto.records WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy hồ sơ'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Xóa hồ sơ thành công'::TEXT;
END;
$$;

-- ==========================================
-- STORED FUNCTIONS — BORROW REQUEST (MƯỢN/TRẢ)
-- ==========================================

-- 16. Danh sách yêu cầu mượn (phân trang)
CREATE OR REPLACE FUNCTION esto.fn_borrow_request_get_list(
  p_unit_id   INT,
  p_status    INT,
  p_keyword   TEXT,
  p_page      INT DEFAULT 1,
  p_page_size INT DEFAULT 20
)
RETURNS TABLE (
  id                BIGINT,
  name              VARCHAR,
  unit_id           INT,
  emergency         INT,
  notice            TEXT,
  borrow_date       DATE,
  status            INT,
  created_user_id   INT,
  creator_name      TEXT,
  created_date      TIMESTAMPTZ,
  record_count      BIGINT,
  total_count       BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT
      br.id,
      br.name,
      br.unit_id,
      br.emergency,
      br.notice,
      br.borrow_date,
      br.status,
      br.created_user_id,
      (s.last_name || ' ' || s.first_name)::TEXT AS creator_name,
      br.created_date,
      (SELECT COUNT(*) FROM esto.borrow_request_records brr WHERE brr.borrow_request_id = br.id) AS record_count
    FROM esto.borrow_requests br
    LEFT JOIN public.staff s ON s.id = br.created_user_id
    WHERE br.unit_id = p_unit_id
      AND (p_status IS NULL OR p_status = -99 OR br.status = p_status)
      AND (p_keyword IS NULL OR TRIM(p_keyword) = '' OR br.name ILIKE '%' || p_keyword || '%')
  )
  SELECT
    flt.*,
    COUNT(*) OVER() AS total_count
  FROM filtered flt
  ORDER BY flt.created_date DESC
  LIMIT p_page_size OFFSET v_offset;
END;
$$;

-- 17. Chi tiết yêu cầu mượn kèm danh sách hồ sơ
CREATE OR REPLACE FUNCTION esto.fn_borrow_request_get_by_id(
  p_id BIGINT
)
RETURNS TABLE (
  id                BIGINT,
  name              VARCHAR,
  unit_id           INT,
  emergency         INT,
  notice            TEXT,
  borrow_date       DATE,
  status            INT,
  created_user_id   INT,
  creator_name      TEXT,
  created_date      TIMESTAMPTZ,
  modified_user_id  INT,
  modified_date     TIMESTAMPTZ,
  record_id         BIGINT,
  record_title      VARCHAR,
  return_date       DATE,
  actual_return_date DATE
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    br.id,
    br.name,
    br.unit_id,
    br.emergency,
    br.notice,
    br.borrow_date,
    br.status,
    br.created_user_id,
    (s.last_name || ' ' || s.first_name)::TEXT AS creator_name,
    br.created_date,
    br.modified_user_id,
    br.modified_date,
    r.id AS record_id,
    r.title AS record_title,
    brr.return_date,
    brr.actual_return_date
  FROM esto.borrow_requests br
  LEFT JOIN public.staff s ON s.id = br.created_user_id
  LEFT JOIN esto.borrow_request_records brr ON brr.borrow_request_id = br.id
  LEFT JOIN esto.records r ON r.id = brr.record_id
  WHERE br.id = p_id;
END;
$$;

-- 18. Tạo yêu cầu mượn
CREATE OR REPLACE FUNCTION esto.fn_borrow_request_create(
  p_name             VARCHAR,
  p_unit_id          INT,
  p_emergency        INT,
  p_notice           TEXT,
  p_borrow_date      DATE,
  p_created_user_id  INT,
  p_record_ids       INT[]
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id BIGINT;
  v_record_id INT;
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên yêu cầu không được để trống'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  INSERT INTO esto.borrow_requests (name, unit_id, emergency, notice, borrow_date, created_user_id, status)
  VALUES (p_name, p_unit_id, p_emergency, p_notice, p_borrow_date, p_created_user_id, 0)
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

-- 19. Duyệt yêu cầu mượn (status 0 -> 1) — T-05-01: validate status=0
CREATE OR REPLACE FUNCTION esto.fn_borrow_request_approve(
  p_id               BIGINT,
  p_modified_user_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_status INT;
BEGIN
  SELECT status INTO v_status FROM esto.borrow_requests WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy yêu cầu mượn'::TEXT;
    RETURN;
  END IF;

  IF v_status <> 0 THEN
    RETURN QUERY SELECT false, 'Yêu cầu không ở trạng thái chờ duyệt'::TEXT;
    RETURN;
  END IF;

  UPDATE esto.borrow_requests SET
    status           = 1,
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT true, 'Duyệt yêu cầu thành công'::TEXT;
END;
$$;

-- 20. Từ chối yêu cầu mượn (status 0 -> -1)
CREATE OR REPLACE FUNCTION esto.fn_borrow_request_reject(
  p_id               BIGINT,
  p_modified_user_id INT,
  p_notice           TEXT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_status INT;
BEGIN
  SELECT status INTO v_status FROM esto.borrow_requests WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy yêu cầu mượn'::TEXT;
    RETURN;
  END IF;

  IF v_status <> 0 THEN
    RETURN QUERY SELECT false, 'Yêu cầu không ở trạng thái chờ duyệt'::TEXT;
    RETURN;
  END IF;

  UPDATE esto.borrow_requests SET
    status           = -1,
    notice           = COALESCE(p_notice, notice),
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT true, 'Từ chối yêu cầu thành công'::TEXT;
END;
$$;

-- 21. Mượn hồ sơ (status 1 -> 2)
CREATE OR REPLACE FUNCTION esto.fn_borrow_request_checkout(
  p_id               BIGINT,
  p_modified_user_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_status INT;
BEGIN
  SELECT status INTO v_status FROM esto.borrow_requests WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy yêu cầu mượn'::TEXT;
    RETURN;
  END IF;

  IF v_status <> 1 THEN
    RETURN QUERY SELECT false, 'Yêu cầu chưa được duyệt'::TEXT;
    RETURN;
  END IF;

  UPDATE esto.borrow_requests SET
    status           = 2,
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT true, 'Xác nhận mượn thành công'::TEXT;
END;
$$;

-- 22. Trả hồ sơ (status 2 -> 3)
CREATE OR REPLACE FUNCTION esto.fn_borrow_request_return(
  p_id               BIGINT,
  p_modified_user_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_status INT;
BEGIN
  SELECT status INTO v_status FROM esto.borrow_requests WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy yêu cầu mượn'::TEXT;
    RETURN;
  END IF;

  IF v_status <> 2 THEN
    RETURN QUERY SELECT false, 'Yêu cầu chưa ở trạng thái đang mượn'::TEXT;
    RETURN;
  END IF;

  UPDATE esto.borrow_requests SET
    status           = 3,
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id;

  UPDATE esto.borrow_request_records SET
    actual_return_date = CURRENT_DATE
  WHERE borrow_request_id = p_id;

  RETURN QUERY SELECT true, 'Xác nhận trả thành công'::TEXT;
END;
$$;

-- ==========================================
-- Thông báo hoàn thành
-- ==========================================
DO $$
BEGIN
  RAISE NOTICE '✅ Migration 016: Sprint 11 Archive/Storage';
  RAISE NOTICE '   Tables: esto.warehouses, esto.fonds, esto.records, esto.borrow_requests, esto.borrow_request_records';
  RAISE NOTICE '   Functions: 22 stored functions (warehouse x5, fond x5, record x5, borrow x7)';
END $$;
