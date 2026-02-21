"""Add username, avatar_updated_at columns to users

Revision ID: 025
Revises: 024
Create Date: 2026-02-21
"""

from alembic import op
import sqlalchemy as sa

revision = "025"
down_revision = "024"
branch_labels = None
depends_on = None


def upgrade():
    conn = op.get_bind()

    def col_exists(table, col):
        result = conn.execute(sa.text(
            "SELECT 1 FROM information_schema.columns "
            "WHERE table_name=:t AND column_name=:c"
        ), {"t": table, "c": col})
        return result.fetchone() is not None

    if not col_exists("users", "username"):
        op.add_column("users", sa.Column("username", sa.String(25), nullable=True))
    if not col_exists("users", "username_lower"):
        op.add_column("users", sa.Column("username_lower", sa.String(25), nullable=True))
    if not col_exists("users", "username_changed_at"):
        op.add_column("users", sa.Column("username_changed_at", sa.DateTime(timezone=True), nullable=True))
    if not col_exists("users", "avatar_updated_at"):
        op.add_column("users", sa.Column("avatar_updated_at", sa.DateTime(timezone=True), nullable=True))

    # Backfill username from email prefix for existing rows
    conn.execute(sa.text(
        "UPDATE users SET username = split_part(email, '@', 1), "
        "username_lower = lower(split_part(email, '@', 1)) "
        "WHERE username IS NULL"
    ))

    # Now make not-nullable and add unique index (after backfill)
    op.alter_column("users", "username", nullable=False)
    op.alter_column("users", "username_lower", nullable=False)

    # Add unique index if it doesn't exist
    conn.execute(sa.text(
        "CREATE UNIQUE INDEX IF NOT EXISTS ix_users_username_lower "
        "ON users (username_lower)"
    ))


def downgrade():
    op.drop_column("users", "username")
    op.drop_column("users", "username_lower")
    op.drop_column("users", "username_changed_at")
    op.drop_column("users", "avatar_updated_at")
