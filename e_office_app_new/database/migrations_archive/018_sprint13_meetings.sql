-- ================================================================
-- MIGRATION 018: Sprint 13 — Họp không giấy (Meetings)
-- Schema: edoc
-- Tables: edoc.rooms, edoc.meeting_types, edoc.room_schedules,
--         edoc.room_schedule_staff, edoc.room_schedule_attachments,
--         edoc.room_schedule_questions, edoc.room_schedule_answers,
--         edoc.room_schedule_votes
-- Functions: ~28 stored functions
-- ================================================================

-- ==========================================
-- 1. BẢNG PHÒNG HỌP (rooms)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.rooms (
  id                SERIAL PRIMARY KEY,
  unit_id           INT NOT NULL,
  name              VARCHAR(200) NOT NULL,
  code              VARCHAR(50),
  location          VARCHAR(500),
  note              TEXT,
  sort_order        INT DEFAULT 0,
  show_in_calendar  BOOLEAN DEFAULT true,
  is_deleted        BOOLEAN DEFAULT false,
  created_user_id   INT NOT NULL,
  created_date      TIMESTAMPTZ DEFAULT NOW(),
  modified_user_id  INT,
  modified_date     TIMESTAMPTZ
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_rooms_code ON edoc.rooms(unit_id, code)
  WHERE code IS NOT NULL AND is_deleted = false;

COMMENT ON TABLE edoc.rooms IS 'Phòng họp — ánh xạ từ Room.cs';

-- ==========================================
-- 2. BẢNG LOẠI CUỘC HỌP (meeting_types)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.meeting_types (
  id                SERIAL PRIMARY KEY,
  unit_id           INT NOT NULL,
  name              VARCHAR(200) NOT NULL,
  description       TEXT,
  sort_order        INT DEFAULT 0,
  is_deleted        BOOLEAN DEFAULT false,
  created_user_id   INT NOT NULL,
  created_date      TIMESTAMPTZ DEFAULT NOW(),
  modified_user_id  INT,
  modified_date     TIMESTAMPTZ
);

COMMENT ON TABLE edoc.meeting_types IS 'Loại cuộc họp — ánh xạ từ RoomGroups.cs';

-- ==========================================
-- 3. BẢNG CUỘC HỌP (room_schedules)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.room_schedules (
  id                  SERIAL PRIMARY KEY,
  unit_id             INT NOT NULL,
  room_id             INT NOT NULL REFERENCES edoc.rooms(id),
  meeting_type_id     INT REFERENCES edoc.meeting_types(id),
  name                VARCHAR(500) NOT NULL,
  content             TEXT,
  component           VARCHAR(500),
  start_date          DATE NOT NULL,
  end_date            DATE,
  start_time          VARCHAR(10),
  end_time            VARCHAR(10),
  master_id           INT,
  -- chủ tọa (staff_id)
  secretary_id        INT,
  approved            INT DEFAULT 0,
  -- 0=Chưa duyệt, 1=Đã duyệt, -1=Từ chối
  approved_date       TIMESTAMPTZ,
  approved_staff_id   INT,
  rejection_reason    TEXT,
  meeting_status      INT DEFAULT 0,
  -- 0=Chưa họp, 1=Đang họp, 2=Đã họp, 3=Hủy
  online_link         VARCHAR(500),
  is_cancel           INT DEFAULT 0,
  created_user_id     INT NOT NULL,
  created_date        TIMESTAMPTZ DEFAULT NOW(),
  modified_user_id    INT,
  modified_date       TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_room_schedules_unit_id ON edoc.room_schedules(unit_id);
CREATE INDEX IF NOT EXISTS idx_room_schedules_room_id ON edoc.room_schedules(room_id);
CREATE INDEX IF NOT EXISTS idx_room_schedules_start_date ON edoc.room_schedules(start_date);

COMMENT ON TABLE edoc.room_schedules IS 'Lịch họp / cuộc họp — ánh xạ từ RoomSchedule.cs';

-- ==========================================
-- 4. BẢNG THÀNH VIÊN HỌP (room_schedule_staff)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.room_schedule_staff (
  id                          SERIAL PRIMARY KEY,
  room_schedule_id            INT NOT NULL REFERENCES edoc.room_schedules(id) ON DELETE CASCADE,
  staff_id                    INT NOT NULL,
  user_type                   INT DEFAULT 0,
  -- 0=Thành viên, 1=Chủ tọa, 2=Thư ký
  is_secretary                BOOLEAN DEFAULT false,
  is_represent                BOOLEAN DEFAULT false,
  attendance                  BOOLEAN DEFAULT false,
  attendance_date             TIMESTAMPTZ,
  attendance_note             TEXT,
  received_appointment        INT DEFAULT 0,
  received_appointment_date   TIMESTAMPTZ,
  view_date                   TIMESTAMPTZ,
  UNIQUE(room_schedule_id, staff_id)
);

COMMENT ON TABLE edoc.room_schedule_staff IS 'Thành viên cuộc họp — ánh xạ từ RoomScheduleStaff.cs';

-- ==========================================
-- 5. BẢNG TÀI LIỆU HỌP (room_schedule_attachments)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.room_schedule_attachments (
  id                BIGSERIAL PRIMARY KEY,
  room_schedule_id  INT NOT NULL REFERENCES edoc.room_schedules(id) ON DELETE CASCADE,
  file_name         VARCHAR(500) NOT NULL,
  file_path         VARCHAR(1000) NOT NULL,
  file_size         BIGINT,
  mime_type         VARCHAR(200),
  description       TEXT,
  created_user_id   INT NOT NULL,
  created_date      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE edoc.room_schedule_attachments IS 'Tài liệu đính kèm cuộc họp';

-- ==========================================
-- 6. BẢNG CÂU HỎI BIỂU QUYẾT (room_schedule_questions)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.room_schedule_questions (
  id                UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  room_schedule_id  INT NOT NULL REFERENCES edoc.room_schedules(id) ON DELETE CASCADE,
  name              VARCHAR(500) NOT NULL,
  start_time        TIMESTAMPTZ,
  stop_time         TIMESTAMPTZ,
  duration          INT DEFAULT 60,
  -- giây
  status            INT DEFAULT 0,
  -- 0=Chưa bắt đầu, 1=Đang biểu quyết, 2=Kết thúc
  question_type     INT DEFAULT 0,
  -- 0=Một lựa chọn, 1=Nhiều lựa chọn
  order_no          INT DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_questions_room_schedule_id ON edoc.room_schedule_questions(room_schedule_id);

COMMENT ON TABLE edoc.room_schedule_questions IS 'Câu hỏi biểu quyết — ánh xạ từ RoomScheduleQuestion.cs';

-- ==========================================
-- 7. BẢNG ĐÁP ÁN BIỂU QUYẾT (room_schedule_answers)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.room_schedule_answers (
  id                        UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  room_schedule_id          INT NOT NULL,
  room_schedule_question_id UUID NOT NULL REFERENCES edoc.room_schedule_questions(id) ON DELETE CASCADE,
  name                      VARCHAR(500) NOT NULL,
  order_no                  INT DEFAULT 0,
  is_other                  BOOLEAN DEFAULT false
);

COMMENT ON TABLE edoc.room_schedule_answers IS 'Đáp án biểu quyết — ánh xạ từ RoomScheduleAnswer.cs';

-- ==========================================
-- 8. BẢNG KẾT QUẢ BIỂU QUYẾT (room_schedule_votes)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.room_schedule_votes (
  id                BIGSERIAL PRIMARY KEY,
  room_schedule_id  INT NOT NULL,
  question_id       UUID NOT NULL REFERENCES edoc.room_schedule_questions(id) ON DELETE CASCADE,
  answer_id         UUID NOT NULL REFERENCES edoc.room_schedule_answers(id) ON DELETE CASCADE,
  staff_id          INT NOT NULL,
  other_text        TEXT,
  voted_at          TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(question_id, staff_id)
  -- single-choice default: 1 vote per staff per question
);

COMMENT ON TABLE edoc.room_schedule_votes IS 'Kết quả biểu quyết realtime — T-05-03: unique(question_id, staff_id)';

-- ==========================================
-- STORED FUNCTIONS — ROOMS (PHÒNG HỌP)
-- ==========================================

-- 1. Danh sách phòng họp
CREATE OR REPLACE FUNCTION edoc.fn_room_get_list(
  p_unit_id INT
)
RETURNS TABLE (
  id                INT,
  unit_id           INT,
  name              VARCHAR,
  code              VARCHAR,
  location          VARCHAR,
  note              TEXT,
  sort_order        INT,
  show_in_calendar  BOOLEAN,
  created_date      TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    r.id, r.unit_id, r.name, r.code, r.location, r.note,
    r.sort_order, r.show_in_calendar, r.created_date
  FROM edoc.rooms r
  WHERE r.unit_id = p_unit_id AND r.is_deleted = false
  ORDER BY r.sort_order, r.name;
END;
$$;

-- 2. Tạo phòng họp
CREATE OR REPLACE FUNCTION edoc.fn_room_create(
  p_unit_id          INT,
  p_name             VARCHAR,
  p_code             VARCHAR,
  p_location         VARCHAR,
  p_note             TEXT,
  p_sort_order       INT,
  p_show_in_calendar BOOLEAN,
  p_created_user_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id INT;
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên phòng họp không được để trống'::TEXT, NULL::INT;
    RETURN;
  END IF;

  INSERT INTO edoc.rooms (unit_id, name, code, location, note, sort_order, show_in_calendar, created_user_id)
  VALUES (p_unit_id, p_name, NULLIF(TRIM(p_code),''), p_location, p_note,
          COALESCE(p_sort_order, 0), COALESCE(p_show_in_calendar, true), p_created_user_id)
  RETURNING edoc.rooms.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo phòng họp thành công'::TEXT, v_id;
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, 'Mã phòng họp đã tồn tại'::TEXT, NULL::INT;
END;
$$;

-- 3. Cập nhật phòng họp
CREATE OR REPLACE FUNCTION edoc.fn_room_update(
  p_id               INT,
  p_name             VARCHAR,
  p_code             VARCHAR,
  p_location         VARCHAR,
  p_note             TEXT,
  p_sort_order       INT,
  p_show_in_calendar BOOLEAN,
  p_modified_user_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên phòng họp không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.rooms SET
    name             = p_name,
    code             = NULLIF(TRIM(p_code),''),
    location         = p_location,
    note             = p_note,
    sort_order       = COALESCE(p_sort_order, 0),
    show_in_calendar = COALESCE(p_show_in_calendar, true),
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id AND is_deleted = false;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy phòng họp'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cập nhật thành công'::TEXT;
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, 'Mã phòng họp đã tồn tại'::TEXT;
END;
$$;

-- 4. Xóa phòng họp (kiểm tra lịch họp)
CREATE OR REPLACE FUNCTION edoc.fn_room_delete(
  p_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM edoc.room_schedules WHERE room_id = p_id;
  IF v_count > 0 THEN
    RETURN QUERY SELECT false, 'Phòng họp đang có lịch họp, không thể xóa'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.rooms SET is_deleted = true WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy phòng họp'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Xóa phòng họp thành công'::TEXT;
END;
$$;

-- ==========================================
-- STORED FUNCTIONS — MEETING TYPES
-- ==========================================

-- 5. Danh sách loại cuộc họp
CREATE OR REPLACE FUNCTION edoc.fn_meeting_type_get_list(
  p_unit_id INT
)
RETURNS TABLE (
  id            INT,
  unit_id       INT,
  name          VARCHAR,
  description   TEXT,
  sort_order    INT,
  created_date  TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    mt.id, mt.unit_id, mt.name, mt.description, mt.sort_order, mt.created_date
  FROM edoc.meeting_types mt
  WHERE mt.unit_id = p_unit_id AND mt.is_deleted = false
  ORDER BY mt.sort_order, mt.name;
END;
$$;

-- 6. Tạo loại cuộc họp
CREATE OR REPLACE FUNCTION edoc.fn_meeting_type_create(
  p_unit_id          INT,
  p_name             VARCHAR,
  p_description      TEXT,
  p_sort_order       INT,
  p_created_user_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id INT;
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên loại cuộc họp không được để trống'::TEXT, NULL::INT;
    RETURN;
  END IF;

  INSERT INTO edoc.meeting_types (unit_id, name, description, sort_order, created_user_id)
  VALUES (p_unit_id, p_name, p_description, COALESCE(p_sort_order, 0), p_created_user_id)
  RETURNING edoc.meeting_types.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo loại cuộc họp thành công'::TEXT, v_id;
END;
$$;

-- 7. Cập nhật loại cuộc họp
CREATE OR REPLACE FUNCTION edoc.fn_meeting_type_update(
  p_id               INT,
  p_name             VARCHAR,
  p_description      TEXT,
  p_sort_order       INT,
  p_modified_user_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên loại cuộc họp không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.meeting_types SET
    name             = p_name,
    description      = p_description,
    sort_order       = COALESCE(p_sort_order, 0),
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id AND is_deleted = false;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy loại cuộc họp'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cập nhật thành công'::TEXT;
END;
$$;

-- 8. Xóa loại cuộc họp (soft delete)
CREATE OR REPLACE FUNCTION edoc.fn_meeting_type_delete(
  p_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE edoc.meeting_types SET is_deleted = true WHERE id = p_id AND is_deleted = false;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy loại cuộc họp'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Xóa loại cuộc họp thành công'::TEXT;
END;
$$;

-- ==========================================
-- STORED FUNCTIONS — ROOM SCHEDULES (CUỘC HỌP)
-- ==========================================

-- 9. Danh sách cuộc họp (phân trang)
CREATE OR REPLACE FUNCTION edoc.fn_room_schedule_get_list(
  p_unit_id      INT,
  p_room_id      INT,
  p_status       INT,
  p_from_date    DATE,
  p_to_date      DATE,
  p_keyword      TEXT,
  p_page         INT DEFAULT 1,
  p_page_size    INT DEFAULT 20
)
RETURNS TABLE (
  id                INT,
  unit_id           INT,
  room_id           INT,
  room_name         VARCHAR,
  meeting_type_id   INT,
  meeting_type_name VARCHAR,
  name              VARCHAR,
  content           TEXT,
  start_date        DATE,
  end_date          DATE,
  start_time        VARCHAR,
  end_time          VARCHAR,
  master_id         INT,
  master_name       TEXT,
  approved          INT,
  meeting_status    INT,
  online_link       VARCHAR,
  created_date      TIMESTAMPTZ,
  staff_count       BIGINT,
  total_count       BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT
      rs.id,
      rs.unit_id,
      rs.room_id,
      r.name AS room_name,
      rs.meeting_type_id,
      mt.name AS meeting_type_name,
      rs.name,
      rs.content,
      rs.start_date,
      rs.end_date,
      rs.start_time,
      rs.end_time,
      rs.master_id,
      (s.last_name || ' ' || s.first_name)::TEXT AS master_name,
      rs.approved,
      rs.meeting_status,
      rs.online_link,
      rs.created_date,
      (SELECT COUNT(*) FROM edoc.room_schedule_staff rss WHERE rss.room_schedule_id = rs.id) AS staff_count
    FROM edoc.room_schedules rs
    LEFT JOIN edoc.rooms r ON r.id = rs.room_id
    LEFT JOIN edoc.meeting_types mt ON mt.id = rs.meeting_type_id
    LEFT JOIN public.staff s ON s.id = rs.master_id
    WHERE rs.unit_id = p_unit_id
      AND (p_room_id IS NULL OR rs.room_id = p_room_id)
      AND (p_status IS NULL OR p_status = -99 OR rs.meeting_status = p_status)
      AND (p_from_date IS NULL OR rs.start_date >= p_from_date)
      AND (p_to_date IS NULL OR rs.start_date <= p_to_date)
      AND (p_keyword IS NULL OR TRIM(p_keyword) = '' OR rs.name ILIKE '%' || p_keyword || '%')
  )
  SELECT
    flt.*,
    COUNT(*) OVER() AS total_count
  FROM filtered flt
  ORDER BY flt.start_date DESC, flt.start_time
  LIMIT p_page_size OFFSET v_offset;
END;
$$;

-- 10. Chi tiết cuộc họp
CREATE OR REPLACE FUNCTION edoc.fn_room_schedule_get_by_id(
  p_id INT
)
RETURNS TABLE (
  id                  INT,
  unit_id             INT,
  room_id             INT,
  room_name           VARCHAR,
  meeting_type_id     INT,
  meeting_type_name   VARCHAR,
  name                VARCHAR,
  content             TEXT,
  component           VARCHAR,
  start_date          DATE,
  end_date            DATE,
  start_time          VARCHAR,
  end_time            VARCHAR,
  master_id           INT,
  master_name         TEXT,
  secretary_id        INT,
  approved            INT,
  approved_date       TIMESTAMPTZ,
  approved_staff_id   INT,
  rejection_reason    TEXT,
  meeting_status      INT,
  online_link         VARCHAR,
  is_cancel           INT,
  created_user_id     INT,
  created_date        TIMESTAMPTZ,
  modified_user_id    INT,
  modified_date       TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    rs.id, rs.unit_id, rs.room_id, r.name AS room_name,
    rs.meeting_type_id, mt.name AS meeting_type_name,
    rs.name, rs.content, rs.component,
    rs.start_date, rs.end_date, rs.start_time, rs.end_time,
    rs.master_id, (ms.last_name || ' ' || ms.first_name)::TEXT AS master_name,
    rs.secretary_id, rs.approved, rs.approved_date, rs.approved_staff_id,
    rs.rejection_reason, rs.meeting_status, rs.online_link, rs.is_cancel,
    rs.created_user_id, rs.created_date, rs.modified_user_id, rs.modified_date
  FROM edoc.room_schedules rs
  LEFT JOIN edoc.rooms r ON r.id = rs.room_id
  LEFT JOIN edoc.meeting_types mt ON mt.id = rs.meeting_type_id
  LEFT JOIN public.staff ms ON ms.id = rs.master_id
  WHERE rs.id = p_id;
END;
$$;

-- 11. Tạo cuộc họp
CREATE OR REPLACE FUNCTION edoc.fn_room_schedule_create(
  p_unit_id          INT,
  p_room_id          INT,
  p_meeting_type_id  INT,
  p_name             VARCHAR,
  p_content          TEXT,
  p_component        VARCHAR,
  p_start_date       DATE,
  p_end_date         DATE,
  p_start_time       VARCHAR,
  p_end_time         VARCHAR,
  p_master_id        INT,
  p_secretary_id     INT,
  p_online_link      VARCHAR,
  p_created_user_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id INT;
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên cuộc họp không được để trống'::TEXT, NULL::INT;
    RETURN;
  END IF;

  IF p_start_date IS NULL THEN
    RETURN QUERY SELECT false, 'Ngày họp không được để trống'::TEXT, NULL::INT;
    RETURN;
  END IF;

  INSERT INTO edoc.room_schedules (
    unit_id, room_id, meeting_type_id, name, content, component,
    start_date, end_date, start_time, end_time, master_id, secretary_id,
    online_link, created_user_id
  ) VALUES (
    p_unit_id, p_room_id, p_meeting_type_id, p_name, p_content, p_component,
    p_start_date, p_end_date, p_start_time, p_end_time, p_master_id, p_secretary_id,
    p_online_link, p_created_user_id
  ) RETURNING edoc.room_schedules.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo cuộc họp thành công'::TEXT, v_id;
END;
$$;

-- 12. Cập nhật cuộc họp
CREATE OR REPLACE FUNCTION edoc.fn_room_schedule_update(
  p_id               INT,
  p_room_id          INT,
  p_meeting_type_id  INT,
  p_name             VARCHAR,
  p_content          TEXT,
  p_component        VARCHAR,
  p_start_date       DATE,
  p_end_date         DATE,
  p_start_time       VARCHAR,
  p_end_time         VARCHAR,
  p_master_id        INT,
  p_secretary_id     INT,
  p_online_link      VARCHAR,
  p_modified_user_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên cuộc họp không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.room_schedules SET
    room_id          = p_room_id,
    meeting_type_id  = p_meeting_type_id,
    name             = p_name,
    content          = p_content,
    component        = p_component,
    start_date       = COALESCE(p_start_date, start_date),
    end_date         = p_end_date,
    start_time       = p_start_time,
    end_time         = p_end_time,
    master_id        = p_master_id,
    secretary_id     = p_secretary_id,
    online_link      = p_online_link,
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy cuộc họp'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cập nhật thành công'::TEXT;
END;
$$;

-- 13. Xóa cuộc họp — T-05-05: chỉ khi approved=0
CREATE OR REPLACE FUNCTION edoc.fn_room_schedule_delete(
  p_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_approved INT;
BEGIN
  SELECT approved INTO v_approved FROM edoc.room_schedules WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy cuộc họp'::TEXT;
    RETURN;
  END IF;

  IF v_approved <> 0 THEN
    RETURN QUERY SELECT false, 'Chỉ có thể xóa cuộc họp chưa được duyệt'::TEXT;
    RETURN;
  END IF;

  DELETE FROM edoc.room_schedules WHERE id = p_id;

  RETURN QUERY SELECT true, 'Xóa cuộc họp thành công'::TEXT;
END;
$$;

-- 14. Duyệt cuộc họp — T-05-02: validate approved=0
CREATE OR REPLACE FUNCTION edoc.fn_room_schedule_approve(
  p_id               INT,
  p_approved_staff_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_approved INT;
BEGIN
  SELECT approved INTO v_approved FROM edoc.room_schedules WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy cuộc họp'::TEXT;
    RETURN;
  END IF;

  IF v_approved <> 0 THEN
    RETURN QUERY SELECT false, 'Cuộc họp không ở trạng thái chờ duyệt'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.room_schedules SET
    approved          = 1,
    approved_date     = NOW(),
    approved_staff_id = p_approved_staff_id,
    modified_user_id  = p_approved_staff_id,
    modified_date     = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT true, 'Duyệt cuộc họp thành công'::TEXT;
END;
$$;

-- 15. Từ chối cuộc họp
CREATE OR REPLACE FUNCTION edoc.fn_room_schedule_reject(
  p_id                INT,
  p_approved_staff_id INT,
  p_reason            TEXT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_approved INT;
BEGIN
  SELECT approved INTO v_approved FROM edoc.room_schedules WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy cuộc họp'::TEXT;
    RETURN;
  END IF;

  IF v_approved <> 0 THEN
    RETURN QUERY SELECT false, 'Cuộc họp không ở trạng thái chờ duyệt'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.room_schedules SET
    approved          = -1,
    approved_date     = NOW(),
    approved_staff_id = p_approved_staff_id,
    rejection_reason  = p_reason,
    modified_user_id  = p_approved_staff_id,
    modified_date     = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT true, 'Từ chối cuộc họp thành công'::TEXT;
END;
$$;

-- ==========================================
-- STORED FUNCTIONS — STAFF MANAGEMENT
-- ==========================================

-- 16. Danh sách thành viên cuộc họp
CREATE OR REPLACE FUNCTION edoc.fn_room_schedule_get_staff(
  p_room_schedule_id INT
)
RETURNS TABLE (
  id                        INT,
  room_schedule_id          INT,
  staff_id                  INT,
  staff_name                TEXT,
  position_name             VARCHAR,
  user_type                 INT,
  is_secretary              BOOLEAN,
  is_represent              BOOLEAN,
  attendance                BOOLEAN,
  attendance_date           TIMESTAMPTZ,
  attendance_note           TEXT,
  received_appointment      INT,
  received_appointment_date TIMESTAMPTZ,
  view_date                 TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    rss.id,
    rss.room_schedule_id,
    rss.staff_id,
    (s.last_name || ' ' || s.first_name)::TEXT AS staff_name,
    p.name AS position_name,
    rss.user_type,
    rss.is_secretary,
    rss.is_represent,
    rss.attendance,
    rss.attendance_date,
    rss.attendance_note,
    rss.received_appointment,
    rss.received_appointment_date,
    rss.view_date
  FROM edoc.room_schedule_staff rss
  LEFT JOIN public.staff s ON s.id = rss.staff_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  WHERE rss.room_schedule_id = p_room_schedule_id
  ORDER BY rss.user_type, s.last_name;
END;
$$;

-- 17. Phân công thành viên hàng loạt
CREATE OR REPLACE FUNCTION edoc.fn_room_schedule_assign_staff(
  p_room_schedule_id INT,
  p_staff_ids        INT[],
  p_user_type        INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_staff_id INT;
BEGIN
  IF p_staff_ids IS NULL OR array_length(p_staff_ids, 1) IS NULL THEN
    RETURN QUERY SELECT false, 'Danh sách nhân sự trống'::TEXT;
    RETURN;
  END IF;

  FOREACH v_staff_id IN ARRAY p_staff_ids LOOP
    INSERT INTO edoc.room_schedule_staff (room_schedule_id, staff_id, user_type)
    VALUES (p_room_schedule_id, v_staff_id, COALESCE(p_user_type, 0))
    ON CONFLICT (room_schedule_id, staff_id) DO NOTHING;
  END LOOP;

  RETURN QUERY SELECT true, 'Phân công thành viên thành công'::TEXT;
END;
$$;

-- 18. Xóa thành viên khỏi cuộc họp
CREATE OR REPLACE FUNCTION edoc.fn_room_schedule_remove_staff(
  p_room_schedule_id INT,
  p_staff_id         INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  DELETE FROM edoc.room_schedule_staff
  WHERE room_schedule_id = p_room_schedule_id AND staff_id = p_staff_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy thành viên trong cuộc họp'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Xóa thành viên thành công'::TEXT;
END;
$$;

-- ==========================================
-- STORED FUNCTIONS — VOTING (BIỂU QUYẾT)
-- ==========================================

-- 19. Danh sách câu hỏi biểu quyết (kèm đáp án)
CREATE OR REPLACE FUNCTION edoc.fn_vote_question_get_list(
  p_room_schedule_id INT
)
RETURNS TABLE (
  id                UUID,
  room_schedule_id  INT,
  name              VARCHAR,
  start_time        TIMESTAMPTZ,
  stop_time         TIMESTAMPTZ,
  duration          INT,
  status            INT,
  question_type     INT,
  order_no          INT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    q.id, q.room_schedule_id, q.name, q.start_time, q.stop_time,
    q.duration, q.status, q.question_type, q.order_no
  FROM edoc.room_schedule_questions q
  WHERE q.room_schedule_id = p_room_schedule_id
  ORDER BY q.order_no, q.start_time;
END;
$$;

-- 20. Tạo câu hỏi biểu quyết
CREATE OR REPLACE FUNCTION edoc.fn_vote_question_create(
  p_room_schedule_id INT,
  p_name             VARCHAR,
  p_question_type    INT,
  p_duration         INT,
  p_order_no         INT
)
RETURNS TABLE (success BOOLEAN, message TEXT, id UUID)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id UUID;
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Nội dung câu hỏi không được để trống'::TEXT, NULL::UUID;
    RETURN;
  END IF;

  INSERT INTO edoc.room_schedule_questions (
    room_schedule_id, name, question_type, duration, order_no
  ) VALUES (
    p_room_schedule_id, p_name, COALESCE(p_question_type, 0),
    COALESCE(p_duration, 60), COALESCE(p_order_no, 0)
  ) RETURNING edoc.room_schedule_questions.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo câu hỏi thành công'::TEXT, v_id;
END;
$$;

-- 21. Tạo đáp án biểu quyết
CREATE OR REPLACE FUNCTION edoc.fn_vote_answer_create(
  p_question_id        UUID,
  p_room_schedule_id   INT,
  p_name               VARCHAR,
  p_order_no           INT,
  p_is_other           BOOLEAN
)
RETURNS TABLE (success BOOLEAN, message TEXT, id UUID)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id UUID;
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Nội dung đáp án không được để trống'::TEXT, NULL::UUID;
    RETURN;
  END IF;

  INSERT INTO edoc.room_schedule_answers (
    room_schedule_question_id, room_schedule_id, name, order_no, is_other
  ) VALUES (
    p_question_id, p_room_schedule_id, p_name,
    COALESCE(p_order_no, 0), COALESCE(p_is_other, false)
  ) RETURNING edoc.room_schedule_answers.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo đáp án thành công'::TEXT, v_id;
END;
$$;

-- 22. Bỏ phiếu — T-05-03: UNIQUE constraint prevents double voting
CREATE OR REPLACE FUNCTION edoc.fn_vote_cast(
  p_question_id UUID,
  p_answer_id   UUID,
  p_staff_id    INT,
  p_other_text  TEXT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_q_status INT;
  v_room_schedule_id INT;
BEGIN
  SELECT q.status, q.room_schedule_id INTO v_q_status, v_room_schedule_id
  FROM edoc.room_schedule_questions q WHERE q.id = p_question_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy câu hỏi'::TEXT;
    RETURN;
  END IF;

  IF v_q_status <> 1 THEN
    RETURN QUERY SELECT false, 'Câu hỏi chưa mở biểu quyết'::TEXT;
    RETURN;
  END IF;

  INSERT INTO edoc.room_schedule_votes (room_schedule_id, question_id, answer_id, staff_id, other_text)
  VALUES (v_room_schedule_id, p_question_id, p_answer_id, p_staff_id, p_other_text)
  ON CONFLICT (question_id, staff_id) DO UPDATE SET
    answer_id  = EXCLUDED.answer_id,
    other_text = EXCLUDED.other_text,
    voted_at   = NOW();

  RETURN QUERY SELECT true, 'Biểu quyết thành công'::TEXT;
END;
$$;

-- 23. Bắt đầu câu hỏi biểu quyết (status 0 -> 1)
CREATE OR REPLACE FUNCTION edoc.fn_vote_question_start(
  p_question_id UUID
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_status INT;
BEGIN
  SELECT status INTO v_status FROM edoc.room_schedule_questions WHERE id = p_question_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy câu hỏi'::TEXT;
    RETURN;
  END IF;

  IF v_status <> 0 THEN
    RETURN QUERY SELECT false, 'Câu hỏi đã bắt đầu hoặc kết thúc'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.room_schedule_questions SET
    status     = 1,
    start_time = NOW()
  WHERE id = p_question_id;

  RETURN QUERY SELECT true, 'Bắt đầu biểu quyết thành công'::TEXT;
END;
$$;

-- 24. Kết thúc câu hỏi biểu quyết (status 1 -> 2)
CREATE OR REPLACE FUNCTION edoc.fn_vote_question_stop(
  p_question_id UUID
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_status INT;
BEGIN
  SELECT status INTO v_status FROM edoc.room_schedule_questions WHERE id = p_question_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy câu hỏi'::TEXT;
    RETURN;
  END IF;

  IF v_status <> 1 THEN
    RETURN QUERY SELECT false, 'Câu hỏi không đang trong trạng thái biểu quyết'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.room_schedule_questions SET
    status    = 2,
    stop_time = NOW()
  WHERE id = p_question_id;

  RETURN QUERY SELECT true, 'Kết thúc biểu quyết thành công'::TEXT;
END;
$$;

-- 25. Kết quả biểu quyết
CREATE OR REPLACE FUNCTION edoc.fn_vote_get_results(
  p_question_id UUID
)
RETURNS TABLE (
  answer_id     UUID,
  answer_name   VARCHAR,
  order_no      INT,
  vote_count    BIGINT,
  voter_names   TEXT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    a.id AS answer_id,
    a.name AS answer_name,
    a.order_no,
    COUNT(v.id) AS vote_count,
    STRING_AGG(
      (s.last_name || ' ' || s.first_name),
      ', ' ORDER BY s.last_name
    ) AS voter_names
  FROM edoc.room_schedule_answers a
  LEFT JOIN edoc.room_schedule_votes v ON v.answer_id = a.id AND v.question_id = p_question_id
  LEFT JOIN public.staff s ON s.id = v.staff_id
  WHERE a.room_schedule_question_id = p_question_id
  GROUP BY a.id, a.name, a.order_no
  ORDER BY a.order_no;
END;
$$;

-- ==========================================
-- STORED FUNCTION — STATISTICS
-- ==========================================

-- 26. Thống kê cuộc họp theo tháng/phòng/loại
CREATE OR REPLACE FUNCTION edoc.fn_room_schedule_stats(
  p_unit_id INT,
  p_year    INT
)
RETURNS TABLE (
  stat_type   TEXT,
  category_id INT,
  category_name VARCHAR,
  month_num   INT,
  count       BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  -- Thống kê theo tháng
  RETURN QUERY
  SELECT
    'by_month'::TEXT AS stat_type,
    0 AS category_id,
    'Tất cả'::VARCHAR AS category_name,
    EXTRACT(MONTH FROM rs.start_date)::INT AS month_num,
    COUNT(*)::BIGINT AS count
  FROM edoc.room_schedules rs
  WHERE rs.unit_id = p_unit_id
    AND EXTRACT(YEAR FROM rs.start_date) = p_year
    AND rs.is_cancel = 0
  GROUP BY EXTRACT(MONTH FROM rs.start_date)
  ORDER BY month_num;

  -- Thống kê theo phòng
  RETURN QUERY
  SELECT
    'by_room'::TEXT AS stat_type,
    r.id AS category_id,
    r.name AS category_name,
    0 AS month_num,
    COUNT(*)::BIGINT AS count
  FROM edoc.room_schedules rs
  JOIN edoc.rooms r ON r.id = rs.room_id
  WHERE rs.unit_id = p_unit_id
    AND EXTRACT(YEAR FROM rs.start_date) = p_year
    AND rs.is_cancel = 0
  GROUP BY r.id, r.name
  ORDER BY count DESC;

  -- Thống kê theo loại cuộc họp
  RETURN QUERY
  SELECT
    'by_meeting_type'::TEXT AS stat_type,
    mt.id AS category_id,
    mt.name AS category_name,
    0 AS month_num,
    COUNT(*)::BIGINT AS count
  FROM edoc.room_schedules rs
  JOIN edoc.meeting_types mt ON mt.id = rs.meeting_type_id
  WHERE rs.unit_id = p_unit_id
    AND EXTRACT(YEAR FROM rs.start_date) = p_year
    AND rs.is_cancel = 0
  GROUP BY mt.id, mt.name
  ORDER BY count DESC;
END;
$$;

-- ==========================================
-- Thông báo hoàn thành
-- ==========================================
DO $$
BEGIN
  RAISE NOTICE '✅ Migration 018: Sprint 13 Meetings (Họp không giấy)';
  RAISE NOTICE '   Tables: edoc.rooms, edoc.meeting_types, edoc.room_schedules';
  RAISE NOTICE '          edoc.room_schedule_staff, edoc.room_schedule_attachments';
  RAISE NOTICE '          edoc.room_schedule_questions, edoc.room_schedule_answers, edoc.room_schedule_votes';
  RAISE NOTICE '   Functions: 26 stored functions (rooms x4, meeting_type x4, room_schedule x7, staff x3, voting x7, stats x1)';
END $$;
