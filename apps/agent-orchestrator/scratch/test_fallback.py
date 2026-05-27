import asyncio
import os
from dotenv import load_dotenv

# Force load .env
load_dotenv(override=True)

# Mock llm_settings to use a BAD OpenRouter key
from app.config.llm_config import llm_settings

# Store original key
original_or_key = llm_settings.OPENROUTER_API_KEY
original_oa_key = llm_settings.OPENAI_API_KEY

async def test_fallback():
    from app.agent.factory import create_agent
    
    print("\n--- Testing LLM Fallback ---")
    
    # 1. Test with WRONG OpenRouter Key to force fallback
    # We set it to something invalid
    llm_settings.OPENROUTER_API_KEY = "sk-or-v1-invalid-key-to-trigger-fallback"
    
    print(f"Using Invalid OpenRouter Key: {llm_settings.OPENROUTER_API_KEY}")
    print(f"Using Valid OpenAI Key: {llm_settings.OPENAI_API_KEY[:10]}...")
    
    agent_data = await create_agent(
        model=llm_settings.LLM_MODEL_BASIC,
        system_prompt="You are a helpful assistant.",
        tools=[]
    )
    
    llm = agent_data["llm"]
    
    print("Sending message...")
    try:
        # LangChain's with_fallbacks will retry OpenRouter, fail, then try OpenAI
        response = await llm.ainvoke("Hi, please tell me which model you are using right now.")
        print("\n✅ Success! Response received.")
        print(f"Response Content: {response.content}")
        
        # Check if the response metadata mentions OpenAI/GPT
        print(f"Response Metadata: {response.response_metadata}")
        
    except Exception as e:
        print(f"\n❌ Fallback failed: {str(e)}")
    finally:
        # Restore original keys
        llm_settings.OPENROUTER_API_KEY = original_or_key

if __name__ == "__main__":
    asyncio.run(test_fallback())
