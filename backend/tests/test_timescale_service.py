"""Tests for timescale_service.py — PostgreSQL native time-series analytics."""

import pytest
from decimal import Decimal
from unittest.mock import AsyncMock, MagicMock, patch


@pytest.mark.asyncio
async def test_write_treasury_snapshot_creates_row():
    from app.services.timescale_service import write_treasury_snapshot
    from app.models.treasury_snapshot import TreasurySnapshot

    mock_db = AsyncMock()
    mock_snapshot = MagicMock(spec=TreasurySnapshot)
    mock_snapshot.pool_type = "consumer"
    mock_snapshot.onchain_balance = Decimal("100.0")

    mock_db.add = MagicMock()
    mock_db.commit = AsyncMock()
    mock_db.refresh = AsyncMock(side_effect=lambda obj: None)

    with patch("app.services.timescale_service.TreasurySnapshot", return_value=mock_snapshot):
        result = await write_treasury_snapshot(mock_db, "consumer", Decimal("100.0"))

    mock_db.add.assert_called_once()
    mock_db.commit.assert_called_once()


@pytest.mark.asyncio
async def test_write_transparency_metric_creates_row():
    from app.services.timescale_service import write_transparency_metric

    mock_db = AsyncMock()
    mock_db.add = MagicMock()
    mock_db.commit = AsyncMock()
    mock_db.refresh = AsyncMock(side_effect=lambda obj: None)

    await write_transparency_metric(mock_db, "global_scan_count", Decimal("42000"))

    mock_db.add.assert_called_once()
    mock_db.commit.assert_called_once()


@pytest.mark.asyncio
async def test_get_treasury_sparkline_returns_list():
    from app.services.timescale_service import get_treasury_sparkline
    from datetime import date

    mock_row = MagicMock()
    mock_row.day = date(2026, 2, 1)
    mock_row.avg_onchain = Decimal("500.0")
    mock_row.avg_bank = Decimal("10000.0")

    mock_result = MagicMock()
    mock_result.fetchall.return_value = [mock_row]

    mock_db = AsyncMock()
    mock_db.execute = AsyncMock(return_value=mock_result)

    result = await get_treasury_sparkline(mock_db, "consumer", days=30)

    assert isinstance(result, list)
    assert len(result) == 1
    assert result[0]["date"] == "2026-02-01"
    assert result[0]["onchain_balance"] == 500.0
    assert result[0]["bank_balance"] == 10000.0


@pytest.mark.asyncio
async def test_get_metric_history_returns_list():
    from app.services.timescale_service import get_metric_history
    from datetime import datetime, timezone

    mock_row = MagicMock()
    mock_row.hour = datetime(2026, 2, 20, 12, 0, 0, tzinfo=timezone.utc)
    mock_row.avg_value = Decimal("1500.0")
    mock_row.max_value = Decimal("2000.0")

    mock_result = MagicMock()
    mock_result.fetchall.return_value = [mock_row]

    mock_db = AsyncMock()
    mock_db.execute = AsyncMock(return_value=mock_result)

    result = await get_metric_history(mock_db, "global_scan_count", hours=24)

    assert isinstance(result, list)
    assert len(result) == 1
    assert result[0]["avg_value"] == 1500.0
    assert result[0]["max_value"] == 2000.0


@pytest.mark.asyncio
async def test_get_treasury_sparkline_empty_returns_empty_list():
    from app.services.timescale_service import get_treasury_sparkline

    mock_result = MagicMock()
    mock_result.fetchall.return_value = []

    mock_db = AsyncMock()
    mock_db.execute = AsyncMock(return_value=mock_result)

    result = await get_treasury_sparkline(mock_db, "consumer")
    assert result == []
