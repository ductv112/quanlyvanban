-- ================================================================
-- COMPREHENSIVE SEED DATA — e-Office Demo
-- TRUNCATES all tables and seeds fresh linked data
-- Run: docker exec eoffice-postgres psql -U postgres -d qlvb -f /docker-entrypoint-initdb.d/seed_full_demo.sql
-- ================================================================

BEGIN;

-- ============ TRUNCATE ALL (reverse dependency order) ============

-- Phase 6 tables (newest)
TRUNCATE edoc.notification_preferences CASCADE;
TRUNCATE edoc.notification_logs CASCADE;
TRUNCATE edoc.device_tokens CASCADE;
TRUNCATE edoc.digital_signatures CASCADE;
TRUNCATE edoc.lgsp_tracking CASCADE;
TRUNCATE edoc.lgsp_organizations CASCADE;
TRUNCATE edoc.lgsp_config CASCADE;
TRUNCATE edoc.send_doc_user_configs CASCADE;
TRUNCATE edoc.doc_columns CASCADE;
TRUNCATE esto.document_archives CASCADE;

-- Phase 5 tables (meetings)
TRUNCATE edoc.room_schedule_votes CASCADE;
TRUNCATE edoc.room_schedule_answers CASCADE;
TRUNCATE edoc.room_schedule_questions CASCADE;
TRUNCATE edoc.room_schedule_attachments CASCADE;
TRUNCATE edoc.room_schedule_staff CASCADE;
TRUNCATE edoc.room_schedules CASCADE;
TRUNCATE edoc.meeting_types CASCADE;
TRUNCATE edoc.rooms CASCADE;

-- Contracts (cont)
TRUNCATE cont.contract_attachments CASCADE;
TRUNCATE cont.contracts CASCADE;
TRUNCATE cont.contract_types CASCADE;

-- Documents (iso)
TRUNCATE iso.documents CASCADE;
TRUNCATE iso.document_categories CASCADE;

-- Archive (esto)
TRUNCATE esto.borrow_request_records CASCADE;
TRUNCATE esto.borrow_requests CASCADE;
TRUNCATE esto.records CASCADE;
TRUNCATE esto.fonds CASCADE;
TRUNCATE esto.warehouses CASCADE;

-- Calendar
TRUNCATE public.calendar_events CASCADE;

-- Messages & Notices
TRUNCATE edoc.notice_reads CASCADE;
TRUNCATE edoc.notices CASCADE;
TRUNCATE edoc.message_recipients CASCADE;
TRUNCATE edoc.messages CASCADE;

-- Inter-incoming docs
TRUNCATE edoc.inter_incoming_docs CASCADE;

-- Workflow tables
TRUNCATE edoc.doc_flow_step_staff CASCADE;
TRUNCATE edoc.doc_flow_step_links CASCADE;
TRUNCATE edoc.doc_flow_steps CASCADE;
TRUNCATE edoc.doc_flows CASCADE;

-- Handling docs (HSCV)
TRUNCATE edoc.attachment_handling_docs CASCADE;
TRUNCATE edoc.opinion_handling_docs CASCADE;
TRUNCATE edoc.staff_handling_docs CASCADE;
TRUNCATE edoc.handling_doc_links CASCADE;
TRUNCATE edoc.handling_docs CASCADE;

-- Core edoc tables
TRUNCATE edoc.user_outgoing_docs CASCADE;
TRUNCATE edoc.user_drafting_docs CASCADE;
TRUNCATE edoc.attachment_outgoing_docs CASCADE;
TRUNCATE edoc.attachment_drafting_docs CASCADE;
TRUNCATE edoc.outgoing_docs CASCADE;
TRUNCATE edoc.drafting_docs CASCADE;
TRUNCATE edoc.staff_notes CASCADE;
TRUNCATE edoc.leader_notes CASCADE;
TRUNCATE edoc.attachment_incoming_docs CASCADE;
TRUNCATE edoc.user_incoming_docs CASCADE;
TRUNCATE edoc.incoming_docs CASCADE;

-- Catalog tables
TRUNCATE edoc.delegations CASCADE;
TRUNCATE edoc.work_group_members CASCADE;
TRUNCATE edoc.work_groups CASCADE;
TRUNCATE edoc.signers CASCADE;
TRUNCATE edoc.email_templates CASCADE;
TRUNCATE edoc.sms_templates CASCADE;
TRUNCATE edoc.organizations CASCADE;
TRUNCATE edoc.doc_columns CASCADE;
TRUNCATE edoc.doc_books CASCADE;
TRUNCATE edoc.doc_fields CASCADE;
TRUNCATE edoc.doc_types CASCADE;

-- System tables
TRUNCATE public.work_calendar CASCADE;
TRUNCATE public.configurations CASCADE;
TRUNCATE public.refresh_tokens CASCADE;
TRUNCATE public.login_history CASCADE;
TRUNCATE public.action_of_role CASCADE;
TRUNCATE public.role_of_staff CASCADE;
TRUNCATE public.roles CASCADE;
TRUNCATE public.rights CASCADE;
TRUNCATE public.staff CASCADE;
TRUNCATE public.positions CASCADE;
TRUNCATE public.departments CASCADE;

-- ============ SYSTEM DATA (public schema) ============

-- ---- Positions ----
INSERT INTO public.positions (id, name, code, sort_order) VALUES
  (1, 'Giám đốc',          'GD',   1),
  (2, 'Phó Giám đốc',      'PGD',  2),
  (3, 'Trưởng phòng',       'TP',   3),
  (4, 'Phó Trưởng phòng',   'PTP',  4),
  (5, 'Chuyên viên',        'CV',   5),
  (6, 'Văn thư',            'VT',   6);

-- ---- Departments (tree: UBND tinh -> Cac So -> Cac Phong) ----
INSERT INTO public.departments (id, parent_id, code, name, short_name, is_unit, level, sort_order, allow_doc_book, created_by) VALUES
  (1,  NULL, 'UBND',   'UBND tỉnh Lào Cai',                   'UBND',   true,  0, 1,  true,  NULL),
  (2,  1,    'SNV',    'Sở Nội vụ',                            'SNV',    true,  1, 2,  true,  1),
  (3,  1,    'STC',    'Sở Tài chính',                         'STC',    true,  1, 3,  true,  1),
  (4,  1,    'STTTT',  'Sở Thông tin và Truyền thông',         'STTTT',  true,  1, 4,  true,  1),
  (5,  1,    'VPUBND', 'Văn phòng UBND tỉnh',                  'VP',     true,  1, 5,  true,  1),
  (6,  2,    'TCHC',   'Phòng Tổ chức - Hành chính',           'TCHC',   false, 2, 1,  false, 1),
  (7,  3,    'QLNS',   'Phòng Quản lý Ngân sách',              'QLNS',   false, 2, 1,  false, 1),
  (8,  4,    'CNTT',   'Phòng Công nghệ thông tin',            'CNTT',   false, 2, 1,  false, 1),
  (9,  5,    'TH',     'Phòng Tổng hợp',                       'TH',     false, 2, 1,  false, 1),
  (10, 2,    'CCVC',   'Phòng Công chức - Viên chức',          'CCVC',   false, 2, 2,  false, 1);

-- ---- Staff ----
-- Password: Admin@123 (bcrypt hash)
INSERT INTO public.staff (id, department_id, unit_id, position_id, code, username, password_hash, is_admin, first_name, last_name, gender, email, phone, mobile) VALUES
  (1,  1, 1, 1, 'NV001', 'admin',       '$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi', true,  'Quản trị',      'Hệ thống',  1, 'admin@laocai.gov.vn',           '02093801001', '0912000001'),
  (2,  2, 2, 1, 'NV002', 'nguyenvana',  '$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi', false, 'Nguyễn Văn',    'An',         1, 'nguyenvana@snv.laocai.gov.vn',  '02093801002', '0912000002'),
  (3,  3, 3, 1, 'NV003', 'tranthib',    '$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi', false, 'Trần Thị',      'Bình',       2, 'tranthib@stc.laocai.gov.vn',    '02093801003', '0912000003'),
  (4,  4, 4, 1, 'NV004', 'levand',      '$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi', false, 'Lê Văn',        'Đức',        1, 'levand@stttt.laocai.gov.vn',    '02093801004', '0912000004'),
  (5,  5, 5, 3, 'NV005', 'phamvane',    '$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi', false, 'Phạm Văn',      'Em',         1, 'phamvane@vpubnd.laocai.gov.vn', '02093801005', '0912000005'),
  (6,  6, 2, 5, 'NV006', 'hoangthif',   '$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi', false, 'Hoàng Thị',     'Phương',     2, 'hoangthif@snv.laocai.gov.vn',   '02093801006', '0912000006'),
  (7,  7, 3, 5, 'NV007', 'dangvang',    '$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi', false, 'Đặng Văn',      'Giang',      1, 'dangvang@stc.laocai.gov.vn',    '02093801007', '0912000007'),
  (8,  8, 4, 5, 'NV008', 'buithih',     '$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi', false, 'Bùi Thị',       'Hương',      2, 'buithih@stttt.laocai.gov.vn',   '02093801008', '0912000008'),
  (9,  9, 5, 6, 'NV009', 'vuthik',      '$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi', false, 'Vũ Thị',        'Kim',        2, 'vuthik@vpubnd.laocai.gov.vn',   '02093801009', '0912000009'),
  (10, 10,2, 4, 'NV010', 'dothil',      '$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi', false, 'Đỗ Thị',        'Lan',        2, 'dothil@snv.laocai.gov.vn',      '02093801010', '0912000010');

-- ---- Roles ----
INSERT INTO public.roles (id, unit_id, name, description) VALUES
  (1, NULL, 'Ban Lãnh đạo',            'Ban lãnh đạo cơ quan'),
  (2, NULL, 'Cán bộ',                  'Cán bộ, Chuyên viên'),
  (3, NULL, 'Chỉ đạo điều hành',       'Chỉ đạo điều hành'),
  (4, NULL, 'Nhóm Trưởng phòng',       'Nhóm Trưởng phòng'),
  (5, NULL, 'Quản trị hệ thống',       'Quản trị hệ thống'),
  (6, NULL, 'Văn thư',                  'Văn thư đơn vị');

-- ---- Role of Staff ----
INSERT INTO public.role_of_staff (staff_id, role_id) VALUES
  (1, 5), (1, 1),    -- admin: Quan tri + Lanh dao
  (2, 1), (2, 3),    -- nguyenvana: Lanh dao + Chi dao dieu hanh
  (3, 1), (3, 3),    -- tranthib: Lanh dao + Chi dao dieu hanh
  (4, 1), (4, 3),    -- levand: Lanh dao + Chi dao dieu hanh
  (5, 4), (5, 6),    -- phamvane: Truong phong + Van thu
  (6, 2),            -- hoangthif: Can bo
  (7, 2),            -- dangvang: Can bo
  (8, 2),            -- buithih: Can bo
  (9, 6),            -- vuthik: Van thu
  (10, 2);           -- dothil: Can bo

-- ---- Rights (menu tree) ----
INSERT INTO public.rights (id, parent_id, name, name_of_menu, action_link, icon, sort_order, show_menu) VALUES
  (1,  NULL, 'Dashboard',              'Dashboard',              '/dashboard',             'DashboardOutlined',    1,  true),
  (2,  NULL, 'Văn bản đến',            'Văn bản đến',            '/van-ban-den',           'InboxOutlined',        2,  true),
  (3,  NULL, 'Văn bản đi',             'Văn bản đi',             '/van-ban-di',            'SendOutlined',         3,  true),
  (4,  NULL, 'Dự thảo',                'Dự thảo',                '/du-thao',               'EditOutlined',         4,  true),
  (5,  NULL, 'Hồ sơ công việc',        'Hồ sơ công việc',        '/ho-so-cong-viec',       'FolderOutlined',       5,  true),
  (6,  NULL, 'Lịch làm việc',          'Lịch làm việc',          '/lich-lam-viec',         'CalendarOutlined',     6,  true),
  (7,  NULL, 'Tin nhắn',               'Tin nhắn',               '/tin-nhan',              'MessageOutlined',      7,  true),
  (8,  NULL, 'Thông báo',              'Thông báo',              '/thong-bao',             'BellOutlined',         8,  true),
  (9,  NULL, 'Họp không giấy',         'Họp không giấy',         '/hop-khong-giay',        'TeamOutlined',         9,  true),
  (10, NULL, 'Kho lưu trữ',            'Kho lưu trữ',            '/kho-luu-tru',           'DatabaseOutlined',     10, true),
  (11, NULL, 'Tài liệu',              'Tài liệu',              '/tai-lieu',              'FileTextOutlined',     11, true),
  (12, NULL, 'Hợp đồng',              'Hợp đồng',              '/hop-dong',              'AuditOutlined',        12, true),
  (13, NULL, 'Quản trị',              'Quản trị',              '/quan-tri',              'SettingOutlined',      13, true),
  (14, 13,   'Đơn vị',                'Đơn vị',                '/quan-tri/don-vi',       NULL,                   1,  true),
  (15, 13,   'Người dùng',            'Người dùng',            '/quan-tri/nguoi-dung',   NULL,                   2,  true),
  (16, 13,   'Nhóm quyền',            'Nhóm quyền',            '/quan-tri/nhom-quyen',   NULL,                   3,  true),
  (17, 13,   'Chức vụ',               'Chức vụ',               '/quan-tri/chuc-vu',      NULL,                   4,  true),
  (18, 13,   'Danh mục',              'Danh mục',              '/quan-tri/danh-muc',     NULL,                   5,  true);

-- Assign all rights to role "Quan tri he thong" (role_id=5)
INSERT INTO public.action_of_role (role_id, right_id)
SELECT 5, id FROM public.rights;

-- Assign operational rights (1-12) to role "Ban Lanh dao" (role_id=1)
INSERT INTO public.action_of_role (role_id, right_id)
SELECT 1, id FROM public.rights WHERE id <= 12;

-- Assign operational rights (1-12) to role "Can bo" (role_id=2)
INSERT INTO public.action_of_role (role_id, right_id)
SELECT 2, id FROM public.rights WHERE id <= 12;

-- ============ CATALOG DATA (edoc schema) ============

-- ---- Doc Types ----
INSERT INTO edoc.doc_types (id, type_id, code, name, sort_order) VALUES
  (1, 2, 'CV', 'Công văn',      1),
  (2, 1, 'NQ', 'Nghị quyết',    2),
  (3, 1, 'QD', 'Quyết định',    3),
  (4, 1, 'CT', 'Chỉ thị',       4),
  (5, 1, 'QC', 'Quy chế',       5),
  (6, 2, 'TB', 'Thông báo',     6),
  (7, 2, 'BC', 'Báo cáo',       7),
  (8, 2, 'TTr', 'Tờ trình',     8);

-- ---- Doc Fields ----
INSERT INTO edoc.doc_fields (id, unit_id, code, name, sort_order, is_active) VALUES
  (1, 1, 'HC',   'Hành chính',                    1, true),
  (2, 1, 'TC',   'Tài chính',                     2, true),
  (3, 1, 'NS',   'Nhân sự',                       3, true),
  (4, 1, 'CNTT', 'Công nghệ thông tin',           4, true),
  (5, 1, 'XDCB', 'Xây dựng cơ bản',              5, true);

-- ---- Doc Books ----
INSERT INTO edoc.doc_books (id, unit_id, type_id, name, sort_order, is_default, created_by) VALUES
  (1, 1, 1, 'Sổ văn bản đến 2026',      1, true,  1),
  (2, 1, 2, 'Sổ văn bản đi 2026',       2, true,  1),
  (3, 1, 3, 'Sổ dự thảo 2026',          3, true,  1),
  (4, 2, 1, 'Sổ VB đến - Sở Nội vụ',    1, true,  2),
  (5, 3, 1, 'Sổ VB đến - Sở Tài chính', 1, true,  3);

-- ---- Signers ----
INSERT INTO edoc.signers (id, unit_id, department_id, staff_id, sort_order) VALUES
  (1, 1, 1, 1, 1),
  (2, 2, 2, 2, 1),
  (3, 3, 3, 3, 1),
  (4, 4, 4, 4, 1);

-- ---- Work Groups ----
INSERT INTO edoc.work_groups (id, unit_id, name, sort_order, created_by) VALUES
  (1, 1, 'Ban Chỉ đạo Chuyển đổi số',           1, 1),
  (2, 1, 'Tổ Công tác cải cách hành chính',      2, 1);

INSERT INTO edoc.work_group_members (group_id, staff_id) VALUES
  (1, 1), (1, 2), (1, 4), (1, 8),
  (2, 1), (2, 5), (2, 6), (2, 10);

-- ---- Delegations ----
INSERT INTO edoc.delegations (id, from_staff_id, to_staff_id, start_date, end_date, note) VALUES
  (1, 2, 10, '2026-04-10', '2026-04-20', 'Ủy quyền xử lý văn bản khi đi công tác'),
  (2, 3, 7,  '2026-04-15', '2026-04-25', 'Ủy quyền ký văn bản trong thời gian nghỉ phép');

-- ---- Organizations ----
INSERT INTO edoc.organizations (id, unit_id, code, name, address, phone, email, secretary, level) VALUES
  (1, 1, 'UBND-LC', 'UBND tỉnh Lào Cai', 'Đường Hoàng Liên, TP Lào Cai', '02143840888', 'ubnd@laocai.gov.vn', 'Vũ Thị Kim', 1),
  (2, 2, 'SNV-LC',  'Sở Nội vụ tỉnh Lào Cai', '123 Trần Phú, TP Lào Cai', '02143840102', 'snv@laocai.gov.vn', 'Đỗ Thị Lan', 2);

-- ---- Work Calendar (ngay nghi) ----
INSERT INTO public.work_calendar (date, description, is_holiday, created_by) VALUES
  ('2026-04-30', 'Ngày Giải phóng miền Nam',     true, 1),
  ('2026-05-01', 'Ngày Quốc tế Lao động',        true, 1),
  ('2026-09-02', 'Ngày Quốc khánh',              true, 1);

-- ============ INCOMING DOCS (7 documents) ============
INSERT INTO edoc.incoming_docs (id, unit_id, received_date, number, notation, document_code, abstract, publish_unit, publish_date, signer, doc_book_id, doc_type_id, doc_field_id, urgent_id, secret_id, number_paper, number_copies, sents, created_by) VALUES
  (1, 1, NOW() - interval '1 day',   101, 'CV-101/UBND',   'CV101',  'V/v triển khai Chính phủ điện tử giai đoạn 2026-2030',                       'Văn phòng Chính phủ',    NOW() - interval '2 days',  'Trần Văn Sơn',       1, 1, 4, 1, 1, 5, 1, 'UBND tỉnh Lào Cai', 1),
  (2, 1, NOW() - interval '2 days',  102, 'QD-102/STC',    'QD102',  'Quyết định phê duyệt dự toán ngân sách năm 2026',                            'Sở Tài chính',           NOW() - interval '3 days',  'Trần Thị Bình',      1, 3, 2, 2, 1, 3, 2, 'Phòng Kế hoạch - Tài chính', 1),
  (3, 1, NOW() - interval '3 days',  103, 'CV-103/STTTT',  'CV103',  'V/v rà soát hạ tầng CNTT các cơ quan nhà nước',                               'Sở TT&TT',              NOW() - interval '4 days',  'Lê Văn Đức',         1, 1, 4, 1, 1, 2, 1, 'Phòng CNTT', 1),
  (4, 1, NOW() - interval '1 day',   104, 'CV-104/SNV',    'CV104',  'V/v tuyển dụng viên chức năm 2026',                                           'Sở Nội vụ',              NOW() - interval '2 days',  'Nguyễn Văn An',      1, 1, 3, 1, 1, 4, 1, 'Phòng Tổ chức cán bộ', 5),
  (5, 1, NOW() - interval '4 days',  105, 'NQ-105/HDND',   'NQ105',  'Nghị quyết về chương trình giám sát năm 2026',                                'HĐND tỉnh Lào Cai',     NOW() - interval '5 days',  'Hoàng Văn Dũng',     1, 2, 1, 1, 1, 8, 2, 'UBND tỉnh Lào Cai', 1),
  (6, 1, NOW(),                       106, 'CT-106/TTg',    'CT106',  'Chỉ thị về đẩy mạnh chuyển đổi số quốc gia',                                  'Thủ tướng Chính phủ',    NOW() - interval '1 day',   'Phạm Minh Chính',    1, 4, 4, 3, 1, 6, 3, 'Văn phòng UBND tỉnh', 1),
  (7, 2, NOW() - interval '2 days',  201, 'CV-201/BNV',    'CV201',  'V/v hướng dẫn thi nâng ngạch công chức năm 2026',                             'Bộ Nội vụ',              NOW() - interval '3 days',  'Phạm Thị Thanh Trà', 4, 1, 3, 2, 1, 10, 2, 'Phòng HC-QT', 2);

-- Mark some as handling
UPDATE edoc.incoming_docs SET is_handling = true WHERE id IN (1, 2, 4);

-- Incoming doc recipients
INSERT INTO edoc.user_incoming_docs (incoming_doc_id, staff_id, is_read) VALUES
  (1, 2, true),  (1, 4, true),  (1, 5, false),
  (2, 3, true),  (2, 7, false),
  (3, 4, true),  (3, 8, true),
  (4, 2, true),  (4, 6, false), (4, 10, false),
  (5, 1, true),  (5, 5, true),
  (6, 1, false), (6, 4, false),
  (7, 2, true),  (7, 6, false);

-- Leader notes on incoming docs
INSERT INTO edoc.leader_notes (incoming_doc_id, staff_id, content) VALUES
  (1, 1, 'Giao Sở TT&TT chủ trì, phối hợp các đơn vị triển khai. Hạn: 30/04/2026.'),
  (2, 1, 'Đồng ý dự toán. Sở TC theo dõi triển khai.'),
  (4, 2, 'Phòng TCHC chuẩn bị phương án tuyển dụng, báo cáo trước 20/04.');

-- ============ DRAFTING DOCS (4 documents) ============
INSERT INTO edoc.drafting_docs (id, unit_id, received_date, number, notation, abstract, drafting_unit_id, drafting_user_id, signer, doc_book_id, doc_type_id, doc_field_id, secret_id, urgent_id, recipients, approved, is_released, created_by) VALUES
  (1, 1, NOW() - interval '5 days', 1, 'DT-01/UBND', 'Dự thảo Quyết định ban hành Quy chế quản lý tài liệu điện tử',            1, 5, 'Quản trị Hệ thống', 3, 3, 1, 1, 1, 'Các Sở, ngành, UBND huyện/TX',    true,  true,  5),
  (2, 1, NOW() - interval '3 days', 2, 'DT-02/UBND', 'Dự thảo Công văn triển khai ứng dụng chữ ký số trong cơ quan nhà nước',    4, 8, 'Lê Văn Đức',        3, 1, 4, 1, 2, 'Các Sở TT&TT, Sở Nội vụ',         true,  true,  8),
  (3, 1, NOW() - interval '1 day',  3, 'DT-03/UBND', 'Dự thảo Báo cáo tình hình ứng dụng CNTT quý I/2026',                      4, 4, 'Lê Văn Đức',        3, 7, 4, 1, 1, 'UBND tỉnh, Bộ TT&TT',             false, false, 4),
  (4, 2, NOW() - interval '2 days', 1, 'DT-01/SNV',  'Dự thảo Kế hoạch tuyển dụng viên chức sự nghiệp GD năm 2026',             2, 6, 'Nguyễn Văn An',     3, 1, 3, 1, 1, 'Sở GD&ĐT, UBND các huyện/TX',     false, false, 6);

-- Set reject_reason for doc #4 (bị từ chối)
UPDATE edoc.drafting_docs SET reject_reason = 'Cần bổ sung thêm chỉ tiêu tuyển dụng từ các đơn vị sự nghiệp' WHERE id = 4;

-- Leader notes on drafting docs
INSERT INTO edoc.leader_notes (drafting_doc_id, staff_id, content) VALUES
  (1, 1, 'Duyệt nội dung. Phát hành ngay.'),
  (3, 2, 'Cần bổ sung số liệu quý I trước khi trình.');

-- ============ OUTGOING DOCS (4 documents — 2 linked to released drafts) ============
INSERT INTO edoc.outgoing_docs (id, unit_id, received_date, number, notation, document_code, abstract, drafting_unit_id, drafting_user_id, publish_unit_id, publish_date, signer, sign_date, doc_book_id, doc_type_id, doc_field_id, secret_id, urgent_id, recipients, approved, created_by) VALUES
  (1, 1, NOW() - interval '4 days', 201, 'QD-201/UBND',  'QD201',  'Quyết định ban hành Quy chế quản lý tài liệu điện tử tỉnh Lào Cai',       1, 5,  1, NOW() - interval '4 days', 'Quản trị Hệ thống', NOW() - interval '4 days', 2, 3, 1, 1, 1, 'Các Sở, ngành, UBND huyện/TX',       true,  5),
  (2, 1, NOW() - interval '2 days', 202, 'CV-202/UBND',  'CV202',  'Công văn triển khai ứng dụng chữ ký số trong cơ quan nhà nước',             4, 8,  1, NOW() - interval '2 days', 'Lê Văn Đức',        NOW() - interval '2 days', 2, 1, 4, 1, 2, 'Các Sở TT&TT, Sở Nội vụ',            true,  8),
  (3, 1, NOW() - interval '1 day',  203, 'CV-203/UBND',  'CV203',  'Công văn về việc tăng cường an toàn thông tin mạng cơ quan nhà nước',       4, 4,  1, NOW() - interval '1 day',  'Lê Văn Đức',        NOW() - interval '1 day',  2, 1, 4, 1, 2, 'Các Sở, Ban, ngành',                  true,  4),
  (4, 2, NOW(),                      101, 'CV-101/SNV',   'CV101S', 'Công văn hướng dẫn thực hiện chế độ báo cáo thống kê ngành nội vụ',        2, 10, 2, NOW(),                      'Nguyễn Văn An',     NOW(),                     2, 1, 3, 1, 1, 'Phòng Nội vụ các huyện/thành phố',   true,  2);

-- Mark outgoing docs 1,2 as digitally signed
UPDATE edoc.outgoing_docs SET is_digital_signed = 1 WHERE id IN (1, 2);

-- Leader notes on outgoing docs (AFTER outgoing_docs inserted)
INSERT INTO edoc.leader_notes (outgoing_doc_id, staff_id, content) VALUES
  (1, 1, 'Ban hành đúng tiến độ. Giao Sở TT&TT hướng dẫn thực hiện.'),
  (2, 2, 'Đẩy mạnh triển khai chữ ký số tại các đơn vị trực thuộc.');

-- Staff notes (bookmarks) with is_important (AFTER all doc tables populated)
INSERT INTO edoc.staff_notes (doc_type, doc_id, staff_id, note, is_important) VALUES
  ('incoming', 1, 2, 'Văn bản quan trọng — Chính phủ điện tử', true),
  ('incoming', 6, 2, 'Chỉ thị Thủ tướng — cần theo dõi', true),
  ('incoming', 3, 4, 'Liên quan đến hạ tầng CNTT', false),
  ('outgoing', 1, 5, 'QĐ do mình soạn', false),
  ('drafting', 3, 4, 'Báo cáo CNTT quý I', true);

-- ============ HANDLING DOCS / HSCV (6 records, linked to incoming docs) ============
INSERT INTO edoc.handling_docs (id, unit_id, department_id, name, abstract, doc_type_id, doc_field_id, start_date, end_date, curator, signer, status, progress, is_from_doc, created_by) VALUES
  (1, 1, NULL,  'Triển khai Chính phủ điện tử 2026-2030',                 'Xử lý CV-101/UBND về triển khai CPĐT',              1, 4, NOW() - interval '1 day',  NOW() + interval '30 days', 4, 1, 1, 30,  true, 1),
  (2, 1, NULL,  'Phê duyệt dự toán ngân sách 2026',                       'Xử lý QĐ-102/STC về dự toán ngân sách',             3, 2, NOW() - interval '2 days', NOW() + interval '15 days', 3, 1, 2, 60,  true, 1),
  (3, 1, NULL,  'Tuyển dụng viên chức năm 2026',                           'Xử lý CV-104/SNV về tuyển dụng viên chức',           1, 3, NOW() - interval '1 day',  NOW() + interval '45 days', 2, 1, 1, 20,  true, 5),
  (4, 1, NULL,  'Chuyển đổi số quốc gia — triển khai tại tỉnh',           'Xử lý CT-106/TTg về CĐS quốc gia',                  4, 4, NOW(),                     NOW() + interval '60 days', 4, 1, 0, 0,   true, 1),
  (5, 1, NULL,  'Soạn thảo báo cáo ứng dụng CNTT quý I/2026',            'Lập báo cáo tình hình ứng dụng CNTT',                7, 4, NOW() - interval '5 days', NOW() + interval '10 days', 4, 1, 3, 80,  false, 4),
  (6, 2, 6,     'Chuẩn bị phương án tuyển dụng Sở Nội vụ',                'Phương án tuyển dụng năm 2026 theo CV-201/BNV',      1, 3, NOW() - interval '2 days', NOW() + interval '20 days', 6, 2, 1, 40,  true, 2);

-- Mark HSCV 5 as completed
UPDATE edoc.handling_docs SET status = 4, progress = 100, complete_user_id = 4, complete_date = NOW() - interval '1 day' WHERE id = 5;

-- Link HSCV to incoming/outgoing docs
INSERT INTO edoc.handling_doc_links (handling_doc_id, doc_type, doc_id) VALUES
  (1, 'incoming', 1),
  (2, 'incoming', 2),
  (3, 'incoming', 4),
  (4, 'incoming', 6),
  (5, 'outgoing', 3),     -- HSCV 5 -> VB di 3
  (6, 'incoming', 7);

-- Staff assignments to HSCV
INSERT INTO edoc.staff_handling_docs (handling_doc_id, staff_id, role, step) VALUES
  (1, 4, 1, 'xu_ly'),  (1, 8, 2, 'phoi_hop'),
  (2, 3, 1, 'xu_ly'),  (2, 7, 2, 'phoi_hop'),
  (3, 2, 1, 'xu_ly'),  (3, 6, 2, 'phoi_hop'), (3, 10, 2, 'phoi_hop'),
  (4, 4, 1, 'xu_ly'),  (4, 8, 2, 'phoi_hop'),
  (5, 4, 1, 'xu_ly'),  (5, 8, 2, 'hoan_thanh'),
  (6, 6, 1, 'xu_ly'),  (6, 10, 2, 'phoi_hop');

-- Opinions on HSCV
INSERT INTO edoc.opinion_handling_docs (handling_doc_id, staff_id, content) VALUES
  (1, 4, 'Đã liên hệ Cục CNTT - Bộ TT&TT để xin hướng dẫn chi tiết.'),
  (1, 8, 'Đề xuất tổ chức hội thảo triển khai CĐS cấp tỉnh.'),
  (2, 3, 'Dự toán phù hợp, đề nghị phê duyệt.'),
  (5, 4, 'Báo cáo đã hoàn thành, gửi BGĐ phê duyệt.');

-- ============ INTER-INCOMING DOCS (3 records) ============
INSERT INTO edoc.inter_incoming_docs (id, unit_id, received_date, notation, document_code, abstract, publish_unit, publish_date, signer, doc_type_id, status, source_system, external_doc_id, created_by) VALUES
  (1, 1, NOW() - interval '1 day',  'LT-001/VPCP',  'LT001',  'V/v triển khai Đề án 06 về CSDL quốc gia dân cư',         'Văn phòng Chính phủ',   NOW() - interval '2 days',  'Trần Văn Sơn',         1, 'pending',    'LGSP-TW',    'VPCP-2026-001', 1),
  (2, 1, NOW() - interval '3 days', 'LT-002/BTTTT', 'LT002',  'V/v triển khai nền tảng LGSP tỉnh',                        'Bộ TT&TT',              NOW() - interval '4 days',  'Nguyễn Mạnh Hùng',     1, 'received',   'LGSP-TW',    'BTTTT-2026-015', 1),
  (3, 1, NOW(),                      'LT-003/UBND-YB', 'LT003', 'V/v phối hợp xử lý văn bản liên thông Tây Bắc',           'UBND tỉnh Yên Bái',     NOW() - interval '1 day',   'Trần Huy Tuấn',        1, 'pending',    'LGSP-YB',    'YB-2026-042',    1);

-- ============ MESSAGES (8 messages between staff) ============
INSERT INTO edoc.messages (id, from_staff_id, subject, content, parent_id) VALUES
  (1, 1, 'Họp giao ban tuần 15',                   'Kính gửi các đồng chí, cuộc họp giao ban tuần 15 sẽ diễn ra vào 8h00 thứ Hai ngày 14/04/2026 tại phòng họp A.',   NULL),
  (2, 3, 'Báo cáo tiến độ dự án CĐS',              'Anh/chị cho em xin báo cáo tiến độ dự án Chuyển đổi số đến hết tuần 14.',                                          NULL),
  (3, 1, 'Thông báo lịch nghỉ lễ 30/4-1/5',        'Thông báo đến toàn thể CBCC: Lịch nghỉ lễ từ 30/04 đến 01/05/2026.',                                               NULL),
  (4, 4, 'Đề xuất nâng cấp hệ thống mạng',         'Kính gửi BGĐ, em xin đề xuất phương án nâng cấp hạ tầng mạng nội bộ.',                                            NULL),
  (5, 1, 'Phân công nhiệm vụ Sprint 5',             'Phân công chi tiết nhiệm vụ Sprint 5 — Module HSCV cho từng thành viên.',                                          NULL),
  (6, 8, 'Báo lỗi chức năng tìm kiếm VB',           'Anh ơi, em phát hiện lỗi tìm kiếm VB đến với từ khóa tiếng Việt có dấu.',                                          NULL),
  (7, 1, 'Re: Báo lỗi chức năng tìm kiếm VB',      'Cảm ơn em đã báo, anh đã ghi nhận và sẽ xử lý trong Sprint tiếp theo.',                                            6),
  (8, 1, 'Kế hoạch demo cuối tuần',                 'Kế hoạch demo e-Office cho BLĐ ngày 18-19/04/2026. Các phòng ban chuẩn bị dữ liệu demo.',                         NULL);

INSERT INTO edoc.message_recipients (message_id, staff_id, is_read) VALUES
  (1, 2, true),  (1, 3, true),  (1, 4, true),  (1, 5, false),
  (2, 1, true),
  (3, 2, false), (3, 3, false), (3, 4, false), (3, 5, false), (3, 6, false), (3, 7, false), (3, 8, false), (3, 9, false), (3, 10, false),
  (4, 1, true),
  (5, 4, true),  (5, 8, true),
  (6, 1, true),
  (7, 8, true),
  (8, 2, false), (8, 3, false), (8, 4, false), (8, 5, true);

-- ============ NOTICES (6 system notices) ============
INSERT INTO edoc.notices (id, unit_id, title, content, notice_type, created_by) VALUES
  (1, NULL, 'Hệ thống e-Office chính thức hoạt động',              'Hệ thống Quản lý văn bản điện tử e-Office triển khai từ 14/04/2026. Đề nghị toàn thể CBCC sử dụng hệ thống mới.',   'system',       1),
  (2, NULL, 'Bảo trì hệ thống ngày 15/04/2026',                   'Hệ thống tạm ngưng từ 22h00 đến 23h00 ngày 15/04/2026 để nâng cấp và bảo trì.',                                      'maintenance',  1),
  (3, NULL, 'Cập nhật phiên bản v2.0 — Module mới',               'Tính năng mới: Họp không giấy, Kho lưu trữ, Tài liệu, Hợp đồng, LGSP, Ký số.',                                      'update',       1),
  (4, NULL, 'Hướng dẫn sử dụng module Ký số điện tử',            'Tài liệu hướng dẫn ký số đã được cập nhật tại mục Tài liệu chung.',                                                   'guide',        1),
  (5, NULL, 'Nhắc nhở đổi mật khẩu định kỳ',                      'Đề nghị toàn bộ CBCC đổi mật khẩu 3 tháng/lần để đảm bảo an toàn thông tin.',                                         'security',     1),
  (6, NULL, 'Demo hệ thống cho Ban lãnh đạo 18-19/04',            'Các phòng ban chuẩn bị dữ liệu demo. Lịch demo: Buổi sáng 18/04 — module VB, buổi chiều — module HSCV và Họp.',      'important',    1);

-- ============ CALENDAR EVENTS (8 events) ============
INSERT INTO public.calendar_events (id, title, description, start_time, end_time, all_day, color, scope, unit_id, created_by) VALUES
  (1, 'Họp giao ban đầu tuần',           'Họp giao ban tuần 15 — tất cả trưởng phòng',             '2026-04-14 08:00:00', '2026-04-14 09:00:00', false, '#1B3A5C', 'unit',     1, 1),
  (2, 'Review code Sprint 5',             'Review module HSCV và Dashboard',                        '2026-04-14 14:00:00', '2026-04-14 16:00:00', false, '#0891B2', 'personal', 1, 4),
  (3, 'Họp triển khai CĐS tỉnh',         'Ban chỉ đạo CĐS tỉnh Lào Cai',                         '2026-04-15 09:00:00', '2026-04-15 11:00:00', false, '#D97706', 'leader',   1, 1),
  (4, 'Đào tạo e-Office buổi 1',          'Đào tạo CBCC sử dụng hệ thống e-Office mới',            '2026-04-16 08:00:00', '2026-04-16 11:00:00', false, '#059669', 'unit',     1, 1),
  (5, 'Đào tạo e-Office buổi 2',          'Đào tạo tiếp: Module VB đi, Dự thảo, Ký số',            '2026-04-17 08:00:00', '2026-04-17 11:00:00', false, '#059669', 'unit',     1, 1),
  (6, 'Demo cho Ban lãnh đạo',            'Demo hệ thống e-Office cho BLĐ tỉnh',                   '2026-04-18 14:00:00', '2026-04-18 16:00:00', false, '#DC2626', 'leader',   1, 1),
  (7, 'Tiếp công dân định kỳ',            'Chủ tịch UBND tiếp công dân tháng 4',                    '2026-04-16 08:00:00', '2026-04-16 11:00:00', false, '#DC2626', 'leader',   1, 1),
  (8, 'Lễ chào cờ đầu tháng 5',           'Sinh hoạt chính trị đầu tháng 5/2026',                   '2026-05-01 07:00:00', '2026-05-01 08:00:00', false, '#D97706', 'unit',     1, 1);

-- ============ ARCHIVE / KHO LUU TRU (esto schema) ============

-- Warehouses (2 kho)
INSERT INTO esto.warehouses (id, unit_id, type_id, code, name, phone_number, address, status, parent_id, is_unit, warehouse_level, created_user_id) VALUES
  (1, 1, 1, 'KHO-01', 'Kho lưu trữ UBND tỉnh',         '02143840900', 'Tầng hầm, Trụ sở UBND tỉnh Lào Cai',            true, 0, true,  0, 1),
  (2, 1, 1, 'KHO-02', 'Kho lưu trữ Sở TT&TT',           '02143840901', 'Phòng 101, Trụ sở Sở TT&TT tỉnh Lào Cai',      true, 0, true,  0, 4),
  (3, 1, 2, 'KE-A1',  'Kệ A1 — Tủ văn bản hành chính',  NULL,          NULL,                                              true, 1, false, 1, 1),
  (4, 1, 2, 'KE-A2',  'Kệ A2 — Tủ văn bản tài chính',   NULL,          NULL,                                              true, 1, false, 1, 1);

-- Fonds (phong luu tru)
INSERT INTO esto.fonds (id, unit_id, parent_id, fond_code, fond_name, fond_history, archives_time, status, created_user_id) VALUES
  (1, 1, 0, 'P-UBND',  'Phông UBND tỉnh Lào Cai',       'Phông lưu trữ văn bản UBND tỉnh từ năm 2020',  '2020-2026', 1, 1),
  (2, 1, 0, 'P-SNV',   'Phông Sở Nội vụ',                'Phông lưu trữ văn bản Sở Nội vụ',               '2022-2026', 1, 2),
  (3, 1, 0, 'P-STTTT', 'Phông Sở TT&TT',                 'Phông lưu trữ Sở TT&TT tỉnh Lào Cai',          '2023-2026', 1, 4);

-- Archive records (ho so luu tru)
INSERT INTO esto.records (id, unit_id, fond_id, file_code, file_notation, title, maintenance, language, start_date, complete_date, total_doc, description, total_paper, warehouse_id, in_charge_staff_id, created_user_id) VALUES
  (1, 1, 1, 'HS-UBND-001', 'UBND/QD/2025', 'Hồ sơ Quyết định nhân sự năm 2025',                      '15 năm',   'Tiếng Việt', '2025-01-01', '2025-12-31', 45,  'Tập hợp QĐ bổ nhiệm, điều động, khen thưởng năm 2025',  120, 3, 5, 1),
  (2, 1, 1, 'HS-UBND-002', 'UBND/CV/2025', 'Hồ sơ Công văn hành chính năm 2025',                     '10 năm',   'Tiếng Việt', '2025-01-01', '2025-12-31', 230, 'Công văn hành chính nội bộ và liên cơ quan',              580, 3, 5, 1),
  (3, 1, 2, 'HS-SNV-001',  'SNV/TD/2025',  'Hồ sơ tuyển dụng công chức năm 2025',                    '20 năm',   'Tiếng Việt', '2025-03-01', '2025-09-30', 85,  'Hồ sơ thi tuyển, xét tuyển công chức năm 2025',          250, 3, 6, 2),
  (4, 1, 3, 'HS-STTTT-001','STTTT/CDS/2025','Hồ sơ Chuyển đổi số năm 2025',                          '10 năm',   'Tiếng Việt', '2025-01-01', '2025-12-31', 60,  'Kế hoạch, báo cáo, đánh giá CĐS năm 2025',              150, 4, 8, 4),
  (5, 1, 1, 'HS-UBND-003', 'UBND/NS/2025', 'Hồ sơ ngân sách năm 2025',                               '15 năm',   'Tiếng Việt', '2025-01-01', '2025-12-31', 120, 'Dự toán, quyết toán, phân bổ ngân sách năm 2025',        350, 4, 7, 1);

-- Borrow requests
INSERT INTO esto.borrow_requests (id, name, unit_id, emergency, notice, borrow_date, status, created_user_id) VALUES
  (1, 'Mượn hồ sơ tuyển dụng 2025 để đối chiếu',  1, 0, 'Cần đối chiếu số liệu cho kế hoạch tuyển dụng 2026', '2026-04-10', 1, 6),
  (2, 'Mượn hồ sơ ngân sách 2025 để lập dự toán',  1, 1, 'Cần gấp để lập dự toán ngân sách quý II/2026',        '2026-04-12', 0, 7);

INSERT INTO esto.borrow_request_records (borrow_request_id, record_id, return_date) VALUES
  (1, 3, '2026-04-25'),
  (2, 5, '2026-04-20');

-- ============ DOCUMENTS / TAI LIEU (iso schema) ============

-- Document categories
INSERT INTO iso.document_categories (id, parent_id, code, name, status, unit_id, created_user_id) VALUES
  (1, 0, 'ISO',    'Tài liệu ISO',                     1, 1, 1),
  (2, 0, 'NB',     'Tài liệu nội bộ',                  1, 1, 1),
  (3, 0, 'PQ',     'Văn bản pháp quy',                  1, 1, 1),
  (4, 1, 'ISO-QT', 'Quy trình ISO 9001:2015',          1, 1, 1),
  (5, 2, 'NB-HD',  'Hướng dẫn sử dụng',                1, 1, 1);

-- Documents
INSERT INTO iso.documents (id, unit_id, category_id, title, description, file_name, file_path, file_size, mime_type, keyword, status, created_user_id) VALUES
  (1, 1, 4, 'Quy trình tiếp nhận và xử lý văn bản đến',         'Quy trình ISO cho văn bản đến theo ISO 9001:2015',             'QT-QLVB-01.pdf',   'iso/QT-QLVB-01.pdf',     2048000, 'application/pdf', 'ISO, văn bản đến, quy trình',     1, 1),
  (2, 1, 4, 'Quy trình soạn thảo và ban hành văn bản',           'Quy trình ISO cho VB đi từ dự thảo đến phát hành',              'QT-QLVB-02.pdf',   'iso/QT-QLVB-02.pdf',     1536000, 'application/pdf', 'ISO, văn bản đi, soạn thảo',       1, 1),
  (3, 1, 5, 'Hướng dẫn sử dụng hệ thống e-Office v2.0',          'Tài liệu hướng dẫn chi tiết cho người dùng cuối',               'HD-eOffice-v2.pdf', 'nb/HD-eOffice-v2.pdf',   5120000, 'application/pdf', 'hướng dẫn, e-Office, sử dụng',    1, 1),
  (4, 1, 5, 'Hướng dẫn ký số điện tử trên e-Office',              'Hướng dẫn sử dụng chữ ký số SmartCA và EsignNEAC',              'HD-KySo.pdf',       'nb/HD-KySo.pdf',         3072000, 'application/pdf', 'ký số, SmartCA, hướng dẫn',        1, 1),
  (5, 1, 3, 'Nghị định 30/2020/NĐ-CP về công tác văn thư',       'Nghị định quy định về công tác văn thư trong cơ quan nhà nước', 'ND-30-2020.pdf',    'pq/ND-30-2020.pdf',     4096000, 'application/pdf', 'nghị định, văn thư, pháp quy',     1, 1),
  (6, 1, 3, 'Thông tư 01/2011/TT-BNV hướng dẫn thể thức VB',    'Thông tư hướng dẫn thể thức và kỹ thuật trình bày văn bản',     'TT-01-2011.pdf',    'pq/TT-01-2011.pdf',     2560000, 'application/pdf', 'thông tư, thể thức, trình bày',    1, 1);

-- ============ CONTRACTS / HOP DONG (cont schema) ============

-- Contract types
INSERT INTO cont.contract_types (id, unit_id, parent_id, code, name, sort_order, created_user_id) VALUES
  (1, 1, 0, 'CNTT',  'Hợp đồng CNTT',                   1, 1),
  (2, 1, 0, 'XD',    'Hợp đồng xây dựng',                2, 1),
  (3, 1, 0, 'MUA',   'Hợp đồng mua sắm',                 3, 1),
  (4, 1, 0, 'DV',    'Hợp đồng dịch vụ',                 4, 1);

-- Contracts
INSERT INTO cont.contracts (id, contract_type_id, department_id, unit_id, code, sign_date, input_date, name, signer, number, curator_name, currency, staff_id, note, status, amount, created_user_id) VALUES
  (1, 1, 8, 1, 'HD-CNTT-2026-001', '2026-01-15', '2026-01-16', 'Hợp đồng triển khai hệ thống e-Office v2.0',                           'Quản trị Hệ thống', 1, 'Bùi Thị Hương',  'VND', 8, 'Hợp đồng với đơn vị phát triển phần mềm',                                1, '2.500.000.000', 1),
  (2, 1, 8, 1, 'HD-CNTT-2026-002', '2026-02-01', '2026-02-02', 'Hợp đồng bảo trì hạ tầng mạng UBND tỉnh năm 2026',                    'Lê Văn Đức',        2, 'Bùi Thị Hương',  'VND', 8, 'Bảo trì hệ thống mạng, máy chủ, thiết bị CNTT',                          1, '800.000.000',   4),
  (3, 3, 9, 1, 'HD-MUA-2026-001',  '2026-03-10', '2026-03-11', 'Hợp đồng mua sắm máy tính và thiết bị văn phòng',                     'Phạm Văn Em',       1, 'Vũ Thị Kim',     'VND', 9, 'Mua 50 bộ máy tính, 10 máy in cho các phòng ban',                         2, '1.200.000.000', 5),
  (4, 4, 5, 1, 'HD-DV-2026-001',   '2026-04-01', '2026-04-02', 'Hợp đồng dịch vụ vệ sinh trụ sở UBND tỉnh năm 2026',                 'Phạm Văn Em',       1, 'Vũ Thị Kim',     'VND', 9, 'Dịch vụ vệ sinh hàng ngày cho trụ sở UBND',                               0, '360.000.000',   5);

-- ============ MEETINGS / HOP KHONG GIAY (edoc schema) ============

-- Meeting types
INSERT INTO edoc.meeting_types (id, unit_id, name, description, sort_order, created_user_id) VALUES
  (1, 1, 'Họp giao ban',         'Họp giao ban định kỳ',                      1, 1),
  (2, 1, 'Họp chuyên đề',        'Họp theo chuyên đề cụ thể',                 2, 1),
  (3, 1, 'Họp Ban lãnh đạo',     'Họp nội bộ Ban lãnh đạo',                   3, 1);

-- Rooms (phong hop)
INSERT INTO edoc.rooms (id, unit_id, name, code, location, note, sort_order, show_in_calendar, created_user_id) VALUES
  (1, 1, 'Phòng họp A — Tầng 3',     'PH-A', 'Tầng 3, Trụ sở UBND tỉnh',  'Sức chứa 50 người, có máy chiếu',    1, true, 1),
  (2, 1, 'Phòng họp B — Tầng 2',     'PH-B', 'Tầng 2, Trụ sở UBND tỉnh',  'Sức chứa 20 người, có TV lớn',       2, true, 1),
  (3, 1, 'Hội trường lớn',             'HT',   'Tầng 1, Trụ sở UBND tỉnh',  'Sức chứa 200 người',                 3, true, 1);

-- Room schedules (cuoc hop)
INSERT INTO edoc.room_schedules (id, unit_id, room_id, meeting_type_id, name, content, start_date, end_date, start_time, end_time, master_id, secretary_id, approved, meeting_status, created_user_id) VALUES
  (1, 1, 1, 1, 'Họp giao ban tuần 15/2026',                   'Giao ban tình hình tuần 15, triển khai nhiệm vụ tuần 16.',                      '2026-04-14', '2026-04-14', '08:00', '09:30', 1, 9, 1, 2, 1),
  (2, 1, 1, 2, 'Họp triển khai Chuyển đổi số tỉnh',           'Rà soát tiến độ CĐS, phân công nhiệm vụ CĐS quý II/2026.',                    '2026-04-15', '2026-04-15', '09:00', '11:00', 1, 5, 1, 0, 1),
  (3, 1, 3, 3, 'Họp Ban lãnh đạo — kế hoạch quý II',          'Thảo luận kế hoạch công tác quý II/2026.',                                      '2026-04-16', '2026-04-16', '14:00', '16:00', 1, 9, 1, 0, 1),
  (4, 1, 2, 2, 'Demo hệ thống e-Office cho BLĐ',              'Trình diễn các chức năng mới: HSCV, Họp, Kho lưu trữ, LGSP, Ký số.',          '2026-04-18', '2026-04-18', '14:00', '16:00', 4, 8, 0, 0, 4);

-- Room schedule staff
INSERT INTO edoc.room_schedule_staff (room_schedule_id, staff_id, user_type, is_secretary, attendance) VALUES
  -- Hop giao ban (da hop)
  (1, 1, 1, false, true),   -- Chu toa
  (1, 2, 0, false, true),
  (1, 3, 0, false, true),
  (1, 4, 0, false, true),
  (1, 5, 0, false, true),
  (1, 9, 2, true,  true),   -- Thu ky
  -- Hop CDS
  (2, 1, 1, false, false),
  (2, 2, 0, false, false),
  (2, 4, 0, false, false),
  (2, 5, 2, true,  false),
  (2, 8, 0, false, false),
  -- Hop BLD
  (3, 1, 1, false, false),
  (3, 2, 0, false, false),
  (3, 3, 0, false, false),
  (3, 4, 0, false, false),
  (3, 9, 2, true,  false),
  -- Demo
  (4, 1, 0, false, false),
  (4, 4, 1, false, false),
  (4, 8, 2, true,  false),
  (4, 5, 0, false, false);

-- ============ LGSP ORGANIZATIONS (Phase 6) ============
INSERT INTO edoc.lgsp_organizations (id, org_code, org_name, parent_code, address, email, phone, is_active) VALUES
  (1, 'BNV',       'Bộ Nội vụ',                                 NULL,     'Số 8 Tôn Thất Thuyết, Hà Nội',        'bnv@chinhphu.vn',       '024.38240101', true),
  (2, 'BTTTT',     'Bộ Thông tin và Truyền thông',              NULL,     'Số 18 Nguyễn Du, Hà Nội',             'btttt@mic.gov.vn',      '024.39437010', true),
  (3, 'BTC',       'Bộ Tài chính',                              NULL,     'Số 28 Trần Hưng Đạo, Hà Nội',        'btc@mof.gov.vn',        '024.22202828', true),
  (4, 'UBND-YB',   'UBND tỉnh Yên Bái',                         NULL,     'Đường Yên Ninh, TP Yên Bái',          'ubnd@yenbai.gov.vn',    '02163852223',  true),
  (5, 'UBND-HP',   'UBND tỉnh Hải Phòng',                       NULL,     'Số 18 Hoàng Diệu, Hải Phòng',        'ubnd@haiphong.gov.vn',  '02253842658',  true),
  (6, 'VPCP',      'Văn phòng Chính phủ',                        NULL,     'Số 1 Hoàng Hoa Thám, Hà Nội',        'vpcp@chinhphu.vn',      '024.08043100', true),
  (7, 'UBND-LC',   'UBND tỉnh Lào Cai',                         NULL,     'Đường Hoàng Liên, TP Lào Cai',        'ubnd@laocai.gov.vn',    '02143840888',  true);

-- ============ LGSP TRACKING (Phase 6) ============
INSERT INTO edoc.lgsp_tracking (id, outgoing_doc_id, incoming_doc_id, direction, lgsp_doc_id, dest_org_code, dest_org_name, status, sent_at, received_at, created_by) VALUES
  (1, 1,    NULL, 'send',    'LGSP-LC-2026-0001', 'BNV',     'Bộ Nội vụ',                 'success',    NOW() - interval '4 days', NULL,                      1),
  (2, 2,    NULL, 'send',    'LGSP-LC-2026-0002', 'BTTTT',   'Bộ Thông tin và Truyền thông', 'success', NOW() - interval '2 days', NULL,                      1),
  (3, NULL, 1,    'receive', 'LGSP-TW-2026-0101', 'VPCP',    'Văn phòng Chính phủ',        'success',    NULL,                      NOW() - interval '1 day',  1),
  (4, 3,    NULL, 'send',    'LGSP-LC-2026-0003', 'UBND-YB', 'UBND tỉnh Yên Bái',          'pending',    NOW() - interval '1 day',  NULL,                      4),
  (5, NULL, 7,    'receive', 'LGSP-TW-2026-0205', 'BNV',     'Bộ Nội vụ',                 'success',    NULL,                      NOW() - interval '2 days', 1);

-- ============ DIGITAL SIGNATURES (Phase 6) ============
INSERT INTO edoc.digital_signatures (id, doc_id, doc_type, staff_id, sign_method, certificate_serial, certificate_subject, certificate_issuer, signed_file_path, original_file_path, sign_status, signed_at) VALUES
  (1, 1, 'outgoing', 1, 'smart_ca',    'CERT-SMARTCA-001', 'CN=Quản trị Hệ thống, O=UBND tỉnh Lào Cai', 'VNPT-CA',    'signed/QD-201-signed.pdf',   'original/QD-201.pdf',   'signed',  NOW() - interval '4 days'),
  (2, 2, 'outgoing', 4, 'smart_ca',    'CERT-SMARTCA-004', 'CN=Lê Văn Đức, O=Sở TT&TT Lào Cai',         'VNPT-CA',    'signed/CV-202-signed.pdf',   'original/CV-202.pdf',   'signed',  NOW() - interval '2 days'),
  (3, 3, 'outgoing', 4, 'esign_neac',  'CERT-NEAC-004',    'CN=Lê Văn Đức, O=Sở TT&TT Lào Cai',         'NEAC-CA',    NULL,                         'original/CV-203.pdf',   'pending', NULL),
  (4, 1, 'drafting', 5, 'smart_ca',    'CERT-SMARTCA-005', 'CN=Phạm Văn Em, O=VP UBND tỉnh Lào Cai',    'VNPT-CA',    'signed/DT-01-signed.pdf',    'original/DT-01.pdf',    'signed',  NOW() - interval '5 days');

-- ============ NOTIFICATION SYSTEM (Phase 6) ============

-- Device tokens
INSERT INTO edoc.device_tokens (id, staff_id, device_token, device_type, is_active) VALUES
  (1, 1, 'fcm-token-admin-web-abc123def456',      'web',     true),
  (2, 2, 'fcm-token-nguyenvana-android-xyz789',    'android', true),
  (3, 4, 'fcm-token-levand-web-ghi012jkl345',      'web',     true),
  (4, 5, 'fcm-token-phamvane-ios-mno678pqr901',    'ios',     true);

-- Notification logs (across channels)
INSERT INTO edoc.notification_logs (id, staff_id, channel, event_type, title, body, ref_type, ref_id, send_status, sent_at) VALUES
  (1,  2, 'fcm',   'incoming_doc_assigned',  'Văn bản đến mới',             'Bạn được giao xử lý CV-101/UBND: V/v triển khai Chính phủ điện tử',                  'incoming_doc', 1, 'sent',   NOW() - interval '1 day'),
  (2,  4, 'fcm',   'incoming_doc_assigned',  'Văn bản đến mới',             'Bạn được giao xử lý CV-101/UBND: V/v triển khai Chính phủ điện tử',                  'incoming_doc', 1, 'sent',   NOW() - interval '1 day'),
  (3,  3, 'email', 'incoming_doc_assigned',  'Văn bản đến mới — QD-102/STC','Bạn được giao xử lý QĐ-102/STC: Quyết định phê duyệt dự toán ngân sách năm 2026',  'incoming_doc', 2, 'sent',   NOW() - interval '2 days'),
  (4,  4, 'sms',   'handling_doc_deadline',  'Nhắc hạn xử lý',              'HSCV "Triển khai CPĐT 2026-2030" sắp đến hạn (30 ngày). Tiến độ: 30%.',             'handling_doc', 1, 'sent',   NOW() - interval '12 hours'),
  (5,  8, 'fcm',   'handling_doc_assigned',  'Phối hợp HSCV',               'Bạn được giao phối hợp HSCV "Triển khai CPĐT 2026-2030".',                           'handling_doc', 1, 'sent',   NOW() - interval '1 day'),
  (6,  1, 'zalo',  'meeting_reminder',       'Nhắc lịch họp',               'Họp triển khai CĐS tỉnh — 09:00 ngày 15/04/2026 tại Phòng họp A.',                  'room_schedule', 2, 'sent',  NOW() - interval '6 hours'),
  (7,  2, 'email', 'meeting_invitation',     'Mời họp giao ban tuần 15',    'Bạn được mời tham dự Họp giao ban tuần 15/2026, 08:00 ngày 14/04/2026.',             'room_schedule', 1, 'sent',  NOW() - interval '2 days'),
  (8,  6, 'fcm',   'delegation_created',     'Ủy quyền mới',                'Bạn được ủy quyền xử lý văn bản từ Nguyễn Văn An (10/04 - 20/04/2026).',            'delegation',    1, 'sent',  NOW() - interval '4 days'),
  (9,  7, 'sms',   'delegation_created',     'Ủy quyền mới',                'Bạn được ủy quyền ký văn bản từ Trần Thị Bình (15/04 - 25/04/2026).',               'delegation',    2, 'sent',  NOW() - interval '12 hours'),
  (10, 4, 'fcm',   'digital_sign_pending',   'Yêu cầu ký số',              'VB đi CV-203/UBND cần ký số. Vui lòng ký để hoàn thành phát hành.',                   'outgoing_doc',  3, 'sent',  NOW() - interval '1 day');

-- Notification preferences
INSERT INTO edoc.notification_preferences (staff_id, channel, is_enabled) VALUES
  (1, 'fcm',   true),   (1, 'email', true),   (1, 'zalo',  true),   (1, 'sms',   false),
  (2, 'fcm',   true),   (2, 'email', true),   (2, 'zalo',  false),  (2, 'sms',   true),
  (3, 'fcm',   true),   (3, 'email', true),   (3, 'zalo',  false),  (3, 'sms',   false),
  (4, 'fcm',   true),   (4, 'email', true),   (4, 'zalo',  true),   (4, 'sms',   true),
  (5, 'fcm',   true),   (5, 'email', false),  (5, 'zalo',  false),  (5, 'sms',   false),
  (8, 'fcm',   true),   (8, 'email', true),   (8, 'zalo',  false),  (8, 'sms',   false);

-- ============ SEQUENCE RESETS ============
-- Reset all sequences to max(id) + 1

SELECT setval('public.positions_id_seq',          (SELECT COALESCE(MAX(id), 1) FROM public.positions));
SELECT setval('public.departments_id_seq',        (SELECT COALESCE(MAX(id), 1) FROM public.departments));
SELECT setval('public.staff_id_seq',              (SELECT COALESCE(MAX(id), 1) FROM public.staff));
SELECT setval('public.roles_id_seq',              (SELECT COALESCE(MAX(id), 1) FROM public.roles));
SELECT setval('public.rights_id_seq',             (SELECT COALESCE(MAX(id), 1) FROM public.rights));
SELECT setval('public.action_of_role_id_seq',     (SELECT COALESCE(MAX(id), 1) FROM public.action_of_role));
SELECT setval('public.role_of_staff_id_seq',      (SELECT COALESCE(MAX(id), 1) FROM public.role_of_staff));
SELECT setval('public.calendar_events_id_seq',    (SELECT COALESCE(MAX(id), 1) FROM public.calendar_events));
SELECT setval('public.configurations_id_seq',     (SELECT COALESCE(MAX(id), 1) FROM public.configurations));
SELECT setval('public.work_calendar_id_seq',      (SELECT COALESCE(MAX(id), 1) FROM public.work_calendar));

SELECT setval('edoc.doc_types_id_seq',            (SELECT COALESCE(MAX(id), 1) FROM edoc.doc_types));
SELECT setval('edoc.doc_fields_id_seq',           (SELECT COALESCE(MAX(id), 1) FROM edoc.doc_fields));
SELECT setval('edoc.doc_books_id_seq',            (SELECT COALESCE(MAX(id), 1) FROM edoc.doc_books));
SELECT setval('edoc.signers_id_seq',              (SELECT COALESCE(MAX(id), 1) FROM edoc.signers));
SELECT setval('edoc.work_groups_id_seq',          (SELECT COALESCE(MAX(id), 1) FROM edoc.work_groups));
SELECT setval('edoc.work_group_members_id_seq',   (SELECT COALESCE(MAX(id), 1) FROM edoc.work_group_members));
SELECT setval('edoc.delegations_id_seq',          (SELECT COALESCE(MAX(id), 1) FROM edoc.delegations));
SELECT setval('edoc.organizations_id_seq',        (SELECT COALESCE(MAX(id), 1) FROM edoc.organizations));

SELECT setval('edoc.incoming_docs_id_seq',        (SELECT COALESCE(MAX(id), 1) FROM edoc.incoming_docs));
SELECT setval('edoc.user_incoming_docs_id_seq',   (SELECT COALESCE(MAX(id), 1) FROM edoc.user_incoming_docs));
SELECT setval('edoc.leader_notes_id_seq',         (SELECT COALESCE(MAX(id), 1) FROM edoc.leader_notes));
SELECT setval('edoc.staff_notes_id_seq',          (SELECT COALESCE(MAX(id), 1) FROM edoc.staff_notes));
SELECT setval('edoc.drafting_docs_id_seq',        (SELECT COALESCE(MAX(id), 1) FROM edoc.drafting_docs));
SELECT setval('edoc.outgoing_docs_id_seq',        (SELECT COALESCE(MAX(id), 1) FROM edoc.outgoing_docs));
SELECT setval('edoc.handling_docs_id_seq',        (SELECT COALESCE(MAX(id), 1) FROM edoc.handling_docs));
SELECT setval('edoc.handling_doc_links_id_seq',   (SELECT COALESCE(MAX(id), 1) FROM edoc.handling_doc_links));
SELECT setval('edoc.staff_handling_docs_id_seq',  (SELECT COALESCE(MAX(id), 1) FROM edoc.staff_handling_docs));
SELECT setval('edoc.opinion_handling_docs_id_seq', (SELECT COALESCE(MAX(id), 1) FROM edoc.opinion_handling_docs));
SELECT setval('edoc.inter_incoming_docs_id_seq',  (SELECT COALESCE(MAX(id), 1) FROM edoc.inter_incoming_docs));
SELECT setval('edoc.messages_id_seq',             (SELECT COALESCE(MAX(id), 1) FROM edoc.messages));
SELECT setval('edoc.message_recipients_id_seq',   (SELECT COALESCE(MAX(id), 1) FROM edoc.message_recipients));
SELECT setval('edoc.notices_id_seq',              (SELECT COALESCE(MAX(id), 1) FROM edoc.notices));
SELECT setval('edoc.rooms_id_seq',                (SELECT COALESCE(MAX(id), 1) FROM edoc.rooms));
SELECT setval('edoc.meeting_types_id_seq',        (SELECT COALESCE(MAX(id), 1) FROM edoc.meeting_types));
SELECT setval('edoc.room_schedules_id_seq',       (SELECT COALESCE(MAX(id), 1) FROM edoc.room_schedules));
SELECT setval('edoc.room_schedule_staff_id_seq',  (SELECT COALESCE(MAX(id), 1) FROM edoc.room_schedule_staff));

SELECT setval('esto.warehouses_id_seq',           (SELECT COALESCE(MAX(id), 1) FROM esto.warehouses));
SELECT setval('esto.fonds_id_seq',                (SELECT COALESCE(MAX(id), 1) FROM esto.fonds));
SELECT setval('esto.records_id_seq',              (SELECT COALESCE(MAX(id), 1) FROM esto.records));
SELECT setval('esto.borrow_requests_id_seq',      (SELECT COALESCE(MAX(id), 1) FROM esto.borrow_requests));
SELECT setval('esto.borrow_request_records_id_seq', (SELECT COALESCE(MAX(id), 1) FROM esto.borrow_request_records));

SELECT setval('iso.document_categories_id_seq',   (SELECT COALESCE(MAX(id), 1) FROM iso.document_categories));
SELECT setval('iso.documents_id_seq',             (SELECT COALESCE(MAX(id), 1) FROM iso.documents));

SELECT setval('cont.contract_types_id_seq',       (SELECT COALESCE(MAX(id), 1) FROM cont.contract_types));
SELECT setval('cont.contracts_id_seq',            (SELECT COALESCE(MAX(id), 1) FROM cont.contracts));

SELECT setval('edoc.lgsp_organizations_id_seq',   (SELECT COALESCE(MAX(id), 1) FROM edoc.lgsp_organizations));
SELECT setval('edoc.lgsp_tracking_id_seq',        (SELECT COALESCE(MAX(id), 1) FROM edoc.lgsp_tracking));
SELECT setval('edoc.digital_signatures_id_seq',   (SELECT COALESCE(MAX(id), 1) FROM edoc.digital_signatures));
SELECT setval('edoc.device_tokens_id_seq',        (SELECT COALESCE(MAX(id), 1) FROM edoc.device_tokens));
SELECT setval('edoc.notification_logs_id_seq',    (SELECT COALESCE(MAX(id), 1) FROM edoc.notification_logs));
SELECT setval('edoc.notification_preferences_id_seq', (SELECT COALESCE(MAX(id), 1) FROM edoc.notification_preferences));

-- ============ VERIFY COUNTS ============
SELECT 'POSITIONS:       ' || count(*) FROM public.positions;
SELECT 'DEPARTMENTS:     ' || count(*) FROM public.departments;
SELECT 'STAFF:           ' || count(*) FROM public.staff;
SELECT 'ROLES:           ' || count(*) FROM public.roles;
SELECT 'RIGHTS:          ' || count(*) FROM public.rights;
SELECT 'DOC_TYPES:       ' || count(*) FROM edoc.doc_types;
SELECT 'DOC_FIELDS:      ' || count(*) FROM edoc.doc_fields;
SELECT 'DOC_BOOKS:       ' || count(*) FROM edoc.doc_books;
SELECT 'INCOMING_DOCS:   ' || count(*) FROM edoc.incoming_docs;
SELECT 'OUTGOING_DOCS:   ' || count(*) FROM edoc.outgoing_docs;
SELECT 'DRAFTING_DOCS:   ' || count(*) FROM edoc.drafting_docs;
SELECT 'HANDLING_DOCS:   ' || count(*) FROM edoc.handling_docs;
SELECT 'INTER_INCOMING:  ' || count(*) FROM edoc.inter_incoming_docs;
SELECT 'MESSAGES:        ' || count(*) FROM edoc.messages;
SELECT 'NOTICES:         ' || count(*) FROM edoc.notices;
SELECT 'CALENDAR_EVENTS: ' || count(*) FROM public.calendar_events;
SELECT 'WAREHOUSES:      ' || count(*) FROM esto.warehouses;
SELECT 'FONDS:           ' || count(*) FROM esto.fonds;
SELECT 'RECORDS:         ' || count(*) FROM esto.records;
SELECT 'BORROW_REQUESTS: ' || count(*) FROM esto.borrow_requests;
SELECT 'ISO_CATEGORIES:  ' || count(*) FROM iso.document_categories;
SELECT 'ISO_DOCUMENTS:   ' || count(*) FROM iso.documents;
SELECT 'CONTRACT_TYPES:  ' || count(*) FROM cont.contract_types;
SELECT 'CONTRACTS:       ' || count(*) FROM cont.contracts;
SELECT 'ROOMS:           ' || count(*) FROM edoc.rooms;
SELECT 'MEETINGS:        ' || count(*) FROM edoc.room_schedules;
SELECT 'LGSP_ORGS:       ' || count(*) FROM edoc.lgsp_organizations;
SELECT 'LGSP_TRACKING:   ' || count(*) FROM edoc.lgsp_tracking;
SELECT 'DIGITAL_SIGS:    ' || count(*) FROM edoc.digital_signatures;
SELECT 'DEVICE_TOKENS:   ' || count(*) FROM edoc.device_tokens;
SELECT 'NOTIF_LOGS:      ' || count(*) FROM edoc.notification_logs;
SELECT 'NOTIF_PREFS:     ' || count(*) FROM edoc.notification_preferences;
-- ============ DYNAMIC FORM — Doc columns (Thuộc tính VB) ============
-- Xóa cũ nếu có
DELETE FROM edoc.doc_columns WHERE is_system = false;

-- type_id: 1=VB đến, 2=VB đi, 3=VB dự thảo
INSERT INTO edoc.doc_columns (type_id, column_name, label, data_type, max_length, sort_order, is_mandatory, is_system, description) VALUES
  -- VB đến
  (1, 'old_notation', 'Số hiệu cũ', 'text', 100, 1, false, false, 'Số hiệu từ hệ thống cũ (nếu có)'),
  -- VB đi
  (2, 'effective_from', 'Hiệu lực từ ngày', 'date', NULL, 1, false, false, 'Ngày bắt đầu có hiệu lực'),
  (2, 'effective_to', 'Hiệu lực đến ngày', 'date', NULL, 2, false, false, 'Ngày hết hiệu lực'),
  -- VB dự thảo
  (3, 'review_deadline', 'Hạn góp ý', 'date', NULL, 1, false, false, 'Hạn chót gửi ý kiến góp ý'),
  (3, 'version_number', 'Số phiên bản', 'number', NULL, 2, false, false, 'Phiên bản dự thảo (VD: 1, 2, 3)')
ON CONFLICT (type_id, column_name) DO NOTHING;

-- ============ LGSP CONFIG ============
INSERT INTO edoc.lgsp_config (unit_id, endpoint_url, org_code, username, is_active) VALUES
  (1, 'https://lgsp.laocai.gov.vn/api', 'UBND_LC', 'admin_lgsp', true)
ON CONFLICT DO NOTHING;

SELECT 'DOC_COLUMNS:     ' || count(*) FROM edoc.doc_columns;
SELECT 'LGSP_CONFIG:     ' || count(*) FROM edoc.lgsp_config;

-- ============ A2: CALENDAR EVENTS bổ sung cho admin (staff_id=1) ============
INSERT INTO public.calendar_events (title, description, start_time, end_time, all_day, color, scope, unit_id, created_by) VALUES
  ('Kiểm tra email và phê duyệt VB',   'Xử lý văn bản đến, ký duyệt VB đi buổi sáng', '2026-04-21 07:30:00', '2026-04-21 08:30:00', false, '#1B3A5C', 'personal', 1, 1),
  ('Họp ban giám đốc',                  'Họp tổng kết tuần và giao nhiệm vụ tuần mới',  '2026-04-21 09:00:00', '2026-04-21 10:30:00', false, '#D97706', 'personal', 1, 1),
  ('Duyệt hồ sơ tuyển dụng',           'Xem hồ sơ ứng viên vị trí chuyên viên CNTT',   '2026-04-22 14:00:00', '2026-04-22 16:00:00', false, '#059669', 'personal', 1, 1)
ON CONFLICT DO NOTHING;

-- ============ A3: SMS & EMAIL TEMPLATES ============
INSERT INTO edoc.sms_templates (unit_id, name, content, description, is_active, created_by) VALUES
  (1, 'Thông báo VB đến mới',     'Ban nhan VB den moi so {doc_code} ngay {doc_date}. Vui long dang nhap e-Office de xu ly.',            'Gửi khi có VB đến mới',       true, 1),
  (1, 'Nhắc nhở xử lý VB',       'VB so {doc_code} sap het han xu ly ({deadline}). Vui long hoan thanh truoc thoi han.',                 'Nhắc trước hạn 1 ngày',       true, 1),
  (1, 'Thông báo cuộc họp',       'Ban duoc moi hop: {meeting_title} luc {meeting_time} tai {meeting_room}. Vui long xac nhan.',          'Gửi khi mời họp',             true, 1)
ON CONFLICT DO NOTHING;

INSERT INTO edoc.email_templates (unit_id, name, subject, content, description, is_active, created_by) VALUES
  (1, 'Thông báo VB đến mới',    'Văn bản đến mới: {doc_code}',
   '<p>Kính gửi <strong>{staff_name}</strong>,</p><p>Bạn nhận được văn bản đến mới số <strong>{doc_code}</strong> ngày {doc_date}.</p><p>Trích yếu: {abstract}</p><p>Vui lòng đăng nhập hệ thống e-Office để xử lý.</p><p>Trân trọng,<br/>Hệ thống e-Office</p>',
   'Email thông báo VB đến mới', true, 1),
  (1, 'Nhắc nhở hạn xử lý',     'Nhắc nhở: VB {doc_code} sắp hết hạn',
   '<p>Kính gửi <strong>{staff_name}</strong>,</p><p>Văn bản số <strong>{doc_code}</strong> có hạn xử lý đến <strong>{deadline}</strong>.</p><p>Vui lòng hoàn thành xử lý trước thời hạn.</p><p>Trân trọng,<br/>Hệ thống e-Office</p>',
   'Email nhắc hạn xử lý', true, 1),
  (1, 'Thông báo cuộc họp',      'Mời họp: {meeting_title}',
   '<p>Kính gửi <strong>{staff_name}</strong>,</p><p>Bạn được mời tham dự cuộc họp:</p><ul><li>Tiêu đề: <strong>{meeting_title}</strong></li><li>Thời gian: {meeting_time}</li><li>Phòng họp: {meeting_room}</li></ul><p>Vui lòng xác nhận tham dự trên hệ thống.</p><p>Trân trọng,<br/>Hệ thống e-Office</p>',
   'Email mời họp', true, 1)
ON CONFLICT DO NOTHING;

-- ============ A4: PROVINCES / DISTRICTS / COMMUNES (sample data) ============
INSERT INTO public.provinces (id, name, code, is_active) VALUES
  (1,  'Lào Cai',      '10', true),
  (2,  'Hà Nội',       '01', true),
  (3,  'TP Hồ Chí Minh','79', true),
  (4,  'Yên Bái',      '15', true),
  (5,  'Hà Giang',     '02', true),
  (6,  'Lai Châu',     '12', true),
  (7,  'Sơn La',       '14', true),
  (8,  'Điện Biên',    '11', true),
  (9,  'Đà Nẵng',      '48', true),
  (10, 'Hải Phòng',    '31', true)
ON CONFLICT DO NOTHING;

SELECT setval('provinces_id_seq', (SELECT COALESCE(MAX(id), 1) FROM public.provinces));

INSERT INTO public.districts (id, province_id, name, code, is_active) VALUES
  -- Lào Cai
  (1,  1, 'TP Lào Cai',     '080', true),
  (2,  1, 'Sa Pa',           '082', true),
  (3,  1, 'Bát Xát',        '083', true),
  (4,  1, 'Bảo Thắng',      '085', true),
  (5,  1, 'Bảo Yên',        '086', true),
  (6,  1, 'Văn Bàn',        '091', true),
  -- Hà Nội
  (7,  2, 'Ba Đình',        '001', true),
  (8,  2, 'Hoàn Kiếm',      '002', true),
  (9,  2, 'Đống Đa',        '006', true),
  (10, 2, 'Cầu Giấy',       '005', true)
ON CONFLICT DO NOTHING;

SELECT setval('districts_id_seq', (SELECT COALESCE(MAX(id), 1) FROM public.districts));

INSERT INTO public.communes (id, district_id, name, code, is_active) VALUES
  -- TP Lào Cai
  (1, 1, 'Phường Cốc Lếu',    '02545', true),
  (2, 1, 'Phường Duyên Hải',   '02548', true),
  (3, 1, 'Phường Lào Cai',     '02551', true),
  (4, 1, 'Phường Kim Tân',     '02554', true),
  -- Sa Pa
  (5, 2, 'TT Sa Pa',           '02590', true),
  (6, 2, 'Xã San Sả Hồ',      '02596', true),
  -- Bát Xát
  (7, 3, 'TT Bát Xát',        '02560', true),
  (8, 3, 'Xã A Mú Sung',      '02563', true)
ON CONFLICT DO NOTHING;

SELECT setval('communes_id_seq', (SELECT COALESCE(MAX(id), 1) FROM public.communes));

-- ============ A5: CONFIGURATIONS (system settings) ============
INSERT INTO public.configurations (unit_id, key, value, description) VALUES
  (1, 'org_name',          'Ủy ban Nhân dân tỉnh Lào Cai',  'Tên cơ quan'),
  (1, 'org_code',          'UBND_LAOCAI',                     'Mã cơ quan'),
  (1, 'org_address',       'Đường Hoàng Liên, TP Lào Cai',   'Địa chỉ cơ quan'),
  (1, 'org_phone',         '02143840900',                     'Số điện thoại'),
  (1, 'org_fax',           '02143840901',                     'Số fax'),
  (1, 'org_email',         'ubnd@laocai.gov.vn',              'Email cơ quan'),
  (1, 'org_website',       'https://laocai.gov.vn',           'Website'),
  (1, 'max_upload_size',   '52428800',                        'Dung lượng upload tối đa (bytes) — 50MB'),
  (1, 'session_timeout',   '900',                             'Thời gian timeout session (giây) — 15 phút'),
  (1, 'password_min_len',  '6',                               'Độ dài tối thiểu mật khẩu'),
  (1, 'password_expiry',   '90',                              'Số ngày hết hạn mật khẩu'),
  (1, 'doc_number_format', '{year}/{book_code}/{number}',     'Định dạng số văn bản'),
  (1, 'default_language',  'vi',                              'Ngôn ngữ mặc định')
ON CONFLICT (unit_id, key) DO NOTHING;

-- ============ FIX sequence cho các bảng mới seed ============
SELECT setval('edoc.sms_templates_id_seq',   (SELECT COALESCE(MAX(id), 1) FROM edoc.sms_templates));
SELECT setval('edoc.email_templates_id_seq', (SELECT COALESCE(MAX(id), 1) FROM edoc.email_templates));
SELECT setval('configurations_id_seq',       (SELECT COALESCE(MAX(id), 1) FROM public.configurations));
SELECT setval('calendar_events_id_seq',      (SELECT COALESCE(MAX(id), 1) FROM public.calendar_events));

-- ============ VERIFY COUNTS (bổ sung) ============
SELECT 'SMS_TEMPLATES:   ' || count(*) FROM edoc.sms_templates;
SELECT 'EMAIL_TEMPLATES: ' || count(*) FROM edoc.email_templates;
SELECT 'PROVINCES:       ' || count(*) FROM public.provinces;
SELECT 'DISTRICTS:       ' || count(*) FROM public.districts;
SELECT 'COMMUNES:        ' || count(*) FROM public.communes;
SELECT 'CONFIGURATIONS:  ' || count(*) FROM public.configurations;
SELECT 'CALENDAR_EVENTS: ' || count(*) FROM public.calendar_events;

SELECT '=== SEED FULL DEMO COMPLETE ===' as result;

COMMIT;
