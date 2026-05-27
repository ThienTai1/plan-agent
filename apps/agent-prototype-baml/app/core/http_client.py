"""
HTTP client base class for service-to-service communication.
"""
import logging
from typing import Optional, Dict, Any
from functools import lru_cache

import httpx

logger = logging.getLogger(__name__)


class ServiceClient:
    """Base HTTP client for inter-service communication."""
    
    def __init__(
        self,
        base_url: str,
        timeout: float = 30.0,
        headers: Optional[Dict[str, str]] = None,
    ):
        """
        Initialize service client.
        
        Args:
            base_url: Base URL of the target service
            timeout: Request timeout in seconds
            headers: Default headers to include in all requests
        """
        self.base_url = str(base_url).rstrip("/")
        self.timeout = timeout
        self.default_headers = headers or {}
        self._client: Optional[httpx.AsyncClient] = None
    
    async def _get_client(self) -> httpx.AsyncClient:
        """Get or create HTTP client."""
        if self._client is None:
            self._client = httpx.AsyncClient(
                base_url=self.base_url,
                timeout=self.timeout,
                headers=self.default_headers,
            )
        return self._client
    
    async def close(self):
        """Close HTTP client."""
        if self._client:
            await self._client.aclose()
            self._client = None
    
    async def get(
        self,
        path: str,
        params: Optional[Dict[str, Any]] = None,
        headers: Optional[Dict[str, str]] = None,
    ) -> httpx.Response:
        """Make GET request."""
        client = await self._get_client()
        merged_headers = {**self.default_headers, **(headers or {})}
        response = await client.get(path, params=params, headers=merged_headers)
        response.raise_for_status()
        return response
    
    async def post(
        self,
        path: str,
        json: Optional[Dict[str, Any]] = None,
        data: Optional[Dict[str, Any]] = None,
        headers: Optional[Dict[str, str]] = None,
    ) -> httpx.Response:
        """Make POST request."""
        client = await self._get_client()
        merged_headers = {**self.default_headers, **(headers or {})}
        response = await client.post(path, json=json, data=data, headers=merged_headers)
        response.raise_for_status()
        return response
    
    async def put(
        self,
        path: str,
        json: Optional[Dict[str, Any]] = None,
        headers: Optional[Dict[str, str]] = None,
    ) -> httpx.Response:
        """Make PUT request."""
        client = await self._get_client()
        merged_headers = {**self.default_headers, **(headers or {})}
        response = await client.put(path, json=json, headers=merged_headers)
        response.raise_for_status()
        return response
    
    async def delete(
        self,
        path: str,
        headers: Optional[Dict[str, str]] = None,
    ) -> httpx.Response:
        """Make DELETE request."""
        client = await self._get_client()
        merged_headers = {**self.default_headers, **(headers or {})}
        response = await client.delete(path, headers=merged_headers)
        response.raise_for_status()
        return response

