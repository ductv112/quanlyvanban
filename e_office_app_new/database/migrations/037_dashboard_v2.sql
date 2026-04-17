-- ================================================================
-- MIGRATION 037: Dashboard V2 — Biểu đồ + Stat cards mở rộng
-- Thêm 8 stored functions cho dashboard nâng cấp
-- ================================================================

-- ==========================================
-- 1. Thống kê mở rộng (stat cards bổ sung)
-- Trả về: drafting_pending, message_unread, notice_unread, today_meetings
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_get_stats_extra(
  p_staff_id INT,
  p_dept_ids INT[] DEFAULT NULL
) RETURNS TABLE (
  drafting_pending BIGINT,
  message_unread   BIGINT,
  notice_unread    BIGINT,
  today_meetings   BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    -- VB dự thảo chờ phát hành (approved nhưng chưa released)
    (
      SELECT COUNT(*)
      FROM edoc.drafting_docs dd
      WHERE dd.approved = TRUE
        AND dd.is_released = FALSE
        AND (p_dept_ids IS NULL OR dd.unit_id = ANY(p_dept_ids))
    ) AS drafting_pending,

    -- Tin nhắn chưa đọc
    (
      SELECT COUNT(*)
      FROM edoc.message_recipients mr
      WHERE mr.staff_id = p_staff_id
        AND mr.is_read = FALSE
        AND mr.is_deleted = FALSE
    ) AS message_unread,

    -- Thông báo chưa đọc
    (
      SELECT COUNT(*)
      FROM edoc.notices n
      WHERE NOT EXISTS (
        SELECT 1 FROM edoc.notice_reads nr
        WHERE nr.notice_id = n.id AND nr.staff_id = p_staff_id
      )
      AND (
        n.unit_id IS NULL
        OR n.unit_id = ANY(COALESCE(p_dept_ids, ARRAY[]::INT[]))
      )
    ) AS notice_unread,

    -- Lịch họp hôm nay
    (
      SELECT COUNT(*)
      FROM edoc.room_schedules rs
      WHERE rs.start_date = CURRENT_DATE
        AND (p_dept_ids IS NULL OR rs.unit_id = ANY(p_dept_ids))
    ) AS today_meetings;
END;
$$;

-- ==========================================
-- 2. VB đến/đi theo tháng (6 tháng gần nhất)
-- Dùng cho biểu đồ cột grouped bar chart
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_doc_by_month(
  p_dept_ids INT[] DEFAULT NULL,
  p_months   INT DEFAULT 6
) RETURNS TABLE (
  month_label  TEXT,
  incoming_count BIGINT,
  outgoing_count BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  WITH months AS (
    SELECT generate_series(
      date_trunc('month', CURRENT_DATE) - ((p_months - 1) || ' months')::interval,
      date_trunc('month', CURRENT_DATE),
      '1 month'::interval
    )::date AS m
  )
  SELECT
    to_char(mo.m, 'MM/YYYY')::TEXT AS month_label,
    COALESCE((
      SELECT COUNT(*)
      FROM edoc.incoming_docs ind
      WHERE date_trunc('month', COALESCE(ind.received_date, ind.created_at)) = mo.m
        AND (p_dept_ids IS NULL OR ind.unit_id = ANY(p_dept_ids))
    ), 0) AS incoming_count,
    COALESCE((
      SELECT COUNT(*)
      FROM edoc.outgoing_docs od
      WHERE date_trunc('month', COALESCE(od.publish_date, od.created_at)) = mo.m
        AND (p_dept_ids IS NULL OR od.unit_id = ANY(p_dept_ids))
    ), 0) AS outgoing_count
  FROM months mo
  ORDER BY mo.m;
END;
$$;

-- ==========================================
-- 3. HSCV theo trạng thái (biểu đồ tròn)
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_task_by_status(
  p_staff_id INT,
  p_dept_ids INT[] DEFAULT NULL
) RETURNS TABLE (
  status_code  SMALLINT,
  status_name  TEXT,
  task_count   BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    hd.status AS status_code,
    CASE hd.status
      WHEN 0 THEN 'Mới'
      WHEN 1 THEN 'Đang xử lý'
      WHEN 2 THEN 'Chờ duyệt'
      WHEN 3 THEN 'Đã duyệt'
      WHEN 4 THEN 'Hoàn thành'
      WHEN -1 THEN 'Từ chối'
      WHEN -2 THEN 'Trả về'
      ELSE 'Khác'
    END::TEXT AS status_name,
    COUNT(*)::BIGINT AS task_count
  FROM edoc.handling_docs hd
  WHERE (p_dept_ids IS NULL OR hd.unit_id = ANY(p_dept_ids))
  GROUP BY hd.status
  ORDER BY hd.status;
END;
$$;

-- ==========================================
-- 4. Top 5 phòng ban có nhiều VB nhất (biểu đồ cột ngang)
-- Đếm tổng VB đến + đi theo phòng ban
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_top_departments(
  p_dept_ids INT[] DEFAULT NULL,
  p_limit    INT DEFAULT 5
) RETURNS TABLE (
  department_id   INT,
  department_name VARCHAR,
  doc_count       BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  WITH dept_incoming AS (
    SELECT ind.department_id AS dept_id, COUNT(*) AS cnt
    FROM edoc.incoming_docs ind
    WHERE ind.department_id IS NOT NULL
      AND (p_dept_ids IS NULL OR ind.unit_id = ANY(p_dept_ids))
    GROUP BY ind.department_id
  ),
  dept_outgoing AS (
    SELECT od.department_id AS dept_id, COUNT(*) AS cnt
    FROM edoc.outgoing_docs od
    WHERE od.department_id IS NOT NULL
      AND (p_dept_ids IS NULL OR od.unit_id = ANY(p_dept_ids))
    GROUP BY od.department_id
  ),
  combined AS (
    SELECT dept_id, SUM(cnt)::BIGINT AS total
    FROM (
      SELECT * FROM dept_incoming
      UNION ALL
      SELECT * FROM dept_outgoing
    ) sub
    GROUP BY dept_id
  )
  SELECT
    c.dept_id AS department_id,
    d.name AS department_name,
    c.total AS doc_count
  FROM combined c
  INNER JOIN public.departments d ON d.id = c.dept_id
  ORDER BY c.total DESC
  LIMIT COALESCE(p_limit, 5);
END;
$$;

-- ==========================================
-- 5. Thông báo mới nhất (widget)
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_recent_notices(
  p_staff_id INT,
  p_dept_ids INT[] DEFAULT NULL,
  p_limit    INT DEFAULT 5
) RETURNS TABLE (
  id          BIGINT,
  title       VARCHAR,
  notice_type VARCHAR,
  created_at  TIMESTAMP,
  is_read     BOOLEAN
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    n.id,
    n.title,
    n.notice_type,
    n.created_at,
    EXISTS (
      SELECT 1 FROM edoc.notice_reads nr
      WHERE nr.notice_id = n.id AND nr.staff_id = p_staff_id
    ) AS is_read
  FROM edoc.notices n
  WHERE (
    n.unit_id IS NULL
    OR n.unit_id = ANY(COALESCE(p_dept_ids, ARRAY[]::INT[]))
  )
  ORDER BY n.created_at DESC
  LIMIT COALESCE(p_limit, 5);
END;
$$;

-- ==========================================
-- 6. Lịch hôm nay (widget mini calendar)
-- Lấy sự kiện hôm nay + 7 ngày tới
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_calendar_today(
  p_staff_id INT,
  p_dept_ids INT[] DEFAULT NULL,
  p_days     INT DEFAULT 7
) RETURNS TABLE (
  id         BIGINT,
  title      VARCHAR,
  start_time TIMESTAMP,
  end_time   TIMESTAMP,
  all_day    BOOLEAN,
  color      VARCHAR,
  scope      VARCHAR
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    ce.id,
    ce.title,
    ce.start_time,
    ce.end_time,
    ce.all_day,
    ce.color,
    ce.scope
  FROM public.calendar_events ce
  WHERE ce.is_deleted = FALSE
    AND ce.start_time < (CURRENT_DATE + p_days * interval '1 day')
    AND ce.end_time >= CURRENT_DATE
    AND (
      (ce.scope = 'personal' AND ce.created_by = p_staff_id)
      OR (ce.scope IN ('unit', 'leader') AND (
        p_dept_ids IS NULL
        OR ce.unit_id = ANY(p_dept_ids)
      ))
    )
  ORDER BY ce.start_time ASC
  LIMIT 10;
END;
$$;

-- ==========================================
-- 7. Tỷ lệ xử lý đúng hạn — KPI admin
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_ontime_rate(
  p_dept_ids INT[] DEFAULT NULL
) RETURNS TABLE (
  total_completed BIGINT,
  ontime_count    BIGINT,
  overdue_count   BIGINT,
  ontime_percent  NUMERIC
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  WITH completed AS (
    SELECT
      hd.id,
      CASE
        WHEN hd.complete_date IS NOT NULL AND hd.end_date IS NOT NULL
             AND hd.complete_date <= hd.end_date THEN TRUE
        ELSE FALSE
      END AS is_ontime
    FROM edoc.handling_docs hd
    WHERE hd.status = 4  -- Hoàn thành
      AND (p_dept_ids IS NULL OR hd.unit_id = ANY(p_dept_ids))
  )
  SELECT
    COUNT(*)::BIGINT AS total_completed,
    COUNT(*) FILTER (WHERE c.is_ontime = TRUE)::BIGINT AS ontime_count,
    COUNT(*) FILTER (WHERE c.is_ontime = FALSE)::BIGINT AS overdue_count,
    CASE
      WHEN COUNT(*) = 0 THEN 0
      ELSE ROUND(COUNT(*) FILTER (WHERE c.is_ontime = TRUE)::NUMERIC / COUNT(*)::NUMERIC * 100, 1)
    END AS ontime_percent
  FROM completed c;
END;
$$;

-- ==========================================
-- 8. VB theo đơn vị/phòng ban (admin) — biểu đồ cột
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_doc_by_department(
  p_dept_ids INT[] DEFAULT NULL
) RETURNS TABLE (
  department_id    INT,
  department_name  VARCHAR,
  incoming_count   BIGINT,
  outgoing_count   BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  WITH depts AS (
    SELECT d.id, d.name
    FROM public.departments d
    WHERE d.is_deleted = FALSE
      AND d.is_unit = FALSE
      AND (p_dept_ids IS NULL OR d.id = ANY(p_dept_ids))
  ),
  inc AS (
    SELECT ind.department_id AS dept_id, COUNT(*) AS cnt
    FROM edoc.incoming_docs ind
    WHERE ind.department_id IS NOT NULL
      AND (p_dept_ids IS NULL OR ind.unit_id = ANY(p_dept_ids))
    GROUP BY ind.department_id
  ),
  outg AS (
    SELECT od.department_id AS dept_id, COUNT(*) AS cnt
    FROM edoc.outgoing_docs od
    WHERE od.department_id IS NOT NULL
      AND (p_dept_ids IS NULL OR od.unit_id = ANY(p_dept_ids))
    GROUP BY od.department_id
  )
  SELECT
    dp.id AS department_id,
    dp.name AS department_name,
    COALESCE(i.cnt, 0) AS incoming_count,
    COALESCE(o.cnt, 0) AS outgoing_count
  FROM depts dp
  LEFT JOIN inc i ON i.dept_id = dp.id
  LEFT JOIN outg o ON o.dept_id = dp.id
  WHERE COALESCE(i.cnt, 0) + COALESCE(o.cnt, 0) > 0
  ORDER BY (COALESCE(i.cnt, 0) + COALESCE(o.cnt, 0)) DESC
  LIMIT 10;
END;
$$;

-- ==========================================
-- Cập nhật fn_dashboard_get_stats: thêm p_dept_ids param
-- (đã được cập nhật trong migration 030, chỉ ghi chú)
-- ==========================================
