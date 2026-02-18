from decimal import Decimal

from sqlalchemy import Boolean, Integer, Numeric, String, Text, text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, UpdateTimestampMixin, UUIDPrimaryKey


class Product(UUIDPrimaryKey, UpdateTimestampMixin, Base):
    __tablename__ = "products"

    name: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    price: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    flavor: Mapped[str | None] = mapped_column(String(100), nullable=True)
    nicotine_strength: Mapped[str | None] = mapped_column(String(20), nullable=True)
    image_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    stock: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    is_active: Mapped[bool] = mapped_column(Boolean, server_default=text("true"), nullable=False)

    qr_codes = relationship("QRCode", back_populates="product")
