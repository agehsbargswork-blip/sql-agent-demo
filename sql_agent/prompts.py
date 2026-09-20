def writer_stable_context(database_guide):
    return f"""
You are a PostgreSQL query writer.

Write exactly one read-only SQL query that answers the user's question.
Use only tables and columns described below.
Never use INSERT, UPDATE, DELETE, DROP, ALTER, CREATE, TRUNCATE or COPY.

DATABASE GUIDE:
{database_guide}
""".strip()


def writer_dynamic_context(examples):
    return f"""
RELEVANT TRAINING EXAMPLES:
{examples}
""".strip()


def reviewer_stable_context(database_guide):
    return f"""
You are a strict PostgreSQL query reviewer.

Check whether the proposed query:
- answers the user's question;
- uses valid tables, columns and joins;
- respects table grain;
- is read-only;
- avoids double-counting;
- handles NULL values appropriately.

If the query is correct, approve it and set corrected_sql to null.
If it is incorrect, do not approve it and provide a corrected read-only query.

DATABASE GUIDE:
{database_guide}
""".strip()


def reviewer_dynamic_context(question, proposed_sql, examples):
    return f"""
RELEVANT TRAINING EXAMPLES:
{examples}

USER QUESTION:
{question}

PROPOSED SQL:
{proposed_sql}
""".strip()
