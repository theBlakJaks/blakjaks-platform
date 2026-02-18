"""Governance & Voting service — votes, ballots, proposals."""

import logging
import uuid
from datetime import datetime, timedelta, timezone

from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.governance_proposal import GovernanceProposal
from app.models.vote import Vote
from app.models.vote_ballot import VoteBallot
from app.services.tier import TIER_ORDER

logger = logging.getLogger(__name__)

# Vote type → minimum tier required (uses TIER_ORDER for rank comparison)
VOTE_TYPE_MIN_TIER: dict[str, str] = {
    "flavor": "VIP",
    "product": "High Roller",
    "loyalty": "High Roller",
    "corporate": "Whale",
}

# Tier eligibility: vote_type → list of eligible tier names
TIER_VOTE_ELIGIBILITY: dict[str, list[str]] = {
    "flavor": ["VIP", "High Roller", "Whale"],
    "product": ["High Roller", "Whale"],
    "loyalty": ["High Roller", "Whale"],
    "corporate": ["Whale"],
}


def _tier_rank(tier_name: str | None) -> int:
    if tier_name is None:
        return -1
    try:
        return TIER_ORDER.index(tier_name)
    except ValueError:
        return -1


async def _get_user_effective_tier(db, user_id: uuid.UUID) -> str:
    """Get effective tier for a user (dynamic + direct assignment)."""
    from app.services.chat_service import _get_user_effective_tier_name
    return await _get_user_effective_tier_name(db, user_id)


def _user_can_vote(user_tier: str, vote_type: str) -> bool:
    """Check if user's tier qualifies for this vote type."""
    eligible = TIER_VOTE_ELIGIBILITY.get(vote_type, [])
    return user_tier in eligible


# ── Vote CRUD ────────────────────────────────────────────────────────


async def create_vote(
    db: AsyncSession,
    admin_user_id: uuid.UUID,
    title: str,
    description: str,
    vote_type: str,
    options: list[dict],
    duration_days: int = 7,
    proposal_id: uuid.UUID | None = None,
) -> Vote:
    """Admin creates a vote. Auto-sets min_tier from vote_type."""
    min_tier = VOTE_TYPE_MIN_TIER.get(vote_type, "VIP")
    now = datetime.now(timezone.utc)

    vote = Vote(
        title=title,
        description=description,
        vote_type=vote_type,
        options_json=options,
        min_tier_required=min_tier,
        status="active",
        start_date=now,
        end_date=now + timedelta(days=duration_days),
        created_by=admin_user_id,
        proposal_id=proposal_id,
    )
    db.add(vote)
    await db.commit()
    await db.refresh(vote)
    return vote


async def get_active_votes(db: AsyncSession, user_id: uuid.UUID) -> list[dict]:
    """Return active votes the user is eligible for based on their effective tier."""
    user_tier = await _get_user_effective_tier(db, user_id)

    result = await db.execute(
        select(Vote).where(Vote.status == "active").order_by(Vote.start_date.desc())
    )
    votes = result.scalars().all()

    eligible = []
    for v in votes:
        if not _user_can_vote(user_tier, v.vote_type):
            continue

        # Check if user has voted
        ballot_result = await db.execute(
            select(VoteBallot).where(VoteBallot.vote_id == v.id, VoteBallot.user_id == user_id)
        )
        ballot = ballot_result.scalar_one_or_none()

        results = await _get_vote_results(db, v)

        eligible.append(_vote_to_dict(v, results, ballot))

    return eligible


async def get_vote_detail(db: AsyncSession, vote_id: uuid.UUID, user_id: uuid.UUID) -> dict | None:
    """Return vote detail with results and user's ballot."""
    result = await db.execute(select(Vote).where(Vote.id == vote_id))
    vote = result.scalar_one_or_none()
    if not vote:
        return None

    ballot_result = await db.execute(
        select(VoteBallot).where(VoteBallot.vote_id == vote_id, VoteBallot.user_id == user_id)
    )
    ballot = ballot_result.scalar_one_or_none()

    results = await _get_vote_results(db, vote)
    return _vote_to_dict(vote, results, ballot)


async def _get_vote_results(db: AsyncSession, vote: Vote) -> list[dict]:
    """Calculate per-option vote counts and percentages."""
    result = await db.execute(
        select(VoteBallot.option_id, func.count(VoteBallot.id).label("cnt"))
        .where(VoteBallot.vote_id == vote.id)
        .group_by(VoteBallot.option_id)
    )
    rows = result.all()

    total = sum(r.cnt for r in rows)
    count_map = {r.option_id: r.cnt for r in rows}

    options = vote.options_json if isinstance(vote.options_json, list) else []
    results = []
    for opt in options:
        opt_id = opt.get("id", "")
        cnt = count_map.get(opt_id, 0)
        pct = round(cnt / total * 100, 1) if total > 0 else 0.0
        results.append({
            "option_id": opt_id,
            "label": opt.get("label", ""),
            "count": cnt,
            "percentage": pct,
        })

    return results


def _vote_to_dict(vote: Vote, results: list[dict], ballot: VoteBallot | None) -> dict:
    """Convert a Vote + results + ballot to response dict."""
    options = vote.options_json if isinstance(vote.options_json, list) else []
    total_votes = sum(r["count"] for r in results)

    return {
        "id": vote.id,
        "title": vote.title,
        "description": vote.description,
        "vote_type": vote.vote_type,
        "options": [{"id": o.get("id", ""), "label": o.get("label", "")} for o in options],
        "status": vote.status,
        "start_date": vote.start_date,
        "end_date": vote.end_date,
        "total_votes": total_votes,
        "results": results,
        "user_has_voted": ballot is not None,
        "user_selected_option": ballot.option_id if ballot else None,
        "created_at": vote.created_at,
    }


# ── Ballot casting ───────────────────────────────────────────────────


async def cast_ballot(
    db: AsyncSession, vote_id: uuid.UUID, user_id: uuid.UUID, option_id: str
) -> VoteBallot | str:
    """Cast a ballot. Returns the ballot or an error string."""
    # Get vote
    vote_result = await db.execute(select(Vote).where(Vote.id == vote_id))
    vote = vote_result.scalar_one_or_none()
    if not vote:
        return "Vote not found"

    if vote.status != "active":
        return "Vote is not active"

    # Check expiry
    now = datetime.now(timezone.utc)
    end_date = vote.end_date
    if end_date.tzinfo is None:
        end_date = end_date.replace(tzinfo=timezone.utc)
    if now > end_date:
        return "Vote has expired"

    # Check tier eligibility
    user_tier = await _get_user_effective_tier(db, user_id)
    if not _user_can_vote(user_tier, vote.vote_type):
        return f"{user_tier} tier cannot vote on {vote.vote_type} votes"

    # Check option exists
    options = vote.options_json if isinstance(vote.options_json, list) else []
    valid_ids = [o.get("id") for o in options]
    if option_id not in valid_ids:
        return "Invalid option"

    # Check not already voted
    existing = await db.execute(
        select(VoteBallot).where(VoteBallot.vote_id == vote_id, VoteBallot.user_id == user_id)
    )
    if existing.scalar_one_or_none():
        return "You have already voted on this ballot"

    ballot = VoteBallot(vote_id=vote_id, user_id=user_id, option_id=option_id)
    db.add(ballot)
    await db.commit()
    await db.refresh(ballot)
    return ballot


async def get_vote_results(db: AsyncSession, vote_id: uuid.UUID) -> list[dict]:
    """Return full results for a vote."""
    vote_result = await db.execute(select(Vote).where(Vote.id == vote_id))
    vote = vote_result.scalar_one_or_none()
    if not vote:
        return []
    return await _get_vote_results(db, vote)


# ── Vote closing ─────────────────────────────────────────────────────


async def close_vote(db: AsyncSession, vote_id: uuid.UUID, admin_user_id: uuid.UUID) -> bool:
    """Close a vote early. Returns True if closed."""
    result = await db.execute(
        update(Vote)
        .where(Vote.id == vote_id, Vote.status == "active")
        .values(status="closed")
    )
    await db.commit()

    if result.rowcount > 0:
        # Post results to announcements (fire-and-forget)
        try:
            await _post_vote_results_to_announcements(db, vote_id, admin_user_id)
        except Exception:
            logger.exception("Failed to post vote results to announcements")
        return True
    return False


async def auto_close_expired_votes(db: AsyncSession) -> int:
    """Batch job: close votes past their end_date."""
    now = datetime.now(timezone.utc)
    result = await db.execute(
        update(Vote)
        .where(Vote.status == "active", Vote.end_date <= now)
        .values(status="closed")
        .returning(Vote.id)
    )
    closed_ids = result.scalars().all()
    await db.commit()
    return len(closed_ids)


async def _post_vote_results_to_announcements(
    db: AsyncSession, vote_id: uuid.UUID, user_id: uuid.UUID
) -> None:
    """Post vote results to #announcements channel as a system message."""
    from app.models.channel import Channel
    from app.models.message import Message

    vote_result = await db.execute(select(Vote).where(Vote.id == vote_id))
    vote = vote_result.scalar_one_or_none()
    if not vote:
        return

    results = await _get_vote_results(db, vote)
    total = sum(r["count"] for r in results)

    lines = [f"📊 Vote Results: {vote.title}"]
    for r in results:
        lines.append(f"  • {r['label']}: {r['count']} votes ({r['percentage']}%)")
    lines.append(f"Total votes: {total}")
    content = "\n".join(lines)

    # Find #announcements channel
    ch_result = await db.execute(select(Channel).where(Channel.name == "announcements"))
    channel = ch_result.scalar_one_or_none()
    if not channel:
        return

    msg = Message(
        channel_id=channel.id,
        user_id=user_id,
        content=content,
        is_system=True,
    )
    db.add(msg)
    await db.commit()


# ── User vote history ────────────────────────────────────────────────


async def get_user_vote_history(
    db: AsyncSession, user_id: uuid.UUID, page: int = 1, per_page: int = 20
) -> dict:
    """Paginated list of votes the user has participated in."""
    base = (
        select(VoteBallot, Vote)
        .join(Vote, VoteBallot.vote_id == Vote.id)
        .where(VoteBallot.user_id == user_id)
    )

    count_result = await db.execute(
        select(func.count()).select_from(VoteBallot).where(VoteBallot.user_id == user_id)
    )
    total = count_result.scalar_one()

    result = await db.execute(
        base.order_by(VoteBallot.created_at.desc())
        .offset((page - 1) * per_page)
        .limit(per_page)
    )
    rows = result.all()

    items = []
    for ballot, vote in rows:
        items.append({
            "vote_id": vote.id,
            "title": vote.title,
            "vote_type": vote.vote_type,
            "user_option": ballot.option_id,
            "status": vote.status,
            "created_at": ballot.created_at,
        })

    return {"items": items, "total": total, "page": page, "per_page": per_page}


# ── Proposals ────────────────────────────────────────────────────────


async def submit_proposal(
    db: AsyncSession,
    user_id: uuid.UUID,
    title: str,
    description: str,
    proposed_vote_type: str,
    proposed_options: list[dict] | None = None,
) -> GovernanceProposal | str:
    """Whale only submits a proposal."""
    user_tier = await _get_user_effective_tier(db, user_id)
    if user_tier != "Whale":
        return "Only Whale tier members can submit proposals"

    proposal = GovernanceProposal(
        user_id=user_id,
        title=title,
        description=description,
        proposed_vote_type=proposed_vote_type,
        proposed_options_json=proposed_options,
    )
    db.add(proposal)
    await db.commit()
    await db.refresh(proposal)
    return proposal


async def get_proposals(
    db: AsyncSession, status_filter: str | None = None
) -> list[GovernanceProposal]:
    """List proposals, optionally filtered by status."""
    query = select(GovernanceProposal).order_by(GovernanceProposal.created_at.desc())
    if status_filter:
        query = query.where(GovernanceProposal.status == status_filter)
    result = await db.execute(query)
    return list(result.scalars().all())


async def get_user_proposals(db: AsyncSession, user_id: uuid.UUID) -> list[GovernanceProposal]:
    """List proposals submitted by a specific user."""
    result = await db.execute(
        select(GovernanceProposal)
        .where(GovernanceProposal.user_id == user_id)
        .order_by(GovernanceProposal.created_at.desc())
    )
    return list(result.scalars().all())


async def review_proposal(
    db: AsyncSession,
    proposal_id: uuid.UUID,
    admin_user_id: uuid.UUID,
    action: str,
    admin_notes: str | None = None,
) -> GovernanceProposal | Vote | str:
    """Admin reviews a proposal. If approved, auto-creates vote."""
    result = await db.execute(
        select(GovernanceProposal).where(GovernanceProposal.id == proposal_id)
    )
    proposal = result.scalar_one_or_none()
    if not proposal:
        return "Proposal not found"

    now = datetime.now(timezone.utc)
    proposal.reviewed_by = admin_user_id
    proposal.reviewed_at = now
    proposal.admin_notes = admin_notes

    if action == "approve":
        proposal.status = "approved"
        await db.commit()

        # Auto-create vote from proposal
        options = proposal.proposed_options_json or [
            {"id": "yes", "label": "Yes"},
            {"id": "no", "label": "No"},
        ]
        vote = await create_vote(
            db,
            admin_user_id,
            proposal.title,
            proposal.description,
            proposal.proposed_vote_type,
            options,
            proposal_id=proposal.id,
        )
        return vote
    elif action == "reject":
        proposal.status = "rejected"
    elif action == "changes_requested":
        proposal.status = "changes_requested"
    else:
        return "Invalid action"

    await db.commit()
    await db.refresh(proposal)
    return proposal
