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
