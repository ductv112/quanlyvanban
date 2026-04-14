# HƯỚNG DẪN CÀI ĐẶT MÔI TRƯỜNG — Quản lý Văn bản

---

## 1. YÊU CẦU HỆ THỐNG

| Phần mềm | Phiên bản | Ghi chú |
|---|---|---|
| **Node.js** | 20 LTS trở lên | https://nodejs.org/ |
| **Docker Desktop** | Mới nhất | https://docker.com/products/docker-desktop/ |
| **Git** | Mới nhất | https://git-scm.com/ |
| **VS Code** (khuyến nghị) | Mới nhất | Extensions: ESLint, Prettier, GitLens |

---

## 2. CLONE DỰ ÁN

```bash
git clone https://github.com/ductv112/quanlyvanban.git
cd quanlyvanban/e_office_app_new
```

---

## 3. KHỞI ĐỘNG DOCKER SERVICES

```bash
docker-compose up -d
```

Sẽ start 4 services:
| Service | Port | Credentials |
|---|---|---|
| PostgreSQL 16 | 5432 | qlvb_admin / QlvbDev@2026 / DB: qlvb_dev |
| MongoDB 7 | 27017 | qlvb_admin / QlvbMongo@2026 / DB: qlvb_logs |
| Redis 7 | 6379 | Password: QlvbRedis@2026 |
| MinIO | 9000 (API), 9001 (Console) | qlvb_admin / QlvbMinio@2026 |

Kiểm tra services đã chạy:
```bash
docker ps
```

---

## 4. CHẠY DATABASE MIGRATIONS

Chạy **theo đúng thứ tự** từ 01 → 06:

```bash
# Schemas + Extensions
cat database/init/01_create_schemas.sql | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev

# System tables (staff, departments, positions, roles, rights...)
cat database/migrations/001_system_tables.sql | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev

# Document tables (edoc schema)
cat database/migrations/002_edoc_tables.sql | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev

# Auth stored procedures
cat database/migrations/003_auth_stored_procedures.sql | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev

# Rename SP convention (sp_ → fn_)
cat database/migrations/004_rename_auth_sp_convention.sql | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev

# Sprint 1: Admin core SPs + menu seed
cat database/migrations/005_sprint1_admin_core_sp.sql | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev

# Sprint 1: Gap fixes (thêm cột, sửa SP)
cat database/migrations/006_sprint1_fix_gaps.sql | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev
```

### Thêm unique constraints (tránh data trùng):
```bash
echo "
ALTER TABLE positions ADD CONSTRAINT IF NOT EXISTS uq_positions_code UNIQUE (code);
ALTER TABLE roles ADD CONSTRAINT IF NOT EXISTS uq_roles_name UNIQUE (name);
ALTER TABLE departments ADD CONSTRAINT IF NOT EXISTS uq_departments_code UNIQUE (code);
" | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev
```

### Cập nhật password admin (hash đúng cho Admin@123):
```bash
echo "
UPDATE staff SET password_hash = '\$2b\$12\$p4p6gNuqB5AAcAj2rrU4VO8wmkvgtSRykSYbETqj.nqDTFMKjbU0K'
WHERE username = 'admin';
" | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev
```

### Sprint 2-3: Văn bản đến/đi/dự thảo, HSCV
```bash
cat database/migrations/007_sprint2_incoming_doc.sql | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev
cat database/migrations/008_sprint3_handling_doc.sql | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev
cat database/migrations/009_sprint4_drafting_outgoing.sql | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev
```

### Sprint 5-10: Danh mục, tin nhắn, lịch, danh bạ, luồng xử lý
```bash
cat database/migrations/010_sprint5_catalog_sp.sql | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev
cat database/migrations/011_sprint6_inter_incoming.sql | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev
cat database/migrations/012_sprint7_messages_notices.sql | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev
cat database/migrations/013_sprint8_calendar_contacts.sql | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev
cat database/migrations/014_sprint9_doc_flow.sql | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev
cat database/migrations/015_sprint10_sms_email_templates.sql | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev
```

### Sprint 11-13: Kho lưu trữ, tài liệu, hợp đồng, cuộc họp
```bash
cat database/migrations/016_sprint11_archive_storage.sql | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev
cat database/migrations/017_sprint12_documents_contracts.sql | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev
cat database/migrations/018_sprint13_meetings.sql | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev
```

### Sprint 14-16: LGSP, Ký số, Thông báo đa kênh
```bash
cat database/migrations/019_sprint14_lgsp.sql | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev
cat database/migrations/020_sprint15_digital_signing.sql | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev
cat database/migrations/021_sprint16_notifications.sql | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev
```

### Seed data demo (TRUNCATE toàn bộ + seed lại từ đầu)
```bash
cat database/seed_full_demo.sql | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev
```

> **Lưu ý:** `seed_full_demo.sql` sẽ TRUNCATE tất cả bảng rồi seed data mới.
> Bao gồm: 10 phòng ban, 10 nhân viên, VB đến/đi/dự thảo, HSCV, cuộc họp, kho lưu trữ, tài liệu ISO, hợp đồng, LGSP, ký số, thông báo.
> Password tất cả tài khoản: **Admin@123**

---

## 5. CẤU HÌNH BACKEND

```bash
cd backend

# Copy file env
cp .env.example .env

# Cài dependencies
npm install

# Start dev server (port 4000)
npm run dev
```

File `.env` mặc định đã có đủ credentials khớp với docker-compose. Nếu đổi password trong docker-compose thì cập nhật `.env` tương ứng.

---

## 6. CẤU HÌNH FRONTEND

```bash
cd frontend

# Copy file env
cp .env.example .env.local

# Cài dependencies
npm install

# Start dev server (port 3000)
npm run dev
```

---

## 7. KIỂM TRA

| URL | Chức năng |
|---|---|
| http://localhost:3000 | Frontend (redirect → login) |
| http://localhost:3000/login | Trang đăng nhập |
| http://localhost:3000/dashboard | Dashboard (sau khi login) |
| http://localhost:4000/api/health | Backend health check |
| http://localhost:9001 | MinIO Console (quản lý file) |

### Tài khoản đăng nhập:
| Username | Password |
|---|---|
| admin | Admin@123 |

---

## 8. TROUBLESHOOTING

### Docker không start được
```bash
# Kiểm tra port đã bị chiếm chưa
netstat -ano | findstr :5432   # PostgreSQL
netstat -ano | findstr :6379   # Redis
netstat -ano | findstr :27017  # MongoDB
```

### Migration lỗi "already exists"
Các migration dùng `IF NOT EXISTS` và `ON CONFLICT` — chạy lại an toàn. Nếu lỗi, có thể reset DB:
```bash
docker-compose down -v   # XÓA toàn bộ data
docker-compose up -d     # Tạo lại
# Chạy lại migrations từ đầu
```

### Backend lỗi kết nối DB
- Kiểm tra Docker container đang chạy: `docker ps`
- Kiểm tra `.env` có đúng credentials không
- Kiểm tra PostgreSQL health: `docker exec qlvb_postgres pg_isready -U qlvb_admin`

### Frontend lỗi API
- Kiểm tra backend đang chạy ở port 4000
- Kiểm tra `.env.local` có `NEXT_PUBLIC_API_URL=http://localhost:4000/api`
- Kiểm tra CORS: backend `.env` có `CORS_ORIGIN=http://localhost:3000`

---

## 9. CẤU TRÚC THƯ MỤC

```
e_office_app_new/
├── docker-compose.yml          # 4 services: PG, Mongo, Redis, MinIO
├── ROADMAP.md                  # Sprint plan (17 sprints)
├── SETUP.md                    # File này
├── backend/                    # Express 5 + TypeScript (port 4000)
│   ├── .env.example
│   ├── package.json
│   └── src/
├── frontend/                   # Next.js 16 + Ant Design 6 (port 3000)
│   ├── .env.example
│   ├── package.json
│   └── src/
├── database/                   # SQL migrations + SPs
│   ├── init/
│   └── migrations/
├── shared/                     # Types + constants dùng chung
├── workers/                    # BullMQ background jobs
└── docs/                       # Tài liệu (quy ước chung...)
```
