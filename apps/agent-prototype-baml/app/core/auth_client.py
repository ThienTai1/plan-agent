"""HTTP client for auth-service."""
import logging
from typing import Optional, Dict, Any

from .http_client import ServiceClient

logger = logging.getLogger(__name__)


class AuthServiceClient(ServiceClient):
    """Client for communicating with auth-service."""
    
    def __init__(self, base_url: str, timeout: float = 10.0):
        """
        Initialize auth service client.
        
        Args:
            base_url: Base URL of the auth service (e.g., "http://auth-service:8200")
            timeout: Request timeout in seconds
        """
        super().__init__(
            base_url=base_url,
            timeout=timeout,
        )
    
    async def login(self, payload: Any) -> Dict[str, Any]:
        """
        Login and get access token.
        
        Args:
            payload: Login payload - can be a dict, Pydantic model, or object with username/password attributes.
                    Should have 'username' and 'password' fields.
            
        Returns:
            Token response dict with access_token and expires_at
        """
        # Convert payload to dict if it's a Pydantic model or has dict() method
        if hasattr(payload, "model_dump"):
            payload_dict = payload.model_dump()
        elif hasattr(payload, "dict"):
            payload_dict = payload.dict()
        elif isinstance(payload, dict):
            payload_dict = payload
        else:
            # Try to get username and password from attributes
            payload_dict = {
                "username": getattr(payload, "username", None),
                "password": getattr(payload, "password", None),
            }
        
        username = payload_dict.get("username")
        if not username:
            raise ValueError("Payload must contain 'username' field")
        
        logger.info("Issuing login request", extra={"user": username})
        try:
            response = await self.post(
                "/v1/auth/token",
                json={"username": payload_dict["username"], "password": payload_dict["password"]}
            )
            return response.json()
        except Exception as e:
            logger.error(f"Login failed: {e}")
            raise
    
    async def verify_token(self, token: str) -> Optional[Dict[str, Any]]:
        """
        Verify token with auth-service.
        
        Args:
            token: JWT token string
            
        Returns:
            User info dict if valid, None otherwise
        """
        try:
            response = await self.get(
                "/v1/auth/verify",
                headers={"Authorization": f"Bearer {token}"}
            )
            return response.json()
        except Exception as e:
            logger.warning(f"Token verification failed: {e}")
            return None
    
    async def get_user(self, user_id: str, token: str) -> Optional[Dict[str, Any]]:
        """
        Get user information from auth-service.
        
        Args:
            user_id: User ID
            token: JWT token for authentication
            
        Returns:
            User info dict or None
        """
        try:
            response = await self.get(
                f"/v1/users/{user_id}",
                headers={"Authorization": f"Bearer {token}"}
            )
            return response.json()
        except Exception as e:
            logger.warning(f"Failed to get user: {e}")
            return None

    async def create_user(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        """
        Create a new user in auth-service.
        
        Args:
            payload: User creation data (id, email, password, full_name, etc.)
            
        Returns:
            Created user info
        """
        logger.info("Issuing user creation request", extra={"email": payload.get("email")})
        try:
            response = await self.post(
                "/v1/users",
                json=payload
            )
            return response.json()
        except Exception as e:
            logger.error(f"User creation failed: {e}")
            raise
    
    async def me(self, token: str) -> Dict[str, str]:
        """
        Get current user info from token.
        
        Args:
            token: JWT token
            
        Returns:
            User info dict with id and email, or {"id": "unknown", "email": ""} if failed
        """
        try:
            user_info = await self.verify_token(token)
            if user_info:
                return {
                    "id": user_info.get("user_id", ""),
                    "email": user_info.get("email", ""),
                }
        except Exception as e:
            logger.warning(f"Failed to get user info: {e}")
        
        return {"id": "unknown", "email": ""}

