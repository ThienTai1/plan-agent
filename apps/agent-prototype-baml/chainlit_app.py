"""
Chainlit Chat UI for the Modular Agent Workflow with LangGraph HITL.

Uses LangGraph's native `interrupt_before` to pause the graph before
executing tools, then resumes or skips based on user input.

Run with: uv run chainlit run chainlit_app.py -w --port 8001
"""
import chainlit as cl
import json
import uuid
from datetime import datetime
from dotenv import load_dotenv
from langgraph.checkpoint.memory import MemorySaver

load_dotenv(override=True)

from app.agents.workflows.self_graph import create_agent_graph, AgentState
from app.services import schema_service
from baml_client.type_builder import TypeBuilder


@cl.on_chat_start
async def on_chat_start():
    """Initialize session with a LangGraph app that has interrupt_before."""
    # Build graph with HITL: pause before execute_tool
    
    # Required to sync tools dynamically via reflection/registry
    tb = TypeBuilder()
    await schema_service.sync_type_builder(tb)
    
    memory = MemorySaver()
    app = create_agent_graph(checkpointer=memory, interrupt_before=["execute_tool"])
    
    cl.user_session.set("app", app)
    cl.user_session.set("history", [])
    cl.user_session.set("thread_id", f"chainlit-{uuid.uuid4().hex[:8]}")

    await cl.Message(
        content="👋 Hello! I'm Levigo, your AI Agent with **Human-in-the-Loop** powered by LangGraph.\n\n"
                "Before executing any tool, the graph will **pause** and ask for your approval. "
                "Try asking me something!"
    ).send()


@cl.on_message
async def on_message(message: cl.Message):
    """Handle user messages using LangGraph's native interrupt flow."""
    query = message.content
    print(f"\n--- NEW MESSAGE RECEIVED: {query} ---")
    history = cl.user_session.get("history", [])
    app = cl.user_session.get("app")
    thread_id = cl.user_session.get("thread_id")

    config = {"configurable": {"thread_id": thread_id}}

    # For the first message in a thread or subsequent messages, we provide the full current state payload
    previous_tool_results = cl.user_session.get("previous_tool_results", [])
    input_state = {
        "query": query,
        "messages": history,
        "user_info": "",
        "previous_tool_results": previous_tool_results,
        # Clear previous state to ensure a fresh turn
        "response": None,
        "stages": None,
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

    final_answer = None

    # ── PHASE 1: Stream until first interrupt ──
    final_answer = await _stream_until_interrupt(app, input_state, config)

    # ── PHASE 2: HITL loop — handle interrupts ──
    while not final_answer:
        # Graph is paused before execute_tool. Check the pending action.
        snapshot = await app.aget_state(config)
        state = snapshot.values
        tool_name = state.get("tool_name")
        tool_data = state.get("tool_data")

        if not tool_name or tool_name == "chat_response":
            # No action pending — graph might have ended or gone to responsor naturally
            break

        # Ask user for approval
        approval = await cl.AskActionMessage(
            content=f"🛡️ **Confirm execution?**\n\n"
                    f"**Tool:** `{tool_name}`\n"
                    f"**Data:** `{json.dumps(tool_data, ensure_ascii=False)}`",
            actions=[
                cl.Action(name="approve", payload={"value": "approve"}, label="✅ Approve"),
                cl.Action(name="reject", payload={"value": "reject"}, label="❌ Reject"),
            ],
            timeout=120
        ).send()

        if approval and approval.get("payload", {}).get("value") == "approve":
            # ── APPROVED: Resume the graph (it will run execute_tool) ──
            final_answer = await _stream_until_interrupt(app, None, config)
        else:
            # ── REJECTED: Update state to skip this tool, then resume ──
            await cl.Message(content=f"⏭️ Skipped step `{tool_name}`.").send()

            # Modify state to mimic that the tool failed or was skipped
            # Stringify keys and values to match BAML ToolResult map<string, string>
            stringified_data = {str(k): str(v) for k, v in tool_data.items()}
            
            tool_history = list(state.get("tool_history", []))
            tool_history.append({
                "tool_name": tool_name,
                "tool_input": [stringified_data],
                "tool_output": "User REJECTED the execution of this tool."
            })

            await app.aupdate_state(
                config,
                {
                    "tool_history": tool_history
                },
                as_node="execute_tool"  # Pretend execute_tool ran, so graph goes to validator
            )

            # Resume from after execute_tool (validator)
            final_answer = await _stream_until_interrupt(app, None, config)

    # Send the final answer
    if not final_answer:
        # Check if the state has it
        snapshot = await app.aget_state(config)
        state_response = snapshot.values.get("response")
        if state_response:
             final_answer = state_response

    if not final_answer:
        final_answer = {"blocks": [{"component_type": "TEXT", "text": "I have completed your request, but I couldn't synthesize a summary. Is there anything else you need?"}]}
    
    # Format the final_answer payload which contains UI blocks into readable text or widgets for Chainlit
    formatted_reply = ""
    if isinstance(final_answer, dict) and "blocks" in final_answer:
        for block in final_answer["blocks"]:
            comp_type = block.get("component_type")
            if comp_type == "TEXT":
                formatted_reply += block.get("text", "") + "\n\n"
            elif comp_type in ["BAR_CHART", "PIE_CHART", "LINE_CHART"]:
                chart_data = block.get("chart_data")
                if not chart_data:
                    continue
                
                title = chart_data.get("title", "Analytics Chart")
                series_list = chart_data.get("series", [])
                
                if comp_type == "PIE_CHART":
                    # Mermaid Pie Chart
                    mermaid_code = f"pie title {title}\n"
                    if series_list:
                        # Pie charts usually take points from the first series or sum them
                        for point in series_list[0].get("data", []):
                            label = point.get("x", "Unknown")
                            value = point.get("y", 0)
                            mermaid_code += f'    "{label}" : {value}\n'
                    formatted_reply += f"```mermaid\n{mermaid_code}```\n\n"
                
                elif comp_type in ["BAR_CHART", "LINE_CHART"]:
                    # Mermaid XY Chart (Beta)
                    # Note: xychart-beta is useful but sometimes restrictive. 
                    # For simplicity and broad support in Chainlit, we can use it or a simple bar/line if available.
                    # xychart-beta version:
                    mermaid_code = f"xychart-beta\n    title \"{title}\"\n"
                    
                    if series_list:
                        # Extract X-axis labels from the first series
                        x_labels = [f'"{p.get("x")}"' for p in series_list[0].get("data", [])]
                        mermaid_code += f"    x-axis [{', '.join(x_labels)}]\n"
                        
                        for series in series_list:
                            s_label = series.get("label", "Value")
                            s_data = [str(p.get("y", 0)) for p in series.get("data", [])]
                            m_type = "bar" if comp_type == "BAR_CHART" else "line"
                            mermaid_code += f"    {m_type} [{', '.join(s_data)}]\n"
                    
                    formatted_reply += f"```mermaid\n{mermaid_code}```\n\n"
    else:
        formatted_reply = str(final_answer)

    await cl.Message(content=formatted_reply).send()

    # Update history correctly
    from app.models.requests import ChatMessage
    history.append(ChatMessage(role="user", content=query))
    
    # Store tool history as a state memory for the next turn
    snapshot = await app.aget_state(config)
    state_tool_history = snapshot.values.get("tool_history", [])
    if state_tool_history:
        from app.services.context_engine import format_tool_results
        internal_results = []
        for th in state_tool_history:
            tool_name = th.get("tool_name", "unknown_tool")
            tool_output = th.get("tool_output", "")
            try:
                if isinstance(tool_output, str):
                    parsed_output = json.loads(tool_output)
                    formatted_res = format_tool_results(tool_name, "entity", parsed_output)
                else:
                    formatted_res = format_tool_results(tool_name, "entity", tool_output)
            except Exception:
                formatted_res = f"Action: {tool_name}\nResult: {tool_output}"
            internal_results.append(formatted_res)
            
        cl.user_session.set("previous_tool_results", internal_results)
    else:
        # Clear it if no tool was run this turn
        cl.user_session.set("previous_tool_results", [])
        
    history.append(ChatMessage(role="assistant", content=formatted_reply))
    cl.user_session.set("history", history)


async def _stream_until_interrupt(app, input_state, config) -> str:
    """
    Stream graph events until it either:
    - Finishes (returns final_answer)
    - Hits an interrupt (returns empty string)
    
    Displays each node's output as a Chainlit Step.
    """
    final_answer = None

    async for event in app.astream(input_state, config=config, stream_mode="updates"):
        print(f"DEBUG [stream]: Received event from nodes: {list(event.keys())}")
        if not event:
            continue
        for node_name, output in event.items():
            if not output:
                continue

            if node_name == "supervisor":
                stages = output.get("stages", [])
                response = output.get("response")
                if response:
                     async with cl.Step(name="🤖 Supervisor", type="llm") as step:
                        step.output = "Direct conversational response generated."
                elif stages:
                    depts = [dept for stage in stages for dept in stage.get("departments", [])]
                    async with cl.Step(name="🤖 Supervisor", type="llm") as step:
                        step.output = f"Identified Action Intent. Departments: **{', '.join(depts)}**"

            elif node_name == "specialist":
                bps = output.get("blueprints", [])
                advices = output.get("advices", [])
                if bps:
                    async with cl.Step(name="🧑‍💼 Specialist", type="llm") as step:
                        step.output = f"Generated {len(bps)} blueprint(s)"
                elif advices:
                     async with cl.Step(name="🧑‍💼 Specialist", type="llm") as step:
                        step.output = f"Generated {len(advices)} advice(s)"

            elif node_name == "context_synthesizer":
                bp = output.get("blueprint")
                if bp:
                    async with cl.Step(name="🧠 Synthesizer", type="llm") as step:
                        try:
                           bp_str = bp.model_dump_json(indent=2)
                        except:
                           bp_str = str(bp)
                        step.output = f"Combined Blueprint Objective:\n```json\n{bp_str}\n```"

            elif node_name == "planner":
                plan = output.get("plan")
                if plan and hasattr(plan, 'steps'):
                    async with cl.Step(name="📝 Planner", type="llm") as step:
                        plan_text = "\n".join([f"- **{s.step}**: {s.description}" for s in plan.steps])
                        step.output = f"Created Execution Plan:\n\n{plan_text}"

            elif node_name == "executor":
                tool_name = output.get("tool_name")
                tool_data = output.get("tool_data")
                if tool_name and tool_name != "chat_response":
                    async with cl.Step(name=f"⚡ Executor", type="llm") as step:
                        step.output = (
                            f"Selected Tool: `{tool_name}`\n\n"
                            f"Params:\n```json\n{json.dumps(tool_data, ensure_ascii=False, indent=2)}\n```"
                        )

            elif node_name == "execute_tool":
                hist = output.get("tool_history", [])
                if hist:
                    last_exec = hist[-1]
                    async with cl.Step(name="🔧 Tool Execution", type="tool") as step:
                        step.output = f"Result from `{last_exec.get('tool_name')}`:\n```\n{last_exec.get('tool_output')}\n```"

            elif node_name == "validator":
                decision = output.get("validator_decision")
                reasoning = output.get("validator_reasoning", "")
                
                icon = "✅" if decision == "PASS" else "🔄" if decision in ["RETRY", "REPLAN"] else "❌"
                async with cl.Step(name=f"{icon} Validator", type="llm") as step:
                    step.output = f"**Decision:** {decision}\n\n**Reasoning:** {reasoning}"

            elif node_name == "responsor":
                if output.get("response"):
                    final_answer = output["response"]
                    async with cl.Step(name="💬 Responsor", type="llm") as step:
                        step.output = "Final conversational UI block generated."

    return final_answer
