from types import SimpleNamespace

from sql_agent import database


class FakeCursor:
    def __init__(self):
        self.statements = []
        self.closed = False

    def execute(self, sql):
        self.statements.append(sql)

    def close(self):
        self.closed = True


class FakeConnection:
    def __init__(self):
        self.autocommit = False
        self.cursor_instance = FakeCursor()

    def cursor(self):
        return self.cursor_instance


def test_connection_uses_ssl_and_configures_read_only_session(monkeypatch):
    connection = FakeConnection()
    received = {}

    def fake_connect(**kwargs):
        received.update(kwargs)
        return connection

    monkeypatch.setattr(database.dbapi, "connect", fake_connect)
    monkeypatch.setattr(
        database,
        "get_settings",
        lambda: SimpleNamespace(
            pg_host="db.example.com",
            pg_port=5432,
            pg_database="postgres",
            pg_user="reader",
            pg_password="secret",
        ),
    )

    result = database.connect_to_database()

    assert result is connection
    assert received == {
        "host": "db.example.com",
        "port": 5432,
        "database": "postgres",
        "user": "reader",
        "password": "secret",
        "ssl_context": True,
        "timeout": 15,
    }
    assert connection.cursor_instance.statements == [
        "SET default_transaction_read_only = on;",
        "SET statement_timeout = 15000;",
    ]
    assert connection.cursor_instance.closed
    assert connection.autocommit is False
