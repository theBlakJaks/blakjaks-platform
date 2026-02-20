"""Governance endpoints — votes, ballots, proposals."""

import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.api.schemas.governance import (
    BallotCast,
    ProposalCreate,
    ProposalOut,
    VoteHistoryList,
    VoteOut,
)
from app.models.user import User
from app.services.governance_service import (
    cast_ballot,
    get_active_votes,
    get_user_proposals,
    get_user_vote_history,
    get_vote_detail,
    submit_proposal,
)

router = APIRouter(prefix="/governance", tags=["governance"])


@router.get("/votes", response_model=list[VoteOut])
async def list_votes(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await get_active_votes(db, user.id)


@router.get("/votes/history", response_model=VoteHistoryList)
async def vote_history(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await get_user_vote_history(db, user.id, page, per_page)


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


@router.post("/votes/{vote_id}/ballot", status_code=status.HTTP_201_CREATED)
async def cast_ballot_endpoint(
    vote_id: uuid.UUID,
    body: BallotCast,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Cast a ballot on a vote (alias for /cast)."""
    result = await cast_ballot(db, vote_id, user.id, body.option_id)
    if isinstance(result, str):
        if "already voted" in result.lower():
            raise HTTPException(status.HTTP_409_CONFLICT, result)
        raise HTTPException(status.HTTP_403_FORBIDDEN, result)
    return {"message": "Vote cast successfully", "option_id": result.option_id}


@router.post("/proposals", response_model=ProposalOut, status_code=status.HTTP_201_CREATED)
async def create_proposal(
    body: ProposalCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    options = [o.model_dump() for o in body.proposed_options] if body.proposed_options else None
    result = await submit_proposal(db, user.id, body.title, body.description, body.proposed_vote_type, options)
    if isinstance(result, str):
        raise HTTPException(status.HTTP_403_FORBIDDEN, result)
    return result


@router.get("/proposals/mine", response_model=list[ProposalOut])
async def my_proposals(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await get_user_proposals(db, user.id)
