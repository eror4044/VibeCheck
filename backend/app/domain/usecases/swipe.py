from __future__ import annotations

from uuid import UUID

from app.domain.models import Swipe
from app.domain.ports import SwipeRepository


def record_swipe(
    *,
    swipes: SwipeRepository,
    user_id: UUID,
    idea_id: UUID,
    direction: str,
    decision_time_ms: int | None,
) -> Swipe:
    if direction not in {"vibe", "no_vibe"}:
        raise ValueError("Invalid swipe direction")
    if decision_time_ms is not None and decision_time_ms < 0:
        raise ValueError("decision_time_ms must be >= 0")
    return swipes.create(
        user_id=user_id,
        idea_id=idea_id,
        direction=direction,
        decision_time_ms=decision_time_ms,
    )
