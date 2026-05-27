import sys
import asyncio
import unittest
from pathlib import Path
from unittest.mock import AsyncMock, patch, MagicMock
from datetime import datetime

# Add the project root to sys.path
root_path = Path(__file__).parent.parent
if str(root_path) not in sys.path:
    sys.path.append(str(root_path))

from app.agent.core import build_workflow
from app.agent.schemas import OrchestratorResult, Stage

class TestPureLangChainWorkflow(unittest.IsolatedAsyncioTestCase):
    
    async def test_supervisor_routing(self):
        # Mock LLM and Structured Output
        mock_model = MagicMock() # with_structured_output is sync
        mock_structured = AsyncMock()
        mock_agent = AsyncMock()
        
        # Mock Orchestrator result (MANAGEMENT)
        mock_res = OrchestratorResult(
            stages=[Stage(name="MANAGEMENT", reasoning="Test")],
            is_complete=False
        )
        mock_structured.ainvoke.return_value = mock_res
        mock_model.with_structured_output.return_value = mock_structured
        
        # Specialist mock response (AIMessage-like object)
        mock_ai_msg = MagicMock()
        mock_ai_msg.content = "Management response"
        mock_ai_msg.tool_calls = []
        mock_agent.ainvoke.return_value = {"messages": [mock_ai_msg]}
        
        with patch("app.agent.core.model", mock_model), \
             patch("app.agent.planner.create_agent", return_value=mock_agent), \
             patch("app.agent.core.create_agent", return_value=mock_agent):
            
            app = build_workflow()
            
            initial_state = {
                "messages": [{"role": "user", "content": "Schedule a meeting"}],
                "session_id": "test_session",
                "user_id": "test_user",
                "current_time": datetime.now().isoformat(),
                "is_pro": False,
                "active_agent": "supervisor",
                "pending_departments": [],
                "current_step_index": 0
            }
            
            config = {"configurable": {"thread_id": "test_thread"}}
            
            final_state = await app.ainvoke(initial_state, config=config)
            
            print(f"Final active agent: {final_state.get('active_agent')}")
            print(f"Pending departments: {final_state.get('pending_departments')}")
            
            # Assertions
            self.assertIn("MANAGEMENT", final_state["pending_departments"])
            self.assertEqual(final_state["messages"][-1]["content"], "Action completed successfully.")

if __name__ == "__main__":
    asyncio.run(unittest.main())
