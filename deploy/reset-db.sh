#!/bin/bash
# ============================================================
# e-Office — Reset DB (CHỈ DÙNG CHO TEST SERVER)
# Wipe sạch DB → re-run schema + migrations + seed demo
#
# ⚠️ CẢNH BÁO: Xóa TOÀN BỘ data — KHÔNG dùng trên production thật
# ============================================================

set -e

APP_DIR="/opt/eoffice/quanlyvanban"
WORK_DIR="$APP_DIR/e_office_app_new"
PG_DB="qlvb_prod"
PG_USER="qlvb_admin"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }

if [ "$EUID" -ne 0 ]; then
  err "Chạy với sudo: sudo bash reset-db.sh"
fi

echo ""
echo "================================================================"
echo -e "  ${RED}⚠ RESET DB — sẽ xóa SẠCH toàn bộ data trong $PG_DB${NC}"
echo "================================================================"
echo ""

# Confirm (yêu cầu gõ chính xác 'yes')
read -p "Xác nhận xóa sạch DB? Gõ 'yes' để tiếp tục: " confirm
if [ "$confirm" != "yes" ]; then
  echo "Đã hủy."
  exit 0
fi
echo ""

# ============================================================
# 1. Pull code mới (optional nhưng tiện)
# ============================================================
if [ -d "$APP_DIR/.git" ]; then
  log "Pull code mới..."
  cd "$APP_DIR"
  git fetch --all -q
  git reset --hard origin/main -q
else
  warn "Skip git pull — $APP_DIR không phải git repo"
fi

# ============================================================
# 2. Drop + recreate schemas
# ============================================================
log "Drop tất cả schemas..."

docker exec qlvb_postgres psql -U $PG_USER -d $PG_DB -v ON_ERROR_STOP=1 -c "
DROP SCHEMA IF EXISTS edoc CASCADE;
DROP SCHEMA IF EXISTS esto CASCADE;
DROP SCHEMA IF EXISTS cont CASCADE;
DROP SCHEMA IF EXISTS iso  CASCADE;
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO $PG_USER;
GRANT ALL ON SCHEMA public TO PUBLIC;
" > /dev/null || err "Drop schemas thất bại"

log "Schemas đã được reset"

# ============================================================
# 3. Apply base schema + quick migrations
# ============================================================
log "Apply 000_full_schema.sql..."

# Migration tracking table
docker exec -i qlvb_postgres psql -U $PG_USER -d $PG_DB -v ON_ERROR_STOP=1 -c "
CREATE TABLE IF NOT EXISTS public._migration_history (
  filename VARCHAR(255) PRIMARY KEY,
  applied_at TIMESTAMPTZ DEFAULT NOW()
);" > /dev/null

apply_migration() {
  local file=$1
  local fname=$(basename "$file")
  log "  → $fname"
  if ! docker exec -i qlvb_postgres psql -U $PG_USER -d $PG_DB -v ON_ERROR_STOP=1 \
       -f - < "$file" > /dev/null 2>&1; then
    err "Migration $fname thất bại"
  fi
  docker exec -i qlvb_postgres psql -U $PG_USER -d $PG_DB -c \
    "INSERT INTO public._migration_history (filename) VALUES ('$fname') ON CONFLICT DO NOTHING" > /dev/null 2>&1
}

apply_migration "$WORK_DIR/database/migrations/000_full_schema.sql"

for f in $(ls "$WORK_DIR"/database/migrations/quick_*.sql 2>/dev/null | sort); do
  apply_migration "$f"
done

# ============================================================
# 4. Seed demo data
# ============================================================
log "Seed demo data..."
if [ -f "$WORK_DIR/database/seed-demo.sql" ]; then
  # seed có DISABLE TRIGGER ALL (pg_dump) — cần superuser postgres
  docker exec -i qlvb_postgres psql -U postgres -d $PG_DB -v ON_ERROR_STOP=1 \
    -f - < "$WORK_DIR/database/seed-demo.sql" > /dev/null 2>&1 \
    || warn "Seed demo thất bại"
else
  warn "Không tìm thấy seed-demo.sql"
fi

# ============================================================
# 5. Rebuild backend + frontend (optional)
# ============================================================
read -p "Rebuild backend + frontend? [y/N] " rebuild
if [ "$rebuild" = "y" ] || [ "$rebuild" = "Y" ]; then
  log "Build Backend..."
  cd "$WORK_DIR/backend"
  npm install --omit=dev > /dev/null 2>&1
  npm run build > /dev/null 2>&1

  log "Build Frontend (2-3 phút)..."
  cd "$WORK_DIR/frontend"
  npm install > /dev/null 2>&1
  npm run build > /dev/null 2>&1

  log "Restart pm2..."
  pm2 restart all > /dev/null 2>&1 || warn "pm2 restart thất bại — check pm2 status"
fi

echo ""
echo "================================================================"
log "DB đã reset + apply đầy đủ migrations + seed demo"
echo ""
echo "  Demo accounts trong seed-demo.sql — check file để biết"
echo "  Login: http://<server-ip>"
echo "================================================================"
echo ""
