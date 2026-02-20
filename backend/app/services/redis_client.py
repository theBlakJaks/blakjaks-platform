"""Async Redis client singleton.

In GKE environments, settings.REDIS_URL points to Cloud Memorystore
(10.96.113.3:6379). In local dev, it points to the docker-compose Redis
container (redis://localhost:6379/0 or redis://redis:6379/0 inside compose).

Usage:
    from app.services.redis_client import get_redis

    redis = await get_redis()
    await redis.set("key", "value", ex=60)
"""

from __future__ import annotations

import logging
from typing import TYPE_CHECKING

import redis.asyncio as aioredis

from app.core.config import settings

if TYPE_CHECKING:
    pass

logger = logging.getLogger(__name__)

_redis_client: aioredis.Redis | None = None


async def get_redis() -> aioredis.Redis:
    """Return the singleton async Redis client, initialising it on first call."""
    global _redis_client
    if _redis_client is None:
        _redis_client = aioredis.from_url(
            settings.REDIS_URL,
            encoding="utf-8",
            decode_responses=True,
            ssl=settings.REDIS_SSL_ENABLED,
        )
        logger.info("Redis client initialised — %s", settings.REDIS_URL)
    return _redis_client


async def close_redis() -> None:
    """Close the Redis connection pool. Called on FastAPI shutdown."""
    global _redis_client
    if _redis_client is not None:
        await _redis_client.aclose()
        _redis_client = None
        logger.info("Redis client closed.")


async def ping_redis() -> bool:
    """Return True if the Redis server is reachable, False otherwise."""
    try:
        client = await get_redis()
        return await client.ping()
    except Exception as exc:
        logger.warning("Redis ping failed: %s", exc)
        return False
