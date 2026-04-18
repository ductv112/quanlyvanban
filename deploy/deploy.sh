#!/bin/bash
# ============================================================
# e-Office — Script deploy production
# Server: Ubuntu 22.04+ / Debian 12+
# Chạy: sudo bash deploy.sh
# ============================================================

set -e

# ---- CẤU HÌNH ----
SERVER_IP="103.97.134.87"
APP_DIR="/opt/eoffice"
REPO_URL="https://github.com/ductv112/quanlyvanban.git"
BRANCH="main"

# Database
PG_DB="qlvb_prod"
PG_USER="qlvb_admin"
PG_PASS="QlvbProd@2026!"
MONGO_PASS="QlvbMongo@2026!"
REDIS_PASS="QlvbRedis@2026!"
MINIO_PASS="QlvbMinio@2026!"

# JWT — tự sinh random
JWT_SECRET=$(openssl rand -hex 32)

# ---- MÀU SẮC ----
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }

# ---- KIỂM TRA ROOT ----
if [ "$EUID" -ne 0 ]; then
  err "Chạy script với sudo: sudo bash deploy.sh"
fi

echo ""
echo "============================================"
echo "  e-Office — Deploy Production"
echo "  Server: $SERVER_IP"
echo "============================================"
echo ""

# ============================================================
# BƯỚC 1: Cài đặt phần mềm
# ============================================================
log "Bước 1/10: Cài đặt phần mềm..."

apt update -qq
apt install -y -qq curl git nginx ufw > /dev/null 2>&1

# Docker
if ! command -v docker &> /dev/null; then
  log "Cài Docker..."
  curl -fsSL https://get.docker.com | sh > /dev/null 2>&1
  systemctl enable docker
  systemctl start docker
  log "Docker đã cài xong"
else
  log "Docker đã có sẵn"
fi

# Docker Compose plugin
if ! docker compose version &> /dev/null; then
  apt install -y -qq docker-compose-plugin > /dev/null 2>&1
fi

# Node.js 20
if ! command -v node &> /dev/null || [ "$(node -v | cut -d. -f1 | tr -d v)" -lt 20 ]; then
  log "Cài Node.js 20..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash - > /dev/null 2>&1
  apt install -y -qq nodejs > /dev/null 2>&1
  log "Node.js $(node -v) đã cài xong"
else
  log "Node.js $(node -v) đã có sẵn"
fi

# PM2
if ! command -v pm2 &> /dev/null; then
  npm install -g pm2 > /dev/null 2>&1
  log "PM2 đã cài xong"
fi

log "Bước 1 hoàn thành"

# ============================================================
# BƯỚC 2: Clone code
# ============================================================
log "Bước 2/10: Clone source code..."

mkdir -p "$APP_DIR"
cd "$APP_DIR"

if [ -d "quanlyvanban" ]; then
  cd quanlyvanban
  git fetch --all -q
  git reset --hard origin/$BRANCH -q
  git pull -q
  log "Source code đã cập nhật"
else
  git clone --depth 1 -b $BRANCH "$REPO_URL" > /dev/null 2>&1
  cd quanlyvanban
  log "Source code đã clone"
fi

WORK_DIR="$APP_DIR/quanlyvanban/e_office_app_new"

# ============================================================
# BƯỚC 3: Tạo docker-compose production
# ============================================================
log "Bước 3/10: Cấu hình Docker services..."

cat > "$WORK_DIR/docker-compose.prod.yml" << YAML
services:
  postgres:
    image: postgres:16-alpine
    container_name: qlvb_postgres
    restart: always
    ports:
      - "127.0.0.1:5432:5432"
    environment:
      POSTGRES_DB: $PG_DB
      POSTGRES_USER: $PG_USER
      POSTGRES_PASSWORD: $PG_PASS
      POSTGRES_INITDB_ARGS: "--encoding=UTF8 --locale=C"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/init:/docker-entrypoint-initdb.d
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $PG_USER -d $PG_DB"]
      interval: 10s
      timeout: 5s
      retries: 5

  mongodb:
    image: mongo:7
    container_name: qlvb_mongodb
    restart: always
    ports:
      - "127.0.0.1:27017:27017"
    environment:
      MONGO_INITDB_ROOT_USERNAME: $PG_USER
      MONGO_INITDB_ROOT_PASSWORD: $MONGO_PASS
      MONGO_INITDB_DATABASE: qlvb_logs
    volumes:
      - mongodb_data:/data/db

  redis:
    image: redis:7-alpine
    container_name: qlvb_redis
    restart: always
    ports:
      - "127.0.0.1:6379:6379"
    command: redis-server --requirepass $REDIS_PASS --maxmemory 256mb --maxmemory-policy allkeys-lru
    volumes:
      - redis_data:/data

  minio:
    image: minio/minio:latest
    container_name: qlvb_minio
    restart: always
    ports:
      - "127.0.0.1:9000:9000"
      - "127.0.0.1:9001:9001"
    environment:
      MINIO_ROOT_USER: $PG_USER
      MINIO_ROOT_PASSWORD: $MINIO_PASS
    command: server /data --console-address ":9001"
    volumes:
      - minio_data:/data

volumes:
  postgres_data:
  mongodb_data:
  redis_data:
  minio_data:
YAML

log "Bước 3 hoàn thành"

# ============================================================
# BƯỚC 4: Khởi động Docker services
# ============================================================
log "Bước 4/10: Khởi động Docker services..."

cd "$WORK_DIR"
docker compose -f docker-compose.prod.yml up -d

# Đợi PostgreSQL ready
log "Đợi PostgreSQL khởi động..."
for i in $(seq 1 30); do
  if docker exec qlvb_postgres pg_isready -U $PG_USER -d $PG_DB > /dev/null 2>&1; then
    break
  fi
  sleep 2
done

docker compose -f docker-compose.prod.yml ps
log "Bước 4 hoàn thành"

# ============================================================
# BƯỚC 5: Chạy database migrations + seed demo (nếu fresh install)
# ============================================================
log "Bước 5/10: Chạy database migrations..."

# Tracking table để skip migration đã apply
docker exec -i qlvb_postgres psql -U $PG_USER -d $PG_DB -c "
CREATE TABLE IF NOT EXISTS public._migration_history (
  filename VARCHAR(255) PRIMARY KEY,
  applied_at TIMESTAMPTZ DEFAULT NOW()
);" > /dev/null 2>&1

apply_migration() {
  local file=$1
  local fname=$(basename "$file")
  local exists=$(docker exec qlvb_postgres psql -U $PG_USER -d $PG_DB -tAc \
    "SELECT 1 FROM public._migration_history WHERE filename='$fname'" 2>/dev/null | tr -d '[:space:]')
  if [ "$exists" = "1" ]; then
    return 0
  fi
  log "  → $fname"
  if ! docker exec -i qlvb_postgres psql -U $PG_USER -d $PG_DB -v ON_ERROR_STOP=1 \
       -f - < "$file" > /dev/null 2>&1; then
    err "Migration $fname thất bại"
  fi
  docker exec -i qlvb_postgres psql -U $PG_USER -d $PG_DB -c \
    "INSERT INTO public._migration_history (filename) VALUES ('$fname') ON CONFLICT DO NOTHING" > /dev/null 2>&1
}

# Apply base schema
apply_migration "$WORK_DIR/database/migrations/000_full_schema.sql"

# Apply các quick migration (hlj, jsd, ...) — sorted tự nhiên
for f in $(ls "$WORK_DIR"/database/migrations/quick_*.sql 2>/dev/null | sort); do
  apply_migration "$f"
done

# Seed demo data chỉ khi DB trống (fresh install)
STAFF_COUNT=$(docker exec qlvb_postgres psql -U $PG_USER -d $PG_DB -tAc \
  "SELECT COUNT(*) FROM public.staff" 2>/dev/null | tr -d '[:space:]')
if [ "$STAFF_COUNT" = "0" ] || [ -z "$STAFF_COUNT" ]; then
  log "  → Seed demo data (lần đầu)..."
  if [ -f "$WORK_DIR/database/seed-demo.sql" ]; then
    # seed có DISABLE TRIGGER ALL (pg_dump) — cần superuser postgres
    docker exec -i qlvb_postgres psql -U postgres -d $PG_DB -v ON_ERROR_STOP=1 \
      -f - < "$WORK_DIR/database/seed-demo.sql" > /dev/null 2>&1 \
      || warn "Seed demo thất bại (không critical)"
  else
    warn "Không tìm thấy seed-demo.sql — bỏ qua"
  fi
else
  log "  → Đã có $STAFF_COUNT staff — bỏ qua seed"
fi

log "Database migrations hoàn thành"

# ============================================================
# BƯỚC 6: Cấu hình Backend
# ============================================================
log "Bước 6/10: Build Backend..."

cat > "$WORK_DIR/backend/.env" << EOF
PORT=4000
NODE_ENV=production
CORS_ORIGIN=http://$SERVER_IP

PG_HOST=127.0.0.1
PG_PORT=5432
PG_DATABASE=$PG_DB
PG_USER=$PG_USER
PG_PASSWORD=$PG_PASS
PG_MAX_CONNECTIONS=20

MONGODB_URI=mongodb://${PG_USER}:$(echo $MONGO_PASS | sed 's/@/%40/g')@127.0.0.1:27017/qlvb_logs?authSource=admin

REDIS_HOST=127.0.0.1
REDIS_PORT=6379
REDIS_PASSWORD=$REDIS_PASS

MINIO_ENDPOINT=127.0.0.1
MINIO_PORT=9000
MINIO_ACCESS_KEY=$PG_USER
MINIO_SECRET_KEY=$MINIO_PASS
MINIO_USE_SSL=false
MINIO_BUCKET=documents

JWT_SECRET=$JWT_SECRET
JWT_ACCESS_EXPIRES=15m
JWT_REFRESH_EXPIRES=7d
EOF

cd "$WORK_DIR/backend"
npm install --omit=dev > /dev/null 2>&1
npm run build > /dev/null 2>&1

log "Backend build xong"

# ============================================================
# BƯỚC 7: Cấu hình Frontend
# ============================================================
log "Bước 7/10: Build Frontend (có thể mất 2-3 phút)..."

echo "NEXT_PUBLIC_API_URL=http://$SERVER_IP/api" > "$WORK_DIR/frontend/.env.local"

cd "$WORK_DIR/frontend"
npm install > /dev/null 2>&1
npm run build > /dev/null 2>&1

log "Frontend build xong"

# ============================================================
# BƯỚC 8: Khởi động PM2
# ============================================================
log "Bước 8/10: Khởi động ứng dụng..."

# Tạo PM2 ecosystem file
cat > "$WORK_DIR/ecosystem.config.cjs" << 'PMEOF'
module.exports = {
  apps: [
    {
      name: 'eoffice-api',
      cwd: './backend',
      script: 'dist/server.js',
      node_args: '--env-file=.env',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production',
      },
      max_memory_restart: '512M',
      error_file: '/var/log/eoffice/api-error.log',
      out_file: '/var/log/eoffice/api-out.log',
      merge_logs: true,
    },
    {
      name: 'eoffice-web',
      cwd: './frontend',
      script: 'node_modules/.bin/next',
      args: 'start',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'production',
        PORT: 3000,
      },
      max_memory_restart: '512M',
      error_file: '/var/log/eoffice/web-error.log',
      out_file: '/var/log/eoffice/web-out.log',
      merge_logs: true,
    },
  ],
};
PMEOF

mkdir -p /var/log/eoffice

cd "$WORK_DIR"
pm2 delete all > /dev/null 2>&1 || true
pm2 start ecosystem.config.cjs
pm2 save

# Auto-start on reboot
pm2 startup systemd -u root --hp /root > /dev/null 2>&1 || true

log "Bước 8 hoàn thành"

# ============================================================
# BƯỚC 9: Cấu hình Nginx
# ============================================================
log "Bước 9/10: Cấu hình Nginx..."

cat > /etc/nginx/sites-available/eoffice << 'NGINX'
server {
    listen 80;
    server_name _;
    client_max_body_size 50M;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Gzip
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml text/javascript image/svg+xml;
    gzip_min_length 1000;
    gzip_comp_level 5;

    # Backend API
    location /api/ {
        proxy_pass http://127.0.0.1:4000/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 30s;
        proxy_send_timeout 30s;
    }

    # Frontend (Next.js)
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_cache_bypass $http_upgrade;
    }

    # Next.js static files — cache dài
    location /_next/static/ {
        proxy_pass http://127.0.0.1:3000/_next/static/;
        proxy_cache_valid 200 365d;
        add_header Cache-Control "public, max-age=31536000, immutable";
    }
}
NGINX

ln -sf /etc/nginx/sites-available/eoffice /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

log "Bước 9 hoàn thành"

# ============================================================
# BƯỚC 10: Firewall
# ============================================================
log "Bước 10/10: Cấu hình firewall..."

ufw --force reset > /dev/null 2>&1
ufw default deny incoming > /dev/null 2>&1
ufw default allow outgoing > /dev/null 2>&1
ufw allow 22/tcp > /dev/null 2>&1    # SSH
ufw allow 80/tcp > /dev/null 2>&1    # HTTP
ufw allow 443/tcp > /dev/null 2>&1   # HTTPS (tương lai)
ufw --force enable > /dev/null 2>&1

log "Firewall: chỉ mở port 22, 80, 443"

# ============================================================
# HOÀN THÀNH
# ============================================================
echo ""
echo "============================================"
echo -e "  ${GREEN}DEPLOY HOÀN THÀNH!${NC}"
echo "============================================"
echo ""
echo "  Truy cập: http://$SERVER_IP"
echo ""
echo "  Tài khoản mặc định:"
echo "    Username: admin"
echo "    Password: Admin@123"
echo ""
echo "  Quản lý:"
echo "    pm2 status         — xem trạng thái app"
echo "    pm2 logs           — xem logs"
echo "    pm2 restart all    — restart app"
echo ""
echo "  Cấu hình đã lưu tại:"
echo "    Backend:  $WORK_DIR/backend/.env"
echo "    Frontend: $WORK_DIR/frontend/.env.local"
echo "    Nginx:    /etc/nginx/sites-available/eoffice"
echo "    PM2:      $WORK_DIR/ecosystem.config.cjs"
echo ""
echo "  JWT_SECRET: $JWT_SECRET"
echo "  (Lưu lại chuỗi này — mất sẽ phải reset tất cả phiên đăng nhập)"
echo ""
echo "============================================"
