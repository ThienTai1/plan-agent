// ══════════════════════════════════════════════════════════════════════
// WORKER MODELS
// ══════════════════════════════════════════════════════════════════════

// ── Execution Pipeline (Planner -> Executor -> Validator) ────────

class Step {
    step int
    description string
}

class Plan {
    reasoning string? @description("High-level thought process about the user's overall goal.")
    steps Step[] | null @description("A logic sequence of steps to fulfill the request.")
}

class ToolResult {
    tool_name string
    tool_input map<string, string>[]
    tool_output string
}

class PlannerInput {
    context string
    specialist_name string
    blueprint Blueprint
    tool_results ToolResult[]? // in case of replan
    allowed_tools string[]
}

class DynamicTool {
    @@dynamic
}

class StepExecution {
    thought string? @description("Expert reasoning for selecting this tool and how to populate its parameters.")
    tool_call DynamicTool? @description("The specific tool call to perform. MUST be provided if the step requires action.")
}

class ExecutorInput {
    context string
    step_description string
    // tool_results ToolResult[]?
    allowed_tools string[]
}

class ValidatorInput {
    context string
    plan Plan
    current_step int
    tool_results ToolResult[]?
}

enum ValidationDecision {
    PASS @description("The step was successful. Proceed to the next step.")
    RETRY @description("The step failed but can be retried with different parameters.")
    REPLAN @description("The plan is flawed. Re-planning is required.")
    AMBIGUOUS @description("The tool returned multiple or unclear results. Need user clarification.")
    FAIL @description("The step failed terminally and cannot be retried.")
}

class ValidationResult {
    reasoning string? @description("MANDATORY for RETRY, REPLAN, FAIL, AMBIGUOUS. Set to null for PASS.")
    decision ValidationDecision
}

class CallTool{
    @@dynamic
}
