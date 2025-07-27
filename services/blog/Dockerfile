FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
RUN pip install poetry

# Copy Poetry files and README
COPY pyproject.toml poetry.lock* README.md ./

# Configure Poetry
RUN poetry config virtualenvs.create false

# Install dependencies
RUN poetry install --no-root

# Copy application code
COPY services/blog/ ./src/

# Set Python path
ENV PYTHONPATH=/app/src

WORKDIR /app/src

EXPOSE 8002

CMD ["poetry", "run", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8002", "--reload"]
