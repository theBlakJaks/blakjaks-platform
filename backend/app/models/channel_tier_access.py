import uuid

from sqlalchemy import ForeignKey, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, UUIDPrimaryKey


class ChannelTierAccess(UUIDPrimaryKey, TimestampMixin, Base):
    """Per-tier access level for a channel.

    access_level values:
      - 'full'      — can view and post
      - 'view_only' — can view but not post
      - 'hidden'    — channel is invisible to this tier

    If no row exists for a (channel, tier) pair, the default is 'full'.
    """

    __tablename__ = "channel_tier_access"
    __table_args__ = (
        UniqueConstraint("channel_id", "tier_id", name="uq_channel_tier"),
    )

    channel_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("channels.id", ondelete="CASCADE"), nullable=False, index=True
    )
    tier_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("tiers.id", ondelete="CASCADE"), nullable=False, index=True
    )
    access_level: Mapped[str] = mapped_column(
        String(20), nullable=False, default="full"
    )

    channel = relationship("Channel", back_populates="tier_access")
    tier = relationship("Tier")
