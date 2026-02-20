"""Create treasury_snapshots TimescaleDB hypertable.

Revision ID: h9i0j1k2l3m4
Revises: g8h9i0j1k2l3
Create Date: 2026-02-19
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import JSONB

revision: str = "h9i0j1k2l3m4"
down_revision: Union[str, None] = "g8h9i0j1k2l3"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "treasury_snapshots",
        sa.Column("id", sa.BigInteger(), autoincrement=True, primary_key=True),
        sa.Column("timestamp", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.text("now()")),
        sa.Column("pool_type", sa.String(50), nullable=False),
        sa.Column("onchain_balance", sa.Numeric(20, 6), nullable=False, server_default="0"),
        sa.Column("bank_balance", sa.Numeric(20, 6), nullable=False, server_default="0"),
        sa.Column("metadata", JSONB, nullable=True),
    )
    op.create_index("ix_treasury_snapshots_timestamp", "treasury_snapshots", ["timestamp"])
    op.create_index("ix_treasury_snapshots_pool_type", "treasury_snapshots", ["pool_type"])

    # Convert to TimescaleDB hypertable if extension is available
    # 90-day retention for raw data; daily rollups kept 2 years (handled by Celery job)
    op.execute("""
        DO $$
        BEGIN
            IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'timescaledb') THEN
                PERFORM create_hypertable('treasury_snapshots', 'timestamp',
                    if_not_exists => TRUE);
                PERFORM add_retention_policy('treasury_snapshots',
                    INTERVAL '90 days', if_not_exists => TRUE);
            END IF;
        END $$;
    """)


def downgrade() -> None:
    op.drop_table("treasury_snapshots")
