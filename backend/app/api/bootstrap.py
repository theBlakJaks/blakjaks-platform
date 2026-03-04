"""Bootstrap endpoint — fetches all initial app data in a single call."""

import asyncio
import logging

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.models.user import User

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/bootstrap", tags=["bootstrap"])


@router.get("")
async def bootstrap(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Fetch user profile, wallet, unread count, and active votes in parallel."""
    from sqlalchemy import select
    from sqlalchemy.orm import selectinload

    from app.services.governance_service import get_active_votes
    from app.services.notification_service import get_unread_count
    from app.services.wallet_service import get_user_wallet_balance

    async def fetch_profile():
        try:
            result = await db.execute(
                select(User).options(selectinload(User.tier)).where(User.id == current_user.id)
            )
            user = result.scalar_one()
            tier = None
            if user.tier is not None:
                tier = {
                    "name": user.tier.name,
                    "color": user.tier.color,
                    "benefits": user.tier.benefits_json,
                }
            return {
                "id": str(user.id),
                "email": user.email,
                "first_name": user.first_name,
                "last_name": user.last_name,
                "username": user.username,
                "avatar_url": user.avatar_url,
                "tier": tier,
            }
        except Exception:
            logger.exception("Bootstrap: failed to fetch profile")
            return None

    async def fetch_wallet():
        try:
            return await get_user_wallet_balance(db, current_user.id)
        except Exception:
            logger.exception("Bootstrap: failed to fetch wallet")
            return None

    async def fetch_unread_count():
        try:
            return await get_unread_count(db, current_user.id)
        except Exception:
            logger.exception("Bootstrap: failed to fetch unread count")
            return 0

    async def fetch_active_votes():
        try:
            votes = await get_active_votes(db, current_user.id)
            return len(votes)
        except Exception:
            logger.exception("Bootstrap: failed to fetch active votes")
            return 0

    profile, wallet, unread_count, active_vote_count = await asyncio.gather(
        fetch_profile(),
        fetch_wallet(),
        fetch_unread_count(),
        fetch_active_votes(),
    )

    return {
        "user": profile,
        "wallet": wallet,
        "unread_notification_count": unread_count,
        "active_vote_count": active_vote_count,
    }
