// --- 1. Tool APIs ---

class CustomProperty{
  name string
  value string
}

class TaskTool {
  id string? @description("The ID of the task if known")
  title string
  due_date string?
  priority string?
  is_completed bool? @description("Whether the task is finished")
}

class EventTool {
  id string?
  title string
  start_time string
  end_time string?
}

class GoalTool {
  id string? @description("The ID of the goal if known")
  title string
  description string?
  status string? @description("active, completed, etc.")
  start_date string?
  end_date string?
}

class SearchTool {
  query string @description("Search query for goals, tasks, or events")
}

// --- 2. Agent Response with Thinking Chain ---

class AgentStepResponse {
  reasoning string? @description("Step-by-step thinking about what the user wants and what to do next.")
  thought_process string? @description("Detailed mental model: 1. Identify intent, 2. Check missing info, 3. Choose tool.")
  
  needs_more_tools bool @description("True if we need to call a tool before answering. False if we have enough info.")
  
  tool_choice TaskTool | EventTool | GoalTool | SearchTool | null @description("The tool to use next, or null if giving final answer.")
  
  final_answer string? @description("The final response to the user if needs_more_tools is false.")
}

// --- 3. Persistent Agent State (Memory) ---

class AgentState {
  current_objective string @description("The main goal the user is trying to achieve")
  completed_steps string[] @description("List of actions already taken")
  gathered_info string @description("Context collected from tool results so far")
}

// --- 4. The ReAct Agent Function ---

function AgentStep(
  user_message: string,
  history: Messages[],
  state: AgentState?,
  previous_results: string?
) -> AgentStepResponse {
  client Gemini25FlashLite
  prompt #"
    You are Levigo, an intelligent Planning Agent. Your goal is to help the user manage their life (Goals, Tasks, Events).
    
    {% if state %}
    --- CURRENT STATE ---
    Objective: {{ state.current_objective }}
    Completed: {{ state.completed_steps | join(", ") }}
    Gathered Info: {{ state.gathered_info }}
    {% endif %}

    {% if previous_results %}
    --- RECENT TOOL RESULTS ---
    {{ previous_results }}
    {% endif %}

    Analyze the user's request and the current context.
    Think step-by-step:
    1. What is the user asking for right now?
    2. What information do I have in the database (via history or previous results)?
    3. Do I need to search more or create/update something?
    4. Choose the best tool or provide a concise final answer.

    {{ ctx.output_format }}

    --- USER MESSAGE ---
    {{ user_message }}
  "#
}

test test_agent_step {
  functions [AgentStep]
    args {
        user_message "I want to create a new task"
        history []
        state null
        previous_results null
    }
}

