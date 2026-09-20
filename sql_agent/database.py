import pandas as pd
import psycopg

from sql_agent.config import get_settings


def connect_to_database():
    settings = get_settings()

    return psycopg.connect(
        host=settings.pg_host,
        port=settings.pg_port,
        dbname=settings.pg_database,
        user=settings.pg_user,
        password=settings.pg_password,
        sslmode="require",
        options="-c default_transaction_read_only=on -c statement_timeout=15000",
    )


def load_training_examples():
    with connect_to_database() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT prompt, tags, sql_text FROM training_set;"
            )
            rows = cursor.fetchall()

    return pd.DataFrame(
        rows,
        columns=["prompt", "tags", "sql_text"],
    )


def execute_query(sql):
    with connect_to_database() as connection:
        with connection.cursor() as cursor:
            cursor.execute(sql)
            columns = [column.name for column in cursor.description]
            rows = cursor.fetchall()

    return pd.DataFrame(rows, columns=columns)
