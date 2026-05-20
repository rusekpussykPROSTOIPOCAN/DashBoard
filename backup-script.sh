#!/bin/sh

# Настройки
BACKUP_DIR="/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/dashboard_$TIMESTAMP.sql.gz"

# Создание бэкапа
echo "Starting backup at $(date)"
pg_dump -h $PGHOST -p $PGPORT -U $PGUSER -d $PGDATABASE | gzip > "$BACKUP_FILE"

# Проверка успешности
if [ $? -eq 0 ]; then
    echo "Backup completed: $BACKUP_FILE"
    # Создаем симлинк на последний бэкап
    ln -sf "$BACKUP_FILE" "$BACKUP_DIR/latest.sql.gz"
else
    echo "Backup failed!"
fi