"""seed tier data

Revision ID: f6e5d4c3b2a1
Revises: a1b2c3d4e5f6
Create Date: 2026-02-18
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

revision: str = "f6e5d4c3b2a1"
down_revision: Union[str, None] = "a1b2c3d4e5f6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

TIERS = [
    {
        "name": "Standard",
        "min_scans": 0,
        "discount_pct": 0,
        "color": "#6B7280",
        "benefits_json": {
            "comp_eligibility": [],
            "community_access": "observational",
            "merch_tier": None,
        },
    },
    {
        "name": "VIP",
        "min_scans": 7,
        "discount_pct": 10,
        "color": "#3B82F6",
        "benefits_json": {
            "comp_eligibility": ["crypto_100"],
            "community_access": "full",
            "merch_tier": "vip",
        },
    },
    {
        "name": "High Roller",
        "min_scans": 15,
        "discount_pct": 15,
        "color": "#F59E0B",
        "benefits_json": {
            "comp_eligibility": ["crypto_100", "crypto_1k"],
            "community_access": "high_roller_lounge",
            "merch_tier": "high_roller",
        },
    },
    {
        "name": "Whale",
        "min_scans": 30,
        "discount_pct": 20,
        "color": "#8B5CF6",
        "benefits_json": {
            "comp_eligibility": ["crypto_100", "crypto_1k", "crypto_10k", "casino_comp"],
            "community_access": "whale_lounge",
            "merch_tier": "whale",
        },
    },
]


def upgrade() -> None:
    tiers_table = sa.table(
        "tiers",
        sa.column("name", sa.String),
        sa.column("min_scans", sa.Integer),
        sa.column("discount_pct", sa.Integer),
        sa.column("color", sa.String),
        sa.column("benefits_json", JSONB),
    )
    op.bulk_insert(tiers_table, TIERS)


def downgrade() -> None:
    op.execute("DELETE FROM tiers WHERE name IN ('Standard', 'VIP', 'High Roller', 'Whale')")
