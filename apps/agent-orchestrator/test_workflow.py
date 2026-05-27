#!/usr/bin/env python3
"""Simple test script to verify the workflow with checkpointer config fix."""

import asyncio
from app.agent.workflow import run_orchestration

async def main():
    """Test the orchestration workflow."""
    print("Testing workflow with checkpointer config...")
    
    try:
        result = await run_orchestration(
            query="Create a goal for Q1",
            session_id="test-session-1",
            user_id="test-user-1"
        )
        
        print("✅ Workflow executed successfully!")
        print(f"\nMessages received:")
        for msg in result.get("messages", []):
            print(f"  - {msg.get('role')}: {msg.get('content', '')[:100]}...")
        
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(main())
