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
    assert result.error is None


def test_ask_sql_returns_reviewer_rejection_without_executing(monkeypatch):
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
                "prompt": ["Show mission users."],
                "tags": ["missions"],
                "sql_text": ["SELECT user_id FROM missions;"],
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
            sql="SELECT user_id FROM missions;",
            explanation="Count mission users.",
            assumptions=[],
        ),
    )
    monkeypatch.setattr(
        pipeline,
        "call_reviewer",
        lambda *args: ReviewerResult(
            approved=False,
            issues=["The meaning of mission engagement is unclear."],
            corrected_sql=None,
        ),
    )

    def fail_if_executed(sql):
        raise AssertionError("Rejected SQL must not be executed.")

    monkeypatch.setattr(pipeline, "execute_query", fail_if_executed)

    question = "Show many users engage with missions per day"
    result = pipeline.ask_sql(question)

    assert result.question == question
    assert result.final_sql is None
    assert result.data is None
    assert question in result.error
    assert "mission engagement is unclear" in result.error
