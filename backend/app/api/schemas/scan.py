import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class ScanSubmit(BaseModel):
    qr_code: str = Field(min_length=1, max_length=500)


class ScanResponse(BaseModel):
    success: bool
    product_name: str
    chip_earned: bool
    quarterly_scan_count: int
    tier_name: str | None


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
