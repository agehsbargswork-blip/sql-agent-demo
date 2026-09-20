import sqlglot
from sqlglot import expressions


BLOCKED_EXPRESSIONS = {
    "ALTER",
    "COMMAND",
    "COPY",
    "CREATE",
    "DELETE",
    "DROP",
    "INSERT",
    "INTO",
    "MERGE",
    "TRANSACTION",
    "TRUNCATE",
    "UPDATE",
}


def validate_read_only(sql):
    statements = sqlglot.parse(sql, read="postgres")

    if len(statements) != 1:
        raise ValueError("The generated SQL must contain exactly one statement.")

    statement = statements[0]

    if not isinstance(statement, expressions.Query):
        raise ValueError("Only read-only SELECT queries are allowed.")

    for expression in statement.walk():
        if expression.__class__.__name__.upper() in BLOCKED_EXPRESSIONS:
            raise ValueError("The generated SQL is not read-only.")

    return sql
