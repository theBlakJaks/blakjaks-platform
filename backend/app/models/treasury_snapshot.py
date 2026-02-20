from decimal import Decimal

from sqlalchemy import DateTime, Numeric, String
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, UUIDPrimaryKey


class TreasurySnapshot(UUIDPrimaryKey, Base):
    __tablename__ = "treasury_snapshots"

    timestamp: Mapped[None] = mapped_column(DateTime(timezone=True), nullable=False, index=True)
    pool_type: Mapped[str] = mapped_column(String(30), nullable=False, index=True)  # consumer, affiliate, wholesale
    onchain_balance: Mapped[Decimal] = mapped_column(Numeric(30, 6), nullable=False)
    bank_balance: Mapped[Decimal] = mapped_column(Numeric(18, 2), nullable=False, default=Decimal("0"))
    metadata_: Mapped[dict | None] = mapped_column("metadata", JSONB, nullable=True)
