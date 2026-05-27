"""
SETTINGS.PY - System configuration.
Contains all constants, environment variables, and Agent settings.
"""
import os
from typing import Dict, Any, List
from dotenv import load_dotenv

# Load environment variables with override to ensure .env changes are picked up on reload
load_dotenv(override=True)

class Settings:
    # App Info
    APP_NAME: str = "Levigo AI"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = os.getenv("DEBUG", "True").lower() == "true"
    
    # API Keys
    OPENROUTER_API_KEY: str = os.getenv("OPENROUTER_API_KEY", "")
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
    
    # Database
    SUPABASE_URL: str = os.getenv("SUPABASE_URL", "")
    SUPABASE_KEY: str = os.getenv("SUPABASE_KEY", "")
    SUPABASE_SERVICE_ROLE_KEY: str = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
    SUPABASE_JWT_SECRET: str = os.getenv("SUPABASE_JWT_SECRET", "")
    DATABASE_URL: str = os.getenv("DATABASE_URL", "") # Full Postgres connection string

    # Session & Auth
    SESSION_TIMEOUT: int = int(os.getenv("SESSION_TIMEOUT", "1800"))  # 30 minutes
    
    # Logging
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")
    
    # Agent Logic
    MAX_TOOL_ITERATIONS: int = int(os.getenv("MAX_TOOL_ITERATIONS", "5"))
    FRONTEND_URL: str = os.getenv("FRONTEND_URL", "*")

settings = Settings()
