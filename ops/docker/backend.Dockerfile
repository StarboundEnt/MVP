# Multi-stage build for Starbound backend utilities
FROM python:3.11-slim AS builder

WORKDIR /app
COPY backend/requirements.txt backend/requirements.txt
RUN pip install --upgrade pip && pip install --prefix=/install -r backend/requirements.txt

FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /install /usr/local
COPY backend backend
COPY backend/config backend/config
COPY backend/mappings backend/mappings
COPY backend/ingestion backend/ingestion
COPY backend/api backend/api
ENV PYTHONUNBUFFERED=1
CMD ["uvicorn", "backend.api.app:app", "--host", "0.0.0.0", "--port", "8000"]
