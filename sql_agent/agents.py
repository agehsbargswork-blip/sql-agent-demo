from openai import OpenAI

from sql_agent.config import get_settings
from sql_agent.prompts import (
    reviewer_dynamic_context,
    reviewer_stable_context,
    writer_dynamic_context,
    writer_stable_context,
)
from sql_agent.schemas import ReviewerResult, WriterResult


PROMPT_CACHE_OPTIONS = {
    "mode": "explicit",
    "ttl": "30m",
}


def stable_developer_message(text):
    return {
        "role": "developer",
        "content": [
            {
                "type": "input_text",
                "text": text,
                "prompt_cache_breakpoint": {
                    "mode": "explicit"
                },
            }
        ],
    }


def create_client():
    settings = get_settings()
    return OpenAI(api_key=settings.openai_api_key)


def call_writer(question, database_guide, examples):
    settings = get_settings()

    response = create_client().responses.parse(
        model=settings.openai_model,
        reasoning={"effort": "low"},
        input=[
            stable_developer_message(
                writer_stable_context(database_guide)
            ),
            {
                "role": "developer",
                "content": writer_dynamic_context(examples),
            },
            {
                "role": "user",
                "content": question,
            },
        ],
        text_format=WriterResult,
        prompt_cache_options=PROMPT_CACHE_OPTIONS,
        max_output_tokens=2000,
    )

    if response.output_parsed is None:
        raise RuntimeError("The SQL writer did not return a result.")

    return response.output_parsed


def call_reviewer(question, proposed_sql, database_guide, examples):
    settings = get_settings()

    response = create_client().responses.parse(
        model=settings.openai_model,
        reasoning={"effort": "low"},
        input=[
            stable_developer_message(
                reviewer_stable_context(database_guide)
            ),
            {
                "role": "user",
                "content": reviewer_dynamic_context(
                    question,
                    proposed_sql,
                    examples,
                ),
            },
        ],
        text_format=ReviewerResult,
        prompt_cache_options=PROMPT_CACHE_OPTIONS,
        max_output_tokens=2000,
    )

    if response.output_parsed is None:
        raise RuntimeError("The SQL reviewer did not return a result.")

    return response.output_parsed
