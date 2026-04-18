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
4. Chạy database migrations + seed data
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
- Apply migration mới (file `quick_*.sql` chưa apply, tracking qua bảng `public._migration_history`)
- Restart pm2
- **KHÔNG** re-run seed (giữ nguyên data đang có)

## Reset toàn bộ DB (CHỈ CHO TEST SERVER)

⚠️ Xóa sạch data — dùng khi muốn test lại từ DB trống tinh:

**Linux:**
```bash
sudo bash /opt/eoffice/quanlyvanban/deploy/reset-db.sh
```

**Windows (PowerShell Administrator):**
```powershell
cd C:\qlvb\quanlyvanban\deploy
.\reset-db-windows.ps1
```

Script tự động:
1. Hỏi xác nhận gõ `yes`
2. Pull code mới
3. DROP tất cả schemas (`edoc`, `esto`, `cont`, `iso`, `public`)
4. Re-apply `000_full_schema.sql` + tất cả `quick_*.sql` theo thứ tự
5. Seed `seed-demo.sql` (demo accounts)
6. Hỏi có rebuild + restart không

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
