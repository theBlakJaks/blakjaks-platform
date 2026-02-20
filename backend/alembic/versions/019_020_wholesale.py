"""Create wholesale_accounts and wholesale_orders tables (if not already existing).

Revision ID: m4n5o6p7q8r9
Revises: l3m4n5o6p7q8
Create Date: 2026-02-19
"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects.postgresql import JSONB, UUID

revision: str = "m4n5o6p7q8r9"
down_revision: Union[str, None] = "l3m4n5o6p7q8"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    existing_tables = inspector.get_table_names()

    if "wholesale_accounts" not in existing_tables:
        op.create_table(
            "wholesale_accounts",
            sa.Column("id", UUID(as_uuid=True), primary_key=True,
                      server_default=sa.text("gen_random_uuid()")),
            sa.Column("user_id", UUID(as_uuid=True),
                      sa.ForeignKey("users.id", ondelete="CASCADE"),
                      nullable=False, unique=True),
            sa.Column("business_name", sa.String(255), nullable=False),
            sa.Column("contact_name", sa.String(255), nullable=False),
            sa.Column("contact_email", sa.String(255), nullable=False),
            sa.Column("contact_phone", sa.String(50), nullable=True),
            sa.Column("status", sa.String(50), nullable=False, server_default="pending"),
            # status: pending | approved | suspended | rejected
            sa.Column("chips_balance", sa.Integer, nullable=False, server_default="0"),
            sa.Column("lifetime_spend", sa.Numeric(20, 2), nullable=False, server_default="0"),
            sa.Column("notes", sa.Text, nullable=True),
            sa.Column("approved_by_id", UUID(as_uuid=True),
                      sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
            sa.Column("approved_at", sa.DateTime(timezone=True), nullable=True),
            sa.Column("created_at", sa.DateTime(timezone=True), nullable=False,
                      server_default=sa.text("now()")),
            sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False,
                      server_default=sa.text("now()")),
        )
        op.create_index("ix_wholesale_accounts_status", "wholesale_accounts", ["status"])

    if "wholesale_orders" not in existing_tables:
        op.create_table(
            "wholesale_orders",
            sa.Column("id", UUID(as_uuid=True), primary_key=True,
                      server_default=sa.text("gen_random_uuid()")),
            sa.Column("account_id", UUID(as_uuid=True),
                      sa.ForeignKey("wholesale_accounts.id", ondelete="CASCADE"),
                      nullable=False, index=True),
            sa.Column("order_number", sa.String(50), nullable=False, unique=True),
            sa.Column("status", sa.String(50), nullable=False, server_default="pending"),
            # status: pending | confirmed | shipped | delivered | cancelled
            sa.Column("total_amount", sa.Numeric(20, 2), nullable=False),
            sa.Column("chips_earned", sa.Integer, nullable=False, server_default="0"),
            sa.Column("items", JSONB, nullable=False, server_default="[]"),
            sa.Column("shipping_address", JSONB, nullable=True),
            sa.Column("notes", sa.Text, nullable=True),
            sa.Column("created_at", sa.DateTime(timezone=True), nullable=False,
                      server_default=sa.text("now()")),
            sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False,
                      server_default=sa.text("now()")),
        )
        op.create_index("ix_wholesale_orders_status", "wholesale_orders", ["status"])


def downgrade() -> None:
    op.drop_table("wholesale_orders")
    op.drop_table("wholesale_accounts")
