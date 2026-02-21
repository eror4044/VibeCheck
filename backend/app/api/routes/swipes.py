from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.api.deps import require_user_id, swipes_repo
from app.data.repositories.swipes import DuplicateSwipeError
from app.domain.ports import SwipeRepository
from app.domain.usecases.swipe import record_swipe


router = APIRouter()


class CreateSwipeRequest(BaseModel):
    idea_id: UUID
    direction: str = Field(pattern="^(vibe|no_vibe)$")
    decision_time_ms: int | None = Field(default=None, ge=0)


class SwipeResponse(BaseModel):
    id: str
    user_id: str
    idea_id: str
    direction: str
    decision_time_ms: int | None
    created_at: str


@router.post("", response_model=SwipeResponse)
def create_swipe(
    body: CreateSwipeRequest,
    user_id: UUID = Depends(require_user_id),
    swipes: SwipeRepository = Depends(swipes_repo),
) -> SwipeResponse:
    try:
        swipe = record_swipe(
            swipes=swipes,
            user_id=user_id,
            idea_id=body.idea_id,
            direction=body.direction,
            decision_time_ms=body.decision_time_ms,
        )
    except DuplicateSwipeError:
        raise HTTPException(status_code=409, detail="Swipe already recorded")
    except ValueError as ex:
        raise HTTPException(status_code=422, detail=str(ex))

    return SwipeResponse(
        id=str(swipe.id),
        user_id=str(swipe.user_id),
        idea_id=str(swipe.idea_id),
        direction=swipe.direction,
        decision_time_ms=swipe.decision_time_ms,
        created_at=swipe.created_at.isoformat(),
    )
