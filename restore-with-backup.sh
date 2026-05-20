#!/bin/bash

# ============================================
# Скрипт восстановления БД из init.sql
# с предварительным бэкапом текущего состояния
# ============================================

# Настройки (можно изменить)
INIT_SQL_PATH="./init.sql"
BACKUP_BEFORE_RESTORE=true  # Делать ли бэкап перед восстановлением

# Цветной вывод
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔄 Процесс восстановления базы данных${NC}"
echo "================================================"

# Проверка существования init.sql
if [ ! -f "$INIT_SQL_PATH" ]; then
    echo -e "${RED}❌ Файл $INIT_SQL_PATH не найден!${NC}"
    echo "Положите init.sql рядом с этим скриптом или укажите путь в переменной INIT_SQL_PATH"
    exit 1
fi

# Проверка, что контейнер запущен
if ! docker ps | grep -q dashboard-postgres; then
    echo -e "${RED}❌ Контейнер dashboard-postgres не запущен!${NC}"
    echo "Запустите: docker-compose up -d"
    exit 1
fi

# Делаем бэкап текущей БД если нужно
if [ "$BACKUP_BEFORE_RESTORE" = true ]; then
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="/backups/pre_restore_${TIMESTAMP}.sql.gz"
    
    echo -e "${YELLOW}💾 Создаем бэкап текущей БД...${NC}"
    docker exec dashboard-postgres-backup /backup-script.sh 2>/dev/null || {
        echo "Создаем бэкап напрямую..."
        docker exec dashboard-postgres pg_dump -U postgres dashboard | gzip > "./backup_pre_restore_${TIMESTAMP}.sql.gz"
    }
    echo -e "${GREEN}✅ Бэкап создан${NC}"
fi

# Подтверждение
echo ""
echo -e "${RED}⚠️  ВНИМАНИЕ! Текущая БД 'dashboard' будет удалена!${NC}"
read -p "Продолжить? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Операция отменена${NC}"
    exit 0
fi

# 1. Дропаем БД
echo -e "${YELLOW}📦 Удаляем старую базу данных...${NC}"
docker exec dashboard-postgres psql -U postgres -c "DROP DATABASE IF EXISTS dashboard;" 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Ошибка при удалении БД${NC}"
    exit 1
fi
echo -e "${GREEN}✅ База данных удалена${NC}"

# 2. Создаем новую БД
echo -e "${YELLOW}✨ Создаем новую базу данных...${NC}"
docker exec dashboard-postgres psql -U postgres -c "CREATE DATABASE dashboard;" 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Ошибка при создании БД${NC}"
    exit 1
fi
echo -e "${GREEN}✅ База данных создана${NC}"

# 3. Копируем init.sql
echo -e "${YELLOW}📋 Копируем init.sql в контейнер...${NC}"
docker cp "$INIT_SQL_PATH" dashboard-postgres:/dump.sql 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Ошибка при копировании файла${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Файл скопирован${NC}"

# 4. Восстанавливаем
echo -e "${YELLOW}🛠️ Восстанавливаем из дампа...${NC}"
docker exec dashboard-postgres psql -U postgres -d dashboard -f /dump.sql 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Ошибка при восстановлении${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Данные восстановлены${NC}"

# 5. Проверяем
echo ""
echo -e "${YELLOW}📊 Проверка результата:${NC}"
docker exec dashboard-postgres psql -U postgres -d dashboard -c "\dt" 2>&1

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}🎉 Восстановление успешно завершено!${NC}"
echo -e "${GREEN}================================================${NC}"