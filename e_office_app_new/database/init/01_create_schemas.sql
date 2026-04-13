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

-- ============================================
-- Thông báo
-- ============================================
DO $$
BEGIN
  RAISE NOTICE '✅ Schemas created: edoc, esto, cont, iso';
  RAISE NOTICE '✅ Extensions enabled: uuid-ossp, pgcrypto, unaccent, pg_trgm';
END $$;
