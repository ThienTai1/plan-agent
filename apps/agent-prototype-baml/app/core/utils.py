from datetime import datetime, timezone
from uuid import uuid4


def utc_now() -> datetime:
    return datetime.now(tz=timezone.utc)


def short_id(prefix: str = "id") -> str:
    return f"{prefix}-{uuid4().hex[:8]}"
