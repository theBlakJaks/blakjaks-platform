import logging
from contextlib import asynccontextmanager

import sentry_sdk
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from prometheus_fastapi_instrumentator import Instrumentator
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request

from app.api.auth import limiter
from app.api.router import api_router
from app.api.social_ws import manager as ws_manager, router as social_ws_router
from app.core.config import settings, validate_settings
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
        await ws_manager.start_subscriber()
        # Clean up any orphaned livestream Redis keys from previous runs
        try:
            from app.services.chat_buffer import cleanup_orphaned_stream_keys
            removed = await cleanup_orphaned_stream_keys()
            if removed:
                logger.info("Cleaned up %d orphaned stream keys on startup.", removed)
        except Exception:
            logger.warning("Failed to clean orphaned stream keys on startup.", exc_info=True)
    else:
        logger.warning("Redis unreachable on startup — dependent features will be unavailable.")

    yield

    # Shutdown
    await ws_manager.stop_subscriber()
    await close_redis()


# ---------------------------------------------------------------------------
# Security headers middleware
# ---------------------------------------------------------------------------

class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        response.headers["Permissions-Policy"] = "camera=(), microphone=(), geolocation=()"
        return response


# ---------------------------------------------------------------------------
# Cache-Control headers middleware
# ---------------------------------------------------------------------------

CACHE_CONTROL_RULES: dict[str, str] = {
    "/api/shop/products": "public, max-age=300",
    "/api/giphy/trending": "public, max-age=600",
    "/api/insights/overview": "public, max-age=30",
    "/api/governance/proposals": "public, max-age=60",
    "/api/social/channels": "private, max-age=60",
}


class CacheControlMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        response = await call_next(request)
        if request.method == "GET":
            path = request.url.path
            for prefix, header in CACHE_CONTROL_RULES.items():
                if path == prefix or path.startswith(prefix + "?"):
                    response.headers["Cache-Control"] = header
                    break
        return response


# ---------------------------------------------------------------------------
# App
# ---------------------------------------------------------------------------

app = FastAPI(title="BlakJaks Platform", version="0.1.0", lifespan=lifespan)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=len(settings.CORS_ORIGINS) > 0 and "*" not in settings.CORS_ORIGINS,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(SecurityHeadersMiddleware)
app.add_middleware(CacheControlMiddleware)

app.include_router(api_router)
app.include_router(social_ws_router)

from app.api import dev_tools
app.include_router(dev_tools.router, prefix="/dev", tags=["dev"])

# ---------------------------------------------------------------------------
# Prometheus — expose /metrics endpoint
# ---------------------------------------------------------------------------

Instrumentator().instrument(app).expose(app)


# ---------------------------------------------------------------------------
# Startup checks
# ---------------------------------------------------------------------------

@app.on_event("startup")
async def startup_checks():
    from app.core.config import validate_settings
    validate_settings(settings)
    if not settings.CORS_ORIGINS:
        import logging
        logging.getLogger("uvicorn").warning(
            "CORS_ORIGINS is empty — all cross-origin requests will be blocked. "
            "Set CORS_ORIGINS env var for web client access."
        )


# ---------------------------------------------------------------------------
# Health check
# ---------------------------------------------------------------------------

@app.get("/health")
async def health():
    redis_ok = await ping_redis()
    return {"status": "ok", "redis": "ok" if redis_ok else "unavailable"}
