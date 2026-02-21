"""Insights aggregator service for the BlakJaks transparency dashboard.

All functions are async and accept a db: AsyncSession argument.
All functions catch exceptions gracefully and return partial data rather than
raising — callers (API endpoints) receive whatever data is available.
"""

from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.affiliate import Affiliate
from app.models.tier import Tier
from app.models.tier_history import TierHistory
from app.models.transaction import Transaction
from app.models.user import User
from app.models.wholesale_account import WholesaleAccount

# Module-level service imports — required for test patching
# These are imported here so tests can patch them at the module level.
# The try/except guards prevent import failures from crashing the module.
try:
    from app.services.redis_service import get_global_scan_count, get_scan_velocity
except ImportError:
    get_global_scan_count = None  # type: ignore[assignment]
    get_scan_velocity = None  # type: ignore[assignment]

try:
    from app.services.comp_engine import (
        get_pool_balances,
        get_recent_comp_recipients,
        get_treasury_stats,
    )
except ImportError:
    get_pool_balances = None  # type: ignore[assignment]
    get_recent_comp_recipients = None  # type: ignore[assignment]
    get_treasury_stats = None  # type: ignore[assignment]

try:
    from app.services.teller_service import get_last_sync_status
except ImportError:
    get_last_sync_status = None  # type: ignore[assignment]

try:
    from app.services.timescale_service import get_treasury_sparkline
except ImportError:
    get_treasury_sparkline = None  # type: ignore[assignment]

try:
    from app.services.blockchain import get_node_health
except ImportError:
    get_node_health = None  # type: ignore[assignment]

logger = logging.getLogger(__name__)

# Crypto comp milestone thresholds (USDC)
_MILESTONES = [100_000, 200_000, 300_000, 400_000, 500_000]


def _mask_username(name: str | None) -> str:
    """Return a masked display name: first 2 chars + *** + last char.

    Examples:
        "Alice"  -> "Al***e"
        "Jo"     -> "Jo***o"
        "X"      -> "X***X"
        None     -> "M***r"
    """
    if not name:
        return "M***r"
    if len(name) <= 1:
        return f"{name}***{name}"
    return f"{name[:2]}***{name[-1]}"


async def get_overview(db: AsyncSession) -> dict:
    """Aggregate high-level platform overview for the transparency dashboard.

    Returns:
        global_scan_count, active_members, payouts_24h, scan_velocity,
        recent_activity, next_milestone
    """
    result: dict = {}

    # --- global_scan_count (Redis) ---
    try:
        result["global_scan_count"] = await get_global_scan_count()
    except Exception as exc:
        logger.warning("get_overview: could not fetch global_scan_count: %s", exc)
        result["global_scan_count"] = 0

    # --- active_members (DB) ---
    try:
        count_result = await db.execute(
            select(func.count()).select_from(User).where(User.is_active == True)  # noqa: E712
        )
        result["active_members"] = count_result.scalar_one()
    except Exception as exc:
        logger.warning("get_overview: could not fetch active_members: %s", exc)
        result["active_members"] = 0

    # --- payouts_24h: sum of comp amounts in the last 24 hours ---
    try:
        cutoff = datetime.now(timezone.utc) - timedelta(hours=24)
        payout_result = await db.execute(
            select(func.coalesce(func.sum(Transaction.amount), Decimal("0")))
            .where(
                Transaction.type.in_(["comp_award", "guaranteed_comp", "affiliate_match", "affiliate_payout"]),
                Transaction.status == "completed",
                Transaction.created_at >= cutoff,
            )
        )
        result["payouts_24h"] = float(payout_result.scalar_one())
    except Exception as exc:
        logger.warning("get_overview: could not fetch payouts_24h: %s", exc)
        result["payouts_24h"] = 0.0

    # --- scan_velocity (Redis) ---
    try:
        result["scan_velocity"] = await get_scan_velocity()
    except Exception as exc:
        logger.warning("get_overview: could not fetch scan_velocity: %s", exc)
        result["scan_velocity"] = {"per_minute": 0, "per_hour": 0}

    # --- recent_activity: last 20 comp recipients ---
    try:
        recipients = await get_recent_comp_recipients(db, limit=20)
        # Ensure amounts are serialisable
        serialisable = []
        for r in recipients:
            serialisable.append({
                "username_masked": r.get("username_masked"),
                "amount": float(r["amount"]) if r.get("amount") is not None else None,
                "comp_type": r.get("comp_type"),
                "awarded_at": r["awarded_at"].isoformat() if r.get("awarded_at") else None,
            })
        result["recent_activity"] = serialisable
    except Exception as exc:
        logger.warning("get_overview: could not fetch recent_activity: %s", exc)
        result["recent_activity"] = []

    # --- next_milestone: progress toward the next $100K milestone ---
    try:
        stats = await get_treasury_stats(db)
        total_distributed = float(stats.get("total_distributed", 0))
        next_ms = None
        for ms in _MILESTONES:
            if total_distributed < ms:
                next_ms = ms
                break
        result["next_milestone"] = {
            "target": next_ms,
            "current": total_distributed,
            "progress_pct": round(total_distributed / next_ms * 100, 2) if next_ms else 100.0,
        }
    except Exception as exc:
        logger.warning("get_overview: could not fetch next_milestone: %s", exc)
        result["next_milestone"] = {"target": None, "current": 0.0, "progress_pct": 0.0}

    return result


async def get_treasury_insights(db: AsyncSession) -> dict:
    """Aggregate treasury data: pool balances, bank balances, sparklines, blockchain health.

    Returns:
        pool_balances, bank_balances, sparklines (consumer/affiliate/wholesale), blockchain_health
    """
    result: dict = {}

    # --- pool_balances (on-chain, from comp_engine) ---
    try:
        raw_pools = await get_pool_balances()
        # Convert Decimal values to float for JSON serialisation
        result["pool_balances"] = {
            pool: {
                "address": data.get("address"),
                "balance": float(data["balance"]) if data.get("balance") is not None else 0.0,
            }
            for pool, data in raw_pools.items()
        }
    except Exception as exc:
        logger.warning("get_treasury_insights: could not fetch pool_balances: %s", exc)
        result["pool_balances"] = {}

    # --- bank_balances (Teller, from teller_service) ---
    try:
        result["bank_balances"] = await get_last_sync_status(db)
    except Exception as exc:
        logger.warning("get_treasury_insights: could not fetch bank_balances: %s", exc)
        result["bank_balances"] = []

    # --- sparklines: 90-day daily history per pool ---
    try:
        sparklines = {}
        for pool in ("consumer", "affiliate", "wholesale"):
            try:
                sparklines[pool] = await get_treasury_sparkline(db, pool_type=pool, days=90)
            except Exception as pool_exc:
                logger.warning("get_treasury_insights: sparkline failed for %s: %s", pool, pool_exc)
                sparklines[pool] = []
        result["sparklines"] = sparklines
    except Exception as exc:
        logger.warning("get_treasury_insights: could not fetch sparklines: %s", exc)
        result["sparklines"] = {"consumer": [], "affiliate": [], "wholesale": []}

    # --- blockchain_health ---
    try:
        result["blockchain_health"] = get_node_health()
    except Exception as exc:
        logger.warning("get_treasury_insights: could not fetch blockchain_health: %s", exc)
        result["blockchain_health"] = {"connected": False, "block_number": None}

    return result


async def get_systems_health(db: AsyncSession) -> dict:
    """Aggregate system health metrics: scan velocity, node health, teller sync, tier distribution.

    Returns:
        scan_velocity, node_health, teller_sync, tier_distribution
    """
    result: dict = {}

    # --- scan_velocity (Redis) ---
    try:
        result["scan_velocity"] = await get_scan_velocity()
    except Exception as exc:
        logger.warning("get_systems_health: could not fetch scan_velocity: %s", exc)
        result["scan_velocity"] = {"per_minute": 0, "per_hour": 0}

    # --- node_health (blockchain) ---
    try:
        result["node_health"] = get_node_health()
    except Exception as exc:
        logger.warning("get_systems_health: could not fetch node_health: %s", exc)
        result["node_health"] = {"connected": False, "block_number": None}

    # --- teller_sync ---
    try:
        result["teller_sync"] = await get_last_sync_status(db)
    except Exception as exc:
        logger.warning("get_systems_health: could not fetch teller_sync: %s", exc)
        result["teller_sync"] = []

    # --- tier_distribution: count of users per tier name ---
    try:
        tier_dist_result = await db.execute(
            select(Tier.name, func.count(User.id).label("user_count"))
            .join(User, User.tier_id == Tier.id, isouter=True)
            .group_by(Tier.name)
            .order_by(Tier.name)
        )
        rows = tier_dist_result.all()
        result["tier_distribution"] = {row.name: row.user_count for row in rows}
    except Exception as exc:
        logger.warning("get_systems_health: could not fetch tier_distribution: %s", exc)
        result["tier_distribution"] = {}

    return result


async def get_comp_stats(db: AsyncSession) -> dict:
    """Aggregate comp distribution statistics.

    Returns:
        prize_tiers (count per milestone threshold), total_comps_paid, active_members
    """
    result: dict = {}

    # --- prize_tiers: count of comp transactions grouped by threshold buckets ---
    try:
        # Query comp payouts, count how many fall into each threshold bucket
        # Using the CRYPTO_MILESTONES: $100, $1,000, $10,000 + affiliate payout $200,000 threshold
        THRESHOLDS = {
            "100": (Decimal("0"), Decimal("100")),
            "1000": (Decimal("100"), Decimal("1000")),
            "10000": (Decimal("1000"), Decimal("10000")),
            "200000": (Decimal("10000"), Decimal("999999999")),
        }
        prize_tiers: dict[str, int] = {}
        for label, (low, high) in THRESHOLDS.items():
            count_result = await db.execute(
                select(func.count())
                .select_from(Transaction)
                .where(
                    Transaction.type.in_(["comp_award", "guaranteed_comp", "affiliate_payout"]),
                    Transaction.status == "completed",
                    Transaction.amount > low,
                    Transaction.amount <= high,
                )
            )
            prize_tiers[label] = count_result.scalar_one()
        result["prize_tiers"] = prize_tiers
    except Exception as exc:
        logger.warning("get_comp_stats: could not fetch prize_tiers: %s", exc)
        result["prize_tiers"] = {"100": 0, "1000": 0, "10000": 0, "200000": 0}

    # --- total_comps_paid and active_members from treasury stats ---
    try:
        stats = await get_treasury_stats(db)
        result["total_comps_paid"] = float(stats.get("total_distributed", 0))
        result["active_members"] = stats.get("total_members_comped", 0)
    except Exception as exc:
        logger.warning("get_comp_stats: could not fetch treasury_stats: %s", exc)
        result["total_comps_paid"] = 0.0
        result["active_members"] = 0

    return result


async def get_partner_stats(db: AsyncSession) -> dict:
    """Aggregate partner (affiliate and wholesale) statistics.

    Returns:
        affiliate_count, wholesale_account_count
    """
    result: dict = {}

    # --- affiliate_count: active affiliates ---
    try:
        # Affiliates whose linked user is active
        aff_result = await db.execute(
            select(func.count())
            .select_from(Affiliate)
            .join(User, Affiliate.user_id == User.id)
            .where(User.is_active == True)  # noqa: E712
        )
        result["affiliate_count"] = aff_result.scalar_one()
    except Exception as exc:
        logger.warning("get_partner_stats: could not fetch affiliate_count: %s", exc)
        result["affiliate_count"] = 0

    # --- wholesale_account_count ---
    try:
        ws_result = await db.execute(
            select(func.count()).select_from(WholesaleAccount)
        )
        result["wholesale_account_count"] = ws_result.scalar_one()
    except Exception as exc:
        logger.warning("get_partner_stats: could not fetch wholesale_account_count: %s", exc)
        result["wholesale_account_count"] = 0

    return result


async def get_activity_feed(
    db: AsyncSession,
    hours: int = 24,
    page: int = 1,
    per_page: int = 20,
) -> dict:
    """Return a paginated activity feed of recent platform events.

    Combines:
    - Comp payouts (type: comp_award, guaranteed_comp, affiliate_match, affiliate_payout)
    - Tier upgrades (from tier_history)
    - New members (users created within the window)

    Args:
        hours:    How many hours of history to include.
        page:     1-based page number.
        per_page: Items per page.

    Returns:
        {"items": [...], "total": int, "page": int, "per_page": int}
        Each item: {"type", "user_masked", "amount", "timestamp"}
    """
    cutoff = datetime.now(timezone.utc) - timedelta(hours=hours)
    events: list[dict] = []

    # --- Comp payouts ---
    try:
        comp_result = await db.execute(
            select(Transaction.type, Transaction.amount, Transaction.created_at, User.first_name)
            .join(User, Transaction.user_id == User.id)
            .where(
                Transaction.type.in_(["comp_award", "guaranteed_comp", "affiliate_match", "affiliate_payout"]),
                Transaction.status == "completed",
                Transaction.created_at >= cutoff,
            )
            .order_by(Transaction.created_at.desc())
        )
        for row in comp_result.all():
            events.append({
                "type": row.type,
                "user_masked": _mask_username(row.first_name),
                "amount": float(row.amount) if row.amount is not None else None,
                "timestamp": row.created_at.isoformat() if row.created_at else None,
            })
    except Exception as exc:
        logger.warning("get_activity_feed: could not fetch comp payouts: %s", exc)

    # --- Tier upgrades ---
    try:
        tier_result = await db.execute(
            select(TierHistory.tier_name, TierHistory.achieved_at, User.first_name)
            .join(User, TierHistory.user_id == User.id)
            .where(TierHistory.achieved_at >= cutoff)
            .order_by(TierHistory.achieved_at.desc())
        )
        for row in tier_result.all():
            events.append({
                "type": "tier_upgrade",
                "user_masked": _mask_username(row.first_name),
                "amount": None,
                "timestamp": row.achieved_at.isoformat() if row.achieved_at else None,
                "tier": row.tier_name,
            })
    except Exception as exc:
        logger.warning("get_activity_feed: could not fetch tier upgrades: %s", exc)

    # --- New members ---
    try:
        new_members_result = await db.execute(
            select(User.first_name, User.created_at)
            .where(User.created_at >= cutoff, User.is_active == True)  # noqa: E712
            .order_by(User.created_at.desc())
        )
        for row in new_members_result.all():
            events.append({
                "type": "new_member",
                "user_masked": _mask_username(row.first_name),
                "amount": None,
                "timestamp": row.created_at.isoformat() if row.created_at else None,
            })
    except Exception as exc:
        logger.warning("get_activity_feed: could not fetch new members: %s", exc)

    # Sort all events descending by timestamp, handling None gracefully
    events.sort(key=lambda e: e.get("timestamp") or "", reverse=True)

    total = len(events)
    offset = (page - 1) * per_page
    page_items = events[offset: offset + per_page]

    return {
        "items": page_items,
        "total": total,
        "page": page,
        "per_page": per_page,
    }
