// ══════════════════════════════════════════════════════════════════════
// UNIFIED ORCHESTRATOR
// ══════════════════════════════════════════════════════════════════════

class OrchestratorStage {
    order int
    departments Department[] @description("The departments responsible for this specific stage. Multiple departments here mean they can be executed in parallel.")
}

class OrchestratorResult {
    stages OrchestratorStage[] @description("The ordered sequence of stages to fulfill the user intent. Stages are executed sequentially, but departments within a stage can be parallel.")
    chat_response string? @description("The conversational response if 'CHAT' is the ONLY department in the stages. Leave empty otherwise.")
}

enum Department {
    MANAGEMENT @description(#"
        manage task, event, project, goal
    "#)
    ANALYTICS @description(#"
        analyze data, provide insights
    "#)
    CHAT @description(#"
        chat with user
    "#)
}

function Orchestrator(query: string, context: string, messages: Messages[]) -> OrchestratorResult {
    client FallbackClient
    prompt #"""
        {{ _.role("system") }} 
        {{ SystemPrompt() }}
        {{ PersonalPrompt() }}
        CONTEXT:
        {{ context }}

        HISTORY:
        {{ messages }}

        TASK:
        You are Levigo, the Orchestrator (Supervisor). Your job is to break down the user's request into a logical sequence of stages. 
        Each stage has an `order` and a list of `departments`.

        RULES:
        44. ANTI-LOOP RULE: If the CONTEXT (specifically [PREVIOUS OPERATION RESULTS]) contains enough information (even if results are 0/empty) to directly answer the USER QUERY, you MUST return a single stage with order=1, departments=["CHAT"] and provide the answer in `chat_response`. Do NOT assign MANAGEMENT or ANALYTICS if the information has already been retrieved.
        2. If the user ONLY says a simple conversational message (greeting, thanks), return a single stage with order=1, departments=["CHAT"] and provide "chat_response".
        3. If the user asks for multiple actions that DO NOT depend on each other (Parallel actions), group them in the SAME stage with the SAME order (e.g., order: 1, departments: ["ANALYTICS", "MANAGEMENT"]).
            * Example of Parallel: "Analyze my tasks this week AND schedule a meeting tomorrow." -> Both Analytics and Management can run at the same time.
        4. If the user asks for an action that DEPENDS on the result of another action (Sequential actions), split them into DIFFERENT stages with INCREASING orders.
            * Example of Sequential: "Find out how many tasks I completed (Analytics). THEN, if the number is low, create a task to review my productivity (Management)." -> order 1: ["ANALYTICS"], order 2: ["MANAGEMENT"].
        5. If a request involves multiple sequential steps that all belong to the SAME department, split them into DIFFERENT stages (e.g., order 1: ["MANAGEMENT"], order 2: ["MANAGEMENT"]).
        6. For ANY actions related to directly managing tasks, events, and simple queries, you MUST assign the step to "MANAGEMENT".
        7. ONLY assign "ANALYTICS" if the user explicitly asks for deep data analysis, metrics, charts, or generating complex summaries.
        {{ ctx.output_format }}

        {{ _.role("user") }}
        USER QUERY:
        {{ query }}
    """#
}

test TestManagementAction {
    functions [Orchestrator]
    args {
            query "i need setup task focus but who are you"
            context "[DATABASE STATE]\n- No tasks currently."
            messages []
    }
}

test TestBothDepartments {
    functions [Orchestrator]
    args {
            query "Summarize last week's tasks and then create a new task to review them tomorrow."
            context "[DATABASE STATE]\n- User has 5 completed tasks from last week."
            messages []
    }
}

test TestParallelDepartments {
    functions [Orchestrator]
    args {
            query "Can you analyze my productivity rate for this month, and then schedule a meeting with Bob for next Monday?"
            context "[DATABASE STATE]\n- User has no upcoming events."
            messages []
    }
}


enum ComponentType {
    TEXT
    CHART @description("Dynamic chart for data visualization. Use when user asks for metrics, trends, or summaries.")
    BREAKDOWN @description("Goal breakdown with milestones and timeline. Use when user asks to break down a goal.")
    INSIGHT @description("Dashboard stats overview with goal progress. Use when user asks for progress/insights/overview.")
    FOCUS @description("Today's top 3 priority tasks. Use when user asks for today's focus/priorities.")
    RESCHEDULE @description("Overdue tasks with suggested new dates. Use when overdue tasks are detected.")
    REFLECTION @description("Weekly review template with guided questions. Use when user asks for weekly review/reflection.")
}

// ── Chart Models ──

class ChartDataPoint {
    x string @description("The X-axis value (e.g., date '2026-03-10', or category 'Project A')")
    y float @description("The Y-axis value (e.g., 15.5, 10)")
}

enum ChartVisualizationType {
    BAR @description("Vertical bar chart for comparisons across categories.")
    LINE @description("Line chart for trends over time.")
    PIE @description("Pie chart for distribution/composition.")
    AREA @description("Area chart (line with fill) for cumulative trends.")
    RADIAL @description("Concentric progress rings (Apple Watch style). Each series = one ring, data[0].y = progress 0.0-1.0. Options: ring_thickness (default 4).")

    SPARKLINE @description("Tiny inline chart rendered inside chat bubble text. No axis labels. series[0].data = array of points. Options: height (default 40), show_area (default true), color ('muted_green'|'muted_blue').")
    STAT_CARD @description("Big number KPI display. Each series = one metric. data[0] x='value' y=number, data[1] x='trend' y=percentage change. Options: layout ('row'|'column').")
    PROGRESS @description("Multiple horizontal progress bars for goal tracking. Each series = one goal. data[0].x = status ('on_track'|'behind'|'at_risk'), data[0].y = progress 0.0-1.0.")
}

class ChartConfig {
    type ChartVisualizationType @description("Preferred visualization type.")
    x_axis_label string? @description("Label for X-axis (if applicable)")
    y_axis_label string? @description("Label for Y-axis (if applicable)")
    show_legend bool? @description("Whether to show the legend.")
    options map<string, string | int | float>? @description("Type-specific options. Each chart type accepts different keys — see ChartVisualizationType descriptions for available options.")
}

class ChartSeries {
    label string? @description("Name of this series for the Legend (e.g., 'Revenue', 'Time Spent')")
    data ChartDataPoint[] @description("The data points for this specific series")
}

class ChartData {
    title string? @description("Optional title for the chart.")
    config ChartConfig @description("Visualization configuration.")
    series ChartSeries[] @description("List of data series to plot. Supports multi-line or grouped charts.")
}

// ── Action Card Models ──

class MilestoneItem {
    title string @description("Title of the milestone")
    deadline string? @description("Suggested deadline in ISO date format (e.g. 2026-04-15)")
    description string? @description("Brief description of what this milestone involves")
    subtasks MilestoneItem[]? @description("Optional sub-steps to achieve this specific milestone")
}


class BreakdownData {
    goal_title string @description("The original goal being broken down")
    milestones MilestoneItem[] @description("Ordered list of milestones with timeline")
}

class GoalProgressItem {
    goal_title string @description("Name of the goal")
    progress_pct float @description("Progress percentage from 0.0 to 1.0")
    status string @description("One of: on_track, behind, at_risk")
}

class InsightData {
    tasks_done int @description("Number of tasks completed")
    tasks_overdue int @description("Number of overdue tasks")
    tasks_on_track int @description("Number of tasks on track")
    goal_progress GoalProgressItem[] @description("Progress per goal")
    warnings string[] @description("Warning messages for items behind schedule")
}

class FocusTask {
    task_id string @description("UUID of the task")
    title string @description("Task title")
    goal_tag string? @description("Name of the associated goal, if any")
    estimated_minutes int? @description("Estimated time in minutes")
    is_completed bool @description("Whether the task is already completed")
}

class FocusData {
    date string @description("Today's date in ISO format")
    tasks FocusTask[] @description("Top 3 priority tasks for today")
}

class RescheduleItem {
    task_id string @description("UUID of the overdue task")
    title string @description("Task title")
    original_due string @description("Original due date in ISO format")
    suggested_due string @description("AI-suggested new due date in ISO format")
}

class RescheduleData {
    overdue_tasks RescheduleItem[] @description("List of overdue tasks with suggested reschedule dates")
}

class ReflectionQuestion {
    prompt string @description("The reflection question")
    placeholder string? @description("Placeholder hint for the answer")
}

class ReflectionData {
    week_summary string? @description("Brief summary of the past week's accomplishments")
    questions ReflectionQuestion[] @description("3 guided reflection questions")
    cta_label string @description("Call-to-action button label (e.g. 'Start Journal Entry')")
    cta_route string @description("Navigation route for the CTA (e.g. '/journal')")
}

// ── Response Block ──

class AgentResponseBlock {
    component_type ComponentType @description("Choose the appropriate component type for this block.")
    text string? @description("Conversational text. Required if component_type is TEXT.")
    chart_data ChartData? @description("Dynamic chart data. Required if component_type is CHART.")
    breakdown_data BreakdownData? @description("Goal breakdown data. Required if component_type is BREAKDOWN.")
    insight_data InsightData? @description("Dashboard insight data. Required if component_type is INSIGHT.")
    focus_data FocusData? @description("Today's focus tasks. Required if component_type is FOCUS.")
    reschedule_data RescheduleData? @description("Reschedule suggestions. Required if component_type is RESCHEDULE.")
    reflection_data ReflectionData? @description("Weekly reflection data. Required if component_type is REFLECTION.")
}

class AgentResponse {
    blocks AgentResponseBlock[] @description("An ordered list of UI blocks to render sequentially from top to bottom.")
}

function Responsor(query: string, context: string, plan: string?, tool_history: string?, validator_reasoning: string?, messages: Messages[]) -> AgentResponse {
    client FallbackClient
    prompt #"
        {{_.role("system")}}
        You are Levigo, the final step of an AI agent pipeline. Your job is to compose a clear, helpful, and concise response to the user.
        Review the CONTEXT and MESSAGES to understand what happened, then respond appropriately based on the situation:

        SITUATION 1 — TASK COMPLETED:
        One or more actions were executed successfully (look for "TOOL EXECUTION RESULT" or "created/updated/deleted" in MESSAGES).
        → Confirm what was done. Be brief and friendly. Do NOT ask for confirmation.

        SITUATION 2 — NEED CLARIFICATION:
        The workflow stopped before completing because the result was ambiguous or information was missing
        (e.g., multiple items matched, no items found, unclear intent).
        → Explain what happened and ask a specific, actionable question to resolve the ambiguity.

        SITUATION 3 — TASK FAILED / NO RESULTS:
        The tool returned an error or empty results and no further action is possible.
        → Apologize briefly, explain what happened, and suggest what the user can try next.

        SITUATION 4 — GENERAL CONVERSATION:
        No tools were involved. The user is just chatting or asking for advice.
        → Answer directly and helpfully based on your knowledge and the provided CONTEXT.

        [UI COMPONENT INSTRUCTIONS]
        - Return an array of `blocks` in the exact visual sequence you want them displayed (e.g., intro TEXT block -> CHART block -> conclusion TEXT block).
        
        CHART RULES:
        - **IF the user asks for a summary, analysis, or overview of data AND you have quantitative data, you MUST include a CHART block.** 
        - Populate its `chart_data` field: 
            - Choose the most appropriate `config.type` (LINE for trends over time, BAR for comparisons, PIE for distribution/composition).
            - Set `config.x_axis_label` and `config.y_axis_label` appropriately.
            - Create one or more `series` with `ChartDataPoint` objects.
        - For standard CRUD tasks with NO analytical request, use TEXT only.

        ACTION CARD RULES — Use these special component types for rich, interactive cards:
        
        1. **BREAKDOWN** — When the user asks to "break down a goal", "create milestones", or "plan how to achieve X":
           → Return a BREAKDOWN block with `breakdown_data` containing the goal_title and an ordered list of milestones with suggested deadlines.
           → The user can "Add all" milestones as goals/tasks directly from the card.
        
        2. **INSIGHT** — When the user asks for "my progress", "show insights", "how am I doing", "overview":
           → Return an INSIGHT block with `insight_data` containing task counts (done/overdue/on_track), per-goal progress bars, and any warnings.
           → Use data from TOOL HISTORY (e.g., get_dashboard_stats results).
        
        3. **FOCUS** — When the user asks "what should I focus on today?", "today's priorities", "my focus list":
           → Return a FOCUS block with `focus_data` containing the top 3 priority tasks for today.
           → The user can check off tasks directly from the card.
           → Use data from TOOL HISTORY (e.g., get_today_focus results).
        
        4. **RESCHEDULE** — When there are overdue tasks detected, or user asks "reschedule overdue", "fix my late tasks":
           → Return a RESCHEDULE block with `reschedule_data` containing overdue tasks and AI-suggested new due dates.
           → The user can "Accept all" to batch-reschedule.
           → Suggest reasonable new dates based on the user's calendar and workload.
        
        5. **REFLECTION** — When the user asks for "weekly review", "reflection", or it's the end of the week:
           → Return a REFLECTION block with `reflection_data` containing a week summary, 3 guided questions, and a CTA to start journaling.
           → Questions should be personalized based on the user's actual week data.
        
        GENERAL RULES:
        - You can combine TEXT blocks with action card blocks (e.g., TEXT intro + INSIGHT card + TEXT conclusion).
        - Each action card block MUST populate the corresponding data field (e.g., BREAKDOWN must have breakdown_data).
        - Prefer action cards over plain text when the data fits one of the 5 card types above.

        {{FewShotExamples()}}

        [STYLE & TONE]
        - Tone: Encouraging, minimalist, and authoritative advisor.
        - Language: High Agency (use "I've organized...", "I recommend...", "Let's focus on...").
        - Keep conversational text blocks very brief (1-2 sentences) when they accompany Action Cards.
        - If no data is found (empty state), be curious and suggest a specific next step to the user.

        CONTEXT:
        {{context}}
        
        {% if plan %}
        PLAN:
        {{plan}}
        {% endif %}

        {% if tool_history %}
        TOOL HISTORY:
        {{tool_history}}
        {% endif %}

        {% if validator_reasoning %}
        VALIDATOR REASONING:
        {{validator_reasoning}}
        {% endif %}

        MESSAGES:
        {{messages}}

        {{_.role("user")}}
        {{query}}
        
        {{ ctx.output_format }}
    "#
}

test TestResponsorAmbiguity {
    functions [Responsor]
    args {
        query "Reschedule my meeting with Boss"
        context "[SEARCH RESULTS: search_events]\n- ID: ev_1, Title: 1:1 with Boss Alpha, Time: 14:00\n- ID: ev_2, Title: Project Sync with Boss Beta, Time: 16:00"
        plan null
        tool_history null
        validator_reasoning "The search returned multiple meetings with 'Boss'. Need to ask the user which one."
        messages [
            {
                role user
                content "Reschedule my meeting with Boss"
            },
            {
                role assistant
                content "[THOUGHT] I need to find the meeting with 'Boss' first.\n[OBSERVATION: search_events] Found two meetings."
            }
        ]
    }
}

test TestResponsor_AnalyticsChart {
    functions [Responsor]
    args {
        query "Summarize my completed tasks this week and show me the time spent."
        context "[SYSTEM]\ncurrent_time: 2026-03-11 06:30:00 UTC\npersona: Levigo."
        plan "{\n  \"reasoning\": \"The user wants an overview.\",\n  \"steps\": [\n    {\n      \"step\": 1,\n      \"description\": \"Search for tasks where is_completed is true.\"\n    }\n  ]\n}"
        tool_history "[{\"tool_name\": \"search_tasks\", \"tool_output\": \"Action: search tasks (3 results)\\nResult: id: t1, title: 'Code Refactoring', time_spent: 15, date: '2026-03-09'\\nid: t2, title: 'Client Meeting', time_spent: 5, date: '2026-03-09'\\nid: t3, title: 'UI Design', time_spent: 10, date: '2026-03-10'\"}]"
        validator_reasoning "The step was successful. Proceed to the next step."
        messages []
    }
}

test TestResponsor_CRUDText {
    functions [Responsor]
    args {
        query "Create a new task called 'Weekend Plan'."
        context "[SYSTEM]\ncurrent_time: 2026-03-11 06:30:00 UTC\npersona: Levigo."
        plan "{\n  \"reasoning\": \"The user wants to create a task.\",\n  \"steps\": [\n    {\n      \"step\": 1,\n      \"description\": \"Create task 'Weekend Plan'.\"\n    }\n  ]\n}"
        tool_history "[{\"tool_name\": \"create_task\", \"tool_output\": \"TOOL EXECUTION RESULT: created task 'Weekend Plan'\"}]"
        validator_reasoning "Task was created successfully."
        messages []
    }
}

test TestResponsor_CategoryPieChart {
    functions [Responsor]
    args {
        query "Show me a pie chart comparing how many tasks I have completed vs how many I still need to do."
        context "[SYSTEM]\ncurrent_time: 2026-03-11 06:30:00 UTC\npersona: Levigo."
        plan "{\n  \"reasoning\": \"The user wants a categorical breakdown of task statuses.\",\n  \"steps\": [\n    {\n      \"step\": 1,\n      \"description\": \"Count tasks by completion status (is_completed).\"\n    }\n  ]\n}"
        tool_history "[{\"tool_name\": \"search_tasks\", \"tool_output\": \"Action: search tasks (5 results)\\nResult: id: t1, is_completed: true\\nid: t2, is_completed: false\\nid: t3, is_completed: true\\nid: t4, is_completed: false\\nid: t5, is_completed: false\"}]"
        validator_reasoning "Data retrieved successfully."
        messages []
    }
}

