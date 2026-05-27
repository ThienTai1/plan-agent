"""
ANALYTICS_ROUTES.PY - API Endpoints for Dashboard and Productivity data.
"""
from fastapi import APIRouter, Depends, Query
from app.api.deps import get_current_user
from app.services.supabase_service import supabase_service
from app.core.security import limiter
from app.core.quota import is_user_pro
from fastapi import Request, HTTPException

router = APIRouter()

async def verify_pro_access(user_id: str = Depends(get_current_user)):
    """Dependency to verify a user has Pro status."""
    if not await is_user_pro(user_id):
        raise HTTPException(status_code=403, detail="Strategic Dashboard requires a Pro subscription.")
    return user_id

@router.get("/dashboard")
@limiter.limit("30/minute")
async def get_dashboard_data(request: Request, user_id: str = Depends(verify_pro_access)):
    """
    Combined endpoint for all Strategic Dashboard data.
    Provides overview, trend, and category focus.
    """
    # 1. Get Overview Stats
    overview = await supabase_service.get_analytics_data(user_id)
    
    # 2. Get Productivity Trend (last 14 days)
    trend = await supabase_service.get_productivity_trend(user_id, days=14)
    
    # 3. Get Focus Distribution (by category)
    focus = await supabase_service.get_category_distribution(user_id)
    
    return {
        "overview": overview,
        "trend": trend,
        "focus": focus,
        "status": "success"
    }

@router.get("/trend")
@limiter.limit("30/minute")
async def get_trend_only(request: Request, days: int = Query(14, ge=1, le=90), user_id: str = Depends(verify_pro_access)):
    """Standalone endpoint for productivity trend."""
    trend = await supabase_service.get_productivity_trend(user_id, days=days)
    return {"trend": trend}
