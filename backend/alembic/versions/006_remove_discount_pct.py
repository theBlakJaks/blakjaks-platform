"""remove discount_pct from tiers, move to benefits_json

Revision ID: s9t0u1v2w3x4
Revises: m3n4o5p6q7r8
Create Date: 2026-02-18
"""
import json
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "s9t0u1v2w3x4"
down_revision: Union[str, None] = "m3n4o5p6q7r8"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

TIER_PARTNER_DISCOUNTS = {
    "Standard": 0,
    "VIP": 10,
    "High Roller": 15,
    "Whale": 20,
}


def upgrade() -> None:
    # Update benefits_json to include partner_discount_pct for each tier
    conn = op.get_bind()
    tiers = conn.execute(sa.text("SELECT id, name, benefits_json FROM tiers")).fetchall()

    for tier_id, name, benefits in tiers:
        partner_pct = TIER_PARTNER_DISCOUNTS.get(name, 0)
        if benefits is None:
            benefits = {}
        benefits["partner_discount_pct"] = partner_pct
        conn.execute(
            sa.text("UPDATE tiers SET benefits_json = cast(:bj as jsonb) WHERE id = :tid"),
            {"bj": json.dumps(benefits), "tid": tier_id},
        )

    # Drop discount_pct column
    op.drop_column("tiers", "discount_pct")


def downgrade() -> None:
    op.add_column("tiers", sa.Column("discount_pct", sa.Integer(), nullable=False, server_default="0"))

    conn = op.get_bind()
    tiers = conn.execute(sa.text("SELECT id, name, benefits_json FROM tiers")).fetchall()

    for tier_id, name, benefits in tiers:
        pct = TIER_PARTNER_DISCOUNTS.get(name, 0)
        conn.execute(
            sa.text("UPDATE tiers SET discount_pct = :pct WHERE id = :tid"),
            {"pct": pct, "tid": tier_id},
        )

        if benefits and "partner_discount_pct" in benefits:
            del benefits["partner_discount_pct"]
            conn.execute(
                sa.text("UPDATE tiers SET benefits_json = cast(:bj as jsonb) WHERE id = :tid"),
                {"bj": json.dumps(benefits), "tid": tier_id},
            )
