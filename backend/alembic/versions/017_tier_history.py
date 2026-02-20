"""Create tier_history table.

Revision ID: k2l3m4n5o6p7
Revises: j1k2l3m4n5o6
Create Date: 2026-02-19
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import UUID

revision: str = "k2l3m4n5o6p7"
down_revision: Union[str, None] = "j1k2l3m4n5o6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "tier_history",
        sa.Column("id", UUID(as_uuid=True), primary_key=True,
                  server_default=sa.text("gen_random_uuid()")),
        sa.Column("user_id", UUID(as_uuid=True),
                  sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("quarter", sa.String(7), nullable=False),
        # Format: 2026-Q1
        sa.Column("tier_name", sa.String(50), nullable=False),
        sa.Column("scan_count", sa.Integer, nullable=False, server_default="0"),
        sa.Column("achieved_at", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.text("now()")),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("is_permanent", sa.Boolean, nullable=False, server_default="false"),
    )
    op.create_index("ix_tier_history_user_quarter", "tier_history",
                    ["user_id", "quarter"], unique=True)


def downgrade() -> None:
    op.drop_table("tier_history")
