"""Admin moderation endpoints for Social Hub."""

import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.api.schemas.social import MuteCreate, ReportOut, ReportUpdateRequest
from app.models.user import User


class BanUserRequest(BaseModel):
    reason: str = Field(default="Banned by admin", min_length=1, max_length=500)
    duration_days: int | None = Field(default=None, ge=1, le=3650)


from app.services.chat_service import (
    ban_user,
    delete_message,
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
