"""Admin moderation endpoints for Social Hub."""

import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.deps import get_current_user, get_db
from app.api.schemas.social import MuteCreate, ReportOut, ReportUpdateRequest
from app.models.channel import Channel
from app.models.channel_tier_access import ChannelTierAccess
from app.models.chat_mute import ChatMute
from app.models.message import Message
from app.models.tier import Tier
from app.models.user import User


class BanUserRequest(BaseModel):
    reason: str = Field(default="Banned by admin", min_length=1, max_length=500)
    duration_days: int | None = Field(default=None, ge=1, le=3650)


class TierAccessInput(BaseModel):
    tier_id: uuid.UUID
    access_level: str = Field(default="full", pattern="^(full|view_only|hidden)$")


class ChannelCreateRequest(BaseModel):
    name: str = Field(min_length=1, max_length=100)
    description: str | None = None
    category: str | None = "General"
    tier_access: list[TierAccessInput] = []


class ChannelUpdateRequest(BaseModel):
    name: str | None = None
    description: str | None = None
    category: str | None = None
    tier_access: list[TierAccessInput] | None = None


from app.services.chat_service import (
    ban_user,
    delete_message,
    delete_user_messages,
    get_reports,
    mute_user,
    pin_message,
    unpin_message,
    update_report_status,
)

router = APIRouter(prefix="/admin/social", tags=["admin-social"])


def require_admin(user: User = Depends(get_current_user)) -> User:
    if not user.is_admin:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Admin access required")
    return user


# ── Stats ──────────────────────────────────────────────────────────────


@router.get("/stats")
async def admin_social_stats(
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    from datetime import datetime, timezone
    from app.models.chat_report import ChatReport

    now = datetime.now(timezone.utc)

    pending_result = await db.execute(
        select(func.count()).select_from(ChatReport).where(ChatReport.status == "pending")
    )
    pending_reports = pending_result.scalar() or 0

    muted_result = await db.execute(
        select(func.count(func.distinct(ChatMute.user_id))).where(ChatMute.muted_until > now)
    )
    active_mutes = muted_result.scalar() or 0

    # "Banned" = muted for > 365 days
    from datetime import timedelta
    ban_threshold = now + timedelta(days=365)
    banned_result = await db.execute(
        select(func.count(func.distinct(ChatMute.user_id))).where(ChatMute.muted_until > ban_threshold)
    )
    banned_users = banned_result.scalar() or 0

    return {
        "pending_reports": pending_reports,
        "active_mutes": active_mutes,
        "banned_users": banned_users,
    }


# ── Messages ───────────────────────────────────────────────────────────


@router.post("/messages/{message_id}/pin")
async def admin_pin(
    message_id: uuid.UUID,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    pinned = await pin_message(db, message_id)
    if not pinned:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Message not found")
    return {"message": "Message pinned"}


@router.post("/messages/{message_id}/unpin")
async def admin_unpin(
    message_id: uuid.UUID,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    unpinned = await unpin_message(db, message_id)
    if not unpinned:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Message not found")
    return {"message": "Message unpinned"}


@router.delete("/messages/{message_id}")
async def admin_delete_message(
    message_id: uuid.UUID,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    deleted = await delete_message(db, message_id, admin.id, is_admin=True)
    if not deleted:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Message not found")
    return {"message": "Message deleted"}


@router.delete("/users/{user_id}/messages")
async def admin_delete_user_messages(
    user_id: uuid.UUID,
    channel_id: uuid.UUID | None = Query(None),
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    count = await delete_user_messages(db, user_id, channel_id)
    return {"message": f"Deleted {count} message(s)", "count": count}


# ── User moderation ───────────────────────────────────────────────────


@router.post("/users/{user_id}/mute")
async def admin_mute_user(
    user_id: uuid.UUID,
    body: MuteCreate,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    mute = await mute_user(db, user_id, body.channel_id, body.duration_hours, body.reason)
    return {"message": "User muted", "muted_until": mute.muted_until.isoformat()}


@router.post("/users/{user_id}/ban")
async def admin_ban_user(
    user_id: uuid.UUID,
    body: BanUserRequest,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    mute = await ban_user(db, user_id, body.reason)
    return {"message": "User banned", "muted_until": mute.muted_until.isoformat()}


# ── Reports ────────────────────────────────────────────────────────────


@router.get("/reports", response_model=list[ReportOut])
async def list_reports(
    report_status: str | None = Query(None, alias="status"),
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    reports = await get_reports(db, status_filter=report_status)
    return reports


@router.put("/reports/{report_id}")
async def update_report(
    report_id: uuid.UUID,
    body: ReportUpdateRequest,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    updated = await update_report_status(db, report_id, body.status)
    if not updated:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Report not found")
    return {"message": f"Report status updated to {body.status}"}


# ── Channel CRUD ───────────────────────────────────────────────────────


@router.get("/channels")
async def admin_list_channels(
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Channel)
        .options(selectinload(Channel.tier_access).selectinload(ChannelTierAccess.tier))
        .order_by(Channel.category, Channel.sort_order)
    )
    channels = result.scalars().all()

    output = []
    for ch in channels:
        tier_access = [
            {
                "tier_id": str(ta.tier_id),
                "tier_name": ta.tier.name if ta.tier else "Unknown",
                "access_level": ta.access_level,
            }
            for ta in ch.tier_access
        ]
        output.append({
            "id": str(ch.id),
            "name": ch.name,
            "description": ch.description,
            "category": ch.category,
            "is_locked": ch.is_locked,
            "sort_order": ch.sort_order,
            "tier_access": tier_access,
        })

    return output


@router.post("/channels", status_code=status.HTTP_201_CREATED)
async def admin_create_channel(
    body: ChannelCreateRequest,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    # Get max sort_order for the category
    max_order = await db.execute(
        select(func.coalesce(func.max(Channel.sort_order), 0)).where(
            Channel.category == body.category
        )
    )
    next_order = (max_order.scalar() or 0) + 1

    channel = Channel(
        name=body.name,
        description=body.description,
        category=body.category,
        sort_order=next_order,
    )
    db.add(channel)
    await db.flush()

    # Set tier access levels
    for ta in body.tier_access:
        db.add(ChannelTierAccess(
            channel_id=channel.id,
            tier_id=ta.tier_id,
            access_level=ta.access_level,
        ))

    await db.commit()
    await db.refresh(channel)
    return {"id": str(channel.id), "name": channel.name, "message": "Channel created"}


@router.put("/channels/{channel_id}")
async def admin_update_channel(
    channel_id: uuid.UUID,
    body: ChannelUpdateRequest,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Channel).where(Channel.id == channel_id))
    channel = result.scalar_one_or_none()
    if not channel:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Channel not found")

    if body.name is not None:
        channel.name = body.name
    if body.description is not None:
        channel.description = body.description
    if body.category is not None:
        channel.category = body.category

    # Update tier access if provided
    if body.tier_access is not None:
        # Remove existing access rules
        from sqlalchemy import delete as sa_delete
        await db.execute(
            sa_delete(ChannelTierAccess).where(ChannelTierAccess.channel_id == channel_id)
        )
        # Add new rules
        for ta in body.tier_access:
            db.add(ChannelTierAccess(
                channel_id=channel_id,
                tier_id=ta.tier_id,
                access_level=ta.access_level,
            ))

    await db.commit()
    return {"message": "Channel updated"}


@router.delete("/channels/{channel_id}")
async def admin_delete_channel(
    channel_id: uuid.UUID,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Channel).where(Channel.id == channel_id))
    channel = result.scalar_one_or_none()
    if not channel:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Channel not found")

    await db.delete(channel)
    await db.commit()
    return {"message": "Channel deleted"}
