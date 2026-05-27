# Use a Python image with uv pre-installed
FROM ghcr.io/astral-sh/uv:python3.11-bookworm-slim AS builder

# Set the working directory
WORKDIR /app

# Enable bytecode compilation
ENV UV_COMPILE_BYTECODE=1

# Copy from the cache instead of linking since it's a multi-stage build
ENV UV_LINK_MODE=copy

# Copy only the files needed for dependency installation
COPY uv.lock pyproject.toml ./

# Install the project's dependencies
RUN uv sync --frozen --no-install-project --no-dev

# ══════════════════════════════════════════════════════════════════════
# FINAL RUNTIME IMAGE
# ══════════════════════════════════════════════════════════════════════

FROM python:3.11-slim-bookworm

WORKDIR /app

# Copy the synced environment from the builder
COPY --from=builder /app/.venv /app/.venv

# Add the virtual environment's bin directory to the PATH
ENV PATH="/app/.venv/bin:$PATH"

# Copy the application source code
COPY . .

# Expose the port (GCP Cloud Run defaults to 8080, but can be configured)
EXPOSE 8080

# Environment variables (Defaults)
ENV PORT=8080
ENV DEBUG=false
ENV LOG_LEVEL=INFO

# Command to run the application
# We use uvicorn directly instead of uv run to keep the runtime image minimal
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
