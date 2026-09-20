from sql_agent.config import DATABASE_GUIDE_FILE


def load_database_guide():
    if not DATABASE_GUIDE_FILE.exists():
        raise FileNotFoundError(
            f"Database guide not found: {DATABASE_GUIDE_FILE}"
        )

    return DATABASE_GUIDE_FILE.read_text(encoding="utf-8")
