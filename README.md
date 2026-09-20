# SQL Agent Demo

A small educational project showing how two AI agents can generate and review
PostgreSQL queries against synthetic mobile-app data.

## Planned workflow

1. A user asks a question in natural language.
2. A SQL writer agent proposes a query.
3. A SQL reviewer agent checks the query.
4. An approved query runs against a read-only Supabase PostgreSQL connection.
5. The notebook displays the query, review and result.

## Repository contents

- `create_tables/` — SQL schema, fact-table SQL and R data-generation scripts.
- `DATABASE_GUIDE.md` — table relationships and querying instructions for LLMs.
- `training/create_training_set.R` — generates 115 prompt-to-SQL training examples.
- `sample_data.sql` — optional small SQL seed data.
- `sql_agent_demo.ipynb` — interactive agent demonstration.
- `requirements.txt` — Python dependencies.
- `.env.example` — required environment-variable names without secrets.

## Security

Never commit `.env`, API keys, database passwords or private data.
