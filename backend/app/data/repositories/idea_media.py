from __future__ import annotations

from uuid import UUID

from psycopg.rows import dict_row

from app.data.db import Database
from app.domain.models import IdeaMedia
from app.domain.ports import IdeaMediaRepository


class PostgresIdeaMediaRepository(IdeaMediaRepository):
    def __init__(self, db: Database) -> None:
        self._db = db

    def add(self, *, idea_id: UUID, media_type: str, s3_key: str, position: int) -> IdeaMedia:
        with self._db.pool().connection() as conn:
            with conn.cursor(row_factory=dict_row) as cur:
                cur.execute(
                    """
                    INSERT INTO idea_media(idea_id, media_type, s3_key, position)
                    VALUES (%s, %s, %s, %s)
                    RETURNING *
                    """,
                    (idea_id, media_type, s3_key, position),
                )
                row = cur.fetchone()
            conn.commit()
        if not row:
            raise RuntimeError("Failed to add idea media")
        return _to_media(row)

    def list_by_idea(self, *, idea_id: UUID) -> list[IdeaMedia]:
        with self._db.pool().connection() as conn:
            with conn.cursor(row_factory=dict_row) as cur:
                cur.execute(
                    "SELECT * FROM idea_media WHERE idea_id = %s ORDER BY position",
                    (idea_id,),
                )
                rows = cur.fetchall()
        return [_to_media(r) for r in rows]

    def delete(self, *, media_id: UUID, idea_id: UUID) -> bool:
        with self._db.pool().connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "DELETE FROM idea_media WHERE id = %s AND idea_id = %s",
                    (media_id, idea_id),
                )
                deleted = cur.rowcount > 0
            conn.commit()
        return deleted

    def reorder(self, *, idea_id: UUID, media_ids: list[UUID]) -> None:
        with self._db.pool().connection() as conn:
            with conn.cursor() as cur:
                for idx, mid in enumerate(media_ids):
                    cur.execute(
                        "UPDATE idea_media SET position = %s WHERE id = %s AND idea_id = %s",
                        (idx, mid, idea_id),
                    )
            conn.commit()


def _to_media(row: dict) -> IdeaMedia:
    return IdeaMedia(
        id=row["id"],
        idea_id=row["idea_id"],
        media_type=row["media_type"],
        s3_key=row["s3_key"],
        position=row["position"],
        created_at=row["created_at"],
    )
