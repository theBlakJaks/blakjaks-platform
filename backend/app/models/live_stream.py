import uuid
from datetime import datetime

from sqlalchemy import DateTime, Integer, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base, TimestampMixin, UUIDPrimaryKey


class LiveStream(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "live_streams"

    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="scheduled", index=True)
    # scheduled, live, ended, cancelled
    scheduled_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    ended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    viewer_count: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    peak_viewers: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    hls_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    vod_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    tier_restriction: Mapped[str | None] = mapped_column(String(20), nullable=True)
    streamyard_broadcast_id: Mapped[str | None] = mapped_column(String(255), nullable=True)
    created_by: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), nullable=True)
