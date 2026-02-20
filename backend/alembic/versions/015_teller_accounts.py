"""Create teller_accounts table and seed 3 treasury accounts.

Revision ID: i0j1k2l3m4n5
Revises: h9i0j1k2l3m4
Create Date: 2026-02-19
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "i0j1k2l3m4n5"
down_revision: Union[str, None] = "h9i0j1k2l3m4"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "teller_accounts",
        sa.Column("id", sa.String(36), primary_key=True),
        sa.Column("account_name", sa.String(100), nullable=False, unique=True),
        sa.Column("account_type", sa.String(50), nullable=False),
        sa.Column("institution_name", sa.String(100), nullable=True),
        sa.Column("teller_account_id", sa.String(100), nullable=True),
        sa.Column("last_four", sa.String(4), nullable=True),
        sa.Column("balance", sa.Numeric(20, 2), nullable=False, server_default="0"),
        sa.Column("currency", sa.String(10), nullable=False, server_default="USD"),
        sa.Column("status", sa.String(50), nullable=False, server_default="pending"),
        sa.Column("last_synced_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.text("now()")),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.text("now()")),
    )

    # Seed 3 treasury accounts per Platform v2 spec (no credentials yet)
    op.execute("""
        INSERT INTO teller_accounts (id, account_name, account_type, status) VALUES
        ('teller-operating-001', 'Operating', 'checking', 'pending'),
        ('teller-reserve-001',   'Reserve',   'savings',  'pending'),
        ('teller-comp-001',      'Comp Pool', 'checking', 'pending')
        ON CONFLICT (id) DO NOTHING;
    """)


def downgrade() -> None:
    op.drop_table("teller_accounts")
