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

-- ─── Flag quyền theo chức vụ (idempotent, production-safe) ───
-- Lãnh đạo: được duyệt/phát hành/thu hồi/gửi VB
UPDATE public.positions
   SET is_leader = TRUE, is_handle_document = TRUE
 WHERE code IN ('GD', 'PGD', 'TP', 'PTP');

-- Nhân viên xử lý VB (sửa/xóa VB dự thảo cùng đơn vị)
UPDATE public.positions
   SET is_handle_document = TRUE
 WHERE code = 'CV';

-- Văn thư: giữ is_leader=FALSE, is_handle_document=FALSE (chỉ vào sổ + đọc)
-- Không cần UPDATE — default FALSE

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

-- ─── 3b. LGSP system staff (v3.2.2 fix #M4 — patched) ──────────────────────
-- Dedicated created_by tracking cho LGSP receive worker (thay vi gan ID admin).
-- password_hash = chuoi placeholder khong match bcrypt format -> login luon fail.
-- is_locked = TRUE: them lop bao ve. Khong show trong UI cau hinh nguoi dung.
--
-- LUU Y: KHONG hardcode id (truoc dung id=2, gay collision tren prod KH da co
-- user thuc id=2). Dung SELECT NOT EXISTS WHERE username de idempotent + an toan
-- voi prod data co san. Worker resolveSystemStaffId() lookup theo username,
-- nen id thuc te do sequence cap khong quan trong.
INSERT INTO public.staff (department_id, unit_id, position_id, code, username, password_hash, is_admin, is_locked,
                          first_name, last_name, gender, email, phone, mobile)
SELECT 1, 1, 1, 'SYS-LGSP', 'lgsp-system',
       'DISABLED_NO_LOGIN_LGSP_SYSTEM_ACCOUNT',
       false, true, 'He thong', 'LGSP', 1,
       'lgsp-system@noreply.local', '', ''
WHERE NOT EXISTS (SELECT 1 FROM public.staff WHERE username = 'lgsp-system');

-- Reset sequence ve MAX(id) hien tai de tranh duplicate key khi insert tiep theo
-- (pitfall #12: explicit id INSERT khong update sequence -> nextval cap id da ton tai).
SELECT setval(pg_get_serial_sequence('public.staff', 'id'),
              GREATEST((SELECT MAX(id) FROM public.staff), 100));

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
  (4,  NULL, 'Văn bản dự thảo',         'Văn bản dự thảo',         '/van-ban-du-thao',       'EditOutlined',              4,  true),
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

-- Doc books — 3 sổ mặc định (VB đến / VB đi / Dự thảo) cho MỖI đơn vị (1-5)
-- Nghiệp vụ: mỗi đơn vị cần đủ 3 loại sổ để tạo VB của loại tương ứng
INSERT INTO edoc.doc_books (id, unit_id, type_id, name, sort_order, is_default, created_by) VALUES
  -- UBND tỉnh Lào Cai (unit=1)
  (1,  1, 1, 'Sổ văn bản đến 2026',                   1, true, 1),
  (2,  1, 2, 'Sổ văn bản đi 2026',                    2, true, 1),
  (3,  1, 3, 'Sổ dự thảo 2026',                       3, true, 1),
  -- Sở Nội vụ (unit=2)
  (4,  2, 1, 'Sổ VB đến - Sở Nội vụ',                 1, true, 1),
  (5,  2, 2, 'Sổ VB đi - Sở Nội vụ',                  2, true, 1),
  (6,  2, 3, 'Sổ dự thảo - Sở Nội vụ',                3, true, 1),
  -- Sở Tài chính (unit=3)
  (7,  3, 1, 'Sổ VB đến - Sở Tài chính',              1, true, 1),
  (8,  3, 2, 'Sổ VB đi - Sở Tài chính',               2, true, 1),
  (9,  3, 3, 'Sổ dự thảo - Sở Tài chính',             3, true, 1),
  -- Sở Thông tin và Truyền thông (unit=4)
  (10, 4, 1, 'Sổ VB đến - Sở TT&TT',                  1, true, 1),
  (11, 4, 2, 'Sổ VB đi - Sở TT&TT',                   2, true, 1),
  (12, 4, 3, 'Sổ dự thảo - Sở TT&TT',                 3, true, 1),
  -- Văn phòng UBND tỉnh (unit=5)
  (13, 5, 1, 'Sổ VB đến - Văn phòng UBND tỉnh',       1, true, 1),
  (14, 5, 2, 'Sổ VB đi - Văn phòng UBND tỉnh',        2, true, 1),
  (15, 5, 3, 'Sổ dự thảo - Văn phòng UBND tỉnh',      3, true, 1)
ON CONFLICT (id) DO NOTHING;
SELECT setval('edoc.doc_books_id_seq', 50, true);

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

  -- ⚠️ LƯU Ý: Nếu DB đã có row provider từ seed cũ (is_active đang bật + dev creds),
  -- ON CONFLICT DO NOTHING sẽ KHÔNG overwrite. Chạy UPDATE thủ công để reset:
  --   UPDATE public.signing_provider_config
  --      SET is_active=FALSE, client_id='', client_secret=pgp_sym_encrypt('', v_key)
  --    WHERE provider_code='SMARTCA_VNPT';
  -- Hoặc chạy reset-db-windows.ps1 để reset fresh DB.

  -- SmartCA VNPT (production-safe: is_active=FALSE + empty credentials)
  -- Admin PHẢI login /ky-so/cau-hinh và nhập real credentials trước khi user ký được.
  -- Xem: deploy/README.md section "Development setup sau reset-db".
  INSERT INTO public.signing_provider_config
    (provider_code, provider_name, base_url, client_id, client_secret,
     profile_id, extra_config, is_active, created_by, updated_by)
  VALUES (
    'SMARTCA_VNPT',
    'SmartCA VNPT',
    'https://gwsca.vnpt.vn',
    '',
    pgp_sym_encrypt('', v_key),
    NULL,
    '{}'::jsonb,
    FALSE,
    1, 1
  )
  ON CONFLICT (provider_code) DO NOTHING;

  -- MySign Viettel (production-safe: is_active=FALSE + placeholder credentials)
  -- Admin PHẢI login /ky-so/cau-hinh và nhập real credentials + profile_id từ Viettel.
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

  -- SmartCA VNPT Tích hợp — chỉ dùng cho DEV TEST E2E.
  -- KHÁC SmartCA Thường: dùng endpoint v2 + TOTP secret + user password (KHÔNG cần app mobile confirm).
  -- KHÔNG khuyến nghị bật cho khách hàng cuối — rủi ro bảo mật (server giữ password + TOTP của user).
  -- Credential demo VNPT pre-fill sẵn (sample code chính thức), admin chỉ bấm Test Connection + Kích hoạt.
  -- User-level credentials (password, TOTP secret) đọc từ env vars SMARTCA_TH_USER_PASSWORD + SMARTCA_TH_TOTP_SECRET.
  -- ON CONFLICT DO UPDATE → idempotent re-apply seed khôi phục credential demo nếu admin lỡ xóa.
  INSERT INTO public.signing_provider_config
    (provider_code, provider_name, base_url, client_id, client_secret,
     profile_id, extra_config, is_active, created_by, updated_by)
  VALUES (
    'SMARTCA_VNPT_TH',
    'SmartCA VNPT Tích hợp (DEV TEST)',
    'https://gwsca.vnpt.vn',
    '4185-637127995547330633.apps.signserviceapi.com',
    pgp_sym_encrypt('NGNhMzdmOGE-OGM2Mi00MTg0', v_key),
    NULL,
    '{}'::jsonb,
    FALSE,
    1, 1
  )
  ON CONFLICT (provider_code) DO UPDATE SET
    base_url = EXCLUDED.base_url,
    client_id = EXCLUDED.client_id,
    client_secret = EXCLUDED.client_secret;

  RAISE NOTICE 'seed/001_required_data.sql: Master data OK (admin/Admin@123, 3 providers disabled — admin must configure via /ky-so/cau-hinh; SMARTCA_VNPT_TH chi dung cho dev test)';
END $$;

-- ============================================================================
-- Phase 33: Seed LGSP placeholder data (REQ LGSP-CRED-05)
-- Source: docs/Truc EDOC Lang Son - QLVB Doanh nghiep/QLVBDNAgencies.xlsx + List.txt
-- Pattern: production-safe — is_active=FALSE + placeholder secret. Admin nhap real qua UI Phase 37.
--
-- IMPORTANT: UPDATE statements match by name keyword (portable across dev/prod DBs):
--   - Tren dev DB Lao Cai (KHONG co 6 DN Lang Son) → 0 row affected, RAISE NOTICE skip
--   - Tren prod DB Lang Son (KH tao 6 DN voi name chuan) → UPDATE thanh cong → INSERT 9 row
-- See: .planning/phases/33-database-core-infrastructure/33-02-root-units-mapping.md
-- ============================================================================

-- --- Phase 33.1: UPDATE 6 root unit set lgsp_org_code (match by name keyword) ---
DO $$
DECLARE
  v_count_updated INT := 0;
BEGIN
  -- DN.001 — Cty CP Huu nghi Xuan Cuong
  UPDATE public.departments SET lgsp_org_code = 'H37.DN.001'
    WHERE parent_id IS NULL
      AND (lgsp_org_code IS NULL OR lgsp_org_code = '')
      AND (name ILIKE '%Xuân Cương%' OR name ILIKE '%Xuan Cuong%');
  GET DIAGNOSTICS v_count_updated = ROW_COUNT;
  IF v_count_updated = 0 THEN RAISE NOTICE 'Phase 33 seed: DN.001 (Xuan Cuong) KHONG match — root unit chua ton tai trong departments'; END IF;

  -- DN.002 — Cty CP San xuat va Thuong Mai Lang Son
  UPDATE public.departments SET lgsp_org_code = 'H37.DN.002'
    WHERE parent_id IS NULL
      AND (lgsp_org_code IS NULL OR lgsp_org_code = '')
      AND (name ILIKE '%Sản xuất%Thương Mại%Lạng Sơn%' OR name ILIKE '%San xuat%Thuong Mai%Lang Son%');
  GET DIAGNOSTICS v_count_updated = ROW_COUNT;
  IF v_count_updated = 0 THEN RAISE NOTICE 'Phase 33 seed: DN.002 (SX TM Lang Son) KHONG match'; END IF;

  -- DN.003 — Cty CP Tap doan DT & XD Phu Loc
  UPDATE public.departments SET lgsp_org_code = 'H37.DN.003'
    WHERE parent_id IS NULL
      AND (lgsp_org_code IS NULL OR lgsp_org_code = '')
      AND (name ILIKE '%Phú Lộc%' OR name ILIKE '%Phu Loc%');
  GET DIAGNOSTICS v_count_updated = ROW_COUNT;
  IF v_count_updated = 0 THEN RAISE NOTICE 'Phase 33 seed: DN.003 (Phu Loc) KHONG match'; END IF;

  -- DN.004 — Cty CP Kim loai mau Bac Bo
  UPDATE public.departments SET lgsp_org_code = 'H37.DN.004'
    WHERE parent_id IS NULL
      AND (lgsp_org_code IS NULL OR lgsp_org_code = '')
      AND (name ILIKE '%Kim loại màu%Bắc Bộ%' OR name ILIKE '%Kim loai mau%Bac Bo%');
  GET DIAGNOSTICS v_count_updated = ROW_COUNT;
  IF v_count_updated = 0 THEN RAISE NOTICE 'Phase 33 seed: DN.004 (Kim loai mau Bac Bo) KHONG match'; END IF;

  -- DN.005 — Cty TNHH TM XD Thien Phu
  UPDATE public.departments SET lgsp_org_code = 'H37.DN.005'
    WHERE parent_id IS NULL
      AND (lgsp_org_code IS NULL OR lgsp_org_code = '')
      AND (name ILIKE '%Thiên Phú%' OR name ILIKE '%Thien Phu%');
  GET DIAGNOSTICS v_count_updated = ROW_COUNT;
  IF v_count_updated = 0 THEN RAISE NOTICE 'Phase 33 seed: DN.005 (Thien Phu) KHONG match'; END IF;

  -- DN.006 — Cty TNHH MTV Xe dien DK Viet Nhat
  UPDATE public.departments SET lgsp_org_code = 'H37.DN.006'
    WHERE parent_id IS NULL
      AND (lgsp_org_code IS NULL OR lgsp_org_code = '')
      AND (name ILIKE '%Xe điện%DK%' OR name ILIKE '%Xe dien%DK%' OR name ILIKE '%Việt Nhật%' OR name ILIKE '%Viet Nhat%');
  GET DIAGNOSTICS v_count_updated = ROW_COUNT;
  IF v_count_updated = 0 THEN RAISE NOTICE 'Phase 33 seed: DN.006 (Xe dien DK Viet Nhat) KHONG match'; END IF;

  RAISE NOTICE 'Phase 33 seed: 6 root unit lgsp_org_code UPDATE done (skip neu name khong match — prod KH Lang Son setup 6 DN truoc khi re-apply)';
END $$;

-- --- Phase 33.2: INSERT 9 row placeholder vao lgsp_agency_config ---
-- 6 prod env (DN.001..006) + 3 sandbox env (DN.001/002/003 chi co sandbox)
-- secret_key_encrypted = pgp_sym_encrypt('placeholder_not_configured', SIGNING_SECRET_KEY)
-- is_active=FALSE — admin bat qua UI Phase 37 sau khi nhap credential that
DO $$
DECLARE
  v_key TEXT;
  v_unit_dn_001 INT;
  v_unit_dn_002 INT;
  v_unit_dn_003 INT;
  v_unit_dn_004 INT;
  v_unit_dn_005 INT;
  v_unit_dn_006 INT;
  v_inserted_count INT := 0;
BEGIN
  -- Doc SIGNING_SECRET_KEY tu session variable (set boi reset-db script hoac deploy script)
  BEGIN
    v_key := current_setting('app.signing_secret_key', FALSE);
  EXCEPTION WHEN OTHERS THEN
    v_key := NULL;
  END;

  IF v_key IS NULL OR length(trim(v_key)) < 16 THEN
    RAISE EXCEPTION 'Phase 33 seed: app.signing_secret_key chua set hoac < 16 ky tu. Chay: SET app.signing_secret_key=''<key>'' TRUOC khi apply seed/001';
  END IF;

  -- Lookup unit_id tu lgsp_org_code da UPDATE phia tren (root unit only)
  SELECT id INTO v_unit_dn_001 FROM public.departments WHERE lgsp_org_code = 'H37.DN.001' AND parent_id IS NULL LIMIT 1;
  SELECT id INTO v_unit_dn_002 FROM public.departments WHERE lgsp_org_code = 'H37.DN.002' AND parent_id IS NULL LIMIT 1;
  SELECT id INTO v_unit_dn_003 FROM public.departments WHERE lgsp_org_code = 'H37.DN.003' AND parent_id IS NULL LIMIT 1;
  SELECT id INTO v_unit_dn_004 FROM public.departments WHERE lgsp_org_code = 'H37.DN.004' AND parent_id IS NULL LIMIT 1;
  SELECT id INTO v_unit_dn_005 FROM public.departments WHERE lgsp_org_code = 'H37.DN.005' AND parent_id IS NULL LIMIT 1;
  SELECT id INTO v_unit_dn_006 FROM public.departments WHERE lgsp_org_code = 'H37.DN.006' AND parent_id IS NULL LIMIT 1;

  -- DN.001 prod + sandbox
  IF v_unit_dn_001 IS NOT NULL THEN
    INSERT INTO edoc.lgsp_agency_config (unit_id, environment, system_id, secret_key_encrypted, base_url, is_active, created_by, updated_by)
    VALUES (v_unit_dn_001, 'prod', 'H37.DN.001', pgp_sym_encrypt('placeholder_not_configured', v_key), 'https://apiltvb.langson.gov.vn', FALSE, 1, 1)
    ON CONFLICT (unit_id, environment) DO NOTHING;
    GET DIAGNOSTICS v_inserted_count = ROW_COUNT;

    INSERT INTO edoc.lgsp_agency_config (unit_id, environment, system_id, secret_key_encrypted, base_url, is_active, created_by, updated_by)
    VALUES (v_unit_dn_001, 'sandbox', 'H37.DN.001', pgp_sym_encrypt('placeholder_not_configured', v_key), 'https://trucltvb.langson.gov.vn/apithunghiem', FALSE, 1, 1)
    ON CONFLICT (unit_id, environment) DO NOTHING;
  ELSE
    RAISE NOTICE 'Phase 33 seed: DN.001 unit_id NULL — bo qua INSERT lgsp_agency_config (prod + sandbox)';
  END IF;

  -- DN.002 prod + sandbox
  IF v_unit_dn_002 IS NOT NULL THEN
    INSERT INTO edoc.lgsp_agency_config (unit_id, environment, system_id, secret_key_encrypted, base_url, is_active, created_by, updated_by)
    VALUES (v_unit_dn_002, 'prod', 'H37.DN.002', pgp_sym_encrypt('placeholder_not_configured', v_key), 'https://apiltvb.langson.gov.vn', FALSE, 1, 1)
    ON CONFLICT (unit_id, environment) DO NOTHING;

    INSERT INTO edoc.lgsp_agency_config (unit_id, environment, system_id, secret_key_encrypted, base_url, is_active, created_by, updated_by)
    VALUES (v_unit_dn_002, 'sandbox', 'H37.DN.002', pgp_sym_encrypt('placeholder_not_configured', v_key), 'https://trucltvb.langson.gov.vn/apithunghiem', FALSE, 1, 1)
    ON CONFLICT (unit_id, environment) DO NOTHING;
  ELSE
    RAISE NOTICE 'Phase 33 seed: DN.002 unit_id NULL — bo qua INSERT (prod + sandbox)';
  END IF;

  -- DN.003 prod + sandbox
  IF v_unit_dn_003 IS NOT NULL THEN
    INSERT INTO edoc.lgsp_agency_config (unit_id, environment, system_id, secret_key_encrypted, base_url, is_active, created_by, updated_by)
    VALUES (v_unit_dn_003, 'prod', 'H37.DN.003', pgp_sym_encrypt('placeholder_not_configured', v_key), 'https://apiltvb.langson.gov.vn', FALSE, 1, 1)
    ON CONFLICT (unit_id, environment) DO NOTHING;

    INSERT INTO edoc.lgsp_agency_config (unit_id, environment, system_id, secret_key_encrypted, base_url, is_active, created_by, updated_by)
    VALUES (v_unit_dn_003, 'sandbox', 'H37.DN.003', pgp_sym_encrypt('placeholder_not_configured', v_key), 'https://trucltvb.langson.gov.vn/apithunghiem', FALSE, 1, 1)
    ON CONFLICT (unit_id, environment) DO NOTHING;
  ELSE
    RAISE NOTICE 'Phase 33 seed: DN.003 unit_id NULL — bo qua INSERT (prod + sandbox)';
  END IF;

  -- DN.004/005/006 chi prod (khong co sandbox credential)
  IF v_unit_dn_004 IS NOT NULL THEN
    INSERT INTO edoc.lgsp_agency_config (unit_id, environment, system_id, secret_key_encrypted, base_url, is_active, created_by, updated_by)
    VALUES (v_unit_dn_004, 'prod', 'H37.DN.004', pgp_sym_encrypt('placeholder_not_configured', v_key), 'https://apiltvb.langson.gov.vn', FALSE, 1, 1)
    ON CONFLICT (unit_id, environment) DO NOTHING;
  ELSE
    RAISE NOTICE 'Phase 33 seed: DN.004 unit_id NULL — bo qua INSERT';
  END IF;

  IF v_unit_dn_005 IS NOT NULL THEN
    INSERT INTO edoc.lgsp_agency_config (unit_id, environment, system_id, secret_key_encrypted, base_url, is_active, created_by, updated_by)
    VALUES (v_unit_dn_005, 'prod', 'H37.DN.005', pgp_sym_encrypt('placeholder_not_configured', v_key), 'https://apiltvb.langson.gov.vn', FALSE, 1, 1)
    ON CONFLICT (unit_id, environment) DO NOTHING;
  ELSE
    RAISE NOTICE 'Phase 33 seed: DN.005 unit_id NULL — bo qua INSERT';
  END IF;

  IF v_unit_dn_006 IS NOT NULL THEN
    INSERT INTO edoc.lgsp_agency_config (unit_id, environment, system_id, secret_key_encrypted, base_url, is_active, created_by, updated_by)
    VALUES (v_unit_dn_006, 'prod', 'H37.DN.006', pgp_sym_encrypt('placeholder_not_configured', v_key), 'https://apiltvb.langson.gov.vn', FALSE, 1, 1)
    ON CONFLICT (unit_id, environment) DO NOTHING;
  ELSE
    RAISE NOTICE 'Phase 33 seed: DN.006 unit_id NULL — bo qua INSERT';
  END IF;

  -- Update sequence sau bulk INSERT (CLAUDE.md pitfall #12)
  PERFORM setval(pg_get_serial_sequence('edoc.lgsp_agency_config', 'id'), COALESCE((SELECT MAX(id) FROM edoc.lgsp_agency_config), 1));

  RAISE NOTICE 'Phase 33 seed: lgsp_agency_config INSERT done. So row thuc te phu thuoc 6 root unit DN.001..006 co lgsp_org_code dung khong. Admin bat is_active qua UI Phase 37.';
END $$;
