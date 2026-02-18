"""seed product catalog — 4 flavors × 4 strengths = 16 products

Revision ID: m3n4o5p6q7r8
Revises: g7h8i9j0k1l2
Create Date: 2026-02-18
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "m3n4o5p6q7r8"
down_revision: Union[str, None] = "g7h8i9j0k1l2"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

FLAVORS = [
    ("Wintergreen", "wintergreen"),
    ("Spearmint", "spearmint"),
    ("Bubblegum", "bubblegum"),
    ("Bluerazz Ice", "bluerazz_ice"),
]

STRENGTHS = ["3mg", "6mg", "9mg", "12mg"]


def upgrade() -> None:
    products_table = sa.table(
        "products",
        sa.column("name", sa.String),
        sa.column("description", sa.Text),
        sa.column("price", sa.Numeric),
        sa.column("flavor", sa.String),
        sa.column("nicotine_strength", sa.String),
        sa.column("stock", sa.Integer),
        sa.column("is_active", sa.Boolean),
    )

    rows = []
    for display_name, flavor_code in FLAVORS:
        for strength in STRENGTHS:
            rows.append({
                "name": f"BlakJaks {display_name} {strength}",
                "description": f"Premium nicotine pouches - {display_name} flavor, {strength} strength",
                "price": 5.00,
                "flavor": flavor_code,
                "nicotine_strength": strength,
                "stock": 1000,
                "is_active": True,
            })

    op.bulk_insert(products_table, rows)


def downgrade() -> None:
    op.execute("DELETE FROM products WHERE name LIKE 'BlakJaks %'")
