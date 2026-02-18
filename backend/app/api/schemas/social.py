"""Pydantic v2 schemas for the Social Hub & Real-Time Chat system."""

import uuid
from datetime import datetime

from pydantic import BaseModel, Field


# ── Channel ──────────────────────────────────────────────────────────


class ChannelOut(BaseModel):
    id: uuid.UUID
    name: str
    description: str | None = None
    category: str | None = None
    tier_required: str | None = None
    unread_count: int = 0
    member_count: int = 0

    model_config = {"from_attributes": True}


# ── Message ──────────────────────────────────────────────────────────


class ReactionOut(BaseModel):
    emoji: str
    count: int
    users: list[str]  # list of user first_names


class MessageOut(BaseModel):
    id: uuid.UUID
    channel_id: uuid.UUID
    user_id: uuid.UUID
    username: str
    user_tier: str | None = None
    content: str
    original_language: str | None = None
    reply_to_id: uuid.UUID | None = None
    reply_preview: str | None = None
    reactions: list[ReactionOut] = []
    is_pinned: bool = False
    is_system: bool = False
    created_at: datetime

    model_config = {"from_attributes": True}


class MessageCreate(BaseModel):
    content: str = Field(min_length=1, max_length=2000)
    reply_to_id: uuid.UUID | None = None


class ReactionCreate(BaseModel):
    emoji: str = Field(min_length=1, max_length=50)


class ReportCreate(BaseModel):
    reason: str = Field(min_length=1, max_length=500)


class MuteCreate(BaseModel):
    channel_id: uuid.UUID | None = None
    duration_hours: int = Field(ge=1, le=8760)  # max 1 year
    reason: str = Field(min_length=1, max_length=500)


class TranslateRequest(BaseModel):
    message_id: uuid.UUID
    target_lang: str = Field(min_length=2, max_length=10)


class TranslateResponse(BaseModel):
    original_text: str
    translated_text: str
    source_lang: str
    target_lang: str


# ── Admin ────────────────────────────────────────────────────────────


class ReportOut(BaseModel):
    id: uuid.UUID
    reporter_id: uuid.UUID
    message_id: uuid.UUID | None = None
    reported_user_id: uuid.UUID
    reason: str
    status: str
    created_at: datetime

    model_config = {"from_attributes": True}


class ReportUpdateRequest(BaseModel):
    status: str = Field(pattern="^(pending|resolved|dismissed)$")
