-- ================================================================
-- SPRINT 5: HỒ SƠ CÔNG VIỆC — Core Stored Procedures
-- 23 stored functions
-- Tables: edoc.handling_docs, staff_handling_docs, handling_doc_links,
--         opinion_handling_docs, attachment_handling_docs
-- ================================================================

-- ==========================================
-- 5.1 DANH SÁCH HSCV
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_get_list(
  p_unit_id       INT,
  p_department_id INT,
  p_staff_id      INT,
  p_status        INT,
  p_filter_type   TEXT,
  p_keyword       TEXT,
  p_from_date     TIMESTAMPTZ,
  p_to_date       TIMESTAMPTZ,
  p_page          INT DEFAULT 1,
  p_page_size     INT DEFAULT 20
)
RETURNS TABLE (
  id              BIGINT,
  name            VARCHAR,
  start_date      TIMESTAMPTZ,
  end_date        TIMESTAMPTZ,
  status          SMALLINT,
  curator_id      INT,
  curator_name    TEXT,
  signer_id       INT,
  signer_name     TEXT,
  progress        SMALLINT,
  doc_field_name  VARCHAR,
  doc_type_name   VARCHAR,
  created_at      TIMESTAMPTZ,
  total_count     BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT
      h.id,
      h.name,
      h.start_date,
      h.end_date,
      h.status,
      h.curator       AS curator_id,
      CONCAT(sc.last_name, ' ', sc.first_name) AS curator_name,
      h.signer        AS signer_id,
      CONCAT(ss.last_name, ' ', ss.first_name) AS signer_name,
      h.progress,
      df.name         AS doc_field_name,
      dt.name         AS doc_type_name,
      h.created_at
    FROM edoc.handling_docs h
    LEFT JOIN public.staff sc ON sc.id = h.curator
    LEFT JOIN public.staff ss ON ss.id = h.signer
    LEFT JOIN edoc.doc_fields df ON df.id = h.doc_field_id
    LEFT JOIN edoc.doc_types dt ON dt.id = h.doc_type_id
    WHERE
      h.unit_id = p_unit_id
      -- status filter (-1=all statuses)
      AND (p_status IS NULL OR p_status = -99 OR h.status = p_status)
      -- department filter
      AND (p_department_id IS NULL OR h.department_id = p_department_id)
      -- filter_type logic
      AND (
        p_filter_type IS NULL OR p_filter_type = 'all' OR
        (p_filter_type = 'created_by_me'    AND h.created_by = p_staff_id) OR
        (p_filter_type = 'rejected'         AND h.status = -1 AND h.created_by = p_staff_id) OR
        (p_filter_type = 'returned'         AND h.status = -2) OR
        (p_filter_type = 'pending_primary'  AND h.status = 0 AND EXISTS (
          SELECT 1 FROM edoc.staff_handling_docs shd WHERE shd.handling_doc_id = h.id AND shd.staff_id = p_staff_id AND shd.role = 1
        )) OR
        (p_filter_type = 'pending_coord'    AND h.status IN (0, 1) AND EXISTS (
          SELECT 1 FROM edoc.staff_handling_docs shd WHERE shd.handling_doc_id = h.id AND shd.staff_id = p_staff_id AND shd.role = 2
        )) OR
        (p_filter_type = 'submitting'       AND h.status = 2) OR
        (p_filter_type = 'in_progress'      AND h.status = 1) OR
        (p_filter_type = 'proposed_complete' AND h.status = 3) OR
        (p_filter_type = 'completed'        AND h.status = 4)
      )
      -- keyword search
      AND (p_keyword IS NULL OR TRIM(p_keyword) = '' OR h.name ILIKE '%' || p_keyword || '%')
      -- date range
      AND (p_from_date IS NULL OR h.start_date >= p_from_date)
      AND (p_to_date IS NULL OR h.start_date <= p_to_date)
  )
  SELECT
    f.id,
    f.name,
    f.start_date,
    f.end_date,
    f.status,
    f.curator_id,
    f.curator_name,
    f.signer_id,
    f.signer_name,
    f.progress,
    f.doc_field_name,
    f.doc_type_name,
    f.created_at,
    COUNT(*) OVER()::BIGINT AS total_count
  FROM filtered f
  ORDER BY f.created_at DESC
  LIMIT COALESCE(p_page_size, 20)
  OFFSET v_offset;
END;
$$;

-- ==========================================
-- 5.1 ĐẾM HSCV THEO TRẠNG THÁI (sidebar badges)
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_count_by_status(
  p_unit_id   INT,
  p_staff_id  INT
)
RETURNS TABLE (filter_type TEXT, count BIGINT)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 'all'::TEXT,               COUNT(*)::BIGINT FROM edoc.handling_docs WHERE unit_id = p_unit_id
  UNION ALL
  SELECT 'created_by_me'::TEXT,     COUNT(*)::BIGINT FROM edoc.handling_docs WHERE unit_id = p_unit_id AND created_by = p_staff_id
  UNION ALL
  SELECT 'rejected'::TEXT,          COUNT(*)::BIGINT FROM edoc.handling_docs WHERE unit_id = p_unit_id AND status = -1 AND created_by = p_staff_id
  UNION ALL
  SELECT 'returned'::TEXT,          COUNT(*)::BIGINT FROM edoc.handling_docs WHERE unit_id = p_unit_id AND status = -2
  UNION ALL
  SELECT 'pending_primary'::TEXT,   COUNT(*)::BIGINT
    FROM edoc.handling_docs h
    WHERE h.unit_id = p_unit_id AND h.status = 0
      AND EXISTS (SELECT 1 FROM edoc.staff_handling_docs shd WHERE shd.handling_doc_id = h.id AND shd.staff_id = p_staff_id AND shd.role = 1)
  UNION ALL
  SELECT 'pending_coord'::TEXT,     COUNT(*)::BIGINT
    FROM edoc.handling_docs h
    WHERE h.unit_id = p_unit_id AND h.status IN (0, 1)
      AND EXISTS (SELECT 1 FROM edoc.staff_handling_docs shd WHERE shd.handling_doc_id = h.id AND shd.staff_id = p_staff_id AND shd.role = 2)
  UNION ALL
  SELECT 'submitting'::TEXT,        COUNT(*)::BIGINT FROM edoc.handling_docs WHERE unit_id = p_unit_id AND status = 2
  UNION ALL
  SELECT 'in_progress'::TEXT,       COUNT(*)::BIGINT FROM edoc.handling_docs WHERE unit_id = p_unit_id AND status = 1
  UNION ALL
  SELECT 'proposed_complete'::TEXT, COUNT(*)::BIGINT FROM edoc.handling_docs WHERE unit_id = p_unit_id AND status = 3
  UNION ALL
  SELECT 'completed'::TEXT,         COUNT(*)::BIGINT FROM edoc.handling_docs WHERE unit_id = p_unit_id AND status = 4;
END;
$$;

-- ==========================================
-- 5.3 CHI TIẾT HSCV
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_get_by_id(
  p_id BIGINT
)
RETURNS TABLE (
  id              BIGINT,
  unit_id         INT,
  unit_name       VARCHAR,
  department_id   INT,
  department_name VARCHAR,
  name            VARCHAR,
  abstract        TEXT,
  comments        TEXT,
  doc_notation    VARCHAR,
  doc_type_id     INT,
  doc_type_name   VARCHAR,
  doc_field_id    INT,
  doc_field_name  VARCHAR,
  start_date      TIMESTAMPTZ,
  end_date        TIMESTAMPTZ,
  curator_id      INT,
  curator_name    TEXT,
  signer_id       INT,
  signer_name     TEXT,
  status          SMALLINT,
  progress        SMALLINT,
  workflow_id     INT,
  workflow_name   VARCHAR,
  parent_id       BIGINT,
  parent_name     VARCHAR,
  is_from_doc     BOOLEAN,
  created_by      INT,
  created_at      TIMESTAMPTZ,
  updated_at      TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    h.id,
    h.unit_id,
    du.name                                 AS unit_name,
    h.department_id,
    dd.name                                 AS department_name,
    h.name,
    h.abstract,
    h.comments,
    h.doc_notation,
    h.doc_type_id,
    dt.name                                 AS doc_type_name,
    h.doc_field_id,
    df.name                                 AS doc_field_name,
    h.start_date,
    h.end_date,
    h.curator                               AS curator_id,
    CONCAT(sc.last_name, ' ', sc.first_name) AS curator_name,
    h.signer                                AS signer_id,
    CONCAT(ss.last_name, ' ', ss.first_name) AS signer_name,
    h.status,
    h.progress,
    h.workflow_id,
    NULL::VARCHAR                           AS workflow_name,
    h.parent_id,
    hp.name                                 AS parent_name,
    h.is_from_doc,
    h.created_by,
    h.created_at,
    h.updated_at
  FROM edoc.handling_docs h
  LEFT JOIN public.departments du ON du.id = h.unit_id
  LEFT JOIN public.departments dd ON dd.id = h.department_id
  LEFT JOIN edoc.doc_types dt ON dt.id = h.doc_type_id
  LEFT JOIN edoc.doc_fields df ON df.id = h.doc_field_id
  LEFT JOIN public.staff sc ON sc.id = h.curator
  LEFT JOIN public.staff ss ON ss.id = h.signer
  LEFT JOIN edoc.handling_docs hp ON hp.id = h.parent_id
  WHERE h.id = p_id;
END;
$$;

-- ==========================================
-- 5.2 TẠO HSCV
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_create(
  p_unit_id       INT,
  p_department_id INT,
  p_doc_type_id   INT,
  p_doc_field_id  INT,
  p_name          VARCHAR,
  p_comments      TEXT,
  p_start_date    TIMESTAMPTZ,
  p_end_date      TIMESTAMPTZ,
  p_curator_id    INT,
  p_signer_id     INT,
  p_workflow_id   INT,
  p_is_from_doc   BOOLEAN,
  p_parent_id     BIGINT,
  p_created_by    INT
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE v_id BIGINT;
BEGIN
  -- Validate: tên bắt buộc
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên hồ sơ công việc không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  -- Validate: hạn giải quyết >= ngày mở
  IF p_start_date IS NOT NULL AND p_end_date IS NOT NULL AND p_end_date < p_start_date THEN
    RETURN QUERY SELECT FALSE, 'Hạn giải quyết phải sau hoặc bằng ngày mở'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.handling_docs (
    unit_id, department_id, doc_type_id, doc_field_id, name, comments,
    start_date, end_date, curator, signer, workflow_id, is_from_doc,
    parent_id, created_by, updated_by
  ) VALUES (
    p_unit_id, p_department_id, p_doc_type_id, p_doc_field_id,
    TRIM(p_name), NULLIF(TRIM(COALESCE(p_comments, '')), ''),
    COALESCE(p_start_date, NOW()), p_end_date, p_curator_id, p_signer_id,
    p_workflow_id, COALESCE(p_is_from_doc, FALSE), p_parent_id,
    p_created_by, p_created_by
  )
  RETURNING edoc.handling_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tạo hồ sơ công việc thành công'::TEXT, v_id;
END;
$$;

-- ==========================================
-- 5.2 CẬP NHẬT HSCV
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_update(
  p_id            BIGINT,
  p_doc_type_id   INT,
  p_doc_field_id  INT,
  p_name          VARCHAR,
  p_comments      TEXT,
  p_start_date    TIMESTAMPTZ,
  p_end_date      TIMESTAMPTZ,
  p_curator_id    INT,
  p_signer_id     INT,
  p_workflow_id   INT,
  p_updated_by    INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_status SMALLINT;
BEGIN
  -- Validate: tên bắt buộc
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên hồ sơ công việc không được để trống'::TEXT;
    RETURN;
  END IF;

  -- Validate: hạn giải quyết >= ngày mở
  IF p_start_date IS NOT NULL AND p_end_date IS NOT NULL AND p_end_date < p_start_date THEN
    RETURN QUERY SELECT FALSE, 'Hạn giải quyết phải sau hoặc bằng ngày mở'::TEXT;
    RETURN;
  END IF;

  -- Kiểm tra tồn tại và trạng thái
  SELECT status INTO v_status FROM edoc.handling_docs WHERE id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Hồ sơ công việc không tồn tại'::TEXT;
    RETURN;
  END IF;

  -- Chỉ cập nhật khi trạng thái = 0 (Mới)
  IF v_status <> 0 THEN
    RETURN QUERY SELECT FALSE, 'Chỉ được cập nhật hồ sơ công việc ở trạng thái Mới'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.handling_docs SET
    doc_type_id  = p_doc_type_id,
    doc_field_id = p_doc_field_id,
    name         = TRIM(p_name),
    comments     = NULLIF(TRIM(COALESCE(p_comments, '')), ''),
    start_date   = p_start_date,
    end_date     = p_end_date,
    curator      = p_curator_id,
    signer       = p_signer_id,
    workflow_id  = p_workflow_id,
    updated_by   = p_updated_by,
    updated_at   = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Cập nhật hồ sơ công việc thành công'::TEXT;
END;
$$;

-- ==========================================
-- 5.2 XÓA HSCV
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_delete(
  p_id BIGINT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_status SMALLINT;
BEGIN
  SELECT status INTO v_status FROM edoc.handling_docs WHERE id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Hồ sơ công việc không tồn tại'::TEXT;
    RETURN;
  END IF;

  -- Chỉ xóa khi trạng thái = 0 (Mới) — T-02-02 threat mitigation
  IF v_status <> 0 THEN
    RETURN QUERY SELECT FALSE, 'Chỉ được xóa hồ sơ công việc ở trạng thái Mới'::TEXT;
    RETURN;
  END IF;

  DELETE FROM edoc.handling_docs WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa hồ sơ công việc thành công'::TEXT;
END;
$$;

-- ==========================================
-- 5.4 CÁN BỘ XỬ LÝ
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_get_staff(
  p_doc_id BIGINT
)
RETURNS TABLE (
  id              BIGINT,
  staff_id        INT,
  staff_name      TEXT,
  position_name   VARCHAR,
  department_name VARCHAR,
  role            SMALLINT,
  step            VARCHAR,
  assigned_at     TIMESTAMPTZ,
  completed_at    TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    shd.id,
    shd.staff_id,
    CONCAT(s.last_name, ' ', s.first_name)::TEXT AS staff_name,
    p.name                                        AS position_name,
    d.name                                        AS department_name,
    shd.role,
    shd.step,
    shd.assigned_at,
    shd.completed_at
  FROM edoc.staff_handling_docs shd
  JOIN public.staff s ON s.id = shd.staff_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  LEFT JOIN public.departments d ON d.id = s.department_id
  WHERE shd.handling_doc_id = p_doc_id
  ORDER BY shd.role, shd.assigned_at;
END;
$$;

-- ==========================================
-- 5.4 PHÂN CÔNG CÁN BỘ
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_assign_staff(
  p_doc_id      BIGINT,
  p_staff_ids   INT[],
  p_role_type   SMALLINT,
  p_deadline    TIMESTAMPTZ,
  p_assigned_by INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
  v_staff_id INT;
BEGIN
  IF p_staff_ids IS NULL OR ARRAY_LENGTH(p_staff_ids, 1) = 0 THEN
    RETURN QUERY SELECT FALSE, 'Danh sách cán bộ không được để trống'::TEXT;
    RETURN;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM edoc.handling_docs WHERE id = p_doc_id) THEN
    RETURN QUERY SELECT FALSE, 'Hồ sơ công việc không tồn tại'::TEXT;
    RETURN;
  END IF;

  FOREACH v_staff_id IN ARRAY p_staff_ids LOOP
    INSERT INTO edoc.staff_handling_docs (handling_doc_id, staff_id, role, assigned_at)
    VALUES (p_doc_id, v_staff_id, COALESCE(p_role_type, 1), NOW())
    ON CONFLICT DO NOTHING;
  END LOOP;

  RETURN QUERY SELECT TRUE, 'Phân công cán bộ thành công'::TEXT;
END;
$$;

-- ==========================================
-- 5.4 HỦY PHÂN CÔNG CÁN BỘ
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_remove_staff(
  p_doc_id    BIGINT,
  p_staff_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM edoc.staff_handling_docs
  WHERE handling_doc_id = p_doc_id AND staff_id = p_staff_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Cán bộ không có trong danh sách xử lý'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, 'Hủy phân công thành công'::TEXT;
END;
$$;

-- ==========================================
-- 5.5 DANH SÁCH Ý KIẾN
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_opinion_get_list(
  p_doc_id BIGINT
)
RETURNS TABLE (
  id              BIGINT,
  staff_id        INT,
  staff_name      TEXT,
  content         TEXT,
  attachment_path VARCHAR,
  created_at      TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    o.id,
    o.staff_id,
    CONCAT(s.last_name, ' ', s.first_name)::TEXT AS staff_name,
    o.content,
    o.attachment_path,
    o.created_at
  FROM edoc.opinion_handling_docs o
  JOIN public.staff s ON s.id = o.staff_id
  WHERE o.handling_doc_id = p_doc_id
  ORDER BY o.created_at ASC;
END;
$$;

-- ==========================================
-- 5.5 THÊM Ý KIẾN
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_opinion_create(
  p_doc_id        BIGINT,
  p_staff_id      INT,
  p_content       TEXT,
  p_opinion_type  TEXT DEFAULT 'general'
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE v_id BIGINT;
BEGIN
  IF p_content IS NULL OR TRIM(p_content) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nội dung ý kiến không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM edoc.handling_docs WHERE id = p_doc_id) THEN
    RETURN QUERY SELECT FALSE, 'Hồ sơ công việc không tồn tại'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.opinion_handling_docs (handling_doc_id, staff_id, content, created_at)
  VALUES (p_doc_id, p_staff_id, TRIM(p_content), NOW())
  RETURNING edoc.opinion_handling_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Thêm ý kiến thành công'::TEXT, v_id;
END;
$$;

-- ==========================================
-- 5.6 VĂN BẢN LIÊN KẾT
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_get_linked_docs(
  p_id BIGINT
)
RETURNS TABLE (
  link_id       BIGINT,
  doc_id        BIGINT,
  doc_type      VARCHAR,
  doc_number    INT,
  doc_notation  VARCHAR,
  doc_abstract  TEXT,
  doc_date      TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    l.id       AS link_id,
    l.doc_id,
    l.doc_type,
    CASE l.doc_type
      WHEN 'incoming' THEN (SELECT d.number FROM edoc.incoming_docs d WHERE d.id = l.doc_id)
      ELSE NULL
    END        AS doc_number,
    CASE l.doc_type
      WHEN 'incoming' THEN (SELECT d.notation FROM edoc.incoming_docs d WHERE d.id = l.doc_id)
      ELSE NULL
    END        AS doc_notation,
    CASE l.doc_type
      WHEN 'incoming' THEN (SELECT d.abstract FROM edoc.incoming_docs d WHERE d.id = l.doc_id)
      ELSE NULL
    END        AS doc_abstract,
    CASE l.doc_type
      WHEN 'incoming' THEN (SELECT d.received_date FROM edoc.incoming_docs d WHERE d.id = l.doc_id)
      ELSE NULL
    END        AS doc_date
  FROM edoc.handling_doc_links l
  WHERE l.handling_doc_id = p_id
  ORDER BY l.created_at DESC;
END;
$$;

-- ==========================================
-- 5.6 LIÊN KẾT VĂN BẢN
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_link_doc(
  p_handling_doc_id BIGINT,
  p_doc_id          BIGINT,
  p_doc_type        VARCHAR,
  p_linked_by       INT
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE v_id BIGINT;
BEGIN
  IF p_doc_type NOT IN ('incoming', 'outgoing', 'drafting') THEN
    RETURN QUERY SELECT FALSE, 'Loại văn bản không hợp lệ'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  IF EXISTS (
    SELECT 1 FROM edoc.handling_doc_links
    WHERE handling_doc_id = p_handling_doc_id AND doc_id = p_doc_id AND doc_type = p_doc_type
  ) THEN
    RETURN QUERY SELECT FALSE, 'Văn bản này đã được liên kết'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.handling_doc_links (handling_doc_id, doc_type, doc_id)
  VALUES (p_handling_doc_id, p_doc_type, p_doc_id)
  RETURNING edoc.handling_doc_links.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Liên kết văn bản thành công'::TEXT, v_id;
END;
$$;

-- ==========================================
-- 5.6 HỦY LIÊN KẾT VĂN BẢN
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_unlink_doc(
  p_link_id BIGINT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM edoc.handling_doc_links WHERE id = p_link_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Liên kết không tồn tại'::TEXT;
    RETURN;
  END IF;
  RETURN QUERY SELECT TRUE, 'Hủy liên kết thành công'::TEXT;
END;
$$;

-- ==========================================
-- 5.3 FILE ĐÍNH KÈM
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_get_attachments(
  p_doc_id BIGINT
)
RETURNS TABLE (
  id              BIGINT,
  file_name       VARCHAR,
  file_path       VARCHAR,
  file_size       BIGINT,
  content_type    VARCHAR,
  sort_order      INT,
  created_by      INT,
  created_by_name TEXT,
  created_at      TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    a.id,
    a.file_name,
    a.file_path,
    a.file_size,
    a.content_type,
    a.sort_order,
    a.created_by,
    CONCAT(s.last_name, ' ', s.first_name)::TEXT AS created_by_name,
    a.created_at
  FROM edoc.attachment_handling_docs a
  LEFT JOIN public.staff s ON s.id = a.created_by
  WHERE a.handling_doc_id = p_doc_id
  ORDER BY a.sort_order, a.created_at;
END;
$$;

-- ==========================================
-- 5.3 HSCV CON
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_get_children(
  p_id BIGINT
)
RETURNS TABLE (
  id              BIGINT,
  name            VARCHAR,
  start_date      TIMESTAMPTZ,
  end_date        TIMESTAMPTZ,
  status          SMALLINT,
  curator_id      INT,
  curator_name    TEXT,
  signer_id       INT,
  signer_name     TEXT,
  progress        SMALLINT,
  doc_field_name  VARCHAR,
  doc_type_name   VARCHAR,
  created_at      TIMESTAMPTZ,
  total_count     BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    h.id,
    h.name,
    h.start_date,
    h.end_date,
    h.status,
    h.curator                                  AS curator_id,
    CONCAT(sc.last_name, ' ', sc.first_name)   AS curator_name,
    h.signer                                   AS signer_id,
    CONCAT(ss.last_name, ' ', ss.first_name)   AS signer_name,
    h.progress,
    df.name                                    AS doc_field_name,
    dt.name                                    AS doc_type_name,
    h.created_at,
    COUNT(*) OVER()::BIGINT                    AS total_count
  FROM edoc.handling_docs h
  LEFT JOIN public.staff sc ON sc.id = h.curator
  LEFT JOIN public.staff ss ON ss.id = h.signer
  LEFT JOIN edoc.doc_fields df ON df.id = h.doc_field_id
  LEFT JOIN edoc.doc_types dt ON dt.id = h.doc_type_id
  WHERE h.parent_id = p_id
  ORDER BY h.created_at DESC;
END;
$$;

-- ==========================================
-- 5.7 CHUYỂN TRẠNG THÁI CHUNG
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_change_status(
  p_id         BIGINT,
  p_new_status SMALLINT,
  p_changed_by INT,
  p_reason     TEXT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_status SMALLINT;
BEGIN
  SELECT status INTO v_status FROM edoc.handling_docs WHERE id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Hồ sơ công việc không tồn tại'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.handling_docs SET
    status     = p_new_status,
    updated_by = p_changed_by,
    updated_at = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Cập nhật trạng thái thành công'::TEXT;
END;
$$;

-- ==========================================
-- 5.7 TRÌNH KÝ
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_submit(
  p_id           BIGINT,
  p_submitted_by INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_status SMALLINT;
BEGIN
  -- T-02-01: validate current status before transition
  SELECT status INTO v_status FROM edoc.handling_docs WHERE id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Hồ sơ công việc không tồn tại'::TEXT;
    RETURN;
  END IF;

  IF v_status NOT IN (0, 1) THEN
    RETURN QUERY SELECT FALSE, 'Chỉ được trình ký khi hồ sơ ở trạng thái Mới hoặc Đang xử lý'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.handling_docs SET
    status     = 2,  -- Chờ duyệt
    updated_by = p_submitted_by,
    updated_at = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Trình ký thành công'::TEXT;
END;
$$;

-- ==========================================
-- 5.7 DUYỆT
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_approve(
  p_id          BIGINT,
  p_approved_by INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_status SMALLINT;
BEGIN
  -- T-02-01: validate current status before transition
  SELECT status INTO v_status FROM edoc.handling_docs WHERE id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Hồ sơ công việc không tồn tại'::TEXT;
    RETURN;
  END IF;

  IF v_status <> 2 THEN
    RETURN QUERY SELECT FALSE, 'Chỉ được duyệt khi hồ sơ ở trạng thái Chờ duyệt'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.handling_docs SET
    status     = 3,  -- Đã duyệt
    updated_by = p_approved_by,
    updated_at = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Duyệt hồ sơ công việc thành công'::TEXT;
END;
$$;

-- ==========================================
-- 5.7 TỪ CHỐI
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_reject(
  p_id          BIGINT,
  p_rejected_by INT,
  p_reason      TEXT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_status SMALLINT;
BEGIN
  -- T-02-01: validate current status before transition
  IF p_reason IS NULL OR TRIM(p_reason) = '' THEN
    RETURN QUERY SELECT FALSE, 'Lý do từ chối không được để trống'::TEXT;
    RETURN;
  END IF;

  SELECT status INTO v_status FROM edoc.handling_docs WHERE id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Hồ sơ công việc không tồn tại'::TEXT;
    RETURN;
  END IF;

  IF v_status <> 2 THEN
    RETURN QUERY SELECT FALSE, 'Chỉ được từ chối khi hồ sơ ở trạng thái Chờ duyệt'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.handling_docs SET
    status     = -1,  -- Từ chối
    comments   = COALESCE(comments, '') || E'\n[Từ chối] ' || TRIM(p_reason),
    updated_by = p_rejected_by,
    updated_at = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Từ chối hồ sơ công việc thành công'::TEXT;
END;
$$;

-- ==========================================
-- 5.7 TRẢ VỀ
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_return(
  p_id          BIGINT,
  p_returned_by INT,
  p_reason      TEXT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_status SMALLINT;
BEGIN
  -- T-02-01: validate current status before transition
  IF p_reason IS NULL OR TRIM(p_reason) = '' THEN
    RETURN QUERY SELECT FALSE, 'Lý do trả về không được để trống'::TEXT;
    RETURN;
  END IF;

  SELECT status INTO v_status FROM edoc.handling_docs WHERE id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Hồ sơ công việc không tồn tại'::TEXT;
    RETURN;
  END IF;

  IF v_status NOT IN (1, 2) THEN
    RETURN QUERY SELECT FALSE, 'Chỉ được trả về khi hồ sơ ở trạng thái Đang xử lý hoặc Chờ duyệt'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.handling_docs SET
    status     = -2,  -- Trả về
    comments   = COALESCE(comments, '') || E'\n[Trả về] ' || TRIM(p_reason),
    updated_by = p_returned_by,
    updated_at = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Trả về hồ sơ công việc thành công'::TEXT;
END;
$$;

-- ==========================================
-- 5.7 HOÀN THÀNH
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_complete(
  p_id           BIGINT,
  p_completed_by INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_status SMALLINT;
BEGIN
  -- T-02-01: validate current status before transition
  SELECT status INTO v_status FROM edoc.handling_docs WHERE id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Hồ sơ công việc không tồn tại'::TEXT;
    RETURN;
  END IF;

  IF v_status <> 3 THEN
    RETURN QUERY SELECT FALSE, 'Chỉ được hoàn thành khi hồ sơ ở trạng thái Đã duyệt'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.handling_docs SET
    status           = 4,  -- Hoàn thành
    complete_user_id = p_completed_by,
    complete_date    = NOW(),
    progress         = 100,
    updated_by       = p_completed_by,
    updated_at       = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Hoàn thành hồ sơ công việc thành công'::TEXT;
END;
$$;

-- ==========================================
-- 5.7 CẬP NHẬT TIẾN ĐỘ
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_update_progress(
  p_id       BIGINT,
  p_progress SMALLINT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  -- T-02-04: validate progress range 0-100
  IF p_progress < 0 OR p_progress > 100 THEN
    RETURN QUERY SELECT FALSE, 'Tiến độ phải trong khoảng 0-100%'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.handling_docs SET
    progress   = p_progress,
    updated_at = NOW()
  WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Hồ sơ công việc không tồn tại'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, 'Cập nhật tiến độ thành công'::TEXT;
END;
$$;
