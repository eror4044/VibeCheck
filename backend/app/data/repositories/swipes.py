from __future__ import annotations

from uuid import UUID

from psycopg.errors import UniqueViolation
from psycopg.rows import dict_row

from app.data.db import Database
from app.domain.models import IdeaStats, Swipe, SwipeStats
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

    def get_user_stats(self, *, user_id: UUID) -> SwipeStats:
        with self._db.pool().connection() as conn:
            with conn.cursor(row_factory=dict_row) as cur:
                # Totals
                cur.execute(
                    """
                    SELECT
                      COUNT(*)::int AS total,
                      COUNT(*) FILTER (WHERE direction = 'vibe')::int AS vibes,
                      COUNT(*) FILTER (WHERE direction = 'no_vibe')::int AS no_vibes
                    FROM swipes WHERE user_id = %s
                    """,
                    (user_id,),
                )
                totals = cur.fetchone() or {}

                # By category
                cur.execute(
                    """
                    SELECT
                      i.category,
                      COUNT(*)::int AS total,
                      COUNT(*) FILTER (WHERE s.direction = 'vibe')::int AS vibes,
                      COUNT(*) FILTER (WHERE s.direction = 'no_vibe')::int AS no_vibes
                    FROM swipes s
                    JOIN ideas i ON i.id = s.idea_id
                    WHERE s.user_id = %s
                    GROUP BY i.category
                    ORDER BY total DESC
                    """,
                    (user_id,),
                )
                cat_rows = cur.fetchall()

        by_category = {}
        for r in cat_rows:
            by_category[r["category"]] = {
                "total": r["total"],
                "vibes": r["vibes"],
                "no_vibes": r["no_vibes"],
            }

        return SwipeStats(
            total_swipes=totals.get("total", 0),
            total_vibes=totals.get("vibes", 0),
            total_no_vibes=totals.get("no_vibes", 0),
            by_category=by_category,
        )

    def get_idea_stats(self, *, idea_id: UUID) -> IdeaStats:
        with self._db.pool().connection() as conn:
            with conn.cursor(row_factory=dict_row) as cur:
                cur.execute(
                    """
                    SELECT
                      COUNT(*)::int AS total,
                      COUNT(*) FILTER (WHERE direction = 'vibe')::int AS vibes,
                      COUNT(*) FILTER (WHERE direction = 'no_vibe')::int AS no_vibes
                    FROM swipes WHERE idea_id = %s
                    """,
                    (idea_id,),
                )
                row = cur.fetchone() or {}

        total = row.get("total", 0)
        vibes = row.get("vibes", 0)
        vibe_rate = (vibes / total * 100) if total > 0 else 0.0

        return IdeaStats(
            idea_id=idea_id,
            total_views=total,
            total_vibes=vibes,
            total_no_vibes=row.get("no_vibes", 0),
            vibe_rate=round(vibe_rate, 1),
        )
