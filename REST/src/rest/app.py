from contextlib import asynccontextmanager

from fastapi import FastAPI

from rest.database import init_db
from rest.routes import router


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    yield


app = FastAPI(title="Kampus API", lifespan=lifespan)
app.include_router(router)
