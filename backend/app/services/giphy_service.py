"""Giphy API service — search and trending GIFs with Redis caching.

Uses redis_service.py key helpers (gif_search_cache, GIF_TRENDING_CACHE) for
TTL-based caching so repeated identical searches do not hit the Giphy API.

Giphy docs: https://developers.giphy.com/docs/api/
"""

import logging
from typing import Any

import httpx

from app.core.config import settings
from app.services.redis_keys import (
    GIF_TRENDING_CACHE,
    TTL_GIF_SEARCH,
    TTL_GIF_TRENDING,
    gif_search_cache,
)

logger = logging.getLogger(__name__)

GIPHY_API_BASE = "https://api.giphy.com/v1/gifs"
_DEFAULT_LIMIT = 20
_DEFAULT_RATING = "pg-13"


def _extract_gif(raw: dict) -> dict:
    """Pull the fields we expose from a raw Giphy GIF object."""
    images = raw.get("images", {})
    fixed = images.get("fixed_height", {})
    original = images.get("original", {})
    return {
        "id": raw.get("id"),
        "title": raw.get("title"),
        "url": raw.get("url"),
        "preview_url": fixed.get("url") or original.get("url"),
        "preview_width": int(fixed.get("width") or 0),
        "preview_height": int(fixed.get("height") or 0),
        "mp4_url": fixed.get("mp4") or original.get("mp4"),
    }


async def _get_redis():
    from app.services.redis_client import get_redis
    return await get_redis()


async def search_gifs(
    query: str,
    limit: int = _DEFAULT_LIMIT,
    offset: int = 0,
    rating: str = _DEFAULT_RATING,
) -> list[dict[str, Any]]:
    """Search Giphy for GIFs matching a query string.

    Results are cached in Redis for TTL_GIF_SEARCH seconds.

    Args:
        query: Search term.
        limit: Max results (1–50).
        offset: Pagination offset.
        rating: Giphy content rating filter.

    Returns:
        List of simplified GIF dicts.
    """
    import json

    if not settings.GIPHY_API_KEY:
        logger.warning("GIPHY_API_KEY not configured — returning empty results")
        return []

    cache_key = gif_search_cache(query, limit, offset)

    try:
        redis = await _get_redis()
        cached = await redis.get(cache_key)
        if cached:
            return json.loads(cached)
    except Exception as exc:
        logger.warning("Giphy cache read failed: %s", exc)

    try:
        async with httpx.AsyncClient(timeout=10) as client:
            response = await client.get(
                f"{GIPHY_API_BASE}/search",
                params={
                    "api_key": settings.GIPHY_API_KEY,
                    "q": query,
                    "limit": min(limit, 50),
                    "offset": offset,
                    "rating": rating,
                    "lang": "en",
                },
            )
            response.raise_for_status()
            data = response.json()
    except httpx.HTTPStatusError as exc:
        logger.error("Giphy search API error %s: %s", exc.response.status_code, exc)
        return []
    except Exception as exc:
        logger.error("Giphy search request failed: %s", exc)
        return []

    gifs = [_extract_gif(g) for g in data.get("data", [])]

    try:
        redis = await _get_redis()
        await redis.setex(cache_key, TTL_GIF_SEARCH, json.dumps(gifs))
    except Exception as exc:
        logger.warning("Giphy cache write failed: %s", exc)

    return gifs


async def get_trending_gifs(
    limit: int = _DEFAULT_LIMIT,
    rating: str = _DEFAULT_RATING,
) -> list[dict[str, Any]]:
    """Return currently trending GIFs from Giphy.

    Results are cached for TTL_GIF_TRENDING seconds.

    Args:
        limit: Max results (1–50).
        rating: Giphy content rating filter.

    Returns:
        List of simplified GIF dicts.
    """
    import json

    if not settings.GIPHY_API_KEY:
        logger.warning("GIPHY_API_KEY not configured — returning empty results")
        return []

    try:
        redis = await _get_redis()
        cached = await redis.get(GIF_TRENDING_CACHE)
        if cached:
            return json.loads(cached)
    except Exception as exc:
        logger.warning("Giphy trending cache read failed: %s", exc)

    try:
        async with httpx.AsyncClient(timeout=10) as client:
            response = await client.get(
                f"{GIPHY_API_BASE}/trending",
                params={
                    "api_key": settings.GIPHY_API_KEY,
                    "limit": min(limit, 50),
                    "rating": rating,
                },
            )
            response.raise_for_status()
            data = response.json()
    except httpx.HTTPStatusError as exc:
        logger.error("Giphy trending API error %s: %s", exc.response.status_code, exc)
        return []
    except Exception as exc:
        logger.error("Giphy trending request failed: %s", exc)
        return []

    gifs = [_extract_gif(g) for g in data.get("data", [])]

    try:
        redis = await _get_redis()
        await redis.setex(GIF_TRENDING_CACHE, TTL_GIF_TRENDING, json.dumps(gifs))
    except Exception as exc:
        logger.warning("Giphy trending cache write failed: %s", exc)

    return gifs
