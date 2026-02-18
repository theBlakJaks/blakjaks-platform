import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, Integer, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDPrimaryKey


class SunsetStatus(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "sunset_status"

    monthly_volume: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    rolling_3mo_avg: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    threshold: Mapped[int] = mapped_column(Integer, nullable=False, server_default=text("10000000"))
    is_triggered: Mapped[bool] = mapped_column(Boolean, server_default=text("false"), nullable=False)
    triggered_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
