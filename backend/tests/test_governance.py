"""Tests for Governance & Voting System (updated for tier-based targeting)."""

import uuid
from datetime import datetime, timedelta, timezone
from decimal import Decimal

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token, hash_password
from app.models.user import User
from app.models.vote import Vote
from app.models.vote_ballot import VoteBallot
from app.services.governance_service import (
    cast_ballot,
    close_vote,
    create_vote,
    get_active_votes,
    get_vote_detail,
    get_vote_results,
    get_votes_for_tier,
)
from app.services.wallet_service import create_user_wallet
from tests.conftest import seed_tiers

pytestmark = pytest.mark.asyncio


# ── Helpers ──────────────────────────────────────────────────────────


async def _create_user(db: AsyncSession, email: str, tier_name: str | None = None, is_admin: bool = False) -> User:
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
        is_admin=is_admin,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    await create_user_wallet(db, user.id, email=email)
    return user


def _auth_headers_for(user: User) -> dict:
    token = create_access_token(user.id)
    return {"Authorization": f"Bearer {token}"}


def _future(days: int = 7) -> datetime:
    return datetime.now(timezone.utc) + timedelta(days=days)


FLAVOR_OPTIONS = [{"id": "mint", "label": "Mint"}, {"id": "berry", "label": "Berry"}, {"id": "citrus", "label": "Citrus"}]
PRODUCT_OPTIONS = [{"id": "yes", "label": "Yes"}, {"id": "no", "label": "No"}]
CORPORATE_OPTIONS = [{"id": "approve", "label": "Approve"}, {"id": "reject", "label": "Reject"}]


# ── Admin creates vote ───────────────────────────────────────────────


async def test_admin_creates_vote(db: AsyncSession):
    await seed_tiers(db)
    admin = await _create_user(db, "admin@test.com", "Whale", is_admin=True)

    vote = await create_vote(
        db, admin.id, "New Flavor", "Pick a flavor",
        ["VIP", "High Roller", "Whale"], FLAVOR_OPTIONS, _future(7),
    )
    assert vote.title == "New Flavor"
    assert vote.target_tiers == ["VIP", "High Roller", "Whale"]
    assert vote.status == "active"
    assert len(vote.options_json) == 3


# ── Tier-based voting eligibility ────────────────────────────────────


async def test_vip_can_vote_when_targeted(db: AsyncSession):
    await seed_tiers(db)
    admin = await _create_user(db, "admin2@test.com", "Whale", is_admin=True)
    vip = await _create_user(db, "vip@test.com", "VIP")

    vote = await create_vote(
        db, admin.id, "Flavor Vote", "Pick one",
        ["VIP", "High Roller", "Whale"], FLAVOR_OPTIONS, _future(7),
    )
    result = await cast_ballot(db, vote.id, vip.id, "mint")
    assert isinstance(result, VoteBallot)
    assert result.option_id == "mint"


async def test_standard_cannot_vote_when_not_targeted(db: AsyncSession):
    await seed_tiers(db)
    admin = await _create_user(db, "admin3@test.com", "Whale", is_admin=True)
    standard = await _create_user(db, "standard@test.com", "Standard")

    vote = await create_vote(
        db, admin.id, "Flavor Vote 2", "Pick one",
        ["VIP", "High Roller", "Whale"], FLAVOR_OPTIONS, _future(7),
    )
    result = await cast_ballot(db, vote.id, standard.id, "mint")
    assert isinstance(result, str)
    assert "not eligible" in result.lower()


async def test_high_roller_can_vote_when_targeted(db: AsyncSession):
    await seed_tiers(db)
    admin = await _create_user(db, "admin4@test.com", "Whale", is_admin=True)
    hr = await _create_user(db, "hr@test.com", "High Roller")

    vote = await create_vote(
        db, admin.id, "Product Vote", "New product?",
        ["High Roller", "Whale"], PRODUCT_OPTIONS, _future(7),
    )
    result = await cast_ballot(db, vote.id, hr.id, "yes")
    assert isinstance(result, VoteBallot)


async def test_vip_cannot_vote_when_not_targeted(db: AsyncSession):
    await seed_tiers(db)
    admin = await _create_user(db, "admin5@test.com", "Whale", is_admin=True)
    vip = await _create_user(db, "vip2@test.com", "VIP")

    vote = await create_vote(
        db, admin.id, "Product Vote 2", "New product?",
        ["High Roller", "Whale"], PRODUCT_OPTIONS, _future(7),
    )
    result = await cast_ballot(db, vote.id, vip.id, "yes")
    assert isinstance(result, str)
    assert "not eligible" in result.lower()


async def test_whale_can_vote_on_whale_only(db: AsyncSession):
    await seed_tiers(db)
    admin = await _create_user(db, "admin6@test.com", "Whale", is_admin=True)
    whale = await _create_user(db, "whale@test.com", "Whale")

    vote = await create_vote(
        db, admin.id, "Corporate Vote", "Board decision",
        ["Whale"], CORPORATE_OPTIONS, _future(7),
    )
    result = await cast_ballot(db, vote.id, whale.id, "approve")
    assert isinstance(result, VoteBallot)


async def test_high_roller_cannot_vote_on_whale_only(db: AsyncSession):
    await seed_tiers(db)
    admin = await _create_user(db, "admin7@test.com", "Whale", is_admin=True)
    hr = await _create_user(db, "hr2@test.com", "High Roller")

    vote = await create_vote(
        db, admin.id, "Corporate Vote 2", "Board decision",
        ["Whale"], CORPORATE_OPTIONS, _future(7),
    )
    result = await cast_ballot(db, vote.id, hr.id, "approve")
    assert isinstance(result, str)
    assert "not eligible" in result.lower()


# ── Ballot mechanics ─────────────────────────────────────────────────


async def test_cast_ballot_succeeds(db: AsyncSession):
    await seed_tiers(db)
    admin = await _create_user(db, "admin8@test.com", "Whale", is_admin=True)
    vip = await _create_user(db, "voter@test.com", "VIP")

    vote = await create_vote(
        db, admin.id, "Vote Test", "Test",
        ["VIP", "High Roller", "Whale"], FLAVOR_OPTIONS, _future(7),
    )
    result = await cast_ballot(db, vote.id, vip.id, "berry")
    assert isinstance(result, VoteBallot)
    assert result.option_id == "berry"


async def test_duplicate_ballot_rejected(db: AsyncSession):
    await seed_tiers(db)
    admin = await _create_user(db, "admin9@test.com", "Whale", is_admin=True)
    vip = await _create_user(db, "dupvoter@test.com", "VIP")

    vote = await create_vote(
        db, admin.id, "Dup Vote", "Test",
        ["VIP", "High Roller", "Whale"], FLAVOR_OPTIONS, _future(7),
    )
    await cast_ballot(db, vote.id, vip.id, "mint")
    result = await cast_ballot(db, vote.id, vip.id, "berry")
    assert isinstance(result, str)
    assert "already voted" in result.lower()


# ── Vote results ─────────────────────────────────────────────────────


async def test_vote_results_percentages(db: AsyncSession):
    await seed_tiers(db)
    admin = await _create_user(db, "admin10@test.com", "Whale", is_admin=True)

    vote = await create_vote(
        db, admin.id, "Results Vote", "Test",
        ["VIP", "High Roller", "Whale"], FLAVOR_OPTIONS, _future(7),
    )

    # 3 votes for mint, 1 for berry
    for i in range(3):
        user = await _create_user(db, f"voter{i}@test.com", "VIP")
        await cast_ballot(db, vote.id, user.id, "mint")

    berry_voter = await _create_user(db, "berryvoter@test.com", "VIP")
    await cast_ballot(db, vote.id, berry_voter.id, "berry")

    results = await get_vote_results(db, vote.id)
    result_map = {r["option_id"]: r for r in results}

    assert result_map["mint"]["count"] == 3
    assert result_map["mint"]["percentage"] == 75.0
    assert result_map["berry"]["count"] == 1
    assert result_map["berry"]["percentage"] == 25.0
    assert result_map["citrus"]["count"] == 0
    assert result_map["citrus"]["percentage"] == 0.0


# ── Admin closes vote ────────────────────────────────────────────────


async def test_admin_closes_vote(db: AsyncSession):
    await seed_tiers(db)
    admin = await _create_user(db, "admin11@test.com", "Whale", is_admin=True)

    vote = await create_vote(
        db, admin.id, "Close Vote", "Test",
        ["VIP", "High Roller", "Whale"], FLAVOR_OPTIONS, _future(7),
    )
    assert vote.status == "active"

    closed = await close_vote(db, vote.id, admin.id)
    assert closed is True

    # Verify status changed
    result = await db.execute(select(Vote).where(Vote.id == vote.id))
    updated = result.scalar_one()
    assert updated.status == "closed"


# ── Active votes filtered by tier ────────────────────────────────────


async def test_active_votes_filtered_by_tier(db: AsyncSession):
    await seed_tiers(db)
    admin = await _create_user(db, "admin12@test.com", "Whale", is_admin=True)
    vip = await _create_user(db, "filtervip@test.com", "VIP")

    # Create flavor vote (VIP+) and corporate vote (Whale only)
    await create_vote(
        db, admin.id, "Flavor Poll", "Pick flavor",
        ["VIP", "High Roller", "Whale"], FLAVOR_OPTIONS, _future(7),
    )
    await create_vote(
        db, admin.id, "Corp Poll", "Board decision",
        ["Whale"], CORPORATE_OPTIONS, _future(7),
    )

    votes = await get_active_votes(db, vip.id)
    titles = [v["title"] for v in votes]
    assert "Flavor Poll" in titles
    assert "Corp Poll" not in titles


# ── get_votes_for_tier ───────────────────────────────────────────────


async def test_get_votes_for_tier(db: AsyncSession):
    await seed_tiers(db)
    admin = await _create_user(db, "admin14@test.com", "Whale", is_admin=True)

    await create_vote(
        db, admin.id, "VIP Vote", "For VIP",
        ["VIP", "High Roller"], FLAVOR_OPTIONS, _future(7),
    )
    await create_vote(
        db, admin.id, "Whale Vote", "For Whale",
        ["Whale"], CORPORATE_OPTIONS, _future(7),
    )

    vip_votes = await get_votes_for_tier(db, "VIP", admin.id)
    assert len(vip_votes) == 1
    assert vip_votes[0]["title"] == "VIP Vote"

    whale_votes = await get_votes_for_tier(db, "Whale", admin.id)
    assert len(whale_votes) == 1
    assert whale_votes[0]["title"] == "Whale Vote"


# ── API endpoints ────────────────────────────────────────────────────


async def test_create_vote_api(client: AsyncClient, db: AsyncSession):
    await seed_tiers(db)
    admin = await _create_user(db, "apiadmin@test.com", "Whale", is_admin=True)

    headers = _auth_headers_for(admin)
    resp = await client.post("/api/admin/governance/votes", headers=headers, json={
        "title": "API Vote",
        "description": "Test via API",
        "target_tiers": ["VIP", "High Roller", "Whale"],
        "options": [{"id": "a", "label": "Option A"}, {"id": "b", "label": "Option B"}],
        "end_date": _future(7).isoformat(),
    })
    assert resp.status_code == 201
    data = resp.json()
    assert data["title"] == "API Vote"
    assert data["status"] == "active"
    assert data["target_tiers"] == ["VIP", "High Roller", "Whale"]


async def test_cast_ballot_api(client: AsyncClient, db: AsyncSession):
    await seed_tiers(db)
    admin = await _create_user(db, "apiadmin2@test.com", "Whale", is_admin=True)
    vip = await _create_user(db, "apivip@test.com", "VIP")

    vote = await create_vote(
        db, admin.id, "API Ballot", "Cast test",
        ["VIP", "High Roller", "Whale"], FLAVOR_OPTIONS, _future(7),
    )

    headers = _auth_headers_for(vip)
    resp = await client.post(
        f"/api/governance/votes/{vote.id}/cast",
        headers=headers,
        json={"option_id": "mint"},
    )
    assert resp.status_code == 201
    assert resp.json()["option_id"] == "mint"


async def test_standard_cast_ballot_api_forbidden(client: AsyncClient, db: AsyncSession):
    await seed_tiers(db)
    admin = await _create_user(db, "apiadmin3@test.com", "Whale", is_admin=True)
    standard = await _create_user(db, "apistd@test.com", "Standard")

    vote = await create_vote(
        db, admin.id, "API Forbidden", "Test",
        ["VIP", "High Roller", "Whale"], FLAVOR_OPTIONS, _future(7),
    )

    headers = _auth_headers_for(standard)
    resp = await client.post(
        f"/api/governance/votes/{vote.id}/cast",
        headers=headers,
        json={"option_id": "mint"},
    )
    assert resp.status_code == 403
