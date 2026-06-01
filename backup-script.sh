#!/bin/sh


BACKUP_DIR="/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/dashboard_${TIMESTAMP}.sql.gz"


echo "[$(date)] Starting backup..."
pg_dump -h postgres -U postgres dashboard | gzip > "$BACKUP_FILE"


if [ -s "$BACKUP_FILE" ]; then
    echo "[$(date)] Backup created: $BACKUP_FILE ($(du -h "$BACKUP_FILE" | cut -f1))"
else
    echo "[$(date)] ERROR: Backup failed!"
    rm -f "$BACKUP_FILE"
fi