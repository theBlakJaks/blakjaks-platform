import uuid
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from unittest.mock import patch

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.affiliate import Affiliate
from app.models.scan import Scan
from app.models.user import User
from app.models.wallet import Wallet
from app.services.comp_engine import (
    AFFILIATE_MATCH_RATE,
    CRYPTO_MILESTONES,
    GUARANTEED_COMP_AMOUNT,
    TIER_ORDER,
    allocate_to_pools,
    award_crypto_comp,
    calculate_affiliate_pool_distribution,
    calculate_gross_profit,
    check_crypto_comp_milestone,
    check_guaranteed_comp,
    get_recent_comp_recipients,
    get_treasury_stats,
    process_affiliate_reward_match,
)
from app.services.wallet_service import create_user_wallet
from tests.conftest import SIGNUP_PAYLOAD, seed_tiers

pytestmark = pytest.mark.asyncio


# ── Helper to create a second user (referral target, affiliate, etc.) ─


async def _create_user(db: AsyncSession, email: str, referred_by: uuid.UUID | None = None) -> User:
    from app.core.security import hash_password

    _local = email.split("@")[0].replace("-", "_").replace(".", "_")[:20]
    user = User(
        email=email,
        username=_local,
        username_lower=_local.lower(),
        password_hash=hash_password("password123"),
        first_name="Test",
        last_name="User",
        referred_by=referred_by,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    # Create wallet
    await create_user_wallet(db, user.id, email=email)
    return user


# ── Pool allocation math ─────────────────────────────────────────────


def test_pool_allocation_math():
    """50/5/5/40 split of gross profit."""
    gp = Decimal("1000")
    pools = allocate_to_pools(gp)
    assert pools["consumer"] == Decimal("500")
    assert pools["affiliate"] == Decimal("50")
    assert pools["wholesale"] == Decimal("50")
    assert pools["company_retained"] == Decimal("400")
    assert sum(pools.values()) == gp


def test_gross_profit_calculation():
    gp = calculate_gross_profit(Decimal("10000"), Decimal("4000"))
    assert gp == Decimal("6000")


def test_pool_allocation_with_real_gp():
    """Full flow: revenue -> COGS -> GP -> pools."""
    gp = calculate_gross_profit(Decimal("10000"), Decimal("4000"))
    pools = allocate_to_pools(gp)
    assert pools["consumer"] == Decimal("3000")
    assert pools["affiliate"] == Decimal("300")
    assert pools["wholesale"] == Decimal("300")
    assert pools["company_retained"] == Decimal("2400")


# ── Crypto comp milestone check ──────────────────────────────────────


async def test_crypto_comp_milestone_standard_user(registered_user, db: AsyncSession):
    """Standard tier user should not be eligible for any milestone."""
    user_id = uuid.UUID(registered_user["user"]["id"])
    # No tiers seeded = Standard user
    milestone = await check_crypto_comp_milestone(db, user_id)
    # Standard < VIP, so not eligible for any milestone
    assert milestone is None


async def test_crypto_comp_milestone_vip_eligible(db: AsyncSession):
    """VIP user should be eligible for the $100 milestone."""
    await seed_tiers(db)
    user = await _create_user(db, "vip@example.com")

    # Mock tier info at the source module (tier.py), which comp_engine imports from
    with patch("app.services.tier.get_user_tier_info", return_value={
        "tier_name": "VIP", "quarterly_scans": 7, "scans_to_next_tier": 8,
    }):
        milestone = await check_crypto_comp_milestone(db, user.id)
        assert milestone is not None
        assert milestone["amount"] == Decimal("100")
        assert milestone["min_tier"] == "VIP"


async def test_crypto_comp_milestone_whale(db: AsyncSession):
    """Whale user should be eligible for the $100 milestone first (sequential)."""
    await seed_tiers(db)
    user = await _create_user(db, "whale@example.com")

    with patch("app.services.tier.get_user_tier_info", return_value={
        "tier_name": "Whale", "quarterly_scans": 30, "scans_to_next_tier": None,
    }):
        milestone = await check_crypto_comp_milestone(db, user.id)
        assert milestone is not None
        assert milestone["amount"] == Decimal("100")


# ── Award crypto comp ────────────────────────────────────────────────


async def test_award_crypto_comp_creates_transaction(db: AsyncSession):
    """award_crypto_comp should create a pending_choice transaction (user must choose payout method)."""
    user = await _create_user(db, "comp@example.com")

    txn = await award_crypto_comp(db, user.id, Decimal("100"))
    assert txn.type == "comp_award"
    assert txn.amount == Decimal("100")
    assert txn.status == "pending_choice"  # Balance credited only after payout choice

    # Wallet balance NOT updated until payout choice is made
    wallet_result = await db.execute(
        __import__("sqlalchemy").select(Wallet).where(Wallet.user_id == user.id)
    )
    wallet = wallet_result.scalar_one()
    assert wallet.balance_available == Decimal("0")


# ── 21% affiliate reward matching ────────────────────────────────────


async def test_affiliate_reward_matching(db: AsyncSession):
    """When a referred user receives a comp payout, affiliate gets 21%."""
    # Create affiliate (referrer)
    affiliate_user = await _create_user(db, "affiliate@example.com")
    affiliate = Affiliate(
        user_id=affiliate_user.id,
        referral_code="AFF123",
        referred_count=1,
    )
    db.add(affiliate)
    await db.commit()

    # Create referred user
    referred_user = await _create_user(db, "referred@example.com", referred_by=affiliate_user.id)

    # Award comp then explicitly trigger affiliate matching (normally done on payout choice)
    txn = await award_crypto_comp(db, referred_user.id, Decimal("100"))
    await process_affiliate_reward_match(db, referred_user.id, Decimal("100"))

    # Check affiliate got 21%
    from sqlalchemy import select
    from app.models.transaction import Transaction

    aff_txns = await db.execute(
        select(Transaction).where(
            Transaction.user_id == affiliate_user.id,
            Transaction.type == "affiliate_match",
        )
    )
    match_txn = aff_txns.scalar_one()
    assert match_txn.amount == Decimal("21.00")
    assert match_txn.status == "completed"

    # Check affiliate wallet updated
    aff_wallet = await db.execute(select(Wallet).where(Wallet.user_id == affiliate_user.id))
    wallet = aff_wallet.scalar_one()
    assert wallet.balance_available == Decimal("21.00")

    # Check affiliate lifetime earnings updated
    await db.refresh(affiliate)
    assert affiliate.lifetime_earnings == Decimal("21.00")


async def test_no_affiliate_match_without_referrer(db: AsyncSession):
    """User without a referrer should not trigger affiliate matching."""
    user = await _create_user(db, "solo@example.com")
    result = await process_affiliate_reward_match(db, user.id, Decimal("100"))
    assert result is None


# ── Guaranteed comp logic ─────────────────────────────────────────────


async def test_guaranteed_comp_new_member(db: AsyncSession):
    """New member within first year who hasn't received comps should be eligible."""
    user = await _create_user(db, "newmember@example.com")
    eligible = await check_guaranteed_comp(db, user.id)
    assert eligible is True


async def test_guaranteed_comp_not_eligible_after_organic_comp(db: AsyncSession):
    """Member who received >= $5 in completed comps this month should not get guaranteed comp."""
    from app.models.transaction import Transaction

    user = await _create_user(db, "organic@example.com")
    # Simulate a completed comp (user already chose payout method)
    txn = Transaction(
        user_id=user.id,
        type="comp_award",
        amount=Decimal("5.00"),
        status="completed",
    )
    db.add(txn)
    await db.commit()

    eligible = await check_guaranteed_comp(db, user.id)
    assert eligible is False


# ── Affiliate pool distribution ──────────────────────────────────────


async def test_affiliate_pool_distribution(db: AsyncSession):
    """Test proportionate chip share calculation."""
    # Create two affiliates with referred users
    aff1 = await _create_user(db, "aff1@example.com")
    aff2 = await _create_user(db, "aff2@example.com")

    ref1 = await _create_user(db, "ref1@example.com", referred_by=aff1.id)
    ref2 = await _create_user(db, "ref2@example.com", referred_by=aff2.id)

    # Create QR codes and scans — ref1 has 3 scans, ref2 has 1 scan
    from app.models.qr_code import QRCode

    qr_codes = []
    for i in range(4):
        qr = QRCode(
            unique_id=f"BLAKJAKS-TST-AFF{i:04d}",
            product_code="TST",
            is_used=True,
        )
        db.add(qr)
        qr_codes.append(qr)
    await db.commit()
    for qr in qr_codes:
        await db.refresh(qr)

    for i in range(3):
        scan = Scan(user_id=ref1.id, qr_code_id=qr_codes[i].id)
        db.add(scan)
    scan = Scan(user_id=ref2.id, qr_code_id=qr_codes[3].id)
    db.add(scan)
    await db.commit()

    weekly_amount = Decimal("1000")
    distributions = await calculate_affiliate_pool_distribution(db, weekly_amount)

    assert len(distributions) == 2

    # Sort by chips to make assertions stable
    distributions.sort(key=lambda d: d["chips"], reverse=True)

    # aff1 has 3/4 chips = 75%
    assert distributions[0]["affiliate_user_id"] == aff1.id
    assert distributions[0]["chips"] == 3
    assert distributions[0]["share_amount"] == Decimal("750.00")

    # aff2 has 1/4 chips = 25%
    assert distributions[1]["affiliate_user_id"] == aff2.id
    assert distributions[1]["chips"] == 1
    assert distributions[1]["share_amount"] == Decimal("250.00")


# ── Treasury API endpoints (public, no auth) ─────────────────────────


async def test_treasury_pools_endpoint(client: AsyncClient):
    """GET /treasury/pools should return all three pools (no auth required)."""
    resp = await client.get("/api/treasury/pools")
    assert resp.status_code == 200
    data = resp.json()
    assert "consumer" in data
    assert "affiliate" in data
    assert "wholesale" in data
    assert Decimal(data["consumer"]["allocation_pct"]) == Decimal("50")
    assert Decimal(data["affiliate"]["allocation_pct"]) == Decimal("5")
    assert Decimal(data["wholesale"]["allocation_pct"]) == Decimal("5")


async def test_treasury_recipients_endpoint(client: AsyncClient, db: AsyncSession):
    """GET /treasury/recipients should return masked usernames."""
    from app.models.transaction import Transaction

    # Create a user with a completed comp (only completed comps appear in recipients)
    user = await _create_user(db, "recipient@example.com")
    txn = Transaction(
        user_id=user.id,
        type="comp_award",
        amount=Decimal("50"),
        status="completed",
    )
    db.add(txn)
    await db.commit()

    resp = await client.get("/api/treasury/recipients")
    assert resp.status_code == 200
    data = resp.json()
    assert "recipients" in data
    assert len(data["recipients"]) >= 1
    # Username should be masked
    assert "***" in data["recipients"][0]["username_masked"]


async def test_treasury_stats_endpoint(client: AsyncClient, db: AsyncSession):
    """GET /treasury/stats should return correct percentages."""
    resp = await client.get("/api/treasury/stats")
    assert resp.status_code == 200
    data = resp.json()
    assert Decimal(data["consumer_pool_pct"]) == Decimal("50")
    assert Decimal(data["affiliate_pool_pct"]) == Decimal("5")
    assert Decimal(data["wholesale_pool_pct"]) == Decimal("5")
    assert "total_distributed" in data
    assert "total_members_comped" in data
