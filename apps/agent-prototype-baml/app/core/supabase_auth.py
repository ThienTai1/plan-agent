from jose import jwt, JWTError
from fastapi import HTTPException, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import Optional, Dict, Any
import os
import logging

logger = logging.getLogger(__name__)

security = HTTPBearer()

def get_jwt_secret() -> str:
    """Get JWT secret from Supabase project settings."""
    secret = os.getenv("SUPABASE_JWT_SECRET")
    if not secret:
        logger.warning("SUPABASE_JWT_SECRET not set, token verification will fail")
        return ""
    return secret

import requests
from functools import lru_cache

@lru_cache(maxsize=1)
def get_supabase_jwks() -> dict:
    """Fetch public keys from Supabase JWKS endpoint."""
    url = os.getenv("SUPABASE_URL")
    if not url:
        logger.error("SUPABASE_URL not set, cannot fetch JWKS")
        return {}
        
    # Supabase provides public keys at this endpoint
    jwks_url = f"{url}/auth/v1/.well-known/jwks.json"
    try:
        response = requests.get(jwks_url, timeout=10)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        logger.error(f"Failed to fetch JWKS from {jwks_url}: {e}")
        return {}

def verify_supabase_token(token: str) -> Optional[Dict[str, Any]]:
    """
    Verify Supabase JWT token.
    
    Returns:
        User payload if valid, None otherwise
    """
    try:
        # Debugging the token header
        unverified_header = jwt.get_unverified_header(token)
        alg = unverified_header.get("alg")
        
        if alg in ["RS256", "ES256"]:
            # Use JWKS for asymmetric algorithms
            jwks = get_supabase_jwks()
            if not jwks:
                logger.error("No JWKS available for token verification")
                return None
                
            payload = jwt.decode(
                token,
                jwks,
                algorithms=[alg],
                audience="authenticated"
            )
            return payload
        else:
            # Fallback to symmetric algorithm with secret
            payload = jwt.decode(
                token,
                get_jwt_secret(),
                algorithms=["HS256"],
                audience="authenticated"
            )
            return payload
            
    except JWTError as e:
        logger.warning(f"JWT verification failed: {e}")
        return None

def get_current_user(
    credentials: HTTPAuthorizationCredentials = Security(security)
) -> Dict[str, Any]:
    """
    FastAPI dependency to get current user from JWT.
    
    Usage:
        @app.get("/protected")
        def protected_route(user: dict = Depends(get_current_user)):
            user_id = user["sub"]
            ...
    """
    token = credentials.credentials
    user = verify_supabase_token(token)
    
    if not user:
        raise HTTPException(
            status_code=401,
            detail="Invalid or expired token"
        )
    
    return user

def get_optional_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Security(
        HTTPBearer(auto_error=False)
    )
) -> Optional[Dict[str, Any]]:
    """Optional authentication - returns None if no token."""
    if not credentials:
        return None
    
    return verify_supabase_token(credentials.credentials)
