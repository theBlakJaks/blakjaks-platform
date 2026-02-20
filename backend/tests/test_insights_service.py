"""Tests for insights_service.py.

All tests use AsyncMock / MagicMock — no real database or Redis connections
are made. External service calls (redis_service, comp_engine, teller_service,
timescale_service, blockchain) are patched at the insights_service module level.
"""

from __future__ import annotations

from decimal import Decimal
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

import app.services.insights_service as svc


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _make_db() -> AsyncMock:
    """Return a minimal AsyncSession mock whose execute() returns an empty result."""
    db = AsyncMock()
    # Default execute returns a result where scalar_one() → 0 and all() → []
    mock_result = MagicMock()
    mock_result.scalar_one.return_value = 0
    mock_result.scalars.return_value.all.return_value = []
    mock_result.all.return_value = []
    db.execute = AsyncMock(return_value=mock_result)
    return db


# ---------------------------------------------------------------------------
# get_overview
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_get_overview_returns_dict():
    """get_overview always returns a dict."""
    db = _make_db()
    with (
        patch("app.services.insights_service.get_global_scan_count", new=AsyncMock(return_value=42)),
        patch("app.services.insights_service.get_scan_velocity", new=AsyncMock(return_value={"per_minute": 1, "per_hour": 10})),
        patch("app.services.insights_service.get_recent_comp_recipients", new=AsyncMock(return_value=[])),
        patch("app.services.insights_service.get_treasury_stats", new=AsyncMock(return_value={"total_distributed": Decimal("500"), "total_members_comped": 5})),
    ):
        result = await svc.get_overview(db)
    assert isinstance(result, dict)


@pytest.mark.asyncio
async def test_get_overview_includes_global_scan_count():
    """get_overview result must contain the 'global_scan_count' key."""
    db = _make_db()
    with (
        patch("app.services.insights_service.get_global_scan_count", new=AsyncMock(return_value=999)),
        patch("app.services.insights_service.get_scan_velocity", new=AsyncMock(return_value={"per_minute": 0, "per_hour": 0})),
        patch("app.services.insights_service.get_recent_comp_recipients", new=AsyncMock(return_value=[])),
        patch("app.services.insights_service.get_treasury_stats", new=AsyncMock(return_value={"total_distributed": Decimal("0"), "total_members_comped": 0})),
    ):
        result = await svc.get_overview(db)
    assert "global_scan_count" in result
    assert result["global_scan_count"] == 999


@pytest.mark.asyncio
async def test_get_overview_does_not_raise_when_services_return_none():
    """get_overview must not raise even when all service calls fail."""
    db = _make_db()
    with (
        patch("app.services.insights_service.get_global_scan_count", new=AsyncMock(side_effect=Exception("redis down"))),
        patch("app.services.insights_service.get_scan_velocity", new=AsyncMock(side_effect=Exception("redis down"))),
        patch("app.services.insights_service.get_recent_comp_recipients", new=AsyncMock(side_effect=Exception("db error"))),
        patch("app.services.insights_service.get_treasury_stats", new=AsyncMock(side_effect=Exception("db error"))),
    ):
        # Should not raise; fallback values returned
        result = await svc.get_overview(db)
    assert isinstance(result, dict)
    assert result["global_scan_count"] == 0
    assert result["scan_velocity"] == {"per_minute": 0, "per_hour": 0}


# ---------------------------------------------------------------------------
# get_treasury_insights
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_get_treasury_insights_returns_dict():
    """get_treasury_insights always returns a dict."""
    db = _make_db()
    with (
        patch("app.services.insights_service.get_pool_balances", new=AsyncMock(return_value={"consumer": {"address": None, "balance": Decimal("0")}, "affiliate": {"address": None, "balance": Decimal("0")}, "wholesale": {"address": None, "balance": Decimal("0")}})),
        patch("app.services.insights_service.get_last_sync_status", new=AsyncMock(return_value=[])),
        patch("app.services.insights_service.get_treasury_sparkline", new=AsyncMock(return_value=[])),
        patch("app.services.insights_service.get_node_health", return_value={"connected": False}),
    ):
        result = await svc.get_treasury_insights(db)
    assert isinstance(result, dict)


@pytest.mark.asyncio
async def test_get_treasury_insights_includes_sparklines():
    """get_treasury_insights result must contain the 'sparklines' key."""
    db = _make_db()
    sample_sparkline = [{"date": "2026-01-01", "onchain_balance": 100.0, "bank_balance": 50.0}]
    with (
        patch("app.services.insights_service.get_pool_balances", new=AsyncMock(return_value={"consumer": {"address": "0x1", "balance": Decimal("100")}, "affiliate": {"address": "0x2", "balance": Decimal("5")}, "wholesale": {"address": "0x3", "balance": Decimal("5")}})),
        patch("app.services.insights_service.get_last_sync_status", new=AsyncMock(return_value=[])),
        patch("app.services.insights_service.get_treasury_sparkline", new=AsyncMock(return_value=sample_sparkline)),
        patch("app.services.insights_service.get_node_health", return_value={"connected": True, "block_number": 12345}),
    ):
        result = await svc.get_treasury_insights(db)
    assert "sparklines" in result
    assert "consumer" in result["sparklines"]
    assert "affiliate" in result["sparklines"]
    assert "wholesale" in result["sparklines"]


@pytest.mark.asyncio
async def test_get_treasury_insights_does_not_raise_when_services_fail():
    """get_treasury_insights must not raise even when all service calls fail."""
    db = _make_db()
    with (
        patch("app.services.insights_service.get_pool_balances", new=AsyncMock(side_effect=Exception("chain down"))),
        patch("app.services.insights_service.get_last_sync_status", new=AsyncMock(side_effect=Exception("teller down"))),
        patch("app.services.insights_service.get_treasury_sparkline", new=AsyncMock(side_effect=Exception("db error"))),
        patch("app.services.insights_service.get_node_health", side_effect=Exception("node down")),
    ):
        result = await svc.get_treasury_insights(db)
    assert isinstance(result, dict)
    assert "sparklines" in result


# ---------------------------------------------------------------------------
# get_systems_health
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_get_systems_health_returns_dict():
    """get_systems_health always returns a dict."""
    db = _make_db()
    with (
        patch("app.services.insights_service.get_scan_velocity", new=AsyncMock(return_value={"per_minute": 3, "per_hour": 50})),
        patch("app.services.insights_service.get_node_health", return_value={"connected": True}),
        patch("app.services.insights_service.get_last_sync_status", new=AsyncMock(return_value=[])),
    ):
        result = await svc.get_systems_health(db)
    assert isinstance(result, dict)


@pytest.mark.asyncio
async def test_get_systems_health_includes_scan_velocity():
    """get_systems_health result must contain the 'scan_velocity' key."""
    db = _make_db()
    expected_velocity = {"per_minute": 7, "per_hour": 120}
    with (
        patch("app.services.insights_service.get_scan_velocity", new=AsyncMock(return_value=expected_velocity)),
        patch("app.services.insights_service.get_node_health", return_value={"connected": True}),
        patch("app.services.insights_service.get_last_sync_status", new=AsyncMock(return_value=[])),
    ):
        result = await svc.get_systems_health(db)
    assert "scan_velocity" in result
    assert result["scan_velocity"] == expected_velocity


# ---------------------------------------------------------------------------
# get_comp_stats
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_get_comp_stats_returns_dict():
    """get_comp_stats always returns a dict."""
    db = _make_db()
    with patch(
        "app.services.insights_service.get_treasury_stats",
        new=AsyncMock(return_value={"total_distributed": Decimal("50000"), "total_members_comped": 200}),
    ):
        result = await svc.get_comp_stats(db)
    assert isinstance(result, dict)


@pytest.mark.asyncio
async def test_get_comp_stats_includes_prize_tiers():
    """get_comp_stats must contain 'prize_tiers' with the four threshold keys."""
    db = _make_db()
    with patch(
        "app.services.insights_service.get_treasury_stats",
        new=AsyncMock(return_value={"total_distributed": Decimal("0"), "total_members_comped": 0}),
    ):
        result = await svc.get_comp_stats(db)
    assert "prize_tiers" in result
    for key in ("100", "1000", "10000", "200000"):
        assert key in result["prize_tiers"]


# ---------------------------------------------------------------------------
# get_partner_stats
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_get_partner_stats_returns_dict():
    """get_partner_stats always returns a dict."""
    db = _make_db()
    result = await svc.get_partner_stats(db)
    assert isinstance(result, dict)


# ---------------------------------------------------------------------------
# get_activity_feed
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_get_activity_feed_returns_paginated_structure():
    """get_activity_feed must return a dict with 'items' and 'total' keys."""
    db = _make_db()
    result = await svc.get_activity_feed(db, hours=24, page=1, per_page=20)
    assert isinstance(result, dict)
    assert "items" in result
    assert "total" in result
    assert "page" in result
    assert "per_page" in result


@pytest.mark.asyncio
async def test_get_activity_feed_pagination_is_correct():
    """get_activity_feed page and per_page values are reflected in the output."""
    db = _make_db()
    result = await svc.get_activity_feed(db, hours=48, page=2, per_page=5)
    assert result["page"] == 2
    assert result["per_page"] == 5


@pytest.mark.asyncio
async def test_get_activity_feed_does_not_raise_when_db_empty():
    """get_activity_feed must not raise when the DB returns no rows."""
    db = _make_db()
    # All execute() calls return empty results (set up in _make_db)
    result = await svc.get_activity_feed(db, hours=24, page=1, per_page=20)
    assert result["total"] == 0
    assert result["items"] == []


# ---------------------------------------------------------------------------
# _mask_username helper
# ---------------------------------------------------------------------------


def test_mask_username_standard():
    """Standard name of 5+ chars gets first 2, ***, last 1."""
    assert svc._mask_username("Alice") == "Al***e"


def test_mask_username_short():
    """Single-char name results in char***char."""
    assert svc._mask_username("X") == "X***X"


def test_mask_username_none():
    """None name returns a safe placeholder."""
    assert svc._mask_username(None) == "M***r"
