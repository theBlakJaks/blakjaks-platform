"""Tests for redis_keys.py — verifies key patterns return expected strings."""

import pytest

from app.services.redis_keys import (
    GLOBAL_SCAN_COUNTER,
    LEADERBOARD_ALL_TIME,
    SCAN_VELOCITY_HOUR,
    SCAN_VELOCITY_MINUTE,
    TTL_EMOTE_SET,
    TTL_GIF_SEARCH,
    TTL_SCAN_VELOCITY_HOUR,
    TTL_SCAN_VELOCITY_MINUTE,
    GIF_TRENDING_CACHE,
    emote_set_cache,
    gif_search_cache,
    leaderboard_monthly,
    unread_notifications,
)


def test_global_scan_counter_constant():
    assert GLOBAL_SCAN_COUNTER == "blakjaks:scans:global_total"


def test_leaderboard_all_time_constant():
    assert LEADERBOARD_ALL_TIME == "blakjaks:leaderboard:all_time"


def test_leaderboard_monthly_format():
    key = leaderboard_monthly("2026-02")
    assert key == "blakjaks:leaderboard:monthly:2026-02"


def test_leaderboard_monthly_different_months():
    assert leaderboard_monthly("2026-01") != leaderboard_monthly("2026-02")


def test_scan_velocity_keys_are_different():
    assert SCAN_VELOCITY_MINUTE != SCAN_VELOCITY_HOUR


def test_scan_velocity_minute_constant():
    assert SCAN_VELOCITY_MINUTE == "blakjaks:scans:velocity:1m"


def test_scan_velocity_hour_constant():
    assert SCAN_VELOCITY_HOUR == "blakjaks:scans:velocity:1h"


def test_unread_notifications_with_string_user_id():
    key = unread_notifications("user-123")
    assert key == "blakjaks:user:user-123:unread_notifications"


def test_unread_notifications_with_int_user_id():
    key = unread_notifications(42)
    assert key == "blakjaks:user:42:unread_notifications"


def test_unread_notifications_different_users():
    assert unread_notifications("a") != unread_notifications("b")


def test_emote_set_cache_format():
    key = emote_set_cache("abc123")
    assert key == "blakjaks:emotes:set:abc123"


def test_emote_set_cache_different_ids():
    assert emote_set_cache("set1") != emote_set_cache("set2")


def test_gif_search_cache_format():
    key = gif_search_cache("pizza", 10, 0)
    assert key == "blakjaks:giphy:search:pizza:10:0"


def test_gif_search_cache_normalizes_spaces():
    key = gif_search_cache("hot dog", 10, 0)
    assert "hot_dog" in key


def test_gif_search_cache_different_params():
    assert gif_search_cache("pizza", 10, 0) != gif_search_cache("pizza", 10, 10)


def test_gif_trending_cache_constant():
    assert GIF_TRENDING_CACHE == "blakjaks:giphy:trending"


def test_ttl_emote_set():
    assert TTL_EMOTE_SET == 3600


def test_ttl_gif_search():
    assert TTL_GIF_SEARCH == 300


def test_ttl_velocity_minute():
    assert TTL_SCAN_VELOCITY_MINUTE == 60


def test_ttl_velocity_hour():
    assert TTL_SCAN_VELOCITY_HOUR == 3600
