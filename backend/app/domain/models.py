from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from uuid import UUID


@dataclass(frozen=True)
class User:
    id: UUID
    auth_provider: str
    auth_subject: str
    display_name: str | None
    about: str | None
    avatar_url: str | None
    interests: dict | None
    created_at: datetime


@dataclass(frozen=True)
class Idea:
    id: UUID
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
    created_at: datetime


@dataclass(frozen=True)
class Swipe:
    id: UUID
    user_id: UUID
    idea_id: UUID
    direction: str  # 'vibe' | 'no_vibe'
    decision_time_ms: int | None
    created_at: datetime
