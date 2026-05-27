# syntax=docker/dockerfile:1.6
FROM python:3.12-slim

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uv/bin/

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/app/src/apps/agent-service/.venv/bin:/uv/bin:$PATH"

WORKDIR /app/src

# 1. Copy internal libraries first
COPY libs/python-common /app/src/libs/python-common

# 2. Copy dependency files for caching
COPY apps/agent-service/pyproject.toml apps/agent-service/uv.lock /app/src/apps/agent-service/

WORKDIR /app/src/apps/agent-service

# 3. Sync dependencies (without the project itself) to cache layers
RUN uv sync --frozen --no-cache --no-install-project

# 4. Copy the application code
COPY apps/agent-service /app/src/apps/agent-service

# 5. CRITICAL: Remove host's .venv if it was copied and re-sync to ensure correct symlinks
RUN rm -rf /app/src/apps/agent-service/.venv && uv sync --frozen --no-cache

# 6. Install internal library in editable mode
RUN uv pip install -e /app/src/libs/python-common

EXPOSE 8100
CMD ["uv", "run", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8100"]
