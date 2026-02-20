from datetime import datetime
from decimal import Decimal

from sqlalchemy import DateTime, Numeric, String, text
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base


class TellerAccount(Base):
    __tablename__ = "teller_accounts"

    id: Mapped[str] = mapped_column(String(36), primary_key=True)
    account_name: Mapped[str] = mapped_column(String(100), nullable=False, unique=True)
    account_type: Mapped[str] = mapped_column(String(50), nullable=False)
    institution_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    teller_account_id: Mapped[str | None] = mapped_column(String(100), nullable=True)
    last_four: Mapped[str | None] = mapped_column(String(4), nullable=True)
    balance: Mapped[Decimal] = mapped_column(
        Numeric(20, 2), nullable=False, default=Decimal("0")
    )
    currency: Mapped[str] = mapped_column(String(10), nullable=False, default="USD")
    status: Mapped[str] = mapped_column(String(50), nullable=False, default="pending")
    last_synced_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("now()")
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("now()")
    )
