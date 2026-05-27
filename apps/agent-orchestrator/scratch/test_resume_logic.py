import asyncio
import uuid
import json
from langgraph.graph import StateGraph, START, END
from langgraph.types import interrupt, Command
from langgraph.checkpoint.memory import MemorySaver

# Mock state
from typing import TypedDict, Annotated, List
class State(TypedDict):
    messages: Annotated[List[str], lambda x, y: x + y]

async def node_with_interrupt(state: State):
    print("--- NODE START ---")
    val = interrupt("Waiting for user...")
    print(f"--- RESUMED WITH: {val} ---")
    return {"messages": [f"Processed {val}"]}

def build_test_graph():
    builder = StateGraph(State)
    builder.add_node("node", node_with_interrupt)
    builder.add_edge(START, "node")
    builder.add_edge("node", END)
    return builder.compile(checkpointer=MemorySaver())

async def test_resume_pattern():
    print("\nStarting Test Graph...")
    graph = build_test_graph()
    thread_id = str(uuid.uuid4())
    config = {"configurable": {"thread_id": thread_id}}
    
    # Run until interrupt
    print("Initial run...")
    async for event in graph.astream({"messages": ["hello"]}, config, stream_mode="updates"):
        print(f"Update: {event}")
    
    # Simulate the Resume logic from routes.py
    print("\nSimulating Resume with List (like 'Add all')...")
    responses = [{"action": "create_task", "title": "Task 1"}]
    
    try:
        # This matches the new logic in routes.py
        result = await graph.ainvoke(Command(resume=responses), config=config)
        print(f"Resume successful! Final state: {result}")
        print("✅ SUCCESS: Command(resume=list) works perfectly.")
    except Exception as e:
        print(f"❌ FAILURE: {str(e)}")

if __name__ == "__main__":
    asyncio.run(test_resume_pattern())
