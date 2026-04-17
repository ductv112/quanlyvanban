# Deploy e-Office Production

## Yêu cầu server
- Ubuntu 22.04+ hoặc Debian 12+
- RAM tối thiểu: 4GB (khuyến nghị 8GB)
- Disk: 40GB+
- Port 80 mở cho HTTP

## Deploy lần đầu

```bash
# SSH vào server
ssh <user>@103.97.134.87

# Upload script (hoặc clone repo rồi chạy)
sudo bash deploy.sh
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

```bash
sudo bash /opt/eoffice/quanlyvanban/deploy/update.sh
```

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
