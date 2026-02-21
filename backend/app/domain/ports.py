from __future__ import annotations

from abc import ABC, abstractmethod
from uuid import UUID

from app.domain.models import Idea, IdeaMedia, IdeaStats, Swipe, SwipeStats, User


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
        author_id: UUID | None = None,
        status: str = "published",
    ) -> Idea: ...

    @abstractmethod
    def get_by_id(self, *, idea_id: UUID) -> Idea | None: ...

    @abstractmethod
    def get_next_for_user(self, *, user_id: UUID) -> Idea | None: ...

    @abstractmethod
    def list_by_author(self, *, author_id: UUID) -> list[Idea]: ...

    @abstractmethod
    def update(
        self,
        *,
        idea_id: UUID,
        author_id: UUID,
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
        status: str,
    ) -> Idea | None: ...

    @abstractmethod
    def delete(self, *, idea_id: UUID, author_id: UUID) -> bool: ...

    @abstractmethod
    def publish(self, *, idea_id: UUID, author_id: UUID) -> Idea | None: ...


class IdeaMediaRepository(ABC):
    @abstractmethod
    def add(self, *, idea_id: UUID, media_type: str, s3_key: str, position: int) -> IdeaMedia: ...

    @abstractmethod
    def list_by_idea(self, *, idea_id: UUID) -> list[IdeaMedia]: ...

    @abstractmethod
    def delete(self, *, media_id: UUID, idea_id: UUID) -> bool: ...

    @abstractmethod
    def reorder(self, *, idea_id: UUID, media_ids: list[UUID]) -> None: ...


class SwipeRepository(ABC):
    @abstractmethod
    def create(self, *, user_id: UUID, idea_id: UUID, direction: str, decision_time_ms: int | None) -> Swipe: ...

    @abstractmethod
    def get_user_stats(self, *, user_id: UUID) -> SwipeStats: ...

    @abstractmethod
    def get_idea_stats(self, *, idea_id: UUID) -> IdeaStats: ...
