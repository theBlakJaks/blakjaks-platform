FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY pyproject.toml .
RUN pip install --no-cache-dir -e ".[dev]"

# Copy application code
COPY . .

# Run Celery worker
CMD ["celery", "-A", "app.celery_app.celery_app", "worker", \
     "--loglevel=info", "--concurrency=4", "-E"]
