"""Restore multiplier columns removed by migration 002.

Migration 002 incorrectly dropped `multiplier` from `tiers` and
`tier_multiplier` from `scans`. Without these the earn system is broken
(usdt_earned is always 0). This migration re-adds both columns and seeds
correct multiplier values per Platform v2 § "Tier System".

Revision ID: f7g8h9i0j1k2
Revises: e6f7g8h9i0j1
Create Date: 2026-02-19
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "f7g8h9i0j1k2"
down_revision: Union[str, None] = "e6f7g8h9i0j1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Re-add multiplier to tiers (default 1.0 — Standard tier value)
    op.add_column(
        "tiers",
        sa.Column(
            "multiplier",
            sa.Numeric(5, 2),
            nullable=False,
            server_default="1.0",
        ),
    )

    # Re-add tier_multiplier to scans (snapshot of tier multiplier at scan time)
    op.add_column(
        "scans",
        sa.Column(
            "tier_multiplier",
            sa.Numeric(5, 2),
            nullable=False,
            server_default="1.0",
        ),
    )

    # Seed correct multiplier values per Platform v2 § "Tier System"
    # Standard: 1.0x | VIP: 1.5x | High Roller: 2.0x | Whale: 3.0x
    op.execute("""
        UPDATE tiers SET multiplier = CASE name
            WHEN 'Standard'    THEN 1.0
            WHEN 'VIP'         THEN 1.5
            WHEN 'High Roller' THEN 2.0
            WHEN 'Whale'       THEN 3.0
            ELSE 1.0
        END
    """)


def downgrade() -> None:
    op.drop_column("scans", "tier_multiplier")
    op.drop_column("tiers", "multiplier")
