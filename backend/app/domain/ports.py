from __future__ import annotations

from abc import ABC, abstractmethod
from uuid import UUID

from app.domain.models import Idea, Swipe, User


class UserRepository(ABC):
    @abstractmethod
    def get_by_id(self, user_id: UUID) -> User | None: ...

    @abstractmethod
    def upsert_by_auth(self, *, auth_provider: str, auth_subject: str) -> User: ...

    @abstractmethod
    def update_interests(self, *, user_id: UUID, interests: dict | None) -> User: ...

    @abstractmethod
    def update_profile(
        self,
        *,
        user_id: UUID,
        display_name: str | None,
        about: str | None,
        avatar_url: str | None,
    ) -> User: ...


class IdeaRepository(ABC):
    @abstractmethod
    def create(
        self,
        *,
        title: str,
        short_pitch: str,
        category: str,
        tags: list[str] | None,
        media_url: str,
        one_liner: str,
        problem: str | None,
        solution: str | None,
        audience: str | None,
        differentiator: str | None,
        stage: str,
        links: dict | None,
    ) -> Idea: ...

    @abstractmethod
    def get_by_id(self, *, idea_id: UUID) -> Idea | None: ...

    @abstractmethod
    def get_next_for_user(self, *, user_id: UUID) -> Idea | None: ...


class SwipeRepository(ABC):
    @abstractmethod
    def create(self, *, user_id: UUID, idea_id: UUID, direction: str, decision_time_ms: int | None) -> Swipe: ...
