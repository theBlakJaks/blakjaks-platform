"""Add saved_emotes table for persistent user emote collections

Revision ID: 029
Revises: 028
Create Date: 2026-03-04
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "029"
down_revision = "028"
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "saved_emotes",
        sa.Column("id", postgresql.UUID(as_uuid=True), server_default=sa.text("gen_random_uuid()"), primary_key=True),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("emote_id", sa.String(64), nullable=False),
        sa.Column("emote_name", sa.String(128), nullable=False),
        sa.Column("animated", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("zero_width", sa.Boolean(), nullable=False, server_default=sa.text("false")),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default=sa.text("0")),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.UniqueConstraint("user_id", "emote_id", name="uq_saved_emote_per_user"),
    )


def downgrade():
    op.drop_table("saved_emotes")
