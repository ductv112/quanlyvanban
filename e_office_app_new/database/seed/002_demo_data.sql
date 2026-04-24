-- ============================================================================
-- seed/002_demo_data.sql — RICH DEMO DATA (test env, skip production)
-- Idempotent: WHERE NOT EXISTS + ON CONFLICT DO NOTHING
-- Depends on: seed/001_required_data.sql (admin user id=1, departments 1-5)
--
-- Data volume target:
--   - 10 user thêm (id 2-11) + admin (id=1) = 11 user tổng
--   - 5 phòng ban con (id 6-10) tổng 10 departments
--   - 3 sổ văn bản bổ sung cho 3 Sở (doc_books id 4-6)
--   - 4 signers, 2 work_groups + 8 work_group_members, 2 delegations, 2 organizations
--   - 50 VB đến (id 1-50)
--   - 50 user_incoming_docs (1 record/VB — staff rotate 2-10)
--   - 30 VB đi (id 1-30)
--   - 20 VB dự thảo (id 1-20)
--   - 15 HSCV (id 1-15, mix status 0→4 + -1 + -2)
--   - 10 VB liên thông (id 1-10, mix status)
--   - 20 attachment_incoming_docs (id 1-20)
--   - 15 attachment_outgoing_docs (id 1-15)
--   - 30 notices (id 1-30)
--   - 8 leader_notes (id 1-8, mix incoming/outgoing/drafting)
--
-- TỔNG: ≥ 260 records across 17 tables
--
-- CÁCH CHẠY:
--   docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev -v ON_ERROR_STOP=1 \
--     -f - < e_office_app_new/database/seed/002_demo_data.sql
-- ============================================================================

\set ON_ERROR_STOP on

-- ─── Guard: verify seed 001 đã chạy ─────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.staff WHERE username='admin') THEN
    RAISE EXCEPTION 'seed/001_required_data.sql chưa được apply. Chạy seed 001 TRƯỚC seed 002.';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.departments WHERE id=1) THEN
    RAISE EXCEPTION 'Root department id=1 không tồn tại. Chạy seed 001 TRƯỚC.';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.roles WHERE id=5) THEN
    RAISE EXCEPTION 'Role id=5 (Quản trị hệ thống) không tồn tại. Chạy seed 001 TRƯỚC.';
  END IF;
END $$;

BEGIN;

-- ─── 1. Phòng ban con (5 phòng, id 6-10 — tổng 10 departments) ──────────────
INSERT INTO public.departments (id, parent_id, code, name, short_name, is_unit, level, sort_order, allow_doc_book, created_by) VALUES
  (6,  2, 'TCHC', 'Phòng Tổ chức - Hành chính',   'TCHC', false, 2, 1, false, 1),
  (7,  3, 'QLNS', 'Phòng Quản lý Ngân sách',      'QLNS', false, 2, 1, false, 1),
  (8,  4, 'CNTT', 'Phòng Công nghệ thông tin',    'CNTT', false, 2, 1, false, 1),
  (9,  5, 'TH',   'Phòng Tổng hợp',               'TH',   false, 2, 1, false, 1),
  (10, 2, 'CCVC', 'Phòng Công chức - Viên chức', 'CCVC', false, 2, 2, false, 1)
ON CONFLICT (id) DO NOTHING;
SELECT setval('public.departments_id_seq', 100, true);

-- ─── 2. 10 user thường (id 2-11, password Admin@123 — cùng hash admin) ─────
-- Password hash cho "Admin@123" (bcrypt 10 rounds)
INSERT INTO public.staff (id, department_id, unit_id, position_id, code, username, password_hash, is_admin,
                          first_name, last_name, gender, email, phone, mobile) VALUES
  (2,  2,  2, 1, 'NV002', 'nguyenvana',   '$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi', false, 'Nguyễn Văn',   'An',      1, 'nguyenvana@snv.laocai.gov.vn',   '02093801002', '0912000002'),
  (3,  3,  3, 1, 'NV003', 'tranthib',     '$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi', false, 'Trần Thị',     'Bình',    2, 'tranthib@stc.laocai.gov.vn',     '02093801003', '0912000003'),
  (4,  4,  4, 1, 'NV004', 'levand',       '$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi', false, 'Lê Văn',       'Đức',     1, 'levand@stttt.laocai.gov.vn',     '02093801004', '0912000004'),
  (5,  5,  5, 3, 'NV005', 'phamvane',     '$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi', false, 'Phạm Văn',     'Em',      1, 'phamvane@vpubnd.laocai.gov.vn',  '02093801005', '0912000005'),
  (6,  6,  2, 5, 'NV006', 'hoangthif',    '$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi', false, 'Hoàng Thị',    'Phương',  2, 'hoangthif@snv.laocai.gov.vn',    '02093801006', '0912000006'),
  (7,  7,  3, 5, 'NV007', 'dangvang',     '$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi', false, 'Đặng Văn',     'Giang',   1, 'dangvang@stc.laocai.gov.vn',     '02093801007', '0912000007'),
  (8,  8,  4, 5, 'NV008', 'buithih',      '$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi', false, 'Bùi Thị',      'Hương',   2, 'buithih@stttt.laocai.gov.vn',    '02093801008', '0912000008'),
  (9,  9,  5, 6, 'NV009', 'vuthik',       '$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi', false, 'Vũ Thị',       'Kim',     2, 'vuthik@vpubnd.laocai.gov.vn',    '02093801009', '0912000009'),
  (10, 10, 2, 4, 'NV010', 'dothil',       '$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi', false, 'Đỗ Thị',       'Lan',     2, 'dothil@snv.laocai.gov.vn',       '02093801010', '0912000010'),
  (11, 1,  1, 6, 'NV011', 'vanthuubnd',   '$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi', false, 'Văn Thư',      'UBND',    2, 'vanthu@ubnd.laocai.gov.vn',      '02093801011', '0912000011')
ON CONFLICT (id) DO NOTHING;
SELECT setval('public.staff_id_seq', 100, true);

-- ─── 3. Assign roles cho 10 user thường ─────────────────────────────────────
INSERT INTO public.role_of_staff (staff_id, role_id) VALUES
  (2,  1), (2,  3),   -- nguyenvana: Lãnh đạo + Chỉ đạo điều hành
  (3,  1), (3,  3),   -- tranthib: Lãnh đạo + Chỉ đạo điều hành
  (4,  1), (4,  3),   -- levand: Lãnh đạo + Chỉ đạo điều hành
  (5,  4), (5,  6),   -- phamvane: Trưởng phòng + Văn thư
  (6,  2),            -- hoangthif: Cán bộ
  (7,  2),            -- dangvang: Cán bộ
  (8,  2),            -- buithih: Cán bộ
  (9,  6),            -- vuthik: Văn thư
  (10, 2),            -- dothil: Cán bộ
  (11, 6)             -- vanthuubnd: Văn thư
ON CONFLICT (staff_id, role_id) DO NOTHING;

-- ─── 4. Doc books bổ sung (3 sổ cho 3 Sở) ──────────────────────────────────
INSERT INTO edoc.doc_books (id, unit_id, type_id, name, sort_order, is_default, created_by) VALUES
  (4, 2, 1, 'Sổ VB đến - Sở Nội vụ',     1, true, 2),
  (5, 3, 1, 'Sổ VB đến - Sở Tài chính',  1, true, 3),
  (6, 4, 1, 'Sổ VB đến - Sở TT&TT',      1, true, 4)
ON CONFLICT (id) DO NOTHING;
SELECT setval('edoc.doc_books_id_seq', 20, true);

-- ─── 5. Signers (4 người ký — mỗi đơn vị 1 người) ──────────────────────────
INSERT INTO edoc.signers (id, unit_id, department_id, staff_id, sort_order) VALUES
  (1, 1, 1, 1, 1),
  (2, 2, 2, 2, 1),
  (3, 3, 3, 3, 1),
  (4, 4, 4, 4, 1)
ON CONFLICT (id) DO NOTHING;
SELECT setval('edoc.signers_id_seq', 20, true);

-- ─── 6. Work groups (2 nhóm công tác) ──────────────────────────────────────
INSERT INTO edoc.work_groups (id, unit_id, name, sort_order, created_by) VALUES
  (1, 1, 'Ban Chỉ đạo Chuyển đổi số',         1, 1),
  (2, 1, 'Tổ Công tác cải cách hành chính',   2, 1)
ON CONFLICT (id) DO NOTHING;
SELECT setval('edoc.work_groups_id_seq', 10, true);

-- Members (8 records)
INSERT INTO edoc.work_group_members (group_id, staff_id) VALUES
  (1, 1), (1, 2), (1, 4), (1, 8),
  (2, 1), (2, 5), (2, 6), (2, 10)
ON CONFLICT DO NOTHING;

-- ─── 7. Delegations (2 ủy quyền) ───────────────────────────────────────────
INSERT INTO edoc.delegations (id, from_staff_id, to_staff_id, start_date, end_date, note) VALUES
  (1, 2, 10, '2026-04-10', '2026-04-20', 'Ủy quyền xử lý văn bản khi đi công tác'),
  (2, 3, 7,  '2026-04-15', '2026-04-25', 'Ủy quyền ký văn bản trong thời gian nghỉ phép')
ON CONFLICT (id) DO NOTHING;
SELECT setval('edoc.delegations_id_seq', 10, true);

-- ─── 8. Organizations (2 cơ quan đối tác LGSP) ─────────────────────────────
INSERT INTO edoc.organizations (id, unit_id, code, name, address, phone, email, secretary, level) VALUES
  (1, 1, 'UBND-LC', 'UBND tỉnh Lào Cai',     'Đường Hoàng Liên, TP Lào Cai', '02143840888', 'ubnd@laocai.gov.vn', 'Vũ Thị Kim', 1),
  (2, 2, 'SNV-LC',  'Sở Nội vụ tỉnh Lào Cai', '123 Trần Phú, TP Lào Cai',     '02143840102', 'snv@laocai.gov.vn',  'Đỗ Thị Lan',  2)
ON CONFLICT (id) DO NOTHING;
SELECT setval('edoc.organizations_id_seq', 10, true);

-- ─── 9. Work calendar (3 ngày nghỉ) ────────────────────────────────────────
INSERT INTO public.work_calendar (date, description, is_holiday, created_by) VALUES
  ('2026-04-30', 'Ngày Giải phóng miền Nam',   true, 1),
  ('2026-05-01', 'Ngày Quốc tế Lao động',      true, 1),
  ('2026-09-02', 'Ngày Quốc khánh',            true, 1)
ON CONFLICT (date) DO NOTHING;

-- ─── 10. VB ĐẾN (50 records — mix urgent/secret/type) ──────────────────────
INSERT INTO edoc.incoming_docs (
  id, unit_id, received_date, number, notation, document_code, abstract, publish_unit,
  publish_date, signer, doc_book_id, doc_type_id, doc_field_id,
  urgent_id, secret_id, number_paper, number_copies, sents, created_by
)
SELECT
  n AS id,
  1 AS unit_id,
  NOW() - (n || ' hours')::INTERVAL AS received_date,
  100 + n AS number,
  'CV-' || (100+n) || '/DEMO' AS notation,
  'CV' || (100+n) AS document_code,
  'Văn bản đến demo số ' || n || ' — ' ||
  CASE (n % 5)
    WHEN 0 THEN 'V/v triển khai công tác chuyển đổi số'
    WHEN 1 THEN 'V/v báo cáo thống kê quý'
    WHEN 2 THEN 'V/v phê duyệt dự toán ngân sách'
    WHEN 3 THEN 'V/v tổ chức hội nghị tổng kết'
    ELSE 'V/v hướng dẫn thực hiện chính sách'
  END AS abstract,
  CASE (n % 4)
    WHEN 0 THEN 'Văn phòng Chính phủ'
    WHEN 1 THEN 'Bộ Nội vụ'
    WHEN 2 THEN 'Bộ Tài chính'
    ELSE 'UBND tỉnh'
  END AS publish_unit,
  NOW() - ((n+1) || ' hours')::INTERVAL AS publish_date,
  CASE (n % 3) WHEN 0 THEN 'Nguyễn Văn A' WHEN 1 THEN 'Trần Thị B' ELSE 'Lê Văn C' END AS signer,
  1 AS doc_book_id,
  ((n % 8) + 1) AS doc_type_id,
  ((n % 5) + 1) AS doc_field_id,
  ((n % 3) + 1)::smallint AS urgent_id,
  ((n % 4) + 1)::smallint AS secret_id,
  (n % 10) + 1 AS number_paper,
  (n % 3) + 1  AS number_copies,
  'Đơn vị demo ' || (n % 5) AS sents,
  1 AS created_by
FROM generate_series(1, 50) AS n
WHERE NOT EXISTS (SELECT 1 FROM edoc.incoming_docs WHERE id = n);

SELECT setval('edoc.incoming_docs_id_seq', 1000, true);

-- v3.0: Mark some VB đến nguồn external (LGSP) thay cho is_handling đã DROP
-- Dùng prefix LGSP-EXT- để tránh conflict với 10 VB liên thông INSERT bên dưới (LGSP-10001..10010)
UPDATE edoc.incoming_docs SET source_type = 'external_lgsp', is_unit_send = false, unit_send = 'Bộ Nội vụ', external_doc_id = 'LGSP-EXT-' || (20000 + id)
  WHERE id % 5 = 0 AND source_type = 'manual';

-- ─── 11. User_incoming_docs (phân công xử lý — 50 records) ─────────────────
-- Mỗi VB đến phân cho 1 staff (rotate 2-10 theo mod để đa dạng)
INSERT INTO edoc.user_incoming_docs (incoming_doc_id, staff_id, is_read, read_at)
SELECT
  d.id,
  ((d.id % 9) + 2) AS staff_id,   -- staff 2..10
  (d.id % 2 = 0) AS is_read,       -- half read, half unread
  CASE WHEN d.id % 2 = 0 THEN d.received_date + INTERVAL '1 hour' ELSE NULL END AS read_at
FROM edoc.incoming_docs d
WHERE d.id BETWEEN 1 AND 50
  AND NOT EXISTS (
    SELECT 1 FROM edoc.user_incoming_docs u
    WHERE u.incoming_doc_id = d.id AND u.staff_id = ((d.id % 9) + 2)
  );

-- ─── 12. VB ĐI (30 records) ────────────────────────────────────────────────
INSERT INTO edoc.outgoing_docs (
  id, unit_id, received_date, number, notation, document_code, abstract,
  drafting_unit_id, drafting_user_id, publish_date, signer,
  doc_book_id, doc_type_id, doc_field_id,
  urgent_id, secret_id, number_paper, number_copies, recipients, created_by
)
SELECT
  n AS id,
  1 AS unit_id,
  NOW() - (n || ' hours')::INTERVAL AS received_date,
  200 + n AS number,
  'CV-' || (200+n) || '/UBND' AS notation,
  'CV' || (200+n) AS document_code,
  'Văn bản đi demo ' || n || ' — trả lời/triển khai văn bản đến số ' || n AS abstract,
  1 AS drafting_unit_id,
  ((n % 9) + 2) AS drafting_user_id,  -- staff 2..10
  NOW() - (n || ' hours')::INTERVAL AS publish_date,
  CASE (n % 3) WHEN 0 THEN 'Nguyễn Văn A' WHEN 1 THEN 'Trần Thị B' ELSE 'Lê Văn C' END AS signer,
  2 AS doc_book_id,
  ((n % 8) + 1) AS doc_type_id,
  ((n % 5) + 1) AS doc_field_id,
  ((n % 3) + 1)::smallint AS urgent_id,
  ((n % 4) + 1)::smallint AS secret_id,
  1 AS number_paper,
  1 AS number_copies,
  'Các Sở, ngành liên quan; UBND các huyện, TX' AS recipients,
  1 AS created_by
FROM generate_series(1, 30) AS n
WHERE NOT EXISTS (SELECT 1 FROM edoc.outgoing_docs WHERE id = n);

SELECT setval('edoc.outgoing_docs_id_seq', 1000, true);

-- ─── 13. VB DỰ THẢO (20 records, mix approved/released) ────────────────────
INSERT INTO edoc.drafting_docs (
  id, unit_id, received_date, number, notation, document_code, abstract,
  drafting_unit_id, drafting_user_id, publish_date, signer,
  doc_book_id, doc_type_id, doc_field_id,
  urgent_id, secret_id, number_paper, number_copies, recipients,
  approved, is_released, created_by
)
SELECT
  n AS id,
  1 AS unit_id,
  NOW() - (n || ' days')::INTERVAL AS received_date,
  n AS number,
  'DT-' || n || '/DEMO' AS notation,
  'DT' || n AS document_code,
  'Dự thảo demo số ' || n || ' — chờ xử lý nội bộ' AS abstract,
  1 AS drafting_unit_id,
  ((n % 9) + 2) AS drafting_user_id,
  NULL::timestamptz AS publish_date,
  CASE (n % 3) WHEN 0 THEN 'Nguyễn Văn A' WHEN 1 THEN 'Trần Thị B' ELSE 'Lê Văn C' END AS signer,
  3 AS doc_book_id,
  ((n % 8) + 1) AS doc_type_id,
  ((n % 5) + 1) AS doc_field_id,
  ((n % 3) + 1)::smallint AS urgent_id,
  ((n % 4) + 1)::smallint AS secret_id,
  1, 1,
  'Các Sở, ngành liên quan' AS recipients,
  (n % 3 = 0) AS approved,        -- 1/3 đã duyệt
  (n % 5 = 0) AS is_released,      -- 1/5 đã phát hành
  1 AS created_by
FROM generate_series(1, 20) AS n
WHERE NOT EXISTS (SELECT 1 FROM edoc.drafting_docs WHERE id = n);

SELECT setval('edoc.drafting_docs_id_seq', 1000, true);

-- ─── 14. HSCV (15 records, mix status 0→4 + -1 + -2) ──────────────────────
-- handling_docs schema: name (not code), status (smallint), progress (smallint 0-100),
--                       start_date/end_date (not create_date/due_date),
--                       curator/signer (integer FK)
INSERT INTO edoc.handling_docs (
  id, unit_id, department_id, name, abstract, doc_notation,
  doc_type_id, doc_field_id, doc_book_id,
  start_date, end_date, received_date,
  curator, signer, status, progress, created_by
)
SELECT
  n AS id,
  1 AS unit_id,
  ((n % 5) + 1) AS department_id,
  'Hồ sơ công việc demo ' || n AS name,
  'HSCV demo ' || n || ' — ' ||
  CASE (n % 5)
    WHEN 0 THEN 'Triển khai chuyển đổi số'
    WHEN 1 THEN 'Báo cáo thống kê'
    WHEN 2 THEN 'Dự toán ngân sách'
    WHEN 3 THEN 'Tổ chức hội nghị'
    ELSE 'Hướng dẫn chính sách'
  END AS abstract,
  'HSCV-' || n AS doc_notation,
  ((n % 8) + 1) AS doc_type_id,
  ((n % 5) + 1) AS doc_field_id,
  1 AS doc_book_id,
  NOW() - (n || ' days')::INTERVAL AS start_date,
  NOW() + ((15-n) || ' days')::INTERVAL AS end_date,
  NOW() - (n || ' days')::INTERVAL AS received_date,
  ((n % 9) + 2) AS curator,         -- staff 2..10
  CASE WHEN n >= 7 THEN 1 ELSE NULL END AS signer,
  CASE
    WHEN n <= 3  THEN 0::smallint   -- dự thảo
    WHEN n <= 6  THEN 1::smallint   -- đang xử lý
    WHEN n <= 9  THEN 2::smallint   -- trình ký
    WHEN n <= 11 THEN 3::smallint   -- chờ duyệt
    WHEN n <= 13 THEN 4::smallint   -- hoàn thành
    WHEN n = 14  THEN (-1)::smallint -- thu hồi
    ELSE (-2)::smallint              -- hủy
  END AS status,
  CASE WHEN n <= 9 THEN (n * 10)::smallint ELSE 100::smallint END AS progress,
  1 AS created_by
FROM generate_series(1, 15) AS n
WHERE NOT EXISTS (SELECT 1 FROM edoc.handling_docs WHERE id = n);

SELECT setval('edoc.handling_docs_id_seq', 1000, true);

-- ─── 15. VB LIÊN THÔNG v3.0 — gộp vào incoming_docs với source_type='external_lgsp' ──
-- v3.0: bảng inter_incoming_docs đã DROP, dùng incoming_docs với cờ source_type
-- Seed 8 cơ quan ngoài tỉnh trước (inter_organizations, rename từ lgsp_organizations)
INSERT INTO edoc.inter_organizations (id, code, name, lgsp_organ_id, is_active) VALUES
  (1, 'BNV', 'Bộ Nội vụ', '000.00.00.H43', TRUE),
  (2, 'BTC', 'Bộ Tài chính', '000.00.00.H44', TRUE),
  (3, 'BTTTT', 'Bộ Thông tin và Truyền thông', '000.00.00.H45', TRUE),
  (4, 'VPCP', 'Văn phòng Chính phủ', '000.00.00.H01', TRUE),
  (5, 'BCT', 'Bộ Công Thương', '000.00.00.H46', TRUE),
  (6, 'BGTVT', 'Bộ Giao thông Vận tải', '000.00.00.H47', TRUE),
  (7, 'BYT', 'Bộ Y tế', '000.00.00.H48', TRUE),
  (8, 'UBND_HN', 'UBND TP Hà Nội', '000.00.00.H02', TRUE)
ON CONFLICT (code) DO NOTHING;

-- Sequence name có thể là lgsp_organizations_id_seq (rename từ v2.0) hoặc inter_organizations_id_seq (fresh)
SELECT setval(pg_get_serial_sequence('edoc.inter_organizations', 'id'), 1000, true);

-- 10 VB liên thông (gộp vào incoming_docs với source_type='external_lgsp')
INSERT INTO edoc.incoming_docs (
  id, unit_id, received_date, number, notation, document_code, abstract,
  publish_unit, publish_date, signer, doc_book_id, doc_type_id, doc_field_id,
  urgent_id, secret_id, number_paper, number_copies, recipients, created_by,
  source_type, is_unit_send, unit_send, external_doc_id
)
SELECT
  (1000 + n) AS id,
  1 AS unit_id,
  NOW() - (n || ' hours')::INTERVAL AS received_date,
  300 + n AS number,
  'LT-' || (300+n) || '/BNV' AS notation,
  'LT' || (300+n) AS document_code,
  'VB liên thông demo ' || n || ' — từ Bộ Nội vụ qua LGSP' AS abstract,
  'Bộ Nội vụ' AS publish_unit,
  NOW() - ((n+1) || ' hours')::INTERVAL AS publish_date,
  'Phạm Thị Thanh Trà' AS signer,
  1 AS doc_book_id,
  ((n % 8) + 1) AS doc_type_id,
  ((n % 5) + 1) AS doc_field_id,
  ((n % 3) + 1)::smallint AS urgent_id,
  1::smallint AS secret_id,
  (n % 5) + 1 AS number_paper,
  1 AS number_copies,
  'UBND tỉnh Lào Cai' AS recipients,
  1 AS created_by,
  'external_lgsp'::edoc.doc_source_type AS source_type,
  FALSE AS is_unit_send,
  'Bộ Nội vụ' AS unit_send,
  'LGSP-' || (10000 + n) AS external_doc_id
FROM generate_series(1, 10) AS n
WHERE NOT EXISTS (SELECT 1 FROM edoc.incoming_docs WHERE id = (1000 + n));

-- Setval lại sequence sau khi insert explicit id 1001..1010 — tránh duplicate key khi user tạo VB mới
SELECT setval('edoc.incoming_docs_id_seq', (SELECT COALESCE(MAX(id), 0) + 1 FROM edoc.incoming_docs));

-- ─── 16. Attachments VB đến (20 records — file giả không upload MinIO) ─────
INSERT INTO edoc.attachment_incoming_docs (
  id, incoming_doc_id, file_name, file_path, file_size, content_type,
  sort_order, created_by, created_at
)
SELECT
  n AS id,
  n AS incoming_doc_id,
  'CV-' || (100+n) || '.pdf' AS file_name,
  'demo/incoming/' || n || '/CV-' || (100+n) || '.pdf' AS file_path,
  (102400 + n * 1000)::bigint AS file_size,
  'application/pdf' AS content_type,
  0 AS sort_order,
  1 AS created_by,
  NOW() - (n || ' hours')::INTERVAL AS created_at
FROM generate_series(1, 20) AS n
WHERE NOT EXISTS (SELECT 1 FROM edoc.attachment_incoming_docs WHERE id = n);

SELECT setval('edoc.attachment_incoming_docs_id_seq', 1000, true);

-- ─── 17. Attachments VB đi (15 records) ────────────────────────────────────
INSERT INTO edoc.attachment_outgoing_docs (
  id, outgoing_doc_id, file_name, file_path, file_size, content_type,
  sort_order, created_by, created_at
)
SELECT
  n AS id,
  n AS outgoing_doc_id,
  'CV-' || (200+n) || '.pdf' AS file_name,
  'demo/outgoing/' || n || '/CV-' || (200+n) || '.pdf' AS file_path,
  (102400 + n * 1000)::bigint AS file_size,
  'application/pdf' AS content_type,
  0 AS sort_order,
  1 AS created_by,
  NOW() - (n || ' hours')::INTERVAL AS created_at
FROM generate_series(1, 15) AS n
WHERE NOT EXISTS (SELECT 1 FROM edoc.attachment_outgoing_docs WHERE id = n);

SELECT setval('edoc.attachment_outgoing_docs_id_seq', 1000, true);

-- ─── 18. Notices (30 records — thông báo hệ thống) ────────────────────────
INSERT INTO edoc.notices (id, unit_id, title, content, notice_type, created_by, created_at)
SELECT
  n AS id,
  1 AS unit_id,
  'Thông báo demo ' || n AS title,
  'Nội dung thông báo mẫu số ' || n || ' — ' ||
  CASE (n % 3)
    WHEN 0 THEN 'thông báo hệ thống bảo trì định kỳ'
    WHEN 1 THEN 'thông báo văn bản mới phân công xử lý'
    ELSE 'thông báo kết quả ký số thành công'
  END AS content,
  CASE (n % 3) WHEN 0 THEN 'system' WHEN 1 THEN 'doc_assigned' ELSE 'sign_result' END AS notice_type,
  1 AS created_by,
  (NOW() - (n || ' minutes')::INTERVAL)::timestamp AS created_at
FROM generate_series(1, 30) AS n
WHERE NOT EXISTS (SELECT 1 FROM edoc.notices WHERE id = n);

SELECT setval('edoc.notices_id_seq', 1000, true);

-- ─── 19. Leader notes (8 records — mix incoming/outgoing/drafting) ─────────
-- Constraint: exactly 1 trong (incoming_doc_id, outgoing_doc_id, drafting_doc_id) IS NOT NULL
INSERT INTO edoc.leader_notes (id, incoming_doc_id, outgoing_doc_id, drafting_doc_id, staff_id, content) VALUES
  (1, 1,  NULL, NULL, 1, 'Giao Sở TT&TT chủ trì, phối hợp các đơn vị triển khai. Hạn: 30/04/2026.'),
  (2, 2,  NULL, NULL, 1, 'Đồng ý dự toán. Sở TC theo dõi triển khai.'),
  (3, 4,  NULL, NULL, 2, 'Phòng TCHC chuẩn bị phương án tuyển dụng, báo cáo trước 20/04.'),
  (4, 6,  NULL, NULL, 1, 'Văn phòng UBND chủ trì rà soát, báo cáo Chủ tịch trước 25/04.'),
  (5, NULL, 1,  NULL, 1, 'Ý kiến chỉ đạo trả lời văn bản đi số 201 — khẩn trương triển khai.'),
  (6, NULL, 5,  NULL, 2, 'Bổ sung thêm nội dung báo cáo định kỳ hàng tháng.'),
  (7, NULL, NULL, 1,  1, 'Dự thảo 01 cần rà soát lại căn cứ pháp lý trước khi ban hành.'),
  (8, NULL, NULL, 5,  2, 'Dự thảo 05 cần lấy ý kiến thêm các Sở liên quan.')
ON CONFLICT (id) DO NOTHING;
SELECT setval('edoc.leader_notes_id_seq', 100, true);

COMMIT;

-- ─── Verify count cuối ─────────────────────────────────────────────────────
DO $$
DECLARE
  v_total INT;
  v_incoming INT;
  v_outgoing INT;
  v_drafting INT;
  v_handling INT;
BEGIN
  SELECT count(*) INTO v_incoming FROM edoc.incoming_docs;
  SELECT count(*) INTO v_outgoing FROM edoc.outgoing_docs;
  SELECT count(*) INTO v_drafting FROM edoc.drafting_docs;
  SELECT count(*) INTO v_handling FROM edoc.handling_docs;

  SELECT
    (SELECT count(*) FROM public.departments) +
    (SELECT count(*) FROM public.staff) +
    (SELECT count(*) FROM public.role_of_staff) +
    (SELECT count(*) FROM edoc.doc_books) +
    (SELECT count(*) FROM edoc.signers) +
    (SELECT count(*) FROM edoc.work_groups) +
    (SELECT count(*) FROM edoc.work_group_members) +
    (SELECT count(*) FROM edoc.delegations) +
    (SELECT count(*) FROM edoc.organizations) +
    (SELECT count(*) FROM public.work_calendar) +
    v_incoming +
    (SELECT count(*) FROM edoc.user_incoming_docs) +
    v_outgoing +
    v_drafting +
    v_handling +
    (SELECT count(*) FROM edoc.inter_organizations) +
    (SELECT count(*) FROM edoc.attachment_incoming_docs) +
    (SELECT count(*) FROM edoc.attachment_outgoing_docs) +
    (SELECT count(*) FROM edoc.notices) +
    (SELECT count(*) FROM edoc.leader_notes)
  INTO v_total;

  IF v_total < 220 THEN
    RAISE EXCEPTION 'Seed 002 data volume = %, cần >= 220', v_total;
  END IF;
  RAISE NOTICE 'seed/002_demo_data.sql: % records OK (incoming=%, outgoing=%, drafting=%, handling=%)',
    v_total, v_incoming, v_outgoing, v_drafting, v_handling;
END $$;
