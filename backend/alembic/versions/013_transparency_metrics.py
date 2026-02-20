"""Create transparency_metrics table.

Revision ID: 013
Revises: 012
Create Date: 2026-02-20
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "013"
down_revision = "012"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "transparency_metrics",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("timestamp", sa.DateTime(timezone=True), nullable=False, index=True),
        sa.Column("metric_type", sa.String(100), nullable=False, index=True),
        sa.Column("metric_value", sa.Numeric(30, 6), nullable=False),
        sa.Column("metadata", postgresql.JSONB, nullable=True),
    )

    # Try to create TimescaleDB hypertable; skip gracefully if extension absent
    try:
        op.execute("SELECT create_hypertable('transparency_metrics', 'timestamp', if_not_exists => TRUE)")
    except Exception:
        pass


def downgrade() -> None:
    op.drop_table("transparency_metrics")
