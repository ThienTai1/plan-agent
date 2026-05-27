from typing import Any, Dict
from datetime import datetime

def baml_search_to_filters(search_obj: Any) -> Dict[str, Any]:
    """
    Convert BAML TaskSearch/EventSearch objects to BaseRepository filter format.
    
    Input example (BAML):
    {
        "title": "Meeting",
        "period_time": {
            "start_time": {"operator": "gte", "value": "2025-12-25T00:00:00Z"},
            "due_date": {"operator": "lt", "value": "2025-12-31T23:59:59Z"}
        },
        "status": ["TODO", "IN_PROGRESS"]
    }
    
    Output (Repository filters):
    {
        "title": "Meeting",
        "start_time__gte": "2025-12-25T00:00:00Z",
        "due_date__lt": "2025-12-31T23:59:59Z",
        "status__in": ["TODO", "IN_PROGRESS"]
    }
    """
    filters = {}
    
    # Convert to dict if Pydantic model
    if hasattr(search_obj, "model_dump"):
        data = search_obj.model_dump(exclude_none=True)
    elif hasattr(search_obj, "dict"):
        data = search_obj.dict(exclude_none=True)
    else:
        data = search_obj if isinstance(search_obj, dict) else {}
    
    for key, value in data.items():
        if value is None:
            continue
            
        # Handle period_time (nested StartTime, DueDate, EndTime)
        if key == "period_time":
            if isinstance(value, dict):
                for time_field, time_obj in value.items():
                    if time_obj and isinstance(time_obj, dict):
                        operator = time_obj.get("operator", "eq")
                        time_value = time_obj.get("value")
                        if time_value:
                            # Always use operator suffix for datetime fields to avoid ILIKE
                            # Map: start_time + operator "gte" -> start_time__gte
                            # Even for "eq", use __eq to ensure proper datetime comparison
                            filter_key = f"{time_field}__{operator}"
                            filters[filter_key] = time_value
        
        # Handle time_range_query (OVERLAPS, WITHIN, etc.)
        elif key == "time_range_query":
            if isinstance(value, dict):
                query_type = value.get("type")
                range_start = value.get("range_start")
                range_end = value.get("range_end")
                
                # Map different query types to SQL conditions
                if query_type == "OVERLAPS":
                    # Event overlaps if: event.start < range_end AND event.end > range_start
                    if range_start:
                        filters["end_time__gt"] = range_start
                    if range_end:
                        filters["start_time__lt"] = range_end
                        
                elif query_type == "WITHIN":
                    # Event is within range: event.start >= range_start AND event.end <= range_end
                    if range_start:
                        filters["start_time__gte"] = range_start
                    if range_end:
                        filters["end_time__lte"] = range_end
                        
                elif query_type == "STARTS_IN":
                    # Event starts in range: event.start >= range_start AND event.start < range_end
                    if range_start:
                        filters["start_time__gte"] = range_start
                    if range_end:
                        filters["start_time__lt"] = range_end
                        
                elif query_type == "ENDS_IN":
                    # Event ends in range: event.end > range_start AND event.end <= range_end
                    if range_start:
                        filters["end_time__gt"] = range_start
                    if range_end:
                        filters["end_time__lte"] = range_end
        
        # Handle list fields (status, priority) -> use __in operator
        elif isinstance(value, list):
            if len(value) == 1:
                filters[key] = value[0]  # Single value, use equality
            elif len(value) > 1:
                filters[f"{key}__in"] = value  # Multiple values, use IN
        
        # Handle simple fields (title, duration, rrule)
        else:
            filters[key] = value
    
    return filters
