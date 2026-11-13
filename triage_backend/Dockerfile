# Use lightweight, secure Debian-based Python 3.13 runtime (matches pyproject.toml requires-python >=3.13)
FROM python:3.13-slim-bookworm

# Set environment variables for optimized execution
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/app/.venv/bin:$PATH"

# Install curl for container healthcheck and clean up package cache
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

# Install uv using the official multi-stage binary copy for zero overhead
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Set working directory
WORKDIR /app

# Ensure directory for mounted persistent Qdrant storage exists
RUN mkdir -p /app/local_qdrant_data

# Leverage Docker layer caching: Copy lockfile and project definitions first
COPY pyproject.toml uv.lock ./

# Install project dependencies without source code to maximize cache hit rate
RUN uv sync --frozen --no-dev --no-install-project

# Copy application code and documentation
COPY README.md ./
COPY app/ ./app/

# Finalize project install into virtualenv
RUN uv sync --frozen --no-dev

# Expose API port
EXPOSE 8000

# Run FastAPI production ASGI server
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
