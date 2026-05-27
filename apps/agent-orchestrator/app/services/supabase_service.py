"""
SUPABASE_SERVICE.PY - Service for direct interaction with Supabase Database.
Used to perform CRUD operations (Goal/Task) directly on the Server.
"""
from typing import Any, Dict, List, Optional
from datetime import datetime, timezone
from supabase import create_client, Client
from app.config.settings import settings
from loguru import logger

class SupabaseService:
    def __init__(self):
        if not settings.SUPABASE_URL or not settings.SUPABASE_KEY:
            logger.warning("⚠️ SUPABASE_URL or SUPABASE_KEY not configured. DB operations will fail.")
        
        # Prioritize SERVICE_ROLE_KEY for administrative backend operations (bypassing RLS)
        admin_key = settings.SUPABASE_SERVICE_ROLE_KEY or settings.SUPABASE_KEY
        self.client: Client = create_client(
            settings.SUPABASE_URL,
            admin_key
        )

    async def create_goal(self, user_id: str, data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new goal directly in the database."""
        try:
            # Ensure user_id is present
            data['user_id'] = user_id
            
            logger.info(f"💾 Attempting to insert goal for user {user_id}: {data}")
            result = self.client.table("goals").insert(data).execute()
            
            if not result.data:
                logger.error(f"⚠️ Insertion returned empty data. Status: {getattr(result, 'status_code', 'unknown')}")
                return {}
                
            logger.info(f"✅ Goal created successfully: {result.data[0].get('id')}")
            return result.data[0]
        except Exception as e:
            logger.error(f"❌ SUPABASE ERROR (create_goal): {str(e)}")
            # Log more details if it's a supabase exception
            if hasattr(e, 'message'):
                logger.error(f"Error Message: {e.message}")
            raise

    async def list_goals(self, user_id: str, status: str = "active") -> List[Dict[str, Any]]:
        """Retrieve the list of goals."""
        try:
            query = self.client.table("goals").select("*").eq("user_id", user_id)
            if status != "all":
                query = query.eq("status", status)
            
            result = query.execute()
            return result.data
        except Exception as e:
            logger.error(f"❌ Failed to list goals: {str(e)}")
            return []

    async def update_goal(self, user_id: str, goal_id: str, data: Dict[str, Any]) -> Dict[str, Any]:
        """Update a goal."""
        try:
            result = self.client.table("goals").update(data).eq("id", goal_id).eq("user_id", user_id).execute()
            return result.data[0] if result.data else {}
        except Exception as e:
            logger.error(f"❌ Failed to update goal: {str(e)}")
            raise

    async def delete_goal(self, user_id: str, goal_id: str) -> bool:
        """Delete a goal (may trigger related task deletion depending on DB constraints)."""
        try:
            self.client.table("goals").delete().eq("id", goal_id).eq("user_id", user_id).execute()
            return True
        except Exception as e:
            logger.error(f"❌ Failed to delete goal: {str(e)}")
            return False

    # --- TASK METHODS ---
    
    async def create_task(self, user_id: str, data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new task."""
        try:
            data['user_id'] = user_id
            result = self.client.table("tasks").insert(data).execute()
            return result.data[0] if result.data else {}
        except Exception as e:
            logger.error(f"❌ Failed to create task: {str(e)}")
            raise

    async def list_tasks(self, user_id: str, goal_id: Optional[str] = None, status: Optional[str] = None) -> List[Dict[str, Any]]:
        """List tasks."""
        try:
            query = self.client.table("tasks").select("*").eq("user_id", user_id)
            if goal_id:
                query = query.eq("goal_id", goal_id)
            if status:
                query = query.eq("status", status)
            
            result = query.execute()
            return result.data
        except Exception as e:
            logger.error(f"❌ Failed to list tasks: {str(e)}")
            return []

    async def update_task(self, user_id: str, task_id: str, data: Dict[str, Any]) -> Dict[str, Any]:
        """Update a task."""
        try:
            result = self.client.table("tasks").update(data).eq("id", task_id).eq("user_id", user_id).execute()
            return result.data[0] if result.data else {}
        except Exception as e:
            logger.error(f"❌ Failed to update task: {str(e)}")
            raise

    async def delete_task(self, user_id: str, task_id: str) -> bool:
        """Delete a task."""
        try:
            self.client.table("tasks").delete().eq("id", task_id).eq("user_id", user_id).execute()
            return True
        except Exception as e:
            logger.error(f"❌ Failed to delete task: {str(e)}")
            return False

    # --- CHAT / THREAD METHODS ---

    async def update_thread_title(self, thread_id: str, title: str) -> bool:
        """Update the title of a conversation (thread)."""
        try:
            now = datetime.now(timezone.utc).isoformat()
            self.client.table("threads").update({
                "title": title,
                "updated_at": now
            }).eq("id", thread_id).execute()
            logger.info(f"✅ Thread {thread_id} title updated to: {title}")
            return True
        except Exception as e:
            logger.error(f"❌ Failed to update thread title: {str(e)}")
            return False

    async def get_first_chat_message(self, thread_id: str) -> Optional[str]:
        """Retrieve the content of the first message from the USER in a thread."""
        try:
            logger.info(f"🔍 Fetching first user message for thread: {thread_id}")
            result = self.client.table("messages")\
                .select("content")\
                .eq("thread_id", thread_id)\
                .eq("role", "user")\
                .order("created_at", desc=False)\
                .limit(1)\
                .execute()
            
            if result.data and len(result.data) > 0:
                content = result.data[0]["content"]
                logger.info(f"✅ Found first message: {content[:20]}...")
                return content
            
            logger.warning(f"⚠️ No user message found for thread: {thread_id}")
            return None
        except Exception as e:
            logger.error(f"❌ Failed to get first message: {str(e)}")
            return None

    # --- ANALYTICS METHODS ---

    async def get_analytics_data(self, user_id: str) -> Dict[str, Any]:
        """Retrieve aggregated statistical data to support analysis/review."""
        try:
            from datetime import datetime, timedelta
            now = datetime.now()
            seven_days_ago = (now - timedelta(days=7)).isoformat()

            # 1. Goals Stats
            goals_res = self.client.table("goals").select("status").eq("user_id", user_id).execute()
            goals = goals_res.data
            active_goals = len([g for g in goals if g["status"] == "active"])
            completed_goals = len([g for g in goals if g["status"] == "completed"])

            # 2. Tasks Stats
            tasks_res = self.client.table("tasks").select("is_completed, created_at, updated_at").eq("user_id", user_id).execute()
            tasks = tasks_res.data
            completed_tasks = [t for t in tasks if t.get("is_completed") is True]
            pending_tasks = [t for t in tasks if not t.get("is_completed")]

            # 3. Tasks completed in last 7 days
            recent_completed = [
                t for t in completed_tasks 
                if t.get("updated_at") and t["updated_at"] >= seven_days_ago
            ]
            
            # 4. Completion Rate
            completion_rate = 0.0
            if len(tasks) > 0:
                completion_rate = round(len(completed_tasks) / len(tasks), 2)

            return {
                "goals": {
                    "active": active_goals,
                    "completed": completed_goals,
                    "total": len(goals)
                },
                "tasks": {
                    "pending": len(pending_tasks),
                    "completed_total": len(completed_tasks),
                    "completed_last_7_days": len(recent_completed),
                    "total": len(tasks)
                },
                "completion_rate": completion_rate,
                "strategy_score": int(completion_rate * 100), # Simple score for now
                "summary": f"User has {active_goals} active goals and {len(pending_tasks)} pending tasks. {len(recent_completed)} tasks were completed in the last 7 days."
            }
        except Exception as e:
            logger.error(f"❌ Failed to get analytics: {str(e)}")
            return {"error": str(e)}

    async def get_category_distribution(self, user_id: str) -> List[Dict[str, Any]]:
        """Aggregate goals by category/label for the focus chart."""
        try:
            res = self.client.table("goals").select("label").eq("user_id", user_id).execute()
            data = res.data
            
            counts = {}
            for g in data:
                label = g.get("label") or "Uncategorized"
                counts[label] = counts.get(label, 0) + 1
            
            # Format for the frontend pie chart
            distribution = []
            for label, count in counts.items():
                distribution.append({
                    "label": label,
                    "count": count,
                    "percentage": round(count / len(data) * 100, 1) if data else 0
                })
            
            return distribution
        except Exception as e:
            logger.error(f"❌ Failed to get category distribution: {str(e)}")
            return []

    async def get_productivity_trend(self, user_id: str, days: int = 14) -> List[Dict[str, Any]]:
        """Fetch daily completion counts for chart visualization."""
        try:
            from datetime import datetime, timedelta
            start_date = (datetime.now() - timedelta(days=days)).date()
            
            # Fetch completed tasks in the period
            res = self.client.table("tasks")\
                .select("updated_at")\
                .eq("user_id", user_id)\
                .eq("is_completed", True)\
                .gte("updated_at", start_date.isoformat())\
                .execute()
            
            # Aggregate by date
            counts = {}
            for t in res.data:
                dt_str = t["updated_at"].split("T")[0]
                counts[dt_str] = counts.get(dt_str, 0) + 1
            
            # Fill missing dates with 0
            trend = []
            for i in range(days + 1):
                d = (start_date + timedelta(days=i)).isoformat()
                trend.append({"x": d, "y": float(counts.get(d, 0))})
                
            return trend
        except Exception as e:
            logger.error(f"❌ Failed to get productivity trend: {str(e)}")
            return []

    async def get_goal_health_metrics(self, user_id: str, goal_id: str) -> Dict[str, Any]:
        """Deep dive into a specific goal's task status."""
        try:
            from datetime import datetime
            now_iso = datetime.now().isoformat()
            
            res = self.client.table("tasks")\
                .select("*")\
                .eq("goal_id", goal_id)\
                .eq("user_id", user_id)\
                .execute()
            
            tasks = res.data
            total = len(tasks)
            if total == 0:
                return {"error": "No tasks found for this goal"}
            
            completed = [t for t in tasks if t.get("is_completed")]
            overdue = [
                t for t in tasks 
                if not t.get("is_completed")
                and t.get("due_date") and t["due_date"] < now_iso
            ]
            
            return {
                "total": total,
                "completed": len(completed),
                "overdue": len(overdue),
                "progress_pct": round(len(completed) / total, 2),
                "status": "at_risk" if len(overdue) > 0 else "on_track"
            }
        except Exception as e:
            logger.error(f"❌ Failed to get goal health: {str(e)}")
            return {"error": str(e)}

# Global instance
supabase_service = SupabaseService()
