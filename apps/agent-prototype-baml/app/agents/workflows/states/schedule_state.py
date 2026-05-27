from langgraph.graph.message import add_messages
from typing import TypedDict, Annotated, List, Optional, Literal, Union, Dict
import operator

from baml_client.types import SchedulerOutput, TaskSearchResult, EventSearchResult


class ScheduleState(TypedDict):
    """State for the Scheduler agent."""
    messages: Annotated[List[dict], add_messages]
    context: str
    scheduler_output: Literal[SchedulerOutput, str]
    output_search: List[Union[TaskSearchResult, EventSearchResult]]
    ref_index: Dict[int, str]
    # final_report: Optional[str]


# class OutputState(ScheduleState):
#     """State for the output of the Scheduler agent."""
#     output_search: str