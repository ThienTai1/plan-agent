import logging
from app.services.embedding_service import EmbeddingService
from datetime import datetime, timezone
from typing import Optional, Dict, Any, List
from uuid import uuid4
from app.agents.tools.supabase_tool import get_supabase_tool

logger = logging.getLogger(__name__)

class TaskService:
    def __init__(self):
        self.tool = get_supabase_tool()
        self.embedding_service = EmbeddingService()

    def create_task(self, title: str, due_date: Optional[datetime] = None, priority: Optional[str] = None, description: Optional[str] = None) -> str:
        content_to_embed = f"{title} {description or ''}".strip()
        embedding = self.embedding_service.get_embedding(content_to_embed)

        task_id = str(uuid4())
        task_data = {
            "id": task_id,
            "title": title,
            "due_date": due_date.isoformat() if due_date else None,
            "priority": priority,
            "description": description or "Created via Levigo",
            "embedding": embedding,
            "is_completed": False
        }
        res = self.tool.insert("tasks", task_data)
        if res["status"] == "success":
            return task_id
        logger.error(f"Failed to create task: {res.get('message')}")
        return ""

    def get_task(self, task_id: str) -> Optional[Dict[str, Any]]:
        res = self.tool.select("tasks", match_params={"id": task_id})
        if res["status"] == "success" and res["data"]:
            return res["data"][0]
        return None

    def update_task(self, task_id: str, **kwargs) -> bool:
        task = self.get_task(task_id)
        if not task:
            return False
        
        # If title or description changes, update embedding
        if "title" in kwargs or "description" in kwargs:
            new_title = kwargs.get("title", task.get("title"))
            new_desc = kwargs.get("description", task.get("description"))
            content_to_embed = f"{new_title} {new_desc or ''}".strip()
            kwargs["embedding"] = self.embedding_service.get_embedding(content_to_embed)

        # Basic attribute update formatting
        update_data = {}
        for key, value in kwargs.items():
            if isinstance(value, datetime):
                update_data[key] = value.isoformat()
            else:
                update_data[key] = value

        res = self.tool.update("tasks", match_params={"id": task_id}, data=update_data)
        return res["status"] == "success"

    def delete_task(self, task_id: str) -> bool:
        res = self.tool.delete("tasks", match_params={"id": task_id})
        return res["status"] == "success"

    def search_tasks(self, query: str, limit: int = 5) -> List[Dict[str, Any]]:
        return self.find_tasks(title=query, limit=limit)

    def find_tasks(self, limit: int = 10, **filters) -> List[Dict[str, Any]]:
        # Without repository's built-in ILIKE and cosine functions,
        # we construct raw Supabase API query using underlying client for advanced queries
        
        query = self.tool.client.table("tasks").select("*")
        
        if "title" in filters and filters["title"]:
            title_query = filters.pop("title")
            query_embedding = self.embedding_service.get_query_embedding(title_query)
            # using RPC for similarity search if it exists, otherwise fallback to simple ilike
            # Assuming `match_tasks` RPC is set up in Supabase:
            try:
                res = self.tool.client.rpc("match_tasks", {
                    "query_embedding": query_embedding,
                    "match_threshold": 0.5, # configurable
                    "match_count": limit
                }).execute()
                # Apply extra filters to the semantic results if needed in-memory
                results = res.data
                for k, v in filters.items():
                    results = [item for item in results if item.get(k) == v]
                return results
            except Exception as e:
                logger.warning(f"RPC match_tasks failed or not found, falling back to basic search: {e}")
                query = query.ilike("title", f"%{title_query}%")
        
        for key, value in filters.items():
            query = query.eq(key, value)
            
        res = query.limit(limit).execute()
        return res.data if res.data else []

    def get_overdue_tasks(self, limit: int = 20) -> List[Dict[str, Any]]:
        now_str = datetime.now(timezone.utc).isoformat()
        res = self.tool.client.table("tasks")\
            .select("*")\
            .lt("due_date", now_str)\
            .eq("is_completed", False)\
            .limit(limit)\
            .execute()
        return res.data if res.data else []
