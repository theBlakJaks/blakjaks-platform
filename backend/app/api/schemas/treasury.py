from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel


class PoolBalance(BaseModel):
    name: str
    address: str | None
    balance: Decimal
    allocation_pct: Decimal


class TreasuryPools(BaseModel):
    consumer: PoolBalance
    affiliate: PoolBalance
    wholesale: PoolBalance
    last_updated: datetime


class CompRecipient(BaseModel):
    username_masked: str
    amount: Decimal
    comp_type: str
    awarded_at: datetime


class CompRecipientList(BaseModel):
    recipients: list[CompRecipient]
    count: int


class TreasuryStats(BaseModel):
    total_distributed: Decimal
    total_members_comped: int
    consumer_pool_pct: Decimal
    affiliate_pool_pct: Decimal
    wholesale_pool_pct: Decimal
