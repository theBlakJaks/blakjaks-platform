"""Application-level Redis operations for the BlakJaks platform.

All services must call functions defined here. No service should import or
call the Redis client directly — this module is the single authoritative
layer for all Redis interactions.
"""

from __future__ import annotations

import json
import logging
from datetime import datetime, timezone

from app.services.redis_client import get_redis
from app.services.redis_keys import (
    GIF_TRENDING_CACHE,
    GLOBAL_SCAN_COUNTER,
    LEADERBOARD_ALL_TIME,
    SCAN_VELOCITY_HOUR,
    SCAN_VELOCITY_MINUTE,
    TTL_EMOTE_SET,
    TTL_GIF_SEARCH,
    TTL_SCAN_VELOCITY_HOUR,
    TTL_SCAN_VELOCITY_MINUTE,
    emote_set_cache,
    gif_search_cache,
    leaderboard_monthly,
    unread_notifications,
)

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Global scan counter
# ---------------------------------------------------------------------------


async def increment_global_scan_counter() -> int:
    """Atomically increment the global scan counter and return the new value."""
    redis = await get_redis()
    return await redis.incr(GLOBAL_SCAN_COUNTER)


async def get_global_scan_count() -> int:
    """Return the current global scan count.

    Returns 0 if the key does not yet exist.
    """
    redis = await get_redis()
    value = await redis.get(GLOBAL_SCAN_COUNTER)
    return int(value) if value is not None else 0


# ---------------------------------------------------------------------------
# Leaderboards
# ---------------------------------------------------------------------------


def _current_year_month() -> str:
    """Return the current UTC year-month string, e.g. '2026-02'."""
    now = datetime.now(timezone.utc)
    return now.strftime("%Y-%m")


async def update_leaderboard(user_id: str, delta: int = 1) -> None:
    """Increment *user_id*'s score in both the monthly and all-time leaderboards.

    Args:
        user_id: The user's identifier (string form of UUID or integer ID).
        delta:   The amount to add to the user's score (default 1 per scan).
    """
    redis = await get_redis()
    year_month = _current_year_month()
    monthly_key = leaderboard_monthly(year_month)

    await redis.zincrby(monthly_key, delta, user_id)
    await redis.zincrby(LEADERBOARD_ALL_TIME, delta, user_id)


async def get_leaderboard(type: str, limit: int = 100) -> list[dict]:
    """Return the top *limit* entries from the requested leaderboard.

    Args:
        type:  ``"monthly"`` for the current month, ``"all_time"`` for the
               permanent leaderboard.
        limit: Maximum number of entries to return (default 100).

    Returns:
        A list of dicts sorted by descending score::

            [{"user_id": str, "score": int, "rank": int}, ...]

    Raises:
        ValueError: If *type* is not ``"monthly"`` or ``"all_time"``.
    """
    if type == "monthly":
        key = leaderboard_monthly(_current_year_month())
    elif type == "all_time":
        key = LEADERBOARD_ALL_TIME
    else:
        raise ValueError(f"Invalid leaderboard type: {type!r}. Must be 'monthly' or 'all_time'.")

    redis = await get_redis()
    # ZREVRANGE returns members highest-score-first; withscores yields (member, score) pairs.
    raw: list[tuple[str, float]] = await redis.zrevrange(key, 0, limit - 1, withscores=True)

    results: list[dict] = []
    for rank_index, (member, score) in enumerate(raw):
        results.append(
            {
                "user_id": member,
                "score": int(score),
                "rank": rank_index + 1,  # 1-based rank
            }
        )
    return results


async def get_user_rank(user_id: str, type: str) -> dict | None:
    """Return rank and score for *user_id* in the given leaderboard, or ``None``.

    Args:
        user_id: The user's identifier.
        type:    ``"monthly"`` or ``"all_time"``.

    Returns:
        ``{"rank": int, "score": int}`` (1-based rank) or ``None`` if the
        user has no score in the requested leaderboard.

    Raises:
        ValueError: If *type* is not ``"monthly"`` or ``"all_time"``.
    """
    if type == "monthly":
        key = leaderboard_monthly(_current_year_month())
    elif type == "all_time":
        key = LEADERBOARD_ALL_TIME
    else:
        raise ValueError(f"Invalid leaderboard type: {type!r}. Must be 'monthly' or 'all_time'.")

    redis = await get_redis()

    # ZREVRANK returns 0-based position from the highest score end, or None.
    rank_index = await redis.zrevrank(key, user_id)
    if rank_index is None:
        return None

    score = await redis.zscore(key, user_id)
    return {
        "rank": rank_index + 1,   # convert to 1-based
        "score": int(score),
    }


# ---------------------------------------------------------------------------
# Scan velocity (sliding-window counters)
# ---------------------------------------------------------------------------


async def track_scan_velocity() -> None:
    """Increment both the 1-minute and 1-hour sliding-window scan counters.

    Each counter is refreshed with its full TTL on every increment so that
    the key expires when traffic goes completely quiet for that window duration.
    """
    redis = await get_redis()

    await redis.incr(SCAN_VELOCITY_MINUTE)
    await redis.expire(SCAN_VELOCITY_MINUTE, TTL_SCAN_VELOCITY_MINUTE)

    await redis.incr(SCAN_VELOCITY_HOUR)
    await redis.expire(SCAN_VELOCITY_HOUR, TTL_SCAN_VELOCITY_HOUR)


async def get_scan_velocity() -> dict:
    """Return the current scan velocity for both windows.

    Returns:
        ``{"per_minute": int, "per_hour": int}``
        Missing keys (counter expired or never set) are returned as ``0``.
    """
    redis = await get_redis()
    per_minute_raw, per_hour_raw = await redis.mget(SCAN_VELOCITY_MINUTE, SCAN_VELOCITY_HOUR)
    return {
        "per_minute": int(per_minute_raw) if per_minute_raw is not None else 0,
        "per_hour": int(per_hour_raw) if per_hour_raw is not None else 0,
    }


# ---------------------------------------------------------------------------
# Unread notification counters
# ---------------------------------------------------------------------------


async def get_unread_count(user_id: str) -> int:
    """Return the unread notification count for *user_id*.

    Returns ``0`` if no counter exists yet.
    """
    redis = await get_redis()
    value = await redis.get(unread_notifications(user_id))
    return int(value) if value is not None else 0


async def increment_unread(user_id: str) -> int:
    """Atomically increment the unread notification count for *user_id*.

    Returns:
        The new unread count after incrementing.
    """
    redis = await get_redis()
    return await redis.incr(unread_notifications(user_id))


async def clear_unread(user_id: str) -> None:
    """Reset the unread notification count to ``0`` for *user_id*."""
    redis = await get_redis()
    await redis.set(unread_notifications(user_id), 0)


# ---------------------------------------------------------------------------
# 7TV emote set cache
# ---------------------------------------------------------------------------


async def cache_emote_set(set_id: str, data: dict) -> None:
    """Serialize and cache a 7TV emote set payload.

    Args:
        set_id: The 7TV emote set ID used as the cache key discriminator.
        data:   Arbitrary dict payload returned by the 7TV API.
    """
    redis = await get_redis()
    key = emote_set_cache(set_id)
    await redis.set(key, json.dumps(data), ex=TTL_EMOTE_SET)


async def get_cached_emote_set(set_id: str) -> dict | None:
    """Return a cached 7TV emote set, or ``None`` on a cache miss.

    Args:
        set_id: The 7TV emote set ID.

    Returns:
        Deserialized dict, or ``None`` if the key is absent or expired.
    """
    redis = await get_redis()
    raw = await redis.get(emote_set_cache(set_id))
    if raw is None:
        return None
    return json.loads(raw)


# ---------------------------------------------------------------------------
# Giphy search result cache
# ---------------------------------------------------------------------------


async def cache_gif_search(query: str, limit: int, offset: int, data: list) -> None:
    """Serialize and cache Giphy search results.

    Args:
        query:  The raw search query string.
        limit:  Number of results that were requested.
        offset: Pagination offset.
        data:   List of GIF objects returned by the Giphy API.
    """
    redis = await get_redis()
    key = gif_search_cache(query, limit, offset)
    await redis.set(key, json.dumps(data), ex=TTL_GIF_SEARCH)


async def get_cached_gif_search(query: str, limit: int, offset: int) -> list | None:
    """Return cached Giphy search results, or ``None`` on a cache miss.

    Args:
        query:  The raw search query string.
        limit:  Number of results that were requested.
        offset: Pagination offset.

    Returns:
        Deserialized list, or ``None`` if the key is absent or expired.
    """
    redis = await get_redis()
    raw = await redis.get(gif_search_cache(query, limit, offset))
    if raw is None:
        return None
    return json.loads(raw)


async def cache_gif_trending(data: list) -> None:
    """Serialize and cache trending Giphy GIFs.

    Args:
        data: List of trending GIF objects returned by the Giphy API.
    """
    redis = await get_redis()
    await redis.set(GIF_TRENDING_CACHE, json.dumps(data), ex=TTL_GIF_SEARCH)


async def get_cached_gif_trending() -> list | None:
    """Return cached trending GIFs, or ``None`` on a cache miss.

    Returns:
        Deserialized list, or ``None`` if the key is absent or expired.
    """
    redis = await get_redis()
    raw = await redis.get(GIF_TRENDING_CACHE)
    if raw is None:
        return None
    return json.loads(raw)
