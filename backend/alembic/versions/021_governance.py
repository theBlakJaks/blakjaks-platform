"""Create governance_votes and governance_ballots tables.

These are distinct from the existing votes/vote_ballots/governance_proposals tables
which serve a different schema. These implement Platform v2 § "Database Schema — Governance".

Revision ID: n5o6p7q8r9s0
Revises: m4n5o6p7q8r9
Create Date: 2026-02-19
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import JSONB, UUID

revision: str = "n5o6p7q8r9s0"
down_revision: Union[str, None] = "m4n5o6p7q8r9"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "governance_votes",
        sa.Column("id", UUID(as_uuid=True), primary_key=True,
                  server_default=sa.text("gen_random_uuid()")),
        sa.Column("title", sa.String(255), nullable=False),
        sa.Column("description", sa.Text, nullable=True),
        sa.Column("vote_type", sa.String(50), nullable=False),
        # vote_type: flavor | loyalty | corporate
        sa.Column("tier_eligibility", sa.String(50), nullable=False),
        # tier_eligibility: vip | high_roller | whale
        sa.Column("options", JSONB, nullable=False, server_default="[]"),
        # Array of option strings
        sa.Column("status", sa.String(50), nullable=False, server_default="draft"),
        # status: draft | active | closed
        sa.Column("results_published", sa.Boolean, nullable=False, server_default="false"),
        sa.Column("created_by_admin", UUID(as_uuid=True),
                  sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("voting_ends_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.text("now()")),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.text("now()")),
    )
    op.create_index("ix_governance_votes_status", "governance_votes", ["status"])
    op.create_index("ix_governance_votes_type", "governance_votes", ["vote_type"])

    op.create_table(
        "governance_ballots",
        sa.Column("id", UUID(as_uuid=True), primary_key=True,
                  server_default=sa.text("gen_random_uuid()")),
        sa.Column("vote_id", UUID(as_uuid=True),
                  sa.ForeignKey("governance_votes.id", ondelete="CASCADE"),
                  nullable=False, index=True),
        sa.Column("user_id", UUID(as_uuid=True),
                  sa.ForeignKey("users.id", ondelete="CASCADE"),
                  nullable=False, index=True),
        sa.Column("selected_option", sa.String(255), nullable=False),
        sa.Column("cast_at", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.text("now()")),
        sa.UniqueConstraint("vote_id", "user_id", name="uq_governance_ballots_vote_user"),
    )


def downgrade() -> None:
    op.drop_table("governance_ballots")
    op.drop_table("governance_votes")
