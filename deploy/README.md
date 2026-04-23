# Deploy e-Office Production

## Yêu cầu server

- **Windows Server 2022** + **IIS** (URL Rewrite + Application Request Routing)
- RAM tối thiểu: 4GB (khuyến nghị 8GB)
- Disk: 40GB+
- Port 80 mở cho HTTP (443 nếu bật HTTPS)
- Quyền Administrator để chạy PowerShell scripts

> **Lưu ý:** Dự án hiện CHỈ hỗ trợ Windows Server. Hệ điều hành khác không được support.

## Scripts có sẵn

| Task | Script |
|------|--------|
| Deploy lần đầu | `deploy-windows.ps1` |
| Update code | `update-windows.ps1` |
| Reset DB (test) | `reset-db-windows.ps1` |
| Cấu hình IIS reverse proxy | `setup-iis.ps1` |

## Cấu trúc DB (v2.0 consolidated)

Từ Phase 11.1 (2026-04-22), DB được tổ chức như sau:

```
e_office_app_new/database/
├── init/
│   └── 01_create_schemas.sql         # Bootstrap — schemas + extensions
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

**Luật:** KHÔNG thêm file migrations rời. Edit trực tiếp `schema/000_schema_v2.0.sql`. Xem `CLAUDE.md` section "DB Migration Strategy (v2.0+)" để biết rules.

## Environment variable BẮT BUỘC

Trước khi chạy seed 001, backend + DB **PHẢI dùng chung key** để encrypt/decrypt `client_secret` của provider ký số:

**Backend `.env`:**

```env
SIGNING_SECRET_KEY=<32+ ký tự random hex>
```

Các script deploy tự động dùng `JWT_SECRET` làm `SIGNING_SECRET_KEY` để 2 key nhất quán. Script `reset-db-windows.ps1` đọc biến env `SIGNING_SECRET_KEY` (nếu có) và set vào session `app.signing_secret_key` trước apply seed 001. Nếu không có env var, dùng hardcoded dev key.

**Lưu ý quan trọng:** Khi đổi `SIGNING_SECRET_KEY` sau deploy, client_secret của provider config **KHÔNG decrypt được** — Admin PHẢI login vào `/ky-so/cau-hinh` và nhập lại credentials (không phải reset DB).

## Deploy lần đầu

Chạy trong PowerShell (Run as Administrator):

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
cd C:\qlvb\quanlyvanban\deploy
.\deploy-windows.ps1
```

Script tự động:

1. Cài Git, Node.js 20, PostgreSQL 16, Redis, MinIO, PM2
2. Clone code từ GitHub
3. Tạo database `qlvb_prod` + user `qlvb_admin`
4. Apply DB v2.0:
   - `init/01_create_schemas.sql` (schemas + extensions)
   - `schema/000_schema_v2.0.sql` (master — tables + SPs + triggers)
   - `seed/001_required_data.sql` (admin + roles + rights + 2 provider config)
   - **KHÔNG** chạy `seed/002_demo_data.sql` (production không có demo data)
5. Build backend + frontend
6. Khởi động PM2 (eoffice-api + eoffice-web)
7. Mở Firewall port 80, 443

Sau khi `deploy-windows.ps1` xong, chạy `setup-iis.ps1` để cấu hình IIS reverse proxy (URL Rewrite + ARR trỏ `/` → Next.js `:3000` và `/api/*` → Express `:4000`).

## Cập nhật code

Chạy trong PowerShell (Run as Administrator):

```powershell
cd C:\qlvb\quanlyvanban\deploy
.\update-windows.ps1
```

Script tự động:

- Pull code mới từ GitHub (`git reset --hard origin/main`)
- `npm install` + `npm run build` backend + frontend
- **Re-apply `schema/000_schema_v2.0.sql`** (idempotent — đồng bộ SPs mới nếu có thay đổi, giữ nguyên data)
- Restart PM2
- **KHÔNG** re-run seed (giữ nguyên data đang có)

## Reset toàn bộ DB (CHỈ CHO TEST SERVER)

Xóa sạch data — chỉ dùng khi muốn test lại từ DB trống tinh. Chạy trong PowerShell (Run as Administrator):

```powershell
cd C:\qlvb\quanlyvanban\deploy

# Mặc định: seed cả required + demo (312 records test UI)
.\reset-db-windows.ps1

# Production simulation: chỉ seed required data
.\reset-db-windows.ps1 -NoDemo
```

Script tự động:

1. Hỏi xác nhận — gõ chính xác `yes` để tiếp tục
2. Pull code mới (nếu là git repo)
3. DROP tất cả schemas (`edoc`, `esto`, `cont`, `iso`, `public`)
4. Apply `init/01_create_schemas.sql` (schemas + extensions)
5. Apply `schema/000_schema_v2.0.sql` (master)
6. Apply `seed/001_required_data.sql` — dùng env var `SIGNING_SECRET_KEY` set vào session `app.signing_secret_key`
7. Apply `seed/002_demo_data.sql` (skip nếu `-NoDemo`)
8. Hỏi có rebuild + restart PM2 không

## Quản lý thường ngày

Chạy trong PowerShell:

```powershell
pm2 status              # Xem trạng thái
pm2 logs                # Xem logs realtime
pm2 logs eoffice-api    # Logs backend
pm2 logs eoffice-web    # Logs frontend
pm2 restart all         # Restart tất cả
pm2 restart eoffice-api # Restart backend

# Services Windows
Get-Service postgresql-16, Redis, minio
Restart-Service Redis
```

## Kiến trúc

```
Client → IIS (:80)
          ├─ /        → Next.js (:3000)  ← PM2
          └─ /api/    → Express (:4000)  ← PM2
                         ├─ PostgreSQL (:5432)  ← Windows service
                         ├─ Redis (:6379)       ← Windows service
                         └─ MinIO (:9000)       ← Windows service (NSSM)
```

## File cấu hình

| File | Đường dẫn |
|------|-----------|
| Backend env  | `C:\qlvb\quanlyvanban\e_office_app_new\backend\.env` |
| Frontend env | `C:\qlvb\quanlyvanban\e_office_app_new\frontend\.env.local` |
| PM2          | `C:\qlvb\quanlyvanban\e_office_app_new\ecosystem.config.cjs` |
| IIS config   | `C:\inetpub\wwwroot\web.config` (tạo bởi `setup-iis.ps1`) |
| PostgreSQL   | `C:\PostgreSQL\16\data\postgresql.conf` |
| Redis        | `C:\Program Files\Redis\redis.windows-service.conf` |
| MinIO data   | `C:\minio\data` |

## Tài khoản mặc định

- **Username:** admin
- **Password:** Admin@123
- Đổi mật khẩu ngay sau khi đăng nhập lần đầu

## Tham khảo

- `.planning/phases/11.1-db-consolidation-seed-strategy/` — chi tiết Phase 11.1 (schema consolidation + seed strategy)
- `e_office_app_new/database/archive/v1.0-migrations/README.md` — lịch sử migrations v1.0
- `e_office_app_new/database/archive/v2.0-incrementals/README.md` — lịch sử migrations v2.0 Phase 8-11
- `CLAUDE.md` — section "DB Migration Strategy (v2.0+)" với rules chi tiết
