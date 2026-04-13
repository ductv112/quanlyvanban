-- ============================================
-- MIGRATION 003: Stored Procedures — Authentication
-- sp_auth_login, sp_auth_refresh, sp_auth_logout, sp_auth_get_me
-- ============================================

-- ==========================================
-- 1. LOGIN — Xác thực user, trả về thông tin + roles
-- ==========================================
CREATE OR REPLACE FUNCTION public.sp_auth_login(
  p_username    VARCHAR,
  p_ip_address  VARCHAR DEFAULT NULL,
  p_user_agent  TEXT DEFAULT NULL
)
RETURNS TABLE (
  staff_id          INT,
  username          VARCHAR,
  password_hash     VARCHAR,
  full_name         VARCHAR,
  email             VARCHAR,
  phone             VARCHAR,
  image             VARCHAR,
  is_admin          BOOLEAN,
  is_locked         BOOLEAN,
  is_deleted        BOOLEAN,
  department_id     INT,
  unit_id           INT,
  position_name     VARCHAR,
  department_name   VARCHAR,
  unit_name         VARCHAR,
  roles             TEXT  -- comma-separated role names
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.id              AS staff_id,
    s.username,
    s.password_hash,
    s.full_name::VARCHAR,
    s.email::VARCHAR,
    COALESCE(s.phone, s.mobile)::VARCHAR AS phone,
    s.image::VARCHAR,
    s.is_admin,
    s.is_locked,
    s.is_deleted,
    s.department_id,
    s.unit_id,
    p.name::VARCHAR   AS position_name,
    d.name::VARCHAR   AS department_name,
    u.name::VARCHAR   AS unit_name,
    COALESCE(
      (SELECT string_agg(r.name, ',')
       FROM public.role_of_staff ros
       JOIN public.roles r ON r.id = ros.role_id
       WHERE ros.staff_id = s.id),
      ''
    )::TEXT AS roles
  FROM public.staff s
  LEFT JOIN public.positions p ON p.id = s.position_id
  LEFT JOIN public.departments d ON d.id = s.department_id
  LEFT JOIN public.departments u ON u.id = s.unit_id
  WHERE s.username = p_username;
END;
$$;

COMMENT ON FUNCTION public.sp_auth_login IS 'Lấy thông tin staff theo username để xác thực (password check ở app layer)';

-- ==========================================
-- 2. GHI NHẬN LOGIN HISTORY
-- ==========================================
CREATE OR REPLACE FUNCTION public.sp_auth_log_login(
  p_staff_id    INT,
  p_username    VARCHAR,
  p_ip_address  VARCHAR,
  p_user_agent  TEXT,
  p_success     BOOLEAN
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.login_history (staff_id, username, ip_address, user_agent, success)
  VALUES (p_staff_id, p_username, p_ip_address, p_user_agent, p_success);

  -- Cập nhật last_login_at nếu thành công
  IF p_success AND p_staff_id IS NOT NULL THEN
    UPDATE public.staff SET last_login_at = NOW() WHERE id = p_staff_id;
  END IF;
END;
$$;

COMMENT ON FUNCTION public.sp_auth_log_login IS 'Ghi nhận lịch sử đăng nhập (thành công/thất bại)';

-- ==========================================
-- 3. LƯU REFRESH TOKEN
-- ==========================================
CREATE OR REPLACE FUNCTION public.sp_auth_save_refresh_token(
  p_staff_id    INT,
  p_token_hash  VARCHAR,
  p_expires_at  TIMESTAMPTZ
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  -- Revoke tất cả refresh token cũ của user (single session)
  UPDATE public.refresh_tokens
  SET revoked_at = NOW()
  WHERE staff_id = p_staff_id AND revoked_at IS NULL;

  -- Tạo token mới
  INSERT INTO public.refresh_tokens (staff_id, token_hash, expires_at)
  VALUES (p_staff_id, p_token_hash, p_expires_at);
END;
$$;

COMMENT ON FUNCTION public.sp_auth_save_refresh_token IS 'Lưu refresh token mới, revoke token cũ (single session)';

-- ==========================================
-- 4. VERIFY REFRESH TOKEN
-- ==========================================
CREATE OR REPLACE FUNCTION public.sp_auth_verify_refresh_token(
  p_token_hash VARCHAR
)
RETURNS TABLE (
  staff_id          INT,
  username          VARCHAR,
  full_name         VARCHAR,
  email             VARCHAR,
  phone             VARCHAR,
  image             VARCHAR,
  is_admin          BOOLEAN,
  is_locked         BOOLEAN,
  is_deleted        BOOLEAN,
  department_id     INT,
  unit_id           INT,
  position_name     VARCHAR,
  department_name   VARCHAR,
  unit_name         VARCHAR,
  roles             TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.id              AS staff_id,
    s.username,
    s.full_name::VARCHAR,
    s.email::VARCHAR,
    COALESCE(s.phone, s.mobile)::VARCHAR AS phone,
    s.image::VARCHAR,
    s.is_admin,
    s.is_locked,
    s.is_deleted,
    s.department_id,
    s.unit_id,
    p.name::VARCHAR   AS position_name,
    d.name::VARCHAR   AS department_name,
    u.name::VARCHAR   AS unit_name,
    COALESCE(
      (SELECT string_agg(r.name, ',')
       FROM public.role_of_staff ros
       JOIN public.roles r ON r.id = ros.role_id
       WHERE ros.staff_id = s.id),
      ''
    )::TEXT AS roles
  FROM public.refresh_tokens rt
  JOIN public.staff s ON s.id = rt.staff_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  LEFT JOIN public.departments d ON d.id = s.department_id
  LEFT JOIN public.departments u ON u.id = s.unit_id
  WHERE rt.token_hash = p_token_hash
    AND rt.revoked_at IS NULL
    AND rt.expires_at > NOW();
END;
$$;

COMMENT ON FUNCTION public.sp_auth_verify_refresh_token IS 'Xác thực refresh token, trả về thông tin user';

-- ==========================================
-- 5. LOGOUT — Revoke refresh token
-- ==========================================
CREATE OR REPLACE FUNCTION public.sp_auth_logout(
  p_token_hash VARCHAR
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.refresh_tokens
  SET revoked_at = NOW()
  WHERE token_hash = p_token_hash AND revoked_at IS NULL;
END;
$$;

COMMENT ON FUNCTION public.sp_auth_logout IS 'Revoke refresh token khi logout';

-- ==========================================
-- 6. LOGOUT ALL — Revoke tất cả token của user
-- ==========================================
CREATE OR REPLACE FUNCTION public.sp_auth_logout_all(
  p_staff_id INT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.refresh_tokens
  SET revoked_at = NOW()
  WHERE staff_id = p_staff_id AND revoked_at IS NULL;
END;
$$;

COMMENT ON FUNCTION public.sp_auth_logout_all IS 'Revoke tất cả refresh token của user';

-- ==========================================
-- 7. GET ME — Lấy thông tin user hiện tại
-- ==========================================
CREATE OR REPLACE FUNCTION public.sp_auth_get_me(
  p_staff_id INT
)
RETURNS TABLE (
  staff_id          INT,
  username          VARCHAR,
  full_name         VARCHAR,
  email             VARCHAR,
  phone             VARCHAR,
  image             VARCHAR,
  is_admin          BOOLEAN,
  gender            SMALLINT,
  birth_date        DATE,
  address           TEXT,
  department_id     INT,
  unit_id           INT,
  position_id       INT,
  position_name     VARCHAR,
  department_name   VARCHAR,
  unit_name         VARCHAR,
  roles             TEXT,
  last_login_at     TIMESTAMPTZ,
  created_at        TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.id              AS staff_id,
    s.username,
    s.full_name::VARCHAR,
    s.email::VARCHAR,
    COALESCE(s.phone, s.mobile)::VARCHAR AS phone,
    s.image::VARCHAR,
    s.is_admin,
    s.gender,
    s.birth_date,
    s.address,
    s.department_id,
    s.unit_id,
    s.position_id,
    p.name::VARCHAR   AS position_name,
    d.name::VARCHAR   AS department_name,
    u.name::VARCHAR   AS unit_name,
    COALESCE(
      (SELECT string_agg(r.name, ',')
       FROM public.role_of_staff ros
       JOIN public.roles r ON r.id = ros.role_id
       WHERE ros.staff_id = s.id),
      ''
    )::TEXT AS roles,
    s.last_login_at,
    s.created_at
  FROM public.staff s
  LEFT JOIN public.positions p ON p.id = s.position_id
  LEFT JOIN public.departments d ON d.id = s.department_id
  LEFT JOIN public.departments u ON u.id = s.unit_id
  WHERE s.id = p_staff_id
    AND s.is_deleted = FALSE
    AND s.is_locked = FALSE;
END;
$$;

COMMENT ON FUNCTION public.sp_auth_get_me IS 'Lấy đầy đủ thông tin profile của user hiện tại';

-- ==========================================
-- 8. CLEANUP — Xóa refresh token hết hạn (chạy cron)
-- ==========================================
CREATE OR REPLACE FUNCTION public.sp_auth_cleanup_expired_tokens()
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
  v_count INT;
BEGIN
  DELETE FROM public.refresh_tokens
  WHERE expires_at < NOW() OR revoked_at IS NOT NULL;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

COMMENT ON FUNCTION public.sp_auth_cleanup_expired_tokens IS 'Dọn dẹp refresh token hết hạn hoặc đã revoke';
