from typing import Optional
from psycopg_pool import AsyncConnectionPool
from app.config import settings
from loguru import logger

class DatabaseManager:
    def __init__(self):
        self.pool: Optional[AsyncConnectionPool] = None

    async def connect(self):
        """Initialize the connection pool asynchronously."""
        if not settings.DATABASE_URL:
            logger.warning("⚠️ DATABASE_URL not set. Persistent memory will be unavailable.")
            return

        try:
            logger.info("🔌 Initializing Async Postgres Connection Pool...")
            self.pool = AsyncConnectionPool(
                conninfo=settings.DATABASE_URL,
                max_size=10,
                open=False, # Don't open in constructor to avoid warning
                kwargs={
                    "autocommit": True,
                    "prepare_threshold": None,
                }
            )
            await self.pool.open()
            
            # Test connection (async call)
            async with self.pool.connection() as conn:
                await conn.execute("SELECT 1")
            logger.info("✅ Async Postgres Connection Pool established.")
        except Exception as e:
            logger.error(f"❌ Failed to initialize Async Postgres pool: {str(e)}")
            self.pool = None

    async def disconnect(self):
        """Close all connections in the pool asynchronously."""
        if self.pool:
            logger.info("🔌 Closing Async Postgres Connection Pool...")
            await self.pool.close()
            logger.info("✅ Async Postgres Connection Pool closed.")

# Singleton instance
db_manager = DatabaseManager()
