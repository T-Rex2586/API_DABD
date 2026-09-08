from collections.abc import Generator

from psycopg import Connection
from psycopg_pool import ConnectionPool

pool: ConnectionPool | None = None

DSN = "user=postgres password=postgrespassword dbname=kampus host=localhost port=5432"


def init_db() -> None:
    global pool
    pool = ConnectionPool(DSN, min_size=2, max_size=10)


def get_db() -> Generator[Connection]:
    with pool.connection() as conn:
        yield conn
