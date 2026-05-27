from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # CORS Settings
    CORS_ORIGINS: list[str] = Field(default_factory=lambda: ["*"])
    CORS_METHODS: list[str] = Field(
        default_factory=lambda: ["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"]
    )
    CORS_HEADERS: list[str] = Field(default_factory=lambda: ["*"])
    CORS_CREDENTIALS: bool = True
    database_url: str = Field(default="", alias="DATABASE_URL")


    class Config:
        env_file = ".env"
        case_sensitive = True
        extra = "ignore"


class LLMSettings(Settings):
    SUPERVISOR_MODEL_NAME: str = "gemini-2.5-flash"
    RECEPTIONIST_MODEL_NAME: str = "gemini-2.5-flash"
    FOLLOW_UP_MODEL_NAME: str = "gemini-2.0-flash-lite"
    COPYWRITING_MODEL_NAME: str = "gemini-2.0-flash"

    GEMINI_API_KEY: str
    LITE_LLM_API_KEY: str
    MAX_HISTORY_TURNS: int = 12


@lru_cache
def get_settings() -> Settings:
    """Get cached settings instance"""
    return Settings()


@lru_cache
def get_llm_settings() -> LLMSettings:
    """Get cached LLM settings instance"""
    return LLMSettings()
