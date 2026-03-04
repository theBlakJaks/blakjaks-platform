import uuid

from sqlalchemy import Boolean, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, UUIDPrimaryKey


class SavedEmote(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "saved_emotes"
    __table_args__ = (
        UniqueConstraint("user_id", "emote_id", name="uq_saved_emote_per_user"),
    )

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    emote_id: Mapped[str] = mapped_column(String(64), nullable=False)
    emote_name: Mapped[str] = mapped_column(String(128), nullable=False)
    animated: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    zero_width: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    sort_order: Mapped[int] = mapped_column(Integer, nullable=False, default=0)

    user = relationship("User")
