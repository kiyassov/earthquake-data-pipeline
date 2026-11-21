# Образ Airflow для проекта: официальный образ + наши Python-зависимости.
#
# Версии Airflow и Python заданы здесь и больше нигде.
# Чтобы обновить Airflow, меняем AIRFLOW_VERSION и пересобираем образ:
#   docker compose build

ARG AIRFLOW_VERSION=3.4.0
ARG PYTHON_VERSION=3.12

FROM apache/airflow:${AIRFLOW_VERSION}-python${PYTHON_VERSION}

# ARG, объявленный до FROM, внутри этапа сборки не виден: объявляем его ещё раз
# (без значения), чтобы использовать в RUN ниже.
ARG AIRFLOW_VERSION

COPY requirements.txt /requirements.txt

# "apache-airflow==${AIRFLOW_VERSION}" в той же команде запрещает pip
# обновить или откатить Airflow ради зависимостей из requirements.txt.
# --no-cache-dir не оставляет кэш pip в образе, так образ меньше.
RUN pip install --no-cache-dir "apache-airflow==${AIRFLOW_VERSION}" -r /requirements.txt
