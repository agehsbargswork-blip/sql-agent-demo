from pydantic import BaseModel


class WriterResult(BaseModel):
    sql: str
    explanation: str
    assumptions: list[str]


class ReviewerResult(BaseModel):
    approved: bool
    issues: list[str]
    corrected_sql: str | None
