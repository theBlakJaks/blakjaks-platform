"""Tests for redis_service.py.

All tests use a FakeRedis instance injected via a pytest fixture that patches
``get_redis`` in the redis_service module.  No real Redis connection is made.
"""

from __future__ import annotations

from unittest.mock import AsyncMock, patch

import pytest
from fakeredis.aioredis import FakeRedis

import app.services.redis_service as svc


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
async def fake_redis() -> FakeRedis:
    """Return a fresh FakeRedis instance for each test."""
    return FakeRedis(decode_responses=True)


@pytest.fixture(autouse=True)
def patch_get_redis(fake_redis: FakeRedis):
    """Patch ``get_redis`` so every service call hits the FakeRedis instance."""
    # get_redis is an async function that returns the client; wrap the instance
    # in an AsyncMock so ``await get_redis()`` returns fake_redis.
    async_getter = AsyncMock(return_value=fake_redis)
    with patch.object(svc, "get_redis", async_getter):
        yield


# ---------------------------------------------------------------------------
# Global scan counter
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_increment_global_scan_counter_starts_at_one():
    """First increment on a fresh key returns 1."""
    result = await svc.increment_global_scan_counter()
    assert result == 1


@pytest.mark.asyncio
async def test_increment_global_scan_counter_is_monotonic():
    """Repeated increments return sequential values."""
    first = await svc.increment_global_scan_counter()
    second = await svc.increment_global_scan_counter()
    third = await svc.increment_global_scan_counter()
    assert first == 1
    assert second == 2
    assert third == 3


@pytest.mark.asyncio
async def test_get_global_scan_count_returns_zero_when_absent():
    """Returns 0 when the counter key has never been written."""
    count = await svc.get_global_scan_count()
    assert count == 0


@pytest.mark.asyncio
async def test_get_global_scan_count_reflects_increments():
    """get_global_scan_count tracks the value set by increments."""
    await svc.increment_global_scan_counter()
    await svc.increment_global_scan_counter()
    count = await svc.get_global_scan_count()
    assert count == 2


# ---------------------------------------------------------------------------
# Leaderboards
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_update_leaderboard_increments_score():
    """Updating the leaderboard for a user raises their score."""
    await svc.update_leaderboard("user-1", delta=5)
    board = await svc.get_leaderboard("all_time")
    assert len(board) == 1
    assert board[0]["user_id"] == "user-1"
    assert board[0]["score"] == 5


@pytest.mark.asyncio
async def test_get_leaderboard_returns_sorted_results():
    """Leaderboard entries are returned in descending score order."""
    await svc.update_leaderboard("user-low", delta=3)
    await svc.update_leaderboard("user-high", delta=10)
    await svc.update_leaderboard("user-mid", delta=6)

    board = await svc.get_leaderboard("all_time")

    assert len(board) == 3
    scores = [entry["score"] for entry in board]
    assert scores == sorted(scores, reverse=True), "Scores must be in descending order"
    assert board[0]["user_id"] == "user-high"
    assert board[1]["user_id"] == "user-mid"
    assert board[2]["user_id"] == "user-low"


@pytest.mark.asyncio
async def test_get_leaderboard_rank_is_one_based():
    """Rank field in each entry should be 1-based."""
    await svc.update_leaderboard("alpha", delta=5)
    await svc.update_leaderboard("beta", delta=3)

    board = await svc.get_leaderboard("all_time")
    assert board[0]["rank"] == 1
    assert board[1]["rank"] == 2


@pytest.mark.asyncio
async def test_get_leaderboard_limit_is_respected():
    """Only the top *limit* entries are returned."""
    for i in range(10):
        await svc.update_leaderboard(f"user-{i}", delta=i + 1)

    board = await svc.get_leaderboard("all_time", limit=3)
    assert len(board) == 3


@pytest.mark.asyncio
async def test_get_leaderboard_monthly_vs_all_time_are_independent():
    """Monthly and all-time leaderboards are separate sorted sets."""
    await svc.update_leaderboard("user-a", delta=10)

    all_time = await svc.get_leaderboard("all_time")
    monthly = await svc.get_leaderboard("monthly")

    # Both should contain user-a because update_leaderboard writes to both
    assert any(e["user_id"] == "user-a" for e in all_time)
    assert any(e["user_id"] == "user-a" for e in monthly)


@pytest.mark.asyncio
async def test_get_leaderboard_invalid_type_raises():
    """An unknown leaderboard type raises ValueError."""
    with pytest.raises(ValueError, match="Invalid leaderboard type"):
        await svc.get_leaderboard("unknown")


@pytest.mark.asyncio
async def test_get_user_rank_returns_none_when_absent():
    """Returns None when the user has no score in the leaderboard."""
    result = await svc.get_user_rank("nonexistent-user", "all_time")
    assert result is None


@pytest.mark.asyncio
async def test_get_user_rank_returns_correct_rank_and_score():
    """Returns correct 1-based rank and score for a ranked user."""
    await svc.update_leaderboard("top-user", delta=20)
    await svc.update_leaderboard("second-user", delta=10)

    rank_data = await svc.get_user_rank("top-user", "all_time")
    assert rank_data is not None
    assert rank_data["rank"] == 1
    assert rank_data["score"] == 20

    rank_data_second = await svc.get_user_rank("second-user", "all_time")
    assert rank_data_second is not None
    assert rank_data_second["rank"] == 2
    assert rank_data_second["score"] == 10


@pytest.mark.asyncio
async def test_get_user_rank_invalid_type_raises():
    """An unknown leaderboard type raises ValueError."""
    with pytest.raises(ValueError, match="Invalid leaderboard type"):
        await svc.get_user_rank("some-user", "bad_type")


# ---------------------------------------------------------------------------
# Scan velocity
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_track_scan_velocity_increments_both_counters():
    """track_scan_velocity bumps both the minute and hour counters."""
    await svc.track_scan_velocity()
    velocity = await svc.get_scan_velocity()
    assert velocity["per_minute"] == 1
    assert velocity["per_hour"] == 1


@pytest.mark.asyncio
async def test_track_scan_velocity_accumulates():
    """Multiple calls accumulate in both counters."""
    for _ in range(5):
        await svc.track_scan_velocity()
    velocity = await svc.get_scan_velocity()
    assert velocity["per_minute"] == 5
    assert velocity["per_hour"] == 5


@pytest.mark.asyncio
async def test_get_scan_velocity_returns_zeros_when_absent():
    """Returns zero for both windows when the keys have never been written."""
    velocity = await svc.get_scan_velocity()
    assert velocity == {"per_minute": 0, "per_hour": 0}


# ---------------------------------------------------------------------------
# Unread notifications
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_get_unread_count_returns_zero_when_absent():
    """Returns 0 when no unread count has been stored for the user."""
    count = await svc.get_unread_count("user-xyz")
    assert count == 0


@pytest.mark.asyncio
async def test_increment_unread_returns_new_count():
    """increment_unread returns the new value after each increment."""
    first = await svc.increment_unread("user-abc")
    second = await svc.increment_unread("user-abc")
    assert first == 1
    assert second == 2


@pytest.mark.asyncio
async def test_clear_unread_zeros_the_count():
    """clear_unread sets the unread counter to 0."""
    await svc.increment_unread("user-def")
    await svc.increment_unread("user-def")
    await svc.clear_unread("user-def")
    count = await svc.get_unread_count("user-def")
    assert count == 0


@pytest.mark.asyncio
async def test_unread_counters_are_per_user():
    """Unread counts for different users do not interfere with each other."""
    await svc.increment_unread("user-1")
    await svc.increment_unread("user-1")
    await svc.increment_unread("user-2")

    assert await svc.get_unread_count("user-1") == 2
    assert await svc.get_unread_count("user-2") == 1


# ---------------------------------------------------------------------------
# Emote set cache
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_cache_emote_set_round_trip():
    """Cached emote set is returned correctly on a cache hit."""
    payload = {"id": "set-001", "emotes": [{"name": "PauseChamp", "id": "emote-1"}]}
    await svc.cache_emote_set("set-001", payload)
    result = await svc.get_cached_emote_set("set-001")
    assert result == payload


@pytest.mark.asyncio
async def test_get_cached_emote_set_returns_none_on_miss():
    """Returns None when the emote set has not been cached."""
    result = await svc.get_cached_emote_set("nonexistent-set")
    assert result is None


@pytest.mark.asyncio
async def test_cache_emote_set_different_ids_are_independent():
    """Different set IDs are stored and retrieved independently."""
    data_a = {"id": "set-a", "emotes": []}
    data_b = {"id": "set-b", "emotes": [{"name": "OMEGALUL"}]}
    await svc.cache_emote_set("set-a", data_a)
    await svc.cache_emote_set("set-b", data_b)
    assert await svc.get_cached_emote_set("set-a") == data_a
    assert await svc.get_cached_emote_set("set-b") == data_b


# ---------------------------------------------------------------------------
# GIF search cache
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_cache_gif_search_round_trip():
    """Cached GIF search results are returned correctly on a cache hit."""
    results = [{"id": "gif-1", "url": "https://media.giphy.com/gif1.gif"}]
    await svc.cache_gif_search("pizza", 10, 0, results)
    cached = await svc.get_cached_gif_search("pizza", 10, 0)
    assert cached == results


@pytest.mark.asyncio
async def test_get_cached_gif_search_returns_none_on_miss():
    """Returns None when the query has not been cached."""
    result = await svc.get_cached_gif_search("uncached query", 10, 0)
    assert result is None


@pytest.mark.asyncio
async def test_cache_gif_search_different_params_are_independent():
    """Different query/limit/offset combinations are cached independently."""
    data_a = [{"id": "a"}]
    data_b = [{"id": "b"}]
    await svc.cache_gif_search("cats", 10, 0, data_a)
    await svc.cache_gif_search("cats", 10, 10, data_b)
    assert await svc.get_cached_gif_search("cats", 10, 0) == data_a
    assert await svc.get_cached_gif_search("cats", 10, 10) == data_b


# ---------------------------------------------------------------------------
# GIF trending cache
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_cache_gif_trending_round_trip():
    """Cached trending GIFs are returned correctly on a cache hit."""
    trending = [{"id": "trend-1"}, {"id": "trend-2"}]
    await svc.cache_gif_trending(trending)
    cached = await svc.get_cached_gif_trending()
    assert cached == trending


@pytest.mark.asyncio
async def test_get_cached_gif_trending_returns_none_on_miss():
    """Returns None when trending GIFs have not been cached."""
    result = await svc.get_cached_gif_trending()
    assert result is None


@pytest.mark.asyncio
async def test_cache_gif_trending_overwrites_previous():
    """Caching new trending data replaces the old payload."""
    old = [{"id": "old-gif"}]
    new = [{"id": "new-gif-1"}, {"id": "new-gif-2"}]
    await svc.cache_gif_trending(old)
    await svc.cache_gif_trending(new)
    cached = await svc.get_cached_gif_trending()
    assert cached == new
