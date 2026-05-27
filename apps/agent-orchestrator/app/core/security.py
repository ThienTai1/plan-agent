"""
SECURITY.PY - Rate Limiting and Input Sanitization.
Uses slowapi to prevent spam and sanitization steps to block Prompt Injection.
"""
from slowapi import Limiter
from slowapi.util import get_remote_address
from fastapi import Request, HTTPException
from loguru import logger

def limit_key_func(request: Request) -> str:
    """
    Identity function for applying Rate limits.
    If the user is logged in, limit by user_id. 
    Otherwise, fallback to the device's IP address.
    """
    user = getattr(request.state, "user", None)
    if user and user.get("sub"):
        return user["sub"]
    return get_remote_address(request)

# Initialize SlowAPI Limiter
limiter = Limiter(key_func=limit_key_func)


def sanitize_input(query: str) -> str:
    """
    Sanitize the user query before passing it to the Agent.
    """
    # 1. Maximum length constraint
    if len(query) > 5000:
        logger.warning("Input blocked for being too long (>5000 characters)")
        raise HTTPException(status_code=400, detail="Query is too long.")

    query_lower = query.lower()

    # 2. Prevent basic and advanced Prompt Injection / Jailbreaks
    forbidden_phrases = [
        "ignore previous instructions",
        "ignore all previous instructions",
        "system prompt",
        "ignore guidelines",
        "override system",
        "you are now",
        "act as",
        "forget your instructions",
        "disregard all previous",
        "developer mode",
        "jailbreak",
        "DAN mode",
        "stay out of character",
        "bypass rules"
    ]

    for phrase in forbidden_phrases:
        if phrase in query_lower:
            logger.warning(f"🚨 Prompt Injection detected with keyword: '{phrase}'")
            raise HTTPException(status_code=400, detail="Invalid input detected.")

    return query.strip()
