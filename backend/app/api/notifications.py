"""Notification endpoints — device token management and unread count."""

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_user, get_db
from app.models.user import User
from app.services.notification_service import get_unread_count
from app.services.push_service import register_device_token, unregister_device_token

router = APIRouter(prefix="/notifications", tags=["notifications"])


class DeviceTokenRequest(BaseModel):
    token: str = Field(min_length=1, max_length=500)
    platform: str = Field(pattern="^(ios|android)$")


class DeviceTokenDeleteRequest(BaseModel):
    token: str = Field(min_length=1, max_length=500)


class UnreadCountResponse(BaseModel):
    unread_count: int


@router.post("/device-token", status_code=status.HTTP_201_CREATED)
async def register_token(
    body: DeviceTokenRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    dt = await register_device_token(db, user.id, body.token, body.platform)
    return {"message": "Device token registered", "id": str(dt.id)}


@router.delete("/device-token")
async def unregister_token(
    body: DeviceTokenDeleteRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    removed = await unregister_device_token(db, user.id, body.token)
    if not removed:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Device token not found")
    return {"message": "Device token removed"}


@router.get("/unread-count", response_model=UnreadCountResponse)
async def unread_count(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    count = await get_unread_count(db, user.id)
    return UnreadCountResponse(unread_count=count)
