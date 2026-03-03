"""Add channel_tier_access table for per-tier channel access levels

Revision ID: 026
Revises: 025
Create Date: 2026-03-03
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID

revision = "026"
down_revision = "025"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "channel_tier_access",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("channel_id", UUID(as_uuid=True), sa.ForeignKey("channels.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("tier_id", UUID(as_uuid=True), sa.ForeignKey("tiers.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("access_level", sa.String(20), nullable=False, server_default="full"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.UniqueConstraint("channel_id", "tier_id", name="uq_channel_tier"),
    )


def downgrade():
    op.drop_table("channel_tier_access")
