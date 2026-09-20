import pandas as pd

from sql_agent import pipeline
from sql_agent.schemas import ReviewerResult, WriterResult


def test_ask_sql_runs_the_complete_pipeline(monkeypatch):
    expected_data = pd.DataFrame({"daily_active_users": [12]})

    monkeypatch.setattr(
        pipeline,
        "load_database_guide",
        lambda: "database guide",
    )
    monkeypatch.setattr(
        pipeline,
        "load_training_examples",
        lambda: pd.DataFrame(
            {
                "prompt": ["Show DAU."],
                "tags": ["select"],
                "sql_text": ["SELECT daily_active_users FROM fact_daily_activity;"],
            }
        ),
    )
    monkeypatch.setattr(
        pipeline,
        "select_examples",
        lambda *args, **kwargs: "selected examples",
    )
    monkeypatch.setattr(
        pipeline,
        "call_writer",
        lambda *args: WriterResult(
            sql="SELECT daily_active_users FROM fact_daily_activity;",
            explanation="Read the daily fact table.",
            assumptions=[],
        ),
    )
    monkeypatch.setattr(
        pipeline,
        "call_reviewer",
        lambda *args: ReviewerResult(
            approved=True,
            issues=[],
            corrected_sql=None,
        ),
    )
    monkeypatch.setattr(
        pipeline,
        "execute_query",
        lambda sql: expected_data,
    )

    result = pipeline.ask_sql("Show DAU.")

    assert result.final_sql == (
        "SELECT daily_active_users FROM fact_daily_activity;"
    )
    assert result.data.equals(expected_data)
