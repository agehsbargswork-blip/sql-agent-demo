from dataclasses import dataclass

import pandas as pd

from sql_agent.agents import call_reviewer, call_writer
from sql_agent.context import load_database_guide
from sql_agent.database import execute_query, load_training_examples
from sql_agent.retrieval import select_examples
from sql_agent.schemas import ReviewerResult, WriterResult
from sql_agent.validation import validate_read_only


@dataclass
class SQLResult:
    question: str
    writer: WriterResult
    reviewer: ReviewerResult
    final_sql: str
    data: pd.DataFrame | None


def ask_sql(question, execute=True, number_of_examples=8):
    database_guide = load_database_guide()
    training_examples = load_training_examples()
    examples = select_examples(
        question,
        training_examples,
        number_of_examples=number_of_examples,
    )

    writer_result = call_writer(
        question,
        database_guide,
        examples,
    )

    reviewer_result = call_reviewer(
        question,
        writer_result.sql,
        database_guide,
        examples,
    )

    if reviewer_result.approved:
        final_sql = writer_result.sql
    elif reviewer_result.corrected_sql:
        final_sql = reviewer_result.corrected_sql
    else:
        raise RuntimeError(
            "The reviewer rejected the query without providing a correction."
        )

    validate_read_only(final_sql)

    data = execute_query(final_sql) if execute else None

    return SQLResult(
        question=question,
        writer=writer_result,
        reviewer=reviewer_result,
        final_sql=final_sql,
        data=data,
    )
