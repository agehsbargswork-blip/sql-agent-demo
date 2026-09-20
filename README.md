# SQL Agent Demo

A small educational project in which one AI agent writes PostgreSQL and a
second agent reviews it before the query runs against a read-only Supabase
connection.

## One-time local setup

Clone the repository, create the local credentials file and install the
package in editable mode:

```cmd
copy .env.example .env
python -m pip install -e .
```

Open `.env` and replace the placeholders with the OpenAI and Supabase
credentials. The real `.env` remains on the local computer and is ignored by
Git. A later `git pull` does not remove or replace it.

## Use from Jupyter

After the one-time installation, a notebook using the same Python environment
can run from any folder:

```python
from sql_agent import ask_sql

result = ask_sql("Show daily revenue by platform for non-test users.")

print(result.final_sql)
display(result.data)
```

`ask_sql()` automatically:

1. Loads `DATABASE_GUIDE.md`.
2. Reads the training examples from the Supabase `training_set` table.
3. Selects the eight most relevant examples.
4. Calls the SQL Writer and SQL Reviewer.
5. Validates that the final SQL is one read-only query.
6. Executes it through a read-only database connection.

Use `ask_sql(question, execute=False)` to generate and review SQL without
executing it.

## Repository contents

- `sql_agent/` — importable Python library.
- `sql_agent_demo.ipynb` — minimal notebook example.
- `create_tables/` — SQL schema, fact-table SQL and R data-generation scripts.
- `DATABASE_GUIDE.md` — table relationships and querying instructions for LLMs.
- `training/create_training_set.R` — creates 115 prompt-to-SQL examples.
- `pyproject.toml` — package definition and runtime dependencies.
- `.env.example` — credentials template without secrets.

## Security

Never commit `.env`, API keys, database passwords or private data.
