import logging
from app.services.embedding_service import EmbeddingService
from datetime import datetime, timezone
from typing import Optional, Dict, Any, List
from uuid import uuid4
from app.agents.tools.supabase_tool import get_supabase_tool

logger = logging.getLogger(__name__)

class EventService:
    def __init__(self):
        self.tool = get_supabase_tool()
        self.embedding_service = EmbeddingService()

    def create_event(self, title: str, start_time: datetime, end_time: Optional[datetime] = None, description: Optional[str] = None, rrule: Optional[str] = None) -> str:
        content_to_embed = f"{title} {description or ''}".strip()
        embedding = self.embedding_service.get_embedding(content_to_embed)

        event_id = str(uuid4())
        event_data = {
            "id": event_id,
            "title": title,
            "start_time": start_time.isoformat(),
            "end_time": end_time.isoformat() if end_time else None,
            "description": description or "Created via Levigo",
            "rrule": rrule,
            "embedding": embedding
        }
        res = self.tool.insert("events", event_data)
        if res["status"] == "success":
            return event_id
        logger.error(f"Failed to create event: {res.get('message')}")
        return ""

    def get_event(self, event_id: str) -> Optional[Dict[str, Any]]:
        res = self.tool.select("events", match_params={"id": event_id})
        if res["status"] == "success" and res["data"]:
            return res["data"][0]
        return None

    def update_event(self, event_id: str, **kwargs) -> bool:
        event = self.get_event(event_id)
        if not event:
            return False
        
        if "title" in kwargs or "description" in kwargs:
            new_title = kwargs.get("title", event.get("title"))
            new_desc = kwargs.get("description", event.get("description"))
            content_to_embed = f"{new_title} {new_desc or ''}".strip()
            kwargs["embedding"] = self.embedding_service.get_embedding(content_to_embed)

        update_data = {}
        for key, value in kwargs.items():
            if isinstance(value, datetime):
                update_data[key] = value.isoformat()
            else:
                update_data[key] = value
        
        res = self.tool.update("events", match_params={"id": event_id}, data=update_data)
        return res["status"] == "success"

    def delete_event(self, event_id: str) -> bool:
        res = self.tool.delete("events", match_params={"id": event_id})
        return res["status"] == "success"

    def search_events(self, query: str, limit: int = 5) -> List[Dict[str, Any]]:
        return self.find_events(title=query, limit=limit)

    def find_events(self, limit: int = 10, **filters) -> List[Dict[str, Any]]:
        query = self.tool.client.table("events").select("*")
        
        if "title" in filters and filters["title"]:
            title_query = filters.pop("title")
            query_embedding = self.embedding_service.get_query_embedding(title_query)
            try:
                res = self.tool.client.rpc("match_events", {
                    "query_embedding": query_embedding,
                    "match_threshold": 0.5,
                    "match_count": limit
                }).execute()
                results = res.data
                for k, v in filters.items():
                    results = [item for item in results if item.get(k) == v]
                return results
            except Exception as e:
                logger.warning(f"RPC match_events failed or not found, falling back to basic search: {e}")
                query = query.ilike("title", f"%{title_query}%")
                
        for key, value in filters.items():
            query = query.eq(key, value)
            
        res = query.limit(limit).execute()
        return res.data if res.data else []
