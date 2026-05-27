# Agent Service

LLM-backed orchestration engine that translates user goals into actionable steps and tool calls.  The FastAPI surface under `app/api/routes.py` is intentionally small: create plans and respond with the generated workflow.

## Local development

```bash
uv sync
uv run uvicorn app.main:app --reload --port 8100
```

The planning logic lives in `app/agent/engine.py` while each external dependency is wrapped inside `app/services` so it can be swapped out later.

### BAML + LangGraph

- Define your `.baml` specifications (see `baml_src/`) and run `baml-cli generate` from this directory so the `baml_client` module is created.  The runtime orchestrates via `ManagerOrchestrator`, which routes to the `PlanningGoalAgent`, `PlanningTaskAgent`, or `PlanningEventAgent` defined in the BAML sources.
- The LangGraph pipeline (`app/agent/workflow.py`) consumes the structured output from those agents and enriches it with calendar/task tools.
