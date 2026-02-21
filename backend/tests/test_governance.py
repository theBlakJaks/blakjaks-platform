"""Tests for Governance & Voting System (Task 15)."""

import uuid
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
    get_user_vote_history,
    get_vote_detail,
    get_vote_results,
    review_proposal,
    submit_proposal,
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


FLAVOR_OPTIONS = [{"id": "mint", "label": "Mint"}, {"id": "berry", "label": "Berry"}, {"id": "citrus", "label": "Citrus"}]
PRODUCT_OPTIONS = [{"id": "yes", "label": "Yes"}, {"id": "no", "label": "No"}]
CORPORATE_OPTIONS = [{"id": "approve", "label": "Approve"}, {"id": "reject", "label": "Reject"}]


# ── Admin creates vote ───────────────────────────────────────────────


async def test_admin_creates_flavor_vote(db: AsyncSession):
    await seed_tiers(db)
    admin = await _create_user(db, "admin@test.com", "Whale", is_admin=True)

    vote = await create_vote(db, admin.id, "New Flavor", "Pick a flavor", "flavor", FLAVOR_OPTIONS)
    assert vote.title == "New Flavor"
    assert vote.vote_type == "flavor"
    assert vote.status == "active"
    assert vote.min_tier_required == "VIP"
    assert len(vote.options_json) == 3


# ── Tier-based voting eligibility ────────────────────────────────────


async def test_vip_can_vote_on_flavor(db: AsyncSession):
    await seed_tiers(db)
    admin = await _create_user(db, "admin2@test.com", "Whale", is_admin=True)
    vip = await _create_user(db, "vip@test.com", "VIP")

    vote = await create_vote(db, admin.id, "Flavor Vote", "Pick one", "flavor", FLAVOR_OPTIONS)
    result = await cast_ballot(db, vote.id, vip.id, "mint")
    assert isinstance(result, VoteBallot)
    assert result.option_id == "mint"


async def test_standard_cannot_vote_on_flavor(db: AsyncSession):
    await seed_tiers(db)
    admin = await _create_user(db, "admin3@test.com", "Whale", is_admin=True)
    standard = await _create_user(db, "standard@test.com", "Standard")

    vote = await create_vote(db, admin.id, "Flavor Vote 2", "Pick one", "flavor", FLAVOR_OPTIONS)
    result = await cast_ballot(db, vote.id, standard.id, "mint")
    assert isinstance(result, str)
    assert "cannot vote" in result.lower()


async def test_high_roller_can_vote_on_product(db: AsyncSession):
    await seed_tiers(db)
    admin = await _create_user(db, "admin4@test.com", "Whale", is_admin=True)
    hr = await _create_user(db, "hr@test.com", "High Roller")

    vote = await create_vote(db, admin.id, "Product Vote", "New product?", "product", PRODUCT_OPTIONS)
    result = await cast_ballot(db, vote.id, hr.id, "yes")
    assert isinstance(result, VoteBallot)


async def test_vip_cannot_vote_on_product(db: AsyncSession):
    await seed_tiers(db)
    admin = await _create_user(db, "admin5@test.com", "Whale", is_admin=True)
    vip = await _create_user(db, "vip2@test.com", "VIP")

    vote = await create_vote(db, admin.id, "Product Vote 2", "New product?", "product", PRODUCT_OPTIONS)
    result = await cast_ballot(db, vote.id, vip.id, "yes")
    assert isinstance(result, str)
    assert "cannot vote" in result.lower()


async def test_whale_can_vote_on_corporate(db: AsyncSession):
    await seed_tiers(db)
    admin = await _create_user(db, "admin6@test.com", "Whale", is_admin=True)
    whale = await _create_user(db, "whale@test.com", "Whale")

    vote = await create_vote(db, admin.id, "Corporate Vote", "Board decision", "corporate", CORPORATE_OPTIONS)
    result = await cast_ballot(db, vote.id, whale.id, "approve")
    assert isinstance(result, VoteBallot)


async def test_high_roller_cannot_vote_on_corporate(db: AsyncSession):
    await seed_tiers(db)
    admin = await _create_user(db, "admin7@test.com", "Whale", is_admin=True)
    hr = await _create_user(db, "hr2@test.com", "High Roller")

    vote = await create_vote(db, admin.id, "Corporate Vote 2", "Board decision", "corporate", CORPORATE_OPTIONS)
    result = await cast_ballot(db, vote.id, hr.id, "approve")
    assert isinstance(result, str)
    assert "cannot vote" in result.lower()


# ── Ballot mechanics ─────────────────────────────────────────────────


async def test_cast_ballot_succeeds(db: AsyncSession):
    await seed_tiers(db)
    admin = await _create_user(db, "admin8@test.com", "Whale", is_admin=True)
    vip = await _create_user(db, "voter@test.com", "VIP")

    vote = await create_vote(db, admin.id, "Vote Test", "Test", "flavor", FLAVOR_OPTIONS)
    result = await cast_ballot(db, vote.id, vip.id, "berry")
    assert isinstance(result, VoteBallot)
    assert result.option_id == "berry"


async def test_duplicate_ballot_rejected(db: AsyncSession):
    await seed_tiers(db)
    admin = await _create_user(db, "admin9@test.com", "Whale", is_admin=True)
    vip = await _create_user(db, "dupvoter@test.com", "VIP")

    vote = await create_vote(db, admin.id, "Dup Vote", "Test", "flavor", FLAVOR_OPTIONS)
    await cast_ballot(db, vote.id, vip.id, "mint")
    result = await cast_ballot(db, vote.id, vip.id, "berry")
    assert isinstance(result, str)
    assert "already voted" in result.lower()


# ── Vote results ─────────────────────────────────────────────────────


async def test_vote_results_percentages(db: AsyncSession):
    await seed_tiers(db)
    admin = await _create_user(db, "admin10@test.com", "Whale", is_admin=True)

    vote = await create_vote(db, admin.id, "Results Vote", "Test", "flavor", FLAVOR_OPTIONS)

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

    vote = await create_vote(db, admin.id, "Close Vote", "Test", "flavor", FLAVOR_OPTIONS)
    assert vote.status == "active"

    closed = await close_vote(db, vote.id, admin.id)
    assert closed is True

    # Verify status changed
    result = await db.execute(select(Vote).where(Vote.id == vote.id))
    updated = result.scalar_one()
    assert updated.status == "closed"


# ── Proposals ────────────────────────────────────────────────────────


async def test_whale_submits_proposal(db: AsyncSession):
    await seed_tiers(db)
    whale = await _create_user(db, "propwhale@test.com", "Whale")

    result = await submit_proposal(db, whale.id, "New Feature", "Add something cool", "product")
    from app.models.governance_proposal import GovernanceProposal
    assert isinstance(result, GovernanceProposal)
    assert result.status == "pending"
    assert result.title == "New Feature"


async def test_vip_cannot_submit_proposal(db: AsyncSession):
    await seed_tiers(db)
    vip = await _create_user(db, "propvip@test.com", "VIP")

    result = await submit_proposal(db, vip.id, "VIP Idea", "My idea", "flavor")
    assert isinstance(result, str)
    assert "whale" in result.lower()


async def test_admin_approves_proposal_creates_vote(db: AsyncSession):
    await seed_tiers(db)
    whale = await _create_user(db, "propwhale2@test.com", "Whale")
    admin = await _create_user(db, "propadmin@test.com", "Whale", is_admin=True)

    proposal = await submit_proposal(
        db, whale.id, "Governance Change", "Important change", "corporate",
        [{"id": "yes", "label": "Yes"}, {"id": "no", "label": "No"}],
    )
    from app.models.governance_proposal import GovernanceProposal
    assert isinstance(proposal, GovernanceProposal)

    result = await review_proposal(db, proposal.id, admin.id, "approve", "Looks good")
    assert isinstance(result, Vote)
    assert result.title == "Governance Change"
    assert result.vote_type == "corporate"
    assert result.proposal_id == proposal.id


async def test_admin_rejects_proposal(db: AsyncSession):
    await seed_tiers(db)
    whale = await _create_user(db, "propwhale3@test.com", "Whale")
    admin = await _create_user(db, "propadmin2@test.com", "Whale", is_admin=True)

    proposal = await submit_proposal(db, whale.id, "Bad Idea", "Not great", "flavor")
    from app.models.governance_proposal import GovernanceProposal
    assert isinstance(proposal, GovernanceProposal)

    result = await review_proposal(db, proposal.id, admin.id, "reject", "Not aligned with roadmap")
    assert isinstance(result, GovernanceProposal)
    assert result.status == "rejected"
    assert result.admin_notes == "Not aligned with roadmap"


# ── Active votes filtered by tier ────────────────────────────────────


async def test_active_votes_filtered_by_tier(db: AsyncSession):
    await seed_tiers(db)
    admin = await _create_user(db, "admin12@test.com", "Whale", is_admin=True)
    vip = await _create_user(db, "filtervip@test.com", "VIP")

    # Create flavor vote (VIP+) and corporate vote (Whale only)
    await create_vote(db, admin.id, "Flavor Poll", "Pick flavor", "flavor", FLAVOR_OPTIONS)
    await create_vote(db, admin.id, "Corp Poll", "Board decision", "corporate", CORPORATE_OPTIONS)

    votes = await get_active_votes(db, vip.id)
    vote_types = [v["vote_type"] for v in votes]
    assert "flavor" in vote_types
    assert "corporate" not in vote_types


# ── Vote history ─────────────────────────────────────────────────────


async def test_vote_history(db: AsyncSession):
    await seed_tiers(db)
    admin = await _create_user(db, "admin13@test.com", "Whale", is_admin=True)
    vip = await _create_user(db, "histvip@test.com", "VIP")

    vote = await create_vote(db, admin.id, "History Vote", "Test", "flavor", FLAVOR_OPTIONS)
    await cast_ballot(db, vote.id, vip.id, "citrus")

    history = await get_user_vote_history(db, vip.id)
    assert history["total"] == 1
    assert history["items"][0]["vote_id"] == vote.id
    assert history["items"][0]["user_option"] == "citrus"


# ── API endpoints ────────────────────────────────────────────────────


async def test_create_vote_api(client: AsyncClient, db: AsyncSession):
    await seed_tiers(db)
    admin = await _create_user(db, "apiadmin@test.com", "Whale", is_admin=True)

    headers = _auth_headers_for(admin)
    resp = await client.post("/api/admin/governance/votes", headers=headers, json={
        "title": "API Vote",
        "description": "Test via API",
        "vote_type": "flavor",
        "options": [{"id": "a", "label": "Option A"}, {"id": "b", "label": "Option B"}],
        "duration_days": 7,
    })
    assert resp.status_code == 201
    data = resp.json()
    assert data["title"] == "API Vote"
    assert data["status"] == "active"


async def test_cast_ballot_api(client: AsyncClient, db: AsyncSession):
    await seed_tiers(db)
    admin = await _create_user(db, "apiadmin2@test.com", "Whale", is_admin=True)
    vip = await _create_user(db, "apivip@test.com", "VIP")

    vote = await create_vote(db, admin.id, "API Ballot", "Cast test", "flavor", FLAVOR_OPTIONS)

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

    vote = await create_vote(db, admin.id, "API Forbidden", "Test", "flavor", FLAVOR_OPTIONS)

    headers = _auth_headers_for(standard)
    resp = await client.post(
        f"/api/governance/votes/{vote.id}/cast",
        headers=headers,
        json={"option_id": "mint"},
    )
    assert resp.status_code == 403
