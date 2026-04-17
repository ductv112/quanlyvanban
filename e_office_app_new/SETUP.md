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

## 4. CHẠY DATABASE

Chỉ cần 2 lệnh: **1 file migration gộp + 1 file seed**.

```bash
# Migration (tạo schemas + tables + 443 stored procedures)
cat database/migrations/000_full_schema.sql | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev

# Seed data demo
cat database/seed_full_demo.sql | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev
```

> **Seed data bao gồm:** 10 phòng ban, 10 nhân viên, VB đến/đi/dự thảo, HSCV, cuộc họp, kho lưu trữ, tài liệu ISO, hợp đồng, LGSP, ký số, thông báo, 10 tỉnh/TP, 13 cấu hình hệ thống.
> Password tất cả tài khoản: **Admin@123**

### RESET SẠCH (xóa toàn bộ data + chạy lại từ đầu)

```bash
cd e_office_app_new

# Bước 1: Reset Docker volumes
docker-compose down -v
docker-compose up -d
sleep 10

# Bước 2: Migration + Seed
cat database/migrations/000_full_schema.sql | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev
cat database/seed_full_demo.sql | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev

# Bước 3: Start backend + frontend
cd backend && npm install && npm run dev &
cd ../frontend && npm install && npm run dev &
```

Tài khoản test sau reset:

| Username | Password | Vai trò | Ghi chú |
|---|---|---|---|
| admin | Admin@123 | Quản trị hệ thống | Thấy tất cả menu |
| nguyenvana | Admin@123 | Ban Lãnh đạo + Chỉ đạo | Thấy Quản lý + Nghiệp vụ |
| phamvane | Admin@123 | Trưởng phòng + Văn thư | Thấy Quản lý + Nghiệp vụ |
| hoangthif | Admin@123 | Cán bộ | Chỉ thấy Nghiệp vụ + Đối tác |

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

## 9. QUICK START (Pull về máy mới / máy nhà)

```bash
git pull
cd e_office_app_new

# 1. Reset Docker + DB
docker-compose down -v
docker-compose up -d
sleep 10

# 2. Migration + Seed (chỉ 2 lệnh)
cat database/migrations/000_full_schema.sql | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev
cat database/seed_full_demo.sql | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev

# 3. Backend
cd backend
cp .env.example .env
npm install
npm run dev &

# 4. Frontend
cd ../frontend
cp .env.example .env.local
npm install
npm run dev &
```

Sau đó mở http://localhost:3000 → login bằng `admin` / `Admin@123`.

**Test plan:** `.planning/TEST_TONG_THE.md` (284 test cases)
**Test report (lần gần nhất):** `.planning/TEST_REPORT.md` (119/119 PASS — 100%)

---

## 10. CẤU TRÚC THƯ MỤC

```
quanlyvanban/
├── CLAUDE.md                          # Config cho Claude Code
├── .planning/                         # GSD workflow (planning, tracking, test)
│   ├── PROJECT.md                     # Mô tả dự án
│   ├── REQUIREMENTS.md                # Yêu cầu nghiệp vụ
│   ├── ROADMAP.md                     # 7 phases tổng quan (GSD)
│   ├── STATE.md                       # Trạng thái GSD hiện tại
│   ├── TEST_REPORT.md                 # Báo cáo test (119/119 PASS)
│   ├── TEST_TONG_THE.md               # Test plan 284 cases
│   ├── API-AUDIT.md                   # Audit API endpoints
│   ├── FIELD-AUDIT.md                 # Audit field mismatches
│   ├── codebase/                      # GSD codebase analysis
│   └── phases/                        # GSD phase execution history
│
├── docs/source_code_cu/               # Source code hệ thống cũ (.NET) — tham khảo
│
└── e_office_app_new/                  # SOURCE CODE DỰ ÁN
    ├── docker-compose.yml             # 4 services: PG, Mongo, Redis, MinIO
    ├── ROADMAP.md                     # 17 sprints chi tiết (SP, API, UI)
    ├── SETUP.md                       # File này
    ├── database/
    │   ├── init/01_create_schemas.sql
    │   ├── migrations/
    │   │   └── 000_full_schema.sql    # 1 file gộp (443 SPs, 17k dòng)
    │   ├── migrations_archive/        # 29 files gốc (tra lại nếu cần)
    │   └── seed_full_demo.sql         # Seed data demo đầy đủ
    ├── backend/                       # Express 5 + TypeScript (port 4000)
    ├── frontend/                      # Next.js 16 + Ant Design 6 (port 3000)
    ├── shared/                        # Types + constants dùng chung
    └── workers/                       # BullMQ background jobs
```
