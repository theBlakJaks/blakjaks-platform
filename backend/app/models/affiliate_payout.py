import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import DateTime, ForeignKey, Numeric, String, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, UUIDPrimaryKey


class AffiliatePayout(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "affiliate_payouts"

    affiliate_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("affiliates.id"), nullable=False, index=True
    )
    amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    payout_type: Mapped[str] = mapped_column(String(30), nullable=False)  # pool_share or reward_match
    period_start: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    period_end: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    status: Mapped[str] = mapped_column(
        String(20), server_default=text("'pending'"), nullable=False
    )  # pending, approved, paid, failed
    tx_hash: Mapped[str | None] = mapped_column(String(100), nullable=True)

    affiliate = relationship("Affiliate")
