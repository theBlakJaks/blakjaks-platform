"""Redis key pattern constants and TTL values.

All Redis key strings must be built using these constants and functions.
No service should ever hardcode a Redis key string directly.
"""

# ---------------------------------------------------------------------------
# TTL constants (seconds)
# ---------------------------------------------------------------------------

TTL_EMOTE_SET = 3600          # 1 hour — 7TV emote set cache
TTL_SCAN_VELOCITY_MINUTE = 60    # 1 minute sliding window
TTL_SCAN_VELOCITY_HOUR = 3600    # 1 hour sliding window
TTL_UNREAD_NOTIFICATIONS = 0     # no TTL — persists until cleared
TTL_GIF_SEARCH = 300             # 5 minutes — Giphy search results
TTL_LEADERBOARD_MONTHLY = 0      # no TTL — expires via monthly reset
TTL_LEADERBOARD_ALL_TIME = 0     # no TTL — permanent
TTL_GLOBAL_SCAN_COUNTER = 0      # no TTL — permanent counter

# ---------------------------------------------------------------------------
# Global counters
# ---------------------------------------------------------------------------

GLOBAL_SCAN_COUNTER = "blakjaks:scans:global_total"
"""Monotonically increasing count of all-time scan submissions."""

# ---------------------------------------------------------------------------
# Leaderboard keys
# ---------------------------------------------------------------------------

LEADERBOARD_ALL_TIME = "blakjaks:leaderboard:all_time"
"""Sorted set — member: user_id (str), score: cumulative scan count."""


def leaderboard_monthly(year_month: str) -> str:
    """Return the Redis key for the monthly leaderboard sorted set.

    Args:
        year_month: ISO year-month string, e.g. "2026-02".

    Returns:
        Key string like "blakjaks:leaderboard:monthly:2026-02".
    """
    return f"blakjaks:leaderboard:monthly:{year_month}"


# ---------------------------------------------------------------------------
# Scan velocity keys (sliding window counters)
# ---------------------------------------------------------------------------

SCAN_VELOCITY_MINUTE = "blakjaks:scans:velocity:1m"
"""Number of scans in the last 60 seconds (sliding window counter)."""

SCAN_VELOCITY_HOUR = "blakjaks:scans:velocity:1h"
"""Number of scans in the last 3600 seconds (sliding window counter)."""

# ---------------------------------------------------------------------------
# Per-user keys
# ---------------------------------------------------------------------------


def unread_notifications(user_id: str | int) -> str:
    """Return the Redis key for a user's unread notification count.

    Args:
        user_id: The user's UUID or integer ID.

    Returns:
        Key string like "blakjaks:user:{user_id}:unread_notifications".
    """
    return f"blakjaks:user:{user_id}:unread_notifications"


# ---------------------------------------------------------------------------
# Emote cache keys
# ---------------------------------------------------------------------------


def emote_set_cache(set_id: str) -> str:
    """Return the Redis key for a cached 7TV emote set.

    Args:
        set_id: The 7TV emote set ID.

    Returns:
        Key string like "blakjaks:emotes:set:{set_id}".
    """
    return f"blakjaks:emotes:set:{set_id}"


# ---------------------------------------------------------------------------
# GIF search cache keys
# ---------------------------------------------------------------------------


def gif_search_cache(query: str, limit: int, offset: int) -> str:
    """Return the Redis key for a cached Giphy search result.

    Args:
        query: The search query string.
        limit: Number of results requested.
        offset: Pagination offset.

    Returns:
        Key string like "blakjaks:giphy:search:{query}:{limit}:{offset}".
    """
    safe_query = query.lower().replace(" ", "_")
    return f"blakjaks:giphy:search:{safe_query}:{limit}:{offset}"


GIF_TRENDING_CACHE = "blakjaks:giphy:trending"
"""Cache key for Giphy trending GIFs (shared across all users)."""
