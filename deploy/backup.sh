#!/bin/bash
# ============================================================
# e-Office — Backup database
# Chạy: sudo bash backup.sh
# Hoặc đặt cron: 0 2 * * * /opt/eoffice/quanlyvanban/deploy/backup.sh
# ============================================================

BACKUP_DIR="/opt/eoffice/backups"
DATE=$(date +%Y%m%d_%H%M)
KEEP_DAYS=7

mkdir -p "$BACKUP_DIR"

# Backup PostgreSQL
echo "[$(date)] Backup PostgreSQL..."
docker exec qlvb_postgres pg_dump -U qlvb_admin -d qlvb_prod \
  --no-owner --no-privileges \
  | gzip > "$BACKUP_DIR/pg_${DATE}.sql.gz"

# Backup MongoDB
echo "[$(date)] Backup MongoDB..."
docker exec qlvb_mongodb mongodump \
  --username qlvb_admin --password 'QlvbMongo@2026!' \
  --authenticationDatabase admin \
  --db qlvb_logs --archive \
  | gzip > "$BACKUP_DIR/mongo_${DATE}.gz"

# Xóa backup cũ
find "$BACKUP_DIR" -name "*.gz" -mtime +$KEEP_DAYS -delete

echo "[$(date)] Backup hoàn thành: $BACKUP_DIR"
ls -lh "$BACKUP_DIR"
