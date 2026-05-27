import asyncio
import os
import sys
from dotenv import load_dotenv

# Add the project root to sys.path
sys.path.append(os.getcwd())

from app.core.db import db_manager
from app.config import settings
from langgraph.checkpoint.postgres.aio import AsyncPostgresSaver
from langchain_core.messages import HumanMessage

async def test_persistence():
    print("🔌 Connecting to DB...")
    await db_manager.connect()
    
    if not db_manager.pool:
        print("❌ Pool initialization failed.")
        return

    try:
        print("🛠️ Setting up saver...")
        saver = AsyncPostgresSaver(db_manager.pool)
        await saver.setup()
        
        config = {"configurable": {"thread_id": "test_thread_123", "user_id": "test_user_456"}}
        checkpoint = {
            "v": 1,
            "ts": "2024-04-14T00:00:00Z",
            "channel_values": {"messages": [HumanMessage(content="Hello world from test script")]},
            "channel_versions": {"messages": 1},
            "versions_seen": {"messages": 1},
            "pending_sends": [],
        }
        
        metadata = {"source": "test_script"}
        
        print(f"💾 Saving checkpoint for {config['configurable']}...")
        await saver.aput(config, checkpoint, metadata, {})
        print("✅ Save call completed.")
        
        print("🔍 Attempting to retrieve...")
        retrieved = await saver.aget(config)
        if retrieved:
            print(f"✅ Successfully retrieved checkpoint: {retrieved.get('v')}")
        else:
            print("❌ Failed to retrieve checkpoint.")
            
    except Exception as e:
        print(f"💥 Error: {str(e)}")
    finally:
        await db_manager.disconnect()

if __name__ == "__main__":
    asyncio.run(test_persistence())
