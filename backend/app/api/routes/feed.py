from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from app.api.deps import get_db, get_settings, ideas_repo, require_user_id
from app.core.settings import Settings
from app.data.db import Database
from app.data.repositories.idea_media import PostgresIdeaMediaRepository
from app.domain.ports import IdeaRepository
from app.domain.usecases.feed import get_next_idea
from app.services.s3_presign import presign_get


router = APIRouter()


def _media_repo(db: Database = Depends(get_db)) -> PostgresIdeaMediaRepository:
    return PostgresIdeaMediaRepository(db)


class FeedMediaItem(BaseModel):
    id: str
    media_type: str
    url: str
    position: int


class FeedIdeaResponse(BaseModel):
    id: str
    title: str
    short_pitch: str
    category: str
    tags: list[str] | None
    media_url: str

    one_liner: str
    problem: str | None
    solution: str | None
    audience: str | None
    differentiator: str | None
    stage: str
    links: dict | None
    media: list[FeedMediaItem] = []


def _presign(s3_key: str, settings: Settings) -> str:
    if not settings.s3_bucket:
        return s3_key
    try:
        return presign_get(
            region=settings.aws_region,
            bucket=settings.s3_bucket,
            object_key=s3_key,
            ttl_seconds=settings.s3_presign_ttl_seconds,
        )
    except Exception:
        return s3_key


@router.get("/next", response_model=FeedIdeaResponse | None)
def next_idea(
    user_id: UUID = Depends(require_user_id),
    ideas: IdeaRepository = Depends(ideas_repo),
    media_repo: PostgresIdeaMediaRepository = Depends(_media_repo),
    settings: Settings = Depends(get_settings),
) -> FeedIdeaResponse | None:
    idea = get_next_idea(ideas=ideas, user_id=user_id)
    if not idea:
        return None

    media_items = media_repo.list_by_idea(idea_id=idea.id)

    return FeedIdeaResponse(
        id=str(idea.id),
        title=idea.title,
        short_pitch=idea.short_pitch,
        category=idea.category,
        tags=idea.tags,
        media_url=idea.media_url,
        one_liner=idea.one_liner,
        problem=idea.problem,
        solution=idea.solution,
        audience=idea.audience,
        differentiator=idea.differentiator,
        stage=idea.stage,
        links=idea.links,
        media=[
            FeedMediaItem(
                id=str(m.id),
                media_type=m.media_type,
                url=_presign(m.s3_key, settings),
                position=m.position,
            )
            for m in media_items
        ],
    )
