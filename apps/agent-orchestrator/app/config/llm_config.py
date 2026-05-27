"""
LLM_CONFIG.PY - Specialized AI configuration.
This file defines models (Advanced and Basic) along with parameters 
like Temperature and Max Tokens. It allows for easy AI model 
adjustments without affecting other system configurations.
"""
from pydantic_settings import BaseSettings, SettingsConfigDict
import os


class LLMSettings(BaseSettings):
    """LLM and OpenRouter specific settings"""

    # Models
    LLM_MODEL_ADVANCED: str = os.getenv("LLM_MODEL_ADVANCED", "qwen/qwen3-max")
    LLM_MODEL_BASIC: str = os.getenv("LLM_MODEL_BASIC", "qwen/qwen-plus")
    
    # Legacy/Default model (for backward compatibility)
    LLM_MODEL: str = os.getenv("LLM_MODEL", "qwen/qwen-plus")
    
    # API Keys
    OPENROUTER_API_KEY: str = os.getenv("OPENROUTER_API_KEY", "")
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
    LLM_API_KEY: str = os.getenv("LLM_API_KEY", "")  # Fallback

    # Fallback Models
    FALLBACK_MODEL_ADVANCED: str = os.getenv("FALLBACK_MODEL_ADVANCED", "gpt-4o")
    FALLBACK_MODEL_BASIC: str = os.getenv("FALLBACK_MODEL_BASIC", "gpt-4o-mini")
    
    # Parameters
    LLM_TEMPERATURE: float = float(os.getenv("LLM_TEMPERATURE", "0.7"))
    LLM_MAX_TOKENS: int = int(os.getenv("LLM_MAX_TOKENS", "2000"))

    @property
    def api_key(self) -> str:
        """Get the effective API key (prefers OPENROUTER_API_KEY)"""
        return self.OPENROUTER_API_KEY or self.LLM_API_KEY

    @property
    def model_name(self) -> str:
        """Get cleaned model name without prefix"""
        return self.LLM_MODEL.replace("openrouter:", "")

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )

llm_settings = LLMSettings()
