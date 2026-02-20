"""Add comp_balance to users and payout_destination to transactions.

Revision ID: 023
Revises: 022
Create Date: 2026-02-20 00:00:00.000000
"""

from alembic import op
import sqlalchemy as sa

revision = "023"
down_revision = "022"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column("comp_balance", sa.Numeric(10, 2), nullable=False, server_default=sa.text("0")),
    )
    op.add_column(
        "transactions",
        sa.Column("payout_destination", sa.String(10), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("transactions", "payout_destination")
    op.drop_column("users", "comp_balance")
