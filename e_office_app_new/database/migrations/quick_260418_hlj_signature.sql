-- ============================================================================
-- Migration: quick_260418_hlj_signature
-- Mục đích: Thêm SP cập nhật chữ ký số (sign_phone, sign_ca, sign_image) cho staff
-- Liên quan: Quick task 260418-hlj — HDSD I.4 (SmartCA UI)
-- ============================================================================
-- Lưu ý: public.staff đã có sẵn các cột (verify bằng \d public.staff):
--   - sign_phone VARCHAR(20)
--   - sign_ca TEXT
--   - sign_image VARCHAR(500)
-- public.staff.id là SERIAL (INT) → p_id INT.
-- KHÔNG cần ALTER bảng — chỉ tạo SP mới.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.fn_staff_update_signature(
    p_id INT,
    p_sign_phone VARCHAR DEFAULT NULL,
    p_sign_ca TEXT DEFAULT NULL,
    p_sign_image VARCHAR DEFAULT NULL
)
RETURNS TABLE(success BOOLEAN, message TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.staff WHERE id = p_id AND is_deleted = FALSE) THEN
        RETURN QUERY SELECT FALSE, 'Không tìm thấy nhân viên'::TEXT;
        RETURN;
    END IF;

    UPDATE public.staff
    SET sign_phone = COALESCE(p_sign_phone, sign_phone),
        sign_ca    = COALESCE(p_sign_ca, sign_ca),
        sign_image = COALESCE(p_sign_image, sign_image),
        updated_at = NOW()
    WHERE id = p_id;

    RETURN QUERY SELECT TRUE, 'Cập nhật chữ ký số thành công'::TEXT;
END;
$$;

COMMENT ON FUNCTION public.fn_staff_update_signature(INT, VARCHAR, TEXT, VARCHAR)
    IS 'Cập nhật thông tin chữ ký số (sign_phone/sign_ca/sign_image) cho nhân viên. Param NULL → giữ nguyên giá trị cũ (COALESCE).';

-- ============================================================================
-- Cập nhật fn_auth_get_me để trả thêm sign_phone + sign_image
-- (FE cần để hiển thị section Chữ ký số + preview ảnh chữ ký)
-- DROP trước vì RETURNS TABLE thay đổi cấu trúc — CREATE OR REPLACE không cho phép.
-- ============================================================================

DROP FUNCTION IF EXISTS public.fn_auth_get_me(INT);

CREATE OR REPLACE FUNCTION public.fn_auth_get_me(p_staff_id INT)
RETURNS TABLE(
    staff_id        INT,
    username        VARCHAR,
    full_name       VARCHAR,
    email           VARCHAR,
    phone           VARCHAR,
    image           VARCHAR,
    is_admin        BOOLEAN,
    gender          SMALLINT,
    birth_date      DATE,
    address         TEXT,
    department_id   INT,
    unit_id         INT,
    position_id     INT,
    position_name   VARCHAR,
    department_name VARCHAR,
    unit_name       VARCHAR,
    roles           TEXT,
    last_login_at   TIMESTAMPTZ,
    created_at      TIMESTAMPTZ,
    sign_phone      VARCHAR,
    sign_image      VARCHAR
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
        s.created_at,
        s.sign_phone::VARCHAR,
        s.sign_image::VARCHAR
    FROM public.staff s
    LEFT JOIN public.positions p ON p.id = s.position_id
    LEFT JOIN public.departments d ON d.id = s.department_id
    LEFT JOIN public.departments u ON u.id = s.unit_id
    WHERE s.id = p_staff_id
      AND s.is_deleted = FALSE
      AND s.is_locked = FALSE;
END;
$$;

COMMENT ON FUNCTION public.fn_auth_get_me(INT)
    IS 'Lấy đầy đủ thông tin profile của user hiện tại (kèm sign_phone/sign_image cho HDSD I.4)';
