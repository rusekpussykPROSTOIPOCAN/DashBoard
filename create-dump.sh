#!/bin/bash

INIT_SQL_PATH="./init.sql"

echo "🔄 Начинаем восстановление базы данных из init.sql..."
echo "================================"

# Проверка существования файла
if [ ! -f "$INIT_SQL_PATH" ]; then
    echo "❌ Файл $INIT_SQL_PATH не найден!"
    echo "Скопируйте init.sql в текущую директорию: $(pwd)"
    echo "Или создайте дамп: ./create-dump.sh"
    exit 1
fi

# Проверка, что контейнер запущен
if ! docker ps | grep -q dashboard-postgres; then
    echo "❌ Контейнер dashboard-postgres не запущен!"
    echo "Запустите: docker-compose up -d"
    exit 1
fi

# Показываем что внутри дампа
echo "📋 Таблицы в init.sql:"
grep "CREATE TABLE" "$INIT_SQL_PATH" | while read -r line; do
    TABLE_NAME=$(echo "$line" | sed 's/.*CREATE TABLE public\.\([^ ]*\).*/\1/')
    echo "   📄 ${TABLE_NAME}"
done

echo ""
echo "⚠️  Текущая БД 'dashboard' будет удалена!"
read -p "Продолжить? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Операция отменена"
    exit 0
fi

# 1. Дропаем существующую БД
echo "📦 Удаляем старую базу данных..."
docker exec -it dashboard-postgres psql -U postgres -c "DROP DATABASE IF EXISTS dashboard;"

# 2. Создаем новую БД
echo "✨ Создаем новую базу данных..."
docker exec -it dashboard-postgres psql -U postgres -c "CREATE DATABASE dashboard;"

# 3. Копируем init.sql в контейнер
echo "📋 Копируем init.sql в контейнер..."
docker cp "$INIT_SQL_PATH" dashboard-postgres:/dump.sql

# 4. Восстанавливаем из дампа
echo "🛠️ Восстанавливаем данные..."
docker exec -it dashboard-postgres psql -U postgres -d dashboard -f /dump.sql

# 5. Проверяем результат
echo ""
echo "✅ Проверка результата:"
docker exec -it dashboard-postgres psql -U postgres -d dashboard -c "\dt"

echo ""
echo "🎉 Восстановление завершено!"
echo "================================"