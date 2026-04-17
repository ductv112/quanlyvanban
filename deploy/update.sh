#!/bin/bash
# ============================================================
# e-Office — Script cập nhật code (chạy khi push code mới)
# Chạy: sudo bash update.sh
# ============================================================

set -e

APP_DIR="/opt/eoffice/quanlyvanban"
WORK_DIR="$APP_DIR/e_office_app_new"

GREEN='\033[0;32m'
NC='\033[0m'
log() { echo -e "${GREEN}[✓]${NC} $1"; }

if [ "$EUID" -ne 0 ]; then
  echo "Chạy với sudo: sudo bash update.sh"
  exit 1
fi

echo ""
echo "=== e-Office — Cập nhật ==="
echo ""

# Pull code mới
cd "$APP_DIR"
log "Pull code mới..."
git fetch --all -q
git reset --hard origin/main -q

# Rebuild backend
log "Build Backend..."
cd "$WORK_DIR/backend"
npm install --omit=dev > /dev/null 2>&1
npm run build > /dev/null 2>&1

# Rebuild frontend
log "Build Frontend (2-3 phút)..."
cd "$WORK_DIR/frontend"
npm install > /dev/null 2>&1
npm run build > /dev/null 2>&1

# Restart apps
log "Restart ứng dụng..."
cd "$WORK_DIR"
pm2 restart all

# Chạy migration mới (nếu có)
# docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_prod \
#   -f - < "$WORK_DIR/database/migrations/0XX_new_migration.sql"

pm2 status

echo ""
log "Cập nhật hoàn thành!"
echo ""
