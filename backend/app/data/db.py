from __future__ import annotations

from psycopg_pool import ConnectionPool


class Database:
    def __init__(self, dsn: str) -> None:
        self._dsn = dsn
        self._pool: ConnectionPool | None = None

    def open(self) -> None:
        if self._pool is not None:
            return
        self._pool = ConnectionPool(conninfo=self._dsn, min_size=1, max_size=10, open=True)

    def close(self) -> None:
        if self._pool is None:
            return
        self._pool.close()
        self._pool = None

    def pool(self) -> ConnectionPool:
        if self._pool is None:
            raise RuntimeError("Database pool is not initialized")
        return self._pool
