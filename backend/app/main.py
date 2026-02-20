import logging
from contextlib import asynccontextmanager

import sentry_sdk
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from prometheus_fastapi_instrumentator import Instrumentator

from app.api.router import api_router
from app.api.social_ws import router as social_ws_router
from app.core.config import settings
from app.services.redis_client import close_redis, get_redis, ping_redis

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Sentry — initialise early; no-op when SENTRY_DSN is blank (dev / test)
# ---------------------------------------------------------------------------
if settings.SENTRY_DSN:
    sentry_sdk.init(
        dsn=settings.SENTRY_DSN,
        environment=settings.SENTRY_ENVIRONMENT,
        release=settings.SENTRY_RELEASE or None,
        traces_sample_rate=settings.SENTRY_TRACES_SAMPLE_RATE,
        integrations=[],  # FastAPI integration registered automatically by SDK
    )
    logger.info("Sentry initialised — environment=%s", settings.SENTRY_ENVIRONMENT)
else:
    logger.info("Sentry DSN not set — error tracking disabled (development mode).")


# ---------------------------------------------------------------------------
# FastAPI lifespan (startup / shutdown)
# ---------------------------------------------------------------------------

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    redis_ok = await ping_redis()
    if redis_ok:
        logger.info("Redis connection verified on startup.")
    else:
        logger.warning("Redis unreachable on startup — dependent features will be unavailable.")

    yield

    # Shutdown
    await close_redis()


# ---------------------------------------------------------------------------
# App
# ---------------------------------------------------------------------------

app = FastAPI(title="BlakJaks Platform", version="0.1.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router)
app.include_router(social_ws_router)

# ---------------------------------------------------------------------------
# Prometheus — expose /metrics endpoint
# ---------------------------------------------------------------------------

Instrumentator().instrument(app).expose(app)


# ---------------------------------------------------------------------------
# Health check
# ---------------------------------------------------------------------------

@app.get("/health")
async def health():
    redis_ok = await ping_redis()
    return {"status": "ok", "redis": "ok" if redis_ok else "unavailable"}
