import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, String, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, UUIDPrimaryKey


class QRCode(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "qr_codes"

    product_code: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    unique_id: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)

    product_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("products.id"), nullable=True, index=True
    )
    is_used: Mapped[bool] = mapped_column(Boolean, server_default=text("false"), nullable=False)
    scanned_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=True, index=True
    )
    scanned_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    product = relationship("Product", back_populates="qr_codes")
    scanner = relationship("User", foreign_keys=[scanned_by])
