-- ============================================
-- MIGRATION 001: Bảng hệ thống (public schema)
-- Departments, Positions, Staff, Roles, Rights
-- ============================================

-- ==========================================
-- 1. CHỨC VỤ (Positions)
-- ==========================================
CREATE TABLE IF NOT EXISTS public.positions (
  id            SERIAL PRIMARY KEY,
  name          VARCHAR(100) NOT NULL,
  code          VARCHAR(20),
  sort_order    INT DEFAULT 0,
  is_active     BOOLEAN DEFAULT TRUE,
  description   TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.positions IS 'Danh mục chức vụ: Giám đốc, Phó GĐ, Trưởng phòng, Chuyên viên, Văn thư...';

INSERT INTO public.positions (name, code, sort_order) VALUES
  ('Giám đốc', 'GD', 1),
  ('Phó Giám đốc', 'PGD', 2),
  ('Trưởng phòng', 'TP', 3),
  ('Phó Trưởng phòng', 'PTP', 4),
  ('Chuyên viên', 'CV', 5),
  ('Văn thư', 'VT', 6)
ON CONFLICT DO NOTHING;

-- ==========================================
-- 2. ĐƠN VỊ / PHÒNG BAN (Departments) — Tree
-- ==========================================
CREATE TABLE IF NOT EXISTS public.departments (
  id            SERIAL PRIMARY KEY,
  parent_id     INT REFERENCES public.departments(id) ON DELETE SET NULL,
  code          VARCHAR(50),
  name          VARCHAR(200) NOT NULL,
  name_en       VARCHAR(200),
  short_name    VARCHAR(50),
  abb_name      VARCHAR(20),
  is_unit       BOOLEAN DEFAULT FALSE,        -- TRUE = đơn vị gốc, FALSE = phòng ban
  level         INT DEFAULT 0,                -- 0 = root, 1 = đơn vị, 2 = phòng ban
  sort_order    INT DEFAULT 0,
  allow_doc_book BOOLEAN DEFAULT FALSE,
  description   TEXT,

  -- Thông tin liên lạc
  phone         VARCHAR(20),
  fax           VARCHAR(20),
  email         VARCHAR(100),
  address       TEXT,

  -- LGSP integration
  lgsp_system_id  VARCHAR(50),
  lgsp_secret_key VARCHAR(100),

  -- Trạng thái
  is_locked     BOOLEAN DEFAULT FALSE,
  is_deleted    BOOLEAN DEFAULT FALSE,

  -- Audit
  created_by    INT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_by    INT,
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_departments_parent ON public.departments(parent_id);
CREATE INDEX idx_departments_is_unit ON public.departments(is_unit) WHERE is_deleted = FALSE;

COMMENT ON TABLE public.departments IS 'Cây tổ chức: Đơn vị → Phòng ban (self-referencing tree)';

-- ==========================================
-- 3. NHÂN VIÊN / NGƯỜI DÙNG (Staff)
-- ==========================================
CREATE TABLE IF NOT EXISTS public.staff (
  id              SERIAL PRIMARY KEY,
  department_id   INT NOT NULL REFERENCES public.departments(id),
  unit_id         INT NOT NULL REFERENCES public.departments(id),  -- Đơn vị gốc
  position_id     INT REFERENCES public.positions(id),

  -- Tài khoản
  username        VARCHAR(50) NOT NULL UNIQUE,
  password_hash   VARCHAR(200) NOT NULL,
  is_admin        BOOLEAN DEFAULT FALSE,

  -- Thông tin cá nhân
  first_name      VARCHAR(50),
  last_name       VARCHAR(50) NOT NULL,
  full_name       VARCHAR(100) GENERATED ALWAYS AS (
    CASE WHEN first_name IS NOT NULL THEN first_name || ' ' || last_name ELSE last_name END
  ) STORED,
  gender          SMALLINT DEFAULT 0,          -- 0=Chưa xác định, 1=Nam, 2=Nữ
  birth_date      DATE,
  email           VARCHAR(100),
  phone           VARCHAR(20),
  mobile          VARCHAR(20),
  address         TEXT,
  image           VARCHAR(500),                -- Path ảnh trên MinIO

  -- CMND/CCCD
  id_card         VARCHAR(20),
  id_card_date    DATE,
  id_card_place   VARCHAR(200),

  -- Ký số
  digital_cert    TEXT,                        -- Chứng thư số (base64)

  -- Đại diện
  is_represent_unit       BOOLEAN DEFAULT FALSE,  -- Đại diện pháp lý đơn vị
  is_represent_department BOOLEAN DEFAULT FALSE,  -- Đại diện phòng ban

  -- Trạng thái
  is_locked       BOOLEAN DEFAULT FALSE,
  is_deleted      BOOLEAN DEFAULT FALSE,
  last_login_at   TIMESTAMPTZ,

  -- Audit
  created_by      INT,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_by      INT,
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_staff_department ON public.staff(department_id) WHERE is_deleted = FALSE;
CREATE INDEX idx_staff_unit ON public.staff(unit_id) WHERE is_deleted = FALSE;
CREATE INDEX idx_staff_username ON public.staff(username);
CREATE INDEX idx_staff_fullname ON public.staff USING gin(full_name gin_trgm_ops);

COMMENT ON TABLE public.staff IS 'Người dùng hệ thống — cán bộ nhân viên';

-- ==========================================
-- 4. NHÓM QUYỀN (Roles)
-- ==========================================
CREATE TABLE IF NOT EXISTS public.roles (
  id            SERIAL PRIMARY KEY,
  unit_id       INT REFERENCES public.departments(id),
  name          VARCHAR(100) NOT NULL,
  description   TEXT,
  is_locked     BOOLEAN DEFAULT FALSE,
  created_by    INT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_by    INT,
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.roles IS 'Nhóm quyền: Ban Lãnh đạo, Cán bộ, Chỉ đạo điều hành, Trưởng phòng, Quản trị, Văn thư';

INSERT INTO public.roles (name, description) VALUES
  ('Ban Lãnh đạo', 'Ban lãnh đạo Công ty'),
  ('Cán bộ', 'Cán bộ, Chuyên viên'),
  ('Chỉ đạo điều hành', 'Chỉ đạo điều hành'),
  ('Nhóm Trưởng phòng', 'Nhóm Trưởng phòng'),
  ('Quản trị hệ thống', 'Quản trị hệ thống'),
  ('Văn thư', 'Văn thư')
ON CONFLICT DO NOTHING;

-- ==========================================
-- 5. CHỨC NĂNG / MENU (Rights)
-- ==========================================
CREATE TABLE IF NOT EXISTS public.rights (
  id              SERIAL PRIMARY KEY,
  parent_id       INT REFERENCES public.rights(id) ON DELETE SET NULL,
  name            VARCHAR(200) NOT NULL,         -- Tên chức năng
  name_of_menu    VARCHAR(200),                  -- Tên hiển thị trên menu
  action_link     VARCHAR(500),                  -- URL / route path
  icon            VARCHAR(100),                  -- Icon class name
  sort_order      INT DEFAULT 0,
  show_menu       BOOLEAN DEFAULT TRUE,          -- Hiển thị trên menu
  default_page    BOOLEAN DEFAULT FALSE,         -- Trang mặc định khi login
  show_in_app     BOOLEAN DEFAULT FALSE,         -- Hiển thị trên mobile app
  description     TEXT,
  is_locked       BOOLEAN DEFAULT FALSE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_rights_parent ON public.rights(parent_id);

COMMENT ON TABLE public.rights IS 'Cây chức năng/menu hệ thống — phân quyền theo chức năng';

-- ==========================================
-- 6. QUYỀN CỦA NHÓM (Role ↔ Right)
-- ==========================================
CREATE TABLE IF NOT EXISTS public.action_of_role (
  id        SERIAL PRIMARY KEY,
  role_id   INT NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
  right_id  INT NOT NULL REFERENCES public.rights(id) ON DELETE CASCADE,
  UNIQUE(role_id, right_id)
);

COMMENT ON TABLE public.action_of_role IS 'Gán quyền chức năng cho nhóm quyền';

-- ==========================================
-- 7. NHÓM QUYỀN CỦA NHÂN VIÊN (Staff ↔ Role)
-- ==========================================
CREATE TABLE IF NOT EXISTS public.role_of_staff (
  id        SERIAL PRIMARY KEY,
  staff_id  INT NOT NULL REFERENCES public.staff(id) ON DELETE CASCADE,
  role_id   INT NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
  UNIQUE(staff_id, role_id)
);

COMMENT ON TABLE public.role_of_staff IS 'Gán nhóm quyền cho nhân viên';

-- ==========================================
-- 8. ĐỊA BÀN HÀNH CHÍNH
-- ==========================================
CREATE TABLE IF NOT EXISTS public.provinces (
  id        SERIAL PRIMARY KEY,
  name      VARCHAR(100) NOT NULL,
  code      VARCHAR(10),
  is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS public.districts (
  id          SERIAL PRIMARY KEY,
  province_id INT NOT NULL REFERENCES public.provinces(id),
  name        VARCHAR(100) NOT NULL,
  code        VARCHAR(10),
  is_active   BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS public.communes (
  id          SERIAL PRIMARY KEY,
  district_id INT NOT NULL REFERENCES public.districts(id),
  name        VARCHAR(100) NOT NULL,
  code        VARCHAR(10),
  is_active   BOOLEAN DEFAULT TRUE
);

-- ==========================================
-- 9. CẤU HÌNH HỆ THỐNG (Key-Value)
-- ==========================================
CREATE TABLE IF NOT EXISTS public.configurations (
  id        SERIAL PRIMARY KEY,
  unit_id   INT REFERENCES public.departments(id),
  key       VARCHAR(100) NOT NULL,
  value     TEXT,
  description TEXT,
  UNIQUE(unit_id, key)
);

COMMENT ON TABLE public.configurations IS 'Cấu hình hệ thống dạng key-value theo đơn vị';

-- ==========================================
-- 10. REFRESH TOKEN
-- ==========================================
CREATE TABLE IF NOT EXISTS public.refresh_tokens (
  id          SERIAL PRIMARY KEY,
  staff_id    INT NOT NULL REFERENCES public.staff(id) ON DELETE CASCADE,
  token_hash  VARCHAR(200) NOT NULL,
  expires_at  TIMESTAMPTZ NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  revoked_at  TIMESTAMPTZ
);

CREATE INDEX idx_refresh_tokens_staff ON public.refresh_tokens(staff_id);
CREATE INDEX idx_refresh_tokens_hash ON public.refresh_tokens(token_hash);

COMMENT ON TABLE public.refresh_tokens IS 'Lưu refresh token (hashed) — hỗ trợ revoke và single session';

-- ==========================================
-- 11. NHẬT KÝ ĐĂNG NHẬP
-- ==========================================
CREATE TABLE IF NOT EXISTS public.login_history (
  id          BIGSERIAL PRIMARY KEY,
  staff_id    INT REFERENCES public.staff(id),
  username    VARCHAR(50),
  ip_address  VARCHAR(50),
  user_agent  TEXT,
  success     BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_login_history_staff ON public.login_history(staff_id, created_at DESC);

-- ==========================================
-- FUNCTION: Tự động cập nhật updated_at
-- ==========================================
CREATE OR REPLACE FUNCTION public.fn_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Gắn trigger cho các bảng chính
DO $$
DECLARE
  t TEXT;
BEGIN
  FOR t IN SELECT unnest(ARRAY['positions', 'departments', 'staff', 'roles'])
  LOOP
    EXECUTE format(
      'CREATE TRIGGER trg_%s_updated_at BEFORE UPDATE ON public.%s FOR EACH ROW EXECUTE FUNCTION public.fn_update_timestamp()',
      t, t
    );
  END LOOP;
END $$;

-- ==========================================
-- TẠO TÀI KHOẢN ADMIN MẶC ĐỊNH
-- ==========================================
DO $$
DECLARE
  v_unit_id INT;
  v_dept_id INT;
  v_staff_id INT;
  v_role_id INT;
BEGIN
  -- Tạo đơn vị mặc định
  INSERT INTO public.departments (name, code, is_unit, level)
  VALUES ('Chuyển đổi số Doanh nghiệp', 'CDSDN', TRUE, 0)
  ON CONFLICT DO NOTHING
  RETURNING id INTO v_unit_id;

  IF v_unit_id IS NULL THEN
    SELECT id INTO v_unit_id FROM public.departments WHERE code = 'CDSDN' LIMIT 1;
  END IF;

  -- Tạo tài khoản admin
  -- Password: Admin@123 (bcrypt hash)
  INSERT INTO public.staff (department_id, unit_id, username, password_hash, last_name, first_name, is_admin, position_id)
  VALUES (
    v_unit_id, v_unit_id, 'admin',
    '$2b$12$p4p6gNuqB5AAcAj2rrU4VO8wmkvgtSRykSYbETqj.nqDTFMKjbU0K',
    'Administrator', 'System',
    TRUE,
    (SELECT id FROM public.positions WHERE code = 'GD' LIMIT 1)
  )
  ON CONFLICT (username) DO NOTHING
  RETURNING id INTO v_staff_id;

  -- Gán role Quản trị hệ thống
  IF v_staff_id IS NOT NULL THEN
    SELECT id INTO v_role_id FROM public.roles WHERE name = 'Quản trị hệ thống' LIMIT 1;
    IF v_role_id IS NOT NULL THEN
      INSERT INTO public.role_of_staff (staff_id, role_id) VALUES (v_staff_id, v_role_id)
      ON CONFLICT DO NOTHING;
    END IF;
  END IF;

  RAISE NOTICE '✅ Admin account created: admin / Admin@123';
END $$;
