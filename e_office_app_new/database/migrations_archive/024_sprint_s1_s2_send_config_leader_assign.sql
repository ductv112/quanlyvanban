-- ============================================================================
-- Migration 024: S1 (Gửi nhanh) + S2 (Bút phê kết hợp phân công)
-- ============================================================================

BEGIN;

-- ============================================================================
-- S1: BẢNG CẤU HÌNH GỬI NHANH
-- ============================================================================

CREATE TABLE IF NOT EXISTS edoc.send_doc_user_configs (
  id          SERIAL PRIMARY KEY,
  user_id     INT NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  target_user_id INT NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  config_type VARCHAR(20) NOT NULL DEFAULT 'doc',  -- 'doc' (VB) | 'handling' (HSCV)
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, target_user_id, config_type)
);

CREATE INDEX IF NOT EXISTS idx_send_config_user ON edoc.send_doc_user_configs(user_id, config_type);

COMMENT ON TABLE edoc.send_doc_user_configs IS 'Cấu hình gửi nhanh — preset danh sách người nhận per user';

-- SP: Lấy danh sách config của user
CREATE OR REPLACE FUNCTION edoc.fn_send_config_get_by_user(
  p_user_id     INT,
  p_config_type VARCHAR DEFAULT 'doc'
)
RETURNS TABLE (
  id              INT,
  target_user_id  INT,
  target_name     VARCHAR,
  position_name   VARCHAR,
  department_name VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT c.id, c.target_user_id, s.full_name, p.name, d.name
  FROM edoc.send_doc_user_configs c
  JOIN public.staff s ON s.id = c.target_user_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  LEFT JOIN public.departments d ON d.id = s.department_id
  WHERE c.user_id = p_user_id AND c.config_type = p_config_type
  ORDER BY d.sort_order, s.full_name;
END;
$$;

-- SP: Lưu config (xóa cũ + insert mới — bulk replace)
CREATE OR REPLACE FUNCTION edoc.fn_send_config_save(
  p_user_id         INT,
  p_config_type     VARCHAR,
  p_target_user_ids INT[]
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql AS $$
DECLARE v_count INT;
BEGIN
  -- Xóa cũ
  DELETE FROM edoc.send_doc_user_configs
  WHERE user_id = p_user_id AND config_type = p_config_type;

  -- Insert mới
  IF p_target_user_ids IS NOT NULL AND array_length(p_target_user_ids, 1) > 0 THEN
    INSERT INTO edoc.send_doc_user_configs (user_id, target_user_id, config_type)
    SELECT p_user_id, unnest(p_target_user_ids), p_config_type
    ON CONFLICT (user_id, target_user_id, config_type) DO NOTHING;
  END IF;

  SELECT COUNT(*) INTO v_count
  FROM edoc.send_doc_user_configs
  WHERE user_id = p_user_id AND config_type = p_config_type;

  RETURN QUERY SELECT TRUE, ('Đã lưu ' || v_count || ' người nhận')::TEXT;
END;
$$;

-- ============================================================================
-- S2: MỞ RỘNG LEADER_NOTES — Bút phê kết hợp phân công
-- ============================================================================

ALTER TABLE edoc.leader_notes ADD COLUMN IF NOT EXISTS expired_date TIMESTAMPTZ;
ALTER TABLE edoc.leader_notes ADD COLUMN IF NOT EXISTS assigned_staff_ids INT[];

COMMENT ON COLUMN edoc.leader_notes.expired_date IS 'Hạn giải quyết (khi phân công)';
COMMENT ON COLUMN edoc.leader_notes.assigned_staff_ids IS 'Danh sách cán bộ được phân công';

-- SP: Bút phê + phân công (combo)
-- Logic: tạo note + gửi VB cho staff + update handling nếu có
DROP FUNCTION IF EXISTS edoc.fn_leader_note_comment_and_assign(BIGINT, INT, TEXT, TIMESTAMPTZ, INT[], VARCHAR);

CREATE OR REPLACE FUNCTION edoc.fn_leader_note_comment_and_assign(
  p_doc_id        BIGINT,
  p_staff_id      INT,
  p_content       TEXT,
  p_expired_date  TIMESTAMPTZ DEFAULT NULL,
  p_staff_ids     INT[] DEFAULT NULL,
  p_doc_type      VARCHAR DEFAULT 'incoming'  -- incoming | outgoing | drafting
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql AS $$
DECLARE
  v_id BIGINT;
  v_sent_count INT := 0;
BEGIN
  IF p_content IS NULL OR TRIM(p_content) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nội dung bút phê không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  -- Tạo leader note
  IF p_doc_type = 'incoming' THEN
    INSERT INTO edoc.leader_notes (incoming_doc_id, staff_id, content, expired_date, assigned_staff_ids)
    VALUES (p_doc_id, p_staff_id, TRIM(p_content), p_expired_date, p_staff_ids)
    RETURNING edoc.leader_notes.id INTO v_id;
  ELSIF p_doc_type = 'outgoing' THEN
    INSERT INTO edoc.leader_notes (outgoing_doc_id, staff_id, content, expired_date, assigned_staff_ids)
    VALUES (p_doc_id, p_staff_id, TRIM(p_content), p_expired_date, p_staff_ids)
    RETURNING edoc.leader_notes.id INTO v_id;
  ELSIF p_doc_type = 'drafting' THEN
    INSERT INTO edoc.leader_notes (drafting_doc_id, staff_id, content, expired_date, assigned_staff_ids)
    VALUES (p_doc_id, p_staff_id, TRIM(p_content), p_expired_date, p_staff_ids)
    RETURNING edoc.leader_notes.id INTO v_id;
  END IF;

  -- Gửi VB cho cán bộ được phân công
  IF p_staff_ids IS NOT NULL AND array_length(p_staff_ids, 1) > 0 THEN
    IF p_doc_type = 'incoming' THEN
      INSERT INTO edoc.user_incoming_docs (incoming_doc_id, staff_id, is_read, created_at)
      SELECT p_doc_id, unnest(p_staff_ids), FALSE, NOW()
      ON CONFLICT (incoming_doc_id, staff_id) DO NOTHING;
      GET DIAGNOSTICS v_sent_count = ROW_COUNT;
    ELSIF p_doc_type = 'outgoing' THEN
      INSERT INTO edoc.user_outgoing_docs (outgoing_doc_id, staff_id, sent_by, is_read, created_at)
      SELECT p_doc_id, unnest(p_staff_ids), p_staff_id, FALSE, NOW()
      ON CONFLICT (outgoing_doc_id, staff_id) DO NOTHING;
      GET DIAGNOSTICS v_sent_count = ROW_COUNT;
    ELSIF p_doc_type = 'drafting' THEN
      INSERT INTO edoc.user_drafting_docs (drafting_doc_id, staff_id, sent_by, is_read, created_at)
      SELECT p_doc_id, unnest(p_staff_ids), p_staff_id, FALSE, NOW()
      ON CONFLICT (drafting_doc_id, staff_id) DO NOTHING;
      GET DIAGNOSTICS v_sent_count = ROW_COUNT;
    END IF;
  END IF;

  RETURN QUERY SELECT TRUE,
    ('Bút phê thành công' || CASE WHEN v_sent_count > 0 THEN ', đã phân công ' || v_sent_count || ' cán bộ' ELSE '' END)::TEXT,
    v_id;
END;
$$;

-- ============================================================================
DO $$ BEGIN
  RAISE NOTICE '✅ Migration 024: S1 + S2';
  RAISE NOTICE '   S1: send_doc_user_configs table + 2 SPs';
  RAISE NOTICE '   S2: leader_notes +expired_date, +assigned_staff_ids, fn_leader_note_comment_and_assign';
END $$;

COMMIT;
