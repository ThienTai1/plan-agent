"""Client used to talk to the calendar-service."""
from loguru import logger

import httpx
from app.core.config import get_settings


class CalendarService:
    def __init__(self) -> None:
        self.settings = get_settings()

    async def list_events(self, limit: int = 3) -> list[dict[str, str]]:
        logger.debug("Listing events from calendar service", extra={"limit": limit})
        # TODO: replace with real HTTP call once the calendar service is online.
        async with httpx.AsyncClient() as client:  # pragma: no cover - placeholder
            # Example of what the call will look like (not executed without a backend)
            try:
                await client.head("https://example.com")
            except httpx.HTTPError:
                pass
        return [
            {"title": "Team sync", "start": "2024-01-01T10:00:00Z"},
            {"title": "Demo prep", "start": "2024-01-02T08:00:00Z"},
        ][:limit]

