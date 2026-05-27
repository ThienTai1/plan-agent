FROM python:3.12-slim

# Install system dependencies required for building Python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install uv globally
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# Set the working directory
WORKDIR /app

# Copy the shared library first (for caching)
COPY libs/python-common /app/libs/python-common

# Copy the agent-service source code
COPY apps/agent-service /app/apps/agent-service

# Set the working directory to the agent-service
WORKDIR /app/apps/agent-service

# Set PYTHONPATH so the service can find the common library
ENV PYTHONPATH="/app/libs/python-common"

# Install dependencies using uv
RUN uv sync --no-dev --no-install-project

# Expose the API port
EXPOSE 8100

# Start the application
CMD ["uv", "run", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8100"]
