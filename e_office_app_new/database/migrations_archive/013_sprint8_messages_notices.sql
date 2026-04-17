-- ================================================================
-- MIGRATION 013: Sprint 8 — Tin nhắn nội bộ & Thông báo hệ thống
-- Tables: edoc.messages, edoc.message_recipients, edoc.notices, edoc.notice_reads
-- Functions: 13 stored functions
-- ================================================================

-- ==========================================
-- 1. BẢNG TIN NHẮN (messages)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.messages (
  id            BIGSERIAL PRIMARY KEY,
  from_staff_id INT NOT NULL REFERENCES public.staff(id),
  subject       VARCHAR(200) NOT NULL,
  content       TEXT NOT NULL,
  parent_id     BIGINT REFERENCES edoc.messages(id),
  created_at    TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_messages_from_staff ON edoc.messages(from_staff_id);
CREATE INDEX IF NOT EXISTS idx_messages_parent_id ON edoc.messages(parent_id);

COMMENT ON TABLE edoc.messages IS 'Tin nhắn nội bộ — parent_id NULL = tin nhắn gốc, có giá trị = trả lời';

-- ==========================================
-- 2. BẢNG NGƯỜI NHẬN TIN NHẮN (message_recipients)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.message_recipients (
  id          BIGSERIAL PRIMARY KEY,
  message_id  BIGINT NOT NULL REFERENCES edoc.messages(id) ON DELETE CASCADE,
  staff_id    INT NOT NULL REFERENCES public.staff(id),
  is_read     BOOLEAN DEFAULT FALSE,
  read_at     TIMESTAMP,
  is_deleted  BOOLEAN DEFAULT FALSE,
  deleted_at  TIMESTAMP,
  CONSTRAINT uq_msg_recipients_message_staff UNIQUE (message_id, staff_id)
);

CREATE INDEX IF NOT EXISTS idx_msg_recipients_staff_id ON edoc.message_recipients(staff_id);
CREATE INDEX IF NOT EXISTS idx_msg_recipients_message_id ON edoc.message_recipients(message_id);

COMMENT ON TABLE edoc.message_recipients IS 'Người nhận tin nhắn — mỗi người nhận 1 bản copy riêng';

-- ==========================================
-- 3. BẢNG THÔNG BÁO (notices)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.notices (
  id           BIGSERIAL PRIMARY KEY,
  unit_id      INT REFERENCES public.departments(id),
  title        VARCHAR(300) NOT NULL,
  content      TEXT NOT NULL,
  notice_type  VARCHAR(50) DEFAULT 'system',
  created_by   INT REFERENCES public.staff(id),
  created_at   TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notices_unit_id ON edoc.notices(unit_id);
CREATE INDEX IF NOT EXISTS idx_notices_created_at ON edoc.notices(created_at DESC);

COMMENT ON TABLE edoc.notices IS 'Thông báo hệ thống — system/admin gửi toàn đơn vị';

-- ==========================================
-- 4. BẢNG ĐÃ ĐỌC THÔNG BÁO (notice_reads)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.notice_reads (
  id        BIGSERIAL PRIMARY KEY,
  notice_id BIGINT NOT NULL REFERENCES edoc.notices(id) ON DELETE CASCADE,
  staff_id  INT NOT NULL REFERENCES public.staff(id),
  read_at   TIMESTAMP DEFAULT NOW(),
  CONSTRAINT uq_notice_reads_notice_staff UNIQUE (notice_id, staff_id)
);

COMMENT ON TABLE edoc.notice_reads IS 'Lịch sử đọc thông báo — mỗi user 1 bản ghi per thông báo';

-- ==========================================
-- 5. FN: HỘP THƯ ĐẾN
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_message_get_inbox(
  p_staff_id  INT,
  p_keyword   TEXT,
  p_page      INT DEFAULT 1,
  p_page_size INT DEFAULT 20
)
RETURNS TABLE (
  id              BIGINT,
  from_staff_id   INT,
  from_staff_name TEXT,
  subject         VARCHAR,
  content         TEXT,
  parent_id       BIGINT,
  created_at      TIMESTAMP,
  is_read         BOOLEAN,
  total_count     BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT
      m.id,
      m.from_staff_id,
      CONCAT(s.last_name, ' ', s.first_name) AS from_staff_name,
      m.subject,
      m.content,
      m.parent_id,
      m.created_at,
      mr.is_read
    FROM edoc.messages m
    JOIN edoc.message_recipients mr ON mr.message_id = m.id AND mr.staff_id = p_staff_id
    JOIN public.staff s ON s.id = m.from_staff_id
    WHERE
      mr.is_deleted = FALSE
      AND m.parent_id IS NULL
      AND (
        p_keyword IS NULL OR TRIM(p_keyword) = ''
        OR m.subject ILIKE '%' || p_keyword || '%'
        OR m.content ILIKE '%' || p_keyword || '%'
      )
  )
  SELECT
    f.id,
    f.from_staff_id,
    f.from_staff_name,
    f.subject,
    f.content,
    f.parent_id,
    f.created_at,
    f.is_read,
    COUNT(*) OVER()::BIGINT AS total_count
  FROM filtered f
  ORDER BY f.created_at DESC
  LIMIT COALESCE(p_page_size, 20)
  OFFSET v_offset;
END;
$$;

-- ==========================================
-- 6. FN: HỘP THƯ ĐÃ GỬI
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_message_get_sent(
  p_staff_id  INT,
  p_keyword   TEXT,
  p_page      INT DEFAULT 1,
  p_page_size INT DEFAULT 20
)
RETURNS TABLE (
  id               BIGINT,
  subject          VARCHAR,
  content          TEXT,
  parent_id        BIGINT,
  created_at       TIMESTAMP,
  recipient_names  TEXT,
  total_count      BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT
      m.id,
      m.subject,
      m.content,
      m.parent_id,
      m.created_at,
      (
        SELECT STRING_AGG(CONCAT(sr.last_name, ' ', sr.first_name), ', ' ORDER BY sr.last_name)
        FROM edoc.message_recipients mr2
        JOIN public.staff sr ON sr.id = mr2.staff_id
        WHERE mr2.message_id = m.id
      ) AS recipient_names
    FROM edoc.messages m
    WHERE
      m.from_staff_id = p_staff_id
      AND m.parent_id IS NULL
      AND (
        p_keyword IS NULL OR TRIM(p_keyword) = ''
        OR m.subject ILIKE '%' || p_keyword || '%'
        OR m.content ILIKE '%' || p_keyword || '%'
      )
  )
  SELECT
    f.id,
    f.subject,
    f.content,
    f.parent_id,
    f.created_at,
    f.recipient_names,
    COUNT(*) OVER()::BIGINT AS total_count
  FROM filtered f
  ORDER BY f.created_at DESC
  LIMIT COALESCE(p_page_size, 20)
  OFFSET v_offset;
END;
$$;

-- ==========================================
-- 7. FN: THÙNG RÁC
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_message_get_trash(
  p_staff_id  INT,
  p_page      INT DEFAULT 1,
  p_page_size INT DEFAULT 20
)
RETURNS TABLE (
  id              BIGINT,
  from_staff_id   INT,
  from_staff_name TEXT,
  subject         VARCHAR,
  content         TEXT,
  parent_id       BIGINT,
  created_at      TIMESTAMP,
  deleted_at      TIMESTAMP,
  total_count     BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT
      m.id,
      m.from_staff_id,
      CONCAT(s.last_name, ' ', s.first_name) AS from_staff_name,
      m.subject,
      m.content,
      m.parent_id,
      m.created_at,
      mr.deleted_at
    FROM edoc.messages m
    JOIN edoc.message_recipients mr ON mr.message_id = m.id AND mr.staff_id = p_staff_id
    JOIN public.staff s ON s.id = m.from_staff_id
    WHERE mr.is_deleted = TRUE
  )
  SELECT
    f.id,
    f.from_staff_id,
    f.from_staff_name,
    f.subject,
    f.content,
    f.parent_id,
    f.created_at,
    f.deleted_at,
    COUNT(*) OVER()::BIGINT AS total_count
  FROM filtered f
  ORDER BY f.deleted_at DESC NULLS LAST
  LIMIT COALESCE(p_page_size, 20)
  OFFSET v_offset;
END;
$$;

-- ==========================================
-- 8. FN: CHI TIẾT TIN NHẮN (auto-mark read)
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_message_get_by_id(
  p_id        BIGINT,
  p_staff_id  INT
)
RETURNS TABLE (
  id              BIGINT,
  from_staff_id   INT,
  from_staff_name TEXT,
  subject         VARCHAR,
  content         TEXT,
  parent_id       BIGINT,
  created_at      TIMESTAMP,
  is_read         BOOLEAN,
  recipient_names TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Đánh dấu đã đọc nếu là người nhận
  UPDATE edoc.message_recipients
  SET is_read = TRUE, read_at = NOW()
  WHERE message_id = p_id AND staff_id = p_staff_id AND is_read = FALSE;

  -- Trả về chi tiết tin nhắn
  RETURN QUERY
  SELECT
    m.id,
    m.from_staff_id,
    CONCAT(s.last_name, ' ', s.first_name) AS from_staff_name,
    m.subject,
    m.content,
    m.parent_id,
    m.created_at,
    COALESCE(mr.is_read, FALSE) AS is_read,
    (
      SELECT STRING_AGG(CONCAT(sr.last_name, ' ', sr.first_name), ', ' ORDER BY sr.last_name)
      FROM edoc.message_recipients mr2
      JOIN public.staff sr ON sr.id = mr2.staff_id
      WHERE mr2.message_id = m.id
    ) AS recipient_names
  FROM edoc.messages m
  JOIN public.staff s ON s.id = m.from_staff_id
  LEFT JOIN edoc.message_recipients mr ON mr.message_id = m.id AND mr.staff_id = p_staff_id
  WHERE
    m.id = p_id
    AND (
      m.from_staff_id = p_staff_id
      OR EXISTS (
        SELECT 1 FROM edoc.message_recipients mr3
        WHERE mr3.message_id = m.id AND mr3.staff_id = p_staff_id
      )
    );
END;
$$;

-- ==========================================
-- 9. FN: GỬI TIN NHẮN MỚI
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_message_create(
  p_from_staff_id INT,
  p_to_staff_ids  INT[],
  p_subject       VARCHAR,
  p_content       TEXT,
  p_parent_id     BIGINT DEFAULT NULL
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT,
  id      BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_id          BIGINT;
  v_staff_id    INT;
BEGIN
  -- Kiểm tra người nhận
  IF p_to_staff_ids IS NULL OR array_length(p_to_staff_ids, 1) = 0 THEN
    RETURN QUERY SELECT FALSE, 'Phải có ít nhất một người nhận'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  -- Kiểm tra tiêu đề
  IF p_subject IS NULL OR TRIM(p_subject) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tiêu đề tin nhắn không được để trống'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  -- Kiểm tra nội dung
  IF p_content IS NULL OR TRIM(p_content) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nội dung tin nhắn không được để trống'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  -- Tạo tin nhắn
  INSERT INTO edoc.messages (from_staff_id, subject, content, parent_id, created_at)
  VALUES (p_from_staff_id, p_subject, p_content, p_parent_id, NOW())
  RETURNING messages.id INTO v_id;

  -- Thêm người nhận
  FOREACH v_staff_id IN ARRAY p_to_staff_ids LOOP
    INSERT INTO edoc.message_recipients (message_id, staff_id, is_read, is_deleted)
    VALUES (v_id, v_staff_id, FALSE, FALSE)
    ON CONFLICT (message_id, staff_id) DO NOTHING;
  END LOOP;

  RETURN QUERY SELECT TRUE, 'Gửi tin nhắn thành công'::TEXT, v_id;
END;
$$;

-- ==========================================
-- 10. FN: TRẢ LỜI TIN NHẮN
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_message_reply(
  p_message_id  BIGINT,
  p_staff_id    INT,
  p_content     TEXT
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT,
  id      BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_reply_id      BIGINT;
  v_original      edoc.messages%ROWTYPE;
  v_subject       VARCHAR(200);
  v_staff_id      INT;
  v_recipient_ids INT[];
BEGIN
  -- Kiểm tra nội dung
  IF p_content IS NULL OR TRIM(p_content) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nội dung trả lời không được để trống'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  -- Lấy tin nhắn gốc
  SELECT * INTO v_original FROM edoc.messages WHERE id = p_message_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy tin nhắn gốc'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  -- Xây dựng tiêu đề trả lời
  v_subject := 'Re: ' || v_original.subject;

  -- Tạo tin nhắn trả lời với parent_id = tin nhắn gốc
  INSERT INTO edoc.messages (from_staff_id, subject, content, parent_id, created_at)
  VALUES (p_staff_id, v_subject, p_content, p_message_id, NOW())
  RETURNING messages.id INTO v_reply_id;

  -- Thêm người gửi gốc làm người nhận
  INSERT INTO edoc.message_recipients (message_id, staff_id, is_read, is_deleted)
  VALUES (v_reply_id, v_original.from_staff_id, FALSE, FALSE)
  ON CONFLICT (message_id, staff_id) DO NOTHING;

  -- Thêm tất cả người nhận tin nhắn gốc (trừ người đang reply)
  FOR v_staff_id IN
    SELECT mr.staff_id FROM edoc.message_recipients mr
    WHERE mr.message_id = p_message_id AND mr.staff_id <> p_staff_id
  LOOP
    INSERT INTO edoc.message_recipients (message_id, staff_id, is_read, is_deleted)
    VALUES (v_reply_id, v_staff_id, FALSE, FALSE)
    ON CONFLICT (message_id, staff_id) DO NOTHING;
  END LOOP;

  RETURN QUERY SELECT TRUE, 'Trả lời tin nhắn thành công'::TEXT, v_reply_id;
END;
$$;

-- ==========================================
-- 11. FN: XÓA TIN NHẮN (soft delete — chuyển thùng rác)
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_message_delete(
  p_id        BIGINT,
  p_staff_id  INT
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_count INT;
BEGIN
  -- Kiểm tra người dùng có quyền xóa (là người nhận)
  SELECT COUNT(*) INTO v_count
  FROM edoc.message_recipients
  WHERE message_id = p_id AND staff_id = p_staff_id AND is_deleted = FALSE;

  IF v_count = 0 THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy tin nhắn hoặc đã bị xóa'::TEXT;
    RETURN;
  END IF;

  -- Soft delete: chỉ xóa bản copy của người dùng này
  UPDATE edoc.message_recipients
  SET is_deleted = TRUE, deleted_at = NOW()
  WHERE message_id = p_id AND staff_id = p_staff_id;

  RETURN QUERY SELECT TRUE, 'Xóa tin nhắn thành công'::TEXT;
END;
$$;

-- ==========================================
-- 12. FN: ĐẾM TIN NHẮN CHƯA ĐỌC
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_message_count_unread(
  p_staff_id  INT
)
RETURNS TABLE (
  count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT COUNT(*)::BIGINT
  FROM edoc.message_recipients mr
  WHERE mr.staff_id = p_staff_id
    AND mr.is_read = FALSE
    AND mr.is_deleted = FALSE;
END;
$$;

-- ==========================================
-- 13. FN: DANH SÁCH THÔNG BÁO
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_notice_get_list(
  p_unit_id   INT,
  p_staff_id  INT,
  p_is_read   TEXT,
  p_page      INT DEFAULT 1,
  p_page_size INT DEFAULT 20
)
RETURNS TABLE (
  id           BIGINT,
  unit_id      INT,
  title        VARCHAR,
  content      TEXT,
  notice_type  VARCHAR,
  created_by   INT,
  created_at   TIMESTAMP,
  is_read      BOOLEAN,
  total_count  BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT
      n.id,
      n.unit_id,
      n.title,
      n.content,
      n.notice_type,
      n.created_by,
      n.created_at,
      CASE WHEN nr.id IS NOT NULL THEN TRUE ELSE FALSE END AS is_read
    FROM edoc.notices n
    LEFT JOIN edoc.notice_reads nr ON nr.notice_id = n.id AND nr.staff_id = p_staff_id
    WHERE
      (p_unit_id IS NULL OR n.unit_id = p_unit_id OR n.unit_id IS NULL)
      AND (
        p_is_read IS NULL OR p_is_read = ''
        OR (p_is_read = 'true' AND nr.id IS NOT NULL)
        OR (p_is_read = 'false' AND nr.id IS NULL)
      )
  )
  SELECT
    f.id,
    f.unit_id,
    f.title,
    f.content,
    f.notice_type,
    f.created_by,
    f.created_at,
    f.is_read,
    COUNT(*) OVER()::BIGINT AS total_count
  FROM filtered f
  ORDER BY f.created_at DESC
  LIMIT COALESCE(p_page_size, 20)
  OFFSET v_offset;
END;
$$;

-- ==========================================
-- 14. FN: TẠO THÔNG BÁO
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_notice_create(
  p_unit_id     INT,
  p_title       VARCHAR,
  p_content     TEXT,
  p_notice_type VARCHAR,
  p_created_by  INT
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT,
  id      BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_id BIGINT;
BEGIN
  -- Kiểm tra tiêu đề
  IF p_title IS NULL OR TRIM(p_title) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tiêu đề thông báo không được để trống'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  -- Kiểm tra nội dung
  IF p_content IS NULL OR TRIM(p_content) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nội dung thông báo không được để trống'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.notices (unit_id, title, content, notice_type, created_by, created_at)
  VALUES (p_unit_id, p_title, p_content, COALESCE(p_notice_type, 'system'), p_created_by, NOW())
  RETURNING notices.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tạo thông báo thành công'::TEXT, v_id;
END;
$$;

-- ==========================================
-- 15. FN: ĐÁNH DẤU ĐÃ ĐỌC THÔNG BÁO
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_notice_mark_read(
  p_notice_id BIGINT,
  p_staff_id  INT
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Kiểm tra thông báo tồn tại
  IF NOT EXISTS (SELECT 1 FROM edoc.notices WHERE id = p_notice_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy thông báo'::TEXT;
    RETURN;
  END IF;

  -- Insert ON CONFLICT DO NOTHING để tránh duplicate
  INSERT INTO edoc.notice_reads (notice_id, staff_id, read_at)
  VALUES (p_notice_id, p_staff_id, NOW())
  ON CONFLICT (notice_id, staff_id) DO NOTHING;

  RETURN QUERY SELECT TRUE, 'Đánh dấu đã đọc thành công'::TEXT;
END;
$$;

-- ==========================================
-- 16. FN: ĐÁNH DẤU TẤT CẢ ĐÃ ĐỌC
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_notice_mark_all_read(
  p_staff_id  INT,
  p_unit_id   INT
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT,
  count   BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_count BIGINT := 0;
BEGIN
  -- Chèn bản ghi đọc cho tất cả thông báo chưa đọc của staff này
  WITH unread_notices AS (
    SELECT n.id
    FROM edoc.notices n
    WHERE
      (p_unit_id IS NULL OR n.unit_id = p_unit_id OR n.unit_id IS NULL)
      AND NOT EXISTS (
        SELECT 1 FROM edoc.notice_reads nr
        WHERE nr.notice_id = n.id AND nr.staff_id = p_staff_id
      )
  ),
  inserted AS (
    INSERT INTO edoc.notice_reads (notice_id, staff_id, read_at)
    SELECT un.id, p_staff_id, NOW() FROM unread_notices un
    ON CONFLICT (notice_id, staff_id) DO NOTHING
    RETURNING 1
  )
  SELECT COUNT(*) INTO v_count FROM inserted;

  RETURN QUERY SELECT TRUE, 'Đánh dấu tất cả đã đọc thành công'::TEXT, v_count;
END;
$$;

-- ==========================================
-- 17. FN: ĐẾM THÔNG BÁO CHƯA ĐỌC
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_notice_count_unread(
  p_staff_id  INT
)
RETURNS TABLE (
  count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT COUNT(*)::BIGINT
  FROM edoc.notices n
  WHERE NOT EXISTS (
    SELECT 1 FROM edoc.notice_reads nr
    WHERE nr.notice_id = n.id AND nr.staff_id = p_staff_id
  );
END;
$$;
