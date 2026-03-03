"""Add email_verified column to users

Revision ID: 026
Revises: 025
Create Date: 2026-03-03
"""

from alembic import op
import sqlalchemy as sa

revision = "026"
down_revision = "025"
branch_labels = None
depends_on = None


def upgrade():
    conn = op.get_bind()

    result = conn.execute(sa.text(
        "SELECT 1 FROM information_schema.columns "
        "WHERE table_name='users' AND column_name='email_verified'"
    ))
    if result.fetchone() is None:
        op.add_column(
            "users",
            sa.Column("email_verified", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        )

    # Backfill: existing users are already verified (they signed up before this feature)
    conn.execute(sa.text("UPDATE users SET email_verified = true WHERE email_verified = false"))


def downgrade():
    op.drop_column("users", "email_verified")
