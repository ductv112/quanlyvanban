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

# Re-apply master schema v2.0 (idempotent) — đồng bộ SP mới nếu schema thay đổi
# File schema/000_schema_v2.0.sql safe để chạy lại vì:
#   - DROP ALL fn_* đầu file + CREATE OR REPLACE cho SPs
#   - CREATE TABLE IF NOT EXISTS + ADD CONSTRAINT wrapped trong DO block catch duplicate
# KHÔNG chạy seed (giữ nguyên data production)
log "Re-apply master schema (đồng bộ SPs mới, idempotent)..."

PG_DB_UP="qlvb_prod"
PG_USER_UP="qlvb_admin"

SCHEMA_FILE="$WORK_DIR/database/schema/000_schema_v2.0.sql"
if [ -f "$SCHEMA_FILE" ]; then
  if ! docker exec -i qlvb_postgres psql -U $PG_USER_UP -d $PG_DB_UP -v ON_ERROR_STOP=1 \
       -f - < "$SCHEMA_FILE" > /dev/null 2>&1; then
    echo "Schema master re-apply thất bại — kiểm tra thủ công"
    exit 1
  fi
  log "  → schema/000_schema_v2.0.sql re-applied OK"
else
  echo "Không tìm thấy $SCHEMA_FILE — kiểm tra cấu trúc repo"
  exit 1
fi

# Restart apps
log "Restart ứng dụng..."
cd "$WORK_DIR"
pm2 restart all

pm2 status

echo ""
log "Cập nhật hoàn thành!"
echo ""
