import asyncio
import uuid
import json
from app.agent.workflow import stream_orchestration
from app.tools.server_tools import ShowActionCardServerTool
from loguru import logger

async def simulate_stringified_json_fix():
    """Verify that backend coercing handles stringified JSON."""
    tool = ShowActionCardServerTool(user_id="test_user")
    
    # Simulate LLM sending data as a string
    stringified_data = '{"goal_title": "Test Goal From String", "milestones": []}'
    
    print(f"\n--- Testing JSON Coercion ---")
    print(f"Input type: {type(stringified_data)}")
    
    result = await tool.arun(type="BREAKDOWN", data=stringified_data)
    
    coerced_data = result.data.get("data")
    print(f"Coerced Output type: {type(coerced_data)}")
    
    if isinstance(coerced_data, dict):
        print(f"Goal Title: {coerced_data.get('goal_title')}")
        print("✅ SUCCESS: Backend coerced stringified JSON into a dictionary!")
    else:
        print("❌ FAILURE: Backend failed to coerce stringified JSON.")

async def test_goal_breakdown_trigger():
    """Verify that a new goal request triggers a BREAKDOWN action card."""
    user_id = "550e8400-e29b-41d4-a716-446655440000"
    session_id = str(uuid.uuid4())
    query = "Tôi muốn học lập trình Flutter trong 30 ngày. Hãy lên kế hoạch giúp tôi."
    
    print(f"\n--- Testing Goal Breakdown Trigger ---")
    print(f"Query: {query}")
    
    found_breakdown = False
    async for event in stream_orchestration(query, session_id, user_id):
        e_type = event.get("type")
        
        if e_type == "object":
            content = event.get("object", {})
            card_type = content.get("type")
            print(f"\n[EVENT] Received UI Object: {card_type}")
            if card_type == "BREAKDOWN":
                found_breakdown = True
                data = content.get("data", {})
                if isinstance(data, dict):
                    print(f"Goal Title: {data.get('goal_title', 'N/A')}")
                else:
                    print(f"Raw Data: {data}")
                
        elif e_type == "text":
            print(f"Agent: {event.get('content')}", end="", flush=True)
            
    if found_breakdown:
        print("\n\n✅ SUCCESS: BREAKDOWN action card was correctly triggered!")
    else:
        print("\n\n❌ FAILURE: BREAKDOWN action card was NOT triggered.")

if __name__ == "__main__":
    asyncio.run(simulate_stringified_json_fix())
    # asyncio.run(test_goal_breakdown_trigger())
