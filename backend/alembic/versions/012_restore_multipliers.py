"""Restore multiplier columns removed in migration 002.

Revision ID: 012
Revises: e6f7g8h9i0j1
Create Date: 2026-02-20
"""

from alembic import op
import sqlalchemy as sa

revision = "012"
down_revision = "e6f7g8h9i0j1"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Add multiplier to tiers
    op.add_column("tiers", sa.Column("multiplier", sa.Numeric(4, 2), nullable=False, server_default="1.0"))
    # Add tier_multiplier to scans
    op.add_column("scans", sa.Column("tier_multiplier", sa.Numeric(4, 2), nullable=True))

    # Seed correct multiplier values per tier name
    op.execute("""
        UPDATE tiers SET multiplier = CASE
            WHEN name ILIKE '%standard%' THEN 1.0
            WHEN name ILIKE '%vip%'      THEN 1.5
            WHEN name ILIKE '%high%'     THEN 2.0
            WHEN name ILIKE '%whale%'    THEN 3.0
            ELSE 1.0
        END
    """)


def downgrade() -> None:
    op.drop_column("scans", "tier_multiplier")
    op.drop_column("tiers", "multiplier")
