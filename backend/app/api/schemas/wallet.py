import uuid
from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field


# --- Responses ---


class WalletResponse(BaseModel):
    address: str | None
    balance_available: Decimal
    balance_pending: Decimal
    comp_balance: Decimal

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


class CompPayoutChoiceResponse(BaseModel):
    comp_id: uuid.UUID
    method: str
    status: str
    amount: Decimal

    model_config = {"from_attributes": True}


class PendingComp(BaseModel):
    id: uuid.UUID
    amount: Decimal
    type: str
    awarded_at: datetime

    model_config = {"from_attributes": True}


class WalletDetailResponse(BaseModel):
    address: str | None
    comp_balance: Decimal
    pending_comps: list[PendingComp]
    balance_available: Decimal
    balance_pending: Decimal

    model_config = {"from_attributes": True}


# --- Requests ---


class WithdrawRequest(BaseModel):
    amount: Decimal = Field(gt=0, description="Amount to withdraw")
    to_address: str | None = Field(
        default=None,
        pattern=r"^0x[0-9a-fA-F]{40}$",
        description="Polygon wallet address (crypto only)",
    )
    method: str = Field(
        default="crypto",
        pattern=r"^(crypto|bank)$",
        description="Withdrawal method: crypto or bank",
    )


class CompPayoutChoiceRequest(BaseModel):
    comp_id: uuid.UUID = Field(description="Transaction ID of the pending_choice comp")
    method: str = Field(
        pattern=r"^(crypto|bank|later)$",
        description="Payout method: crypto, bank, or later",
    )
