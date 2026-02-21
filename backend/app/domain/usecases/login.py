from __future__ import annotations

from app.domain.ports import UserRepository


def login_with_subject(*, users: UserRepository, auth_provider: str, auth_subject: str) -> str:
    user = users.upsert_by_auth(auth_provider=auth_provider, auth_subject=auth_subject)
    return str(user.id)
