from google import genai
from typing import List
from app.config.settings import get_llm_settings
from loguru import logger

class EmbeddingService:
    def __init__(self):
        settings = get_llm_settings()
        # Initialize the Google GenAI client
        self.client = genai.Client(api_key=settings.GEMINI_API_KEY)
        self.model = "text-embedding-004" # 768 dimensions

    def get_embedding(self, text: str) -> List[float]:
        try:
            if not text:
                return []
            result = self.client.models.embed_content(
                model=self.model,
                contents=text,
                config={
                    "task_type": "RETRIEVAL_DOCUMENT"
                }
            )
            # The new SDK returns a list of embeddings
            return result.embeddings[0].values
        except Exception as e:
            logger.error(f"Error generating embedding: {e}")
            return []

    def get_query_embedding(self, query: str) -> List[float]:
        try:
            result = self.client.models.embed_content(
                model=self.model,
                contents=query,
                config={
                    "task_type": "RETRIEVAL_QUERY"
                }
            )
            return result.embeddings[0].values
        except Exception as e:
            logger.error(f"Error generating query embedding: {e}")
            return []
