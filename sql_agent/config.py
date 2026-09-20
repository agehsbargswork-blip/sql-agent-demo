import os
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path

from dotenv import load_dotenv


PROJECT_ROOT = Path(__file__).resolve().parent.parent
ENV_FILE = PROJECT_ROOT / ".env"
DATABASE_GUIDE_FILE = PROJECT_ROOT / "DATABASE_GUIDE.md"


@dataclass(frozen=True)
class Settings:
    openai_api_key: str
    openai_model: str
    pg_host: str
    pg_port: int
    pg_database: str
    pg_user: str
    pg_password: str


@lru_cache
def get_settings():
    if ENV_FILE.exists():
        load_dotenv(ENV_FILE)

    required_names = [
        "OPENAI_API_KEY",
        "PGHOST",
        "PGPORT",
        "PGDATABASE",
        "PGUSER",
        "PGPASSWORD",
    ]

    missing = [name for name in required_names if not os.getenv(name)]

    if missing:
        raise RuntimeError(
            f"Missing settings: {', '.join(missing)}. "
            f"Add them to {ENV_FILE}."
        )

    return Settings(
        openai_api_key=os.environ["OPENAI_API_KEY"],
        openai_model=os.getenv("OPENAI_MODEL", "gpt-5.6-terra"),
        pg_host=os.environ["PGHOST"],
        pg_port=int(os.environ["PGPORT"]),
        pg_database=os.environ["PGDATABASE"],
        pg_user=os.environ["PGUSER"],
        pg_password=os.environ["PGPASSWORD"],
    )
