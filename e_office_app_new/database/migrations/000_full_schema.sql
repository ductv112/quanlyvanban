-- ================================================================
-- FULL SCHEMA — e-Office Quản lý Văn bản
-- Gộp từ: init/01_create_schemas.sql + migrations 001-029
-- Ngày gộp: 2026-04-17
-- Cách dùng: cat database/migrations/000_full_schema.sql | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev
-- ================================================================

-- ============================================
-- KHỞI TẠO SCHEMAS CHO HỆ THỐNG QLVB
-- Chạy tự động khi PostgreSQL container khởi tạo lần đầu
-- ============================================

-- Schema chính: Văn bản điện tử
CREATE SCHEMA IF NOT EXISTS edoc;
COMMENT ON SCHEMA edoc IS 'Văn bản điện tử: VB đến, VB đi, dự thảo, HSCV, workflow, lịch, họp, tin nhắn';

-- Schema hệ thống: Users, Departments, Roles
-- (dùng public schema thay cho dbo của SQL Server)
COMMENT ON SCHEMA public IS 'Hệ thống: users, departments, roles, rights, SMS, email, địa bàn';

-- Schema lưu trữ
CREATE SCHEMA IF NOT EXISTS esto;
COMMENT ON SCHEMA esto IS 'Kho lưu trữ: phông, hồ sơ, mục lục, kho, kệ, mượn trả';

-- Schema hợp đồng
CREATE SCHEMA IF NOT EXISTS cont;
COMMENT ON SCHEMA cont IS 'Hợp đồng: hợp đồng, phụ lục, đối tác, loại hợp đồng';

-- Schema tài liệu ISO
CREATE SCHEMA IF NOT EXISTS iso;
COMMENT ON SCHEMA iso IS 'Tài liệu: ISO, đào tạo, nội bộ, pháp quy';

-- Extensions hữu ích
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";       -- UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";         -- bcrypt, encryption
CREATE EXTENSION IF NOT EXISTS "unaccent";         -- Bỏ dấu tiếng Việt cho search
CREATE EXTENSION IF NOT EXISTS "pg_trgm";          -- Trigram similarity search

-- Mark unaccent IMMUTABLE để dùng được trong functional index (FTS tiếng Việt)
-- Mặc định unaccent là STABLE, không cho tạo index expression
ALTER FUNCTION public.unaccent(text) IMMUTABLE;
ALTER FUNCTION public.unaccent(regdictionary, text) IMMUTABLE;

-- ============================================
-- Thông báo
-- ============================================
DO $$
BEGIN
  RAISE NOTICE '✅ Schemas created: edoc, esto, cont, iso';
  RAISE NOTICE '✅ Extensions enabled: uuid-ossp, pgcrypto, unaccent, pg_trgm';
END $$;


-- ================================================================
-- Source: 001_system_tables.sql
-- ================================================================

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

-- ================================================================
-- Source: 002_edoc_tables.sql
-- ================================================================

-- ============================================
-- MIGRATION 002: Bảng văn bản điện tử (edoc schema)
-- Core tables cho module Văn bản
-- ============================================

-- ==========================================
-- 1. SỔ VĂN BẢN (DocBook)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.doc_books (
  id          SERIAL PRIMARY KEY,
  unit_id     INT NOT NULL REFERENCES public.departments(id),
  type_id     SMALLINT NOT NULL,               -- 1=VB đến, 2=VB đi, 3=Dự thảo
  name        VARCHAR(200) NOT NULL,
  description TEXT,
  sort_order  INT DEFAULT 0,
  is_default  BOOLEAN DEFAULT FALSE,
  is_deleted  BOOLEAN DEFAULT FALSE,
  created_by  INT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE edoc.doc_books IS 'Sổ văn bản: type_id 1=đến, 2=đi, 3=dự thảo';

-- ==========================================
-- 2. LOẠI VĂN BẢN (DocType)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.doc_types (
  id              SERIAL PRIMARY KEY,
  type_id         SMALLINT NOT NULL,             -- 1=QPPL, 2=Hành chính, 3=Khác
  code            VARCHAR(20) NOT NULL,          -- CV, NQ, QĐ, CT, QC...
  name            VARCHAR(200) NOT NULL,
  description     TEXT,
  sort_order      INT DEFAULT 0,
  notation_type   SMALLINT DEFAULT 0,            -- Kiểu đánh số ký hiệu
  is_default      BOOLEAN DEFAULT FALSE,
  is_deleted      BOOLEAN DEFAULT FALSE,
  created_by      INT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE edoc.doc_types IS 'Loại văn bản: CV=Công văn, NQ=Nghị quyết, QĐ=Quyết định...';

INSERT INTO edoc.doc_types (type_id, code, name, sort_order) VALUES
  (2, 'CV', 'Công văn', 1),
  (1, 'NQ', 'Nghị quyết', 2),
  (1, 'QD', 'Quyết định', 3),
  (1, 'CT', 'Chỉ thị', 4),
  (1, 'QC', 'Quy chế', 5)
ON CONFLICT DO NOTHING;

-- ==========================================
-- 3. LĨNH VỰC VĂN BẢN (DocField)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.doc_fields (
  id          SERIAL PRIMARY KEY,
  unit_id     INT NOT NULL REFERENCES public.departments(id),
  code        VARCHAR(20) NOT NULL,
  name        VARCHAR(200) NOT NULL,
  sort_order  INT DEFAULT 0,
  is_active   BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE edoc.doc_fields IS 'Lĩnh vực văn bản theo đơn vị';

-- ==========================================
-- 4. VĂN BẢN ĐẾN (IncomingDoc)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.incoming_docs (
  id                BIGSERIAL PRIMARY KEY,
  unit_id           INT NOT NULL REFERENCES public.departments(id),

  -- Thông tin chính
  received_date     TIMESTAMPTZ,               -- Ngày đến
  number            INT,                       -- Số đến
  notation          VARCHAR(100),              -- Số ký hiệu
  document_code     VARCHAR(100),              -- Mã văn bản
  abstract          TEXT,                      -- Trích yếu nội dung
  publish_unit      VARCHAR(500),              -- Cơ quan phát hành
  publish_date      TIMESTAMPTZ,               -- Ngày phát hành
  signer            VARCHAR(200),              -- Người ký
  sign_date         TIMESTAMPTZ,               -- Ngày ký

  -- Phân loại
  doc_book_id       INT REFERENCES edoc.doc_books(id),
  doc_type_id       INT REFERENCES edoc.doc_types(id),
  doc_field_id      INT REFERENCES edoc.doc_fields(id),
  secret_id         SMALLINT DEFAULT 1,        -- 1=Thường, 2=Mật, 3=Tối mật, 4=Tuyệt mật
  urgent_id         SMALLINT DEFAULT 1,        -- 1=Thường, 2=Khẩn, 3=Hỏa tốc

  -- Số lượng
  number_paper      INT DEFAULT 1,             -- Số tờ
  number_copies     INT DEFAULT 1,             -- Số bản

  -- Xử lý
  expired_date      TIMESTAMPTZ,               -- Hạn xử lý
  recipients        TEXT,                      -- Nơi nhận (text)
  approver          VARCHAR(200),              -- Người duyệt
  approved          BOOLEAN DEFAULT FALSE,     -- Đã duyệt chưa

  -- Trạng thái
  is_handling       BOOLEAN DEFAULT FALSE,     -- Đã tạo HSCV chưa
  is_received_paper BOOLEAN DEFAULT FALSE,     -- Đã nhận bản giấy
  archive_status    BOOLEAN DEFAULT FALSE,     -- Đã lưu trữ

  -- Liên thông
  is_inter_doc      BOOLEAN DEFAULT FALSE,     -- Là VB liên thông
  inter_doc_id      INT,                       -- ID VB trên trục liên thông

  -- Audit
  created_by        INT NOT NULL REFERENCES public.staff(id),
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_by        INT,
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_incoming_docs_unit ON edoc.incoming_docs(unit_id, received_date DESC);
CREATE INDEX idx_incoming_docs_number ON edoc.incoming_docs(unit_id, number);
CREATE INDEX idx_incoming_docs_notation ON edoc.incoming_docs(notation);
CREATE INDEX idx_incoming_docs_search ON edoc.incoming_docs USING gin(abstract gin_trgm_ops);
-- Full-text search tiếng Việt (bỏ dấu)
CREATE INDEX idx_incoming_docs_fts ON edoc.incoming_docs USING gin(
  to_tsvector('simple', coalesce(unaccent(abstract), '') || ' ' || coalesce(unaccent(notation), '') || ' ' || coalesce(unaccent(publish_unit), ''))
);

COMMENT ON TABLE edoc.incoming_docs IS 'Văn bản đến — bảng chính';

-- ==========================================
-- 5. NGƯỜI NHẬN VĂN BẢN ĐẾN
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.user_incoming_docs (
  id              BIGSERIAL PRIMARY KEY,
  incoming_doc_id BIGINT NOT NULL REFERENCES edoc.incoming_docs(id) ON DELETE CASCADE,
  staff_id        INT NOT NULL REFERENCES public.staff(id),
  is_read         BOOLEAN DEFAULT FALSE,
  read_at         TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(incoming_doc_id, staff_id)
);

CREATE INDEX idx_user_incoming_docs_staff ON edoc.user_incoming_docs(staff_id, is_read);

-- ==========================================
-- 6. FILE ĐÍNH KÈM VĂN BẢN ĐẾN
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.attachment_incoming_docs (
  id              BIGSERIAL PRIMARY KEY,
  incoming_doc_id BIGINT NOT NULL REFERENCES edoc.incoming_docs(id) ON DELETE CASCADE,
  file_name       VARCHAR(500) NOT NULL,
  file_path       VARCHAR(1000) NOT NULL,       -- Path trên MinIO
  file_size       BIGINT DEFAULT 0,
  content_type    VARCHAR(100),
  sort_order      INT DEFAULT 0,
  created_by      INT REFERENCES public.staff(id),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================
-- 7. BÚT PHÊ LÃNH ĐẠO (LeaderNote)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.leader_notes (
  id              BIGSERIAL PRIMARY KEY,
  incoming_doc_id BIGINT NOT NULL REFERENCES edoc.incoming_docs(id) ON DELETE CASCADE,
  staff_id        INT NOT NULL REFERENCES public.staff(id),
  content         TEXT NOT NULL,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================
-- 8. GHI CHÚ CÁ NHÂN (StaffNote — bookmark)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.staff_notes (
  id              BIGSERIAL PRIMARY KEY,
  doc_type        VARCHAR(20) NOT NULL,         -- 'incoming', 'outgoing', 'drafting'
  doc_id          BIGINT NOT NULL,
  staff_id        INT NOT NULL REFERENCES public.staff(id),
  note            TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(doc_type, doc_id, staff_id)
);

-- ==========================================
-- 9. VĂN BẢN ĐI / PHÁT HÀNH (OutgoingDoc)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.outgoing_docs (
  id                BIGSERIAL PRIMARY KEY,
  unit_id           INT NOT NULL REFERENCES public.departments(id),

  received_date     TIMESTAMPTZ,
  number            INT,
  sub_number        VARCHAR(20),
  notation          VARCHAR(100),
  document_code     VARCHAR(100),
  abstract          TEXT,

  -- Đơn vị soạn & phát hành
  drafting_unit_id  INT REFERENCES public.departments(id),
  drafting_user_id  INT REFERENCES public.staff(id),
  publish_unit_id   INT REFERENCES public.departments(id),
  publish_date      TIMESTAMPTZ,

  signer            VARCHAR(200),
  sign_date         TIMESTAMPTZ,
  expired_date      TIMESTAMPTZ,

  number_paper      INT DEFAULT 1,
  number_copies     INT DEFAULT 1,
  secret_id         SMALLINT DEFAULT 1,
  urgent_id         SMALLINT DEFAULT 1,

  recipients        TEXT,
  doc_book_id       INT REFERENCES edoc.doc_books(id),
  doc_type_id       INT REFERENCES edoc.doc_types(id),
  doc_field_id      INT REFERENCES edoc.doc_fields(id),

  approved          BOOLEAN DEFAULT FALSE,
  is_handling       BOOLEAN DEFAULT FALSE,
  archive_status    BOOLEAN DEFAULT FALSE,

  -- Liên thông
  is_inter_doc      BOOLEAN DEFAULT FALSE,
  inter_doc_id      BIGINT,

  -- Ký số
  is_digital_signed SMALLINT DEFAULT 0,        -- 0=chưa ký, 1=đã ký

  created_by        INT NOT NULL REFERENCES public.staff(id),
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_by        INT,
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_outgoing_docs_unit ON edoc.outgoing_docs(unit_id, received_date DESC);
CREATE INDEX idx_outgoing_docs_search ON edoc.outgoing_docs USING gin(abstract gin_trgm_ops);

COMMENT ON TABLE edoc.outgoing_docs IS 'Văn bản đi / phát hành';

-- ==========================================
-- 10. VĂN BẢN DỰ THẢO (DraftingDoc)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.drafting_docs (
  id                BIGSERIAL PRIMARY KEY,
  unit_id           INT NOT NULL REFERENCES public.departments(id),

  received_date     TIMESTAMPTZ,
  number            INT,
  sub_number        VARCHAR(20),
  notation          VARCHAR(100),
  abstract          TEXT,

  drafting_unit_id  INT REFERENCES public.departments(id),
  drafting_user_id  INT REFERENCES public.staff(id),
  publish_unit_id   INT REFERENCES public.departments(id),
  publish_date      TIMESTAMPTZ,

  signer            VARCHAR(200),
  sign_date         TIMESTAMPTZ,

  number_paper      INT DEFAULT 1,
  number_copies     INT DEFAULT 1,
  secret_id         SMALLINT DEFAULT 1,
  urgent_id         SMALLINT DEFAULT 1,

  recipients        TEXT,
  doc_book_id       INT REFERENCES edoc.doc_books(id),
  doc_type_id       INT REFERENCES edoc.doc_types(id),
  doc_field_id      INT REFERENCES edoc.doc_fields(id),

  approved          BOOLEAN DEFAULT FALSE,
  is_released       BOOLEAN DEFAULT FALSE,       -- Đã phát hành thành VB đi
  released_date     TIMESTAMPTZ,

  created_by        INT NOT NULL REFERENCES public.staff(id),
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_by        INT,
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE edoc.drafting_docs IS 'Văn bản dự thảo — khi duyệt xong sẽ chuyển thành VB đi';

-- ==========================================
-- 11. FILE ĐÍNH KÈM VB ĐI + DỰ THẢO
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.attachment_outgoing_docs (
  id              BIGSERIAL PRIMARY KEY,
  outgoing_doc_id BIGINT NOT NULL REFERENCES edoc.outgoing_docs(id) ON DELETE CASCADE,
  file_name       VARCHAR(500) NOT NULL,
  file_path       VARCHAR(1000) NOT NULL,
  file_size       BIGINT DEFAULT 0,
  content_type    VARCHAR(100),
  sort_order      INT DEFAULT 0,
  created_by      INT REFERENCES public.staff(id),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS edoc.attachment_drafting_docs (
  id              BIGSERIAL PRIMARY KEY,
  drafting_doc_id BIGINT NOT NULL REFERENCES edoc.drafting_docs(id) ON DELETE CASCADE,
  file_name       VARCHAR(500) NOT NULL,
  file_path       VARCHAR(1000) NOT NULL,
  file_size       BIGINT DEFAULT 0,
  content_type    VARCHAR(100),
  sort_order      INT DEFAULT 0,
  created_by      INT REFERENCES public.staff(id),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================
-- 12. NGƯỜI NHẬN VB ĐI + DỰ THẢO
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.user_outgoing_docs (
  id              BIGSERIAL PRIMARY KEY,
  outgoing_doc_id BIGINT NOT NULL REFERENCES edoc.outgoing_docs(id) ON DELETE CASCADE,
  staff_id        INT NOT NULL REFERENCES public.staff(id),
  is_read         BOOLEAN DEFAULT FALSE,
  read_at         TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(outgoing_doc_id, staff_id)
);

CREATE TABLE IF NOT EXISTS edoc.user_drafting_docs (
  id              BIGSERIAL PRIMARY KEY,
  drafting_doc_id BIGINT NOT NULL REFERENCES edoc.drafting_docs(id) ON DELETE CASCADE,
  staff_id        INT NOT NULL REFERENCES public.staff(id),
  is_read         BOOLEAN DEFAULT FALSE,
  read_at         TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(drafting_doc_id, staff_id)
);

-- ==========================================
-- 13. HỒ SƠ CÔNG VIỆC (HandlingDoc)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.handling_docs (
  id              BIGSERIAL PRIMARY KEY,
  unit_id         INT NOT NULL REFERENCES public.departments(id),
  department_id   INT REFERENCES public.departments(id),

  name            VARCHAR(500) NOT NULL,         -- Tên HSCV
  abstract        TEXT,                          -- Trích yếu
  comments        TEXT,                          -- Ghi chú
  doc_notation    VARCHAR(100),                  -- Số ký hiệu

  -- Phân loại
  doc_type_id     INT REFERENCES edoc.doc_types(id),
  doc_field_id    INT REFERENCES edoc.doc_fields(id),
  doc_book_id     INT REFERENCES edoc.doc_books(id),

  -- Thời hạn
  start_date      TIMESTAMPTZ,                   -- Ngày mở
  end_date        TIMESTAMPTZ,                   -- Hạn giải quyết
  received_date   TIMESTAMPTZ,

  -- Người liên quan
  curator         INT REFERENCES public.staff(id),  -- Người phụ trách
  signer          INT REFERENCES public.staff(id),  -- Lãnh đạo ký

  -- Trạng thái
  status          SMALLINT DEFAULT 0,            -- 0=Mới, 1=Đang xử lý, 2=Chờ duyệt, 3=Đã duyệt, 4=Hoàn thành, -1=Từ chối, -2=Trả về
  sign_status     SMALLINT DEFAULT 0,
  sign_date       TIMESTAMPTZ,
  progress        SMALLINT DEFAULT 0,            -- 0-100%

  -- Workflow
  workflow_id     INT,
  step            VARCHAR(50),                   -- Bước hiện tại

  -- Hoàn thành
  complete_user_id INT REFERENCES public.staff(id),
  complete_date    TIMESTAMPTZ,

  -- Đơn vị phát hành/soạn thảo
  publish_unit_id  INT REFERENCES public.departments(id),
  publish_name     VARCHAR(500),
  drafting_unit_id INT REFERENCES public.departments(id),
  number           INT,
  sub_number       VARCHAR(20),
  notation         VARCHAR(100),

  -- Liên kết
  parent_id       BIGINT REFERENCES edoc.handling_docs(id),  -- HSCV cha
  root_id         BIGINT,                        -- HSCV gốc
  is_from_doc     BOOLEAN DEFAULT FALSE,         -- Tạo từ văn bản đến

  -- Audit
  created_by      INT NOT NULL REFERENCES public.staff(id),
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_by      INT,
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_handling_docs_unit ON edoc.handling_docs(unit_id, status, start_date DESC);
CREATE INDEX idx_handling_docs_curator ON edoc.handling_docs(curator);
CREATE INDEX idx_handling_docs_search ON edoc.handling_docs USING gin(name gin_trgm_ops);

COMMENT ON TABLE edoc.handling_docs IS 'Hồ sơ công việc — quản lý xử lý văn bản theo workflow';

-- ==========================================
-- 14. LIÊN KẾT HSCV ↔ VĂN BẢN
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.handling_doc_links (
  id              BIGSERIAL PRIMARY KEY,
  handling_doc_id BIGINT NOT NULL REFERENCES edoc.handling_docs(id) ON DELETE CASCADE,
  doc_type        VARCHAR(20) NOT NULL,          -- 'incoming', 'outgoing', 'drafting'
  doc_id          BIGINT NOT NULL,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(handling_doc_id, doc_type, doc_id)
);

-- ==========================================
-- 15. CÁN BỘ XỬ LÝ HSCV
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.staff_handling_docs (
  id              BIGSERIAL PRIMARY KEY,
  handling_doc_id BIGINT NOT NULL REFERENCES edoc.handling_docs(id) ON DELETE CASCADE,
  staff_id        INT NOT NULL REFERENCES public.staff(id),
  role            SMALLINT DEFAULT 1,            -- 1=Phụ trách (Prim), 2=Phối hợp (Coordinator)
  step            VARCHAR(50),
  assigned_at     TIMESTAMPTZ DEFAULT NOW(),
  completed_at    TIMESTAMPTZ
);

CREATE INDEX idx_staff_handling_docs_staff ON edoc.staff_handling_docs(staff_id, handling_doc_id);

-- ==========================================
-- 16. Ý KIẾN XỬ LÝ HSCV
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.opinion_handling_docs (
  id              BIGSERIAL PRIMARY KEY,
  handling_doc_id BIGINT NOT NULL REFERENCES edoc.handling_docs(id) ON DELETE CASCADE,
  staff_id        INT NOT NULL REFERENCES public.staff(id),
  content         TEXT NOT NULL,
  attachment_path VARCHAR(1000),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================
-- 17. FILE ĐÍNH KÈM HSCV
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.attachment_handling_docs (
  id              BIGSERIAL PRIMARY KEY,
  handling_doc_id BIGINT NOT NULL REFERENCES edoc.handling_docs(id) ON DELETE CASCADE,
  file_name       VARCHAR(500) NOT NULL,
  file_path       VARCHAR(1000) NOT NULL,
  file_size       BIGINT DEFAULT 0,
  content_type    VARCHAR(100),
  sort_order      INT DEFAULT 0,
  created_by      INT REFERENCES public.staff(id),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================
-- TRIGGERS
-- ==========================================
CREATE TRIGGER trg_incoming_docs_updated_at
  BEFORE UPDATE ON edoc.incoming_docs
  FOR EACH ROW EXECUTE FUNCTION public.fn_update_timestamp();

CREATE TRIGGER trg_outgoing_docs_updated_at
  BEFORE UPDATE ON edoc.outgoing_docs
  FOR EACH ROW EXECUTE FUNCTION public.fn_update_timestamp();

CREATE TRIGGER trg_drafting_docs_updated_at
  BEFORE UPDATE ON edoc.drafting_docs
  FOR EACH ROW EXECUTE FUNCTION public.fn_update_timestamp();

CREATE TRIGGER trg_handling_docs_updated_at
  BEFORE UPDATE ON edoc.handling_docs
  FOR EACH ROW EXECUTE FUNCTION public.fn_update_timestamp();

-- ================================================================
-- Source: 003_auth_stored_procedures.sql
-- ================================================================

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

-- ================================================================
-- Source: 004_rename_auth_sp_convention.sql
-- ================================================================

-- ============================================
-- MIGRATION 004: Rename Auth SPs theo convention
-- Convention: {schema}.fn_{module}_{action}
-- sp_auth_* → public.fn_auth_*
-- ============================================

-- 1. fn_auth_login
ALTER FUNCTION public.sp_auth_login(VARCHAR, VARCHAR, TEXT)
  RENAME TO fn_auth_login;

-- 2. fn_auth_log_login
ALTER FUNCTION public.sp_auth_log_login(INT, VARCHAR, VARCHAR, TEXT, BOOLEAN)
  RENAME TO fn_auth_log_login;

-- 3. fn_auth_save_refresh_token
ALTER FUNCTION public.sp_auth_save_refresh_token(INT, VARCHAR, TIMESTAMPTZ)
  RENAME TO fn_auth_save_refresh_token;

-- 4. fn_auth_verify_refresh_token
ALTER FUNCTION public.sp_auth_verify_refresh_token(VARCHAR)
  RENAME TO fn_auth_verify_refresh_token;

-- 5. fn_auth_logout
ALTER FUNCTION public.sp_auth_logout(VARCHAR)
  RENAME TO fn_auth_logout;

-- 6. fn_auth_logout_all
ALTER FUNCTION public.sp_auth_logout_all(INT)
  RENAME TO fn_auth_logout_all;

-- 7. fn_auth_get_me
ALTER FUNCTION public.sp_auth_get_me(INT)
  RENAME TO fn_auth_get_me;

-- 8. fn_auth_cleanup_expired_tokens
ALTER FUNCTION public.sp_auth_cleanup_expired_tokens()
  RENAME TO fn_auth_cleanup_expired_tokens;

-- ================================================================
-- Source: 005_sprint1_admin_core_sp.sql
-- ================================================================

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

-- ================================================================
-- Source: 006_sprint1_fix_gaps.sql
-- ================================================================

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

-- ================================================================
-- Source: 007_sprint2_catalog_config.sql
-- ================================================================

-- ============================================
-- MIGRATION 007: Sprint 2 — Danh muc & Cau hinh
-- Sub-modules: 2.1–2.12
--   DocBook, DocType, DocField, DocColumn,
--   Organization, Signer, WorkGroup, Delegation,
--   Province/District/Commune, WorkCalendar,
--   SMS/Email Template, Configuration
-- ============================================

-- ══════════════════════════════════════════════
-- SCHEMA ALTERATIONS (existing tables)
-- ══════════════════════════════════════════════

-- 2.2 DocType: add parent_id for tree structure
ALTER TABLE edoc.doc_types
  ADD COLUMN IF NOT EXISTS parent_id INT REFERENCES edoc.doc_types(id);

-- ══════════════════════════════════════════════
-- NEW TABLES
-- ══════════════════════════════════════════════

-- 2.4 edoc.doc_columns (Thuoc tinh van ban)
CREATE TABLE IF NOT EXISTS edoc.doc_columns (
  id            SERIAL PRIMARY KEY,
  type_id       SMALLINT NOT NULL,                -- 1=den, 2=di, 3=du thao
  column_name   VARCHAR(100) NOT NULL,
  label         VARCHAR(200) NOT NULL,
  is_mandatory  BOOLEAN DEFAULT FALSE,
  is_show_all   BOOLEAN DEFAULT TRUE,
  sort_order    INT DEFAULT 0,
  description   TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(type_id, column_name)
);

COMMENT ON TABLE edoc.doc_columns IS 'Thuoc tinh van ban theo loai (den/di/du thao)';

-- 2.5 edoc.organizations (Thong tin co quan)
CREATE TABLE IF NOT EXISTS edoc.organizations (
  id                SERIAL PRIMARY KEY,
  unit_id           INT NOT NULL REFERENCES public.departments(id) UNIQUE,
  code              VARCHAR(20),
  name              VARCHAR(200),
  address           TEXT,
  phone             VARCHAR(20),
  fax               VARCHAR(20),
  email             VARCHAR(100),
  email_doc         VARCHAR(100),
  secretary         VARCHAR(200),
  chairman_number   VARCHAR(20),
  level             SMALLINT DEFAULT 1,
  is_exchange       BOOLEAN DEFAULT FALSE,
  lgsp_system_id    VARCHAR(50),
  lgsp_secret_key   VARCHAR(100),
  updated_by        INT,
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE edoc.organizations IS 'Thong tin co quan - 1 ban ghi / don vi';

-- 2.6 edoc.signers (Nguoi ky van ban)
CREATE TABLE IF NOT EXISTS edoc.signers (
  id              SERIAL PRIMARY KEY,
  unit_id         INT NOT NULL REFERENCES public.departments(id),
  department_id   INT REFERENCES public.departments(id),
  staff_id        INT NOT NULL REFERENCES public.staff(id),
  sort_order      INT DEFAULT 0,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(unit_id, staff_id)
);

COMMENT ON TABLE edoc.signers IS 'Danh sach nguoi ky van ban theo don vi';

-- 2.7 edoc.work_groups + edoc.work_group_members
CREATE TABLE IF NOT EXISTS edoc.work_groups (
  id          SERIAL PRIMARY KEY,
  unit_id     INT NOT NULL REFERENCES public.departments(id),
  name        VARCHAR(200) NOT NULL,
  function    TEXT,
  sort_order  INT DEFAULT 0,
  is_deleted  BOOLEAN DEFAULT FALSE,
  created_by  INT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE edoc.work_groups IS 'Nhom xu ly cong viec';

CREATE TABLE IF NOT EXISTS edoc.work_group_members (
  id          SERIAL PRIMARY KEY,
  group_id    INT NOT NULL REFERENCES edoc.work_groups(id) ON DELETE CASCADE,
  staff_id    INT NOT NULL REFERENCES public.staff(id),
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(group_id, staff_id)
);

COMMENT ON TABLE edoc.work_group_members IS 'Thanh vien nhom xu ly';

-- 2.8 edoc.delegations (Uy quyen)
CREATE TABLE IF NOT EXISTS edoc.delegations (
  id              SERIAL PRIMARY KEY,
  from_staff_id   INT NOT NULL REFERENCES public.staff(id),
  to_staff_id     INT NOT NULL REFERENCES public.staff(id),
  start_date      DATE NOT NULL,
  end_date        DATE NOT NULL,
  note            TEXT,
  is_revoked      BOOLEAN DEFAULT FALSE,
  revoked_at      TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE edoc.delegations IS 'Uy quyen xu ly van ban';

CREATE INDEX IF NOT EXISTS idx_delegations_from ON edoc.delegations(from_staff_id) WHERE is_revoked = FALSE;
CREATE INDEX IF NOT EXISTS idx_delegations_to   ON edoc.delegations(to_staff_id)   WHERE is_revoked = FALSE;

-- 2.10 public.work_calendar (Lich lam viec — ngay nghi)
CREATE TABLE IF NOT EXISTS public.work_calendar (
  id          SERIAL PRIMARY KEY,
  date        DATE NOT NULL UNIQUE,
  description VARCHAR(200),
  is_holiday  BOOLEAN DEFAULT TRUE,
  created_by  INT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.work_calendar IS 'Lich ngay nghi / ngay le';

-- 2.11 edoc.sms_templates
CREATE TABLE IF NOT EXISTS edoc.sms_templates (
  id          SERIAL PRIMARY KEY,
  unit_id     INT NOT NULL REFERENCES public.departments(id),
  name        VARCHAR(200) NOT NULL,
  content     TEXT NOT NULL,
  description TEXT,
  is_active   BOOLEAN DEFAULT TRUE,
  created_by  INT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE edoc.sms_templates IS 'Mau tin nhan SMS';

-- 2.11 edoc.email_templates
CREATE TABLE IF NOT EXISTS edoc.email_templates (
  id          SERIAL PRIMARY KEY,
  unit_id     INT NOT NULL REFERENCES public.departments(id),
  name        VARCHAR(200) NOT NULL,
  subject     VARCHAR(500),
  content     TEXT NOT NULL,
  description TEXT,
  is_active   BOOLEAN DEFAULT TRUE,
  created_by  INT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE edoc.email_templates IS 'Mau email thong bao (HTML)';

-- ══════════════════════════════════════════════
-- SEED DATA: doc_columns
-- ══════════════════════════════════════════════

-- type_id = 1 (VB den)
INSERT INTO edoc.doc_columns (type_id, column_name, label, is_mandatory, sort_order) VALUES
  (1, 'received_date',  'Ngay den',          TRUE,   1),
  (1, 'number',         'So den',            TRUE,   2),
  (1, 'notation',       'So ky hieu',        FALSE,  3),
  (1, 'abstract',       'Trich yeu',         TRUE,   4),
  (1, 'publish_unit',   'Co quan ban hanh',  FALSE,  5),
  (1, 'signer',         'Nguoi ky',          FALSE,  6),
  (1, 'doc_type_id',    'Loai van ban',      FALSE,  7),
  (1, 'doc_field_id',   'Linh vuc',          FALSE,  8),
  (1, 'urgent_id',      'Do khan',           FALSE,  9),
  (1, 'secret_id',      'Do mat',            FALSE, 10),
  (1, 'expired_date',   'Han xu ly',         FALSE, 11),
  (1, 'doc_book_id',    'So van ban',        FALSE, 12)
ON CONFLICT DO NOTHING;

-- type_id = 2 (VB di)
INSERT INTO edoc.doc_columns (type_id, column_name, label, is_mandatory, sort_order) VALUES
  (2, 'received_date',  'Ngay phat hanh',    TRUE,   1),
  (2, 'number',         'So phat hanh',      TRUE,   2),
  (2, 'notation',       'So ky hieu',        TRUE,   3),
  (2, 'abstract',       'Trich yeu',         TRUE,   4),
  (2, 'publish_unit',   'Don vi soan thao',  FALSE,  5),
  (2, 'signer',         'Nguoi ky',          FALSE,  6),
  (2, 'doc_type_id',    'Loai van ban',      FALSE,  7),
  (2, 'doc_field_id',   'Linh vuc',          FALSE,  8),
  (2, 'urgent_id',      'Do khan',           FALSE,  9),
  (2, 'secret_id',      'Do mat',            FALSE, 10),
  (2, 'recipients',     'Noi nhan',          FALSE, 11),
  (2, 'doc_book_id',    'So van ban',        FALSE, 12)
ON CONFLICT DO NOTHING;

-- type_id = 3 (Du thao)
INSERT INTO edoc.doc_columns (type_id, column_name, label, is_mandatory, sort_order) VALUES
  (3, 'received_date',  'Ngay tao',          TRUE,   1),
  (3, 'notation',       'So ky hieu',        FALSE,  2),
  (3, 'abstract',       'Trich yeu',         TRUE,   3),
  (3, 'publish_unit',   'Don vi soan thao',  FALSE,  4),
  (3, 'signer',         'Nguoi ky',          FALSE,  5),
  (3, 'doc_type_id',    'Loai van ban',      FALSE,  6),
  (3, 'doc_field_id',   'Linh vuc',          FALSE,  7),
  (3, 'urgent_id',      'Do khan',           FALSE,  8),
  (3, 'secret_id',      'Do mat',            FALSE,  9),
  (3, 'doc_book_id',    'So van ban',        FALSE, 10)
ON CONFLICT DO NOTHING;


-- ══════════════════════════════════════════════════════════════════════
-- STORED PROCEDURES
-- ══════════════════════════════════════════════════════════════════════


-- ══════════════════════════════════════════════
-- 2.1 DOC BOOK (So van ban)
-- ══════════════════════════════════════════════

-- 2.1.1 Danh sach so van ban
CREATE OR REPLACE FUNCTION edoc.fn_doc_book_get_list(
  p_type_id  SMALLINT DEFAULT NULL,
  p_unit_id  INT DEFAULT NULL
)
RETURNS TABLE (
  id INT, unit_id INT, type_id SMALLINT, name VARCHAR,
  description TEXT, sort_order INT, is_default BOOLEAN,
  created_by INT, created_at TIMESTAMPTZ
)
LANGUAGE sql STABLE
AS $$
  SELECT b.id, b.unit_id, b.type_id, b.name::VARCHAR,
         b.description, b.sort_order, b.is_default,
         b.created_by, b.created_at
  FROM edoc.doc_books b
  WHERE b.is_deleted = FALSE
    AND (p_type_id IS NULL OR b.type_id = p_type_id)
    AND (p_unit_id IS NULL OR b.unit_id = p_unit_id)
  ORDER BY b.sort_order, b.name;
$$;

-- 2.1.2 Chi tiet
CREATE OR REPLACE FUNCTION edoc.fn_doc_book_get_by_id(p_id INT)
RETURNS TABLE (
  id INT, unit_id INT, type_id SMALLINT, name VARCHAR,
  description TEXT, sort_order INT, is_default BOOLEAN,
  created_by INT, created_at TIMESTAMPTZ
)
LANGUAGE sql STABLE
AS $$
  SELECT b.id, b.unit_id, b.type_id, b.name::VARCHAR,
         b.description, b.sort_order, b.is_default,
         b.created_by, b.created_at
  FROM edoc.doc_books b
  WHERE b.id = p_id AND b.is_deleted = FALSE;
$$;

-- 2.1.3 Tao moi
CREATE OR REPLACE FUNCTION edoc.fn_doc_book_create(
  p_type_id     SMALLINT,
  p_unit_id     INT,
  p_name        VARCHAR,
  p_is_default  BOOLEAN DEFAULT FALSE,
  p_description TEXT DEFAULT NULL,
  p_created_by  INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql
AS $$
DECLARE v_id INT; v_exists BOOLEAN;
BEGIN
  -- Validate
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên sổ văn bản không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF LENGTH(p_name) > 200 THEN
    RETURN QUERY SELECT FALSE, 'Tên sổ văn bản không được vượt quá 200 ký tự'::TEXT, 0;
    RETURN;
  END IF;

  -- Check unique name per type + unit
  SELECT EXISTS(
    SELECT 1 FROM edoc.doc_books
    WHERE type_id = p_type_id AND unit_id = p_unit_id
      AND LOWER(TRIM(name)) = LOWER(TRIM(p_name))
      AND is_deleted = FALSE
  ) INTO v_exists;

  IF v_exists THEN
    RETURN QUERY SELECT FALSE, 'Tên sổ văn bản đã tồn tại trong đơn vị'::TEXT, 0;
    RETURN;
  END IF;

  -- If setting as default, unset others
  IF p_is_default THEN
    UPDATE edoc.doc_books SET is_default = FALSE
    WHERE type_id = p_type_id AND unit_id = p_unit_id AND is_deleted = FALSE;
  END IF;

  INSERT INTO edoc.doc_books (type_id, unit_id, name, is_default, description, created_by)
  VALUES (p_type_id, p_unit_id, TRIM(p_name), COALESCE(p_is_default, FALSE), p_description, p_created_by)
  RETURNING doc_books.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao so van ban thanh cong'::TEXT, v_id;
END;
$$;

-- 2.1.4 Cap nhat
CREATE OR REPLACE FUNCTION edoc.fn_doc_book_update(
  p_id          INT,
  p_name        VARCHAR,
  p_is_default  BOOLEAN DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_sort_order  INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_rec edoc.doc_books%ROWTYPE;
BEGIN
  SELECT * INTO v_rec FROM edoc.doc_books WHERE id = p_id AND is_deleted = FALSE;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy sổ văn bản'::TEXT;
    RETURN;
  END IF;

  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên sổ văn bản không được để trống'::TEXT;
    RETURN;
  END IF;
  IF LENGTH(p_name) > 200 THEN
    RETURN QUERY SELECT FALSE, 'Tên sổ văn bản không được vượt quá 200 ký tự'::TEXT;
    RETURN;
  END IF;

  -- Check unique name (exclude self)
  IF EXISTS(
    SELECT 1 FROM edoc.doc_books
    WHERE type_id = v_rec.type_id AND unit_id = v_rec.unit_id
      AND LOWER(TRIM(name)) = LOWER(TRIM(p_name))
      AND id <> p_id AND is_deleted = FALSE
  ) THEN
    RETURN QUERY SELECT FALSE, 'Tên sổ văn bản đã tồn tại trong đơn vị'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.doc_books SET
    name        = TRIM(p_name),
    is_default  = COALESCE(p_is_default, is_default),
    description = COALESCE(p_description, description),
    sort_order  = COALESCE(p_sort_order, sort_order)
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Cap nhat thanh cong'::TEXT;
END;
$$;

-- 2.1.5 Xoa (soft delete)
CREATE OR REPLACE FUNCTION edoc.fn_doc_book_delete(p_id INT)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.doc_books WHERE id = p_id AND is_deleted = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy sổ văn bản'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.doc_books SET is_deleted = TRUE WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xoa so van ban thanh cong'::TEXT;
END;
$$;

-- 2.1.6 Dat mac dinh
CREATE OR REPLACE FUNCTION edoc.fn_doc_book_set_default(
  p_id      INT,
  p_type_id SMALLINT,
  p_unit_id INT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
  -- Unset all defaults for this type + unit
  UPDATE edoc.doc_books SET is_default = FALSE
  WHERE type_id = p_type_id AND unit_id = p_unit_id AND is_deleted = FALSE;

  -- Set the selected one
  UPDATE edoc.doc_books SET is_default = TRUE
  WHERE id = p_id AND is_deleted = FALSE;

  RETURN FOUND;
END;
$$;


-- ══════════════════════════════════════════════
-- 2.2 DOC TYPE (Loai van ban) — tree
-- ══════════════════════════════════════════════

-- 2.2.1 Cay loai van ban
CREATE OR REPLACE FUNCTION edoc.fn_doc_type_get_tree(p_type_id SMALLINT DEFAULT NULL)
RETURNS TABLE (
  id INT, type_id SMALLINT, parent_id INT, code VARCHAR, name VARCHAR,
  description TEXT, sort_order INT, notation_type SMALLINT,
  is_default BOOLEAN, created_at TIMESTAMPTZ
)
LANGUAGE sql STABLE
AS $$
  SELECT t.id, t.type_id, t.parent_id, t.code::VARCHAR, t.name::VARCHAR,
         t.description, t.sort_order, t.notation_type,
         t.is_default, t.created_at
  FROM edoc.doc_types t
  WHERE t.is_deleted = FALSE
    AND (p_type_id IS NULL OR t.type_id = p_type_id)
  ORDER BY t.sort_order, t.name;
$$;

-- 2.2.2 Chi tiet
CREATE OR REPLACE FUNCTION edoc.fn_doc_type_get_by_id(p_id INT)
RETURNS TABLE (
  id INT, type_id SMALLINT, parent_id INT, code VARCHAR, name VARCHAR,
  description TEXT, sort_order INT, notation_type SMALLINT,
  is_default BOOLEAN, created_at TIMESTAMPTZ
)
LANGUAGE sql STABLE
AS $$
  SELECT t.id, t.type_id, t.parent_id, t.code::VARCHAR, t.name::VARCHAR,
         t.description, t.sort_order, t.notation_type,
         t.is_default, t.created_at
  FROM edoc.doc_types t
  WHERE t.id = p_id AND t.is_deleted = FALSE;
$$;

-- 2.2.3 Tao moi
CREATE OR REPLACE FUNCTION edoc.fn_doc_type_create(
  p_type_id       SMALLINT,
  p_parent_id     INT DEFAULT NULL,
  p_name          VARCHAR DEFAULT NULL,
  p_code          VARCHAR DEFAULT NULL,
  p_notation_type SMALLINT DEFAULT 0,
  p_sort_order    INT DEFAULT 0,
  p_created_by    INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql
AS $$
DECLARE v_id INT;
BEGIN
  -- Validate required
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên loại văn bản không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF p_code IS NULL OR TRIM(p_code) = '' THEN
    RETURN QUERY SELECT FALSE, 'Mã loại văn bản không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF LENGTH(p_code) > 20 THEN
    RETURN QUERY SELECT FALSE, 'Mã loại văn bản không được vượt quá 20 ký tự'::TEXT, 0;
    RETURN;
  END IF;
  IF LENGTH(p_name) > 200 THEN
    RETURN QUERY SELECT FALSE, 'Tên loại văn bản không được vượt quá 200 ký tự'::TEXT, 0;
    RETURN;
  END IF;

  -- Check unique code
  IF EXISTS(
    SELECT 1 FROM edoc.doc_types
    WHERE LOWER(TRIM(code)) = LOWER(TRIM(p_code)) AND is_deleted = FALSE
  ) THEN
    RETURN QUERY SELECT FALSE, 'Mã loại văn bản đã tồn tại'::TEXT, 0;
    RETURN;
  END IF;

  -- Check parent exists
  IF p_parent_id IS NOT NULL THEN
    IF NOT EXISTS(SELECT 1 FROM edoc.doc_types dt WHERE dt.id = p_parent_id AND dt.is_deleted = FALSE) THEN
      RETURN QUERY SELECT FALSE, 'Loại văn bản cha không tồn tại'::TEXT, 0;
      RETURN;
    END IF;
  END IF;

  INSERT INTO edoc.doc_types (type_id, parent_id, code, name, notation_type, sort_order, created_by)
  VALUES (p_type_id, p_parent_id, TRIM(p_code), TRIM(p_name), p_notation_type, p_sort_order, p_created_by)
  RETURNING doc_types.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao loai van ban thanh cong'::TEXT, v_id;
END;
$$;

-- 2.2.4 Cap nhat
CREATE OR REPLACE FUNCTION edoc.fn_doc_type_update(
  p_id            INT,
  p_parent_id     INT DEFAULT NULL,
  p_name          VARCHAR DEFAULT NULL,
  p_code          VARCHAR DEFAULT NULL,
  p_notation_type SMALLINT DEFAULT NULL,
  p_sort_order    INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.doc_types WHERE id = p_id AND is_deleted = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy loại văn bản'::TEXT;
    RETURN;
  END IF;

  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên loại văn bản không được để trống'::TEXT;
    RETURN;
  END IF;
  IF p_code IS NULL OR TRIM(p_code) = '' THEN
    RETURN QUERY SELECT FALSE, 'Mã loại văn bản không được để trống'::TEXT;
    RETURN;
  END IF;
  IF LENGTH(p_code) > 20 THEN
    RETURN QUERY SELECT FALSE, 'Mã loại văn bản không được vượt quá 20 ký tự'::TEXT;
    RETURN;
  END IF;

  -- Check unique code (exclude self)
  IF EXISTS(
    SELECT 1 FROM edoc.doc_types
    WHERE LOWER(TRIM(code)) = LOWER(TRIM(p_code))
      AND id <> p_id AND is_deleted = FALSE
  ) THEN
    RETURN QUERY SELECT FALSE, 'Mã loại văn bản đã tồn tại'::TEXT;
    RETURN;
  END IF;

  -- Prevent self-referencing
  IF p_parent_id = p_id THEN
    RETURN QUERY SELECT FALSE, 'Không thể chọn chính mình làm cha'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.doc_types SET
    parent_id     = p_parent_id,
    name          = TRIM(p_name),
    code          = TRIM(p_code),
    notation_type = COALESCE(p_notation_type, notation_type),
    sort_order    = COALESCE(p_sort_order, sort_order)
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Cap nhat thanh cong'::TEXT;
END;
$$;

-- 2.2.5 Xoa (soft delete, check children)
CREATE OR REPLACE FUNCTION edoc.fn_doc_type_delete(p_id INT)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_child_count INT;
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.doc_types WHERE id = p_id AND is_deleted = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy loại văn bản'::TEXT;
    RETURN;
  END IF;

  SELECT COUNT(*) INTO v_child_count
  FROM edoc.doc_types WHERE parent_id = p_id AND is_deleted = FALSE;

  IF v_child_count > 0 THEN
    RETURN QUERY SELECT FALSE, ('Không thể xóa: còn '|| v_child_count ||' loại văn bản con')::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.doc_types SET is_deleted = TRUE WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xoa loai van ban thanh cong'::TEXT;
END;
$$;


-- ══════════════════════════════════════════════
-- 2.3 DOC FIELD (Linh vuc van ban)
-- ══════════════════════════════════════════════

-- 2.3.1 Danh sach
CREATE OR REPLACE FUNCTION edoc.fn_doc_field_get_list(
  p_unit_id INT DEFAULT NULL,
  p_keyword VARCHAR DEFAULT NULL
)
RETURNS TABLE (
  id INT, unit_id INT, code VARCHAR, name VARCHAR,
  sort_order INT, is_active BOOLEAN, created_at TIMESTAMPTZ
)
LANGUAGE sql STABLE
AS $$
  SELECT f.id, f.unit_id, f.code::VARCHAR, f.name::VARCHAR,
         f.sort_order, f.is_active, f.created_at
  FROM edoc.doc_fields f
  WHERE (p_unit_id IS NULL OR f.unit_id = p_unit_id)
    AND (p_keyword IS NULL OR f.name ILIKE '%' || p_keyword || '%'
         OR f.code ILIKE '%' || p_keyword || '%')
  ORDER BY f.sort_order, f.name;
$$;

-- 2.3.2 Chi tiet
CREATE OR REPLACE FUNCTION edoc.fn_doc_field_get_by_id(p_id INT)
RETURNS TABLE (
  id INT, unit_id INT, code VARCHAR, name VARCHAR,
  sort_order INT, is_active BOOLEAN, created_at TIMESTAMPTZ
)
LANGUAGE sql STABLE
AS $$
  SELECT f.id, f.unit_id, f.code::VARCHAR, f.name::VARCHAR,
         f.sort_order, f.is_active, f.created_at
  FROM edoc.doc_fields f WHERE f.id = p_id;
$$;

-- 2.3.3 Tao moi
CREATE OR REPLACE FUNCTION edoc.fn_doc_field_create(
  p_unit_id INT,
  p_code    VARCHAR,
  p_name    VARCHAR
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql
AS $$
DECLARE v_id INT;
BEGIN
  IF p_code IS NULL OR TRIM(p_code) = '' THEN
    RETURN QUERY SELECT FALSE, 'Mã lĩnh vực không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên lĩnh vực không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF LENGTH(p_code) > 20 THEN
    RETURN QUERY SELECT FALSE, 'Mã lĩnh vực không được vượt quá 20 ký tự'::TEXT, 0;
    RETURN;
  END IF;
  IF LENGTH(p_name) > 200 THEN
    RETURN QUERY SELECT FALSE, 'Tên lĩnh vực không được vượt quá 200 ký tự'::TEXT, 0;
    RETURN;
  END IF;

  -- Check unique code per unit
  IF EXISTS(
    SELECT 1 FROM edoc.doc_fields
    WHERE unit_id = p_unit_id AND LOWER(TRIM(code)) = LOWER(TRIM(p_code))
  ) THEN
    RETURN QUERY SELECT FALSE, 'Mã lĩnh vực đã tồn tại trong đơn vị'::TEXT, 0;
    RETURN;
  END IF;

  INSERT INTO edoc.doc_fields (unit_id, code, name)
  VALUES (p_unit_id, TRIM(p_code), TRIM(p_name))
  RETURNING doc_fields.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao linh vuc thanh cong'::TEXT, v_id;
END;
$$;

-- 2.3.4 Cap nhat
CREATE OR REPLACE FUNCTION edoc.fn_doc_field_update(
  p_id        INT,
  p_code      VARCHAR DEFAULT NULL,
  p_name      VARCHAR DEFAULT NULL,
  p_sort_order INT DEFAULT NULL,
  p_is_active BOOLEAN DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_unit_id INT;
BEGIN
  SELECT unit_id INTO v_unit_id FROM edoc.doc_fields WHERE id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy lĩnh vực'::TEXT;
    RETURN;
  END IF;

  IF p_code IS NULL OR TRIM(p_code) = '' THEN
    RETURN QUERY SELECT FALSE, 'Mã lĩnh vực không được để trống'::TEXT;
    RETURN;
  END IF;
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên lĩnh vực không được để trống'::TEXT;
    RETURN;
  END IF;
  IF LENGTH(p_code) > 20 THEN
    RETURN QUERY SELECT FALSE, 'Mã lĩnh vực không được vượt quá 20 ký tự'::TEXT;
    RETURN;
  END IF;

  -- Check unique code (exclude self)
  IF EXISTS(
    SELECT 1 FROM edoc.doc_fields
    WHERE unit_id = v_unit_id AND LOWER(TRIM(code)) = LOWER(TRIM(p_code))
      AND id <> p_id
  ) THEN
    RETURN QUERY SELECT FALSE, 'Mã lĩnh vực đã tồn tại trong đơn vị'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.doc_fields SET
    code       = TRIM(p_code),
    name       = TRIM(p_name),
    sort_order = COALESCE(p_sort_order, sort_order),
    is_active  = COALESCE(p_is_active, is_active)
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Cap nhat thanh cong'::TEXT;
END;
$$;

-- 2.3.5 Xoa
CREATE OR REPLACE FUNCTION edoc.fn_doc_field_delete(p_id INT)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.doc_fields WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy lĩnh vực'::TEXT;
    RETURN;
  END IF;

  DELETE FROM edoc.doc_fields WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xoa linh vuc thanh cong'::TEXT;
END;
$$;


-- ══════════════════════════════════════════════
-- 2.4 DOC COLUMN (Thuoc tinh van ban)
-- ══════════════════════════════════════════════

-- 2.4.1 Danh sach theo type
CREATE OR REPLACE FUNCTION edoc.fn_doc_column_get_list(p_type_id SMALLINT)
RETURNS TABLE (
  id INT, type_id SMALLINT, column_name VARCHAR, label VARCHAR,
  is_mandatory BOOLEAN, is_show_all BOOLEAN, sort_order INT,
  description TEXT
)
LANGUAGE sql STABLE
AS $$
  SELECT c.id, c.type_id, c.column_name::VARCHAR, c.label::VARCHAR,
         c.is_mandatory, c.is_show_all, c.sort_order, c.description
  FROM edoc.doc_columns c
  WHERE c.type_id = p_type_id
  ORDER BY c.sort_order;
$$;

-- 2.4.2 Cap nhat
CREATE OR REPLACE FUNCTION edoc.fn_doc_column_update(
  p_id           INT,
  p_label        VARCHAR DEFAULT NULL,
  p_is_mandatory BOOLEAN DEFAULT NULL,
  p_is_show_all  BOOLEAN DEFAULT NULL,
  p_sort_order   INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.doc_columns WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy thuộc tính'::TEXT;
    RETURN;
  END IF;

  IF p_label IS NOT NULL AND LENGTH(p_label) > 200 THEN
    RETURN QUERY SELECT FALSE, 'Nhãn hiển thị không được vượt quá 200 ký tự'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.doc_columns SET
    label        = COALESCE(NULLIF(TRIM(p_label), ''), label),
    is_mandatory = COALESCE(p_is_mandatory, is_mandatory),
    is_show_all  = COALESCE(p_is_show_all, is_show_all),
    sort_order   = COALESCE(p_sort_order, sort_order)
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Cap nhat thanh cong'::TEXT;
END;
$$;

-- 2.4.3 Toggle hien thi
CREATE OR REPLACE FUNCTION edoc.fn_doc_column_toggle_visibility(p_id INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE edoc.doc_columns SET is_show_all = NOT is_show_all WHERE id = p_id;
  RETURN FOUND;
END;
$$;


-- ══════════════════════════════════════════════
-- 2.5 ORGANIZATION (Thong tin co quan)
-- ══════════════════════════════════════════════

-- 2.5.1 Lay thong tin co quan
CREATE OR REPLACE FUNCTION edoc.fn_organization_get(p_unit_id INT)
RETURNS TABLE (
  id INT, unit_id INT, code VARCHAR, name VARCHAR, address TEXT,
  phone VARCHAR, fax VARCHAR, email VARCHAR, email_doc VARCHAR,
  secretary VARCHAR, chairman_number VARCHAR, level SMALLINT,
  is_exchange BOOLEAN, lgsp_system_id VARCHAR, lgsp_secret_key VARCHAR,
  updated_by INT, updated_at TIMESTAMPTZ
)
LANGUAGE sql STABLE
AS $$
  SELECT o.id, o.unit_id, o.code::VARCHAR, o.name::VARCHAR, o.address,
         o.phone::VARCHAR, o.fax::VARCHAR, o.email::VARCHAR, o.email_doc::VARCHAR,
         o.secretary::VARCHAR, o.chairman_number::VARCHAR, o.level,
         o.is_exchange, o.lgsp_system_id::VARCHAR, o.lgsp_secret_key::VARCHAR,
         o.updated_by, o.updated_at
  FROM edoc.organizations o
  WHERE o.unit_id = p_unit_id;
$$;

-- 2.5.2 Upsert thong tin co quan
CREATE OR REPLACE FUNCTION edoc.fn_organization_upsert(
  p_unit_id          INT,
  p_code             VARCHAR DEFAULT NULL,
  p_name             VARCHAR DEFAULT NULL,
  p_address          TEXT DEFAULT NULL,
  p_phone            VARCHAR DEFAULT NULL,
  p_fax              VARCHAR DEFAULT NULL,
  p_email            VARCHAR DEFAULT NULL,
  p_email_doc        VARCHAR DEFAULT NULL,
  p_secretary        VARCHAR DEFAULT NULL,
  p_chairman_number  VARCHAR DEFAULT NULL,
  p_level            SMALLINT DEFAULT 1,
  p_is_exchange      BOOLEAN DEFAULT FALSE,
  p_updated_by       INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  -- Validate FK
  IF NOT EXISTS(SELECT 1 FROM public.departments WHERE id = p_unit_id AND is_deleted = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Đơn vị không tồn tại'::TEXT;
    RETURN;
  END IF;

  -- Validate lengths
  IF p_code IS NOT NULL AND LENGTH(p_code) > 20 THEN
    RETURN QUERY SELECT FALSE, 'Mã cơ quan không được vượt quá 20 ký tự'::TEXT;
    RETURN;
  END IF;
  IF p_email IS NOT NULL AND LENGTH(p_email) > 100 THEN
    RETURN QUERY SELECT FALSE, 'Email không được vượt quá 100 ký tự'::TEXT;
    RETURN;
  END IF;
  IF p_phone IS NOT NULL AND LENGTH(p_phone) > 20 THEN
    RETURN QUERY SELECT FALSE, 'Số điện thoại không được vượt quá 20 ký tự'::TEXT;
    RETURN;
  END IF;

  INSERT INTO edoc.organizations (
    unit_id, code, name, address, phone, fax, email, email_doc,
    secretary, chairman_number, level, is_exchange,
    lgsp_system_id, lgsp_secret_key, updated_by, updated_at
  ) VALUES (
    p_unit_id, p_code, p_name, p_address, p_phone, p_fax, p_email, p_email_doc,
    p_secretary, p_chairman_number, p_level, p_is_exchange,
    NULL, NULL, p_updated_by, NOW()
  )
  ON CONFLICT (unit_id) DO UPDATE SET
    code             = EXCLUDED.code,
    name             = EXCLUDED.name,
    address          = EXCLUDED.address,
    phone            = EXCLUDED.phone,
    fax              = EXCLUDED.fax,
    email            = EXCLUDED.email,
    email_doc        = EXCLUDED.email_doc,
    secretary        = EXCLUDED.secretary,
    chairman_number  = EXCLUDED.chairman_number,
    level            = EXCLUDED.level,
    is_exchange      = EXCLUDED.is_exchange,
    updated_by       = EXCLUDED.updated_by,
    updated_at       = NOW();

  RETURN QUERY SELECT TRUE, 'Cap nhat thong tin co quan thanh cong'::TEXT;
END;
$$;


-- ══════════════════════════════════════════════
-- 2.6 SIGNER (Nguoi ky van ban)
-- ══════════════════════════════════════════════

-- 2.6.1 Danh sach
CREATE OR REPLACE FUNCTION edoc.fn_signer_get_list(
  p_unit_id       INT,
  p_department_id INT DEFAULT NULL
)
RETURNS TABLE (
  id INT, unit_id INT, department_id INT, staff_id INT,
  staff_name VARCHAR, position_name VARCHAR, department_name VARCHAR,
  sort_order INT
)
LANGUAGE sql STABLE
AS $$
  SELECT sg.id, sg.unit_id, sg.department_id, sg.staff_id,
         s.full_name::VARCHAR AS staff_name,
         p.name::VARCHAR AS position_name,
         d.name::VARCHAR AS department_name,
         sg.sort_order
  FROM edoc.signers sg
    JOIN public.staff s ON s.id = sg.staff_id
    LEFT JOIN public.positions p ON p.id = s.position_id
    LEFT JOIN public.departments d ON d.id = sg.department_id
  WHERE sg.unit_id = p_unit_id
    AND (p_department_id IS NULL OR sg.department_id = p_department_id)
  ORDER BY sg.sort_order, s.full_name;
$$;

-- 2.6.2 Them nguoi ky
CREATE OR REPLACE FUNCTION edoc.fn_signer_create(
  p_unit_id       INT,
  p_department_id INT DEFAULT NULL,
  p_staff_id      INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql
AS $$
DECLARE v_id INT;
BEGIN
  IF p_staff_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Vui lòng chọn nhân viên'::TEXT, 0;
    RETURN;
  END IF;

  -- Check staff exists
  IF NOT EXISTS(SELECT 1 FROM public.staff s WHERE s.id = p_staff_id AND s.is_deleted = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Nhân viên không tồn tại'::TEXT, 0;
    RETURN;
  END IF;

  -- Check unique
  IF EXISTS(SELECT 1 FROM edoc.signers WHERE unit_id = p_unit_id AND staff_id = p_staff_id) THEN
    RETURN QUERY SELECT FALSE, 'Nhân viên đã có trong danh sách người ký'::TEXT, 0;
    RETURN;
  END IF;

  INSERT INTO edoc.signers (unit_id, department_id, staff_id)
  VALUES (p_unit_id, p_department_id, p_staff_id)
  RETURNING signers.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Them nguoi ky thanh cong'::TEXT, v_id;
END;
$$;

-- 2.6.3 Xoa nguoi ky
CREATE OR REPLACE FUNCTION edoc.fn_signer_delete(p_id INT)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.signers WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy người ký'::TEXT;
    RETURN;
  END IF;

  DELETE FROM edoc.signers WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xoa nguoi ky thanh cong'::TEXT;
END;
$$;


-- ══════════════════════════════════════════════
-- 2.7 WORK GROUP (Nhom xu ly)
-- ══════════════════════════════════════════════

-- 2.7.1 Danh sach nhom
CREATE OR REPLACE FUNCTION edoc.fn_work_group_get_list(p_unit_id INT)
RETURNS TABLE (
  id INT, unit_id INT, name VARCHAR, function TEXT,
  sort_order INT, member_count BIGINT,
  created_by INT, created_at TIMESTAMPTZ
)
LANGUAGE sql STABLE
AS $$
  SELECT g.id, g.unit_id, g.name::VARCHAR, g.function,
         g.sort_order,
         (SELECT COUNT(*) FROM edoc.work_group_members m WHERE m.group_id = g.id) AS member_count,
         g.created_by, g.created_at
  FROM edoc.work_groups g
  WHERE g.unit_id = p_unit_id AND g.is_deleted = FALSE
  ORDER BY g.sort_order, g.name;
$$;

-- 2.7.2 Chi tiet
CREATE OR REPLACE FUNCTION edoc.fn_work_group_get_by_id(p_id INT)
RETURNS TABLE (
  id INT, unit_id INT, name VARCHAR, function TEXT,
  sort_order INT, created_by INT, created_at TIMESTAMPTZ
)
LANGUAGE sql STABLE
AS $$
  SELECT g.id, g.unit_id, g.name::VARCHAR, g.function,
         g.sort_order, g.created_by, g.created_at
  FROM edoc.work_groups g
  WHERE g.id = p_id AND g.is_deleted = FALSE;
$$;

-- 2.7.3 Tao nhom
CREATE OR REPLACE FUNCTION edoc.fn_work_group_create(
  p_unit_id    INT,
  p_name       VARCHAR,
  p_function   TEXT DEFAULT NULL,
  p_sort_order INT DEFAULT 0,
  p_created_by INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql
AS $$
DECLARE v_id INT;
BEGIN
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên nhóm không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF LENGTH(p_name) > 200 THEN
    RETURN QUERY SELECT FALSE, 'Tên nhóm không được vượt quá 200 ký tự'::TEXT, 0;
    RETURN;
  END IF;

  -- Check unique name per unit
  IF EXISTS(
    SELECT 1 FROM edoc.work_groups
    WHERE unit_id = p_unit_id AND LOWER(TRIM(name)) = LOWER(TRIM(p_name))
      AND is_deleted = FALSE
  ) THEN
    RETURN QUERY SELECT FALSE, 'Tên nhóm đã tồn tại trong đơn vị'::TEXT, 0;
    RETURN;
  END IF;

  INSERT INTO edoc.work_groups (unit_id, name, function, sort_order, created_by)
  VALUES (p_unit_id, TRIM(p_name), p_function, p_sort_order, p_created_by)
  RETURNING work_groups.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao nhom thanh cong'::TEXT, v_id;
END;
$$;

-- 2.7.4 Cap nhat nhom
CREATE OR REPLACE FUNCTION edoc.fn_work_group_update(
  p_id         INT,
  p_name       VARCHAR DEFAULT NULL,
  p_function   TEXT DEFAULT NULL,
  p_sort_order INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_unit_id INT;
BEGIN
  SELECT unit_id INTO v_unit_id FROM edoc.work_groups WHERE id = p_id AND is_deleted = FALSE;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy nhóm'::TEXT;
    RETURN;
  END IF;

  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên nhóm không được để trống'::TEXT;
    RETURN;
  END IF;
  IF LENGTH(p_name) > 200 THEN
    RETURN QUERY SELECT FALSE, 'Tên nhóm không được vượt quá 200 ký tự'::TEXT;
    RETURN;
  END IF;

  -- Check unique name (exclude self)
  IF EXISTS(
    SELECT 1 FROM edoc.work_groups
    WHERE unit_id = v_unit_id AND LOWER(TRIM(name)) = LOWER(TRIM(p_name))
      AND id <> p_id AND is_deleted = FALSE
  ) THEN
    RETURN QUERY SELECT FALSE, 'Tên nhóm đã tồn tại trong đơn vị'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.work_groups SET
    name       = TRIM(p_name),
    function   = COALESCE(p_function, function),
    sort_order = COALESCE(p_sort_order, sort_order)
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Cap nhat nhom thanh cong'::TEXT;
END;
$$;

-- 2.7.5 Xoa nhom (soft delete)
CREATE OR REPLACE FUNCTION edoc.fn_work_group_delete(p_id INT)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.work_groups WHERE id = p_id AND is_deleted = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy nhóm'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.work_groups SET is_deleted = TRUE WHERE id = p_id;
  -- Also remove members
  DELETE FROM edoc.work_group_members WHERE group_id = p_id;

  RETURN QUERY SELECT TRUE, 'Xoa nhom thanh cong'::TEXT;
END;
$$;

-- 2.7.6 Danh sach thanh vien
CREATE OR REPLACE FUNCTION edoc.fn_work_group_get_members(p_group_id INT)
RETURNS TABLE (
  id INT, group_id INT, staff_id INT,
  staff_name VARCHAR, position_name VARCHAR, department_name VARCHAR,
  created_at TIMESTAMPTZ
)
LANGUAGE sql STABLE
AS $$
  SELECT m.id, m.group_id, m.staff_id,
         s.full_name::VARCHAR AS staff_name,
         p.name::VARCHAR AS position_name,
         d.name::VARCHAR AS department_name,
         m.created_at
  FROM edoc.work_group_members m
    JOIN public.staff s ON s.id = m.staff_id
    LEFT JOIN public.positions p ON p.id = s.position_id
    LEFT JOIN public.departments d ON d.id = s.department_id
  WHERE m.group_id = p_group_id
  ORDER BY s.full_name;
$$;

-- 2.7.7 Gan thanh vien (xoa cu, them moi)
CREATE OR REPLACE FUNCTION edoc.fn_work_group_assign_members(
  p_group_id  INT,
  p_staff_ids INT[]
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.work_groups WHERE id = p_group_id AND is_deleted = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy nhóm'::TEXT;
    RETURN;
  END IF;

  -- Delete old members
  DELETE FROM edoc.work_group_members WHERE group_id = p_group_id;

  -- Insert new members
  IF p_staff_ids IS NOT NULL AND array_length(p_staff_ids, 1) > 0 THEN
    INSERT INTO edoc.work_group_members (group_id, staff_id)
    SELECT p_group_id, unnest(p_staff_ids)
    ON CONFLICT (group_id, staff_id) DO NOTHING;
  END IF;

  RETURN QUERY SELECT TRUE, 'Cap nhat thanh vien thanh cong'::TEXT;
END;
$$;


-- ══════════════════════════════════════════════
-- 2.8 DELEGATION (Uy quyen)
-- ══════════════════════════════════════════════

-- 2.8.1 Danh sach uy quyen
CREATE OR REPLACE FUNCTION edoc.fn_delegation_get_list(
  p_unit_id  INT DEFAULT NULL,
  p_staff_id INT DEFAULT NULL
)
RETURNS TABLE (
  id INT, from_staff_id INT, from_staff_name VARCHAR,
  to_staff_id INT, to_staff_name VARCHAR,
  start_date DATE, end_date DATE, note TEXT,
  is_revoked BOOLEAN, revoked_at TIMESTAMPTZ, created_at TIMESTAMPTZ
)
LANGUAGE sql STABLE
AS $$
  SELECT dl.id, dl.from_staff_id,
         sf.full_name::VARCHAR AS from_staff_name,
         dl.to_staff_id,
         st.full_name::VARCHAR AS to_staff_name,
         dl.start_date, dl.end_date, dl.note,
         dl.is_revoked, dl.revoked_at, dl.created_at
  FROM edoc.delegations dl
    JOIN public.staff sf ON sf.id = dl.from_staff_id
    JOIN public.staff st ON st.id = dl.to_staff_id
  WHERE (p_unit_id IS NULL OR sf.unit_id = p_unit_id)
    AND (p_staff_id IS NULL OR dl.from_staff_id = p_staff_id OR dl.to_staff_id = p_staff_id)
  ORDER BY dl.created_at DESC;
$$;

-- 2.8.2 Tao uy quyen
CREATE OR REPLACE FUNCTION edoc.fn_delegation_create(
  p_from_staff_id INT,
  p_to_staff_id   INT,
  p_start_date    DATE,
  p_end_date      DATE,
  p_note          TEXT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql
AS $$
DECLARE v_id INT;
BEGIN
  IF p_from_staff_id IS NULL OR p_to_staff_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Vui lòng chọn người ủy quyền và người nhận ủy quyền'::TEXT, 0;
    RETURN;
  END IF;
  IF p_from_staff_id = p_to_staff_id THEN
    RETURN QUERY SELECT FALSE, 'Không thể ủy quyền cho chính mình'::TEXT, 0;
    RETURN;
  END IF;
  IF p_start_date IS NULL OR p_end_date IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Ngày bắt đầu và ngày kết thúc không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF p_end_date < p_start_date THEN
    RETURN QUERY SELECT FALSE, 'Ngày kết thúc phải lớn hơn hoặc bằng ngày bắt đầu'::TEXT, 0;
    RETURN;
  END IF;

  -- Check staff exists
  IF NOT EXISTS(SELECT 1 FROM public.staff s WHERE s.id = p_from_staff_id AND s.is_deleted = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Người ủy quyền không tồn tại'::TEXT, 0;
    RETURN;
  END IF;
  IF NOT EXISTS(SELECT 1 FROM public.staff s WHERE s.id = p_to_staff_id AND s.is_deleted = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Người nhận ủy quyền không tồn tại'::TEXT, 0;
    RETURN;
  END IF;

  -- Check overlap: same from_staff, active, date range overlaps
  IF EXISTS(
    SELECT 1 FROM edoc.delegations d
    WHERE d.from_staff_id = p_from_staff_id
      AND d.is_revoked = FALSE
      AND d.start_date <= p_end_date
      AND d.end_date >= p_start_date
  ) THEN
    RETURN QUERY SELECT FALSE, 'Đã tồn tại ủy quyền trong khoảng thời gian này'::TEXT, 0;
    RETURN;
  END IF;

  INSERT INTO edoc.delegations (from_staff_id, to_staff_id, start_date, end_date, note)
  VALUES (p_from_staff_id, p_to_staff_id, p_start_date, p_end_date, p_note)
  RETURNING edoc.delegations.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao uy quyen thanh cong'::TEXT, v_id;
END;
$$;

-- 2.8.3 Thu hoi uy quyen
CREATE OR REPLACE FUNCTION edoc.fn_delegation_revoke(p_id INT)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.delegations WHERE id = p_id AND is_revoked = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy ủy quyền hoặc đã thu hồi'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.delegations SET is_revoked = TRUE, revoked_at = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Thu hoi uy quyen thanh cong'::TEXT;
END;
$$;


-- ══════════════════════════════════════════════
-- 2.9 PROVINCE / DISTRICT / COMMUNE (Dia ban hanh chinh)
-- ══════════════════════════════════════════════

-- === Province ===

CREATE OR REPLACE FUNCTION public.fn_province_get_list(p_keyword VARCHAR DEFAULT NULL)
RETURNS TABLE (id INT, name VARCHAR, code VARCHAR, is_active BOOLEAN)
LANGUAGE sql STABLE
AS $$
  SELECT p.id, p.name::VARCHAR, p.code::VARCHAR, p.is_active
  FROM public.provinces p
  WHERE (p_keyword IS NULL OR p.name ILIKE '%' || p_keyword || '%'
         OR p.code ILIKE '%' || p_keyword || '%')
  ORDER BY p.name;
$$;

CREATE OR REPLACE FUNCTION public.fn_province_create(
  p_name VARCHAR,
  p_code VARCHAR DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql
AS $$
DECLARE v_id INT;
BEGIN
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên tỉnh/thành không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF p_code IS NOT NULL AND LENGTH(p_code) > 10 THEN
    RETURN QUERY SELECT FALSE, 'Mã tỉnh/thành không được vượt quá 10 ký tự'::TEXT, 0;
    RETURN;
  END IF;

  -- Check unique code
  IF p_code IS NOT NULL AND EXISTS(
    SELECT 1 FROM public.provinces WHERE LOWER(TRIM(code)) = LOWER(TRIM(p_code))
  ) THEN
    RETURN QUERY SELECT FALSE, 'Mã tỉnh/thành đã tồn tại'::TEXT, 0;
    RETURN;
  END IF;

  INSERT INTO public.provinces (name, code)
  VALUES (TRIM(p_name), TRIM(p_code))
  RETURNING provinces.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao tinh/thanh thanh cong'::TEXT, v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_province_update(
  p_id        INT,
  p_name      VARCHAR,
  p_code      VARCHAR DEFAULT NULL,
  p_is_active BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM public.provinces WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy tỉnh/thành'::TEXT;
    RETURN;
  END IF;
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên tỉnh/thành không được để trống'::TEXT;
    RETURN;
  END IF;

  -- Check unique code (exclude self)
  IF p_code IS NOT NULL AND EXISTS(
    SELECT 1 FROM public.provinces
    WHERE LOWER(TRIM(code)) = LOWER(TRIM(p_code)) AND id <> p_id
  ) THEN
    RETURN QUERY SELECT FALSE, 'Mã tỉnh/thành đã tồn tại'::TEXT;
    RETURN;
  END IF;

  UPDATE public.provinces SET name = TRIM(p_name), code = TRIM(p_code), is_active = p_is_active WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Cap nhat thanh cong'::TEXT;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_province_delete(p_id INT)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_district_count INT;
BEGIN
  IF NOT EXISTS(SELECT 1 FROM public.provinces WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy tỉnh/thành'::TEXT;
    RETURN;
  END IF;

  SELECT COUNT(*) INTO v_district_count FROM public.districts WHERE province_id = p_id;
  IF v_district_count > 0 THEN
    RETURN QUERY SELECT FALSE, ('Không thể xóa: còn '|| v_district_count ||' quận/huyện thuộc tỉnh/thành này')::TEXT;
    RETURN;
  END IF;

  DELETE FROM public.provinces WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xoa tinh/thanh thanh cong'::TEXT;
END;
$$;

-- === District ===

CREATE OR REPLACE FUNCTION public.fn_district_get_list(
  p_province_id INT DEFAULT NULL,
  p_keyword     VARCHAR DEFAULT NULL
)
RETURNS TABLE (id INT, province_id INT, name VARCHAR, code VARCHAR, is_active BOOLEAN)
LANGUAGE sql STABLE
AS $$
  SELECT d.id, d.province_id, d.name::VARCHAR, d.code::VARCHAR, d.is_active
  FROM public.districts d
  WHERE (p_province_id IS NULL OR d.province_id = p_province_id)
    AND (p_keyword IS NULL OR d.name ILIKE '%' || p_keyword || '%'
         OR d.code ILIKE '%' || p_keyword || '%')
  ORDER BY d.name;
$$;

CREATE OR REPLACE FUNCTION public.fn_district_create(
  p_province_id INT,
  p_name        VARCHAR,
  p_code        VARCHAR DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql
AS $$
DECLARE v_id INT;
BEGIN
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên quận/huyện không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF NOT EXISTS(SELECT 1 FROM public.provinces pv WHERE pv.id = p_province_id) THEN
    RETURN QUERY SELECT FALSE, 'Tỉnh/thành không tồn tại'::TEXT, 0;
    RETURN;
  END IF;
  IF p_code IS NOT NULL AND LENGTH(p_code) > 10 THEN
    RETURN QUERY SELECT FALSE, 'Mã quận/huyện không được vượt quá 10 ký tự'::TEXT, 0;
    RETURN;
  END IF;

  -- Check unique code within province
  IF p_code IS NOT NULL AND EXISTS(
    SELECT 1 FROM public.districts
    WHERE province_id = p_province_id AND LOWER(TRIM(code)) = LOWER(TRIM(p_code))
  ) THEN
    RETURN QUERY SELECT FALSE, 'Mã quận/huyện đã tồn tại trong tỉnh/thành'::TEXT, 0;
    RETURN;
  END IF;

  INSERT INTO public.districts (province_id, name, code)
  VALUES (p_province_id, TRIM(p_name), TRIM(p_code))
  RETURNING districts.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao quan/huyen thanh cong'::TEXT, v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_district_update(
  p_id        INT,
  p_name      VARCHAR,
  p_code      VARCHAR DEFAULT NULL,
  p_is_active BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_province_id INT;
BEGIN
  SELECT province_id INTO v_province_id FROM public.districts WHERE id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy quận/huyện'::TEXT;
    RETURN;
  END IF;
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên quận/huyện không được để trống'::TEXT;
    RETURN;
  END IF;

  -- Check unique code (exclude self)
  IF p_code IS NOT NULL AND EXISTS(
    SELECT 1 FROM public.districts
    WHERE province_id = v_province_id AND LOWER(TRIM(code)) = LOWER(TRIM(p_code))
      AND id <> p_id
  ) THEN
    RETURN QUERY SELECT FALSE, 'Mã quận/huyện đã tồn tại trong tỉnh/thành'::TEXT;
    RETURN;
  END IF;

  UPDATE public.districts SET name = TRIM(p_name), code = TRIM(p_code), is_active = p_is_active WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Cap nhat thanh cong'::TEXT;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_district_delete(p_id INT)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_commune_count INT;
BEGIN
  IF NOT EXISTS(SELECT 1 FROM public.districts WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy quận/huyện'::TEXT;
    RETURN;
  END IF;

  SELECT COUNT(*) INTO v_commune_count FROM public.communes WHERE district_id = p_id;
  IF v_commune_count > 0 THEN
    RETURN QUERY SELECT FALSE, ('Không thể xóa: còn '|| v_commune_count ||' phường/xã thuộc quận/huyện này')::TEXT;
    RETURN;
  END IF;

  DELETE FROM public.districts WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xoa quan/huyen thanh cong'::TEXT;
END;
$$;

-- === Commune ===

CREATE OR REPLACE FUNCTION public.fn_commune_get_list(
  p_district_id INT DEFAULT NULL,
  p_keyword     VARCHAR DEFAULT NULL
)
RETURNS TABLE (id INT, district_id INT, name VARCHAR, code VARCHAR, is_active BOOLEAN)
LANGUAGE sql STABLE
AS $$
  SELECT c.id, c.district_id, c.name::VARCHAR, c.code::VARCHAR, c.is_active
  FROM public.communes c
  WHERE (p_district_id IS NULL OR c.district_id = p_district_id)
    AND (p_keyword IS NULL OR c.name ILIKE '%' || p_keyword || '%'
         OR c.code ILIKE '%' || p_keyword || '%')
  ORDER BY c.name;
$$;

CREATE OR REPLACE FUNCTION public.fn_commune_create(
  p_district_id INT,
  p_name        VARCHAR,
  p_code        VARCHAR DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql
AS $$
DECLARE v_id INT;
BEGIN
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên phường/xã không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF NOT EXISTS(SELECT 1 FROM public.districts ds WHERE ds.id = p_district_id) THEN
    RETURN QUERY SELECT FALSE, 'Quận/huyện không tồn tại'::TEXT, 0;
    RETURN;
  END IF;
  IF p_code IS NOT NULL AND LENGTH(p_code) > 10 THEN
    RETURN QUERY SELECT FALSE, 'Mã phường/xã không được vượt quá 10 ký tự'::TEXT, 0;
    RETURN;
  END IF;

  -- Check unique code within district
  IF p_code IS NOT NULL AND EXISTS(
    SELECT 1 FROM public.communes
    WHERE district_id = p_district_id AND LOWER(TRIM(code)) = LOWER(TRIM(p_code))
  ) THEN
    RETURN QUERY SELECT FALSE, 'Mã phường/xã đã tồn tại trong quận/huyện'::TEXT, 0;
    RETURN;
  END IF;

  INSERT INTO public.communes (district_id, name, code)
  VALUES (p_district_id, TRIM(p_name), TRIM(p_code))
  RETURNING communes.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao phuong/xa thanh cong'::TEXT, v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_commune_update(
  p_id        INT,
  p_name      VARCHAR,
  p_code      VARCHAR DEFAULT NULL,
  p_is_active BOOLEAN DEFAULT TRUE
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_district_id INT;
BEGIN
  SELECT district_id INTO v_district_id FROM public.communes WHERE id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy phường/xã'::TEXT;
    RETURN;
  END IF;
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên phường/xã không được để trống'::TEXT;
    RETURN;
  END IF;

  -- Check unique code (exclude self)
  IF p_code IS NOT NULL AND EXISTS(
    SELECT 1 FROM public.communes
    WHERE district_id = v_district_id AND LOWER(TRIM(code)) = LOWER(TRIM(p_code))
      AND id <> p_id
  ) THEN
    RETURN QUERY SELECT FALSE, 'Mã phường/xã đã tồn tại trong quận/huyện'::TEXT;
    RETURN;
  END IF;

  UPDATE public.communes SET name = TRIM(p_name), code = TRIM(p_code), is_active = p_is_active WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Cap nhat thanh cong'::TEXT;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_commune_delete(p_id INT)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM public.communes WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy phường/xã'::TEXT;
    RETURN;
  END IF;

  DELETE FROM public.communes WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xoa phuong/xa thanh cong'::TEXT;
END;
$$;


-- ══════════════════════════════════════════════
-- 2.10 WORK CALENDAR (Lich ngay nghi)
-- ══════════════════════════════════════════════

-- 2.10.1 Lay lich theo nam
CREATE OR REPLACE FUNCTION public.fn_work_calendar_get(p_year INT)
RETURNS TABLE (
  id INT, date DATE, description VARCHAR, is_holiday BOOLEAN,
  created_by INT, created_at TIMESTAMPTZ
)
LANGUAGE sql STABLE
AS $$
  SELECT wc.id, wc.date, wc.description::VARCHAR, wc.is_holiday,
         wc.created_by, wc.created_at
  FROM public.work_calendar wc
  WHERE EXTRACT(YEAR FROM wc.date) = p_year
  ORDER BY wc.date;
$$;

-- 2.10.2 Upsert ngay nghi
CREATE OR REPLACE FUNCTION public.fn_work_calendar_set_holiday(
  p_date        DATE,
  p_description VARCHAR DEFAULT NULL,
  p_created_by  INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF p_date IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Ngày không được để trống'::TEXT;
    RETURN;
  END IF;
  IF p_description IS NOT NULL AND LENGTH(p_description) > 200 THEN
    RETURN QUERY SELECT FALSE, 'Mô tả không được vượt quá 200 ký tự'::TEXT;
    RETURN;
  END IF;

  INSERT INTO public.work_calendar (date, description, is_holiday, created_by)
  VALUES (p_date, p_description, TRUE, p_created_by)
  ON CONFLICT (date) DO UPDATE SET
    description = EXCLUDED.description,
    is_holiday  = TRUE,
    created_by  = EXCLUDED.created_by;

  RETURN QUERY SELECT TRUE, 'Cap nhat lich thanh cong'::TEXT;
END;
$$;

-- 2.10.3 Xoa ngay nghi
CREATE OR REPLACE FUNCTION public.fn_work_calendar_remove_holiday(p_date DATE)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM public.work_calendar WHERE date = p_date) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy ngày nghỉ'::TEXT;
    RETURN;
  END IF;

  DELETE FROM public.work_calendar WHERE date = p_date;
  RETURN QUERY SELECT TRUE, 'Xoa ngay nghi thanh cong'::TEXT;
END;
$$;


-- ══════════════════════════════════════════════
-- 2.11 SMS / EMAIL TEMPLATES
-- ══════════════════════════════════════════════

-- === SMS Template ===

CREATE OR REPLACE FUNCTION edoc.fn_sms_template_get_list(p_unit_id INT)
RETURNS TABLE (
  id INT, unit_id INT, name VARCHAR, content TEXT,
  description TEXT, is_active BOOLEAN,
  created_by INT, created_at TIMESTAMPTZ
)
LANGUAGE sql STABLE
AS $$
  SELECT t.id, t.unit_id, t.name::VARCHAR, t.content,
         t.description, t.is_active, t.created_by, t.created_at
  FROM edoc.sms_templates t
  WHERE t.unit_id = p_unit_id
  ORDER BY t.name;
$$;

CREATE OR REPLACE FUNCTION edoc.fn_sms_template_create(
  p_unit_id     INT,
  p_name        VARCHAR,
  p_content     TEXT,
  p_description TEXT DEFAULT NULL,
  p_created_by  INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql
AS $$
DECLARE v_id INT;
BEGIN
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên mẫu tin nhắn không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF p_content IS NULL OR TRIM(p_content) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nội dung mẫu tin nhắn không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF LENGTH(p_name) > 200 THEN
    RETURN QUERY SELECT FALSE, 'Tên mẫu tin nhắn không được vượt quá 200 ký tự'::TEXT, 0;
    RETURN;
  END IF;

  INSERT INTO edoc.sms_templates (unit_id, name, content, description, created_by)
  VALUES (p_unit_id, TRIM(p_name), TRIM(p_content), p_description, p_created_by)
  RETURNING sms_templates.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao mau tin nhan thanh cong'::TEXT, v_id;
END;
$$;

CREATE OR REPLACE FUNCTION edoc.fn_sms_template_update(
  p_id          INT,
  p_name        VARCHAR DEFAULT NULL,
  p_content     TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_is_active   BOOLEAN DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.sms_templates WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy mẫu tin nhắn'::TEXT;
    RETURN;
  END IF;
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên mẫu tin nhắn không được để trống'::TEXT;
    RETURN;
  END IF;
  IF p_content IS NULL OR TRIM(p_content) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nội dung mẫu tin nhắn không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.sms_templates SET
    name        = TRIM(p_name),
    content     = TRIM(p_content),
    description = COALESCE(p_description, description),
    is_active   = COALESCE(p_is_active, is_active)
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Cap nhat mau tin nhan thanh cong'::TEXT;
END;
$$;

CREATE OR REPLACE FUNCTION edoc.fn_sms_template_delete(p_id INT)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.sms_templates WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy mẫu tin nhắn'::TEXT;
    RETURN;
  END IF;

  DELETE FROM edoc.sms_templates WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xoa mau tin nhan thanh cong'::TEXT;
END;
$$;

-- === Email Template ===

CREATE OR REPLACE FUNCTION edoc.fn_email_template_get_list(p_unit_id INT)
RETURNS TABLE (
  id INT, unit_id INT, name VARCHAR, subject VARCHAR,
  content TEXT, description TEXT, is_active BOOLEAN,
  created_by INT, created_at TIMESTAMPTZ
)
LANGUAGE sql STABLE
AS $$
  SELECT t.id, t.unit_id, t.name::VARCHAR, t.subject::VARCHAR,
         t.content, t.description, t.is_active, t.created_by, t.created_at
  FROM edoc.email_templates t
  WHERE t.unit_id = p_unit_id
  ORDER BY t.name;
$$;

CREATE OR REPLACE FUNCTION edoc.fn_email_template_create(
  p_unit_id     INT,
  p_name        VARCHAR,
  p_subject     VARCHAR DEFAULT NULL,
  p_content     TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_created_by  INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql
AS $$
DECLARE v_id INT;
BEGIN
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên mẫu email không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF p_content IS NULL OR TRIM(p_content) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nội dung mẫu email không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF LENGTH(p_name) > 200 THEN
    RETURN QUERY SELECT FALSE, 'Tên mẫu email không được vượt quá 200 ký tự'::TEXT, 0;
    RETURN;
  END IF;
  IF p_subject IS NOT NULL AND LENGTH(p_subject) > 500 THEN
    RETURN QUERY SELECT FALSE, 'Tiêu đề email không được vượt quá 500 ký tự'::TEXT, 0;
    RETURN;
  END IF;

  INSERT INTO edoc.email_templates (unit_id, name, subject, content, description, created_by)
  VALUES (p_unit_id, TRIM(p_name), TRIM(p_subject), TRIM(p_content), p_description, p_created_by)
  RETURNING email_templates.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao mau email thanh cong'::TEXT, v_id;
END;
$$;

CREATE OR REPLACE FUNCTION edoc.fn_email_template_update(
  p_id          INT,
  p_name        VARCHAR DEFAULT NULL,
  p_subject     VARCHAR DEFAULT NULL,
  p_content     TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL,
  p_is_active   BOOLEAN DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.email_templates WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy mẫu email'::TEXT;
    RETURN;
  END IF;
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên mẫu email không được để trống'::TEXT;
    RETURN;
  END IF;
  IF p_content IS NULL OR TRIM(p_content) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nội dung mẫu email không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.email_templates SET
    name        = TRIM(p_name),
    subject     = COALESCE(TRIM(p_subject), subject),
    content     = TRIM(p_content),
    description = COALESCE(p_description, description),
    is_active   = COALESCE(p_is_active, is_active)
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Cap nhat mau email thanh cong'::TEXT;
END;
$$;

CREATE OR REPLACE FUNCTION edoc.fn_email_template_delete(p_id INT)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.email_templates WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy mẫu email'::TEXT;
    RETURN;
  END IF;

  DELETE FROM edoc.email_templates WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xoa mau email thanh cong'::TEXT;
END;
$$;


-- ══════════════════════════════════════════════
-- 2.12 CONFIGURATION (Cau hinh he thong)
-- ══════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.fn_config_get_list(p_unit_id INT DEFAULT NULL)
RETURNS TABLE (id INT, unit_id INT, key VARCHAR, value TEXT, description TEXT)
LANGUAGE sql STABLE
AS $$
  SELECT c.id, c.unit_id, c.key::VARCHAR, c.value, c.description
  FROM public.configurations c
  WHERE (p_unit_id IS NULL OR c.unit_id = p_unit_id)
  ORDER BY c.key;
$$;

CREATE OR REPLACE FUNCTION public.fn_config_upsert(
  p_unit_id     INT,
  p_key         VARCHAR,
  p_value       TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF p_key IS NULL OR TRIM(p_key) = '' THEN
    RETURN QUERY SELECT FALSE, 'Key cấu hình không được để trống'::TEXT;
    RETURN;
  END IF;
  IF LENGTH(p_key) > 100 THEN
    RETURN QUERY SELECT FALSE, 'Key cấu hình không được vượt quá 100 ký tự'::TEXT;
    RETURN;
  END IF;

  INSERT INTO public.configurations (unit_id, key, value, description)
  VALUES (p_unit_id, TRIM(p_key), p_value, p_description)
  ON CONFLICT (unit_id, key) DO UPDATE SET
    value       = EXCLUDED.value,
    description = COALESCE(EXCLUDED.description, configurations.description);

  RETURN QUERY SELECT TRUE, 'Cap nhat cau hinh thanh cong'::TEXT;
END;
$$;


-- ══════════════════════════════════════════════
-- END OF MIGRATION 007
-- ══════════════════════════════════════════════

-- ================================================================
-- Source: 008_sprint3_incoming_docs.sql
-- ================================================================

-- ================================================================
-- SPRINT 3: VĂN BẢN ĐẾN (Incoming Documents)
-- 20 stored procedures
-- ================================================================

-- ==========================================
-- 3.2 CRUD — Lấy số đến tiếp theo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_get_next_number(
  p_doc_book_id INT,
  p_unit_id     INT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE v_max INT;
BEGIN
  SELECT COALESCE(MAX(number), 0) INTO v_max
  FROM edoc.incoming_docs
  WHERE doc_book_id = p_doc_book_id
    AND unit_id = p_unit_id
    AND EXTRACT(YEAR FROM received_date) = EXTRACT(YEAR FROM NOW());
  RETURN v_max + 1;
END;
$$;

-- ==========================================
-- 3.2 CRUD — Tạo văn bản đến
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_create(
  p_unit_id         INT,
  p_received_date   TIMESTAMPTZ,
  p_number          INT,
  p_notation        VARCHAR,
  p_document_code   VARCHAR,
  p_abstract        TEXT,
  p_publish_unit    VARCHAR,
  p_publish_date    TIMESTAMPTZ,
  p_signer          VARCHAR,
  p_sign_date       TIMESTAMPTZ,
  p_doc_book_id     INT,
  p_doc_type_id     INT,
  p_doc_field_id    INT,
  p_secret_id       SMALLINT DEFAULT 1,
  p_urgent_id       SMALLINT DEFAULT 1,
  p_number_paper    INT DEFAULT 1,
  p_number_copies   INT DEFAULT 1,
  p_expired_date    TIMESTAMPTZ DEFAULT NULL,
  p_recipients      TEXT DEFAULT NULL,
  p_is_received_paper BOOLEAN DEFAULT FALSE,
  p_created_by      INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE v_id BIGINT;
BEGIN
  -- Validate
  IF p_abstract IS NULL OR TRIM(p_abstract) = '' THEN
    RETURN QUERY SELECT FALSE, 'Trích yếu nội dung không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  IF p_doc_book_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Sổ văn bản là bắt buộc'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  -- Auto number nếu không truyền
  IF p_number IS NULL OR p_number = 0 THEN
    p_number := edoc.fn_incoming_doc_get_next_number(p_doc_book_id, p_unit_id);
  END IF;

  INSERT INTO edoc.incoming_docs (
    unit_id, received_date, number, notation, document_code,
    abstract, publish_unit, publish_date, signer, sign_date,
    doc_book_id, doc_type_id, doc_field_id, secret_id, urgent_id,
    number_paper, number_copies, expired_date, recipients,
    is_received_paper, created_by, updated_by
  ) VALUES (
    p_unit_id, COALESCE(p_received_date, NOW()), p_number, NULLIF(TRIM(p_notation), ''), NULLIF(TRIM(p_document_code), ''),
    TRIM(p_abstract), NULLIF(TRIM(p_publish_unit), ''), p_publish_date, NULLIF(TRIM(p_signer), ''), p_sign_date,
    p_doc_book_id, p_doc_type_id, p_doc_field_id, COALESCE(p_secret_id, 1), COALESCE(p_urgent_id, 1),
    COALESCE(p_number_paper, 1), COALESCE(p_number_copies, 1), p_expired_date, NULLIF(TRIM(p_recipients), ''),
    COALESCE(p_is_received_paper, FALSE), p_created_by, p_created_by
  )
  RETURNING edoc.incoming_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tạo văn bản đến thành công'::TEXT, v_id;
END;
$$;

-- ==========================================
-- 3.2 CRUD — Cập nhật văn bản đến
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_update(
  p_id              BIGINT,
  p_received_date   TIMESTAMPTZ,
  p_number          INT,
  p_notation        VARCHAR,
  p_document_code   VARCHAR,
  p_abstract        TEXT,
  p_publish_unit    VARCHAR,
  p_publish_date    TIMESTAMPTZ,
  p_signer          VARCHAR,
  p_sign_date       TIMESTAMPTZ,
  p_doc_book_id     INT,
  p_doc_type_id     INT,
  p_doc_field_id    INT,
  p_secret_id       SMALLINT DEFAULT 1,
  p_urgent_id       SMALLINT DEFAULT 1,
  p_number_paper    INT DEFAULT 1,
  p_number_copies   INT DEFAULT 1,
  p_expired_date    TIMESTAMPTZ DEFAULT NULL,
  p_recipients      TEXT DEFAULT NULL,
  p_is_received_paper BOOLEAN DEFAULT FALSE,
  p_updated_by      INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_approved BOOLEAN;
BEGIN
  -- Check exists & approved
  SELECT approved INTO v_approved FROM edoc.incoming_docs WHERE edoc.incoming_docs.id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đến'::TEXT;
    RETURN;
  END IF;
  IF v_approved = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Không thể sửa văn bản đã được duyệt'::TEXT;
    RETURN;
  END IF;

  -- Validate
  IF p_abstract IS NULL OR TRIM(p_abstract) = '' THEN
    RETURN QUERY SELECT FALSE, 'Trích yếu nội dung không được để trống'::TEXT;
    RETURN;
  END IF;

  IF p_doc_book_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Sổ văn bản là bắt buộc'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.incoming_docs SET
    received_date   = COALESCE(p_received_date, received_date),
    number          = COALESCE(p_number, number),
    notation        = NULLIF(TRIM(p_notation), ''),
    document_code   = NULLIF(TRIM(p_document_code), ''),
    abstract        = TRIM(p_abstract),
    publish_unit    = NULLIF(TRIM(p_publish_unit), ''),
    publish_date    = p_publish_date,
    signer          = NULLIF(TRIM(p_signer), ''),
    sign_date       = p_sign_date,
    doc_book_id     = p_doc_book_id,
    doc_type_id     = p_doc_type_id,
    doc_field_id    = p_doc_field_id,
    secret_id       = COALESCE(p_secret_id, 1),
    urgent_id       = COALESCE(p_urgent_id, 1),
    number_paper    = COALESCE(p_number_paper, 1),
    number_copies   = COALESCE(p_number_copies, 1),
    expired_date    = p_expired_date,
    recipients      = NULLIF(TRIM(p_recipients), ''),
    is_received_paper = COALESCE(p_is_received_paper, FALSE),
    updated_by      = p_updated_by,
    updated_at      = NOW()
  WHERE edoc.incoming_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Cập nhật văn bản đến thành công'::TEXT;
END;
$$;

-- ==========================================
-- 3.2 CRUD — Xóa văn bản đến
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_delete(
  p_id BIGINT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_approved BOOLEAN;
BEGIN
  SELECT approved INTO v_approved FROM edoc.incoming_docs WHERE edoc.incoming_docs.id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đến'::TEXT;
    RETURN;
  END IF;
  IF v_approved = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Không thể xóa văn bản đã được duyệt'::TEXT;
    RETURN;
  END IF;

  -- CASCADE sẽ xóa user_incoming_docs, attachments, leader_notes
  DELETE FROM edoc.incoming_docs WHERE edoc.incoming_docs.id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa văn bản đến thành công'::TEXT;
END;
$$;

-- ==========================================
-- 3.1 Danh sách — Lấy danh sách văn bản đến (phân trang)
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_get_list(
  p_unit_id       INT,
  p_staff_id      INT,
  p_doc_book_id   INT       DEFAULT NULL,
  p_doc_type_id   INT       DEFAULT NULL,
  p_doc_field_id  INT       DEFAULT NULL,
  p_urgent_id     SMALLINT  DEFAULT NULL,
  p_is_read       BOOLEAN   DEFAULT NULL,
  p_approved      BOOLEAN   DEFAULT NULL,
  p_from_date     TIMESTAMPTZ DEFAULT NULL,
  p_to_date       TIMESTAMPTZ DEFAULT NULL,
  p_keyword       TEXT      DEFAULT NULL,
  p_page          INT       DEFAULT 1,
  p_page_size     INT       DEFAULT 20
)
RETURNS TABLE (
  id              BIGINT,
  unit_id         INT,
  received_date   TIMESTAMPTZ,
  number          INT,
  notation        VARCHAR,
  document_code   VARCHAR,
  abstract        TEXT,
  publish_unit    VARCHAR,
  publish_date    TIMESTAMPTZ,
  signer          VARCHAR,
  sign_date       TIMESTAMPTZ,
  doc_book_id     INT,
  doc_type_id     INT,
  doc_field_id    INT,
  secret_id       SMALLINT,
  urgent_id       SMALLINT,
  number_paper    INT,
  number_copies   INT,
  expired_date    TIMESTAMPTZ,
  recipients      TEXT,
  approver        VARCHAR,
  approved        BOOLEAN,
  is_handling     BOOLEAN,
  is_received_paper BOOLEAN,
  archive_status  BOOLEAN,
  created_by      INT,
  created_at      TIMESTAMPTZ,
  -- Joined fields
  doc_book_name   VARCHAR,
  doc_type_name   VARCHAR,
  doc_type_code   VARCHAR,
  doc_field_name  VARCHAR,
  created_by_name VARCHAR,
  -- Read status
  is_read         BOOLEAN,
  read_at         TIMESTAMPTZ,
  -- Attachment count
  attachment_count BIGINT,
  -- Pagination
  total_count     BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_offset INT;
  v_keyword TEXT;
BEGIN
  v_offset := (GREATEST(p_page, 1) - 1) * p_page_size;
  v_keyword := NULLIF(TRIM(p_keyword), '');

  RETURN QUERY
  WITH filtered AS (
    SELECT
      d.id AS doc_id,
      d.*,
      db.name AS _doc_book_name,
      dt.name AS _doc_type_name,
      dt.code AS _doc_type_code,
      df.name AS _doc_field_name,
      s.full_name AS _created_by_name,
      uid.is_read AS _is_read,
      uid.read_at AS _read_at,
      (SELECT COUNT(*) FROM edoc.attachment_incoming_docs a WHERE a.incoming_doc_id = d.id) AS _attachment_count,
      COUNT(*) OVER() AS _total_count
    FROM edoc.incoming_docs d
    LEFT JOIN edoc.doc_books db ON db.id = d.doc_book_id
    LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
    LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id
    LEFT JOIN public.staff s ON s.id = d.created_by
    LEFT JOIN edoc.user_incoming_docs uid ON uid.incoming_doc_id = d.id AND uid.staff_id = p_staff_id
    WHERE d.unit_id = p_unit_id
      AND (p_doc_book_id IS NULL OR d.doc_book_id = p_doc_book_id)
      AND (p_doc_type_id IS NULL OR d.doc_type_id = p_doc_type_id)
      AND (p_doc_field_id IS NULL OR d.doc_field_id = p_doc_field_id)
      AND (p_urgent_id IS NULL OR d.urgent_id = p_urgent_id)
      AND (p_approved IS NULL OR d.approved = p_approved)
      AND (p_from_date IS NULL OR d.received_date >= p_from_date)
      AND (p_to_date IS NULL OR d.received_date <= p_to_date)
      AND (p_is_read IS NULL OR (p_is_read = TRUE AND uid.is_read = TRUE) OR (p_is_read = FALSE AND (uid.is_read IS NULL OR uid.is_read = FALSE)))
      AND (v_keyword IS NULL OR
           d.abstract ILIKE '%' || v_keyword || '%' OR
           d.notation ILIKE '%' || v_keyword || '%' OR
           d.publish_unit ILIKE '%' || v_keyword || '%' OR
           d.signer ILIKE '%' || v_keyword || '%' OR
           d.document_code ILIKE '%' || v_keyword || '%'
      )
    ORDER BY d.received_date DESC, d.number DESC
    LIMIT p_page_size OFFSET v_offset
  )
  SELECT
    f.doc_id,
    f.unit_id,
    f.received_date,
    f.number,
    f.notation,
    f.document_code,
    f.abstract,
    f.publish_unit,
    f.publish_date,
    f.signer,
    f.sign_date,
    f.doc_book_id,
    f.doc_type_id,
    f.doc_field_id,
    f.secret_id,
    f.urgent_id,
    f.number_paper,
    f.number_copies,
    f.expired_date,
    f.recipients,
    f.approver,
    f.approved,
    f.is_handling,
    f.is_received_paper,
    f.archive_status,
    f.created_by,
    f.created_at,
    f._doc_book_name,
    f._doc_type_name,
    f._doc_type_code,
    f._doc_field_name,
    f._created_by_name,
    COALESCE(f._is_read, FALSE),
    f._read_at,
    f._attachment_count,
    f._total_count
  FROM filtered f;
END;
$$;

-- ==========================================
-- 3.1 Danh sách — Đếm chưa đọc
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_count_unread(
  p_unit_id   INT,
  p_staff_id  INT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE v_count INT;
BEGIN
  SELECT COUNT(*)::INT INTO v_count
  FROM edoc.incoming_docs d
  LEFT JOIN edoc.user_incoming_docs uid ON uid.incoming_doc_id = d.id AND uid.staff_id = p_staff_id
  WHERE d.unit_id = p_unit_id
    AND (uid.is_read IS NULL OR uid.is_read = FALSE);
  RETURN v_count;
END;
$$;

-- ==========================================
-- 3.1 Danh sách — Đánh dấu đã đọc
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_mark_read(
  p_doc_id    BIGINT,
  p_staff_id  INT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO edoc.user_incoming_docs (incoming_doc_id, staff_id, is_read, read_at)
  VALUES (p_doc_id, p_staff_id, TRUE, NOW())
  ON CONFLICT (incoming_doc_id, staff_id)
  DO UPDATE SET is_read = TRUE, read_at = COALESCE(edoc.user_incoming_docs.read_at, NOW());
END;
$$;

-- ==========================================
-- 3.1 Danh sách — Đánh dấu đã đọc hàng loạt
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_mark_read_bulk(
  p_doc_ids   BIGINT[],
  p_staff_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO edoc.user_incoming_docs (incoming_doc_id, staff_id, is_read, read_at)
  SELECT unnest(p_doc_ids), p_staff_id, TRUE, NOW()
  ON CONFLICT (incoming_doc_id, staff_id)
  DO UPDATE SET is_read = TRUE, read_at = COALESCE(edoc.user_incoming_docs.read_at, NOW());

  RETURN QUERY SELECT TRUE, 'Đã đánh dấu đọc thành công'::TEXT;
END;
$$;

-- ==========================================
-- 3.3 Chi tiết — Lấy theo ID
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_get_by_id(
  p_id        BIGINT,
  p_staff_id  INT
)
RETURNS TABLE (
  id              BIGINT,
  unit_id         INT,
  received_date   TIMESTAMPTZ,
  number          INT,
  notation        VARCHAR,
  document_code   VARCHAR,
  abstract        TEXT,
  publish_unit    VARCHAR,
  publish_date    TIMESTAMPTZ,
  signer          VARCHAR,
  sign_date       TIMESTAMPTZ,
  doc_book_id     INT,
  doc_type_id     INT,
  doc_field_id    INT,
  secret_id       SMALLINT,
  urgent_id       SMALLINT,
  number_paper    INT,
  number_copies   INT,
  expired_date    TIMESTAMPTZ,
  recipients      TEXT,
  approver        VARCHAR,
  approved        BOOLEAN,
  is_handling     BOOLEAN,
  is_received_paper BOOLEAN,
  archive_status  BOOLEAN,
  created_by      INT,
  created_at      TIMESTAMPTZ,
  updated_by      INT,
  updated_at      TIMESTAMPTZ,
  -- Joined
  doc_book_name   VARCHAR,
  doc_type_name   VARCHAR,
  doc_type_code   VARCHAR,
  doc_field_name  VARCHAR,
  created_by_name VARCHAR,
  is_read         BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
  -- Đánh dấu đã đọc
  PERFORM edoc.fn_incoming_doc_mark_read(p_id, p_staff_id);

  RETURN QUERY
  SELECT
    d.id, d.unit_id, d.received_date, d.number, d.notation, d.document_code,
    d.abstract, d.publish_unit, d.publish_date, d.signer, d.sign_date,
    d.doc_book_id, d.doc_type_id, d.doc_field_id, d.secret_id, d.urgent_id,
    d.number_paper, d.number_copies, d.expired_date, d.recipients,
    d.approver, d.approved, d.is_handling, d.is_received_paper, d.archive_status,
    d.created_by, d.created_at, d.updated_by, d.updated_at,
    db.name, dt.name, dt.code, df.name, s.full_name,
    TRUE  -- đã mark read ở trên
  FROM edoc.incoming_docs d
  LEFT JOIN edoc.doc_books db ON db.id = d.doc_book_id
  LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
  LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id
  LEFT JOIN public.staff s ON s.id = d.created_by
  WHERE d.id = p_id;
END;
$$;

-- ==========================================
-- 3.3 Chi tiết — Danh sách người nhận
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_get_recipients(
  p_doc_id BIGINT
)
RETURNS TABLE (
  id          BIGINT,
  staff_id    INT,
  staff_name  VARCHAR,
  position_name VARCHAR,
  department_name VARCHAR,
  is_read     BOOLEAN,
  read_at     TIMESTAMPTZ,
  created_at  TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    uid.id, uid.staff_id,
    s.full_name,
    p.name AS position_name,
    dep.name AS department_name,
    uid.is_read, uid.read_at, uid.created_at
  FROM edoc.user_incoming_docs uid
  JOIN public.staff s ON s.id = uid.staff_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  LEFT JOIN public.departments dep ON dep.id = s.department_id
  WHERE uid.incoming_doc_id = p_doc_id
  ORDER BY uid.created_at DESC;
END;
$$;

-- ==========================================
-- 3.3 Chi tiết — Lịch sử xử lý (timeline)
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_get_history(
  p_doc_id BIGINT
)
RETURNS TABLE (
  event_type  VARCHAR,
  event_time  TIMESTAMPTZ,
  staff_name  VARCHAR,
  content     TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM (
    -- Tạo VB
    SELECT 'created'::VARCHAR AS evt, d.created_at AS etime, s.full_name AS sname, ('Tạo văn bản đến, số đến: ' || d.number)::TEXT AS econtent
    FROM edoc.incoming_docs d
    JOIN public.staff s ON s.id = d.created_by
    WHERE d.id = p_doc_id

    UNION ALL
    -- Duyệt
    SELECT 'approved'::VARCHAR, d.updated_at, d.approver::VARCHAR, 'Duyệt văn bản'::TEXT
    FROM edoc.incoming_docs d
    WHERE d.id = p_doc_id AND d.approved = TRUE

    UNION ALL
    -- Gửi cho cán bộ
    SELECT 'sent'::VARCHAR, uid.created_at, s.full_name, ('Nhận văn bản')::TEXT
    FROM edoc.user_incoming_docs uid
    JOIN public.staff s ON s.id = uid.staff_id
    WHERE uid.incoming_doc_id = p_doc_id

    UNION ALL
    -- Bút phê
    SELECT 'leader_note'::VARCHAR, ln.created_at, s.full_name, ln.content
    FROM edoc.leader_notes ln
    JOIN public.staff s ON s.id = ln.staff_id
    WHERE ln.incoming_doc_id = p_doc_id
  ) sub
  ORDER BY sub.etime DESC;
END;
$$;

-- ==========================================
-- 3.4 File đính kèm — Danh sách
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_attachment_incoming_get_list(
  p_doc_id BIGINT
)
RETURNS TABLE (
  id            BIGINT,
  file_name     VARCHAR,
  file_path     VARCHAR,
  file_size     BIGINT,
  content_type  VARCHAR,
  sort_order    INT,
  created_by    INT,
  created_at    TIMESTAMPTZ,
  created_by_name VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT a.id, a.file_name, a.file_path, a.file_size, a.content_type,
         a.sort_order, a.created_by, a.created_at, s.full_name
  FROM edoc.attachment_incoming_docs a
  LEFT JOIN public.staff s ON s.id = a.created_by
  WHERE a.incoming_doc_id = p_doc_id
  ORDER BY a.sort_order, a.created_at;
END;
$$;

-- ==========================================
-- 3.4 File đính kèm — Tạo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_attachment_incoming_create(
  p_doc_id       BIGINT,
  p_file_name    VARCHAR,
  p_file_path    VARCHAR,
  p_file_size    BIGINT,
  p_content_type VARCHAR,
  p_created_by   INT
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE v_id BIGINT;
BEGIN
  IF p_file_name IS NULL OR TRIM(p_file_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên file không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.attachment_incoming_docs (incoming_doc_id, file_name, file_path, file_size, content_type, created_by)
  VALUES (p_doc_id, p_file_name, p_file_path, COALESCE(p_file_size, 0), p_content_type, p_created_by)
  RETURNING edoc.attachment_incoming_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tải lên thành công'::TEXT, v_id;
END;
$$;

-- ==========================================
-- 3.4 File đính kèm — Xóa (trả về file_path để xóa trên MinIO)
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_attachment_incoming_delete(
  p_id BIGINT
)
RETURNS TABLE (success BOOLEAN, message TEXT, file_path VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE v_path VARCHAR;
BEGIN
  SELECT a.file_path INTO v_path FROM edoc.attachment_incoming_docs a WHERE a.id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy file đính kèm'::TEXT, ''::VARCHAR;
    RETURN;
  END IF;

  DELETE FROM edoc.attachment_incoming_docs WHERE edoc.attachment_incoming_docs.id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa file thành công'::TEXT, v_path;
END;
$$;

-- ==========================================
-- 3.5 Gửi / Phân phối — DS cán bộ có thể gửi
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_get_sendable_staff(
  p_unit_id INT
)
RETURNS TABLE (
  staff_id        INT,
  full_name       VARCHAR,
  position_name   VARCHAR,
  department_id   INT,
  department_name VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT s.id, s.full_name, p.name, s.department_id, d.name
  FROM public.staff s
  LEFT JOIN public.positions p ON p.id = s.position_id
  LEFT JOIN public.departments d ON d.id = s.department_id
  WHERE s.department_id IN (
    SELECT dep.id FROM public.departments dep
    WHERE dep.id = p_unit_id OR dep.parent_id = p_unit_id
  )
  AND s.is_locked = FALSE AND s.is_deleted = FALSE
  ORDER BY d.sort_order, d.name, s.full_name;
END;
$$;

-- ==========================================
-- 3.5 Gửi / Phân phối — Gửi VB cho cán bộ
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_send(
  p_doc_id    BIGINT,
  p_staff_ids INT[],
  p_sent_by   INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
  v_approved BOOLEAN;
  v_count INT;
BEGIN
  -- Check approved
  SELECT approved INTO v_approved FROM edoc.incoming_docs WHERE edoc.incoming_docs.id = p_doc_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đến'::TEXT;
    RETURN;
  END IF;
  IF v_approved IS NULL OR v_approved = FALSE THEN
    RETURN QUERY SELECT FALSE, 'Văn bản chưa được duyệt, không thể gửi'::TEXT;
    RETURN;
  END IF;

  IF p_staff_ids IS NULL OR array_length(p_staff_ids, 1) IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Vui lòng chọn ít nhất một người nhận'::TEXT;
    RETURN;
  END IF;

  -- Insert, skip duplicates
  INSERT INTO edoc.user_incoming_docs (incoming_doc_id, staff_id, is_read, created_at)
  SELECT p_doc_id, unnest(p_staff_ids), FALSE, NOW()
  ON CONFLICT (incoming_doc_id, staff_id) DO NOTHING;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN QUERY SELECT TRUE, ('Đã gửi cho ' || v_count || ' người nhận')::TEXT;
END;
$$;

-- ==========================================
-- 3.6 Bút phê — Danh sách
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_leader_note_get_list(
  p_doc_id BIGINT
)
RETURNS TABLE (
  id          BIGINT,
  staff_id    INT,
  staff_name  VARCHAR,
  position_name VARCHAR,
  content     TEXT,
  created_at  TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT ln.id, ln.staff_id, s.full_name, p.name, ln.content, ln.created_at
  FROM edoc.leader_notes ln
  JOIN public.staff s ON s.id = ln.staff_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  WHERE ln.incoming_doc_id = p_doc_id
  ORDER BY ln.created_at DESC;
END;
$$;

-- ==========================================
-- 3.6 Bút phê — Tạo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_leader_note_create(
  p_doc_id    BIGINT,
  p_staff_id  INT,
  p_content   TEXT
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE v_id BIGINT;
BEGIN
  IF p_content IS NULL OR TRIM(p_content) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nội dung bút phê không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.leader_notes (incoming_doc_id, staff_id, content)
  VALUES (p_doc_id, p_staff_id, TRIM(p_content))
  RETURNING edoc.leader_notes.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Thêm bút phê thành công'::TEXT, v_id;
END;
$$;

-- ==========================================
-- 3.6 Bút phê — Xóa
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_leader_note_delete(
  p_id        BIGINT,
  p_staff_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM edoc.leader_notes
  WHERE edoc.leader_notes.id = p_id AND staff_id = p_staff_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy bút phê hoặc bạn không có quyền xóa'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, 'Xóa bút phê thành công'::TEXT;
END;
$$;

-- ==========================================
-- 3.7 Đánh dấu cá nhân — Toggle bookmark
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_staff_note_toggle(
  p_doc_type  VARCHAR,
  p_doc_id    BIGINT,
  p_staff_id  INT,
  p_note      TEXT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, is_bookmarked BOOLEAN)
LANGUAGE plpgsql
AS $$
DECLARE v_exists BOOLEAN;
BEGIN
  SELECT TRUE INTO v_exists
  FROM edoc.staff_notes
  WHERE doc_type = p_doc_type AND doc_id = p_doc_id AND staff_id = p_staff_id;

  IF v_exists THEN
    DELETE FROM edoc.staff_notes
    WHERE doc_type = p_doc_type AND doc_id = p_doc_id AND staff_id = p_staff_id;
    RETURN QUERY SELECT TRUE, 'Đã bỏ đánh dấu'::TEXT, FALSE;
  ELSE
    INSERT INTO edoc.staff_notes (doc_type, doc_id, staff_id, note)
    VALUES (p_doc_type, p_doc_id, p_staff_id, NULLIF(TRIM(p_note), ''));
    RETURN QUERY SELECT TRUE, 'Đã đánh dấu'::TEXT, TRUE;
  END IF;
END;
$$;

-- ==========================================
-- 3.7 Đánh dấu cá nhân — Danh sách VB đánh dấu
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_staff_note_get_list(
  p_staff_id  INT,
  p_doc_type  VARCHAR DEFAULT 'incoming'
)
RETURNS TABLE (
  note_id     BIGINT,
  doc_id      BIGINT,
  note        TEXT,
  created_at  TIMESTAMPTZ,
  -- Doc info
  doc_number      INT,
  doc_notation    VARCHAR,
  doc_abstract    TEXT,
  doc_received_date TIMESTAMPTZ,
  doc_publish_unit  VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT sn.id, sn.doc_id, sn.note, sn.created_at,
         d.number, d.notation, d.abstract, d.received_date, d.publish_unit
  FROM edoc.staff_notes sn
  JOIN edoc.incoming_docs d ON d.id = sn.doc_id
  WHERE sn.staff_id = p_staff_id AND sn.doc_type = p_doc_type
  ORDER BY sn.created_at DESC;
END;
$$;

-- ==========================================
-- 3.8 Duyệt / Hủy duyệt
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_approve(
  p_id        BIGINT,
  p_staff_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_staff_name VARCHAR;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.incoming_docs WHERE edoc.incoming_docs.id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đến'::TEXT;
    RETURN;
  END IF;

  SELECT full_name INTO v_staff_name FROM public.staff WHERE public.staff.id = p_staff_id;

  UPDATE edoc.incoming_docs SET
    approved = TRUE,
    approver = v_staff_name,
    updated_by = p_staff_id,
    updated_at = NOW()
  WHERE edoc.incoming_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Duyệt văn bản thành công'::TEXT;
END;
$$;

CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_unapprove(
  p_id        BIGINT,
  p_staff_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_has_sent BOOLEAN;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.incoming_docs WHERE edoc.incoming_docs.id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đến'::TEXT;
    RETURN;
  END IF;

  -- Không cho hủy duyệt nếu đã gửi
  SELECT EXISTS(SELECT 1 FROM edoc.user_incoming_docs WHERE incoming_doc_id = p_id) INTO v_has_sent;
  IF v_has_sent THEN
    RETURN QUERY SELECT FALSE, 'Không thể hủy duyệt: văn bản đã được gửi cho cán bộ'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.incoming_docs SET
    approved = FALSE,
    approver = NULL,
    updated_by = p_staff_id,
    updated_at = NOW()
  WHERE edoc.incoming_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Hủy duyệt thành công'::TEXT;
END;
$$;

-- ==========================================
-- 3.8 Nhận bản giấy
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_receive_paper(
  p_id        BIGINT,
  p_staff_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE edoc.incoming_docs SET
    is_received_paper = TRUE,
    updated_by = p_staff_id,
    updated_at = NOW()
  WHERE edoc.incoming_docs.id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đến'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, 'Đã xác nhận nhận bản giấy'::TEXT;
END;
$$;

-- ==========================================
-- FN: THU HỒI VĂN BẢN ĐẾN (Retract)
-- Xóa user_incoming_docs (trừ người tạo), reset approved
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_retract(
  p_id       BIGINT,
  p_staff_id INT
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_deleted_count INT;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.incoming_docs WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đến'::TEXT; RETURN;
  END IF;

  DELETE FROM edoc.user_incoming_docs
  WHERE incoming_doc_id = p_id AND staff_id != p_staff_id;
  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;

  UPDATE edoc.incoming_docs
  SET approved = FALSE, updated_by = p_staff_id, updated_at = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, ('Thu hồi thành công — đã xóa ' || v_deleted_count || ' người nhận')::TEXT;
END;
$$;

-- ================================================================
-- Source: 009_sprint4_drafting_outgoing.sql
-- ================================================================

-- ================================================================
-- SPRINT 4: VĂN BẢN DỰ THẢO & VĂN BẢN ĐI
-- ~30 stored procedures
-- ================================================================

-- ==========================================
-- 0. ALTER TABLES — Thêm cột còn thiếu
-- ==========================================
-- drafting_docs cần thêm: approver, expired_date
ALTER TABLE edoc.drafting_docs ADD COLUMN IF NOT EXISTS approver VARCHAR(200);
ALTER TABLE edoc.drafting_docs ADD COLUMN IF NOT EXISTS expired_date TIMESTAMPTZ;
ALTER TABLE edoc.drafting_docs ADD COLUMN IF NOT EXISTS document_code VARCHAR(100);

-- outgoing_docs cần thêm: approver
ALTER TABLE edoc.outgoing_docs ADD COLUMN IF NOT EXISTS approver VARCHAR(200);

-- Index cho drafting
CREATE INDEX IF NOT EXISTS idx_drafting_docs_unit ON edoc.drafting_docs(unit_id, received_date DESC);
CREATE INDEX IF NOT EXISTS idx_drafting_docs_search ON edoc.drafting_docs USING gin(abstract gin_trgm_ops);

-- Index cho user tracking
CREATE INDEX IF NOT EXISTS idx_user_outgoing_docs_staff ON edoc.user_outgoing_docs(staff_id, is_read);
CREATE INDEX IF NOT EXISTS idx_user_drafting_docs_staff ON edoc.user_drafting_docs(staff_id, is_read);


-- ================================================================
-- PHẦN A: VĂN BẢN DỰ THẢO (DRAFTING DOCS)
-- ================================================================

-- ==========================================
-- A.1 Lấy số tiếp theo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_get_next_number(
  p_doc_book_id INT,
  p_unit_id     INT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE v_max INT;
BEGIN
  SELECT COALESCE(MAX(number), 0) INTO v_max
  FROM edoc.drafting_docs
  WHERE doc_book_id = p_doc_book_id
    AND unit_id = p_unit_id
    AND EXTRACT(YEAR FROM received_date) = EXTRACT(YEAR FROM NOW());
  RETURN v_max + 1;
END;
$$;

-- ==========================================
-- A.2 Tạo văn bản dự thảo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_create(
  p_unit_id           INT,
  p_received_date     TIMESTAMPTZ,
  p_number            INT,
  p_sub_number        VARCHAR,
  p_notation          VARCHAR,
  p_document_code     VARCHAR,
  p_abstract          TEXT,
  p_drafting_unit_id  INT        DEFAULT NULL,
  p_drafting_user_id  INT        DEFAULT NULL,
  p_publish_unit_id   INT        DEFAULT NULL,
  p_publish_date      TIMESTAMPTZ DEFAULT NULL,
  p_signer            VARCHAR    DEFAULT NULL,
  p_sign_date         TIMESTAMPTZ DEFAULT NULL,
  p_doc_book_id       INT        DEFAULT NULL,
  p_doc_type_id       INT        DEFAULT NULL,
  p_doc_field_id      INT        DEFAULT NULL,
  p_secret_id         SMALLINT   DEFAULT 1,
  p_urgent_id         SMALLINT   DEFAULT 1,
  p_number_paper      INT        DEFAULT 1,
  p_number_copies     INT        DEFAULT 1,
  p_expired_date      TIMESTAMPTZ DEFAULT NULL,
  p_recipients        TEXT       DEFAULT NULL,
  p_created_by        INT        DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE v_id BIGINT;
BEGIN
  -- Validate
  IF p_abstract IS NULL OR TRIM(p_abstract) = '' THEN
    RETURN QUERY SELECT FALSE, 'Trích yếu nội dung không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  IF p_doc_book_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Sổ văn bản là bắt buộc'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  -- Auto number nếu không truyền
  IF p_number IS NULL OR p_number = 0 THEN
    p_number := edoc.fn_drafting_doc_get_next_number(p_doc_book_id, p_unit_id);
  END IF;

  INSERT INTO edoc.drafting_docs (
    unit_id, received_date, number, sub_number, notation, document_code,
    abstract, drafting_unit_id, drafting_user_id, publish_unit_id, publish_date,
    signer, sign_date, doc_book_id, doc_type_id, doc_field_id,
    secret_id, urgent_id, number_paper, number_copies, expired_date,
    recipients, created_by, updated_by
  ) VALUES (
    p_unit_id, COALESCE(p_received_date, NOW()), p_number,
    NULLIF(TRIM(p_sub_number), ''), NULLIF(TRIM(p_notation), ''), NULLIF(TRIM(p_document_code), ''),
    TRIM(p_abstract), p_drafting_unit_id, p_drafting_user_id, p_publish_unit_id, p_publish_date,
    NULLIF(TRIM(p_signer), ''), p_sign_date, p_doc_book_id, p_doc_type_id, p_doc_field_id,
    COALESCE(p_secret_id, 1), COALESCE(p_urgent_id, 1),
    COALESCE(p_number_paper, 1), COALESCE(p_number_copies, 1), p_expired_date,
    NULLIF(TRIM(p_recipients), ''), p_created_by, p_created_by
  )
  RETURNING edoc.drafting_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tạo văn bản dự thảo thành công'::TEXT, v_id;
END;
$$;

-- ==========================================
-- A.3 Cập nhật văn bản dự thảo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_update(
  p_id                BIGINT,
  p_received_date     TIMESTAMPTZ,
  p_number            INT,
  p_sub_number        VARCHAR,
  p_notation          VARCHAR,
  p_document_code     VARCHAR,
  p_abstract          TEXT,
  p_drafting_unit_id  INT        DEFAULT NULL,
  p_drafting_user_id  INT        DEFAULT NULL,
  p_publish_unit_id   INT        DEFAULT NULL,
  p_publish_date      TIMESTAMPTZ DEFAULT NULL,
  p_signer            VARCHAR    DEFAULT NULL,
  p_sign_date         TIMESTAMPTZ DEFAULT NULL,
  p_doc_book_id       INT        DEFAULT NULL,
  p_doc_type_id       INT        DEFAULT NULL,
  p_doc_field_id      INT        DEFAULT NULL,
  p_secret_id         SMALLINT   DEFAULT 1,
  p_urgent_id         SMALLINT   DEFAULT 1,
  p_number_paper      INT        DEFAULT 1,
  p_number_copies     INT        DEFAULT 1,
  p_expired_date      TIMESTAMPTZ DEFAULT NULL,
  p_recipients        TEXT       DEFAULT NULL,
  p_updated_by        INT        DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
  v_approved BOOLEAN;
  v_released BOOLEAN;
BEGIN
  SELECT approved, is_released INTO v_approved, v_released
  FROM edoc.drafting_docs WHERE edoc.drafting_docs.id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản dự thảo'::TEXT;
    RETURN;
  END IF;
  IF v_approved = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Không thể sửa văn bản đã được duyệt'::TEXT;
    RETURN;
  END IF;
  IF v_released = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Không thể sửa văn bản đã phát hành'::TEXT;
    RETURN;
  END IF;

  IF p_abstract IS NULL OR TRIM(p_abstract) = '' THEN
    RETURN QUERY SELECT FALSE, 'Trích yếu nội dung không được để trống'::TEXT;
    RETURN;
  END IF;
  IF p_doc_book_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Sổ văn bản là bắt buộc'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.drafting_docs SET
    received_date     = COALESCE(p_received_date, received_date),
    number            = COALESCE(p_number, number),
    sub_number        = NULLIF(TRIM(p_sub_number), ''),
    notation          = NULLIF(TRIM(p_notation), ''),
    document_code     = NULLIF(TRIM(p_document_code), ''),
    abstract          = TRIM(p_abstract),
    drafting_unit_id  = p_drafting_unit_id,
    drafting_user_id  = p_drafting_user_id,
    publish_unit_id   = p_publish_unit_id,
    publish_date      = p_publish_date,
    signer            = NULLIF(TRIM(p_signer), ''),
    sign_date         = p_sign_date,
    doc_book_id       = p_doc_book_id,
    doc_type_id       = p_doc_type_id,
    doc_field_id      = p_doc_field_id,
    secret_id         = COALESCE(p_secret_id, 1),
    urgent_id         = COALESCE(p_urgent_id, 1),
    number_paper      = COALESCE(p_number_paper, 1),
    number_copies     = COALESCE(p_number_copies, 1),
    expired_date      = p_expired_date,
    recipients        = NULLIF(TRIM(p_recipients), ''),
    updated_by        = p_updated_by,
    updated_at        = NOW()
  WHERE edoc.drafting_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Cập nhật văn bản dự thảo thành công'::TEXT;
END;
$$;

-- ==========================================
-- A.4 Xóa văn bản dự thảo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_delete(
  p_id BIGINT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
  v_approved BOOLEAN;
  v_released BOOLEAN;
BEGIN
  SELECT approved, is_released INTO v_approved, v_released
  FROM edoc.drafting_docs WHERE edoc.drafting_docs.id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản dự thảo'::TEXT;
    RETURN;
  END IF;
  IF v_approved = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Không thể xóa văn bản đã được duyệt'::TEXT;
    RETURN;
  END IF;
  IF v_released = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Không thể xóa văn bản đã phát hành'::TEXT;
    RETURN;
  END IF;

  DELETE FROM edoc.drafting_docs WHERE edoc.drafting_docs.id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa văn bản dự thảo thành công'::TEXT;
END;
$$;

-- ==========================================
-- A.5 Danh sách văn bản dự thảo (phân trang)
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_get_list(
  p_unit_id       INT,
  p_staff_id      INT,
  p_doc_book_id   INT       DEFAULT NULL,
  p_doc_type_id   INT       DEFAULT NULL,
  p_doc_field_id  INT       DEFAULT NULL,
  p_urgent_id     SMALLINT  DEFAULT NULL,
  p_is_released   BOOLEAN   DEFAULT NULL,
  p_approved      BOOLEAN   DEFAULT NULL,
  p_from_date     TIMESTAMPTZ DEFAULT NULL,
  p_to_date       TIMESTAMPTZ DEFAULT NULL,
  p_keyword       TEXT      DEFAULT NULL,
  p_page          INT       DEFAULT 1,
  p_page_size     INT       DEFAULT 20
)
RETURNS TABLE (
  id              BIGINT,
  unit_id         INT,
  received_date   TIMESTAMPTZ,
  number          INT,
  sub_number      VARCHAR,
  notation        VARCHAR,
  document_code   VARCHAR,
  abstract        TEXT,
  drafting_unit_id  INT,
  drafting_user_id  INT,
  publish_unit_id   INT,
  publish_date    TIMESTAMPTZ,
  signer          VARCHAR,
  sign_date       TIMESTAMPTZ,
  doc_book_id     INT,
  doc_type_id     INT,
  doc_field_id    INT,
  secret_id       SMALLINT,
  urgent_id       SMALLINT,
  number_paper    INT,
  number_copies   INT,
  expired_date    TIMESTAMPTZ,
  recipients      TEXT,
  approver        VARCHAR,
  approved        BOOLEAN,
  is_released     BOOLEAN,
  released_date   TIMESTAMPTZ,
  created_by      INT,
  created_at      TIMESTAMPTZ,
  -- Joined
  doc_book_name   VARCHAR,
  doc_type_name   VARCHAR,
  doc_type_code   VARCHAR,
  doc_field_name  VARCHAR,
  drafting_unit_name VARCHAR,
  drafting_user_name VARCHAR,
  created_by_name VARCHAR,
  -- Read status
  is_read         BOOLEAN,
  read_at         TIMESTAMPTZ,
  -- Attachment count
  attachment_count BIGINT,
  -- Pagination
  total_count     BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_offset INT;
  v_keyword TEXT;
BEGIN
  v_offset := (GREATEST(p_page, 1) - 1) * p_page_size;
  v_keyword := NULLIF(TRIM(p_keyword), '');

  RETURN QUERY
  WITH filtered AS (
    SELECT
      d.id AS doc_id,
      d.*,
      db.name AS _doc_book_name,
      dt.name AS _doc_type_name,
      dt.code AS _doc_type_code,
      df.name AS _doc_field_name,
      du.name AS _drafting_unit_name,
      ds.full_name AS _drafting_user_name,
      s.full_name AS _created_by_name,
      ud.is_read AS _is_read,
      ud.read_at AS _read_at,
      (SELECT COUNT(*) FROM edoc.attachment_drafting_docs a WHERE a.drafting_doc_id = d.id) AS _attachment_count,
      COUNT(*) OVER() AS _total_count
    FROM edoc.drafting_docs d
    LEFT JOIN edoc.doc_books db ON db.id = d.doc_book_id
    LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
    LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id
    LEFT JOIN public.departments du ON du.id = d.drafting_unit_id
    LEFT JOIN public.staff ds ON ds.id = d.drafting_user_id
    LEFT JOIN public.staff s ON s.id = d.created_by
    LEFT JOIN edoc.user_drafting_docs ud ON ud.drafting_doc_id = d.id AND ud.staff_id = p_staff_id
    WHERE d.unit_id = p_unit_id
      AND (p_doc_book_id IS NULL OR d.doc_book_id = p_doc_book_id)
      AND (p_doc_type_id IS NULL OR d.doc_type_id = p_doc_type_id)
      AND (p_doc_field_id IS NULL OR d.doc_field_id = p_doc_field_id)
      AND (p_urgent_id IS NULL OR d.urgent_id = p_urgent_id)
      AND (p_approved IS NULL OR d.approved = p_approved)
      AND (p_is_released IS NULL OR d.is_released = p_is_released)
      AND (p_from_date IS NULL OR d.received_date >= p_from_date)
      AND (p_to_date IS NULL OR d.received_date <= p_to_date)
      AND (v_keyword IS NULL OR
           d.abstract ILIKE '%' || v_keyword || '%' OR
           d.notation ILIKE '%' || v_keyword || '%' OR
           d.signer ILIKE '%' || v_keyword || '%' OR
           d.recipients ILIKE '%' || v_keyword || '%'
      )
    ORDER BY d.received_date DESC, d.number DESC
    LIMIT p_page_size OFFSET v_offset
  )
  SELECT
    f.doc_id, f.unit_id, f.received_date, f.number, f.sub_number,
    f.notation, f.document_code, f.abstract,
    f.drafting_unit_id, f.drafting_user_id, f.publish_unit_id, f.publish_date,
    f.signer, f.sign_date, f.doc_book_id, f.doc_type_id, f.doc_field_id,
    f.secret_id, f.urgent_id, f.number_paper, f.number_copies,
    f.expired_date, f.recipients, f.approver, f.approved,
    f.is_released, f.released_date, f.created_by, f.created_at,
    f._doc_book_name, f._doc_type_name, f._doc_type_code, f._doc_field_name,
    f._drafting_unit_name, f._drafting_user_name, f._created_by_name,
    COALESCE(f._is_read, FALSE), f._read_at,
    f._attachment_count, f._total_count
  FROM filtered f;
END;
$$;

-- ==========================================
-- A.6 Chi tiết văn bản dự thảo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_get_by_id(
  p_id        BIGINT,
  p_staff_id  INT
)
RETURNS TABLE (
  id              BIGINT,
  unit_id         INT,
  received_date   TIMESTAMPTZ,
  number          INT,
  sub_number      VARCHAR,
  notation        VARCHAR,
  document_code   VARCHAR,
  abstract        TEXT,
  drafting_unit_id  INT,
  drafting_user_id  INT,
  publish_unit_id   INT,
  publish_date    TIMESTAMPTZ,
  signer          VARCHAR,
  sign_date       TIMESTAMPTZ,
  doc_book_id     INT,
  doc_type_id     INT,
  doc_field_id    INT,
  secret_id       SMALLINT,
  urgent_id       SMALLINT,
  number_paper    INT,
  number_copies   INT,
  expired_date    TIMESTAMPTZ,
  recipients      TEXT,
  approver        VARCHAR,
  approved        BOOLEAN,
  is_released     BOOLEAN,
  released_date   TIMESTAMPTZ,
  created_by      INT,
  created_at      TIMESTAMPTZ,
  updated_by      INT,
  updated_at      TIMESTAMPTZ,
  -- Joined
  doc_book_name   VARCHAR,
  doc_type_name   VARCHAR,
  doc_type_code   VARCHAR,
  doc_field_name  VARCHAR,
  drafting_unit_name VARCHAR,
  drafting_user_name VARCHAR,
  created_by_name VARCHAR,
  is_read         BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
  -- Đánh dấu đã đọc
  INSERT INTO edoc.user_drafting_docs (drafting_doc_id, staff_id, is_read, read_at)
  VALUES (p_id, p_staff_id, TRUE, NOW())
  ON CONFLICT (drafting_doc_id, staff_id)
  DO UPDATE SET is_read = TRUE, read_at = COALESCE(edoc.user_drafting_docs.read_at, NOW());

  RETURN QUERY
  SELECT
    d.id, d.unit_id, d.received_date, d.number, d.sub_number,
    d.notation, d.document_code, d.abstract,
    d.drafting_unit_id, d.drafting_user_id, d.publish_unit_id, d.publish_date,
    d.signer, d.sign_date, d.doc_book_id, d.doc_type_id, d.doc_field_id,
    d.secret_id, d.urgent_id, d.number_paper, d.number_copies,
    d.expired_date, d.recipients, d.approver, d.approved,
    d.is_released, d.released_date,
    d.created_by, d.created_at, d.updated_by, d.updated_at,
    db.name, dt.name, dt.code, df.name,
    du.name, ds.full_name, s.full_name,
    TRUE  -- đã mark read ở trên
  FROM edoc.drafting_docs d
  LEFT JOIN edoc.doc_books db ON db.id = d.doc_book_id
  LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
  LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id
  LEFT JOIN public.departments du ON du.id = d.drafting_unit_id
  LEFT JOIN public.staff ds ON ds.id = d.drafting_user_id
  LEFT JOIN public.staff s ON s.id = d.created_by
  WHERE d.id = p_id;
END;
$$;

-- ==========================================
-- A.7 Đếm chưa đọc — dự thảo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_count_unread(
  p_unit_id   INT,
  p_staff_id  INT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE v_count INT;
BEGIN
  SELECT COUNT(*)::INT INTO v_count
  FROM edoc.drafting_docs d
  LEFT JOIN edoc.user_drafting_docs ud ON ud.drafting_doc_id = d.id AND ud.staff_id = p_staff_id
  WHERE d.unit_id = p_unit_id
    AND (ud.is_read IS NULL OR ud.is_read = FALSE);
  RETURN v_count;
END;
$$;

-- ==========================================
-- A.8 Đánh dấu đã đọc hàng loạt — dự thảo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_mark_read_bulk(
  p_doc_ids   BIGINT[],
  p_staff_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO edoc.user_drafting_docs (drafting_doc_id, staff_id, is_read, read_at)
  SELECT unnest(p_doc_ids), p_staff_id, TRUE, NOW()
  ON CONFLICT (drafting_doc_id, staff_id)
  DO UPDATE SET is_read = TRUE, read_at = COALESCE(edoc.user_drafting_docs.read_at, NOW());

  RETURN QUERY SELECT TRUE, 'Đã đánh dấu đọc thành công'::TEXT;
END;
$$;

-- ==========================================
-- A.9 Duyệt văn bản dự thảo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_approve(
  p_id        BIGINT,
  p_staff_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_staff_name VARCHAR;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.drafting_docs WHERE edoc.drafting_docs.id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản dự thảo'::TEXT;
    RETURN;
  END IF;

  IF (SELECT is_released FROM edoc.drafting_docs WHERE edoc.drafting_docs.id = p_id) = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Văn bản đã phát hành, không cần duyệt'::TEXT;
    RETURN;
  END IF;

  SELECT full_name INTO v_staff_name FROM public.staff WHERE public.staff.id = p_staff_id;

  UPDATE edoc.drafting_docs SET
    approved = TRUE,
    approver = v_staff_name,
    updated_by = p_staff_id,
    updated_at = NOW()
  WHERE edoc.drafting_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Duyệt văn bản dự thảo thành công'::TEXT;
END;
$$;

-- ==========================================
-- A.10 Hủy duyệt văn bản dự thảo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_unapprove(
  p_id        BIGINT,
  p_staff_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.drafting_docs WHERE edoc.drafting_docs.id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản dự thảo'::TEXT;
    RETURN;
  END IF;

  IF (SELECT is_released FROM edoc.drafting_docs WHERE edoc.drafting_docs.id = p_id) = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Không thể hủy duyệt: văn bản đã phát hành'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.drafting_docs SET
    approved = FALSE,
    approver = NULL,
    updated_by = p_staff_id,
    updated_at = NOW()
  WHERE edoc.drafting_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Hủy duyệt thành công'::TEXT;
END;
$$;

-- ==========================================
-- A.11 Từ chối văn bản dự thảo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_reject(
  p_id        BIGINT,
  p_staff_id  INT,
  p_reason    TEXT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_staff_name VARCHAR;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.drafting_docs WHERE edoc.drafting_docs.id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản dự thảo'::TEXT;
    RETURN;
  END IF;

  IF (SELECT is_released FROM edoc.drafting_docs WHERE edoc.drafting_docs.id = p_id) = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Không thể từ chối: văn bản đã phát hành'::TEXT;
    RETURN;
  END IF;

  SELECT full_name INTO v_staff_name FROM public.staff WHERE public.staff.id = p_staff_id;

  UPDATE edoc.drafting_docs SET
    approved = FALSE,
    approver = NULL,
    updated_by = p_staff_id,
    updated_at = NOW()
  WHERE edoc.drafting_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Đã từ chối văn bản dự thảo'::TEXT;
END;
$$;

-- ==========================================
-- A.12 Phát hành dự thảo → Tạo VB đi
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_release(
  p_id          BIGINT,
  p_released_by INT
)
RETURNS TABLE (success BOOLEAN, message TEXT, outgoing_doc_id BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE
  v_draft   edoc.drafting_docs%ROWTYPE;
  v_out_id  BIGINT;
BEGIN
  SELECT * INTO v_draft FROM edoc.drafting_docs WHERE edoc.drafting_docs.id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản dự thảo'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  IF v_draft.approved IS NULL OR v_draft.approved = FALSE THEN
    RETURN QUERY SELECT FALSE, 'Văn bản chưa được duyệt, không thể phát hành'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  IF v_draft.is_released = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Văn bản đã được phát hành trước đó'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  -- Tạo VB đi từ dự thảo
  INSERT INTO edoc.outgoing_docs (
    unit_id, received_date, number, sub_number, notation, document_code,
    abstract, drafting_unit_id, drafting_user_id, publish_unit_id, publish_date,
    signer, sign_date, expired_date,
    number_paper, number_copies, secret_id, urgent_id,
    recipients, doc_book_id, doc_type_id, doc_field_id,
    approved, approver, created_by, updated_by
  ) VALUES (
    v_draft.unit_id, v_draft.received_date, v_draft.number, v_draft.sub_number,
    v_draft.notation, v_draft.document_code, v_draft.abstract,
    v_draft.drafting_unit_id, v_draft.drafting_user_id, v_draft.publish_unit_id, v_draft.publish_date,
    v_draft.signer, v_draft.sign_date, v_draft.expired_date,
    v_draft.number_paper, v_draft.number_copies, v_draft.secret_id, v_draft.urgent_id,
    v_draft.recipients, v_draft.doc_book_id, v_draft.doc_type_id, v_draft.doc_field_id,
    TRUE, v_draft.approver, p_released_by, p_released_by
  )
  RETURNING edoc.outgoing_docs.id INTO v_out_id;

  -- Copy đính kèm từ dự thảo sang VB đi
  INSERT INTO edoc.attachment_outgoing_docs (outgoing_doc_id, file_name, file_path, file_size, content_type, sort_order, created_by)
  SELECT v_out_id, file_name, file_path, file_size, content_type, sort_order, created_by
  FROM edoc.attachment_drafting_docs
  WHERE drafting_doc_id = p_id;

  -- Đánh dấu dự thảo đã phát hành
  UPDATE edoc.drafting_docs SET
    is_released = TRUE,
    released_date = NOW(),
    updated_by = p_released_by,
    updated_at = NOW()
  WHERE edoc.drafting_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Phát hành thành công, đã tạo văn bản đi'::TEXT, v_out_id;
END;
$$;

-- ==========================================
-- A.13 File đính kèm dự thảo — Danh sách
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_attachment_drafting_get_list(
  p_doc_id BIGINT
)
RETURNS TABLE (
  id            BIGINT,
  file_name     VARCHAR,
  file_path     VARCHAR,
  file_size     BIGINT,
  content_type  VARCHAR,
  sort_order    INT,
  created_by    INT,
  created_at    TIMESTAMPTZ,
  created_by_name VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT a.id, a.file_name, a.file_path, a.file_size, a.content_type,
         a.sort_order, a.created_by, a.created_at, s.full_name
  FROM edoc.attachment_drafting_docs a
  LEFT JOIN public.staff s ON s.id = a.created_by
  WHERE a.drafting_doc_id = p_doc_id
  ORDER BY a.sort_order, a.created_at;
END;
$$;

-- ==========================================
-- A.14 File đính kèm dự thảo — Tạo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_attachment_drafting_create(
  p_doc_id       BIGINT,
  p_file_name    VARCHAR,
  p_file_path    VARCHAR,
  p_file_size    BIGINT,
  p_content_type VARCHAR,
  p_created_by   INT
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE v_id BIGINT;
BEGIN
  IF p_file_name IS NULL OR TRIM(p_file_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên file không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.attachment_drafting_docs (drafting_doc_id, file_name, file_path, file_size, content_type, created_by)
  VALUES (p_doc_id, p_file_name, p_file_path, COALESCE(p_file_size, 0), p_content_type, p_created_by)
  RETURNING edoc.attachment_drafting_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tải lên thành công'::TEXT, v_id;
END;
$$;

-- ==========================================
-- A.15 File đính kèm dự thảo — Xóa
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_attachment_drafting_delete(
  p_id BIGINT
)
RETURNS TABLE (success BOOLEAN, message TEXT, file_path VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE v_path VARCHAR;
BEGIN
  SELECT a.file_path INTO v_path FROM edoc.attachment_drafting_docs a WHERE a.id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy file đính kèm'::TEXT, ''::VARCHAR;
    RETURN;
  END IF;

  DELETE FROM edoc.attachment_drafting_docs WHERE edoc.attachment_drafting_docs.id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa file thành công'::TEXT, v_path;
END;
$$;

-- ==========================================
-- A.16 Lịch sử xử lý dự thảo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_get_history(
  p_doc_id BIGINT
)
RETURNS TABLE (
  event_type  VARCHAR,
  event_time  TIMESTAMPTZ,
  staff_name  VARCHAR,
  content     TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM (
    -- Tạo
    SELECT 'created'::VARCHAR AS evt, d.created_at AS etime, s.full_name AS sname,
           ('Tạo văn bản dự thảo, số: ' || d.number)::TEXT AS econtent
    FROM edoc.drafting_docs d
    JOIN public.staff s ON s.id = d.created_by
    WHERE d.id = p_doc_id

    UNION ALL
    -- Duyệt
    SELECT 'approved'::VARCHAR, d.updated_at, d.approver::VARCHAR, 'Duyệt văn bản dự thảo'::TEXT
    FROM edoc.drafting_docs d
    WHERE d.id = p_doc_id AND d.approved = TRUE

    UNION ALL
    -- Phát hành
    SELECT 'released'::VARCHAR, d.released_date, s.full_name, 'Phát hành thành văn bản đi'::TEXT
    FROM edoc.drafting_docs d
    JOIN public.staff s ON s.id = d.updated_by
    WHERE d.id = p_doc_id AND d.is_released = TRUE

    UNION ALL
    -- Gửi
    SELECT 'sent'::VARCHAR, ud.created_at, s.full_name, 'Nhận văn bản'::TEXT
    FROM edoc.user_drafting_docs ud
    JOIN public.staff s ON s.id = ud.staff_id
    WHERE ud.drafting_doc_id = p_doc_id
  ) sub
  ORDER BY sub.etime DESC;
END;
$$;

-- ==========================================
-- A.17 Gửi VB dự thảo cho cán bộ
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_send(
  p_doc_id    BIGINT,
  p_staff_ids INT[],
  p_sent_by   INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
  v_approved BOOLEAN;
  v_count INT;
BEGIN
  SELECT approved INTO v_approved FROM edoc.drafting_docs WHERE edoc.drafting_docs.id = p_doc_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản dự thảo'::TEXT;
    RETURN;
  END IF;
  IF v_approved IS NULL OR v_approved = FALSE THEN
    RETURN QUERY SELECT FALSE, 'Văn bản chưa được duyệt, không thể gửi'::TEXT;
    RETURN;
  END IF;

  IF p_staff_ids IS NULL OR array_length(p_staff_ids, 1) IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Vui lòng chọn ít nhất một người nhận'::TEXT;
    RETURN;
  END IF;

  INSERT INTO edoc.user_drafting_docs (drafting_doc_id, staff_id, is_read, created_at)
  SELECT p_doc_id, unnest(p_staff_ids), FALSE, NOW()
  ON CONFLICT (drafting_doc_id, staff_id) DO NOTHING;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN QUERY SELECT TRUE, ('Đã gửi cho ' || v_count || ' người nhận')::TEXT;
END;
$$;

-- ==========================================
-- A.18 Danh sách người nhận dự thảo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_get_recipients(
  p_doc_id BIGINT
)
RETURNS TABLE (
  id          BIGINT,
  staff_id    INT,
  staff_name  VARCHAR,
  position_name VARCHAR,
  department_name VARCHAR,
  is_read     BOOLEAN,
  read_at     TIMESTAMPTZ,
  created_at  TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    ud.id, ud.staff_id,
    s.full_name,
    p.name AS position_name,
    dep.name AS department_name,
    ud.is_read, ud.read_at, ud.created_at
  FROM edoc.user_drafting_docs ud
  JOIN public.staff s ON s.id = ud.staff_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  LEFT JOIN public.departments dep ON dep.id = s.department_id
  WHERE ud.drafting_doc_id = p_doc_id
  ORDER BY ud.created_at DESC;
END;
$$;


-- ================================================================
-- PHẦN B: VĂN BẢN ĐI (OUTGOING DOCS)
-- ================================================================

-- ==========================================
-- B.1 Lấy số tiếp theo — VB đi
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_get_next_number(
  p_doc_book_id INT,
  p_unit_id     INT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE v_max INT;
BEGIN
  SELECT COALESCE(MAX(number), 0) INTO v_max
  FROM edoc.outgoing_docs
  WHERE doc_book_id = p_doc_book_id
    AND unit_id = p_unit_id
    AND EXTRACT(YEAR FROM received_date) = EXTRACT(YEAR FROM NOW());
  RETURN v_max + 1;
END;
$$;

-- ==========================================
-- B.2 Tạo VB đi
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_create(
  p_unit_id           INT,
  p_received_date     TIMESTAMPTZ,
  p_number            INT,
  p_sub_number        VARCHAR,
  p_notation          VARCHAR,
  p_document_code     VARCHAR,
  p_abstract          TEXT,
  p_drafting_unit_id  INT        DEFAULT NULL,
  p_drafting_user_id  INT        DEFAULT NULL,
  p_publish_unit_id   INT        DEFAULT NULL,
  p_publish_date      TIMESTAMPTZ DEFAULT NULL,
  p_signer            VARCHAR    DEFAULT NULL,
  p_sign_date         TIMESTAMPTZ DEFAULT NULL,
  p_doc_book_id       INT        DEFAULT NULL,
  p_doc_type_id       INT        DEFAULT NULL,
  p_doc_field_id      INT        DEFAULT NULL,
  p_secret_id         SMALLINT   DEFAULT 1,
  p_urgent_id         SMALLINT   DEFAULT 1,
  p_number_paper      INT        DEFAULT 1,
  p_number_copies     INT        DEFAULT 1,
  p_expired_date      TIMESTAMPTZ DEFAULT NULL,
  p_recipients        TEXT       DEFAULT NULL,
  p_created_by        INT        DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE v_id BIGINT;
BEGIN
  IF p_abstract IS NULL OR TRIM(p_abstract) = '' THEN
    RETURN QUERY SELECT FALSE, 'Trích yếu nội dung không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  IF p_doc_book_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Sổ văn bản là bắt buộc'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  IF p_number IS NULL OR p_number = 0 THEN
    p_number := edoc.fn_outgoing_doc_get_next_number(p_doc_book_id, p_unit_id);
  END IF;

  INSERT INTO edoc.outgoing_docs (
    unit_id, received_date, number, sub_number, notation, document_code,
    abstract, drafting_unit_id, drafting_user_id, publish_unit_id, publish_date,
    signer, sign_date, expired_date,
    number_paper, number_copies, secret_id, urgent_id,
    recipients, doc_book_id, doc_type_id, doc_field_id,
    created_by, updated_by
  ) VALUES (
    p_unit_id, COALESCE(p_received_date, NOW()), p_number,
    NULLIF(TRIM(p_sub_number), ''), NULLIF(TRIM(p_notation), ''), NULLIF(TRIM(p_document_code), ''),
    TRIM(p_abstract), p_drafting_unit_id, p_drafting_user_id, p_publish_unit_id, p_publish_date,
    NULLIF(TRIM(p_signer), ''), p_sign_date, p_expired_date,
    COALESCE(p_number_paper, 1), COALESCE(p_number_copies, 1),
    COALESCE(p_secret_id, 1), COALESCE(p_urgent_id, 1),
    NULLIF(TRIM(p_recipients), ''), p_doc_book_id, p_doc_type_id, p_doc_field_id,
    p_created_by, p_created_by
  )
  RETURNING edoc.outgoing_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tạo văn bản đi thành công'::TEXT, v_id;
END;
$$;

-- ==========================================
-- B.3 Cập nhật VB đi
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_update(
  p_id                BIGINT,
  p_received_date     TIMESTAMPTZ,
  p_number            INT,
  p_sub_number        VARCHAR,
  p_notation          VARCHAR,
  p_document_code     VARCHAR,
  p_abstract          TEXT,
  p_drafting_unit_id  INT        DEFAULT NULL,
  p_drafting_user_id  INT        DEFAULT NULL,
  p_publish_unit_id   INT        DEFAULT NULL,
  p_publish_date      TIMESTAMPTZ DEFAULT NULL,
  p_signer            VARCHAR    DEFAULT NULL,
  p_sign_date         TIMESTAMPTZ DEFAULT NULL,
  p_doc_book_id       INT        DEFAULT NULL,
  p_doc_type_id       INT        DEFAULT NULL,
  p_doc_field_id      INT        DEFAULT NULL,
  p_secret_id         SMALLINT   DEFAULT 1,
  p_urgent_id         SMALLINT   DEFAULT 1,
  p_number_paper      INT        DEFAULT 1,
  p_number_copies     INT        DEFAULT 1,
  p_expired_date      TIMESTAMPTZ DEFAULT NULL,
  p_recipients        TEXT       DEFAULT NULL,
  p_updated_by        INT        DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_approved BOOLEAN;
BEGIN
  SELECT approved INTO v_approved FROM edoc.outgoing_docs WHERE edoc.outgoing_docs.id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đi'::TEXT;
    RETURN;
  END IF;
  IF v_approved = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Không thể sửa văn bản đã được duyệt'::TEXT;
    RETURN;
  END IF;

  IF p_abstract IS NULL OR TRIM(p_abstract) = '' THEN
    RETURN QUERY SELECT FALSE, 'Trích yếu nội dung không được để trống'::TEXT;
    RETURN;
  END IF;
  IF p_doc_book_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Sổ văn bản là bắt buộc'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.outgoing_docs SET
    received_date     = COALESCE(p_received_date, received_date),
    number            = COALESCE(p_number, number),
    sub_number        = NULLIF(TRIM(p_sub_number), ''),
    notation          = NULLIF(TRIM(p_notation), ''),
    document_code     = NULLIF(TRIM(p_document_code), ''),
    abstract          = TRIM(p_abstract),
    drafting_unit_id  = p_drafting_unit_id,
    drafting_user_id  = p_drafting_user_id,
    publish_unit_id   = p_publish_unit_id,
    publish_date      = p_publish_date,
    signer            = NULLIF(TRIM(p_signer), ''),
    sign_date         = p_sign_date,
    doc_book_id       = p_doc_book_id,
    doc_type_id       = p_doc_type_id,
    doc_field_id      = p_doc_field_id,
    secret_id         = COALESCE(p_secret_id, 1),
    urgent_id         = COALESCE(p_urgent_id, 1),
    number_paper      = COALESCE(p_number_paper, 1),
    number_copies     = COALESCE(p_number_copies, 1),
    expired_date      = p_expired_date,
    recipients        = NULLIF(TRIM(p_recipients), ''),
    updated_by        = p_updated_by,
    updated_at        = NOW()
  WHERE edoc.outgoing_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Cập nhật văn bản đi thành công'::TEXT;
END;
$$;

-- ==========================================
-- B.4 Xóa VB đi
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_delete(
  p_id BIGINT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_approved BOOLEAN;
BEGIN
  SELECT approved INTO v_approved FROM edoc.outgoing_docs WHERE edoc.outgoing_docs.id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đi'::TEXT;
    RETURN;
  END IF;
  IF v_approved = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Không thể xóa văn bản đã được duyệt'::TEXT;
    RETURN;
  END IF;

  DELETE FROM edoc.outgoing_docs WHERE edoc.outgoing_docs.id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa văn bản đi thành công'::TEXT;
END;
$$;

-- ==========================================
-- B.5 Danh sách VB đi (phân trang)
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_get_list(
  p_unit_id       INT,
  p_staff_id      INT,
  p_doc_book_id   INT       DEFAULT NULL,
  p_doc_type_id   INT       DEFAULT NULL,
  p_doc_field_id  INT       DEFAULT NULL,
  p_urgent_id     SMALLINT  DEFAULT NULL,
  p_approved      BOOLEAN   DEFAULT NULL,
  p_from_date     TIMESTAMPTZ DEFAULT NULL,
  p_to_date       TIMESTAMPTZ DEFAULT NULL,
  p_keyword       TEXT      DEFAULT NULL,
  p_page          INT       DEFAULT 1,
  p_page_size     INT       DEFAULT 20
)
RETURNS TABLE (
  id              BIGINT,
  unit_id         INT,
  received_date   TIMESTAMPTZ,
  number          INT,
  sub_number      VARCHAR,
  notation        VARCHAR,
  document_code   VARCHAR,
  abstract        TEXT,
  drafting_unit_id  INT,
  drafting_user_id  INT,
  publish_unit_id   INT,
  publish_date    TIMESTAMPTZ,
  signer          VARCHAR,
  sign_date       TIMESTAMPTZ,
  expired_date    TIMESTAMPTZ,
  doc_book_id     INT,
  doc_type_id     INT,
  doc_field_id    INT,
  secret_id       SMALLINT,
  urgent_id       SMALLINT,
  number_paper    INT,
  number_copies   INT,
  recipients      TEXT,
  approver        VARCHAR,
  approved        BOOLEAN,
  is_handling     BOOLEAN,
  archive_status  BOOLEAN,
  created_by      INT,
  created_at      TIMESTAMPTZ,
  -- Joined
  doc_book_name   VARCHAR,
  doc_type_name   VARCHAR,
  doc_type_code   VARCHAR,
  doc_field_name  VARCHAR,
  drafting_unit_name VARCHAR,
  drafting_user_name VARCHAR,
  created_by_name VARCHAR,
  -- Read status
  is_read         BOOLEAN,
  read_at         TIMESTAMPTZ,
  -- Attachment count
  attachment_count BIGINT,
  -- Pagination
  total_count     BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_offset INT;
  v_keyword TEXT;
BEGIN
  v_offset := (GREATEST(p_page, 1) - 1) * p_page_size;
  v_keyword := NULLIF(TRIM(p_keyword), '');

  RETURN QUERY
  WITH filtered AS (
    SELECT
      d.id AS doc_id,
      d.*,
      db.name AS _doc_book_name,
      dt.name AS _doc_type_name,
      dt.code AS _doc_type_code,
      df.name AS _doc_field_name,
      du.name AS _drafting_unit_name,
      ds.full_name AS _drafting_user_name,
      s.full_name AS _created_by_name,
      uo.is_read AS _is_read,
      uo.read_at AS _read_at,
      (SELECT COUNT(*) FROM edoc.attachment_outgoing_docs a WHERE a.outgoing_doc_id = d.id) AS _attachment_count,
      COUNT(*) OVER() AS _total_count
    FROM edoc.outgoing_docs d
    LEFT JOIN edoc.doc_books db ON db.id = d.doc_book_id
    LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
    LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id
    LEFT JOIN public.departments du ON du.id = d.drafting_unit_id
    LEFT JOIN public.staff ds ON ds.id = d.drafting_user_id
    LEFT JOIN public.staff s ON s.id = d.created_by
    LEFT JOIN edoc.user_outgoing_docs uo ON uo.outgoing_doc_id = d.id AND uo.staff_id = p_staff_id
    WHERE d.unit_id = p_unit_id
      AND (p_doc_book_id IS NULL OR d.doc_book_id = p_doc_book_id)
      AND (p_doc_type_id IS NULL OR d.doc_type_id = p_doc_type_id)
      AND (p_doc_field_id IS NULL OR d.doc_field_id = p_doc_field_id)
      AND (p_urgent_id IS NULL OR d.urgent_id = p_urgent_id)
      AND (p_approved IS NULL OR d.approved = p_approved)
      AND (p_from_date IS NULL OR d.received_date >= p_from_date)
      AND (p_to_date IS NULL OR d.received_date <= p_to_date)
      AND (v_keyword IS NULL OR
           d.abstract ILIKE '%' || v_keyword || '%' OR
           d.notation ILIKE '%' || v_keyword || '%' OR
           d.signer ILIKE '%' || v_keyword || '%' OR
           d.recipients ILIKE '%' || v_keyword || '%'
      )
    ORDER BY d.received_date DESC, d.number DESC
    LIMIT p_page_size OFFSET v_offset
  )
  SELECT
    f.doc_id, f.unit_id, f.received_date, f.number, f.sub_number,
    f.notation, f.document_code, f.abstract,
    f.drafting_unit_id, f.drafting_user_id, f.publish_unit_id, f.publish_date,
    f.signer, f.sign_date, f.expired_date,
    f.doc_book_id, f.doc_type_id, f.doc_field_id,
    f.secret_id, f.urgent_id, f.number_paper, f.number_copies,
    f.recipients, f.approver, f.approved,
    f.is_handling, f.archive_status, f.created_by, f.created_at,
    f._doc_book_name, f._doc_type_name, f._doc_type_code, f._doc_field_name,
    f._drafting_unit_name, f._drafting_user_name, f._created_by_name,
    COALESCE(f._is_read, FALSE), f._read_at,
    f._attachment_count, f._total_count
  FROM filtered f;
END;
$$;

-- ==========================================
-- B.6 Chi tiết VB đi
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_get_by_id(
  p_id        BIGINT,
  p_staff_id  INT
)
RETURNS TABLE (
  id              BIGINT,
  unit_id         INT,
  received_date   TIMESTAMPTZ,
  number          INT,
  sub_number      VARCHAR,
  notation        VARCHAR,
  document_code   VARCHAR,
  abstract        TEXT,
  drafting_unit_id  INT,
  drafting_user_id  INT,
  publish_unit_id   INT,
  publish_date    TIMESTAMPTZ,
  signer          VARCHAR,
  sign_date       TIMESTAMPTZ,
  expired_date    TIMESTAMPTZ,
  doc_book_id     INT,
  doc_type_id     INT,
  doc_field_id    INT,
  secret_id       SMALLINT,
  urgent_id       SMALLINT,
  number_paper    INT,
  number_copies   INT,
  recipients      TEXT,
  approver        VARCHAR,
  approved        BOOLEAN,
  is_handling     BOOLEAN,
  archive_status  BOOLEAN,
  is_inter_doc    BOOLEAN,
  is_digital_signed SMALLINT,
  created_by      INT,
  created_at      TIMESTAMPTZ,
  updated_by      INT,
  updated_at      TIMESTAMPTZ,
  -- Joined
  doc_book_name   VARCHAR,
  doc_type_name   VARCHAR,
  doc_type_code   VARCHAR,
  doc_field_name  VARCHAR,
  drafting_unit_name VARCHAR,
  drafting_user_name VARCHAR,
  created_by_name VARCHAR,
  is_read         BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
  -- Đánh dấu đã đọc
  INSERT INTO edoc.user_outgoing_docs (outgoing_doc_id, staff_id, is_read, read_at)
  VALUES (p_id, p_staff_id, TRUE, NOW())
  ON CONFLICT (outgoing_doc_id, staff_id)
  DO UPDATE SET is_read = TRUE, read_at = COALESCE(edoc.user_outgoing_docs.read_at, NOW());

  RETURN QUERY
  SELECT
    d.id, d.unit_id, d.received_date, d.number, d.sub_number,
    d.notation, d.document_code, d.abstract,
    d.drafting_unit_id, d.drafting_user_id, d.publish_unit_id, d.publish_date,
    d.signer, d.sign_date, d.expired_date,
    d.doc_book_id, d.doc_type_id, d.doc_field_id,
    d.secret_id, d.urgent_id, d.number_paper, d.number_copies,
    d.recipients, d.approver, d.approved,
    d.is_handling, d.archive_status, d.is_inter_doc, d.is_digital_signed,
    d.created_by, d.created_at, d.updated_by, d.updated_at,
    db.name, dt.name, dt.code, df.name,
    du.name, ds.full_name, s.full_name,
    TRUE
  FROM edoc.outgoing_docs d
  LEFT JOIN edoc.doc_books db ON db.id = d.doc_book_id
  LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
  LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id
  LEFT JOIN public.departments du ON du.id = d.drafting_unit_id
  LEFT JOIN public.staff ds ON ds.id = d.drafting_user_id
  LEFT JOIN public.staff s ON s.id = d.created_by
  WHERE d.id = p_id;
END;
$$;

-- ==========================================
-- B.7 Đếm chưa đọc — VB đi
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_count_unread(
  p_unit_id   INT,
  p_staff_id  INT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE v_count INT;
BEGIN
  SELECT COUNT(*)::INT INTO v_count
  FROM edoc.outgoing_docs d
  LEFT JOIN edoc.user_outgoing_docs uo ON uo.outgoing_doc_id = d.id AND uo.staff_id = p_staff_id
  WHERE d.unit_id = p_unit_id
    AND (uo.is_read IS NULL OR uo.is_read = FALSE);
  RETURN v_count;
END;
$$;

-- ==========================================
-- B.8 Đánh dấu đã đọc hàng loạt — VB đi
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_mark_read_bulk(
  p_doc_ids   BIGINT[],
  p_staff_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO edoc.user_outgoing_docs (outgoing_doc_id, staff_id, is_read, read_at)
  SELECT unnest(p_doc_ids), p_staff_id, TRUE, NOW()
  ON CONFLICT (outgoing_doc_id, staff_id)
  DO UPDATE SET is_read = TRUE, read_at = COALESCE(edoc.user_outgoing_docs.read_at, NOW());

  RETURN QUERY SELECT TRUE, 'Đã đánh dấu đọc thành công'::TEXT;
END;
$$;

-- ==========================================
-- B.9 Duyệt VB đi
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_approve(
  p_id        BIGINT,
  p_staff_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_staff_name VARCHAR;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.outgoing_docs WHERE edoc.outgoing_docs.id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đi'::TEXT;
    RETURN;
  END IF;

  SELECT full_name INTO v_staff_name FROM public.staff WHERE public.staff.id = p_staff_id;

  UPDATE edoc.outgoing_docs SET
    approved = TRUE,
    approver = v_staff_name,
    updated_by = p_staff_id,
    updated_at = NOW()
  WHERE edoc.outgoing_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Duyệt văn bản đi thành công'::TEXT;
END;
$$;

-- ==========================================
-- B.10 Hủy duyệt VB đi
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_unapprove(
  p_id        BIGINT,
  p_staff_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_has_sent BOOLEAN;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.outgoing_docs WHERE edoc.outgoing_docs.id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đi'::TEXT;
    RETURN;
  END IF;

  SELECT EXISTS(SELECT 1 FROM edoc.user_outgoing_docs WHERE outgoing_doc_id = p_id) INTO v_has_sent;
  IF v_has_sent THEN
    RETURN QUERY SELECT FALSE, 'Không thể hủy duyệt: văn bản đã được gửi cho cán bộ'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.outgoing_docs SET
    approved = FALSE,
    approver = NULL,
    updated_by = p_staff_id,
    updated_at = NOW()
  WHERE edoc.outgoing_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Hủy duyệt thành công'::TEXT;
END;
$$;

-- ==========================================
-- B.11 Gửi VB đi cho cán bộ
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_send(
  p_doc_id    BIGINT,
  p_staff_ids INT[],
  p_sent_by   INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
  v_approved BOOLEAN;
  v_count INT;
BEGIN
  SELECT approved INTO v_approved FROM edoc.outgoing_docs WHERE edoc.outgoing_docs.id = p_doc_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đi'::TEXT;
    RETURN;
  END IF;
  IF v_approved IS NULL OR v_approved = FALSE THEN
    RETURN QUERY SELECT FALSE, 'Văn bản chưa được duyệt, không thể gửi'::TEXT;
    RETURN;
  END IF;

  IF p_staff_ids IS NULL OR array_length(p_staff_ids, 1) IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Vui lòng chọn ít nhất một người nhận'::TEXT;
    RETURN;
  END IF;

  INSERT INTO edoc.user_outgoing_docs (outgoing_doc_id, staff_id, is_read, created_at)
  SELECT p_doc_id, unnest(p_staff_ids), FALSE, NOW()
  ON CONFLICT (outgoing_doc_id, staff_id) DO NOTHING;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN QUERY SELECT TRUE, ('Đã gửi cho ' || v_count || ' người nhận')::TEXT;
END;
$$;

-- ==========================================
-- B.12 Danh sách người nhận VB đi
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_get_recipients(
  p_doc_id BIGINT
)
RETURNS TABLE (
  id          BIGINT,
  staff_id    INT,
  staff_name  VARCHAR,
  position_name VARCHAR,
  department_name VARCHAR,
  is_read     BOOLEAN,
  read_at     TIMESTAMPTZ,
  created_at  TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    uo.id, uo.staff_id,
    s.full_name,
    p.name AS position_name,
    dep.name AS department_name,
    uo.is_read, uo.read_at, uo.created_at
  FROM edoc.user_outgoing_docs uo
  JOIN public.staff s ON s.id = uo.staff_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  LEFT JOIN public.departments dep ON dep.id = s.department_id
  WHERE uo.outgoing_doc_id = p_doc_id
  ORDER BY uo.created_at DESC;
END;
$$;

-- ==========================================
-- B.13 File đính kèm VB đi — Danh sách
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_attachment_outgoing_get_list(
  p_doc_id BIGINT
)
RETURNS TABLE (
  id            BIGINT,
  file_name     VARCHAR,
  file_path     VARCHAR,
  file_size     BIGINT,
  content_type  VARCHAR,
  sort_order    INT,
  created_by    INT,
  created_at    TIMESTAMPTZ,
  created_by_name VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT a.id, a.file_name, a.file_path, a.file_size, a.content_type,
         a.sort_order, a.created_by, a.created_at, s.full_name
  FROM edoc.attachment_outgoing_docs a
  LEFT JOIN public.staff s ON s.id = a.created_by
  WHERE a.outgoing_doc_id = p_doc_id
  ORDER BY a.sort_order, a.created_at;
END;
$$;

-- ==========================================
-- B.14 File đính kèm VB đi — Tạo
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_attachment_outgoing_create(
  p_doc_id       BIGINT,
  p_file_name    VARCHAR,
  p_file_path    VARCHAR,
  p_file_size    BIGINT,
  p_content_type VARCHAR,
  p_created_by   INT
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE v_id BIGINT;
BEGIN
  IF p_file_name IS NULL OR TRIM(p_file_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên file không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.attachment_outgoing_docs (outgoing_doc_id, file_name, file_path, file_size, content_type, created_by)
  VALUES (p_doc_id, p_file_name, p_file_path, COALESCE(p_file_size, 0), p_content_type, p_created_by)
  RETURNING edoc.attachment_outgoing_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tải lên thành công'::TEXT, v_id;
END;
$$;

-- ==========================================
-- B.15 File đính kèm VB đi — Xóa
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_attachment_outgoing_delete(
  p_id BIGINT
)
RETURNS TABLE (success BOOLEAN, message TEXT, file_path VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE v_path VARCHAR;
BEGIN
  SELECT a.file_path INTO v_path FROM edoc.attachment_outgoing_docs a WHERE a.id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy file đính kèm'::TEXT, ''::VARCHAR;
    RETURN;
  END IF;

  DELETE FROM edoc.attachment_outgoing_docs WHERE edoc.attachment_outgoing_docs.id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa file thành công'::TEXT, v_path;
END;
$$;

-- ==========================================
-- B.16 Lịch sử xử lý VB đi
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_get_history(
  p_doc_id BIGINT
)
RETURNS TABLE (
  event_type  VARCHAR,
  event_time  TIMESTAMPTZ,
  staff_name  VARCHAR,
  content     TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM (
    -- Tạo
    SELECT 'created'::VARCHAR AS evt, d.created_at AS etime, s.full_name AS sname,
           ('Tạo văn bản đi, số: ' || d.number)::TEXT AS econtent
    FROM edoc.outgoing_docs d
    JOIN public.staff s ON s.id = d.created_by
    WHERE d.id = p_doc_id

    UNION ALL
    -- Duyệt
    SELECT 'approved'::VARCHAR, d.updated_at, d.approver::VARCHAR, 'Duyệt văn bản đi'::TEXT
    FROM edoc.outgoing_docs d
    WHERE d.id = p_doc_id AND d.approved = TRUE

    UNION ALL
    -- Gửi
    SELECT 'sent'::VARCHAR, uo.created_at, s.full_name, 'Nhận văn bản'::TEXT
    FROM edoc.user_outgoing_docs uo
    JOIN public.staff s ON s.id = uo.staff_id
    WHERE uo.outgoing_doc_id = p_doc_id
  ) sub
  ORDER BY sub.etime DESC;
END;
$$;


-- ================================================================
-- PHẦN C: HÀM DÙNG CHUNG — Bookmark cho outgoing/drafting
-- ================================================================

-- Cập nhật fn_staff_note_get_list để hỗ trợ outgoing + drafting
CREATE OR REPLACE FUNCTION edoc.fn_staff_note_get_list(
  p_staff_id  INT,
  p_doc_type  VARCHAR DEFAULT 'incoming'
)
RETURNS TABLE (
  note_id     BIGINT,
  doc_id      BIGINT,
  note        TEXT,
  created_at  TIMESTAMPTZ,
  doc_number      INT,
  doc_notation    VARCHAR,
  doc_abstract    TEXT,
  doc_received_date TIMESTAMPTZ,
  doc_publish_unit  VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
  IF p_doc_type = 'incoming' THEN
    RETURN QUERY
    SELECT sn.id, sn.doc_id, sn.note, sn.created_at,
           d.number, d.notation, d.abstract, d.received_date, d.publish_unit
    FROM edoc.staff_notes sn
    JOIN edoc.incoming_docs d ON d.id = sn.doc_id
    WHERE sn.staff_id = p_staff_id AND sn.doc_type = 'incoming'
    ORDER BY sn.created_at DESC;

  ELSIF p_doc_type = 'outgoing' THEN
    RETURN QUERY
    SELECT sn.id, sn.doc_id, sn.note, sn.created_at,
           d.number, d.notation, d.abstract, d.received_date,
           COALESCE(du.name, '')::VARCHAR
    FROM edoc.staff_notes sn
    JOIN edoc.outgoing_docs d ON d.id = sn.doc_id
    LEFT JOIN public.departments du ON du.id = d.drafting_unit_id
    WHERE sn.staff_id = p_staff_id AND sn.doc_type = 'outgoing'
    ORDER BY sn.created_at DESC;

  ELSIF p_doc_type = 'drafting' THEN
    RETURN QUERY
    SELECT sn.id, sn.doc_id, sn.note, sn.created_at,
           d.number, d.notation, d.abstract, d.received_date,
           COALESCE(du.name, '')::VARCHAR
    FROM edoc.staff_notes sn
    JOIN edoc.drafting_docs d ON d.id = sn.doc_id
    LEFT JOIN public.departments du ON du.id = d.drafting_unit_id
    WHERE sn.staff_id = p_staff_id AND sn.doc_type = 'drafting'
    ORDER BY sn.created_at DESC;
  END IF;
END;
$$;

-- ==========================================
-- FN: THU HỒI VĂN BẢN DỰ THẢO (Retract)
-- Xóa user_drafting_docs, reset approved=false
-- Chỉ thu hồi VB chưa phát hành
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_retract(
  p_id       BIGINT,
  p_staff_id INT
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_is_released BOOLEAN;
  v_deleted_count INT;
BEGIN
  SELECT d.is_released INTO v_is_released
  FROM edoc.drafting_docs d WHERE d.id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản dự thảo'::TEXT; RETURN;
  END IF;

  IF v_is_released THEN
    RETURN QUERY SELECT FALSE, 'Không thể thu hồi — văn bản đã phát hành'::TEXT; RETURN;
  END IF;

  DELETE FROM edoc.user_drafting_docs WHERE drafting_doc_id = p_id;
  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;

  UPDATE edoc.drafting_docs
  SET approved = FALSE, updated_by = p_staff_id, updated_at = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, ('Thu hồi thành công — đã xóa ' || v_deleted_count || ' người nhận')::TEXT;
END;
$$;

-- ==========================================
-- FN: THU HỒI VĂN BẢN ĐI (Retract)
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_retract(
  p_id BIGINT, p_staff_id INT
) RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_deleted_count INT;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.outgoing_docs WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đi'::TEXT; RETURN;
  END IF;
  DELETE FROM edoc.user_outgoing_docs WHERE outgoing_doc_id = p_id AND staff_id != p_staff_id;
  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  UPDATE edoc.outgoing_docs SET approved = FALSE, updated_by = p_staff_id, updated_at = NOW() WHERE id = p_id;
  RETURN QUERY SELECT TRUE, ('Thu hồi thành công — đã xóa ' || v_deleted_count || ' người nhận')::TEXT;
END; $$;

-- ==========================================
-- FN: TỪ CHỐI VĂN BẢN ĐI (Reject)
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_reject(
  p_id BIGINT, p_staff_id INT, p_reason TEXT DEFAULT NULL
) RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.outgoing_docs WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đi'::TEXT; RETURN;
  END IF;
  UPDATE edoc.outgoing_docs SET approved = FALSE, updated_by = p_staff_id, updated_at = NOW() WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Đã từ chối văn bản đi'::TEXT;
END; $$;

-- ================================================================
-- Source: 010_sprint5_handling_doc_sps.sql
-- ================================================================

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

-- ================================================================
-- Source: 011_sprint6_workflow_tables_sps.sql
-- ================================================================

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

-- ================================================================
-- Source: 012_sprint7_inter_incoming.sql
-- ================================================================

-- ================================================================
-- MIGRATION 012: Sprint 7 — Văn bản liên thông & Giao việc từ VB
-- Tables: edoc.inter_incoming_docs
-- Functions: 7 stored functions
-- ================================================================

-- ==========================================
-- 1. BẢNG VĂN BẢN LIÊN THÔNG (inter_incoming_docs)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.inter_incoming_docs (
  id                BIGSERIAL PRIMARY KEY,
  unit_id           INT NOT NULL REFERENCES public.departments(id),
  received_date     TIMESTAMP DEFAULT NOW(),
  notation          VARCHAR(100),
  document_code     VARCHAR(100),
  abstract          TEXT,
  publish_unit      VARCHAR(300),
  publish_date      DATE,
  signer            VARCHAR(200),
  sign_date         DATE,
  expired_date      DATE,
  doc_type_id       INT REFERENCES edoc.doc_types(id),
  status            VARCHAR(50) DEFAULT 'pending',
  source_system     VARCHAR(100),
  external_doc_id   VARCHAR(200),
  created_by        INT REFERENCES public.staff(id),
  created_at        TIMESTAMP DEFAULT NOW(),
  updated_at        TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_inter_incoming_unit_id ON edoc.inter_incoming_docs(unit_id);
CREATE INDEX IF NOT EXISTS idx_inter_incoming_received_date ON edoc.inter_incoming_docs(received_date DESC);
CREATE INDEX IF NOT EXISTS idx_inter_incoming_status ON edoc.inter_incoming_docs(status);

COMMENT ON TABLE edoc.inter_incoming_docs IS 'Văn bản đến liên thông — nhận từ hệ thống LGSP bên ngoài';

-- ==========================================
-- 2. FN: DANH SÁCH VB LIÊN THÔNG
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_inter_incoming_get_list(
  p_unit_id     INT,
  p_keyword     TEXT,
  p_status      TEXT,
  p_from_date   DATE,
  p_to_date     DATE,
  p_page        INT DEFAULT 1,
  p_page_size   INT DEFAULT 20
)
RETURNS TABLE (
  id              BIGINT,
  unit_id         INT,
  received_date   TIMESTAMP,
  notation        VARCHAR,
  document_code   VARCHAR,
  abstract        TEXT,
  publish_unit    VARCHAR,
  publish_date    DATE,
  signer          VARCHAR,
  sign_date       DATE,
  expired_date    DATE,
  doc_type_id     INT,
  status          VARCHAR,
  source_system   VARCHAR,
  external_doc_id VARCHAR,
  created_by      INT,
  created_at      TIMESTAMP,
  updated_at      TIMESTAMP,
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
      d.id,
      d.unit_id,
      d.received_date,
      d.notation,
      d.document_code,
      d.abstract,
      d.publish_unit,
      d.publish_date,
      d.signer,
      d.sign_date,
      d.expired_date,
      d.doc_type_id,
      d.status,
      d.source_system,
      d.external_doc_id,
      d.created_by,
      d.created_at,
      d.updated_at
    FROM edoc.inter_incoming_docs d
    WHERE
      d.unit_id = p_unit_id
      AND (p_status IS NULL OR p_status = '' OR d.status = p_status)
      AND (p_from_date IS NULL OR d.received_date::DATE >= p_from_date)
      AND (p_to_date IS NULL OR d.received_date::DATE <= p_to_date)
      AND (
        p_keyword IS NULL OR TRIM(p_keyword) = ''
        OR d.notation ILIKE '%' || p_keyword || '%'
        OR d.abstract ILIKE '%' || p_keyword || '%'
        OR d.publish_unit ILIKE '%' || p_keyword || '%'
      )
  )
  SELECT
    f.id,
    f.unit_id,
    f.received_date,
    f.notation,
    f.document_code,
    f.abstract,
    f.publish_unit,
    f.publish_date,
    f.signer,
    f.sign_date,
    f.expired_date,
    f.doc_type_id,
    f.status,
    f.source_system,
    f.external_doc_id,
    f.created_by,
    f.created_at,
    f.updated_at,
    COUNT(*) OVER()::BIGINT AS total_count
  FROM filtered f
  ORDER BY f.received_date DESC NULLS LAST
  LIMIT COALESCE(p_page_size, 20)
  OFFSET v_offset;
END;
$$;

-- ==========================================
-- 3. FN: CHI TIẾT VB LIÊN THÔNG
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_inter_incoming_get_by_id(
  p_id  BIGINT
)
RETURNS TABLE (
  id              BIGINT,
  unit_id         INT,
  received_date   TIMESTAMP,
  notation        VARCHAR,
  document_code   VARCHAR,
  abstract        TEXT,
  publish_unit    VARCHAR,
  publish_date    DATE,
  signer          VARCHAR,
  sign_date       DATE,
  expired_date    DATE,
  doc_type_id     INT,
  status          VARCHAR,
  source_system   VARCHAR,
  external_doc_id VARCHAR,
  created_by      INT,
  created_at      TIMESTAMP,
  updated_at      TIMESTAMP
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    d.id,
    d.unit_id,
    d.received_date,
    d.notation,
    d.document_code,
    d.abstract,
    d.publish_unit,
    d.publish_date,
    d.signer,
    d.sign_date,
    d.expired_date,
    d.doc_type_id,
    d.status,
    d.source_system,
    d.external_doc_id,
    d.created_by,
    d.created_at,
    d.updated_at
  FROM edoc.inter_incoming_docs d
  WHERE d.id = p_id;
END;
$$;

-- ==========================================
-- 4. FN: TẠO VB LIÊN THÔNG
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_inter_incoming_create(
  p_unit_id         INT,
  p_notation        VARCHAR,
  p_document_code   VARCHAR,
  p_abstract        TEXT,
  p_publish_unit    VARCHAR,
  p_publish_date    DATE,
  p_signer          VARCHAR,
  p_sign_date       DATE,
  p_expired_date    DATE,
  p_doc_type_id     INT,
  p_source_system   VARCHAR,
  p_external_doc_id VARCHAR,
  p_created_by      INT
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
  -- Kiểm tra đơn vị tồn tại
  IF NOT EXISTS (SELECT 1 FROM public.departments WHERE id = p_unit_id) THEN
    RETURN QUERY SELECT FALSE, 'Đơn vị không tồn tại'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.inter_incoming_docs (
    unit_id, notation, document_code, abstract,
    publish_unit, publish_date, signer, sign_date,
    expired_date, doc_type_id, source_system, external_doc_id,
    created_by, created_at, updated_at
  ) VALUES (
    p_unit_id, p_notation, p_document_code, p_abstract,
    p_publish_unit, p_publish_date, p_signer, p_sign_date,
    p_expired_date, p_doc_type_id, p_source_system, p_external_doc_id,
    p_created_by, NOW(), NOW()
  )
  RETURNING inter_incoming_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tạo văn bản liên thông thành công'::TEXT, v_id;
END;
$$;

-- ==========================================
-- 5. FN: NHẬN BÀN GIAO VB LIÊN THÔNG (pending → received)
--    Tự động tạo VB đến (incoming_docs) từ thông tin VB liên thông
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_inter_incoming_receive(
  p_id       BIGINT,
  p_staff_id INT
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_inter       edoc.inter_incoming_docs%ROWTYPE;
  v_unit_id     INT;
  v_incoming_id BIGINT;
  v_next_number INT;
BEGIN
  -- Lấy thông tin VB liên thông
  SELECT * INTO v_inter FROM edoc.inter_incoming_docs WHERE id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản liên thông'::TEXT; RETURN;
  END IF;
  IF v_inter.status != 'pending' THEN
    RETURN QUERY SELECT FALSE, ('Không thể nhận bàn giao — trạng thái hiện tại: ' || v_inter.status)::TEXT; RETURN;
  END IF;

  -- Lấy unit_id từ staff
  SELECT s.unit_id INTO v_unit_id FROM public.staff s WHERE s.id = p_staff_id;
  IF v_unit_id IS NULL THEN v_unit_id := v_inter.unit_id; END IF;

  -- Tính số đến tiếp theo
  SELECT COALESCE(MAX(number), 0) + 1 INTO v_next_number
  FROM edoc.incoming_docs WHERE unit_id = v_unit_id;

  -- Tạo VB đến từ VB liên thông
  INSERT INTO edoc.incoming_docs (
    unit_id, received_date, number, notation, document_code,
    abstract, publish_unit, publish_date, signer, sign_date,
    doc_type_id, expired_date, secret_id, urgent_id,
    is_inter_doc, inter_doc_id,
    approved, is_handling, is_received_paper, archive_status,
    created_by, created_at
  ) VALUES (
    v_unit_id, NOW(), v_next_number, v_inter.notation, v_inter.document_code,
    v_inter.abstract, v_inter.publish_unit, v_inter.publish_date, v_inter.signer, v_inter.sign_date,
    v_inter.doc_type_id, v_inter.expired_date, 1, 1,
    TRUE, p_id::INT,
    FALSE, FALSE, FALSE, FALSE,
    p_staff_id, NOW()
  ) RETURNING id INTO v_incoming_id;

  -- Phân phối VB đến cho người nhận bàn giao
  INSERT INTO edoc.user_incoming_docs (incoming_doc_id, staff_id, is_read, created_at)
  VALUES (v_incoming_id, p_staff_id, FALSE, NOW());

  -- Cập nhật trạng thái VB liên thông
  UPDATE edoc.inter_incoming_docs SET status = 'received', updated_at = NOW() WHERE id = p_id;

  RETURN QUERY SELECT TRUE, ('Nhận bàn giao thành công — đã tạo văn bản đến số ' || v_next_number)::TEXT;
END;
$$;

-- ==========================================
-- 6. FN: CHUYỂN LẠI / TỪ CHỐI VB LIÊN THÔNG (pending → returned)
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_inter_incoming_return(
  p_id       BIGINT,
  p_staff_id INT,
  p_reason   TEXT DEFAULT NULL
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_status VARCHAR;
BEGIN
  SELECT status INTO v_status FROM edoc.inter_incoming_docs WHERE id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản liên thông'::TEXT; RETURN;
  END IF;
  IF v_status != 'pending' THEN
    RETURN QUERY SELECT FALSE, ('Không thể chuyển lại — trạng thái hiện tại: ' || v_status)::TEXT; RETURN;
  END IF;
  UPDATE edoc.inter_incoming_docs SET status = 'returned', updated_at = NOW() WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Chuyển lại văn bản thành công'::TEXT;
END;
$$;

-- ==========================================
-- 7. FN: HOÀN THÀNH XỬ LÝ VB LIÊN THÔNG (received → completed)
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_inter_incoming_complete(
  p_id       BIGINT,
  p_staff_id INT
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_status VARCHAR;
BEGIN
  SELECT status INTO v_status FROM edoc.inter_incoming_docs WHERE id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản liên thông'::TEXT; RETURN;
  END IF;
  IF v_status != 'received' THEN
    RETURN QUERY SELECT FALSE, ('Không thể hoàn thành — trạng thái hiện tại: ' || v_status)::TEXT; RETURN;
  END IF;
  UPDATE edoc.inter_incoming_docs SET status = 'completed', updated_at = NOW() WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Hoàn thành xử lý văn bản liên thông'::TEXT;
END;
$$;

-- ==========================================
-- 8. FN: TẠO HSCV TỪ VĂN BẢN ĐẾN (giao việc)
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_create_from_doc(
  p_doc_id        BIGINT,
  p_doc_type      VARCHAR,
  p_name          TEXT,
  p_start_date    DATE,
  p_end_date      DATE,
  p_curator_ids   INT[],
  p_note          TEXT,
  p_created_by    INT
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
  v_id      BIGINT;
  v_unit_id INT;
  v_curator_id INT;
  v_cid     INT;
BEGIN
  -- Lấy unit_id từ văn bản gốc
  IF p_doc_type = 'incoming' THEN
    SELECT ind.unit_id INTO v_unit_id FROM edoc.incoming_docs ind WHERE ind.id = p_doc_id;
  ELSIF p_doc_type = 'outgoing' THEN
    SELECT od.unit_id INTO v_unit_id FROM edoc.outgoing_docs od WHERE od.id = p_doc_id;
  ELSIF p_doc_type = 'drafting' THEN
    SELECT dd.unit_id INTO v_unit_id FROM edoc.drafting_docs dd WHERE dd.id = p_doc_id;
  END IF;

  IF v_unit_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản nguồn'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  -- Lấy người phụ trách đầu tiên (primary curator)
  IF p_curator_ids IS NOT NULL AND array_length(p_curator_ids, 1) > 0 THEN
    v_curator_id := p_curator_ids[1];
  END IF;

  -- Tạo hồ sơ công việc
  INSERT INTO edoc.handling_docs (
    unit_id, name, comments, start_date, end_date,
    curator, status, is_from_doc, created_by, created_at, updated_at
  ) VALUES (
    v_unit_id, p_name, p_note, p_start_date, p_end_date,
    v_curator_id, 0, TRUE, p_created_by, NOW(), NOW()
  )
  RETURNING edoc.handling_docs.id INTO v_id;

  -- Liên kết văn bản với HSCV
  INSERT INTO edoc.handling_doc_links (handling_doc_id, doc_type, doc_id)
  VALUES (v_id, p_doc_type, p_doc_id)
  ON CONFLICT DO NOTHING;

  -- Thêm các người phụ trách vào staff_handling_docs
  IF p_curator_ids IS NOT NULL THEN
    FOREACH v_cid IN ARRAY p_curator_ids LOOP
      INSERT INTO edoc.staff_handling_docs (handling_doc_id, staff_id, role, assigned_at)
      VALUES (v_id, v_cid, 1, NOW())
      ON CONFLICT DO NOTHING;
    END LOOP;
  END IF;

  RETURN QUERY SELECT TRUE, 'Tạo hồ sơ công việc thành công'::TEXT, v_id;
END;
$$;

-- ==========================================
-- 6. FN: NHẬN BÀN GIAO VĂN BẢN ĐẾN
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_handover(
  p_doc_id    BIGINT,
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
  -- Kiểm tra văn bản tồn tại
  SELECT COUNT(*) INTO v_count FROM edoc.incoming_docs WHERE id = p_doc_id;
  IF v_count = 0 THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản'::TEXT;
    RETURN;
  END IF;

  -- Đánh dấu nhân viên đã nhận bàn giao (ghi nhận user nhận VB)
  INSERT INTO edoc.user_incoming_docs (incoming_doc_id, staff_id, is_read, read_at)
  VALUES (p_doc_id, p_staff_id, TRUE, NOW())
  ON CONFLICT (incoming_doc_id, staff_id)
  DO UPDATE SET is_read = TRUE, read_at = NOW();

  RETURN QUERY SELECT TRUE, 'Nhận bàn giao thành công'::TEXT;
END;
$$;

-- ==========================================
-- 7. FN: CHUYỂN LẠI / TRẢ VĂN BẢN ĐẾN
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_return(
  p_doc_id      BIGINT,
  p_returned_by INT,
  p_reason      TEXT
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
  -- Kiểm tra lý do không được rỗng
  IF p_reason IS NULL OR TRIM(p_reason) = '' THEN
    RETURN QUERY SELECT FALSE, 'Lý do chuyển lại không được để trống'::TEXT;
    RETURN;
  END IF;

  -- Kiểm tra văn bản tồn tại
  SELECT COUNT(*) INTO v_count FROM edoc.incoming_docs WHERE id = p_doc_id;
  IF v_count = 0 THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản'::TEXT;
    RETURN;
  END IF;

  -- Ghi nhận bút phê lý do chuyển lại
  INSERT INTO edoc.leader_notes (incoming_doc_id, staff_id, content, created_at)
  VALUES (p_doc_id, p_returned_by, '[Chuyển lại] ' || TRIM(p_reason), NOW());

  -- Cập nhật trạng thái văn bản về chờ xử lý
  UPDATE edoc.incoming_docs
  SET
    approved = FALSE,
    updated_by = p_returned_by,
    updated_at = NOW()
  WHERE id = p_doc_id;

  RETURN QUERY SELECT TRUE, 'Chuyển lại văn bản thành công'::TEXT;
END;
$$;

-- ==========================================
-- 8. FN: HỦY DUYỆT VĂN BẢN ĐẾN
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_cancel_approve(
  p_doc_id        BIGINT,
  p_cancelled_by  INT
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_approved BOOLEAN;
BEGIN
  -- Kiểm tra văn bản tồn tại và đã được duyệt
  SELECT approved INTO v_approved FROM edoc.incoming_docs WHERE id = p_doc_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản'::TEXT;
    RETURN;
  END IF;

  IF NOT COALESCE(v_approved, FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Văn bản chưa được duyệt, không thể hủy duyệt'::TEXT;
    RETURN;
  END IF;

  -- Hủy duyệt
  UPDATE edoc.incoming_docs
  SET
    approved = FALSE,
    updated_by = p_cancelled_by,
    updated_at = NOW()
  WHERE id = p_doc_id;

  RETURN QUERY SELECT TRUE, 'Hủy duyệt văn bản thành công'::TEXT;
END;
$$;

-- ================================================================
-- Source: 013_sprint8_messages_notices.sql
-- ================================================================

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

-- ================================================================
-- Source: 014_sprint9_calendar_directory.sql
-- ================================================================

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

-- ================================================================
-- Source: 015_sprint10_dashboard_stats.sql
-- ================================================================

-- ================================================================
-- MIGRATION 015: Sprint 10 — Dashboard thống kê & Widget dữ liệu
-- Functions: fn_dashboard_get_stats, fn_dashboard_recent_incoming,
--            fn_dashboard_upcoming_tasks, fn_dashboard_recent_outgoing
-- Fixed: doc_code→document_code, is_deleted removed, TIMESTAMPTZ, SMALLINT
-- ================================================================

-- ==========================================
-- 1. FN: Thống kê KPI Dashboard
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_get_stats(
  p_staff_id INT,
  p_unit_id  INT
) RETURNS TABLE (
  incoming_unread  BIGINT,
  outgoing_pending BIGINT,
  handling_total   BIGINT,
  handling_overdue BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    (
      SELECT COUNT(*)
      FROM edoc.user_incoming_docs uid
      INNER JOIN edoc.incoming_docs ind ON ind.id = uid.incoming_doc_id
      WHERE uid.staff_id = p_staff_id
        AND uid.is_read = FALSE
    ) AS incoming_unread,

    (
      SELECT COUNT(*)
      FROM edoc.outgoing_docs
      WHERE unit_id = p_unit_id
        AND approved = FALSE
    ) AS outgoing_pending,

    (
      SELECT COUNT(*)
      FROM edoc.handling_docs
      WHERE unit_id = p_unit_id
    ) AS handling_total,

    (
      SELECT COUNT(*)
      FROM edoc.handling_docs
      WHERE unit_id = p_unit_id
        AND end_date IS NOT NULL
        AND end_date < NOW()
        AND status != 4
    ) AS handling_overdue;
END;
$$;

-- ==========================================
-- 2. FN: Văn bản đến mới nhất
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_recent_incoming(
  p_unit_id INT,
  p_limit   INT DEFAULT 10
) RETURNS TABLE (
  id            BIGINT,
  doc_code      VARCHAR,
  abstract      TEXT,
  received_date TIMESTAMPTZ,
  urgency_name  VARCHAR,
  sender_name   VARCHAR
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    d.id,
    COALESCE(NULLIF(d.notation, ''), d.document_code, '')::VARCHAR AS doc_code,
    d.abstract,
    d.received_date,
    CASE d.urgent_id
      WHEN 1 THEN 'Thường'
      WHEN 2 THEN 'Khẩn'
      WHEN 3 THEN 'Hỏa tốc'
      ELSE 'Thường'
    END::VARCHAR AS urgency_name,
    COALESCE(d.publish_unit, '')::VARCHAR AS sender_name
  FROM edoc.incoming_docs d
  WHERE d.unit_id = p_unit_id
  ORDER BY d.received_date DESC NULLS LAST, d.created_at DESC
  LIMIT COALESCE(p_limit, 10);
END;
$$;

-- ==========================================
-- 3. FN: Việc sắp tới hạn
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_upcoming_tasks(
  p_staff_id INT,
  p_limit    INT DEFAULT 10
) RETURNS TABLE (
  id               BIGINT,
  title            VARCHAR,
  open_date        TIMESTAMPTZ,
  status           SMALLINT,
  progress_percent SMALLINT,
  deadline         TIMESTAMPTZ
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT
    hd.id,
    hd.name::VARCHAR AS title,
    hd.start_date AS open_date,
    hd.status,
    COALESCE(hd.progress, 0::SMALLINT) AS progress_percent,
    hd.end_date AS deadline
  FROM edoc.handling_docs hd
  WHERE hd.status != 4
    AND hd.end_date >= NOW()
    AND (
      hd.curator = p_staff_id
      OR EXISTS (
        SELECT 1 FROM edoc.staff_handling_docs shd
        WHERE shd.handling_doc_id = hd.id
          AND shd.staff_id = p_staff_id
      )
    )
  ORDER BY hd.end_date ASC
  LIMIT COALESCE(p_limit, 10);
END;
$$;

-- ==========================================
-- 4. FN: Văn bản đi mới nhất
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_recent_outgoing(
  p_unit_id INT,
  p_limit   INT DEFAULT 10
) RETURNS TABLE (
  id            BIGINT,
  doc_code      VARCHAR,
  abstract      TEXT,
  sent_date     TIMESTAMPTZ,
  doc_type_name VARCHAR
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    d.id,
    COALESCE(NULLIF(d.notation, ''), d.document_code, '')::VARCHAR AS doc_code,
    d.abstract,
    COALESCE(d.publish_date, d.received_date, d.created_at) AS sent_date,
    COALESCE(dt.name, '')::VARCHAR AS doc_type_name
  FROM edoc.outgoing_docs d
  LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
  WHERE d.unit_id = p_unit_id
  ORDER BY COALESCE(d.publish_date, d.received_date, d.created_at) DESC
  LIMIT COALESCE(p_limit, 10);
END;
$$;

-- ================================================================
-- Source: 016_sprint11_archive_storage.sql
-- ================================================================

-- ================================================================
-- MIGRATION 016: Sprint 11 — Kho lưu trữ (Archive/Storage)
-- Schema: esto
-- Tables: esto.warehouses, esto.fonds, esto.records,
--         esto.borrow_requests, esto.borrow_request_records
-- Functions: ~20 stored functions for warehouse/fond/record/borrow
-- ================================================================

-- ==========================================
-- 1. BẢNG KHO LƯU TRỮ (warehouses)
-- ==========================================
CREATE TABLE IF NOT EXISTS esto.warehouses (
  id                SERIAL PRIMARY KEY,
  unit_id           INT NOT NULL REFERENCES public.departments(id),
  type_id           INT,
  code              VARCHAR(50),
  name              VARCHAR(200) NOT NULL,
  phone_number      VARCHAR(50),
  address           VARCHAR(500),
  status            BOOLEAN DEFAULT true,
  description       TEXT,
  parent_id         INT DEFAULT 0,
  is_unit           BOOLEAN DEFAULT false,
  warehouse_level   INT DEFAULT 0,
  limit_child       INT DEFAULT 0,
  position          VARCHAR(200),
  is_deleted        BOOLEAN DEFAULT false,
  created_user_id   INT NOT NULL,
  created_date      TIMESTAMPTZ DEFAULT NOW(),
  modified_user_id  INT,
  modified_date     TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_warehouses_unit_id ON esto.warehouses(unit_id);
CREATE INDEX IF NOT EXISTS idx_warehouses_parent_id ON esto.warehouses(parent_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_warehouses_code ON esto.warehouses(unit_id, code) WHERE code IS NOT NULL AND is_deleted = false;

COMMENT ON TABLE esto.warehouses IS 'Kho lưu trữ — cấu trúc cây (parent_id), ánh xạ từ Warehouse.cs';

-- ==========================================
-- 2. BẢNG PHÔNG LƯU TRỮ (fonds)
-- ==========================================
CREATE TABLE IF NOT EXISTS esto.fonds (
  id                SERIAL PRIMARY KEY,
  unit_id           INT NOT NULL,
  parent_id         INT DEFAULT 0,
  fond_code         VARCHAR(50),
  fond_name         VARCHAR(200) NOT NULL,
  fond_history      TEXT,
  archives_time     VARCHAR(100),
  paper_total       DECIMAL,
  paper_digital     DECIMAL,
  keys_group        VARCHAR(200),
  other_type        VARCHAR(200),
  language          VARCHAR(100),
  lookup_tools      VARCHAR(200),
  coppy_number      DECIMAL,
  status            INT DEFAULT 1,
  description       TEXT,
  version           DECIMAL,
  created_user_id   INT NOT NULL,
  created_date      TIMESTAMPTZ DEFAULT NOW(),
  modified_user_id  INT,
  modified_date     TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_fonds_unit_id ON esto.fonds(unit_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_fonds_code ON esto.fonds(unit_id, fond_code) WHERE fond_code IS NOT NULL;

COMMENT ON TABLE esto.fonds IS 'Phông lưu trữ — ánh xạ từ Fond.cs';

-- ==========================================
-- 3. BẢNG HỒ SƠ LƯU TRỮ (records)
-- ==========================================
CREATE TABLE IF NOT EXISTS esto.records (
  id                        BIGSERIAL PRIMARY KEY,
  unit_id                   INT NOT NULL,
  fond_id                   INT NOT NULL REFERENCES esto.fonds(id),
  file_code                 VARCHAR(100),
  file_catalog              INT,
  file_notation             VARCHAR(200),
  title                     VARCHAR(500) NOT NULL,
  maintenance               VARCHAR(200),
  rights                    VARCHAR(200),
  language                  VARCHAR(100),
  start_date                DATE,
  complete_date             DATE,
  total_doc                 INT,
  description               TEXT,
  infor_sign                VARCHAR(200),
  keyword                   VARCHAR(500),
  total_paper               DECIMAL,
  page_number               DECIMAL,
  format                    INT DEFAULT 0,
  archive_date              DATE,
  reception_archive_id      INT,
  in_charge_staff_id        INT NOT NULL,
  parent_id                 INT DEFAULT 0,
  warehouse_id              INT NOT NULL REFERENCES esto.warehouses(id),
  reception_date            DATE,
  reception_from            INT DEFAULT 0,
  transfer_staff            VARCHAR(200),
  is_document_original      BOOLEAN,
  number_of_copy            INT,
  doc_field_id              INT,
  transfer_online_status    BOOLEAN DEFAULT false,
  created_user_id           INT,
  created_date              TIMESTAMPTZ DEFAULT NOW(),
  modified_user_id          INT,
  modified_date             TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_records_unit_id ON esto.records(unit_id);
CREATE INDEX IF NOT EXISTS idx_records_fond_id ON esto.records(fond_id);
CREATE INDEX IF NOT EXISTS idx_records_warehouse_id ON esto.records(warehouse_id);

COMMENT ON TABLE esto.records IS 'Hồ sơ lưu trữ — ánh xạ từ Record.cs';

-- ==========================================
-- 4. BẢNG YÊU CẦU MƯỢN/TRẢ (borrow_requests)
-- ==========================================
CREATE TABLE IF NOT EXISTS esto.borrow_requests (
  id                BIGSERIAL PRIMARY KEY,
  name              VARCHAR(200) NOT NULL,
  unit_id           INT NOT NULL,
  emergency         INT,
  notice            TEXT,
  borrow_date       DATE,
  status            INT DEFAULT 0,
  -- 0=Mới, 1=Đã duyệt, 2=Đã mượn, 3=Đã trả, -1=Từ chối
  created_user_id   INT NOT NULL,
  created_date      TIMESTAMPTZ DEFAULT NOW(),
  modified_user_id  INT,
  modified_date     TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_borrow_requests_unit_id ON esto.borrow_requests(unit_id);
CREATE INDEX IF NOT EXISTS idx_borrow_requests_status ON esto.borrow_requests(status);

COMMENT ON TABLE esto.borrow_requests IS 'Yêu cầu mượn/trả hồ sơ lưu trữ — ánh xạ từ BorrowRequest.cs';

-- ==========================================
-- 5. BẢNG LIÊN KẾT MƯỢN-HỒ SƠ (borrow_request_records)
-- ==========================================
CREATE TABLE IF NOT EXISTS esto.borrow_request_records (
  id                  BIGSERIAL PRIMARY KEY,
  borrow_request_id   BIGINT NOT NULL REFERENCES esto.borrow_requests(id) ON DELETE CASCADE,
  record_id           BIGINT NOT NULL REFERENCES esto.records(id),
  return_date         DATE,
  actual_return_date  DATE,
  UNIQUE(borrow_request_id, record_id)
);

COMMENT ON TABLE esto.borrow_request_records IS 'Chi tiết hồ sơ trong yêu cầu mượn/trả';

-- ==========================================
-- STORED FUNCTIONS — WAREHOUSE (KHO)
-- ==========================================

-- 1. Lấy cây kho
CREATE OR REPLACE FUNCTION esto.fn_warehouse_get_tree(
  p_unit_id INT
)
RETURNS TABLE (
  id                INT,
  unit_id           INT,
  type_id           INT,
  code              VARCHAR,
  name              VARCHAR,
  phone_number      VARCHAR,
  address           VARCHAR,
  status            BOOLEAN,
  description       TEXT,
  parent_id         INT,
  is_unit           BOOLEAN,
  warehouse_level   INT,
  limit_child       INT,
  "position"        VARCHAR,
  created_user_id   INT,
  created_date      TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    w.id,
    w.unit_id,
    w.type_id,
    w.code,
    w.name,
    w.phone_number,
    w.address,
    w.status,
    w.description,
    w.parent_id,
    w.is_unit,
    w.warehouse_level,
    w.limit_child,
    w."position",
    w.created_user_id,
    w.created_date
  FROM esto.warehouses w
  WHERE w.unit_id = p_unit_id
    AND w.is_deleted = false
  ORDER BY w.parent_id, w.name;
END;
$$;

-- 2. Lấy 1 kho theo id
CREATE OR REPLACE FUNCTION esto.fn_warehouse_get_by_id(
  p_id INT
)
RETURNS TABLE (
  id                INT,
  unit_id           INT,
  type_id           INT,
  code              VARCHAR,
  name              VARCHAR,
  phone_number      VARCHAR,
  address           VARCHAR,
  status            BOOLEAN,
  description       TEXT,
  parent_id         INT,
  is_unit           BOOLEAN,
  warehouse_level   INT,
  limit_child       INT,
  "position"        VARCHAR,
  created_user_id   INT,
  created_date      TIMESTAMPTZ,
  modified_user_id  INT,
  modified_date     TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    w.id,
    w.unit_id,
    w.type_id,
    w.code,
    w.name,
    w.phone_number,
    w.address,
    w.status,
    w.description,
    w.parent_id,
    w.is_unit,
    w.warehouse_level,
    w.limit_child,
    w."position",
    w.created_user_id,
    w.created_date,
    w.modified_user_id,
    w.modified_date
  FROM esto.warehouses w
  WHERE w.id = p_id AND w.is_deleted = false;
END;
$$;

-- 3. Tạo kho
CREATE OR REPLACE FUNCTION esto.fn_warehouse_create(
  p_unit_id          INT,
  p_type_id          INT,
  p_code             VARCHAR,
  p_name             VARCHAR,
  p_phone_number     VARCHAR,
  p_address          VARCHAR,
  p_status           BOOLEAN,
  p_description      TEXT,
  p_parent_id        INT,
  p_is_unit          BOOLEAN,
  p_warehouse_level  INT,
  p_limit_child      INT,
  p_position         VARCHAR,
  p_created_user_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id INT;
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên kho không được để trống'::TEXT, NULL::INT;
    RETURN;
  END IF;

  INSERT INTO esto.warehouses (
    unit_id, type_id, code, name, phone_number, address, status,
    description, parent_id, is_unit, warehouse_level, limit_child,
    "position", created_user_id
  ) VALUES (
    p_unit_id, p_type_id, NULLIF(TRIM(p_code),''), p_name, p_phone_number,
    p_address, COALESCE(p_status, true), p_description,
    COALESCE(p_parent_id, 0), COALESCE(p_is_unit, false),
    COALESCE(p_warehouse_level, 0), COALESCE(p_limit_child, 0),
    p_position, p_created_user_id
  ) RETURNING esto.warehouses.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo kho thành công'::TEXT, v_id;
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, 'Mã kho đã tồn tại trong đơn vị'::TEXT, NULL::INT;
END;
$$;

-- 4. Cập nhật kho
CREATE OR REPLACE FUNCTION esto.fn_warehouse_update(
  p_id               INT,
  p_type_id          INT,
  p_code             VARCHAR,
  p_name             VARCHAR,
  p_phone_number     VARCHAR,
  p_address          VARCHAR,
  p_status           BOOLEAN,
  p_description      TEXT,
  p_parent_id        INT,
  p_is_unit          BOOLEAN,
  p_warehouse_level  INT,
  p_limit_child      INT,
  p_position         VARCHAR,
  p_modified_user_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên kho không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE esto.warehouses SET
    type_id          = p_type_id,
    code             = NULLIF(TRIM(p_code),''),
    name             = p_name,
    phone_number     = p_phone_number,
    address          = p_address,
    status           = COALESCE(p_status, true),
    description      = p_description,
    parent_id        = COALESCE(p_parent_id, 0),
    is_unit          = COALESCE(p_is_unit, false),
    warehouse_level  = COALESCE(p_warehouse_level, 0),
    limit_child      = COALESCE(p_limit_child, 0),
    "position"       = p_position,
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id AND is_deleted = false;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy kho'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cập nhật thành công'::TEXT;
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, 'Mã kho đã tồn tại trong đơn vị'::TEXT;
END;
$$;

-- 5. Xóa kho (soft delete, kiểm tra hồ sơ con)
CREATE OR REPLACE FUNCTION esto.fn_warehouse_delete(
  p_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM esto.records WHERE warehouse_id = p_id;
  IF v_count > 0 THEN
    RETURN QUERY SELECT false, 'Kho đang có hồ sơ, không thể xóa'::TEXT;
    RETURN;
  END IF;

  SELECT COUNT(*) INTO v_count FROM esto.warehouses WHERE parent_id = p_id AND is_deleted = false;
  IF v_count > 0 THEN
    RETURN QUERY SELECT false, 'Kho đang có kho con, không thể xóa'::TEXT;
    RETURN;
  END IF;

  UPDATE esto.warehouses SET is_deleted = true WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy kho'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Xóa kho thành công'::TEXT;
END;
$$;

-- ==========================================
-- STORED FUNCTIONS — FOND (PHÔNG)
-- ==========================================

-- 6. Lấy cây phông
CREATE OR REPLACE FUNCTION esto.fn_fond_get_tree(
  p_unit_id INT
)
RETURNS TABLE (
  id                INT,
  unit_id           INT,
  parent_id         INT,
  fond_code         VARCHAR,
  fond_name         VARCHAR,
  fond_history      TEXT,
  archives_time     VARCHAR,
  paper_total       DECIMAL,
  paper_digital     DECIMAL,
  keys_group        VARCHAR,
  other_type        VARCHAR,
  language          VARCHAR,
  lookup_tools      VARCHAR,
  coppy_number      DECIMAL,
  status            INT,
  description       TEXT,
  version           DECIMAL,
  created_date      TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    f.id,
    f.unit_id,
    f.parent_id,
    f.fond_code,
    f.fond_name,
    f.fond_history,
    f.archives_time,
    f.paper_total,
    f.paper_digital,
    f.keys_group,
    f.other_type,
    f.language,
    f.lookup_tools,
    f.coppy_number,
    f.status,
    f.description,
    f.version,
    f.created_date
  FROM esto.fonds f
  WHERE f.unit_id = p_unit_id
  ORDER BY f.parent_id, f.fond_name;
END;
$$;

-- 7. Lấy 1 phông theo id
CREATE OR REPLACE FUNCTION esto.fn_fond_get_by_id(
  p_id INT
)
RETURNS TABLE (
  id                INT,
  unit_id           INT,
  parent_id         INT,
  fond_code         VARCHAR,
  fond_name         VARCHAR,
  fond_history      TEXT,
  archives_time     VARCHAR,
  paper_total       DECIMAL,
  paper_digital     DECIMAL,
  keys_group        VARCHAR,
  other_type        VARCHAR,
  language          VARCHAR,
  lookup_tools      VARCHAR,
  coppy_number      DECIMAL,
  status            INT,
  description       TEXT,
  version           DECIMAL,
  created_date      TIMESTAMPTZ,
  modified_user_id  INT,
  modified_date     TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    f.id, f.unit_id, f.parent_id, f.fond_code, f.fond_name,
    f.fond_history, f.archives_time, f.paper_total, f.paper_digital,
    f.keys_group, f.other_type, f.language, f.lookup_tools,
    f.coppy_number, f.status, f.description, f.version,
    f.created_date, f.modified_user_id, f.modified_date
  FROM esto.fonds f
  WHERE f.id = p_id;
END;
$$;

-- 8. Tạo phông
CREATE OR REPLACE FUNCTION esto.fn_fond_create(
  p_unit_id          INT,
  p_parent_id        INT,
  p_fond_code        VARCHAR,
  p_fond_name        VARCHAR,
  p_fond_history     TEXT,
  p_archives_time    VARCHAR,
  p_paper_total      DECIMAL,
  p_paper_digital    DECIMAL,
  p_keys_group       VARCHAR,
  p_other_type       VARCHAR,
  p_language         VARCHAR,
  p_lookup_tools     VARCHAR,
  p_coppy_number     DECIMAL,
  p_status           INT,
  p_description      TEXT,
  p_version          DECIMAL,
  p_created_user_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id INT;
BEGIN
  IF TRIM(COALESCE(p_fond_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên phông không được để trống'::TEXT, NULL::INT;
    RETURN;
  END IF;

  INSERT INTO esto.fonds (
    unit_id, parent_id, fond_code, fond_name, fond_history, archives_time,
    paper_total, paper_digital, keys_group, other_type, language,
    lookup_tools, coppy_number, status, description, version, created_user_id
  ) VALUES (
    p_unit_id, COALESCE(p_parent_id, 0), NULLIF(TRIM(p_fond_code),''),
    p_fond_name, p_fond_history, p_archives_time, p_paper_total, p_paper_digital,
    p_keys_group, p_other_type, p_language, p_lookup_tools, p_coppy_number,
    COALESCE(p_status, 1), p_description, p_version, p_created_user_id
  ) RETURNING esto.fonds.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo phông thành công'::TEXT, v_id;
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, 'Mã phông đã tồn tại trong đơn vị'::TEXT, NULL::INT;
END;
$$;

-- 9. Cập nhật phông
CREATE OR REPLACE FUNCTION esto.fn_fond_update(
  p_id               INT,
  p_parent_id        INT,
  p_fond_code        VARCHAR,
  p_fond_name        VARCHAR,
  p_fond_history     TEXT,
  p_archives_time    VARCHAR,
  p_paper_total      DECIMAL,
  p_paper_digital    DECIMAL,
  p_keys_group       VARCHAR,
  p_other_type       VARCHAR,
  p_language         VARCHAR,
  p_lookup_tools     VARCHAR,
  p_coppy_number     DECIMAL,
  p_status           INT,
  p_description      TEXT,
  p_version          DECIMAL,
  p_modified_user_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TRIM(COALESCE(p_fond_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên phông không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE esto.fonds SET
    parent_id        = COALESCE(p_parent_id, 0),
    fond_code        = NULLIF(TRIM(p_fond_code),''),
    fond_name        = p_fond_name,
    fond_history     = p_fond_history,
    archives_time    = p_archives_time,
    paper_total      = p_paper_total,
    paper_digital    = p_paper_digital,
    keys_group       = p_keys_group,
    other_type       = p_other_type,
    language         = p_language,
    lookup_tools     = p_lookup_tools,
    coppy_number     = p_coppy_number,
    status           = COALESCE(p_status, 1),
    description      = p_description,
    version          = p_version,
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy phông'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cập nhật thành công'::TEXT;
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, 'Mã phông đã tồn tại trong đơn vị'::TEXT;
END;
$$;

-- 10. Xóa phông
CREATE OR REPLACE FUNCTION esto.fn_fond_delete(
  p_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM esto.records WHERE fond_id = p_id;
  IF v_count > 0 THEN
    RETURN QUERY SELECT false, 'Phông đang có hồ sơ, không thể xóa'::TEXT;
    RETURN;
  END IF;

  SELECT COUNT(*) INTO v_count FROM esto.fonds WHERE parent_id = p_id;
  IF v_count > 0 THEN
    RETURN QUERY SELECT false, 'Phông đang có phông con, không thể xóa'::TEXT;
    RETURN;
  END IF;

  DELETE FROM esto.fonds WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy phông'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Xóa phông thành công'::TEXT;
END;
$$;

-- ==========================================
-- STORED FUNCTIONS — RECORD (HỒ SƠ LƯU TRỮ)
-- ==========================================

-- 11. Danh sách hồ sơ (phân trang)
CREATE OR REPLACE FUNCTION esto.fn_record_get_list(
  p_unit_id      INT,
  p_fond_id      INT,
  p_warehouse_id INT,
  p_keyword      TEXT,
  p_page         INT DEFAULT 1,
  p_page_size    INT DEFAULT 20
)
RETURNS TABLE (
  id                      BIGINT,
  unit_id                 INT,
  fond_id                 INT,
  fond_name               VARCHAR,
  file_code               VARCHAR,
  file_catalog            INT,
  file_notation           VARCHAR,
  title                   VARCHAR,
  maintenance             VARCHAR,
  rights                  VARCHAR,
  language                VARCHAR,
  start_date              DATE,
  complete_date           DATE,
  total_doc               INT,
  description             TEXT,
  infor_sign              VARCHAR,
  keyword                 VARCHAR,
  total_paper             DECIMAL,
  page_number             DECIMAL,
  format                  INT,
  archive_date            DATE,
  in_charge_staff_id      INT,
  warehouse_id            INT,
  warehouse_name          VARCHAR,
  transfer_online_status  BOOLEAN,
  created_date            TIMESTAMPTZ,
  total_count             BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT
      r.id,
      r.unit_id,
      r.fond_id,
      f.fond_name,
      r.file_code,
      r.file_catalog,
      r.file_notation,
      r.title,
      r.maintenance,
      r.rights,
      r.language,
      r.start_date,
      r.complete_date,
      r.total_doc,
      r.description,
      r.infor_sign,
      r.keyword,
      r.total_paper,
      r.page_number,
      r.format,
      r.archive_date,
      r.in_charge_staff_id,
      r.warehouse_id,
      w.name AS warehouse_name,
      r.transfer_online_status,
      r.created_date
    FROM esto.records r
    LEFT JOIN esto.fonds f ON f.id = r.fond_id
    LEFT JOIN esto.warehouses w ON w.id = r.warehouse_id
    WHERE r.unit_id = p_unit_id
      AND (p_fond_id IS NULL OR r.fond_id = p_fond_id)
      AND (p_warehouse_id IS NULL OR r.warehouse_id = p_warehouse_id)
      AND (p_keyword IS NULL OR TRIM(p_keyword) = '' OR
           r.title ILIKE '%' || p_keyword || '%' OR
           r.file_code ILIKE '%' || p_keyword || '%')
  )
  SELECT
    flt.*,
    COUNT(*) OVER() AS total_count
  FROM filtered flt
  ORDER BY flt.created_date DESC
  LIMIT p_page_size OFFSET v_offset;
END;
$$;

-- 12. Chi tiết 1 hồ sơ
CREATE OR REPLACE FUNCTION esto.fn_record_get_by_id(
  p_id BIGINT
)
RETURNS TABLE (
  id                      BIGINT,
  unit_id                 INT,
  fond_id                 INT,
  fond_name               VARCHAR,
  file_code               VARCHAR,
  file_catalog            INT,
  file_notation           VARCHAR,
  title                   VARCHAR,
  maintenance             VARCHAR,
  rights                  VARCHAR,
  language                VARCHAR,
  start_date              DATE,
  complete_date           DATE,
  total_doc               INT,
  description             TEXT,
  infor_sign              VARCHAR,
  keyword                 VARCHAR,
  total_paper             DECIMAL,
  page_number             DECIMAL,
  format                  INT,
  archive_date            DATE,
  reception_archive_id    INT,
  in_charge_staff_id      INT,
  parent_id               INT,
  warehouse_id            INT,
  warehouse_name          VARCHAR,
  reception_date          DATE,
  reception_from          INT,
  transfer_staff          VARCHAR,
  is_document_original    BOOLEAN,
  number_of_copy          INT,
  doc_field_id            INT,
  transfer_online_status  BOOLEAN,
  created_user_id         INT,
  created_date            TIMESTAMPTZ,
  modified_user_id        INT,
  modified_date           TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    r.id,
    r.unit_id,
    r.fond_id,
    f.fond_name,
    r.file_code,
    r.file_catalog,
    r.file_notation,
    r.title,
    r.maintenance,
    r.rights,
    r.language,
    r.start_date,
    r.complete_date,
    r.total_doc,
    r.description,
    r.infor_sign,
    r.keyword,
    r.total_paper,
    r.page_number,
    r.format,
    r.archive_date,
    r.reception_archive_id,
    r.in_charge_staff_id,
    r.parent_id,
    r.warehouse_id,
    w.name AS warehouse_name,
    r.reception_date,
    r.reception_from,
    r.transfer_staff,
    r.is_document_original,
    r.number_of_copy,
    r.doc_field_id,
    r.transfer_online_status,
    r.created_user_id,
    r.created_date,
    r.modified_user_id,
    r.modified_date
  FROM esto.records r
  LEFT JOIN esto.fonds f ON f.id = r.fond_id
  LEFT JOIN esto.warehouses w ON w.id = r.warehouse_id
  WHERE r.id = p_id;
END;
$$;

-- 13. Tạo hồ sơ
CREATE OR REPLACE FUNCTION esto.fn_record_create(
  p_unit_id                 INT,
  p_fond_id                 INT,
  p_warehouse_id            INT,
  p_file_code               VARCHAR,
  p_file_catalog            INT,
  p_file_notation           VARCHAR,
  p_title                   VARCHAR,
  p_maintenance             VARCHAR,
  p_rights                  VARCHAR,
  p_language                VARCHAR,
  p_start_date              DATE,
  p_complete_date           DATE,
  p_total_doc               INT,
  p_description             TEXT,
  p_infor_sign              VARCHAR,
  p_keyword                 VARCHAR,
  p_total_paper             DECIMAL,
  p_page_number             DECIMAL,
  p_format                  INT,
  p_archive_date            DATE,
  p_in_charge_staff_id      INT,
  p_reception_date          DATE,
  p_reception_from          INT,
  p_transfer_staff          VARCHAR,
  p_is_document_original    BOOLEAN,
  p_number_of_copy          INT,
  p_doc_field_id            INT,
  p_created_user_id         INT
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id BIGINT;
BEGIN
  IF TRIM(COALESCE(p_title, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tiêu đề hồ sơ không được để trống'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  INSERT INTO esto.records (
    unit_id, fond_id, warehouse_id, file_code, file_catalog, file_notation,
    title, maintenance, rights, language, start_date, complete_date, total_doc,
    description, infor_sign, keyword, total_paper, page_number, format,
    archive_date, in_charge_staff_id, reception_date, reception_from,
    transfer_staff, is_document_original, number_of_copy, doc_field_id,
    created_user_id
  ) VALUES (
    p_unit_id, p_fond_id, p_warehouse_id, p_file_code, p_file_catalog, p_file_notation,
    p_title, p_maintenance, p_rights, p_language, p_start_date, p_complete_date, p_total_doc,
    p_description, p_infor_sign, p_keyword, p_total_paper, p_page_number, COALESCE(p_format, 0),
    p_archive_date, p_in_charge_staff_id, p_reception_date, COALESCE(p_reception_from, 0),
    p_transfer_staff, p_is_document_original, p_number_of_copy, p_doc_field_id,
    p_created_user_id
  ) RETURNING esto.records.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo hồ sơ thành công'::TEXT, v_id;
END;
$$;

-- 14. Cập nhật hồ sơ
CREATE OR REPLACE FUNCTION esto.fn_record_update(
  p_id                      BIGINT,
  p_fond_id                 INT,
  p_warehouse_id            INT,
  p_file_code               VARCHAR,
  p_file_catalog            INT,
  p_file_notation           VARCHAR,
  p_title                   VARCHAR,
  p_maintenance             VARCHAR,
  p_rights                  VARCHAR,
  p_language                VARCHAR,
  p_start_date              DATE,
  p_complete_date           DATE,
  p_total_doc               INT,
  p_description             TEXT,
  p_infor_sign              VARCHAR,
  p_keyword                 VARCHAR,
  p_total_paper             DECIMAL,
  p_page_number             DECIMAL,
  p_format                  INT,
  p_archive_date            DATE,
  p_in_charge_staff_id      INT,
  p_reception_date          DATE,
  p_reception_from          INT,
  p_transfer_staff          VARCHAR,
  p_is_document_original    BOOLEAN,
  p_number_of_copy          INT,
  p_doc_field_id            INT,
  p_modified_user_id        INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TRIM(COALESCE(p_title, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tiêu đề hồ sơ không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE esto.records SET
    fond_id               = p_fond_id,
    warehouse_id          = p_warehouse_id,
    file_code             = p_file_code,
    file_catalog          = p_file_catalog,
    file_notation         = p_file_notation,
    title                 = p_title,
    maintenance           = p_maintenance,
    rights                = p_rights,
    language              = p_language,
    start_date            = p_start_date,
    complete_date         = p_complete_date,
    total_doc             = p_total_doc,
    description           = p_description,
    infor_sign            = p_infor_sign,
    keyword               = p_keyword,
    total_paper           = p_total_paper,
    page_number           = p_page_number,
    format                = COALESCE(p_format, 0),
    archive_date          = p_archive_date,
    in_charge_staff_id    = p_in_charge_staff_id,
    reception_date        = p_reception_date,
    reception_from        = COALESCE(p_reception_from, 0),
    transfer_staff        = p_transfer_staff,
    is_document_original  = p_is_document_original,
    number_of_copy        = p_number_of_copy,
    doc_field_id          = p_doc_field_id,
    modified_user_id      = p_modified_user_id,
    modified_date         = NOW()
  WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy hồ sơ'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cập nhật thành công'::TEXT;
END;
$$;

-- 15. Xóa hồ sơ (kiểm tra yêu cầu mượn)
CREATE OR REPLACE FUNCTION esto.fn_record_delete(
  p_id BIGINT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM esto.borrow_request_records WHERE record_id = p_id;
  IF v_count > 0 THEN
    RETURN QUERY SELECT false, 'Hồ sơ đang có yêu cầu mượn, không thể xóa'::TEXT;
    RETURN;
  END IF;

  DELETE FROM esto.records WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy hồ sơ'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Xóa hồ sơ thành công'::TEXT;
END;
$$;

-- ==========================================
-- STORED FUNCTIONS — BORROW REQUEST (MƯỢN/TRẢ)
-- ==========================================

-- 16. Danh sách yêu cầu mượn (phân trang)
CREATE OR REPLACE FUNCTION esto.fn_borrow_request_get_list(
  p_unit_id   INT,
  p_status    INT,
  p_keyword   TEXT,
  p_page      INT DEFAULT 1,
  p_page_size INT DEFAULT 20
)
RETURNS TABLE (
  id                BIGINT,
  name              VARCHAR,
  unit_id           INT,
  emergency         INT,
  notice            TEXT,
  borrow_date       DATE,
  status            INT,
  created_user_id   INT,
  creator_name      TEXT,
  created_date      TIMESTAMPTZ,
  record_count      BIGINT,
  total_count       BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT
      br.id,
      br.name,
      br.unit_id,
      br.emergency,
      br.notice,
      br.borrow_date,
      br.status,
      br.created_user_id,
      (s.last_name || ' ' || s.first_name)::TEXT AS creator_name,
      br.created_date,
      (SELECT COUNT(*) FROM esto.borrow_request_records brr WHERE brr.borrow_request_id = br.id) AS record_count
    FROM esto.borrow_requests br
    LEFT JOIN public.staff s ON s.id = br.created_user_id
    WHERE br.unit_id = p_unit_id
      AND (p_status IS NULL OR p_status = -99 OR br.status = p_status)
      AND (p_keyword IS NULL OR TRIM(p_keyword) = '' OR br.name ILIKE '%' || p_keyword || '%')
  )
  SELECT
    flt.*,
    COUNT(*) OVER() AS total_count
  FROM filtered flt
  ORDER BY flt.created_date DESC
  LIMIT p_page_size OFFSET v_offset;
END;
$$;

-- 17. Chi tiết yêu cầu mượn kèm danh sách hồ sơ
CREATE OR REPLACE FUNCTION esto.fn_borrow_request_get_by_id(
  p_id BIGINT
)
RETURNS TABLE (
  id                BIGINT,
  name              VARCHAR,
  unit_id           INT,
  emergency         INT,
  notice            TEXT,
  borrow_date       DATE,
  status            INT,
  created_user_id   INT,
  creator_name      TEXT,
  created_date      TIMESTAMPTZ,
  modified_user_id  INT,
  modified_date     TIMESTAMPTZ,
  record_id         BIGINT,
  record_title      VARCHAR,
  return_date       DATE,
  actual_return_date DATE
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    br.id,
    br.name,
    br.unit_id,
    br.emergency,
    br.notice,
    br.borrow_date,
    br.status,
    br.created_user_id,
    (s.last_name || ' ' || s.first_name)::TEXT AS creator_name,
    br.created_date,
    br.modified_user_id,
    br.modified_date,
    r.id AS record_id,
    r.title AS record_title,
    brr.return_date,
    brr.actual_return_date
  FROM esto.borrow_requests br
  LEFT JOIN public.staff s ON s.id = br.created_user_id
  LEFT JOIN esto.borrow_request_records brr ON brr.borrow_request_id = br.id
  LEFT JOIN esto.records r ON r.id = brr.record_id
  WHERE br.id = p_id;
END;
$$;

-- 18. Tạo yêu cầu mượn
CREATE OR REPLACE FUNCTION esto.fn_borrow_request_create(
  p_name             VARCHAR,
  p_unit_id          INT,
  p_emergency        INT,
  p_notice           TEXT,
  p_borrow_date      DATE,
  p_created_user_id  INT,
  p_record_ids       INT[]
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id BIGINT;
  v_record_id INT;
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên yêu cầu không được để trống'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  INSERT INTO esto.borrow_requests (name, unit_id, emergency, notice, borrow_date, created_user_id, status)
  VALUES (p_name, p_unit_id, p_emergency, p_notice, p_borrow_date, p_created_user_id, 0)
  RETURNING esto.borrow_requests.id INTO v_id;

  IF p_record_ids IS NOT NULL THEN
    FOREACH v_record_id IN ARRAY p_record_ids LOOP
      INSERT INTO esto.borrow_request_records (borrow_request_id, record_id)
      VALUES (v_id, v_record_id)
      ON CONFLICT (borrow_request_id, record_id) DO NOTHING;
    END LOOP;
  END IF;

  RETURN QUERY SELECT true, 'Tạo yêu cầu mượn thành công'::TEXT, v_id;
END;
$$;

-- 19. Duyệt yêu cầu mượn (status 0 -> 1) — T-05-01: validate status=0
CREATE OR REPLACE FUNCTION esto.fn_borrow_request_approve(
  p_id               BIGINT,
  p_modified_user_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_status INT;
BEGIN
  SELECT status INTO v_status FROM esto.borrow_requests WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy yêu cầu mượn'::TEXT;
    RETURN;
  END IF;

  IF v_status <> 0 THEN
    RETURN QUERY SELECT false, 'Yêu cầu không ở trạng thái chờ duyệt'::TEXT;
    RETURN;
  END IF;

  UPDATE esto.borrow_requests SET
    status           = 1,
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT true, 'Duyệt yêu cầu thành công'::TEXT;
END;
$$;

-- 20. Từ chối yêu cầu mượn (status 0 -> -1)
CREATE OR REPLACE FUNCTION esto.fn_borrow_request_reject(
  p_id               BIGINT,
  p_modified_user_id INT,
  p_notice           TEXT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_status INT;
BEGIN
  SELECT status INTO v_status FROM esto.borrow_requests WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy yêu cầu mượn'::TEXT;
    RETURN;
  END IF;

  IF v_status <> 0 THEN
    RETURN QUERY SELECT false, 'Yêu cầu không ở trạng thái chờ duyệt'::TEXT;
    RETURN;
  END IF;

  UPDATE esto.borrow_requests SET
    status           = -1,
    notice           = COALESCE(p_notice, notice),
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT true, 'Từ chối yêu cầu thành công'::TEXT;
END;
$$;

-- 21. Mượn hồ sơ (status 1 -> 2)
CREATE OR REPLACE FUNCTION esto.fn_borrow_request_checkout(
  p_id               BIGINT,
  p_modified_user_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_status INT;
BEGIN
  SELECT status INTO v_status FROM esto.borrow_requests WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy yêu cầu mượn'::TEXT;
    RETURN;
  END IF;

  IF v_status <> 1 THEN
    RETURN QUERY SELECT false, 'Yêu cầu chưa được duyệt'::TEXT;
    RETURN;
  END IF;

  UPDATE esto.borrow_requests SET
    status           = 2,
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT true, 'Xác nhận mượn thành công'::TEXT;
END;
$$;

-- 22. Trả hồ sơ (status 2 -> 3)
CREATE OR REPLACE FUNCTION esto.fn_borrow_request_return(
  p_id               BIGINT,
  p_modified_user_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_status INT;
BEGIN
  SELECT status INTO v_status FROM esto.borrow_requests WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy yêu cầu mượn'::TEXT;
    RETURN;
  END IF;

  IF v_status <> 2 THEN
    RETURN QUERY SELECT false, 'Yêu cầu chưa ở trạng thái đang mượn'::TEXT;
    RETURN;
  END IF;

  UPDATE esto.borrow_requests SET
    status           = 3,
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id;

  UPDATE esto.borrow_request_records SET
    actual_return_date = CURRENT_DATE
  WHERE borrow_request_id = p_id;

  RETURN QUERY SELECT true, 'Xác nhận trả thành công'::TEXT;
END;
$$;

-- ==========================================
-- Thông báo hoàn thành
-- ==========================================
DO $$
BEGIN
  RAISE NOTICE '✅ Migration 016: Sprint 11 Archive/Storage';
  RAISE NOTICE '   Tables: esto.warehouses, esto.fonds, esto.records, esto.borrow_requests, esto.borrow_request_records';
  RAISE NOTICE '   Functions: 22 stored functions (warehouse x5, fond x5, record x5, borrow x7)';
END $$;

-- ================================================================
-- Source: 017_sprint12_documents_contracts.sql
-- ================================================================

-- ================================================================
-- MIGRATION 017: Sprint 12 — Tài liệu chung (iso) & Hợp đồng (cont)
-- Schema: iso, cont
-- Tables: iso.document_categories, iso.documents,
--         cont.contract_types, cont.contracts, cont.contract_attachments
-- Functions: ~18 stored functions
-- ================================================================

-- ==========================================
-- 1. BẢNG DANH MỤC TÀI LIỆU (document_categories)
-- ==========================================
CREATE TABLE IF NOT EXISTS iso.document_categories (
  id                SERIAL PRIMARY KEY,
  parent_id         INT DEFAULT 0,
  code              VARCHAR(50),
  name              VARCHAR(200) NOT NULL,
  date_process      DECIMAL,
  status            INT DEFAULT 1,
  description       TEXT,
  version           DECIMAL,
  unit_id           INT,
  created_user_id   INT NOT NULL,
  created_date      TIMESTAMPTZ DEFAULT NOW(),
  modified_user_id  INT,
  modified_date     TIMESTAMPTZ
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_doc_categories_code ON iso.document_categories(unit_id, code)
  WHERE code IS NOT NULL;

COMMENT ON TABLE iso.document_categories IS 'Danh mục tài liệu ISO — cây phân cấp, ánh xạ từ EstoCategory.cs';

-- ==========================================
-- 2. BẢNG TÀI LIỆU CHUNG (documents)
-- ==========================================
CREATE TABLE IF NOT EXISTS iso.documents (
  id                BIGSERIAL PRIMARY KEY,
  unit_id           INT NOT NULL,
  category_id       INT REFERENCES iso.document_categories(id),
  title             VARCHAR(500) NOT NULL,
  description       TEXT,
  file_name         VARCHAR(500),
  file_path         VARCHAR(1000),
  file_size         BIGINT,
  mime_type         VARCHAR(200),
  keyword           VARCHAR(500),
  status            INT DEFAULT 1,
  -- 1=Đang hoạt động, 0=Không hoạt động
  created_user_id   INT NOT NULL,
  created_date      TIMESTAMPTZ DEFAULT NOW(),
  modified_user_id  INT,
  modified_date     TIMESTAMPTZ,
  is_deleted        BOOLEAN DEFAULT false
);

CREATE INDEX IF NOT EXISTS idx_documents_unit_id ON iso.documents(unit_id);
CREATE INDEX IF NOT EXISTS idx_documents_category_id ON iso.documents(category_id);

COMMENT ON TABLE iso.documents IS 'Tài liệu chung — tài liệu ISO, nội bộ, pháp quy';

-- ==========================================
-- 3. BẢNG LOẠI HỢP ĐỒNG (contract_types)
-- ==========================================
CREATE TABLE IF NOT EXISTS cont.contract_types (
  id                SERIAL PRIMARY KEY,
  unit_id           INT,
  parent_id         INT DEFAULT 0,
  code              VARCHAR(50),
  name              VARCHAR(200) NOT NULL,
  note              TEXT,
  sort_order        INT DEFAULT 0,
  created_user_id   INT NOT NULL,
  created_date      TIMESTAMPTZ DEFAULT NOW(),
  modified_user_id  INT,
  modified_date     TIMESTAMPTZ
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_contract_types_code ON cont.contract_types(unit_id, code)
  WHERE code IS NOT NULL;

COMMENT ON TABLE cont.contract_types IS 'Loại hợp đồng — ánh xạ từ ContractType.cs';

-- ==========================================
-- 4. BẢNG HỢP ĐỒNG (contracts)
-- ==========================================
CREATE TABLE IF NOT EXISTS cont.contracts (
  id                  SERIAL PRIMARY KEY,
  code_index          INT,
  contract_type_id    INT REFERENCES cont.contract_types(id),
  department_id       INT,
  type_of_contract    INT DEFAULT 0,
  contact_id          INT,
  contact_name        VARCHAR(200),
  unit_id             INT NOT NULL,
  code                VARCHAR(100),
  sign_date           DATE,
  input_date          DATE,
  receive_date        DATE,
  name                VARCHAR(500) NOT NULL,
  signer              VARCHAR(200),
  number              INT,
  ballot              VARCHAR(200),
  marker              VARCHAR(200),
  curator_name        VARCHAR(200),
  currency            VARCHAR(50),
  transporter         VARCHAR(200),
  staff_id            INT,
  note                TEXT,
  status              INT DEFAULT 0,
  -- 0=Mới, 1=Đang thực hiện, 2=Hoàn thành, -1=Hủy
  amount              VARCHAR(200),
  payment_amount      DECIMAL,
  created_user_id     INT NOT NULL,
  created_date        TIMESTAMPTZ DEFAULT NOW(),
  modified_user_id    INT,
  modified_date       TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_contracts_unit_id ON cont.contracts(unit_id);
CREATE INDEX IF NOT EXISTS idx_contracts_contract_type_id ON cont.contracts(contract_type_id);

COMMENT ON TABLE cont.contracts IS 'Hợp đồng — ánh xạ từ Contract.cs';

-- ==========================================
-- 5. BẢNG ĐÍNH KÈM HỢP ĐỒNG (contract_attachments)
-- ==========================================
CREATE TABLE IF NOT EXISTS cont.contract_attachments (
  id                BIGSERIAL PRIMARY KEY,
  contract_id       INT NOT NULL REFERENCES cont.contracts(id) ON DELETE CASCADE,
  file_name         VARCHAR(500) NOT NULL,
  file_path         VARCHAR(1000) NOT NULL,
  file_size         BIGINT,
  mime_type         VARCHAR(200),
  created_user_id   INT NOT NULL,
  created_date      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE cont.contract_attachments IS 'Đính kèm hợp đồng — ánh xạ từ AttachmentOfContract.cs';

-- ==========================================
-- STORED FUNCTIONS — DOCUMENT CATEGORIES
-- ==========================================

-- 1. Lấy cây danh mục tài liệu
CREATE OR REPLACE FUNCTION iso.fn_doc_category_get_tree(
  p_unit_id INT
)
RETURNS TABLE (
  id                INT,
  parent_id         INT,
  code              VARCHAR,
  name              VARCHAR,
  date_process      DECIMAL,
  status            INT,
  description       TEXT,
  version           DECIMAL,
  unit_id           INT,
  created_date      TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    dc.id,
    dc.parent_id,
    dc.code,
    dc.name,
    dc.date_process,
    dc.status,
    dc.description,
    dc.version,
    dc.unit_id,
    dc.created_date
  FROM iso.document_categories dc
  WHERE (dc.unit_id IS NULL OR dc.unit_id = p_unit_id)
    AND dc.status = 1
  ORDER BY dc.parent_id, dc.name;
END;
$$;

-- 2. Tạo danh mục tài liệu
CREATE OR REPLACE FUNCTION iso.fn_doc_category_create(
  p_parent_id        INT,
  p_code             VARCHAR,
  p_name             VARCHAR,
  p_date_process     DECIMAL,
  p_description      TEXT,
  p_version          DECIMAL,
  p_unit_id          INT,
  p_created_user_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id INT;
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên danh mục không được để trống'::TEXT, NULL::INT;
    RETURN;
  END IF;

  INSERT INTO iso.document_categories (
    parent_id, code, name, date_process, description, version, unit_id, created_user_id
  ) VALUES (
    COALESCE(p_parent_id, 0), NULLIF(TRIM(p_code),''), p_name,
    p_date_process, p_description, p_version, p_unit_id, p_created_user_id
  ) RETURNING iso.document_categories.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo danh mục thành công'::TEXT, v_id;
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, 'Mã danh mục đã tồn tại'::TEXT, NULL::INT;
END;
$$;

-- 3. Cập nhật danh mục tài liệu
CREATE OR REPLACE FUNCTION iso.fn_doc_category_update(
  p_id               INT,
  p_parent_id        INT,
  p_code             VARCHAR,
  p_name             VARCHAR,
  p_date_process     DECIMAL,
  p_status           INT,
  p_description      TEXT,
  p_version          DECIMAL,
  p_modified_user_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên danh mục không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE iso.document_categories SET
    parent_id        = COALESCE(p_parent_id, 0),
    code             = NULLIF(TRIM(p_code),''),
    name             = p_name,
    date_process     = p_date_process,
    status           = COALESCE(p_status, 1),
    description      = p_description,
    version          = p_version,
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy danh mục'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cập nhật thành công'::TEXT;
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, 'Mã danh mục đã tồn tại'::TEXT;
END;
$$;

-- 4. Xóa danh mục (kiểm tra danh mục con + tài liệu)
CREATE OR REPLACE FUNCTION iso.fn_doc_category_delete(
  p_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM iso.document_categories WHERE parent_id = p_id;
  IF v_count > 0 THEN
    RETURN QUERY SELECT false, 'Danh mục đang có danh mục con, không thể xóa'::TEXT;
    RETURN;
  END IF;

  SELECT COUNT(*) INTO v_count FROM iso.documents WHERE category_id = p_id AND is_deleted = false;
  IF v_count > 0 THEN
    RETURN QUERY SELECT false, 'Danh mục đang có tài liệu, không thể xóa'::TEXT;
    RETURN;
  END IF;

  UPDATE iso.document_categories SET status = 0 WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy danh mục'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Xóa danh mục thành công'::TEXT;
END;
$$;

-- ==========================================
-- STORED FUNCTIONS — DOCUMENTS
-- ==========================================

-- 5. Danh sách tài liệu (phân trang)
CREATE OR REPLACE FUNCTION iso.fn_document_get_list(
  p_unit_id     INT,
  p_category_id INT,
  p_keyword     TEXT,
  p_page        INT DEFAULT 1,
  p_page_size   INT DEFAULT 20
)
RETURNS TABLE (
  id              BIGINT,
  unit_id         INT,
  category_id     INT,
  category_name   VARCHAR,
  title           VARCHAR,
  description     TEXT,
  file_name       VARCHAR,
  file_path       VARCHAR,
  file_size       BIGINT,
  mime_type       VARCHAR,
  keyword         VARCHAR,
  status          INT,
  created_user_id INT,
  creator_name    TEXT,
  created_date    TIMESTAMPTZ,
  total_count     BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT
      d.id,
      d.unit_id,
      d.category_id,
      dc.name AS category_name,
      d.title,
      d.description,
      d.file_name,
      d.file_path,
      d.file_size,
      d.mime_type,
      d.keyword,
      d.status,
      d.created_user_id,
      (s.last_name || ' ' || s.first_name)::TEXT AS creator_name,
      d.created_date
    FROM iso.documents d
    LEFT JOIN iso.document_categories dc ON dc.id = d.category_id
    LEFT JOIN public.staff s ON s.id = d.created_user_id
    WHERE d.unit_id = p_unit_id
      AND d.is_deleted = false
      AND (p_category_id IS NULL OR d.category_id = p_category_id)
      AND (p_keyword IS NULL OR TRIM(p_keyword) = '' OR
           d.title ILIKE '%' || p_keyword || '%' OR
           d.keyword ILIKE '%' || p_keyword || '%')
  )
  SELECT
    flt.*,
    COUNT(*) OVER() AS total_count
  FROM filtered flt
  ORDER BY flt.created_date DESC
  LIMIT p_page_size OFFSET v_offset;
END;
$$;

-- 6. Chi tiết tài liệu
CREATE OR REPLACE FUNCTION iso.fn_document_get_by_id(
  p_id BIGINT
)
RETURNS TABLE (
  id              BIGINT,
  unit_id         INT,
  category_id     INT,
  category_name   VARCHAR,
  title           VARCHAR,
  description     TEXT,
  file_name       VARCHAR,
  file_path       VARCHAR,
  file_size       BIGINT,
  mime_type       VARCHAR,
  keyword         VARCHAR,
  status          INT,
  created_user_id INT,
  creator_name    TEXT,
  created_date    TIMESTAMPTZ,
  modified_user_id INT,
  modified_date   TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    d.id, d.unit_id, d.category_id, dc.name AS category_name,
    d.title, d.description, d.file_name, d.file_path, d.file_size,
    d.mime_type, d.keyword, d.status, d.created_user_id,
    (s.last_name || ' ' || s.first_name)::TEXT AS creator_name,
    d.created_date, d.modified_user_id, d.modified_date
  FROM iso.documents d
  LEFT JOIN iso.document_categories dc ON dc.id = d.category_id
  LEFT JOIN public.staff s ON s.id = d.created_user_id
  WHERE d.id = p_id AND d.is_deleted = false;
END;
$$;

-- 7. Tạo tài liệu
CREATE OR REPLACE FUNCTION iso.fn_document_create(
  p_unit_id          INT,
  p_category_id      INT,
  p_title            VARCHAR,
  p_description      TEXT,
  p_file_name        VARCHAR,
  p_file_path        VARCHAR,
  p_file_size        BIGINT,
  p_mime_type        VARCHAR,
  p_keyword          VARCHAR,
  p_status           INT,
  p_created_user_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id BIGINT;
BEGIN
  IF TRIM(COALESCE(p_title, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tiêu đề tài liệu không được để trống'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  INSERT INTO iso.documents (
    unit_id, category_id, title, description, file_name, file_path,
    file_size, mime_type, keyword, status, created_user_id
  ) VALUES (
    p_unit_id, p_category_id, p_title, p_description, p_file_name, p_file_path,
    p_file_size, p_mime_type, p_keyword, COALESCE(p_status, 1), p_created_user_id
  ) RETURNING iso.documents.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo tài liệu thành công'::TEXT, v_id;
END;
$$;

-- 8. Cập nhật tài liệu
CREATE OR REPLACE FUNCTION iso.fn_document_update(
  p_id               BIGINT,
  p_category_id      INT,
  p_title            VARCHAR,
  p_description      TEXT,
  p_file_name        VARCHAR,
  p_file_path        VARCHAR,
  p_file_size        BIGINT,
  p_mime_type        VARCHAR,
  p_keyword          VARCHAR,
  p_status           INT,
  p_modified_user_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TRIM(COALESCE(p_title, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tiêu đề tài liệu không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE iso.documents SET
    category_id      = p_category_id,
    title            = p_title,
    description      = p_description,
    file_name        = COALESCE(p_file_name, file_name),
    file_path        = COALESCE(p_file_path, file_path),
    file_size        = COALESCE(p_file_size, file_size),
    mime_type        = COALESCE(p_mime_type, mime_type),
    keyword          = p_keyword,
    status           = COALESCE(p_status, status),
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id AND is_deleted = false;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy tài liệu'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cập nhật thành công'::TEXT;
END;
$$;

-- 9. Xóa tài liệu (soft delete)
CREATE OR REPLACE FUNCTION iso.fn_document_delete(
  p_id BIGINT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE iso.documents SET is_deleted = true WHERE id = p_id AND is_deleted = false;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy tài liệu'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Xóa tài liệu thành công'::TEXT;
END;
$$;

-- ==========================================
-- STORED FUNCTIONS — CONTRACT TYPES
-- ==========================================

-- 10. Danh sách loại hợp đồng
CREATE OR REPLACE FUNCTION cont.fn_contract_type_get_list(
  p_unit_id INT
)
RETURNS TABLE (
  id                INT,
  unit_id           INT,
  parent_id         INT,
  code              VARCHAR,
  name              VARCHAR,
  note              TEXT,
  sort_order        INT,
  created_date      TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    ct.id, ct.unit_id, ct.parent_id, ct.code, ct.name, ct.note,
    ct.sort_order, ct.created_date
  FROM cont.contract_types ct
  WHERE (ct.unit_id IS NULL OR ct.unit_id = p_unit_id)
  ORDER BY ct.sort_order, ct.name;
END;
$$;

-- 11. Tạo loại hợp đồng
CREATE OR REPLACE FUNCTION cont.fn_contract_type_create(
  p_unit_id          INT,
  p_parent_id        INT,
  p_code             VARCHAR,
  p_name             VARCHAR,
  p_note             TEXT,
  p_sort_order       INT,
  p_created_user_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id INT;
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên loại hợp đồng không được để trống'::TEXT, NULL::INT;
    RETURN;
  END IF;

  INSERT INTO cont.contract_types (unit_id, parent_id, code, name, note, sort_order, created_user_id)
  VALUES (p_unit_id, COALESCE(p_parent_id, 0), NULLIF(TRIM(p_code),''), p_name, p_note, COALESCE(p_sort_order, 0), p_created_user_id)
  RETURNING cont.contract_types.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo loại hợp đồng thành công'::TEXT, v_id;
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, 'Mã loại hợp đồng đã tồn tại'::TEXT, NULL::INT;
END;
$$;

-- 12. Cập nhật loại hợp đồng
CREATE OR REPLACE FUNCTION cont.fn_contract_type_update(
  p_id               INT,
  p_parent_id        INT,
  p_code             VARCHAR,
  p_name             VARCHAR,
  p_note             TEXT,
  p_sort_order       INT,
  p_modified_user_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên loại hợp đồng không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE cont.contract_types SET
    parent_id        = COALESCE(p_parent_id, 0),
    code             = NULLIF(TRIM(p_code),''),
    name             = p_name,
    note             = p_note,
    sort_order       = COALESCE(p_sort_order, 0),
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy loại hợp đồng'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cập nhật thành công'::TEXT;
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, 'Mã loại hợp đồng đã tồn tại'::TEXT;
END;
$$;

-- 13. Xóa loại hợp đồng
CREATE OR REPLACE FUNCTION cont.fn_contract_type_delete(
  p_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM cont.contracts WHERE contract_type_id = p_id;
  IF v_count > 0 THEN
    RETURN QUERY SELECT false, 'Loại hợp đồng đang được sử dụng, không thể xóa'::TEXT;
    RETURN;
  END IF;

  DELETE FROM cont.contract_types WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy loại hợp đồng'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Xóa loại hợp đồng thành công'::TEXT;
END;
$$;

-- ==========================================
-- STORED FUNCTIONS — CONTRACTS
-- ==========================================

-- 14. Danh sách hợp đồng (phân trang)
CREATE OR REPLACE FUNCTION cont.fn_contract_get_list(
  p_unit_id          INT,
  p_contract_type_id INT,
  p_status           INT,
  p_keyword          TEXT,
  p_page             INT DEFAULT 1,
  p_page_size        INT DEFAULT 20
)
RETURNS TABLE (
  id                INT,
  code_index        INT,
  contract_type_id  INT,
  type_name         VARCHAR,
  unit_id           INT,
  code              VARCHAR,
  name              VARCHAR,
  sign_date         DATE,
  signer            VARCHAR,
  contact_name      VARCHAR,
  staff_id          INT,
  status            INT,
  amount            VARCHAR,
  payment_amount    DECIMAL,
  created_date      TIMESTAMPTZ,
  attachment_count  BIGINT,
  total_count       BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT
      c.id,
      c.code_index,
      c.contract_type_id,
      ct.name AS type_name,
      c.unit_id,
      c.code,
      c.name,
      c.sign_date,
      c.signer,
      c.contact_name,
      c.staff_id,
      c.status,
      c.amount,
      c.payment_amount,
      c.created_date,
      (SELECT COUNT(*) FROM cont.contract_attachments ca WHERE ca.contract_id = c.id) AS attachment_count
    FROM cont.contracts c
    LEFT JOIN cont.contract_types ct ON ct.id = c.contract_type_id
    WHERE c.unit_id = p_unit_id
      AND (p_contract_type_id IS NULL OR c.contract_type_id = p_contract_type_id)
      AND (p_status IS NULL OR p_status = -99 OR c.status = p_status)
      AND (p_keyword IS NULL OR TRIM(p_keyword) = '' OR
           c.name ILIKE '%' || p_keyword || '%' OR
           c.code ILIKE '%' || p_keyword || '%' OR
           c.contact_name ILIKE '%' || p_keyword || '%')
  )
  SELECT
    flt.*,
    COUNT(*) OVER() AS total_count
  FROM filtered flt
  ORDER BY flt.created_date DESC
  LIMIT p_page_size OFFSET v_offset;
END;
$$;

-- 15. Chi tiết hợp đồng
CREATE OR REPLACE FUNCTION cont.fn_contract_get_by_id(
  p_id INT
)
RETURNS TABLE (
  id                INT,
  code_index        INT,
  contract_type_id  INT,
  type_name         VARCHAR,
  department_id     INT,
  type_of_contract  INT,
  contact_id        INT,
  contact_name      VARCHAR,
  unit_id           INT,
  code              VARCHAR,
  sign_date         DATE,
  input_date        DATE,
  receive_date      DATE,
  name              VARCHAR,
  signer            VARCHAR,
  number            INT,
  ballot            VARCHAR,
  marker            VARCHAR,
  curator_name      VARCHAR,
  currency          VARCHAR,
  transporter       VARCHAR,
  staff_id          INT,
  note              TEXT,
  status            INT,
  amount            VARCHAR,
  payment_amount    DECIMAL,
  created_user_id   INT,
  created_date      TIMESTAMPTZ,
  modified_user_id  INT,
  modified_date     TIMESTAMPTZ,
  attachment_count  BIGINT
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id, c.code_index, c.contract_type_id, ct.name AS type_name,
    c.department_id, c.type_of_contract, c.contact_id, c.contact_name,
    c.unit_id, c.code, c.sign_date, c.input_date, c.receive_date,
    c.name, c.signer, c.number, c.ballot, c.marker, c.curator_name,
    c.currency, c.transporter, c.staff_id, c.note, c.status,
    c.amount, c.payment_amount, c.created_user_id, c.created_date,
    c.modified_user_id, c.modified_date,
    (SELECT COUNT(*) FROM cont.contract_attachments ca WHERE ca.contract_id = c.id) AS attachment_count
  FROM cont.contracts c
  LEFT JOIN cont.contract_types ct ON ct.id = c.contract_type_id
  WHERE c.id = p_id;
END;
$$;

-- 16. Tạo hợp đồng
CREATE OR REPLACE FUNCTION cont.fn_contract_create(
  p_code_index        INT,
  p_contract_type_id  INT,
  p_department_id     INT,
  p_type_of_contract  INT,
  p_contact_id        INT,
  p_contact_name      VARCHAR,
  p_unit_id           INT,
  p_code              VARCHAR,
  p_sign_date         DATE,
  p_input_date        DATE,
  p_receive_date      DATE,
  p_name              VARCHAR,
  p_signer            VARCHAR,
  p_number            INT,
  p_ballot            VARCHAR,
  p_marker            VARCHAR,
  p_curator_name      VARCHAR,
  p_currency          VARCHAR,
  p_transporter       VARCHAR,
  p_staff_id          INT,
  p_note              TEXT,
  p_status            INT,
  p_amount            VARCHAR,
  p_payment_amount    DECIMAL,
  p_created_user_id   INT
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_id INT;
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên hợp đồng không được để trống'::TEXT, NULL::INT;
    RETURN;
  END IF;

  INSERT INTO cont.contracts (
    code_index, contract_type_id, department_id, type_of_contract, contact_id,
    contact_name, unit_id, code, sign_date, input_date, receive_date, name,
    signer, number, ballot, marker, curator_name, currency, transporter,
    staff_id, note, status, amount, payment_amount, created_user_id
  ) VALUES (
    p_code_index, p_contract_type_id, p_department_id, COALESCE(p_type_of_contract, 0),
    p_contact_id, p_contact_name, p_unit_id, p_code, p_sign_date, p_input_date,
    p_receive_date, p_name, p_signer, p_number, p_ballot, p_marker, p_curator_name,
    p_currency, p_transporter, p_staff_id, p_note, COALESCE(p_status, 0),
    p_amount, p_payment_amount, p_created_user_id
  ) RETURNING cont.contracts.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo hợp đồng thành công'::TEXT, v_id;
END;
$$;

-- 17. Cập nhật hợp đồng
CREATE OR REPLACE FUNCTION cont.fn_contract_update(
  p_id                INT,
  p_code_index        INT,
  p_contract_type_id  INT,
  p_department_id     INT,
  p_type_of_contract  INT,
  p_contact_id        INT,
  p_contact_name      VARCHAR,
  p_code              VARCHAR,
  p_sign_date         DATE,
  p_input_date        DATE,
  p_receive_date      DATE,
  p_name              VARCHAR,
  p_signer            VARCHAR,
  p_number            INT,
  p_ballot            VARCHAR,
  p_marker            VARCHAR,
  p_curator_name      VARCHAR,
  p_currency          VARCHAR,
  p_transporter       VARCHAR,
  p_staff_id          INT,
  p_note              TEXT,
  p_status            INT,
  p_amount            VARCHAR,
  p_payment_amount    DECIMAL,
  p_modified_user_id  INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên hợp đồng không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE cont.contracts SET
    code_index        = p_code_index,
    contract_type_id  = p_contract_type_id,
    department_id     = p_department_id,
    type_of_contract  = COALESCE(p_type_of_contract, 0),
    contact_id        = p_contact_id,
    contact_name      = p_contact_name,
    code              = p_code,
    sign_date         = p_sign_date,
    input_date        = p_input_date,
    receive_date      = p_receive_date,
    name              = p_name,
    signer            = p_signer,
    number            = p_number,
    ballot            = p_ballot,
    marker            = p_marker,
    curator_name      = p_curator_name,
    currency          = p_currency,
    transporter       = p_transporter,
    staff_id          = p_staff_id,
    note              = p_note,
    status            = COALESCE(p_status, status),
    amount            = p_amount,
    payment_amount    = p_payment_amount,
    modified_user_id  = p_modified_user_id,
    modified_date     = NOW()
  WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy hợp đồng'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cập nhật thành công'::TEXT;
END;
$$;

-- 18. Xóa hợp đồng (chỉ khi status=0)
CREATE OR REPLACE FUNCTION cont.fn_contract_delete(
  p_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_status INT;
BEGIN
  SELECT status INTO v_status FROM cont.contracts WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy hợp đồng'::TEXT;
    RETURN;
  END IF;

  IF v_status <> 0 THEN
    RETURN QUERY SELECT false, 'Chỉ có thể xóa hợp đồng ở trạng thái Mới'::TEXT;
    RETURN;
  END IF;

  DELETE FROM cont.contracts WHERE id = p_id;

  RETURN QUERY SELECT true, 'Xóa hợp đồng thành công'::TEXT;
END;
$$;

-- 19. Lấy danh sách đính kèm hợp đồng
CREATE OR REPLACE FUNCTION cont.fn_contract_get_attachments(
  p_contract_id INT
)
RETURNS TABLE (
  id              BIGINT,
  contract_id     INT,
  file_name       VARCHAR,
  file_path       VARCHAR,
  file_size       BIGINT,
  mime_type       VARCHAR,
  created_user_id INT,
  created_date    TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    ca.id, ca.contract_id, ca.file_name, ca.file_path,
    ca.file_size, ca.mime_type, ca.created_user_id, ca.created_date
  FROM cont.contract_attachments ca
  WHERE ca.contract_id = p_contract_id
  ORDER BY ca.created_date DESC;
END;
$$;

-- ==========================================
-- Thông báo hoàn thành
-- ==========================================
DO $$
BEGIN
  RAISE NOTICE '✅ Migration 017: Sprint 12 Documents & Contracts';
  RAISE NOTICE '   Tables: iso.document_categories, iso.documents, cont.contract_types, cont.contracts, cont.contract_attachments';
  RAISE NOTICE '   Functions: 19 stored functions (doc_category x4, document x5, contract_type x4, contract x5, attachment x1)';
END $$;

-- ================================================================
-- Source: 018_sprint13_meetings.sql
-- ================================================================

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

-- ================================================================
-- Source: 019_sprint14_lgsp.sql
-- ================================================================

-- ================================================================
-- MIGRATION 019: Sprint 14 — LGSP Lien thong van ban
-- Schema: edoc
-- Tables: edoc.lgsp_organizations, edoc.lgsp_tracking
-- Functions: 6 stored functions
-- ================================================================

-- ==========================================
-- 1. BANG CO QUAN LIEN THONG (lgsp_organizations)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.lgsp_organizations (
  id          BIGSERIAL PRIMARY KEY,
  org_code    VARCHAR(100) NOT NULL,
  org_name    VARCHAR(500) NOT NULL,
  parent_code VARCHAR(100),
  address     VARCHAR(500),
  email       VARCHAR(200),
  phone       VARCHAR(50),
  is_active   BOOLEAN DEFAULT true,
  synced_at   TIMESTAMPTZ DEFAULT NOW(),
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT uq_lgsp_org_code UNIQUE(org_code)
);

COMMENT ON TABLE edoc.lgsp_organizations IS 'Danh sach co quan lien thong dong bo tu LGSP';

-- ==========================================
-- 2. BANG TRACKING LIEN THONG (lgsp_tracking)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.lgsp_tracking (
  id               BIGSERIAL PRIMARY KEY,
  outgoing_doc_id  BIGINT REFERENCES edoc.outgoing_docs(id),
  incoming_doc_id  BIGINT REFERENCES edoc.incoming_docs(id),
  direction        VARCHAR(10) NOT NULL CHECK(direction IN ('send', 'receive')),
  lgsp_doc_id      VARCHAR(200),
  dest_org_code    VARCHAR(100),
  dest_org_name    VARCHAR(500),
  edxml_content    TEXT,
  status           VARCHAR(50) NOT NULL DEFAULT 'pending'
                   CHECK(status IN ('pending', 'processing', 'success', 'error')),
  error_message    TEXT,
  sent_at          TIMESTAMPTZ,
  received_at      TIMESTAMPTZ,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  created_by       INT REFERENCES public.staff(id)
);

CREATE INDEX IF NOT EXISTS idx_lgsp_tracking_outgoing ON edoc.lgsp_tracking(outgoing_doc_id);
CREATE INDEX IF NOT EXISTS idx_lgsp_tracking_status ON edoc.lgsp_tracking(status);
CREATE INDEX IF NOT EXISTS idx_lgsp_tracking_direction ON edoc.lgsp_tracking(direction);

COMMENT ON TABLE edoc.lgsp_tracking IS 'Tracking trang thai gui/nhan van ban lien thong LGSP';

-- ==========================================
-- 3. FN: DONG BO CO QUAN LIEN THONG (UPSERT)
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_lgsp_org_sync(
  p_org_code    VARCHAR,
  p_org_name    VARCHAR,
  p_parent_code VARCHAR DEFAULT NULL,
  p_address     VARCHAR DEFAULT NULL,
  p_email       VARCHAR DEFAULT NULL,
  p_phone       VARCHAR DEFAULT NULL
)
RETURNS TABLE (
  success   BOOLEAN,
  message   TEXT,
  id        BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
  v_id BIGINT;
BEGIN
  INSERT INTO edoc.lgsp_organizations (org_code, org_name, parent_code, address, email, phone, synced_at)
  VALUES (p_org_code, p_org_name, p_parent_code, p_address, p_email, p_phone, NOW())
  ON CONFLICT (org_code) DO UPDATE SET
    org_name    = EXCLUDED.org_name,
    parent_code = EXCLUDED.parent_code,
    address     = EXCLUDED.address,
    email       = EXCLUDED.email,
    phone       = EXCLUDED.phone,
    synced_at   = NOW()
  RETURNING edoc.lgsp_organizations.id INTO v_id;

  RETURN QUERY SELECT true, 'Dong bo co quan thanh cong'::TEXT, v_id;
END;
$$;

-- ==========================================
-- 4. FN: DANH SACH CO QUAN LIEN THONG
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_lgsp_org_get_list(
  p_search    TEXT DEFAULT NULL,
  p_page      INT DEFAULT 1,
  p_page_size INT DEFAULT 20
)
RETURNS TABLE (
  id          BIGINT,
  org_code    VARCHAR,
  org_name    VARCHAR,
  parent_code VARCHAR,
  address     VARCHAR,
  email       VARCHAR,
  phone       VARCHAR,
  is_active   BOOLEAN,
  synced_at   TIMESTAMPTZ,
  total_count BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
  v_offset INT := (p_page - 1) * p_page_size;
  v_total  BIGINT;
BEGIN
  SELECT COUNT(*) INTO v_total
  FROM edoc.lgsp_organizations o
  WHERE (p_search IS NULL OR p_search = ''
    OR o.org_code ILIKE '%' || p_search || '%'
    OR o.org_name ILIKE '%' || p_search || '%');

  RETURN QUERY
  SELECT
    o.id,
    o.org_code,
    o.org_name,
    o.parent_code,
    o.address,
    o.email,
    o.phone,
    o.is_active,
    o.synced_at,
    v_total
  FROM edoc.lgsp_organizations o
  WHERE (p_search IS NULL OR p_search = ''
    OR o.org_code ILIKE '%' || p_search || '%'
    OR o.org_name ILIKE '%' || p_search || '%')
  ORDER BY o.org_name
  LIMIT p_page_size OFFSET v_offset;
END;
$$;

-- ==========================================
-- 5. FN: TAO TRACKING LIEN THONG
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_lgsp_tracking_create(
  p_outgoing_doc_id BIGINT DEFAULT NULL,
  p_direction       VARCHAR DEFAULT 'send',
  p_dest_org_code   VARCHAR DEFAULT NULL,
  p_dest_org_name   VARCHAR DEFAULT NULL,
  p_edxml_content   TEXT DEFAULT NULL,
  p_created_by      INT DEFAULT NULL
)
RETURNS TABLE (
  success   BOOLEAN,
  message   TEXT,
  id        BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
  v_id BIGINT;
BEGIN
  INSERT INTO edoc.lgsp_tracking (
    outgoing_doc_id, direction, dest_org_code, dest_org_name,
    edxml_content, created_by
  )
  VALUES (
    p_outgoing_doc_id, p_direction, p_dest_org_code, p_dest_org_name,
    p_edxml_content, p_created_by
  )
  RETURNING edoc.lgsp_tracking.id INTO v_id;

  RETURN QUERY SELECT true, 'Tao tracking thanh cong'::TEXT, v_id;
END;
$$;

-- ==========================================
-- 6. FN: CAP NHAT TRANG THAI TRACKING
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_lgsp_tracking_update_status(
  p_id            BIGINT,
  p_status        VARCHAR,
  p_lgsp_doc_id   VARCHAR DEFAULT NULL,
  p_error_message TEXT DEFAULT NULL
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT
)
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE edoc.lgsp_tracking
  SET status        = p_status,
      lgsp_doc_id   = COALESCE(p_lgsp_doc_id, lgsp_doc_id),
      error_message = p_error_message,
      sent_at       = CASE WHEN p_status = 'success' THEN NOW() ELSE sent_at END,
      received_at   = CASE WHEN p_status = 'success' AND direction = 'receive' THEN NOW() ELSE received_at END
  WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Khong tim thay tracking'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cap nhat trang thai thanh cong'::TEXT;
END;
$$;

-- ==========================================
-- 7. FN: DANH SACH TRACKING LIEN THONG
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_lgsp_tracking_get_list(
  p_direction VARCHAR DEFAULT NULL,
  p_status    VARCHAR DEFAULT NULL,
  p_page      INT DEFAULT 1,
  p_page_size INT DEFAULT 20
)
RETURNS TABLE (
  id              BIGINT,
  outgoing_doc_id BIGINT,
  incoming_doc_id BIGINT,
  direction       VARCHAR,
  lgsp_doc_id     VARCHAR,
  dest_org_code   VARCHAR,
  dest_org_name   VARCHAR,
  status          VARCHAR,
  error_message   TEXT,
  sent_at         TIMESTAMPTZ,
  received_at     TIMESTAMPTZ,
  created_at      TIMESTAMPTZ,
  total_count     BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
  v_offset INT := (p_page - 1) * p_page_size;
  v_total  BIGINT;
BEGIN
  SELECT COUNT(*) INTO v_total
  FROM edoc.lgsp_tracking t
  WHERE (p_direction IS NULL OR p_direction = '' OR t.direction = p_direction)
    AND (p_status IS NULL OR p_status = '' OR t.status = p_status);

  RETURN QUERY
  SELECT
    t.id,
    t.outgoing_doc_id,
    t.incoming_doc_id,
    t.direction,
    t.lgsp_doc_id,
    t.dest_org_code,
    t.dest_org_name,
    t.status,
    t.error_message,
    t.sent_at,
    t.received_at,
    t.created_at,
    v_total
  FROM edoc.lgsp_tracking t
  WHERE (p_direction IS NULL OR p_direction = '' OR t.direction = p_direction)
    AND (p_status IS NULL OR p_status = '' OR t.status = p_status)
  ORDER BY t.created_at DESC
  LIMIT p_page_size OFFSET v_offset;
END;
$$;

-- ==========================================
-- 8. FN: TRACKING THEO VAN BAN DI
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_lgsp_tracking_get_by_doc(
  p_outgoing_doc_id BIGINT
)
RETURNS TABLE (
  id            BIGINT,
  direction     VARCHAR,
  lgsp_doc_id   VARCHAR,
  dest_org_code VARCHAR,
  dest_org_name VARCHAR,
  status        VARCHAR,
  error_message TEXT,
  sent_at       TIMESTAMPTZ,
  created_at    TIMESTAMPTZ
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    t.id,
    t.direction,
    t.lgsp_doc_id,
    t.dest_org_code,
    t.dest_org_name,
    t.status,
    t.error_message,
    t.sent_at,
    t.created_at
  FROM edoc.lgsp_tracking t
  WHERE t.outgoing_doc_id = p_outgoing_doc_id
  ORDER BY t.created_at DESC;
END;
$$;

-- ================================================================
-- Source: 020_sprint15_digital_signing.sql
-- ================================================================

-- ================================================================
-- MIGRATION 020: Sprint 15 — Ky so dien tu (Digital Signing)
-- Schema: edoc
-- Tables: edoc.digital_signatures
-- Functions: 4 stored functions
-- ================================================================

-- ==========================================
-- 1. BANG CHU KY SO (digital_signatures)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.digital_signatures (
  id                  BIGSERIAL PRIMARY KEY,
  doc_id              BIGINT NOT NULL,
  doc_type            VARCHAR(20) NOT NULL CHECK(doc_type IN ('outgoing', 'drafting')),
  staff_id            INT NOT NULL REFERENCES public.staff(id),
  sign_method         VARCHAR(30) NOT NULL CHECK(sign_method IN ('smart_ca', 'esign_neac', 'usb_token')),
  certificate_serial  VARCHAR(200),
  certificate_subject VARCHAR(500),
  certificate_issuer  VARCHAR(500),
  signed_file_path    VARCHAR(1000),
  original_file_path  VARCHAR(1000),
  sign_status         VARCHAR(20) NOT NULL DEFAULT 'pending'
                      CHECK(sign_status IN ('pending', 'signing', 'signed', 'error', 'rejected')),
  error_message       TEXT,
  signed_at           TIMESTAMPTZ,
  created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_digsig_doc ON edoc.digital_signatures(doc_id, doc_type);
CREATE INDEX IF NOT EXISTS idx_digsig_staff ON edoc.digital_signatures(staff_id);
CREATE INDEX IF NOT EXISTS idx_digsig_status ON edoc.digital_signatures(sign_status);

COMMENT ON TABLE edoc.digital_signatures IS 'Chu ky so tren van ban — luu thong tin ky SmartCA, EsignNEAC, USB Token';

-- ==========================================
-- 2. FN: TAO YEU CAU KY SO
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_digital_signature_create(
  p_doc_id             BIGINT,
  p_doc_type           VARCHAR,
  p_staff_id           INT,
  p_sign_method        VARCHAR,
  p_original_file_path VARCHAR DEFAULT NULL
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT,
  id      BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
  v_id BIGINT;
BEGIN
  -- Validate doc_type
  IF p_doc_type NOT IN ('outgoing', 'drafting') THEN
    RETURN QUERY SELECT false, 'Loai van ban khong hop le'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  -- Validate sign_method
  IF p_sign_method NOT IN ('smart_ca', 'esign_neac', 'usb_token') THEN
    RETURN QUERY SELECT false, 'Phuong thuc ky khong hop le'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.digital_signatures (
    doc_id, doc_type, staff_id, sign_method, original_file_path
  )
  VALUES (
    p_doc_id, p_doc_type, p_staff_id, p_sign_method, p_original_file_path
  )
  RETURNING edoc.digital_signatures.id INTO v_id;

  RETURN QUERY SELECT true, 'Tao yeu cau ky so thanh cong'::TEXT, v_id;
END;
$$;

-- ==========================================
-- 3. FN: CAP NHAT TRANG THAI KY SO
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_digital_signature_update_status(
  p_id                  BIGINT,
  p_sign_status         VARCHAR,
  p_certificate_serial  VARCHAR DEFAULT NULL,
  p_certificate_subject VARCHAR DEFAULT NULL,
  p_certificate_issuer  VARCHAR DEFAULT NULL,
  p_signed_file_path    VARCHAR DEFAULT NULL,
  p_error_message       TEXT DEFAULT NULL
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT
)
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE edoc.digital_signatures
  SET sign_status         = p_sign_status,
      certificate_serial  = COALESCE(p_certificate_serial, certificate_serial),
      certificate_subject = COALESCE(p_certificate_subject, certificate_subject),
      certificate_issuer  = COALESCE(p_certificate_issuer, certificate_issuer),
      signed_file_path    = COALESCE(p_signed_file_path, signed_file_path),
      error_message       = p_error_message,
      signed_at           = CASE WHEN p_sign_status = 'signed' THEN NOW() ELSE signed_at END
  WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Khong tim thay ban ghi ky so'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cap nhat trang thai ky so thanh cong'::TEXT;
END;
$$;

-- ==========================================
-- 4. FN: LAY CHU KY SO THEO VAN BAN
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_digital_signature_get_by_doc(
  p_doc_id   BIGINT,
  p_doc_type VARCHAR
)
RETURNS TABLE (
  id                  BIGINT,
  doc_id              BIGINT,
  doc_type            VARCHAR,
  staff_id            INT,
  staff_name          VARCHAR,
  sign_method         VARCHAR,
  certificate_serial  VARCHAR,
  certificate_subject VARCHAR,
  certificate_issuer  VARCHAR,
  signed_file_path    VARCHAR,
  original_file_path  VARCHAR,
  sign_status         VARCHAR,
  error_message       TEXT,
  signed_at           TIMESTAMPTZ,
  created_at          TIMESTAMPTZ
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    ds.id,
    ds.doc_id,
    ds.doc_type,
    ds.staff_id,
    s.full_name::VARCHAR AS staff_name,
    ds.sign_method,
    ds.certificate_serial,
    ds.certificate_subject,
    ds.certificate_issuer,
    ds.signed_file_path,
    ds.original_file_path,
    ds.sign_status,
    ds.error_message,
    ds.signed_at,
    ds.created_at
  FROM edoc.digital_signatures ds
  JOIN public.staff s ON s.id = ds.staff_id
  WHERE ds.doc_id = p_doc_id
    AND ds.doc_type = p_doc_type
  ORDER BY ds.created_at DESC;
END;
$$;

-- ==========================================
-- 5. FN: LAY CHU KY SO THEO ID
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_digital_signature_get_by_id(
  p_id BIGINT
)
RETURNS TABLE (
  id                  BIGINT,
  doc_id              BIGINT,
  doc_type            VARCHAR,
  staff_id            INT,
  staff_name          VARCHAR,
  sign_method         VARCHAR,
  certificate_serial  VARCHAR,
  certificate_subject VARCHAR,
  certificate_issuer  VARCHAR,
  signed_file_path    VARCHAR,
  original_file_path  VARCHAR,
  sign_status         VARCHAR,
  error_message       TEXT,
  signed_at           TIMESTAMPTZ,
  created_at          TIMESTAMPTZ
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    ds.id,
    ds.doc_id,
    ds.doc_type,
    ds.staff_id,
    s.full_name::VARCHAR AS staff_name,
    ds.sign_method,
    ds.certificate_serial,
    ds.certificate_subject,
    ds.certificate_issuer,
    ds.signed_file_path,
    ds.original_file_path,
    ds.sign_status,
    ds.error_message,
    ds.signed_at,
    ds.created_at
  FROM edoc.digital_signatures ds
  JOIN public.staff s ON s.id = ds.staff_id
  WHERE ds.id = p_id;
END;
$$;

-- ================================================================
-- Source: 021_sprint16_notifications.sql
-- ================================================================

-- ================================================================
-- MIGRATION 021: Sprint 16 — Thong bao da kenh (Notifications)
-- Schema: edoc
-- Tables: edoc.device_tokens, edoc.notification_logs, edoc.notification_preferences
-- Functions: 8 stored functions
-- ================================================================

-- ==========================================
-- 1. BANG DEVICE TOKEN (device_tokens)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.device_tokens (
  id           BIGSERIAL PRIMARY KEY,
  staff_id     INT NOT NULL REFERENCES public.staff(id),
  device_token VARCHAR(500) NOT NULL,
  device_type  VARCHAR(20) DEFAULT 'web' CHECK(device_type IN ('web', 'android', 'ios')),
  is_active    BOOLEAN DEFAULT true,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT uq_device_token UNIQUE(device_token)
);

CREATE INDEX IF NOT EXISTS idx_device_tokens_staff ON edoc.device_tokens(staff_id);

COMMENT ON TABLE edoc.device_tokens IS 'FCM device tokens cho push notification';

-- ==========================================
-- 2. BANG LOG THONG BAO (notification_logs)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.notification_logs (
  id            BIGSERIAL PRIMARY KEY,
  staff_id      INT NOT NULL REFERENCES public.staff(id),
  channel       VARCHAR(20) NOT NULL CHECK(channel IN ('fcm', 'zalo', 'sms', 'email')),
  event_type    VARCHAR(50) NOT NULL,
  title         VARCHAR(500),
  body          TEXT,
  ref_type      VARCHAR(30),
  ref_id        BIGINT,
  send_status   VARCHAR(20) NOT NULL DEFAULT 'pending'
                CHECK(send_status IN ('pending', 'sent', 'failed')),
  error_message TEXT,
  sent_at       TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notif_log_staff ON edoc.notification_logs(staff_id);
CREATE INDEX IF NOT EXISTS idx_notif_log_channel ON edoc.notification_logs(channel);
CREATE INDEX IF NOT EXISTS idx_notif_log_status ON edoc.notification_logs(send_status);
CREATE INDEX IF NOT EXISTS idx_notif_log_created ON edoc.notification_logs(created_at DESC);

COMMENT ON TABLE edoc.notification_logs IS 'Log tat ca thong bao gui qua cac kenh (FCM, Zalo, SMS, Email)';

-- ==========================================
-- 3. BANG CAU HINH THONG BAO (notification_preferences)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.notification_preferences (
  id         BIGSERIAL PRIMARY KEY,
  staff_id   INT NOT NULL REFERENCES public.staff(id),
  channel    VARCHAR(20) NOT NULL CHECK(channel IN ('fcm', 'zalo', 'sms', 'email')),
  is_enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT uq_notif_pref_staff_channel UNIQUE(staff_id, channel)
);

COMMENT ON TABLE edoc.notification_preferences IS 'Cau hinh kenh thong bao theo user';

-- ==========================================
-- 4. FN: UPSERT DEVICE TOKEN
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_device_token_upsert(
  p_staff_id     INT,
  p_device_token VARCHAR,
  p_device_type  VARCHAR DEFAULT 'web'
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT,
  id      BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
  v_id BIGINT;
BEGIN
  INSERT INTO edoc.device_tokens (staff_id, device_token, device_type, updated_at)
  VALUES (p_staff_id, p_device_token, p_device_type, NOW())
  ON CONFLICT (device_token) DO UPDATE SET
    staff_id    = EXCLUDED.staff_id,
    device_type = EXCLUDED.device_type,
    is_active   = true,
    updated_at  = NOW()
  RETURNING edoc.device_tokens.id INTO v_id;

  RETURN QUERY SELECT true, 'Luu device token thanh cong'::TEXT, v_id;
END;
$$;

-- ==========================================
-- 5. FN: LAY DEVICE TOKEN THEO STAFF
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_device_token_get_by_staff(
  p_staff_id INT
)
RETURNS TABLE (
  id           BIGINT,
  device_token VARCHAR,
  device_type  VARCHAR,
  is_active    BOOLEAN,
  created_at   TIMESTAMPTZ
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    dt.id,
    dt.device_token,
    dt.device_type,
    dt.is_active,
    dt.created_at
  FROM edoc.device_tokens dt
  WHERE dt.staff_id = p_staff_id
    AND dt.is_active = true
  ORDER BY dt.created_at DESC;
END;
$$;

-- ==========================================
-- 6. FN: XOA DEVICE TOKEN
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_device_token_delete(
  p_id       BIGINT,
  p_staff_id INT
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT
)
LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM edoc.device_tokens
  WHERE id = p_id AND staff_id = p_staff_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Khong tim thay device token'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Xoa device token thanh cong'::TEXT;
END;
$$;

-- ==========================================
-- 7. FN: TAO LOG THONG BAO
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_notification_log_create(
  p_staff_id   INT,
  p_channel    VARCHAR,
  p_event_type VARCHAR,
  p_title      VARCHAR DEFAULT NULL,
  p_body       TEXT DEFAULT NULL,
  p_ref_type   VARCHAR DEFAULT NULL,
  p_ref_id     BIGINT DEFAULT NULL
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT,
  id      BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
  v_id BIGINT;
BEGIN
  INSERT INTO edoc.notification_logs (
    staff_id, channel, event_type, title, body, ref_type, ref_id
  )
  VALUES (
    p_staff_id, p_channel, p_event_type, p_title, p_body, p_ref_type, p_ref_id
  )
  RETURNING edoc.notification_logs.id INTO v_id;

  RETURN QUERY SELECT true, 'Tao log thong bao thanh cong'::TEXT, v_id;
END;
$$;

-- ==========================================
-- 8. FN: CAP NHAT TRANG THAI THONG BAO
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_notification_log_update_status(
  p_id            BIGINT,
  p_send_status   VARCHAR,
  p_error_message TEXT DEFAULT NULL
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT
)
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE edoc.notification_logs
  SET send_status   = p_send_status,
      error_message = p_error_message,
      sent_at       = CASE WHEN p_send_status = 'sent' THEN NOW() ELSE sent_at END
  WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Khong tim thay log thong bao'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cap nhat trang thai thong bao thanh cong'::TEXT;
END;
$$;

-- ==========================================
-- 9. FN: DANH SACH LOG THONG BAO
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_notification_log_get_list(
  p_staff_id    INT DEFAULT NULL,
  p_channel     VARCHAR DEFAULT NULL,
  p_send_status VARCHAR DEFAULT NULL,
  p_page        INT DEFAULT 1,
  p_page_size   INT DEFAULT 20
)
RETURNS TABLE (
  id            BIGINT,
  staff_id      INT,
  channel       VARCHAR,
  event_type    VARCHAR,
  title         VARCHAR,
  body          TEXT,
  ref_type      VARCHAR,
  ref_id        BIGINT,
  send_status   VARCHAR,
  error_message TEXT,
  sent_at       TIMESTAMPTZ,
  created_at    TIMESTAMPTZ,
  total_count   BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
  v_offset INT := (p_page - 1) * p_page_size;
  v_total  BIGINT;
BEGIN
  SELECT COUNT(*) INTO v_total
  FROM edoc.notification_logs nl
  WHERE (p_staff_id IS NULL OR nl.staff_id = p_staff_id)
    AND (p_channel IS NULL OR p_channel = '' OR nl.channel = p_channel)
    AND (p_send_status IS NULL OR p_send_status = '' OR nl.send_status = p_send_status);

  RETURN QUERY
  SELECT
    nl.id,
    nl.staff_id,
    nl.channel,
    nl.event_type,
    nl.title,
    nl.body,
    nl.ref_type,
    nl.ref_id,
    nl.send_status,
    nl.error_message,
    nl.sent_at,
    nl.created_at,
    v_total
  FROM edoc.notification_logs nl
  WHERE (p_staff_id IS NULL OR nl.staff_id = p_staff_id)
    AND (p_channel IS NULL OR p_channel = '' OR nl.channel = p_channel)
    AND (p_send_status IS NULL OR p_send_status = '' OR nl.send_status = p_send_status)
  ORDER BY nl.created_at DESC
  LIMIT p_page_size OFFSET v_offset;
END;
$$;

-- ==========================================
-- 10. FN: UPSERT CAU HINH THONG BAO
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_notification_pref_upsert(
  p_staff_id   INT,
  p_channel    VARCHAR,
  p_is_enabled BOOLEAN DEFAULT true
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT,
  id      BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
  v_id BIGINT;
BEGIN
  INSERT INTO edoc.notification_preferences (staff_id, channel, is_enabled, updated_at)
  VALUES (p_staff_id, p_channel, p_is_enabled, NOW())
  ON CONFLICT (staff_id, channel) DO UPDATE SET
    is_enabled = EXCLUDED.is_enabled,
    updated_at = NOW()
  RETURNING edoc.notification_preferences.id INTO v_id;

  RETURN QUERY SELECT true, 'Cap nhat cau hinh thong bao thanh cong'::TEXT, v_id;
END;
$$;

-- ==========================================
-- 11. FN: LAY CAU HINH THONG BAO THEO STAFF
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_notification_pref_get_by_staff(
  p_staff_id INT
)
RETURNS TABLE (
  id         BIGINT,
  channel    VARCHAR,
  is_enabled BOOLEAN
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    np.id,
    np.channel,
    np.is_enabled
  FROM edoc.notification_preferences np
  WHERE np.staff_id = p_staff_id
  ORDER BY np.channel;
END;
$$;

-- ================================================================
-- Source: 022_doc_module_fixes.sql
-- ================================================================

-- ============================================================================
-- Migration 022: Doc Module Fixes — Schema Changes + SP Updates
-- Ngay: 2026-04-16
-- Muc dich: Hoan thien 5 module VB den/di/du thao/lien thong/danh dau
-- ============================================================================

BEGIN;

-- ============================================================================
-- BATCH 1: SCHEMA CHANGES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1.1 incoming_docs — Them cot "Noi gui" va "Ngay nhan ban giay"
-- ----------------------------------------------------------------------------
ALTER TABLE edoc.incoming_docs ADD COLUMN IF NOT EXISTS sents TEXT;
COMMENT ON COLUMN edoc.incoming_docs.sents IS 'Noi gui van ban (source cu: Sents)';

ALTER TABLE edoc.incoming_docs ADD COLUMN IF NOT EXISTS received_paper_date TIMESTAMPTZ;
COMMENT ON COLUMN edoc.incoming_docs.received_paper_date IS 'Ngay nhan ban giay (chi co khi is_received_paper=true)';

-- ----------------------------------------------------------------------------
-- 1.2 leader_notes — Mo rong cho VB di + VB du thao
-- Hien tai chi co incoming_doc_id NOT NULL — can nullable + them 2 cot moi
-- ----------------------------------------------------------------------------
ALTER TABLE edoc.leader_notes ALTER COLUMN incoming_doc_id DROP NOT NULL;

ALTER TABLE edoc.leader_notes ADD COLUMN IF NOT EXISTS outgoing_doc_id BIGINT
  REFERENCES edoc.outgoing_docs(id) ON DELETE CASCADE;

ALTER TABLE edoc.leader_notes ADD COLUMN IF NOT EXISTS drafting_doc_id BIGINT
  REFERENCES edoc.drafting_docs(id) ON DELETE CASCADE;

-- Constraint: dung 1 trong 3 doc_id duoc co gia tri (XOR)
-- Drop truoc neu ton tai (cho phep chay lai)
ALTER TABLE edoc.leader_notes DROP CONSTRAINT IF EXISTS chk_leader_note_doc_type;
ALTER TABLE edoc.leader_notes ADD CONSTRAINT chk_leader_note_doc_type
  CHECK (
    (incoming_doc_id IS NOT NULL)::int +
    (outgoing_doc_id IS NOT NULL)::int +
    (drafting_doc_id IS NOT NULL)::int = 1
  );

-- Index cho cac cot moi
CREATE INDEX IF NOT EXISTS idx_leader_notes_outgoing ON edoc.leader_notes(outgoing_doc_id)
  WHERE outgoing_doc_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_leader_notes_drafting ON edoc.leader_notes(drafting_doc_id)
  WHERE drafting_doc_id IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 1.3 staff_notes — Them is_important (danh dau quan trong)
-- ----------------------------------------------------------------------------
ALTER TABLE edoc.staff_notes ADD COLUMN IF NOT EXISTS is_important BOOLEAN DEFAULT false;
COMMENT ON COLUMN edoc.staff_notes.is_important IS 'Danh dau quan trong (source cu: IsImportant)';

-- ----------------------------------------------------------------------------
-- 1.4 drafting_docs — Them reject_reason (ly do tu choi)
-- ----------------------------------------------------------------------------
ALTER TABLE edoc.drafting_docs ADD COLUMN IF NOT EXISTS reject_reason TEXT;
COMMENT ON COLUMN edoc.drafting_docs.reject_reason IS 'Ly do tu choi (ghi boi nguoi tu choi)';

-- ----------------------------------------------------------------------------
-- 1.5 Attachment tables — Them description cho 3 bang
-- Source cu co FileDescription, moi thieu
-- ----------------------------------------------------------------------------
ALTER TABLE edoc.attachment_incoming_docs ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE edoc.attachment_outgoing_docs ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE edoc.attachment_drafting_docs ADD COLUMN IF NOT EXISTS description TEXT;

COMMENT ON COLUMN edoc.attachment_incoming_docs.description IS 'Mo ta file dinh kem';
COMMENT ON COLUMN edoc.attachment_outgoing_docs.description IS 'Mo ta file dinh kem';
COMMENT ON COLUMN edoc.attachment_drafting_docs.description IS 'Mo ta file dinh kem';

-- ----------------------------------------------------------------------------
-- 1.6 user_outgoing_docs + user_drafting_docs — Them tracking columns
-- Source cu co: UserSend, ExpiredDate — moi thieu
-- ----------------------------------------------------------------------------
ALTER TABLE edoc.user_outgoing_docs ADD COLUMN IF NOT EXISTS sent_by INTEGER
  REFERENCES staff(id);
ALTER TABLE edoc.user_outgoing_docs ADD COLUMN IF NOT EXISTS expired_date TIMESTAMPTZ;

COMMENT ON COLUMN edoc.user_outgoing_docs.sent_by IS 'Nguoi gui (staff_id)';
COMMENT ON COLUMN edoc.user_outgoing_docs.expired_date IS 'Han xu ly per-person';

ALTER TABLE edoc.user_drafting_docs ADD COLUMN IF NOT EXISTS sent_by INTEGER
  REFERENCES staff(id);
ALTER TABLE edoc.user_drafting_docs ADD COLUMN IF NOT EXISTS expired_date TIMESTAMPTZ;

COMMENT ON COLUMN edoc.user_drafting_docs.sent_by IS 'Nguoi gui (staff_id)';
COMMENT ON COLUMN edoc.user_drafting_docs.expired_date IS 'Han xu ly per-person';

-- ----------------------------------------------------------------------------
-- 1.7 inter_incoming_docs — Them truong LGSP + thong tin bo sung
-- Source cu co nhieu truong: OrganID, FromOrganID, Priority, PageAmount...
-- ----------------------------------------------------------------------------
ALTER TABLE edoc.inter_incoming_docs ADD COLUMN IF NOT EXISTS organ_id VARCHAR(100);
COMMENT ON COLUMN edoc.inter_incoming_docs.organ_id IS 'Ma don vi gui (LGSP OrganID)';

ALTER TABLE edoc.inter_incoming_docs ADD COLUMN IF NOT EXISTS from_organ_id VARCHAR(100);
COMMENT ON COLUMN edoc.inter_incoming_docs.from_organ_id IS 'Ma don vi nhan (LGSP FromOrganID)';

ALTER TABLE edoc.inter_incoming_docs ADD COLUMN IF NOT EXISTS number_paper INTEGER DEFAULT 1;
ALTER TABLE edoc.inter_incoming_docs ADD COLUMN IF NOT EXISTS number_copies INTEGER DEFAULT 1;
ALTER TABLE edoc.inter_incoming_docs ADD COLUMN IF NOT EXISTS secret_id SMALLINT DEFAULT 1;
ALTER TABLE edoc.inter_incoming_docs ADD COLUMN IF NOT EXISTS urgent_id SMALLINT DEFAULT 1;
ALTER TABLE edoc.inter_incoming_docs ADD COLUMN IF NOT EXISTS recipients TEXT;

ALTER TABLE edoc.inter_incoming_docs ADD COLUMN IF NOT EXISTS doc_field_id INTEGER
  REFERENCES edoc.doc_fields(id);

-- Index cho LGSP lookup
CREATE INDEX IF NOT EXISTS idx_inter_incoming_organ ON edoc.inter_incoming_docs(organ_id)
  WHERE organ_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_inter_incoming_external ON edoc.inter_incoming_docs(external_doc_id)
  WHERE external_doc_id IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 1.8 Tao bang attachment_inter_incoming_docs
-- Source cu co AttachmentInterIncomingDoc — moi thieu hoan toan
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS edoc.attachment_inter_incoming_docs (
  id            BIGSERIAL PRIMARY KEY,
  inter_incoming_doc_id BIGINT NOT NULL
    REFERENCES edoc.inter_incoming_docs(id) ON DELETE CASCADE,
  file_name     VARCHAR(500) NOT NULL,
  file_path     VARCHAR(1000) NOT NULL,
  file_size     BIGINT DEFAULT 0,
  content_type  VARCHAR(100),
  description   TEXT,
  sort_order    INTEGER DEFAULT 0,
  created_by    INTEGER REFERENCES staff(id),
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_attach_inter_incoming_doc
  ON edoc.attachment_inter_incoming_docs(inter_incoming_doc_id);

COMMENT ON TABLE edoc.attachment_inter_incoming_docs
  IS 'File dinh kem VB lien thong (tu LGSP hoac upload thu cong)';

-- ============================================================================
-- Ket thuc Batch 1
-- ============================================================================

DO $$ BEGIN
  RAISE NOTICE '✅ Migration 022 — Batch 1: Schema changes applied';
  RAISE NOTICE '   incoming_docs: +sents, +received_paper_date';
  RAISE NOTICE '   leader_notes: +outgoing_doc_id, +drafting_doc_id (nullable incoming_doc_id)';
  RAISE NOTICE '   staff_notes: +is_important';
  RAISE NOTICE '   drafting_docs: +reject_reason';
  RAISE NOTICE '   attachment_*_docs: +description (3 tables)';
  RAISE NOTICE '   user_outgoing/drafting_docs: +sent_by, +expired_date';
  RAISE NOTICE '   inter_incoming_docs: +organ_id, +from_organ_id, +number_paper, +number_copies, +secret_id, +urgent_id, +recipients, +doc_field_id';
  RAISE NOTICE '   NEW TABLE: attachment_inter_incoming_docs';
END $$;

COMMIT;

-- ============================================================================
-- BATCH 2: STORED PROCEDURE UPDATES
-- ============================================================================

BEGIN;

-- ============================================================================
-- DROP functions có RETURNS TABLE thay đổi (CREATE OR REPLACE không cho đổi)
-- ============================================================================
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_get_by_id(BIGINT, INT);
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_create(INT, TIMESTAMPTZ, INT, VARCHAR, VARCHAR, TEXT, VARCHAR, TIMESTAMPTZ, VARCHAR, TIMESTAMPTZ, INT, INT, INT, SMALLINT, SMALLINT, INT, INT, TIMESTAMPTZ, TEXT, BOOLEAN, INT);
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_update(BIGINT, TIMESTAMPTZ, INT, VARCHAR, VARCHAR, TEXT, VARCHAR, TIMESTAMPTZ, VARCHAR, TIMESTAMPTZ, INT, INT, INT, SMALLINT, SMALLINT, INT, INT, TIMESTAMPTZ, TEXT, BOOLEAN, INT);
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_receive_paper(BIGINT, INT);
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_get_list(INT, INT, INT, INT, INT, SMALLINT, BOOLEAN, BOOLEAN, TIMESTAMPTZ, TIMESTAMPTZ, TEXT, INT, INT);
DROP FUNCTION IF EXISTS edoc.fn_outgoing_doc_get_by_id(BIGINT, INT);
DROP FUNCTION IF EXISTS edoc.fn_outgoing_doc_retract(BIGINT, INT);
DROP FUNCTION IF EXISTS edoc.fn_outgoing_doc_send(BIGINT, INT[], INT);
DROP FUNCTION IF EXISTS edoc.fn_drafting_doc_get_by_id(BIGINT, INT);
DROP FUNCTION IF EXISTS edoc.fn_drafting_doc_reject(BIGINT, INT, TEXT);
DROP FUNCTION IF EXISTS edoc.fn_drafting_doc_retract(BIGINT, INT);
DROP FUNCTION IF EXISTS edoc.fn_drafting_doc_send(BIGINT, INT[], INT);
DROP FUNCTION IF EXISTS edoc.fn_inter_incoming_get_by_id(BIGINT);
DROP FUNCTION IF EXISTS edoc.fn_inter_incoming_get_list(INT, TEXT, TEXT, DATE, DATE, INT, INT);
DROP FUNCTION IF EXISTS edoc.fn_staff_note_toggle(VARCHAR, BIGINT, INT, TEXT);
DROP FUNCTION IF EXISTS edoc.fn_staff_note_get_list(INT, VARCHAR);

-- ############################################################################
-- VĂN BẢN ĐẾN — SP Updates
-- ############################################################################

-- ----------------------------------------------------------------------------
-- 2.1 fn_incoming_doc_get_by_id — Thêm: is_inter_doc, inter_doc_id, sents, received_paper_date
-- BUG CŨ: thiếu is_inter_doc → nút "Nhận bàn giao" không hiển thị
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_get_by_id(
  p_id        BIGINT,
  p_staff_id  INT
)
RETURNS TABLE (
  id              BIGINT,
  unit_id         INT,
  received_date   TIMESTAMPTZ,
  number          INT,
  notation        VARCHAR,
  document_code   VARCHAR,
  abstract        TEXT,
  publish_unit    VARCHAR,
  publish_date    TIMESTAMPTZ,
  signer          VARCHAR,
  sign_date       TIMESTAMPTZ,
  doc_book_id     INT,
  doc_type_id     INT,
  doc_field_id    INT,
  secret_id       SMALLINT,
  urgent_id       SMALLINT,
  number_paper    INT,
  number_copies   INT,
  expired_date    TIMESTAMPTZ,
  recipients      TEXT,
  sents           TEXT,                  -- MỚI
  approver        VARCHAR,
  approved        BOOLEAN,
  is_handling     BOOLEAN,
  is_received_paper BOOLEAN,
  received_paper_date TIMESTAMPTZ,       -- MỚI
  archive_status  BOOLEAN,
  is_inter_doc    BOOLEAN,               -- MỚI (đã có trong bảng, thiếu trong SP cũ)
  inter_doc_id    INT,                   -- MỚI
  created_by      INT,
  created_at      TIMESTAMPTZ,
  updated_by      INT,
  updated_at      TIMESTAMPTZ,
  -- Joined
  doc_book_name   VARCHAR,
  doc_type_name   VARCHAR,
  doc_type_code   VARCHAR,
  doc_field_name  VARCHAR,
  created_by_name VARCHAR,
  is_read         BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
  -- Đánh dấu đã đọc
  PERFORM edoc.fn_incoming_doc_mark_read(p_id, p_staff_id);

  RETURN QUERY
  SELECT
    d.id, d.unit_id, d.received_date, d.number, d.notation, d.document_code,
    d.abstract, d.publish_unit, d.publish_date, d.signer, d.sign_date,
    d.doc_book_id, d.doc_type_id, d.doc_field_id, d.secret_id, d.urgent_id,
    d.number_paper, d.number_copies, d.expired_date, d.recipients,
    d.sents,                                    -- MỚI
    d.approver, d.approved, d.is_handling, d.is_received_paper,
    d.received_paper_date,                      -- MỚI
    d.archive_status,
    d.is_inter_doc,                             -- MỚI
    d.inter_doc_id,                             -- MỚI
    d.created_by, d.created_at, d.updated_by, d.updated_at,
    db.name, dt.name, dt.code, df.name, s.full_name,
    TRUE  -- đã mark read ở trên
  FROM edoc.incoming_docs d
  LEFT JOIN edoc.doc_books db ON db.id = d.doc_book_id
  LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
  LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id
  LEFT JOIN public.staff s ON s.id = d.created_by
  WHERE d.id = p_id;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2.2 fn_incoming_doc_create — Thêm p_sents
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_create(
  p_unit_id         INT,
  p_received_date   TIMESTAMPTZ,
  p_number          INT,
  p_notation        VARCHAR,
  p_document_code   VARCHAR,
  p_abstract        TEXT,
  p_publish_unit    VARCHAR,
  p_publish_date    TIMESTAMPTZ,
  p_signer          VARCHAR,
  p_sign_date       TIMESTAMPTZ,
  p_doc_book_id     INT,
  p_doc_type_id     INT,
  p_doc_field_id    INT,
  p_secret_id       SMALLINT DEFAULT 1,
  p_urgent_id       SMALLINT DEFAULT 1,
  p_number_paper    INT DEFAULT 1,
  p_number_copies   INT DEFAULT 1,
  p_expired_date    TIMESTAMPTZ DEFAULT NULL,
  p_recipients      TEXT DEFAULT NULL,
  p_sents           TEXT DEFAULT NULL,           -- MỚI
  p_is_received_paper BOOLEAN DEFAULT FALSE,
  p_created_by      INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE v_id BIGINT;
BEGIN
  IF p_abstract IS NULL OR TRIM(p_abstract) = '' THEN
    RETURN QUERY SELECT FALSE, 'Trích yếu nội dung không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  IF p_doc_book_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Sổ văn bản là bắt buộc'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  IF p_number IS NULL OR p_number = 0 THEN
    p_number := edoc.fn_incoming_doc_get_next_number(p_doc_book_id, p_unit_id);
  END IF;

  INSERT INTO edoc.incoming_docs (
    unit_id, received_date, number, notation, document_code,
    abstract, publish_unit, publish_date, signer, sign_date,
    doc_book_id, doc_type_id, doc_field_id, secret_id, urgent_id,
    number_paper, number_copies, expired_date, recipients, sents,
    is_received_paper, created_by, updated_by
  ) VALUES (
    p_unit_id, COALESCE(p_received_date, NOW()), p_number, NULLIF(TRIM(p_notation), ''), NULLIF(TRIM(p_document_code), ''),
    TRIM(p_abstract), NULLIF(TRIM(p_publish_unit), ''), p_publish_date, NULLIF(TRIM(p_signer), ''), p_sign_date,
    p_doc_book_id, p_doc_type_id, p_doc_field_id, COALESCE(p_secret_id, 1), COALESCE(p_urgent_id, 1),
    COALESCE(p_number_paper, 1), COALESCE(p_number_copies, 1), p_expired_date, NULLIF(TRIM(p_recipients), ''),
    NULLIF(TRIM(p_sents), ''),
    COALESCE(p_is_received_paper, FALSE), p_created_by, p_created_by
  )
  RETURNING edoc.incoming_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tạo văn bản đến thành công'::TEXT, v_id;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2.2 fn_incoming_doc_update — Thêm p_sents
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_update(
  p_id              BIGINT,
  p_received_date   TIMESTAMPTZ,
  p_number          INT,
  p_notation        VARCHAR,
  p_document_code   VARCHAR,
  p_abstract        TEXT,
  p_publish_unit    VARCHAR,
  p_publish_date    TIMESTAMPTZ,
  p_signer          VARCHAR,
  p_sign_date       TIMESTAMPTZ,
  p_doc_book_id     INT,
  p_doc_type_id     INT,
  p_doc_field_id    INT,
  p_secret_id       SMALLINT DEFAULT 1,
  p_urgent_id       SMALLINT DEFAULT 1,
  p_number_paper    INT DEFAULT 1,
  p_number_copies   INT DEFAULT 1,
  p_expired_date    TIMESTAMPTZ DEFAULT NULL,
  p_recipients      TEXT DEFAULT NULL,
  p_sents           TEXT DEFAULT NULL,           -- MỚI
  p_is_received_paper BOOLEAN DEFAULT FALSE,
  p_updated_by      INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_approved BOOLEAN;
BEGIN
  SELECT approved INTO v_approved FROM edoc.incoming_docs WHERE edoc.incoming_docs.id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đến'::TEXT;
    RETURN;
  END IF;
  IF v_approved = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Không thể sửa văn bản đã được duyệt'::TEXT;
    RETURN;
  END IF;

  IF p_abstract IS NULL OR TRIM(p_abstract) = '' THEN
    RETURN QUERY SELECT FALSE, 'Trích yếu nội dung không được để trống'::TEXT;
    RETURN;
  END IF;

  IF p_doc_book_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Sổ văn bản là bắt buộc'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.incoming_docs SET
    received_date   = COALESCE(p_received_date, received_date),
    number          = COALESCE(p_number, number),
    notation        = NULLIF(TRIM(p_notation), ''),
    document_code   = NULLIF(TRIM(p_document_code), ''),
    abstract        = TRIM(p_abstract),
    publish_unit    = NULLIF(TRIM(p_publish_unit), ''),
    publish_date    = p_publish_date,
    signer          = NULLIF(TRIM(p_signer), ''),
    sign_date       = p_sign_date,
    doc_book_id     = p_doc_book_id,
    doc_type_id     = p_doc_type_id,
    doc_field_id    = p_doc_field_id,
    secret_id       = COALESCE(p_secret_id, 1),
    urgent_id       = COALESCE(p_urgent_id, 1),
    number_paper    = COALESCE(p_number_paper, 1),
    number_copies   = COALESCE(p_number_copies, 1),
    expired_date    = p_expired_date,
    recipients      = NULLIF(TRIM(p_recipients), ''),
    sents           = NULLIF(TRIM(p_sents), ''),       -- MỚI
    is_received_paper = COALESCE(p_is_received_paper, FALSE),
    updated_by      = p_updated_by,
    updated_at      = NOW()
  WHERE edoc.incoming_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Cập nhật văn bản đến thành công'::TEXT;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2.3 fn_incoming_doc_receive_paper — Thêm p_received_paper_date
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_receive_paper(
  p_id                  BIGINT,
  p_staff_id            INT,
  p_received_paper_date TIMESTAMPTZ DEFAULT NULL    -- MỚI
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE edoc.incoming_docs SET
    is_received_paper = TRUE,
    received_paper_date = COALESCE(p_received_paper_date, NOW()),  -- MỚI
    updated_by = p_staff_id,
    updated_at = NOW()
  WHERE edoc.incoming_docs.id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đến'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, 'Đã xác nhận nhận bản giấy'::TEXT;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2.4 fn_incoming_doc_get_list — Thêm filter: signer, from_number, to_number
--     Thêm output: sents
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_get_list(
  p_unit_id       INT,
  p_staff_id      INT,
  p_doc_book_id   INT       DEFAULT NULL,
  p_doc_type_id   INT       DEFAULT NULL,
  p_doc_field_id  INT       DEFAULT NULL,
  p_urgent_id     SMALLINT  DEFAULT NULL,
  p_is_read       BOOLEAN   DEFAULT NULL,
  p_approved      BOOLEAN   DEFAULT NULL,
  p_from_date     TIMESTAMPTZ DEFAULT NULL,
  p_to_date       TIMESTAMPTZ DEFAULT NULL,
  p_keyword       TEXT      DEFAULT NULL,
  p_signer        TEXT      DEFAULT NULL,          -- MỚI
  p_from_number   INT       DEFAULT NULL,          -- MỚI
  p_to_number     INT       DEFAULT NULL,          -- MỚI
  p_page          INT       DEFAULT 1,
  p_page_size     INT       DEFAULT 20
)
RETURNS TABLE (
  id              BIGINT,
  unit_id         INT,
  received_date   TIMESTAMPTZ,
  number          INT,
  notation        VARCHAR,
  document_code   VARCHAR,
  abstract        TEXT,
  publish_unit    VARCHAR,
  publish_date    TIMESTAMPTZ,
  signer          VARCHAR,
  sign_date       TIMESTAMPTZ,
  doc_book_id     INT,
  doc_type_id     INT,
  doc_field_id    INT,
  secret_id       SMALLINT,
  urgent_id       SMALLINT,
  number_paper    INT,
  number_copies   INT,
  expired_date    TIMESTAMPTZ,
  recipients      TEXT,
  sents           TEXT,                            -- MỚI
  approver        VARCHAR,
  approved        BOOLEAN,
  is_handling     BOOLEAN,
  is_received_paper BOOLEAN,
  archive_status  BOOLEAN,
  created_by      INT,
  created_at      TIMESTAMPTZ,
  -- Joined fields
  doc_book_name   VARCHAR,
  doc_type_name   VARCHAR,
  doc_type_code   VARCHAR,
  doc_field_name  VARCHAR,
  created_by_name VARCHAR,
  -- Read status
  is_read         BOOLEAN,
  read_at         TIMESTAMPTZ,
  -- Attachment count
  attachment_count BIGINT,
  -- Pagination
  total_count     BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_offset INT;
  v_keyword TEXT;
  v_signer TEXT;
BEGIN
  v_offset := (GREATEST(p_page, 1) - 1) * p_page_size;
  v_keyword := NULLIF(TRIM(p_keyword), '');
  v_signer := NULLIF(TRIM(p_signer), '');

  RETURN QUERY
  WITH filtered AS (
    SELECT
      d.id AS doc_id,
      d.*,
      db.name AS _doc_book_name,
      dt.name AS _doc_type_name,
      dt.code AS _doc_type_code,
      df.name AS _doc_field_name,
      s.full_name AS _created_by_name,
      uid.is_read AS _is_read,
      uid.read_at AS _read_at,
      (SELECT COUNT(*) FROM edoc.attachment_incoming_docs a WHERE a.incoming_doc_id = d.id) AS _attachment_count,
      COUNT(*) OVER() AS _total_count
    FROM edoc.incoming_docs d
    LEFT JOIN edoc.doc_books db ON db.id = d.doc_book_id
    LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
    LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id
    LEFT JOIN public.staff s ON s.id = d.created_by
    LEFT JOIN edoc.user_incoming_docs uid ON uid.incoming_doc_id = d.id AND uid.staff_id = p_staff_id
    WHERE d.unit_id = p_unit_id
      AND (p_doc_book_id IS NULL OR d.doc_book_id = p_doc_book_id)
      AND (p_doc_type_id IS NULL OR d.doc_type_id = p_doc_type_id)
      AND (p_doc_field_id IS NULL OR d.doc_field_id = p_doc_field_id)
      AND (p_urgent_id IS NULL OR d.urgent_id = p_urgent_id)
      AND (p_approved IS NULL OR d.approved = p_approved)
      AND (p_from_date IS NULL OR d.received_date >= p_from_date)
      AND (p_to_date IS NULL OR d.received_date <= p_to_date)
      AND (p_is_read IS NULL OR (p_is_read = TRUE AND uid.is_read = TRUE) OR (p_is_read = FALSE AND (uid.is_read IS NULL OR uid.is_read = FALSE)))
      AND (v_signer IS NULL OR d.signer ILIKE '%' || v_signer || '%')                  -- MỚI
      AND (p_from_number IS NULL OR d.number >= p_from_number)                          -- MỚI
      AND (p_to_number IS NULL OR d.number <= p_to_number)                              -- MỚI
      AND (v_keyword IS NULL OR
           d.abstract ILIKE '%' || v_keyword || '%' OR
           d.notation ILIKE '%' || v_keyword || '%' OR
           d.publish_unit ILIKE '%' || v_keyword || '%' OR
           d.signer ILIKE '%' || v_keyword || '%' OR
           d.document_code ILIKE '%' || v_keyword || '%'
      )
    ORDER BY d.received_date DESC, d.number DESC
    LIMIT p_page_size OFFSET v_offset
  )
  SELECT
    f.doc_id,
    f.unit_id,
    f.received_date,
    f.number,
    f.notation,
    f.document_code,
    f.abstract,
    f.publish_unit,
    f.publish_date,
    f.signer,
    f.sign_date,
    f.doc_book_id,
    f.doc_type_id,
    f.doc_field_id,
    f.secret_id,
    f.urgent_id,
    f.number_paper,
    f.number_copies,
    f.expired_date,
    f.recipients,
    f.sents,                            -- MỚI
    f.approver,
    f.approved,
    f.is_handling,
    f.is_received_paper,
    f.archive_status,
    f.created_by,
    f.created_at,
    f._doc_book_name,
    f._doc_type_name,
    f._doc_type_code,
    f._doc_field_name,
    f._created_by_name,
    COALESCE(f._is_read, FALSE),
    f._read_at,
    f._attachment_count,
    f._total_count
  FROM filtered f;
END;
$$;


-- ############################################################################
-- VĂN BẢN ĐI — SP Updates
-- ############################################################################

-- ----------------------------------------------------------------------------
-- 2.7 fn_outgoing_doc_get_by_id — Thêm JOIN publish_unit_name
-- BUG CŨ: hiển thị "Đơn vị #N" thay vì tên
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_get_by_id(
  p_id        BIGINT,
  p_staff_id  INT
)
RETURNS TABLE (
  id              BIGINT,
  unit_id         INT,
  received_date   TIMESTAMPTZ,
  number          INT,
  sub_number      VARCHAR,
  notation        VARCHAR,
  document_code   VARCHAR,
  abstract        TEXT,
  drafting_unit_id  INT,
  drafting_user_id  INT,
  publish_unit_id   INT,
  publish_date    TIMESTAMPTZ,
  signer          VARCHAR,
  sign_date       TIMESTAMPTZ,
  expired_date    TIMESTAMPTZ,
  doc_book_id     INT,
  doc_type_id     INT,
  doc_field_id    INT,
  secret_id       SMALLINT,
  urgent_id       SMALLINT,
  number_paper    INT,
  number_copies   INT,
  recipients      TEXT,
  approver        VARCHAR,
  approved        BOOLEAN,
  is_handling     BOOLEAN,
  archive_status  BOOLEAN,
  is_inter_doc    BOOLEAN,
  is_digital_signed SMALLINT,
  created_by      INT,
  created_at      TIMESTAMPTZ,
  updated_by      INT,
  updated_at      TIMESTAMPTZ,
  -- Joined
  doc_book_name   VARCHAR,
  doc_type_name   VARCHAR,
  doc_type_code   VARCHAR,
  doc_field_name  VARCHAR,
  drafting_unit_name VARCHAR,
  drafting_user_name VARCHAR,
  publish_unit_name  VARCHAR,              -- MỚI
  created_by_name VARCHAR,
  is_read         BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
  -- Đánh dấu đã đọc
  INSERT INTO edoc.user_outgoing_docs (outgoing_doc_id, staff_id, is_read, read_at)
  VALUES (p_id, p_staff_id, TRUE, NOW())
  ON CONFLICT (outgoing_doc_id, staff_id)
  DO UPDATE SET is_read = TRUE, read_at = COALESCE(edoc.user_outgoing_docs.read_at, NOW());

  RETURN QUERY
  SELECT
    d.id, d.unit_id, d.received_date, d.number, d.sub_number,
    d.notation, d.document_code, d.abstract,
    d.drafting_unit_id, d.drafting_user_id, d.publish_unit_id, d.publish_date,
    d.signer, d.sign_date, d.expired_date,
    d.doc_book_id, d.doc_type_id, d.doc_field_id,
    d.secret_id, d.urgent_id, d.number_paper, d.number_copies,
    d.recipients, d.approver, d.approved,
    d.is_handling, d.archive_status, d.is_inter_doc, d.is_digital_signed,
    d.created_by, d.created_at, d.updated_by, d.updated_at,
    db.name, dt.name, dt.code, df.name,
    du.name, ds.full_name,
    pu.name,                                       -- MỚI: publish_unit_name
    s.full_name,
    TRUE
  FROM edoc.outgoing_docs d
  LEFT JOIN edoc.doc_books db ON db.id = d.doc_book_id
  LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
  LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id
  LEFT JOIN public.departments du ON du.id = d.drafting_unit_id
  LEFT JOIN public.staff ds ON ds.id = d.drafting_user_id
  LEFT JOIN public.departments pu ON pu.id = d.publish_unit_id    -- MỚI
  LEFT JOIN public.staff s ON s.id = d.created_by
  WHERE d.id = p_id;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2.8 fn_outgoing_doc_retract — Per-person retract
-- Nếu p_staff_ids = NULL → thu hồi tất cả (behavior cũ)
-- Nếu p_staff_ids có giá trị → chỉ thu hồi người cụ thể
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_retract(
  p_id        BIGINT,
  p_staff_id  INT,
  p_staff_ids INT[] DEFAULT NULL        -- MỚI: NULL = thu hồi tất cả
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_deleted_count INT;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.outgoing_docs WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đi'::TEXT; RETURN;
  END IF;

  IF p_staff_ids IS NULL THEN
    -- Thu hồi tất cả (trừ người thu hồi)
    DELETE FROM edoc.user_outgoing_docs WHERE outgoing_doc_id = p_id AND staff_id != p_staff_id;
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    -- Reset approved khi thu hồi toàn bộ
    UPDATE edoc.outgoing_docs SET approved = FALSE, updated_by = p_staff_id, updated_at = NOW() WHERE id = p_id;
  ELSE
    -- Thu hồi từng người cụ thể
    DELETE FROM edoc.user_outgoing_docs WHERE outgoing_doc_id = p_id AND staff_id = ANY(p_staff_ids);
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    UPDATE edoc.outgoing_docs SET updated_by = p_staff_id, updated_at = NOW() WHERE id = p_id;
  END IF;

  RETURN QUERY SELECT TRUE, ('Thu hồi thành công — đã xóa ' || v_deleted_count || ' người nhận')::TEXT;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2.9 fn_outgoing_doc_send — Thêm sent_by, expired_date
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_send(
  p_doc_id       BIGINT,
  p_staff_ids    INT[],
  p_sent_by      INT,
  p_expired_date TIMESTAMPTZ DEFAULT NULL        -- MỚI: hạn xử lý per-person
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
  v_approved BOOLEAN;
  v_count INT;
BEGIN
  SELECT approved INTO v_approved FROM edoc.outgoing_docs WHERE edoc.outgoing_docs.id = p_doc_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đi'::TEXT;
    RETURN;
  END IF;
  IF v_approved IS NULL OR v_approved = FALSE THEN
    RETURN QUERY SELECT FALSE, 'Văn bản chưa được duyệt, không thể gửi'::TEXT;
    RETURN;
  END IF;

  IF p_staff_ids IS NULL OR array_length(p_staff_ids, 1) IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Vui lòng chọn ít nhất một người nhận'::TEXT;
    RETURN;
  END IF;

  INSERT INTO edoc.user_outgoing_docs (outgoing_doc_id, staff_id, sent_by, expired_date, is_read, created_at)
  SELECT p_doc_id, unnest(p_staff_ids), p_sent_by, p_expired_date, FALSE, NOW()
  ON CONFLICT (outgoing_doc_id, staff_id) DO NOTHING;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN QUERY SELECT TRUE, ('Đã gửi cho ' || v_count || ' người nhận')::TEXT;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2.10 fn_outgoing_doc_check_number — MỚI: Kiểm tra trùng số
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_check_number(
  p_unit_id     INT,
  p_doc_book_id INT,
  p_number      INT,
  p_exclude_id  BIGINT DEFAULT NULL
)
RETURNS TABLE (is_exists BOOLEAN)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT EXISTS (
    SELECT 1 FROM edoc.outgoing_docs
    WHERE unit_id = p_unit_id
      AND doc_book_id = p_doc_book_id
      AND number = p_number
      AND EXTRACT(YEAR FROM received_date) = EXTRACT(YEAR FROM NOW())
      AND (p_exclude_id IS NULL OR id != p_exclude_id)
  );
END;
$$;

-- ----------------------------------------------------------------------------
-- 2.12 Leader notes cho VB đi — Danh sách
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_leader_note_get_by_outgoing_doc(
  p_doc_id BIGINT
)
RETURNS TABLE (
  id          BIGINT,
  staff_id    INT,
  staff_name  VARCHAR,
  position_name VARCHAR,
  content     TEXT,
  created_at  TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT ln.id, ln.staff_id, s.full_name, p.name, ln.content, ln.created_at
  FROM edoc.leader_notes ln
  JOIN public.staff s ON s.id = ln.staff_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  WHERE ln.outgoing_doc_id = p_doc_id
  ORDER BY ln.created_at DESC;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2.12 Leader notes cho VB đi — Tạo
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_leader_note_create_outgoing(
  p_doc_id    BIGINT,
  p_staff_id  INT,
  p_content   TEXT
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

  INSERT INTO edoc.leader_notes (outgoing_doc_id, staff_id, content)
  VALUES (p_doc_id, p_staff_id, TRIM(p_content))
  RETURNING edoc.leader_notes.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Thêm ý kiến thành công'::TEXT, v_id;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2.12 Leader notes cho VB đi — Xóa
-- Dùng chung fn_leader_note_delete đã có (check staff_id)
-- ----------------------------------------------------------------------------

-- ############################################################################
-- VĂN BẢN DỰ THẢO — SP Updates
-- ############################################################################

-- ----------------------------------------------------------------------------
-- 2.13 fn_drafting_doc_get_by_id — Thêm JOIN publish_unit_name + reject_reason
-- BUG CŨ: hiển thị "#ID" thay vì tên đơn vị
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_get_by_id(
  p_id        BIGINT,
  p_staff_id  INT
)
RETURNS TABLE (
  id              BIGINT,
  unit_id         INT,
  received_date   TIMESTAMPTZ,
  number          INT,
  sub_number      VARCHAR,
  notation        VARCHAR,
  document_code   VARCHAR,
  abstract        TEXT,
  drafting_unit_id  INT,
  drafting_user_id  INT,
  publish_unit_id   INT,
  publish_date    TIMESTAMPTZ,
  signer          VARCHAR,
  sign_date       TIMESTAMPTZ,
  doc_book_id     INT,
  doc_type_id     INT,
  doc_field_id    INT,
  secret_id       SMALLINT,
  urgent_id       SMALLINT,
  number_paper    INT,
  number_copies   INT,
  expired_date    TIMESTAMPTZ,
  recipients      TEXT,
  approver        VARCHAR,
  approved        BOOLEAN,
  is_released     BOOLEAN,
  released_date   TIMESTAMPTZ,
  reject_reason   TEXT,                    -- MỚI
  created_by      INT,
  created_at      TIMESTAMPTZ,
  updated_by      INT,
  updated_at      TIMESTAMPTZ,
  -- Joined
  doc_book_name   VARCHAR,
  doc_type_name   VARCHAR,
  doc_type_code   VARCHAR,
  doc_field_name  VARCHAR,
  drafting_unit_name VARCHAR,
  drafting_user_name VARCHAR,
  publish_unit_name  VARCHAR,              -- MỚI
  created_by_name VARCHAR,
  is_read         BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
  -- Đánh dấu đã đọc
  INSERT INTO edoc.user_drafting_docs (drafting_doc_id, staff_id, is_read, read_at)
  VALUES (p_id, p_staff_id, TRUE, NOW())
  ON CONFLICT (drafting_doc_id, staff_id)
  DO UPDATE SET is_read = TRUE, read_at = COALESCE(edoc.user_drafting_docs.read_at, NOW());

  RETURN QUERY
  SELECT
    d.id, d.unit_id, d.received_date, d.number, d.sub_number,
    d.notation, d.document_code, d.abstract,
    d.drafting_unit_id, d.drafting_user_id, d.publish_unit_id, d.publish_date,
    d.signer, d.sign_date, d.doc_book_id, d.doc_type_id, d.doc_field_id,
    d.secret_id, d.urgent_id, d.number_paper, d.number_copies,
    d.expired_date, d.recipients, d.approver, d.approved,
    d.is_released, d.released_date,
    d.reject_reason,                                -- MỚI
    d.created_by, d.created_at, d.updated_by, d.updated_at,
    db.name, dt.name, dt.code, df.name,
    du.name, ds.full_name,
    pu.name,                                        -- MỚI: publish_unit_name
    s.full_name,
    TRUE
  FROM edoc.drafting_docs d
  LEFT JOIN edoc.doc_books db ON db.id = d.doc_book_id
  LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
  LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id
  LEFT JOIN public.departments du ON du.id = d.drafting_unit_id
  LEFT JOIN public.staff ds ON ds.id = d.drafting_user_id
  LEFT JOIN public.departments pu ON pu.id = d.publish_unit_id    -- MỚI
  LEFT JOIN public.staff s ON s.id = d.created_by
  WHERE d.id = p_id;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2.14 fn_drafting_doc_reject — Lưu reason vào reject_reason
-- BUG CŨ: p_reason bị bỏ qua hoàn toàn
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_reject(
  p_id        BIGINT,
  p_staff_id  INT,
  p_reason    TEXT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE v_staff_name VARCHAR;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.drafting_docs WHERE edoc.drafting_docs.id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản dự thảo'::TEXT;
    RETURN;
  END IF;

  IF (SELECT is_released FROM edoc.drafting_docs WHERE edoc.drafting_docs.id = p_id) = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Không thể từ chối: văn bản đã phát hành'::TEXT;
    RETURN;
  END IF;

  SELECT full_name INTO v_staff_name FROM public.staff WHERE public.staff.id = p_staff_id;

  UPDATE edoc.drafting_docs SET
    approved = FALSE,
    approver = NULL,
    reject_reason = NULLIF(TRIM(p_reason), ''),    -- MỚI: lưu lý do
    updated_by = p_staff_id,
    updated_at = NOW()
  WHERE edoc.drafting_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Đã từ chối văn bản dự thảo'::TEXT;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2.15 fn_drafting_doc_retract — Per-person retract
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_retract(
  p_id        BIGINT,
  p_staff_id  INT,
  p_staff_ids INT[] DEFAULT NULL        -- MỚI: NULL = thu hồi tất cả
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_is_released BOOLEAN;
  v_deleted_count INT;
BEGIN
  SELECT d.is_released INTO v_is_released
  FROM edoc.drafting_docs d WHERE d.id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản dự thảo'::TEXT; RETURN;
  END IF;

  IF v_is_released THEN
    RETURN QUERY SELECT FALSE, 'Không thể thu hồi — văn bản đã phát hành'::TEXT; RETURN;
  END IF;

  IF p_staff_ids IS NULL THEN
    DELETE FROM edoc.user_drafting_docs WHERE drafting_doc_id = p_id;
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    UPDATE edoc.drafting_docs SET approved = FALSE, updated_by = p_staff_id, updated_at = NOW() WHERE id = p_id;
  ELSE
    DELETE FROM edoc.user_drafting_docs WHERE drafting_doc_id = p_id AND staff_id = ANY(p_staff_ids);
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    UPDATE edoc.drafting_docs SET updated_by = p_staff_id, updated_at = NOW() WHERE id = p_id;
  END IF;

  RETURN QUERY SELECT TRUE, ('Thu hồi thành công — đã xóa ' || v_deleted_count || ' người nhận')::TEXT;
END;
$$;

-- ----------------------------------------------------------------------------
-- Leader notes cho VB dự thảo — Danh sách
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_leader_note_get_by_drafting_doc(
  p_doc_id BIGINT
)
RETURNS TABLE (
  id          BIGINT,
  staff_id    INT,
  staff_name  VARCHAR,
  position_name VARCHAR,
  content     TEXT,
  created_at  TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT ln.id, ln.staff_id, s.full_name, p.name, ln.content, ln.created_at
  FROM edoc.leader_notes ln
  JOIN public.staff s ON s.id = ln.staff_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  WHERE ln.drafting_doc_id = p_doc_id
  ORDER BY ln.created_at DESC;
END;
$$;

-- Leader notes cho VB dự thảo — Tạo
CREATE OR REPLACE FUNCTION edoc.fn_leader_note_create_drafting(
  p_doc_id    BIGINT,
  p_staff_id  INT,
  p_content   TEXT
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

  INSERT INTO edoc.leader_notes (drafting_doc_id, staff_id, content)
  VALUES (p_doc_id, p_staff_id, TRIM(p_content))
  RETURNING edoc.leader_notes.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Thêm ý kiến thành công'::TEXT, v_id;
END;
$$;

-- ----------------------------------------------------------------------------
-- fn_drafting_doc_send — Thêm sent_by, expired_date
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_send(
  p_doc_id       BIGINT,
  p_staff_ids    INT[],
  p_sent_by      INT,
  p_expired_date TIMESTAMPTZ DEFAULT NULL        -- MỚI
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
  v_approved BOOLEAN;
  v_count INT;
BEGIN
  SELECT approved INTO v_approved FROM edoc.drafting_docs WHERE edoc.drafting_docs.id = p_doc_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản dự thảo'::TEXT;
    RETURN;
  END IF;
  IF v_approved IS NULL OR v_approved = FALSE THEN
    RETURN QUERY SELECT FALSE, 'Văn bản chưa được duyệt, không thể gửi'::TEXT;
    RETURN;
  END IF;

  IF p_staff_ids IS NULL OR array_length(p_staff_ids, 1) IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Vui lòng chọn ít nhất một người nhận'::TEXT;
    RETURN;
  END IF;

  INSERT INTO edoc.user_drafting_docs (drafting_doc_id, staff_id, sent_by, expired_date, is_read, created_at)
  SELECT p_doc_id, unnest(p_staff_ids), p_sent_by, p_expired_date, FALSE, NOW()
  ON CONFLICT (drafting_doc_id, staff_id) DO NOTHING;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN QUERY SELECT TRUE, ('Đã gửi cho ' || v_count || ' người nhận')::TEXT;
END;
$$;


-- ############################################################################
-- VĂN BẢN LIÊN THÔNG — SP Updates
-- ############################################################################

-- ----------------------------------------------------------------------------
-- 2.16 fn_inter_incoming_get_by_id — Thêm JOINs cho doc_type_name, doc_field_name, created_by_name
--      + các cột mới từ Batch 1
-- BUG CŨ: không JOIN gì, frontend hiển thị "—" hết
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_inter_incoming_get_by_id(
  p_id  BIGINT
)
RETURNS TABLE (
  id              BIGINT,
  unit_id         INT,
  received_date   TIMESTAMP,
  notation        VARCHAR,
  document_code   VARCHAR,
  abstract        TEXT,
  publish_unit    VARCHAR,
  publish_date    DATE,
  signer          VARCHAR,
  sign_date       DATE,
  expired_date    DATE,
  doc_type_id     INT,
  doc_field_id    INT,                   -- MỚI
  secret_id       SMALLINT,              -- MỚI
  urgent_id       SMALLINT,              -- MỚI
  number_paper    INT,                   -- MỚI
  number_copies   INT,                   -- MỚI
  recipients      TEXT,                  -- MỚI
  status          VARCHAR,
  source_system   VARCHAR,
  external_doc_id VARCHAR,
  organ_id        VARCHAR,               -- MỚI
  from_organ_id   VARCHAR,               -- MỚI
  created_by      INT,
  created_at      TIMESTAMP,
  updated_at      TIMESTAMP,
  -- Joined fields
  doc_type_name   VARCHAR,               -- MỚI
  doc_field_name  VARCHAR,               -- MỚI
  created_by_name VARCHAR                -- MỚI
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    d.id, d.unit_id, d.received_date, d.notation, d.document_code,
    d.abstract, d.publish_unit, d.publish_date, d.signer, d.sign_date,
    d.expired_date, d.doc_type_id,
    d.doc_field_id,                                -- MỚI
    d.secret_id,                                   -- MỚI
    d.urgent_id,                                   -- MỚI
    d.number_paper,                                -- MỚI
    d.number_copies,                               -- MỚI
    d.recipients,                                  -- MỚI
    d.status, d.source_system, d.external_doc_id,
    d.organ_id,                                    -- MỚI
    d.from_organ_id,                               -- MỚI
    d.created_by, d.created_at, d.updated_at,
    dt.name,                                       -- MỚI: doc_type_name
    df.name,                                       -- MỚI: doc_field_name
    s.full_name                                    -- MỚI: created_by_name
  FROM edoc.inter_incoming_docs d
  LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id        -- MỚI
  LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id      -- MỚI
  LEFT JOIN public.staff s ON s.id = d.created_by             -- MỚI
  WHERE d.id = p_id;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2.17 fn_inter_incoming_get_list — Thêm p_doc_type_id + joined fields
-- BUG CŨ: frontend gửi doc_type_id nhưng SP không nhận
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_inter_incoming_get_list(
  p_unit_id      INT,
  p_keyword      TEXT,
  p_status       TEXT,
  p_from_date    DATE,
  p_to_date      DATE,
  p_doc_type_id  INT DEFAULT NULL,              -- MỚI
  p_page         INT DEFAULT 1,
  p_page_size    INT DEFAULT 20
)
RETURNS TABLE (
  id              BIGINT,
  unit_id         INT,
  received_date   TIMESTAMP,
  notation        VARCHAR,
  document_code   VARCHAR,
  abstract        TEXT,
  publish_unit    VARCHAR,
  publish_date    DATE,
  signer          VARCHAR,
  sign_date       DATE,
  expired_date    DATE,
  doc_type_id     INT,
  status          VARCHAR,
  source_system   VARCHAR,
  external_doc_id VARCHAR,
  created_by      INT,
  created_at      TIMESTAMP,
  updated_at      TIMESTAMP,
  -- Joined
  doc_type_name   VARCHAR,                       -- MỚI
  created_by_name VARCHAR,                       -- MỚI
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
      d.id, d.unit_id, d.received_date, d.notation, d.document_code,
      d.abstract, d.publish_unit, d.publish_date, d.signer, d.sign_date,
      d.expired_date, d.doc_type_id, d.status, d.source_system, d.external_doc_id,
      d.created_by, d.created_at, d.updated_at,
      dt.name AS _doc_type_name,                  -- MỚI
      s.full_name AS _created_by_name             -- MỚI
    FROM edoc.inter_incoming_docs d
    LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id       -- MỚI
    LEFT JOIN public.staff s ON s.id = d.created_by            -- MỚI
    WHERE
      d.unit_id = p_unit_id
      AND (p_status IS NULL OR p_status = '' OR d.status = p_status)
      AND (p_doc_type_id IS NULL OR d.doc_type_id = p_doc_type_id)  -- MỚI
      AND (p_from_date IS NULL OR d.received_date::DATE >= p_from_date)
      AND (p_to_date IS NULL OR d.received_date::DATE <= p_to_date)
      AND (
        p_keyword IS NULL OR TRIM(p_keyword) = ''
        OR d.notation ILIKE '%' || p_keyword || '%'
        OR d.abstract ILIKE '%' || p_keyword || '%'
        OR d.publish_unit ILIKE '%' || p_keyword || '%'
      )
  )
  SELECT
    f.id, f.unit_id, f.received_date, f.notation, f.document_code,
    f.abstract, f.publish_unit, f.publish_date, f.signer, f.sign_date,
    f.expired_date, f.doc_type_id, f.status, f.source_system, f.external_doc_id,
    f.created_by, f.created_at, f.updated_at,
    f._doc_type_name,                              -- MỚI
    f._created_by_name,                            -- MỚI
    COUNT(*) OVER()::BIGINT AS total_count
  FROM filtered f
  ORDER BY f.received_date DESC NULLS LAST
  LIMIT COALESCE(p_page_size, 20)
  OFFSET v_offset;
END;
$$;


-- ############################################################################
-- BOOKMARK — SP Updates
-- ############################################################################

-- ----------------------------------------------------------------------------
-- 2.18 fn_staff_note_toggle — Thêm p_is_important
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_staff_note_toggle(
  p_doc_type      VARCHAR,
  p_doc_id        BIGINT,
  p_staff_id      INT,
  p_note          TEXT DEFAULT NULL,
  p_is_important  BOOLEAN DEFAULT FALSE          -- MỚI
)
RETURNS TABLE (success BOOLEAN, message TEXT, is_bookmarked BOOLEAN)
LANGUAGE plpgsql
AS $$
DECLARE v_exists BOOLEAN;
BEGIN
  SELECT TRUE INTO v_exists
  FROM edoc.staff_notes
  WHERE doc_type = p_doc_type AND doc_id = p_doc_id AND staff_id = p_staff_id;

  IF v_exists THEN
    DELETE FROM edoc.staff_notes
    WHERE doc_type = p_doc_type AND doc_id = p_doc_id AND staff_id = p_staff_id;
    RETURN QUERY SELECT TRUE, 'Đã bỏ đánh dấu'::TEXT, FALSE;
  ELSE
    INSERT INTO edoc.staff_notes (doc_type, doc_id, staff_id, note, is_important)
    VALUES (p_doc_type, p_doc_id, p_staff_id, NULLIF(TRIM(p_note), ''), COALESCE(p_is_important, FALSE));
    RETURN QUERY SELECT TRUE, 'Đã đánh dấu'::TEXT, TRUE;
  END IF;
END;
$$;

-- ----------------------------------------------------------------------------
-- fn_staff_note_update_important — MỚI: Toggle is_important mà không xóa bookmark
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_staff_note_update_important(
  p_doc_type      VARCHAR,
  p_doc_id        BIGINT,
  p_staff_id      INT,
  p_is_important  BOOLEAN
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE edoc.staff_notes SET
    is_important = p_is_important
  WHERE doc_type = p_doc_type AND doc_id = p_doc_id AND staff_id = p_staff_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy đánh dấu'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT TRUE,
    CASE WHEN p_is_important THEN 'Đã đánh dấu quan trọng'::TEXT
    ELSE 'Đã bỏ đánh dấu quan trọng'::TEXT END;
END;
$$;

-- ----------------------------------------------------------------------------
-- fn_staff_note_get_list — Thêm is_important vào output
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION edoc.fn_staff_note_get_list(
  p_staff_id  INT,
  p_doc_type  VARCHAR DEFAULT 'incoming'
)
RETURNS TABLE (
  note_id     BIGINT,
  doc_id      BIGINT,
  note        TEXT,
  is_important BOOLEAN,                          -- MỚI
  created_at  TIMESTAMPTZ,
  doc_number      INT,
  doc_notation    VARCHAR,
  doc_abstract    TEXT,
  doc_received_date TIMESTAMPTZ,
  doc_publish_unit  VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
  IF p_doc_type = 'incoming' THEN
    RETURN QUERY
    SELECT sn.id, sn.doc_id, sn.note, sn.is_important, sn.created_at,
           d.number, d.notation, d.abstract, d.received_date, d.publish_unit
    FROM edoc.staff_notes sn
    JOIN edoc.incoming_docs d ON d.id = sn.doc_id
    WHERE sn.staff_id = p_staff_id AND sn.doc_type = 'incoming'
    ORDER BY sn.is_important DESC, sn.created_at DESC;

  ELSIF p_doc_type = 'outgoing' THEN
    RETURN QUERY
    SELECT sn.id, sn.doc_id, sn.note, sn.is_important, sn.created_at,
           d.number, d.notation, d.abstract, d.received_date,
           COALESCE(du.name, '')::VARCHAR
    FROM edoc.staff_notes sn
    JOIN edoc.outgoing_docs d ON d.id = sn.doc_id
    LEFT JOIN public.departments du ON du.id = d.drafting_unit_id
    WHERE sn.staff_id = p_staff_id AND sn.doc_type = 'outgoing'
    ORDER BY sn.is_important DESC, sn.created_at DESC;

  ELSIF p_doc_type = 'drafting' THEN
    RETURN QUERY
    SELECT sn.id, sn.doc_id, sn.note, sn.is_important, sn.created_at,
           d.number, d.notation, d.abstract, d.received_date,
           COALESCE(du.name, '')::VARCHAR
    FROM edoc.staff_notes sn
    JOIN edoc.drafting_docs d ON d.id = sn.doc_id
    LEFT JOIN public.departments du ON du.id = d.drafting_unit_id
    WHERE sn.staff_id = p_staff_id AND sn.doc_type = 'drafting'
    ORDER BY sn.is_important DESC, sn.created_at DESC;
  END IF;
END;
$$;


-- ============================================================================
-- Kết thúc Batch 2
-- ============================================================================

DO $$ BEGIN
  RAISE NOTICE '✅ Migration 022 — Batch 2: SP updates applied';
  RAISE NOTICE '   VB đến: fn_incoming_doc_get_by_id (+is_inter_doc, sents, received_paper_date)';
  RAISE NOTICE '   VB đến: fn_incoming_doc_create/update (+sents)';
  RAISE NOTICE '   VB đến: fn_incoming_doc_receive_paper (+received_paper_date)';
  RAISE NOTICE '   VB đến: fn_incoming_doc_get_list (+signer, from/to number filters, +sents)';
  RAISE NOTICE '   VB đi:  fn_outgoing_doc_get_by_id (+publish_unit_name)';
  RAISE NOTICE '   VB đi:  fn_outgoing_doc_retract (per-person)';
  RAISE NOTICE '   VB đi:  fn_outgoing_doc_send (+sent_by, expired_date)';
  RAISE NOTICE '   VB đi:  fn_outgoing_doc_check_number (MỚI)';
  RAISE NOTICE '   VB đi:  fn_leader_note_get/create_outgoing (MỚI)';
  RAISE NOTICE '   Dự thảo: fn_drafting_doc_get_by_id (+publish_unit_name, reject_reason)';
  RAISE NOTICE '   Dự thảo: fn_drafting_doc_reject (lưu reason)';
  RAISE NOTICE '   Dự thảo: fn_drafting_doc_retract (per-person)';
  RAISE NOTICE '   Dự thảo: fn_leader_note_get/create_drafting (MỚI)';
  RAISE NOTICE '   Dự thảo: fn_drafting_doc_send (+sent_by, expired_date)';
  RAISE NOTICE '   Liên thông: fn_inter_incoming_get_by_id (+JOINs, +new columns)';
  RAISE NOTICE '   Liên thông: fn_inter_incoming_get_list (+doc_type_id, +JOINs)';
  RAISE NOTICE '   Bookmark: fn_staff_note_toggle (+is_important)';
  RAISE NOTICE '   Bookmark: fn_staff_note_update_important (MỚI)';
  RAISE NOTICE '   Bookmark: fn_staff_note_get_list (+is_important)';
END $$;

COMMIT;

-- ================================================================
-- Source: 023_doc_module_extras.sql
-- ================================================================

-- ============================================================================
-- Migration 023: Doc Module Extras
-- 1. SP lấy danh sách HSCV để link VB vào
-- 2. SP lấy số chưa phát hành VB đi
-- 3. SP giao việc từ VB đi (đã có fn_handling_doc_create_from_doc hỗ trợ 'outgoing')
-- 4. SP gửi liên thông LGSP từ VB đến/đi
-- 5. SP CRUD file đính kèm VB liên thông
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. HSCV — Lấy danh sách HSCV sẵn có để link VB
-- ============================================================================

CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_get_for_link(
  p_unit_id INT,
  p_keyword TEXT DEFAULT NULL
)
RETURNS TABLE (
  id          BIGINT,
  name        VARCHAR,
  abstract    TEXT,
  status      SMALLINT,
  start_date  TIMESTAMPTZ,
  end_date    TIMESTAMPTZ,
  curator_name VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE v_kw TEXT := NULLIF(TRIM(p_keyword), '');
BEGIN
  RETURN QUERY
  SELECT h.id, h.name::VARCHAR, h.abstract, h.status, h.start_date, h.end_date,
         s.full_name
  FROM edoc.handling_docs h
  LEFT JOIN public.staff s ON s.id = h.curator
  WHERE h.unit_id = p_unit_id
    AND h.status < 3  -- chưa hoàn thành (0=mới, 1=đang xử lý, 2=trình duyệt)
    AND (v_kw IS NULL OR h.name ILIKE '%' || v_kw || '%' OR h.abstract ILIKE '%' || v_kw || '%')
  ORDER BY h.created_at DESC
  LIMIT 50;
END;
$$;

-- ============================================================================
-- 2. VB ĐI — Lấy danh sách số chưa phát hành (cấp số rồi nhưng chưa có VB)
-- Source cũ: Prc_OutgoingDocGetNumberNotUse
-- Logic: tìm gaps trong dãy số đã cấp trong năm
-- ============================================================================

CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_get_unused_numbers(
  p_unit_id     INT,
  p_doc_book_id INT
)
RETURNS TABLE (
  unused_number INT
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_max INT;
BEGIN
  -- Lấy số lớn nhất đã cấp trong năm
  SELECT COALESCE(MAX(number), 0) INTO v_max
  FROM edoc.outgoing_docs
  WHERE unit_id = p_unit_id
    AND doc_book_id = p_doc_book_id
    AND EXTRACT(YEAR FROM received_date) = EXTRACT(YEAR FROM NOW());

  -- Trả về các số bị bỏ qua (gaps)
  RETURN QUERY
  SELECT g.n::INT AS unused_number
  FROM generate_series(1, v_max) AS g(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM edoc.outgoing_docs o
    WHERE o.unit_id = p_unit_id
      AND o.doc_book_id = p_doc_book_id
      AND o.number = g.n
      AND EXTRACT(YEAR FROM o.received_date) = EXTRACT(YEAR FROM NOW())
  )
  ORDER BY g.n;
END;
$$;

-- ============================================================================
-- 4. LGSP — Gửi liên thông từ VB đến (tạo tracking record)
-- Mở rộng fn_lgsp_tracking_create để hỗ trợ incoming_doc_id
-- ============================================================================

DROP FUNCTION IF EXISTS edoc.fn_lgsp_tracking_create(BIGINT, VARCHAR, VARCHAR, VARCHAR, TEXT, INT);

CREATE OR REPLACE FUNCTION edoc.fn_lgsp_tracking_create(
  p_outgoing_doc_id BIGINT DEFAULT NULL,
  p_incoming_doc_id BIGINT DEFAULT NULL,        -- MỚI
  p_direction       VARCHAR DEFAULT 'send',
  p_dest_org_code   VARCHAR DEFAULT NULL,
  p_dest_org_name   VARCHAR DEFAULT NULL,
  p_edxml_content   TEXT DEFAULT NULL,
  p_created_by      INT DEFAULT NULL
)
RETURNS TABLE (
  success   BOOLEAN,
  message   TEXT,
  id        BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
  v_id BIGINT;
BEGIN
  INSERT INTO edoc.lgsp_tracking (
    outgoing_doc_id, incoming_doc_id, direction, dest_org_code, dest_org_name,
    edxml_content, status, created_by
  )
  VALUES (
    p_outgoing_doc_id, p_incoming_doc_id, p_direction, p_dest_org_code, p_dest_org_name,
    p_edxml_content, 'pending', p_created_by
  )
  RETURNING edoc.lgsp_tracking.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo tracking liên thông thành công'::TEXT, v_id;
END;
$$;

-- ============================================================================
-- 5. FILE ĐÍNH KÈM VB LIÊN THÔNG — CRUD SPs
-- Bảng edoc.attachment_inter_incoming_docs đã tạo ở migration 022
-- ============================================================================

-- 5a. Danh sách
CREATE OR REPLACE FUNCTION edoc.fn_attachment_inter_incoming_get_list(
  p_doc_id BIGINT
)
RETURNS TABLE (
  id            BIGINT,
  file_name     VARCHAR,
  file_path     VARCHAR,
  file_size     BIGINT,
  content_type  VARCHAR,
  description   TEXT,
  sort_order    INT,
  created_by    INT,
  created_at    TIMESTAMPTZ,
  created_by_name VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT a.id, a.file_name, a.file_path, a.file_size, a.content_type,
         a.description, a.sort_order, a.created_by, a.created_at, s.full_name
  FROM edoc.attachment_inter_incoming_docs a
  LEFT JOIN public.staff s ON s.id = a.created_by
  WHERE a.inter_incoming_doc_id = p_doc_id
  ORDER BY a.sort_order, a.created_at;
END;
$$;

-- 5b. Tạo
CREATE OR REPLACE FUNCTION edoc.fn_attachment_inter_incoming_create(
  p_doc_id       BIGINT,
  p_file_name    VARCHAR,
  p_file_path    VARCHAR,
  p_file_size    BIGINT,
  p_content_type VARCHAR,
  p_description  TEXT DEFAULT NULL,
  p_created_by   INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE v_id BIGINT;
BEGIN
  IF p_file_name IS NULL OR TRIM(p_file_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên file không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.attachment_inter_incoming_docs (
    inter_incoming_doc_id, file_name, file_path, file_size, content_type, description, created_by
  )
  VALUES (p_doc_id, p_file_name, p_file_path, COALESCE(p_file_size, 0), p_content_type, NULLIF(TRIM(p_description), ''), p_created_by)
  RETURNING edoc.attachment_inter_incoming_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tải lên thành công'::TEXT, v_id;
END;
$$;

-- 5c. Xóa
CREATE OR REPLACE FUNCTION edoc.fn_attachment_inter_incoming_delete(
  p_id BIGINT
)
RETURNS TABLE (success BOOLEAN, message TEXT, file_path VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE v_path VARCHAR;
BEGIN
  SELECT a.file_path INTO v_path FROM edoc.attachment_inter_incoming_docs a WHERE a.id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy file đính kèm'::TEXT, ''::VARCHAR;
    RETURN;
  END IF;

  DELETE FROM edoc.attachment_inter_incoming_docs WHERE edoc.attachment_inter_incoming_docs.id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa file thành công'::TEXT, v_path;
END;
$$;

-- ============================================================================
DO $$ BEGIN
  RAISE NOTICE '✅ Migration 023: Doc Module Extras';
  RAISE NOTICE '   fn_handling_doc_get_for_link (HSCV sẵn có để link)';
  RAISE NOTICE '   fn_outgoing_doc_get_unused_numbers (số chưa phát hành)';
  RAISE NOTICE '   fn_lgsp_tracking_create (mở rộng cho incoming_doc_id)';
  RAISE NOTICE '   fn_attachment_inter_incoming_* (CRUD 3 SPs)';
END $$;

COMMIT;

-- ================================================================
-- Source: 024_sprint_s1_s2_send_config_leader_assign.sql
-- ================================================================

-- ============================================================================
-- Migration 024: S1 (Gửi nhanh) + S2 (Bút phê kết hợp phân công)
-- ============================================================================

BEGIN;

-- ============================================================================
-- S1: BẢNG CẤU HÌNH GỬI NHANH
-- ============================================================================

CREATE TABLE IF NOT EXISTS edoc.send_doc_user_configs (
  id          SERIAL PRIMARY KEY,
  user_id     INT NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  target_user_id INT NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  config_type VARCHAR(20) NOT NULL DEFAULT 'doc',  -- 'doc' (VB) | 'handling' (HSCV)
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, target_user_id, config_type)
);

CREATE INDEX IF NOT EXISTS idx_send_config_user ON edoc.send_doc_user_configs(user_id, config_type);

COMMENT ON TABLE edoc.send_doc_user_configs IS 'Cấu hình gửi nhanh — preset danh sách người nhận per user';

-- SP: Lấy danh sách config của user
CREATE OR REPLACE FUNCTION edoc.fn_send_config_get_by_user(
  p_user_id     INT,
  p_config_type VARCHAR DEFAULT 'doc'
)
RETURNS TABLE (
  id              INT,
  target_user_id  INT,
  target_name     VARCHAR,
  position_name   VARCHAR,
  department_name VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT c.id, c.target_user_id, s.full_name, p.name, d.name
  FROM edoc.send_doc_user_configs c
  JOIN public.staff s ON s.id = c.target_user_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  LEFT JOIN public.departments d ON d.id = s.department_id
  WHERE c.user_id = p_user_id AND c.config_type = p_config_type
  ORDER BY d.sort_order, s.full_name;
END;
$$;

-- SP: Lưu config (xóa cũ + insert mới — bulk replace)
CREATE OR REPLACE FUNCTION edoc.fn_send_config_save(
  p_user_id         INT,
  p_config_type     VARCHAR,
  p_target_user_ids INT[]
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql AS $$
DECLARE v_count INT;
BEGIN
  -- Xóa cũ
  DELETE FROM edoc.send_doc_user_configs
  WHERE user_id = p_user_id AND config_type = p_config_type;

  -- Insert mới
  IF p_target_user_ids IS NOT NULL AND array_length(p_target_user_ids, 1) > 0 THEN
    INSERT INTO edoc.send_doc_user_configs (user_id, target_user_id, config_type)
    SELECT p_user_id, unnest(p_target_user_ids), p_config_type
    ON CONFLICT (user_id, target_user_id, config_type) DO NOTHING;
  END IF;

  SELECT COUNT(*) INTO v_count
  FROM edoc.send_doc_user_configs
  WHERE user_id = p_user_id AND config_type = p_config_type;

  RETURN QUERY SELECT TRUE, ('Đã lưu ' || v_count || ' người nhận')::TEXT;
END;
$$;

-- ============================================================================
-- S2: MỞ RỘNG LEADER_NOTES — Bút phê kết hợp phân công
-- ============================================================================

ALTER TABLE edoc.leader_notes ADD COLUMN IF NOT EXISTS expired_date TIMESTAMPTZ;
ALTER TABLE edoc.leader_notes ADD COLUMN IF NOT EXISTS assigned_staff_ids INT[];

COMMENT ON COLUMN edoc.leader_notes.expired_date IS 'Hạn giải quyết (khi phân công)';
COMMENT ON COLUMN edoc.leader_notes.assigned_staff_ids IS 'Danh sách cán bộ được phân công';

-- SP: Bút phê + phân công (combo)
-- Logic: tạo note + gửi VB cho staff + update handling nếu có
DROP FUNCTION IF EXISTS edoc.fn_leader_note_comment_and_assign(BIGINT, INT, TEXT, TIMESTAMPTZ, INT[], VARCHAR);

CREATE OR REPLACE FUNCTION edoc.fn_leader_note_comment_and_assign(
  p_doc_id        BIGINT,
  p_staff_id      INT,
  p_content       TEXT,
  p_expired_date  TIMESTAMPTZ DEFAULT NULL,
  p_staff_ids     INT[] DEFAULT NULL,
  p_doc_type      VARCHAR DEFAULT 'incoming'  -- incoming | outgoing | drafting
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql AS $$
DECLARE
  v_id BIGINT;
  v_sent_count INT := 0;
BEGIN
  IF p_content IS NULL OR TRIM(p_content) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nội dung bút phê không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  -- Tạo leader note
  IF p_doc_type = 'incoming' THEN
    INSERT INTO edoc.leader_notes (incoming_doc_id, staff_id, content, expired_date, assigned_staff_ids)
    VALUES (p_doc_id, p_staff_id, TRIM(p_content), p_expired_date, p_staff_ids)
    RETURNING edoc.leader_notes.id INTO v_id;
  ELSIF p_doc_type = 'outgoing' THEN
    INSERT INTO edoc.leader_notes (outgoing_doc_id, staff_id, content, expired_date, assigned_staff_ids)
    VALUES (p_doc_id, p_staff_id, TRIM(p_content), p_expired_date, p_staff_ids)
    RETURNING edoc.leader_notes.id INTO v_id;
  ELSIF p_doc_type = 'drafting' THEN
    INSERT INTO edoc.leader_notes (drafting_doc_id, staff_id, content, expired_date, assigned_staff_ids)
    VALUES (p_doc_id, p_staff_id, TRIM(p_content), p_expired_date, p_staff_ids)
    RETURNING edoc.leader_notes.id INTO v_id;
  END IF;

  -- Gửi VB cho cán bộ được phân công
  IF p_staff_ids IS NOT NULL AND array_length(p_staff_ids, 1) > 0 THEN
    IF p_doc_type = 'incoming' THEN
      INSERT INTO edoc.user_incoming_docs (incoming_doc_id, staff_id, is_read, created_at)
      SELECT p_doc_id, unnest(p_staff_ids), FALSE, NOW()
      ON CONFLICT (incoming_doc_id, staff_id) DO NOTHING;
      GET DIAGNOSTICS v_sent_count = ROW_COUNT;
    ELSIF p_doc_type = 'outgoing' THEN
      INSERT INTO edoc.user_outgoing_docs (outgoing_doc_id, staff_id, sent_by, is_read, created_at)
      SELECT p_doc_id, unnest(p_staff_ids), p_staff_id, FALSE, NOW()
      ON CONFLICT (outgoing_doc_id, staff_id) DO NOTHING;
      GET DIAGNOSTICS v_sent_count = ROW_COUNT;
    ELSIF p_doc_type = 'drafting' THEN
      INSERT INTO edoc.user_drafting_docs (drafting_doc_id, staff_id, sent_by, is_read, created_at)
      SELECT p_doc_id, unnest(p_staff_ids), p_staff_id, FALSE, NOW()
      ON CONFLICT (drafting_doc_id, staff_id) DO NOTHING;
      GET DIAGNOSTICS v_sent_count = ROW_COUNT;
    END IF;
  END IF;

  RETURN QUERY SELECT TRUE,
    ('Bút phê thành công' || CASE WHEN v_sent_count > 0 THEN ', đã phân công ' || v_sent_count || ' cán bộ' ELSE '' END)::TEXT,
    v_id;
END;
$$;

-- ============================================================================
DO $$ BEGIN
  RAISE NOTICE '✅ Migration 024: S1 + S2';
  RAISE NOTICE '   S1: send_doc_user_configs table + 2 SPs';
  RAISE NOTICE '   S2: leader_notes +expired_date, +assigned_staff_ids, fn_leader_note_comment_and_assign';
END $$;

COMMIT;

-- ================================================================
-- Source: 025_sprint_s3_archive.sql
-- ================================================================

-- ============================================================================
-- Migration 025: S3 — Chuyển lưu trữ (MoveToArchive)
-- ============================================================================

BEGIN;

-- ============================================================================
-- Bảng lưu trữ VB (liên kết VB đến/đi với hồ sơ lưu trữ)
-- ============================================================================

CREATE TABLE IF NOT EXISTS esto.document_archives (
  id              BIGSERIAL PRIMARY KEY,
  doc_type        VARCHAR(20) NOT NULL,  -- 'incoming' | 'outgoing'
  doc_id          BIGINT NOT NULL,
  fond_id         INT REFERENCES esto.fonds(id),
  warehouse_id    INT REFERENCES esto.warehouses(id),
  record_id       BIGINT REFERENCES esto.records(id),
  file_catalog    VARCHAR(200),          -- Mục lục hồ sơ
  file_notation   VARCHAR(100),          -- Ký hiệu hồ sơ
  doc_ordinal     INT,                   -- Thứ tự VB trong hồ sơ
  language        VARCHAR(50) DEFAULT 'Tiếng Việt',
  autograph       TEXT,                  -- Bút tích
  keyword         TEXT,                  -- Từ khóa
  format          VARCHAR(50) DEFAULT 'Điện tử', -- Điện tử / Giấy
  confidence_level VARCHAR(50),          -- Mức độ tin cậy
  is_original     BOOLEAN DEFAULT true,  -- Bản gốc
  archive_date    TIMESTAMPTZ DEFAULT NOW(),
  archived_by     INT REFERENCES staff(id),
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(doc_type, doc_id)
);

CREATE INDEX IF NOT EXISTS idx_doc_archives_doc ON esto.document_archives(doc_type, doc_id);

-- SP: Chuyển lưu trữ
CREATE OR REPLACE FUNCTION esto.fn_document_archive_create(
  p_doc_type        VARCHAR,
  p_doc_id          BIGINT,
  p_fond_id         INT DEFAULT NULL,
  p_warehouse_id    INT DEFAULT NULL,
  p_record_id       BIGINT DEFAULT NULL,
  p_file_catalog    VARCHAR DEFAULT NULL,
  p_file_notation   VARCHAR DEFAULT NULL,
  p_doc_ordinal     INT DEFAULT NULL,
  p_language        VARCHAR DEFAULT 'Tiếng Việt',
  p_autograph       TEXT DEFAULT NULL,
  p_keyword         TEXT DEFAULT NULL,
  p_format          VARCHAR DEFAULT 'Điện tử',
  p_confidence_level VARCHAR DEFAULT NULL,
  p_is_original     BOOLEAN DEFAULT true,
  p_archived_by     INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql AS $$
DECLARE v_id BIGINT;
BEGIN
  IF p_doc_type NOT IN ('incoming', 'outgoing') THEN
    RETURN QUERY SELECT FALSE, 'Loại văn bản không hợp lệ'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  -- Kiểm tra VB tồn tại
  IF p_doc_type = 'incoming' AND NOT EXISTS (SELECT 1 FROM edoc.incoming_docs ind WHERE ind.id = p_doc_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đến'::TEXT, 0::BIGINT; RETURN;
  END IF;
  IF p_doc_type = 'outgoing' AND NOT EXISTS (SELECT 1 FROM edoc.outgoing_docs od WHERE od.id = p_doc_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đi'::TEXT, 0::BIGINT; RETURN;
  END IF;

  INSERT INTO esto.document_archives (
    doc_type, doc_id, fond_id, warehouse_id, record_id,
    file_catalog, file_notation, doc_ordinal, language,
    autograph, keyword, format, confidence_level, is_original, archived_by
  ) VALUES (
    p_doc_type, p_doc_id, p_fond_id, p_warehouse_id, p_record_id,
    NULLIF(TRIM(p_file_catalog), ''), NULLIF(TRIM(p_file_notation), ''), p_doc_ordinal,
    COALESCE(p_language, 'Tiếng Việt'),
    NULLIF(TRIM(p_autograph), ''), NULLIF(TRIM(p_keyword), ''),
    COALESCE(p_format, 'Điện tử'), NULLIF(TRIM(p_confidence_level), ''),
    COALESCE(p_is_original, true), p_archived_by
  )
  ON CONFLICT (doc_type, doc_id) DO UPDATE SET
    fond_id = EXCLUDED.fond_id, warehouse_id = EXCLUDED.warehouse_id,
    record_id = EXCLUDED.record_id, file_catalog = EXCLUDED.file_catalog,
    file_notation = EXCLUDED.file_notation, doc_ordinal = EXCLUDED.doc_ordinal,
    language = EXCLUDED.language, autograph = EXCLUDED.autograph,
    keyword = EXCLUDED.keyword, format = EXCLUDED.format,
    confidence_level = EXCLUDED.confidence_level, is_original = EXCLUDED.is_original,
    archived_by = EXCLUDED.archived_by, archive_date = NOW()
  RETURNING esto.document_archives.id INTO v_id;

  -- Cập nhật archive_status trên VB gốc
  IF p_doc_type = 'incoming' THEN
    UPDATE edoc.incoming_docs SET archive_status = true WHERE id = p_doc_id;
  ELSIF p_doc_type = 'outgoing' THEN
    UPDATE edoc.outgoing_docs SET archive_status = true WHERE id = p_doc_id;
  END IF;

  RETURN QUERY SELECT TRUE, 'Chuyển lưu trữ thành công'::TEXT, v_id;
END;
$$;

-- SP: Lấy thông tin lưu trữ của VB
CREATE OR REPLACE FUNCTION esto.fn_document_archive_get_by_doc(
  p_doc_type VARCHAR,
  p_doc_id   BIGINT
)
RETURNS TABLE (
  id              BIGINT,
  fond_id         INT,
  fond_name       VARCHAR,
  warehouse_id    INT,
  warehouse_name  VARCHAR,
  record_id       BIGINT,
  record_name     VARCHAR,
  file_catalog    VARCHAR,
  file_notation   VARCHAR,
  doc_ordinal     INT,
  language        VARCHAR,
  autograph       TEXT,
  keyword         TEXT,
  format          VARCHAR,
  confidence_level VARCHAR,
  is_original     BOOLEAN,
  archive_date    TIMESTAMPTZ,
  archived_by_name VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT a.id, a.fond_id, f.name, a.warehouse_id, w.name,
         a.record_id, r.name, a.file_catalog, a.file_notation,
         a.doc_ordinal, a.language, a.autograph, a.keyword,
         a.format, a.confidence_level, a.is_original,
         a.archive_date, s.full_name
  FROM esto.document_archives a
  LEFT JOIN esto.fonds f ON f.id = a.fond_id
  LEFT JOIN esto.warehouses w ON w.id = a.warehouse_id
  LEFT JOIN esto.records r ON r.id = a.record_id
  LEFT JOIN public.staff s ON s.id = a.archived_by
  WHERE a.doc_type = p_doc_type AND a.doc_id = p_doc_id;
END;
$$;

-- SP: Lấy danh sách phông + kho cho dropdown
CREATE OR REPLACE FUNCTION esto.fn_get_fonds_list(p_unit_id INT DEFAULT NULL)
RETURNS TABLE (id INT, name VARCHAR, code VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY SELECT f.id, f.name, f.code FROM esto.fonds f
  WHERE (p_unit_id IS NULL OR f.warehouse_id IN (SELECT w.id FROM esto.warehouses w WHERE w.unit_id = p_unit_id))
  ORDER BY f.name;
END;
$$;

CREATE OR REPLACE FUNCTION esto.fn_get_warehouses_list(p_unit_id INT DEFAULT NULL)
RETURNS TABLE (id INT, name VARCHAR, code VARCHAR)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY SELECT w.id, w.name, w.code FROM esto.warehouses w
  WHERE (p_unit_id IS NULL OR w.unit_id = p_unit_id)
  ORDER BY w.name;
END;
$$;

DO $$ BEGIN
  RAISE NOTICE '✅ Migration 025: S3 Chuyển lưu trữ';
  RAISE NOTICE '   esto.document_archives + 4 SPs';
END $$;

COMMIT;

-- ================================================================
-- Source: 026_sprint_s6_s7_lgsp_signing_mock.sql
-- ================================================================

-- ============================================================================
-- Migration 026: S6 (LGSP mock) + S7 (Ký số mock)
-- Giả lập — khi có SDK/API thật chỉ cần swap implementation
-- ============================================================================

BEGIN;

-- ============================================================================
-- S6: LGSP CONFIG TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS edoc.lgsp_config (
  id                  SERIAL PRIMARY KEY,
  unit_id             INT REFERENCES departments(id),
  endpoint_url        VARCHAR(500) NOT NULL DEFAULT 'https://lgsp.laocai.gov.vn/api',
  org_code            VARCHAR(100) NOT NULL,
  username            VARCHAR(100),
  password_encrypted  VARCHAR(200),
  polling_interval_sec INT DEFAULT 300,
  is_active           BOOLEAN DEFAULT true,
  last_sync_at        TIMESTAMPTZ,
  created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- SP: Mock nhận VB từ LGSP (giả lập tạo inter_incoming_doc)
CREATE OR REPLACE FUNCTION edoc.fn_lgsp_mock_receive(
  p_unit_id       INT,
  p_notation      VARCHAR,
  p_abstract      TEXT,
  p_publish_unit  VARCHAR,
  p_signer        VARCHAR,
  p_doc_type_id   INT DEFAULT NULL,
  p_created_by    INT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql AS $$
DECLARE v_id BIGINT;
BEGIN
  INSERT INTO edoc.inter_incoming_docs (
    unit_id, notation, abstract, publish_unit, signer,
    doc_type_id, source_system, status, created_by
  ) VALUES (
    p_unit_id, p_notation, p_abstract, p_publish_unit, p_signer,
    p_doc_type_id, 'LGSP_MOCK', 'pending', p_created_by
  )
  RETURNING inter_incoming_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, ('[MOCK] Đã nhận VB liên thông #' || v_id)::TEXT, v_id;
END;
$$;

-- SP: Mock gửi VB đi qua LGSP (giả lập thành công)
CREATE OR REPLACE FUNCTION edoc.fn_lgsp_mock_send(
  p_doc_id        BIGINT,
  p_doc_type      VARCHAR,  -- 'incoming' | 'outgoing'
  p_dest_org_code VARCHAR,
  p_dest_org_name VARCHAR,
  p_sent_by       INT
)
RETURNS TABLE (success BOOLEAN, message TEXT, tracking_id BIGINT)
LANGUAGE plpgsql AS $$
DECLARE v_id BIGINT;
BEGIN
  INSERT INTO edoc.lgsp_tracking (
    outgoing_doc_id, incoming_doc_id, direction, dest_org_code, dest_org_name,
    status, sent_at, created_by
  ) VALUES (
    CASE WHEN p_doc_type = 'outgoing' THEN p_doc_id ELSE NULL END,
    CASE WHEN p_doc_type = 'incoming' THEN p_doc_id ELSE NULL END,
    'send', p_dest_org_code, p_dest_org_name,
    'success', NOW(), p_sent_by  -- Mock: luôn success
  )
  RETURNING edoc.lgsp_tracking.id INTO v_id;

  RETURN QUERY SELECT TRUE, ('[MOCK] Gửi liên thông thành công → ' || p_dest_org_name)::TEXT, v_id;
END;
$$;

-- ============================================================================
-- S7: KÝ SỐ — Thêm cột cho 3 bảng attachment
-- ============================================================================

ALTER TABLE edoc.attachment_incoming_docs ADD COLUMN IF NOT EXISTS is_ca BOOLEAN DEFAULT false;
ALTER TABLE edoc.attachment_incoming_docs ADD COLUMN IF NOT EXISTS ca_date TIMESTAMPTZ;
ALTER TABLE edoc.attachment_incoming_docs ADD COLUMN IF NOT EXISTS signed_file_path VARCHAR(1000);

ALTER TABLE edoc.attachment_outgoing_docs ADD COLUMN IF NOT EXISTS is_ca BOOLEAN DEFAULT false;
ALTER TABLE edoc.attachment_outgoing_docs ADD COLUMN IF NOT EXISTS ca_date TIMESTAMPTZ;
ALTER TABLE edoc.attachment_outgoing_docs ADD COLUMN IF NOT EXISTS signed_file_path VARCHAR(1000);

ALTER TABLE edoc.attachment_drafting_docs ADD COLUMN IF NOT EXISTS is_ca BOOLEAN DEFAULT false;
ALTER TABLE edoc.attachment_drafting_docs ADD COLUMN IF NOT EXISTS ca_date TIMESTAMPTZ;
ALTER TABLE edoc.attachment_drafting_docs ADD COLUMN IF NOT EXISTS signed_file_path VARCHAR(1000);

-- SP: Mock ký số (cập nhật attachment — giả lập ký thành công)
CREATE OR REPLACE FUNCTION edoc.fn_attachment_mock_sign(
  p_attachment_id   BIGINT,
  p_attachment_type VARCHAR,  -- 'incoming' | 'outgoing' | 'drafting'
  p_signed_by       INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql AS $$
BEGIN
  IF p_attachment_type = 'incoming' THEN
    UPDATE edoc.attachment_incoming_docs SET is_ca = true, ca_date = NOW(), signed_file_path = file_path WHERE id = p_attachment_id;
  ELSIF p_attachment_type = 'outgoing' THEN
    UPDATE edoc.attachment_outgoing_docs SET is_ca = true, ca_date = NOW(), signed_file_path = file_path WHERE id = p_attachment_id;
  ELSIF p_attachment_type = 'drafting' THEN
    UPDATE edoc.attachment_drafting_docs SET is_ca = true, ca_date = NOW(), signed_file_path = file_path WHERE id = p_attachment_id;
  ELSE
    RETURN QUERY SELECT FALSE, 'Loại không hợp lệ'::TEXT; RETURN;
  END IF;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy file đính kèm'::TEXT; RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, '[MOCK] Ký số thành công'::TEXT;
END;
$$;

-- SP: Xác thực chữ ký (mock — luôn trả valid)
CREATE OR REPLACE FUNCTION edoc.fn_attachment_mock_verify(
  p_attachment_id   BIGINT,
  p_attachment_type VARCHAR
)
RETURNS TABLE (is_valid BOOLEAN, signer_name VARCHAR, sign_date TIMESTAMPTZ, message TEXT)
LANGUAGE plpgsql AS $$
DECLARE v_ca BOOLEAN; v_date TIMESTAMPTZ;
BEGIN
  IF p_attachment_type = 'incoming' THEN
    SELECT is_ca, ca_date INTO v_ca, v_date FROM edoc.attachment_incoming_docs WHERE id = p_attachment_id;
  ELSIF p_attachment_type = 'outgoing' THEN
    SELECT is_ca, ca_date INTO v_ca, v_date FROM edoc.attachment_outgoing_docs WHERE id = p_attachment_id;
  ELSIF p_attachment_type = 'drafting' THEN
    SELECT is_ca, ca_date INTO v_ca, v_date FROM edoc.attachment_drafting_docs WHERE id = p_attachment_id;
  END IF;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, ''::VARCHAR, NULL::TIMESTAMPTZ, 'Không tìm thấy file'::TEXT; RETURN;
  END IF;

  IF COALESCE(v_ca, false) THEN
    RETURN QUERY SELECT TRUE, '[MOCK] Người ký hợp lệ'::VARCHAR, v_date, 'Chữ ký số hợp lệ (MOCK)'::TEXT;
  ELSE
    RETURN QUERY SELECT FALSE, ''::VARCHAR, NULL::TIMESTAMPTZ, 'File chưa được ký số'::TEXT;
  END IF;
END;
$$;

DO $$ BEGIN
  RAISE NOTICE '✅ Migration 026: S6 + S7 (LGSP mock + Ký số mock)';
  RAISE NOTICE '   S6: lgsp_config table, fn_lgsp_mock_receive, fn_lgsp_mock_send';
  RAISE NOTICE '   S7: attachment +is_ca/ca_date/signed_file_path, fn_attachment_mock_sign/verify';
END $$;

COMMIT;

-- ================================================================
-- Source: 027_sprint_s5_doc_columns.sql
-- ================================================================

-- ============================================================================
-- Migration 027: S5 — Dynamic DocColumns
-- Admin cấu hình trường form per loại VB
-- ============================================================================

BEGIN;

-- Bảng doc_columns đã tồn tại từ sprint 2 với cột type_id (smallint)
-- Cần ALTER để thêm các cột mới cho dynamic form
ALTER TABLE edoc.doc_columns ADD COLUMN IF NOT EXISTS data_type VARCHAR(50) DEFAULT 'text';
ALTER TABLE edoc.doc_columns ADD COLUMN IF NOT EXISTS max_length INT;
ALTER TABLE edoc.doc_columns ADD COLUMN IF NOT EXISTS is_system BOOLEAN DEFAULT false;

-- Đổi tên type_id → dùng trực tiếp (giữ nguyên, SP dùng type_id)
-- Không rename vì có UNIQUE constraint đang dùng

CREATE INDEX IF NOT EXISTS idx_doc_columns_type ON edoc.doc_columns(type_id, sort_order);

-- SP: Lấy columns theo type_id
DROP FUNCTION IF EXISTS edoc.fn_doc_column_get_by_type(INT);
DROP FUNCTION IF EXISTS edoc.fn_doc_column_get_all();
DROP FUNCTION IF EXISTS edoc.fn_doc_column_save(INT, INT, VARCHAR, VARCHAR, VARCHAR, INT, INT, BOOLEAN, TEXT);
DROP FUNCTION IF EXISTS edoc.fn_doc_column_delete(INT);

CREATE OR REPLACE FUNCTION edoc.fn_doc_column_get_by_type(p_type_id INT)
RETURNS TABLE (
  id INT, column_name VARCHAR, label VARCHAR, data_type VARCHAR,
  max_length INT, sort_order INT, is_mandatory BOOLEAN, is_system BOOLEAN, description TEXT
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT c.id, c.column_name, c.label, c.data_type, c.max_length,
         c.sort_order, c.is_mandatory, c.is_system, c.description
  FROM edoc.doc_columns c
  WHERE c.type_id = p_type_id
  ORDER BY c.sort_order, c.id;
END;
$$;

-- SP: Lấy tất cả columns (admin)
CREATE OR REPLACE FUNCTION edoc.fn_doc_column_get_all()
RETURNS TABLE (
  id INT, type_id INT, doc_type_name VARCHAR,
  column_name VARCHAR, label VARCHAR, data_type VARCHAR,
  max_length INT, sort_order INT, is_mandatory BOOLEAN, is_system BOOLEAN
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT c.id, c.type_id, dt.name, c.column_name, c.label, c.data_type,
         c.max_length, c.sort_order, c.is_mandatory, c.is_system
  FROM edoc.doc_columns c
  JOIN edoc.doc_types dt ON dt.id = c.type_id
  ORDER BY dt.name, c.sort_order;
END;
$$;

-- SP: Lưu column (upsert)
CREATE OR REPLACE FUNCTION edoc.fn_doc_column_save(
  p_id          INT DEFAULT NULL,
  p_type_id INT DEFAULT NULL,
  p_column_name VARCHAR DEFAULT NULL,
  p_label       VARCHAR DEFAULT NULL,
  p_data_type   VARCHAR DEFAULT 'text',
  p_max_length  INT DEFAULT NULL,
  p_sort_order  INT DEFAULT 0,
  p_is_mandatory BOOLEAN DEFAULT false,
  p_description TEXT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT, id INT)
LANGUAGE plpgsql AS $$
DECLARE v_id INT;
BEGIN
  IF p_label IS NULL OR TRIM(p_label) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nhãn hiển thị là bắt buộc'::TEXT, 0; RETURN;
  END IF;

  IF p_id IS NOT NULL AND p_id > 0 THEN
    -- Update
    UPDATE edoc.doc_columns SET
      column_name = COALESCE(p_column_name, column_name),
      label = TRIM(p_label),
      data_type = COALESCE(p_data_type, data_type),
      max_length = p_max_length,
      sort_order = COALESCE(p_sort_order, sort_order),
      is_mandatory = COALESCE(p_is_mandatory, is_mandatory),
      description = NULLIF(TRIM(p_description), '')
    WHERE edoc.doc_columns.id = p_id AND is_system = false;

    IF NOT FOUND THEN
      RETURN QUERY SELECT FALSE, 'Không tìm thấy hoặc không thể sửa trường hệ thống'::TEXT, 0; RETURN;
    END IF;
    v_id := p_id;
  ELSE
    -- Insert
    INSERT INTO edoc.doc_columns (type_id, column_name, label, data_type, max_length, sort_order, is_mandatory, description)
    VALUES (p_type_id, p_column_name, TRIM(p_label), COALESCE(p_data_type, 'text'), p_max_length, COALESCE(p_sort_order, 0), COALESCE(p_is_mandatory, false), NULLIF(TRIM(p_description), ''))
    RETURNING edoc.doc_columns.id INTO v_id;
  END IF;

  RETURN QUERY SELECT TRUE, 'Lưu thành công'::TEXT, v_id;
END;
$$;

-- SP: Xóa column (chỉ non-system)
CREATE OR REPLACE FUNCTION edoc.fn_doc_column_delete(p_id INT)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM edoc.doc_columns WHERE id = p_id AND is_system = false;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy hoặc không thể xóa trường hệ thống'::TEXT; RETURN;
  END IF;
  RETURN QUERY SELECT TRUE, 'Đã xóa'::TEXT;
END;
$$;

-- Seed: tạo columns mặc định cho loại "Công văn" (type_id = 1)
INSERT INTO edoc.doc_columns (type_id, column_name, label, data_type, sort_order, is_mandatory, is_system) VALUES
  (1, 'abstract', 'Trích yếu nội dung', 'textarea', 1, true, true),
  (1, 'notation', 'Số ký hiệu', 'text', 2, false, true),
  (1, 'publish_unit', 'Cơ quan ban hành', 'text', 3, false, true),
  (1, 'signer', 'Người ký', 'text', 4, false, false),
  (1, 'sign_date', 'Ngày ký', 'date', 5, false, false),
  (1, 'publish_date', 'Ngày ban hành', 'date', 6, false, false),
  (1, 'expired_date', 'Hạn xử lý', 'date', 7, false, false),
  (1, 'recipients', 'Nơi nhận', 'textarea', 8, false, false)
ON CONFLICT (type_id, column_name) DO NOTHING;

DO $$ BEGIN
  RAISE NOTICE '✅ Migration 027: S5 Dynamic DocColumns';
  RAISE NOTICE '   edoc.doc_columns table + 4 SPs + seed data';
END $$;

COMMIT;

-- ================================================================
-- Source: 028_s5_dynamic_form_extra_fields.sql
-- ================================================================

-- ============================================================================
-- Migration 028: S5 Dynamic Form — extra_fields JSONB + fix doc_columns
-- Form VB có 2 phần: cứng (system) + động (custom từ doc_columns)
-- Dữ liệu custom lưu vào extra_fields JSONB
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. Thêm cột extra_fields vào 3 bảng VB chính
-- ============================================================================

ALTER TABLE edoc.incoming_docs ADD COLUMN IF NOT EXISTS extra_fields JSONB DEFAULT '{}';
ALTER TABLE edoc.outgoing_docs ADD COLUMN IF NOT EXISTS extra_fields JSONB DEFAULT '{}';
ALTER TABLE edoc.drafting_docs ADD COLUMN IF NOT EXISTS extra_fields JSONB DEFAULT '{}';

COMMENT ON COLUMN edoc.incoming_docs.extra_fields IS 'Trường bổ sung theo cấu hình doc_columns (dynamic form)';
COMMENT ON COLUMN edoc.outgoing_docs.extra_fields IS 'Trường bổ sung theo cấu hình doc_columns (dynamic form)';
COMMENT ON COLUMN edoc.drafting_docs.extra_fields IS 'Trường bổ sung theo cấu hình doc_columns (dynamic form)';

-- ============================================================================
-- 2. Xóa seed data system columns cũ (nếu có) — chỉ giữ custom columns
-- doc_columns chỉ dùng cho trường BỔ SUNG, không quản lý trường system
-- ============================================================================

DELETE FROM edoc.doc_columns WHERE is_system = true;

-- ============================================================================
-- 3. SP: Lưu extra_fields cho VB (generic — dùng cho cả 3 loại)
-- ============================================================================

CREATE OR REPLACE FUNCTION edoc.fn_doc_save_extra_fields(
  p_doc_type VARCHAR,   -- 'incoming' | 'outgoing' | 'drafting'
  p_doc_id   BIGINT,
  p_extra    JSONB
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql AS $$
BEGIN
  IF p_doc_type = 'incoming' THEN
    UPDATE edoc.incoming_docs SET extra_fields = COALESCE(p_extra, '{}') WHERE id = p_doc_id;
  ELSIF p_doc_type = 'outgoing' THEN
    UPDATE edoc.outgoing_docs SET extra_fields = COALESCE(p_extra, '{}') WHERE id = p_doc_id;
  ELSIF p_doc_type = 'drafting' THEN
    UPDATE edoc.drafting_docs SET extra_fields = COALESCE(p_extra, '{}') WHERE id = p_doc_id;
  ELSE
    RETURN QUERY SELECT FALSE, 'Loại VB không hợp lệ'::TEXT; RETURN;
  END IF;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản'::TEXT; RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, 'Lưu trường bổ sung thành công'::TEXT;
END;
$$;

-- ============================================================================
-- 4. Seed: Tạo vài trường mẫu cho demo
-- ============================================================================

-- Loại "Quyết định" (id=3) — thêm 2 trường: Hiệu lực từ, Hiệu lực đến
INSERT INTO edoc.doc_columns (type_id, column_name, label, data_type, max_length, sort_order, is_mandatory, is_system, description)
VALUES
  (3, 'effective_from', 'Hiệu lực từ ngày', 'date', NULL, 1, false, false, 'Ngày bắt đầu có hiệu lực'),
  (3, 'effective_to', 'Hiệu lực đến ngày', 'date', NULL, 2, false, false, 'Ngày hết hiệu lực')
ON CONFLICT (type_id, column_name) DO NOTHING;

-- Loại "Báo cáo" (id=7 nếu có) — thêm: Kỳ báo cáo
INSERT INTO edoc.doc_columns (type_id, column_name, label, data_type, max_length, sort_order, is_mandatory, is_system, description)
VALUES
  (7, 'report_period', 'Kỳ báo cáo', 'text', 100, 1, true, false, 'VD: Quý I/2026, Tháng 4/2026')
ON CONFLICT (type_id, column_name) DO NOTHING;

-- Loại "Công văn" (id=1) — thêm: Số hiệu cũ (cho chuyển đổi)
INSERT INTO edoc.doc_columns (type_id, column_name, label, data_type, max_length, sort_order, is_mandatory, is_system, description)
VALUES
  (1, 'old_notation', 'Số hiệu cũ', 'text', 100, 1, false, false, 'Số hiệu từ hệ thống cũ (nếu có)')
ON CONFLICT (type_id, column_name) DO NOTHING;

DO $$ BEGIN
  RAISE NOTICE '✅ Migration 028: S5 Dynamic Form';
  RAISE NOTICE '   +extra_fields JSONB (3 bảng VB)';
  RAISE NOTICE '   +fn_doc_save_extra_fields';
  RAISE NOTICE '   +Seed: 4 custom columns mẫu';
END $$;

COMMIT;

-- ================================================================
-- Source: 029_fix_test_report_bugs.sql
-- ================================================================

-- ================================================================
-- Migration 029: Fix bugs from test report (2026-04-17)
-- A1: Fix fn_doc_column_get_all type_id smallint mismatch
-- ================================================================

BEGIN;

-- ============================================================
-- A1: Fix SP fn_doc_column_get_all — type_id phải là SMALLINT
-- ============================================================
DROP FUNCTION IF EXISTS edoc.fn_doc_column_get_all();
CREATE OR REPLACE FUNCTION edoc.fn_doc_column_get_all()
RETURNS TABLE(
  id          INTEGER,
  type_id     SMALLINT,
  doc_type_name VARCHAR,
  column_name VARCHAR,
  label       VARCHAR,
  data_type   VARCHAR,
  max_length  INTEGER,
  sort_order  INTEGER,
  is_mandatory BOOLEAN,
  is_system   BOOLEAN
)
LANGUAGE plpgsql STABLE
AS $$
BEGIN
  RETURN QUERY
  SELECT c.id, c.type_id, dt.name, c.column_name, c.label, c.data_type,
         c.max_length, c.sort_order, c.is_mandatory, c.is_system
  FROM edoc.doc_columns c
  JOIN edoc.doc_types dt ON dt.id = c.type_id
  ORDER BY dt.name, c.sort_order;
END;
$$;

-- Also fix fn_doc_column_get_by_type if it has the same issue
CREATE OR REPLACE FUNCTION edoc.fn_doc_column_get_by_type(p_type_id SMALLINT)
RETURNS TABLE(
  id          INTEGER,
  type_id     SMALLINT,
  column_name VARCHAR,
  label       VARCHAR,
  data_type   VARCHAR,
  max_length  INTEGER,
  sort_order  INTEGER,
  is_mandatory BOOLEAN,
  is_system   BOOLEAN,
  is_show_all BOOLEAN,
  description TEXT
)
LANGUAGE plpgsql STABLE
AS $$
BEGIN
  RETURN QUERY
  SELECT c.id, c.type_id, c.column_name, c.label, c.data_type,
         c.max_length, c.sort_order, c.is_mandatory, c.is_system,
         c.is_show_all, c.description
  FROM edoc.doc_columns c
  WHERE c.type_id = p_type_id
  ORDER BY c.sort_order;
END;
$$;

DO $$ BEGIN RAISE NOTICE '✅ Migration 029: Fixed fn_doc_column SPs (type_id smallint)'; END $$;

COMMIT;
-- ================================================================
-- MIGRATION 037: Dashboard V2 — Biểu đồ + Stat cards mở rộng
-- Thêm 8 stored functions cho dashboard nâng cấp
-- ================================================================

-- ==========================================
-- 1. Thống kê mở rộng (stat cards bổ sung)
-- Trả về: drafting_pending, message_unread, notice_unread, today_meetings
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_get_stats_extra(
  p_staff_id INT,
  p_dept_ids INT[] DEFAULT NULL
) RETURNS TABLE (
  drafting_pending BIGINT,
  message_unread   BIGINT,
  notice_unread    BIGINT,
  today_meetings   BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    -- VB dự thảo chờ phát hành (approved nhưng chưa released)
    (
      SELECT COUNT(*)
      FROM edoc.drafting_docs dd
      WHERE dd.approved = TRUE
        AND dd.is_released = FALSE
        AND (p_dept_ids IS NULL OR dd.unit_id = ANY(p_dept_ids))
    ) AS drafting_pending,

    -- Tin nhắn chưa đọc
    (
      SELECT COUNT(*)
      FROM edoc.message_recipients mr
      WHERE mr.staff_id = p_staff_id
        AND mr.is_read = FALSE
        AND mr.is_deleted = FALSE
    ) AS message_unread,

    -- Thông báo chưa đọc
    (
      SELECT COUNT(*)
      FROM edoc.notices n
      WHERE NOT EXISTS (
        SELECT 1 FROM edoc.notice_reads nr
        WHERE nr.notice_id = n.id AND nr.staff_id = p_staff_id
      )
      AND (
        n.unit_id IS NULL
        OR n.unit_id = ANY(COALESCE(p_dept_ids, ARRAY[]::INT[]))
      )
    ) AS notice_unread,

    -- Lịch họp hôm nay
    (
      SELECT COUNT(*)
      FROM edoc.room_schedules rs
      WHERE rs.start_date = CURRENT_DATE
        AND (p_dept_ids IS NULL OR rs.unit_id = ANY(p_dept_ids))
    ) AS today_meetings;
END;
$$;

-- ==========================================
-- 2. VB đến/đi theo tháng (6 tháng gần nhất)
-- Dùng cho biểu đồ cột grouped bar chart
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_doc_by_month(
  p_dept_ids INT[] DEFAULT NULL,
  p_months   INT DEFAULT 6
) RETURNS TABLE (
  month_label  TEXT,
  incoming_count BIGINT,
  outgoing_count BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  WITH months AS (
    SELECT generate_series(
      date_trunc('month', CURRENT_DATE) - ((p_months - 1) || ' months')::interval,
      date_trunc('month', CURRENT_DATE),
      '1 month'::interval
    )::date AS m
  )
  SELECT
    to_char(mo.m, 'MM/YYYY')::TEXT AS month_label,
    COALESCE((
      SELECT COUNT(*)
      FROM edoc.incoming_docs ind
      WHERE date_trunc('month', COALESCE(ind.received_date, ind.created_at)) = mo.m
        AND (p_dept_ids IS NULL OR ind.unit_id = ANY(p_dept_ids))
    ), 0) AS incoming_count,
    COALESCE((
      SELECT COUNT(*)
      FROM edoc.outgoing_docs od
      WHERE date_trunc('month', COALESCE(od.publish_date, od.created_at)) = mo.m
        AND (p_dept_ids IS NULL OR od.unit_id = ANY(p_dept_ids))
    ), 0) AS outgoing_count
  FROM months mo
  ORDER BY mo.m;
END;
$$;

-- ==========================================
-- 3. HSCV theo trạng thái (biểu đồ tròn)
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_task_by_status(
  p_staff_id INT,
  p_dept_ids INT[] DEFAULT NULL
) RETURNS TABLE (
  status_code  SMALLINT,
  status_name  TEXT,
  task_count   BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    hd.status AS status_code,
    CASE hd.status
      WHEN 0 THEN 'Mới'
      WHEN 1 THEN 'Đang xử lý'
      WHEN 2 THEN 'Chờ duyệt'
      WHEN 3 THEN 'Đã duyệt'
      WHEN 4 THEN 'Hoàn thành'
      WHEN -1 THEN 'Từ chối'
      WHEN -2 THEN 'Trả về'
      ELSE 'Khác'
    END::TEXT AS status_name,
    COUNT(*)::BIGINT AS task_count
  FROM edoc.handling_docs hd
  WHERE (p_dept_ids IS NULL OR hd.unit_id = ANY(p_dept_ids))
  GROUP BY hd.status
  ORDER BY hd.status;
END;
$$;

-- ==========================================
-- 4. Top 5 phòng ban có nhiều VB nhất (biểu đồ cột ngang)
-- Đếm tổng VB đến + đi theo phòng ban
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_top_departments(
  p_dept_ids INT[] DEFAULT NULL,
  p_limit    INT DEFAULT 5
) RETURNS TABLE (
  department_id   INT,
  department_name VARCHAR,
  doc_count       BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  WITH dept_incoming AS (
    SELECT ind.department_id AS dept_id, COUNT(*) AS cnt
    FROM edoc.incoming_docs ind
    WHERE ind.department_id IS NOT NULL
      AND (p_dept_ids IS NULL OR ind.unit_id = ANY(p_dept_ids))
    GROUP BY ind.department_id
  ),
  dept_outgoing AS (
    SELECT od.department_id AS dept_id, COUNT(*) AS cnt
    FROM edoc.outgoing_docs od
    WHERE od.department_id IS NOT NULL
      AND (p_dept_ids IS NULL OR od.unit_id = ANY(p_dept_ids))
    GROUP BY od.department_id
  ),
  combined AS (
    SELECT dept_id, SUM(cnt) AS total
    FROM (
      SELECT * FROM dept_incoming
      UNION ALL
      SELECT * FROM dept_outgoing
    ) sub
    GROUP BY dept_id
  )
  SELECT
    c.dept_id AS department_id,
    d.name AS department_name,
    c.total AS doc_count
  FROM combined c
  INNER JOIN public.departments d ON d.id = c.dept_id
  ORDER BY c.total DESC
  LIMIT COALESCE(p_limit, 5);
END;
$$;

-- ==========================================
-- 5. Thông báo mới nhất (widget)
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_recent_notices(
  p_staff_id INT,
  p_dept_ids INT[] DEFAULT NULL,
  p_limit    INT DEFAULT 5
) RETURNS TABLE (
  id          BIGINT,
  title       VARCHAR,
  notice_type VARCHAR,
  created_at  TIMESTAMP,
  is_read     BOOLEAN
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    n.id,
    n.title,
    n.notice_type,
    n.created_at,
    EXISTS (
      SELECT 1 FROM edoc.notice_reads nr
      WHERE nr.notice_id = n.id AND nr.staff_id = p_staff_id
    ) AS is_read
  FROM edoc.notices n
  WHERE (
    n.unit_id IS NULL
    OR n.unit_id = ANY(COALESCE(p_dept_ids, ARRAY[]::INT[]))
  )
  ORDER BY n.created_at DESC
  LIMIT COALESCE(p_limit, 5);
END;
$$;

-- ==========================================
-- 6. Lịch hôm nay (widget mini calendar)
-- Lấy sự kiện hôm nay + 7 ngày tới
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_calendar_today(
  p_staff_id INT,
  p_dept_ids INT[] DEFAULT NULL,
  p_days     INT DEFAULT 7
) RETURNS TABLE (
  id         BIGINT,
  title      VARCHAR,
  start_time TIMESTAMP,
  end_time   TIMESTAMP,
  all_day    BOOLEAN,
  color      VARCHAR,
  scope      VARCHAR
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT
    ce.id,
    ce.title,
    ce.start_time,
    ce.end_time,
    ce.all_day,
    ce.color,
    ce.scope
  FROM public.calendar_events ce
  WHERE ce.is_deleted = FALSE
    AND ce.start_time < (CURRENT_DATE + p_days * interval '1 day')
    AND ce.end_time >= CURRENT_DATE
    AND (
      (ce.scope = 'personal' AND ce.created_by = p_staff_id)
      OR (ce.scope IN ('unit', 'leader') AND (
        p_dept_ids IS NULL
        OR ce.unit_id = ANY(p_dept_ids)
      ))
    )
  ORDER BY ce.start_time ASC
  LIMIT 10;
END;
$$;

-- ==========================================
-- 7. Tỷ lệ xử lý đúng hạn — KPI admin
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_ontime_rate(
  p_dept_ids INT[] DEFAULT NULL
) RETURNS TABLE (
  total_completed BIGINT,
  ontime_count    BIGINT,
  overdue_count   BIGINT,
  ontime_percent  NUMERIC
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  WITH completed AS (
    SELECT
      hd.id,
      CASE
        WHEN hd.complete_date IS NOT NULL AND hd.end_date IS NOT NULL
             AND hd.complete_date <= hd.end_date THEN TRUE
        ELSE FALSE
      END AS is_ontime
    FROM edoc.handling_docs hd
    WHERE hd.status = 4  -- Hoàn thành
      AND (p_dept_ids IS NULL OR hd.unit_id = ANY(p_dept_ids))
  )
  SELECT
    COUNT(*)::BIGINT AS total_completed,
    COUNT(*) FILTER (WHERE c.is_ontime = TRUE)::BIGINT AS ontime_count,
    COUNT(*) FILTER (WHERE c.is_ontime = FALSE)::BIGINT AS overdue_count,
    CASE
      WHEN COUNT(*) = 0 THEN 0
      ELSE ROUND(COUNT(*) FILTER (WHERE c.is_ontime = TRUE)::NUMERIC / COUNT(*)::NUMERIC * 100, 1)
    END AS ontime_percent
  FROM completed c;
END;
$$;

-- ==========================================
-- 8. VB theo đơn vị/phòng ban (admin) — biểu đồ cột
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_dashboard_doc_by_department(
  p_dept_ids INT[] DEFAULT NULL
) RETURNS TABLE (
  department_id    INT,
  department_name  VARCHAR,
  incoming_count   BIGINT,
  outgoing_count   BIGINT
) LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  WITH depts AS (
    SELECT d.id, d.name
    FROM public.departments d
    WHERE d.is_deleted = FALSE
      AND d.is_unit = FALSE
      AND (p_dept_ids IS NULL OR d.id = ANY(p_dept_ids))
  ),
  inc AS (
    SELECT ind.department_id AS dept_id, COUNT(*) AS cnt
    FROM edoc.incoming_docs ind
    WHERE ind.department_id IS NOT NULL
      AND (p_dept_ids IS NULL OR ind.unit_id = ANY(p_dept_ids))
    GROUP BY ind.department_id
  ),
  outg AS (
    SELECT od.department_id AS dept_id, COUNT(*) AS cnt
    FROM edoc.outgoing_docs od
    WHERE od.department_id IS NOT NULL
      AND (p_dept_ids IS NULL OR od.unit_id = ANY(p_dept_ids))
    GROUP BY od.department_id
  )
  SELECT
    dp.id AS department_id,
    dp.name AS department_name,
    COALESCE(i.cnt, 0) AS incoming_count,
    COALESCE(o.cnt, 0) AS outgoing_count
  FROM depts dp
  LEFT JOIN inc i ON i.dept_id = dp.id
  LEFT JOIN outg o ON o.dept_id = dp.id
  WHERE COALESCE(i.cnt, 0) + COALESCE(o.cnt, 0) > 0
  ORDER BY (COALESCE(i.cnt, 0) + COALESCE(o.cnt, 0)) DESC
  LIMIT 10;
END;
$$;

-- ==========================================
-- Cập nhật fn_dashboard_get_stats: thêm p_dept_ids param
-- (đã được cập nhật trong migration 030, chỉ ghi chú)
-- ==========================================
-- ================================================================
-- MIGRATION 038: Fix duplicate function overloads
-- Khi 000_full_schema.sql tạo function cũ, rồi migration 030+
-- tạo function mới cùng tên nhưng khác signature (thêm p_dept_ids),
-- PostgreSQL giữ cả 2 overload → backend gọi nhầm bản cũ.
-- Script này tự động tìm và xóa bản cũ (OID nhỏ hơn).
-- ================================================================

DO $$
DECLARE
  r RECORD;
  drop_count INTEGER := 0;
BEGIN
  FOR r IN
    SELECT n.nspname, p.proname, p.oid,
           pg_get_function_identity_arguments(p.oid) as args,
           ROW_NUMBER() OVER (PARTITION BY n.nspname, p.proname ORDER BY p.oid DESC) as rn
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname IN ('edoc', 'public', 'esto', 'cont', 'iso')
    AND p.proname LIKE 'fn_%'
    AND p.proname IN (
      SELECT p2.proname FROM pg_proc p2
      JOIN pg_namespace n2 ON n2.oid = p2.pronamespace
      WHERE n2.nspname IN ('edoc', 'public', 'esto', 'cont', 'iso')
      AND p2.proname LIKE 'fn_%'
      GROUP BY n2.nspname, p2.proname HAVING count(*) > 1
    )
  LOOP
    IF r.rn > 1 THEN
      EXECUTE format('DROP FUNCTION %I.%I(%s)', r.nspname, r.proname, r.args);
      RAISE NOTICE 'Dropped: %.%(%)', r.nspname, r.proname, r.args;
      drop_count := drop_count + 1;
    END IF;
  END LOOP;
  RAISE NOTICE 'Total dropped: % duplicate overloads', drop_count;
END
$$;
