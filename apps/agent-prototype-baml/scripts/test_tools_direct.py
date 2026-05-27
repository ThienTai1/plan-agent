import asyncio
import os
import sys
from pathlib import Path

# Add project root to sys.path
root_path = Path(__file__).parent.parent
if str(root_path) not in sys.path:
    sys.path.append(str(root_path))

from app.agents.tools.actions import search_tasks

async def main():
    print("Testing 'search_tasks' tool directly...")
    try:
        # We use a dummy user_id since we're testing the function logic
        result = await search_tasks(user_id="current_user", keyword="")
        print(f"Tool Result: {result}")
        print("\nSUCCESS: Tool is working correctly.")
    except Exception as e:
        print(f"\nFAILURE: Tool encountered an error: {e}")

if __name__ == "__main__":
    asyncio.run(main())
