"""
FACTORY.PY - LLM Factory.
This file contains a centralized function to initialize ChatOpenRouter 
with configurations such as API Key, Model name, Temperature, and necessary headers.
It ensures that the entire chatbot uses a single standardized connection method.
"""
from typing import Optional, List, Any, Dict
from langchain_openai import ChatOpenAI
from langchain_openrouter import ChatOpenRouter
from langchain_core.tools import StructuredTool
from app.config import settings, llm_settings
from app.tools.server_tools import create_all_server_tools

def _wrap_tool(tool: Any) -> Any:
    """Helper to wrap custom tools as LangChain StructuredTools."""
    if hasattr(tool, "arun") and hasattr(tool, "name"):
        # LangChain needs a sync or async function. 
        return StructuredTool.from_function(
            coroutine=tool.arun,
            name=tool.name,
            description=tool.description,
            args_schema=getattr(tool, "args_schema", None),
        )
    return tool

async def create_agent(
    model: str, 
    system_prompt: str, 
    tools: Optional[List[Any]] = None
) -> Dict[str, Any]:
    """
    Factory function to create an LLM with automated fallbacks.
    Returns a dictionary containing the runnable chain, system prompt, and tools.
    """
    # 1. Determine which fallback model to use based on the primary model
    if model == llm_settings.LLM_MODEL_ADVANCED:
        fallback_model_name = llm_settings.FALLBACK_MODEL_ADVANCED
    else:
        fallback_model_name = llm_settings.FALLBACK_MODEL_BASIC

    # 2. Initialize Primary Model (OpenRouter)
    processed_model = model.replace("openrouter:", "")
    primary_llm = ChatOpenRouter(
        model=processed_model,
        api_key=llm_settings.api_key,
        temperature=llm_settings.LLM_TEMPERATURE,
        max_tokens=llm_settings.LLM_MAX_TOKENS,
    )
    
    # 3. Initialize Fallback Model (OpenAI)
    fallback_llm = ChatOpenAI(
        model=fallback_model_name,
        api_key=llm_settings.OPENAI_API_KEY,
        temperature=llm_settings.LLM_TEMPERATURE,
        max_tokens=llm_settings.LLM_MAX_TOKENS,
    )
    
    # 4. Prepare Tools
    wrapped_tools = []
    if tools:
        wrapped_tools = [_wrap_tool(t) for t in tools]
        # Bind tools to BOTH models to ensure consistency in case of fallback
        primary_llm = primary_llm.bind_tools(wrapped_tools)
        fallback_llm = fallback_llm.bind_tools(wrapped_tools)
    
    # 5. Create the Fallback Chain
    # This runnable will automatically try primary_llm first, 
    # and switch to fallback_llm on error.
    llm_chain = primary_llm.with_fallbacks([fallback_llm])
    
    return {
        "llm": llm_chain, 
        "system_prompt": system_prompt, 
        "tools": wrapped_tools
    }

