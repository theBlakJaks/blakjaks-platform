import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, UUIDPrimaryKey


class TierHistory(UUIDPrimaryKey, Base):
    __tablename__ = "tier_history"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True
    )
    quarter: Mapped[str] = mapped_column(String(7), nullable=False)  # e.g. "2026-Q1"
    tier_name: Mapped[str] = mapped_column(String(50), nullable=False)
    scan_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    achieved_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    is_permanent: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
