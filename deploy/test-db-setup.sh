#!/usr/bin/env bash
# ============================================================
# test-db-setup.sh - Setup qlvb_test DB cho automation testing
# Linux/Ubuntu wrapper, dung trong CI ubuntu-latest hoac local
#
# Chay:
#   bash deploy/test-db-setup.sh           # confirm prompt
#   bash deploy/test-db-setup.sh -f        # skip confirm (CI / auto)
#   FORCE=1 bash deploy/test-db-setup.sh   # alternative skip via env
#
# Yeu cau:
#   - PostgreSQL chay tren localhost:5432 (docker hoac native)
#   - Node.js + npm da install
#   - Backend da chay 'npm install'
#
# Pre-requisite: tao .env.test trong backend dir tu .env.test.example
# ============================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND_DIR="$REPO_ROOT/e_office_app_new/backend"
ENV_TEST_EXAMPLE="$REPO_ROOT/.env.test.example"
ENV_TEST_BACKEND="$BACKEND_DIR/.env.test"

# Parse -f / --force flag
FORCE_FLAG="${FORCE:-0}"
for arg in "$@"; do
  case "$arg" in
    -f|--force|--Force)
      FORCE_FLAG=1
      ;;
  esac
done

log()  { echo "[OK] $1"; }
warn() { echo "[!!] $1" >&2; }
err()  { echo "[XX] $1" >&2; exit 1; }

echo ''
echo '================================================================'
echo '  Setup qlvb_test DB cho automation test'
echo '  (DROP qlvb_test + apply schema v3.0 + seed 001 + seed 003)'
echo '================================================================'
echo ''

# Confirm (skip khi -f hoac FORCE=1)
if [[ "$FORCE_FLAG" != "1" ]]; then
  read -r -p "Setup qlvb_test DB? Go 'yes' de tiep tuc: " confirm
  if [[ "$confirm" != "yes" ]]; then
    echo 'Da huy.'
    exit 0
  fi
else
  warn '-f / FORCE=1 enabled - skip confirm, chay tu dong'
fi

# Verify backend dir ton tai
if [[ ! -d "$BACKEND_DIR" ]]; then
  err "Backend dir khong ton tai: $BACKEND_DIR"
fi

# Verify .env.test
if [[ ! -f "$ENV_TEST_BACKEND" ]]; then
  warn ".env.test missing in backend - copying from .env.test.example..."
  if [[ -f "$ENV_TEST_EXAMPLE" ]]; then
    cp "$ENV_TEST_EXAMPLE" "$ENV_TEST_BACKEND"
    log ".env.test created tu template: $ENV_TEST_BACKEND"
  else
    err ".env.test.example missing tai $ENV_TEST_EXAMPLE"
  fi
fi

# Verify tools/test-db-reset.ts
RESET_SCRIPT="$BACKEND_DIR/tools/test-db-reset.ts"
if [[ ! -f "$RESET_SCRIPT" ]]; then
  err "Khong tim thay tools/test-db-reset.ts tai $RESET_SCRIPT"
fi

# Detect Docker postgres
DOCKER_CONTAINER=''
if command -v docker >/dev/null 2>&1; then
  if docker ps --filter "name=qlvb_postgres" --format "{{.Names}}" 2>/dev/null | grep -q 'qlvb_postgres'; then
    DOCKER_CONTAINER='qlvb_postgres'
    log "Detected Docker postgres: $DOCKER_CONTAINER"
  else
    log 'Docker postgres khong detect - dung psql local (CI mode)'
  fi
else
  log 'Docker khong cai dat - dung psql local (CI mode)'
fi

cd "$BACKEND_DIR"
log 'Running npm run test:db:reset...'

START_TS=$(date +%s)
if [[ -n "$DOCKER_CONTAINER" ]]; then
  NODE_ENV=test PG_DOCKER_CONTAINER="$DOCKER_CONTAINER" npm run test:db:reset
else
  NODE_ENV=test npm run test:db:reset
fi
EXIT_CODE=$?
END_TS=$(date +%s)
ELAPSED=$((END_TS - START_TS))

if [[ $EXIT_CODE -eq 0 ]]; then
  log "Test DB setup DONE in ${ELAPSED}s"
  if [[ $ELAPSED -gt 30 ]]; then
    warn "Vuot 30s target (AUTO-02 acceptance) - kiem tra performance"
  fi
else
  err "Test DB setup FAILED with exit code $EXIT_CODE (elapsed: ${ELAPSED}s)"
fi
