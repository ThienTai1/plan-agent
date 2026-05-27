// ── Execution Pipeline (Planner -> Executor -> Validator) ────────

function Planner(input: PlannerInput) -> Plan { 
    client FallbackClient
    prompt #"
        {{ _.role("system") }}
        
        YOUR ROLE IN THE PIPELINE:
        You are the PLANNER in a chain: SPECIALIST ({{ input.specialist_name }}) → YOU → EXECUTOR.
        - The SPECIALIST has already analyzed the user's intent and provided a Blueprint with an objective and expert insights.
        - YOUR job is to convert that objective into a conrete, step-by-step plan using ONLY the ALLOWED TOOLS.
        - The EXECUTOR will pick exactly ONE tool per step and execute it.

        CONTEXT:
        {{ input.context }}

        {% if input.tool_results %}
        PREVIOUS TOOL RESULTS (History of what has been done so far):
        {{ input.tool_results }}
        {% endif %}
        
        {% if input.blueprint %}
        SPECIALIST {{ input.specialist_name }}:
        {% if input.blueprint.objective %}Objective: {{ input.blueprint.objective }}{% endif %}
        {% if input.blueprint.thought %}Expert Insight: {{ input.blueprint.thought }}{% endif %}
        {% endif %}
        
        ALLOWED TOOLS:
        {{ input.allowed_tools }}

        INSTRUCTIONS:
        1. Read the SPECIALIST ANALYSIS to understand the ultimate goal and any expert warnings.
        2. Analyze the CONVERSATION HISTORY and CONTEXT (which includes previous tool results):
           - START: If no steps have been executed, create a full sequence to achieve the objective.
           - RE-PLAN: If a previous step failed or the situation changed, analyze the failure and adjust the remaining steps.
           - SKIP REDUNDANT: If a step's goal is ALREADY satisfied by the results in the CONTEXT, DO NOT include that step in the plan.
        3. Break down the objective into atomic, executable steps (e.g., Search → Analyze → Mutate).
        4. Each step MUST map to exactly ONE tool from the ALLOWED TOOLS list.
        5. Provide specific details in step descriptions (IDs, dates, parameters) so the Executor knows exactly what to do.
        6. PROACTIVE DISAMBIGUATION: If you suspect that a search might return multiple results or that the objective is slightly underspecified, design the initial steps to "Identify and Disambiguate". For example: 'Search for meetings matching "Boss" and wait for user selection if multiple results occur.'
        7. FULL CHAINS: For creation or update requests that require verification (e.g., 'Check then Create' or 'Verify existence'), ALWAYS provide the full sequence of steps (e.g., Search -> Create) in the same plan. Do NOT omit the action step because it is conditional on the search result.

        OUTPUT FORMAT:
        {{ ctx.output_format }}
    "#
}

test TestComplexPlanner {
    functions [Planner]
    args {
        input {
            context #"
                current time: Monday, 09/03/2026
            "#
            specialist_name "MANAGEMENT"
            tool_results []
            allowed_tools ["search_tasks", "update_task", "create_task"]
            blueprint {
                objective "Create a new task with the title 'Buy milk' scheduled for tomorrow morning."
                thought "The user specified 'tomorrow morning'. I will assume this means 09:00 AM tomorrow. The current date is 09/03/2026, so 'tomorrow' will be 10/03/2026. The planner should confirm the exact time or use a default if a more specific time is not provided."
            }
        }
    }
}

test TestPlannerAmbiguity {
    functions [Planner]
    args {
        input {
            query "Update meeting with Boss"
            context ""
            specialist_name "MANAGEMENT"
            blueprint {
                objective "Update the title of the next meeting with 'Boss' to 'Project Sync'"
            }
            tool_results []
            allowed_tools ["search_events", "update_task"]
        }
    }
}


function Executor(input: ExecutorInput) -> StepExecution {
    client FallbackClient
    prompt #"
        {{ _.role("system") }}

        CONTEXT:
        {{ input.context }}

        {# {% if input.tool_results %}
        PREVIOUS TOOL RESULTS:
        {{ input.tool_results }}
        {% endif %} #}

        TARGET STEP:
        {{ input.step_description }}
        
        ALLOWED TOOLS:
        {{ input.allowed_tools }}

        OUTPUT FORMAT:
        {{ ctx.output_format }}

        1. MANDATORY RULE: If the TARGET STEP describes a search, creation, update, or deletion, you MUST select the appropriate tool UNLESS your reasoning determines that the action is ALREADY satisfied (e.g., search already found the item, item already updated).
        2. If the objective is satisfied, do NOT select a tool. Explain why in the `thought` field and return `null` for `tool_call`.
        3. Use the `thought` field to explain your reasoning before selecting the tool and populating its fields.
        4. Populate parameters using the IDs, dates, and names found in the CONTEXT.
        5. If the step is dependent on a previous result, extract the correct ID.
    "#
}

test test_executor {
    functions [Executor]
    type_builder {
        class CreateTask {
            title string
            dueDate string?
            priority string?
            is_completed bool?
        }
        
        class SearchTasks {
            keyword string?
            is_completed bool?
        }

        class SearchEvents {
            start_time string
            end_time string
        }

        dynamic class DynamicTool {
            create_task CreateTask?
            search_tasks SearchTasks?
            search_events SearchEvents?
        }
    }
    args {
        input {
            context "[DATABASE STATE]\n- Task 1: Buy milk (is_completed=true)\n- Task 2: Learn BAML (is_completed=false)\n- Current Time: 2026-03-09"
            step_description "Search for completed tasks to analyze productivity."
            tool_results []
            allowed_tools ["search_tasks", "create_task"]
        }
    }
}



function Validator(input: ValidatorInput) -> ValidationResult {
    client FallbackClient
    prompt #"
        {{ _.role("system") }}

        CONTEXT:
        {{ input.context }}

        PLAN:
        {{ input.plan }}

        CURRENT STEP (Index):
        {{ input.current_step }}

        {%if input.tool_results%}
        {% for result in input.tool_results %}
        EXECUTED ACTION: {{ result.tool_name}}
        ACTION INPUT: {{ result.tool_input}}
        ACTION OUTPUT: {{ result.tool_output }}
        {% endfor %}
        {%endif%}

        OUTPUT FORMAT:
        {{ ctx.output_format }}

        DECISION RULES:
        1. PASS: Action succeeded. Proceed to the next logical step in the plan. (Dont reasoning).
        2. AMBIGUOUS: The tool returned multiple results or ambiguous data. (Explain the OPTIONS in reasoning).
        3. RETRY: The action failed (e.g., syntax error) but can be corrected. (Explain the ERROR and FIX in reasoning).
        4. REPLAN: The current plan is no longer valid due to unexpected results. (Explain WHY in reasoning).
        5. FAIL: Action failed terminally (e.g., item not found). (Explain WHY in reasoning).

        INSTRUCTIONS:
        1. Evaluate the EXECUTED ACTION's output against the CURRENT STEP and the overall PLAN.
        2. If the tool output is a success, check if it satisfies the step's goal. If yes, choose PASS.
            * CRITICAL ANTI-LOOP RULE: If the goal was to "find", "search", or "check for" items, and the tool executed correctly but returned "0 results" or empty data, this IS a SUCCESSFUL execution. You MUST choose PASS. 
            * DO NOT choose REPLAN or RETRY just because the data is empty. Data being empty is a valid answer.
            * Choose PASS and let the Supervisor or Responsor handle the empty result.
        3. If the tool output contains multiple choices or is unclear (for a modification/deletion task), choose AMBIGUOUS and list the OPTIONS.
        4. If the tool failed due to a fixable error (e.g., bad date format), choose RETRY and explain the fix.
        5. If the current plan is no longer viable (e.g., trying to read an ID that doesn't exist), choose REPLAN or FAIL.
        
        CRITICAL: For PASS, `reasoning` MUST be null. For all other decisions, `reasoning` is MANDATORY.
    "#
}

test TestValidatorSuccess {
    functions [Validator]
    args {
        input {
            context "current time: 09/03/2026"
            plan {
                reasoning "Search for the meeting first, then update it."
                steps [
                    { step: 1, description: "Search for meetings on 10/03/2026" },
                    { step: 2, description: "Update the meeting with ID ev_1 to 17/03/2026" }
                ]
            }
            current_step 1
            tool_results [
                {
                    tool_name: "search_events"
                    tool_input: []
                    tool_output: #"[ { "id": "ev_1", "title": "1:1 with Boss", "start": "10/03/2026 10:00" } ]"#
                }
            ]
        }
    }
}

test TestValidatorAmbiguity {
    functions [Validator]
    args {
        input {
            context "current time: 09/03/2026"
            plan {
                reasoning "Find the meeting ID first."
                steps [{ step: 1, description: "Search for meetings with 'Boss'" }]
            }
            current_step 1
            tool_results [
                {
                    tool_name: "search_events"
                    tool_input: []
                    tool_output: #"[ { "id": "ev_1", "title": "Boss Alpha" }, { "id": "ev_2", "title": "Boss Beta" } ]"#
                }
            ]
        }
    }
}

test TestValidatorRetry {
    functions [Validator]
    args {
        input {
            context ""
            plan {
                reasoning "Check meetings."
                steps [{ step: 1, description: "Search for meetings" }]
            }
            current_step 1
            tool_results [
                {
                    tool_name: "search_events"
                    tool_input: []
                    tool_output: "Error: Invalid date format. Expected YYYY-MM-DD."
                }
            ]
        }
    }
}

test TestValidatorFail {
    functions [Validator]
    args {
        input {
            context "current time: 09/03/2026"
            plan {
                reasoning "Update the specific task."
                steps [{ step: 1, description: "Mark task 't_999' as completed (is_completed=true)" }]
            }
            current_step 1
            tool_results [
                {
                    tool_name: "update_task"
                    tool_input: []
                    tool_output: "Error: Task with ID 't_999' not found."
                }
            ]
        }
    }
}
test TestValidatorReplan {
    functions [Validator]
    args {
        input {
            context "current time: 09/03/2026"
            plan {
                reasoning "Search for the task 'Update Website' and mark it as DONE."
                steps [
                    { step: 1, description: "Search for task 'Update Website'" },
                    { step: 2, description: "Mark task 't_456' as completed (is_completed=true)" }
                ]
            }
            current_step 1
            tool_results [
                {
                    tool_name: "search_tasks"
                    tool_input: []
                    tool_output: "Task 'Update Website' not found, but found task 'Fix Website' with ID 't_789'."
                }
            ]
        }
    }
}


function ExecuteTool(query: string) -> StepExecution {
    client FallbackClient
    prompt #"
    You are a tool executor.


    {{ctx.output_format}}

    {{ _.role("user") }}
    USER: {{ query }}

    "#
}


test TestExecuteTool {
    functions [ExecuteTool]
    type_builder {
        class CreateTask {
            title string
            dueDate string?
            priority string?
            is_completed bool?
        }
        
        class SearchTasks {
            keyword string?
            is_completed bool?
        }

        class SearchEvents {
            start_time string
            end_time string
        }

        dynamic class DynamicTool {
            create_task CreateTask?
            search_tasks SearchTasks?
            search_events SearchEvents?
        }
    }
    args {
        query "Search for meetings on 10/03/2026"
    }
}