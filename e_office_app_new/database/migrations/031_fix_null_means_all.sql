-- ================================================================
-- Migration 031: Fix WHERE logic — NULL = show all (admin)
-- Thay CASE fallback unit_id bằng (IS NULL OR ANY)
-- ================================================================
BEGIN;

-- 1. fn_incoming_doc_count_unread
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_count_unread(
  p_unit_id INT, p_staff_id INT, p_dept_ids INT[] DEFAULT NULL
) RETURNS INT LANGUAGE plpgsql AS $$
DECLARE v_count INT;
BEGIN
  SELECT COUNT(*)::INT INTO v_count
  FROM edoc.incoming_docs d
  LEFT JOIN edoc.user_incoming_docs uid ON uid.incoming_doc_id = d.id AND uid.staff_id = p_staff_id
  WHERE (p_dept_ids IS NULL OR d.department_id = ANY(p_dept_ids))
    AND (uid.is_read IS NULL OR uid.is_read = FALSE);
  RETURN v_count;
END; $$;

-- 2. fn_outgoing_doc_count_unread
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_count_unread(
  p_unit_id INT, p_staff_id INT, p_dept_ids INT[] DEFAULT NULL
) RETURNS INT LANGUAGE plpgsql AS $$
DECLARE v_count INT;
BEGIN
  SELECT COUNT(*)::INT INTO v_count
  FROM edoc.outgoing_docs d
  LEFT JOIN edoc.user_outgoing_docs uo ON uo.outgoing_doc_id = d.id AND uo.staff_id = p_staff_id
  WHERE (p_dept_ids IS NULL OR d.department_id = ANY(p_dept_ids))
    AND (uo.is_read IS NULL OR uo.is_read = FALSE);
  RETURN v_count;
END; $$;

-- 3. fn_drafting_doc_count_unread
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_count_unread(
  p_unit_id INT, p_staff_id INT, p_dept_ids INT[] DEFAULT NULL
) RETURNS INT LANGUAGE plpgsql AS $$
DECLARE v_count INT;
BEGIN
  SELECT COUNT(*)::INT INTO v_count
  FROM edoc.drafting_docs d
  LEFT JOIN edoc.user_drafting_docs ud ON ud.drafting_doc_id = d.id AND ud.staff_id = p_staff_id
  WHERE (p_dept_ids IS NULL OR d.department_id = ANY(p_dept_ids))
    AND (ud.is_read IS NULL OR ud.is_read = FALSE);
  RETURN v_count;
END; $$;

-- 4. fn_handling_doc_count_by_status
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_count_by_status(
  p_unit_id INT, p_staff_id INT, p_dept_ids INT[] DEFAULT NULL
) RETURNS TABLE (filter_type TEXT, count BIGINT) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT 'all'::TEXT,               COUNT(*)::BIGINT FROM edoc.handling_docs WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids))
  UNION ALL
  SELECT 'created_by_me'::TEXT,     COUNT(*)::BIGINT FROM edoc.handling_docs WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids)) AND created_by = p_staff_id
  UNION ALL
  SELECT 'rejected'::TEXT,          COUNT(*)::BIGINT FROM edoc.handling_docs WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids)) AND status = -1 AND created_by = p_staff_id
  UNION ALL
  SELECT 'returned'::TEXT,          COUNT(*)::BIGINT FROM edoc.handling_docs WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids)) AND status = -2
  UNION ALL
  SELECT 'pending_primary'::TEXT,   COUNT(*)::BIGINT
    FROM edoc.handling_docs h
    WHERE (p_dept_ids IS NULL OR h.department_id = ANY(p_dept_ids)) AND h.status = 0
      AND EXISTS (SELECT 1 FROM edoc.staff_handling_docs shd WHERE shd.handling_doc_id = h.id AND shd.staff_id = p_staff_id AND shd.role = 1)
  UNION ALL
  SELECT 'pending_coord'::TEXT,     COUNT(*)::BIGINT
    FROM edoc.handling_docs h
    WHERE (p_dept_ids IS NULL OR h.department_id = ANY(p_dept_ids)) AND h.status IN (0, 1)
      AND EXISTS (SELECT 1 FROM edoc.staff_handling_docs shd WHERE shd.handling_doc_id = h.id AND shd.staff_id = p_staff_id AND shd.role = 2)
  UNION ALL
  SELECT 'submitting'::TEXT,        COUNT(*)::BIGINT FROM edoc.handling_docs WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids)) AND status = 2
  UNION ALL
  SELECT 'in_progress'::TEXT,       COUNT(*)::BIGINT FROM edoc.handling_docs WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids)) AND status = 1
  UNION ALL
  SELECT 'proposed_complete'::TEXT, COUNT(*)::BIGINT FROM edoc.handling_docs WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids)) AND status = 3
  UNION ALL
  SELECT 'completed'::TEXT,         COUNT(*)::BIGINT FROM edoc.handling_docs WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids)) AND status = 4;
END; $$;

-- 5. fn_dashboard_get_stats
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_get_stats(
  p_staff_id INT, p_unit_id INT, p_dept_ids INT[] DEFAULT NULL
) RETURNS TABLE (
  incoming_unread BIGINT, outgoing_pending BIGINT, handling_total BIGINT, handling_overdue BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY SELECT
    (SELECT COUNT(*) FROM edoc.user_incoming_docs uid
     INNER JOIN edoc.incoming_docs ind ON ind.id = uid.incoming_doc_id
     WHERE uid.staff_id = p_staff_id AND uid.is_read = FALSE
       AND (p_dept_ids IS NULL OR ind.department_id = ANY(p_dept_ids))
    ),
    (SELECT COUNT(*) FROM edoc.outgoing_docs
     WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids)) AND approved = FALSE
    ),
    (SELECT COUNT(*) FROM edoc.handling_docs
     WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids))
    ),
    (SELECT COUNT(*) FROM edoc.handling_docs
     WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids))
       AND end_date IS NOT NULL AND end_date < NOW() AND status != 4
    );
END; $$;

-- 6. fn_dashboard_recent_incoming
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_recent_incoming(
  p_unit_id INT, p_limit INT DEFAULT 10, p_dept_ids INT[] DEFAULT NULL
) RETURNS TABLE (
  id BIGINT, doc_code VARCHAR, abstract TEXT, received_date TIMESTAMPTZ, urgency_name VARCHAR, sender_name VARCHAR
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY SELECT d.id,
    COALESCE(NULLIF(d.notation, ''), d.document_code, '')::VARCHAR,
    d.abstract, d.received_date,
    CASE d.urgent_id WHEN 1 THEN 'Thường' WHEN 2 THEN 'Khẩn' WHEN 3 THEN 'Hỏa tốc' ELSE 'Thường' END::VARCHAR,
    COALESCE(d.publish_unit, '')::VARCHAR
  FROM edoc.incoming_docs d
  WHERE (p_dept_ids IS NULL OR d.department_id = ANY(p_dept_ids))
  ORDER BY d.received_date DESC NULLS LAST, d.created_at DESC
  LIMIT COALESCE(p_limit, 10);
END; $$;

-- 7. fn_dashboard_recent_outgoing
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_recent_outgoing(
  p_unit_id INT, p_limit INT DEFAULT 10, p_dept_ids INT[] DEFAULT NULL
) RETURNS TABLE (
  id BIGINT, doc_code VARCHAR, abstract TEXT, sent_date TIMESTAMPTZ, doc_type_name VARCHAR
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY SELECT d.id,
    COALESCE(NULLIF(d.notation, ''), d.document_code, '')::VARCHAR,
    d.abstract, COALESCE(d.publish_date, d.received_date, d.created_at),
    COALESCE(dt.name, '')::VARCHAR
  FROM edoc.outgoing_docs d LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
  WHERE (p_dept_ids IS NULL OR d.department_id = ANY(p_dept_ids))
  ORDER BY COALESCE(d.publish_date, d.received_date, d.created_at) DESC
  LIMIT COALESCE(p_limit, 10);
END; $$;

-- 8. fn_incoming_doc_get_list
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_get_list(INT, INT, INT, INT, INT, SMALLINT, BOOLEAN, BOOLEAN, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, TEXT, INT, INT, INT, INT, INT[]);
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_get_list(
  p_unit_id INT, p_staff_id INT,
  p_doc_book_id INT DEFAULT NULL, p_doc_type_id INT DEFAULT NULL, p_doc_field_id INT DEFAULT NULL,
  p_urgent_id SMALLINT DEFAULT NULL, p_is_read BOOLEAN DEFAULT NULL, p_approved BOOLEAN DEFAULT NULL,
  p_from_date TIMESTAMPTZ DEFAULT NULL, p_to_date TIMESTAMPTZ DEFAULT NULL, p_keyword TEXT DEFAULT NULL,
  p_signer TEXT DEFAULT NULL, p_from_number INT DEFAULT NULL, p_to_number INT DEFAULT NULL,
  p_page INT DEFAULT 1, p_page_size INT DEFAULT 20,
  p_dept_ids INT[] DEFAULT NULL
)
RETURNS TABLE (
  id BIGINT, unit_id INT, received_date TIMESTAMPTZ, number INT, notation VARCHAR,
  document_code VARCHAR, abstract TEXT, publish_unit VARCHAR, publish_date TIMESTAMPTZ,
  signer VARCHAR, sign_date TIMESTAMPTZ, doc_book_id INT, doc_type_id INT, doc_field_id INT,
  secret_id SMALLINT, urgent_id SMALLINT, number_paper INT, number_copies INT,
  expired_date TIMESTAMPTZ, recipients TEXT, sents TEXT,
  approver VARCHAR, approved BOOLEAN, is_handling BOOLEAN, is_received_paper BOOLEAN,
  archive_status BOOLEAN, created_by INT, created_at TIMESTAMPTZ,
  doc_book_name VARCHAR, doc_type_name VARCHAR, doc_type_code VARCHAR, doc_field_name VARCHAR,
  created_by_name VARCHAR, is_read BOOLEAN, read_at TIMESTAMPTZ,
  attachment_count BIGINT, total_count BIGINT
) LANGUAGE plpgsql AS $$
DECLARE v_offset INT; v_keyword TEXT; v_signer TEXT;
BEGIN
  v_offset := (GREATEST(p_page, 1) - 1) * p_page_size;
  v_keyword := NULLIF(TRIM(p_keyword), '');
  v_signer := NULLIF(TRIM(p_signer), '');
  RETURN QUERY
  WITH filtered AS (
    SELECT d.id AS doc_id, d.*,
      db.name AS _doc_book_name, dt.name AS _doc_type_name, dt.code AS _doc_type_code,
      df.name AS _doc_field_name, s.full_name AS _created_by_name,
      uid.is_read AS _is_read, uid.read_at AS _read_at,
      (SELECT COUNT(*) FROM edoc.attachment_incoming_docs a WHERE a.incoming_doc_id = d.id) AS _attachment_count,
      COUNT(*) OVER() AS _total_count
    FROM edoc.incoming_docs d
    LEFT JOIN edoc.doc_books db ON db.id = d.doc_book_id
    LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
    LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id
    LEFT JOIN public.staff s ON s.id = d.created_by
    LEFT JOIN edoc.user_incoming_docs uid ON uid.incoming_doc_id = d.id AND uid.staff_id = p_staff_id
    WHERE (p_dept_ids IS NULL OR d.department_id = ANY(p_dept_ids))
      AND (p_doc_book_id IS NULL OR d.doc_book_id = p_doc_book_id)
      AND (p_doc_type_id IS NULL OR d.doc_type_id = p_doc_type_id)
      AND (p_doc_field_id IS NULL OR d.doc_field_id = p_doc_field_id)
      AND (p_urgent_id IS NULL OR d.urgent_id = p_urgent_id)
      AND (p_approved IS NULL OR d.approved = p_approved)
      AND (p_from_date IS NULL OR d.received_date >= p_from_date)
      AND (p_to_date IS NULL OR d.received_date <= p_to_date)
      AND (p_is_read IS NULL OR (p_is_read = TRUE AND uid.is_read = TRUE) OR (p_is_read = FALSE AND (uid.is_read IS NULL OR uid.is_read = FALSE)))
      AND (v_signer IS NULL OR d.signer ILIKE '%' || v_signer || '%')
      AND (p_from_number IS NULL OR d.number >= p_from_number)
      AND (p_to_number IS NULL OR d.number <= p_to_number)
      AND (v_keyword IS NULL OR d.abstract ILIKE '%' || v_keyword || '%' OR d.notation ILIKE '%' || v_keyword || '%' OR d.publish_unit ILIKE '%' || v_keyword || '%' OR d.signer ILIKE '%' || v_keyword || '%' OR d.document_code ILIKE '%' || v_keyword || '%')
    ORDER BY d.received_date DESC, d.number DESC LIMIT p_page_size OFFSET v_offset
  )
  SELECT f.doc_id, f.unit_id, f.received_date, f.number, f.notation, f.document_code, f.abstract,
    f.publish_unit, f.publish_date, f.signer, f.sign_date, f.doc_book_id, f.doc_type_id, f.doc_field_id,
    f.secret_id, f.urgent_id, f.number_paper, f.number_copies, f.expired_date, f.recipients, f.sents,
    f.approver, f.approved, f.is_handling, f.is_received_paper, f.archive_status,
    f.created_by, f.created_at, f._doc_book_name, f._doc_type_name, f._doc_type_code, f._doc_field_name,
    f._created_by_name, COALESCE(f._is_read, FALSE), f._read_at, f._attachment_count, f._total_count
  FROM filtered f;
END; $$;

-- 9. fn_outgoing_doc_get_list
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_get_list(
  p_unit_id INT, p_staff_id INT,
  p_doc_book_id INT DEFAULT NULL, p_doc_type_id INT DEFAULT NULL, p_doc_field_id INT DEFAULT NULL,
  p_urgent_id SMALLINT DEFAULT NULL, p_approved BOOLEAN DEFAULT NULL,
  p_from_date TIMESTAMPTZ DEFAULT NULL, p_to_date TIMESTAMPTZ DEFAULT NULL, p_keyword TEXT DEFAULT NULL,
  p_page INT DEFAULT 1, p_page_size INT DEFAULT 20,
  p_dept_ids INT[] DEFAULT NULL
)
RETURNS TABLE (
  id BIGINT, unit_id INT, received_date TIMESTAMPTZ, number INT, sub_number VARCHAR,
  notation VARCHAR, document_code VARCHAR, abstract TEXT,
  drafting_unit_id INT, drafting_user_id INT, publish_unit_id INT,
  publish_date TIMESTAMPTZ, signer VARCHAR, sign_date TIMESTAMPTZ, expired_date TIMESTAMPTZ,
  doc_book_id INT, doc_type_id INT, doc_field_id INT, secret_id SMALLINT, urgent_id SMALLINT,
  number_paper INT, number_copies INT, recipients TEXT,
  approver VARCHAR, approved BOOLEAN, is_handling BOOLEAN, archive_status BOOLEAN,
  created_by INT, created_at TIMESTAMPTZ,
  doc_book_name VARCHAR, doc_type_name VARCHAR, doc_type_code VARCHAR, doc_field_name VARCHAR,
  drafting_unit_name VARCHAR, drafting_user_name VARCHAR, created_by_name VARCHAR,
  is_read BOOLEAN, read_at TIMESTAMPTZ, attachment_count BIGINT, total_count BIGINT
) LANGUAGE plpgsql AS $$
DECLARE v_offset INT; v_keyword TEXT;
BEGIN
  v_offset := (GREATEST(p_page, 1) - 1) * p_page_size;
  v_keyword := NULLIF(TRIM(p_keyword), '');
  RETURN QUERY
  WITH filtered AS (
    SELECT d.id AS doc_id, d.*,
      db.name AS _doc_book_name, dt.name AS _doc_type_name, dt.code AS _doc_type_code,
      df.name AS _doc_field_name, du.name AS _drafting_unit_name, ds.full_name AS _drafting_user_name,
      s.full_name AS _created_by_name, uo.is_read AS _is_read, uo.read_at AS _read_at,
      (SELECT COUNT(*) FROM edoc.attachment_outgoing_docs a WHERE a.outgoing_doc_id = d.id) AS _attachment_count,
      COUNT(*) OVER() AS _total_count
    FROM edoc.outgoing_docs d
    LEFT JOIN edoc.doc_books db ON db.id = d.doc_book_id LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
    LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id LEFT JOIN public.departments du ON du.id = d.drafting_unit_id
    LEFT JOIN public.staff ds ON ds.id = d.drafting_user_id LEFT JOIN public.staff s ON s.id = d.created_by
    LEFT JOIN edoc.user_outgoing_docs uo ON uo.outgoing_doc_id = d.id AND uo.staff_id = p_staff_id
    WHERE (p_dept_ids IS NULL OR d.department_id = ANY(p_dept_ids))
      AND (p_doc_book_id IS NULL OR d.doc_book_id = p_doc_book_id)
      AND (p_doc_type_id IS NULL OR d.doc_type_id = p_doc_type_id)
      AND (p_doc_field_id IS NULL OR d.doc_field_id = p_doc_field_id)
      AND (p_urgent_id IS NULL OR d.urgent_id = p_urgent_id)
      AND (p_approved IS NULL OR d.approved = p_approved)
      AND (p_from_date IS NULL OR d.received_date >= p_from_date)
      AND (p_to_date IS NULL OR d.received_date <= p_to_date)
      AND (v_keyword IS NULL OR d.abstract ILIKE '%' || v_keyword || '%' OR d.notation ILIKE '%' || v_keyword || '%' OR d.signer ILIKE '%' || v_keyword || '%' OR d.recipients ILIKE '%' || v_keyword || '%')
    ORDER BY d.received_date DESC, d.number DESC LIMIT p_page_size OFFSET v_offset
  )
  SELECT f.doc_id, f.unit_id, f.received_date, f.number, f.sub_number, f.notation, f.document_code, f.abstract,
    f.drafting_unit_id, f.drafting_user_id, f.publish_unit_id, f.publish_date, f.signer, f.sign_date, f.expired_date,
    f.doc_book_id, f.doc_type_id, f.doc_field_id, f.secret_id, f.urgent_id, f.number_paper, f.number_copies,
    f.recipients, f.approver, f.approved, f.is_handling, f.archive_status,
    f.created_by, f.created_at, f._doc_book_name, f._doc_type_name, f._doc_type_code, f._doc_field_name,
    f._drafting_unit_name, f._drafting_user_name, f._created_by_name,
    COALESCE(f._is_read, FALSE), f._read_at, f._attachment_count, f._total_count
  FROM filtered f;
END; $$;

-- 10. fn_drafting_doc_get_list
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_get_list(
  p_unit_id INT, p_staff_id INT,
  p_doc_book_id INT DEFAULT NULL, p_doc_type_id INT DEFAULT NULL, p_doc_field_id INT DEFAULT NULL,
  p_urgent_id SMALLINT DEFAULT NULL, p_is_released BOOLEAN DEFAULT NULL, p_approved BOOLEAN DEFAULT NULL,
  p_from_date TIMESTAMPTZ DEFAULT NULL, p_to_date TIMESTAMPTZ DEFAULT NULL, p_keyword TEXT DEFAULT NULL,
  p_page INT DEFAULT 1, p_page_size INT DEFAULT 20,
  p_dept_ids INT[] DEFAULT NULL
)
RETURNS TABLE (
  id BIGINT, unit_id INT, received_date TIMESTAMPTZ, number INT, sub_number VARCHAR,
  notation VARCHAR, document_code VARCHAR, abstract TEXT,
  drafting_unit_id INT, drafting_user_id INT, publish_unit_id INT,
  publish_date TIMESTAMPTZ, signer VARCHAR, sign_date TIMESTAMPTZ,
  doc_book_id INT, doc_type_id INT, doc_field_id INT, secret_id SMALLINT, urgent_id SMALLINT,
  number_paper INT, number_copies INT, expired_date TIMESTAMPTZ, recipients TEXT,
  approver VARCHAR, approved BOOLEAN, is_released BOOLEAN, released_date TIMESTAMPTZ,
  created_by INT, created_at TIMESTAMPTZ,
  doc_book_name VARCHAR, doc_type_name VARCHAR, doc_type_code VARCHAR, doc_field_name VARCHAR,
  drafting_unit_name VARCHAR, drafting_user_name VARCHAR, created_by_name VARCHAR,
  is_read BOOLEAN, read_at TIMESTAMPTZ, attachment_count BIGINT, total_count BIGINT
) LANGUAGE plpgsql AS $$
DECLARE v_offset INT; v_keyword TEXT;
BEGIN
  v_offset := (GREATEST(p_page, 1) - 1) * p_page_size;
  v_keyword := NULLIF(TRIM(p_keyword), '');
  RETURN QUERY
  WITH filtered AS (
    SELECT d.id AS doc_id, d.*,
      db.name AS _doc_book_name, dt.name AS _doc_type_name, dt.code AS _doc_type_code,
      df.name AS _doc_field_name, du.name AS _drafting_unit_name, ds.full_name AS _drafting_user_name,
      s.full_name AS _created_by_name, ud.is_read AS _is_read, ud.read_at AS _read_at,
      (SELECT COUNT(*) FROM edoc.attachment_drafting_docs a WHERE a.drafting_doc_id = d.id) AS _attachment_count,
      COUNT(*) OVER() AS _total_count
    FROM edoc.drafting_docs d
    LEFT JOIN edoc.doc_books db ON db.id = d.doc_book_id LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
    LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id LEFT JOIN public.departments du ON du.id = d.drafting_unit_id
    LEFT JOIN public.staff ds ON ds.id = d.drafting_user_id LEFT JOIN public.staff s ON s.id = d.created_by
    LEFT JOIN edoc.user_drafting_docs ud ON ud.drafting_doc_id = d.id AND ud.staff_id = p_staff_id
    WHERE (p_dept_ids IS NULL OR d.department_id = ANY(p_dept_ids))
      AND (p_doc_book_id IS NULL OR d.doc_book_id = p_doc_book_id)
      AND (p_doc_type_id IS NULL OR d.doc_type_id = p_doc_type_id)
      AND (p_doc_field_id IS NULL OR d.doc_field_id = p_doc_field_id)
      AND (p_urgent_id IS NULL OR d.urgent_id = p_urgent_id)
      AND (p_approved IS NULL OR d.approved = p_approved)
      AND (p_is_released IS NULL OR d.is_released = p_is_released)
      AND (p_from_date IS NULL OR d.received_date >= p_from_date)
      AND (p_to_date IS NULL OR d.received_date <= p_to_date)
      AND (v_keyword IS NULL OR d.abstract ILIKE '%' || v_keyword || '%' OR d.notation ILIKE '%' || v_keyword || '%' OR d.signer ILIKE '%' || v_keyword || '%' OR d.recipients ILIKE '%' || v_keyword || '%')
    ORDER BY d.received_date DESC, d.number DESC LIMIT p_page_size OFFSET v_offset
  )
  SELECT f.doc_id, f.unit_id, f.received_date, f.number, f.sub_number, f.notation, f.document_code, f.abstract,
    f.drafting_unit_id, f.drafting_user_id, f.publish_unit_id, f.publish_date, f.signer, f.sign_date,
    f.doc_book_id, f.doc_type_id, f.doc_field_id, f.secret_id, f.urgent_id, f.number_paper, f.number_copies,
    f.expired_date, f.recipients, f.approver, f.approved, f.is_released, f.released_date,
    f.created_by, f.created_at, f._doc_book_name, f._doc_type_name, f._doc_type_code, f._doc_field_name,
    f._drafting_unit_name, f._drafting_user_name, f._created_by_name,
    COALESCE(f._is_read, FALSE), f._read_at, f._attachment_count, f._total_count
  FROM filtered f;
END; $$;

-- 11. fn_handling_doc_get_list
DROP FUNCTION IF EXISTS edoc.fn_handling_doc_get_list(INT, INT[], INT, INT, TEXT, TEXT, TIMESTAMPTZ, TIMESTAMPTZ, INT, INT);
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_get_list(
  p_unit_id INT, p_dept_ids INT[] DEFAULT NULL, p_staff_id INT DEFAULT NULL,
  p_status INT DEFAULT NULL, p_filter_type TEXT DEFAULT NULL, p_keyword TEXT DEFAULT NULL,
  p_from_date TIMESTAMPTZ DEFAULT NULL, p_to_date TIMESTAMPTZ DEFAULT NULL,
  p_page INT DEFAULT 1, p_page_size INT DEFAULT 20
)
RETURNS TABLE (
  id BIGINT, name VARCHAR, start_date TIMESTAMPTZ, end_date TIMESTAMPTZ, status SMALLINT,
  curator_id INT, curator_name TEXT, signer_id INT, signer_name TEXT,
  progress SMALLINT, doc_field_name VARCHAR, doc_type_name VARCHAR, created_at TIMESTAMPTZ, total_count BIGINT
) LANGUAGE plpgsql AS $$
DECLARE v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT h.id, h.name, h.start_date, h.end_date, h.status,
      h.curator AS curator_id, CONCAT(sc.last_name, ' ', sc.first_name) AS curator_name,
      h.signer AS signer_id, CONCAT(ss.last_name, ' ', ss.first_name) AS signer_name,
      h.progress, df.name AS doc_field_name, dt.name AS doc_type_name, h.created_at
    FROM edoc.handling_docs h
    LEFT JOIN public.staff sc ON sc.id = h.curator LEFT JOIN public.staff ss ON ss.id = h.signer
    LEFT JOIN edoc.doc_fields df ON df.id = h.doc_field_id LEFT JOIN edoc.doc_types dt ON dt.id = h.doc_type_id
    WHERE (p_dept_ids IS NULL OR h.department_id = ANY(p_dept_ids))
      AND (p_status IS NULL OR p_status = -99 OR h.status = p_status)
      AND (p_filter_type IS NULL OR p_filter_type = 'all' OR
        (p_filter_type = 'created_by_me' AND h.created_by = p_staff_id) OR
        (p_filter_type = 'rejected' AND h.status = -1 AND h.created_by = p_staff_id) OR
        (p_filter_type = 'returned' AND h.status = -2) OR
        (p_filter_type = 'pending_primary' AND h.status = 0 AND EXISTS (SELECT 1 FROM edoc.staff_handling_docs shd WHERE shd.handling_doc_id = h.id AND shd.staff_id = p_staff_id AND shd.role = 1)) OR
        (p_filter_type = 'pending_coord' AND h.status IN (0, 1) AND EXISTS (SELECT 1 FROM edoc.staff_handling_docs shd WHERE shd.handling_doc_id = h.id AND shd.staff_id = p_staff_id AND shd.role = 2)) OR
        (p_filter_type = 'submitting' AND h.status = 2) OR (p_filter_type = 'in_progress' AND h.status = 1) OR
        (p_filter_type = 'proposed_complete' AND h.status = 3) OR (p_filter_type = 'completed' AND h.status = 4))
      AND (p_keyword IS NULL OR TRIM(p_keyword) = '' OR h.name ILIKE '%' || p_keyword || '%')
      AND (p_from_date IS NULL OR h.start_date >= p_from_date)
      AND (p_to_date IS NULL OR h.start_date <= p_to_date)
  )
  SELECT f.id, f.name, f.start_date, f.end_date, f.status,
    f.curator_id, f.curator_name::TEXT, f.signer_id, f.signer_name::TEXT,
    f.progress, f.doc_field_name, f.doc_type_name, f.created_at,
    COUNT(*) OVER() AS total_count
  FROM filtered f ORDER BY f.created_at DESC LIMIT p_page_size OFFSET v_offset;
END; $$;

DO $$ BEGIN RAISE NOTICE '✅ Migration 031: All SPs fixed — NULL = show all'; END $$;
COMMIT;
