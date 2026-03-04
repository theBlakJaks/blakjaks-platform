"""Governance endpoints — votes and ballots."""

import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.api.schemas.governance import (
    BallotCast,
    VoteOut,
)
from app.models.user import User
from app.services.governance_service import (
    cast_ballot,
    get_active_votes,
    get_vote_detail,
    get_votes_for_tier,
)

router = APIRouter(prefix="/governance", tags=["governance"])


@router.get("/votes", response_model=list[VoteOut])
async def list_votes(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await get_active_votes(db, user.id)


@router.get("/votes/tier/{tier_name}", response_model=list[VoteOut])
async def votes_for_tier(
    tier_name: str,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Return active votes targeting a specific tier (for governance rooms)."""
    return await get_votes_for_tier(db, tier_name, user.id)


@router.get("/votes/{vote_id}", response_model=VoteOut)
async def vote_detail(
    vote_id: uuid.UUID,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    detail = await get_vote_detail(db, vote_id, user.id)
    if not detail:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Vote not found")
    return detail


@router.post("/votes/{vote_id}/cast", status_code=status.HTTP_201_CREATED)
async def cast_vote(
    vote_id: uuid.UUID,
    body: BallotCast,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await cast_ballot(db, vote_id, user.id, body.option_id)
    if isinstance(result, str):
        if "already voted" in result.lower():
            raise HTTPException(status.HTTP_409_CONFLICT, result)
        raise HTTPException(status.HTTP_403_FORBIDDEN, result)
    return {"message": "Vote cast successfully", "option_id": result.option_id}
