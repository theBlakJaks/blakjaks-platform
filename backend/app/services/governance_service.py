"""Governance & Voting service — votes and ballots."""

import logging
import uuid
from datetime import datetime, timezone

from sqlalchemy import func, select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.vote import Vote
from app.models.vote_ballot import VoteBallot

logger = logging.getLogger(__name__)


async def _get_user_effective_tier(db, user_id: uuid.UUID) -> str:
    """Get effective tier for a user (dynamic + direct assignment)."""
    from app.services.chat_service import _get_user_effective_tier_name
    return await _get_user_effective_tier_name(db, user_id)


# ── Vote CRUD ────────────────────────────────────────────────────────


async def create_vote(
    db: AsyncSession,
    admin_user_id: uuid.UUID,
    title: str,
    description: str,
    target_tiers: list[str],
    options: list[dict],
    end_date: datetime,
) -> Vote:
    """Admin creates a vote targeting specific tiers."""
    now = datetime.now(timezone.utc)

    vote = Vote(
        title=title,
        description=description,
        options_json=options,
        target_tiers=target_tiers,
        status="active",
        start_date=now,
        end_date=end_date,
        created_by=admin_user_id,
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
        tiers = v.target_tiers if isinstance(v.target_tiers, list) else []
        if user_tier not in tiers:
            continue

        # Check if user has voted
        ballot_result = await db.execute(
            select(VoteBallot).where(VoteBallot.vote_id == v.id, VoteBallot.user_id == user_id)
        )
        ballot = ballot_result.scalar_one_or_none()

        results = await _get_vote_results(db, v)

        eligible.append(_vote_to_dict(v, results, ballot))

    return eligible


async def get_votes_for_tier(db: AsyncSession, tier_name: str, user_id: uuid.UUID) -> list[dict]:
    """Return active votes where tier_name is in target_tiers (for governance rooms)."""
    result = await db.execute(
        select(Vote).where(Vote.status == "active").order_by(Vote.start_date.desc())
    )
    votes = result.scalars().all()

    matching = []
    for v in votes:
        tiers = v.target_tiers if isinstance(v.target_tiers, list) else []
        if tier_name not in tiers:
            continue

        ballot_result = await db.execute(
            select(VoteBallot).where(VoteBallot.vote_id == v.id, VoteBallot.user_id == user_id)
        )
        ballot = ballot_result.scalar_one_or_none()

        results = await _get_vote_results(db, v)
        matching.append(_vote_to_dict(v, results, ballot))

    return matching


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
        "target_tiers": vote.target_tiers if isinstance(vote.target_tiers, list) else [],
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
    tiers = vote.target_tiers if isinstance(vote.target_tiers, list) else []
    if user_tier not in tiers:
        return f"{user_tier} tier is not eligible for this vote"

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


async def get_all_votes(db: AsyncSession) -> list[Vote]:
    """Admin: return all votes regardless of status, newest first."""
    result = await db.execute(
        select(Vote).order_by(Vote.created_at.desc())
    )
    return list(result.scalars().all())


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
    """Post vote results to the Standard category announcements channel."""
    from app.models.channel import Channel
    from app.models.message import Message

    vote_result = await db.execute(select(Vote).where(Vote.id == vote_id))
    vote = vote_result.scalar_one_or_none()
    if not vote:
        return

    results = await _get_vote_results(db, vote)
    total = sum(r["count"] for r in results)

    lines = [f"Vote Results: {vote.title}"]
    for r in results:
        lines.append(f"  - {r['label']}: {r['count']} votes ({r['percentage']}%)")
    lines.append(f"Total votes: {total}")
    content = "\n".join(lines)

    # Find Standard category announcements channel
    ch_result = await db.execute(
        select(Channel).where(
            Channel.name == "announcements",
            Channel.category == "Standard",
        )
    )
    channel = ch_result.scalar_one_or_none()
    if not channel:
        # Fallback: any announcements channel
        ch_result = await db.execute(
            select(Channel).where(Channel.name == "announcements")
        )
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
