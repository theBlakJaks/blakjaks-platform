"""Create transparency_metrics TimescaleDB hypertable.

Revision ID: g8h9i0j1k2l3
Revises: f7g8h9i0j1k2
Create Date: 2026-02-19
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import JSONB

revision: str = "g8h9i0j1k2l3"
down_revision: Union[str, None] = "f7g8h9i0j1k2"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "transparency_metrics",
        sa.Column("id", sa.BigInteger(), autoincrement=True, primary_key=True),
        sa.Column("timestamp", sa.DateTime(timezone=True), nullable=False,
                  server_default=sa.text("now()")),
        sa.Column("metric_type", sa.String(100), nullable=False),
        sa.Column("metric_value", sa.Numeric(20, 6), nullable=False),
        sa.Column("metadata", JSONB, nullable=True),
    )
    op.create_index("ix_transparency_metrics_timestamp", "transparency_metrics", ["timestamp"])
    op.create_index("ix_transparency_metrics_type", "transparency_metrics", ["metric_type"])

    # Convert to TimescaleDB hypertable if extension is available
    op.execute("""
        DO $$
        BEGIN
            IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'timescaledb') THEN
                PERFORM create_hypertable('transparency_metrics', 'timestamp',
                    if_not_exists => TRUE);
                PERFORM add_retention_policy('transparency_metrics',
                    INTERVAL '2 years', if_not_exists => TRUE);
            END IF;
        END $$;
    """)


def downgrade() -> None:
    op.drop_table("transparency_metrics")
