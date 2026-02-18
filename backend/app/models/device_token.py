import uuid

from sqlalchemy import ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, UUIDPrimaryKey


class DeviceToken(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "device_tokens"

    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True
    )
    token: Mapped[str] = mapped_column(String(500), unique=True, nullable=False)
    platform: Mapped[str] = mapped_column(String(10), nullable=False)  # "ios" or "android"

    user = relationship("User")
