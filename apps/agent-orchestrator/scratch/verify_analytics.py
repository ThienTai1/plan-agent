import asyncio
import sys
import os

# Add app to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.services.supabase_service import supabase_service
from app.config import settings

async def verify():
    print("🔍 Verifying Analytics Service...")
    
    # Use a valid UUID format for testing
    user_id = "00000000-0000-0000-0000-000000000000" 
    
    print(f"📊 Testing get_analytics_data for {user_id}...")
    try:
        data = await supabase_service.get_analytics_data(user_id)
        print(f"✅ Summary: {data.get('summary')}")
    except Exception as e:
        print(f"❌ Analytics Data failed: {e}")

    print("\n📈 Testing get_productivity_trend...")
    try:
        trend = await supabase_service.get_productivity_trend(user_id, days=7)
        print(f"✅ Trend counts: {[t['count'] for t in trend]}")
    except Exception as e:
        print(f"❌ Productivity Trend failed: {e}")

    print("\n🔚 Verification complete.")

if __name__ == "__main__":
    asyncio.run(verify())
