import uuid
from decimal import Decimal

from sqlalchemy import ForeignKey, Integer, Numeric, String, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, UpdateTimestampMixin, UUIDPrimaryKey


class Affiliate(UUIDPrimaryKey, UpdateTimestampMixin, Base):
    __tablename__ = "affiliates"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), unique=True, nullable=False, index=True
    )
    referral_code: Mapped[str] = mapped_column(
        String(20), unique=True, nullable=False, index=True
    )
    referred_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    reward_matching_pct: Mapped[Decimal] = mapped_column(
        Numeric(5, 2), nullable=False, server_default=text("21")
    )
    lifetime_earnings: Mapped[Decimal] = mapped_column(
        Numeric(18, 2), nullable=False, server_default=text("0")
    )
    tier_status: Mapped[str | None] = mapped_column(String(50), nullable=True)

    user = relationship("User", back_populates="affiliate")
