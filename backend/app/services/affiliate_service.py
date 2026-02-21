"""Affiliate service — referral tracking, chips, vault, payouts, sunset."""

import logging
import re
import uuid
from datetime import datetime, timedelta, timezone
from decimal import Decimal

from sqlalchemy import and_, func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.affiliate import Affiliate
from app.models.affiliate_chip import AffiliateChip
from app.models.affiliate_payout import AffiliatePayout
from app.models.order import Order
from app.models.order_item import OrderItem
from app.models.scan import Scan
from app.models.sunset_status import SunsetStatus
from app.models.tier import Tier
from app.models.user import User
from app.models.wallet import Wallet
from app.services.tier import TIER_ORDER

logger = logging.getLogger(__name__)

# Permanent tier thresholds (cumulative referred tins)
PERMANENT_TIER_THRESHOLDS = [
    (21000, "Whale"),
    (2100, "High Roller"),
    (210, "VIP"),
]

AFFILIATE_MATCH_RATE = Decimal("0.21")


# ── Core affiliate CRUD ──────────────────────────────────────────────


async def get_affiliate(db: AsyncSession, user_id: uuid.UUID) -> Affiliate | None:
    """Get affiliate record for a user."""
    result = await db.execute(select(Affiliate).where(Affiliate.user_id == user_id))
    return result.scalar_one_or_none()


async def get_or_create_affiliate(db: AsyncSession, user_id: uuid.UUID) -> Affiliate:
    """Auto-create affiliate record for user if it doesn't exist."""
    existing = await get_affiliate(db, user_id)
    if existing:
        return existing

    # Check sunset — if triggered, don't create new affiliates
    sunset = await _get_sunset_record(db)
    if sunset and sunset.is_triggered:
        raise ValueError("Affiliate program is closed (sunset triggered)")

    # Generate referral code from user info
    user_result = await db.execute(select(User).where(User.id == user_id))
    user = user_result.scalar_one_or_none()
    if not user:
        raise ValueError("User not found")

    # Use existing referral_code from user or generate one
    code = user.referral_code or _generate_referral_code(user)

    affiliate = Affiliate(
        user_id=user_id,
        referral_code=code,
    )
    db.add(affiliate)
    await db.commit()
    await db.refresh(affiliate)

    # Also set referral_code on user if not set
    if not user.referral_code:
        user.referral_code = code
        await db.commit()

    return affiliate


def _generate_referral_code(user: User) -> str:
    """Generate a referral code from user's name + random suffix."""
    base = (user.first_name or "user").lower()
    base = re.sub(r"[^a-z0-9]", "", base)
    suffix = uuid.uuid4().hex[:6]
    return f"{base}-{suffix}"


async def set_custom_referral_code(db: AsyncSession, user_id: uuid.UUID, custom_code: str) -> Affiliate:
    """Set a custom referral code. Must be unique, alphanumeric, 3-20 chars."""
    affiliate = await get_or_create_affiliate(db, user_id)

    # Check uniqueness
    existing = await db.execute(
        select(Affiliate).where(Affiliate.referral_code == custom_code, Affiliate.id != affiliate.id)
    )
    if existing.scalar_one_or_none():
        raise ValueError("Referral code already taken")

    # Also check user referral_codes
    existing_user = await db.execute(
        select(User).where(User.referral_code == custom_code, User.id != user_id)
    )
    if existing_user.scalar_one_or_none():
        raise ValueError("Referral code already taken")

    affiliate.referral_code = custom_code
    # Update user's referral_code too
    user_result = await db.execute(select(User).where(User.id == user_id))
    user = user_result.scalar_one_or_none()
    if user:
        user.referral_code = custom_code

    await db.commit()
    await db.refresh(affiliate)
    return affiliate


# ── Referral attribution ─────────────────────────────────────────────


async def attribute_referral(db: AsyncSession, new_user_id: uuid.UUID, referral_code: str) -> bool:
    """Attribute a new signup to an affiliate. Permanent, first-touch."""
    # Find the affiliate by referral code
    aff_result = await db.execute(
        select(Affiliate).where(Affiliate.referral_code == referral_code)
    )
    affiliate = aff_result.scalar_one_or_none()
    if not affiliate:
        return False

    # Don't let user refer themselves
    if affiliate.user_id == new_user_id:
        return False

    # Set referred_by on the new user
    user_result = await db.execute(select(User).where(User.id == new_user_id))
    user = user_result.scalar_one_or_none()
    if not user or user.referred_by:
        return False  # Already attributed

    user.referred_by = affiliate.user_id
    affiliate.referred_count += 1
    await db.commit()

    logger.info("Referral attributed: user %s -> affiliate %s (code: %s)",
                new_user_id, affiliate.user_id, referral_code)
    return True


# ── Referral scan → affiliate chip ───────────────────────────────────


async def process_referral_scan(db: AsyncSession, scan_id: uuid.UUID, user_id: uuid.UUID) -> AffiliateChip | None:
    """When a referred member scans, award 1 chip to their referrer's affiliate. Check sunset first."""
    # Check sunset
    sunset = await _get_sunset_record(db)
    if sunset and sunset.is_triggered:
        return None  # No new chips after sunset

    # Find referrer
    user_result = await db.execute(select(User.referred_by).where(User.id == user_id))
    referred_by = user_result.scalar_one_or_none()
    if not referred_by:
        return None

    # Get or create affiliate for referrer
    affiliate = await get_affiliate(db, referred_by)
    if not affiliate:
        return None

    chip = AffiliateChip(
        affiliate_id=affiliate.id,
        source_user_id=user_id,
        source_scan_id=scan_id,
    )
    db.add(chip)
    await db.commit()
    await db.refresh(chip)
    return chip


# ── 21% reward matching ──────────────────────────────────────────────


def calculate_reward_match(comp_amount: Decimal) -> Decimal:
    """Calculate 21% of a comp amount."""
    return (comp_amount * AFFILIATE_MATCH_RATE).quantize(Decimal("0.01"))


async def process_reward_match(
    db: AsyncSession, comp_amount: Decimal, recipient_user_id: uuid.UUID
) -> AffiliatePayout | None:
    """Execute 21% match: create payout record for the referrer."""
    # Find referrer
    user_result = await db.execute(select(User.referred_by).where(User.id == recipient_user_id))
    referred_by = user_result.scalar_one_or_none()
    if not referred_by:
        return None

    affiliate = await get_affiliate(db, referred_by)
    if not affiliate:
        return None

    match_amount = calculate_reward_match(comp_amount)
    if match_amount <= 0:
        return None

    now = datetime.now(timezone.utc)
    payout = AffiliatePayout(
        affiliate_id=affiliate.id,
        amount=match_amount,
        payout_type="reward_match",
        period_start=now,
        period_end=now,
        status="completed",
    )
    db.add(payout)

    # Update affiliate lifetime earnings
    affiliate.lifetime_earnings += match_amount

    await db.commit()
    await db.refresh(payout)
    return payout


# ── Downline ─────────────────────────────────────────────────────────


async def get_downline(
    db: AsyncSession, affiliate_id: uuid.UUID, page: int = 1, per_page: int = 20
) -> dict:
    """Paginated list of referred members."""
    aff_result = await db.execute(select(Affiliate).where(Affiliate.id == affiliate_id))
    affiliate = aff_result.scalar_one_or_none()
    if not affiliate:
        return {"items": [], "total": 0, "page": page, "per_page": per_page}

    base = select(User).where(User.referred_by == affiliate.user_id)

    # Count
    count_result = await db.execute(select(func.count()).select_from(base.subquery()))
    total = count_result.scalar_one()

    # Paginated
    result = await db.execute(
        base.order_by(User.created_at.desc())
        .offset((page - 1) * per_page)
        .limit(per_page)
    )
    users = result.scalars().all()

    items = []
    for u in users:
        # Count scans
        scan_count_result = await db.execute(
            select(func.count()).select_from(Scan).where(Scan.user_id == u.id)
        )
        scan_count = scan_count_result.scalar_one()

        # Get tier name
        tier_name = None
        if u.tier_id:
            tier_result = await db.execute(select(Tier.name).where(Tier.id == u.tier_id))
            tier_name = tier_result.scalar_one_or_none()

        items.append({
            "user_id": u.id,
            "username": u.first_name or "User",
            "tier": tier_name,
            "total_scans": scan_count,
            "earnings_generated": Decimal("0"),  # TODO: sum affiliate matches from this user
            "joined_at": u.created_at,
        })

    return {"items": items, "total": total, "page": page, "per_page": per_page}


# ── Chips ────────────────────────────────────────────────────────────


async def get_affiliate_chips(db: AsyncSession, affiliate_id: uuid.UUID) -> dict:
    """Chip summary: active, vaulted, expired, total earned."""
    base = select(func.count()).select_from(AffiliateChip).where(
        AffiliateChip.affiliate_id == affiliate_id
    )

    total_result = await db.execute(base)
    total = total_result.scalar_one()

    active_result = await db.execute(
        base.where(AffiliateChip.is_vaulted == False, AffiliateChip.is_expired == False)  # noqa: E712
    )
    active = active_result.scalar_one()

    vaulted_result = await db.execute(
        base.where(AffiliateChip.is_vaulted == True, AffiliateChip.is_expired == False)  # noqa: E712
    )
    vaulted = vaulted_result.scalar_one()

    expired_result = await db.execute(
        base.where(AffiliateChip.is_expired == True)  # noqa: E712
    )
    expired = expired_result.scalar_one()

    return {
        "active_chips": active,
        "vaulted_chips": vaulted,
        "expired_chips": expired,
        "total_earned": total,
    }


async def vault_chips(db: AsyncSession, affiliate_id: uuid.UUID, chip_ids: list[uuid.UUID]) -> int:
    """Move chips to vault. Sets vault_date and vault_expiry (+365 days). Returns count vaulted."""
    now = datetime.now(timezone.utc)
    expiry = now + timedelta(days=365)

    result = await db.execute(
        update(AffiliateChip)
        .where(
            AffiliateChip.id.in_(chip_ids),
            AffiliateChip.affiliate_id == affiliate_id,
            AffiliateChip.is_vaulted == False,  # noqa: E712
            AffiliateChip.is_expired == False,  # noqa: E712
        )
        .values(is_vaulted=True, vault_date=now, vault_expiry=expiry)
    )
    await db.commit()
    return result.rowcount


async def unvault_chips(db: AsyncSession, affiliate_id: uuid.UUID, chip_ids: list[uuid.UUID]) -> int:
    """Move chips out of vault before expiry. Returns count unvaulted."""
    result = await db.execute(
        update(AffiliateChip)
        .where(
            AffiliateChip.id.in_(chip_ids),
            AffiliateChip.affiliate_id == affiliate_id,
            AffiliateChip.is_vaulted == True,  # noqa: E712
            AffiliateChip.is_expired == False,  # noqa: E712
        )
        .values(is_vaulted=False, vault_date=None, vault_expiry=None)
    )
    await db.commit()
    return result.rowcount


async def process_vault_bonuses(db: AsyncSession) -> int:
    """Batch job: for every 5 vaulted chips, generate 1 bonus chip per month.
    Returns count of bonus chips created.
    """
    # Get all affiliates with vaulted chips
    result = await db.execute(
        select(
            AffiliateChip.affiliate_id,
            func.count(AffiliateChip.id).label("vaulted_count"),
        )
        .where(AffiliateChip.is_vaulted == True, AffiliateChip.is_expired == False)  # noqa: E712
        .group_by(AffiliateChip.affiliate_id)
    )
    rows = result.all()

    bonus_count = 0
    for aff_id, vaulted in rows:
        bonuses_due = vaulted // 5
        if bonuses_due <= 0:
            continue

        # Get any scan from this affiliate's referrals as a source reference
        chip_result = await db.execute(
            select(AffiliateChip).where(AffiliateChip.affiliate_id == aff_id).limit(1)
        )
        sample_chip = chip_result.scalar_one_or_none()
        if not sample_chip:
            continue

        for _ in range(bonuses_due):
            bonus = AffiliateChip(
                affiliate_id=aff_id,
                source_user_id=sample_chip.source_user_id,
                source_scan_id=sample_chip.source_scan_id,
            )
            db.add(bonus)
            bonus_count += 1

    await db.commit()
    logger.info("Vault bonuses processed: %d bonus chips created", bonus_count)
    return bonus_count


async def expire_vaulted_chips(db: AsyncSession) -> int:
    """Batch job: expire chips past 365 days vault expiry. Returns count expired."""
    now = datetime.now(timezone.utc)
    result = await db.execute(
        update(AffiliateChip)
        .where(
            AffiliateChip.is_vaulted == True,  # noqa: E712
            AffiliateChip.is_expired == False,  # noqa: E712
            AffiliateChip.vault_expiry <= now,
        )
        .values(is_expired=True)
    )
    await db.commit()
    logger.info("Expired vaulted chips: %d", result.rowcount)
    return result.rowcount


# ── Weekly pool distribution ─────────────────────────────────────────


async def calculate_weekly_pool_distribution(
    db: AsyncSession, pool_amount: Decimal
) -> list[dict]:
    """Calculate each affiliate's share: (their chips / total chips) × pool amount."""
    result = await db.execute(
        select(
            AffiliateChip.affiliate_id,
            func.count(AffiliateChip.id).label("chips"),
        )
        .where(AffiliateChip.is_expired == False)  # noqa: E712
        .group_by(AffiliateChip.affiliate_id)
    )
    rows = result.all()

    if not rows:
        return []

    total_chips = sum(r.chips for r in rows)
    if total_chips == 0:
        return []

    distributions = []
    for row in rows:
        share = (Decimal(row.chips) / Decimal(total_chips) * pool_amount).quantize(Decimal("0.01"))
        distributions.append({
            "affiliate_id": row.affiliate_id,
            "chips": row.chips,
            "share_amount": share,
        })

    return distributions


async def process_weekly_payout(db: AsyncSession, pool_amount: Decimal) -> list[AffiliatePayout]:
    """Batch job: calculate shares, create pending payout records."""
    distributions = await calculate_weekly_pool_distribution(db, pool_amount)

    now = datetime.now(timezone.utc)
    week_start = (now - timedelta(days=now.weekday())).replace(
        hour=0, minute=0, second=0, microsecond=0
    )
    week_end = week_start + timedelta(days=7)

    payouts = []
    for dist in distributions:
        if dist["share_amount"] <= 0:
            continue
        payout = AffiliatePayout(
            affiliate_id=dist["affiliate_id"],
            amount=dist["share_amount"],
            payout_type="pool_share",
            period_start=week_start,
            period_end=week_end,
            status="pending",
        )
        db.add(payout)
        payouts.append(payout)

    await db.commit()
    for p in payouts:
        await db.refresh(p)

    logger.info("Weekly payout batch created: %d payouts", len(payouts))
    return payouts


async def approve_payout_batch(db: AsyncSession, batch_date: datetime | None = None) -> int:
    """Admin: approve all pending payouts. Returns count approved."""
    query = update(AffiliatePayout).where(AffiliatePayout.status == "pending")
    if batch_date:
        query = query.where(AffiliatePayout.period_start <= batch_date)
    result = await db.execute(query.values(status="approved"))
    await db.commit()
    return result.rowcount


async def execute_payouts(db: AsyncSession) -> int:
    """Execute approved payouts: update to paid status. Returns count executed.
    TODO: Send USDC from affiliate pool wallet via blockchain.py.
    """
    result = await db.execute(
        update(AffiliatePayout)
        .where(AffiliatePayout.status == "approved")
        .values(status="paid")
    )
    await db.commit()
    logger.info("Payouts executed: %d", result.rowcount)
    return result.rowcount


async def get_payout_history(
    db: AsyncSession, affiliate_id: uuid.UUID, page: int = 1, per_page: int = 20
) -> dict:
    """Paginated payout history."""
    base = select(AffiliatePayout).where(AffiliatePayout.affiliate_id == affiliate_id)

    count_result = await db.execute(select(func.count()).select_from(base.subquery()))
    total = count_result.scalar_one()

    result = await db.execute(
        base.order_by(AffiliatePayout.created_at.desc())
        .offset((page - 1) * per_page)
        .limit(per_page)
    )
    items = result.scalars().all()

    return {"items": items, "total": total, "page": page, "per_page": per_page}


# ── Permanent tier ───────────────────────────────────────────────────


async def get_referred_tins_count(db: AsyncSession, affiliate_id: uuid.UUID) -> int:
    """Count total tins purchased by all referrals (lifetime, for permanent tier)."""
    aff_result = await db.execute(select(Affiliate).where(Affiliate.id == affiliate_id))
    affiliate = aff_result.scalar_one_or_none()
    if not affiliate:
        return 0

    # Sum all order_items quantities for orders placed by referred users
    result = await db.execute(
        select(func.coalesce(func.sum(OrderItem.quantity), 0))
        .join(Order, OrderItem.order_id == Order.id)
        .where(
            Order.user_id.in_(
                select(User.id).where(User.referred_by == affiliate.user_id)
            ),
            Order.status.in_(["completed", "shipped", "delivered", "pending"]),
        )
    )
    return result.scalar_one()


def check_permanent_tier(referred_tins: int) -> str | None:
    """Calculate permanent tier based on referred tins."""
    for threshold, tier_name in PERMANENT_TIER_THRESHOLDS:
        if referred_tins >= threshold:
            return tier_name
    return None


async def update_permanent_tier(db: AsyncSession, affiliate_id: uuid.UUID) -> str | None:
    """Update affiliate's permanent tier, recalculate user's effective tier."""
    tins = await get_referred_tins_count(db, affiliate_id)
    tier_name = check_permanent_tier(tins)

    aff_result = await db.execute(select(Affiliate).where(Affiliate.id == affiliate_id))
    affiliate = aff_result.scalar_one_or_none()
    if not affiliate:
        return None

    affiliate.tier_status = tier_name
    await db.commit()
    return tier_name


# ── Sunset ───────────────────────────────────────────────────────────


async def _get_sunset_record(db: AsyncSession) -> SunsetStatus | None:
    """Get the single sunset status record, or None."""
    result = await db.execute(select(SunsetStatus).limit(1))
    return result.scalar_one_or_none()


async def check_sunset_status(db: AsyncSession) -> dict:
    """Check if 3-month rolling average >= 10M."""
    sunset = await _get_sunset_record(db)
    if not sunset:
        return {
            "current_monthly_volume": 0,
            "rolling_3mo_avg": 0,
            "threshold": 10_000_000,
            "percentage": 0.0,
            "is_triggered": False,
            "triggered_at": None,
        }

    return {
        "current_monthly_volume": sunset.monthly_volume,
        "rolling_3mo_avg": sunset.rolling_3mo_avg,
        "threshold": sunset.threshold,
        "percentage": round(sunset.rolling_3mo_avg / sunset.threshold * 100, 2) if sunset.threshold > 0 else 0.0,
        "is_triggered": sunset.is_triggered,
        "triggered_at": sunset.triggered_at,
    }


async def trigger_sunset(db: AsyncSession) -> bool:
    """Lock all chip counts, mark sunset as triggered. One-time, irreversible."""
    sunset = await _get_sunset_record(db)
    if not sunset:
        sunset = SunsetStatus(
            monthly_volume=0,
            rolling_3mo_avg=10_000_000,
            is_triggered=True,
            triggered_at=datetime.now(timezone.utc),
        )
        db.add(sunset)
    elif sunset.is_triggered:
        return False  # Already triggered
    else:
        sunset.is_triggered = True
        sunset.triggered_at = datetime.now(timezone.utc)

    await db.commit()
    logger.warning("SUNSET TRIGGERED at %s", sunset.triggered_at)
    return True


async def get_sunset_progress(db: AsyncSession) -> dict:
    """Return current volume, percentage toward 10M, is_triggered."""
    return await check_sunset_status(db)


# ── Admin queries ────────────────────────────────────────────────────


async def get_all_affiliates(
    db: AsyncSession, page: int = 1, per_page: int = 20, sort_by: str = "earnings"
) -> dict:
    """List all affiliates with stats."""
    base = select(Affiliate)
    if sort_by == "earnings":
        base = base.order_by(Affiliate.lifetime_earnings.desc())
    elif sort_by == "downline":
        base = base.order_by(Affiliate.referred_count.desc())
    else:
        base = base.order_by(Affiliate.created_at.desc())

    count_result = await db.execute(select(func.count()).select_from(Affiliate))
    total = count_result.scalar_one()

    result = await db.execute(base.offset((page - 1) * per_page).limit(per_page))
    affiliates = result.scalars().all()

    return {"items": affiliates, "total": total, "page": page, "per_page": per_page}


async def get_pending_payouts(db: AsyncSession) -> list[AffiliatePayout]:
    """List all pending payouts."""
    result = await db.execute(
        select(AffiliatePayout)
        .where(AffiliatePayout.status == "pending")
        .order_by(AffiliatePayout.created_at.desc())
    )
    return list(result.scalars().all())
