from sqlalchemy import Integer, String
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, UUIDPrimaryKey


class Tier(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "tiers"

    name: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    min_scans: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    discount_pct: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    benefits_json: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    color: Mapped[str | None] = mapped_column(String(20), nullable=True)

    users = relationship("User", back_populates="tier")
    channels = relationship("Channel", back_populates="tier_required")
