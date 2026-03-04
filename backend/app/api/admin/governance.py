"""Admin governance endpoints — vote management."""

import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.api.schemas.governance import VoteCreate, VoteOut
from app.models.user import User
from app.services.governance_service import (
    close_vote,
    create_vote,
    get_all_votes,
    get_vote_detail,
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
        db, admin.id, body.title, body.description, body.target_tiers, options, body.end_date
    )
    detail = await get_vote_detail(db, vote.id, admin.id)
    return detail


@router.get("/votes", response_model=list[VoteOut])
async def admin_list_votes(
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Return all votes (all statuses) for admin review."""
    votes = await get_all_votes(db)
    results = []
    for vote in votes:
        detail = await get_vote_detail(db, vote.id, admin.id)
        if detail:
            results.append(detail)
    return results


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
