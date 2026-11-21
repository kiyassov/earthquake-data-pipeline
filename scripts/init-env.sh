#!/usr/bin/env bash
# Создаёт или дополняет .env по шаблону .env.example и генерирует пустые секреты.
#
# Запуск из корня проекта: ./scripts/init-env.sh
#
# Скрипт безопасно запускать повторно: уже заполненные значения он не меняет.
# Он только добавляет переменные, которые появились в .env.example,
# и заполняет те, у которых пустое значение.

set -euo pipefail

cd "$(dirname "$0")/.."

ENV_FILE=.env
EXAMPLE_FILE=.env.example

# 1. Нет .env: копируем шаблон целиком.
if [[ ! -f "$ENV_FILE" ]]; then
  cp "$EXAMPLE_FILE" "$ENV_FILE"
  echo "Created $ENV_FILE from $EXAMPLE_FILE"
fi

# 2. Дописываем переменные, которые есть в шаблоне, но отсутствуют в .env.
# Если файл не заканчивается переводом строки, сначала добавляем его,
# иначе новая переменная приклеится к последней строке.
if [[ -s "$ENV_FILE" && -n "$(tail -c 1 "$ENV_FILE")" ]]; then
  echo >> "$ENV_FILE"
fi
while IFS= read -r line; do
  [[ "$line" =~ ^([A-Z0-9_]+)= ]] || continue
  name="${BASH_REMATCH[1]}"
  if ! grep -q "^${name}=" "$ENV_FILE"; then
    echo "$line" >> "$ENV_FILE"
    echo "Added $name"
  fi
done < "$EXAMPLE_FILE"

# 3. Заполняем пустую переменную, если её значение в .env пустое.
fill_if_empty() {
  local name="$1" value="$2"
  if grep -q "^${name}=$" "$ENV_FILE"; then
    sed -i "s|^${name}=$|${name}=${value}|" "$ENV_FILE"
    echo "Generated $name"
  fi
}

fill_if_empty AIRFLOW_UID            "$(id -u)"
fill_if_empty AIRFLOW_DB_PASSWORD    "$(openssl rand -hex 16)"
fill_if_empty AIRFLOW_FERNET_KEY     "$(openssl rand -base64 32 | tr '+/' '-_')"
fill_if_empty AIRFLOW_JWT_SECRET     "$(openssl rand -hex 32)"
fill_if_empty AIRFLOW_API_SECRET_KEY "$(openssl rand -hex 32)"
fill_if_empty AIRFLOW_ADMIN_PASSWORD "$(openssl rand -hex 8)"
fill_if_empty S3_ACCESS_KEY          "$(openssl rand -hex 10)"
fill_if_empty S3_SECRET_KEY          "$(openssl rand -hex 20)"
fill_if_empty DWH_DB_PASSWORD        "$(openssl rand -hex 16)"

# 4. Проверяем, что пустых значений не осталось.
if grep -qE '^[A-Z0-9_]+=$' "$ENV_FILE"; then
  echo "Still empty in $ENV_FILE, fill them manually:" >&2
  grep -E '^[A-Z0-9_]+=$' "$ENV_FILE" >&2
  exit 1
fi

echo "$ENV_FILE is ready"
