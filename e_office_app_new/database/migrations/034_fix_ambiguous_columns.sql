-- ================================================================
-- Migration 034: Fix ambiguous column references trong SPs
-- ================================================================

BEGIN;

-- 1. fn_message_get_by_id — is_read ambiguous
CREATE OR REPLACE FUNCTION edoc.fn_message_get_by_id(p_id BIGINT, p_staff_id INT)
RETURNS TABLE(id BIGINT, from_staff_id INT, from_staff_name TEXT, subject VARCHAR, content TEXT, parent_id BIGINT, created_at TIMESTAMP, is_read BOOLEAN, recipient_names TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE edoc.message_recipients mr
  SET is_read = TRUE, read_at = NOW()
  WHERE mr.message_id = p_id AND mr.staff_id = p_staff_id AND mr.is_read = FALSE;

  RETURN QUERY
  SELECT m.id, m.from_staff_id,
    CONCAT(s.last_name, ' ', s.first_name)::TEXT,
    m.subject, m.content, m.parent_id, m.created_at,
    COALESCE(mr.is_read, FALSE),
    (SELECT STRING_AGG(CONCAT(sr.last_name, ' ', sr.first_name), ', ' ORDER BY sr.last_name)
     FROM edoc.message_recipients mr2 JOIN public.staff sr ON sr.id = mr2.staff_id
     WHERE mr2.message_id = m.id)::TEXT
  FROM edoc.messages m
  JOIN public.staff s ON s.id = m.from_staff_id
  LEFT JOIN edoc.message_recipients mr ON mr.message_id = m.id AND mr.staff_id = p_staff_id
  WHERE m.id = p_id
    AND (m.from_staff_id = p_staff_id
      OR EXISTS (SELECT 1 FROM edoc.message_recipients mr3 WHERE mr3.message_id = m.id AND mr3.staff_id = p_staff_id));
END; $$;

-- 2. fn_document_archive_create — id ambiguous (đã fix trước đó nhưng lưu lại)
CREATE OR REPLACE FUNCTION esto.fn_document_archive_create(
  p_doc_type VARCHAR, p_doc_id BIGINT,
  p_fond_id INT DEFAULT NULL, p_warehouse_id INT DEFAULT NULL, p_record_id BIGINT DEFAULT NULL,
  p_file_catalog VARCHAR DEFAULT NULL, p_file_notation VARCHAR DEFAULT NULL,
  p_doc_ordinal INT DEFAULT NULL, p_language VARCHAR DEFAULT 'Tiếng Việt',
  p_autograph TEXT DEFAULT NULL, p_keyword TEXT DEFAULT NULL,
  p_format VARCHAR DEFAULT 'Điện tử', p_confidence_level VARCHAR DEFAULT NULL,
  p_is_original BOOLEAN DEFAULT true, p_archived_by INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql AS $$
DECLARE v_id BIGINT;
BEGIN
  IF p_doc_type NOT IN ('incoming', 'outgoing') THEN
    RETURN QUERY SELECT FALSE, 'Loại văn bản không hợp lệ'::TEXT, 0::BIGINT; RETURN;
  END IF;
  IF p_doc_type = 'incoming' AND NOT EXISTS (SELECT 1 FROM edoc.incoming_docs ind WHERE ind.id = p_doc_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đến'::TEXT, 0::BIGINT; RETURN;
  END IF;
  IF p_doc_type = 'outgoing' AND NOT EXISTS (SELECT 1 FROM edoc.outgoing_docs od WHERE od.id = p_doc_id) THEN
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
  RETURNING document_archives.id INTO v_id;

  IF p_doc_type = 'incoming' THEN
    UPDATE edoc.incoming_docs SET archive_status = true WHERE edoc.incoming_docs.id = p_doc_id;
  ELSIF p_doc_type = 'outgoing' THEN
    UPDATE edoc.outgoing_docs SET archive_status = true WHERE edoc.outgoing_docs.id = p_doc_id;
  END IF;

  RETURN QUERY SELECT TRUE, 'Chuyển lưu trữ thành công'::TEXT, v_id;
END; $$;

-- 3. fn_message_reply — id ambiguous (WHERE id = p_message_id + RETURNING id)
CREATE OR REPLACE FUNCTION edoc.fn_message_reply(p_message_id BIGINT, p_staff_id INT, p_content TEXT)
RETURNS TABLE(success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_reply_id BIGINT;
  v_original edoc.messages%ROWTYPE;
  v_subject VARCHAR(200);
  v_staff_id INT;
BEGIN
  IF p_content IS NULL OR TRIM(p_content) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nội dung trả lời không được để trống'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  SELECT * INTO v_original FROM edoc.messages m WHERE m.id = p_message_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy tin nhắn gốc'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  v_subject := 'Re: ' || v_original.subject;

  INSERT INTO edoc.messages (from_staff_id, subject, content, parent_id, created_at)
  VALUES (p_staff_id, v_subject, p_content, p_message_id, NOW())
  RETURNING edoc.messages.id INTO v_reply_id;

  INSERT INTO edoc.message_recipients (message_id, staff_id, is_read, is_deleted)
  VALUES (v_reply_id, v_original.from_staff_id, FALSE, FALSE)
  ON CONFLICT (message_id, staff_id) DO NOTHING;

  FOR v_staff_id IN
    SELECT mr.staff_id FROM edoc.message_recipients mr
    WHERE mr.message_id = p_message_id AND mr.staff_id <> p_staff_id
  LOOP
    INSERT INTO edoc.message_recipients (message_id, staff_id, is_read, is_deleted)
    VALUES (v_reply_id, v_staff_id, FALSE, FALSE)
    ON CONFLICT (message_id, staff_id) DO NOTHING;
  END LOOP;

  RETURN QUERY SELECT TRUE, 'Trả lời tin nhắn thành công'::TEXT, v_reply_id;
END; $$;

DO $$ BEGIN RAISE NOTICE '034: Fixed ambiguous columns in fn_message_get_by_id + fn_document_archive_create + fn_message_reply'; END $$;

COMMIT;
