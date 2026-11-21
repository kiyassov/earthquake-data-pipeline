# earthquake-data-pipeline

Учебный пайплайн данных о землетрясениях из API USGS.

Статус: шаг 2, локальное окружение: Airflow 3, S3-хранилище и PostgreSQL для DWH. DAG пока нет.

## Стек

| Компонент | Версия | Зачем |
|---|---|---|
| Apache Airflow | 3.4.0, LocalExecutor | оркестрация |
| Python в образе Airflow | 3.12 | |
| PostgreSQL (метаданные Airflow) | 17.12 | служебная база Airflow |
| RustFS | 1.0.6 | S3-совместимое хранилище для сырых данных (Parquet) |
| PostgreSQL (DWH) | 17.12 | хранилище данных для dbt и Metabase |

Почему RustFS, а не MinIO: open-source MinIO больше не поддерживается,
репозиторий архивирован, а образы `minio/minio` удалены с Docker Hub (2026).
RustFS работает по тому же протоколу S3, поэтому код пайплайна от выбора
хранилища не зависит: меняется только адрес и ключи.

## Запуск локально (Linux)

Нужны Docker Engine и плагин Docker Compose v2, не меньше 4 ГБ RAM для Docker.

Создать `.env` и сгенерировать секреты (повторный запуск безопасен,
заполненные значения не меняются):

```bash
./scripts/init-env.sh
```

Собрать и запустить:

```bash
docker compose up -d --build --wait
```

| Сервис | Адрес | Логин |
|---|---|---|
| Airflow UI | <http://localhost:8080> | `AIRFLOW_ADMIN_USERNAME` / `AIRFLOW_ADMIN_PASSWORD` |
| RustFS консоль | <http://localhost:9001/rustfs/console/> | `S3_ACCESS_KEY` / `S3_SECRET_KEY` |
| RustFS S3 API | `http://localhost:9000` | те же ключи |
| DWH PostgreSQL | `localhost:5433` | `DWH_DB_USER` / `DWH_DB_PASSWORD`, база `DWH_DB_NAME` |

Все порты открыты только на `127.0.0.1`.

Остановить: `docker compose down`. Данные (база Airflow, бакет, DWH) хранятся
в Docker volumes и переживают перезапуск. Удалить вместе с данными:
`docker compose down -v`.

## Структура

```
dags/                  DAG-файлы, монтируются в контейнеры Airflow
scripts/init-env.sh    создаёт .env из шаблона и генерирует секреты
Dockerfile             образ Airflow с зависимостями из requirements.txt
requirements.txt       Python-зависимости DAG с точными версиями
docker-compose.yaml    локальное окружение
.env.example           шаблон переменных окружения, настоящий .env не коммитим
```
