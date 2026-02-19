import uuid
from datetime import date, datetime

from sqlalchemy import Boolean, Date, DateTime, ForeignKey, String, Text, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, UpdateTimestampMixin, UUIDPrimaryKey


class User(UUIDPrimaryKey, UpdateTimestampMixin, Base):
    __tablename__ = "users"

    username: Mapped[str] = mapped_column(String(25), nullable=False)
    username_lower: Mapped[str] = mapped_column(String(25), nullable=False, unique=True, index=True)
    username_changed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    password_hash: Mapped[str] = mapped_column(Text, nullable=False)
    first_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    last_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    birthdate: Mapped[date | None] = mapped_column(Date, nullable=True)
    phone: Mapped[str | None] = mapped_column(String(20), nullable=True)
    avatar_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    avatar_updated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    wallet_address: Mapped[str | None] = mapped_column(String(255), nullable=True)

    tier_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("tiers.id"), nullable=True, index=True
    )
    referral_code: Mapped[str | None] = mapped_column(
        String(20), unique=True, nullable=True, index=True
    )
    referred_by: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=True, index=True
    )

    is_active: Mapped[bool] = mapped_column(Boolean, server_default=text("true"), nullable=False)
    is_admin: Mapped[bool] = mapped_column(Boolean, server_default=text("false"), nullable=False)

    tier = relationship("Tier", back_populates="users")
    referrer = relationship("User", remote_side="User.id", foreign_keys=[referred_by])
    wallet = relationship("Wallet", back_populates="user", uselist=False)
    scans = relationship("Scan", back_populates="user")
    transactions = relationship("Transaction", back_populates="user")
    orders = relationship("Order", back_populates="user")
    messages = relationship("Message", back_populates="user")
    affiliate = relationship("Affiliate", back_populates="user", uselist=False)
    notifications = relationship("Notification", back_populates="user")
