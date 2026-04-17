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
