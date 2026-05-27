from supabase import create_client, Client
from typing import Optional
import os

class SupabaseClient:
    """Singleton Supabase client for backend services."""
    
    _instance: Optional[Client] = None
    
    @classmethod
    def get_client(cls) -> Client:
        """Get or create Supabase client instance."""
        if cls._instance is None:
            url = os.getenv("SUPABASE_URL")
            key = os.getenv("SUPABASE_SERVICE_ROLE_KEY") or os.getenv("SUPABASE_KEY")
            
            if not url or not key:
                raise ValueError("SUPABASE_URL and one of SUPABASE_SERVICE_ROLE_KEY or SUPABASE_KEY must be set in environment variables")
            
            cls._instance = create_client(url, key)
        
        return cls._instance

# Convenience function
def get_supabase() -> Client:
    return SupabaseClient.get_client()
