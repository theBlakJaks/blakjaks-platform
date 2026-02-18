"""Pydantic v2 schemas for the Affiliate System."""

import uuid
from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field


class AffiliateOut(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    referral_code: str
    referral_link: str
    total_earnings: Decimal
    pending_earnings: Decimal = Decimal("0")
    downline_count: int
    total_chips: int = 0
    vaulted_chips: int = 0
    permanent_tier: str | None = None
    created_at: datetime

    model_config = {"from_attributes": True}


class DownlineMember(BaseModel):
    user_id: uuid.UUID
    username: str
    tier: str | None = None
    total_scans: int = 0
    earnings_generated: Decimal = Decimal("0")
    joined_at: datetime


class DownlineList(BaseModel):
    items: list[DownlineMember]
    total: int
    page: int
    per_page: int


class ChipSummary(BaseModel):
    active_chips: int
    vaulted_chips: int
    expired_chips: int
    total_earned: int


class VaultRequest(BaseModel):
    chip_ids: list[uuid.UUID] = Field(min_length=1)


class PayoutOut(BaseModel):
    id: uuid.UUID
    amount: Decimal
    payout_type: str
    period_start: datetime
    period_end: datetime
    status: str
    tx_hash: str | None = None
    created_at: datetime

    model_config = {"from_attributes": True}


class PayoutList(BaseModel):
    items: list[PayoutOut]
    total: int
    page: int
    per_page: int


class SunsetProgress(BaseModel):
    current_monthly_volume: int
    rolling_3mo_avg: int
    threshold: int
    percentage: float
    is_triggered: bool
    triggered_at: datetime | None = None


class ReferralCodeUpdate(BaseModel):
    code: str = Field(min_length=3, max_length=20, pattern="^[a-zA-Z0-9_-]+$")
