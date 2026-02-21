from __future__ import annotations

from uuid import UUID

from app.domain.models import Idea
from app.domain.ports import IdeaRepository


def get_next_idea(*, ideas: IdeaRepository, user_id: UUID) -> Idea | None:
    return ideas.get_next_for_user(user_id=user_id)
