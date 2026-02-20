from decimal import Decimal

from sqlalchemy import BigInteger, DateTime, Numeric, String, text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base


class TreasurySnapshot(Base):
    __tablename__ = "treasury_snapshots"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    timestamp: Mapped[str] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("now()")
    )
    pool_type: Mapped[str] = mapped_column(String(50), nullable=False)
    onchain_balance: Mapped[Decimal] = mapped_column(
        Numeric(20, 6), nullable=False, default=Decimal("0")
    )
    bank_balance: Mapped[Decimal] = mapped_column(
        Numeric(20, 6), nullable=False, default=Decimal("0")
    )
    metadata: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
