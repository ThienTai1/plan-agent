// This will be a place to create Agents to control the quality of the system's output

class QCTestCase {
    test_id string? @description("Optional identifier for the test case.")
    intent string @description("The initial user request or intent of the test.")
    expected_outcome string @description("What should have happened or been the final response.")
}

class QCWorkflowEvent {
    step_number int
    agent_name string @description("The name of the agent or component taking the action.")
    action string @description("The tool or action executed.")
    action_input string @description("The input parameters provided to the action.")
    action_output string @description("The result returned by the action.")
}

class QCInput {
    test_case QCTestCase
    workflow_events QCWorkflowEvent[]
    final_agent_response string
}

class AnomalyReport {
    step_number int? @description("The step number where the anomaly occurred, if applicable.")
    severity string @description("e.g., LOW, MEDIUM, HIGH, CRITICAL")
    issue_description string @description("Detailed explanation of what went wrong or seemed illogical.")
    suggested_fix string @description("How the agent should have behaved instead.")
}

class QCResult {
    is_valid bool @description("True if the workflow perfectly matched the expected outcome with no critical logic errors, false otherwise.")
    anomalies AnomalyReport[] @description("List of questionable actions, hallucinations, or deviations from the expected logic.")
    overall_evaluation string @description("A brief summary of the workflow execution quality.")
}

function EvaluateWorkflow(input: QCInput) -> QCResult {
    client LLMAsJudgeClient
    prompt #"
        {{ _.role("system") }}
        You are an expert Quality Control (QC) AI. Your task is to evaluate a sequence of actions taken by an AI system (Workflow Events) against a Ground Truth Test Case to determine if the system behaved logically and achieved the Expected Outcome.

        TEST CASE INTENT:
        {{ input.test_case.intent }}

        EXPECTED OUTCOME:
        {{ input.test_case.expected_outcome }}

        WORKFLOW EVENTS:
        {% for event in input.workflow_events %}
        --- STEP {{ event.step_number }} ---
        Agent: {{ event.agent_name }}
        Action: {{ event.action }}
        Action Input:
        {{ event.action_input }}
        Action Output:
        {{ event.action_output }}

        {% endfor %}

        FINAL RESPONSE DELIVERED TO USER:
        {{ input.final_agent_response }}

        INSTRUCTIONS:
        1. Read the Test Case Intent and Expected Outcome.
        2. Trace the sequence of Workflow Events step by step.
        3. Determine if each action is logical, necessary, and uses tools correctly.
        4. Identify any "anomalies":
           - Hallucinations or making up data.
           - Unnecessary repetitive loops or looping agent behavior.
           - Calling a tool with incorrect or arbitrary parameters.
           - Ignoring the context or previous tool outputs to answer.
           - The final response deviating from the Expected Outcome.
        5. Provide a detailed report of any anomalies found. If the workflow executed perfectly without issues, the anomalies list should be empty.

        Return your findings in the requested JSON format:
        {{ ctx.output_format }}
    "#
}
