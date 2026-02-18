from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.router import api_router
from app.api.social_ws import router as social_ws_router
from app.core.config import settings

app = FastAPI(title="BlakJaks Platform", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router)
app.include_router(social_ws_router)


@app.get("/health")
async def health():
    return {"status": "ok"}
