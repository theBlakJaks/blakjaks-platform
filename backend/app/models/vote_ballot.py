import uuid

from sqlalchemy import ForeignKey, String, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin, UUIDPrimaryKey


class VoteBallot(UUIDPrimaryKey, TimestampMixin, Base):
    __tablename__ = "vote_ballots"
    __table_args__ = (
        UniqueConstraint("vote_id", "user_id", name="uq_one_ballot_per_user"),
    )

    vote_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("votes.id", ondelete="CASCADE"), nullable=False, index=True
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id"), nullable=False, index=True
    )
    option_id: Mapped[str] = mapped_column(String(50), nullable=False)

    vote = relationship("Vote", back_populates="ballots")
    user = relationship("User")
