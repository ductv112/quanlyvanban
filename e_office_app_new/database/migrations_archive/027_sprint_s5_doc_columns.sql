-- ============================================================================
-- Migration 027: S5 — Dynamic DocColumns
-- Admin cấu hình trường form per loại VB
-- ============================================================================

BEGIN;

-- Bảng doc_columns đã tồn tại từ sprint 2 với cột type_id (smallint)
-- Cần ALTER để thêm các cột mới cho dynamic form
ALTER TABLE edoc.doc_columns ADD COLUMN IF NOT EXISTS data_type VARCHAR(50) DEFAULT 'text';
ALTER TABLE edoc.doc_columns ADD COLUMN IF NOT EXISTS max_length INT;
ALTER TABLE edoc.doc_columns ADD COLUMN IF NOT EXISTS is_system BOOLEAN DEFAULT false;

-- Đổi tên type_id → dùng trực tiếp (giữ nguyên, SP dùng type_id)
-- Không rename vì có UNIQUE constraint đang dùng

CREATE INDEX IF NOT EXISTS idx_doc_columns_type ON edoc.doc_columns(type_id, sort_order);

-- SP: Lấy columns theo type_id
DROP FUNCTION IF EXISTS edoc.fn_doc_column_get_by_type(INT);
DROP FUNCTION IF EXISTS edoc.fn_doc_column_get_all();
DROP FUNCTION IF EXISTS edoc.fn_doc_column_save(INT, INT, VARCHAR, VARCHAR, VARCHAR, INT, INT, BOOLEAN, TEXT);
DROP FUNCTION IF EXISTS edoc.fn_doc_column_delete(INT);

CREATE OR REPLACE FUNCTION edoc.fn_doc_column_get_by_type(p_type_id INT)
RETURNS TABLE (
  id INT, column_name VARCHAR, label VARCHAR, data_type VARCHAR,
  max_length INT, sort_order INT, is_mandatory BOOLEAN, is_system BOOLEAN, description TEXT
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT c.id, c.column_name, c.label, c.data_type, c.max_length,
         c.sort_order, c.is_mandatory, c.is_system, c.description
  FROM edoc.doc_columns c
  WHERE c.type_id = p_type_id
  ORDER BY c.sort_order, c.id;
END;
$$;

-- SP: Lấy tất cả columns (admin)
CREATE OR REPLACE FUNCTION edoc.fn_doc_column_get_all()
RETURNS TABLE (
  id INT, type_id INT, doc_type_name VARCHAR,
  column_name VARCHAR, label VARCHAR, data_type VARCHAR,
  max_length INT, sort_order INT, is_mandatory BOOLEAN, is_system BOOLEAN
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT c.id, c.type_id, dt.name, c.column_name, c.label, c.data_type,
         c.max_length, c.sort_order, c.is_mandatory, c.is_system
  FROM edoc.doc_columns c
  JOIN edoc.doc_types dt ON dt.id = c.type_id
  ORDER BY dt.name, c.sort_order;
END;
$$;

-- SP: Lưu column (upsert)
CREATE OR REPLACE FUNCTION edoc.fn_doc_column_save(
  p_id          INT DEFAULT NULL,
  p_type_id INT DEFAULT NULL,
  p_column_name VARCHAR DEFAULT NULL,
  p_label       VARCHAR DEFAULT NULL,
  p_data_type   VARCHAR DEFAULT 'text',
  p_max_length  INT DEFAULT NULL,
  p_sort_order  INT DEFAULT 0,
  p_is_mandatory BOOLEAN DEFAULT false,
  p_description TEXT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql AS $$
DECLARE v_id INT;
BEGIN
  IF p_label IS NULL OR TRIM(p_label) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nhãn hiển thị là bắt buộc'::TEXT, 0; RETURN;
  END IF;

  IF p_id IS NOT NULL AND p_id > 0 THEN
    -- Update
    UPDATE edoc.doc_columns SET
      column_name = COALESCE(p_column_name, column_name),
      label = TRIM(p_label),
      data_type = COALESCE(p_data_type, data_type),
      max_length = p_max_length,
      sort_order = COALESCE(p_sort_order, sort_order),
      is_mandatory = COALESCE(p_is_mandatory, is_mandatory),
      description = NULLIF(TRIM(p_description), '')
    WHERE edoc.doc_columns.id = p_id AND is_system = false;

    IF NOT FOUND THEN
      RETURN QUERY SELECT FALSE, 'Không tìm thấy hoặc không thể sửa trường hệ thống'::TEXT, 0; RETURN;
    END IF;
    v_id := p_id;
  ELSE
    -- Insert
    INSERT INTO edoc.doc_columns (type_id, column_name, label, data_type, max_length, sort_order, is_mandatory, description)
    VALUES (p_type_id, p_column_name, TRIM(p_label), COALESCE(p_data_type, 'text'), p_max_length, COALESCE(p_sort_order, 0), COALESCE(p_is_mandatory, false), NULLIF(TRIM(p_description), ''))
    RETURNING edoc.doc_columns.id INTO v_id;
  END IF;

  RETURN QUERY SELECT TRUE, 'Lưu thành công'::TEXT, v_id;
END;
$$;

-- SP: Xóa column (chỉ non-system)
CREATE OR REPLACE FUNCTION edoc.fn_doc_column_delete(p_id INT)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM edoc.doc_columns WHERE id = p_id AND is_system = false;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy hoặc không thể xóa trường hệ thống'::TEXT; RETURN;
  END IF;
  RETURN QUERY SELECT TRUE, 'Đã xóa'::TEXT;
END;
$$;

-- Seed: tạo columns mặc định cho loại "Công văn" (type_id = 1)
INSERT INTO edoc.doc_columns (type_id, column_name, label, data_type, sort_order, is_mandatory, is_system) VALUES
  (1, 'abstract', 'Trích yếu nội dung', 'textarea', 1, true, true),
  (1, 'notation', 'Số ký hiệu', 'text', 2, false, true),
  (1, 'publish_unit', 'Cơ quan ban hành', 'text', 3, false, true),
  (1, 'signer', 'Người ký', 'text', 4, false, false),
  (1, 'sign_date', 'Ngày ký', 'date', 5, false, false),
  (1, 'publish_date', 'Ngày ban hành', 'date', 6, false, false),
  (1, 'expired_date', 'Hạn xử lý', 'date', 7, false, false),
  (1, 'recipients', 'Nơi nhận', 'textarea', 8, false, false)
ON CONFLICT (type_id, column_name) DO NOTHING;

DO $$ BEGIN
  RAISE NOTICE '✅ Migration 027: S5 Dynamic DocColumns';
  RAISE NOTICE '   edoc.doc_columns table + 4 SPs + seed data';
END $$;

COMMIT;
