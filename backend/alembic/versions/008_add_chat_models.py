"""Add chat models — message_reactions, chat_mutes, chat_reports + alter messages table.

Revision ID: a1b2c3d4e5f6
Revises: y5z6a7b8c9d0
"""
from typing import Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import UUID

revision: str = "c3d4e5f6g7h8"
down_revision: Union[str, None] = "y5z6a7b8c9d0"


def upgrade() -> None:
    # -- Alter messages table: add new columns --
    op.add_column("messages", sa.Column("original_language", sa.String(10), nullable=True))
    op.add_column("messages", sa.Column("reply_to_id", UUID(as_uuid=True), nullable=True))
    op.add_column("messages", sa.Column("is_system", sa.Boolean(), server_default=sa.text("false"), nullable=False))
    op.add_column("messages", sa.Column("is_pinned", sa.Boolean(), server_default=sa.text("false"), nullable=False))
    op.add_column("messages", sa.Column("is_deleted", sa.Boolean(), server_default=sa.text("false"), nullable=False))

    op.create_index("ix_messages_reply_to_id", "messages", ["reply_to_id"])
    op.create_foreign_key("fk_messages_reply_to", "messages", "messages", ["reply_to_id"], ["id"])

    # Also alter content column from Text to String(2000) — PostgreSQL varchar(2000)
    op.alter_column("messages", "content", type_=sa.String(2000), existing_type=sa.Text())

    # -- message_reactions --
    op.create_table(
        "message_reactions",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("message_id", UUID(as_uuid=True), sa.ForeignKey("messages.id", ondelete="CASCADE"), nullable=False, index=True),
        sa.Column("user_id", UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False, index=True),
        sa.Column("emoji", sa.String(50), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.UniqueConstraint("message_id", "user_id", "emoji", name="uq_reaction_per_user"),
    )

    # -- chat_mutes --
    op.create_table(
        "chat_mutes",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("user_id", UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False, index=True),
        sa.Column("channel_id", UUID(as_uuid=True), sa.ForeignKey("channels.id"), nullable=True, index=True),
        sa.Column("muted_until", sa.DateTime(timezone=True), nullable=False),
        sa.Column("reason", sa.String(500), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
    )

    # -- chat_reports --
    op.create_table(
        "chat_reports",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("reporter_id", UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False, index=True),
        sa.Column("message_id", UUID(as_uuid=True), sa.ForeignKey("messages.id"), nullable=True, index=True),
        sa.Column("reported_user_id", UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False, index=True),
        sa.Column("reason", sa.String(500), nullable=False),
        sa.Column("status", sa.String(20), server_default=sa.text("'pending'"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
    )


def downgrade() -> None:
    op.drop_table("chat_reports")
    op.drop_table("chat_mutes")
    op.drop_table("message_reactions")

    op.drop_constraint("fk_messages_reply_to", "messages", type_="foreignkey")
    op.drop_index("ix_messages_reply_to_id", "messages")
    op.drop_column("messages", "is_deleted")
    op.drop_column("messages", "is_pinned")
    op.drop_column("messages", "is_system")
    op.drop_column("messages", "reply_to_id")
    op.drop_column("messages", "original_language")
    op.alter_column("messages", "content", type_=sa.Text(), existing_type=sa.String(2000))
