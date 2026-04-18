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

# Apply migration mới (idempotent — tracking qua public._migration_history)
log "Kiểm tra migration mới..."

PG_DB_UP="qlvb_prod"
PG_USER_UP="qlvb_admin"

docker exec -i qlvb_postgres psql -U $PG_USER_UP -d $PG_DB_UP -c "
CREATE TABLE IF NOT EXISTS public._migration_history (
  filename VARCHAR(255) PRIMARY KEY,
  applied_at TIMESTAMPTZ DEFAULT NOW()
);" > /dev/null 2>&1

for f in $(ls "$WORK_DIR"/database/migrations/quick_*.sql 2>/dev/null | sort); do
  fname=$(basename "$f")
  exists=$(docker exec qlvb_postgres psql -U $PG_USER_UP -d $PG_DB_UP -tAc \
    "SELECT 1 FROM public._migration_history WHERE filename='$fname'" 2>/dev/null | tr -d '[:space:]')
  if [ "$exists" != "1" ]; then
    log "  → Apply $fname"
    if ! docker exec -i qlvb_postgres psql -U $PG_USER_UP -d $PG_DB_UP -v ON_ERROR_STOP=1 \
         -f - < "$f" > /dev/null 2>&1; then
      echo "Migration $fname thất bại — kiểm tra thủ công"
      exit 1
    fi
    docker exec -i qlvb_postgres psql -U $PG_USER_UP -d $PG_DB_UP -c \
      "INSERT INTO public._migration_history (filename) VALUES ('$fname') ON CONFLICT DO NOTHING" > /dev/null 2>&1
  fi
done

# Restart apps
log "Restart ứng dụng..."
cd "$WORK_DIR"
pm2 restart all

pm2 status

echo ""
log "Cập nhật hoàn thành!"
echo ""
