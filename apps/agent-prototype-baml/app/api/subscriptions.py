from fastapi import APIRouter, HTTPException, Depends
from app.core.auth import get_current_user_id

router = APIRouter(prefix="/subscriptions", tags=["subscriptions"])

@router.get("/status")
async def get_subscription_status(user_id: str = Depends(get_current_user_id)):
    # This is now handled by the profiles table in Supabase
    # But we can keep an endpoint here if the Agent needs it
    return {"status": "ok"}
