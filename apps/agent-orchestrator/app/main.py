from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import logging

from contextlib import asynccontextmanager
from app.api.routes import router as api_router
from app.config import settings
from app.core.db import db_manager
from app.agent.workflow import get_checkpointer

from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from app.core.security import limiter

# Configure logging
logging.basicConfig(
    level=settings.LOG_LEVEL,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Manage application lifecycle.
    """
    # 🔌 Startup: Connect to DB and setup checkpointer tables
    await db_manager.connect()
    
    if db_manager.pool:
        try:
            from langgraph.checkpoint.postgres.aio import AsyncPostgresSaver
            # Direct instantiation since our version doesn't support async with on the object
            checkpointer = AsyncPostgresSaver(db_manager.pool)
            logger.info("🛠️ Setting up LangGraph persistence tables...")
            await checkpointer.setup()
            
            # Store in app state
            app.state.checkpointer = checkpointer
            logger.info("✅ LangGraph persistence (Postgres) ready.")
        except Exception as e:
            logger.error(f"❌ Failed to setup checkpointer: {str(e)}")
            
    yield
    
    # 🔌 Shutdown: Close DB pool
    await db_manager.disconnect()

# Create FastAPI app
app = FastAPI(
    title=settings.APP_NAME,
    description="Multi-agent backend for goal and task management",
    version=settings.APP_VERSION,
    lifespan=lifespan,
)

# Connect SlowAPI limiter
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify allowed origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Health check endpoint
@app.get("/")
def health_check():
    return {
        "status": "ok",
        "service": settings.APP_NAME,
        "version": settings.APP_VERSION,
    }


@app.get("/health")
def health_status():
    return {
        "status": "healthy",
        "service": settings.APP_NAME,
    }


# Include routers
from app.api.analytics_routes import router as analytics_router
app.include_router(api_router, prefix="/v1/agent")
app.include_router(analytics_router, prefix="/v1/agent/analytics", tags=["analytics"])


@app.exception_handler(Exception)
async def general_exception_handler(request, exc):
    # If it's already an HTTPException, return its own status and detail
    if isinstance(exc, HTTPException):
        return JSONResponse(
            status_code=exc.status_code,
            content={"detail": exc.detail},
        )
    
    logger.error(f"Unhandled exception: {str(exc)}")
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"},
    )


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8100,
        reload=settings.DEBUG,
    )
