import uuid
from datetime import date, datetime
from typing import Any

from pydantic import BaseModel, EmailStr, Field


class UserProfileResponse(BaseModel):
    id: uuid.UUID
    email: str
    username: str
    first_name: str | None
    last_name: str | None
    birthdate: date | None
    phone: str | None
    avatar_url: str | None
    avatar_updated_at: datetime | None = None
    wallet_address: str | None
    referral_code: str | None
    is_active: bool
    is_admin: bool
    tier: "TierResponse | None" = None
    created_at: datetime

    model_config = {"from_attributes": True}


class TierResponse(BaseModel):
    name: str
    color: str | None
    benefits: dict | None

    model_config = {"from_attributes": True}


class AvatarUploadResponse(BaseModel):
    avatar_url: str
    sizes: dict[str, str]


class UserUpdateRequest(BaseModel):
    first_name: str | None = Field(None, min_length=1, max_length=100)
    last_name: str | None = Field(None, min_length=1, max_length=100)
    phone: str | None = Field(None, max_length=20)
    avatar_url: str | None = None


class UserStatsResponse(BaseModel):
    tier_name: str | None
    tier_color: str | None
    benefits: dict | None
    quarterly_scans: int
    scans_to_next_tier: int | None
    current_streak: int


class NotificationResponse(BaseModel):
    id: uuid.UUID
    type: str
    title: str
    body: str | None
    is_read: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class PaginatedNotifications(BaseModel):
    items: list[NotificationResponse]
    total: int
    page: int
    page_size: int


class UsernameCheckResponse(BaseModel):
    available: bool
    message: str
    suggestions: list[str] | None = None


class UsernameChangeRequest(BaseModel):
    username: str = Field(min_length=4, max_length=25, pattern=r'^[a-zA-Z_][a-zA-Z0-9_]{3,24}$')
