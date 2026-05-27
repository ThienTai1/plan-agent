"""Supabase JWT authentication middleware."""
from typing import Optional, Dict, Any
from fastapi import HTTPException, status, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

# We use the shared library for Supabase auth verification
from app.core.supabase_auth import verify_supabase_token
from app.core.supabase_client import get_supabase

# HTTP Bearer token scheme
security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> Dict[str, Any]:
    """
    Extract and verify Supabase JWT token from Authorization header.
    
    Returns:
        User payload dict from token
        
    Raises:
        HTTPException: If token is invalid or missing
    """
    token = credentials.credentials
    user = verify_supabase_token(token)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Fetch profile data (role, limits) from profiles table
    try:
        supabase = get_supabase()
        result = supabase.table("profiles")\
            .select("role", "daily_messages_count", "last_message_at")\
            .eq("id", user["sub"])\
            .single()\
            .execute()
        
        if result.data:
            user["role"] = result.data.get("role", "free")
            user["daily_messages_count"] = result.data.get("daily_messages_count", 0)
            user["last_message_at"] = result.data.get("last_message_at")
        else:
            user["role"] = "free"
            user["daily_messages_count"] = 0
            user["last_message_at"] = None
    except Exception as e:
        print(f"Error fetching user role: {e}")
        user["role"] = "free"  # Fallback to free
        
    return user


async def get_current_user_id(
    user: Dict[str, Any] = Depends(get_current_user)
) -> str:
    """
    Dependency to get just the user ID (sub) from the authenticated user.
    Compatible with previous implementation.
    """
    return user["sub"]


async def get_optional_user_id(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(HTTPBearer(auto_error=False))
) -> Optional[str]:
    """
    Extract user ID from token if present, otherwise return None.
    Useful for endpoints that work with or without authentication.
    """
    if not credentials:
        return None
    
    user = verify_supabase_token(credentials.credentials)
    return user["sub"] if user else None
