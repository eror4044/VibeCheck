from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.router import api_router
from app.core.logging import configure_logging
from app.core.settings import Settings
from app.data.db import Database
from app.data.migrations import run_migrations


def create_app() -> FastAPI:
    settings = Settings()
    configure_logging(settings.log_level)

    application = FastAPI(
        title="VibeCheck API",
        version="0.1.0",
        docs_url="/docs" if settings.app_env != "prod" else None,
        redoc_url=None,
        openapi_url="/openapi.json",
    )

    if settings.cors_origins:
        origins = [o.strip() for o in settings.cors_origins.split(",") if o.strip()]
        if origins:
            application.add_middleware(
                CORSMiddleware,
                allow_origins=origins,
                allow_credentials=True,
                allow_methods=["GET", "POST", "PUT", "OPTIONS"],
                allow_headers=["Authorization", "Content-Type", "X-Admin-Key"],
            )

    db = Database(settings.database_url)

    migrations_dir = str(Path(__file__).resolve().parents[1] / "migrations")

    @application.on_event("startup")
    def _startup() -> None:
        db.open()
        run_migrations(db, migrations_dir=migrations_dir)

    @application.on_event("shutdown")
    def _shutdown() -> None:
        db.close()

    application.state.settings = settings
    application.state.db = db

    application.include_router(api_router)
    return application


app = create_app()
