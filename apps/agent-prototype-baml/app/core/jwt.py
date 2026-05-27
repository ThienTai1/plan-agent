"""
JWT utilities for authentication across services.
"""
from datetime import datetime, timedelta
from typing import Optional

from jose import JWTError, jwt


class JWTManager:
    """JWT token manager for creating and verifying tokens."""
    
    def __init__(self, secret: str, algorithm: str = "HS256", ttl_minutes: int = 60):
        """
        Initialize JWT manager.
        
        Args:
            secret: JWT secret key
            algorithm: JWT algorithm (default: HS256)
            ttl_minutes: Token time-to-live in minutes (default: 60)
        """
        self.secret = secret
        self.algorithm = algorithm
        self.ttl_minutes = ttl_minutes
    
    def create_access_token(self, subject: str, expires_delta: Optional[timedelta] = None) -> str:
        """
        Create a JWT access token.
        
        Args:
            subject: Subject (usually user ID)
            expires_delta: Optional custom expiration time
            
        Returns:
            Encoded JWT token string
        """
        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(minutes=self.ttl_minutes)
        
        payload = {"sub": subject, "exp": expire}
        return jwt.encode(payload, self.secret, algorithm=self.algorithm)
    
    def verify_token(self, token: str) -> Optional[str]:
        """
        Verify and decode a JWT token.
        
        Args:
            token: JWT token string
            
        Returns:
            Subject (user ID) if token is valid, None otherwise
        """
        try:
            payload = jwt.decode(token, self.secret, algorithms=[self.algorithm])
            return str(payload.get("sub"))
        except JWTError:
            return None
    
    def decode_token(self, token: str) -> Optional[dict]:
        """
        Decode JWT token without verification (for debugging).
        
        Args:
            token: JWT token string
            
        Returns:
            Decoded payload dict or None if invalid
        """
        try:
            return jwt.decode(token, self.secret, algorithms=[self.algorithm])
        except JWTError:
            return None

