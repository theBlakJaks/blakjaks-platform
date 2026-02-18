"""Admin governance endpoints — vote management, proposal review."""

import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.api.schemas.governance import ProposalOut, ProposalReview, VoteCreate, VoteOut
from app.models.user import User
from app.models.vote import Vote
from app.services.governance_service import (
    close_vote,
    create_vote,
    get_proposals,
    get_vote_detail,
    review_proposal,
)

router = APIRouter(prefix="/admin/governance", tags=["admin-governance"])


def require_admin(user: User = Depends(get_current_user)) -> User:
    if not user.is_admin:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Admin access required")
    return user


@router.post("/votes", response_model=VoteOut, status_code=status.HTTP_201_CREATED)
async def admin_create_vote(
    body: VoteCreate,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    options = [o.model_dump() for o in body.options]
    vote = await create_vote(
        db, admin.id, body.title, body.description, body.vote_type, options, body.duration_days
    )
    detail = await get_vote_detail(db, vote.id, admin.id)
    return detail


@router.put("/votes/{vote_id}/close")
async def admin_close_vote(
    vote_id: uuid.UUID,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    closed = await close_vote(db, vote_id, admin.id)
    if not closed:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Vote not found or already closed")
    return {"message": "Vote closed"}


@router.get("/proposals", response_model=list[ProposalOut])
async def admin_list_proposals(
    proposal_status: str | None = Query(None, alias="status"),
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    return await get_proposals(db, status_filter=proposal_status)


@router.put("/proposals/{proposal_id}/review")
async def admin_review_proposal(
    proposal_id: uuid.UUID,
    body: ProposalReview,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await review_proposal(db, proposal_id, admin.id, body.action, body.admin_notes)
    if isinstance(result, str):
        raise HTTPException(status.HTTP_404_NOT_FOUND, result)
    if isinstance(result, Vote):
        return {"message": "Proposal approved, vote created", "vote_id": str(result.id)}
    return {"message": f"Proposal status updated to {result.status}"}
