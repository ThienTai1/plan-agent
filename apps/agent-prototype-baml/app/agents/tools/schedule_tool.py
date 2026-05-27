import json
from datetime import datetime
from typing import Optional, List, Dict, Any
from uuid import uuid4
from app.agents.tools.supabase_tool import get_supabase_tool

def search_items(keyword: str, item_type: Optional[str] = None) -> List[Dict[str, Any]]:
    results = []
    tool = get_supabase_tool()
    
    if item_type is None or item_type.lower() == "task":
        res = tool.client.table("tasks")\
            .select("id, type, title, description, status, due_date")\
            .or_(f"title.ilike.%{keyword}%,description.ilike.%{keyword}%")\
            .execute()
        if res.data:
            for t in res.data:
                results.append({
                    "id": t.get("id"),
                    "type": "task",
                    "title": t.get("title"),
                    "description": t.get("description"),
                    "status": t.get("status"),
                    "due_date": t.get("due_date")
                })

    if item_type is None or item_type.lower() == "event":
        res = tool.client.table("events")\
            .select("id, title, description, start_time, end_time, location")\
            .or_(f"title.ilike.%{keyword}%,description.ilike.%{keyword}%")\
            .execute()
        if res.data:
            for e in res.data:
                results.append({
                    "id": e.get("id"),
                    "type": "event",
                    "title": e.get("title"),
                    "description": e.get("description"),
                    "start_time": e.get("start_time"),
                    "end_time": e.get("end_time"),
                    "location": e.get("location")
                })
    return results

def check_availability(start_time: str, end_time: str) -> Dict[str, Any]:
    tool = get_supabase_tool()
    
    res = tool.client.table("events")\
        .select("id, title, start_time, end_time")\
        .lt("start_time", end_time)\
        .gt("end_time", start_time)\
        .execute()
        
    conflicts = res.data if res.data else []
    
    if not conflicts:
        return {"available": True}
    
    return {
        "available": False,
        "conflicts": conflicts
    }

def update_item(id: str, updates: dict) -> Dict[str, Any]:
    tool = get_supabase_tool()
    
    # Try finding in tasks first
    task_res = tool.select("tasks", match_params={"id": id})
    if task_res["status"] == "success" and task_res["data"]:
        formatted_updates = {}
        if "title" in updates: formatted_updates["title"] = updates["title"]
        if "description" in updates: formatted_updates["description"] = updates["description"]
        if "status" in updates: formatted_updates["status"] = updates["status"]
        if "due_date" in updates:
            dt = datetime.fromisoformat(updates["due_date"].replace("Z", "+00:00"))
            formatted_updates["due_date"] = dt.isoformat()
        if "priority" in updates: formatted_updates["priority"] = updates["priority"]
        
        tool.update("tasks", match_params={"id": id}, data=formatted_updates)
        return {"success": True, "type": "task", "id": id}
    
    # Try finding in events
    event_res = tool.select("events", match_params={"id": id})
    if event_res["status"] == "success" and event_res["data"]:
        formatted_updates = {}
        if "title" in updates: formatted_updates["title"] = updates["title"]
        if "description" in updates: formatted_updates["description"] = updates["description"]
        if "start_time" in updates:
            dt = datetime.fromisoformat(updates["start_time"].replace("Z", "+00:00"))
            formatted_updates["start_time"] = dt.isoformat()
        if "end_time" in updates:
            dt = datetime.fromisoformat(updates["end_time"].replace("Z", "+00:00"))
            formatted_updates["end_time"] = dt.isoformat()
        if "location" in updates: formatted_updates["location"] = updates["location"]
        
        tool.update("events", match_params={"id": id}, data=formatted_updates)
        return {"success": True, "type": "event", "id": id}
        
    return {"success": False, "error": f"Item with id {id} not found"}

def delete_item(id: str) -> Dict[str, Any]:
    tool = get_supabase_tool()
    
    res = tool.delete("tasks", match_params={"id": id})
    if res["status"] == "success" and res.get("data"):
        return {"success": True, "type": "task", "id": id}
        
    res = tool.delete("events", match_params={"id": id})
    if res["status"] == "success" and res.get("data"):
        return {"success": True, "type": "event", "id": id}
        
    return {"success": False, "error": f"Item with id {id} not found"}

def create_item(data: dict) -> Dict[str, Any]:
    tool = get_supabase_tool()
    item_type = data.get("type", "task").lower()
    item_id = str(uuid4())
    
    if item_type == "task":
        due_date = None
        if data.get("due_date"):
            due_date = datetime.fromisoformat(data["due_date"].replace("Z", "+00:00")).isoformat()
        
        new_task = {
            "id": item_id,
            "title": data.get("title", "New Task"),
            "description": data.get("description"),
            "due_date": due_date,
            "status": data.get("status", "PENDING"),
            "priority": data.get("priority")
        }
        res = tool.insert("tasks", new_task)
        if res["status"] == "success":
            return {"success": True, "type": "task", "id": item_id}
        
    elif item_type == "event":
        start_time = datetime.fromisoformat(data["start_time"].replace("Z", "+00:00")).isoformat()
        end_time = datetime.fromisoformat(data["end_time"].replace("Z", "+00:00")).isoformat()
        
        new_event = {
            "id": item_id,
            "title": data.get("title", "New Event"),
            "description": data.get("description"),
            "start_time": start_time,
            "end_time": end_time,
            "location": data.get("location")
        }
        res = tool.insert("events", new_event)
        if res["status"] == "success":
            return {"success": True, "type": "event", "id": item_id}
            
    return {"success": False, "error": f"Unsupported item type or insert failed: {item_type}"}

if __name__ == "__main__":
    pass