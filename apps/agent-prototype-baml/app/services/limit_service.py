from datetime import datetime, timezone
from typing import Dict, Any
from app.core.supabase_client import get_supabase
from loguru import logger

def is_same_day(dt1_str: str, dt2: datetime) -> bool:
    """Check if two datetimes are on the same day (UTC)."""
    if not dt1_str:
        return False
    try:
        dt1 = datetime.fromisoformat(dt1_str.replace("Z", "+00:00"))
        return dt1.year == dt2.year and dt1.month == dt2.month and dt1.day == dt2.day
    except Exception as e:
        logger.error(f"Error parsing date: {e}")
        return False

def is_same_month(dt1_str: str, dt2: datetime) -> bool:
    """Check if two datetimes are in the same month (UTC)."""
    if not dt1_str:
        return False
    try:
        dt1 = datetime.fromisoformat(dt1_str.replace("Z", "+00:00"))
        return dt1.year == dt2.year and dt1.month == dt2.month
    except Exception as e:
        logger.error(f"Error parsing date: {e}")
        return False

async def check_and_update_limit(user_id: str) -> bool:
    """
    Checks if the user has reached their daily chat limit.
    Fetches the latest data from the database.
    Returns True if allowed, False if limit reached.
    """
    supabase = get_supabase()
    
    try:
        # 1. Fetch current profile state
        result = supabase.table("profiles").select(
            "role, daily_messages_count, last_message_at, ai_credits, monthly_messages_count, last_monthly_refill"
        ).eq("id", user_id).single().execute()
        
        if not result.data:
            return True
            
        data = result.data
        role = data.get("role", "free")
        now = datetime.now(timezone.utc)
        
        # ─── 2. Handle Pro Users (500/month) ───
        if role == "pro":
            monthly_count = data.get("monthly_messages_count", 0) or 0
            last_monthly = data.get("last_monthly_refill")
            
            # Reset monthly counter if needed
            if not last_monthly or not is_same_month(last_monthly, now):
                supabase.table("profiles").update({
                    "monthly_messages_count": 1,
                    "last_monthly_refill": now.isoformat()
                }).eq("id", user_id).execute()
                return True
                
            if monthly_count >= 500:
                logger.warning(f"Pro user {user_id} reached monthly limit of 500 messages.")
                return False
                
            supabase.table("profiles").update({
                "monthly_messages_count": monthly_count + 1
            }).eq("id", user_id).execute()
            return True

        # ─── 3. Handle Free Users (Initial Gift & 5/day) ───
        ai_credits = data.get("ai_credits")
        if ai_credits is None:
            ai_credits = 20 # Fallback for migration
            
        daily_count = data.get("daily_messages_count", 0) or 0
        last_at = data.get("last_message_at")

        # A. Priority 1: Use Initial Gift (20 messages)
        if ai_credits > 0:
            supabase.table("profiles").update({
                "ai_credits": ai_credits - 1,
                "last_message_at": now.isoformat()
            }).eq("id", user_id).execute()
            return True

        # B. Priority 2: Use Daily Free Quota (5 messages)
        # Reset counter if it's a new day
        if not last_at or not is_same_day(last_at, now):
            supabase.table("profiles").update({
                "daily_messages_count": 1,
                "last_message_at": now.isoformat()
            }).eq("id", user_id).execute()
            return True

        if daily_count >= 5:
            logger.warning(f"Free user {user_id} reached daily limit of 5 messages.")
            return False

        # Increment daily counter
        supabase.table("profiles").update({
            "daily_messages_count": daily_count + 1,
            "last_message_at": now.isoformat()
        }).eq("id", user_id).execute()
        return True
        
    except Exception as e:
        logger.error(f"Error checking rate limit for user {user_id}: {e}")
        return True # Fallback to allow on internal errors

async def get_quota_status(user_id: str) -> Dict[str, Any]:
    """
    Returns the complete quota status for a user.
    """
    supabase = get_supabase()
    
    try:
        # We select with a try/except specifically for columns that might be missing during migration
        result = supabase.table("profiles").select(
            "role, daily_messages_count, last_message_at, ai_credits, monthly_messages_count, last_monthly_refill"
        ).eq("id", user_id).single().execute()
        
        if not result.data:
            return {
                "role": "free",
                "is_pro": False,
                "ai_credits": 20,
                "daily_count": 0,
                "daily_limit": 5,
                "monthly_count": 0,
                "monthly_limit": 500
            }
            
        data = result.data
        role = data.get("role", "free")
        now = datetime.now(timezone.utc)
        
        ai_credits = data.get("ai_credits")
        if ai_credits is None: # Column missing or row never updated
             ai_credits = 20
             
        daily_count = data.get("daily_messages_count", 0) or 0
        last_at = data.get("last_message_at")
        monthly_count = data.get("monthly_messages_count", 0) or 0
        last_monthly = data.get("last_monthly_refill")

        if last_at and not is_same_day(last_at, now):
            daily_count = 0
            
        if last_monthly and not is_same_month(last_monthly, now):
            monthly_count = 0

        return {
            "role": role,
            "is_pro": role == "pro",
            "ai_credits": ai_credits,
            "daily_count": daily_count,
            "daily_limit": 5,
            "monthly_count": monthly_count,
            "monthly_limit": 500
        }
    except Exception as e:
        logger.error(f"Error fetching quota status for user {user_id}: {e}")
        # If we can't fetch, we might be missing columns. Return safe defaults.
        return {
                "role": "free",
                "is_pro": False,
                "ai_credits": 20, # Default to 20 to be friendly during migration issues
                "daily_count": 0,
                "daily_limit": 5,
                "monthly_count": 0,
                "monthly_limit": 500
            }
