# Production-ready Dockerfile for Python Flask application
# Stage 1: Builder stage for compiling dependencies
FROM python:3.11-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    python3-dev && \
    rm -rf /var/lib/apt/lists/*

# Install Python dependencies to /usr/local (accessible to all users)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Stage 2: Runtime stage
FROM python:3.11-slim

LABEL org.opencontainers.image.source="https://github.com/banicr/demo_app"
LABEL org.opencontainers.image.description="Demo Flask Application"

WORKDIR /app

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# APP_VERSION can be overridden at build time
ARG APP_VERSION=v1.0.0
ENV APP_VERSION=${APP_VERSION}

# Install only curl for healthcheck (no build tools needed)
RUN apt-get update && apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

# Copy Python dependencies from builder (they're in /usr/local)
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application code
COPY app/ ./app/

# Create non-root user for security
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app

USER appuser

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/healthz || exit 1

# Run with gunicorn for production with graceful shutdown
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--threads", "4", \
     "--timeout", "60", "--graceful-timeout", "30", \
     "--access-logfile", "-", "--error-logfile", "-", "app.main:app"]
