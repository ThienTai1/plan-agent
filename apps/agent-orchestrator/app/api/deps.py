"""
DEPS.PY - Dependencies.
Manages common objects such as Database (Supabase), User Authentication (Auth), 
and security configurations for the API.
"""
import httpx
from jose import jwt, JWTError
from fastapi import Header, HTTPException, Depends
from app.config import settings
from loguru import logger
from typing import Dict, Any, Optional, List

# Constants for JWT
ALLOWED_ALGORITHMS = ["HS256", "RS256", "ES256"]
JWKS_URL = f"{settings.SUPABASE_URL.rstrip('/')}/auth/v1/.well-known/jwks.json"

# Cache for JWKS keys to avoid frequent network calls
_jwks_cache: Dict[str, Any] = {}

async def get_jwks_keys() -> List[Dict[str, Any]]:
    """Fetches the public keys from Supabase JWKS endpoint."""
    global _jwks_cache
    if _jwks_cache:
        return _jwks_cache.get("keys", [])

    try:
        async with httpx.AsyncClient() as client:
            # Supabase API Gateway (Kong) requires apikey header even for public auth endpoints
            headers = {"apikey": settings.SUPABASE_KEY}
            response = await client.get(JWKS_URL, headers=headers)
            response.raise_for_status()
            data = response.json()
            _jwks_cache = data
            logger.info("✅ Fetched JWKS keys from Supabase")
            return _jwks_cache.get("keys", [])
    except Exception as e:
        logger.error(f"❌ Failed to fetch JWKS keys: {str(e)}")
        return []

async def get_current_user(authorization: str = Header(None)):
    """
    Verifies the Supabase JWT token from the Authorization header.
    Supports both HS256 (Legacy secret) and ES256 (ECC Public Key).
    """
    if not authorization:
        logger.warning("🚫 Authorization header missing")
        raise HTTPException(status_code=401, detail="Authorization header missing")
    
    if not authorization.startswith("Bearer "):
        logger.warning("🚫 Invalid authorization format (must be Bearer)")
        raise HTTPException(status_code=401, detail="Invalid authorization format")

    token = authorization.replace("Bearer ", "")
    
    try:
        # Step 1: Inspect the header (unverified) to see the alg and kid
        try:
            header = jwt.get_unverified_header(token)
            token_alg = header.get("alg")
            token_kid = header.get("kid")
            logger.debug(f"🔑 Verifying JWT with alg: {token_alg}, kid: {token_kid}")
        except Exception as e:
            logger.error(f"❌ Failed to parse JWT header: {str(e)}")
            raise HTTPException(status_code=401, detail="Invalid token format")

        # Step 2: Determine verification key
        verification_key = settings.SUPABASE_JWT_SECRET
        
        if token_alg == "ES256":
            # For ECC, we need the public key from JWKS
            keys = await get_jwks_keys()
            # If we have a kid, find the specific key, otherwise just try the keys
            # (Supabase usually has one active key at a time in JWKS)
            if token_kid:
                key_match = next((k for k in keys if k.get("kid") == token_kid), None)
                if key_match:
                    verification_key = key_match
                else:
                    logger.warning(f"⚠️ Kid {token_kid} not found in JWKS, trying all keys...")
                    verification_key = keys # jose can take the list
            else:
                verification_key = keys

        # Step 3: Decode and verify
        payload = jwt.decode(
            token, 
            verification_key, 
            algorithms=ALLOWED_ALGORITHMS, 
            options={"verify_aud": False} 
        )
        
        user_id = payload.get("sub")
        if not user_id:
            logger.error("🚫 JWT payload missing 'sub' claim")
            raise HTTPException(status_code=401, detail="Invalid token: missing subject")
            
        return user_id
        
    except JWTError as e:
        logger.error(f"❌ JWT Verification Error: {str(e)}")
        raise HTTPException(status_code=401, detail=f"Invalid token: {str(e)}")
