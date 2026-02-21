"""Treasury & Comp Distribution Engine.

Business rules (from business plan):
- Pool allocations are percentages of GROSS PROFIT, not revenue
- Consumer Pool = 50% of GP
- Affiliate Pool = 5% of GP
- Wholesale Pool = 5% of GP
- Company Retained = 40% of GP

Consumer Pool breakdown:
- Casino Comps: 60% of Consumer Pool (Whale only, milestone-based)
- Crypto Comps: 30% of Consumer Pool (milestone payouts + $50 new member guarantee)
- Trip Comps: 10% of Consumer Pool

Crypto comp milestones (predetermined, automatic):
- $100 USDC — VIP+ eligible
- $1,000 USDC — High Roller+ eligible
- $10,000 USDC — Whale only

New member guaranteed comp:
- Every new member gets $50 in comps during first year
- Distributed as 10 × $5 comps spread across 12 months
- If member hasn't organically received $5+ by month-end, system ensures $5
- Month 12 anniversary comp regardless

Affiliate comps:
- 21% reward matching on every comp a referred member receives
- Weekly chip-proportionate distribution from 5% GP pool every Sunday
"""

import logging
import uuid
from datetime import datetime, timedelta, timezone
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.affiliate import Affiliate
from app.models.scan import Scan
from app.models.transaction import Transaction
from app.models.user import User
from app.models.wallet import Wallet
from app.services.blockchain import (
    AFFILIATE_POOL,
    COMPANY_RETAINED,
    CONSUMER_POOL,
    WHOLESALE_POOL,
)

logger = logging.getLogger(__name__)

# --- Consumer pool sub-allocations (% of Consumer Pool) ---
CASINO_COMP_PCT = Decimal("60")
CRYPTO_COMP_PCT = Decimal("30")
TRIP_COMP_PCT = Decimal("10")

# --- Crypto comp milestones ---
CRYPTO_MILESTONES = [
    {"amount": Decimal("100"), "min_tier": "VIP"},
    {"amount": Decimal("1000"), "min_tier": "High Roller"},
    {"amount": Decimal("10000"), "min_tier": "Whale"},
]

# Tier ordering for eligibility checks
TIER_ORDER = ["Standard", "VIP", "High Roller", "Whale"]

# --- Affiliate reward matching rate ---
AFFILIATE_MATCH_RATE = Decimal("0.21")  # 21%

# --- New member guaranteed comp ---
GUARANTEED_COMP_AMOUNT = Decimal("5.00")
GUARANTEED_COMP_TOTAL = Decimal("50.00")
GUARANTEED_COMP_COUNT = 10
FIRST_YEAR_DAYS = 365


# ── Pool allocation math ──────────────────────────────────────────────


def calculate_gross_profit(revenue: Decimal, cogs: Decimal) -> Decimal:
    """Calculate gross profit: revenue minus cost of goods sold."""
    return revenue - cogs


def allocate_to_pools(gross_profit: Decimal) -> dict[str, Decimal]:
    """Split gross profit into pool amounts using the 50/5/5/40 allocation.

    Returns dict with keys: consumer, affiliate, wholesale, company_retained.
    """
    return {
        "consumer": gross_profit * CONSUMER_POOL / Decimal("100"),
        "affiliate": gross_profit * AFFILIATE_POOL / Decimal("100"),
        "wholesale": gross_profit * WHOLESALE_POOL / Decimal("100"),
        "company_retained": gross_profit * COMPANY_RETAINED / Decimal("100"),
    }


# ── Crypto comp milestones ────────────────────────────────────────────


def _tier_at_least(user_tier: str, required_tier: str) -> bool:
    """Check if user_tier meets or exceeds required_tier."""
    if user_tier not in TIER_ORDER or required_tier not in TIER_ORDER:
        return False
    return TIER_ORDER.index(user_tier) >= TIER_ORDER.index(required_tier)


async def _get_user_tier_name(db: AsyncSession, user_id: uuid.UUID) -> str:
    """Get the user's current tier name. Defaults to 'Standard'."""
    from app.services.tier import get_user_tier_info

    info = await get_user_tier_info(db, user_id)
    return info.get("tier_name") or "Standard"


async def _get_total_comps_received(db: AsyncSession, user_id: uuid.UUID) -> Decimal:
    """Sum of all accepted comp_award transactions for a user (not pending_choice)."""
    result = await db.execute(
        select(func.coalesce(func.sum(Transaction.amount), Decimal("0")))
        .where(
            Transaction.user_id == user_id,
            Transaction.type.in_(["comp_award", "guaranteed_comp"]),
            Transaction.status.notin_(["pending_choice"]),
        )
    )
    return result.scalar_one()


async def check_crypto_comp_milestone(db: AsyncSession, user_id: uuid.UUID) -> dict | None:
    """Check if user is eligible for a crypto comp milestone they haven't received yet.

    Returns the highest eligible milestone dict or None.
    """
    tier_name = await _get_user_tier_name(db, user_id)
    total_comps = await _get_total_comps_received(db, user_id)

    # Find the highest eligible milestone not yet reached
    eligible = None
    for milestone in CRYPTO_MILESTONES:
        if _tier_at_least(tier_name, milestone["min_tier"]) and total_comps < milestone["amount"]:
            eligible = milestone
            break  # Return the lowest unmet milestone (they progress sequentially)

    return eligible


async def award_crypto_comp(
    db: AsyncSession,
    user_id: uuid.UUID,
    amount: Decimal,
    comp_type: str = "comp_award",
) -> Transaction:
    """Award a comp to a user: create pending_choice transaction.

    Balance is NOT credited until the user makes a payout choice.
    Affiliate reward matching triggers when user makes payout choice.
    """
    txn = Transaction(
        user_id=user_id,
        type=comp_type,
        amount=amount,
        status="pending_choice",
    )
    db.add(txn)
    await db.commit()
    await db.refresh(txn)
    return txn


# ── Affiliate reward matching ─────────────────────────────────────────


async def process_affiliate_reward_match(
    db: AsyncSession,
    comp_recipient_user_id: uuid.UUID,
    comp_amount: Decimal,
) -> Transaction | None:
    """If the comp recipient was referred, award 21% of the comp to the affiliate.

    Returns the affiliate's reward transaction or None if no referrer.
    """
    # Find referrer
    user_result = await db.execute(
        select(User.referred_by).where(User.id == comp_recipient_user_id)
    )
    referred_by = user_result.scalar_one_or_none()
    if not referred_by:
        return None

    match_amount = (comp_amount * AFFILIATE_MATCH_RATE).quantize(Decimal("0.01"))
    if match_amount <= 0:
        return None

    # Update affiliate's wallet
    wallet_result = await db.execute(select(Wallet).where(Wallet.user_id == referred_by))
    wallet = wallet_result.scalar_one_or_none()
    if wallet:
        wallet.balance_available += match_amount

    # Update affiliate lifetime earnings
    aff_result = await db.execute(select(Affiliate).where(Affiliate.user_id == referred_by))
    affiliate = aff_result.scalar_one_or_none()
    if affiliate:
        affiliate.lifetime_earnings += match_amount

    # Record the reward match transaction
    txn = Transaction(
        user_id=referred_by,
        type="affiliate_match",
        amount=match_amount,
        status="completed",
    )
    db.add(txn)
    await db.commit()
    await db.refresh(txn)

    logger.info(
        "Affiliate match: %s gets %s (21%% of %s comp to %s)",
        referred_by, match_amount, comp_amount, comp_recipient_user_id,
    )
    return txn


# ── New member guaranteed comps ───────────────────────────────────────


async def check_guaranteed_comp(db: AsyncSession, user_id: uuid.UUID) -> bool:
    """Check if a new member (within first year) needs their guaranteed $5 comp.

    Returns True if the user is eligible for a guaranteed comp this month.
    """
    # Get user creation date
    user_result = await db.execute(select(User.created_at).where(User.id == user_id))
    created_at = user_result.scalar_one_or_none()
    if not created_at:
        return False

    now = datetime.now(timezone.utc)
    first_year_end = created_at + timedelta(days=FIRST_YEAR_DAYS)
    if now > first_year_end:
        return False

    # Count guaranteed comps already received (exclude pending_choice)
    result = await db.execute(
        select(func.count())
        .select_from(Transaction)
        .where(
            Transaction.user_id == user_id,
            Transaction.type == "guaranteed_comp",
            Transaction.status.notin_(["pending_choice"]),
        )
    )
    guaranteed_count = result.scalar_one()
    if guaranteed_count >= GUARANTEED_COMP_COUNT:
        return False

    # Check if they received any comp (organic or guaranteed) this month (exclude pending_choice)
    month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    result = await db.execute(
        select(func.coalesce(func.sum(Transaction.amount), Decimal("0")))
        .where(
            Transaction.user_id == user_id,
            Transaction.type.in_(["comp_award", "guaranteed_comp"]),
            Transaction.status.notin_(["pending_choice"]),
            Transaction.created_at >= month_start,
        )
    )
    month_comps = result.scalar_one()

    return month_comps < GUARANTEED_COMP_AMOUNT


async def process_guaranteed_comps(db: AsyncSession) -> list[Transaction]:
    """Batch job: find all members in first year who haven't received $5 this month.

    Awards them a guaranteed $5 comp. Returns list of awarded transactions.
    """
    now = datetime.now(timezone.utc)
    first_year_cutoff = now - timedelta(days=FIRST_YEAR_DAYS)
    month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

    # Find users in their first year
    result = await db.execute(
        select(User.id).where(
            User.created_at >= first_year_cutoff,
            User.is_active == True,
        )
    )
    user_ids = list(result.scalars().all())

    awarded = []
    for uid in user_ids:
        if await check_guaranteed_comp(db, uid):
            txn = await award_crypto_comp(db, uid, GUARANTEED_COMP_AMOUNT, comp_type="guaranteed_comp")
            awarded.append(txn)

    logger.info("Guaranteed comps processed: %d awards", len(awarded))
    return awarded


# ── Affiliate pool distribution (weekly) ──────────────────────────────


async def calculate_affiliate_pool_distribution(
    db: AsyncSession,
    weekly_pool_amount: Decimal,
) -> list[dict]:
    """Calculate each affiliate's share: (their chips / total chips) × weekly pool.

    Affiliate chips = total scans from all referred users in the current week.
    Returns list of dicts: [{affiliate_user_id, chips, share_amount}, ...]
    """
    now = datetime.now(timezone.utc)
    # Week starts on Monday
    week_start = (now - timedelta(days=now.weekday())).replace(
        hour=0, minute=0, second=0, microsecond=0
    )

    # Count scans per affiliate (scans by their referred users this week)
    result = await db.execute(
        select(
            User.referred_by.label("affiliate_id"),
            func.count(Scan.id).label("chips"),
        )
        .join(User, Scan.user_id == User.id)
        .where(
            User.referred_by.isnot(None),
            Scan.created_at >= week_start,
        )
        .group_by(User.referred_by)
    )
    rows = result.all()

    if not rows:
        return []

    total_chips = sum(r.chips for r in rows)
    if total_chips == 0:
        return []

    distributions = []
    for row in rows:
        share = (Decimal(row.chips) / Decimal(total_chips) * weekly_pool_amount).quantize(Decimal("0.01"))
        distributions.append({
            "affiliate_user_id": row.affiliate_id,
            "chips": row.chips,
            "share_amount": share,
        })

    return distributions


async def process_weekly_affiliate_payout(
    db: AsyncSession,
    weekly_pool_amount: Decimal,
) -> list[Transaction]:
    """Batch job for Sunday payouts: distribute affiliate pool based on chip shares.

    Returns list of payout transactions.
    """
    distributions = await calculate_affiliate_pool_distribution(db, weekly_pool_amount)

    payouts = []
    for dist in distributions:
        aff_id = dist["affiliate_user_id"]
        amount = dist["share_amount"]

        if amount <= 0:
            continue

        # Update wallet
        wallet_result = await db.execute(select(Wallet).where(Wallet.user_id == aff_id))
        wallet = wallet_result.scalar_one_or_none()
        if wallet:
            wallet.balance_available += amount

        # Update affiliate earnings
        aff_result = await db.execute(select(Affiliate).where(Affiliate.user_id == aff_id))
        affiliate = aff_result.scalar_one_or_none()
        if affiliate:
            affiliate.lifetime_earnings += amount

        txn = Transaction(
            user_id=aff_id,
            type="affiliate_payout",
            amount=amount,
            status="completed",
        )
        db.add(txn)
        payouts.append(txn)

    await db.commit()
    for txn in payouts:
        await db.refresh(txn)

    logger.info("Weekly affiliate payout: %d affiliates, total %s",
                len(payouts), sum(d["share_amount"] for d in distributions))
    return payouts


# ── Transparency dashboard queries ───────────────────────────────────


async def get_pool_balances() -> dict[str, dict]:
    """Return on-chain USDC balances of all three pool wallets.

    Uses mocked values on testnet when no contract address is configured.
    """
    from app.services.blockchain import (
        get_consumer_pool_address,
        get_affiliate_pool_address,
        get_wholesale_pool_address,
        get_usdc_balance,
    )

    pools = {}
    for name, get_addr in [
        ("consumer", get_consumer_pool_address),
        ("affiliate", get_affiliate_pool_address),
        ("wholesale", get_wholesale_pool_address),
    ]:
        try:
            addr = get_addr()
            balance = get_usdc_balance(addr)
        except Exception:
            # KMS not available in dev/test — return placeholder
            addr = None
            balance = Decimal("0")
        pools[name] = {"address": addr, "balance": balance}

    return pools


async def get_recent_comp_recipients(
    db: AsyncSession,
    limit: int = 20,
) -> list[dict]:
    """Return recent comp awards with masked usernames (for transparency dashboard).

    Public data — no PII exposed.
    """
    result = await db.execute(
        select(Transaction, User.first_name)
        .join(User, Transaction.user_id == User.id)
        .where(
            Transaction.type.in_(["comp_award", "guaranteed_comp", "affiliate_match"]),
            Transaction.status == "completed",
        )
        .order_by(Transaction.created_at.desc())
        .limit(limit)
    )
    rows = result.all()

    recipients = []
    for txn, first_name in rows:
        masked = f"{first_name[0]}***" if first_name else "M***"
        recipients.append({
            "username_masked": masked,
            "amount": txn.amount,
            "comp_type": txn.type,
            "awarded_at": txn.created_at,
        })

    return recipients


async def get_treasury_stats(db: AsyncSession) -> dict:
    """Return aggregate treasury statistics for the transparency dashboard."""
    # Total comps distributed
    total_result = await db.execute(
        select(func.coalesce(func.sum(Transaction.amount), Decimal("0")))
        .where(
            Transaction.type.in_(["comp_award", "guaranteed_comp", "affiliate_match", "affiliate_payout"]),
            Transaction.status == "completed",
        )
    )
    total_distributed = total_result.scalar_one()

    # Total unique members who received comps
    members_result = await db.execute(
        select(func.count(func.distinct(Transaction.user_id)))
        .where(
            Transaction.type.in_(["comp_award", "guaranteed_comp"]),
            Transaction.status == "completed",
        )
    )
    total_members = members_result.scalar_one()

    return {
        "total_distributed": total_distributed,
        "total_members_comped": total_members,
        "consumer_pool_pct": CONSUMER_POOL,
        "affiliate_pool_pct": AFFILIATE_POOL,
        "wholesale_pool_pct": WHOLESALE_POOL,
    }
