-- ============================================================================
-- Migration 028: S5 Dynamic Form — extra_fields JSONB + fix doc_columns
-- Form VB có 2 phần: cứng (system) + động (custom từ doc_columns)
-- Dữ liệu custom lưu vào extra_fields JSONB
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. Thêm cột extra_fields vào 3 bảng VB chính
-- ============================================================================

ALTER TABLE edoc.incoming_docs ADD COLUMN IF NOT EXISTS extra_fields JSONB DEFAULT '{}';
ALTER TABLE edoc.outgoing_docs ADD COLUMN IF NOT EXISTS extra_fields JSONB DEFAULT '{}';
ALTER TABLE edoc.drafting_docs ADD COLUMN IF NOT EXISTS extra_fields JSONB DEFAULT '{}';

COMMENT ON COLUMN edoc.incoming_docs.extra_fields IS 'Trường bổ sung theo cấu hình doc_columns (dynamic form)';
COMMENT ON COLUMN edoc.outgoing_docs.extra_fields IS 'Trường bổ sung theo cấu hình doc_columns (dynamic form)';
COMMENT ON COLUMN edoc.drafting_docs.extra_fields IS 'Trường bổ sung theo cấu hình doc_columns (dynamic form)';

-- ============================================================================
-- 2. Xóa seed data system columns cũ (nếu có) — chỉ giữ custom columns
-- doc_columns chỉ dùng cho trường BỔ SUNG, không quản lý trường system
-- ============================================================================

DELETE FROM edoc.doc_columns WHERE is_system = true;

-- ============================================================================
-- 3. SP: Lưu extra_fields cho VB (generic — dùng cho cả 3 loại)
-- ============================================================================

CREATE OR REPLACE FUNCTION edoc.fn_doc_save_extra_fields(
  p_doc_type VARCHAR,   -- 'incoming' | 'outgoing' | 'drafting'
  p_doc_id   BIGINT,
  p_extra    JSONB
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql AS $$
BEGIN
  IF p_doc_type = 'incoming' THEN
    UPDATE edoc.incoming_docs SET extra_fields = COALESCE(p_extra, '{}') WHERE id = p_doc_id;
  ELSIF p_doc_type = 'outgoing' THEN
    UPDATE edoc.outgoing_docs SET extra_fields = COALESCE(p_extra, '{}') WHERE id = p_doc_id;
  ELSIF p_doc_type = 'drafting' THEN
    UPDATE edoc.drafting_docs SET extra_fields = COALESCE(p_extra, '{}') WHERE id = p_doc_id;
  ELSE
    RETURN QUERY SELECT FALSE, 'Loại VB không hợp lệ'::TEXT; RETURN;
  END IF;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản'::TEXT; RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, 'Lưu trường bổ sung thành công'::TEXT;
END;
$$;

-- ============================================================================
-- 4. Seed: Tạo vài trường mẫu cho demo
-- ============================================================================

-- Loại "Quyết định" (id=3) — thêm 2 trường: Hiệu lực từ, Hiệu lực đến
INSERT INTO edoc.doc_columns (type_id, column_name, label, data_type, max_length, sort_order, is_mandatory, is_system, description)
VALUES
  (3, 'effective_from', 'Hiệu lực từ ngày', 'date', NULL, 1, false, false, 'Ngày bắt đầu có hiệu lực'),
  (3, 'effective_to', 'Hiệu lực đến ngày', 'date', NULL, 2, false, false, 'Ngày hết hiệu lực')
ON CONFLICT (type_id, column_name) DO NOTHING;

-- Loại "Báo cáo" (id=7 nếu có) — thêm: Kỳ báo cáo
INSERT INTO edoc.doc_columns (type_id, column_name, label, data_type, max_length, sort_order, is_mandatory, is_system, description)
VALUES
  (7, 'report_period', 'Kỳ báo cáo', 'text', 100, 1, true, false, 'VD: Quý I/2026, Tháng 4/2026')
ON CONFLICT (type_id, column_name) DO NOTHING;

-- Loại "Công văn" (id=1) — thêm: Số hiệu cũ (cho chuyển đổi)
INSERT INTO edoc.doc_columns (type_id, column_name, label, data_type, max_length, sort_order, is_mandatory, is_system, description)
VALUES
  (1, 'old_notation', 'Số hiệu cũ', 'text', 100, 1, false, false, 'Số hiệu từ hệ thống cũ (nếu có)')
ON CONFLICT (type_id, column_name) DO NOTHING;

DO $$ BEGIN
  RAISE NOTICE '✅ Migration 028: S5 Dynamic Form';
  RAISE NOTICE '   +extra_fields JSONB (3 bảng VB)';
  RAISE NOTICE '   +fn_doc_save_extra_fields';
  RAISE NOTICE '   +Seed: 4 custom columns mẫu';
END $$;

COMMIT;
