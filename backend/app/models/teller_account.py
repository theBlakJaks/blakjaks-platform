import uuid
from decimal import Decimal

from sqlalchemy import DateTime, Numeric, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDPrimaryKey


class TellerAccount(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "teller_accounts"

    name: Mapped[str] = mapped_column(String(100), nullable=False)
    teller_account_id: Mapped[str | None] = mapped_column(String(255), nullable=True, unique=True)
    account_type: Mapped[str] = mapped_column(String(50), nullable=False)  # operating, reserve, comp_pool
    institution_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    last_four: Mapped[str | None] = mapped_column(String(4), nullable=True)
    balance: Mapped[Decimal] = mapped_column(Numeric(18, 2), nullable=False, default=Decimal("0"))
    currency: Mapped[str] = mapped_column(String(3), nullable=False, default="USD")
    last_synced_at: Mapped[None] = mapped_column(DateTime(timezone=True), nullable=True)
    sync_status: Mapped[str] = mapped_column(String(20), nullable=False, default="pending")
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
