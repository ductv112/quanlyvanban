-- ============================================
-- MIGRATION 005: Sprint 1 — Quản trị hệ thống Core
-- Stored Procedures: Department, Position, Staff, Role, Right
-- Convention: public.fn_{module}_{action}
-- ============================================

-- ══════════════════════════════════════════════
-- 1. DEPARTMENT (Đơn vị / Phòng ban)
-- ══════════════════════════════════════════════

-- 1.1 Lấy cây tổ chức đệ quy
CREATE OR REPLACE FUNCTION public.fn_department_get_tree(p_unit_id INT DEFAULT NULL)
RETURNS TABLE (
  id INT, parent_id INT, code VARCHAR, name VARCHAR, name_en VARCHAR,
  short_name VARCHAR, abb_name VARCHAR, is_unit BOOLEAN, level INT,
  sort_order INT, phone VARCHAR, fax VARCHAR, email VARCHAR, address TEXT,
  allow_doc_book BOOLEAN, is_locked BOOLEAN, staff_count BIGINT
)
LANGUAGE sql STABLE
AS $$
  SELECT
    d.id, d.parent_id, d.code::VARCHAR, d.name::VARCHAR, d.name_en::VARCHAR,
    d.short_name::VARCHAR, d.abb_name::VARCHAR, d.is_unit, d.level,
    d.sort_order, d.phone::VARCHAR, d.fax::VARCHAR, d.email::VARCHAR, d.address,
    d.allow_doc_book, d.is_locked,
    (SELECT COUNT(*) FROM public.staff s WHERE s.department_id = d.id AND s.is_deleted = FALSE) AS staff_count
  FROM public.departments d
  WHERE d.is_deleted = FALSE
    AND (p_unit_id IS NULL OR d.id = p_unit_id OR d.parent_id = p_unit_id
         OR d.parent_id IN (SELECT dd.id FROM public.departments dd WHERE dd.parent_id = p_unit_id AND dd.is_deleted = FALSE))
  ORDER BY d.sort_order, d.name;
$$;

-- 1.2 Lấy chi tiết 1 đơn vị
CREATE OR REPLACE FUNCTION public.fn_department_get_by_id(p_id INT)
RETURNS TABLE (
  id INT, parent_id INT, code VARCHAR, name VARCHAR, name_en VARCHAR,
  short_name VARCHAR, abb_name VARCHAR, is_unit BOOLEAN, level INT,
  sort_order INT, phone VARCHAR, fax VARCHAR, email VARCHAR, address TEXT,
  allow_doc_book BOOLEAN, description TEXT, is_locked BOOLEAN,
  lgsp_system_id VARCHAR, lgsp_secret_key VARCHAR,
  created_at TIMESTAMPTZ, updated_at TIMESTAMPTZ
)
LANGUAGE sql STABLE
AS $$
  SELECT d.id, d.parent_id, d.code::VARCHAR, d.name::VARCHAR, d.name_en::VARCHAR,
    d.short_name::VARCHAR, d.abb_name::VARCHAR, d.is_unit, d.level,
    d.sort_order, d.phone::VARCHAR, d.fax::VARCHAR, d.email::VARCHAR, d.address,
    d.allow_doc_book, d.description, d.is_locked,
    d.lgsp_system_id::VARCHAR, d.lgsp_secret_key::VARCHAR,
    d.created_at, d.updated_at
  FROM public.departments d WHERE d.id = p_id AND d.is_deleted = FALSE;
$$;

-- 1.3 Tạo đơn vị / phòng ban
CREATE OR REPLACE FUNCTION public.fn_department_create(
  p_parent_id INT, p_code VARCHAR, p_name VARCHAR, p_name_en VARCHAR,
  p_short_name VARCHAR, p_abb_name VARCHAR, p_is_unit BOOLEAN,
  p_level INT, p_sort_order INT, p_phone VARCHAR, p_fax VARCHAR,
  p_email VARCHAR, p_address TEXT, p_allow_doc_book BOOLEAN,
  p_description TEXT, p_created_by INT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE v_id INT;
BEGIN
  INSERT INTO public.departments (
    parent_id, code, name, name_en, short_name, abb_name, is_unit,
    level, sort_order, phone, fax, email, address, allow_doc_book,
    description, created_by
  ) VALUES (
    p_parent_id, p_code, p_name, p_name_en, p_short_name, p_abb_name, p_is_unit,
    p_level, p_sort_order, p_phone, p_fax, p_email, p_address, p_allow_doc_book,
    p_description, p_created_by
  ) RETURNING id INTO v_id;
  RETURN v_id;
END;
$$;

-- 1.4 Cập nhật
CREATE OR REPLACE FUNCTION public.fn_department_update(
  p_id INT, p_parent_id INT, p_code VARCHAR, p_name VARCHAR, p_name_en VARCHAR,
  p_short_name VARCHAR, p_abb_name VARCHAR, p_is_unit BOOLEAN,
  p_level INT, p_sort_order INT, p_phone VARCHAR, p_fax VARCHAR,
  p_email VARCHAR, p_address TEXT, p_allow_doc_book BOOLEAN,
  p_description TEXT, p_updated_by INT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.departments SET
    parent_id = p_parent_id, code = p_code, name = p_name, name_en = p_name_en,
    short_name = p_short_name, abb_name = p_abb_name, is_unit = p_is_unit,
    level = p_level, sort_order = p_sort_order, phone = p_phone, fax = p_fax,
    email = p_email, address = p_address, allow_doc_book = p_allow_doc_book,
    description = p_description, updated_by = p_updated_by
  WHERE id = p_id AND is_deleted = FALSE;
  RETURN FOUND;
END;
$$;

-- 1.5 Xóa (soft delete)
CREATE OR REPLACE FUNCTION public.fn_department_delete(p_id INT)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_staff_count INT; v_child_count INT;
BEGIN
  SELECT COUNT(*) INTO v_child_count FROM public.departments WHERE parent_id = p_id AND is_deleted = FALSE;
  IF v_child_count > 0 THEN
    RETURN QUERY SELECT FALSE, 'Không thể xóa: còn '|| v_child_count ||' phòng ban con';
    RETURN;
  END IF;

  SELECT COUNT(*) INTO v_staff_count FROM public.staff WHERE department_id = p_id AND is_deleted = FALSE;
  IF v_staff_count > 0 THEN
    RETURN QUERY SELECT FALSE, 'Không thể xóa: còn '|| v_staff_count ||' nhân viên thuộc phòng ban này';
    RETURN;
  END IF;

  UPDATE public.departments SET is_deleted = TRUE WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa thành công'::TEXT;
END;
$$;

-- 1.6 Khóa / Mở khóa
CREATE OR REPLACE FUNCTION public.fn_department_toggle_lock(p_id INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.departments SET is_locked = NOT is_locked WHERE id = p_id AND is_deleted = FALSE;
  RETURN FOUND;
END;
$$;

-- ══════════════════════════════════════════════
-- 2. POSITION (Chức vụ)
-- ══════════════════════════════════════════════

-- 2.1 Danh sách chức vụ (có phân trang)
CREATE OR REPLACE FUNCTION public.fn_position_get_list(
  p_keyword VARCHAR DEFAULT NULL,
  p_page INT DEFAULT 1,
  p_page_size INT DEFAULT 20
)
RETURNS TABLE (
  id INT, name VARCHAR, code VARCHAR, sort_order INT,
  description TEXT, is_active BOOLEAN,
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
    f.description, f.is_active,
    (SELECT COUNT(*) FROM public.staff s WHERE s.position_id = f.id AND s.is_deleted = FALSE) AS staff_count,
    f.total_count
  FROM filtered f;
$$;

-- 2.2 Lấy theo ID
CREATE OR REPLACE FUNCTION public.fn_position_get_by_id(p_id INT)
RETURNS TABLE (id INT, name VARCHAR, code VARCHAR, sort_order INT, description TEXT, is_active BOOLEAN)
LANGUAGE sql STABLE
AS $$
  SELECT p.id, p.name::VARCHAR, p.code::VARCHAR, p.sort_order, p.description, p.is_active
  FROM public.positions p WHERE p.id = p_id;
$$;

-- 2.3 Tạo chức vụ
CREATE OR REPLACE FUNCTION public.fn_position_create(
  p_name VARCHAR, p_code VARCHAR, p_sort_order INT, p_description TEXT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE v_id INT;
BEGIN
  INSERT INTO public.positions (name, code, sort_order, description)
  VALUES (p_name, p_code, p_sort_order, p_description)
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$$;

-- 2.4 Cập nhật
CREATE OR REPLACE FUNCTION public.fn_position_update(
  p_id INT, p_name VARCHAR, p_code VARCHAR, p_sort_order INT, p_description TEXT, p_is_active BOOLEAN
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.positions SET name = p_name, code = p_code, sort_order = p_sort_order,
    description = p_description, is_active = p_is_active
  WHERE id = p_id;
  RETURN FOUND;
END;
$$;

-- 2.5 Xóa
CREATE OR REPLACE FUNCTION public.fn_position_delete(p_id INT)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM public.staff WHERE position_id = p_id AND is_deleted = FALSE;
  IF v_count > 0 THEN
    RETURN QUERY SELECT FALSE, 'Không thể xóa: còn '|| v_count ||' nhân viên đang sử dụng chức vụ này';
    RETURN;
  END IF;
  DELETE FROM public.positions WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa thành công'::TEXT;
END;
$$;

-- ══════════════════════════════════════════════
-- 3. STAFF (Người dùng)
-- ══════════════════════════════════════════════

-- 3.1 Danh sách nhân viên (phân trang + filter)
CREATE OR REPLACE FUNCTION public.fn_staff_get_list(
  p_unit_id INT DEFAULT NULL,
  p_department_id INT DEFAULT NULL,
  p_keyword VARCHAR DEFAULT NULL,
  p_is_locked BOOLEAN DEFAULT NULL,
  p_page INT DEFAULT 1,
  p_page_size INT DEFAULT 20
)
RETURNS TABLE (
  id INT, username VARCHAR, full_name VARCHAR, first_name VARCHAR, last_name VARCHAR,
  email VARCHAR, phone VARCHAR, image VARCHAR, gender SMALLINT,
  department_id INT, department_name VARCHAR, unit_id INT, unit_name VARCHAR,
  position_id INT, position_name VARCHAR,
  is_admin BOOLEAN, is_locked BOOLEAN, is_represent_unit BOOLEAN, is_represent_department BOOLEAN,
  last_login_at TIMESTAMPTZ, created_at TIMESTAMPTZ, total_count BIGINT
)
LANGUAGE sql STABLE
AS $$
  SELECT
    s.id, s.username::VARCHAR, s.full_name::VARCHAR, s.first_name::VARCHAR, s.last_name::VARCHAR,
    s.email::VARCHAR, COALESCE(s.phone, s.mobile)::VARCHAR AS phone, s.image::VARCHAR, s.gender,
    s.department_id, d.name::VARCHAR AS department_name,
    s.unit_id, u.name::VARCHAR AS unit_name,
    s.position_id, p.name::VARCHAR AS position_name,
    s.is_admin, s.is_locked, s.is_represent_unit, s.is_represent_department,
    s.last_login_at, s.created_at,
    COUNT(*) OVER() AS total_count
  FROM public.staff s
  LEFT JOIN public.departments d ON d.id = s.department_id
  LEFT JOIN public.departments u ON u.id = s.unit_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  WHERE s.is_deleted = FALSE
    AND (p_unit_id IS NULL OR s.unit_id = p_unit_id)
    AND (p_department_id IS NULL OR s.department_id = p_department_id)
    AND (p_keyword IS NULL OR s.full_name ILIKE '%' || p_keyword || '%' OR s.username ILIKE '%' || p_keyword || '%' OR s.email ILIKE '%' || p_keyword || '%')
    AND (p_is_locked IS NULL OR s.is_locked = p_is_locked)
  ORDER BY s.last_name, s.first_name
  OFFSET (p_page - 1) * p_page_size LIMIT p_page_size;
$$;

-- 3.2 Chi tiết nhân viên
CREATE OR REPLACE FUNCTION public.fn_staff_get_by_id(p_id INT)
RETURNS TABLE (
  id INT, username VARCHAR, full_name VARCHAR, first_name VARCHAR, last_name VARCHAR,
  email VARCHAR, phone VARCHAR, mobile VARCHAR, image VARCHAR,
  gender SMALLINT, birth_date DATE, address TEXT,
  id_card VARCHAR, id_card_date DATE, id_card_place VARCHAR,
  department_id INT, department_name VARCHAR, unit_id INT, unit_name VARCHAR,
  position_id INT, position_name VARCHAR,
  is_admin BOOLEAN, is_locked BOOLEAN,
  is_represent_unit BOOLEAN, is_represent_department BOOLEAN,
  last_login_at TIMESTAMPTZ, created_at TIMESTAMPTZ,
  roles TEXT
)
LANGUAGE sql STABLE
AS $$
  SELECT
    s.id, s.username::VARCHAR, s.full_name::VARCHAR, s.first_name::VARCHAR, s.last_name::VARCHAR,
    s.email::VARCHAR, s.phone::VARCHAR, s.mobile::VARCHAR, s.image::VARCHAR,
    s.gender, s.birth_date, s.address,
    s.id_card::VARCHAR, s.id_card_date, s.id_card_place::VARCHAR,
    s.department_id, d.name::VARCHAR, s.unit_id, u.name::VARCHAR,
    s.position_id, p.name::VARCHAR,
    s.is_admin, s.is_locked, s.is_represent_unit, s.is_represent_department,
    s.last_login_at, s.created_at,
    COALESCE((SELECT string_agg(r.name, ',') FROM public.role_of_staff ros JOIN public.roles r ON r.id = ros.role_id WHERE ros.staff_id = s.id), '')::TEXT AS roles
  FROM public.staff s
  LEFT JOIN public.departments d ON d.id = s.department_id
  LEFT JOIN public.departments u ON u.id = s.unit_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  WHERE s.id = p_id AND s.is_deleted = FALSE;
$$;

-- 3.3 Tạo nhân viên
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
DECLARE v_id INT;
BEGIN
  -- Check unique username
  IF EXISTS (SELECT 1 FROM public.staff WHERE username = p_username AND is_deleted = FALSE) THEN
    RETURN QUERY SELECT 0, 'Tên đăng nhập đã tồn tại'::TEXT;
    RETURN;
  END IF;

  INSERT INTO public.staff (
    department_id, unit_id, position_id, username, password_hash,
    first_name, last_name, gender, birth_date, email, phone, mobile,
    address, id_card, id_card_date, id_card_place,
    is_admin, is_represent_unit, is_represent_department, created_by
  ) VALUES (
    p_department_id, p_unit_id, p_position_id, p_username, p_password_hash,
    p_first_name, p_last_name, p_gender, p_birth_date, p_email, p_phone, p_mobile,
    p_address, p_id_card, p_id_card_date, p_id_card_place,
    p_is_admin, p_is_represent_unit, p_is_represent_department, p_created_by
  ) RETURNING staff.id INTO v_id;

  RETURN QUERY SELECT v_id, 'Tạo thành công'::TEXT;
END;
$$;

-- 3.4 Cập nhật
CREATE OR REPLACE FUNCTION public.fn_staff_update(
  p_id INT, p_department_id INT, p_unit_id INT, p_position_id INT,
  p_first_name VARCHAR, p_last_name VARCHAR, p_gender SMALLINT,
  p_birth_date DATE, p_email VARCHAR, p_phone VARCHAR, p_mobile VARCHAR,
  p_address TEXT, p_id_card VARCHAR, p_id_card_date DATE, p_id_card_place VARCHAR,
  p_is_admin BOOLEAN, p_is_represent_unit BOOLEAN, p_is_represent_department BOOLEAN,
  p_updated_by INT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.staff SET
    department_id = p_department_id, unit_id = p_unit_id, position_id = p_position_id,
    first_name = p_first_name, last_name = p_last_name, gender = p_gender,
    birth_date = p_birth_date, email = p_email, phone = p_phone, mobile = p_mobile,
    address = p_address, id_card = p_id_card, id_card_date = p_id_card_date,
    id_card_place = p_id_card_place, is_admin = p_is_admin,
    is_represent_unit = p_is_represent_unit, is_represent_department = p_is_represent_department,
    updated_by = p_updated_by
  WHERE id = p_id AND is_deleted = FALSE;
  RETURN FOUND;
END;
$$;

-- 3.5 Xóa (soft)
CREATE OR REPLACE FUNCTION public.fn_staff_delete(p_id INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.staff SET is_deleted = TRUE WHERE id = p_id AND is_deleted = FALSE;
  RETURN FOUND;
END;
$$;

-- 3.6 Khóa / Mở khóa
CREATE OR REPLACE FUNCTION public.fn_staff_toggle_lock(p_id INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.staff SET is_locked = NOT is_locked WHERE id = p_id AND is_deleted = FALSE;
  RETURN FOUND;
END;
$$;

-- 3.7 Reset mật khẩu
CREATE OR REPLACE FUNCTION public.fn_staff_reset_password(p_id INT, p_new_password_hash VARCHAR)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.staff SET password_hash = p_new_password_hash WHERE id = p_id AND is_deleted = FALSE;
  RETURN FOUND;
END;
$$;

-- 3.8 Upload avatar
CREATE OR REPLACE FUNCTION public.fn_staff_update_avatar(p_id INT, p_image_path VARCHAR)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.staff SET image = p_image_path WHERE id = p_id AND is_deleted = FALSE;
  RETURN FOUND;
END;
$$;

-- ══════════════════════════════════════════════
-- 4. ROLE (Nhóm quyền)
-- ══════════════════════════════════════════════

-- 4.1 Danh sách nhóm quyền
CREATE OR REPLACE FUNCTION public.fn_role_get_list(
  p_unit_id INT DEFAULT NULL,
  p_keyword VARCHAR DEFAULT NULL
)
RETURNS TABLE (
  id INT, name VARCHAR, description TEXT, unit_id INT,
  is_locked BOOLEAN, staff_count BIGINT, created_at TIMESTAMPTZ
)
LANGUAGE sql STABLE
AS $$
  SELECT r.id, r.name::VARCHAR, r.description, r.unit_id,
    r.is_locked,
    (SELECT COUNT(*) FROM public.role_of_staff ros WHERE ros.role_id = r.id) AS staff_count,
    r.created_at
  FROM public.roles r
  WHERE (p_unit_id IS NULL OR r.unit_id = p_unit_id OR r.unit_id IS NULL)
    AND (p_keyword IS NULL OR r.name ILIKE '%' || p_keyword || '%')
  ORDER BY r.name;
$$;

-- 4.2 Chi tiết
CREATE OR REPLACE FUNCTION public.fn_role_get_by_id(p_id INT)
RETURNS TABLE (id INT, name VARCHAR, description TEXT, unit_id INT, is_locked BOOLEAN)
LANGUAGE sql STABLE
AS $$
  SELECT r.id, r.name::VARCHAR, r.description, r.unit_id, r.is_locked FROM public.roles r WHERE r.id = p_id;
$$;

-- 4.3 Tạo
CREATE OR REPLACE FUNCTION public.fn_role_create(p_unit_id INT, p_name VARCHAR, p_description TEXT, p_created_by INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE v_id INT;
BEGIN
  INSERT INTO public.roles (unit_id, name, description, created_by)
  VALUES (p_unit_id, p_name, p_description, p_created_by)
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$$;

-- 4.4 Cập nhật
CREATE OR REPLACE FUNCTION public.fn_role_update(p_id INT, p_name VARCHAR, p_description TEXT, p_updated_by INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.roles SET name = p_name, description = p_description, updated_by = p_updated_by WHERE id = p_id;
  RETURN FOUND;
END;
$$;

-- 4.5 Xóa
CREATE OR REPLACE FUNCTION public.fn_role_delete(p_id INT)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM public.role_of_staff WHERE role_id = p_id;
  IF v_count > 0 THEN
    RETURN QUERY SELECT FALSE, 'Không thể xóa: còn '|| v_count ||' nhân viên trong nhóm quyền này';
    RETURN;
  END IF;
  DELETE FROM public.action_of_role WHERE role_id = p_id;
  DELETE FROM public.roles WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa thành công'::TEXT;
END;
$$;

-- 4.6 Lấy danh sách quyền (right_id) của role
CREATE OR REPLACE FUNCTION public.fn_role_get_rights(p_role_id INT)
RETURNS TABLE (right_id INT)
LANGUAGE sql STABLE
AS $$
  SELECT aor.right_id FROM public.action_of_role aor WHERE aor.role_id = p_role_id;
$$;

-- 4.7 Gán quyền cho role (replace all)
CREATE OR REPLACE FUNCTION public.fn_role_assign_rights(p_role_id INT, p_right_ids INT[])
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM public.action_of_role WHERE role_id = p_role_id;
  INSERT INTO public.action_of_role (role_id, right_id)
  SELECT p_role_id, unnest(p_right_ids)
  ON CONFLICT DO NOTHING;
END;
$$;

-- 4.8 Lấy roles của nhân viên
CREATE OR REPLACE FUNCTION public.fn_staff_get_roles(p_staff_id INT)
RETURNS TABLE (role_id INT, role_name VARCHAR)
LANGUAGE sql STABLE
AS $$
  SELECT r.id, r.name::VARCHAR
  FROM public.role_of_staff ros
  JOIN public.roles r ON r.id = ros.role_id
  WHERE ros.staff_id = p_staff_id;
$$;

-- 4.9 Gán roles cho nhân viên (replace all)
CREATE OR REPLACE FUNCTION public.fn_staff_assign_roles(p_staff_id INT, p_role_ids INT[])
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM public.role_of_staff WHERE staff_id = p_staff_id;
  INSERT INTO public.role_of_staff (staff_id, role_id)
  SELECT p_staff_id, unnest(p_role_ids)
  ON CONFLICT DO NOTHING;
END;
$$;

-- ══════════════════════════════════════════════
-- 5. RIGHT (Chức năng / Menu)
-- ══════════════════════════════════════════════

-- 5.1 Lấy toàn bộ cây chức năng
CREATE OR REPLACE FUNCTION public.fn_right_get_tree()
RETURNS TABLE (
  id INT, parent_id INT, name VARCHAR, name_of_menu VARCHAR,
  action_link VARCHAR, icon VARCHAR, sort_order INT,
  show_menu BOOLEAN, default_page BOOLEAN, show_in_app BOOLEAN,
  description TEXT, is_locked BOOLEAN
)
LANGUAGE sql STABLE
AS $$
  SELECT r.id, r.parent_id, r.name::VARCHAR, r.name_of_menu::VARCHAR,
    r.action_link::VARCHAR, r.icon::VARCHAR, r.sort_order,
    r.show_menu, r.default_page, r.show_in_app,
    r.description, r.is_locked
  FROM public.rights r
  ORDER BY r.sort_order, r.name;
$$;

-- 5.2 Chi tiết
CREATE OR REPLACE FUNCTION public.fn_right_get_by_id(p_id INT)
RETURNS TABLE (
  id INT, parent_id INT, name VARCHAR, name_of_menu VARCHAR,
  action_link VARCHAR, icon VARCHAR, sort_order INT,
  show_menu BOOLEAN, default_page BOOLEAN, show_in_app BOOLEAN,
  description TEXT, is_locked BOOLEAN
)
LANGUAGE sql STABLE
AS $$
  SELECT r.id, r.parent_id, r.name::VARCHAR, r.name_of_menu::VARCHAR,
    r.action_link::VARCHAR, r.icon::VARCHAR, r.sort_order,
    r.show_menu, r.default_page, r.show_in_app,
    r.description, r.is_locked
  FROM public.rights r WHERE r.id = p_id;
$$;

-- 5.3 Tạo
CREATE OR REPLACE FUNCTION public.fn_right_create(
  p_parent_id INT, p_name VARCHAR, p_name_of_menu VARCHAR,
  p_action_link VARCHAR, p_icon VARCHAR, p_sort_order INT,
  p_show_menu BOOLEAN, p_default_page BOOLEAN, p_show_in_app BOOLEAN,
  p_description TEXT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE v_id INT;
BEGIN
  INSERT INTO public.rights (parent_id, name, name_of_menu, action_link, icon,
    sort_order, show_menu, default_page, show_in_app, description)
  VALUES (p_parent_id, p_name, p_name_of_menu, p_action_link, p_icon,
    p_sort_order, p_show_menu, p_default_page, p_show_in_app, p_description)
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$$;

-- 5.4 Cập nhật
CREATE OR REPLACE FUNCTION public.fn_right_update(
  p_id INT, p_parent_id INT, p_name VARCHAR, p_name_of_menu VARCHAR,
  p_action_link VARCHAR, p_icon VARCHAR, p_sort_order INT,
  p_show_menu BOOLEAN, p_default_page BOOLEAN, p_show_in_app BOOLEAN,
  p_description TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.rights SET parent_id = p_parent_id, name = p_name,
    name_of_menu = p_name_of_menu, action_link = p_action_link, icon = p_icon,
    sort_order = p_sort_order, show_menu = p_show_menu, default_page = p_default_page,
    show_in_app = p_show_in_app, description = p_description
  WHERE id = p_id;
  RETURN FOUND;
END;
$$;

-- 5.5 Xóa
CREATE OR REPLACE FUNCTION public.fn_right_delete(p_id INT)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM public.rights WHERE parent_id = p_id;
  IF v_count > 0 THEN
    RETURN QUERY SELECT FALSE, 'Không thể xóa: còn '|| v_count ||' chức năng con';
    RETURN;
  END IF;
  DELETE FROM public.action_of_role WHERE right_id = p_id;
  DELETE FROM public.rights WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa thành công'::TEXT;
END;
$$;

-- 5.6 Lấy menu theo quyền user
CREATE OR REPLACE FUNCTION public.fn_right_get_by_staff(p_staff_id INT)
RETURNS TABLE (
  id INT, parent_id INT, name VARCHAR, name_of_menu VARCHAR,
  action_link VARCHAR, icon VARCHAR, sort_order INT,
  show_menu BOOLEAN, default_page BOOLEAN, show_in_app BOOLEAN
)
LANGUAGE sql STABLE
AS $$
  SELECT r.id, r.parent_id, r.name::VARCHAR, r.name_of_menu::VARCHAR,
    r.action_link::VARCHAR, r.icon::VARCHAR, r.sort_order,
    r.show_menu, r.default_page, r.show_in_app
  FROM public.rights r
  WHERE r.show_menu = TRUE
    AND (
      EXISTS (
        SELECT 1 FROM public.action_of_role aor
        JOIN public.role_of_staff ros ON ros.role_id = aor.role_id
        WHERE aor.right_id = r.id AND ros.staff_id = p_staff_id
      )
      OR EXISTS (
        SELECT 1 FROM public.staff s WHERE s.id = p_staff_id AND s.is_admin = TRUE
      )
    )
  ORDER BY r.sort_order, r.name;
$$;

-- ══════════════════════════════════════════════
-- SEED: Menu mặc định
-- ══════════════════════════════════════════════
INSERT INTO public.rights (id, parent_id, name, name_of_menu, action_link, icon, sort_order, show_menu) VALUES
  (1, NULL, 'Tổng quan', 'Tổng quan', '/dashboard', 'DashboardOutlined', 1, TRUE),
  (2, NULL, 'Văn bản', 'Văn bản', NULL, 'FileTextOutlined', 2, TRUE),
  (3, 2, 'Văn bản đến', 'Văn bản đến', '/van-ban/den', 'InboxOutlined', 1, TRUE),
  (4, 2, 'Văn bản đi', 'Văn bản đi', '/van-ban/di', 'SendOutlined', 2, TRUE),
  (5, 2, 'Văn bản dự thảo', 'Văn bản dự thảo', '/van-ban/du-thao', 'EditOutlined', 3, TRUE),
  (6, 2, 'Văn bản liên thông', 'Văn bản liên thông', '/van-ban/lien-thong', 'SwapOutlined', 4, TRUE),
  (7, NULL, 'Hồ sơ công việc', 'Hồ sơ công việc', '/ho-so-cong-viec', 'FolderOpenOutlined', 3, TRUE),
  (8, NULL, 'Tin nhắn', 'Tin nhắn', '/tin-nhan', 'MessageOutlined', 4, TRUE),
  (9, NULL, 'Tiện ích', 'Tiện ích', NULL, 'AppstoreOutlined', 5, TRUE),
  (10, 9, 'Thông báo', 'Thông báo', '/tien-ich/thong-bao', 'BellOutlined', 1, TRUE),
  (11, 9, 'Lịch cá nhân', 'Lịch cá nhân', '/tien-ich/lich-ca-nhan', 'CalendarOutlined', 2, TRUE),
  (12, 9, 'Lịch cơ quan', 'Lịch cơ quan', '/tien-ich/lich-co-quan', 'ScheduleOutlined', 3, TRUE),
  (13, 9, 'Lịch lãnh đạo', 'Lịch lãnh đạo', '/tien-ich/lich-lanh-dao', 'TeamOutlined', 4, TRUE),
  (14, 9, 'Danh bạ', 'Danh bạ', '/tien-ich/danh-ba', 'ContactsOutlined', 5, TRUE),
  (15, NULL, 'Họp không giấy', 'Họp không giấy', '/hop-khong-giay', 'VideoCameraOutlined', 6, TRUE),
  (16, NULL, 'Hợp đồng', 'Hợp đồng', '/hop-dong', 'AuditOutlined', 7, TRUE),
  (17, NULL, 'Kho lưu trữ', 'Kho lưu trữ', '/kho-luu-tru', 'DatabaseOutlined', 8, TRUE),
  (18, NULL, 'Tài liệu', 'Tài liệu', '/tai-lieu', 'ReadOutlined', 9, TRUE),
  (19, NULL, 'Quản trị hệ thống', 'Quản trị', NULL, 'SettingOutlined', 100, TRUE),
  (20, 19, 'Đơn vị / Phòng ban', 'Đơn vị', '/quan-tri/don-vi', 'ApartmentOutlined', 1, TRUE),
  (21, 19, 'Chức vụ', 'Chức vụ', '/quan-tri/chuc-vu', 'IdcardOutlined', 2, TRUE),
  (22, 19, 'Người dùng', 'Người dùng', '/quan-tri/nguoi-dung', 'UserOutlined', 3, TRUE),
  (23, 19, 'Nhóm quyền', 'Nhóm quyền', '/quan-tri/nhom-quyen', 'KeyOutlined', 4, TRUE),
  (24, 19, 'Chức năng', 'Chức năng', '/quan-tri/chuc-nang', 'MenuOutlined', 5, TRUE),
  (25, 19, 'Danh mục văn bản', 'Danh mục VB', '/quan-tri/danh-muc-vb', 'BookOutlined', 6, TRUE),
  (26, 19, 'Cấu hình', 'Cấu hình', '/quan-tri/cau-hinh', 'ToolOutlined', 7, TRUE)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name, name_of_menu = EXCLUDED.name_of_menu,
  action_link = EXCLUDED.action_link, icon = EXCLUDED.icon,
  sort_order = EXCLUDED.sort_order, show_menu = EXCLUDED.show_menu,
  parent_id = EXCLUDED.parent_id;

-- Reset sequence
SELECT setval('rights_id_seq', (SELECT MAX(id) FROM public.rights));

-- Gán tất cả quyền cho role "Quản trị hệ thống"
INSERT INTO public.action_of_role (role_id, right_id)
SELECT
  (SELECT id FROM public.roles WHERE name = 'Quản trị hệ thống' LIMIT 1),
  r.id
FROM public.rights r
ON CONFLICT DO NOTHING;
