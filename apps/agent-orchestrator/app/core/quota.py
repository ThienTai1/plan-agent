"""
QUOTA.PY - User message limit management.
Simplified version: Only supports 'ai_credits' (one-time trial messages) and Pro status (unlimited).
No more daily message resets.
"""
from fastapi import HTTPException
from loguru import logger
from datetime import datetime, timezone
from app.core.db import db_manager

async def is_user_pro(user_id: str) -> bool:
    """
    Check if a user has Pro status without deducting credits.
    """
    if not db_manager.pool:
        return False

    try:
        async with db_manager.pool.connection() as conn:
            async with conn.cursor() as cur:
                await cur.execute("""
                    SELECT role, pro_expires_at 
                    FROM profiles 
                    WHERE id = %s
                """, (user_id,))
                row = await cur.fetchone()

                if not row:
                    return False

                role = row[0]
                pro_expires_at = row[1]

                if role == 'pro':
                    return True
                if pro_expires_at and pro_expires_at > datetime.now(timezone.utc):
                    return True
                
                return False
    except Exception as e:
        logger.error(f"❌ Error checking pro status: {e}")
        return False

async def check_and_deduct_quota(user_id: str):
    """
    Check and deduct the user's usage limit asynchronously.
    Throws HTTPException 403 if the limit is exceeded.
    """
    if not db_manager.pool:
        logger.warning(f"⚠️ No DB Connection Pool, skipping Quota check for {user_id}")
        return

    try:
        async with db_manager.pool.connection() as conn:
            async with conn.cursor() as cur:
                # 1. Retrieve Quota information from the profiles table
                await cur.execute("""
                    SELECT ai_credits, role, pro_expires_at 
                    FROM profiles 
                    WHERE id = %s
                """, (user_id,))
                row = await cur.fetchone()

                if not row:
                    logger.warning(f"Profile does not exist for user {user_id}")
                    raise HTTPException(status_code=403, detail="Profile not found")

                ai_credits = row[0] if row[0] is not None else 0
                role = row[1]
                pro_expires_at = row[2]

                # 2. Check for Pro status first (Unlimited)
                is_pro = False
                if role == 'pro':
                    is_pro = True
                elif pro_expires_at and pro_expires_at > datetime.now(timezone.utc):
                    is_pro = True

                if is_pro:
                    logger.debug(f"💎 Pro user {user_id} detected. Unlimited access.")
                    return

                # 3. Process Trial Credits (ai_credits)
                if ai_credits > 0:
                    logger.info(f"🪄 User {user_id} using Trial Credit. Remaining: {ai_credits - 1}")
                    await cur.execute("UPDATE profiles SET ai_credits = ai_credits - 1 WHERE id = %s", (user_id,))
                    return

                # 4. If credits are exhausted and not Pro -> Block access
                logger.warning(f"🚫 User {user_id} reached trial limit (Quota Exceeded).")
                raise HTTPException(status_code=403, detail="Quota Exceeded")
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"❌ Error checking quota: {e}")
        raise HTTPException(status_code=500, detail="Quota service error")
