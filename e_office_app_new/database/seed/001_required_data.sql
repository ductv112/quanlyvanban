-- ============================================================================
-- seed/001_required_data.sql — MASTER DATA bắt buộc (production-safe)
-- Idempotent: INSERT ... ON CONFLICT DO NOTHING / WHERE NOT EXISTS
-- Chạy sau: database/schema/000_schema_v2.0.sql
--
-- Nội dung:
--   1. Positions (6 chức vụ)
--   2. Departments (5 đơn vị root — UBND + 4 Sở)
--   3. Staff (1 admin user — username=admin, password=Admin@123)
--   4. Roles (6 vai trò default)
--   5. Rights (menu tree — 22 rights: 18 gốc + 4 ký số)
--   6. Role_of_staff (admin → Quản trị hệ thống + Ban Lãnh đạo)
--   7. Action_of_role (assign rights cho 6 roles)
--   8. Doc catalog skeleton (doc_types + doc_fields + doc_books cơ bản)
--   9. Signing provider config (2 row: SmartCA VNPT active + MySign Viettel inactive)
--
-- CÁCH CHẠY:
--   docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev -v ON_ERROR_STOP=1 \
--     -c "SET app.signing_secret_key='qlvb-signing-dev-key-change-production-2026';" \
--     -f - < e_office_app_new/database/seed/001_required_data.sql
--
-- LƯU Ý BẢO MẬT: File này KHÔNG chứa TRUNCATE/DELETE — chạy production an toàn.
-- Mọi INSERT đều idempotent (chạy lại 2+ lần không duplicate, không lỗi).
-- ============================================================================

\set ON_ERROR_STOP on

BEGIN;

-- ─── 1. Positions (6 chức vụ) ────────────────────────────────────────────────
INSERT INTO public.positions (id, name, code, sort_order) VALUES
  (1, 'Giám đốc',           'GD',   1),
  (2, 'Phó Giám đốc',       'PGD',  2),
  (3, 'Trưởng phòng',       'TP',   3),
  (4, 'Phó Trưởng phòng',   'PTP',  4),
  (5, 'Chuyên viên',        'CV',   5),
  (6, 'Văn thư',            'VT',   6)
ON CONFLICT (id) DO NOTHING;
SELECT setval('public.positions_id_seq', 10, true);

-- ─── 2. Departments (UBND + 4 Sở, root tree) ────────────────────────────────
INSERT INTO public.departments (id, parent_id, code, name, short_name, is_unit, level, sort_order, allow_doc_book, created_by) VALUES
  (1,  NULL, 'UBND',   'UBND tỉnh Lào Cai',              'UBND',   true, 0, 1, true, NULL),
  (2,  1,    'SNV',    'Sở Nội vụ',                      'SNV',    true, 1, 2, true, NULL),
  (3,  1,    'STC',    'Sở Tài chính',                   'STC',    true, 1, 3, true, NULL),
  (4,  1,    'STTTT',  'Sở Thông tin và Truyền thông',   'STTTT',  true, 1, 4, true, NULL),
  (5,  1,    'VPUBND', 'Văn phòng UBND tỉnh',            'VP',     true, 1, 5, true, NULL)
ON CONFLICT (id) DO NOTHING;
SELECT setval('public.departments_id_seq', 100, true);

-- ─── 3. Staff admin (password Admin@123) ─────────────────────────────────────
INSERT INTO public.staff (id, department_id, unit_id, position_id, code, username, password_hash, is_admin,
                          first_name, last_name, gender, email, phone, mobile) VALUES
  (1, 1, 1, 1, 'NV001', 'admin',
   '$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi',
   true, 'Quản trị', 'Hệ thống', 1,
   'admin@laocai.gov.vn', '02093801001', '0912000001')
ON CONFLICT (id) DO NOTHING;
SELECT setval('public.staff_id_seq', 100, true);

-- ─── 4. Roles (6 vai trò default) ────────────────────────────────────────────
INSERT INTO public.roles (id, unit_id, name, description) VALUES
  (1, NULL, 'Ban Lãnh đạo',           'Ban lãnh đạo cơ quan'),
  (2, NULL, 'Cán bộ',                 'Cán bộ, Chuyên viên'),
  (3, NULL, 'Chỉ đạo điều hành',      'Chỉ đạo điều hành'),
  (4, NULL, 'Nhóm Trưởng phòng',      'Nhóm Trưởng phòng'),
  (5, NULL, 'Quản trị hệ thống',      'Quản trị hệ thống'),
  (6, NULL, 'Văn thư',                'Văn thư đơn vị')
ON CONFLICT (id) DO NOTHING;
SELECT setval('public.roles_id_seq', 20, true);

-- ─── 5. Rights (menu tree — 22 items: 18 gốc + 4 ký số UX-01) ───────────────
INSERT INTO public.rights (id, parent_id, name, name_of_menu, action_link, icon, sort_order, show_menu) VALUES
  (1,  NULL, 'Dashboard',               'Dashboard',               '/dashboard',             'DashboardOutlined',         1,  true),
  (2,  NULL, 'Văn bản đến',             'Văn bản đến',             '/van-ban-den',           'InboxOutlined',             2,  true),
  (3,  NULL, 'Văn bản đi',              'Văn bản đi',              '/van-ban-di',            'SendOutlined',              3,  true),
  (4,  NULL, 'Dự thảo',                 'Dự thảo',                 '/du-thao',               'EditOutlined',              4,  true),
  (5,  NULL, 'Hồ sơ công việc',         'Hồ sơ công việc',         '/ho-so-cong-viec',       'FolderOutlined',            5,  true),
  (6,  NULL, 'Lịch làm việc',           'Lịch làm việc',           '/lich-lam-viec',         'CalendarOutlined',          6,  true),
  (7,  NULL, 'Tin nhắn',                'Tin nhắn',                '/tin-nhan',              'MessageOutlined',           7,  true),
  (8,  NULL, 'Thông báo',               'Thông báo',               '/thong-bao',             'BellOutlined',              8,  true),
  (9,  NULL, 'Họp không giấy',          'Họp không giấy',          '/hop-khong-giay',        'TeamOutlined',              9,  true),
  (10, NULL, 'Kho lưu trữ',             'Kho lưu trữ',             '/kho-luu-tru',           'DatabaseOutlined',          10, true),
  (11, NULL, 'Tài liệu',                'Tài liệu',                '/tai-lieu',              'FileTextOutlined',          11, true),
  (12, NULL, 'Hợp đồng',                'Hợp đồng',                '/hop-dong',              'AuditOutlined',             12, true),
  (13, NULL, 'Quản trị',                'Quản trị',                '/quan-tri',              'SettingOutlined',           13, true),
  (14, 13,   'Đơn vị',                  'Đơn vị',                  '/quan-tri/don-vi',       NULL,                        1,  true),
  (15, 13,   'Người dùng',              'Người dùng',              '/quan-tri/nguoi-dung',   NULL,                        2,  true),
  (16, 13,   'Nhóm quyền',              'Nhóm quyền',              '/quan-tri/nhom-quyen',   NULL,                        3,  true),
  (17, 13,   'Chức vụ',                 'Chức vụ',                 '/quan-tri/chuc-vu',      NULL,                        4,  true),
  (18, 13,   'Danh mục',                'Danh mục',                '/quan-tri/danh-muc',     NULL,                        5,  true),
  (19, NULL, 'Ký số',                   'Ký số',                   '/ky-so',                 'SafetyCertificateOutlined', 14, true),
  (20, 19,   'Cấu hình ký số hệ thống', 'Cấu hình ký số hệ thống', '/ky-so/cau-hinh',        NULL,                        1,  true),
  (21, 19,   'Tài khoản ký số cá nhân', 'Tài khoản ký số cá nhân', '/ky-so/tai-khoan',       NULL,                        2,  true),
  (22, 19,   'Danh sách ký số',         'Danh sách ký số',         '/ky-so/danh-sach',       NULL,                        3,  true)
ON CONFLICT (id) DO NOTHING;
SELECT setval('public.rights_id_seq', 100, true);

-- ─── 6. Role_of_staff (admin → Quản trị hệ thống + Ban Lãnh đạo) ───────────
INSERT INTO public.role_of_staff (staff_id, role_id) VALUES
  (1, 5),  -- admin → Quản trị hệ thống
  (1, 1)   -- admin → Ban Lãnh đạo
ON CONFLICT (staff_id, role_id) DO NOTHING;

-- ─── 7. Action_of_role (assign quyền) ───────────────────────────────────────
-- Quản trị hệ thống (role 5): TẤT CẢ rights
INSERT INTO public.action_of_role (role_id, right_id)
SELECT 5, id FROM public.rights
ON CONFLICT (role_id, right_id) DO NOTHING;

-- Ban Lãnh đạo (role 1): menu 1-12 + ký số 19, 21, 22 (trừ cấu hình system)
INSERT INTO public.action_of_role (role_id, right_id)
SELECT 1, id FROM public.rights WHERE id <= 12 OR id IN (19, 21, 22)
ON CONFLICT (role_id, right_id) DO NOTHING;

-- Cán bộ (role 2): menu 1-12 + ký số 19, 21, 22
INSERT INTO public.action_of_role (role_id, right_id)
SELECT 2, id FROM public.rights WHERE id <= 12 OR id IN (19, 21, 22)
ON CONFLICT (role_id, right_id) DO NOTHING;

-- Chỉ đạo điều hành (role 3): menu 1-12 + ký số 19, 21, 22
INSERT INTO public.action_of_role (role_id, right_id)
SELECT 3, id FROM public.rights WHERE id <= 12 OR id IN (19, 21, 22)
ON CONFLICT (role_id, right_id) DO NOTHING;

-- Nhóm Trưởng phòng (role 4): menu 1-12 + ký số 19, 21, 22
INSERT INTO public.action_of_role (role_id, right_id)
SELECT 4, id FROM public.rights WHERE id <= 12 OR id IN (19, 21, 22)
ON CONFLICT (role_id, right_id) DO NOTHING;

-- Văn thư (role 6): menu 1-12 (không ký số)
INSERT INTO public.action_of_role (role_id, right_id)
SELECT 6, id FROM public.rights WHERE id <= 12
ON CONFLICT (role_id, right_id) DO NOTHING;

-- ─── 8. Doc catalog skeleton ─────────────────────────────────────────────────
-- Doc types (8 loại văn bản cơ bản)
INSERT INTO edoc.doc_types (id, type_id, code, name, sort_order) VALUES
  (1, 2, 'CV',  'Công văn',   1),
  (2, 1, 'NQ',  'Nghị quyết', 2),
  (3, 1, 'QD',  'Quyết định', 3),
  (4, 1, 'CT',  'Chỉ thị',    4),
  (5, 1, 'QC',  'Quy chế',    5),
  (6, 2, 'TB',  'Thông báo',  6),
  (7, 2, 'BC',  'Báo cáo',    7),
  (8, 2, 'TTr', 'Tờ trình',   8)
ON CONFLICT (id) DO NOTHING;
SELECT setval('edoc.doc_types_id_seq', 20, true);

-- Doc fields (5 lĩnh vực)
INSERT INTO edoc.doc_fields (id, unit_id, code, name, sort_order, is_active) VALUES
  (1, 1, 'HC',   'Hành chính',          1, true),
  (2, 1, 'TC',   'Tài chính',           2, true),
  (3, 1, 'NS',   'Nhân sự',             3, true),
  (4, 1, 'CNTT', 'Công nghệ thông tin', 4, true),
  (5, 1, 'XDCB', 'Xây dựng cơ bản',     5, true)
ON CONFLICT (id) DO NOTHING;
SELECT setval('edoc.doc_fields_id_seq', 20, true);

-- Doc books (3 sổ mặc định UBND tỉnh)
INSERT INTO edoc.doc_books (id, unit_id, type_id, name, sort_order, is_default, created_by) VALUES
  (1, 1, 1, 'Sổ văn bản đến 2026', 1, true, 1),
  (2, 1, 2, 'Sổ văn bản đi 2026',  2, true, 1),
  (3, 1, 3, 'Sổ dự thảo 2026',     3, true, 1)
ON CONFLICT (id) DO NOTHING;
SELECT setval('edoc.doc_books_id_seq', 20, true);

COMMIT;

-- ─── 9. Signing provider config (cần session variable app.signing_secret_key) ───
-- Tách riêng ngoài BEGIN/COMMIT vì dùng pgp_sym_encrypt + RAISE EXCEPTION
DO $$
DECLARE
  v_key TEXT;
BEGIN
  -- Đọc session variable
  BEGIN
    v_key := current_setting('app.signing_secret_key', FALSE);
  EXCEPTION WHEN OTHERS THEN
    v_key := NULL;
  END;

  IF v_key IS NULL OR length(trim(v_key)) < 16 THEN
    RAISE EXCEPTION 'app.signing_secret_key chưa set hoặc quá ngắn (cần >= 16 ký tự). Chạy: SET app.signing_secret_key=''<key>'' trước khi \i file này';
  END IF;

  -- SmartCA VNPT (active=TRUE với credentials dev từ source cũ .NET)
  INSERT INTO public.signing_provider_config
    (provider_code, provider_name, base_url, client_id, client_secret,
     profile_id, extra_config, is_active, created_by, updated_by)
  VALUES (
    'SMARTCA_VNPT',
    'SmartCA VNPT',
    'https://gwsca.vnpt.vn',
    '4d00-638392811079166938.apps.smartcaapi.com',
    pgp_sym_encrypt('ZjA4MjE4NDg-MjU3Mi00ZDAw', v_key),
    NULL,
    '{}'::jsonb,
    TRUE,
    1, 1
  )
  ON CONFLICT (provider_code) DO NOTHING;

  -- MySign Viettel (active=FALSE, placeholder chưa cấu hình)
  INSERT INTO public.signing_provider_config
    (provider_code, provider_name, base_url, client_id, client_secret,
     profile_id, extra_config, is_active, created_by, updated_by)
  VALUES (
    'MYSIGN_VIETTEL',
    'MySign Viettel',
    '',
    '',
    pgp_sym_encrypt('placeholder_not_configured', v_key),
    '',
    '{}'::jsonb,
    FALSE,
    1, 1
  )
  ON CONFLICT (provider_code) DO NOTHING;

  RAISE NOTICE 'seed/001_required_data.sql: Master data OK (admin/Admin@123, 2 providers seeded)';
END $$;
