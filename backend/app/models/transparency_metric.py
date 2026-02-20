from decimal import Decimal

from sqlalchemy import BigInteger, DateTime, Numeric, String, text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base


class TransparencyMetric(Base):
    __tablename__ = "transparency_metrics"

    id: Mapped[int] = mapped_column(BigInteger, primary_key=True, autoincrement=True)
    timestamp: Mapped[str] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=text("now()")
    )
    metric_type: Mapped[str] = mapped_column(String(100), nullable=False)
    metric_value: Mapped[Decimal] = mapped_column(Numeric(20, 6), nullable=False)
    metadata: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
