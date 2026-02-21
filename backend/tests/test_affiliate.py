"""Tests for Affiliate System (Task 14)."""

import uuid
from decimal import Decimal

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token, hash_password
from app.models.affiliate import Affiliate
from app.models.affiliate_chip import AffiliateChip
from app.models.scan import Scan
from app.models.qr_code import QRCode
from app.models.user import User
from app.services.affiliate_service import (
    attribute_referral,
    calculate_reward_match,
    calculate_weekly_pool_distribution,
    check_permanent_tier,
    check_sunset_status,
    get_affiliate_chips,
    get_downline,
    get_or_create_affiliate,
    process_referral_scan,
    process_reward_match,
    set_custom_referral_code,
    vault_chips,
    unvault_chips,
)
from app.services.wallet_service import create_user_wallet
from tests.conftest import seed_tiers

pytestmark = pytest.mark.asyncio


# ── Helpers ──────────────────────────────────────────────────────────


async def _create_user(db: AsyncSession, email: str, tier_name: str | None = None) -> User:
    from app.models.tier import Tier

    tier_id = None
    if tier_name:
        tier_result = await db.execute(select(Tier).where(Tier.name == tier_name))
        tier = tier_result.scalar_one_or_none()
        if tier:
            tier_id = tier.id

    _local = email.split("@")[0].replace("-", "_").replace(".", "_")[:20]
    user = User(
        email=email,
        username=_local,
        username_lower=_local.lower(),
        password_hash=hash_password("password123"),
        first_name=email.split("@")[0].capitalize(),
        last_name="Tester",
        tier_id=tier_id,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    await create_user_wallet(db, user.id, email=email)
    return user


async def _create_scan(db: AsyncSession, user_id: uuid.UUID) -> Scan:
    """Create a scan for testing (needs a QR code)."""
    from app.models.product import Product

    # Get or create a product
    prod_result = await db.execute(select(Product).limit(1))
    product = prod_result.scalar_one_or_none()
    if not product:
        product = Product(name="Test Tin", price=Decimal("5.00"), stock=100)
        db.add(product)
        await db.commit()
        await db.refresh(product)

    qr = QRCode(product_code="TEST", unique_id=f"test-{uuid.uuid4().hex[:8]}")
    db.add(qr)
    await db.commit()
    await db.refresh(qr)

    scan = Scan(user_id=user_id, qr_code_id=qr.id)
    db.add(scan)
    await db.commit()
    await db.refresh(scan)
    return scan


def _auth_headers_for(user: User) -> dict:
    token = create_access_token(user.id)
    return {"Authorization": f"Bearer {token}"}


# ── Auto-create affiliate ───────────────────────────────────────────


async def test_auto_create_affiliate(db: AsyncSession):
    await seed_tiers(db)
    user = await _create_user(db, "autoaff@test.com")
    affiliate = await get_or_create_affiliate(db, user.id)
    assert affiliate is not None
    assert affiliate.user_id == user.id
    assert affiliate.referral_code is not None
    assert len(affiliate.referral_code) >= 3


async def test_get_or_create_returns_existing(db: AsyncSession):
    await seed_tiers(db)
    user = await _create_user(db, "existing@test.com")
    a1 = await get_or_create_affiliate(db, user.id)
    a2 = await get_or_create_affiliate(db, user.id)
    assert a1.id == a2.id


# ── Custom referral code ─────────────────────────────────────────────


async def test_set_custom_referral_code(db: AsyncSession):
    await seed_tiers(db)
    user = await _create_user(db, "custom@test.com")
    affiliate = await set_custom_referral_code(db, user.id, "mycode123")
    assert affiliate.referral_code == "mycode123"


async def test_duplicate_referral_code_rejected(db: AsyncSession):
    await seed_tiers(db)
    user1 = await _create_user(db, "dup1@test.com")
    user2 = await _create_user(db, "dup2@test.com")

    await set_custom_referral_code(db, user1.id, "taken-code")

    with pytest.raises(ValueError, match="already taken"):
        await set_custom_referral_code(db, user2.id, "taken-code")


# ── Referral attribution ─────────────────────────────────────────────


async def test_attribute_referral(db: AsyncSession):
    await seed_tiers(db)
    referrer = await _create_user(db, "referrer@test.com")
    affiliate = await get_or_create_affiliate(db, referrer.id)

    new_user = await _create_user(db, "newbie@test.com")
    result = await attribute_referral(db, new_user.id, affiliate.referral_code)
    assert result is True

    # Verify user's referred_by is set
    user_result = await db.execute(select(User).where(User.id == new_user.id))
    user = user_result.scalar_one()
    assert user.referred_by == referrer.id

    # Verify affiliate referred_count incremented
    await db.refresh(affiliate)
    assert affiliate.referred_count == 1


async def test_signup_with_referral_code(client: AsyncClient, db: AsyncSession):
    await seed_tiers(db)
    # Create a referrer first
    referrer = await _create_user(db, "signup-ref@test.com")
    affiliate = await get_or_create_affiliate(db, referrer.id)

    # Signup with referral code
    resp = await client.post("/api/auth/signup", json={
        "email": "referred@test.com",
        "password": "securepassword123",
        "username": "referred_user1",
        "first_name": "Referred",
        "last_name": "User",
        "birthdate": "1995-06-15",
        "referral_code": affiliate.referral_code,
    })
    assert resp.status_code == 201

    # Verify attribution
    new_user_id = uuid.UUID(resp.json()["user"]["id"])
    user_result = await db.execute(select(User).where(User.id == new_user_id))
    user = user_result.scalar_one()
    assert user.referred_by == referrer.id


# ── Referral scan → chip ─────────────────────────────────────────────


async def test_referral_scan_awards_chip(db: AsyncSession):
    await seed_tiers(db)
    referrer = await _create_user(db, "chipreferrer@test.com")
    affiliate = await get_or_create_affiliate(db, referrer.id)

    referred = await _create_user(db, "chipreferred@test.com")
    await attribute_referral(db, referred.id, affiliate.referral_code)

    scan = await _create_scan(db, referred.id)
    chip = await process_referral_scan(db, scan.id, referred.id)
    assert chip is not None
    assert chip.affiliate_id == affiliate.id
    assert chip.source_user_id == referred.id
    assert chip.source_scan_id == scan.id


# ── 21% reward matching ──────────────────────────────────────────────


async def test_reward_match_calculation():
    """$100 comp → $21 match."""
    match = calculate_reward_match(Decimal("100"))
    assert match == Decimal("21.00")


async def test_reward_match_calculation_large():
    """$200,000 trip comp → $42,000 match."""
    match = calculate_reward_match(Decimal("200000"))
    assert match == Decimal("42000.00")


async def test_process_reward_match(db: AsyncSession):
    await seed_tiers(db)
    referrer = await _create_user(db, "matchref@test.com")
    affiliate = await get_or_create_affiliate(db, referrer.id)

    referred = await _create_user(db, "matchreferred@test.com")
    await attribute_referral(db, referred.id, affiliate.referral_code)

    payout = await process_reward_match(db, Decimal("100"), referred.id)
    assert payout is not None
    assert payout.amount == Decimal("21.00")
    assert payout.payout_type == "reward_match"

    # Check affiliate earnings updated
    await db.refresh(affiliate)
    assert affiliate.lifetime_earnings == Decimal("21.00")


# ── Downline ─────────────────────────────────────────────────────────


async def test_get_downline(db: AsyncSession):
    await seed_tiers(db)
    referrer = await _create_user(db, "downlineref@test.com")
    affiliate = await get_or_create_affiliate(db, referrer.id)

    for i in range(3):
        u = await _create_user(db, f"down{i}@test.com")
        await attribute_referral(db, u.id, affiliate.referral_code)

    result = await get_downline(db, affiliate.id)
    assert result["total"] == 3
    assert len(result["items"]) == 3


# ── Chips vault/unvault ──────────────────────────────────────────────


async def test_vault_chips(db: AsyncSession):
    await seed_tiers(db)
    referrer = await _create_user(db, "vaultref@test.com")
    affiliate = await get_or_create_affiliate(db, referrer.id)

    referred = await _create_user(db, "vaultreferred@test.com")
    await attribute_referral(db, referred.id, affiliate.referral_code)

    # Create some chips
    chip_ids = []
    for _ in range(3):
        scan = await _create_scan(db, referred.id)
        chip = await process_referral_scan(db, scan.id, referred.id)
        chip_ids.append(chip.id)

    # Vault 2 chips
    count = await vault_chips(db, affiliate.id, chip_ids[:2])
    assert count == 2

    # Verify chip summary
    summary = await get_affiliate_chips(db, affiliate.id)
    assert summary["active_chips"] == 1
    assert summary["vaulted_chips"] == 2


async def test_unvault_chips(db: AsyncSession):
    await seed_tiers(db)
    referrer = await _create_user(db, "unvaultref@test.com")
    affiliate = await get_or_create_affiliate(db, referrer.id)

    referred = await _create_user(db, "unvaultreferred@test.com")
    await attribute_referral(db, referred.id, affiliate.referral_code)

    scan = await _create_scan(db, referred.id)
    chip = await process_referral_scan(db, scan.id, referred.id)

    await vault_chips(db, affiliate.id, [chip.id])
    count = await unvault_chips(db, affiliate.id, [chip.id])
    assert count == 1

    summary = await get_affiliate_chips(db, affiliate.id)
    assert summary["vaulted_chips"] == 0
    assert summary["active_chips"] == 1


# ── Weekly pool distribution ─────────────────────────────────────────


async def test_weekly_pool_distribution(db: AsyncSession):
    await seed_tiers(db)

    # Create 2 affiliates with different chip counts
    ref1 = await _create_user(db, "pool1@test.com")
    aff1 = await get_or_create_affiliate(db, ref1.id)
    u1 = await _create_user(db, "poolref1@test.com")
    await attribute_referral(db, u1.id, aff1.referral_code)

    ref2 = await _create_user(db, "pool2@test.com")
    aff2 = await get_or_create_affiliate(db, ref2.id)
    u2 = await _create_user(db, "poolref2@test.com")
    await attribute_referral(db, u2.id, aff2.referral_code)

    # 3 chips for aff1, 1 chip for aff2
    for _ in range(3):
        scan = await _create_scan(db, u1.id)
        await process_referral_scan(db, scan.id, u1.id)

    scan2 = await _create_scan(db, u2.id)
    await process_referral_scan(db, scan2.id, u2.id)

    # Distribute $100 pool
    distributions = await calculate_weekly_pool_distribution(db, Decimal("100"))
    assert len(distributions) == 2

    # aff1 has 3/4 = 75%, aff2 has 1/4 = 25%
    dist_map = {d["affiliate_id"]: d for d in distributions}
    assert dist_map[aff1.id]["share_amount"] == Decimal("75.00")
    assert dist_map[aff2.id]["share_amount"] == Decimal("25.00")


# ── Permanent tier ───────────────────────────────────────────────────


def test_permanent_tier_thresholds():
    assert check_permanent_tier(0) is None
    assert check_permanent_tier(209) is None
    assert check_permanent_tier(210) == "VIP"
    assert check_permanent_tier(2099) == "VIP"
    assert check_permanent_tier(2100) == "High Roller"
    assert check_permanent_tier(20999) == "High Roller"
    assert check_permanent_tier(21000) == "Whale"


# ── Sunset ───────────────────────────────────────────────────────────


async def test_sunset_progress(db: AsyncSession):
    result = await check_sunset_status(db)
    assert result["is_triggered"] is False
    assert result["threshold"] == 10_000_000
    assert result["percentage"] == 0.0


# ── API endpoints ────────────────────────────────────────────────────


async def test_affiliate_dashboard_api(client: AsyncClient, db: AsyncSession):
    await seed_tiers(db)
    user = await _create_user(db, "dashapi@test.com")

    headers = _auth_headers_for(user)
    resp = await client.get("/api/affiliate/me", headers=headers)
    assert resp.status_code == 200
    data = resp.json()
    assert "referral_code" in data
    assert "referral_link" in data
    assert data["referral_link"].startswith("https://blakjaks.com/r/")


async def test_affiliate_downline_api(client: AsyncClient, db: AsyncSession):
    await seed_tiers(db)
    user = await _create_user(db, "downapi@test.com")

    headers = _auth_headers_for(user)
    resp = await client.get("/api/affiliate/me/downline", headers=headers)
    assert resp.status_code == 200
    data = resp.json()
    assert "items" in data
    assert data["total"] == 0


async def test_affiliate_chips_api(client: AsyncClient, db: AsyncSession):
    await seed_tiers(db)
    user = await _create_user(db, "chipapi@test.com")

    headers = _auth_headers_for(user)
    resp = await client.get("/api/affiliate/me/chips", headers=headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["active_chips"] == 0
    assert data["vaulted_chips"] == 0


async def test_sunset_api(client: AsyncClient, db: AsyncSession):
    await seed_tiers(db)
    user = await _create_user(db, "sunsetapi@test.com")

    headers = _auth_headers_for(user)
    resp = await client.get("/api/affiliate/sunset", headers=headers)
    assert resp.status_code == 200
    data = resp.json()
    assert data["is_triggered"] is False
    assert data["threshold"] == 10_000_000
