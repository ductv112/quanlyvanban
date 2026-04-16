-- ================================================================
-- MIGRATION 015: Sprint 10 — Dashboard thống kê & Widget dữ liệu
-- Functions: fn_dashboard_get_stats, fn_dashboard_recent_incoming,
--            fn_dashboard_upcoming_tasks, fn_dashboard_recent_outgoing
-- Fixed: doc_code→document_code, is_deleted removed, TIMESTAMPTZ, SMALLINT
-- ================================================================

-- ==========================================
-- 1. FN: Thống kê KPI Dashboard
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_get_stats(
  p_staff_id INT,
  p_unit_id  INT
) RETURNS TABLE (
  incoming_unread  BIGINT,
  outgoing_pending BIGINT,
  handling_total   BIGINT,
  handling_overdue BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    (
      SELECT COUNT(*)
      FROM edoc.user_incoming_docs uid
      INNER JOIN edoc.incoming_docs ind ON ind.id = uid.incoming_doc_id
      WHERE uid.staff_id = p_staff_id
        AND uid.is_read = FALSE
    ) AS incoming_unread,

    (
      SELECT COUNT(*)
      FROM edoc.outgoing_docs
      WHERE unit_id = p_unit_id
        AND approved = FALSE
    ) AS outgoing_pending,

    (
      SELECT COUNT(*)
      FROM edoc.handling_docs
      WHERE unit_id = p_unit_id
    ) AS handling_total,

    (
      SELECT COUNT(*)
      FROM edoc.handling_docs
      WHERE unit_id = p_unit_id
        AND end_date IS NOT NULL
        AND end_date < NOW()
        AND status != 4
    ) AS handling_overdue;
END;
$$;

-- ==========================================
-- 2. FN: Văn bản đến mới nhất
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_recent_incoming(
  p_unit_id INT,
  p_limit   INT DEFAULT 10
) RETURNS TABLE (
  id            BIGINT,
  doc_code      VARCHAR,
  abstract      TEXT,
  received_date TIMESTAMPTZ,
  urgency_name  VARCHAR,
  sender_name   VARCHAR
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    d.id,
    d.document_code::VARCHAR AS doc_code,
    d.abstract,
    d.received_date,
    CASE d.urgent_id
      WHEN 1 THEN 'Thường'
      WHEN 2 THEN 'Khẩn'
      WHEN 3 THEN 'Hỏa tốc'
      ELSE 'Thường'
    END::VARCHAR AS urgency_name,
    COALESCE(d.publish_unit, '')::VARCHAR AS sender_name
  FROM edoc.incoming_docs d
  WHERE d.unit_id = p_unit_id
  ORDER BY d.received_date DESC NULLS LAST, d.created_at DESC
  LIMIT COALESCE(p_limit, 10);
END;
$$;

-- ==========================================
-- 3. FN: Việc sắp tới hạn
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_upcoming_tasks(
  p_staff_id INT,
  p_limit    INT DEFAULT 10
) RETURNS TABLE (
  id               BIGINT,
  title            VARCHAR,
  open_date        TIMESTAMPTZ,
  status           SMALLINT,
  progress_percent SMALLINT,
  deadline         TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT
    hd.id,
    hd.name::VARCHAR AS title,
    hd.start_date AS open_date,
    hd.status,
    COALESCE(hd.progress, 0::SMALLINT) AS progress_percent,
    hd.end_date AS deadline
  FROM edoc.handling_docs hd
  WHERE hd.status != 4
    AND hd.end_date >= NOW()
    AND (
      hd.curator = p_staff_id
      OR EXISTS (
        SELECT 1 FROM edoc.staff_handling_docs shd
        WHERE shd.handling_doc_id = hd.id
          AND shd.staff_id = p_staff_id
      )
    )
  ORDER BY hd.end_date ASC
  LIMIT COALESCE(p_limit, 10);
END;
$$;

-- ==========================================
-- 4. FN: Văn bản đi mới nhất
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_recent_outgoing(
  p_unit_id INT,
  p_limit   INT DEFAULT 10
) RETURNS TABLE (
  id            BIGINT,
  doc_code      VARCHAR,
  abstract      TEXT,
  sent_date     TIMESTAMPTZ,
  doc_type_name VARCHAR
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    d.id,
    d.document_code::VARCHAR AS doc_code,
    d.abstract,
    COALESCE(d.publish_date, d.received_date, d.created_at) AS sent_date,
    COALESCE(dt.name, '')::VARCHAR AS doc_type_name
  FROM edoc.outgoing_docs d
  LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
  WHERE d.unit_id = p_unit_id
  ORDER BY COALESCE(d.publish_date, d.received_date, d.created_at) DESC
  LIMIT COALESCE(p_limit, 10);
END;
$$;
