"""Create treasury_snapshots table.

Revision ID: 014
Revises: 013
Create Date: 2026-02-20
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "014"
down_revision = "013"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "treasury_snapshots",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("timestamp", sa.DateTime(timezone=True), nullable=False, index=True),
        sa.Column("pool_type", sa.String(30), nullable=False, index=True),
        sa.Column("onchain_balance", sa.Numeric(30, 6), nullable=False),
        sa.Column("bank_balance", sa.Numeric(18, 2), nullable=False, server_default="0"),
        sa.Column("metadata", postgresql.JSONB, nullable=True),
    )

    op.execute("""
        DO $$
        BEGIN
            IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'timescaledb') THEN
                PERFORM create_hypertable('treasury_snapshots', 'timestamp', if_not_exists => TRUE);
            END IF;
        END $$;
    """)


def downgrade() -> None:
    op.drop_table("treasury_snapshots")
