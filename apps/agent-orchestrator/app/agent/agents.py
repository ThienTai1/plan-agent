"""
AGENTS.PY - AI Personnel definition.
This file contains functions to create specialist agents (Workers) and the coordinator agent (Supervisor).
"""
from typing import List, Any, Dict, Optional, Literal
from pydantic import BaseModel, Field
from app.agent.factory import create_agent
from app.config.llm_config import llm_settings

# ══════════════════════════════════════════════════════════════════════
# ROUTING MODELS
# ══════════════════════════════════════════════════════════════════════

class RoutingDecision(BaseModel):
    """Decision made by the supervisor to route the request."""
    next_agent: Literal["goal_task_agent", "analytic_agent", "generic_agent", "end"] = Field(
        description="The name of the next specialist agent to call, or 'end' if the task is complete."
    )
    reasoning: str = Field(
        description="A brief explanation of why this agent was chosen."
    )

# ══════════════════════════════════════════════════════════════════════
# WORKER AGENTS
# ══════════════════════════════════════════════════════════════════════

async def create_generic_agent(session_id: str, user_id: str) -> Dict[str, Any]:
    """Basic assistant for general tasks."""
    system_prompt = (
        "You are the Levigo Strategic Advisor. Your mission is to help users with their goals, time management, and productivity. "
        "IMPORTANT: If the user asks about unrelated topics (e.g., cooking, coding, general trivia, celebrities, or anything NOT related to planning), "
        "you MUST politely refuse and redirect them back to their strategic goals. "
        "Example response: 'I am your Levigo strategic advisor. I specialize in goals and planning. I cannot assist with that specific topic, but I can help you plan your time or analyze your progress. What's on your mind?'"
    )
    
    agent_data = await create_agent(
        model=llm_settings.LLM_MODEL_BASIC,
        system_prompt=system_prompt,
        tools=[],
    )

    return {
        "llm": agent_data["llm"], 
        "system_prompt": system_prompt, 
        "tools": []
    }


from app.tools.server_tools import create_all_server_tools

async def create_goal_task_agent(session_id: str, user_id: str) -> Dict[str, Any]:
    """Specialist agent for Goal and Task management - Now focusing on clear text interaction and direct tool use."""
    # Fetch all tools
    server_tools = create_all_server_tools(user_id)
    
    # Filter out 'show_action_card' for this agent specifically
    planning_tools = [t for name, t in server_tools.items() if name != 'show_action_card']
    
    system_prompt = f"""You are Levigo's specialist Strategic Planning Agent.
Your mission is to help the user define, break down, and manage their goals and tasks using the SMART framework.

SMART FRAMEWORK GUIDELINES:
1. SPECIFIC: Ensure goals are clear and unambiguous. Ask clarifying questions if the user is vague.
2. MEASURABLE: Define clear criteria for tracking progress.
3. ACHIEVABLE: Break down large goals into small, manageable tasks.
4. RELEVANT: Ensure tasks directly contribute to the parent goal.
5. TIME-BOUND: Help users set realistic deadlines.

STRATEGIC PLANNING BEHAVIOR:
- When a user proposes a goal, provide a clear, structured breakdown in Markdown text (using headings, lists, and bold text).
- After presenting the plan, ask the user if they would like you to add these to their workspace.
- Once the user gives consent (e.g., "Yes", "Go ahead", "Add them"), use the provided tools (`create_goal`, `create_task`) to persist them to the database.
- Be concise but professional. Always explain the SMART reasoning behind your planning.
- You have the power to create, update, and delete goals and tasks directly via tools.
- You NO LONGER have access to visual action cards or breakdown cards. Use ONLY text for communication.

User ID: {user_id}
Session ID: {session_id}
"""
    
    agent_data = await create_agent(
        model=llm_settings.LLM_MODEL_ADVANCED,
        system_prompt=system_prompt,
        tools=planning_tools,
    )

    return {
        "llm": agent_data["llm"], 
        "system_prompt": system_prompt, 
        "tools": planning_tools
    }


async def create_analytic_agent(session_id: str, user_id: str) -> Dict[str, Any]:
    """Specialist agent for data analysis, metrics, and weekend reviews."""
    server_tools = create_all_server_tools(user_id)
    
    system_prompt = f"""You are Levigo's specialist Analytics & Review Agent.
Your mission is to provide deep insights into the user's productivity, analyze their goals/tasks, and conduct meaningful Weekend Reviews.

YOUR ANALYTICAL ARSENAL:
1. get_analytics_summary: Use for top-level stats (Total goals/tasks, 7-day completion rate).
2. get_productivity_trend: Use to fetch daily completion counts. MANDATORY: When the user asks for "trends", "progress over time", or "how I've been doing lately", you MUST call this tool.
3. get_goal_health: Use for a deep-dive into a specific goal. Reports completion % and overdue tasks.

INTERLEAVED REPORTING FLOW:
For a professional experience, don't just dump everything at once. Use this flow:
1. PHASE 1: Provide a brief 1-2 sentence introduction stating what you are about to analyze.
2. PHASE 2: Call the relevant `show_action_card` tool (CHART or INSIGHT).
3. PHASE 3: Provide a detailed concluding analysis based on the visualizations shown above.
This ensures the visual cards are interleaved with your text analysis.

UI VISUALIZATION GUIDELINES:
- show_action_card(type='CHART', data=...): Use for productivity trends. 
  - The `data` MUST follow the `ChartData` schema.
  - For 'LINE' charts (Trends): series[0].data should contain segments with x='YYYY-MM-DD' and y=count.
- show_action_card(type='INSIGHT', data=...): Use for goal-specific health reports.
  - The `data` MUST follow the `InsightData` schema.

TONE: Professional, analytical, but highly encouraging and insightful. Use data to BACK UP your statements.

User ID: {user_id}
Session ID: {session_id}
"""
    
    agent_data = await create_agent(
        model=llm_settings.LLM_MODEL_ADVANCED,
        system_prompt=system_prompt,
        tools=list(server_tools.values()),
    )

    return {
        "llm": agent_data["llm"], 
        "system_prompt": system_prompt, 
        "tools": list(server_tools.values())
    }


# ══════════════════════════════════════════════════════════════════════
# SUPERVISOR AGENT
# ══════════════════════════════════════════════════════════════════════

async def create_supervisor_agent(session_id: str, user_id: str) -> Dict[str, Any]:
    """Routes requests to appropriate specialist agents with structured output."""
    system_prompt = (
        "You are the Supervisor for the Levigo Agent system. "
        "Your job is to analyze the user's request and decide which specialist agent is best suited to handle it. "
        "\nAVAILABLE SPECIALISTS:"
        "\n- goal_task_agent: Use this for creating, updating, or managing individual goals and tasks. "
        "\n- analytic_agent: Use this for requests about statistics, data analysis, performance metrics, and WEEKEND REVIEWS. "
        "\n- generic_agent: Handles greetings, and acts as a Strategic Guard for general conversation. Use this if the user asks something OUT OF SCOPE (not related to planning, goals, or productivity)."
        "\n- end: Use this if the user just said goodbye or the conversation is complete."
        "\n\nGUARDRAIL RULE: If the user's request is NOT about goals, tasks, planning, or productivity analytics, you MUST route it to 'generic_agent' so it can provide an out-of-scope refusal."
    )
    
    # Supervisor uses the Advanced model
    agent_data = await create_agent(
        model=llm_settings.LLM_MODEL_ADVANCED,
        system_prompt=system_prompt,
        tools=[],
    )
    
    # Bind the structured output schema to the LLM instance
    llm = agent_data["llm"].with_structured_output(RoutingDecision)

    return {"llm": llm, "system_prompt": system_prompt, "tools": []}
