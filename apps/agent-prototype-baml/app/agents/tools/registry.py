"""
Tool Registry — Decorator-based tool registration with BAML TypeBuilder integration.

Usage:
    from app.agents.tools.registry import tool, tool_registry

    @tool("create_task", "Create a new task for the user")
    def create_task(user_id: str, title: str, description: str = None) -> dict:
        ...

    # Build a BAML TypeBuilder with all registered tool schemas
    tb = tool_registry.build_type_builder()
    result = await baml_client.WorkerExecutor(step, blueprint, state, {"tb": tb})

    # Execute a tool by name
    result = tool_registry.execute("create_task", {"user_id": "...", "title": "Buy milk"})
"""

import inspect
import json
import typing
from typing import Callable, Dict, Any, get_origin, get_args

from pydantic.fields import FieldInfo


class ToolDefinition:
    """A registered tool with its metadata and schema."""

    def __init__(self, name: str, description: str, func: Callable, schema: Dict[str, Any]):
        self.name = name
        self.description = description
        self.func = func
        self.schema = schema  # param_name -> {type, description, is_required}

    def __repr__(self) -> str:
        params = ", ".join(
            f"{k}: {v['type']}{'?' if not v['is_required'] else ''}"
            for k, v in self.schema.items()
        )
        return f"Tool({self.name}({params}))"


class ToolRegistry:
    """
    Singleton registry for tool functions.
    
    Tools are registered via the @tool decorator:
        @tool("tool_name", "Description of the tool")
        def my_tool(param1: str, param2: int = 0) -> dict: ...
    """

    def __init__(self):
        self._tools: Dict[str, ToolDefinition] = {}

    def register(self, name: str, description: str):
        """Decorator to register a tool function."""
        def decorator(func: Callable):
            schema = self._parse_signature(func)
            self._tools[name] = ToolDefinition(name, description, func, schema)
            return func
        return decorator

    def get_tool(self, name: str) -> ToolDefinition | None:
        return self._tools.get(name)

    def get_all_tools(self) -> Dict[str, ToolDefinition]:
        return self._tools

    def get_tool_names(self) -> list[str]:
        return list(self._tools.keys())

    def execute(self, name: str, args: Dict[str, Any]) -> Any:
        """Execute a registered tool by name with the given arguments."""
        tool_def = self._tools.get(name)
        if not tool_def:
            return {"status": "error", "message": f"Unknown tool: {name}"}

        # Filter args to only include valid parameters
        sig = inspect.signature(tool_def.func)
        valid_params = set(sig.parameters.keys())
        filtered_args = {k: v for k, v in args.items() if k in valid_params}

        try:
            return tool_def.func(**filtered_args)
        except Exception as e:
            return {"status": "error", "message": f"Tool execution error: {str(e)}"}

    def build_type_builder(self, tb: Any, allowed_tools: list[str] | None = None):
        """
        Populate an existing BAML TypeBuilder with dynamic classes for each tool's parameters.
        """
        from loguru import logger
        # Filter tools
        tools_to_include = {
            name: defn for name, defn in self._tools.items()
            if allowed_tools is None or name in allowed_tools
        }

        print(f"DEBUG [registry]: Building TypeBuilder with {len(tools_to_include)} tools")

        for name, defn in tools_to_include.items():
            param_class_name = "".join(x.capitalize() for x in name.split("_")) + "Params"
            
            try:
                param_cls = tb.add_class(param_class_name)
            except Exception:
                try:
                    param_cls = getattr(tb, param_class_name)
                except AttributeError:
                    continue
            
            for param_name, param_info in defn.schema.items():
                ptype = param_info.get("type", "string")
                if ptype == "int":
                    baml_type = tb.int()
                elif ptype == "float":
                    baml_type = tb.float()
                elif ptype == "bool":
                    baml_type = tb.bool()
                else:
                    baml_type = tb.string()
                
                if not param_info.get("is_required", True):
                    baml_type = baml_type.optional()
                
                prop = param_cls.add_property(param_name, baml_type)
                if param_info.get("description"):
                    prop.description(param_info["description"])

            # Link to DynamicTool and CallTool
            for target in ["DynamicTool", "CallTool"]:
                try:
                    try:
                        target_cls = getattr(tb, target)
                    except AttributeError:
                        target_cls = tb.add_class(target)
                    
                    target_cls.add_property(name, param_cls.type().optional())
                    print(f"DEBUG [registry]: Registered {name} into {target}")
                except Exception as e:
                    logger.warning(f"Could not add {name} to {target}: {str(e)}")

        return tb

    def get_tools_description(self, allowed_tools: list[str] | None = None) -> str:
        """
        Get a human-readable description of all tools and their schemas.
        Useful for injecting into prompts directly.
        """
        tools = {
            name: defn for name, defn in self._tools.items()
            if allowed_tools is None or name in allowed_tools
        }

        lines = []
        for name, defn in tools.items():
            lines.append(f"• {name}: {defn.description}")
            for param_name, param_info in defn.schema.items():
                req = "required" if param_info["is_required"] else "optional"
                desc = f" — {param_info['description']}" if param_info["description"] else ""
                lines.append(f"    - {param_name} ({param_info['type']}, {req}){desc}")
        
        return "\n".join(lines)

    def _parse_signature(self, func: Callable) -> Dict[str, Any]:
        """
        Introspect the function signature and create a schema representation.
        Supports standard Python types and Pydantic Field descriptions.
        """
        sig = inspect.signature(func)
        type_hints = typing.get_type_hints(func, include_extras=True)
        schema = {}

        for param_name, param in sig.parameters.items():
            if param_name in ('self', 'cls', 'user_id') or param.kind in (
                inspect.Parameter.VAR_KEYWORD, inspect.Parameter.VAR_POSITIONAL
            ):
                continue

            annotation = type_hints.get(param_name, param.annotation)
            if annotation == inspect.Parameter.empty:
                annotation = str

            # Extract description from Annotated[Type, Field(...)]
            description = ""
            if get_origin(annotation) is typing.Annotated:
                metadata = get_args(annotation)
                for item in metadata:
                    if isinstance(item, FieldInfo):
                        description = item.description or ""
                        break
                base_type = get_args(annotation)[0]
            else:
                base_type = annotation
                if isinstance(param.default, FieldInfo):
                    description = param.default.description or ""

            # Handle Optional / Union with None
            is_optional = False
            origin = get_origin(base_type)
            if origin is not None:
                if origin is typing.Union or (
                    hasattr(typing, "UnionType") and isinstance(base_type, typing.UnionType)
                ):
                    args = get_args(base_type)
                    if type(None) in args:
                        is_optional = True
                        base_type = next(a for a in args if a is not type(None))

            # Map Python types to BAML type strings
            type_str = "string"
            if base_type == int:
                type_str = "int"
            elif base_type == float:
                type_str = "float"
            elif base_type == bool:
                type_str = "bool"

            is_required = not is_optional and (
                param.default == inspect.Parameter.empty
                or (isinstance(param.default, FieldInfo) and param.default.is_required())
            )

            schema[param_name] = {
                "type": type_str,
                "description": description,
                "is_required": is_required,
            }

        return schema


# ── Global singleton ──
tool_registry = ToolRegistry()

# Public decorator alias
tool = tool_registry.register
