-- ============================================================================
-- seed/003_test_fixtures.sql — TEST AUTOMATION FIXTURES (test env only)
-- Idempotent: INSERT ... ON CONFLICT DO UPDATE / DO NOTHING
-- Depends on: seed/001_required_data.sql (admin id=1, departments 1-5, roles 1-6,
--             doc_books 4=Sở Nội vụ VB đến, 5=Sở Nội vụ VB đi)
--
-- ENV GUARD: tuyet doi KHONG duoc apply len PROD
-- Config bat buoc: SET app.environment='test' (hoac 'dev', KHONG duoc 'prod')
--
-- Schema reference (queried tu qlvb_test sau khi apply schema v3.0):
--   incoming_docs columns: id, unit_id, received_date, number, notation,
--     document_code, abstract, publish_unit, publish_date, signer, sign_date,
--     doc_book_id, doc_type_id, doc_field_id, secret_id, urgent_id, number_paper,
--     number_copies, expired_date, recipients, approver, approved,
--     is_received_paper, archive_status, created_by, source_type, is_unit_send,
--     unit_send, external_doc_id, department_id, rejected_by, rejection_reason,
--     previous_outgoing_doc_id, ... (KHONG co is_handling/is_inter_doc/inter_doc_id)
--   outgoing_docs has status enum + is_released; KHONG co is_handling/is_inter_doc
--   drafting_docs has status enum (draft/reviewing/approved/released/rejected)
--   handling_docs status smallint, KHONG co status enum
--
-- Noi dung:
--   1. 6 user fixtures (id 9001-9005 + 9099 locked) — password Test@123
--   2. Role assignments
--   3. 5 VB den fixtures (id 90001-90005) — 5 trang thai
--   4. user_incoming_docs assignments
--   5. 3 VB di fixtures (id 90001-90003) — sd status enum
--   6. 2 du thao fixtures (id 90001-90002) — sd status enum
--   7. 2 HSCV fixtures (id 9001-9002 — active + closed)
--   8. 3 notice fixtures (id 90001-90003)
--   9. Sequence reset
--
-- CACH CHAY (manual):
--   docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_test -v ON_ERROR_STOP=1 \
--     -c "SET app.environment='test';" \
--     -f - < e_office_app_new/database/seed/003_test_fixtures.sql
-- ============================================================================

\set ON_ERROR_STOP on

-- ─── ENV GUARD: chan chay len prod ──────────────────────────────────────────
DO $$
BEGIN
  IF current_setting('app.environment', true) = 'prod' THEN
    RAISE EXCEPTION 'KHONG duoc chay test fixtures tren PROD. Set app.environment=test';
  END IF;
END $$;

-- ─── Verify seed 001 da chay ────────────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.staff WHERE id=1) THEN
    RAISE EXCEPTION 'seed/001_required_data.sql chua duoc apply. Chay seed 001 TRUOC seed 003.';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.roles WHERE id IN (5, 6, 1, 2)) THEN
    RAISE EXCEPTION 'Roles 1/2/5/6 khong ton tai. Chay seed 001 TRUOC.';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.departments WHERE id IN (1, 2, 3)) THEN
    RAISE EXCEPTION 'Departments 1/2/3 khong ton tai. Chay seed 001 TRUOC.';
  END IF;
END $$;

BEGIN;

-- ─── 1. 5 user fixtures + 1 locked user (id 9001-9005, 9099) ────────────────
-- Password Test@123 bcrypt hash (gen 1 lan):
--   cd e_office_app_new/backend && node -e "require('bcryptjs').hash('Test@123', 10).then(console.log)"
-- Hash: $2b$10$y/GpbkimP4hyef0/QLVNwuW2xb4tbDNuKREpqenGy7WMnN8QtXsOe (verified bcrypt.compare = true)
INSERT INTO public.staff (
  id, department_id, unit_id, position_id, code, username, password_hash, is_admin,
  first_name, last_name, gender, email, phone, mobile, is_locked
) VALUES
  (9001, 1, 1, 1, 'TEST001', 'test_admin',
   '$2b$10$y/GpbkimP4hyef0/QLVNwuW2xb4tbDNuKREpqenGy7WMnN8QtXsOe',
   true,  'TEST', 'Quản trị',    1, 'test_admin@test.local',   '0900000001', '0900000001', false),
  (9002, 2, 2, 6, 'TEST002', 'test_vanthu',
   '$2b$10$y/GpbkimP4hyef0/QLVNwuW2xb4tbDNuKREpqenGy7WMnN8QtXsOe',
   false, 'TEST', 'Văn thư',     2, 'test_vanthu@test.local',  '0900000002', '0900000002', false),
  (9003, 2, 2, 1, 'TEST003', 'test_lanhdao',
   '$2b$10$y/GpbkimP4hyef0/QLVNwuW2xb4tbDNuKREpqenGy7WMnN8QtXsOe',
   false, 'TEST', 'Lãnh đạo',    1, 'test_lanhdao@test.local', '0900000003', '0900000003', false),
  (9004, 2, 2, 5, 'TEST004', 'test_canbo',
   '$2b$10$y/GpbkimP4hyef0/QLVNwuW2xb4tbDNuKREpqenGy7WMnN8QtXsOe',
   false, 'TEST', 'Cán bộ',      1, 'test_canbo@test.local',   '0900000004', '0900000004', false),
  (9005, 3, 3, 5, 'TEST005', 'test_canbo_x',
   '$2b$10$y/GpbkimP4hyef0/QLVNwuW2xb4tbDNuKREpqenGy7WMnN8QtXsOe',
   false, 'TEST', 'Cán bộ đơn vị khác', 2, 'test_canbo_x@test.local', '0900000005', '0900000005', false),
  (9099, 2, 2, 5, 'TEST099', 'test_locked',
   '$2b$10$y/GpbkimP4hyef0/QLVNwuW2xb4tbDNuKREpqenGy7WMnN8QtXsOe',
   false, 'TEST', 'User đã khóa', 1, 'test_locked@test.local',  '0900000099', '0900000099', true)
ON CONFLICT (id) DO UPDATE SET
  password_hash = EXCLUDED.password_hash,
  is_locked = EXCLUDED.is_locked,
  username = EXCLUDED.username,
  updated_at = now();

-- ─── 2. Role assignments cho 6 user ─────────────────────────────────────────
-- Roles tu seed 001: 1=Lanh dao, 2=Can bo, 5=Quan tri he thong, 6=Van thu
INSERT INTO public.role_of_staff (staff_id, role_id) VALUES
  (9001, 5),  -- test_admin: Quan tri he thong
  (9002, 6),  -- test_vanthu: Van thu
  (9003, 1),  -- test_lanhdao: Ban Lanh dao
  (9004, 2),  -- test_canbo: Can bo
  (9005, 2),  -- test_canbo_x: Can bo (don vi khac — STC)
  (9099, 2)   -- test_locked: Can bo (user da khoa)
ON CONFLICT (staff_id, role_id) DO NOTHING;

-- ─── 3. 5 VB den fixtures (id 90001-90005, 5 trang thai khac nhau) ─────────
-- Trang thai suy ra tu flags:
--   90001: NEW (approved=false, no user_incoming_docs) — chua vao so
--   90002: DISTRIBUTED (approved=true + user_incoming_docs is_read=false)
--   90003: PROCESSING (approved=true + user_incoming_docs is_read=true)
--   90004: COMPLETED (approved=true + archive_status=true)
--   90005: REJECTED (approved=false + rejected_by IS NOT NULL + rejection_reason)
INSERT INTO edoc.incoming_docs (
  id, unit_id, department_id, received_date, number, notation, document_code, abstract,
  publish_unit, publish_date, signer, doc_book_id, doc_type_id, doc_field_id,
  urgent_id, secret_id, number_paper, number_copies, sents,
  approved, archive_status, created_by, source_type, is_unit_send,
  rejected_by, rejection_reason
) VALUES
  (90001, 2, 2, NOW() - INTERVAL '5 hours', 90001, 'TEST/VBD-NEW',     'TEST-VBD-NEW',
   'TEST: VB den moi - chua vao so', 'Co quan TEST', NOW() - INTERVAL '6 hours',
   'TEST Signer', 4, 1, 1, 1::smallint, 1::smallint, 1, 1, 'TEST recipient',
   false, false, 9002, 'manual'::edoc.doc_source_type, false, NULL, NULL),
  (90002, 2, 2, NOW() - INTERVAL '4 hours', 90002, 'TEST/VBD-DIST',    'TEST-VBD-DIST',
   'TEST: VB den da giao viec', 'Co quan TEST', NOW() - INTERVAL '5 hours',
   'TEST Signer', 4, 1, 1, 2::smallint, 1::smallint, 1, 1, 'TEST recipient',
   true,  false, 9002, 'manual'::edoc.doc_source_type, false, NULL, NULL),
  (90003, 2, 2, NOW() - INTERVAL '3 hours', 90003, 'TEST/VBD-PROC',    'TEST-VBD-PROC',
   'TEST: VB den dang xu ly', 'Co quan TEST', NOW() - INTERVAL '4 hours',
   'TEST Signer', 4, 1, 1, 2::smallint, 2::smallint, 2, 1, 'TEST recipient',
   true,  false, 9002, 'manual'::edoc.doc_source_type, false, NULL, NULL),
  (90004, 2, 2, NOW() - INTERVAL '2 days', 90004, 'TEST/VBD-DONE',     'TEST-VBD-DONE',
   'TEST: VB den hoan thanh, da luu kho', 'Co quan TEST', NOW() - INTERVAL '3 days',
   'TEST Signer', 4, 1, 1, 1::smallint, 1::smallint, 1, 1, 'TEST recipient',
   true,  true,  9002, 'manual'::edoc.doc_source_type, false, NULL, NULL),
  (90005, 2, 2, NOW() - INTERVAL '1 day', 90005, 'TEST/VBD-RJCT',      'TEST-VBD-RJCT',
   'TEST: VB den bi tu choi tiep nhan', 'Co quan TEST', NOW() - INTERVAL '1 day 2 hours',
   'TEST Signer', 4, 1, 1, 1::smallint, 1::smallint, 1, 1, 'TEST recipient',
   false, false, 9002, 'manual'::edoc.doc_source_type, false,
   9003, 'TEST: Tu choi tiep nhan - sai don vi nhan')
ON CONFLICT (id) DO NOTHING;

-- ─── 4. user_incoming_docs assignments (cho VB den da giao viec) ───────────
INSERT INTO edoc.user_incoming_docs (incoming_doc_id, staff_id, is_read, read_at, sent_by) VALUES
  (90002, 9004, false, NULL,                              9002),  -- VB da giao, chua doc
  (90003, 9004, true,  NOW() - INTERVAL '2 hours',        9002),  -- VB dang xu ly, da doc
  (90004, 9004, true,  NOW() - INTERVAL '2 days',         9002)   -- VB hoan thanh
ON CONFLICT (incoming_doc_id, staff_id) DO NOTHING;

-- ─── 5. 3 VB di fixtures (id 90001-90003) ──────────────────────────────────
-- status enum: draft / reviewing / released / sent / completed / rejected
INSERT INTO edoc.outgoing_docs (
  id, unit_id, department_id, received_date, number, notation, document_code, abstract,
  drafting_unit_id, drafting_user_id, publish_date, signer,
  doc_book_id, doc_type_id, doc_field_id,
  urgent_id, secret_id, number_paper, number_copies, recipients, created_by,
  status, is_released, released_date, approved
) VALUES
  (90001, 2, 2, NOW() - INTERVAL '2 hours', 90001, 'TEST/VBD-OUT-1', 'TEST-VBD-OUT-1',
   'TEST: VB di duoc tao tu du thao', 2, 9004, NOW() - INTERVAL '3 hours',
   'TEST Lanh dao', 5, 1, 1, 1::smallint, 1::smallint, 1, 1, 'Co quan TEST', 9004,
   'released', true, NOW() - INTERVAL '3 hours', true),
  (90002, 2, 2, NOW() - INTERVAL '1 hour',  90002, 'TEST/VBD-OUT-2', 'TEST-VBD-OUT-2',
   'TEST: VB di phat hanh ngoai', 2, 9004, NOW() - INTERVAL '2 hours',
   'TEST Lanh dao', 5, 1, 1, 2::smallint, 1::smallint, 1, 1, 'Co quan TEST 2', 9004,
   'sent',     true, NOW() - INTERVAL '2 hours', true),
  (90003, 2, 2, NOW() - INTERVAL '30 min',  90003, 'TEST/VBD-OUT-3', 'TEST-VBD-OUT-3',
   'TEST: VB di test cross-unit', 2, 9004, NOW() - INTERVAL '1 hour',
   'TEST Lanh dao', 5, 1, 1, 1::smallint, 1::smallint, 1, 1, 'Co quan TEST 3', 9004,
   'released', true, NOW() - INTERVAL '1 hour',  true)
ON CONFLICT (id) DO NOTHING;

-- ─── 6. 2 du thao fixtures (id 90001-90002) ────────────────────────────────
-- status enum: draft / reviewing / approved / released / rejected
INSERT INTO edoc.drafting_docs (
  id, unit_id, department_id, received_date, number, notation, document_code, abstract,
  drafting_unit_id, drafting_user_id, signer,
  doc_book_id, doc_type_id, doc_field_id,
  urgent_id, secret_id, number_paper, number_copies, recipients,
  approved, is_released, status, created_by
) VALUES
  (90001, 2, 2, NOW() - INTERVAL '6 hours', 90001, 'TEST/DT-1', 'TEST-DT-1',
   'TEST: Du thao chua duyet', 2, 9004, 'TEST Lanh dao',
   5, 1, 1, 1::smallint, 1::smallint, 1, 1, 'Co quan TEST',
   false, false, 'draft', 9004),
  (90002, 2, 2, NOW() - INTERVAL '4 hours', 90002, 'TEST/DT-2', 'TEST-DT-2',
   'TEST: Du thao da duyet, chua phat hanh', 2, 9004, 'TEST Lanh dao',
   5, 1, 1, 2::smallint, 1::smallint, 1, 1, 'Co quan TEST 2',
   true,  false, 'approved', 9004)
ON CONFLICT (id) DO NOTHING;

-- ─── 7. 2 HSCV fixtures (1 active + 1 closed) ───────────────────────────────
-- handling_docs.status smallint: 0=draft, 1=active, 4=completed (theo source code cu)
INSERT INTO edoc.handling_docs (
  id, unit_id, department_id, name, abstract, doc_notation,
  doc_type_id, doc_field_id, doc_book_id,
  start_date, end_date, received_date,
  curator, signer, status, progress, created_by
) VALUES
  (9001, 2, 2, 'TEST: HSCV active', 'TEST: HSCV dang xu ly', 'TEST-HSCV-1',
   1, 1, 4, NOW() - INTERVAL '5 days', NOW() + INTERVAL '10 days', NOW() - INTERVAL '5 days',
   9004, 9003, 1::smallint, 30, 9004),
  (9002, 2, 2, 'TEST: HSCV closed', 'TEST: HSCV da hoan thanh', 'TEST-HSCV-2',
   1, 1, 4, NOW() - INTERVAL '20 days', NOW() - INTERVAL '5 days', NOW() - INTERVAL '20 days',
   9004, 9003, 4::smallint, 100, 9004)
ON CONFLICT (id) DO NOTHING;

-- ─── 8. 3 notice fixtures ───────────────────────────────────────────────────
-- edoc.notices columns: id, unit_id, title, content, notice_type, created_by, created_at
INSERT INTO edoc.notices (id, unit_id, title, content, notice_type, created_by, created_at) VALUES
  (90001, 2, 'TEST: Thong bao 1', 'TEST: Noi dung thong bao test 1', 'system', 9001, NOW() - INTERVAL '1 day'),
  (90002, 2, 'TEST: Thong bao 2', 'TEST: Noi dung thong bao test 2', 'system', 9001, NOW() - INTERVAL '2 days'),
  (90003, 2, 'TEST: Thong bao 3', 'TEST: Noi dung thong bao test 3', 'system', 9001, NOW() - INTERVAL '3 days')
ON CONFLICT (id) DO NOTHING;

COMMIT;

-- ─── 9. Sequence reset (CLAUDE.md pitfall #12) ─────────────────────────────
-- Bao dam nextval() khong cap id da ton tai sau bulk INSERT explicit id
SELECT setval(pg_get_serial_sequence('public.staff', 'id'),
       GREATEST(9099, COALESCE((SELECT MAX(id) FROM public.staff), 9099)));
SELECT setval(pg_get_serial_sequence('edoc.incoming_docs', 'id'),
       GREATEST(90005, COALESCE((SELECT MAX(id) FROM edoc.incoming_docs), 90005)));
SELECT setval(pg_get_serial_sequence('edoc.outgoing_docs', 'id'),
       GREATEST(90003, COALESCE((SELECT MAX(id) FROM edoc.outgoing_docs), 90003)));
SELECT setval(pg_get_serial_sequence('edoc.drafting_docs', 'id'),
       GREATEST(90002, COALESCE((SELECT MAX(id) FROM edoc.drafting_docs), 90002)));
SELECT setval(pg_get_serial_sequence('edoc.handling_docs', 'id'),
       GREATEST(9002, COALESCE((SELECT MAX(id) FROM edoc.handling_docs), 9002)));
SELECT setval(pg_get_serial_sequence('edoc.notices', 'id'),
       GREATEST(90003, COALESCE((SELECT MAX(id) FROM edoc.notices), 90003)));

-- ─── DONE ───────────────────────────────────────────────────────────────────
DO $$
DECLARE
  staff_count INT;
  vbd_count INT;
  vbdi_count INT;
BEGIN
  SELECT COUNT(*) INTO staff_count FROM public.staff WHERE id BETWEEN 9001 AND 9099;
  SELECT COUNT(*) INTO vbd_count FROM edoc.incoming_docs WHERE id BETWEEN 90001 AND 90005;
  SELECT COUNT(*) INTO vbdi_count FROM edoc.outgoing_docs WHERE id BETWEEN 90001 AND 90003;
  RAISE NOTICE 'seed/003_test_fixtures.sql: % users + % VB den + % VB di OK', staff_count, vbd_count, vbdi_count;
END $$;
