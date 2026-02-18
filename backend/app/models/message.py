import uuid

from sqlalchemy import Boolean, ForeignKey, String, Text, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, UUIDPrimaryKey


class Message(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "messages"

    channel_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("channels.id"), nullable=False, index=True
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True
    )
    content: Mapped[str] = mapped_column(String(2000), nullable=False)
    original_language: Mapped[str | None] = mapped_column(String(10), nullable=True)
    reply_to_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("messages.id"), nullable=True, index=True
    )
    is_system: Mapped[bool] = mapped_column(Boolean, server_default=text("false"), nullable=False)
    is_pinned: Mapped[bool] = mapped_column(Boolean, server_default=text("false"), nullable=False)
    is_deleted: Mapped[bool] = mapped_column(Boolean, server_default=text("false"), nullable=False)

    channel = relationship("Channel", back_populates="messages")
    user = relationship("User", back_populates="messages")
    reply_to = relationship("Message", remote_side="Message.id", foreign_keys=[reply_to_id])
    reactions = relationship("MessageReaction", back_populates="message", cascade="all, delete-orphan")
