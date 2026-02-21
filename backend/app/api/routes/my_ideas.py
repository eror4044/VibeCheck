from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Response
from pydantic import BaseModel, Field

from app.api.deps import get_settings, ideas_repo, require_user_id
from app.core.settings import Settings
from app.data.repositories.idea_media import PostgresIdeaMediaRepository
from app.api.deps import get_db
from app.data.db import Database
from app.domain.ports import IdeaRepository
from app.services.s3_presign import presign_get, presign_put_idea_media

router = APIRouter()


# ── helpers ───────────────────────────────────────────────────────

def _media_repo(db: Database = Depends(get_db)) -> PostgresIdeaMediaRepository:
    return PostgresIdeaMediaRepository(db)


def _presign_media_url(s3_key: str, settings: Settings) -> str:
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


# ── request / response models ────────────────────────────────────

class MediaResponse(BaseModel):
    id: str
    media_type: str
    url: str
    position: int


class MyIdeaResponse(BaseModel):
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
    status: str
    created_at: str
    media: list[MediaResponse] = []


class CreateMyIdeaRequest(BaseModel):
    title: str = Field(min_length=1, max_length=80)
    short_pitch: str = Field(min_length=1, max_length=160)
    category: str = Field(min_length=1, max_length=40)
    tags: list[str] | None = Field(default=None)
    media_url: str = Field(default="")
    one_liner: str | None = Field(default=None, max_length=120)
    problem: str | None = Field(default=None, max_length=500)
    solution: str | None = Field(default=None, max_length=500)
    audience: str | None = Field(default=None, max_length=200)
    differentiator: str | None = Field(default=None, max_length=200)
    stage: str = Field(default="idea")
    links: dict | None = Field(default=None)
    status: str = Field(default="draft")


class UpdateMyIdeaRequest(BaseModel):
    title: str = Field(min_length=1, max_length=80)
    short_pitch: str = Field(min_length=1, max_length=160)
    category: str = Field(min_length=1, max_length=40)
    tags: list[str] | None = Field(default=None)
    media_url: str = Field(default="")
    one_liner: str | None = Field(default=None, max_length=120)
    problem: str | None = Field(default=None, max_length=500)
    solution: str | None = Field(default=None, max_length=500)
    audience: str | None = Field(default=None, max_length=200)
    differentiator: str | None = Field(default=None, max_length=200)
    stage: str = Field(default="idea")
    links: dict | None = Field(default=None)
    status: str = Field(default="draft")


class MediaUploadUrlRequest(BaseModel):
    content_type: str
    media_type: str = "image"  # 'image' | 'video'


class MediaUploadUrlResponse(BaseModel):
    object_key: str
    upload_url: str
    headers: dict[str, str]


# ── endpoints ────────────────────────────────────────────────────

@router.get("", response_model=list[MyIdeaResponse])
def list_my_ideas(
    user_id: UUID = Depends(require_user_id),
    ideas: IdeaRepository = Depends(ideas_repo),
    media_repo: PostgresIdeaMediaRepository = Depends(_media_repo),
    settings: Settings = Depends(get_settings),
) -> list[MyIdeaResponse]:
    rows = ideas.list_by_author(author_id=user_id)
    result: list[MyIdeaResponse] = []
    for idea in rows:
        media_items = media_repo.list_by_idea(idea_id=idea.id)
        result.append(MyIdeaResponse(
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
            status=idea.status,
            created_at=idea.created_at.isoformat(),
            media=[
                MediaResponse(
                    id=str(m.id),
                    media_type=m.media_type,
                    url=_presign_media_url(m.s3_key, settings),
                    position=m.position,
                )
                for m in media_items
            ],
        ))
    return result


@router.post("", response_model=MyIdeaResponse, status_code=201)
def create_my_idea(
    body: CreateMyIdeaRequest,
    user_id: UUID = Depends(require_user_id),
    ideas: IdeaRepository = Depends(ideas_repo),
) -> MyIdeaResponse:
    idea = ideas.create(
        title=body.title,
        short_pitch=body.short_pitch,
        category=body.category,
        tags=body.tags,
        media_url=body.media_url or "",
        one_liner=body.one_liner or body.short_pitch,
        problem=body.problem,
        solution=body.solution,
        audience=body.audience,
        differentiator=body.differentiator,
        stage=body.stage,
        links=body.links,
        author_id=user_id,
        status=body.status,
    )
    return MyIdeaResponse(
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
        status=idea.status,
        created_at=idea.created_at.isoformat(),
    )


@router.get("/{idea_id}", response_model=MyIdeaResponse)
def get_my_idea(
    idea_id: UUID,
    user_id: UUID = Depends(require_user_id),
    ideas: IdeaRepository = Depends(ideas_repo),
    media_repo: PostgresIdeaMediaRepository = Depends(_media_repo),
    settings: Settings = Depends(get_settings),
) -> MyIdeaResponse:
    idea = ideas.get_by_id(idea_id=idea_id)
    if not idea or idea.author_id != user_id:
        raise HTTPException(status_code=404, detail="Idea not found")

    media_items = media_repo.list_by_idea(idea_id=idea.id)
    return MyIdeaResponse(
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
        status=idea.status,
        created_at=idea.created_at.isoformat(),
        media=[
            MediaResponse(
                id=str(m.id),
                media_type=m.media_type,
                url=_presign_media_url(m.s3_key, settings),
                position=m.position,
            )
            for m in media_items
        ],
    )


@router.put("/{idea_id}", response_model=MyIdeaResponse)
def update_my_idea(
    idea_id: UUID,
    body: UpdateMyIdeaRequest,
    user_id: UUID = Depends(require_user_id),
    ideas: IdeaRepository = Depends(ideas_repo),
) -> MyIdeaResponse:
    idea = ideas.update(
        idea_id=idea_id,
        author_id=user_id,
        title=body.title,
        short_pitch=body.short_pitch,
        category=body.category,
        tags=body.tags,
        media_url=body.media_url or "",
        one_liner=body.one_liner or body.short_pitch,
        problem=body.problem,
        solution=body.solution,
        audience=body.audience,
        differentiator=body.differentiator,
        stage=body.stage,
        links=body.links,
        status=body.status,
    )
    if not idea:
        raise HTTPException(status_code=404, detail="Idea not found")
    return MyIdeaResponse(
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
        status=idea.status,
        created_at=idea.created_at.isoformat(),
    )


@router.delete("/{idea_id}", status_code=204, response_class=Response)
def delete_my_idea(
    idea_id: UUID,
    user_id: UUID = Depends(require_user_id),
    ideas: IdeaRepository = Depends(ideas_repo),
) -> Response:
    deleted = ideas.delete(idea_id=idea_id, author_id=user_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Idea not found")
    return Response(status_code=204)


@router.post("/{idea_id}/publish", response_model=MyIdeaResponse)
def publish_my_idea(
    idea_id: UUID,
    user_id: UUID = Depends(require_user_id),
    ideas: IdeaRepository = Depends(ideas_repo),
) -> MyIdeaResponse:
    idea = ideas.publish(idea_id=idea_id, author_id=user_id)
    if not idea:
        raise HTTPException(status_code=404, detail="Idea not found")
    return MyIdeaResponse(
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
        status=idea.status,
        created_at=idea.created_at.isoformat(),
    )


# ── media upload ─────────────────────────────────────────────────

@router.post("/{idea_id}/media/upload-url", response_model=MediaUploadUrlResponse)
def create_media_upload_url(
    idea_id: UUID,
    body: MediaUploadUrlRequest,
    user_id: UUID = Depends(require_user_id),
    ideas: IdeaRepository = Depends(ideas_repo),
    settings: Settings = Depends(get_settings),
) -> MediaUploadUrlResponse:
    # Verify ownership
    idea = ideas.get_by_id(idea_id=idea_id)
    if not idea or idea.author_id != user_id:
        raise HTTPException(status_code=404, detail="Idea not found")

    if not settings.s3_bucket:
        raise HTTPException(status_code=503, detail="S3 is not configured")

    try:
        presigned = presign_put_idea_media(
            region=settings.aws_region,
            bucket=settings.s3_bucket,
            idea_id=str(idea_id),
            content_type=body.content_type,
            ttl_seconds=settings.s3_presign_ttl_seconds,
        )
    except Exception as ex:
        raise HTTPException(status_code=500, detail=f"Failed to presign: {ex}")

    return MediaUploadUrlResponse(
        object_key=presigned.object_key,
        upload_url=presigned.upload_url,
        headers=presigned.headers,
    )


@router.post("/{idea_id}/media", response_model=MediaResponse, status_code=201)
def register_media(
    idea_id: UUID,
    body: _RegisterMediaRequest,
    user_id: UUID = Depends(require_user_id),
    ideas: IdeaRepository = Depends(ideas_repo),
    media_repo: PostgresIdeaMediaRepository = Depends(_media_repo),
    settings: Settings = Depends(get_settings),
) -> MediaResponse:
    """After uploading to S3, client calls this to register the media in DB."""
    idea = ideas.get_by_id(idea_id=idea_id)
    if not idea or idea.author_id != user_id:
        raise HTTPException(status_code=404, detail="Idea not found")

    existing = media_repo.list_by_idea(idea_id=idea_id)
    position = max((m.position for m in existing), default=-1) + 1

    media = media_repo.add(
        idea_id=idea_id,
        media_type=body.media_type,
        s3_key=body.s3_key,
        position=position,
    )
    return MediaResponse(
        id=str(media.id),
        media_type=media.media_type,
        url=_presign_media_url(media.s3_key, settings),
        position=media.position,
    )


class _RegisterMediaRequest(BaseModel):
    s3_key: str
    media_type: str = "image"


@router.delete("/{idea_id}/media/{media_id}", status_code=204, response_class=Response)
def delete_media(
    idea_id: UUID,
    media_id: UUID,
    user_id: UUID = Depends(require_user_id),
    ideas: IdeaRepository = Depends(ideas_repo),
    media_repo: PostgresIdeaMediaRepository = Depends(_media_repo),
) -> Response:
    idea = ideas.get_by_id(idea_id=idea_id)
    if not idea or idea.author_id != user_id:
        raise HTTPException(status_code=404, detail="Idea not found")

    deleted = media_repo.delete(media_id=media_id, idea_id=idea_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Media not found")
    return Response(status_code=204)
