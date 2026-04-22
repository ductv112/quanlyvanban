# Deploy e-Office Production

## Yêu cầu server
- **Linux**: Ubuntu 22.04+ hoặc Debian 12+ (dùng script `.sh`)
- **Windows**: Windows Server 2022 + IIS (dùng script `.ps1`)
- RAM tối thiểu: 4GB (khuyến nghị 8GB)
- Disk: 40GB+
- Port 80 mở cho HTTP

## Chọn scripts theo OS

| Task | Linux | Windows |
|---|---|---|
| Deploy lần đầu | `deploy.sh` | `deploy-windows.ps1` |
| Update code | `update.sh` | `update-windows.ps1` |
| Reset DB (test) | `reset-db.sh` | `reset-db-windows.ps1` |

## Cấu trúc DB (v2.0 consolidated)

Từ Phase 11.1 (2026-04-22), DB được tổ chức như sau:

```
e_office_app_new/database/
├── init/
│   └── 01_create_schemas.sql         # Bootstrap Docker — schemas + extensions
├── schema/
│   └── 000_schema_v2.0.sql           # MASTER idempotent schema (tables + SPs + triggers)
├── seed/
│   ├── 001_required_data.sql         # BẮT BUỘC: admin + roles + rights + 2 providers
│   └── 002_demo_data.sql             # OPTIONAL: 312 records demo (skip cho production)
├── migrations/
│   └── README.md                     # Pointer — folder đã consolidate
└── archive/
    ├── v1.0-migrations/              # Lịch sử Phase 1-7 (KHÔNG chạy)
    └── v2.0-incrementals/            # Lịch sử Phase 8-11 (KHÔNG chạy)
```

**Luật:** KHÔNG thêm file `migrations/*.sql` rời. Edit trực tiếp `schema/000_schema_v2.0.sql`. Xem `CLAUDE.md` section "DB Migration Strategy (v2.0+)" để biết rules.

## Environment variable BẮT BUỘC

Trước khi chạy seed 001, backend + DB **PHẢI dùng chung key** để encrypt/decrypt `client_secret` của provider ký số:

**Backend `.env`:**
```bash
SIGNING_SECRET_KEY=<32+ ký tự random hex>
```

Các script deploy tự động dùng `JWT_SECRET` làm `SIGNING_SECRET_KEY` để 2 key nhất quán. Reset-db scripts đọc biến env `SIGNING_SECRET_KEY` (nếu có) và set vào session `app.signing_secret_key` trước apply seed 001. Nếu không có env var, dùng hardcoded dev key.

**Lưu ý quan trọng:** Khi đổi `SIGNING_SECRET_KEY` sau deploy, client_secret của provider config **KHÔNG decrypt được** — Admin PHẢI login vào `/ky-so/cau-hinh` và nhập lại credentials (không phải reset DB).

## Deploy lần đầu

**Linux:**
```bash
ssh <user>@103.97.134.87
sudo bash /opt/eoffice/quanlyvanban/deploy/deploy.sh
```

**Windows (PowerShell Administrator):**
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
cd C:\qlvb\quanlyvanban\deploy
.\deploy-windows.ps1
```

Script tự động:
1. Cài Docker, Node.js 20, Nginx, PM2
2. Clone code từ GitHub
3. Khởi động 4 Docker services (PostgreSQL, MongoDB, Redis, MinIO)
4. Apply DB v2.0:
   - `init/01_create_schemas.sql` (schemas + extensions)
   - `schema/000_schema_v2.0.sql` (master — tables + SPs + triggers)
   - `seed/001_required_data.sql` (admin/Admin@123 + 2 provider config)
   - **KHÔNG** chạy `seed/002_demo_data.sql` (production không có demo data)
5. Build backend + frontend
6. Cấu hình Nginx reverse proxy
7. Cấu hình firewall (chỉ mở 22, 80, 443)

## Cập nhật code

**Linux:**
```bash
sudo bash /opt/eoffice/quanlyvanban/deploy/update.sh
```

**Windows (PowerShell Administrator):**
```powershell
cd C:\qlvb\quanlyvanban\deploy
.\update-windows.ps1
```

Script tự động:
- Pull code mới từ GitHub
- Rebuild backend + frontend
- **Re-apply `schema/000_schema_v2.0.sql`** (idempotent — đồng bộ SPs mới nếu có thay đổi, giữ nguyên data)
- Restart pm2
- **KHÔNG** re-run seed (giữ nguyên data đang có)

## Reset toàn bộ DB (CHỈ CHO TEST SERVER)

⚠️ Xóa sạch data — dùng khi muốn test lại từ DB trống tinh:

**Linux:**
```bash
# Mặc định: seed cả required + demo (150+ records test UI)
sudo bash /opt/eoffice/quanlyvanban/deploy/reset-db.sh

# Production simulation: chỉ seed required data
sudo bash /opt/eoffice/quanlyvanban/deploy/reset-db.sh --no-demo
```

**Windows (PowerShell Administrator):**
```powershell
cd C:\qlvb\quanlyvanban\deploy

# Mặc định: seed cả required + demo
.\reset-db-windows.ps1

# Production simulation: chỉ seed required data
.\reset-db-windows.ps1 -NoDemo
```

Script tự động:
1. Hỏi xác nhận gõ `yes`
2. Pull code mới
3. DROP tất cả schemas (`edoc`, `esto`, `cont`, `iso`, `public`)
4. Apply `init/01_create_schemas.sql` (schemas + extensions)
5. Apply `schema/000_schema_v2.0.sql` (master)
6. Apply `seed/001_required_data.sql` — dùng env var `SIGNING_SECRET_KEY` cho `app.signing_secret_key`
7. Apply `seed/002_demo_data.sql` (skip nếu `--no-demo` / `-NoDemo`)
8. Hỏi có rebuild + restart không

## Backup database

```bash
# Chạy thủ công
sudo bash /opt/eoffice/quanlyvanban/deploy/backup.sh

# Đặt lịch backup tự động 2h sáng mỗi ngày
sudo crontab -e
# Thêm dòng:
0 2 * * * /opt/eoffice/quanlyvanban/deploy/backup.sh >> /var/log/eoffice/backup.log 2>&1
```

## Quản lý thường ngày

```bash
pm2 status              # Xem trạng thái
pm2 logs                # Xem logs realtime
pm2 logs eoffice-api    # Logs backend
pm2 logs eoffice-web    # Logs frontend
pm2 restart all         # Restart tất cả
pm2 restart eoffice-api # Restart backend

docker compose -f /opt/eoffice/quanlyvanban/e_office_app_new/docker-compose.prod.yml ps
docker compose -f /opt/eoffice/quanlyvanban/e_office_app_new/docker-compose.prod.yml logs postgres
```

## Kiến trúc

```
Client → Nginx (:80)
           ├─ /        → Next.js (:3000)  ← PM2
           └─ /api/    → Express (:4000)  ← PM2
                          ├─ PostgreSQL (:5432)  ← Docker
                          ├─ MongoDB (:27017)    ← Docker
                          ├─ Redis (:6379)       ← Docker
                          └─ MinIO (:9000)       ← Docker
```

## File cấu hình

| File | Đường dẫn |
|------|-----------|
| Backend env | `/opt/eoffice/quanlyvanban/e_office_app_new/backend/.env` |
| Frontend env | `/opt/eoffice/quanlyvanban/e_office_app_new/frontend/.env.local` |
| PM2 | `/opt/eoffice/quanlyvanban/e_office_app_new/ecosystem.config.cjs` |
| Nginx | `/etc/nginx/sites-available/eoffice` |
| Docker | `/opt/eoffice/quanlyvanban/e_office_app_new/docker-compose.prod.yml` |

## Tài khoản mặc định

- **Username:** admin
- **Password:** Admin@123
- Đổi mật khẩu ngay sau khi đăng nhập lần đầu

## Tham khảo

- `.planning/phases/11.1-db-consolidation-seed-strategy/` — chi tiết Phase 11.1 (schema consolidation + seed strategy)
- `e_office_app_new/database/archive/v1.0-migrations/README.md` — lịch sử migrations v1.0
- `e_office_app_new/database/archive/v2.0-incrementals/README.md` — lịch sử migrations v2.0 Phase 8-11
- `CLAUDE.md` — section "DB Migration Strategy (v2.0+)" với rules chi tiết
