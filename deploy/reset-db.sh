#!/bin/bash
# ============================================================
# e-Office — Reset DB (CHỈ DÙNG CHO TEST SERVER)
# Flow v2.0 consolidated: schema master + 2 file seed (KHÔNG loop migrations/)
#
# ⚠️ CẢNH BÁO: Xóa TOÀN BỘ data — KHÔNG dùng trên production thật
# Usage: sudo bash reset-db.sh [--no-demo]
#   --no-demo: bỏ qua seed/002 demo data (production deploy dùng flag này)
# ============================================================

set -e

APP_DIR="/opt/eoffice/quanlyvanban"
WORK_DIR="$APP_DIR/e_office_app_new"
PG_DB="qlvb_prod"
PG_USER="qlvb_admin"

# Session variable cho pgp_sym_encrypt trong seed/001 — PHẢI match backend SIGNING_SECRET_KEY (.env)
SIGNING_KEY="${SIGNING_SECRET_KEY:-qlvb-signing-dev-key-change-production-2026}"

# Parse flags
NO_DEMO=false
for arg in "$@"; do
  case "$arg" in
    --no-demo) NO_DEMO=true ;;
  esac
done

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
if [ "$NO_DEMO" = "true" ]; then
  echo -e "  ${YELLOW}(--no-demo: chỉ seed required data, KHÔNG seed demo 002)${NC}"
fi
echo "================================================================"
echo ""

read -p "Xác nhận xóa sạch DB? Gõ 'yes' để tiếp tục: " confirm
if [ "$confirm" != "yes" ]; then
  echo "Đã hủy."
  exit 0
fi
echo ""

# ============================================================
# 1. Pull code mới (optional)
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

log "Schemas đã reset"

# ============================================================
# 3. Apply init (schemas + extensions)
# ============================================================
log "Apply init/01_create_schemas.sql (schemas edoc/esto/cont/iso + extensions)..."

docker exec -i qlvb_postgres psql -U $PG_USER -d $PG_DB -v ON_ERROR_STOP=1 -f - \
  < "$WORK_DIR/database/init/01_create_schemas.sql" > /dev/null \
  || err "Init schemas thất bại"

# ============================================================
# 4. Apply master schema v2.0
# ============================================================
log "Apply schema/000_schema_v2.0.sql (MASTER — tables + SPs + triggers)..."

docker exec -i qlvb_postgres psql -U $PG_USER -d $PG_DB -v ON_ERROR_STOP=1 -f - \
  < "$WORK_DIR/database/schema/000_schema_v2.0.sql" > /dev/null \
  || err "Schema master thất bại"

# ============================================================
# 5. Apply seed 001 (required data)
#    PHẢI set app.signing_secret_key để pgp_sym_encrypt encrypt client_secret
# ============================================================
log "Apply seed/001_required_data.sql (admin + roles + rights + 2 providers)..."

# Dùng -v để SET variable via psql \set, sau đó seed file làm SET LOCAL
# Cách an toàn: gộp SET + \i trong 1 session qua heredoc
docker exec -i qlvb_postgres psql -U $PG_USER -d $PG_DB -v ON_ERROR_STOP=1 \
  -c "SET app.signing_secret_key = '$SIGNING_KEY';" \
  -f - < "$WORK_DIR/database/seed/001_required_data.sql" > /dev/null \
  || err "Seed 001 thất bại (kiểm tra SIGNING_SECRET_KEY env var — cần ≥ 16 ký tự)"

# ============================================================
# 6. Apply seed 002 (demo) — SKIP nếu --no-demo
# ============================================================
if [ "$NO_DEMO" = "false" ]; then
  log "Apply seed/002_demo_data.sql (rich demo data 312 records)..."
  docker exec -i qlvb_postgres psql -U $PG_USER -d $PG_DB -v ON_ERROR_STOP=1 -f - \
    < "$WORK_DIR/database/seed/002_demo_data.sql" > /dev/null \
    || err "Seed 002 thất bại"
else
  warn "Skip seed/002_demo_data.sql (--no-demo) — DB chỉ có required data"
fi

# ============================================================
# 7. Rebuild backend + frontend (optional)
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
log "DB reset thành công"
echo ""
echo "  Admin: username=admin, password=Admin@123"
echo "  Login: http://<server-ip>"
if [ "$NO_DEMO" = "false" ]; then
  echo "  Demo data: 10 users, 50 VB đến, 30 VB đi, 20 dự thảo, 15 HSCV, 2 provider config"
else
  echo "  --no-demo mode: chỉ admin + 2 provider config (production-like)"
fi
echo "================================================================"
echo ""
