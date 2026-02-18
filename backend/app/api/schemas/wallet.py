import uuid
from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field


# --- Responses ---


class WalletResponse(BaseModel):
    address: str | None
    balance_available: Decimal
    balance_pending: Decimal

    model_config = {"from_attributes": True}


class TransactionResponse(BaseModel):
    id: uuid.UUID
    type: str
    amount: Decimal
    status: str
    tx_hash: str | None
    from_address: str | None
    to_address: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class TransactionListResponse(BaseModel):
    transactions: list[TransactionResponse]
    count: int


# --- Requests ---


class WithdrawRequest(BaseModel):
    amount: Decimal = Field(gt=0, description="USDT amount to withdraw")
    to_address: str = Field(
        pattern=r"^0x[0-9a-fA-F]{40}$",
        description="Polygon wallet address",
    )


class OobitActivateRequest(BaseModel):
    """Placeholder for Oobit card activation."""
    card_last_four: str = Field(min_length=4, max_length=4, pattern=r"^\d{4}$")


class OobitActivateResponse(BaseModel):
    status: str
    message: str
