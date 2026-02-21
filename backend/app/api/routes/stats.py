from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from app.api.deps import ideas_repo, require_user_id, swipes_repo
from app.domain.ports import IdeaRepository, SwipeRepository


router = APIRouter()


class CategoryStat(BaseModel):
    category: str
    total: int
    vibes: int
    no_vibes: int
    vibe_rate: float


class UserStatsResponse(BaseModel):
    total_swipes: int
    total_vibes: int
    total_no_vibes: int
    vibe_rate: float
    by_category: list[CategoryStat]


class IdeaStatResponse(BaseModel):
    idea_id: str
    title: str
    total_views: int
    total_vibes: int
    total_no_vibes: int
    vibe_rate: float


class MyIdeasStatsResponse(BaseModel):
    ideas: list[IdeaStatResponse]
    total_views: int
    total_vibes: int


@router.get("/me", response_model=UserStatsResponse)
def get_my_stats(
    user_id: UUID = Depends(require_user_id),
    swipes: SwipeRepository = Depends(swipes_repo),
) -> UserStatsResponse:
    stats = swipes.get_user_stats(user_id=user_id)
    total = stats.total_swipes
    vibe_rate = (stats.total_vibes / total * 100) if total > 0 else 0.0

    cats = []
    for cat, data in stats.by_category.items():
        cat_total = data["total"]
        cats.append(CategoryStat(
            category=cat,
            total=cat_total,
            vibes=data["vibes"],
            no_vibes=data["no_vibes"],
            vibe_rate=round(data["vibes"] / cat_total * 100, 1) if cat_total > 0 else 0.0,
        ))

    return UserStatsResponse(
        total_swipes=total,
        total_vibes=stats.total_vibes,
        total_no_vibes=stats.total_no_vibes,
        vibe_rate=round(vibe_rate, 1),
        by_category=cats,
    )


@router.get("/my-ideas", response_model=MyIdeasStatsResponse)
def get_my_ideas_stats(
    user_id: UUID = Depends(require_user_id),
    ideas: IdeaRepository = Depends(ideas_repo),
    swipes: SwipeRepository = Depends(swipes_repo),
) -> MyIdeasStatsResponse:
    my_ideas = ideas.list_by_author(author_id=user_id)
    idea_stats: list[IdeaStatResponse] = []
    sum_views = 0
    sum_vibes = 0

    for idea in my_ideas:
        st = swipes.get_idea_stats(idea_id=idea.id)
        idea_stats.append(IdeaStatResponse(
            idea_id=str(idea.id),
            title=idea.title,
            total_views=st.total_views,
            total_vibes=st.total_vibes,
            total_no_vibes=st.total_no_vibes,
            vibe_rate=st.vibe_rate,
        ))
        sum_views += st.total_views
        sum_vibes += st.total_vibes

    return MyIdeasStatsResponse(
        ideas=idea_stats,
        total_views=sum_views,
        total_vibes=sum_vibes,
    )
