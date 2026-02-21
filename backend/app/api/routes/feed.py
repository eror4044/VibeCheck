from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from app.api.deps import ideas_repo, require_user_id
from app.domain.ports import IdeaRepository
from app.domain.usecases.feed import get_next_idea


router = APIRouter()


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


@router.get("/next", response_model=FeedIdeaResponse | None)
def next_idea(user_id: UUID = Depends(require_user_id), ideas: IdeaRepository = Depends(ideas_repo)) -> FeedIdeaResponse | None:
    idea = get_next_idea(ideas=ideas, user_id=user_id)
    if not idea:
        return None
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
    )
