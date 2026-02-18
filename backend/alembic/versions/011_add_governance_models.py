"""Add governance models — votes, vote_ballots, governance_proposals.

Revision ID: e6f7g8h9i0j1
Revises: d5e6f7g8h9i0
"""
from typing import Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import JSONB, UUID

revision: str = "e6f7g8h9i0j1"
down_revision: Union[str, None] = "d5e6f7g8h9i0"


def upgrade() -> None:
    # -- governance_proposals (must be created before votes due to FK) --
    op.create_table(
        "governance_proposals",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("user_id", UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False, index=True),
        sa.Column("title", sa.String(200), nullable=False),
        sa.Column("description", sa.String(2000), nullable=False),
        sa.Column("proposed_vote_type", sa.String(20), nullable=False),
        sa.Column("proposed_options_json", JSONB, nullable=True),
        sa.Column("status", sa.String(30), server_default=sa.text("'pending'"), nullable=False, index=True),
        sa.Column("admin_notes", sa.String(500), nullable=True),
        sa.Column("reviewed_by", UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=True),
        sa.Column("reviewed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
    )

    # -- votes --
    op.create_table(
        "votes",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("title", sa.String(200), nullable=False),
        sa.Column("description", sa.String(2000), nullable=False),
        sa.Column("vote_type", sa.String(20), nullable=False, index=True),
        sa.Column("options_json", JSONB, nullable=False),
        sa.Column("min_tier_required", sa.String(50), nullable=False),
        sa.Column("status", sa.String(20), server_default=sa.text("'draft'"), nullable=False, index=True),
        sa.Column("start_date", sa.DateTime(timezone=True), nullable=False),
        sa.Column("end_date", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_by", UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("proposal_id", UUID(as_uuid=True), sa.ForeignKey("governance_proposals.id"), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
    )

    # -- vote_ballots --
    op.create_table(
        "vote_ballots",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("vote_id", UUID(as_uuid=True), sa.ForeignKey("votes.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("user_id", UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False, index=True),
        sa.Column("option_id", sa.String(50), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.UniqueConstraint("vote_id", "user_id", name="uq_one_ballot_per_user"),
    )


def downgrade() -> None:
    op.drop_table("vote_ballots")
    op.drop_table("votes")
    op.drop_table("governance_proposals")
