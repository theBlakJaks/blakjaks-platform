import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, UpdateTimestampMixin, UUIDPrimaryKey


class Vote(UUIDPrimaryKey, UpdateTimestampMixin, Base):
    __tablename__ = "votes"

    title: Mapped[str] = mapped_column(String(200), nullable=False)
    description: Mapped[str] = mapped_column(String(2000), nullable=False)
    vote_type: Mapped[str] = mapped_column(String(20), nullable=False, index=True)
    options_json: Mapped[dict | list] = mapped_column(JSONB, nullable=False)
    min_tier_required: Mapped[str] = mapped_column(String(50), nullable=False)
    status: Mapped[str] = mapped_column(
        String(20), server_default=text("'draft'"), nullable=False, index=True
    )
    start_date: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    end_date: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    created_by: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False
    )
    proposal_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("governance_proposals.id"), nullable=True
    )

    creator = relationship("User", foreign_keys=[created_by])
    proposal = relationship("GovernanceProposal", foreign_keys=[proposal_id])
    ballots = relationship("VoteBallot", back_populates="vote", cascade="all, delete-orphan")
