"""Add affiliate chips, payouts, and sunset status tables.

Revision ID: d5e6f7g8h9i0
Revises: b7c8d9e0f1g2
"""
from typing import Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import UUID

revision: str = "d5e6f7g8h9i0"
down_revision: Union[str, None] = "b7c8d9e0f1g2"


def upgrade() -> None:
    # -- affiliate_chips --
    op.create_table(
        "affiliate_chips",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("affiliate_id", UUID(as_uuid=True), sa.ForeignKey("affiliates.id"), nullable=False, index=True),
        sa.Column("source_user_id", UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False, index=True),
        sa.Column("source_scan_id", UUID(as_uuid=True), sa.ForeignKey("scans.id"), nullable=False, index=True),
        sa.Column("is_vaulted", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("vault_date", sa.DateTime(timezone=True), nullable=True),
        sa.Column("vault_expiry", sa.DateTime(timezone=True), nullable=True),
        sa.Column("is_expired", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
    )

    # -- affiliate_payouts --
    op.create_table(
        "affiliate_payouts",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("affiliate_id", UUID(as_uuid=True), sa.ForeignKey("affiliates.id"), nullable=False, index=True),
        sa.Column("amount", sa.Numeric(12, 2), nullable=False),
        sa.Column("payout_type", sa.String(30), nullable=False),
        sa.Column("period_start", sa.DateTime(timezone=True), nullable=False),
        sa.Column("period_end", sa.DateTime(timezone=True), nullable=False),
        sa.Column("status", sa.String(20), server_default=sa.text("'pending'"), nullable=False),
        sa.Column("tx_hash", sa.String(100), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
    )

    # -- sunset_status --
    op.create_table(
        "sunset_status",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("monthly_volume", sa.Integer(), nullable=False, server_default=sa.text("0")),
        sa.Column("rolling_3mo_avg", sa.Integer(), nullable=False, server_default=sa.text("0")),
        sa.Column("threshold", sa.Integer(), nullable=False, server_default=sa.text("10000000")),
        sa.Column("is_triggered", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("triggered_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
    )


def downgrade() -> None:
    op.drop_table("sunset_status")
    op.drop_table("affiliate_payouts")
    op.drop_table("affiliate_chips")
