from __future__ import annotations

from uuid import UUID

from psycopg.errors import UniqueViolation
from psycopg.rows import dict_row

from app.data.db import Database
from app.domain.models import Swipe
from app.domain.ports import SwipeRepository


class DuplicateSwipeError(Exception):
    pass


class PostgresSwipeRepository(SwipeRepository):
    def __init__(self, db: Database) -> None:
        self._db = db

    def create(self, *, user_id: UUID, idea_id: UUID, direction: str, decision_time_ms: int | None) -> Swipe:
        with self._db.pool().connection() as conn:
            try:
                with conn.cursor(row_factory=dict_row) as cur:
                    cur.execute(
                        """
                        INSERT INTO swipes(user_id, idea_id, direction, decision_time_ms)
                        VALUES (%s, %s, %s, %s)
                        RETURNING *
                        """,
                        (user_id, idea_id, direction, decision_time_ms),
                    )
                    row = cur.fetchone()
                conn.commit()
            except UniqueViolation as ex:
                conn.rollback()
                raise DuplicateSwipeError("Swipe already recorded") from ex

        if not row:
            raise RuntimeError("Failed to create swipe")

        return Swipe(
            id=row["id"],
            user_id=row["user_id"],
            idea_id=row["idea_id"],
            direction=row["direction"],
            decision_time_ms=row.get("decision_time_ms"),
            created_at=row["created_at"],
        )
