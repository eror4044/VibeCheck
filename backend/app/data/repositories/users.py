from __future__ import annotations

from uuid import UUID

from psycopg.rows import dict_row
from psycopg.types.json import Jsonb

from app.data.db import Database
from app.domain.models import User
from app.domain.ports import UserRepository


class PostgresUserRepository(UserRepository):
    def __init__(self, db: Database) -> None:
        self._db = db

    def get_by_id(self, user_id: UUID) -> User | None:
        with self._db.pool().connection() as conn:
            with conn.cursor(row_factory=dict_row) as cur:
                cur.execute("SELECT * FROM users WHERE id = %s", (user_id,))
                row = cur.fetchone()
        return _to_user(row) if row else None

    def upsert_by_auth(self, *, auth_provider: str, auth_subject: str) -> User:
        with self._db.pool().connection() as conn:
            with conn.cursor(row_factory=dict_row) as cur:
                cur.execute(
                    """
                    INSERT INTO users(auth_provider, auth_subject)
                    VALUES (%s, %s)
                    ON CONFLICT (auth_provider, auth_subject)
                    DO UPDATE SET auth_subject = EXCLUDED.auth_subject
                    RETURNING *
                    """,
                    (auth_provider, auth_subject),
                )
                row = cur.fetchone()
            conn.commit()
        if not row:
            raise RuntimeError("Failed to upsert user")
        return _to_user(row)

    def update_interests(self, *, user_id: UUID, interests: dict | None) -> User:
        interests_value = Jsonb(interests) if interests is not None else None
        with self._db.pool().connection() as conn:
            with conn.cursor(row_factory=dict_row) as cur:
                cur.execute(
                    "UPDATE users SET interests = %s WHERE id = %s RETURNING *",
                    (interests_value, user_id),
                )
                row = cur.fetchone()
            conn.commit()
        if not row:
            raise KeyError("User not found")
        return _to_user(row)

    def update_profile(
        self,
        *,
        user_id: UUID,
        display_name: str | None,
        about: str | None,
        avatar_url: str | None,
    ) -> User:
        with self._db.pool().connection() as conn:
            with conn.cursor(row_factory=dict_row) as cur:
                cur.execute(
                    """
                    UPDATE users
                    SET display_name = %s,
                        about = %s,
                        avatar_url = %s
                    WHERE id = %s
                    RETURNING *
                    """,
                    (display_name, about, avatar_url, user_id),
                )
                row = cur.fetchone()
            conn.commit()
        if not row:
            raise KeyError("User not found")
        return _to_user(row)


def _to_user(row: dict) -> User:
    return User(
        id=row["id"],
        auth_provider=row["auth_provider"],
        auth_subject=row["auth_subject"],
        display_name=row.get("display_name"),
        about=row.get("about"),
        avatar_url=row.get("avatar_url"),
        interests=row.get("interests"),
        created_at=row["created_at"],
    )
