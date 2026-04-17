-- ================================================================
-- MIGRATION 014: Sprint 9 — Lịch (Calendar) & Danh bạ (Directory)
-- Tables: public.calendar_events
-- Functions: fn_calendar_event_get_list, fn_calendar_event_get_by_id,
--            fn_calendar_event_create, fn_calendar_event_update,
--            fn_calendar_event_delete, fn_directory_get_list
-- ================================================================

-- ==========================================
-- 1. BẢNG SỰ KIỆN LỊCH (calendar_events)
-- ==========================================
CREATE TABLE IF NOT EXISTS public.calendar_events (
  id          BIGSERIAL PRIMARY KEY,
  title       VARCHAR(300) NOT NULL,
  description TEXT,
  start_time  TIMESTAMP NOT NULL,
  end_time    TIMESTAMP NOT NULL,
  all_day     BOOLEAN DEFAULT FALSE,
  color       VARCHAR(20) DEFAULT '#1B3A5C',
  repeat_type VARCHAR(20) DEFAULT 'none' CHECK (repeat_type IN ('none', 'daily', 'weekly', 'monthly')),
  scope       VARCHAR(20) DEFAULT 'personal' CHECK (scope IN ('personal', 'unit', 'leader')),
  unit_id     INT REFERENCES public.departments(id),
  created_by  INT NOT NULL REFERENCES public.staff(id),
  created_at  TIMESTAMP DEFAULT NOW(),
  updated_at  TIMESTAMP DEFAULT NOW(),
  is_deleted  BOOLEAN DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_calendar_events_scope_unit_start ON public.calendar_events(scope, unit_id, start_time);
CREATE INDEX IF NOT EXISTS idx_calendar_events_created_by_start ON public.calendar_events(created_by, start_time);
CREATE INDEX IF NOT EXISTS idx_calendar_events_is_deleted ON public.calendar_events(is_deleted);

COMMENT ON TABLE public.calendar_events IS 'Sự kiện lịch — scope: personal (cá nhân), unit (cơ quan), leader (lãnh đạo)';

-- ==========================================
-- 2. FN: Lấy danh sách sự kiện lịch
-- ==========================================
CREATE OR REPLACE FUNCTION public.fn_calendar_event_get_list(
  p_scope      VARCHAR,
  p_unit_id    INT,
  p_staff_id   INT,
  p_start      TIMESTAMP,
  p_end        TIMESTAMP
) RETURNS TABLE (
  id           BIGINT,
  title        VARCHAR,
  description  TEXT,
  start_time   TIMESTAMP,
  end_time     TIMESTAMP,
  all_day      BOOLEAN,
  color        VARCHAR,
  repeat_type  VARCHAR,
  scope        VARCHAR,
  unit_id      INT,
  created_by   INT,
  creator_name VARCHAR,
  created_at   TIMESTAMP,
  updated_at   TIMESTAMP
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    ce.id,
    ce.title,
    ce.description,
    ce.start_time,
    ce.end_time,
    ce.all_day,
    ce.color,
    ce.repeat_type,
    ce.scope,
    ce.unit_id,
    ce.created_by,
    (s.last_name || ' ' || s.first_name)::VARCHAR AS creator_name,
    ce.created_at,
    ce.updated_at
  FROM public.calendar_events ce
  LEFT JOIN public.staff s ON s.id = ce.created_by
  WHERE ce.is_deleted = FALSE
    AND ce.scope = p_scope
    AND (
      CASE
        WHEN p_scope = 'personal' THEN ce.created_by = p_staff_id
        ELSE ce.unit_id = p_unit_id
      END
    )
    AND ce.start_time >= p_start
    AND ce.start_time <= p_end
  ORDER BY ce.start_time ASC;
END;
$$;

-- ==========================================
-- 3. FN: Lấy chi tiết sự kiện lịch theo ID
-- ==========================================
CREATE OR REPLACE FUNCTION public.fn_calendar_event_get_by_id(
  p_id BIGINT
) RETURNS TABLE (
  id           BIGINT,
  title        VARCHAR,
  description  TEXT,
  start_time   TIMESTAMP,
  end_time     TIMESTAMP,
  all_day      BOOLEAN,
  color        VARCHAR,
  repeat_type  VARCHAR,
  scope        VARCHAR,
  unit_id      INT,
  created_by   INT,
  creator_name VARCHAR,
  created_at   TIMESTAMP,
  updated_at   TIMESTAMP
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    ce.id,
    ce.title,
    ce.description,
    ce.start_time,
    ce.end_time,
    ce.all_day,
    ce.color,
    ce.repeat_type,
    ce.scope,
    ce.unit_id,
    ce.created_by,
    (s.last_name || ' ' || s.first_name)::VARCHAR AS creator_name,
    ce.created_at,
    ce.updated_at
  FROM public.calendar_events ce
  LEFT JOIN public.staff s ON s.id = ce.created_by
  WHERE ce.id = p_id
    AND ce.is_deleted = FALSE;
END;
$$;

-- ==========================================
-- 4. FN: Tạo sự kiện lịch mới
-- ==========================================
CREATE OR REPLACE FUNCTION public.fn_calendar_event_create(
  p_title       VARCHAR,
  p_description TEXT,
  p_start_time  TIMESTAMP,
  p_end_time    TIMESTAMP,
  p_all_day     BOOLEAN,
  p_color       VARCHAR,
  p_repeat_type VARCHAR,
  p_scope       VARCHAR,
  p_unit_id     INT,
  p_created_by  INT
) RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_new_id BIGINT;
BEGIN
  -- Validate title
  IF p_title IS NULL OR TRIM(p_title) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tiêu đề sự kiện là bắt buộc'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;
  -- Validate times
  IF p_end_time < p_start_time THEN
    RETURN QUERY SELECT FALSE, 'Thời gian kết thúc phải sau thời gian bắt đầu'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;
  -- Validate scope
  IF p_scope NOT IN ('personal', 'unit', 'leader') THEN
    RETURN QUERY SELECT FALSE, 'Phạm vi sự kiện không hợp lệ'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  INSERT INTO public.calendar_events (
    title, description, start_time, end_time, all_day,
    color, repeat_type, scope, unit_id, created_by
  ) VALUES (
    TRIM(p_title), p_description,
    p_start_time, p_end_time, COALESCE(p_all_day, FALSE),
    COALESCE(p_color, '#1B3A5C'), COALESCE(p_repeat_type, 'none'),
    p_scope, p_unit_id, p_created_by
  ) RETURNING calendar_events.id INTO v_new_id;

  RETURN QUERY SELECT TRUE, 'Tạo sự kiện thành công'::TEXT, v_new_id;
END;
$$;

-- ==========================================
-- 5. FN: Cập nhật sự kiện lịch
-- ==========================================
CREATE OR REPLACE FUNCTION public.fn_calendar_event_update(
  p_id          BIGINT,
  p_title       VARCHAR,
  p_description TEXT,
  p_start_time  TIMESTAMP,
  p_end_time    TIMESTAMP,
  p_all_day     BOOLEAN,
  p_color       VARCHAR,
  p_repeat_type VARCHAR,
  p_scope       VARCHAR,
  p_unit_id     INT,
  p_staff_id    INT
) RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_event public.calendar_events%ROWTYPE;
BEGIN
  SELECT * INTO v_event FROM public.calendar_events WHERE id = p_id AND is_deleted = FALSE;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy sự kiện'::TEXT;
    RETURN;
  END IF;
  -- Ownership check for personal scope
  IF v_event.scope = 'personal' AND v_event.created_by != p_staff_id THEN
    RETURN QUERY SELECT FALSE, 'Bạn không có quyền chỉnh sửa sự kiện này'::TEXT;
    RETURN;
  END IF;
  -- Validate times
  IF p_end_time < p_start_time THEN
    RETURN QUERY SELECT FALSE, 'Thời gian kết thúc phải sau thời gian bắt đầu'::TEXT;
    RETURN;
  END IF;

  UPDATE public.calendar_events SET
    title       = TRIM(p_title),
    description = p_description,
    start_time  = p_start_time,
    end_time    = p_end_time,
    all_day     = COALESCE(p_all_day, FALSE),
    color       = COALESCE(p_color, '#1B3A5C'),
    repeat_type = COALESCE(p_repeat_type, 'none'),
    scope       = p_scope,
    unit_id     = p_unit_id,
    updated_at  = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Cập nhật sự kiện thành công'::TEXT;
END;
$$;

-- ==========================================
-- 6. FN: Xóa mềm sự kiện lịch
-- ==========================================
CREATE OR REPLACE FUNCTION public.fn_calendar_event_delete(
  p_id       BIGINT,
  p_staff_id INT
) RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_event public.calendar_events%ROWTYPE;
BEGIN
  SELECT * INTO v_event FROM public.calendar_events WHERE id = p_id AND is_deleted = FALSE;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy sự kiện'::TEXT;
    RETURN;
  END IF;
  -- Ownership check for personal scope
  IF v_event.scope = 'personal' AND v_event.created_by != p_staff_id THEN
    RETURN QUERY SELECT FALSE, 'Bạn không có quyền xóa sự kiện này'::TEXT;
    RETURN;
  END IF;

  UPDATE public.calendar_events SET is_deleted = TRUE, updated_at = NOW() WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa sự kiện thành công'::TEXT;
END;
$$;

-- ==========================================
-- 7. FN: Danh bạ nhân viên (phân trang)
-- ==========================================
CREATE OR REPLACE FUNCTION public.fn_directory_get_list(
  p_unit_id       INT,
  p_department_id INT,
  p_search        VARCHAR,
  p_page          INT,
  p_page_size     INT
) RETURNS TABLE (
  id              INT,
  full_name       VARCHAR,
  position_name   VARCHAR,
  department_name VARCHAR,
  unit_name       VARCHAR,
  phone           VARCHAR,
  mobile          VARCHAR,
  email           VARCHAR,
  image           VARCHAR,
  total_count     BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
  v_limit  INT := COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  SELECT
    s.id,
    (s.last_name || ' ' || s.first_name)::VARCHAR AS full_name,
    pos.name::VARCHAR AS position_name,
    dep.name::VARCHAR AS department_name,
    unit.name::VARCHAR AS unit_name,
    s.phone,
    s.mobile,
    s.email,
    s.image,
    COUNT(*) OVER() AS total_count
  FROM public.staff s
  LEFT JOIN public.positions pos ON pos.id = s.position_id
  LEFT JOIN public.departments dep ON dep.id = s.department_id
  LEFT JOIN public.departments unit ON unit.id = s.unit_id
  WHERE s.is_locked = FALSE
    AND s.is_deleted = FALSE
    AND (p_unit_id IS NULL OR s.unit_id = p_unit_id)
    AND (p_department_id IS NULL OR s.department_id = p_department_id)
    AND (
      p_search IS NULL OR TRIM(p_search) = '' OR
      (s.last_name || ' ' || s.first_name) ILIKE '%' || TRIM(p_search) || '%' OR
      s.phone ILIKE '%' || TRIM(p_search) || '%' OR
      s.mobile ILIKE '%' || TRIM(p_search) || '%' OR
      s.email ILIKE '%' || TRIM(p_search) || '%'
    )
  ORDER BY s.last_name ASC, s.first_name ASC
  OFFSET v_offset
  LIMIT v_limit;
END;
$$;
