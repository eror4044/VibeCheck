from __future__ import annotations

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from app.api.deps import ideas_repo, require_admin_key
from app.domain.ports import IdeaRepository


router = APIRouter()


class CreateIdeaRequest(BaseModel):
    title: str = Field(min_length=1, max_length=80)
    short_pitch: str = Field(min_length=1, max_length=160)
    category: str = Field(min_length=1, max_length=40)
    tags: list[str] | None = Field(default=None)
    media_url: str = Field(min_length=10)

    one_liner: str | None = Field(default=None, max_length=120)
    problem: str | None = Field(default=None, max_length=240)
    solution: str | None = Field(default=None, max_length=240)
    audience: str | None = Field(default=None, max_length=120)
    differentiator: str | None = Field(default=None, max_length=140)
    stage: str = Field(default="idea")
    links: dict | None = Field(default=None)


class IdeaResponse(BaseModel):
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
    created_at: str


@router.post("", response_model=IdeaResponse, dependencies=[Depends(require_admin_key)])
def create_idea(body: CreateIdeaRequest, ideas: IdeaRepository = Depends(ideas_repo)) -> IdeaResponse:
    idea = ideas.create(
        title=body.title,
        short_pitch=body.short_pitch,
        category=body.category,
        tags=body.tags,
        media_url=body.media_url,
        one_liner=body.one_liner or body.short_pitch,
        problem=body.problem,
        solution=body.solution,
        audience=body.audience,
        differentiator=body.differentiator,
        stage=body.stage,
        links=body.links,
    )
    return IdeaResponse(
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
        created_at=idea.created_at.isoformat(),
    )
