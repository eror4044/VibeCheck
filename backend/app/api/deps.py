from __future__ import annotations

from uuid import UUID

from fastapi import Depends, Header, HTTPException, Request

from app.core.security import decode_access_token
from app.core.settings import Settings
from app.data.db import Database
from app.data.repositories.ideas import PostgresIdeaRepository
from app.data.repositories.swipes import PostgresSwipeRepository
from app.data.repositories.users import PostgresUserRepository


def get_settings(request: Request) -> Settings:
    return request.app.state.settings


def get_db(request: Request) -> Database:
    return request.app.state.db


def users_repo(db: Database = Depends(get_db)) -> PostgresUserRepository:
    return PostgresUserRepository(db)


def ideas_repo(db: Database = Depends(get_db)) -> PostgresIdeaRepository:
    return PostgresIdeaRepository(db)


def swipes_repo(db: Database = Depends(get_db)) -> PostgresSwipeRepository:
    return PostgresSwipeRepository(db)


def require_user_id(
    authorization: str | None = Header(default=None),
    settings: Settings = Depends(get_settings),
) -> UUID:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = authorization.removeprefix("Bearer ").strip()
    try:
        claims = decode_access_token(
            token=token,
            secret=settings.jwt_secret,
            issuer=settings.jwt_issuer,
            audience=settings.jwt_audience,
        )
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")

    sub = claims.get("sub")
    try:
        return UUID(str(sub))
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token subject")


def require_admin_key(
    x_admin_key: str | None = Header(default=None, alias="X-Admin-Key"),
    settings: Settings = Depends(get_settings),
) -> None:
    if not settings.admin_api_key:
        raise HTTPException(status_code=403, detail="Admin ingestion is disabled")
    if not x_admin_key or x_admin_key != settings.admin_api_key:
        raise HTTPException(status_code=403, detail="Invalid admin key")
