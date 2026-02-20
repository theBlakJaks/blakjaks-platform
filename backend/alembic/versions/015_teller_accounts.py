"""Create teller_accounts table and seed 3 account records.

Revision ID: 015
Revises: 014
Create Date: 2026-02-20
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql
import uuid

revision = "015"
down_revision = "014"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "teller_accounts",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column("teller_account_id", sa.String(255), nullable=True, unique=True),
        sa.Column("account_type", sa.String(50), nullable=False),
        sa.Column("institution_name", sa.String(100), nullable=True),
        sa.Column("last_four", sa.String(4), nullable=True),
        sa.Column("balance", sa.Numeric(18, 2), nullable=False, server_default="0"),
        sa.Column("currency", sa.String(3), nullable=False, server_default="USD"),
        sa.Column("last_synced_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("sync_status", sa.String(20), nullable=False, server_default="pending"),
        sa.Column("notes", sa.Text, nullable=True),
    )

    # Seed 3 account placeholders
    op.execute("""
        INSERT INTO teller_accounts (id, name, account_type, sync_status)
        VALUES
            (gen_random_uuid(), 'Operating Account', 'operating', 'pending'),
            (gen_random_uuid(), 'Reserve Account', 'reserve', 'pending'),
            (gen_random_uuid(), 'Comp Pool Account', 'comp_pool', 'pending')
    """)


def downgrade() -> None:
    op.drop_table("teller_accounts")
