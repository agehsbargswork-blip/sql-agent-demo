import pandas as pd
from pg8000 import dbapi

from sql_agent.config import get_settings


def connect_to_database():
    settings = get_settings()

    connection = dbapi.connect(
        host=settings.pg_host,
        port=settings.pg_port,
        database=settings.pg_database,
        user=settings.pg_user,
        password=settings.pg_password,
        ssl_context=True,
        timeout=15,
    )

    # Configure the session before pg8000 starts the query transaction.
    connection.autocommit = True
    cursor = connection.cursor()
    try:
        cursor.execute("SET default_transaction_read_only = on;")
        cursor.execute("SET statement_timeout = 15000;")
    finally:
        cursor.close()
    connection.autocommit = False

    return connection


def load_training_examples():
    connection = connect_to_database()
    cursor = connection.cursor()
    try:
        cursor.execute("SELECT prompt, tags, sql_text FROM training_set;")
        rows = cursor.fetchall()
    finally:
        cursor.close()
        connection.close()

    return pd.DataFrame(
        rows,
        columns=["prompt", "tags", "sql_text"],
    )


def execute_query(sql):
    connection = connect_to_database()
    cursor = connection.cursor()
    try:
        cursor.execute(sql)
        columns = [column[0] for column in cursor.description]
        rows = cursor.fetchall()
    finally:
        cursor.close()
        connection.close()

    return pd.DataFrame(rows, columns=columns)
