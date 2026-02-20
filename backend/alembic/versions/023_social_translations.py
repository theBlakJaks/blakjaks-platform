"""Create social_message_translations table.

Revision ID: p7q8r9s0t1u2
Revises: o6p7q8r9s0t1
Create Date: 2026-02-19
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import UUID

revision: str = "p7q8r9s0t1u2"
down_revision: Union[str, None] = "o6p7q8r9s0t1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "social_message_translations",
        sa.Column("id", UUID(as_uuid=True), primary_key=True,
                  server_default=sa.text("gen_random_uuid()")),
        sa.Column("message_id", UUID(as_uuid=True),
                  sa.ForeignKey("messages.id", ondelete="CASCADE"),
                  nullable=False, index=True),
        sa.Column("language", sa.String(5), nullable=False),
        # ISO language code: en, es, fr, etc.
        sa.Column("translated_text", sa.Text, nullable=False),
        sa.Column("translated_at", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.text("now()")),
        sa.UniqueConstraint("message_id", "language",
                            name="uq_social_translations_msg_lang"),
    )


def downgrade() -> None:
    op.drop_table("social_message_translations")
