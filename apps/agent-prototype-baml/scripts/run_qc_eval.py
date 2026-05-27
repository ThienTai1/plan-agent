import json
import os
import sys
import asyncio

# Append the project root or baml_client path if needed to run this standalone
sys.path.append(os.path.join(os.path.dirname(__file__), ".."))

from loguru import logger
from baml_client import b
from baml_client.types import QCInput, QCTestCase, QCWorkflowEvent

# Import the graph creation logic
from app.agents.workflows.self_graph import create_agent_graph
from baml_client.type_builder import TypeBuilder
from app.services import schema_service

async def run_qc_eval():
    data_path = os.path.join(os.path.dirname(__file__), "..", "tests", "qc_data", "testcases.json")
    
    with open(data_path, "r", encoding="utf-8") as f:
        testcases = json.load(f)

    print(f"Loaded {len(testcases)} test cases from {data_path}")

    # Initialize Graph Context
    tb = TypeBuilder()
    await schema_service.sync_type_builder(tb)
    agent_graph = create_agent_graph()

    results_report = []

    # Run each test case through the Graph
    for i, tc in enumerate(testcases, 1):
        print(f"\n[{i}/{len(testcases)}] Testing Intent: {tc['intent']}")
        
        state = {
            "query": tc["intent"],
            "messages": [],
            "user_info": "",
            "stages": None,
            "response": None,
            "plan": None,
            "blueprint": None,
            "blueprints": [],
            "advices": [],
            "error": None,
            "tool_history": [],
            "retry_count": 0,
            "replan_count": 0,
            "current_step": 0,
            "iterations": 0
        }
        
        workflow_events = []
        step_counter = 1
        
        try:
            # Stream the graph to capture state transitions as events
            async for s in agent_graph.astream(state, stream_mode="updates"):
                for node_name, node_state in s.items():
                    # Create a workflow event for each node executed
                    # (This provides the QC judge a trace of what happened)
                    
                    action_input_str = ""
                    action_output_str = ""
                    
                    if node_name == "supervisor":
                        action_input_str = f"Query: {tc['intent']}"
                        action_output_str = json.dumps(node_state.get('stages', []), indent=2)
                    elif node_name == "specialist":
                        action_input_str = "Extracted context/stages from supervisor"
                        action_output_str = f"Blueprints generated: {len(node_state.get('blueprints', []))}"
                    elif node_name == "execute_tool":
                        action_input_str = f"Tool Called: {node_state.get('tool_name')}\nInput Data: {node_state.get('tool_data')}"
                        history_len = len(node_state.get('tool_history', []))
                        last_tool_output = node_state.get('tool_history', [])[-1] if history_len > 0 else "Unknown Output"
                        action_output_str = str(last_tool_output)
                    elif node_name == "responsor":
                        action_input_str = "Gathered all previous context"
                        action_output_str = json.dumps(node_state.get('response', 'No Response'), indent=2, ensure_ascii=False)
                    else:
                        action_input_str = "Internal State Transition"
                        action_output_str = f"Reached node: {node_name}"
                        
                    evt = QCWorkflowEvent(
                        step_number=step_counter,
                        agent_name=node_name.capitalize(),
                        action=f"Execute {node_name}",
                        action_input=action_input_str,
                        action_output=action_output_str
                    )
                    workflow_events.append(evt)
                    step_counter += 1
            
            # The final response from the agent should be captured in the last node (usually responsor)
            # but we can also just fetch it from the final complete state using `.ainvoke()` or just trusting the stream.
            # To be safe and get the exact final state dict:
            final_state = await agent_graph.ainvoke(state)
            final_response_dict = final_state.get("response", "No final response generated")
            final_response_str = json.dumps(final_response_dict, indent=2, ensure_ascii=False) if isinstance(final_response_dict, dict) else str(final_response_dict)
            
            # Now evaluate with the QC Agent
            qc_test_case = QCTestCase(
                test_id=tc.get("test_id", f"tc_{i}"),
                intent=tc["intent"],
                expected_outcome=f"Expected Outcome/Structure:\n{tc['expected_outcome']}"
            )
            
            qc_input = QCInput(
                test_case=qc_test_case,
                workflow_events=workflow_events,
                final_agent_response=final_response_str
            )
            
            qc_result = b.EvaluateWorkflow(qc_input)
            
            print(f"  -> Is Valid: {"✅ YES" if qc_result.is_valid else "❌ NO"}")
            
            results_report.append({
                "test_id": qc_test_case.test_id,
                "intent": qc_test_case.intent,
                "is_valid": qc_result.is_valid,
                "overall_evaluation": qc_result.overall_evaluation,
                "anomalies": [a.model_dump() for a in qc_result.anomalies]
            })
            
            if not qc_result.is_valid:
                print(f"  -> Anomalies Found:")
                for idx, anomaly in enumerate(qc_result.anomalies, 1):
                    msg = anomaly.issue_description.replace("\n", " ")
                    print(f"     {idx}. Step {anomaly.step_number} [{anomaly.severity}]: {msg}")

        except Exception as e:
            print(f"Error processing testcase {i}: {e}")
            logger.exception("Traceback:")
            
    # Save the output report
    report_path = os.path.join(os.path.dirname(__file__), "..", "tests", "qc_data", "qc_report.json")
    with open(report_path, "w", encoding="utf-8") as f:
        json.dump(results_report, f, indent=2, ensure_ascii=False)
        
    print(f"\n✅ QC Evaluation complete. Report saved to {report_path}")

if __name__ == "__main__":
    asyncio.run(run_qc_eval())
