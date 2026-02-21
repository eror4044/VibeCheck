from __future__ import annotations

import logging
from pathlib import Path

from psycopg import sql

from app.data.db import Database


logger = logging.getLogger(__name__)


def _ensure_migrations_table(db: Database) -> None:
    with db.pool().connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                CREATE TABLE IF NOT EXISTS schema_migrations (
                  version TEXT PRIMARY KEY,
                  applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
                );
                """
            )
        conn.commit()


def _get_applied_versions(db: Database) -> set[str]:
    with db.pool().connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT version FROM schema_migrations")
            rows = cur.fetchall()
    return {r[0] for r in rows}


def run_migrations(db: Database, *, migrations_dir: str) -> None:
    _ensure_migrations_table(db)
    applied = _get_applied_versions(db)

    path = Path(migrations_dir)
    if not path.exists():
        logger.warning("Migrations directory not found: %s", migrations_dir)
        return

    migration_files = sorted([p for p in path.iterdir() if p.is_file() and p.suffix == ".sql"])
    for migration in migration_files:
        version = migration.name
        if version in applied:
            continue

        sql_text = migration.read_text(encoding="utf-8")
        logger.info("Applying migration %s", version)

        with db.pool().connection() as conn:
            with conn.cursor() as cur:
                cur.execute(sql_text)
                cur.execute(
                    sql.SQL("INSERT INTO schema_migrations(version) VALUES ({v})").format(v=sql.Literal(version))
                )
            conn.commit()
