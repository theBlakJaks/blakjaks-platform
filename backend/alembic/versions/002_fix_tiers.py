"""fix tiers: remove multipliers, add discount_pct

Revision ID: a1b2c3d4e5f6
Revises: d4460416a694
Create Date: 2026-02-18
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "a1b2c3d4e5f6"
down_revision: Union[str, None] = "d4460416a694"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.drop_column("tiers", "multiplier")
    op.add_column("tiers", sa.Column("discount_pct", sa.Integer(), nullable=False, server_default="0"))
    op.drop_column("scans", "tier_multiplier")


def downgrade() -> None:
    op.add_column("scans", sa.Column("tier_multiplier", sa.Numeric(5, 2), nullable=False, server_default="1.0"))
    op.drop_column("tiers", "discount_pct")
    op.add_column("tiers", sa.Column("multiplier", sa.Numeric(5, 2), nullable=False, server_default="1.0"))
