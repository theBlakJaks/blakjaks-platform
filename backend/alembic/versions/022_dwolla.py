"""Add dwolla_customers table.

Revision ID: 022
Revises: 021
Create Date: 2025-05-01 00:00:00.000000
"""

from alembic import op
import sqlalchemy as sa

revision = "022"
down_revision = "021"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "dwolla_customers",
        sa.Column(
            "id",
            sa.UUID(),
            server_default=sa.text("gen_random_uuid()"),
            nullable=False,
        ),
        sa.Column("user_id", sa.UUID(), nullable=False),
        sa.Column("dwolla_customer_url", sa.String(512), nullable=False),
        sa.Column("dwolla_funding_source_url", sa.String(512), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.UniqueConstraint("user_id"),
    )
    op.create_index(
        "ix_dwolla_customers_user_id", "dwolla_customers", ["user_id"]
    )


def downgrade() -> None:
    op.drop_index("ix_dwolla_customers_user_id", table_name="dwolla_customers")
    op.drop_table("dwolla_customers")
