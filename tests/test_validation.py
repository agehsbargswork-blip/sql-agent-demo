import pytest

from sql_agent.validation import validate_read_only


def test_accepts_select_query():
    sql = "SELECT platform_name FROM dim_platform;"
    assert validate_read_only(sql) == sql


def test_accepts_common_table_expression():
    sql = "WITH users AS (SELECT user_id FROM dim_users) SELECT * FROM users;"
    assert validate_read_only(sql) == sql


@pytest.mark.parametrize(
    "sql",
    [
        "DELETE FROM events;",
        "UPDATE dim_users SET is_test_user = TRUE;",
        "DROP TABLE events;",
        "SELECT * INTO copied_events FROM events;",
        "SELECT * FROM events; DELETE FROM events;",
    ],
)
def test_rejects_non_read_only_sql(sql):
    with pytest.raises(ValueError):
        validate_read_only(sql)
