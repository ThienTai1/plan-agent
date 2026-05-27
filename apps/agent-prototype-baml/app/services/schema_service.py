from baml_client.type_builder import TypeBuilder
from app.agents.tools.registry import tool_registry

async def sync_type_builder(tb: TypeBuilder):
    """Syncs the BAML TypeBuilder with the project schema by loading all tools."""
    # Ensure all tool modules are imported once so they register themselves
    import app.agents.tools.actions as _actions
    import app.agents.tools.schedule_tool as _schedule
    import app.agents.tools.supabase_tool as _supabase
    
    # Populate the provided TypeBuilder with registered tools
    tool_registry.build_type_builder(tb)
