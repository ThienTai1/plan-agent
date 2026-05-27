from dotenv import load_dotenv
load_dotenv(override=True)

from app.api.routes import router
from app.api.subscriptions import router as subscription_router
# from app.api.ws_router import router as ws_router
from app.config.settings import get_settings
from app.core.logging import configure_logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware


settings = get_settings()
# Create the FastAPI app
app = FastAPI(
    title="Awesome GenAI API",
    description="API for Awesome GenAI backend",
    version="0.1.0",
)

settings = get_settings()
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_methods=settings.CORS_METHODS,
    allow_headers=settings.CORS_HEADERS,
    allow_credentials=settings.CORS_CREDENTIALS,
)

app.include_router(router, prefix="/v1")
app.include_router(subscription_router, prefix="/v1")
# app.include_router(ws_router, prefix="/v1")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, port=8000)
