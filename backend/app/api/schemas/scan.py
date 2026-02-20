import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class ScanSubmit(BaseModel):
    qr_code: str = Field(min_length=1, max_length=500)


class TierProgress(BaseModel):
    quarter: str
    current_count: int
    next_tier: str | None
    scans_required: int | None


class CompEarned(BaseModel):
    amount: float
    type: str
    lifetime_comps: float
    wallet_balance: float


class ScanResponse(BaseModel):
    success: bool
    product_name: str
    usdt_earned: float
    tier_multiplier: float
    tier_progress: TierProgress
    comp_earned: CompEarned | None
    milestone_hit: bool
    wallet_balance: float
    global_scan_count: int


class ScanHistoryItem(BaseModel):
    id: uuid.UUID
    product_name: str | None
    scanned_at: datetime

    model_config = {"from_attributes": True}


class ScanHistoryPage(BaseModel):
    items: list[ScanHistoryItem]
    total: int
    page: int
    per_page: int


class QRCodeResponse(BaseModel):
    id: uuid.UUID
    product_code: str
    unique_id: str
    full_code: str
    is_used: bool
    scanned_by: uuid.UUID | None
    scanned_at: datetime | None
    created_at: datetime

    model_config = {"from_attributes": True}


class QRCodeGenerateRequest(BaseModel):
    product_id: uuid.UUID
    quantity: int = Field(ge=1, le=10000)


class QRCodeGenerateResponse(BaseModel):
    generated: int
    codes: list[str]


class QRCodeListPage(BaseModel):
    items: list[QRCodeResponse]
    total: int
    page: int
    per_page: int
