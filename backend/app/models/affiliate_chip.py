import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, UUIDPrimaryKey


class AffiliateChip(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "affiliate_chips"

    affiliate_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("affiliates.id"), nullable=False, index=True
    )
    source_user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True
    )
    source_scan_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("scans.id"), nullable=False, index=True
    )
    is_vaulted: Mapped[bool] = mapped_column(Boolean, server_default=text("false"), nullable=False)
    vault_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    vault_expiry: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    is_expired: Mapped[bool] = mapped_column(Boolean, server_default=text("false"), nullable=False)

    affiliate = relationship("Affiliate")
    source_user = relationship("User")
    source_scan = relationship("Scan")
