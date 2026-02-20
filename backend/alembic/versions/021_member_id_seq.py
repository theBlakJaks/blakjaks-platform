"""Add member_id_seq sequence and member_id column to users.

Revision ID: 021
Revises: 020
Create Date: 2026-02-20
"""

from alembic import op
import sqlalchemy as sa

revision = "021"
down_revision = "020"
branch_labels = None
depends_on = None

TIER_SUFFIX = {
    "standard": "ST",
    "vip": "VIP",
    "high roller": "HR",
    "whale": "WH",
}


def upgrade() -> None:
    # Create PostgreSQL sequence for member IDs
    op.execute("CREATE SEQUENCE IF NOT EXISTS member_id_seq START 1 INCREMENT 1")

    # Add member_id column
    op.add_column("users", sa.Column("member_id", sa.String(20), nullable=True, unique=True))

    # Backfill existing users with sequential IDs using standard suffix
    op.execute("""
        UPDATE users
        SET member_id = 'BJ-' || LPAD(nextval('member_id_seq')::text, 4, '0') || '-ST'
        WHERE member_id IS NULL
    """)


def downgrade() -> None:
    op.drop_column("users", "member_id")
    op.execute("DROP SEQUENCE IF EXISTS member_id_seq")
