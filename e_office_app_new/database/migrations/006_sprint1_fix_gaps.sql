-- ============================================
-- MIGRATION 006: Sprint 1 Gap Fixes
-- Ref: Phân tích source code cũ (OneWin)
-- ============================================

-- Drop functions that change return type (must drop before recreate)
DROP FUNCTION IF EXISTS public.fn_position_get_list(VARCHAR, INT, INT);
DROP FUNCTION IF EXISTS public.fn_position_get_by_id(INT);
DROP FUNCTION IF EXISTS public.fn_staff_get_list(INT, INT, VARCHAR, BOOLEAN, INT, INT);
DROP FUNCTION IF EXISTS public.fn_staff_get_by_id(INT);

-- ══════════════════════════════════════════════
-- 1. POSITION: Thêm is_leader, is_handle_document
-- Ref cũ: Position.cs → IsLeader, IsHandleDocument
-- ══════════════════════════════════════════════

ALTER TABLE public.positions
  ADD COLUMN IF NOT EXISTS is_leader BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS is_handle_document BOOLEAN DEFAULT FALSE;

COMMENT ON COLUMN public.positions.is_leader IS 'Chức vụ lãnh đạo (ảnh hưởng workflow ký duyệt)';
COMMENT ON COLUMN public.positions.is_handle_document IS 'Cho phép xử lý văn bản (phân công VB)';

-- Seed: Giám đốc, Phó GĐ, Trưởng phòng = leader
UPDATE public.positions SET is_leader = TRUE WHERE code IN ('GD', 'PGD', 'TP');
-- Tất cả chức vụ đều handle document mặc định
UPDATE public.positions SET is_handle_document = TRUE;

-- Update SPs cho Position
CREATE OR REPLACE FUNCTION public.fn_position_get_list(
  p_keyword VARCHAR DEFAULT NULL,
  p_page INT DEFAULT 1,
  p_page_size INT DEFAULT 20
)
RETURNS TABLE (
  id INT, name VARCHAR, code VARCHAR, sort_order INT,
  description TEXT, is_active BOOLEAN, is_leader BOOLEAN, is_handle_document BOOLEAN,
  staff_count BIGINT, total_count BIGINT
)
LANGUAGE sql STABLE
AS $$
  WITH filtered AS (
    SELECT p.*, COUNT(*) OVER() AS total_count
    FROM public.positions p
    WHERE (p_keyword IS NULL OR p.name ILIKE '%' || p_keyword || '%' OR p.code ILIKE '%' || p_keyword || '%')
    ORDER BY p.sort_order, p.name
    OFFSET (p_page - 1) * p_page_size LIMIT p_page_size
  )
  SELECT f.id, f.name::VARCHAR, f.code::VARCHAR, f.sort_order,
    f.description, f.is_active, f.is_leader, f.is_handle_document,
    (SELECT COUNT(*) FROM public.staff s WHERE s.position_id = f.id AND s.is_deleted = FALSE) AS staff_count,
    f.total_count
  FROM filtered f;
$$;

CREATE OR REPLACE FUNCTION public.fn_position_get_by_id(p_id INT)
RETURNS TABLE (id INT, name VARCHAR, code VARCHAR, sort_order INT, description TEXT, is_active BOOLEAN, is_leader BOOLEAN, is_handle_document BOOLEAN)
LANGUAGE sql STABLE
AS $$
  SELECT p.id, p.name::VARCHAR, p.code::VARCHAR, p.sort_order, p.description, p.is_active, p.is_leader, p.is_handle_document
  FROM public.positions p WHERE p.id = p_id;
$$;

CREATE OR REPLACE FUNCTION public.fn_position_create(
  p_name VARCHAR, p_code VARCHAR, p_sort_order INT, p_description TEXT,
  p_is_leader BOOLEAN DEFAULT FALSE, p_is_handle_document BOOLEAN DEFAULT TRUE
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE v_id INT;
BEGIN
  INSERT INTO public.positions (name, code, sort_order, description, is_leader, is_handle_document)
  VALUES (p_name, p_code, p_sort_order, p_description, p_is_leader, p_is_handle_document)
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_position_update(
  p_id INT, p_name VARCHAR, p_code VARCHAR, p_sort_order INT,
  p_description TEXT, p_is_active BOOLEAN,
  p_is_leader BOOLEAN DEFAULT FALSE, p_is_handle_document BOOLEAN DEFAULT TRUE
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.positions SET name = p_name, code = p_code, sort_order = p_sort_order,
    description = p_description, is_active = p_is_active,
    is_leader = p_is_leader, is_handle_document = p_is_handle_document
  WHERE id = p_id;
  RETURN FOUND;
END;
$$;

-- ══════════════════════════════════════════════
-- 2. STAFF: Thêm code, password_changed, sign fields
-- Ref cũ: Staff.cs → Code (SEQ_STAFFCODE), PasswordChanged, SignPhone, SignCA, SignImage
-- ══════════════════════════════════════════════

-- Sequence cho staff code
CREATE SEQUENCE IF NOT EXISTS public.seq_staff_code START WITH 1000 INCREMENT BY 1;

ALTER TABLE public.staff
  ADD COLUMN IF NOT EXISTS code VARCHAR(20),
  ADD COLUMN IF NOT EXISTS password_changed BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS sign_phone VARCHAR(20),
  ADD COLUMN IF NOT EXISTS sign_ca TEXT,
  ADD COLUMN IF NOT EXISTS sign_image VARCHAR(500);

COMMENT ON COLUMN public.staff.code IS 'Mã cán bộ (auto-generate từ seq_staff_code)';
COMMENT ON COLUMN public.staff.password_changed IS 'Đã đổi mật khẩu lần đầu (bắt đổi pass nếu FALSE)';
COMMENT ON COLUMN public.staff.sign_phone IS 'SĐT ký số từ xa';
COMMENT ON COLUMN public.staff.sign_ca IS 'Chứng thư số (base64)';
COMMENT ON COLUMN public.staff.sign_image IS 'Ảnh chữ ký scan (path MinIO)';

-- Update code cho admin hiện có
UPDATE public.staff SET code = 'NV' || LPAD(nextval('seq_staff_code')::TEXT, 6, '0') WHERE code IS NULL;

-- Function tạo staff code
CREATE OR REPLACE FUNCTION public.fn_staff_generate_code()
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN 'NV' || LPAD(nextval('seq_staff_code')::TEXT, 6, '0');
END;
$$;

-- ══════════════════════════════════════════════
-- 3. Update fn_staff_create: auto-gen code, normalize username, default password logic
-- ══════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.fn_staff_create(
  p_department_id INT, p_unit_id INT, p_position_id INT,
  p_username VARCHAR, p_password_hash VARCHAR,
  p_first_name VARCHAR, p_last_name VARCHAR, p_gender SMALLINT,
  p_birth_date DATE, p_email VARCHAR, p_phone VARCHAR, p_mobile VARCHAR,
  p_address TEXT, p_id_card VARCHAR, p_id_card_date DATE, p_id_card_place VARCHAR,
  p_is_admin BOOLEAN, p_is_represent_unit BOOLEAN, p_is_represent_department BOOLEAN,
  p_created_by INT
)
RETURNS TABLE (id INT, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
  v_id INT;
  v_code VARCHAR;
  v_username VARCHAR;
BEGIN
  -- Normalize username: trim, lowercase
  v_username := LOWER(TRIM(REPLACE(p_username, ' ', '')));

  -- Check unique username (case-insensitive)
  IF EXISTS (SELECT 1 FROM public.staff WHERE LOWER(username) = v_username AND is_deleted = FALSE) THEN
    RETURN QUERY SELECT 0, 'Tên đăng nhập đã tồn tại'::TEXT;
    RETURN;
  END IF;

  -- Check email unique (nếu có)
  IF p_email IS NOT NULL AND p_email <> '' THEN
    IF EXISTS (SELECT 1 FROM public.staff WHERE LOWER(email) = LOWER(TRIM(p_email)) AND is_deleted = FALSE) THEN
      RETURN QUERY SELECT 0, 'Email đã được sử dụng'::TEXT;
      RETURN;
    END IF;
  END IF;

  -- Auto-generate staff code
  v_code := public.fn_staff_generate_code();

  INSERT INTO public.staff (
    department_id, unit_id, position_id, username, password_hash, code,
    first_name, last_name, gender, birth_date, email, phone, mobile,
    address, id_card, id_card_date, id_card_place,
    is_admin, is_represent_unit, is_represent_department,
    password_changed, created_by
  ) VALUES (
    p_department_id, p_unit_id, p_position_id, v_username, p_password_hash, v_code,
    TRIM(p_first_name), TRIM(p_last_name), p_gender, p_birth_date,
    LOWER(TRIM(p_email)), TRIM(p_phone), TRIM(p_mobile),
    TRIM(p_address), TRIM(p_id_card), p_id_card_date, TRIM(p_id_card_place),
    COALESCE(p_is_admin, FALSE), COALESCE(p_is_represent_unit, FALSE), COALESCE(p_is_represent_department, FALSE),
    FALSE,  -- password_changed = FALSE → bắt đổi pass lần đầu
    p_created_by
  ) RETURNING staff.id INTO v_id;

  RETURN QUERY SELECT v_id, 'Tạo thành công'::TEXT;
END;
$$;

-- ══════════════════════════════════════════════
-- 4. Update fn_staff_get_list: thêm code
-- ══════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.fn_staff_get_list(
  p_unit_id INT DEFAULT NULL,
  p_department_id INT DEFAULT NULL,
  p_keyword VARCHAR DEFAULT NULL,
  p_is_locked BOOLEAN DEFAULT NULL,
  p_page INT DEFAULT 1,
  p_page_size INT DEFAULT 20
)
RETURNS TABLE (
  id INT, code VARCHAR, username VARCHAR, full_name VARCHAR, first_name VARCHAR, last_name VARCHAR,
  email VARCHAR, phone VARCHAR, image VARCHAR, gender SMALLINT,
  department_id INT, department_name VARCHAR, unit_id INT, unit_name VARCHAR,
  position_id INT, position_name VARCHAR,
  is_admin BOOLEAN, is_locked BOOLEAN, is_represent_unit BOOLEAN, is_represent_department BOOLEAN,
  password_changed BOOLEAN,
  last_login_at TIMESTAMPTZ, created_at TIMESTAMPTZ, total_count BIGINT
)
LANGUAGE sql STABLE
AS $$
  SELECT
    s.id, s.code::VARCHAR, s.username::VARCHAR, s.full_name::VARCHAR, s.first_name::VARCHAR, s.last_name::VARCHAR,
    s.email::VARCHAR, COALESCE(s.phone, s.mobile)::VARCHAR AS phone, s.image::VARCHAR, s.gender,
    s.department_id, d.name::VARCHAR AS department_name,
    s.unit_id, u.name::VARCHAR AS unit_name,
    s.position_id, p.name::VARCHAR AS position_name,
    s.is_admin, s.is_locked, s.is_represent_unit, s.is_represent_department,
    s.password_changed,
    s.last_login_at, s.created_at,
    COUNT(*) OVER() AS total_count
  FROM public.staff s
  LEFT JOIN public.departments d ON d.id = s.department_id
  LEFT JOIN public.departments u ON u.id = s.unit_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  WHERE s.is_deleted = FALSE
    AND (p_unit_id IS NULL OR s.unit_id = p_unit_id)
    AND (p_department_id IS NULL OR s.department_id = p_department_id)
    AND (p_keyword IS NULL OR s.full_name ILIKE '%' || p_keyword || '%'
         OR s.username ILIKE '%' || p_keyword || '%'
         OR s.email ILIKE '%' || p_keyword || '%'
         OR s.code ILIKE '%' || p_keyword || '%')
    AND (p_is_locked IS NULL OR s.is_locked = p_is_locked)
  ORDER BY s.last_name, s.first_name
  OFFSET (p_page - 1) * p_page_size LIMIT p_page_size;
$$;

-- ══════════════════════════════════════════════
-- 5. Update fn_staff_get_by_id: thêm code, password_changed, sign fields
-- ══════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.fn_staff_get_by_id(p_id INT)
RETURNS TABLE (
  id INT, code VARCHAR, username VARCHAR, full_name VARCHAR, first_name VARCHAR, last_name VARCHAR,
  email VARCHAR, phone VARCHAR, mobile VARCHAR, image VARCHAR,
  gender SMALLINT, birth_date DATE, address TEXT,
  id_card VARCHAR, id_card_date DATE, id_card_place VARCHAR,
  department_id INT, department_name VARCHAR, unit_id INT, unit_name VARCHAR,
  position_id INT, position_name VARCHAR,
  is_admin BOOLEAN, is_locked BOOLEAN,
  is_represent_unit BOOLEAN, is_represent_department BOOLEAN,
  password_changed BOOLEAN,
  sign_phone VARCHAR, sign_ca TEXT, sign_image VARCHAR,
  last_login_at TIMESTAMPTZ, created_at TIMESTAMPTZ,
  roles TEXT
)
LANGUAGE sql STABLE
AS $$
  SELECT
    s.id, s.code::VARCHAR, s.username::VARCHAR, s.full_name::VARCHAR, s.first_name::VARCHAR, s.last_name::VARCHAR,
    s.email::VARCHAR, s.phone::VARCHAR, s.mobile::VARCHAR, s.image::VARCHAR,
    s.gender, s.birth_date, s.address,
    s.id_card::VARCHAR, s.id_card_date, s.id_card_place::VARCHAR,
    s.department_id, d.name::VARCHAR, s.unit_id, u.name::VARCHAR,
    s.position_id, p.name::VARCHAR,
    s.is_admin, s.is_locked, s.is_represent_unit, s.is_represent_department,
    s.password_changed,
    s.sign_phone::VARCHAR, s.sign_ca, s.sign_image::VARCHAR,
    s.last_login_at, s.created_at,
    COALESCE((SELECT string_agg(r.name, ',') FROM public.role_of_staff ros JOIN public.roles r ON r.id = ros.role_id WHERE ros.staff_id = s.id), '')::TEXT AS roles
  FROM public.staff s
  LEFT JOIN public.departments d ON d.id = s.department_id
  LEFT JOIN public.departments u ON u.id = s.unit_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  WHERE s.id = p_id AND s.is_deleted = FALSE;
$$;

-- ══════════════════════════════════════════════
-- 6. fn_staff_change_password: user tự đổi (kiểm tra mật khẩu cũ)
-- Ref cũ: Prc_StaffChangePassword — old password != new password
-- ══════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.fn_staff_change_password(
  p_id INT,
  p_new_password_hash VARCHAR
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
  v_current_hash VARCHAR;
BEGIN
  SELECT password_hash INTO v_current_hash FROM public.staff WHERE id = p_id AND is_deleted = FALSE AND is_locked = FALSE;

  IF v_current_hash IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Tài khoản không tồn tại hoặc đã bị khóa'::TEXT;
    RETURN;
  END IF;

  -- Note: So sánh old vs new password phải check ở app layer (bcrypt compare)
  -- Ở đây chỉ update
  UPDATE public.staff SET password_hash = p_new_password_hash, password_changed = TRUE WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Đổi mật khẩu thành công'::TEXT;
END;
$$;
