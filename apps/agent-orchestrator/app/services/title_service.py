import asyncio
from typing import Optional
from langchain_openai import ChatOpenAI
from langchain_openrouter import ChatOpenRouter
from langchain_core.messages import SystemMessage, HumanMessage
from app.config import llm_settings
from app.services.supabase_service import supabase_service
from loguru import logger

class TitleService:
    def __init__(self):
        self.llm = ChatOpenRouter(
            model="gpt-4o-mini", # Use a cheaper model for titles
            api_key=llm_settings.api_key,
            temperature=0.7,
        )

    async def generate_and_update_title(self, thread_id: str, first_message: Optional[str] = None) -> str:
        """
        Retrieves the first message, generates a title, and updates the database.
        """
        try:
            # 1. Use provided message or fetch from DB (with retry)
            if not first_message:
                for attempt in range(3):
                    first_message = await supabase_service.get_first_chat_message(thread_id)
                    if first_message:
                        break
                    logger.info(f"⏳ Message not found yet, retrying in 2.0s... (attempt {attempt+1}, thread: {thread_id})")
                    await asyncio.sleep(2.0)
            
            if not first_message:
                logger.warning(f"❌ Giving up: No first message found for title generation (thread: {thread_id})")
                return "New Conversation"

            # 2. Generate title using LLM
            prompt = """You are a professional summarizer.
Your task is to create an extremely concise title (3 to 5 words) for a conversation based on the user's first message.
The title must be concise, professional, and accurately reflect the main topic.
Do NOT use quotation marks, and do NOT use prefixes like 'Title:'. Only return the title content.
The title should be in Vietnamese if the user uses Vietnamese, and in English if the user uses English.
"""
            
            response = await self.llm.ainvoke([
                SystemMessage(content=prompt),
                HumanMessage(content=f"Message: {first_message}")
            ])
            
            title = response.content.strip()
            # Clean up unwanted characters
            title = title.replace('"', '').replace("'", "")
            
            # 3. Update DB
            await supabase_service.update_thread_title(thread_id, title)
            
            return title
        except Exception as e:
            logger.error(f"💥 Failed to generate title: {str(e)}")
            return "New Conversation"

title_service = TitleService()
