"""Rename usdt_earned to usdc_earned in scans table

Revision ID: 024
Revises: 023
Create Date: 2026-02-20
"""

from alembic import op

revision = "024"
down_revision = "023"
branch_labels = None
depends_on = None


def upgrade():
    op.alter_column('scans', 'usdt_earned', new_column_name='usdc_earned')


def downgrade():
    op.alter_column('scans', 'usdc_earned', new_column_name='usdt_earned')
