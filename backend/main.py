"""Uvicorn entrypoint — exposes the FastAPI app instance."""
from backend.api.app import create_app

app = create_app()
