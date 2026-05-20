#!/bin/bash

# Путь к init.sql (можно изменить)
INIT_SQL_PATH="./init.sql"

# Если файл лежит в Documents
# INIT_SQL_PATH="/c/Users/user/Documents/init.sql"

echo "🔄 Начинаем восстановление базы данных из init.sql..."

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
echo "✅ Проверка результата..."
docker exec -it dashboard-postgres psql -U postgres -d dashboard -c "\dt"

echo "🎉 Восстановление завершено!"