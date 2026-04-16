-- ============================================================================
-- Migration 025: S3 — Chuyển lưu trữ (MoveToArchive)
-- ============================================================================

BEGIN;

-- ============================================================================
-- Bảng lưu trữ VB (liên kết VB đến/đi với hồ sơ lưu trữ)
-- ============================================================================

CREATE TABLE IF NOT EXISTS esto.document_archives (
  id              BIGSERIAL PRIMARY KEY,
  doc_type        VARCHAR(20) NOT NULL,  -- 'incoming' | 'outgoing'
  doc_id          BIGINT NOT NULL,
  fond_id         INT REFERENCES esto.fonds(id),
  warehouse_id    INT REFERENCES esto.warehouses(id),
  record_id       BIGINT REFERENCES esto.records(id),
  file_catalog    VARCHAR(200),          -- Mục lục hồ sơ
  file_notation   VARCHAR(100),          -- Ký hiệu hồ sơ
  doc_ordinal     INT,                   -- Thứ tự VB trong hồ sơ
  language        VARCHAR(50) DEFAULT 'Tiếng Việt',
  autograph       TEXT,                  -- Bút tích
  keyword         TEXT,                  -- Từ khóa
  format          VARCHAR(50) DEFAULT 'Điện tử', -- Điện tử / Giấy
  confidence_level VARCHAR(50),          -- Mức độ tin cậy
  is_original     BOOLEAN DEFAULT true,  -- Bản gốc
  archive_date    TIMESTAMPTZ DEFAULT NOW(),
  archived_by     INT REFERENCES staff(id),
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(doc_type, doc_id)
);

CREATE INDEX IF NOT EXISTS idx_doc_archives_doc ON esto.document_archives(doc_type, doc_id);

-- SP: Chuyển lưu trữ
CREATE OR REPLACE FUNCTION esto.fn_document_archive_create(
  p_doc_type        VARCHAR,
  p_doc_id          BIGINT,
  p_fond_id         INT DEFAULT NULL,
  p_warehouse_id    INT DEFAULT NULL,
  p_record_id       BIGINT DEFAULT NULL,
  p_file_catalog    VARCHAR DEFAULT NULL,
  p_file_notation   VARCHAR DEFAULT NULL,
  p_doc_ordinal     INT DEFAULT NULL,
  p_language        VARCHAR DEFAULT 'Tiếng Việt',
  p_autograph       TEXT DEFAULT NULL,
  p_keyword         TEXT DEFAULT NULL,
  p_format          VARCHAR DEFAULT 'Điện tử',
  p_confidence_level VARCHAR DEFAULT NULL,
  p_is_original     BOOLEAN DEFAULT true,
  p_archived_by     INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql AS $$
DECLARE v_id BIGINT;
BEGIN
  IF p_doc_type NOT IN ('incoming', 'outgoing') THEN
    RETURN QUERY SELECT FALSE, 'Loại văn bản không hợp lệ'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  -- Kiểm tra VB tồn tại
  IF p_doc_type = 'incoming' AND NOT EXISTS (SELECT 1 FROM edoc.incoming_docs WHERE id = p_doc_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đến'::TEXT, 0::BIGINT; RETURN;
  END IF;
  IF p_doc_type = 'outgoing' AND NOT EXISTS (SELECT 1 FROM edoc.outgoing_docs WHERE id = p_doc_id) THEN
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
  RETURNING esto.document_archives.id INTO v_id;

  -- Cập nhật archive_status trên VB gốc
  IF p_doc_type = 'incoming' THEN
    UPDATE edoc.incoming_docs SET archive_status = true WHERE id = p_doc_id;
  ELSIF p_doc_type = 'outgoing' THEN
    UPDATE edoc.outgoing_docs SET archive_status = true WHERE id = p_doc_id;
  END IF;

  RETURN QUERY SELECT TRUE, 'Chuyển lưu trữ thành công'::TEXT, v_id;
END;
$$;

-- SP: Lấy thông tin lưu trữ của VB
CREATE OR REPLACE FUNCTION esto.fn_document_archive_get_by_doc(
  p_doc_type VARCHAR,
  p_doc_id   BIGINT
)
RETURNS TABLE (
  id              BIGINT,
  fond_id         INT,
  fond_name       VARCHAR,
  warehouse_id    INT,
  warehouse_name  VARCHAR,
  record_id       BIGINT,
  record_name     VARCHAR,
  file_catalog    VARCHAR,
  file_notation   VARCHAR,
  doc_ordinal     INT,
  language        VARCHAR,
  autograph       TEXT,
  keyword         TEXT,
  format          VARCHAR,
  confidence_level VARCHAR,
  is_original     BOOLEAN,
  archive_date    TIMESTAMPTZ,
  archived_by_name VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT a.id, a.fond_id, f.name, a.warehouse_id, w.name,
         a.record_id, r.name, a.file_catalog, a.file_notation,
         a.doc_ordinal, a.language, a.autograph, a.keyword,
         a.format, a.confidence_level, a.is_original,
         a.archive_date, s.full_name
  FROM esto.document_archives a
  LEFT JOIN esto.fonds f ON f.id = a.fond_id
  LEFT JOIN esto.warehouses w ON w.id = a.warehouse_id
  LEFT JOIN esto.records r ON r.id = a.record_id
  LEFT JOIN public.staff s ON s.id = a.archived_by
  WHERE a.doc_type = p_doc_type AND a.doc_id = p_doc_id;
END;
$$;

-- SP: Lấy danh sách phông + kho cho dropdown
CREATE OR REPLACE FUNCTION esto.fn_get_fonds_list(p_unit_id INT DEFAULT NULL)
RETURNS TABLE (id INT, name VARCHAR, code VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY SELECT f.id, f.name, f.code FROM esto.fonds f
  WHERE (p_unit_id IS NULL OR f.warehouse_id IN (SELECT w.id FROM esto.warehouses w WHERE w.unit_id = p_unit_id))
  ORDER BY f.name;
END;
$$;

CREATE OR REPLACE FUNCTION esto.fn_get_warehouses_list(p_unit_id INT DEFAULT NULL)
RETURNS TABLE (id INT, name VARCHAR, code VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY SELECT w.id, w.name, w.code FROM esto.warehouses w
  WHERE (p_unit_id IS NULL OR w.unit_id = p_unit_id)
  ORDER BY w.name;
END;
$$;

DO $$ BEGIN
  RAISE NOTICE '✅ Migration 025: S3 Chuyển lưu trữ';
  RAISE NOTICE '   esto.document_archives + 4 SPs';
END $$;

COMMIT;
