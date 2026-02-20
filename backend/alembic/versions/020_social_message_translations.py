"""Create social_message_translations table.

Revision ID: 020
Revises: 019
Create Date: 2026-02-20
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "020"
down_revision = "019"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "social_message_translations",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("message_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("messages.id"), nullable=False, index=True),
        sa.Column("language", sa.String(5), nullable=False),
        sa.Column("translated_text", sa.Text, nullable=False),
        sa.Column("translated_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("message_id", "language", name="uq_message_language"),
    )


def downgrade() -> None:
    op.drop_table("social_message_translations")
