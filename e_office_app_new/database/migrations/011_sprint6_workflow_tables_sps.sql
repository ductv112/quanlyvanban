-- ================================================================
-- SPRINT 6: WORKFLOW TABLES + KPI + REPORTS
-- 4 tables + 17 stored functions
-- ================================================================

-- ==========================================
-- TABLES: WORKFLOW
-- ==========================================

-- 1. Quy trình xử lý
CREATE TABLE IF NOT EXISTS edoc.doc_flows (
  id            SERIAL PRIMARY KEY,
  unit_id       INT NOT NULL REFERENCES public.departments(id),
  name          VARCHAR(500) NOT NULL,
  version       VARCHAR(50),
  doc_field_id  INT REFERENCES edoc.doc_fields(id),
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  created_by    INT REFERENCES public.staff(id),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_doc_flows_unit_name_version UNIQUE (unit_id, name, version)
);

CREATE INDEX idx_doc_flows_unit ON edoc.doc_flows(unit_id, is_active);

COMMENT ON TABLE edoc.doc_flows IS 'Quy trình xử lý văn bản / hồ sơ công việc';

-- 2. Bước trong quy trình
CREATE TABLE IF NOT EXISTS edoc.doc_flow_steps (
  id            SERIAL PRIMARY KEY,
  flow_id       INT NOT NULL REFERENCES edoc.doc_flows(id) ON DELETE CASCADE,
  step_name     VARCHAR(500) NOT NULL,
  step_order    INT NOT NULL DEFAULT 0,
  step_type     VARCHAR(50) NOT NULL DEFAULT 'process',  -- 'start', 'process', 'end'
  allow_sign    BOOLEAN NOT NULL DEFAULT FALSE,
  deadline_days INT NOT NULL DEFAULT 0,
  position_x    FLOAT NOT NULL DEFAULT 0,
  position_y    FLOAT NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT chk_doc_flow_steps_type CHECK (step_type IN ('start', 'process', 'end'))
);

CREATE INDEX idx_doc_flow_steps_flow ON edoc.doc_flow_steps(flow_id, step_order);

COMMENT ON TABLE edoc.doc_flow_steps IS 'Các bước trong một quy trình xử lý';

-- 3. Liên kết giữa các bước
CREATE TABLE IF NOT EXISTS edoc.doc_flow_step_links (
  id            SERIAL PRIMARY KEY,
  from_step_id  INT NOT NULL REFERENCES edoc.doc_flow_steps(id) ON DELETE CASCADE,
  to_step_id    INT NOT NULL REFERENCES edoc.doc_flow_steps(id) ON DELETE CASCADE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_doc_flow_step_links UNIQUE (from_step_id, to_step_id)
);

COMMENT ON TABLE edoc.doc_flow_step_links IS 'Liên kết định tuyến giữa các bước quy trình';

-- 4. Cán bộ thực hiện từng bước
CREATE TABLE IF NOT EXISTS edoc.doc_flow_step_staff (
  id         SERIAL PRIMARY KEY,
  step_id    INT NOT NULL REFERENCES edoc.doc_flow_steps(id) ON DELETE CASCADE,
  staff_id   INT NOT NULL REFERENCES public.staff(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_doc_flow_step_staff UNIQUE (step_id, staff_id)
);

CREATE INDEX idx_doc_flow_step_staff_step ON edoc.doc_flow_step_staff(step_id);

COMMENT ON TABLE edoc.doc_flow_step_staff IS 'Cán bộ được giao thực hiện từng bước quy trình';

-- ==========================================
-- TRIGGER: updated_at on doc_flows
-- ==========================================
CREATE TRIGGER trg_doc_flows_updated_at
  BEFORE UPDATE ON edoc.doc_flows
  FOR EACH ROW EXECUTE FUNCTION public.fn_update_timestamp();

-- ==========================================
-- 6.1 DANH SÁCH QUY TRÌNH
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_doc_flow_get_list(
  p_unit_id       INT,
  p_doc_field_id  INT DEFAULT NULL,
  p_is_active     BOOLEAN DEFAULT NULL
)
RETURNS TABLE (
  id              INT,
  name            VARCHAR,
  version         VARCHAR,
  doc_field_id    INT,
  doc_field_name  VARCHAR,
  is_active       BOOLEAN,
  step_count      BIGINT,
  created_at      TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    f.id,
    f.name,
    f.version,
    f.doc_field_id,
    df.name                                  AS doc_field_name,
    f.is_active,
    COUNT(s.id)                              AS step_count,
    f.created_at
  FROM edoc.doc_flows f
  LEFT JOIN edoc.doc_fields df ON df.id = f.doc_field_id
  LEFT JOIN edoc.doc_flow_steps s ON s.flow_id = f.id
  WHERE
    f.unit_id = p_unit_id
    AND (p_doc_field_id IS NULL OR f.doc_field_id = p_doc_field_id)
    AND (p_is_active IS NULL OR f.is_active = p_is_active)
  GROUP BY f.id, f.name, f.version, f.doc_field_id, df.name, f.is_active, f.created_at
  ORDER BY f.name, f.version;
END;
$$;

-- ==========================================
-- 6.1 CHI TIẾT QUY TRÌNH
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_doc_flow_get_by_id(
  p_id INT
)
RETURNS TABLE (
  id              INT,
  unit_id         INT,
  name            VARCHAR,
  version         VARCHAR,
  doc_field_id    INT,
  doc_field_name  VARCHAR,
  is_active       BOOLEAN,
  created_by      INT,
  created_at      TIMESTAMPTZ,
  updated_at      TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    f.id,
    f.unit_id,
    f.name,
    f.version,
    f.doc_field_id,
    df.name  AS doc_field_name,
    f.is_active,
    f.created_by,
    f.created_at,
    f.updated_at
  FROM edoc.doc_flows f
  LEFT JOIN edoc.doc_fields df ON df.id = f.doc_field_id
  WHERE f.id = p_id;
END;
$$;

-- ==========================================
-- 6.1 TẠO QUY TRÌNH
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_doc_flow_create(
  p_unit_id       INT,
  p_name          VARCHAR,
  p_version       VARCHAR,
  p_doc_field_id  INT,
  p_created_by    INT
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql
AS $$
DECLARE v_id INT;
BEGIN
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên quy trình không được để trống'::TEXT, 0::INT;
    RETURN;
  END IF;

  IF EXISTS (
    SELECT 1 FROM edoc.doc_flows
    WHERE unit_id = p_unit_id AND name = TRIM(p_name)
      AND (version = p_version OR (version IS NULL AND p_version IS NULL))
  ) THEN
    RETURN QUERY SELECT FALSE, 'Quy trình với tên và phiên bản này đã tồn tại'::TEXT, 0::INT;
    RETURN;
  END IF;

  INSERT INTO edoc.doc_flows (unit_id, name, version, doc_field_id, is_active, created_by)
  VALUES (p_unit_id, TRIM(p_name), NULLIF(TRIM(COALESCE(p_version, '')), ''), p_doc_field_id, TRUE, p_created_by)
  RETURNING edoc.doc_flows.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tạo quy trình thành công'::TEXT, v_id;
END;
$$;

-- ==========================================
-- 6.1 CẬP NHẬT QUY TRÌNH
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_doc_flow_update(
  p_id            INT,
  p_name          VARCHAR,
  p_version       VARCHAR,
  p_doc_field_id  INT,
  p_is_active     BOOLEAN
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên quy trình không được để trống'::TEXT;
    RETURN;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM edoc.doc_flows WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Quy trình không tồn tại'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.doc_flows SET
    name          = TRIM(p_name),
    version       = NULLIF(TRIM(COALESCE(p_version, '')), ''),
    doc_field_id  = p_doc_field_id,
    is_active     = COALESCE(p_is_active, is_active),
    updated_at    = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Cập nhật quy trình thành công'::TEXT;
END;
$$;

-- ==========================================
-- 6.1 XÓA QUY TRÌNH
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_doc_flow_delete(
  p_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  -- Không xóa nếu đang được sử dụng bởi HSCV
  IF EXISTS (SELECT 1 FROM edoc.handling_docs WHERE workflow_id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không thể xóa quy trình đang được sử dụng bởi hồ sơ công việc'::TEXT;
    RETURN;
  END IF;

  DELETE FROM edoc.doc_flows WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Quy trình không tồn tại'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, 'Xóa quy trình thành công'::TEXT;
END;
$$;

-- ==========================================
-- 6.1 DANH SÁCH BƯỚC QUY TRÌNH
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_doc_flow_step_get_list(
  p_flow_id INT
)
RETURNS TABLE (
  id            INT,
  step_name     VARCHAR,
  step_order    INT,
  step_type     VARCHAR,
  allow_sign    BOOLEAN,
  deadline_days INT,
  position_x    FLOAT,
  position_y    FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.id,
    s.step_name,
    s.step_order,
    s.step_type,
    s.allow_sign,
    s.deadline_days,
    s.position_x,
    s.position_y
  FROM edoc.doc_flow_steps s
  WHERE s.flow_id = p_flow_id
  ORDER BY s.step_order, s.id;
END;
$$;

-- ==========================================
-- 6.1 TẠO BƯỚC QUY TRÌNH
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_doc_flow_step_create(
  p_flow_id     INT,
  p_step_name   VARCHAR,
  p_step_order  INT,
  p_step_type   VARCHAR,
  p_allow_sign  BOOLEAN,
  p_deadline_days INT,
  p_position_x  FLOAT,
  p_position_y  FLOAT
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql
AS $$
DECLARE v_id INT;
BEGIN
  IF p_step_name IS NULL OR TRIM(p_step_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên bước không được để trống'::TEXT, 0::INT;
    RETURN;
  END IF;

  IF p_step_type NOT IN ('start', 'process', 'end') THEN
    RETURN QUERY SELECT FALSE, 'Loại bước không hợp lệ (start/process/end)'::TEXT, 0::INT;
    RETURN;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM edoc.doc_flows WHERE id = p_flow_id) THEN
    RETURN QUERY SELECT FALSE, 'Quy trình không tồn tại'::TEXT, 0::INT;
    RETURN;
  END IF;

  INSERT INTO edoc.doc_flow_steps (
    flow_id, step_name, step_order, step_type,
    allow_sign, deadline_days, position_x, position_y
  ) VALUES (
    p_flow_id, TRIM(p_step_name), COALESCE(p_step_order, 0),
    COALESCE(p_step_type, 'process'), COALESCE(p_allow_sign, FALSE),
    COALESCE(p_deadline_days, 0), COALESCE(p_position_x, 0), COALESCE(p_position_y, 0)
  )
  RETURNING edoc.doc_flow_steps.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tạo bước quy trình thành công'::TEXT, v_id;
END;
$$;

-- ==========================================
-- 6.1 CẬP NHẬT BƯỚC QUY TRÌNH
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_doc_flow_step_update(
  p_step_id     INT,
  p_step_name   VARCHAR,
  p_step_order  INT,
  p_step_type   VARCHAR,
  p_allow_sign  BOOLEAN,
  p_deadline_days INT,
  p_position_x  FLOAT,
  p_position_y  FLOAT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF p_step_name IS NULL OR TRIM(p_step_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên bước không được để trống'::TEXT;
    RETURN;
  END IF;

  IF p_step_type NOT IN ('start', 'process', 'end') THEN
    RETURN QUERY SELECT FALSE, 'Loại bước không hợp lệ (start/process/end)'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.doc_flow_steps SET
    step_name     = TRIM(p_step_name),
    step_order    = COALESCE(p_step_order, step_order),
    step_type     = COALESCE(p_step_type, step_type),
    allow_sign    = COALESCE(p_allow_sign, allow_sign),
    deadline_days = COALESCE(p_deadline_days, deadline_days),
    position_x    = COALESCE(p_position_x, position_x),
    position_y    = COALESCE(p_position_y, position_y)
  WHERE id = p_step_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Bước quy trình không tồn tại'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, 'Cập nhật bước quy trình thành công'::TEXT;
END;
$$;

-- ==========================================
-- 6.1 XÓA BƯỚC QUY TRÌNH
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_doc_flow_step_delete(
  p_step_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM edoc.doc_flow_steps WHERE id = p_step_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Bước quy trình không tồn tại'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, 'Xóa bước quy trình thành công'::TEXT;
END;
$$;

-- ==========================================
-- 6.1 TẠO LIÊN KẾT BƯỚC
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_doc_flow_step_link_create(
  p_from_step_id INT,
  p_to_step_id   INT
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql
AS $$
DECLARE v_id INT;
BEGIN
  IF p_from_step_id = p_to_step_id THEN
    RETURN QUERY SELECT FALSE, 'Không thể tạo liên kết vòng lặp cùng bước'::TEXT, 0::INT;
    RETURN;
  END IF;

  IF EXISTS (
    SELECT 1 FROM edoc.doc_flow_step_links
    WHERE from_step_id = p_from_step_id AND to_step_id = p_to_step_id
  ) THEN
    RETURN QUERY SELECT FALSE, 'Liên kết giữa hai bước này đã tồn tại'::TEXT, 0::INT;
    RETURN;
  END IF;

  INSERT INTO edoc.doc_flow_step_links (from_step_id, to_step_id)
  VALUES (p_from_step_id, p_to_step_id)
  RETURNING edoc.doc_flow_step_links.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tạo liên kết bước thành công'::TEXT, v_id;
END;
$$;

-- ==========================================
-- 6.1 XÓA LIÊN KẾT BƯỚC
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_doc_flow_step_link_delete(
  p_link_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM edoc.doc_flow_step_links WHERE id = p_link_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Liên kết không tồn tại'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, 'Xóa liên kết bước thành công'::TEXT;
END;
$$;

-- ==========================================
-- 6.1 CÁN BỘ THỰC HIỆN BƯỚC
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_doc_flow_step_get_staff(
  p_step_id INT
)
RETURNS TABLE (
  id              INT,
  staff_id        INT,
  staff_name      TEXT,
  position_name   VARCHAR,
  department_name VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    ss.id,
    ss.staff_id,
    CONCAT(s.last_name, ' ', s.first_name)::TEXT AS staff_name,
    p.name                                        AS position_name,
    d.name                                        AS department_name
  FROM edoc.doc_flow_step_staff ss
  JOIN public.staff s ON s.id = ss.staff_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  LEFT JOIN public.departments d ON d.id = s.department_id
  WHERE ss.step_id = p_step_id
  ORDER BY s.last_name, s.first_name;
END;
$$;

-- ==========================================
-- 6.1 GÁN CÁN BỘ CHO BƯỚC (replace all)
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_doc_flow_step_assign_staff(
  p_step_id   INT,
  p_staff_ids INT[]
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_staff_id INT;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.doc_flow_steps WHERE id = p_step_id) THEN
    RETURN QUERY SELECT FALSE, 'Bước quy trình không tồn tại'::TEXT;
    RETURN;
  END IF;

  -- Xóa toàn bộ cán bộ cũ của bước
  DELETE FROM edoc.doc_flow_step_staff WHERE step_id = p_step_id;

  -- Gán mới nếu có danh sách
  IF p_staff_ids IS NOT NULL AND ARRAY_LENGTH(p_staff_ids, 1) > 0 THEN
    FOREACH v_staff_id IN ARRAY p_staff_ids LOOP
      INSERT INTO edoc.doc_flow_step_staff (step_id, staff_id)
      VALUES (p_step_id, v_staff_id)
      ON CONFLICT DO NOTHING;
    END LOOP;
  END IF;

  RETURN QUERY SELECT TRUE, 'Cập nhật cán bộ thực hiện bước thành công'::TEXT;
END;
$$;

-- ==========================================
-- 6.2 KPI TỔNG QUAN HSCV
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_kpi(
  p_unit_id   INT,
  p_from_date TIMESTAMPTZ,
  p_to_date   TIMESTAMPTZ
)
RETURNS TABLE (
  total           BIGINT,
  prev_period     BIGINT,
  current_period  BIGINT,
  completed       BIGINT,
  in_progress     BIGINT,
  overdue         BIGINT,
  overdue_percent NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_total         BIGINT;
  v_prev          BIGINT;
  v_current       BIGINT;
  v_completed     BIGINT;
  v_in_progress   BIGINT;
  v_overdue       BIGINT;
  v_percent       NUMERIC;
BEGIN
  -- Tổng HSCV thuộc đơn vị
  SELECT COUNT(*) INTO v_total
  FROM edoc.handling_docs
  WHERE unit_id = p_unit_id;

  -- Chuyển kỳ trước: tạo trước p_from_date và chưa hoàn thành/từ chối
  SELECT COUNT(*) INTO v_prev
  FROM edoc.handling_docs
  WHERE unit_id = p_unit_id
    AND created_at < p_from_date
    AND status NOT IN (4, -1);

  -- Kỳ này: tạo trong khoảng from-to
  SELECT COUNT(*) INTO v_current
  FROM edoc.handling_docs
  WHERE unit_id = p_unit_id
    AND (p_from_date IS NULL OR created_at >= p_from_date)
    AND (p_to_date IS NULL OR created_at <= p_to_date);

  -- Hoàn thành trong kỳ
  SELECT COUNT(*) INTO v_completed
  FROM edoc.handling_docs
  WHERE unit_id = p_unit_id
    AND status = 4
    AND (p_from_date IS NULL OR complete_date >= p_from_date)
    AND (p_to_date IS NULL OR complete_date <= p_to_date);

  -- Đang thực hiện (kỳ này, chưa hoàn thành)
  SELECT COUNT(*) INTO v_in_progress
  FROM edoc.handling_docs
  WHERE unit_id = p_unit_id
    AND status IN (0, 1, 2, 3)
    AND (p_from_date IS NULL OR created_at >= p_from_date)
    AND (p_to_date IS NULL OR created_at <= p_to_date);

  -- Quá hạn: end_date < NOW() và chưa hoàn thành/từ chối
  SELECT COUNT(*) INTO v_overdue
  FROM edoc.handling_docs
  WHERE unit_id = p_unit_id
    AND end_date < NOW()
    AND status NOT IN (4, -1)
    AND (p_from_date IS NULL OR created_at >= p_from_date)
    AND (p_to_date IS NULL OR created_at <= p_to_date);

  -- % quá hạn
  IF v_current > 0 THEN
    v_percent := ROUND((v_overdue::NUMERIC / v_current::NUMERIC) * 100, 2);
  ELSE
    v_percent := 0;
  END IF;

  RETURN QUERY SELECT v_total, v_prev, v_current, v_completed, v_in_progress, v_overdue, v_percent;
END;
$$;

-- ==========================================
-- 6.3 BÁO CÁO THEO ĐƠN VỊ/PHÒNG BAN
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_report_handling_by_unit(
  p_unit_id   INT,
  p_from_date TIMESTAMPTZ,
  p_to_date   TIMESTAMPTZ
)
RETURNS TABLE (
  department_id   INT,
  department_name TEXT,
  total           BIGINT,
  completed       BIGINT,
  in_progress     BIGINT,
  overdue         BIGINT,
  completion_rate NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    d.id                                                      AS department_id,
    d.name::TEXT                                              AS department_name,
    COUNT(h.id)::BIGINT                                       AS total,
    COUNT(h.id) FILTER (WHERE h.status = 4)::BIGINT           AS completed,
    COUNT(h.id) FILTER (WHERE h.status IN (0,1,2,3))::BIGINT  AS in_progress,
    COUNT(h.id) FILTER (
      WHERE h.end_date < NOW() AND h.status NOT IN (4, -1)
    )::BIGINT                                                  AS overdue,
    CASE
      WHEN COUNT(h.id) > 0
      THEN ROUND(COUNT(h.id) FILTER (WHERE h.status = 4)::NUMERIC / COUNT(h.id)::NUMERIC * 100, 2)
      ELSE 0
    END                                                        AS completion_rate
  FROM public.departments d
  LEFT JOIN edoc.handling_docs h ON h.department_id = d.id
    AND h.unit_id = p_unit_id
    AND (p_from_date IS NULL OR h.created_at >= p_from_date)
    AND (p_to_date IS NULL OR h.created_at <= p_to_date)
  WHERE d.parent_id = p_unit_id AND d.is_unit = FALSE AND d.is_deleted = FALSE
  GROUP BY d.id, d.name
  ORDER BY total DESC, d.name;
END;
$$;

-- ==========================================
-- 6.3 BÁO CÁO THEO CÁN BỘ GIẢI QUYẾT (curator)
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_report_handling_by_resolver(
  p_unit_id   INT,
  p_from_date TIMESTAMPTZ,
  p_to_date   TIMESTAMPTZ
)
RETURNS TABLE (
  staff_id        INT,
  staff_name      TEXT,
  department_name TEXT,
  total           BIGINT,
  completed       BIGINT,
  in_progress     BIGINT,
  overdue         BIGINT,
  completion_rate NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.id                                                                   AS staff_id,
    CONCAT(s.last_name, ' ', s.first_name)::TEXT                          AS staff_name,
    d.name::TEXT                                                           AS department_name,
    COUNT(h.id)::BIGINT                                                    AS total,
    COUNT(h.id) FILTER (WHERE h.status = 4)::BIGINT                        AS completed,
    COUNT(h.id) FILTER (WHERE h.status IN (0,1,2,3))::BIGINT               AS in_progress,
    COUNT(h.id) FILTER (
      WHERE h.end_date < NOW() AND h.status NOT IN (4, -1)
    )::BIGINT                                                               AS overdue,
    CASE
      WHEN COUNT(h.id) > 0
      THEN ROUND(COUNT(h.id) FILTER (WHERE h.status = 4)::NUMERIC / COUNT(h.id)::NUMERIC * 100, 2)
      ELSE 0
    END                                                                     AS completion_rate
  FROM public.staff s
  LEFT JOIN public.departments d ON d.id = s.department_id
  LEFT JOIN edoc.handling_docs h ON h.curator = s.id
    AND h.unit_id = p_unit_id
    AND (p_from_date IS NULL OR h.created_at >= p_from_date)
    AND (p_to_date IS NULL OR h.created_at <= p_to_date)
  WHERE s.unit_id = p_unit_id AND s.is_locked = FALSE
  GROUP BY s.id, s.last_name, s.first_name, d.name
  HAVING COUNT(h.id) > 0
  ORDER BY total DESC, s.last_name;
END;
$$;

-- ==========================================
-- 6.3 BÁO CÁO THEO NGƯỜI GIAO VIỆC (created_by)
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_report_handling_by_assigner(
  p_unit_id   INT,
  p_from_date TIMESTAMPTZ,
  p_to_date   TIMESTAMPTZ
)
RETURNS TABLE (
  staff_id        INT,
  staff_name      TEXT,
  department_name TEXT,
  total           BIGINT,
  completed       BIGINT,
  in_progress     BIGINT,
  overdue         BIGINT,
  completion_rate NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.id                                                                   AS staff_id,
    CONCAT(s.last_name, ' ', s.first_name)::TEXT                          AS staff_name,
    d.name::TEXT                                                           AS department_name,
    COUNT(h.id)::BIGINT                                                    AS total,
    COUNT(h.id) FILTER (WHERE h.status = 4)::BIGINT                        AS completed,
    COUNT(h.id) FILTER (WHERE h.status IN (0,1,2,3))::BIGINT               AS in_progress,
    COUNT(h.id) FILTER (
      WHERE h.end_date < NOW() AND h.status NOT IN (4, -1)
    )::BIGINT                                                               AS overdue,
    CASE
      WHEN COUNT(h.id) > 0
      THEN ROUND(COUNT(h.id) FILTER (WHERE h.status = 4)::NUMERIC / COUNT(h.id)::NUMERIC * 100, 2)
      ELSE 0
    END                                                                     AS completion_rate
  FROM public.staff s
  LEFT JOIN public.departments d ON d.id = s.department_id
  LEFT JOIN edoc.handling_docs h ON h.created_by = s.id
    AND h.unit_id = p_unit_id
    AND (p_from_date IS NULL OR h.created_at >= p_from_date)
    AND (p_to_date IS NULL OR h.created_at <= p_to_date)
  WHERE s.unit_id = p_unit_id AND s.is_locked = FALSE
  GROUP BY s.id, s.last_name, s.first_name, d.name
  HAVING COUNT(h.id) > 0
  ORDER BY total DESC, s.last_name;
END;
$$;
