import uuid
from datetime import date, datetime, timezone

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.affiliate import Affiliate
from app.models.scan import Scan
from app.models.tier import Tier

# Tier thresholds ordered ascending — must match seed data
TIER_ORDER = ["Standard", "VIP", "High Roller", "Whale"]


def get_current_quarter_range() -> tuple[datetime, datetime]:
    """Return (start, end) datetimes for the current calendar quarter (UTC)."""
    today = date.today()
    quarter = (today.month - 1) // 3
    q_start_month = quarter * 3 + 1
    q_start = datetime(today.year, q_start_month, 1, tzinfo=timezone.utc)

    next_q_month = q_start_month + 3
    if next_q_month > 12:
        q_end = datetime(today.year + 1, 1, 1, tzinfo=timezone.utc)
    else:
        q_end = datetime(today.year, next_q_month, 1, tzinfo=timezone.utc)

    return q_start, q_end


async def get_quarterly_scan_count(db: AsyncSession, user_id: uuid.UUID) -> int:
    """Count scans for a user in the current quarter."""
    q_start, q_end = get_current_quarter_range()
    result = await db.execute(
        select(func.count())
        .select_from(Scan)
        .where(
            Scan.user_id == user_id,
            Scan.created_at >= q_start,
            Scan.created_at < q_end,
        )
    )
    return result.scalar_one()


async def get_all_tiers(db: AsyncSession) -> list[Tier]:
    """Return all tiers ordered by min_scans ascending."""
    result = await db.execute(select(Tier).order_by(Tier.min_scans.asc()))
    return list(result.scalars().all())


def determine_tier_from_scans(tiers: list[Tier], scan_count: int) -> Tier:
    """Given an ascending-sorted tier list and a scan count, return the earned tier."""
    earned = tiers[0]
    for tier in tiers:
        if scan_count >= tier.min_scans:
            earned = tier
    return earned


async def get_permanent_tier(db: AsyncSession, user_id: uuid.UUID, tiers: list[Tier]) -> Tier | None:
    """If the user has an affiliate record with tier_status, return that tier."""
    result = await db.execute(
        select(Affiliate).where(Affiliate.user_id == user_id)
    )
    affiliate = result.scalar_one_or_none()
    if affiliate is None or affiliate.tier_status is None:
        return None
    for tier in tiers:
        if tier.name == affiliate.tier_status:
            return tier
    return None


def effective_tier(quarterly: Tier, permanent: Tier | None, tiers: list[Tier]) -> Tier:
    """Return the higher of quarterly and permanent tier."""
    if permanent is None:
        return quarterly
    tier_names = [t.name for t in tiers]
    q_idx = tier_names.index(quarterly.name)
    p_idx = tier_names.index(permanent.name)
    return tiers[max(q_idx, p_idx)]


def scans_to_next_tier(tiers: list[Tier], current_tier: Tier, scan_count: int) -> int | None:
    """Return scans remaining to reach the next tier, or None if already at max."""
    tier_names = [t.name for t in tiers]
    idx = tier_names.index(current_tier.name)
    if idx >= len(tiers) - 1:
        return None
    next_tier = tiers[idx + 1]
    return max(0, next_tier.min_scans - scan_count)


async def get_user_tier_info(db: AsyncSession, user_id: uuid.UUID) -> dict:
    """Full tier summary for a user."""
    tiers = await get_all_tiers(db)
    if not tiers:
        return {"tier": None, "quarterly_scans": 0, "scans_to_next": None}

    scan_count = await get_quarterly_scan_count(db, user_id)
    quarterly_tier = determine_tier_from_scans(tiers, scan_count)
    permanent = await get_permanent_tier(db, user_id, tiers)
    current = effective_tier(quarterly_tier, permanent, tiers)
    remaining = scans_to_next_tier(tiers, current, scan_count)

    return {
        "tier_name": current.name,
        "tier_color": current.color,
        "benefits": current.benefits_json,
        "quarterly_scans": scan_count,
        "scans_to_next_tier": remaining,
    }
