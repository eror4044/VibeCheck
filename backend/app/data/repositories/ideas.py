from __future__ import annotations

from uuid import UUID

from psycopg.rows import dict_row
from psycopg.types.json import Jsonb

from app.data.db import Database
from app.domain.models import Idea
from app.domain.ports import IdeaRepository


class PostgresIdeaRepository(IdeaRepository):
    def __init__(self, db: Database) -> None:
        self._db = db

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
    ) -> Idea:
        tags_value = Jsonb(tags) if tags is not None else None
        links_value = Jsonb(links) if links is not None else None
        with self._db.pool().connection() as conn:
            with conn.cursor(row_factory=dict_row) as cur:
                cur.execute(
                    """
                    INSERT INTO ideas(
                      title,
                      short_pitch,
                      category,
                      tags,
                      media_url,
                      one_liner,
                      problem,
                      solution,
                      audience,
                      differentiator,
                      stage,
                      links
                    )
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    RETURNING *
                    """,
                    (
                        title,
                        short_pitch,
                        category,
                        tags_value,
                        media_url,
                        one_liner,
                        problem,
                        solution,
                        audience,
                        differentiator,
                        stage,
                        links_value,
                    ),
                )
                row = cur.fetchone()
            conn.commit()
        if not row:
            raise RuntimeError("Failed to create idea")
        return _to_idea(row)

    def get_next_for_user(self, *, user_id: UUID) -> Idea | None:
        with self._db.pool().connection() as conn:
            with conn.cursor(row_factory=dict_row) as cur:
                cur.execute(
                    """
                    SELECT i.*
                    FROM ideas i
                    WHERE NOT EXISTS (
                      SELECT 1 FROM swipes s
                      WHERE s.user_id = %s AND s.idea_id = i.id
                    )
                    ORDER BY i.created_at DESC
                    LIMIT 1
                    """,
                    (user_id,),
                )
                row = cur.fetchone()
        return _to_idea(row) if row else None

    def get_by_id(self, *, idea_id: UUID) -> Idea | None:
        with self._db.pool().connection() as conn:
            with conn.cursor(row_factory=dict_row) as cur:
                cur.execute("SELECT * FROM ideas WHERE id = %s", (idea_id,))
                row = cur.fetchone()
        return _to_idea(row) if row else None


def _to_idea(row: dict) -> Idea:
    tags = row.get("tags")
    return Idea(
        id=row["id"],
        title=row["title"],
        short_pitch=row["short_pitch"],
        category=row["category"],
        tags=tags,
        media_url=row["media_url"],
        one_liner=row.get("one_liner") or row["short_pitch"],
        problem=row.get("problem"),
        solution=row.get("solution"),
        audience=row.get("audience"),
        differentiator=row.get("differentiator"),
        stage=str(row.get("stage") or "idea"),
        links=row.get("links"),
        created_at=row["created_at"],
    )
