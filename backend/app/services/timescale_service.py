"""Analytics service for treasury snapshots and transparency metrics.

Uses PostgreSQL native date_trunc() + GROUP BY for time-bucketed aggregations.
TimescaleDB is NOT required — the same queries work on standard PostgreSQL.

Tables used:
  - treasury_snapshots (created in migration 014)
  - transparency_metrics (created in migration 013)
"""

import logging
from datetime import datetime, timezone
from decimal import Decimal

import sqlalchemy as sa
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.transparency_metric import TransparencyMetric
from app.models.treasury_snapshot import TreasurySnapshot

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Treasury snapshots
# ---------------------------------------------------------------------------


async def write_treasury_snapshot(
    db: AsyncSession,
    pool_type: str,
    onchain_balance: Decimal,
    bank_balance: Decimal = Decimal("0"),
    metadata: dict | None = None,
) -> TreasurySnapshot:
    """Write a treasury snapshot row for a specific pool.

    Args:
        pool_type: One of "consumer", "affiliate", "wholesale".
        onchain_balance: On-chain USDT balance in human-readable units.
        bank_balance: Teller bank balance in USD.
        metadata: Optional dict of extra info (e.g. block number).

    Returns:
        The created TreasurySnapshot row.
    """
    snapshot = TreasurySnapshot(
        timestamp=datetime.now(timezone.utc),
        pool_type=pool_type,
        onchain_balance=onchain_balance,
        bank_balance=bank_balance,
        metadata_=metadata,
    )
    db.add(snapshot)
    await db.commit()
    await db.refresh(snapshot)
    logger.debug(
        "Wrote treasury snapshot: pool=%s onchain=%s bank=%s",
        pool_type, onchain_balance, bank_balance,
    )
    return snapshot


async def get_treasury_sparkline(
    db: AsyncSession,
    pool_type: str,
    days: int = 90,
) -> list[dict]:
    """Return daily aggregated treasury snapshots for sparkline charts.

    Uses PostgreSQL native date_trunc('day', timestamp) + AVG() for bucketing.

    Args:
        pool_type: Pool to query ("consumer", "affiliate", "wholesale").
        days: Number of days of history to return.

    Returns:
        List of {"date": str, "onchain_balance": float, "bank_balance": float}
        sorted ascending by date.
    """
    query = sa.text("""
        SELECT
            date_trunc('day', timestamp)::date AS day,
            AVG(onchain_balance) AS avg_onchain,
            AVG(bank_balance)    AS avg_bank
        FROM treasury_snapshots
        WHERE
            pool_type = :pool_type
            AND timestamp >= NOW() - INTERVAL '1 day' * :days
        GROUP BY day
        ORDER BY day ASC
    """)
    result = await db.execute(query, {"pool_type": pool_type, "days": days})
    rows = result.fetchall()
    return [
        {
            "date": str(row.day),
            "onchain_balance": float(row.avg_onchain or 0),
            "bank_balance": float(row.avg_bank or 0),
        }
        for row in rows
    ]


# ---------------------------------------------------------------------------
# Transparency metrics
# ---------------------------------------------------------------------------


async def write_transparency_metric(
    db: AsyncSession,
    metric_key: str,
    value: Decimal,
    metadata: dict | None = None,
) -> TransparencyMetric:
    """Write a transparency metric data point.

    Args:
        metric_key: Metric identifier (e.g. "global_scan_count", "comp_payout_24h").
        value: Numeric value for this metric at this point in time.
        metadata: Optional extra info.

    Returns:
        The created TransparencyMetric row.
    """
    metric = TransparencyMetric(
        timestamp=datetime.now(timezone.utc),
        metric_type=metric_key,
        metric_value=value,
        metadata_=metadata,
    )
    db.add(metric)
    await db.commit()
    await db.refresh(metric)
    return metric


async def get_metric_history(
    db: AsyncSession,
    metric_key: str,
    hours: int = 24,
) -> list[dict]:
    """Return hourly bucketed metric history for the past N hours.

    Args:
        metric_key: Metric type to query.
        hours: Number of hours of history.

    Returns:
        List of {"hour": str, "avg_value": float, "max_value": float}
        sorted ascending by hour.
    """
    query = sa.text("""
        SELECT
            date_trunc('hour', timestamp) AS hour,
            AVG(metric_value)             AS avg_value,
            MAX(metric_value)             AS max_value
        FROM transparency_metrics
        WHERE
            metric_type = :metric_key
            AND timestamp >= NOW() - INTERVAL '1 hour' * :hours
        GROUP BY hour
        ORDER BY hour ASC
    """)
    result = await db.execute(query, {"metric_key": metric_key, "hours": hours})
    rows = result.fetchall()
    return [
        {
            "hour": row.hour.isoformat() if row.hour else None,
            "avg_value": float(row.avg_value or 0),
            "max_value": float(row.max_value or 0),
        }
        for row in rows
    ]
