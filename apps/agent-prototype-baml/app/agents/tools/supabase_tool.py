import logging
from typing import Dict, Any, List, Optional
from app.core.supabase_client import get_supabase

logger = logging.getLogger(__name__)

class SupabaseCRUDTool:
    """
    A utility class to perform generic CRUD operations on Supabase tables.
    """
    
    def __init__(self):
        self.client = get_supabase()
        
    def insert(self, table: str, data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Insert a new record into a specified table.
        """
        try:
            res = self.client.table(table).insert(data).execute()
            if res.data:
                return {"status": "success", "data": res.data[0]}
            return {"status": "error", "message": "No data returned on insert."}
        except Exception as e:
            logger.error(f"Error inserting into {table}: {e}")
            return {"status": "error", "message": str(e)}

    def select(self, table: str, match_params: Dict[str, Any] = None, search_params: Dict[str, Any] = None, limit: int = 50) -> Dict[str, Any]:
        """
        Select records from a table matching the optional parameters.
        - match_params: dictionary of exact match (eq)
        - search_params: dictionary of partial match (ilike)
        """
        try:
            query = self.client.table(table).select("*")
            if match_params:
                for key, value in match_params.items():
                    query = query.eq(key, value)
            
            if search_params:
                for key, value in search_params.items():
                    query = query.ilike(key, f"%{value}%")
            
            res = query.limit(limit).execute()
            return {"status": "success", "data": res.data}
        except Exception as e:
            logger.error(f"Error selecting from {table}: {e}")
            return {"status": "error", "message": str(e)}

    def update(self, table: str, match_params: Dict[str, Any], data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Update records in a table matching the parameters with new data.
        """
        if not match_params:
            return {"status": "error", "message": "match_params are required for update to prevent bulk updates."}
            
        try:
            query = self.client.table(table).update(data)
            for key, value in match_params.items():
                query = query.eq(key, value)
                
            res = query.execute()
            if res.data:
                 return {"status": "success", "data": res.data}
            return {"status": "success", "message": "No records updated. Match params might not match any existing record.", "data": []}
        except Exception as e:
            logger.error(f"Error updating {table}: {e}")
            return {"status": "error", "message": str(e)}

    def delete(self, table: str, match_params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Delete records from a table matching the parameters.
        """
        if not match_params:
            return {"status": "error", "message": "match_params are required for delete to prevent bulk deletion."}
            
        try:
            query = self.client.table(table).delete()
            for key, value in match_params.items():
                query = query.eq(key, value)
                
            res = query.execute()
            if res.data:
                 return {"status": "success", "data": res.data}
            return {"status": "success", "message": "No records deleted. Match params might not match any existing record.", "data": []}
        except Exception as e:
            logger.error(f"Error deleting from {table}: {e}")
            return {"status": "error", "message": str(e)}

# For easy access without instantiating
default_supabase_tool = None

def get_supabase_tool() -> SupabaseCRUDTool:
    global default_supabase_tool
    if default_supabase_tool is None:
        default_supabase_tool = SupabaseCRUDTool()
    return default_supabase_tool
