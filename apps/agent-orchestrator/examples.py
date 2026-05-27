"""
Example integration and usage patterns.
Shows how to use the backend components together.
"""

import asyncio
from app.agent.core import run_agent_workflow
from app.services.session_manager import get_session_manager
from app.services.frontend_client import get_frontend_client
from app.tools.frontend_tools import create_frontend_tools


async def example_task_planning():
    """Example: User asking to plan a project"""

    print("\n📋 Example 1: Task Planning\n")

    query = "Help me break down my goal to build a web app into manageable tasks"
    session_id = "example-session-1"
    user_id = "user-123"

    # Run the workflow
    result = await run_agent_workflow(query, session_id, user_id)

    # Display results
    print(f"Query: {query}")
    print(f"\nResponse:")

    for msg in result.get("messages", []):
        if msg.get("role") == "assistant":
            print(f"  {msg.get('content')}")

    # Check if there's a pending action
    if result.get("pending_action"):
        action = result.get("pending_action")
        print(f"\n💭 Pending Action:")
        print(f"  Tool: {action.get('type')}")
        print(f"  Data: {action.get('data')}")


async def example_with_session_management():
    """Example: Using session management"""

    print("\n🔐 Example 2: Session Management\n")

    session_manager = get_session_manager()

    # Create session
    session_id = session_manager.create_session("user-456")
    print(f"Session created: {session_id}")

    # Run workflow
    query = "What's my task completion status this week?"
    result = await run_agent_workflow(query, session_id, "user-456")

    # Add response to session
    for msg in result.get("messages", []):
        session_manager.add_message(session_id, msg["role"], msg["content"])

    # Get session info
    info = session_manager.get_session_info(session_id)
    print(f"\nSession info:")
    print(f"  Messages: {info['message_count']}")
    print(f"  Agents used: {info['agents_used']}")

    # Stats
    stats = session_manager.get_stats()
    print(f"\nManager stats:")
    print(f"  Total sessions: {stats['total_sessions']}")
    print(f"  Total users: {stats['total_users']}")


async def example_multi_turn_conversation():
    """Example: Multi-turn conversation"""

    print("\n💬 Example 3: Multi-turn Conversation\n")

    session_id = "multi-turn-session"
    user_id = "user-789"

    queries = [
        "I want to start a fitness routine",
        "Break it down into specific habits",
        "How can I track my progress?",
    ]

    for i, query in enumerate(queries, 1):
        print(f"Turn {i}: {query}")

        result = await run_agent_workflow(query, session_id, user_id)

        for msg in result.get("messages", []):
            if msg.get("role") == "assistant":
                content = msg.get("content")[:100] + "..."

                print(f"  Agent: {content}\n")


async def example_direct_tool_access():
    """Example: Accessing tools directly"""

    print("\n🛠️  Example 4: Direct Tool Access\n")

    session_id = "tool-example"
    user_id = "user-tool"

    # Create tools
    tools = create_frontend_tools(session_id, user_id)

    # Access specific tools
    print("Available tools:")
    for tool_name in [
        "create_goal",
        "list_goals",
        "list_tasks",
        "get_user_context",
    ]:
        tool = tools.get(tool_name)
        if tool:
            print(f"  - {tool.name}: {tool.description.split('.')[0]}")


async def main():
    """Run all examples"""

    print("=" * 60)
    print("PLANNING AGENT BACKEND - USAGE EXAMPLES")
    print("=" * 60)

    try:
        # Example 1: Task Planning
        await example_task_planning()

        # Example 2: Session Management
        await example_with_session_management()

        # Example 3: Multi-turn Conversation
        await example_multi_turn_conversation()

        # Example 4: Direct Tool Access
        await example_direct_tool_access()

        print("\n" + "=" * 60)
        print("✅ All examples completed!")
        print("=" * 60)

    except Exception as e:
        print(f"\n❌ Error running examples: {str(e)}")
        import traceback

        traceback.print_exc()


if __name__ == "__main__":
    asyncio.run(main())
